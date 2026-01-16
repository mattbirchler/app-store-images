//
//  AuthorizeNetService.swift
//  MerchantPOS
//

import Foundation

enum AuthorizeNetError: LocalizedError {
    case invalidCredentials
    case networkError(String)
    case apiError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid API Login ID or Transaction Key"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return message
        case .decodingError:
            return "Failed to process server response"
        }
    }
}

class AuthorizeNetService {
    private let apiLoginId: String
    private let transactionKey: String
    private let baseURL: String

    // Use sandbox for development, production for live
    static let sandboxURL = "https://apitest.authorize.net/xml/v1/request.api"
    static let productionURL = "https://api.authorize.net/xml/v1/request.api"

    init(apiLoginId: String, transactionKey: String, useSandbox: Bool = true) {
        self.apiLoginId = apiLoginId
        self.transactionKey = transactionKey
        self.baseURL = useSandbox ? Self.sandboxURL : Self.productionURL
    }

    private var authenticationBlock: [String: Any] {
        return [
            "name": apiLoginId,
            "transactionKey": transactionKey
        ]
    }

    // MARK: - Validate Credentials / Get Merchant Profile

    func getMerchantProfile() async throws -> MerchantProfile {
        let request: [String: Any] = [
            "getMerchantDetailsRequest": [
                "merchantAuthentication": authenticationBlock
            ]
        ]

        let responseData = try await performRequest(request)

        guard let response = responseData["getMerchantDetailsResponse"] as? [String: Any] else {
            throw AuthorizeNetError.decodingError
        }

        if let messages = response["messages"] as? [String: Any],
           let resultCode = messages["resultCode"] as? String,
           resultCode == "Error" {
            if let messageArray = messages["message"] as? [[String: Any]],
               let firstMessage = messageArray.first,
               let text = firstMessage["text"] as? String {
                throw AuthorizeNetError.apiError(text)
            }
            throw AuthorizeNetError.invalidCredentials
        }

        let merchantName = response["merchantName"] as? String ?? "Merchant"
        let gatewayId = response["gatewayId"] as? String ?? ""

        var contactDetails: MerchantProfile.ContactDetails?
        if let contact = response["contactDetails"] as? [String: Any] {
            contactDetails = MerchantProfile.ContactDetails(
                firstName: contact["firstName"] as? String,
                lastName: contact["lastName"] as? String,
                email: contact["email"] as? String,
                company: contact["companyName"] as? String,
                address: contact["address"] as? String,
                city: contact["city"] as? String,
                state: contact["state"] as? String,
                zip: contact["zip"] as? String,
                country: contact["country"] as? String,
                phoneNumber: contact["phoneNumber"] as? String
            )
        }

        var processors: [MerchantProfile.ProcessorInfo] = []
        if let processorArray = response["processors"] as? [[String: Any]] {
            processors = processorArray.compactMap { proc in
                MerchantProfile.ProcessorInfo(name: proc["name"] as? String)
            }
        }

        return MerchantProfile(
            merchantName: merchantName,
            gatewayId: gatewayId,
            contactDetails: contactDetails,
            processors: processors
        )
    }

    // MARK: - Process Payment

    func processPayment(_ payment: PaymentRequest) async throws -> TransactionResponse {
        let request: [String: Any] = [
            "createTransactionRequest": [
                "merchantAuthentication": authenticationBlock,
                "transactionRequest": [
                    "transactionType": "authCaptureTransaction",
                    "amount": String(format: "%.2f", payment.totalAmount),
                    "payment": [
                        "creditCard": [
                            "cardNumber": payment.cardNumber,
                            "expirationDate": payment.expirationDate,
                            "cardCode": payment.cvv
                        ]
                    ],
                    "tax": [
                        "amount": String(format: "%.2f", payment.taxAmount),
                        "name": "Sales Tax"
                    ],
                    "billTo": [
                        "firstName": payment.customerFirstName,
                        "lastName": payment.customerLastName,
                        "address": payment.customerAddress,
                        "city": payment.customerCity,
                        "state": payment.customerState,
                        "zip": payment.customerZip,
                        "country": payment.customerCountry,
                        "email": payment.customerEmail
                    ]
                ]
            ]
        ]

        let responseData = try await performRequest(request)

        guard let response = responseData["createTransactionResponse"] as? [String: Any] else {
            throw AuthorizeNetError.decodingError
        }

        if let messages = response["messages"] as? [String: Any],
           let resultCode = messages["resultCode"] as? String,
           resultCode == "Error" {
            if let messageArray = messages["message"] as? [[String: Any]],
               let firstMessage = messageArray.first,
               let text = firstMessage["text"] as? String {
                throw AuthorizeNetError.apiError(text)
            }
            throw AuthorizeNetError.apiError("Transaction failed")
        }

        guard let transactionResponse = response["transactionResponse"] as? [String: Any] else {
            throw AuthorizeNetError.decodingError
        }

        let responseCode = transactionResponse["responseCode"] as? String ?? "0"
        let transactionId = transactionResponse["transId"] as? String
        let authCode = transactionResponse["authCode"] as? String

        var messageCode: String?
        var description: String?
        if let messages = transactionResponse["messages"] as? [[String: Any]],
           let firstMessage = messages.first {
            messageCode = firstMessage["code"] as? String
            description = firstMessage["description"] as? String
        } else if let errors = transactionResponse["errors"] as? [[String: Any]],
                  let firstError = errors.first {
            messageCode = firstError["errorCode"] as? String
            description = firstError["errorText"] as? String
        }

        return TransactionResponse(
            transactionId: transactionId,
            responseCode: responseCode,
            messageCode: messageCode,
            description: description,
            authCode: authCode
        )
    }

