<#
.SYNOPSIS
    Installs agent-forge outputs into a workspace/project directory.
.DESCRIPTION
    Copies platform-specific files into the correct locations within a project.
    Supports selective agent installation via -Agents parameter.
.PARAMETER Path
    Path to the target workspace/project directory.
.PARAMETER Platform
    Target platform(s): copilot, claude, codex, or all.
.PARAMETER Agents
    Optional. Comma-separated list of agent names to install. If omitted, installs all.
.PARAMETER AgentNamePrefix
    Optional prefix added to installed Copilot/Claude agent names.
    Useful when distinguishing variants (for example: cp-, ws-, team-).
.PARAMETER AgentNameSuffix
    Optional suffix added to installed Copilot/Claude agent names.
    Useful when distinguishing platform variants (for example: -claude, -copilot).
.PARAMETER Force
    Overwrite existing files.
.EXAMPLE
    .\install-workspace.ps1 -Path "C:\projects\myapp" -Platform copilot
    .\install-workspace.ps1 -Path "C:\projects\myapp" -Platform copilot -AgentNamePrefix "ws-"
    .\install-workspace.ps1 -Path "C:\projects\myapp" -Platform claude -AgentNameSuffix "-claude"
    .\install-workspace.ps1 -Path "C:\projects\myapp" -Platform all -Agents qa-tester,devops
#>
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [ValidateSet("copilot", "claude", "codex", "all")]
    [string]$Platform,

    [string]$Agents,

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

if (-not (Test-Path $Path)) {
    Write-Error "Workspace path not found: $Path"
    exit 1
}

$agentFilter = if ($Agents) { $Agents -split "," | ForEach-Object { $_.Trim() } } else { $null }

function Copy-SafeFile {
    param([string]$Source, [string]$Dest)
    
    if ((Test-Path $Dest) -and -not $Force) {
        Write-Host "  [SKIP] Exists: $Dest" -ForegroundColor Yellow
        return
    }
    $destDir = Split-Path $Dest -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Copy-Item $Source $Dest -Force
    Write-Host "  [OK] $Dest" -ForegroundColor Green
}

function Copy-AgentWithAffixes {
    param([string]$Source, [string]$Dest, [string]$Prefix, [string]$Suffix)

    if ((Test-Path $Dest) -and -not $Force) {
        Write-Host "  [SKIP] Exists: $Dest" -ForegroundColor Yellow
        return
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

function Should-Include {
    param([string]$FileName)
    if (-not $agentFilter) { return $true }
    foreach ($a in $agentFilter) {
        if ($FileName -match "^$a\b") { return $true }
    }
    return $false
}

# ---------- Copilot ----------

function Install-CopilotWorkspace {
    Write-Host "`n=== Installing Copilot files ===" -ForegroundColor Cyan
    $src = Join-Path $platformsDir "copilot"

    # Agents
    foreach ($file in (Get-ChildItem "$src\agents\*.agent.md" -ErrorAction SilentlyContinue)) {
        if (Should-Include $file.BaseName) {
            $installedName = Get-DecoratedFileName -FileName $file.Name -Prefix $AgentNamePrefix -Suffix $AgentNameSuffix
            $dest = Join-Path $Path ".github\agents\$installedName"
            if ([string]::IsNullOrWhiteSpace($AgentNamePrefix) -and [string]::IsNullOrWhiteSpace($AgentNameSuffix)) {
                Copy-SafeFile $file.FullName $dest
            } else {
                Copy-AgentWithAffixes -Source $file.FullName -Dest $dest -Prefix $AgentNamePrefix -Suffix $AgentNameSuffix
            }
        }
    }

    # Instructions
    foreach ($file in (Get-ChildItem "$src\instructions\*.instructions.md" -ErrorAction SilentlyContinue)) {
        Copy-SafeFile $file.FullName (Join-Path $Path ".github\instructions\$($file.Name)")
    }

    # Prompts
    foreach ($file in (Get-ChildItem "$src\prompts\*.prompt.md" -ErrorAction SilentlyContinue)) {
        Copy-SafeFile $file.FullName (Join-Path $Path ".github\prompts\$($file.Name)")
    }
}

# ---------- Claude Code ----------

function Install-ClaudeWorkspace {
    Write-Host "`n=== Installing Claude Code files ===" -ForegroundColor Cyan
    $src = Join-Path $platformsDir "claude"

    # CLAUDE.md
    $claudeMd = Join-Path $src "CLAUDE.md"
    if (Test-Path $claudeMd) {
        Copy-SafeFile $claudeMd (Join-Path $Path "CLAUDE.md")
    }

    # Agents
    foreach ($file in (Get-ChildItem "$src\agents\*.md" -ErrorAction SilentlyContinue)) {
        if (Should-Include $file.BaseName) {
            $installedName = Get-DecoratedFileName -FileName $file.Name -Prefix $AgentNamePrefix -Suffix $AgentNameSuffix
            $dest = Join-Path $Path ".claude\agents\$installedName"
            if ([string]::IsNullOrWhiteSpace($AgentNamePrefix) -and [string]::IsNullOrWhiteSpace($AgentNameSuffix)) {
                Copy-SafeFile $file.FullName $dest
            } else {
                Copy-AgentWithAffixes -Source $file.FullName -Dest $dest -Prefix $AgentNamePrefix -Suffix $AgentNameSuffix
            }
        }
    }

    # Commands
    foreach ($file in (Get-ChildItem "$src\commands\*.md" -ErrorAction SilentlyContinue)) {
        Copy-SafeFile $file.FullName (Join-Path $Path ".claude\commands\$($file.Name)")
    }
}

# ---------- Codex ----------

function Install-CodexWorkspace {
    Write-Host "`n=== Installing Codex files ===" -ForegroundColor Cyan
    $agentsMd = Join-Path $platformsDir "codex\AGENTS.md"
    if (Test-Path $agentsMd) {
        Copy-SafeFile $agentsMd (Join-Path $Path "AGENTS.md")
    }
}

# ---------- Main ----------

$platforms = if ($Platform -eq "all") {
    @("copilot", "claude", "codex")
} else {
    @($Platform)
}

foreach ($p in $platforms) {
    switch ($p) {
        "copilot"  { Install-CopilotWorkspace }
        "claude"   { Install-ClaudeWorkspace }
        "codex"    { Install-CodexWorkspace }
    }
}

Write-Host "`n=== Workspace Install Complete ===" -ForegroundColor Cyan
Write-Host "Target: $Path"
Write-Host "Platform: $Platform"
if ($agentFilter) { Write-Host "Agents: $($agentFilter -join ', ')" }
