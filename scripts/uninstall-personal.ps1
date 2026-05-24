<#
.SYNOPSIS
    Removes agent-forge outputs from the user profile.
.DESCRIPTION
    Deletes files and directories previously installed by install-personal.ps1
    for GitHub Copilot and Claude Code.
.PARAMETER Platform
    Target platform: copilot, claude, or all.
.EXAMPLE
    .\uninstall-personal.ps1 -Platform copilot
    .\uninstall-personal.ps1 -Platform all
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet("copilot", "claude", "all")]
    [string]$Platform
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$platformsDir = Join-Path $root "platforms"

function Remove-PathSafe {
    param([string]$PathToRemove)

    if (-not (Test-Path $PathToRemove)) {
        Write-Host "  [SKIP] Missing: $PathToRemove" -ForegroundColor Yellow
        return
    }

    Remove-Item -Path $PathToRemove -Force -Recurse
    Write-Host "  [DEL] $PathToRemove" -ForegroundColor Green
}

function Remove-AgentVariants {
    param([string]$Directory, [string]$CanonicalFileName)

    if (-not (Test-Path $Directory)) {
        return
    }

    $pattern = ""
    if ($CanonicalFileName -match '^(?<stem>.+?)\.agent\.md$') {
        $stem = [regex]::Escape($Matches['stem'])
        $pattern = "^(?:.+-)?${stem}(?:-.+)?\.agent\.md$"
    }
    elseif ($CanonicalFileName -match '^(?<stem>.+?)\.mdc$') {
        $stem = [regex]::Escape($Matches['stem'])
        $pattern = "^(?:.+-)?${stem}(?:-.+)?\.mdc$"
    }
    elseif ($CanonicalFileName -match '^(?<stem>.+?)\.md$') {
        $stem = [regex]::Escape($Matches['stem'])
        $pattern = "^(?:.+-)?${stem}(?:-.+)?\.md$"
    }
    else {
        $escapedName = [regex]::Escape($CanonicalFileName)
        $pattern = "(^.+-)?$escapedName$"
    }

    foreach ($entry in (Get-ChildItem -Path $Directory -File -ErrorAction SilentlyContinue)) {
        if ($entry.Name -match $pattern) {
            Remove-PathSafe -PathToRemove $entry.FullName
        }
    }
}

function Uninstall-Copilot {
    Write-Host "`n=== Removing GitHub Copilot files ===" -ForegroundColor Cyan

    $userPrompts = Join-Path $env:APPDATA "Code\User\prompts"
    $copilotDir = Join-Path $platformsDir "copilot"

    $agentsDir = Join-Path $copilotDir "agents"
    if (Test-Path $agentsDir) {
        foreach ($file in (Get-ChildItem "$agentsDir\*.agent.md" -File)) {
            Remove-AgentVariants -Directory $userPrompts -CanonicalFileName $file.Name
        }
    }

    $instructionsDir = Join-Path $copilotDir "instructions"
    if (Test-Path $instructionsDir) {
        foreach ($file in (Get-ChildItem "$instructionsDir\*.instructions.md" -File)) {
            Remove-PathSafe -PathToRemove (Join-Path $userPrompts "instructions\$($file.Name)")
        }
    }

    $promptsDir = Join-Path $copilotDir "prompts"
    if (Test-Path $promptsDir) {
        foreach ($file in (Get-ChildItem "$promptsDir\*.prompt.md" -File)) {
            Remove-PathSafe -PathToRemove (Join-Path $userPrompts $file.Name)
        }
    }

    $skillsSource = Join-Path $root "canonical\skills"
    $skillsDest = Join-Path $env:USERPROFILE ".copilot\skills"
    if (Test-Path $skillsSource) {
        foreach ($dir in (Get-ChildItem $skillsSource -Directory)) {
            Remove-PathSafe -PathToRemove (Join-Path $skillsDest $dir.Name)
        }
    }

    Write-Host "`n[OK] Copilot uninstall complete" -ForegroundColor Green
}

function Uninstall-Claude {
    Write-Host "`n=== Removing Claude Code files ===" -ForegroundColor Cyan

    $claudeHome = Join-Path $env:USERPROFILE ".claude"
    $claudeDir = Join-Path $platformsDir "claude"

    $agentsDir = Join-Path $claudeDir "agents"
    if (Test-Path $agentsDir) {
        foreach ($file in (Get-ChildItem "$agentsDir\*.md" -File)) {
            Remove-AgentVariants -Directory (Join-Path $claudeHome "agents") -CanonicalFileName $file.Name
        }
    }

    $commandsDir = Join-Path $claudeDir "commands"
    if (Test-Path $commandsDir) {
        foreach ($file in (Get-ChildItem "$commandsDir\*.md" -File)) {
            Remove-PathSafe -PathToRemove (Join-Path $claudeHome "commands\$($file.Name)")
        }
    }

    Write-Host "`n[OK] Claude Code uninstall complete" -ForegroundColor Green
}

switch ($Platform) {
    "copilot" { Uninstall-Copilot }
    "claude"  { Uninstall-Claude }
    "all"     { Uninstall-Copilot; Uninstall-Claude }
}

Write-Host "`n=== Personal Uninstall Complete ===" -ForegroundColor Cyan
Write-Host "Platform: $Platform"