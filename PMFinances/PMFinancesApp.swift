import SwiftUI
import AppIntents

@main struct PMFinancesApp: App {
    @AppStorage("app_language") private var appLanguage: String = "es"
    @AppStorage("app_appearance") private var appAppearance: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: appLanguage))
                .onAppear {
                    AppAppearance.apply(appearance: appAppearance)
                    PMFinancesShortcuts.updateAppShortcutParameters()
                }
                .onChange(of: appAppearance) { _, newAppearance in
                    AppAppearance.apply(appearance: newAppearance)
                }
        }
    }
}
