// swift-tools-version:5.9
//
// WordMeaning for macOS.
//
// Two targets on purpose. WordMeaningCore holds everything that can be tested
// without a window server — the packed dictionary, sense selection, wrapping —
// so CI can run the suite headlessly on a macos runner. The executable target
// is the AppKit shell: menu bar item, event monitors, the popup panel.
//
// The .app bundle is assembled by build-mac.sh, which copies the compiled binary,
// Info.plist and assets/dictionary.dat into place. `swift run` works for quick
// checks but has no bundle, so it falls back to reading the dictionary from the
// repository (see LocalDictionary.locateData).
import PackageDescription

let package = Package(
    name: "WordMeaning",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "WordMeaning", targets: ["WordMeaning"]),
        .library(name: "WordMeaningCore", targets: ["WordMeaningCore"])
    ],
    targets: [
        .target(name: "WordMeaningCore"),
        .executableTarget(name: "WordMeaning", dependencies: ["WordMeaningCore"]),
        .testTarget(name: "WordMeaningCoreTests", dependencies: ["WordMeaningCore"])
    ]
)
