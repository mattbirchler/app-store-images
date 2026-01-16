//
//  DashboardView.swift
//  MerchantPOS
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var dailyRevenue: Double = 0.0
    @State private var isLoadingRevenue: Bool = true
    @State private var showingNewSale: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    if let profile = appState.merchantProfile {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back,")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(profile.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // Daily Revenue Card
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title2)
                                .foregroundColor(.green)

                            Text("Today's Revenue")
                                .font(.headline)

                            Spacer()

                            if isLoadingRevenue {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }

                        HStack {
                            Text(formattedRevenue)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        HStack {
                            Text("Pending settlement")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button(action: refreshRevenue) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // New Sale Button
                    Button(action: { showingNewSale = true }) {
                        HStack(spacing: 16) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("New Sale")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Start a new transaction")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.title2)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)

                    // Quick Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Info")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            StatCard(
                                icon: "percent",
                                title: "Tax Rate",
                                value: String(format: "%.2f%%", appState.settings.taxRate)
                            )

                            StatCard(
                                icon: "dollarsign.circle",
                                title: "Currency",
                                value: appState.settings.currency
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingNewSale) {
                NewSaleView(onComplete: {
                    showingNewSale = false
                    refreshRevenue()
                })
            }
            .onAppear {
                refreshRevenue()
            }
        }
    }

    private var formattedRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = appState.settings.currency
        return formatter.string(from: NSNumber(value: dailyRevenue)) ?? "$0.00"
    }

    private func refreshRevenue() {
        guard let credentials = appState.apiCredentials else { return }

        isLoadingRevenue = true

        let service = AuthorizeNetService(
            apiLoginId: credentials.apiLoginId,
            transactionKey: credentials.transactionKey
        )

        Task {
            do {
                let revenue = try await service.getDailyStatistics()
                await MainActor.run {
                    dailyRevenue = revenue
                    isLoadingRevenue = false
                }
            } catch {
                await MainActor.run {
                    isLoadingRevenue = false
                }
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
