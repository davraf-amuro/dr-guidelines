<#
.SYNOPSIS
    Collega le linee guida Davraf alla root del progetto tramite copia/junction.
.DESCRIPTION
    Da eseguire dalla root del progetto host OPPURE direttamente:
        .\davraf-guidelines\setup.ps1

    Copia i file di configurazione e collega .github/ tramite junction.
    Non richiede privilegi amministrativi.

    Usa -Update per sovrascrivere i file già presenti con la versione aggiornata
    delle guidelines (utile dopo `git submodule update --remote davraf-guidelines`).
.PARAMETER Update
    Se specificato, sovrascrive i file di configurazione già presenti nel progetto
    con la versione corrente delle guidelines. Non sovrascrive CLAUDE.md.
.PARAMETER IncludeWorkflows
    Se specificato, copia anche .github/workflows/ nel progetto host.
    Per default la cartella è esclusa perché le pipeline CI/CD dipendono dall'ambiente.
.EXAMPLE
    # Prima installazione
    cd C:\MioProgetto
    git submodule add https://github.com/davraf-amuro/davraf-guidelines.git davraf-guidelines
    .\davraf-guidelines\setup.ps1

.EXAMPLE
    # Aggiornamento dopo submodule update
    git submodule update --remote davraf-guidelines
    .\davraf-guidelines\setup.ps1 -Update
#>

[CmdletBinding()]
param(
    [switch]$Update,
    [switch]$IncludeWorkflows
)

$ErrorActionPreference = "Stop"

$guidelinesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot   = (Get-Item $guidelinesDir).Parent.FullName

Write-Host ""
Write-Host "Davraf Guidelines Setup" -ForegroundColor Cyan
if ($Update) {
    Write-Host "  Modalità : UPDATE (sovrascrive file esistenti)" -ForegroundColor Yellow
}
Write-Host "  Guidelines : $guidelinesDir"
Write-Host "  Progetto   : $projectRoot"
Write-Host ""

function Copy-GuidelineFile {
    param([string]$FileName)

    $src  = Join-Path $guidelinesDir $FileName
    $dest = Join-Path $projectRoot   $FileName

    if (-not (Test-Path $src)) {
        Write-Host "  [WARN] Non trovato: $FileName" -ForegroundColor Yellow
        return
    }
    if ((Test-Path $dest) -and -not $Update) {
        Write-Host "  [SKIP] Esiste già: $FileName" -ForegroundColor DarkGray
        return
    }
    Copy-Item -Path $src -Destination $dest -Force
    $tag = if ($Update -and (Test-Path $dest)) { "[UPD] " } else { "[OK]  " }
    Write-Host "  $tag $FileName" -ForegroundColor Green
}

function New-Junction {
    param([string]$Link, [string]$Target)

    if (-not (Test-Path $Target)) {
        Write-Host "  [WARN] Target non trovato: $Target" -ForegroundColor Yellow
        return
    }
    if (Test-Path $Link) {
        Write-Host "  [SKIP] Esiste già: $(Split-Path -Leaf $Link)" -ForegroundColor DarkGray
        return
    }
    New-Item -ItemType Junction -Path $Link -Target $Target -Force | Out-Null
    Write-Host "  [OK]   $(Split-Path -Leaf $Link) (junction)" -ForegroundColor Green
}

# --- File di configurazione (copia) ---
Write-Host "File di configurazione:" -ForegroundColor White
foreach ($file in @(".editorconfig", "Directory.Build.props", "global.json", ".gitignore", ".gitattributes")) {
    Copy-GuidelineFile -FileName $file
}

# --- Cartella .github ---
Write-Host ""
Write-Host "Cartella .github:" -ForegroundColor White

$githubSrc  = Join-Path $guidelinesDir ".github"
$githubDest = Join-Path $projectRoot   ".github"

if (-not (Test-Path $githubDest)) {
    New-Junction -Link $githubDest -Target $githubSrc
} else {
    $junctionTarget = (Get-Item $githubDest -Force).Target
    if ($junctionTarget -and ((Resolve-Path $junctionTarget).Path -eq (Resolve-Path $githubSrc).Path)) {
        Write-Host "  [SKIP] .github è una junction verso la stessa sorgente, nessuna copia necessaria." -ForegroundColor DarkGray
    } else {

    $mode = if ($Update) { "aggiornamento" } else { "copia nuovi file" }
    Write-Host "  [INFO] .github esiste, $mode..." -ForegroundColor Cyan

    $srcFolders = @($githubSrc) + (
        Get-ChildItem $githubSrc -Directory |
        Where-Object { $_.Name -ne "workflows" -or $IncludeWorkflows } |
        ForEach-Object { $_.FullName }
    )

    foreach ($srcFolder in $srcFolders) {
        $rel        = if ($srcFolder -eq $githubSrc) { "" } else { Split-Path -Leaf $srcFolder }
        $destFolder = if ($rel) { Join-Path $githubDest $rel } else { $githubDest }

        if (-not (Test-Path $destFolder)) {
            New-Item -ItemType Directory -Path $destFolder | Out-Null
        }

        foreach ($f in Get-ChildItem $srcFolder -File) {
            $destFile = Join-Path $destFolder $f.Name
            if ((Test-Path $destFile) -and -not $Update) {
                Write-Host "  [SKIP] $($f.Name)" -ForegroundColor DarkGray
            } else {
                $isUpdate = $Update -and (Test-Path $destFile)
                Copy-Item -Path $f.FullName -Destination $destFile -Force
                $tag = if ($isUpdate) { "[UPD]" } else { "[OK] " }
                Write-Host "  $tag  $($f.Name)" -ForegroundColor Green
            }
        }
    }
    } # end else (not junction)
}

