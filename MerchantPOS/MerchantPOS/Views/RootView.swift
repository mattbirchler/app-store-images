//
//  RootView.swift
//  MerchantPOS
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.currentScreen {
            case .login:
                LoginView()
            case .welcome:
                WelcomeView()
            case .onboardingCurrency:
                CurrencySetupView()
            case .onboardingTax:
                TaxSetupView()
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut, value: appState.currentScreen)
    }
}
