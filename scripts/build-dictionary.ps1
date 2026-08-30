# build-dictionary.ps1 — generates assets\dictionary.dat, the offline dictionary
# the app ships with, from the Princeton WordNet 3.1 database files.
#
#   .\scripts\build-dictionary.ps1            # download (cached) and generate
#   .\scripts\build-dictionary.ps1 -Force     # regenerate even if up to date
#
# Why a build step and not a committed data file: the .dat is generated output.
# It is derived from a fixed, versioned corpus, so anyone (and CI) can reproduce
# it byte for byte from this script. Nothing generated belongs in git.
#
# Output format — one record per line, tab separated, sorted by key so the app
# can binary-search the file by seeking instead of loading 10+ MB into memory:
#
#   key <TAB> partOfSpeech <TAB> definition <TAB> altDefinition <TAB> example
#   key <TAB> =            <TAB> targetWord                        (irregular form)
#
# Comment lines start with "#", which sorts before every key ("#" = 0x23, keys
# always start with a letter), so they stay at the top and the search never
# reaches them.
param(
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# WordNet 3.1 database files. Pinned and checksummed for the same reason the
# CI toolchain is: the shipped dictionary should be reproducible, not "whatever
# the server had that day".
$WordNetUrl    = 'https://wordnetcode.princeton.edu/wn3.1.dict.tar.gz'
$WordNetSha256 = '3F7D8BE8EF6ECC7167D39B10D66954EC734280B5BDCD57F7D9EAFE429D11C22A'

# Mirrors of the app's own limits (src\Config.ahk). Applying them here keeps the
# shipped file from carrying text the popup would only throw away.
$MaxDefinitionLen = 300
$MaxExampleLen    = 140
$WordPattern      = "^[A-Za-z][A-Za-z'\-]{0,31}$"

# Forward slashes throughout: pwsh runs this on macOS too (the Mac build needs
# the same .dat), and a backslash is an ordinary filename character there.
$staging = Join-Path $root '.staging/wordnet'
$dictDir = Join-Path $staging 'dict'
$outFile = Join-Path $root 'assets/dictionary.dat'

# --- Fetch and unpack (cached in .staging, which is git-ignored) -------------
if (-not (Test-Path (Join-Path $dictDir 'index.noun'))) {
    New-Item -ItemType Directory -Force -Path $staging | Out-Null
    $tgz = Join-Path $staging 'wn3.1.dict.tar.gz'
    if (-not (Test-Path $tgz)) {
        Write-Host "Downloading WordNet 3.1 ($WordNetUrl)"
        Invoke-WebRequest -Uri $WordNetUrl -OutFile $tgz
    }
    $hash = (Get-FileHash $tgz -Algorithm SHA256).Hash
    if ($hash -ne $WordNetSha256) {
        Remove-Item $tgz -Force
        throw "WordNet checksum mismatch. Expected $WordNetSha256, got $hash"
    }
    Write-Host "Checksum verified. Extracting..."
    # tar.exe (bsdtar) ships with Windows 10+ and the GitHub runners.
    & tar -xzf $tgz -C $staging
    if ($LASTEXITCODE -ne 0) { throw "tar failed to extract $tgz" }
}
if (-not (Test-Path (Join-Path $dictDir 'index.noun'))) {
    throw "WordNet files not found under $dictDir after extraction."
}

if ((Test-Path $outFile) -and -not $Force) {
    $out = Get-Item $outFile
    $src = Get-Item $PSCommandPath
    if ($out.LastWriteTimeUtc -gt $src.LastWriteTimeUtc) {
        Write-Host ("Up to date: {0} ({1:N0} bytes). Use -Force to rebuild." -f $outFile, $out.Length)
        return
    }
}

# --- Pass 1: synset offset -> definition + example --------------------------
# A gloss is "definition; \"an example\"; \"another\"". The definition itself
# often contains semicolons ("...since prehistoric times; occurs in many
# breeds"), so the split is at the first quoted run, not at the first semicolon.
$posName = @{ 'n' = 'noun'; 'v' = 'verb'; 'a' = 'adjective'; 's' = 'adjective'; 'r' = 'adverb' }
$synsets = @{}

foreach ($p in 'noun', 'verb', 'adj', 'adv') {
    $file = Join-Path $dictDir "data.$p"
    Write-Host "Reading $file"
    $reader = [System.IO.File]::OpenText($file)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            if ($line.StartsWith(' ')) { continue }        # licence header block
            $bar = $line.IndexOf('|')
            if ($bar -lt 0) { continue }
            $gloss = $line.Substring($bar + 1).Trim()
            if ($gloss.Length -eq 0) { continue }

            $def = $gloss
            $example = ''
            $q = $gloss.IndexOf('"')
            if ($q -ge 0) {
                $def = $gloss.Substring(0, $q).TrimEnd(" `t;".ToCharArray())
                $end = $gloss.IndexOf('"', $q + 1)
                if ($end -gt $q) { $example = $gloss.Substring($q + 1, $end - $q - 1).Trim() }
            }
            if ($def.Length -eq 0) { continue }

            # _CleanExample's rules: a fragment or an overlong citation is worse
            # than no example at all in a small popup, so drop rather than trim.
            if ($example.Length -gt $MaxExampleLen -or
                ($example -split '\s+' | Where-Object { $_ }).Count -lt 4) {
                $example = ''
            }

            # "00001930 03 n 01 physical_entity ... | gloss"
            #  ^offset   ^lex ^ss_type
            $synsets[$line.Substring(0, 8)] = @{
                def     = $def
                example = $example
                pos     = $posName[$line.Substring(12, 1)]
            }
        }
    } finally { $reader.Dispose() }
}
Write-Host ("  {0:N0} synsets" -f $synsets.Count)

