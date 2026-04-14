#Requires -Version 5.1
<#
.SYNOPSIS
    Automatically updates all Winget packages at system startup.
.DESCRIPTION
    Checks all installed Winget packages for available updates
    and installs them without user confirmation.
#>

$LogPath = Join-Path $env:LOCALAPPDATA "WingetAutoUpdate"
if (-not (Test-Path $LogPath)) { New-Item -Path $LogPath -ItemType Directory -Force | Out-Null }
$LogFile = Join-Path $LogPath "update_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').log"

function Write-Log {
    param([string]$Message)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    $entry | Tee-Object -FilePath $LogFile -Append
}

# Ensure winget path is available (Scheduled Tasks may have a restricted PATH)
$wingetPath = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetPath) {
    $resolvedPath = Resolve-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe" -ErrorAction SilentlyContinue
    if ($resolvedPath) {
        $wingetPath = $resolvedPath.Path
    } else {
        Write-Log "ERROR: winget not found. Aborting."
        exit 1
    }
} else {
    $wingetPath = $wingetPath.Source
}

Write-Log "=== Winget Auto-Update started ==="
Write-Log "Winget path: $wingetPath"

# Update all packages without confirmation, skip pinned packages
Write-Log "Starting update of all packages..."
& $wingetPath upgrade --all --silent --accept-package-agreements --accept-source-agreements --include-unknown 2>&1 |
    ForEach-Object { Write-Log $_ }

Write-Log "=== Winget Auto-Update completed ==="

# Clean up old logs (older than 30 days)
Get-ChildItem -Path $LogPath -Filter "update_*.log" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Force
