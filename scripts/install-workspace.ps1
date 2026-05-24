<#
.SYNOPSIS
    Installs agent-forge outputs into a workspace/project directory.
.DESCRIPTION
    Copies platform-specific files into the correct locations within a project.
    Supports selective agent installation via -Agents parameter.
.PARAMETER Path
    Path to the target workspace/project directory.
.PARAMETER Platform
    Target platform(s): copilot, claude, codex, cursor, windsurf, or all.
.PARAMETER Agents
    Optional. Comma-separated list of agent names to install. If omitted, installs all.
.PARAMETER AgentNamePrefix
    Optional prefix added to installed Copilot/Claude/Cursor agent names.
    Useful when distinguishing variants (for example: cp-, ws-, team-).
.PARAMETER Force
    Overwrite existing files.
.EXAMPLE
    .\install-workspace.ps1 -Path "C:\projects\myapp" -Platform copilot
    .\install-workspace.ps1 -Path "C:\projects\myapp" -Platform copilot -AgentNamePrefix "ws-"
    .\install-workspace.ps1 -Path "C:\projects\myapp" -Platform all -Agents qa-tester,devops
#>
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [ValidateSet("copilot", "claude", "codex", "cursor", "windsurf", "all")]
    [string]$Platform,

    [string]$Agents,

    [string]$AgentNamePrefix = "",

    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$platformsDir = Join-Path $root "platforms"

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

function Copy-AgentWithPrefix {
    param([string]$Source, [string]$Dest, [string]$Prefix)

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
        $updatedName = "$Prefix$originalName"
        $content = [regex]::Replace($content, '(?m)^name:\s*.+$', "name: $updatedName", 1)
    }

    Set-Content -Path $Dest -Value $content -Encoding UTF8
    Write-Host "  [OK] $Dest (name prefixed: $Prefix)" -ForegroundColor Green
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
            $dest = Join-Path $Path ".github\agents\$($file.Name)"
            if ([string]::IsNullOrWhiteSpace($AgentNamePrefix)) {
                Copy-SafeFile $file.FullName $dest
            } else {
                Copy-AgentWithPrefix -Source $file.FullName -Dest $dest -Prefix $AgentNamePrefix
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
            $dest = Join-Path $Path ".claude\agents\$($file.Name)"
            if ([string]::IsNullOrWhiteSpace($AgentNamePrefix)) {
                Copy-SafeFile $file.FullName $dest
            } else {
                Copy-AgentWithPrefix -Source $file.FullName -Dest $dest -Prefix $AgentNamePrefix
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

# ---------- Cursor ----------

function Install-CursorWorkspace {
    Write-Host "`n=== Installing Cursor files ===" -ForegroundColor Cyan
    $src = Join-Path $platformsDir "cursor"

    # .cursorrules
    $rules = Join-Path $src ".cursorrules"
    if (Test-Path $rules) {
        Copy-SafeFile $rules (Join-Path $Path ".cursorrules")
    }

    # .cursor/rules/*.mdc
    foreach ($file in (Get-ChildItem "$src\rules\*.mdc" -ErrorAction SilentlyContinue)) {
        if (Should-Include $file.BaseName) {
            $dest = Join-Path $Path ".cursor\rules\$($file.Name)"
            if ([string]::IsNullOrWhiteSpace($AgentNamePrefix)) {
                Copy-SafeFile $file.FullName $dest
            } else {
                Copy-AgentWithPrefix -Source $file.FullName -Dest $dest -Prefix $AgentNamePrefix
            }
        }
    }
}

# ---------- Windsurf ----------

function Install-WindsurfWorkspace {
    Write-Host "`n=== Installing Windsurf files ===" -ForegroundColor Cyan
    $rules = Join-Path $platformsDir "windsurf\.windsurfrules"
    if (Test-Path $rules) {
        Copy-SafeFile $rules (Join-Path $Path ".windsurfrules")
    }
}

# ---------- Main ----------

$platforms = if ($Platform -eq "all") {
    @("copilot", "claude", "codex", "cursor", "windsurf")
} else {
    @($Platform)
}

foreach ($p in $platforms) {
    switch ($p) {
        "copilot"  { Install-CopilotWorkspace }
        "claude"   { Install-ClaudeWorkspace }
        "codex"    { Install-CodexWorkspace }
        "cursor"   { Install-CursorWorkspace }
        "windsurf" { Install-WindsurfWorkspace }
    }
}

Write-Host "`n=== Workspace Install Complete ===" -ForegroundColor Cyan
Write-Host "Target: $Path"
Write-Host "Platform: $Platform"
if ($agentFilter) { Write-Host "Agents: $($agentFilter -join ', ')" }