# --- Pass 2: how often each part of speech is actually used ------------------
# cntlist.rev carries the sense frequencies from WordNet's tagged corpora, keyed
# "lemma%ss_type:...". Without it "better" resolves to the verb ("surpass in
# excellence") because it has more senses; the counts say the adjective outweighs
# it 92 to 3, which is the reading someone reading prose has just hit.
$posDigit = @{ '1' = 'noun'; '2' = 'verb'; '3' = 'adjective'; '4' = 'adverb'; '5' = 'adjective' }
$freq = @{}

$cntlist = Join-Path $dictDir 'cntlist.rev'
Write-Host "Reading $cntlist"
foreach ($line in [System.IO.File]::ReadLines($cntlist)) {
    $pct = $line.IndexOf('%')
    if ($pct -lt 1) { continue }
    $lemma = $line.Substring(0, $pct)
    if ($lemma.Contains('_')) { continue }
    $pos = $posDigit[$line.Substring($pct + 1, 1)]
    if (-not $pos) { continue }
    $f = $line.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    if ($f.Count -lt 3) { continue }
    $k = $lemma.ToLowerInvariant() + '|' + $pos
    $freq[$k] = [int]$freq[$k] + [int]$f[2]
}
Write-Host ("  {0:N0} frequency-tagged word senses" -f $freq.Count)

# --- Pass 3: lemma -> its senses, per part of speech -------------------------
# index.<pos> lists a lemma's synsets most-frequent-first, which is already the
# order the popup wants — unlike Wiktionary, whose sense 1 is the oldest one.
#   lemma pos synset_cnt p_cnt [ptr...] sense_cnt tagsense_cnt offset...
$lemmas = @{}

foreach ($p in 'noun', 'verb', 'adj', 'adv') {
    $file = Join-Path $dictDir "index.$p"
    $groupPos = @{ 'noun' = 'noun'; 'verb' = 'verb'; 'adj' = 'adjective'; 'adv' = 'adverb' }[$p]
    Write-Host "Reading $file"
    $reader = [System.IO.File]::OpenText($file)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            if ($line.StartsWith(' ')) { continue }
            $f = $line.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
            if ($f.Count -lt 6) { continue }

            $word = $f[0]
            # Single English words only — the app never looks up a phrase, and
            # WordNet writes collocations as "hot_dog".
            if ($word -notmatch $WordPattern) { continue }

            $pCnt        = [int]$f[3]
            $senseCnt    = [int]$f[4 + $pCnt]
            $tagsenseCnt = [int]$f[5 + $pCnt]
            $offsets     = $f[(6 + $pCnt)..(5 + $pCnt + $senseCnt)]

            $key = $word.ToLowerInvariant()
            if (-not $lemmas.ContainsKey($key)) { $lemmas[$key] = @() }
            $lemmas[$key] += , @{ tagged = $tagsenseCnt; offsets = $offsets; pos = $groupPos }
        }
    } finally { $reader.Dispose() }
}
# .psbase.Count, not .Count: member access on a hashtable resolves a matching KEY
# first, and "count" is an English word, so $lemmas.Count returns that entry.
Write-Host ("  {0:N0} single-word lemmas" -f $lemmas.psbase.Count)

# Mirrors Dictionary._Score: an example sentence is the strongest signal that a
# sense is the everyday one; a gloss that just restates the word teaches nothing.
function Get-SenseScore {
    param([string]$Word, [string]$Def, [string]$Example)
    $s = 0
    $stem = if ($Word.Length -gt 6) { $Word.Substring(0, $Word.Length - 3) } else { $Word }
    if ($Example) { $s += 2 } elseif ($Def.ToLowerInvariant().Contains($stem)) { $s -= 3 }
    if ($Def.StartsWith('(')) { $s -= 1 }
    return $s
}

# --- Pass 4: choose the two senses each entry shows --------------------------
$records = New-Object System.Collections.Generic.List[string]
$tab = "`t"

