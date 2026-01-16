//
//  Transaction.swift
//  MerchantPOS
//

import Foundation

struct Transaction: Identifiable, Codable {
    let id: String
    let transactionId: String
    let submitTimeUTC: String
    let submitTimeLocal: String
    let transactionStatus: String
    let accountType: String?
    let accountNumber: String?
    let settleAmount: Double
    let firstName: String?
    let lastName: String?

    var customerName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Unknown Customer" : name
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: settleAmount)) ?? "$\(settleAmount)"
    }

    var formattedDate: String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]

        if let date = inputFormatter.date(from: submitTimeUTC) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            outputFormatter.timeStyle = .short
            return outputFormatter.string(from: date)
        }
        return submitTimeLocal
    }

    var statusColor: String {
        switch transactionStatus.lowercased() {
        case "settledsuccessfully":
            return "green"
        case "capturedpendingsettlement":
            return "orange"
        case "declined", "error", "voided":
            return "red"
        default:
            return "gray"
        }
    }

    var maskedCardNumber: String {
        if let accountNumber = accountNumber {
            return "****\(accountNumber)"
        }
        return "****"
    }
}

struct TransactionResponse: Codable {
    let transactionId: String?
    let responseCode: String
    let messageCode: String?
    let description: String?
    let authCode: String?

    var isSuccess: Bool {
        return responseCode == "1"
    }
}

struct PaymentRequest {
    let amount: Double
    let taxAmount: Double
    let cardNumber: String
    let expirationDate: String
    let cvv: String
    let customerFirstName: String
    let customerLastName: String
    let customerEmail: String
    let customerAddress: String
    let customerCity: String
    let customerState: String
    let customerZip: String
    let customerCountry: String

    var totalAmount: Double {
        return amount + taxAmount
    }
}
