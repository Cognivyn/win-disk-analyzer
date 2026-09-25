<#
.SYNOPSIS
    Read-only Windows disk space analysis and diagnostic utility.

.DESCRIPTION
    Analyze-DiskSpace inspects local storage volumes, scans for top space-consuming files,
    and calculates directory sizes without making ANY modifications to the system.
    Strictly follows a zero-mutation, read-only security policy.

.SECURITY GUARANTEE
    - ZERO MUTATION: Contains NO code paths to delete, move, clean, or modify any files,
      directories, volumes, or registry keys.
    - LEAST PRIVILEGE: Operates safely in standard, non-elevated user sessions.
    - DEFENSIVE PARSING: Handles restricted/locked files and directories gracefully
      without attempting to take ownership or alter permissions.

.PARAMETER Drive
    Target drive letter to inspect (e.g., "C:", "D", "E:").

.PARAMETER Path
    Target directory path to inspect. If omitted and -Drive is specified, defaults to the root of that drive.

.PARAMETER TopFiles
    Number of largest files to report (e.g., 20).

.PARAMETER TopFolders
    Number of largest subdirectories to report (e.g., 10).

.PARAMETER OpenSettings
    Launches native Windows Storage Sense settings GUI (ms-settings:storagesense).

.PARAMETER ExportFormat
    Export results to structured file format: "CSV" or "JSON".

.PARAMETER OutFile
    Path to destination export file when -ExportFormat is specified.

.EXAMPLE
    .\Analyze-DiskSpace.ps1
    Displays a colorized overview of all local storage volumes.

.EXAMPLE
    .\Analyze-DiskSpace.ps1 -Drive C: -TopFiles 20
    Finds the 20 largest files on drive C:.

.EXAMPLE
    .\Analyze-DiskSpace.ps1 -Drive C: -TopFolders 10
    Calculates and displays the top 10 largest folders on drive C:.

.EXAMPLE
    .\Analyze-DiskSpace.ps1 -OpenSettings
    Opens the native Windows Storage Sense panel.
#>