    // MARK: - Get Transaction History

    func getTransactionHistory(batchId: String? = nil) async throws -> [Transaction] {
        // First get settled batches to find transactions
        let batchRequest: [String: Any] = [
            "getSettledBatchListRequest": [
                "merchantAuthentication": authenticationBlock,
                "includeStatistics": false
            ]
        ]

        let batchResponseData = try await performRequest(batchRequest)

        guard let batchResponse = batchResponseData["getSettledBatchListResponse"] as? [String: Any] else {
            return []
        }

        // Check for errors
        if let messages = batchResponse["messages"] as? [String: Any],
           let resultCode = messages["resultCode"] as? String,
           resultCode == "Error" {
            return []
        }

        guard let batchList = batchResponse["batchList"] as? [[String: Any]],
              let latestBatch = batchList.first,
              let batchIdToUse = latestBatch["batchId"] as? String else {
            return try await getUnsettledTransactions()
        }

        // Get transactions from batch
        return try await getTransactionsFromBatch(batchId: batchIdToUse)
    }

    private func getTransactionsFromBatch(batchId: String) async throws -> [Transaction] {
        let request: [String: Any] = [
            "getTransactionListRequest": [
                "merchantAuthentication": authenticationBlock,
                "batchId": batchId
            ]
        ]

        let responseData = try await performRequest(request)

        guard let response = responseData["getTransactionListResponse"] as? [String: Any],
              let transactions = response["transactions"] as? [[String: Any]] else {
            return []
        }

        return transactions.compactMap { parseTransaction($0) }
    }

    func getUnsettledTransactions() async throws -> [Transaction] {
        let request: [String: Any] = [
            "getUnsettledTransactionListRequest": [
                "merchantAuthentication": authenticationBlock
            ]
        ]

        let responseData = try await performRequest(request)

        guard let response = responseData["getUnsettledTransactionListResponse"] as? [String: Any],
              let transactions = response["transactions"] as? [[String: Any]] else {
            return []
        }

        return transactions.compactMap { parseTransaction($0) }
    }

    private func parseTransaction(_ data: [String: Any]) -> Transaction? {
        guard let transId = data["transId"] as? String else { return nil }

        let submitTimeUTC = data["submitTimeUTC"] as? String ?? ""
        let submitTimeLocal = data["submitTimeLocal"] as? String ?? ""
        let transactionStatus = data["transactionStatus"] as? String ?? "unknown"
        let accountType = data["accountType"] as? String
        let accountNumber = data["accountNumber"] as? String
        let settleAmount = data["settleAmount"] as? Double ?? 0.0
        let firstName = data["firstName"] as? String
        let lastName = data["lastName"] as? String

        return Transaction(
            id: transId,
            transactionId: transId,
            submitTimeUTC: submitTimeUTC,
            submitTimeLocal: submitTimeLocal,
            transactionStatus: transactionStatus,
            accountType: accountType,
            accountNumber: accountNumber,
            settleAmount: settleAmount,
            firstName: firstName,
            lastName: lastName
        )
    }

    // MARK: - Get Daily Statistics

    func getDailyStatistics() async throws -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]

        let request: [String: Any] = [
            "getUnsettledTransactionListRequest": [
                "merchantAuthentication": authenticationBlock
            ]
        ]

        let responseData = try await performRequest(request)

        guard let response = responseData["getUnsettledTransactionListResponse"] as? [String: Any],
              let transactions = response["transactions"] as? [[String: Any]] else {
            return 0.0
        }

        let todayTotal = transactions.reduce(0.0) { total, transaction in
            let amount = transaction["settleAmount"] as? Double ?? 0.0
            return total + amount
        }

        return todayTotal
    }

    // MARK: - Network Layer

    private func performRequest(_ body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: baseURL) else {
            throw AuthorizeNetError.networkError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthorizeNetError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthorizeNetError.networkError("Server error: \(httpResponse.statusCode)")
        }

        // Remove BOM if present and parse JSON
        var cleanData = data
        if data.count >= 3 {
            let bom: [UInt8] = [0xEF, 0xBB, 0xBF]
            let prefix = Array(data.prefix(3))
            if prefix == bom {
                cleanData = data.dropFirst(3)
            }
        }

        guard let json = try JSONSerialization.jsonObject(with: cleanData) as? [String: Any] else {
            throw AuthorizeNetError.decodingError
        }

        return json
    }
}
