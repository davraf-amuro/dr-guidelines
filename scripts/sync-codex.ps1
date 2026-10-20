<#
.SYNOPSIS
    Genera gli artefatti Codex (.agents/skills, AGENTS.md) da quelli Claude Code.
.DESCRIPTION
    Claude Code e' l'agente primario: .claude/skills/*/SKILL.md e CLAUDE.md sono la fonte.
    Le copie Codex non si modificano a mano: questo script le rigenera identiche alla fonte,
    con un preambolo che dice a Codex come tradurre gli strumenti specifici di Claude Code.
    Nessuna sostituzione di testo nel corpo: una sostituzione cieca ("Claude Code" -> "Codex")
    cambia il significato delle regole e ha gia' prodotto percorsi e URL inesistenti.
    Cambia solo il titolo di AGENTS.md. I preamboli stanno in templates/codex-*-preamble.md.
    Senza -Check riscrive le copie divergenti e rimuove le skill Codex orfane
    (senza sorgente in .claude/skills).
.PARAMETER Check
    Non scrive nulla: confronta e termina con exit code 1 se le copie Codex divergono
    o se esistono skill Codex orfane. Usato dalla CI.
.EXAMPLE
    pwsh ./scripts/sync-codex.ps1
    pwsh ./scripts/sync-codex.ps1 -Check
#>
[CmdletBinding()]
param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-Normalized([string]$Text) {
    return ($Text -replace "`r`n", "`n")
}

# Preamboli in file Markdown UTF-8: questo script resta ASCII (PowerShell 5.1 legge senza BOM come ANSI)
$templatesDir   = Join-Path $repoRoot "templates"
$skillPreamble  = Get-Normalized ([System.IO.File]::ReadAllText((Join-Path $templatesDir "codex-skill-preamble.md"), $utf8NoBom))
$agentsPreamble = Get-Normalized ([System.IO.File]::ReadAllText((Join-Path $templatesDir "codex-agents-preamble.md"), $utf8NoBom))

function Get-ExpectedSkill([string]$SourcePath, [string]$SkillName) {
    $src = Get-Normalized ([System.IO.File]::ReadAllText($SourcePath, $utf8NoBom))
    $pre = $skillPreamble.Replace("{0}", $SkillName)
    # Il preambolo va dopo il frontmatter: name/description devono restare in testa al file
    $m = [regex]::Match($src, "(?s)\A---\n.*?\n---\n")
    if ($m.Success) {
        return $src.Substring(0, $m.Length) + "`n" + $pre + $src.Substring($m.Length).TrimStart("`n")
    }
    return $pre + $src
}

function Get-ExpectedAgents([string]$SourcePath) {
    $src = Get-Normalized ([System.IO.File]::ReadAllText($SourcePath, $utf8NoBom))
    $src = $src -replace "\A# Linee guida per Claude Code", "# Linee guida per Codex (copia di CLAUDE.md)"
    $lines = $src -split "`n", 2
    return $lines[0] + "`n`n" + $agentsPreamble + $lines[1].TrimStart("`n")
}

$targets = New-Object System.Collections.Generic.List[object]

$claudeSkills = Join-Path (Join-Path $repoRoot ".claude") "skills"
$agentsSkills = Join-Path (Join-Path $repoRoot ".agents") "skills"

foreach ($dir in Get-ChildItem -LiteralPath $claudeSkills -Directory) {
    $src = Join-Path $dir.FullName "SKILL.md"
    if (-not (Test-Path -LiteralPath $src)) { continue }
    $targets.Add([pscustomobject]@{
        Path     = Join-Path (Join-Path $agentsSkills $dir.Name) "SKILL.md"
        Expected = Get-ExpectedSkill -SourcePath $src -SkillName $dir.Name
    })
}

$targets.Add([pscustomobject]@{
    Path     = Join-Path $repoRoot "AGENTS.md"
    Expected = Get-ExpectedAgents -SourcePath (Join-Path $repoRoot "CLAUDE.md")
})

# Skill Codex senza sorgente Claude: orfane, da rimuovere
$orphans = @()
if (Test-Path -LiteralPath $agentsSkills) {
    $orphans = @(Get-ChildItem -LiteralPath $agentsSkills -Directory |
        Where-Object { -not (Test-Path -LiteralPath (Join-Path (Join-Path $claudeSkills $_.Name) "SKILL.md")) })
}

$diverging = @()
foreach ($t in $targets) {
    $current = if (Test-Path -LiteralPath $t.Path) { Get-Normalized ([System.IO.File]::ReadAllText($t.Path, $utf8NoBom)) } else { $null }
    if ($current -ne $t.Expected) { $diverging += $t }
}

if ($Check) {
    if ($diverging.Count -eq 0 -and $orphans.Count -eq 0) {
        Write-Host "Copie Codex allineate a .claude/skills e CLAUDE.md" -ForegroundColor Green
        exit 0
    }
    $diverging | ForEach-Object { Write-Host "[DIFF]   $($_.Path)" -ForegroundColor Yellow }
    $orphans   | ForEach-Object { Write-Host "[ORFANA] $($_.FullName)" -ForegroundColor Yellow }
    Write-Host "Esegui: pwsh ./scripts/sync-codex.ps1" -ForegroundColor Yellow
    exit 1
}

foreach ($t in $diverging) {
    $parent = Split-Path $t.Path -Parent
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($t.Path, $t.Expected, $utf8NoBom)
    Write-Host "[UPD]    $($t.Path)" -ForegroundColor Green
}
foreach ($o in $orphans) {
    Remove-Item -LiteralPath $o.FullName -Recurse -Force
    Write-Host "[DEL]    $($o.FullName)" -ForegroundColor Yellow
}
Write-Host "Sincronizzazione Codex completata: $($diverging.Count) file aggiornati, $($orphans.Count) skill orfane rimosse"
