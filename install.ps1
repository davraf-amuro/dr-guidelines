<#
.SYNOPSIS
    Installa il pacchetto dr-guidelines (core) nel progetto corrente, oppure le linee guida globali.
.DESCRIPTION
    Esegui dalla root del progetto host.

    Installazione:
        irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/install.ps1 | iex

    Aggiornamento (sovrascrive i file gia presenti, merge sezione CLAUDE.md):
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/install.ps1))) -Update

    Installazione globale (scrive ~/.claude/CLAUDE.md, non tocca il progetto corrente):
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/install.ps1))) -Global

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

if ($Global) {
    Install-DrGlobal -Update:$Update
} else {
    Install-DrPackage -PackageName "dr-guidelines" -Update:$Update
}
