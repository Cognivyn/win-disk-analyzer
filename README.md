# Win Disk Analyzer (`win-disk-analyzer`)

> **Native, zero-dependency, strictly read-only Windows disk space analyzer & diagnostic utility.**

[![Security: Read-Only](https://img.shields.io/badge/Security-Strictly%20Read--Only-success?style=flat-square)](#-security-policy--read-only-guarantee)
[![Privilege: Non-Elevated](https://img.shields.io/badge/Privilege-Standard%20User-blue?style=flat-square)](#-security-policy--read-only-guarantee)
[![Runtime: PowerShell 5.1+](https://img.shields.io/badge/Runtime-PowerShell%205.1%20%7C%207%2B-informational?style=flat-square)](#requirements)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)](LICENSE)

---

## 🛡️ Security Policy & Read-Only Guarantee

**Security is the #1 priority of this utility.**

- 🔒 **Zero State Mutation**: This utility is strictly read-only. It contains **no code paths** for deleting, cleaning, moving, or altering any file, folder, volume, or registry key.
- 🛡️ **No Blind Remote Execution**: We explicitly **reject** piping downloaded web scripts directly into `Invoke-Expression` (`irm ... | iex`). The script should always be cloned, reviewed, and audited locally before execution under your organization's PowerShell `ExecutionPolicy`.
- 👤 **Least Privilege Operation**: Operates entirely in non-administrator user sessions. No administrative rights or UAC elevation are required or requested.
- 🛑 **Safe Exception Handling**: Gracefully skips locked, protected, or inaccessible directories (such as `System Volume Information`) without modifying access control lists (ACLs) or taking file ownership.

---

## ⚡ Quick Start

Clone or download the repository to inspect and run locally:

```powershell
# Clone the repository
git clone https://github.com/Cognivyn/win-disk-analyzer.git
cd win-disk-analyzer

# Audit all local drives (Default view)
.\Analyze-DiskSpace.ps1
```

---

## 📖 Usage & Examples

### 1. Volume Health & Capacity Overview (Default)
Inspects all fixed local drives, calculates free/used percentages, and renders visual ASCII health bars:

```powershell
.\Analyze-DiskSpace.ps1
```

Output:
```text
[SECURITY NOTICE] Strict Read-Only Mode active. No files will be modified or deleted.

Auditing storage volumes (Read-Only Diagnostic)...

Drive Label Total     Used      Free      % Free Usage Graph          Health
----- ----- -----     ----      ----      ------ -----------          ------
C:    OS    475.69 GB 312.44 GB 163.25 GB 34.3%  [#############-------] HEALTHY
D:    Data  931.51 GB 820.10 GB 111.41 GB 12.0%  [##################--] WARNING
```

### 2. Find Largest Files
Locate space-consuming files across a target drive or folder without scanning locked system partitions:

```powershell
# Find top 20 largest files on C: drive
.\Analyze-DiskSpace.ps1 -Drive C: -TopFiles 20

# Find top 50 largest files inside a specific directory
.\Analyze-DiskSpace.ps1 -Path "D:\Projects" -TopFiles 50
```

### 3. Measure Top-Level Directory Sizes
Calculates aggregated directory sizes for root or user folders:

```powershell
# Measure top 10 heaviest directories on C:
.\Analyze-DiskSpace.ps1 -Drive C: -TopFolders 10
```

### 4. Export Diagnostic Reports
Export the inspection snapshot to CSV or JSON for reporting or infrastructure audit:

```powershell
# Export volume summary to JSON
.\Analyze-DiskSpace.ps1 -ExportFormat JSON -OutFile .\disk-audit.json

# Export top 100 largest files to CSV
.\Analyze-DiskSpace.ps1 -Drive C: -TopFiles 100 -ExportFormat CSV -OutFile .\heavy-files.csv
```

### 5. Launch Windows Native Storage Sense
Open the Windows built-in Storage Sense GUI directly from the terminal:

```powershell
.\Analyze-DiskSpace.ps1 -OpenSettings
```

---

## 📋 Parameter Reference

| Parameter | Type | Default | Description |
|---|---|---|---|
| `-Drive` | String | None | Target drive letter to inspect (e.g. `C:`, `D`). Validated with regex `^[a-zA-Z]:?$`. |
| `-Path` | String | None | Specific directory path to inspect. |
| `-TopFiles` | Integer | 20 | Number of largest files to return (1-1000). |
| `-TopFolders` | Integer | 10 | Number of top subdirectories to calculate sizes for (1-100). |
| `-OpenSettings` | Switch | False | Launches native Windows Storage Sense (`ms-settings:storagesense`). |
| `-ExportFormat` | String | None | Output format for report: `CSV` or `JSON`. |
| `-OutFile` | String | None | File path for the exported report. |
| `-Summary` | Switch | True | Displays overall storage volume summary table. |

---

## 🛠️ Native Windows Command Fallbacks (Zero Download)

If you are on a restricted machine where you cannot clone git repositories, you can run these native Windows one-liners:

### Overall Drive Summary
```powershell
Get-Volume | Select-Object DriveLetter, FileSystemLabel, 
    @{Name="Size(GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}}, 
    @{Name="Free(GB)"; Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}}, 
    @{Name="% Free"; Expression={[math]::Round(($_.SizeRemaining / $_.Size) * 100, 1)}} | 
    Sort-Object "% Free"
```

### Top 20 Largest Files (PowerShell)
```powershell
Get-ChildItem -Path C:\ -Recurse -File -Force -ErrorAction SilentlyContinue | 
    Sort-Object Length -Descending | 
    Select-Object -First 20 FullName, @{Name="Size(GB)"; Expression={[math]::Round($_.Length / 1GB, 2)}} | 
    Format-Table -AutoSize
```

### Top-Level Folder Breakdown (PowerShell)
```powershell
Get-ChildItem -Path C:\ -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $size = (Get-ChildItem -Path $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        Folder     = $_.FullName
        "Size(GB)" = [math]::Round($size / 1GB, 2)
    }
} | Sort-Object "Size(GB)" -Descending | Format-Table -AutoSize
```

### Windows CMD (Command Prompt)
```cmd
wmic logicaldisk get Caption, FreeSpace, Size
```

---

## 💻 Requirements
- **OS**: Windows 10, Windows 11, or Windows Server 2016+
- **Shell**: Windows PowerShell 5.1 or PowerShell Core 7+
- **Privilege**: Standard User (Administrator privilege **not** required)

---

## 📄 License
Released under the [MIT License](LICENSE). Maintained by [Cognivyn](https://github.com/Cognivyn).
