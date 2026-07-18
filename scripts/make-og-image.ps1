param([string]$OutPath = "$PSScriptRoot\..\docs\assets\og.png")
Add-Type -AssemblyName System.Drawing

# Social-card image (1200x630) for og:image / twitter:image.
# Same Win95 grammar as docs/index.html: teal desktop, bevelled window, a real
# selection, a real tooltip. Regenerate after any landing-page visual change.

$W = 1200; $H = 630

# Palette mirrors :root in docs/index.html
function C([int]$r, [int]$g, [int]$b) { [System.Drawing.Color]::FromArgb(255, $r, $g, $b) }
$desk     = C 11 110 110    # --desk
$grey     = C 192 192 192   # --grey
$greyLit  = C 255 255 255   # --grey-lit
$greySoft = C 223 223 223   # --grey-soft
$greyMid  = C 128 128 128   # --grey-mid
$greyDk   = C 0 0 0         # --grey-dk
$navy     = C 0 0 128       # --navy
$paper    = C 255 255 255
$ink      = C 23 23 23      # --ink
$inkSoft  = C 74 74 77      # --ink-soft
$tipBg    = C 255 255 225   # classic tooltip cream

$bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.TextRenderingHint = 'AntiAliasGridFit'
$g.Clear($desk)

function New-Brush($color) { New-Object System.Drawing.SolidBrush($color) }
function New-Pen($color) { New-Object System.Drawing.Pen($color, 1) }

function Fill([int]$x, [int]$y, [int]$w, [int]$h, $color) {
    $b = New-Brush $color
    $g.FillRectangle($b, $x, $y, $w, $h)
    $b.Dispose()
}

# Win95 bevel. $raised = light top/left, dark bottom/right (a button/window).
# $raised = $false inverts it (a sunken well).
function Bevel([int]$x, [int]$y, [int]$w, [int]$h, [bool]$raised) {
    if ($raised) { $tl1 = $greyLit; $tl2 = $greySoft; $br1 = $greyDk; $br2 = $greyMid }
    else         { $tl1 = $greyMid; $tl2 = $greyDk;   $br1 = $greyLit; $br2 = $greySoft }
    $pTL1 = New-Pen $tl1; $pTL2 = New-Pen $tl2; $pBR1 = New-Pen $br1; $pBR2 = New-Pen $br2
    # outer
    $g.DrawLine($pTL1, $x, $y, $x + $w - 1, $y)
    $g.DrawLine($pTL1, $x, $y, $x, $y + $h - 1)
    $g.DrawLine($pBR1, $x, $y + $h - 1, $x + $w - 1, $y + $h - 1)
    $g.DrawLine($pBR1, $x + $w - 1, $y, $x + $w - 1, $y + $h - 1)
    # inner
    $g.DrawLine($pTL2, $x + 1, $y + 1, $x + $w - 2, $y + 1)
    $g.DrawLine($pTL2, $x + 1, $y + 1, $x + 1, $y + $h - 2)
    $g.DrawLine($pBR2, $x + 1, $y + $h - 2, $x + $w - 2, $y + $h - 2)
    $g.DrawLine($pBR2, $x + $w - 2, $y + 1, $x + $w - 2, $y + $h - 2)
    foreach ($p in @($pTL1, $pTL2, $pBR1, $pBR2)) { $p.Dispose() }
}

function New-Font([string]$family, [single]$size, [string]$style) {
    New-Object System.Drawing.Font($family, $size, [System.Drawing.FontStyle]$style, [System.Drawing.GraphicsUnit]::Pixel)
}

# GenericTypographic: no trailing padding, so measured widths chain correctly.
$fmt = [System.Drawing.StringFormat]::GenericTypographic.Clone()
$fmt.FormatFlags = $fmt.FormatFlags -bor [System.Drawing.StringFormatFlags]::MeasureTrailingSpaces

function Get-TextWidth([string]$text, $font) {
    return $g.MeasureString($text, $font, [System.Drawing.PointF]::new(0, 0), $fmt).Width
}

function Draw([string]$text, $font, $color, [single]$x, [single]$y) {
    $b = New-Brush $color
    $g.DrawString($text, $font, $b, [System.Drawing.PointF]::new($x, $y), $fmt)
    $b.Dispose()
    return $x + (Get-TextWidth $text $font)
}

# ---------- the window ----------
$winX = 110; $winY = 74; $winW = 980; $winH = 302
Fill $winX $winY $winW $winH $grey
Bevel $winX $winY $winW $winH $true

# titlebar
$tbX = $winX + 4; $tbY = $winY + 4; $tbW = $winW - 8; $tbH = 30
Fill $tbX $tbY $tbW $tbH $navy
$fTitle = New-Font 'Tahoma' 17 'Bold'
[void](Draw 'WordMeaning' $fTitle ([System.Drawing.Color]::White) ($tbX + 8) ($tbY + 6))

