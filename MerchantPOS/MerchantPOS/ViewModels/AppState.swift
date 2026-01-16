//
//  AppState.swift
//  MerchantPOS
//

import Foundation
import SwiftUI

enum AppScreen {
    case login
    case welcome
    case onboardingCurrency
    case onboardingTax
    case main
}

class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .login
    @Published var isAuthenticated: Bool = false
    @Published var merchantProfile: MerchantProfile?
    @Published var settings: MerchantSettings

    private let settingsKey = "merchantSettings"
    private let credentialsKey = "merchantCredentials"

    init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(MerchantSettings.self, from: data) {
            self.settings = settings
        } else {
            self.settings = MerchantSettings()
        }
    }

    var apiCredentials: APICredentials? {
        get {
            guard let data = UserDefaults.standard.data(forKey: credentialsKey),
                  let credentials = try? JSONDecoder().decode(APICredentials.self, from: data) else {
                return nil
            }
            return credentials
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: credentialsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: credentialsKey)
            }
        }
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    func completeLogin(profile: MerchantProfile, credentials: APICredentials) {
        self.merchantProfile = profile
        self.apiCredentials = credentials
        self.isAuthenticated = true
        self.currentScreen = .welcome
    }

    func proceedToOnboarding() {
        currentScreen = .onboardingCurrency
    }

    func completeCurrencySetup() {
        saveSettings()
        currentScreen = .onboardingTax
    }

    func completeTaxSetup() {
        saveSettings()
        settings.hasCompletedOnboarding = true
        saveSettings()
        currentScreen = .main
    }

    func signOut() {
        isAuthenticated = false
        merchantProfile = nil
        apiCredentials = nil
        settings = MerchantSettings()
        UserDefaults.standard.removeObject(forKey: settingsKey)
        UserDefaults.standard.removeObject(forKey: credentialsKey)
        currentScreen = .login
    }
}

struct APICredentials: Codable {
    let apiLoginId: String
    let transactionKey: String
}

struct MerchantSettings: Codable {
    var currency: String = "USD"
    var taxRate: Double = 0.0
    var hasCompletedOnboarding: Bool = false
}
