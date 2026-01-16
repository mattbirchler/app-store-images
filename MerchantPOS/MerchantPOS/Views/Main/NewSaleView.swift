//
//  NewSaleView.swift
//  MerchantPOS
//

import SwiftUI

struct NewSaleView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var onComplete: () -> Void

    // Amount
    @State private var amountString: String = ""

    // Card Info
    @State private var cardNumber: String = ""
    @State private var expirationMonth: String = ""
    @State private var expirationYear: String = ""
    @State private var cvv: String = ""

    // Customer Info
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var country: String = "US"

    // State
    @State private var isProcessing: Bool = false
    @State private var showingResult: Bool = false
    @State private var transactionResult: TransactionResponse?
    @State private var errorMessage: String?
    @State private var currentStep: Int = 0

    private var amount: Double {
        Double(amountString) ?? 0.0
    }

    private var taxAmount: Double {
        amount * (appState.settings.taxRate / 100)
    }

    private var totalAmount: Double {
        amount + taxAmount
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Step Indicator
                StepIndicator(currentStep: currentStep, totalSteps: 3)
                    .padding()

                TabView(selection: $currentStep) {
                    // Step 1: Amount
                    AmountEntryView(
                        amountString: $amountString,
                        currency: appState.settings.currency,
                        taxRate: appState.settings.taxRate
                    )
                    .tag(0)

                    // Step 2: Card Info
                    CardInfoView(
                        cardNumber: $cardNumber,
                        expirationMonth: $expirationMonth,
                        expirationYear: $expirationYear,
                        cvv: $cvv
                    )
                    .tag(1)

                    // Step 3: Customer Info
                    CustomerInfoView(
                        firstName: $firstName,
                        lastName: $lastName,
                        email: $email,
                        address: $address,
                        city: $city,
                        state: $state,
                        zip: $zip,
                        country: $country
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: { withAnimation { currentStep -= 1 } }) {
                            Text("Back")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }

                    Button(action: handleNextAction) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(currentStep == 2 ? (isProcessing ? "Processing..." : "Process Payment") : "Continue")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isStepValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isStepValid || isProcessing)
                }
                .padding()
            }
            .navigationTitle("New Sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Transaction Result", isPresented: $showingResult) {
                Button("Done") {
                    if transactionResult?.isSuccess == true {
                        onComplete()
                    }
                }
            } message: {
                if let result = transactionResult {
                    if result.isSuccess {
                        Text("Transaction approved!\nTransaction ID: \(result.transactionId ?? "N/A")\nAuth Code: \(result.authCode ?? "N/A")")
                    } else {
                        Text("Transaction declined.\n\(result.description ?? "Please try again.")")
                    }
                } else if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private var isStepValid: Bool {
        switch currentStep {
        case 0:
            return amount > 0
        case 1:
            return cardNumber.count >= 13 &&
                   !expirationMonth.isEmpty &&
                   !expirationYear.isEmpty &&
                   cvv.count >= 3
        case 2:
            return !firstName.isEmpty &&
                   !lastName.isEmpty &&
                   !address.isEmpty &&
                   !city.isEmpty &&
                   !state.isEmpty &&
                   !zip.isEmpty
        default:
            return false
        }
    }

    private func handleNextAction() {
        if currentStep < 2 {
            withAnimation {
                currentStep += 1
            }
        } else {
            processPayment()
        }
    }

    private func processPayment() {
        guard let credentials = appState.apiCredentials else { return }

        isProcessing = true
        errorMessage = nil

        let service = AuthorizeNetService(
            apiLoginId: credentials.apiLoginId,
            transactionKey: credentials.transactionKey
        )

        let expDate = "\(expirationMonth)/\(expirationYear)"

        let paymentRequest = PaymentRequest(
            amount: amount,
            taxAmount: taxAmount,
            cardNumber: cardNumber.replacingOccurrences(of: " ", with: ""),
            expirationDate: expDate,
            cvv: cvv,
            customerFirstName: firstName,
            customerLastName: lastName,
            customerEmail: email,
            customerAddress: address,
            customerCity: city,
            customerState: state,
            customerZip: zip,
            customerCountry: country
        )

        Task {
            do {
                let response = try await service.processPayment(paymentRequest)
                await MainActor.run {
                    transactionResult = response
                    isProcessing = false
                    showingResult = true
                }
            } catch let error as AuthorizeNetError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    transactionResult = nil
                    isProcessing = false
                    showingResult = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "An unexpected error occurred."
                    transactionResult = nil
                    isProcessing = false
                    showingResult = true
                }
            }
        }
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
            }
        }
    }
}

// MARK: - Amount Entry View

struct AmountEntryView: View {
    @Binding var amountString: String
    let currency: String
    let taxRate: Double

    private var amount: Double {
        Double(amountString) ?? 0.0
    }

    private var taxAmount: Double {
        amount * (taxRate / 100)
    }

    private var totalAmount: Double {
        amount + taxAmount
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Enter Amount")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(alignment: .top, spacing: 4) {
                Text(currencySymbol)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.secondary)

                TextField("0.00", text: $amountString)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 56, weight: .bold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 200)
            }

            // Tax Breakdown
            if amount > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("Subtotal")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(amount))
                    }

                    HStack {
                        Text("Tax (\(String(format: "%.2f", taxRate))%)")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(taxAmount))
                    }

                    Divider()

                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(formatCurrency(totalAmount))
                            .fontWeight(.bold)
                    }
                }
                .font(.subheadline)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .padding()
    }

    private var currencySymbol: String {
        let locale = Locale.current
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.currencySymbol ?? "$"
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - Card Info View

struct CardInfoView: View {
    @Binding var cardNumber: String
    @Binding var expirationMonth: String
    @Binding var expirationYear: String
    @Binding var cvv: String

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Card Information")
                    .font(.headline)
                    .foregroundColor(.secondary)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Card Number")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("1234 5678 9012 3456", text: $cardNumber)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Month")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("MM", text: $expirationMonth)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Year")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("YY", text: $expirationYear)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("CVV")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            SecureField("123", text: $cvv)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Card Type Indicator
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .font(.title)
                        .foregroundColor(cardType != nil ? .blue : .gray)

                    if let type = cardType {
                        Text(type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
    }

    private var cardType: String? {
        let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        guard !cleanNumber.isEmpty else { return nil }

        if cleanNumber.hasPrefix("4") {
            return "Visa"
        } else if cleanNumber.hasPrefix("5") || cleanNumber.hasPrefix("2") {
            return "Mastercard"
        } else if cleanNumber.hasPrefix("3") {
            return "American Express"
        } else if cleanNumber.hasPrefix("6") {
            return "Discover"
        }
        return "Card"
    }
}

// MARK: - Customer Info View

struct CustomerInfoView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String
    @Binding var address: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zip: String
    @Binding var country: String

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Customer Information")
                    .font(.headline)
                    .foregroundColor(.secondary)

                VStack(spacing: 16) {
                    // Name
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("John", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocorrectionDisabled()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("Doe", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocorrectionDisabled()
                        }
                    }

                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("john@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }

                    // Address
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Street Address")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("123 Main St", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // City, State, Zip
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("City")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("City", text: $city)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("State")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("CA", text: $state)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("ZIP")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("12345", text: $zip)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                        }
                    }

                    // Country
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Country")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("US", text: $country)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    NewSaleView(onComplete: {})
        .environmentObject(AppState())
}
