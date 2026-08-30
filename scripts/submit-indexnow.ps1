<#
.SYNOPSIS
    Tells Bing, Yandex, Seznam and the other IndexNow participants that pages on the site changed.

.DESCRIPTION
    Google does not use IndexNow, but Bing does, and ChatGPT search runs on Bing's index — so a
    new or edited page is worth pinging here as well as submitting the sitemap in Search Console.

    Ownership is proved by a key file served from the site:
        https://ishpreet36752.github.io/WordMeaning/9a1cfd86bf22913fb2d927b51f92a7fe.txt
    That file lives at docs/<key>.txt and contains the key and nothing else. Because it sits in a
    subdirectory rather than at the host root (the host root belongs to a different repository),
    it authorises only URLs under /WordMeaning/ — which is the whole site — and every request must
    carry keyLocation. Delete or rename the file and submissions start failing with 403.

    URLs default to the ones in docs/sitemap.xml, so a new page is picked up automatically once it
    is in the sitemap.

.PARAMETER Url
    One or more URLs to submit instead of the whole sitemap. Must be under the site root.

.PARAMETER WhatIf
    Print the payload without sending it.

.EXAMPLE
    .\scripts\submit-indexnow.ps1
    .\scripts\submit-indexnow.ps1 -Url https://ishpreet36752.github.io/WordMeaning/offline-dictionary-windows.html
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]] $Url
)

$ErrorActionPreference = 'Stop'

$SiteRoot    = 'https://ishpreet36752.github.io/WordMeaning/'
$HostName    = 'ishpreet36752.github.io'
$Key         = '9a1cfd86bf22913fb2d927b51f92a7fe'
$KeyLocation = "$SiteRoot$Key.txt"
$Endpoint    = 'https://api.indexnow.org/IndexNow'

$repo    = Split-Path -Parent $PSScriptRoot
$keyFile = Join-Path $repo "docs\$Key.txt"
if (-not (Test-Path $keyFile)) {
    throw "Key file missing: $keyFile. IndexNow verifies ownership by fetching $KeyLocation, so the file must stay committed and published."
}

if (-not $Url) {
    $sitemapPath = Join-Path $repo 'docs\sitemap.xml'
    [xml] $sitemap = Get-Content -Path $sitemapPath -Raw
    $Url = @($sitemap.urlset.url.loc)
    Write-Host "Submitting $($Url.Count) URL(s) from docs\sitemap.xml"
}

foreach ($u in $Url) {
    if (-not $u.StartsWith($SiteRoot)) {
        throw "URL outside the authorised path: $u. The key file only authorises URLs under $SiteRoot."
    }
}

$body = [ordered]@{
    host        = $HostName
    key         = $Key
    keyLocation = $KeyLocation
    urlList     = @($Url)
} | ConvertTo-Json -Depth 3

if (-not $PSCmdlet.ShouldProcess($Endpoint, "POST $($Url.Count) URL(s)")) {
    Write-Host $body
    return
}

try {
    $resp = Invoke-WebRequest -Uri $Endpoint -Method Post -ContentType 'application/json; charset=utf-8' -Body $body -UseBasicParsing
    # 200 = accepted, 202 = accepted but the key is still being validated. Both are fine.
    Write-Host "IndexNow: HTTP $($resp.StatusCode) $($resp.StatusDescription)"
    foreach ($u in $Url) { Write-Host "  $u" }
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    switch ($code) {
        400 { Write-Error "IndexNow rejected the request (400): bad format." }
        403 { Write-Error "IndexNow rejected the key (403): $KeyLocation must serve exactly '$Key'. Check the page is published." }
        422 { Write-Error "IndexNow rejected the URLs (422): they must belong to $HostName and sit under the key file's directory." }
        429 { Write-Error "IndexNow rate-limited this host (429). Submit changed pages only, not the whole sitemap, and try later." }
        default { throw }
    }
}
