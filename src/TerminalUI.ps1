# src/TerminalUI.ps1
# Single Responsibility: Terminal presentation, Unicode box drawing, colorization, and visual formatting.

function Show-SecurityHeader {
    <#
    .SYNOPSIS
        Displays the top application branding and security guarantee card with pixel-perfect alignment.
    #>
    param(
        [string]$Version = "v1.1.0"
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $computerName = $env:COMPUTERNAME
    if ($computerName.Length -gt 15) { $computerName = $computerName.Substring(0, 15) }

    $targetWidth = 77

    $line1Left  = " WIN DISK ANALYZER • $Version"
    $line1Right = "Cognivyn Infrasys "
    $pad1       = " " * [math]::Max(0, ($targetWidth - $line1Left.Length - $line1Right.Length))

    $line2Left  = " Security: Strictly Read-Only (Zero Mutation)"
    $line2Right = "Host: $($computerName.PadRight(15)) "
    $pad2       = " " * [math]::Max(0, ($targetWidth - $line2Left.Length - $line2Right.Length))

    $line3Left  = " Privilege: Non-Elevated Standard User"
    $line3Right = "Audit: $timestamp "
    $pad3       = " " * [math]::Max(0, ($targetWidth - $line3Left.Length - $line3Right.Length))

    Write-Host ""
    Write-Host "╭─────────────────────────────────────────────────────────────────────────────╮" -ForegroundColor Cyan
    Write-Host "│" -ForegroundColor Cyan -NoNewline
    Write-Host $line1Left -ForegroundColor White -NoNewline
    Write-Host $pad1 -NoNewline
    Write-Host $line1Right -ForegroundColor DarkCyan -NoNewline
    Write-Host "│" -ForegroundColor Cyan

    Write-Host "│" -ForegroundColor Cyan -NoNewline
    Write-Host $line2Left -ForegroundColor Green -NoNewline
    Write-Host $pad2 -NoNewline
    Write-Host $line2Right -ForegroundColor DarkGray -NoNewline
    Write-Host "│" -ForegroundColor Cyan

    Write-Host "│" -ForegroundColor Cyan -NoNewline
    Write-Host $line3Left -ForegroundColor DarkGray -NoNewline
    Write-Host $pad3 -NoNewline
    Write-Host $line3Right -ForegroundColor DarkGray -NoNewline
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "╰─────────────────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
    Write-Host ""
}

function Show-StorageSummary {
    <#
    .SYNOPSIS
        Renders an aggregated capacity summary bar across all audited drives.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$EnrichedVolumes
    )

    $totalCapacity = 0.0
    $totalFree     = 0.0
    $criticalCount = 0
    $warningCount  = 0

    foreach ($v in $EnrichedVolumes) {
        $totalCapacity += $v.TotalBytes
        $totalFree     += $v.FreeBytes
        if ($v.HealthStatus -eq 'CRITICAL') { $criticalCount++ }
        elseif ($v.HealthStatus -eq 'WARNING') { $warningCount++ }
    }

    $totalUsed = $totalCapacity - $totalFree
    $overallUsedPercent = if ($totalCapacity -gt 0) { [math]::Round(($totalUsed / $totalCapacity) * 100, 1) } else { 0.0 }

    Write-Host "  CAPACITY: " -ForegroundColor DarkGray -NoNewline
    Write-Host (Format-ByteSize $totalCapacity) -ForegroundColor White -NoNewline
    Write-Host "  │  USED: " -ForegroundColor DarkGray -NoNewline
    Write-Host "$(Format-ByteSize $totalUsed) ($overallUsedPercent%)" -ForegroundColor White -NoNewline
    Write-Host "  │  FREE: " -ForegroundColor DarkGray -NoNewline
    Write-Host (Format-ByteSize $totalFree) -ForegroundColor White -NoNewline
    Write-Host "  │  STATUS: " -ForegroundColor DarkGray -NoNewline

    if ($criticalCount -gt 0) {
        Write-Host "$criticalCount Critical Drive(s)" -ForegroundColor Red
    } elseif ($warningCount -gt 0) {
        Write-Host "$warningCount Warning Drive(s)" -ForegroundColor Yellow
    } else {
        Write-Host "All Drives Healthy" -ForegroundColor Green
    }
    Write-Host ""
}