# .psbase again: the keys here are English words, so a corpus that ever contains
# "keys" would otherwise turn this loop into a single-entry one.
foreach ($key in $lemmas.psbase.Keys) {
    # A word can be several parts of speech ("run", "better"). Prefer the one
    # used most often in the tagged corpora; fall back to the count of tagged
    # senses for the words the corpora never covered.
    $groups = $lemmas[$key]
    $chosen = $null
    $chosenRank = -1
    foreach ($g in $groups) {
        $rank = [int]$freq[$key + '|' + $g.pos]
        if ($rank -gt $chosenRank) { $chosenRank = $rank; $chosen = $g }
    }
    if ($chosenRank -le 0) {
        $chosen = $groups[0]
        foreach ($g in $groups) { if ($g.tagged -gt $chosen.tagged) { $chosen = $g } }
    }

    $senses = @()
    foreach ($o in $chosen.offsets) { if ($synsets.ContainsKey($o)) { $senses += $synsets[$o] } }
    if ($senses.Count -eq 0) { continue }

    $primary = $senses[0]
    $best = $primary
    $bestScore = Get-SenseScore -Word $key -Def $primary.def -Example $primary.example
    for ($i = 1; $i -lt $senses.Count; $i++) {
        $sc = Get-SenseScore -Word $key -Def $senses[$i].def -Example $senses[$i].example
        if ($sc -gt $bestScore) { $bestScore = $sc; $best = $senses[$i] }
    }

    $def = $primary.def
    $alt = if ($best.def -eq $primary.def) { '' } else { $best.def }
    $example = if ($best.example) { $best.example } else { $primary.example }

    # Dictionary._Result's budget: the second sense is dropped, not shrunk.
    if ($def.Length -gt $MaxDefinitionLen) { $def = $def.Substring(0, $MaxDefinitionLen) + [char]0x2026 }
    if ($def.Length + $alt.Length -gt $MaxDefinitionLen) { $alt = '' }

    # Tabs and newlines are the record separators; WordNet has neither, but a
    # stray one would silently corrupt the file, so normalise anyway.
    $clean = { param($s) ($s -replace '[\t\r\n]', ' ').Trim() }
    $records.Add($key + $tab + $primary.pos + $tab + (& $clean $def) + $tab +
                 (& $clean $alt) + $tab + (& $clean $example))
}
Write-Host ("  {0:N0} entries" -f $records.Count)

# --- Pass 5: irregular forms -------------------------------------------------
# Regular inflections ("-s", "-ed", "-ing") are stripped by rule at lookup time
# in LocalDictionary._Detach, which costs no bytes. Only the irregulars WordNet
# lists by hand ("ran run", "mice mouse") have to be shipped as data.
$aliases = 0
foreach ($p in 'noun', 'verb', 'adj', 'adv') {
    $file = Join-Path $dictDir "$p.exc"
    if (-not (Test-Path $file)) { continue }
    foreach ($line in [System.IO.File]::ReadLines($file)) {
        $f = $line.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
        if ($f.Count -lt 2) { continue }
        $from = $f[0].ToLowerInvariant()
        $to = $f[1].ToLowerInvariant()
        # A form that is itself a headword keeps its own entry ("axes" is a word).
        if ($from -notmatch $WordPattern -or $lemmas.ContainsKey($from)) { continue }
        if (-not $lemmas.ContainsKey($to)) { continue }
        $records.Add($from + $tab + '=' + $tab + $to)
        $lemmas[$from] = @()      # de-duplicate repeats across the four files
        $aliases++
    }
}
Write-Host ("  {0:N0} irregular forms" -f $aliases)

# --- Write, sorted ordinally so the app's binary search agrees with this order
$arr = $records.ToArray()
[Array]::Sort($arr, [StringComparer]::Ordinal)

$header = @(
    '# WordMeaning offline dictionary. Generated by scripts/build-dictionary.ps1 - do not edit.',
    '# Source: WordNet 3.1, Princeton University. https://wordnet.princeton.edu/',
    '# WordNet 3.1 Copyright 2011 by Princeton University. All rights reserved.',
    '# Licensed under the WordNet licence: https://wordnet.princeton.edu/license-and-commercial-use',
    '# Format: key<TAB>pos<TAB>definition<TAB>altDefinition<TAB>example',
    '#         key<TAB>=<TAB>target   (irregular inflected form)'
)

New-Item -ItemType Directory -Force -Path (Split-Path $outFile) | Out-Null
# No BOM: the app seeks to arbitrary byte offsets, and a BOM would land in the
# first record's key.
$utf8 = New-Object System.Text.UTF8Encoding($false)
$writer = New-Object System.IO.StreamWriter($outFile, $false, $utf8)
try {
    $writer.NewLine = "`n"
    foreach ($h in $header) { $writer.WriteLine($h) }
    foreach ($r in $arr) { $writer.WriteLine($r) }
} finally { $writer.Dispose() }

Write-Host ""
Write-Host ("Wrote {0}  ({1:N0} bytes, {2:N0} records)" -f $outFile, (Get-Item $outFile).Length, $arr.Count)
