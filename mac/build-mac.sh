#!/usr/bin/env bash
#
# build-mac.sh — builds WordMeaning.app and WordMeaning.dmg. The Mac counterpart
# of build.ps1, and the same script CI runs, so a release is never assembled by
# hand out of steps nobody can repeat.
#
#   ./mac/build-mac.sh [version]
#
# Requires the Xcode command line tools (swift, sips, iconutil, hdiutil,
# codesign) and python3, all present on a stock macOS with Xcode installed.
#
# Signing, in the order it is attempted:
#   * CODESIGN_IDENTITY set     -> a real Developer ID signature, hardened runtime.
#   * NOTARY_* also set         -> submitted to Apple for notarization and stapled.
#   * neither                   -> ad-hoc signature ("-"). Required on Apple
#                                  Silicon, where an unsigned binary will not run
#                                  at all, but Gatekeeper still warns the user.
set -euo pipefail

VERSION="${1:-0.0.0-dev}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACDIR="$ROOT/mac"
BUILD="$MACDIR/.build"
DIST="$MACDIR/dist"
APP="$DIST/WordMeaning.app"
DICT="$ROOT/assets/dictionary.dat"

# Ahk2Exe embeds the dictionary at compile time on Windows and refuses to start
# without it; the same rule applies here, because an .app with no dictionary is a
# program that can answer nothing.
if [[ ! -f "$DICT" ]]; then
    echo "error: $DICT is missing. Generate it first:" >&2
    echo "       pwsh ./scripts/build-dictionary.ps1" >&2
    exit 1
fi

echo "==> Building WordMeaning $VERSION (universal: arm64 + x86_64)"
rm -rf "$DIST"
mkdir -p "$DIST"
swift build --package-path "$MACDIR" -c release --arch arm64 --arch x86_64

BIN="$(swift build --package-path "$MACDIR" -c release --arch arm64 --arch x86_64 --show-bin-path)"

echo "==> Assembling the bundle"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/WordMeaning" "$APP/Contents/MacOS/WordMeaning"
# The dictionary is read from here and memory-mapped, never copied or written.
cp "$DICT" "$APP/Contents/Resources/dictionary.dat"
sed "s/@VERSION@/$VERSION/g" "$MACDIR/Resources/Info.plist" > "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "==> Icon"
ICONSET="$BUILD/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
python3 "$MACDIR/ico2png.py" "$ROOT/assets/wordmeaning.ico" "$BUILD/icon.png"
# The source frame is 256px, so the two largest sizes are upscaled. Regenerate
# assets/wordmeaning.ico at 512px if that ever looks soft on a Retina display.
for size in 16 32 64 128 256 512; do
    sips -z $size $size "$BUILD/icon.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z $double $double "$BUILD/icon.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

echo "==> Signing"
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    codesign --force --deep --options runtime --timestamp \
             --sign "$CODESIGN_IDENTITY" "$APP"
    echo "    signed with $CODESIGN_IDENTITY"
else
    # Ad-hoc. Apple Silicon refuses to launch an unsigned binary outright, so this
    # is not optional even for an unnotarized build.
    codesign --force --deep --sign - "$APP"
    echo "    ad-hoc signed (no CODESIGN_IDENTITY set)"
fi
codesign --verify --strict --verbose=2 "$APP"

if [[ -n "${CODESIGN_IDENTITY:-}" && -n "${NOTARY_APPLE_ID:-}" \
      && -n "${NOTARY_PASSWORD:-}" && -n "${NOTARY_TEAM_ID:-}" ]]; then
    echo "==> Notarizing"
    ZIP="$BUILD/WordMeaning-notarize.zip"
    ditto -c -k --keepParent "$APP" "$ZIP"
    xcrun notarytool submit "$ZIP" \
        --apple-id "$NOTARY_APPLE_ID" \
        --password "$NOTARY_PASSWORD" \
        --team-id "$NOTARY_TEAM_ID" \
        --wait
    xcrun stapler staple "$APP"
    echo "    notarized and stapled"
else
    echo "==> Notarization skipped (no Developer ID credentials in the environment)"
fi

echo "==> Disk image"
DMG="$DIST/WordMeaning.dmg"
STAGE="$BUILD/dmg"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"      # the usual drag-to-install layout
hdiutil create -volname "WordMeaning" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null

echo
echo "Built:"
echo "  $APP"
echo "  $DMG  ($(du -h "$DMG" | cut -f1))"
