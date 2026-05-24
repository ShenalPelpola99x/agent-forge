<#
.SYNOPSIS
    Builds platform-specific agent/skill/instruction outputs from canonical sources.
.DESCRIPTION
    Reads canonical/ and generates platform-specific files in platforms/ for
    Copilot, Claude Code, Codex, Cursor, and Windsurf.
.PARAMETER Agent
    Optional. Build only a specific agent by name. If omitted, builds all.
.PARAMETER Force
    Overwrite existing platform outputs.
.EXAMPLE
    .\build-platforms.ps1
    .\build-platforms.ps1 -Agent qa-tester
#>
param(
    [string]$Agent,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$canonical = Join-Path $root "canonical"
$platforms = Join-Path $root "platforms"

function Parse-Frontmatter {
    param([string]$Content)
    $result = @{}
    if ($Content -match "^---\s*\r?\n([\s\S]*?)\r?\n---") {
        $fm = $Matches[1]
        foreach ($line in ($fm -split "`n")) {
            if ($line -match "^(\w[\w-]*):\s*(.+)") {
                $key = $Matches[1].Trim()
                $val = $Matches[2].Trim().Trim('"').Trim("'")
                $result[$key] = $val
            }
        }
        # Parse array fields
        $arrayFields = @("tools", "subagents", "requires_skills", "requires_mcp", "tags")
        foreach ($field in $arrayFields) {
            if ($fm -match "(?m)^${field}:\s*$") {
                $items = @()
                $inField = $false
                foreach ($l in ($fm -split "`n")) {
                    if ($l -match "^${field}:\s*$") { $inField = $true; continue }
                    if ($inField -and $l -match "^\s+-\s+(.+)") { $items += $Matches[1].Trim().Trim('"').Trim("'") }
                    elseif ($inField -and $l -match "^\w") { break }
                }
                $result[$field] = $items
            }
        }
    }
    return $result
}

function Get-Body {
    param([string]$Content)
    if ($Content -match "^---\s*\r?\n[\s\S]*?\r?\n---\s*\r?\n(.*)$") {
        return $Matches[1]
    }
    return $Content
}

# ---------- Build Agents ----------

$agentDir = Join-Path $canonical "agents"
$agentFiles = if ($Agent) {
    @(Get-ChildItem "$agentDir\$Agent.md" -ErrorAction SilentlyContinue)
} else {
    @(Get-ChildItem "$agentDir\*.md" -ErrorAction SilentlyContinue)
}

$registry = @{ agents = @(); skills = @(); prompts = @() }

foreach ($file in $agentFiles) {
    $content = Get-Content $file.FullName -Raw
    $fm = Parse-Frontmatter $content
    $body = Get-Body $content
    $name = $fm["name"]
    if (-not $name) { $name = $file.BaseName }

    Write-Host "Building agent: $name" -ForegroundColor Cyan

    # --- Copilot (.agent.md) ---
    $copilotTools = @()
    if ($fm["tools"] -is [array]) { $copilotTools = $fm["tools"] }
    $toolsYaml = if ($copilotTools.Count -gt 0) {
        "`ntools:`n" + ($copilotTools | ForEach-Object { "  - $_" }) -join "`n"
    } else { "" }
    
    $agentsYaml = ""
    if ($fm["subagents"] -is [array] -and $fm["subagents"].Count -gt 0) {
        $agentsYaml = "`nagents:`n" + ($fm["subagents"] | ForEach-Object { "  - $_" }) -join "`n"
    }
    
    $modelYaml = if ($fm["model"]) { "`nmodel: $($fm["model"])" } else { "" }
    
    $copilotContent = @"
---
description: "$($fm["description"])"$toolsYaml$modelYaml$agentsYaml
---

$body
"@
    $copilotPath = Join-Path $platforms "copilot\agents\$name.agent.md"
    $copilotContent | Set-Content $copilotPath -Encoding UTF8
    Write-Host "  ✅ Copilot: $name.agent.md" -ForegroundColor Green

    # --- Claude Code (.md) ---
    $claudeContent = $body
    if ($fm["model"]) {
        $claudeContent += "`n`n## Model`n`n$($fm["model"])`n"
    }
    $claudePath = Join-Path $platforms "claude\agents\$name.md"
    $claudeContent | Set-Content $claudePath -Encoding UTF8
    Write-Host "  ✅ Claude: agents/$name.md" -ForegroundColor Green

    # --- Cursor (.mdc) ---
    $cursorContent = @"
---
description: "$($fm["description"])"
alwaysApply: false
---

$body
"@
    $cursorPath = Join-Path $platforms "cursor\rules\$name.mdc"
    $cursorContent | Set-Content $cursorPath -Encoding UTF8
    Write-Host "  ✅ Cursor: rules/$name.mdc" -ForegroundColor Green

    # Registry entry
    $registry.agents += @{
        name = $name
        version = if ($fm["version"]) { $fm["version"] } else { "1.0.0" }
        description = $fm["description"]
        platforms = @("copilot", "claude", "codex", "cursor", "windsurf")
        tags = if ($fm["tags"] -is [array]) { $fm["tags"] } else { @() }
        requires_skills = if ($fm["requires_skills"] -is [array]) { $fm["requires_skills"] } else { @() }
        requires_mcp = if ($fm["requires_mcp"] -is [array]) { $fm["requires_mcp"] } else { @() }
        model_recommendation = if ($fm["model"]) { $fm["model"] } else { "sonnet" }
    }
}

# --- Codex (AGENTS.md) ---
if ($agentFiles.Count -gt 0) {
    $codexContent = "# Project Agents`n`n"
    foreach ($file in $agentFiles) {
        $content = Get-Content $file.FullName -Raw
        $body = Get-Body $content
        $codexContent += "$body`n`n---`n`n"
    }
    $codexPath = Join-Path $platforms "codex\AGENTS.md"
    $codexContent | Set-Content $codexPath -Encoding UTF8
    Write-Host "  ✅ Codex: AGENTS.md" -ForegroundColor Green
}

# --- Windsurf (.windsurfrules) ---
if ($agentFiles.Count -gt 0) {
    $windsurfContent = "# Project Rules and Agents`n`n"
    foreach ($file in $agentFiles) {
        $content = Get-Content $file.FullName -Raw
        $fm = Parse-Frontmatter $content
        $body = Get-Body $content
        $name = if ($fm["name"]) { $fm["name"] } else { $file.BaseName }
        $windsurfContent += "## Agent: $name`n`n$body`n`n---`n`n"
    }
    $windsurfPath = Join-Path $platforms "windsurf\.windsurfrules"
    $windsurfContent | Set-Content $windsurfPath -Encoding UTF8
    Write-Host "  ✅ Windsurf: .windsurfrules" -ForegroundColor Green
}

# ---------- Build Instructions ----------

$instrDir = Join-Path $canonical "instructions"
if (Test-Path $instrDir) {
    $instrFiles = Get-ChildItem "$instrDir\*.md" -ErrorAction SilentlyContinue
    foreach ($file in $instrFiles) {
        $content = Get-Content $file.FullName -Raw
        $fm = Parse-Frontmatter $content
        $body = Get-Body $content
        $name = $file.BaseName

        # Copilot .instructions.md
        $applyTo = if ($fm["applyTo"]) { "`napplyTo: `"$($fm["applyTo"])`"" } else { "" }
        $copilotInstr = "---`ndescription: `"$($fm["description"])`"$applyTo`n---`n`n$body"
        $copilotInstrPath = Join-Path $platforms "copilot\instructions\$name.instructions.md"
        $copilotInstr | Set-Content $copilotInstrPath -Encoding UTF8
        Write-Host "  ✅ Copilot instruction: $name.instructions.md" -ForegroundColor Green
    }
}

# ---------- Build Prompts ----------

$promptDir = Join-Path $canonical "prompts"
if (Test-Path $promptDir) {
    $promptFiles = Get-ChildItem "$promptDir\*.md" -ErrorAction SilentlyContinue
    foreach ($file in $promptFiles) {
        $content = Get-Content $file.FullName -Raw
        $fm = Parse-Frontmatter $content
        $body = Get-Body $content
        $name = $file.BaseName

        # Copilot .prompt.md
        $copilotPrompt = "---`ndescription: `"$($fm["description"])`"`n---`n`n$body"
        $copilotPromptPath = Join-Path $platforms "copilot\prompts\$name.prompt.md"
        $copilotPrompt | Set-Content $copilotPromptPath -Encoding UTF8
        Write-Host "  ✅ Copilot prompt: $name.prompt.md" -ForegroundColor Green

        # Claude command
        $claudeCmdPath = Join-Path $platforms "claude\commands\$name.md"
        $body | Set-Content $claudeCmdPath -Encoding UTF8
        Write-Host "  ✅ Claude command: commands/$name.md" -ForegroundColor Green

        $registry.prompts += @{ name = $name; description = $fm["description"] }
    }
}

# ---------- Build CLAUDE.md (composite) ----------

$claudeMdPath = Join-Path $platforms "claude\CLAUDE.md"
$claudeComposite = "# Project Instructions`n`n"
$instrDir2 = Join-Path $canonical "instructions"
if (Test-Path $instrDir2) {
    foreach ($file in (Get-ChildItem "$instrDir2\*.md" -ErrorAction SilentlyContinue)) {
        $body = Get-Body (Get-Content $file.FullName -Raw)
        $claudeComposite += "## $($file.BaseName)`n`n$body`n`n---`n`n"
    }
}
$claudeComposite | Set-Content $claudeMdPath -Encoding UTF8
Write-Host "  ✅ Claude: CLAUDE.md (composite)" -ForegroundColor Green

# ---------- Write Registry ----------

$registryPath = Join-Path $root "registry.json"
$registry | ConvertTo-Json -Depth 5 | Set-Content $registryPath -Encoding UTF8
Write-Host "`n✅ Registry: registry.json" -ForegroundColor Green

# ---------- Summary ----------

Write-Host "`n=== Build Complete ===" -ForegroundColor Cyan
Write-Host "Agents: $($agentFiles.Count)"
Write-Host "Output: $platforms"
