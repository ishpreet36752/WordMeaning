// FocusWatcher.swift — fires a callback when the frontmost application changes,
// so a popup left over from the last app is dismissed. Counterpart of
// src/FocusWatcher.ahk, which polls the foreground window id on a timer.
//
// macOS hands this over as a notification, so there is no timer here. The
// granularity differs in the same way it does on Windows: switching between two
// windows (or tabs) of one app is not an app switch, and that case is covered by
// the click-to-dismiss path in SelectionWatcher and by the auto-hide timer.
import AppKit

final class FocusWatcher {
    static let shared = FocusWatcher()

    private var token: NSObjectProtocol?

    func start(onChange: @escaping () -> Void) {
        stop()
        token = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { _ in
            onChange()
        }
    }

    func stop() {
        if let token {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        token = nil
    }
}
