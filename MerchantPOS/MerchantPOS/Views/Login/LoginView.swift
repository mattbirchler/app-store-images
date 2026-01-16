//
//  LoginView.swift
//  MerchantPOS
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiLoginId: String = ""
    @State private var transactionKey: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var useSandbox: Bool = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo and Header
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Merchant POS")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in with your Authorize.net account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Login Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Login ID")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("Enter your API Login ID", text: $apiLoginId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transaction Key")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            SecureField("Enter your Transaction Key", text: $transactionKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        Toggle("Use Sandbox Environment", isOn: $useSandbox)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Sign In Button
                    Button(action: signIn) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Signing In..." : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal)

                    // Help Text
                    VStack(spacing: 8) {
                        Text("Need help finding your credentials?")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Log in to your Authorize.net account and navigate to Account > Settings > Security Settings > API Credentials & Keys")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var isFormValid: Bool {
        !apiLoginId.trimmingCharacters(in: .whitespaces).isEmpty &&
        !transactionKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func signIn() {
        errorMessage = nil
        isLoading = true

        let service = AuthorizeNetService(
            apiLoginId: apiLoginId.trimmingCharacters(in: .whitespaces),
            transactionKey: transactionKey.trimmingCharacters(in: .whitespaces),
            useSandbox: useSandbox
        )

        Task {
            do {
                let profile = try await service.getMerchantProfile()

                await MainActor.run {
                    let credentials = APICredentials(
                        apiLoginId: apiLoginId.trimmingCharacters(in: .whitespaces),
                        transactionKey: transactionKey.trimmingCharacters(in: .whitespaces)
                    )
                    appState.completeLogin(profile: profile, credentials: credentials)
                    isLoading = false
                }
            } catch let error as AuthorizeNetError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "An unexpected error occurred. Please try again."
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
