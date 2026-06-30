<#
.SYNOPSIS
    Collega le linee guida Davraf alla root del progetto tramite copia/junction,
    oppure le installa globalmente in ~/.claude/CLAUDE.md.
.DESCRIPTION
    Da eseguire dalla root del progetto host OPPURE direttamente:
        .\davraf-guidelines\setup.ps1

    Copia i file di configurazione e collega .github/ tramite junction.
    Non richiede privilegi amministrativi.

    Usa -Update per sovrascrivere i file già presenti con la versione aggiornata
    delle guidelines (utile dopo `git submodule update --remote davraf-guidelines`).

    Usa -GlobalInstall per installare le linee guida in ~/.claude/CLAUDE.md in modo
    che Claude Code le carichi automaticamente in ogni sessione, indipendentemente dal
    progetto corrente. Non tocca il progetto host.

    Usa -GlobalUpdate per aggiornare l'installazione globale: esegue git pull sul
    repo delle guidelines e riscrive la sezione in ~/.claude/CLAUDE.md.

    Le due modalità (progetto e globale) sono indipendenti e coesistono senza conflitti.
    Se entrambe sono attive, Claude carica prima il globale poi il progetto;
    le istruzioni di progetto hanno precedenza sui conflitti.
.PARAMETER Update
    Sovrascrive i file di configurazione già presenti nel progetto con la versione
    corrente delle guidelines. Non sovrascrive CLAUDE.md. Non tocca ~/.claude/.
.PARAMETER IncludeWorkflows
    Copia anche .github/workflows/ nel progetto host.
    Per default la cartella è esclusa perché le pipeline CI/CD dipendono dall'ambiente.
.PARAMETER GlobalInstall
    Installa le linee guida in ~/.claude/CLAUDE.md (globale PC).
    Idempotente. Non tocca il progetto corrente.
.PARAMETER GlobalUpdate
    Esegue git pull sul repo delle guidelines, poi aggiorna ~/.claude/CLAUDE.md.
    Non tocca il progetto corrente.
.EXAMPLE
    # Prima installazione in un progetto
    cd C:\MioProgetto
    git submodule add https://github.com/davraf-amuro/davraf-guidelines.git davraf-guidelines
    .\davraf-guidelines\setup.ps1

.EXAMPLE
    # Aggiornamento progetto dopo submodule update
    git submodule update --remote davraf-guidelines
    .\davraf-guidelines\setup.ps1 -Update

.EXAMPLE
    # Installazione globale (una tantum, da qualsiasi clone del repo)
    .\davraf-guidelines\setup.ps1 -GlobalInstall

.EXAMPLE
    # Aggiornamento globale
    .\davraf-guidelines\setup.ps1 -GlobalUpdate
#>

[CmdletBinding()]
param(
    [switch]$Update,
    [switch]$IncludeWorkflows,
    [switch]$GlobalInstall,
    [switch]$GlobalUpdate
)

$ErrorActionPreference = "Stop"

$guidelinesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot   = (Get-Item $guidelinesDir).Parent.FullName

