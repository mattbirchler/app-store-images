import SwiftUI

@main
struct NMI_POSApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    // Refresh merchant profile on app launch to get latest MDFs
                    await appState.refreshMerchantProfile()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        // Lock the app when going to background if biometric is enabled
                        if appState.settings.biometricEnabled && appState.currentScreen == .main {
                            appState.lockApp()
                        }
                    }
                }
        }
    }
}