# close box, top right
$cbS = 22; $cbX = $tbX + $tbW - $cbS - 4; $cbY = $tbY + 4
Fill $cbX $cbY $cbS $cbS $grey
Bevel $cbX $cbY $cbS $cbS $true
$fClose = New-Font 'Tahoma' 14 'Bold'
[void](Draw 'x' $fClose $greyDk ($cbX + 7) ($cbY + 3))

# ---------- the page being read ----------
$pX = $winX + 16; $pY = $tbY + $tbH + 12; $pW = $winW - 32; $pH = $winH - ($pY - $winY) - 16
Fill $pX $pY $pW $pH $paper
Bevel $pX $pY $pW $pH $false

$fBody = New-Font 'Segoe UI' 34 'Regular'
$textX = $pX + 40
$lineY = $pY + 44

# Line 1, with one word selected. Selection = navy block, white text (Win95 highlight).
$pre = 'Their fame proved '
$sel = 'ephemeral'
$post = ', but the'
$x = [single]$textX
$x = Draw $pre $fBody $ink $x $lineY

$selW = Get-TextWidth $sel $fBody
$selX = $x
Fill ([int]$selX) ([int]($lineY - 2)) ([int][Math]::Ceiling($selW)) 44 $navy
$x = Draw $sel $fBody ([System.Drawing.Color]::White) $x $lineY
[void](Draw $post $fBody $ink $x $lineY)
[void](Draw 'story outlived every one of them.' $fBody $ink $textX ($lineY + 52))

# ---------- the tooltip, at the cursor under the selected word ----------
$fTip = New-Font 'Segoe UI' 25 'Regular'
$fTipWord = New-Font 'Segoe UI' 25 'Bold'
$tipWord = 'ephemeral '
$tipPos = '(adjective) '
$tipDef = 'lasting for a very short time'
$tipPad = 16
$tipW = [int]((Get-TextWidth $tipWord $fTipWord) + (Get-TextWidth $tipPos $fTip) + (Get-TextWidth $tipDef $fTip) + $tipPad * 2)
$tipH = 52
$tipX = [int]$selX - 6
$tipY = [int]$lineY + 62
if ($tipX + $tipW -gt $pX + $pW - 12) { $tipX = $pX + $pW - 12 - $tipW }

Fill $tipX $tipY $tipW $tipH $tipBg
$pTip = New-Pen $greyDk
$g.DrawRectangle($pTip, $tipX, $tipY, $tipW - 1, $tipH - 1)
$pTip.Dispose()

$tx = [single]($tipX + $tipPad)
$ty = [single]($tipY + 12)
$tx = Draw $tipWord $fTipWord $ink $tx $ty
$tx = Draw $tipPos $fTip $inkSoft $tx $ty
[void](Draw $tipDef $fTip $ink $tx $ty)

# mouse cursor sitting on the selection
$curX = [int]$selX + [int]($selW / 2); $curY = [int]$lineY + 34
$arrow = @(
    [System.Drawing.Point]::new($curX,      $curY),
    [System.Drawing.Point]::new($curX,      $curY + 22),
    [System.Drawing.Point]::new($curX + 6,  $curY + 16),
    [System.Drawing.Point]::new($curX + 10, $curY + 25),
    [System.Drawing.Point]::new($curX + 14, $curY + 23),
    [System.Drawing.Point]::new($curX + 10, $curY + 14),
    [System.Drawing.Point]::new($curX + 17, $curY + 14)
)
$bCur = New-Brush ([System.Drawing.Color]::White)
$pCur = New-Pen $greyDk
$g.FillPolygon($bCur, $arrow)
$g.DrawPolygon($pCur, $arrow)
$bCur.Dispose(); $pCur.Dispose()

# ---------- the claim, on the desktop ----------
$fLead = New-Font 'Segoe UI' 38 'Bold'
$fSub = New-Font 'Segoe UI' 27 'Regular'
$dot = "  $([char]0x00B7)  "   # middot, kept out of the source encoding
$lead = 'Select a word in any Windows app. See what it means.'
$sub  = "Free${dot}No account${dot}Nothing stored${dot}Browsers, PDFs, Word"
$leadW = Get-TextWidth $lead $fLead
$subW = Get-TextWidth $sub $fSub
[void](Draw $lead $fLead ([System.Drawing.Color]::White) (($W - $leadW) / 2) 434)
[void](Draw $sub $fSub (C 190 226 226) (($W - $subW) / 2) 494)

$OutPath = [System.IO.Path]::GetFullPath($OutPath)
$dir = [System.IO.Path]::GetDirectoryName($OutPath)
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
$g.Dispose()
$bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "wrote $OutPath ($((Get-Item $OutPath).Length) bytes, ${W}x${H})"
