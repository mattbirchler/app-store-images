//
//  TaxSetupView.swift
//  MerchantPOS
//

import SwiftUI

struct TaxSetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var taxRateString: String = ""
    @FocusState private var isInputFocused: Bool

    private var taxRateValue: Double {
        Double(taxRateString) ?? 0.0
    }

    private var isValidTaxRate: Bool {
        let value = taxRateValue
        return value >= 0 && value <= 100
    }

    var body: some View {
        VStack(spacing: 24) {
            // Progress Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)

                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
            .padding(.top, 20)

            // Header
            VStack(spacing: 12) {
                Image(systemName: "percent")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Set Your Tax Rate")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Enter your local sales tax rate to automatically calculate taxes on transactions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            // Tax Rate Input
            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 8) {
                    TextField("0.00", text: $taxRateString)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 48, weight: .bold))
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 100)
                        .focused($isInputFocused)

                    Text("%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.secondary)
                }

                Text("Example: Enter 8.25 for 8.25% sales tax")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Common Tax Rates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Select")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        QuickTaxButton(rate: "0") { taxRateString = "0" }
                        QuickTaxButton(rate: "5") { taxRateString = "5" }
                        QuickTaxButton(rate: "7") { taxRateString = "7" }
                        QuickTaxButton(rate: "8.25") { taxRateString = "8.25" }
                        QuickTaxButton(rate: "10") { taxRateString = "10" }
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // Complete Setup Button
            Button(action: completeSetup) {
                Text("Complete Setup")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidTaxRate ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!isValidTaxRate)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .onTapGesture {
            isInputFocused = false
        }
    }

    private func completeSetup() {
        appState.settings.taxRate = taxRateValue
        appState.completeTaxSetup()
    }
}

struct QuickTaxButton: View {
    let rate: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(rate)%")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    TaxSetupView()
        .environmentObject(AppState())
}
