$ErrorActionPreference = 'Stop'

$root = (Get-Location).Path
$remote = $env:REMOTE
$branch = $env:BRANCH
$remote = if ($remote) { $remote.Trim() } else { $remote }
$branch = if ($branch) { $branch.Trim() } else { $branch }

# Fallback: read from git if env not provided (so the script also works standalone)
if (-not $remote) {
    $remote = (& git remote get-url origin 2>$null) | Out-String
    if ($remote) { $remote = $remote.Trim() }
}
if (-not $branch) {
    $branch = (& git branch --show-current 2>$null) | Out-String
    if ($branch) { $branch = $branch.Trim() }
    if (-not $branch) { $branch = 'main' }
}

if (-not $remote -or $remote -notmatch 'github\.com[/:]([^/]+)/([^/.]+)') {
    Write-Host ('[ERROR] Cannot parse GitHub user/repo from remote: ' + $remote)
    exit 1
}
$user = $matches[1]
$repo = $matches[2]

$base = "https://cdn.jsdelivr.net/gh/$user/$repo@$branch/"
$out  = Join-Path $root 'files_list.txt'
$utf8Bom = New-Object System.Text.UTF8Encoding $true

$files = Get-ChildItem -Path $root -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch '[\\/]\.git[\\/]' -and
        $_.Name -ne 'files_list.txt' -and
        $_.Extension -notin @('.bat', '.ps1')
    }

$lines = foreach ($f in $files) {
    $rel = $f.FullName.Substring($root.Length).TrimStart('\', '/')
    $segments = $rel.Split([char[]]@('\', '/')) | ForEach-Object { [uri]::EscapeDataString($_) }
    $encoded = $segments -join '/'
    $base + $encoded
}

[System.IO.File]::WriteAllLines($out, $lines, $utf8Bom)

Write-Host ('Wrote ' + $lines.Count + ' URLs to ' + $out)
Write-Host ''
Write-Host '--- preview (first 20) ---'
$lines | Select-Object -First 20 | ForEach-Object { Write-Host $_ }
Write-Host '--- end preview ---'