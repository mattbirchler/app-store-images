import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var securityKey = ""
    @State private var isSecure = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // Logo and Title
                    VStack(spacing: 16) {
                        Image("iProcessIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .cornerRadius(22)

                        Text("iProcess")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in with your gateway credentials")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                        .frame(height: 20)

                    // Login Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Security Key")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                if isSecure {
                                    SecureField("Enter your security key", text: $securityKey)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                } else {
                                    TextField("Enter your security key", text: $securityKey)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                }

                                Button {
                                    isSecure.toggle()
                                } label: {
                                    Image(systemName: isSecure ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        // Error Message
                        if let error = appState.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }

                        // Sign In Button
                        Button {
                            Task {
                                await appState.login(securityKey: securityKey)
                            }
                        } label: {
                            HStack {
                                if appState.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(securityKey.isEmpty ? Color.gray : Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .disabled(securityKey.isEmpty || appState.isLoading)
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Help Text
                    VStack(spacing: 8) {
                        Text("Need help?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Find your security key in your payment gateway merchant portal under Settings > Security Keys.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
