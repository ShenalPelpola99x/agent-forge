<#
.SYNOPSIS
    Installs agent-forge outputs to user profile for personal cross-workspace use.
.DESCRIPTION
    Creates symlinks from platform outputs to user profile locations so agents,
    skills, instructions, and prompts are available in all workspaces.
.PARAMETER Platform
    Target platform: copilot, claude, or all.
.PARAMETER Force
    Remove existing symlinks before creating new ones.
.EXAMPLE
    .\install-personal.ps1 -Platform copilot
    .\install-personal.ps1 -Platform all
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet("copilot", "claude", "all")]
    [string]$Platform,

    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$platformsDir = Join-Path $root "platforms"

function New-SymlinkSafe {
    param([string]$Link, [string]$Target, [switch]$IsDirectory)
    
    if (Test-Path $Link) {
        if ($Force) {
            Remove-Item $Link -Force -Recurse
            Write-Host "  🗑️  Removed existing: $Link" -ForegroundColor Yellow
        } else {
            Write-Host "  ⏭️  Skipped (exists): $Link" -ForegroundColor Yellow
            return
        }
    }

    $parentDir = Split-Path $Link -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if ($IsDirectory) {
        New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
    } else {
        New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-Null
    }
    Write-Host "  ✅ $Link → $Target" -ForegroundColor Green
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
            $link = Join-Path $userPrompts $file.Name
            New-SymlinkSafe -Link $link -Target $file.FullName
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

    Write-Host "`n✅ Copilot install complete" -ForegroundColor Green
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
            $link = Join-Path $claudeHome "agents\$($file.Name)"
            New-SymlinkSafe -Link $link -Target $file.FullName
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

    Write-Host "`n✅ Claude Code install complete" -ForegroundColor Green
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
