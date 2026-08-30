#!/usr/bin/env python3
"""Extract the largest image from assets/wordmeaning.ico as a PNG.

The Mac build needs an .icns and the only icon in the repository is a Windows
.ico, so this pulls the 256x256 frame out of it. Standard library only (zlib is
all a PNG writer needs) — a build that has to `pip install` something to draw an
icon is a build that breaks the first time a runner image changes.

Usage: python3 mac/ico2png.py assets/wordmeaning.ico build/icon.png
"""
import struct
import sys
import zlib


def read_ico(path):
    data = open(path, "rb").read()
    reserved, image_type, count = struct.unpack("<HHH", data[:6])
    if reserved != 0 or count == 0:
        raise SystemExit(f"{path}: not an ICO file")

    entries = []
    for i in range(count):
        off = 6 + 16 * i
        width, height, colors, _r, planes, bpp, size, offset = struct.unpack(
            "<BBBBHHII", data[off:off + 16])
        entries.append({
            "width": width or 256,
            "height": height or 256,
            "size": size,
            "offset": offset,
        })
    best = max(entries, key=lambda e: e["width"] * e["height"])
    return data[best["offset"]:best["offset"] + best["size"]], best


def bmp_to_rgba(blob, entry):
    """The frame is a BITMAPINFOHEADER DIB: no file header, height doubled by the
    AND mask, rows bottom-up, pixels BGRA."""
    if blob[:8] == b"\x89PNG\r\n\x1a\n":
        return None, None, None                      # already a PNG frame
    header_size, width, height, planes, bpp = struct.unpack("<IiiHH", blob[:16])
    if header_size < 40:
        raise SystemExit("unsupported icon frame: not a BITMAPINFOHEADER")
    if bpp != 32:
        raise SystemExit(f"unsupported icon frame: {bpp} bits per pixel, expected 32")
    height //= 2                                     # the second half is the AND mask
    pixels = blob[header_size:header_size + width * height * 4]

    rows = []
    stride = width * 4
    for y in range(height - 1, -1, -1):              # bottom-up to top-down
        row = pixels[y * stride:(y + 1) * stride]
        out = bytearray(stride)
        out[0::4] = row[2::4]                        # B G R A -> R G B A
        out[1::4] = row[1::4]
        out[2::4] = row[0::4]
        out[3::4] = row[3::4]
        rows.append(bytes(out))
    return width, height, rows


def write_png(path, width, height, rows):
    def chunk(tag, payload):
        return (struct.pack(">I", len(payload)) + tag + payload
                + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF))

    raw = b"".join(b"\x00" + row for row in rows)    # filter byte 0 per scanline
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    open(path, "wb").write(png)


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    src, dst = sys.argv[1], sys.argv[2]
    blob, entry = read_ico(src)
    width, height, rows = bmp_to_rgba(blob, entry)
    if width is None:
        open(dst, "wb").write(blob)                  # the frame was a PNG already
        print(f"copied embedded PNG frame to {dst}")
        return
    write_png(dst, width, height, rows)
    print(f"wrote {dst} ({width}x{height})")


if __name__ == "__main__":
    main()