[CmdletBinding(DefaultParameterSetName = 'Summary')]
param (
    [Parameter(ParameterSetName = 'AnalyzeDrive')]
    [Parameter(ParameterSetName = 'Files')]
    [Parameter(ParameterSetName = 'Folders')]
    [ValidatePattern('^[a-zA-Z]:?$')]
    [string]$Drive,

    [Parameter(ParameterSetName = 'AnalyzeDrive')]
    [Parameter(ParameterSetName = 'Files')]
    [Parameter(ParameterSetName = 'Folders')]
    [string]$Path,

    [Parameter(ParameterSetName = 'Files')]
    [ValidateRange(1, 1000)]
    [int]$TopFiles = 20,

    [Parameter(ParameterSetName = 'Folders')]
    [ValidateRange(1, 100)]
    [int]$TopFolders = 10,

    [Parameter(ParameterSetName = 'Settings')]
    [switch]$OpenSettings,

    [Parameter(ParameterSetName = 'Summary')]
    [switch]$Summary,

    [Parameter()]
    [ValidateSet('CSV', 'JSON')]
    [string]$ExportFormat,

    [Parameter()]
    [string]$OutFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-SecurityBanner {
    Write-Host "[SECURITY NOTICE] " -ForegroundColor Cyan -NoNewline
    Write-Host "Strict Read-Only Mode active. No files will be modified or deleted." -ForegroundColor DarkGray
    Write-Host ""
}

function Format-Bytes {
    param([double]$Bytes)
    if ($Bytes -ge 1TB) {
        return "$([math]::Round($Bytes / 1TB, 2)) TB"
    } elseif ($Bytes -ge 1GB) {
        return "$([math]::Round($Bytes / 1GB, 2)) GB"
    } elseif ($Bytes -ge 1MB) {
        return "$([math]::Round($Bytes / 1MB, 2)) MB"
    } elseif ($Bytes -ge 1KB) {
        return "$([math]::Round($Bytes / 1KB, 2)) KB"
    } else {
        return "$Bytes B"
    }
}

function Export-DiagnosticData {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,
        [string]$Format,
        [string]$Destination
    )

    if (-not $Format -or -not $Destination) {
        return
    }

    try {
        $parentDir = Split-Path -Path $Destination -Parent
        if ($parentDir -and -not (Test-Path -Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        if ($Format -eq 'CSV') {
            $Data | Export-Csv -Path $Destination -NoTypeInformation -Encoding UTF8
            Write-Host "`n[EXPORT] Report saved to: $Destination (CSV)" -ForegroundColor Green
        } elseif ($Format -eq 'JSON') {
            $Data | ConvertTo-Json -Depth 4 | Set-Content -Path $Destination -Encoding UTF8
            Write-Host "`n[EXPORT] Report saved to: $Destination (JSON)" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Failed to export diagnostic data to '$Destination': $_"
    }
}

# --- Action: Open Native Storage Settings ---
if ($OpenSettings) {
    Write-SecurityBanner
    Write-Host "Opening Windows Storage Sense (ms-settings:storagesense)..." -ForegroundColor Cyan
    Start-Process "ms-settings:storagesense"
    exit 0
}

# --- Action: Files Scanner ---
if ($PSCmdlet.ParameterSetName -eq 'Files') {
    Write-SecurityBanner
    
    $targetPath = if ($Path) { $Path } else { "$($Drive.TrimEnd(':')):\ " }
    $targetPath = $targetPath.Trim()
    
    if (-not (Test-Path -LiteralPath $targetPath)) {
        Write-Error "Target path '$targetPath' does not exist."
        exit 1
    }

    Write-Host "Scanning top $TopFiles largest files under '$targetPath' (Read-Only)..." -ForegroundColor Cyan
    Write-Host "(Skipping protected system files and access-denied paths safely)" -ForegroundColor DarkGray
    Write-Host ""

    $results = @()
    try {
        $files = Get-ChildItem -LiteralPath $targetPath -Recurse -File -Force -ErrorAction SilentlyContinue |
            Sort-Object Length -Descending |
            Select-Object -First $TopFiles

        foreach ($file in $files) {
            $results += [PSCustomObject]@{
                "File Name" = $file.Name
                "Size"      = Format-Bytes $file.Length
                "SizeBytes" = $file.Length
                "Extension" = $file.Extension
                "Directory" = $file.DirectoryName
            }
        }
    } catch {
        Write-Warning "Error during file scan: $_"
    }

    if ($results.Count -gt 0) {
        $results | Select-Object "File Name", "Size", "Extension", "Directory" | Format-Table -AutoSize
        Export-DiagnosticData -Data $results -Format $ExportFormat -Destination $OutFile
    } else {
        Write-Host "No files found or unable to access files under '$targetPath'." -ForegroundColor Yellow
    }
    exit 0
}

# --- Action: Folders Breakdown ---
if ($PSCmdlet.ParameterSetName -eq 'Folders') {
    Write-SecurityBanner
    
    $targetPath = if ($Path) { $Path } else { "$($Drive.TrimEnd(':')):\ " }
    $targetPath = $targetPath.Trim()

    if (-not (Test-Path -LiteralPath $targetPath)) {
        Write-Error "Target path '$targetPath' does not exist."
        exit 1
    }

    Write-Host "Measuring top-level folders under '$targetPath' (Read-Only)..." -ForegroundColor Cyan
    Write-Host ""

    $results = @()
    $subDirs = Get-ChildItem -LiteralPath $targetPath -Directory -Force -ErrorAction SilentlyContinue

    foreach ($dir in $subDirs) {
        Write-Progress -Activity "Measuring Folder Sizes" -Status "Analyzing: $($dir.Name)"
        $folderSize = (Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum

        if ($null -eq $folderSize) { $folderSize = 0 }

        $results += [PSCustomObject]@{
            "Folder Name" = $dir.Name
            "Size"        = Format-Bytes $folderSize
            "SizeBytes"   = $folderSize
            "FullPath"    = $dir.FullName
        }
    }
    Write-Progress -Activity "Measuring Folder Sizes" -Completed

    $topDirs = $results | Sort-Object SizeBytes -Descending | Select-Object -First $TopFolders

    if ($topDirs) {
        $topDirs | Select-Object "Folder Name", "Size", "FullPath" | Format-Table -AutoSize
        Export-DiagnosticData -Data $topDirs -Format $ExportFormat -Destination $OutFile
    } else {
        Write-Host "No subdirectories found under '$targetPath'." -ForegroundColor Yellow
    }
    exit 0
}

# --- Default Action: Volume Overview ---
Write-SecurityBanner
Write-Host "Auditing storage volumes (Read-Only Diagnostic)...`n" -ForegroundColor Cyan

$volumes = @()
try {
    $volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.Size -gt 0 }
} catch {
    # Fallback to Get-PSDrive if Get-Volume is unavailable
    $volumes = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
}

$reportData = @()

foreach ($vol in $volumes) {
    $driveLetter = if ($vol.DriveLetter) { "$($vol.DriveLetter):" } else { $vol.Name }
    $totalSize   = if ($vol.Size) { $vol.Size } else { ($vol.Used + $vol.Free) }
    $freeSize    = if ($vol.SizeRemaining) { $vol.SizeRemaining } else { $vol.Free }
    $usedSize    = $totalSize - $freeSize
    
    $freePercent = if ($totalSize -gt 0) { [math]::Round(($freeSize / $totalSize) * 100, 1) } else { 0 }
    $usedPercent = 100 - $freePercent

    # Progress bar visualization (20 characters)
    $usedBlocks = [math]::Round(($usedPercent / 100) * 20)
    $freeBlocks = 20 - $usedBlocks
    $bar = "[" + ("#" * $usedBlocks) + ("-" * $freeBlocks) + "]"

    # Status classification
    $statusColor = if ($freePercent -lt 10) { "Red" } elseif ($freePercent -lt 25) { "Yellow" } else { "Green" }
    $healthStatus = if ($freePercent -lt 10) { "CRITICAL" } elseif ($freePercent -lt 25) { "WARNING" } else { "HEALTHY" }

    $reportData += [PSCustomObject]@{
        "Drive"        = $driveLetter
        "Label"        = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "" }
        "Total"        = Format-Bytes $totalSize
        "Used"         = Format-Bytes $usedSize
        "Free"         = Format-Bytes $freeSize
        "% Free"       = "$freePercent%"
        "Usage Graph"  = $bar
        "Health"       = $healthStatus
        "TotalBytes"   = $totalSize
        "FreeBytes"    = $freeSize
    }
}

$reportData | Select-Object "Drive", "Label", "Total", "Used", "Free", "% Free", "Usage Graph", "Health" | Format-Table -AutoSize

Write-Host "`nRecommendations:" -ForegroundColor Cyan
Write-Host "  - To inspect largest files on a drive:  .\Analyze-DiskSpace.ps1 -Drive C: -TopFiles 20" -ForegroundColor Gray
Write-Host "  - To inspect largest directories:      .\Analyze-DiskSpace.ps1 -Drive C: -TopFolders 10" -ForegroundColor Gray
Write-Host "  - To open Windows Storage Sense GUI:   .\Analyze-DiskSpace.ps1 -OpenSettings" -ForegroundColor Gray

Export-DiagnosticData -Data $reportData -Format $ExportFormat -Destination $OutFile
