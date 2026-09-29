import SwiftUI
import WeeklyLimit
import WeeklyLimitUI

@main
struct HelloCodexApp: App {
    @State private var services: AppServices

    init() {
        let services = AppServices()
        services.start()
        _services = State(initialValue: services)
    }

    var body: some Scene {
        Window("Hello Codex", id: MainWindow.id) {
            MainWindow()
        }

        MenuBarExtra {
            MenuBarContent()
        } label: {
            WeeklyLimitMenuBarLabel(limit: services.weeklyLimit.limit, icon: Image("MenuBarIcon"))
        }
        .menuBarExtraStyle(.window)
    }
}
