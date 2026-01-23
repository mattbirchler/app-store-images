import SwiftUI

struct CustomerVaultView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let onSelectCustomer: (VaultCustomer) -> Void

    @State private var customers: [VaultCustomer] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var filteredCustomers: [VaultCustomer] {
        guard !searchText.isEmpty else { return customers }
        let query = searchText.lowercased()
        return customers.filter { customer in
            customer.firstName.lowercased().contains(query) ||
            customer.lastName.lowercased().contains(query) ||
            customer.email.lowercased().contains(query) ||
            customer.company.lowercased().contains(query) ||
            customer.lastFour.contains(query) ||
            customer.phone.contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if customers.isEmpty {
                    emptyView
                } else {
                    customerListView
                }
            }
            .navigationTitle("Customer Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadCustomers()
            }
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading customers...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Unable to load customers")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                Task {
                    await loadCustomers()
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Vaulted Customers")
                .font(.headline)

            Text("Customers with stored payment methods will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var customerListView: some View {
        List {
            if filteredCustomers.isEmpty && !searchText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)

                    Text("No results for \"\(searchText)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredCustomers) { customer in
                    Button {
                        onSelectCustomer(customer)
                        dismiss()
                    } label: {
                        CustomerVaultRow(customer: customer)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search by name, email, or card")
        .refreshable {
            await loadCustomers()
        }
    }

    // MARK: - Actions

    private func loadCustomers() async {
        isLoading = true
        errorMessage = nil

        do {
            customers = try await NMIService.shared.getVaultCustomers(securityKey: appState.securityKey)
        } catch let error as NMIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Customer Vault Row

struct CustomerVaultRow: View {
    let customer: VaultCustomer

    var body: some View {
        HStack(spacing: 12) {
            // Card type icon
            cardIcon
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            // Customer details
            VStack(alignment: .leading, spacing: 4) {
                Text(customer.displayName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text("\(customer.cardTypeDisplayName) \u{2022}\u{2022}\u{2022}\u{2022} \(customer.lastFour)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Exp \(customer.formattedExpiration)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if !customer.email.isEmpty {
                    Text(customer.email)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var cardIcon: some View {
        let color: Color = {
            switch customer.ccType.lowercased() {
            case "visa":
                return .blue
            case "mastercard", "mc":
                return .orange
            case "amex", "americanexpress":
                return .green
            case "discover":
                return .purple
            default:
                return .gray
            }
        }()

        return Image(systemName: "creditcard.fill")
            .font(.system(size: 18))
            .foregroundStyle(color)
    }
}

#Preview {
    CustomerVaultView(onSelectCustomer: { _ in })
        .environmentObject(AppState())
}

#Preview("Customer Row") {
    List {
        CustomerVaultRow(customer: VaultCustomer(
            id: "123",
            customerVaultId: "123",
            firstName: "John",
            lastName: "Smith",
            email: "john@example.com",
            phone: "555-1234",
            company: "",
            address1: "123 Main St",
            city: "Anytown",
            state: "CA",
            postalCode: "12345",
            country: "US",
            ccNumber: "4xxxxxxxxxxx4242",
            ccExp: "1225",
            ccType: "visa",
            ccBin: "411111",
            created: Date(),
            updated: Date()
        ))
    }
}
