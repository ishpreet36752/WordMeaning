// AppDelegate.swift — entry wiring, menu bar item, enable/disable state.
// Counterpart of src/Main.ahk.
//
// Flow: SelectionWatcher → onSelection (word filter) → DictionaryService.lookup →
//       Popup.show.
// Dismiss: SelectionWatcher's press callback (click anywhere) and FocusWatcher
//       (app switch) → Popup.hide; plus the 6s auto-hide timer.
// Web fallback: the hot key is registered only while a popup is visible, so it
//       cannot shadow Command+Shift+D in the app being read.
//
// The one thing Windows does not need: macOS will not let anything watch events or
// read another app's selection until the user grants Accessibility access, so the
// app starts in a waiting state and begins watching the moment permission appears.
import AppKit
import ApplicationServices
import WordMeaningCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let dictionary = DictionaryService.shared
    private let lookupQueue = DispatchQueue(label: "io.github.wordmeaning.lookup", qos: .userInitiated)

    private var enabled = true
    private var lastWord = ""           // word in the current popup — target of the hot key
    private var permissionTimer: Timer?
    private var watching = false

    // Menu items kept around so their check marks can be flipped.
    private var enabledItem: NSMenuItem?
    private var loginItem: NSMenuItem?
    private var onlineItem: NSMenuItem?
    private var permissionItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
        buildStatusItem()

        Popup.shared.onVisibilityChange = { visible in
            // The hot key exists only while there is a popup to act on.
            if visible {
                WebSearchHotkey.shared.register()
            } else {
                WebSearchHotkey.shared.unregister()
            }
        }
        WebSearchHotkey.shared.onFire = { [weak self] in self?.openWebSearch() }

        FocusWatcher.shared.start { Popup.shared.hide() }

        requestAccessibilityIfNeeded()
        startWatchingIfPermitted()
    }

    func applicationWillTerminate(_ notification: Notification) {
        SelectionWatcher.shared.stop()
        FocusWatcher.shared.stop()
        WebSearchHotkey.shared.unregister()
        permissionTimer?.invalidate()
    }

    // MARK: - Accessibility permission

    /// Prompts once on first launch. macOS shows its own dialog and remembers the
    /// answer; nothing here can grant the right, only ask for it.
    private func requestAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func startWatchingIfPermitted() {
        guard !watching else { return }
        guard AXIsProcessTrusted() else {
            permissionItem?.isHidden = false
            statusItem?.button?.appearsDisabled = true
            schedulePermissionPoll()
            return
        }

        watching = true
        permissionTimer?.invalidate()
        permissionTimer = nil
        permissionItem?.isHidden = true
        statusItem?.button?.appearsDisabled = false

        SelectionWatcher.shared.start(
            onSelect: { [weak self] text in self?.onSelection(text) },
            onPress: { Popup.shared.hide() }        // clicking anywhere dismisses
        )
    }

    /// Granting access does not notify anyone, so this re-checks quietly until it
    /// is there. It stops the moment watching starts.
    private func schedulePermissionPoll() {
        guard permissionTimer == nil else { return }
        permissionTimer = Timer.scheduledTimer(withTimeInterval: Config.permissionPollSec,
                                               repeats: true) { [weak self] _ in
            self?.startWatchingIfPermitted()
        }
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url { NSWorkspace.shared.open(url) }
    }

    // MARK: - Lookup

    private func onSelection(_ text: String) {
        guard enabled else { return }
        // Single words only — sentences and fragments are ignored silently.
        guard DictionaryService.isSingleWord(text) else { return }

        lookupQueue.async { [weak self] in
            guard let self else { return }
            let result = self.dictionary.lookup(text)
            guard let body = PopupText.compose(result) else { return }
            DispatchQueue.main.async {
                guard self.enabled else { return }
                self.lastWord = result.word
                Popup.shared.show(body)
            }
        }
    }

    private func openWebSearch() {
        Popup.shared.hide()
        guard !lastWord.isEmpty else { return }
        let url = URL(string: Config.webSearchUrl + DictionaryService.urlEncode(lastWord))
        if let url { NSWorkspace.shared.open(url) }
    }

    // MARK: - Menu bar

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "character.book.closed",
                                   accessibilityDescription: Config.appName)
            button.image?.isTemplate = true
            button.toolTip = "\(Config.appName) — select a word to see its meaning"
        }

        let menu = NSMenu()

        let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledItem.target = self
        enabledItem.state = .on
        menu.addItem(enabledItem)

        let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(loginItem)

        // Session-only, deliberately not remembered: enabling the network is a
        // decision the user should re-make, not one a preferences file makes.
        let onlineItem = NSMenuItem(title: Config.onlineMenuText, action: #selector(toggleOnline), keyEquivalent: "")
        onlineItem.target = self
        onlineItem.state = dictionary.onlineFallback ? .on : .off
        menu.addItem(onlineItem)

        menu.addItem(.separator())

        let permissionItem = NSMenuItem(title: "Grant Accessibility access…",
                                        action: #selector(openAccessibilitySettings), keyEquivalent: "")
        permissionItem.target = self
        permissionItem.isHidden = true
        menu.addItem(permissionItem)

        let aboutItem = NSMenuItem(title: "About \(Config.appName)", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        self.statusItem = item
        self.enabledItem = enabledItem
        self.loginItem = loginItem
        self.onlineItem = onlineItem
        self.permissionItem = permissionItem
    }

    @objc private func toggleEnabled() {
        enabled.toggle()
        enabledItem?.state = enabled ? .on : .off
        if !enabled { Popup.shared.hide() }
    }

    @objc private func toggleLoginItem() {
        loginItem?.state = LoginItem.toggle() ? .on : .off
    }

    /// Words that missed while offline-only must be retried once the network is
    /// allowed, so the session cache goes with the switch.
    @objc private func toggleOnline() {
        dictionary.onlineFallback.toggle()
        dictionary.clearCache()
        onlineItem?.state = dictionary.onlineFallback ? .on : .off
    }

    /// The primary online source is CC BY-SA 4.0 and WordNet requires its notice
    /// be reproduced, so this text is not decoration.
    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = Config.appName
        alert.informativeText = Config.attributionText
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
