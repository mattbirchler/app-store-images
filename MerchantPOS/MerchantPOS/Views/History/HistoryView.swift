//
//  HistoryView.swift
//  MerchantPOS
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var transactions: [Transaction] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showingUnsettled: Bool = true

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segment Control
                Picker("Transaction Type", selection: $showingUnsettled) {
                    Text("Pending").tag(true)
                    Text("Settled").tag(false)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: showingUnsettled) { _ in
                    loadTransactions()
                }

                if isLoading {
                    Spacer()
                    ProgressView("Loading transactions...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Retry") {
                            loadTransactions()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    Spacer()
                } else if transactions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text("No transactions found")
                            .font(.headline)

                        Text(showingUnsettled ?
                             "Transactions will appear here once you process a sale" :
                             "No settled transactions in recent batches")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(transactions) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Transaction History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadTransactions) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                loadTransactions()
            }
        }
    }

    private func loadTransactions() {
        guard let credentials = appState.apiCredentials else { return }

        isLoading = true
        errorMessage = nil

        let service = AuthorizeNetService(
            apiLoginId: credentials.apiLoginId,
            transactionKey: credentials.transactionKey
        )

        Task {
            do {
                let fetchedTransactions: [Transaction]
                if showingUnsettled {
                    fetchedTransactions = try await service.getUnsettledTransactions()
                } else {
                    fetchedTransactions = try await service.getTransactionHistory()
                }

                await MainActor.run {
                    transactions = fetchedTransactions
                    isLoading = false
                }
            } catch let error as AuthorizeNetError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load transactions"
                    isLoading = false
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.customerName)
                        .font(.headline)

                    Spacer()

                    Text(transaction.formattedAmount)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                HStack {
                    Text(transaction.maskedCardNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let accountType = transaction.accountType {
                        Text("(\(accountType))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(transaction.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(formattedStatus)
                    .font(.caption2)
                    .foregroundColor(statusColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch transaction.transactionStatus.lowercased() {
        case "settledsuccessfully":
            return .green
        case "capturedpendingsettlement":
            return .orange
        case "declined", "error", "voided":
            return .red
        default:
            return .gray
        }
    }

    private var formattedStatus: String {
        switch transaction.transactionStatus.lowercased() {
        case "settledsuccessfully":
            return "Settled"
        case "capturedpendingsettlement":
            return "Pending Settlement"
        case "declined":
            return "Declined"
        case "voided":
            return "Voided"
        case "error":
            return "Error"
        default:
            return transaction.transactionStatus
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
}
