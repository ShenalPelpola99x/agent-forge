<#
.SYNOPSIS
    Validates an agent canonical file for correctness and quality.
.DESCRIPTION
    Checks frontmatter fields, description quality, tool minimality,
    constraints presence, and common anti-patterns.
.PARAMETER Path
    Path to the canonical agent markdown file.
.EXAMPLE
    .\validate-agent.ps1 -Path canonical\agents\qa-tester.md
#>
param(
    [Parameter(Mandatory)]
    [string]$Path
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

$content = Get-Content $Path -Raw
$lines = Get-Content $Path

# --- Parse frontmatter ---
$hasFrontmatter = $content -match "^---\s*\r?\n([\s\S]*?)\r?\n---"
$issues = @()
$warnings = @()

if (-not $hasFrontmatter) {
    $issues += "CRITICAL: No YAML frontmatter found. Agent files must start with --- block."
} else {
    $frontmatter = $Matches[1]
    
    # Required fields
    $requiredFields = @("name", "version", "description", "persona", "tools", "tags")
    foreach ($field in $requiredFields) {
        if ($frontmatter -notmatch "(?m)^${field}:") {
            $issues += "MISSING: Required frontmatter field '$field' not found."
        }
    }
    
    # Description quality
    if ($frontmatter -match '(?m)^description:\s*"(.+)"') {
        $desc = $Matches[1]
        $wordCount = ($desc -split '\s+').Count
        if ($wordCount -lt 15) {
            $warnings += "WEAK: Description is only $wordCount words. Aim for 20-50 words with trigger phrases."
        }
        if ($desc -notmatch "use when|trigger|use for|use this") {
            $warnings += "WEAK: Description lacks trigger phrases (e.g., 'Use when...', 'Triggers on...')"
        }
    }
    
    # Version format
    if ($frontmatter -match '(?m)^version:\s*(.+)') {
        $ver = $Matches[1].Trim()
        if ($ver -notmatch '^\d+\.\d+\.\d+$') {
            $warnings += "FORMAT: Version '$ver' doesn't follow semver (expected X.Y.Z)"
        }
    }
}

# --- Check body sections ---
$body = if ($hasFrontmatter) { ($content -split "---", 3)[2] } else { $content }

$expectedSections = @("## Role", "## Responsibilities", "## Constraints")
foreach ($section in $expectedSections) {
    if ($body -notmatch [regex]::Escape($section)) {
        $warnings += "MISSING SECTION: '$section' not found in body."
    }
}

# Check for constraints
if ($body -match "## Constraints") {
    $constraintSection = ($body -split "## Constraints", 2)[1]
    $constraintLines = ($constraintSection -split "`n") | Where-Object { $_ -match "^\s*-\s+" }
    if ($constraintLines.Count -lt 2) {
        $warnings += "WEAK: Constraints section has fewer than 2 items. Be more specific."
    }
}

# --- Anti-pattern checks ---
if ($body -match "(?i)you should|you might want to|you could") {
    $warnings += "STYLE: Use imperative form ('Review code for X') not suggestive ('You should review...')"
}

if ($body -match "(?i)if before \w+ \d{4}|if after \w+ \d{4}") {
    $issues += "ANTI-PATTERN: Time-sensitive instructions detected. Remove date-conditional logic."
}

if (($body -match "## Tools" -or $frontmatter -match "tools:") -and $frontmatter -match "tools:" ) {
    $toolLines = ($frontmatter -split "`n") | Where-Object { $_ -match "^\s+-\s+" }
    if ($toolLines.Count -gt 8) {
        $warnings += "BLOAT: $($toolLines.Count) tools listed. Consider reducing -- agents with fewer tools perform better."
    }
}

# --- Line count ---
$lineCount = $lines.Count
if ($lineCount -gt 200) {
    $warnings += "LENGTH: Agent file is $lineCount lines. Consider moving detailed reference content to separate files."
}

# --- Report ---
$agentName = if ($frontmatter -match '(?m)^name:\s*(.+)') { $Matches[1].Trim() } else { (Split-Path $Path -Leaf) }

Write-Host ""
Write-Host "=== Agent Validation: $agentName ===" -ForegroundColor Cyan
Write-Host "File: $Path"
Write-Host "Lines: $lineCount"
Write-Host ""

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✅ All checks passed!" -ForegroundColor Green
    exit 0
}

if ($issues.Count -gt 0) {
    Write-Host "❌ Issues ($($issues.Count)):" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  Warnings ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($warn in $warnings) {
        Write-Host "  - $warn" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($issues.Count -gt 0) {
    Write-Host "Result: FAIL" -ForegroundColor Red
    exit 1
} else {
    Write-Host "Result: PASS (with warnings)" -ForegroundColor Yellow
    exit 0
}
