// WebSearchHotkey.swift — Command+Shift+D, live only while a popup is on screen.
//
// The Windows build gets this from AHK's `HotIf Popup.IsVisible()`: the hotkey
// exists only while there is a popup, so it cannot shadow the same combination in
// the app being read. A Carbon hot key gives the same property here — it is
// registered when the popup appears and unregistered when it goes away, so the rest
// of the time the combination belongs entirely to whatever the user is using.
//
// A global NSEvent monitor would have been shorter, but it cannot swallow the key,
// so Command+Shift+D would still reach the app underneath while the popup is up.
import AppKit
import Carbon.HIToolbox
import WordMeaningCore

final class WebSearchHotkey {
    static let shared = WebSearchHotkey()

    /// 'WMNG' — the four-character signature Carbon uses to tell hot keys apart.
    private static let signature: OSType = 0x574D_4E47

    private var hotKeyRef: EventHotKeyRef?
    private var handlerInstalled = false

    /// Called on the main thread when the combination is pressed.
    var onFire: (() -> Void)?

    func register() {
        installHandlerIfNeeded()
        guard hotKeyRef == nil else { return }

        let id = EventHotKeyID(signature: WebSearchHotkey.signature, id: 1)
        let modifiers = UInt32(cmdKey | shiftKey)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(Config.webSearchKeyCode, modifiers, id,
                                         GetApplicationEventTarget(), 0, &ref)
        if status == noErr {
            hotKeyRef = ref
        } else {
            NSLog("WordMeaning: could not register the web-search hot key (\(status))")
        }
    }

    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        hotKeyRef = nil
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        // The callback is a C function pointer, so it captures nothing and reaches
        // the singleton directly.
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, _, _ -> OSStatus in
            DispatchQueue.main.async { WebSearchHotkey.shared.onFire?() }
            return noErr
        }, 1, &spec, nil, nil)
        handlerInstalled = (status == noErr)
    }
}