# --- Modalità Globale (GlobalInstall / GlobalUpdate) ---
# Scrive in ~/.claude/CLAUDE.md. Non tocca il progetto corrente.
if ($GlobalInstall -or $GlobalUpdate) {
    $globalClaudePath   = Join-Path $HOME ".claude\CLAUDE.md"
    $globalTemplatePath = Join-Path $guidelinesDir "templates\global-claude.md"

    if (-not (Test-Path $globalTemplatePath)) {
        Write-Error "  [ERR] Template non trovato: $globalTemplatePath"
        exit 1
    }

    Write-Host ""
    Write-Host "Davraf Guidelines — Installazione Globale" -ForegroundColor Cyan
    $modeLabel = if ($GlobalUpdate) { "GLOBAL UPDATE" } else { "GLOBAL INSTALL" }
    Write-Host "  Modalità   : $modeLabel" -ForegroundColor Yellow
    Write-Host "  Guidelines : $guidelinesDir"
    Write-Host "  Target     : $globalClaudePath"
    Write-Host ""

    if ($GlobalUpdate) {
        Write-Host "Aggiornamento repository..." -ForegroundColor White
        git -C $guidelinesDir pull
        Write-Host ""
    }

    Write-Host "~/.claude/CLAUDE.md:" -ForegroundColor White

    $templateRaw  = Get-Content $globalTemplatePath -Raw -Encoding UTF8
    $templateBody = ($templateRaw -replace "^#[^\n]*\n+", "").TrimStart()
    $davrafBlock  = "## Davraf Guidelines (Globale)`n`n$templateBody`n<!-- /davraf-guidelines -->`n"
    $claudeDir    = Split-Path $globalClaudePath

    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }

    if (-not (Test-Path $globalClaudePath)) {
        Set-Content -Path $globalClaudePath -Value $davrafBlock -Encoding UTF8
        Write-Host "  [OK]  Creato ~/.claude/CLAUDE.md con sezione Davraf Guidelines" -ForegroundColor Green
    } else {
        $existing     = Get-Content $globalClaudePath -Raw -Encoding UTF8
        $sectionTitle = "## Davraf Guidelines (Globale)"
        if ($existing -notmatch [regex]::Escape($sectionTitle)) {
            $newContent = $existing.TrimEnd() + "`n`n" + $davrafBlock
            Set-Content -Path $globalClaudePath -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "  [OK]  Sezione Davraf Guidelines inserita in ~/.claude/CLAUDE.md" -ForegroundColor Green
        } else {
            $pattern     = "(?s)(## Davraf Guidelines \(Globale\)\r?\n).*?(<!-- /davraf-guidelines -->)"
            $replacement = "## Davraf Guidelines (Globale)`n`n$templateBody`n<!-- /davraf-guidelines -->"
            if ($existing -match $pattern) {
                $newContent = [regex]::Replace($existing, $pattern, $replacement)
                Set-Content -Path $globalClaudePath -Value $newContent -Encoding UTF8 -NoNewline
                $tag = if ($GlobalUpdate) { "[UPD]" } else { "[OK] " }
                Write-Host "  $tag ~/.claude/CLAUDE.md — sezione Davraf Guidelines aggiornata" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] Trovata intestazione '$sectionTitle' ma sentinel '<!-- /davraf-guidelines -->' mancante — verifica manualmente" -ForegroundColor Yellow
            }
        }
    }

    Write-Host ""
    Write-Host "Installazione globale completata." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Per aggiornare in futuro:" -ForegroundColor White
    Write-Host "  cd $guidelinesDir" -ForegroundColor DarkCyan
    Write-Host "  git pull" -ForegroundColor DarkCyan
    Write-Host "  .\setup.ps1 -GlobalUpdate" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "Nota:" -ForegroundColor White
    Write-Host "  Claude carica ~/.claude/CLAUDE.md in ogni sessione." -ForegroundColor DarkGray
    Write-Host "  Se un progetto ha un proprio CLAUDE.md (via submodule), le sue" -ForegroundColor DarkGray
    Write-Host "  istruzioni hanno precedenza sulle linee guida globali." -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

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


# --- File di configurazione (copia) ---
Write-Host "File di configurazione:" -ForegroundColor White
foreach ($file in @(".editorconfig", "Directory.Build.props", "global.json", ".gitignore", ".gitattributes")) {
    Copy-GuidelineFile -FileName $file
}

# --- .mcp.json (server MCP consigliati) ---
Write-Host ""
Write-Host ".mcp.json:" -ForegroundColor White

$mcpSrc  = Join-Path $guidelinesDir ".mcp.json"
$mcpDest = Join-Path $projectRoot   ".mcp.json"

