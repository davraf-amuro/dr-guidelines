<#
.SYNOPSIS
    Collega le linee guida Davraf alla root del progetto tramite copia/junction.
.DESCRIPTION
    Da eseguire dalla root del progetto host OPPURE direttamente:
        .\davraf-guidelines\setup.ps1
    Copia i file di configurazione e collega .github/ tramite junction.
    Non richiede privilegi amministrativi.
.EXAMPLE
    cd C:\MioProgetto
    git submodule add https://github.com/davraf-amuro/davraf-guidelines.git davraf-guidelines
    .\davraf-guidelines\setup.ps1
#>

$ErrorActionPreference = "Stop"

$guidelinesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot   = (Get-Item $guidelinesDir).Parent.FullName

Write-Host ""
Write-Host "Davraf Guidelines Setup" -ForegroundColor Cyan
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
    if (Test-Path $dest) {
        Write-Host "  [SKIP] Esiste già: $FileName" -ForegroundColor DarkGray
        return
    }
    Copy-Item -Path $src -Destination $dest
    Write-Host "  [OK]   $FileName" -ForegroundColor Green
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
    # Esiste già: copia file per file per non sovrascrivere contenuto esistente
    Write-Host "  [INFO] .github esiste, copia file per file..." -ForegroundColor Cyan

    $subDirs = @("", "instructions", "prompts")
    foreach ($sub in $subDirs) {
        $srcFolder  = if ($sub) { Join-Path $githubSrc  $sub } else { $githubSrc }
        $destFolder = if ($sub) { Join-Path $githubDest $sub } else { $githubDest }

        if (-not (Test-Path $destFolder)) {
            New-Item -ItemType Directory -Path $destFolder | Out-Null
        }

        if (Test-Path $srcFolder) {
            foreach ($f in Get-ChildItem $srcFolder -File) {
                $destFile = Join-Path $destFolder $f.Name
                if (Test-Path $destFile) {
                    Write-Host "  [SKIP] $($f.Name)" -ForegroundColor DarkGray
                } else {
                    Copy-Item -Path $f.FullName -Destination $destFile
                    Write-Host "  [OK]   $($f.Name)" -ForegroundColor Green
                }
            }
        }
    }
}

# --- CLAUDE.md ---
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
        Write-Host "  [SKIP] Regola già presente in CLAUDE.md" -ForegroundColor DarkGray
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
    foreach ($f in Get-ChildItem $claudeSkillsSrc -File) {
        $destFile = Join-Path $claudeSkillsDest $f.Name
        if (Test-Path $destFile) {
            Write-Host "  [SKIP] $($f.Name)" -ForegroundColor DarkGray
        } else {
            Copy-Item -Path $f.FullName -Destination $destFile
            Write-Host "  [OK]   $($f.Name)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  [WARN] Non trovata: .claude/skills" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup completato." -ForegroundColor Cyan
Write-Host "Per aggiornare le linee guida in futuro:" -ForegroundColor White
Write-Host "  git submodule update --remote davraf-guidelines" -ForegroundColor DarkCyan
Write-Host ""
