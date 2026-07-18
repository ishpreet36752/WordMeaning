param([string]$OutPath)
Add-Type -AssemblyName System.Drawing

# Draw one size: rounded blue tile + white "W" (WordMeaning)
function New-Tile([int]$s) {
    $bmp = New-Object System.Drawing.Bitmap($s, $s, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.Clear([System.Drawing.Color]::Transparent)

    $r = [Math]::Max(2, [int]($s * 0.18))
    $pad = [Math]::Max(0, [int]($s * 0.04))
    $x = $pad; $y = $pad; $w = $s - 2*$pad - 1; $h = $s - 2*$pad - 1
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()

    $rect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
    $c1 = [System.Drawing.Color]::FromArgb(255, 37, 99, 235)
    $c2 = [System.Drawing.Color]::FromArgb(255, 29, 78, 216)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, 90)
    $g.FillPath($brush, $path)

    $fontSize = $s * 0.60
    $font = New-Object System.Drawing.Font('Segoe UI', $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = 'Center'
    $sf.LineAlignment = 'Center'
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $layout = [System.Drawing.RectangleF]::new([single]0, [single](-$s*0.04), [single]$s, [single]$s)
    $g.DrawString('W', $font, $white, $layout, $sf)

    $g.Dispose()
    return $bmp
}

# Convert a Bitmap to a DIB blob for ICO (BITMAPINFOHEADER + bottom-up BGRA + AND mask)
function Get-DibBytes([System.Drawing.Bitmap]$bmp) {
    $w = $bmp.Width; $h = $bmp.Height
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $bd = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $bd.Stride
    $buf = New-Object byte[] ($stride * $h)
    [System.Runtime.InteropServices.Marshal]::Copy($bd.Scan0, $buf, 0, $buf.Length)
    $bmp.UnlockBits($bd)

    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    # BITMAPINFOHEADER
    $bw.Write([UInt32]40)          # biSize
    $bw.Write([Int32]$w)           # biWidth
    $bw.Write([Int32]($h * 2))     # biHeight = XOR + AND stacked
    $bw.Write([UInt16]1)           # biPlanes
    $bw.Write([UInt16]32)          # biBitCount
    $bw.Write([UInt32]0)           # biCompression = BI_RGB
    $bw.Write([UInt32]0)           # biSizeImage
    $bw.Write([Int32]0); $bw.Write([Int32]0)  # ppm x/y
    $bw.Write([UInt32]0); $bw.Write([UInt32]0) # clrUsed / clrImportant

    # XOR: 32bpp BGRA, bottom-up
    for ($row = $h - 1; $row -ge 0; $row--) {
        $bw.Write($buf, $row * $stride, $w * 4)
    }
    # AND mask: 1bpp, all zero (alpha handles transparency), rows padded to 4 bytes
    $maskRow = [int]([Math]::Floor(($w + 31) / 32)) * 4
    $zeros = New-Object byte[] ($maskRow * $h)
    $bw.Write($zeros)

    $bw.Flush()
    return ,$ms.ToArray()   # unary comma: emit the byte[] as ONE object, no unrolling
}

$sizes = @(16, 24, 32, 48, 64, 128, 256)
$dibs = @()
foreach ($sz in $sizes) {
    $b = New-Tile $sz
    $dibs += ,(Get-DibBytes $b)
    $b.Dispose()
}

$fs = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($fs)
$bw.Write([UInt16]0)              # reserved
$bw.Write([UInt16]1)              # type = icon
$bw.Write([UInt16]$sizes.Count)

$offset = 6 + (16 * $sizes.Count)
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $sz = $sizes[$i]; $data = $dibs[$i]
    $dim = if ($sz -ge 256) { 0 } else { $sz }
    $bw.Write([Byte]$dim)
    $bw.Write([Byte]$dim)
    $bw.Write([Byte]0)
    $bw.Write([Byte]0)
    $bw.Write([UInt16]1)
    $bw.Write([UInt16]32)
    $bw.Write([UInt32]$data.Length)
    $bw.Write([UInt32]$offset)
    $offset += $data.Length
}
foreach ($data in $dibs) { $bw.Write($data) }
$bw.Flush()

[System.IO.File]::WriteAllBytes($OutPath, $fs.ToArray())
$fs.Dispose()
Write-Output "wrote $OutPath ($((Get-Item $OutPath).Length) bytes, $($sizes.Count) sizes, DIB)"
