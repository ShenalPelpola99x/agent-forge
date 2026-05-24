<#
.SYNOPSIS
    Installs agent-forge outputs to user profile for personal cross-workspace use.
.DESCRIPTION
    Creates symlinks from platform outputs to user profile locations so agents,
    skills, instructions, and prompts are available in all workspaces.
.PARAMETER Platform
    Target platform: copilot, claude, or all.
.PARAMETER AgentNamePrefix
    Optional prefix added to agent names in installed files (Copilot only).
    Useful for distinguishing personal/workspace or platform variants.
.PARAMETER AgentNameSuffix
    Optional suffix added to agent names in installed files.
    Useful for distinguishing platform variants (for example: -claude, -copilot).
.PARAMETER Force
    Remove existing symlinks before creating new ones.
.EXAMPLE
    .\install-personal.ps1 -Platform copilot
    .\install-personal.ps1 -Platform copilot -AgentNamePrefix "cp-"
    .\install-personal.ps1 -Platform claude -AgentNameSuffix "-claude"
    .\install-personal.ps1 -Platform all
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet("copilot", "claude", "all")]
    [string]$Platform,

    [string]$AgentNamePrefix = "",

    [string]$AgentNameSuffix = "",

    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$platformsDir = Join-Path $root "platforms"

function Get-DecoratedFileName {
    param([string]$FileName, [string]$Prefix, [string]$Suffix)

    if ([string]::IsNullOrWhiteSpace($Prefix) -and [string]::IsNullOrWhiteSpace($Suffix)) {
        return $FileName
    }

    $safePrefix = if ([string]::IsNullOrWhiteSpace($Prefix)) { "" } else { $Prefix }
    $safeSuffix = if ([string]::IsNullOrWhiteSpace($Suffix)) { "" } else { $Suffix }

    if ($FileName -match '^(?<stem>.+?)\.agent\.md$') {
        return "$safePrefix$($Matches['stem'])$safeSuffix.agent.md"
    }

    if ($FileName -match '^(?<stem>.+?)\.mdc$') {
        return "$safePrefix$($Matches['stem'])$safeSuffix.mdc"
    }

    if ($FileName -match '^(?<stem>.+?)\.md$') {
        return "$safePrefix$($Matches['stem'])$safeSuffix.md"
    }

    $extension = [System.IO.Path]::GetExtension($FileName)
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    return "$safePrefix$stem$safeSuffix$extension"
}

function Copy-AgentWithAffixes {
    param([string]$Source, [string]$Dest, [string]$Prefix, [string]$Suffix)

    if (Test-Path $Dest) {
        if (-not $Force) {
            Write-Host "  [SKIP] Exists: $Dest" -ForegroundColor Yellow
            return
        }
        # If destination is an existing symlink, remove it so we do not rewrite the link target.
        Remove-Item $Dest -Force -Recurse
        Write-Host "  [DEL] Removed existing: $Dest" -ForegroundColor Yellow
    }

    $destDir = Split-Path $Dest -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $content = Get-Content -Path $Source -Raw
    $nameMatch = [regex]::Match($content, '(?m)^name:\s*(.+)$')
    if ($nameMatch.Success) {
        $originalName = $nameMatch.Groups[1].Value.Trim()
        $safePrefix = if ([string]::IsNullOrWhiteSpace($Prefix)) { "" } else { $Prefix }
        $safeSuffix = if ([string]::IsNullOrWhiteSpace($Suffix)) { "" } else { $Suffix }
        $updatedName = "$safePrefix$originalName$safeSuffix"
        $content = [regex]::Replace($content, '(?m)^name:\s*.+$', "name: $updatedName", 1)
    }

    Set-Content -Path $Dest -Value $content -Encoding UTF8
    Write-Host "  [OK] $Dest (name affixes: '$Prefix' + '$Suffix')" -ForegroundColor Green
}

function New-SymlinkSafe {
    param([string]$Link, [string]$Target, [switch]$IsDirectory)
    
    if (Test-Path $Link) {
        if ($Force) {
            Remove-Item $Link -Force -Recurse
            Write-Host "  [DEL] Removed existing: $Link" -ForegroundColor Yellow
        } else {
            Write-Host "  [SKIP] Exists: $Link" -ForegroundColor Yellow
            return
        }
    }

    $parentDir = Split-Path $Link -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    try {
        if ($IsDirectory) {
            New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
        } else {
            New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-Null
        }
        Write-Host "  [OK] $Link -> $Target" -ForegroundColor Green
    }
    catch {
        # Some systems require elevation for symbolic links. Fall back to copy so install still succeeds.
        if ($IsDirectory) {
            Copy-Item -Path $Target -Destination $Link -Recurse -Force
        } else {
            Copy-Item -Path $Target -Destination $Link -Force
        }
        Write-Host "  [OK] $Link (copied fallback)" -ForegroundColor Green
    }
}

