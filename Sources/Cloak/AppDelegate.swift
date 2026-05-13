import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var overlayController: ClockOverlayController?
    private var settingsController: SettingsWindowController?
    private let prefs = Preferences.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlayController = ClockOverlayController(prefs: prefs)
        setupStatusItem()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "clock.fill",
                accessibilityDescription: "Cloak"
            )
            button.image?.isTemplate = true
        }
        item.menu = buildMenu()
        statusItem = item
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "設定…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Cloak を終了",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        for item in menu.items {
            item.target = self
        }
        return menu
    }

    @objc private func openSettings() {
        if settingsController == nil {
            let controller = SettingsWindowController(prefs: prefs)
            controller.onClose = { [weak self] in
                self?.settingsController = nil
            }
            settingsController = controller
        }
        settingsController?.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
