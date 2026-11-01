import SwiftUI

@main struct MyApp: App {
    @AppStorage("app_language") private var appLanguage: String = "es"
    @AppStorage("app_appearance") private var appAppearance: String = "system"

    private var preferredColorScheme: ColorScheme? {
        AppAppearance(rawValue: appAppearance)?.colorScheme
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: appLanguage))
                .preferredColorScheme(preferredColorScheme)
        }
    }
}