if (Test-Path $mcpSrc) {
    if (-not (Test-Path $mcpDest)) {
        Copy-Item -Path $mcpSrc -Destination $mcpDest
        Write-Host "  [OK]   .mcp.json" -ForegroundColor Green
    } elseif ((Get-FileHash $mcpSrc).Hash -ne (Get-FileHash $mcpDest).Hash) {
        # Mai sovrascritto, nemmeno con -Update: il file host può contenere
        # server MCP aggiunti dal progetto.
        Write-Host "  [WARN] .mcp.json esiste con contenuto diverso - non sovrascritto, confronta manualmente" -ForegroundColor Yellow
    } else {
        Write-Host "  [SKIP] .mcp.json identico" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  [WARN] Non trovato: .mcp.json" -ForegroundColor Yellow
}

# --- Cartella .github ---
Write-Host ""
Write-Host "Cartella .github:" -ForegroundColor White

$githubSrc  = Join-Path $guidelinesDir ".github"
$githubDest = Join-Path $projectRoot   ".github"

if (-not (Test-Path $githubSrc)) {
    Write-Host "  [WARN] .github non trovato nelle guidelines" -ForegroundColor Yellow
} else {
    if (-not (Test-Path $githubDest)) {
        New-Item -ItemType Directory -Path $githubDest -Force | Out-Null
    }

    # File in root .github/
    foreach ($f in Get-ChildItem $githubSrc -File) {
        $destFile = Join-Path $githubDest $f.Name
        if ((Test-Path $destFile) -and -not $Update) {
            Write-Host "  [SKIP] $($f.Name)" -ForegroundColor DarkGray
        } else {
            $isUpdate = $Update -and (Test-Path $destFile)
            Copy-Item -Path $f.FullName -Destination $destFile -Force
            $tag = if ($isUpdate) { "[UPD]" } else { "[OK] " }
            Write-Host "  $tag  $($f.Name)" -ForegroundColor Green
        }
    }

    # Sottocartelle (esclude workflows a meno di -IncludeWorkflows)
    foreach ($dir in Get-ChildItem $githubSrc -Directory | Where-Object { $_.Name -ne "workflows" -or $IncludeWorkflows }) {
        $destDir = Join-Path $githubDest $dir.Name
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        foreach ($f in Get-ChildItem $dir.FullName -File) {
            $destFile = Join-Path $destDir $f.Name
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
}

# --- CLAUDE.md --- (merge automatico della sezione Davraf Guidelines)
Write-Host ""
Write-Host "CLAUDE.md:" -ForegroundColor White

$claudeMd      = Join-Path $projectRoot "CLAUDE.md"
$claudeMdSrc   = Join-Path $guidelinesDir "CLAUDE.md"

# Leggi il contenuto sorgente dal submodule, rimuovi il titolo h1
$srcRaw        = Get-Content $claudeMdSrc -Raw -Encoding UTF8
$srcBody       = ($srcRaw -replace "^#[^\n]*\n+", "").TrimStart()

# Blocco da iniettare (marcatore di inizio + contenuto + sentinel di fine)
$davrafBlock   = "## Davraf Guidelines`n`n$srcBody`n<!-- /davraf-guidelines -->`n"

if (-not (Test-Path $claudeMd)) {
    Set-Content -Path $claudeMd -Value $davrafBlock -Encoding UTF8
    Write-Host "  [OK]   CLAUDE.md creato con sezione Davraf Guidelines" -ForegroundColor Green
} else {
    $existing = Get-Content $claudeMd -Raw -Encoding UTF8

    if ($existing -notmatch "## Davraf Guidelines") {
        # Nessuna sezione esistente: inserisci dopo il titolo h1 (se presente)
        if ($existing -match "^(#[^\n]*\n+)(.*)$") {
            $newContent = $Matches[1] + "`n" + $davrafBlock + "`n" + $Matches[2]
        } else {
            $newContent = $davrafBlock + "`n" + $existing
        }
        Set-Content -Path $claudeMd -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "  [OK]   Sezione Davraf Guidelines inserita in CLAUDE.md" -ForegroundColor Green
    } elseif ($Update) {
        # Sostituisci il blocco tra ## Davraf Guidelines e il separatore --- seguito da ## (sezioni progetto)
        # Pattern: da "## Davraf Guidelines" fino a "---\n" che precede una riga "## " o fine file
        # Fine sezione identificata dal sentinel <!-- /davraf-guidelines -->
        $pattern     = "(?s)(## Davraf Guidelines\r?\n).*?(<!-- /davraf-guidelines -->)"
        $replacement = "## Davraf Guidelines`n`n$srcBody`n<!-- /davraf-guidelines -->"
        if ($existing -match $pattern) {
            $newContent = [regex]::Replace($existing, $pattern, $replacement)
            Set-Content -Path $claudeMd -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "  [UPD]  Sezione Davraf Guidelines aggiornata in CLAUDE.md" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] Trovata intestazione 'Davraf Guidelines' ma sentinel '<!-- /davraf-guidelines -->' non trovato - verifica manualmente" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [SKIP] Sezione Davraf Guidelines già presente (usa -Update per aggiornare)" -ForegroundColor DarkGray
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
    # Nota: copiare il contenuto (\*) e non la cartella — Copy-Item su directory
    # esistente anniderebbe la sorgente dentro la destinazione.
    foreach ($dir in Get-ChildItem $claudeSkillsSrc -Directory) {
        $destDir = Join-Path $claudeSkillsDest $dir.Name
        if ((Test-Path $destDir) -and -not $Update) {
            Write-Host "  [SKIP] $($dir.Name)/" -ForegroundColor DarkGray
        } else {
            $isUpdate = $Update -and (Test-Path $destDir)
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir | Out-Null
            }
            Copy-Item -Path (Join-Path $dir.FullName "*") -Destination $destDir -Recurse -Force
            $tag = if ($isUpdate) { "[UPD]" } else { "[OK] " }
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
Write-Host "  - CLAUDE.md: sezione 'Davraf Guidelines' aggiornata automaticamente; le sezioni specifiche del progetto sono preservate" -ForegroundColor Yellow
if (-not $IncludeWorkflows) {
    Write-Host "  - .github/workflows/: non copiata (usa -IncludeWorkflows per includerla)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Per aggiornare le linee guida in futuro:" -ForegroundColor White
Write-Host "  git submodule update --remote davraf-guidelines" -ForegroundColor DarkCyan
Write-Host "  .\davraf-guidelines\setup.ps1 -Update" -ForegroundColor DarkCyan
Write-Host ""
