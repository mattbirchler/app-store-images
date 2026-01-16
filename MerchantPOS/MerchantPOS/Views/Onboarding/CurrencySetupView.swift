//
//  CurrencySetupView.swift
//  MerchantPOS
//

import SwiftUI

struct CurrencySetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCurrency: String = "USD"

    private let currencies = [
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "EUR"),
        ("GBP", "British Pound", "GBP"),
        ("CAD", "Canadian Dollar", "CAD"),
        ("AUD", "Australian Dollar", "AUD"),
        ("JPY", "Japanese Yen", "JPY"),
        ("MXN", "Mexican Peso", "MXN")
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Progress Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)

                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
            .padding(.top, 20)

            // Header
            VStack(spacing: 12) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Set Your Currency")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Choose the default currency for your transactions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // Currency List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(currencies, id: \.0) { currency in
                        CurrencyRow(
                            code: currency.0,
                            name: currency.1,
                            symbol: currency.2,
                            isSelected: selectedCurrency == currency.0
                        ) {
                            selectedCurrency = currency.0
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            // Continue Button
            Button(action: {
                appState.settings.currency = selectedCurrency
                appState.completeCurrencySetup()
            }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

struct CurrencyRow: View {
    let code: String
    let name: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(code)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(symbol)
                    .font(.title3)
                    .foregroundColor(.secondary)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    CurrencySetupView()
        .environmentObject(AppState())
}
