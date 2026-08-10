# download-stats.ps1 - how many people have downloaded WordMeaning.
#
# The website's Download buttons point at GitHub Release assets, and GitHub
# counts every asset download. This just reads those counters back.
#
# Needs the GitHub CLI (https://cli.github.com) logged in: gh auth status
#
#   .\scripts\download-stats.ps1
#
# Caveat: re-uploading an asset with --clobber deletes it and creates a new one,
# which resets that asset's counter to zero. Cut a new tag per version instead.

$ErrorActionPreference = 'Stop'
$repo = 'ishpreet36752/WordMeaning'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI not found. Install it from https://cli.github.com" -ForegroundColor Yellow
    exit 1
}

$releases = gh api "repos/$repo/releases" --paginate | ConvertFrom-Json
if (-not $releases) {
    Write-Host "No releases yet. Cut one with: gh release create v1.0.0 dist\WordMeaning-Setup.exe dist\WordMeaning.exe"
    exit 0
}

$total = 0
foreach ($rel in $releases) {
    Write-Host ""
    Write-Host $rel.tag_name -ForegroundColor Cyan -NoNewline
    Write-Host "  published $([datetime]$rel.published_at | Get-Date -Format 'yyyy-MM-dd')"
    foreach ($asset in $rel.assets) {
        $total += $asset.download_count
        Write-Host ("  {0,-28} {1,6}" -f $asset.name, $asset.download_count)
    }
}

Write-Host ""
Write-Host ("  {0,-28} {1,6}" -f 'TOTAL DOWNLOADS', $total) -ForegroundColor Green
Write-Host ""
Write-Host "Repo views (14-day window, separate from the Pages site):"
$views = gh api "repos/$repo/traffic/views" | ConvertFrom-Json
Write-Host ("  {0} views from {1} unique visitors" -f $views.count, $views.uniques)
