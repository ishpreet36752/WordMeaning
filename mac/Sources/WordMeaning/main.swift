// main.swift — process entry point.
//
// No storyboard, no nib: an accessory app that owns one status item and one panel
// needs neither. The delegate is retained here for the life of the process.
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
