// TextWrap.swift — the popup's word wrapping, port of Popup._Wrap in src/Popup.ahk.
//
// AppKit could wrap the text itself, but the popup is deliberately a narrow column
// rather than a paragraph as wide as the screen, and the Windows build fixes that
// column in characters. Wrapping here keeps both platforms showing the same shape
// for the same definition, and keeps the logic testable without a window server.
import Foundation

public enum TextWrap {
    /// Wrap each existing line to at most `width` characters, breaking at spaces.
    /// A single word longer than the width is left alone rather than cut.
    public static func wrap(_ text: String, width: Int) -> String {
        text.components(separatedBy: "\n")
            .map { wrapLine($0, width: width) }
            .joined(separator: "\n")
    }

    static func wrapLine(_ line: String, width: Int) -> String {
        var result = ""
        var current = ""
        for word in line.components(separatedBy: " ") {
            if current.isEmpty {
                current = word
            } else if current.count + 1 + word.count <= width {
                current += " " + word
            } else {
                result += (result.isEmpty ? "" : "\n") + current
                current = word
            }
        }
        if !current.isEmpty {
            result += (result.isEmpty ? "" : "\n") + current
        }
        return result
    }
}