# ---------- Copilot ----------

function Install-Copilot {
    Write-Host "`n=== Installing for GitHub Copilot ===" -ForegroundColor Cyan
    
    $userPrompts = Join-Path $env:APPDATA "Code\User\prompts"
    $copilotDir = Join-Path $platformsDir "copilot"

    # Agents
    $agentsDir = Join-Path $copilotDir "agents"
    if (Test-Path $agentsDir) {
        foreach ($file in (Get-ChildItem "$agentsDir\*.agent.md")) {
            $installedName = Get-DecoratedFileName -FileName $file.Name -Prefix $AgentNamePrefix -Suffix $AgentNameSuffix
            $link = Join-Path $userPrompts $installedName
            if ([string]::IsNullOrWhiteSpace($AgentNamePrefix) -and [string]::IsNullOrWhiteSpace($AgentNameSuffix)) {
                New-SymlinkSafe -Link $link -Target $file.FullName
            } else {
                Copy-AgentWithAffixes -Source $file.FullName -Dest $link -Prefix $AgentNamePrefix -Suffix $AgentNameSuffix
            }
        }
    }

    # Instructions
    $instrDir = Join-Path $copilotDir "instructions"
    if (Test-Path $instrDir) {
        foreach ($file in (Get-ChildItem "$instrDir\*.instructions.md")) {
            $link = Join-Path $userPrompts "instructions\$($file.Name)"
            New-SymlinkSafe -Link $link -Target $file.FullName
        }
    }

    # Prompts
    $promptDir = Join-Path $copilotDir "prompts"
    if (Test-Path $promptDir) {
        foreach ($file in (Get-ChildItem "$promptDir\*.prompt.md")) {
            $link = Join-Path $userPrompts $file.Name
            New-SymlinkSafe -Link $link -Target $file.FullName
        }
    }

    # Skills (from canonical — they need the full directory structure)
    $skillsSource = Join-Path $root "canonical\skills"
    $skillsDest = Join-Path $env:USERPROFILE ".copilot\skills"
    if (Test-Path $skillsSource) {
        foreach ($dir in (Get-ChildItem $skillsSource -Directory)) {
            $link = Join-Path $skillsDest $dir.Name
            New-SymlinkSafe -Link $link -Target $dir.FullName -IsDirectory
        }
    }

    Write-Host "`n[OK] Copilot install complete" -ForegroundColor Green
}

# ---------- Claude Code ----------

function Install-Claude {
    Write-Host "`n=== Installing for Claude Code ===" -ForegroundColor Cyan
    
    $claudeHome = Join-Path $env:USERPROFILE ".claude"
    $claudeDir = Join-Path $platformsDir "claude"

    # Agents
    $agentsDir = Join-Path $claudeDir "agents"
    if (Test-Path $agentsDir) {
        foreach ($file in (Get-ChildItem "$agentsDir\*.md")) {
            $installedName = Get-DecoratedFileName -FileName $file.Name -Prefix $AgentNamePrefix -Suffix $AgentNameSuffix
            $link = Join-Path $claudeHome "agents\$installedName"
            if ([string]::IsNullOrWhiteSpace($AgentNamePrefix) -and [string]::IsNullOrWhiteSpace($AgentNameSuffix)) {
                New-SymlinkSafe -Link $link -Target $file.FullName
            } else {
                Copy-AgentWithAffixes -Source $file.FullName -Dest $link -Prefix $AgentNamePrefix -Suffix $AgentNameSuffix
            }
        }
    }

    # Commands
    $cmdsDir = Join-Path $claudeDir "commands"
    if (Test-Path $cmdsDir) {
        foreach ($file in (Get-ChildItem "$cmdsDir\*.md")) {
            $link = Join-Path $claudeHome "commands\$($file.Name)"
            New-SymlinkSafe -Link $link -Target $file.FullName
        }
    }

    Write-Host "`n[OK] Claude Code install complete" -ForegroundColor Green
}

# ---------- Main ----------

switch ($Platform) {
    "copilot" { Install-Copilot }
    "claude"  { Install-Claude }
    "all"     { Install-Copilot; Install-Claude }
}

Write-Host "`n=== Personal Install Complete ===" -ForegroundColor Cyan
Write-Host "Platform: $Platform"
Write-Host "Source: $platformsDir"
