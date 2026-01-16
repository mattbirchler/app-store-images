//
//  WelcomeView.swift
//  MerchantPOS
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Welcome Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            // Welcome Message
            VStack(spacing: 12) {
                Text("Welcome!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let profile = appState.merchantProfile {
                    Text(profile.displayName)
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }

            // Account Info Card
            if let profile = appState.merchantProfile {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Information")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        if let contactName = profile.contactName {
                            InfoRow(icon: "person.fill", label: "Contact", value: contactName)
                        }

                        if let contact = profile.contactDetails, let email = contact.email, !email.isEmpty {
                            InfoRow(icon: "envelope.fill", label: "Email", value: email)
                        }

                        if let contact = profile.contactDetails, let phone = contact.phoneNumber, !phone.isEmpty {
                            InfoRow(icon: "phone.fill", label: "Phone", value: phone)
                        }

                        if let address = profile.formattedAddress {
                            InfoRow(icon: "location.fill", label: "Address", value: address)
                        }

                        if !profile.gatewayId.isEmpty {
                            InfoRow(icon: "number", label: "Gateway ID", value: profile.gatewayId)
                        }

                        if let processors = profile.processors, !processors.isEmpty {
                            let processorNames = processors.compactMap { $0.name }.joined(separator: ", ")
                            if !processorNames.isEmpty {
                                InfoRow(icon: "building.2.fill", label: "Processor", value: processorNames)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
            }

            Spacer()

            // Continue Button
            Button(action: {
                appState.proceedToOnboarding()
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

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
            }

            Spacer()
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
            address: "123 Main St",
            city: "San Francisco",
            state: "CA",
            zip: "94102",
            country: "US",
            phoneNumber: "555-123-4567"
        ),
        processors: [MerchantProfile.ProcessorInfo(name: "First Data")]
    )
    return WelcomeView()
        .environmentObject(appState)
}
