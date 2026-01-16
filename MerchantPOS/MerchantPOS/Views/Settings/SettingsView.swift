//
//  SettingsView.swift
//  MerchantPOS
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSignOutAlert: Bool = false
    @State private var showingTaxEditor: Bool = false
    @State private var newTaxRate: String = ""

    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section {
                    if let profile = appState.merchantProfile {
                        HStack(spacing: 16) {
                            Image(systemName: "building.2.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .frame(width: 50, height: 50)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.displayName)
                                    .font(.headline)

                                if let contact = profile.contactDetails, let email = contact.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Account")
                }

                // Settings Section
                Section {
                    // Tax Rate
                    Button(action: {
                        newTaxRate = String(format: "%.2f", appState.settings.taxRate)
                        showingTaxEditor = true
                    }) {
                        HStack {
                            Image(systemName: "percent")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            Text("Tax Rate")
                                .foregroundColor(.primary)

                            Spacer()

                            Text(String(format: "%.2f%%", appState.settings.taxRate))
                                .foregroundColor(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Currency (display only for now)
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        Text("Currency")

                        Spacer()

                        Text(appState.settings.currency)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Transaction Settings")
                }

                // App Info Section
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        Text("Version")

                        Spacer()

                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        Text("Environment")

                        Spacer()

                        Text("Sandbox")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }

                // Sign Out Section
                Section {
                    Button(action: { showingSignOutAlert = true }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    appState.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? You will need to enter your credentials again to use the app.")
            }
            .sheet(isPresented: $showingTaxEditor) {
                TaxRateEditorView(
                    taxRateString: $newTaxRate,
                    onSave: { rate in
                        appState.settings.taxRate = rate
                        appState.saveSettings()
                        showingTaxEditor = false
                    },
                    onCancel: {
                        showingTaxEditor = false
                    }
                )
            }
        }
    }
}

struct TaxRateEditorView: View {
    @Binding var taxRateString: String
    var onSave: (Double) -> Void
    var onCancel: () -> Void

    @FocusState private var isInputFocused: Bool

    private var taxRate: Double {
        Double(taxRateString) ?? 0.0
    }

    private var isValid: Bool {
        taxRate >= 0 && taxRate <= 100
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "percent")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Edit Tax Rate")
                    .font(.title)
                    .fontWeight(.bold)

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

                // Quick Select
                VStack(spacing: 12) {
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

                Spacer()

                Button(action: { onSave(taxRate) }) {
                    Text("Save")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }
}

#Preview {
    let appState = AppState()
    appState.merchantProfile = MerchantProfile(
        merchantName: "Test Merchant",
        gatewayId: "123456",
        contactDetails: MerchantProfile.ContactDetails(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            company: "Acme Corp",
            address: nil,
            city: nil,
            state: nil,
            zip: nil,
            country: nil,
            phoneNumber: nil
        ),
        processors: nil
    )
    return SettingsView()
        .environmentObject(appState)
}
