// LoginItem.swift — the optional "Start at Login" toggle. Counterpart of
// src/Startup.ahk, which writes the per-user HKCU Run key on Windows.
//
// SMAppService registers the app itself with the current user's login items. Like
// the Windows version it touches nothing machine-wide, needs no administrator, and
// stores only the fact that this app should launch — never anything looked up.
import Foundation
import ServiceManagement

enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Flip the state and return what it ended up as. Registration fails when the
    /// binary is not in a proper .app bundle (a `swift run` build, for instance),
    /// which is reported rather than crashed on.
    @discardableResult
    static func toggle() -> Bool {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("WordMeaning: could not change the login item: \(error.localizedDescription)")
        }
        return isEnabled
    }
}
