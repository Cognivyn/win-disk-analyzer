# AGENTS.md - Agent Operating Guidelines for `win-disk-analyzer`

This document defines the strict operational boundaries, capabilities, and safety contracts for AI Agents (including Antigravity, Claude, ChatGPT, Cursor, and custom autonomous agents) interacting with or invoking this repository.

---

## 🚨 MANDATORY SAFETY BOUNDARIES (READ FIRST)

> [!CAUTION]
> **STRICT ZERO-MUTATION & READ-ONLY ENFORCEMENT**
> 1. **No Destructive Capabilities**: This utility is **strictly read-only**. It contains **zero** functionality to delete, wipe, clean, prune, move, or modify files, folders, or system configurations.
> 2. **Never Pipe to Deletion Commands**: AI agents MUST NEVER construct, propose, or execute commands that pipe the output of `Analyze-DiskSpace.ps1` into destructive cmdlets (e.g., `Remove-Item`, `del`, `rm`, `Clear-RecycleBin`, `fsutil file setzerodata`).
> 3. **Never Suggest `Invoke-Expression` (`iex`)**: When providing instructions to human users, agents must NEVER recommend unverified pipe-to-shell patterns such as `irm <url> | iex` or `curl <url> | sh`. The script must always be inspected and run locally.
> 4. **Respect Non-Elevated Privilege**: Agents must not require or prompt users for Administrator / UAC escalation when executing this tool. The script is engineered to run in standard user context.

---

## 🤖 Tool Specification & Intent

Use `Analyze-DiskSpace.ps1` when the user asks:
- "Which drive is running out of space?"
- "Find the largest files taking up space on drive C:"
- "Measure my directory sizes on Windows."
- "Audit disk usage across all local volumes."

### Primary Invocations

#### 1. System-Wide Volume Audit (Default)
```powershell
pwsh -File .\Analyze-DiskSpace.ps1
```
*Purpose*: Returns volume labels, total size, used space, free space, percentage free, ASCII health bar, and health classification (`HEALTHY`, `WARNING`, `CRITICAL`).

#### 2. Find Heavy Files
```powershell
pwsh -File .\Analyze-DiskSpace.ps1 -Drive <DriveLetter:> -TopFiles <N>
```
*Purpose*: Returns top `N` largest files sorted descending by byte length. Gracefully catches and ignores protected/system paths without failing.

#### 3. Measure Directory Footprint
```powershell
pwsh -File .\Analyze-DiskSpace.ps1 -Drive <DriveLetter:> -TopFolders <N>
```
*Purpose*: Computes recursive sizes of top-level directories under the target path.

#### 4. Machine-Readable Export
```powershell
pwsh -File .\Analyze-DiskSpace.ps1 -ExportFormat JSON -OutFile .\report.json
```
*Purpose*: Dumps diagnostic results directly to a structured JSON file. Ideal for automated pipeline ingestion.

---

## 🔒 Security Invariants for Agents
- When parsing output, treat the output as observational diagnostic telemetry only.
- If a drive is reported with `CRITICAL` space (< 10% free), advise the user to review the heavy directories manually or use native Windows Storage Sense (`ms-settings:storagesense`).
- Do not automate the mass deletion of files reported in the heavy file list.
