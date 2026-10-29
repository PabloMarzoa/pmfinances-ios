import SwiftUI

@main struct MyApp: App {
    @AppStorage("app_language") private var appLanguage: String = "es"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: appLanguage))
                .preferredColorScheme(.dark)
        }
    }
}
