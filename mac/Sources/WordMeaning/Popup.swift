// Popup.swift — the definition panel at the cursor. Counterpart of src/Popup.ahk.
//
// A borderless, non-activating NSPanel: it must never take focus, or the click that
// selected the word would pull the user out of what they were reading. The material
// is a vibrancy view, so the popup follows Light and Dark Mode without a second
// palette to keep in step.
import AppKit
import WordMeaningCore

final class Popup {
    static let shared = Popup()

    private var panel: NSPanel?
    private var label: NSTextField?
    private var hideTimer: Timer?
    private(set) var isVisible = false

    /// Called when the popup appears or disappears, so the web-search hotkey can
    /// exist only while there is something on screen to search for.
    var onVisibilityChange: ((Bool) -> Void)?

    func show(_ text: String) {
        let wrapped = TextWrap.wrap(text, width: Config.popupWrapWidth)
        let panel = ensurePanel()

        label?.stringValue = wrapped
        label?.sizeToFit()

        let size = contentSize(for: wrapped)
        panel.setContentSize(size)
        panel.setFrameOrigin(origin(for: size))
        panel.orderFrontRegardless()        // never makeKey: focus stays where it was

        setVisible(true)
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: Config.tooltipTimeoutSec,
                                         repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    func hide() {
        hideTimer?.invalidate()
        hideTimer = nil
        panel?.orderOut(nil)
        setVisible(false)
    }

    private func setVisible(_ value: Bool) {
        guard value != isVisible else { return }
        isVisible = value
        onVisibilityChange?(value)
    }

    // MARK: - Panel

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }

        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 80),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true      // it is a tooltip, not a target
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let effect = NSVisualEffectView()
        effect.material = .popover
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 8
        effect.layer?.masksToBounds = true

        let field = NSTextField(labelWithString: "")
        field.font = .systemFont(ofSize: 13)
        field.textColor = .labelColor
        field.backgroundColor = .clear
        field.isBezeled = false
        field.isEditable = false
        field.isSelectable = false
        field.lineBreakMode = .byClipping    // wrapping is done in TextWrap
        field.maximumNumberOfLines = 0
        field.translatesAutoresizingMaskIntoConstraints = false

        effect.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: effect.leadingAnchor, constant: 10),
            field.trailingAnchor.constraint(equalTo: effect.trailingAnchor, constant: -10),
            field.topAnchor.constraint(equalTo: effect.topAnchor, constant: 8),
            field.bottomAnchor.constraint(equalTo: effect.bottomAnchor, constant: -8)
        ])

        panel.contentView = effect
        self.panel = panel
        self.label = field
        return panel
    }

    private func contentSize(for text: String) -> NSSize {
        let font = NSFont.systemFont(ofSize: 13)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        var width: CGFloat = 0
        var lines = 0
        for line in text.components(separatedBy: "\n") {
            let w = (line as NSString).size(withAttributes: attributes).width
            width = max(width, w)
            lines += 1
        }
        let lineHeight = font.boundingRectForFont.height + 2
        return NSSize(width: min(width + 20, 520).rounded(.up),
                      height: (CGFloat(lines) * lineHeight + 16).rounded(.up))
    }

    /// Below and right of the cursor, like the Windows tooltip, then pulled back
    /// onto the screen it is on if that would push it off an edge.
    private func origin(for size: NSSize) -> NSPoint {
        let mouse = NSEvent.mouseLocation
        var x = mouse.x + 12
        var y = mouse.y - 16 - size.height      // macOS y grows upwards

        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            x = min(x, frame.maxX - size.width - 8)
            x = max(x, frame.minX + 8)
            if y < frame.minY + 8 {
                y = mouse.y + 16                // no room below: flip above the cursor
            }
            y = min(y, frame.maxY - size.height - 8)
        }
        return NSPoint(x: x.rounded(), y: y.rounded())
    }
}