# --- CLAUDE.md --- (mai sovrascritto, anche con -Update)
Write-Host ""
Write-Host "CLAUDE.md:" -ForegroundColor White

$claudeMd   = Join-Path $projectRoot "CLAUDE.md"
$claudeRule = @"

## Davraf Guidelines

Leggi sempre `.github/copilot-instructions.md` all'inizio di ogni conversazione.
Prima di generare codice, leggi il file di istruzioni modulare pertinente al task in `.github/instructions/`.
"@

if (-not (Test-Path $claudeMd)) {
    Set-Content -Path $claudeMd -Value "# Claude Code Instructions$claudeRule" -Encoding UTF8
    Write-Host "  [OK]   CLAUDE.md creato" -ForegroundColor Green
} else {
    $existing = Get-Content $claudeMd -Raw
    if ($existing -notlike "*Davraf Guidelines*") {
        Add-Content -Path $claudeMd -Value $claudeRule -Encoding UTF8
        Write-Host "  [OK]   Regola aggiunta a CLAUDE.md esistente" -ForegroundColor Green
    } else {
        $claudeRuleTrimmed = $claudeRule.Trim()
        if ($existing -notlike "*$claudeRuleTrimmed*") {
            Write-Host "  [WARN] La sezione 'Davraf Guidelines' in CLAUDE.md potrebbe essere obsoleta - verifica manualmente" -ForegroundColor Yellow
        } else {
            Write-Host "  [SKIP] Regola già presente e aggiornata in CLAUDE.md" -ForegroundColor DarkGray
        }
    }
}

# --- Cartella .claude/skills ---
Write-Host ""
Write-Host "Cartella .claude/skills:" -ForegroundColor White

$claudeSkillsSrc  = Join-Path $guidelinesDir ".claude\skills"
$claudeSkillsDest = Join-Path $projectRoot   ".claude\skills"

if (Test-Path $claudeSkillsSrc) {
    if (-not (Test-Path $claudeSkillsDest)) {
        New-Item -ItemType Directory -Path $claudeSkillsDest -Force | Out-Null
    }
    # Copia file nella root di skills
    foreach ($f in Get-ChildItem $claudeSkillsSrc -File) {
        $destFile = Join-Path $claudeSkillsDest $f.Name
        if ((Test-Path $destFile) -and -not $Update) {
            Write-Host "  [SKIP] $($f.Name)" -ForegroundColor DarkGray
        } else {
            $isUpdate = $Update -and (Test-Path $destFile)
            Copy-Item -Path $f.FullName -Destination $destFile -Force
            $tag = if ($isUpdate) { "[UPD]" } else { "[OK] " }
            Write-Host "  $tag  $($f.Name)" -ForegroundColor Green
        }
    }
    # Copia sottocartelle (ogni skill è una cartella con SKILL.md)
    foreach ($dir in Get-ChildItem $claudeSkillsSrc -Directory) {
        $destDir = Join-Path $claudeSkillsDest $dir.Name
        if ((Test-Path $destDir) -and -not $Update) {
            Write-Host "  [SKIP] $($dir.Name)/" -ForegroundColor DarkGray
        } else {
            Copy-Item -Path $dir.FullName -Destination $destDir -Recurse -Force
            $tag = if ($Update -and (Test-Path $destDir)) { "[UPD]" } else { "[OK] " }
            Write-Host "  $tag  $($dir.Name)/" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  [WARN] Non trovata: .claude/skills" -ForegroundColor Yellow
}

# --- Cartella docs/ ---
Write-Host ""
Write-Host "Cartella docs:" -ForegroundColor White

$docsDest = Join-Path $projectRoot "docs"

if (-not (Test-Path $docsDest)) {
    New-Item -ItemType Directory -Path $docsDest | Out-Null
    Write-Host "  [OK]   docs/ creata" -ForegroundColor Green
} else {
    Write-Host "  [SKIP] docs/ esiste già" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Setup completato." -ForegroundColor Cyan
Write-Host ""
Write-Host "Attenzioni manuali:" -ForegroundColor White
Write-Host "  - CLAUDE.md: non sovrascritta automaticamente, verificare se allineata al submodule" -ForegroundColor Yellow
if (-not $IncludeWorkflows) {
    Write-Host "  - .github/workflows/: non copiata (usa -IncludeWorkflows per includerla)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Per aggiornare le linee guida in futuro:" -ForegroundColor White
Write-Host "  git submodule update --remote davraf-guidelines" -ForegroundColor DarkCyan
Write-Host "  .\davraf-guidelines\setup.ps1 -Update" -ForegroundColor DarkCyan
Write-Host ""