function Show-VolumeTable {
    <#
    .SYNOPSIS
        Renders the volume capacity table with Unicode borders and colored usage meters.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$EnrichedVolumes
    )

    # Column Inner Widths:
    # DRV: 4, LABEL: 10, TOTAL: 9, USED: 9, FREE: 9, % FREE: 6, METER: 22, HEALTH: 8
    # Outer Widths (with 2 spaces padding each):
    # 6 + 12 + 11 + 11 + 11 + 8 + 24 + 10 = 93 inner chars + 9 vertical lines = 102 chars
    Write-Host "┌──────┬────────────┬───────────┬───────────┬───────────┬────────┬────────────────────────┬──────────┐" -ForegroundColor DarkCyan
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "DRV " -ForegroundColor White -NoNewline
    Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "LABEL      " -ForegroundColor White -NoNewline
    Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
    Write-Host " TOTAL   " -ForegroundColor White -NoNewline
    Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "  USED   " -ForegroundColor White -NoNewline
    Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "  FREE   " -ForegroundColor White -NoNewline
    Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "% FREE " -ForegroundColor White -NoNewline
    Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "USAGE METER            " -ForegroundColor White -NoNewline
    Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "HEALTH   " -ForegroundColor White -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "├──────┼────────────┼───────────┼───────────┼───────────┼────────┼────────────────────────┼──────────┤" -ForegroundColor DarkCyan

    foreach ($v in $EnrichedVolumes) {
        $drv   = $v.DriveLetter.PadRight(4)
        $lbl   = ($v.Label.PadRight(10)).Substring(0, [math]::Min(10, $v.Label.Length)).PadRight(10)
        $total = (Format-ByteSize $v.TotalBytes).PadLeft(9)
        $used  = (Format-ByteSize $v.UsedBytes).PadLeft(9)
        $free  = (Format-ByteSize $v.FreeBytes).PadLeft(9)
        $pct   = ("$($v.FreePercent)%").PadLeft(6)
        $hlth  = $v.HealthStatus.PadRight(8)

        Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $drv -ForegroundColor Yellow -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $lbl -ForegroundColor Gray -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $total -ForegroundColor White -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $used -ForegroundColor Gray -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $free -ForegroundColor White -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $pct -ForegroundColor $v.StatusColor -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $v.ProgressBar -ForegroundColor $v.StatusColor -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $hlth -ForegroundColor $v.StatusColor -NoNewline
        Write-Host " │" -ForegroundColor DarkCyan
    }

    Write-Host "└──────┴────────────┴───────────┴───────────┴───────────┴────────┴────────────────────────┴──────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-FilesTable {
    <#
    .SYNOPSIS
        Renders the top space-consuming files table.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Files,
        [string]$TargetPath
    )

    Write-Host "── Top Largest Files in '$TargetPath' ──────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host ""

    if ($Files.Count -eq 0) {
        Write-Host "  No files found or unable to access files under '$TargetPath'." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    Write-Host "┌────┬──────────────────────────────────────┬───────────┬──────┬────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "#  " -ForegroundColor White -NoNewline
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "FILE NAME                            " -ForegroundColor White -NoNewline
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "SIZE      " -ForegroundColor White -NoNewline
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "TYPE " -ForegroundColor White -NoNewline
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "DIRECTORY                        " -ForegroundColor White -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "├────┼──────────────────────────────────────┼───────────┼──────┼────────────────────────────────┤" -ForegroundColor DarkCyan

    $idx = 1
    foreach ($f in $Files) {
        $rankStr = "$idx".PadLeft(2)
        $fnTrim  = if ($f.FileName.Length -gt 36) { $f.FileName.Substring(0, 33) + "..." } else { $f.FileName.PadRight(36) }
        $szStr   = (Format-ByteSize $f.SizeBytes).PadLeft(9)
        $extStr  = if ($f.Extension) { ($f.Extension.PadRight(4)).Substring(0, [math]::Min(4, $f.Extension.Length)) } else { "    " }
        $dirTrim = if ($f.Directory.Length -gt 30) { "..." + $f.Directory.Substring($f.Directory.Length - 27) } else { $f.Directory.PadRight(30) }

        Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $rankStr -ForegroundColor DarkGray -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $fnTrim -ForegroundColor White -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $szStr -ForegroundColor Yellow -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $extStr -ForegroundColor DarkCyan -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $dirTrim -ForegroundColor DarkGray -NoNewline
        Write-Host " │" -ForegroundColor DarkCyan
        $idx++
    }

    Write-Host "└────┴──────────────────────────────────────┴───────────┴──────┴────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-FoldersTable {
    <#
    .SYNOPSIS
        Renders the top subdirectories table.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Folders,
        [string]$TargetPath
    )

    Write-Host "── Directory Footprint Breakdown for '$TargetPath' ───────────────────────────" -ForegroundColor Cyan
    Write-Host ""

    if ($Folders.Count -eq 0) {
        Write-Host "  No subdirectories found under '$TargetPath'." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    Write-Host "┌────┬──────────────────────────────────┬───────────┬───────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "#  " -ForegroundColor White -NoNewline
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "FOLDER NAME                      " -ForegroundColor White -NoNewline
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "SIZE      " -ForegroundColor White -NoNewline
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "FULL PATH                                   " -ForegroundColor White -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "├────┼──────────────────────────────────┼───────────┼───────────────────────────────────────────┤" -ForegroundColor DarkCyan

    $idx = 1
    foreach ($f in $Folders) {
        $rankStr = "$idx".PadLeft(2)
        $fnTrim  = if ($f.FolderName.Length -gt 32) { $f.FolderName.Substring(0, 29) + "..." } else { $f.FolderName.PadRight(32) }
        $szStr   = (Format-ByteSize $f.SizeBytes).PadLeft(9)
        $pathTrim = if ($f.FullPath.Length -gt 41) { "..." + $f.FullPath.Substring($f.FullPath.Length - 38) } else { $f.FullPath.PadRight(41) }

        Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $rankStr -ForegroundColor DarkGray -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $fnTrim -ForegroundColor White -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $szStr -ForegroundColor Yellow -NoNewline
        Write-Host " │ " -ForegroundColor DarkCyan -NoNewline
        Write-Host $pathTrim -ForegroundColor DarkGray -NoNewline
        Write-Host " │" -ForegroundColor DarkCyan
        $idx++
    }

    Write-Host "└────┴──────────────────────────────────┴───────────┴───────────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Recommendations {
    <#
    .SYNOPSIS
        Displays quick diagnostic shortcuts and CLI tips.
    #>
    Write-Host "Commands & Next Steps:" -ForegroundColor Cyan
    Write-Host "  • Inspect largest files on drive C:      " -ForegroundColor DarkGray -NoNewline
    Write-Host ".\Analyze-DiskSpace.ps1 -Drive C: -TopFiles 20" -ForegroundColor White
    Write-Host "  • Inspect largest directories:          " -ForegroundColor DarkGray -NoNewline
    Write-Host ".\Analyze-DiskSpace.ps1 -Drive C: -TopFolders 10" -ForegroundColor White
    Write-Host "  • Open native Windows Storage Sense:    " -ForegroundColor DarkGray -NoNewline
    Write-Host ".\Analyze-DiskSpace.ps1 -OpenSettings" -ForegroundColor White
    Write-Host "  • Export report to JSON:                " -ForegroundColor DarkGray -NoNewline
    Write-Host ".\Analyze-DiskSpace.ps1 -ExportFormat JSON -OutFile .\report.json" -ForegroundColor White
    Write-Host ""
}
