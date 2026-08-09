<#
.SYNOPSIS
    Installa il pacchetto dr-guidelines (core) nel progetto corrente, oppure le linee guida globali.
.DESCRIPTION
    Esegui dalla root del progetto host.

    Installazione (repo Public):
        irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1 | iex

    Installazione (repo Private, con gh autenticato):
        & ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))

    Aggiornamento (sovrascrive i file gia presenti, merge sezione CLAUDE.md):
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1))) -Update

    Installazione globale (scrive ~/.claude/CLAUDE.md, non tocca il progetto corrente):
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1))) -Global

    dr-guidelines e' il pacchetto core: instructions/skill trasversali, file di
    configurazione radice, sezione CLAUDE.md. Nessuna dipendenza.
.PARAMETER Update
    Sovrascrive i file gia presenti con la versione corrente del pacchetto.
    Con -Global, sovrascrive la sezione gia presente in ~/.claude/CLAUDE.md.
.PARAMETER Global
    Installa le linee guida personali in ~/.claude/CLAUDE.md invece che nel progetto
    corrente. Il progetto corrente non viene toccato in alcun modo.
#>

[CmdletBinding()]
param(
    [switch]$Update,
    [switch]$Global
)

# --- Risoluzione della libreria condivisa ---
# Tre tentativi, in ordine di preferenza. Il primo che riesce vince.
#   1. raw pubblico       -> caso normale a repo Public
#   2. clone locale       -> $PSScriptRoot valorizzato (invocazione da path), vuoto sotto `iex`
#   3. gh api             -> repo Private con gh autenticato: l'unica via che scarica davvero da GitHub

$libName    = "dr-guidelines-install-lib.ps1"
$libRepo    = "davraf-amuro/dr-guidelines"
$libUrl     = "https://raw.githubusercontent.com/$libRepo/main/$libName"
$libLoaded  = $false
$libFailures = @()

try {
    $libContent = Invoke-RestMethod -Uri $libUrl -ErrorAction Stop
    Invoke-Expression $libContent
    $libLoaded = $true
} catch {
    $libFailures += "raw pubblico: $($_.Exception.Message)"
}

if (-not $libLoaded -and $PSScriptRoot) {
    $localLib = Join-Path $PSScriptRoot $libName
    if (Test-Path $localLib) {
        . $localLib
        $libLoaded = $true
    } else {
        $libFailures += "clone locale: $libName non trovato in $PSScriptRoot"
    }
} elseif (-not $libLoaded) {
    $libFailures += "clone locale: nessuno ($PSScriptRoot vuoto, script eseguito da stream)"
}

if (-not $libLoaded) {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        try {
            $libContent = gh api "repos/$libRepo/contents/$libName" -H "Accept: application/vnd.github.raw" 2>$null | Out-String
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($libContent)) {
                throw "gh api ha restituito exit $LASTEXITCODE (autenticato? 'gh auth status')"
            }
            Invoke-Expression $libContent
            $libLoaded = $true
        } catch {
            $libFailures += "gh api: $($_.Exception.Message)"
        }
    } else {
        $libFailures += "gh api: gh non installato o non nel PATH"
    }
}

if (-not $libLoaded) {
    Write-Host ""
    Write-Host "Impossibile caricare $libName. Tentativi:" -ForegroundColor Red
    $libFailures | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkGray }
    Write-Host ""
    Write-Host "Su repo Private serve gh autenticato: 'gh auth login' (scope repo)." -ForegroundColor Yellow
    throw "Caricamento di $libName fallito."
}

if ($Global) {
    Install-DrGlobal -Update:$Update
} else {
    Install-DrPackage -PackageName "dr-guidelines" -Update:$Update
}
