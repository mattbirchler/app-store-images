import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordSecure = true
    @FocusState private var focusedField: Field?

    enum Field {
        case username, password
    }

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
                    VStack(spacing: 16) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            TextField("Enter your username", text: $username)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .password
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                if isPasswordSecure {
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            if canSignIn {
                                                Task {
                                                    await appState.login(username: username, password: password)
                                                }
                                            }
                                        }
                                } else {
                                    TextField("Enter your password", text: $password)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit {
                                            if canSignIn {
                                                Task {
                                                    await appState.login(username: username, password: password)
                                                }
                                            }
                                        }
                                }

                                Button {
                                    isPasswordSecure.toggle()
                                } label: {
                                    Image(systemName: isPasswordSecure ? "eye.slash" : "eye")
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
                                await appState.login(username: username, password: password)
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
                            .background(canSignIn ? Color.accentColor : Color.gray)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!canSignIn || appState.isLoading)
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Help Text
                    VStack(spacing: 8) {
                        Text("Need help?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Use the same username and password you use to sign in to your payment gateway merchant portal.")
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

    private var canSignIn: Bool {
        !username.isEmpty && !password.isEmpty
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
