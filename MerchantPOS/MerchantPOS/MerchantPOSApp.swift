//
//  MerchantPOSApp.swift
//  MerchantPOS
//
//  A simple point-of-sale app for Authorize.net merchants
//

import SwiftUI

@main
struct MerchantPOSApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
