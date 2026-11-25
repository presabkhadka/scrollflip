import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(clicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        refresh()

        // Keep the icon in sync if the setting is changed elsewhere (e.g. System Settings).
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(externalChange),
            name: Notification.Name("SwipeScrollDirectionDidChangeNotification"), object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(externalChange),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    @objc private func externalChange() {
        DispatchQueue.main.async { self.refresh() }
    }

    @objc private func clicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        let wantsMenu = event.type == .rightMouseUp
            || event.modifierFlags.contains(.option)
            || event.modifierFlags.contains(.control)
        if wantsMenu {
            showMenu()
        } else {
            ScrollDirection.toggle()
            refresh()
        }
    }

    private func refresh() {
        let natural = ScrollDirection.isNatural
        let symbol = natural ? "hand.draw" : "computermouse"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Natural scrolling")
        image?.isTemplate = true
        statusItem.button?.image = image
        var tip = "Natural scrolling: \(natural ? "On" : "Off") — click to toggle, right-click for menu"
        if !ScrollDirection.appliesLive { tip += "\n(Log out to apply changes)" }
        statusItem.button?.toolTip = tip
    }

    private func showMenu() {
        let menu = NSMenu()

        let natural = NSMenuItem(title: "Natural Scrolling", action: #selector(toggleFromMenu), keyEquivalent: "")
        natural.target = self
        natural.state = ScrollDirection.isNatural ? .on : .off
        menu.addItem(natural)

        if !ScrollDirection.appliesLive {
            let note = NSMenuItem(title: "Log out to apply changes", action: nil, keyEquivalent: "")
            note.isEnabled = false
            menu.addItem(note)
        }

        menu.addItem(.separator())

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit ScrollFlip", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // Attach temporarily so left-click keeps toggling instead of opening the menu.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleFromMenu() {
        ScrollDirection.toggle()
        refresh()
    }

    @objc private func toggleLogin() {
        LoginItem.setEnabled(!LoginItem.isEnabled)
    }
}
