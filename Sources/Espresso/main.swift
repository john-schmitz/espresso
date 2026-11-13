import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var caffeinateProcess: Process?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopCaffeinate()
    }

    /// Called from the SIGTERM handler (e.g. when launchd stops us) so the
    /// child caffeinate process doesn't get orphaned and leave the Mac awake.
    func shutdown() {
        stopCaffeinate()
    }

    // MARK: - Status item

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        guard let button = item.button else { return }
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateAppearance()
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggle()
        }
    }

    // MARK: - Context menu

    private func showContextMenu() {
        guard let statusItem, let button = statusItem.button else { return }

        let menu = NSMenu()

        let stateItem = NSMenuItem(
            title: isActive ? "Espresso is ON — your Mac won't sleep" : "Espresso is OFF",
            action: nil,
            keyEquivalent: ""
        )
        stateItem.isEnabled = false
        menu.addItem(stateItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Espresso",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        button.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Toggle

    private var isActive: Bool {
        caffeinateProcess?.isRunning ?? false
    }

    private func toggle() {
        isActive ? stopCaffeinate() : startCaffeinate()
    }

    private func startCaffeinate() {
        guard caffeinateProcess == nil else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-imdsu"]
        process.terminationHandler = { [weak self] terminatedProcess in
            DispatchQueue.main.async {
                guard let self, self.caffeinateProcess === terminatedProcess else { return }
                self.caffeinateProcess = nil
                self.updateAppearance()
            }
        }

        do {
            try process.run()
            caffeinateProcess = process
            updateAppearance()
        } catch {
            caffeinateProcess = nil
            presentError(error)
        }
    }

    private func stopCaffeinate() {
        guard let process = caffeinateProcess else { return }
        caffeinateProcess = nil
        if process.isRunning {
            process.terminate()
        }
        updateAppearance()
    }

    private func presentError(_ error: Error) {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Couldn't start caffeinate"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }

    // MARK: - Appearance

    private func updateAppearance() {
        guard let button = statusItem?.button else { return }
        let symbolName = isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Espresso")
        image?.isTemplate = true
        button.image = image
        button.appearsDisabled = !isActive
        button.toolTip = isActive
            ? "Espresso is ON — click to let your Mac sleep again"
            : "Espresso is OFF — click to keep your Mac awake"
    }
}

// MARK: - Entry point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)

// Clean up the child process if we're stopped by launchd (SIGTERM).
let sigterm = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
sigterm.setEventHandler {
    delegate.shutdown()
    exit(0)
}
sigterm.resume()

app.run()
