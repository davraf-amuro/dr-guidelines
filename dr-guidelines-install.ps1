<#
.SYNOPSIS
    Installa il pacchetto dr-guidelines (core) nel progetto corrente, oppure le linee guida globali.
.DESCRIPTION
    Esegui dalla root del progetto host.

    Installazione (repo Public):
        irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1 | iex

    Installazione (repo Private, con gh autenticato):
        & ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))

    Aggiornamento (riscrive istruzioni e skill, merge sezione CLAUDE.md, file di configurazione personalizzati -> '<file>.new'):
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1))) -Update

    Installazione globale (scrive ~/.claude/CLAUDE.md, non tocca il progetto corrente):
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1))) -Global

    Installazione di un pacchetto dominio, senza scaricare il suo installer:
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1))) -Package dr-minimalapi

    dr-guidelines e' il pacchetto core: instructions/skill trasversali, file di
    configurazione radice, sezione CLAUDE.md. Nessuna dipendenza.
.PARAMETER Update
    Sovrascrive istruzioni, prompt e skill gia' presenti con la versione corrente del pacchetto
    e riscrive la sezione marcata in CLAUDE.md. I file di configurazione che l'host personalizza
    (.gitignore, .editorconfig, .gitattributes, .github/copilot-instructions.md e i rootFiles
    dei pacchetti) si sovrascrivono solo se mai modificati rispetto alla versione installata;
    altrimenti la versione nuova va in '<file>.new' e l'originale non si tocca.
    Con -Global, sovrascrive la sezione gia' presente in ~/.claude/CLAUDE.md.
.PARAMETER Global
    Installa le linee guida personali in ~/.claude/CLAUDE.md invece che nel progetto
    corrente. Il progetto corrente non viene toccato in alcun modo.
.PARAMETER Package
    Nome del pacchetto dr-* da installare (es. dr-minimalapi). Il core dr-guidelines
    e' una dipendenza implicita di ogni pacchetto: se manca dal manifest si installa
    per primo. Le altre dipendenze mancanti vengono installate prima del pacchetto:
    dr-minimalapi tira dr-dotnet-backend. Prima di clonare qualsiasi cosa l'installer annuncia
    l'albero in un blocco unico, una riga '[dep]' per dipendenza nell'ordine di
    installazione; nessuna conferma interattiva. Un ciclo nel catalogo e' un errore
    e ferma l'installazione prima di scrivere. Nome sconosciuto -> errore con
    l'elenco dei pacchetti disponibili. Mutuamente esclusivo con -Global.
.PARAMETER NoDependencies
    Solo con -Package. Non installa le dipendenze mancanti: le elenca come '[skip]'
    con un avviso e installa solo il pacchetto richiesto. Vale anche per il core.
.PARAMETER SourceRoot
    Solo con -Package. Cartella dell'host, relativa alla radice, dove finiscono i
    sorgenti applicativi dei pacchetti (campo 'sourceFiles' del catalogo), es.
    'frontend' quando src/ sta in una sottocartella. Default: la radice. Percorsi
    assoluti o con '..' sono rifiutati. I sorgenti gia' presenti non si sovrascrivono
    mai: con -Update la versione nuova va in '<file>.new'.
.PARAMETER WithMcp
    Solo per l'installazione nel progetto (non con -Global). Copia anche .mcp.example.json
    come .mcp.json, cioe' attiva nel progetto i server MCP dell'esempio. Senza questo
    switch il file non si installa e l'installer stampa un '[sugg]'. Un .mcp.json gia'
    presente con contenuto diverso non si sovrascrive mai.
.PARAMETER ForceRemoteLib
    Quando lo script gira da un clone locale (cartella con accanto la libreria), si usano
    la libreria e il catalogo locali: e' la versione che stai sviluppando o provando.
    Con questo switch si ignora il clone e si carica la libreria pubblicata su GitHub,
    come farebbe un host con `irm | iex`. Sotto `iex` non ha effetto: il clone non c'e'.
    Se il download dal raw pubblico fallisce, il clone locale resta comunque un ripiego.
#>

[CmdletBinding()]
param(
    [switch]$Update,
    [switch]$Global,
    [string]$Package,
    [switch]$NoDependencies,
    [string]$SourceRoot = ".",
    [switch]$WithMcp,
    [switch]$ForceRemoteLib
)

# --- Risoluzione della libreria condivisa ---
# Ordine di preferenza. Il primo tentativo che riesce vince.
#   1. clone locale       -> $PSScriptRoot valorizzato (invocazione da path), vuoto sotto `iex`.
#                            Ha la precedenza: lo script e la sua libreria devono essere della stessa versione.
#                            -ForceRemoteLib lo salta.
#   2. raw pubblico       -> caso normale a repo Public
#   3. clone locale       -> ripiego se il punto 1 era stato saltato con -ForceRemoteLib e il raw e' fallito
#   4. gh api             -> repo Private con gh autenticato: l'unica via che scarica davvero da GitHub

$libName    = "dr-guidelines-install-lib.ps1"
$libRepo    = "davraf-amuro/dr-guidelines"
$libUrl     = "https://raw.githubusercontent.com/$libRepo/main/$libName"
$libLoaded  = $false
$libFailures = @()
$localLib   = if ($PSScriptRoot) { Join-Path $PSScriptRoot $libName } else { $null }

if (-not $ForceRemoteLib -and $localLib -and (Test-Path $localLib)) {
    . $localLib
    $libLoaded = $true
    $Script:PreferLocalSource = $true
    Write-Host "  Libreria: copia locale ($localLib). Per usare quella pubblicata: -ForceRemoteLib." -ForegroundColor DarkGray
}

if (-not $libLoaded) {
    try {
        $libContent = Invoke-RestMethod -Uri $libUrl -ErrorAction Stop
        Invoke-Expression $libContent
        $libLoaded = $true
    } catch {
        $libFailures += "raw pubblico: $($_.Exception.Message)"
    }
}

if (-not $libLoaded) {
    if ($localLib -and (Test-Path $localLib)) {
        . $localLib
        $libLoaded = $true
    } elseif ($PSScriptRoot) {
        $libFailures += "clone locale: $libName non trovato in $PSScriptRoot"
    } else {
        $libFailures += "clone locale: nessuno ($PSScriptRoot vuoto, script eseguito da stream)"
    }
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

if ($Global -and $Package) {
    throw "-Global e -Package sono mutuamente esclusivi: -Global scrive ~/.claude/CLAUDE.md e non tocca il progetto corrente."
}
if ($PSBoundParameters.ContainsKey('SourceRoot') -and -not $Package) {
    throw "-SourceRoot vale solo con -Package: il core non distribuisce sorgenti applicativi."
}
if ($Global -and $WithMcp) {
    throw "-WithMcp vale solo per l'installazione nel progetto: -Global non tocca il progetto corrente."
}

if ($Global) {
    Install-DrGlobal -Update:$Update
} elseif ($Package) {
    Install-DrPackage -PackageName $Package -Update:$Update -NoDependencies:$NoDependencies -SourceRoot $SourceRoot -WithMcp:$WithMcp
} else {
    Install-DrPackage -PackageName "dr-guidelines" -Update:$Update -WithMcp:$WithMcp
}
