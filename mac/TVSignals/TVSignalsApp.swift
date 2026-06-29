import SwiftUI

@main
struct TVSignalsApp: App {
    var body: some Scene {
        WindowGroup {
            WebView()
                .frame(minWidth: 980, minHeight: 640)
                .ignoresSafeArea()
        }
        .defaultSize(width: 1440, height: 900)
        .windowResizability(.contentMinSize)
        .commands { CommandGroup(replacing: .newItem) {} }   // no "New Window"
    }
}
