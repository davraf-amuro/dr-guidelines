<#
.SYNOPSIS
    Installa il pacchetto dr-guidelines (core) nel progetto corrente.
.DESCRIPTION
    Esegui dalla root del progetto host.

    Installazione:
        irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/install.ps1 | iex

    Aggiornamento (sovrascrive i file gia presenti, merge sezione CLAUDE.md):
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/install.ps1))) -Update

    dr-guidelines e' il pacchetto core: instructions/skill trasversali, file di
    configurazione radice, sezione CLAUDE.md. Nessuna dipendenza.
.PARAMETER Update
    Sovrascrive i file gia presenti nel progetto con la versione corrente del pacchetto.
#>

[CmdletBinding()]
param([switch]$Update)

$libUrl = "https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/install-lib.ps1"

try {
    $libContent = Invoke-RestMethod -Uri $libUrl
    Invoke-Expression $libContent
} catch {
    # Fallback per test in fase Private (gate 2b): invocazione da path locale del workspace,
    # dove $PSScriptRoot e' valorizzato (non e' il caso di `irm | iex`, dove e' vuoto).
    if ($PSScriptRoot) {
        $localLib = Join-Path $PSScriptRoot "install-lib.ps1"
        if (Test-Path $localLib) {
            . $localLib
        } else {
            throw
        }
    } else {
        throw
    }
}

Install-DrPackage -PackageName "dr-guidelines" -Update:$Update
