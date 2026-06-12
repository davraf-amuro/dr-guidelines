<#
.SYNOPSIS
    Crea un nuovo progetto .NET collegando le Davraf Guidelines come submodule.
.DESCRIPTION
    Lancia una UI minimale per scegliere nome progetto e cartella di destinazione,
    quindi crea la struttura, aggiunge davraf-guidelines come git submodule ed
    esegue setup.ps1 per collegare i file di configurazione.
    Non richiede privilegi amministrativi.
.EXAMPLE
    irm https://raw.githubusercontent.com/davraf-amuro/davraf-guidelines/main/CreateNewSolution.ps1 | iex
#>

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

$guidelinesRepo = "https://github.com/davraf-amuro/davraf-guidelines.git"

# ---------------------------------------------------------------------------
# Step 1 — Nome progetto
# ---------------------------------------------------------------------------
$projectName = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Inserisci il nome del nuovo progetto:",
    "Nuovo Progetto .NET",
    ""
)

if ([string]::IsNullOrWhiteSpace($projectName)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Nome progetto non inserito. Operazione annullata.",
        "Annullato",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
    exit 0
}

# Validazione: solo lettere, numeri, trattini e underscore
if ($projectName -notmatch '^[a-zA-Z0-9_\-]+$') {
    [System.Windows.Forms.MessageBox]::Show(
        "Il nome del progetto può contenere solo lettere, numeri, trattini (-) e underscore (_).",
        "Nome non valido",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

# ---------------------------------------------------------------------------
# Step 2 — Cartella di destinazione
# ---------------------------------------------------------------------------
$browser = New-Object System.Windows.Forms.FolderBrowserDialog
$browser.Description  = "Seleziona la cartella dove creare il progetto '$projectName'"
$browser.RootFolder   = [System.Environment+SpecialFolder]::MyComputer
$browser.ShowNewFolderButton = $true

$result = $browser.ShowDialog()

if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
    exit 0
}

$parentFolder = $browser.SelectedPath
$projectDir   = Join-Path $parentFolder $projectName

# ---------------------------------------------------------------------------
# Step 3 — Creazione cartella progetto
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Creazione progetto: $projectName" -ForegroundColor Cyan
Write-Host "  Percorso: $projectDir"
Write-Host ""

if (Test-Path $projectDir) {
    [System.Windows.Forms.MessageBox]::Show(
        "Esiste già una cartella '$projectName' in:`n$parentFolder",
        "Cartella già esistente",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

Write-Host "[1/4] Creazione cartella progetto..." -ForegroundColor White
New-Item -ItemType Directory -Path $projectDir | Out-Null
Write-Host "  [OK] $projectDir" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Step 4 — Git init + submodule  OPPURE  download ZIP (fallback)
# ---------------------------------------------------------------------------
$gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)

if ($gitAvailable) {
    Write-Host ""
    Write-Host "[2/4] Inizializzazione repository git..." -ForegroundColor White
    Push-Location $projectDir
    try {
        git init | Out-Null
        Write-Host "  [OK] git init" -ForegroundColor Green

        Write-Host ""
        Write-Host "[3/4] Aggiunta davraf-guidelines come submodule..." -ForegroundColor White
        $ErrorActionPreference = "Continue"
        git submodule add $guidelinesRepo davraf-guidelines 2>&1 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor DarkGray
        }
        $ErrorActionPreference = "Stop"
        if ($LASTEXITCODE -ne 0) { throw "git submodule add fallito (exit code $LASTEXITCODE)" }
        Write-Host "  [OK] submodule aggiunto" -ForegroundColor Green
    } finally {
        Pop-Location
    }
} else {
    Write-Host ""
    Write-Host "[2/4] Git non trovato — download ZIP delle guidelines..." -ForegroundColor Yellow

    $zipUrl  = "https://github.com/davraf-amuro/davraf-guidelines/archive/refs/heads/main.zip"
    $zipPath = Join-Path $env:TEMP "davraf-guidelines.zip"
    $zipDest = Join-Path $env:TEMP "davraf-guidelines-extract"

    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "  [OK] download completato" -ForegroundColor Green

    Write-Host ""
    Write-Host "[3/4] Estrazione..." -ForegroundColor White
    if (Test-Path $zipDest) { Remove-Item $zipDest -Recurse -Force }
    Expand-Archive -Path $zipPath -DestinationPath $zipDest
    $extractedFolder = Get-ChildItem $zipDest | Select-Object -First 1
    Move-Item -Path $extractedFolder.FullName -Destination (Join-Path $projectDir "davraf-guidelines")
    Remove-Item $zipPath -Force
    Write-Host "  [OK] guidelines estratte" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Step 5 — Esecuzione setup.ps1
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[4/4] Esecuzione setup.ps1..." -ForegroundColor White

$setupScript = Join-Path $projectDir "davraf-guidelines\setup.ps1"

if (-not (Test-Path $setupScript)) {
    Write-Host "  [ERRORE] setup.ps1 non trovato in: $setupScript" -ForegroundColor Red
    exit 1
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
& $setupScript

# ---------------------------------------------------------------------------
# Fine
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Progetto '$projectName' creato con successo!" -ForegroundColor Cyan
Write-Host "  Percorso: $projectDir" -ForegroundColor White
Write-Host ""
Write-Host "Prossimi passi:" -ForegroundColor White
Write-Host "  1. cd $projectDir" -ForegroundColor DarkCyan
Write-Host "  2. Crea la tua solution .NET (dotnet new sln -n $projectName)" -ForegroundColor DarkCyan
Write-Host "  3. Per aggiornare le guidelines in futuro:" -ForegroundColor DarkCyan
Write-Host "     git submodule update --remote davraf-guidelines" -ForegroundColor DarkCyan
Write-Host ""
