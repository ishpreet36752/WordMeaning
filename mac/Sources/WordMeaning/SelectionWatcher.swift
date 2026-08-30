// SelectionWatcher.swift — detects text selection (drag or double-click) anywhere
// on the desktop and reads it. Counterpart of src/SelectionWatcher.ahk.
//
// Two differences from the Windows build, both forced by the platform:
//
//  * macOS has a real API for this. The Accessibility API can hand back the focused
//    element's selected text directly (kAXSelectedTextAttribute), so the usual path
//    never touches the pasteboard at all — strictly better than the Windows Ctrl+C
//    probe. Apps that do not expose it (many Electron and Java apps, some PDF
//    readers) fall back to a Cmd+C probe that saves and restores the pasteboard,
//    which is the Windows behaviour exactly.
//
//  * Global event monitors require Accessibility permission, so nothing is watched
//    until the user grants it in System Settings. AppDelegate handles that prompt.
import AppKit
import ApplicationServices
import WordMeaningCore

final class SelectionWatcher {
    static let shared = SelectionWatcher()

    private var onSelect: ((String) -> Void)?
    private var onPress: (() -> Void)?
    private var downMonitor: Any?
    private var upMonitor: Any?
    private var pressPoint = NSPoint.zero
    private var lastClickTime: TimeInterval = 0

    /// onSelect: the captured selection (may be multi-word; the caller filters).
    /// onPress:  fired on every left-button press, before the selection resolves,
    ///           so clicking anywhere dismisses a stale popup.
    func start(onSelect: @escaping (String) -> Void, onPress: @escaping () -> Void) {
        stop()
        self.onSelect = onSelect
        self.onPress = onPress

        downMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            self?.handleDown()
        }
        upMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.handleUp(event)
        }
    }

    func stop() {
        if let downMonitor { NSEvent.removeMonitor(downMonitor) }
        if let upMonitor { NSEvent.removeMonitor(upMonitor) }
        downMonitor = nil
        upMonitor = nil
    }

    private func handleDown() {
        pressPoint = NSEvent.mouseLocation
        onPress?()
    }

    private func handleUp(_ event: NSEvent) {
        let now = NSEvent.mouseLocation
        let dragged = abs(now.x - pressPoint.x) > Config.dragThresholdPx
            || abs(now.y - pressPoint.y) > Config.dragThresholdPx

        // clickCount is authoritative here; the timestamp check mirrors the Windows
        // build for the rare event that arrives without one.
        let stamp = Date().timeIntervalSince1970
        let doubleClick = event.clickCount >= 2
            || (stamp - lastClickTime) < Config.doubleClickInterval
        lastClickTime = stamp

        guard dragged || doubleClick else { return }

        // Double-click selection needs a beat for the app to apply word-select.
        let delay = doubleClick ? Config.doubleClickSettleSec : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            let text = self.captureSelection()
            guard !text.isEmpty else { return }
            self.onSelect?(text)
        }
    }

    // MARK: - Capture

    /// Accessibility first, pasteboard probe second. Returns "" when there is
    /// nothing selected (an empty click, a password field, a canvas).
    private func captureSelection() -> String {
        if let text = accessibilitySelection(), !text.isEmpty { return text }
        return pasteboardProbe()
    }

    /// Ask the focused UI element for its selected text. No pasteboard, no
    /// synthetic keystroke, no side effects at all.
    private func accessibilitySelection() -> String? {
        let system = AXUIElementCreateSystemWide()

        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system,
                                            kAXFocusedUIElementAttribute as CFString,
                                            &focused) == .success,
              let element = focused else { return nil }
        // CFTypeRef -> AXUIElement: the attribute is documented to return one.
        guard CFGetTypeID(element) == AXUIElementGetTypeID() else { return nil }
        let axElement = unsafeBitCast(element, to: AXUIElement.self)

        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axElement,
                                            kAXSelectedTextAttribute as CFString,
                                            &value) == .success,
              let text = value as? String else { return nil }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Copies the current selection while preserving the user's pasteboard.
    /// The pasteboard is always put back, including when the copy fails — that
    /// invariant is the same one the Windows build keeps.
    private func pasteboardProbe() -> String {
        let pasteboard = NSPasteboard.general
        let saved = savePasteboard(pasteboard)
        let changeCountBefore = pasteboard.changeCount
        pasteboard.clearContents()

        sendCommandC()

        var captured = ""
        let deadline = Date().addingTimeInterval(Config.clipWaitSec)
        while Date() < deadline {
            if pasteboard.changeCount != changeCountBefore,
               let s = pasteboard.string(forType: .string) {
                captured = s
                break
            }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }

        restorePasteboard(saved, to: pasteboard)
        return captured.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sendCommandC() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let vKeyC: CGKeyCode = 8    // kVK_ANSI_C
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKeyC, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: vKeyC, keyDown: false)
        else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private struct SavedPasteboard {
        let items: [[NSPasteboard.PasteboardType: Data]]
    }

    private func savePasteboard(_ pasteboard: NSPasteboard) -> SavedPasteboard {
        var saved: [[NSPasteboard.PasteboardType: Data]] = []
        for item in pasteboard.pasteboardItems ?? [] {
            var copy: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) { copy[type] = data }
            }
            if !copy.isEmpty { saved.append(copy) }
        }
        return SavedPasteboard(items: saved)
    }

    private func restorePasteboard(_ saved: SavedPasteboard, to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        guard !saved.items.isEmpty else { return }
        let items: [NSPasteboardItem] = saved.items.map { stored in
            let item = NSPasteboardItem()
            for (type, data) in stored { item.setData(data, forType: type) }
            return item
        }
        pasteboard.writeObjects(items)
    }
}
