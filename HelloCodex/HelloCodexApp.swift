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
            MainWindow(weeklyLimit: services.weeklyLimit)
        }
        // SwiftUI restores the window's size and position itself; the default
        // size fits the design's 760 wide.
        .defaultSize(width: 760, height: 930)

        MenuBarExtra {
            MenuBarContent(weeklyLimit: services.weeklyLimit)
        } label: {
            WeeklyLimitMenuBarLabel(limit: services.weeklyLimit.limit, icon: Image("MenuBarIcon"))
        }
        .menuBarExtraStyle(.window)
    }
}
