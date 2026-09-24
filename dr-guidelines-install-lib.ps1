<#
.SYNOPSIS
    Libreria condivisa per l'installazione dei pacchetti dr-* (dr-guidelines e domini).
.DESCRIPTION
    Non eseguire direttamente. Viene fetchata a runtime da ciascun <pacchetto>-install.ps1
    (thin wrapper) e dot-sourced/eval'd per esporre Install-DrPackage, Install-DrGlobal
    e il registro pacchetti.

    Vive solo in dr-guidelines: anche gli installer dei pacchetti dominio la prendono da qui.
#>

# L'elenco dei pacchetti vive in un posto solo: scaffolding-catalog.json nel repo core.
# Aggiungere un pacchetto e' una voce nel catalogo, non una modifica a questo script.
$Script:CatalogRepo   = "davraf-amuro/dr-guidelines"
$Script:CatalogName   = "scaffolding-catalog.json"
$Script:AllowedOwner  = "davraf-amuro"
$Script:Catalog         = $null
$Script:PackageRegistry = $null

function Get-DrCatalog {
    if ($Script:Catalog) { return $Script:Catalog }

    # Stessa catena di fallback con cui i wrapper caricano questa libreria:
    #   1. raw pubblico   2. copia locale accanto allo script   3. gh api (repo Private)
    $failures = @()
    $parsed   = $null

    try {
        $content = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/$Script:CatalogRepo/main/$Script:CatalogName" -ErrorAction Stop
        $parsed  = if ($content -is [string]) { $content | ConvertFrom-Json } else { $content }
    } catch {
        $failures += "raw pubblico: $($_.Exception.Message)"
    }

    if (-not $parsed -and $PSScriptRoot) {
        $localCatalog = Join-Path $PSScriptRoot $Script:CatalogName
        if (Test-Path $localCatalog) {
            try {
                $parsed = Get-Content $localCatalog -Raw | ConvertFrom-Json
            } catch {
                $failures += "copia locale: JSON non valido in $localCatalog"
            }
        } else {
            $failures += "copia locale: $Script:CatalogName non trovato in $PSScriptRoot"
        }
    }

    if (-not $parsed -and (Get-Command gh -ErrorAction SilentlyContinue)) {
        try {
            $content = gh api "repos/$Script:CatalogRepo/contents/$Script:CatalogName" -H "Accept: application/vnd.github.raw" 2>$null | Out-String
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($content)) {
                throw "gh api ha restituito exit $LASTEXITCODE (autenticato? 'gh auth status')"
            }
            $parsed = $content | ConvertFrom-Json
        } catch {
            $failures += "gh api: $($_.Exception.Message)"
        }
    }

    # Nessun elenco incorporato come ripiego: un catalogo non raggiungibile e' un errore,
    # non un motivo per installare da una lista potenzialmente obsoleta.
    if (-not $parsed) {
        throw "Impossibile caricare $Script:CatalogName. Tentativi: $($failures -join ' | ')"
    }

    $Script:Catalog = $parsed
    return $Script:Catalog
}

function Get-DrPackageRegistry {
    if ($Script:PackageRegistry) { return $Script:PackageRegistry }

    $catalog  = Get-DrCatalog
    $registry = @{}

    foreach ($p in $catalog.packages) {
        # L'URL da clonare arriva da un file di dati: l'owner deve restare quello atteso
        $owner = ($p.repo -split '/')[0]
        if ($owner -ne $Script:AllowedOwner) {
            throw "Pacchetto '$($p.name)': owner non consentito '$owner' (atteso '$Script:AllowedOwner')."
        }

        $registry[$p.name] = @{
            Repo              = $p.repo
            IsCore            = [bool]$p.isCore
            Dependencies      = @($p.dependencies      | Where-Object { $_ })
            RootFiles         = @($p.rootFiles         | Where-Object { $_ })
            ObsoleteArtifacts = @($p.obsoleteArtifacts | Where-Object { $_ })
        }
    }

    $Script:PackageRegistry = $registry
    return $registry
}

function Copy-GuidelineFile {
    param(
        [string]$SrcFile,
        [string]$DestFile,
        [switch]$Update
    )
    if (-not (Test-Path $SrcFile)) { return }

    $destDir = Split-Path $DestFile -Parent
    if ($destDir -and -not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    if ((Test-Path $DestFile) -and -not $Update) {
        Write-Host "  [SKIP] $(Split-Path $DestFile -Leaf)" -ForegroundColor DarkGray
        return
    }
    $isUpdate = $Update -and (Test-Path $DestFile)
    Copy-Item -Path $SrcFile -Destination $DestFile -Force
    $tag = if ($isUpdate) { "[UPD]" } else { "[OK] " }
    Write-Host "  $tag  $(Split-Path $DestFile -Leaf)" -ForegroundColor Green
}

function Copy-InstructionsAndPrompts {
    param([string]$TempRoot, [string]$HostRoot, [switch]$Update)

    foreach ($sub in @("instructions", "prompts")) {
        $srcDir = Join-Path $TempRoot ".github\$sub"
        if (-not (Test-Path $srcDir)) { continue }

        $destDir = Join-Path $HostRoot ".github\$sub"
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

        Write-Host "  .github/$sub/:" -ForegroundColor White
        foreach ($f in Get-ChildItem $srcDir -File) {
            Copy-GuidelineFile -SrcFile $f.FullName -DestFile (Join-Path $destDir $f.Name) -Update:$Update
        }
    }
}

function Copy-Skills {
    param([string]$TempRoot, [string]$HostRoot, [switch]$Update)

    $srcDir = Join-Path $TempRoot ".claude\skills"
    if (-not (Test-Path $srcDir)) { return }

    $destDir = Join-Path $HostRoot ".claude\skills"
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

    Write-Host "  .claude/skills/:" -ForegroundColor White
    foreach ($dir in Get-ChildItem $srcDir -Directory) {
        $destSkillDir = Join-Path $destDir $dir.Name
        if ((Test-Path $destSkillDir) -and -not $Update) {
            Write-Host "  [SKIP] $($dir.Name)/" -ForegroundColor DarkGray
            continue
        }
        $isUpdate = $Update -and (Test-Path $destSkillDir)
        if (-not (Test-Path $destSkillDir)) { New-Item -ItemType Directory -Path $destSkillDir -Force | Out-Null }
        Copy-Item -Path (Join-Path $dir.FullName "*") -Destination $destSkillDir -Recurse -Force
        $tag = if ($isUpdate) { "[UPD]" } else { "[OK] " }
        Write-Host "  $tag  $($dir.Name)/" -ForegroundColor Green
    }
}

function Remove-ObsoleteArtifacts {
    param([string]$HostRoot, [string[]]$Artifacts)

    # Skill e prompt rinominati a monte: la copia installa il nome nuovo ma non rimuove il vecchio.
    # Senza questa pulizia l'host si ritrova due skill attive con la stessa descrizione e l'agente
    # non sa quale invocare. Si esegue solo con -Update: una prima installazione non ha nulla da togliere.
    if (-not $Artifacts -or $Artifacts.Count -eq 0) { return }

    $removed = @()
    foreach ($relative in $Artifacts) {
        # Il catalogo e' un file di dati: un percorso fuori dalle due cartelle gestite e' un errore,
        # non una rimozione da tentare comunque.
        $normalized = $relative -replace '\\', '/'
        if ($normalized -match '(^|/)\.\.(/|$)' -or [System.IO.Path]::IsPathRooted($normalized)) {
            throw "obsoleteArtifacts: percorso non relativo o con risalita '$relative'."
        }
        if ($normalized -notmatch '^(\.claude/skills/|\.github/)') {
            throw "obsoleteArtifacts: '$relative' e' fuori da .claude/skills/ e .github/."
        }

        # String.Replace, non -replace: l'operatore e' regex e il separatore di Windows e' un escape
        $target = Join-Path $HostRoot $normalized.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        if (Test-Path $target) {
            Remove-Item -Path $target -Recurse -Force
            $removed += $normalized
        }
    }

    if ($removed.Count -gt 0) {
        Write-Host "  Artefatti obsoleti rimossi:" -ForegroundColor White
        $removed | ForEach-Object { Write-Host "  [DEL]  $_" -ForegroundColor Yellow }
    }
}

function Copy-PackageRootFiles {
    param([string]$TempRoot, [string]$HostRoot, [string[]]$RootFiles, [switch]$Update)

    # File di radice propri di un pacchetto di dominio (es. Directory.Build.props per .NET).
    # Chi installa il pacchetto ha gia' dichiarato il dominio: nessun rilevamento dello stack,
    # altrimenti in una cartella vuota i file verrebbero saltati proprio quando servono.
    if (-not $RootFiles -or $RootFiles.Count -eq 0) { return }

    Write-Host "  File di configurazione del pacchetto:" -ForegroundColor White
    foreach ($file in $RootFiles) {
        Copy-GuidelineFile -SrcFile (Join-Path $TempRoot $file) -DestFile (Join-Path $HostRoot $file) -Update:$Update
    }
}

function Copy-CoreConfigFiles {
    param([string]$TempRoot, [string]$HostRoot, [switch]$Update)

    Write-Host "  File di configurazione:" -ForegroundColor White
    foreach ($file in @(".editorconfig", ".gitignore", ".gitattributes")) {
        Copy-GuidelineFile -SrcFile (Join-Path $TempRoot $file) -DestFile (Join-Path $HostRoot $file) -Update:$Update
    }

    # copilot-instructions.md sta qui e non in Copy-InstructionsAndPrompts perche' e' contenuto
    # del solo core: questa funzione e' invocata sotto IsCore, quella e' per-pacchetto e
    # duplicherebbe il file a ogni pacchetto di dominio installato. Senza questa copia il
    # riferimento @.github/copilot-instructions.md iniettato in CLAUDE.md punta al nulla.
    $copilotInstructions = ".github\copilot-instructions.md"
    Copy-GuidelineFile -SrcFile (Join-Path $TempRoot $copilotInstructions) -DestFile (Join-Path $HostRoot $copilotInstructions) -Update:$Update

    # Directory.Build.props e global.json non stanno piu' nel core: sono contenuto .NET
    # e vivono in dr-dotnet-backend, che li installa quando il progetto e' davvero .NET.

    # .mcp.json: mai sovrascritto se il contenuto host diverge (puo contenere server MCP aggiunti dal progetto)
    $mcpSrc  = Join-Path $TempRoot ".mcp.example.json"
    $mcpDest = Join-Path $HostRoot ".mcp.json"
    if (Test-Path $mcpSrc) {
        if (-not (Test-Path $mcpDest)) {
            Copy-Item -Path $mcpSrc -Destination $mcpDest
            Write-Host "  [OK]   .mcp.json" -ForegroundColor Green
        } elseif ((Get-FileHash $mcpSrc).Hash -ne (Get-FileHash $mcpDest).Hash) {
            Write-Host "  [WARN] .mcp.json esiste con contenuto diverso - non sovrascritto, confronta manualmente" -ForegroundColor Yellow
        } else {
            Write-Host "  [SKIP] .mcp.json identico" -ForegroundColor DarkGray
        }
    }
}

function Merge-ClaudeSettings {
    param([string]$TempRoot, [string]$HostRoot)

    # Merge non distruttivo dei permessi condivisi: aggiunge solo le voci permissions.allow
    # mancanti. Le altre chiavi del file host (mcpServers, env, hooks) non vengono toccate.
    # Additivo e idempotente: si esegue anche senza -Update.
    $src  = Join-Path $TempRoot ".claude\settings.json"
    $dest = Join-Path $HostRoot ".claude\settings.json"

    Write-Host "  .claude/settings.json:" -ForegroundColor White

    if (-not (Test-Path $src)) {
        Write-Host "  [WARN] settings.json non trovato nel pacchetto core" -ForegroundColor Yellow
        return
    }

    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

    if (-not (Test-Path $dest)) {
        Copy-Item -Path $src -Destination $dest -Force
        Write-Host "  [OK]   .claude/settings.json" -ForegroundColor Green
        return
    }

    $srcJson  = $null
    $destJson = $null
    try {
        $srcJson  = Get-Content $src  -Raw | ConvertFrom-Json
        $destJson = Get-Content $dest -Raw | ConvertFrom-Json
    } catch {
        Write-Host "  [WARN] JSON non valido - merge saltato, confronta manualmente" -ForegroundColor Yellow
        return
    }
    if ($null -eq $srcJson -or $null -eq $destJson) { return }

    if (-not $destJson.PSObject.Properties['permissions']) {
        $destJson | Add-Member -NotePropertyName permissions -NotePropertyValue ([pscustomobject]@{ allow = @() })
    }
    if (-not $destJson.permissions.PSObject.Properties['allow']) {
        $destJson.permissions | Add-Member -NotePropertyName allow -NotePropertyValue @()
    }

    $destAllow = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in @($destJson.permissions.allow)) {
        if ($entry) { $destAllow.Add([string]$entry) }
    }

    $added = 0
    foreach ($entry in @($srcJson.permissions.allow)) {
        if ($entry -and -not $destAllow.Contains([string]$entry)) {
            $destAllow.Add([string]$entry)
            $added++
        }
    }

    if ($added -gt 0) {
        $destJson.permissions.allow = $destAllow.ToArray()
        $out = $destJson | ConvertTo-Json -Depth 20
        # UTF-8 senza BOM: indipendente dalla versione di PowerShell
        [System.IO.File]::WriteAllText($dest, $out, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  [UPD]  .claude/settings.json - $added voci aggiunte" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] .claude/settings.json - nessuna voce da aggiungere" -ForegroundColor DarkGray
    }
}

function Copy-ScaffoldingCatalog {
    param([string]$TempRoot, [string]$HostRoot, [switch]$Update)

    # Le skill dr-scaffold* girano nel progetto host e non vedono la root del repo dr-guidelines:
    # il catalogo va distribuito insieme al core, sotto .ai\
    $src = Join-Path $TempRoot "scaffolding-catalog.json"
    if (-not (Test-Path $src)) {
        Write-Host "  [WARN] scaffolding-catalog.json non trovato nel pacchetto core" -ForegroundColor Yellow
        return
    }

    Write-Host "  Catalogo scaffolding:" -ForegroundColor White
    Copy-GuidelineFile -SrcFile $src -DestFile (Join-Path $HostRoot ".ai\dr-scaffolding-catalog.json") -Update:$Update
}

function New-BriefsFolder {
    param([string]$HostRoot)

    # briefs\ e' dell'utente: ci scrive le richieste da indicare all'agente, che ne ricava un piano.
    # L'installer crea solo la cartella, vuota; il contenuto non si legge ne' si tocca, nemmeno con -Update.
    $dest = Join-Path $HostRoot "briefs"
    Write-Host "  Cartella brief:" -ForegroundColor White
    if (Test-Path $dest) {
        Write-Host "  [SKIP] briefs\ gia presente" -ForegroundColor DarkGray
        return
    }
    New-Item -ItemType Directory -Path $dest | Out-Null
    Write-Host "  [OK]   briefs\" -ForegroundColor Green
}

function Merge-ClaudeMdSection {
    param(
        [string]$SrcClaudeMd,
        [string]$DestClaudeMd,
        [string]$PackageName,
        [switch]$Update
    )
    if (-not (Test-Path $SrcClaudeMd)) {
        Write-Host "  [WARN] CLAUDE.md non trovato nel pacchetto $PackageName" -ForegroundColor Yellow
        return
    }

    $srcRaw  = Get-Content $SrcClaudeMd -Raw -Encoding UTF8
    $srcBody = ($srcRaw -replace "^#[^\n]*\n+", "").TrimStart()

    $startMarker = "<!-- $PackageName -->"
    $endMarker   = "<!-- /$PackageName -->"
    $block       = "$startMarker`n$srcBody`n$endMarker"

    if (-not (Test-Path $DestClaudeMd)) {
        Set-Content -Path $DestClaudeMd -Value ($block + "`n") -Encoding UTF8
        Write-Host "  [OK]   CLAUDE.md creato con sezione $PackageName" -ForegroundColor Green
        return
    }

    $existing = Get-Content $DestClaudeMd -Raw -Encoding UTF8
    $escStart = [regex]::Escape($startMarker)
    $escEnd   = [regex]::Escape($endMarker)
    $pattern  = "(?s)$escStart.*?$escEnd"

    if ($existing -match $pattern) {
        if (-not $Update) {
            Write-Host "  [SKIP] Sezione $PackageName gia presente in CLAUDE.md (usa -Update per aggiornare)" -ForegroundColor DarkGray
            return
        }
        $newContent = [regex]::Replace($existing, $pattern, $block)
        Set-Content -Path $DestClaudeMd -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "  [UPD]  Sezione $PackageName aggiornata in CLAUDE.md" -ForegroundColor Green
    } else {
        $newContent = $existing.TrimEnd() + "`n`n" + $block + "`n"
        Set-Content -Path $DestClaudeMd -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "  [OK]   Sezione $PackageName inserita in CLAUDE.md" -ForegroundColor Green
    }
}

function Get-DrManifestPath {
    param([string]$HostRoot)
    return Join-Path $HostRoot ".ai\dr-guidelines-packages.json"
}

function Read-DrManifest {
    param([string]$HostRoot)
    $path = Get-DrManifestPath -HostRoot $HostRoot
    if (-not (Test-Path $path)) {
        return [PSCustomObject]@{ installed = @() }
    }
    $raw = Get-Content $path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [PSCustomObject]@{ installed = @() }
    }
    return $raw | ConvertFrom-Json
}

function Test-DrPackageInstalled {
    param($Manifest, [string]$PackageName)
    return [bool]($Manifest.installed | Where-Object { $_.package -eq $PackageName })
}

function Get-DrInstalledCommit {
    param($Manifest, [string]$PackageName)
    $entry = $Manifest.installed | Where-Object { $_.package -eq $PackageName }
    if ($entry -and $entry.PSObject.Properties['commit']) { return $entry.commit }
    return $null
}

function Update-DrManifest {
    param([string]$HostRoot, [string]$PackageName, [string]$Commit)

    $path = Get-DrManifestPath -HostRoot $HostRoot
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $manifest      = Read-DrManifest -HostRoot $HostRoot
    $installedList = @($manifest.installed)
    $existing      = $installedList | Where-Object { $_.package -eq $PackageName }
    $today         = Get-Date -Format "yyyy-MM-dd"

    if ($existing) {
        $existing.installedAt = $today
        # Il manifest e' anche il lock file: registra da quale commit arriva il contenuto installato
        if (-not $existing.PSObject.Properties['commit']) {
            $existing | Add-Member -NotePropertyName commit -NotePropertyValue $Commit
        } else {
            $existing.commit = $Commit
        }
    } else {
        $installedList += [PSCustomObject]@{ package = $PackageName; installedAt = $today; commit = $Commit }
    }

    $manifest.installed = $installedList
    ($manifest | ConvertTo-Json -Depth 5) | Set-Content -Path $path -Encoding UTF8

    $shortCommit = if ($Commit) { $Commit.Substring(0, [Math]::Min(7, $Commit.Length)) } else { "sconosciuto" }
    Write-Host "  [OK]   Manifest aggiornato: $PackageName ($shortCommit)" -ForegroundColor Green
}

function Install-DrPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        [switch]$Update
    )

    $registry = Get-DrPackageRegistry
    if (-not $registry.ContainsKey($PackageName)) {
        throw "Pacchetto sconosciuto: $PackageName. Pacchetti disponibili: $($registry.Keys -join ', ')"
    }

    $pkg      = $registry[$PackageName]
    $hostRoot = (Get-Location).Path

    Write-Host ""
    Write-Host "=== $PackageName ===" -ForegroundColor Cyan
    Write-Host "  Repo    : $($pkg.Repo)"
    Write-Host "  Progetto: $hostRoot"

    # Risoluzione dipendenze: -Update non si propaga, riguarda solo il pacchetto richiesto esplicitamente
    $manifest = Read-DrManifest -HostRoot $hostRoot
    foreach ($dep in $pkg.Dependencies) {
        if (-not (Test-DrPackageInstalled -Manifest $manifest -PackageName $dep)) {
            Write-Host "  Dipendenza mancante: $dep -> installazione automatica" -ForegroundColor Yellow
            Install-DrPackage -PackageName $dep
            $manifest = Read-DrManifest -HostRoot $hostRoot
        }
    }

    $tempDir = Join-Path $env:TEMP ("dr-install-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        Write-Host "  Clonazione $($pkg.Repo)..." -ForegroundColor White
        git clone --quiet --depth 1 "https://github.com/$($pkg.Repo).git" $tempDir 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "git clone fallito per $($pkg.Repo) (repo Private? verifica autenticazione git/gh)"
        }

        # Commit effettivamente installato: e' quello che finisce nel manifest/lock file
        $newCommit = (git -C $tempDir rev-parse HEAD 2>$null | Out-String).Trim()
        $oldCommit = Get-DrInstalledCommit -Manifest $manifest -PackageName $PackageName

        if ($oldCommit -and $newCommit) {
            if ($oldCommit -eq $newCommit) {
                Write-Host "  Nessuna novita': gia' al commit $($newCommit.Substring(0,7))" -ForegroundColor DarkGray
            } else {
                Write-Host "  Aggiornamento: $($oldCommit.Substring(0,7)) -> $($newCommit.Substring(0,7))" -ForegroundColor White
                # --quiet perche' il clone e' --depth 1: il vecchio commit non e' nella history locale
                $changed = git -C $tempDir diff --name-only "$oldCommit" HEAD 2>$null
                if ($LASTEXITCODE -eq 0 -and $changed) {
                    Write-Host "  File modificati a monte:" -ForegroundColor White
                    $changed | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
                }
            }
        }

        Copy-InstructionsAndPrompts -TempRoot $tempDir -HostRoot $hostRoot -Update:$Update
        Copy-Skills -TempRoot $tempDir -HostRoot $hostRoot -Update:$Update

        if ($Update -and $pkg.ObsoleteArtifacts) {
            Remove-ObsoleteArtifacts -HostRoot $hostRoot -Artifacts $pkg.ObsoleteArtifacts
        }

        if ($pkg.RootFiles) {
            Copy-PackageRootFiles -TempRoot $tempDir -HostRoot $hostRoot -RootFiles $pkg.RootFiles -Update:$Update
        }

        if ($pkg.IsCore) {
            Copy-CoreConfigFiles -TempRoot $tempDir -HostRoot $hostRoot -Update:$Update
            Merge-ClaudeSettings -TempRoot $tempDir -HostRoot $hostRoot
            Copy-ScaffoldingCatalog -TempRoot $tempDir -HostRoot $hostRoot -Update:$Update
            New-BriefsFolder -HostRoot $hostRoot
            Write-Host "  CLAUDE.md:" -ForegroundColor White
            Merge-ClaudeMdSection -SrcClaudeMd (Join-Path $tempDir "CLAUDE.md") -DestClaudeMd (Join-Path $hostRoot "CLAUDE.md") -PackageName $PackageName -Update:$Update
        }

        Update-DrManifest -HostRoot $hostRoot -PackageName $PackageName -Commit $newCommit
    }
    finally {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "  Completato: $PackageName" -ForegroundColor Cyan
}

function Install-DrGlobal {
    <#
    .SYNOPSIS
        Installa o aggiorna la sezione linee guida globali in ~/.claude/CLAUDE.md.
    .DESCRIPTION
        Non tocca il progetto corrente: scrive solo nel file CLAUDE.md dell'utente,
        che Claude Code carica in ogni sessione. La sezione e' delimitata dal titolo
        "## Davraf Guidelines (Globale)" e dal sentinel "<!-- /davraf-guidelines -->":
        tutto cio' che sta fuori da quel blocco viene preservato.

        Il template si prende dal clone locale se disponibile ($PSScriptRoot valorizzato),
        altrimenti da un clone temporaneo del pacchetto core.
    .PARAMETER Update
        Sovrascrive la sezione se gia' presente. Senza questo switch, una sezione
        esistente viene lasciata intatta.
    .PARAMETER ClaudeMdPath
        Percorso del CLAUDE.md globale. Default: ~/.claude/CLAUDE.md. Serve per i test,
        che non devono scrivere nella home reale.
    #>
    [CmdletBinding()]
    param(
        [switch]$Update,
        [string]$ClaudeMdPath = (Join-Path $HOME ".claude\CLAUDE.md")
    )

    $sectionTitle = "## Davraf Guidelines (Globale)"
    $endMarker    = "<!-- /davraf-guidelines -->"

    Write-Host ""
    Write-Host "=== dr-guidelines (installazione globale) ===" -ForegroundColor Cyan
    Write-Host "  Target  : $ClaudeMdPath"

    $tempDir = $null
    try {
        # $PSScriptRoot e' valorizzato solo quando la libreria e' stata dot-sourced da un clone locale:
        # fetchata via raw o via gh api, il template si prende dal clone temporaneo.
        $localTemplate = if ($PSScriptRoot) { Join-Path $PSScriptRoot "templates\global-claude.md" } else { $null }

        if ($localTemplate -and (Test-Path $localTemplate)) {
            $templatePath = $localTemplate
            Write-Host "  Sorgente: $templatePath"
        } else {
            $repo    = (Get-DrPackageRegistry)["dr-guidelines"].Repo
            $tempDir = Join-Path $env:TEMP ("dr-install-" + [guid]::NewGuid().ToString("N"))
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

            Write-Host "  Clonazione $repo..." -ForegroundColor White
            git clone --quiet --depth 1 "https://github.com/$repo.git" $tempDir 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "git clone fallito per $repo (repo Private? verifica autenticazione git/gh)"
            }
            $templatePath = Join-Path $tempDir "templates\global-claude.md"
        }

        if (-not (Test-Path $templatePath)) {
            throw "Template non trovato: $templatePath"
        }

        $templateRaw  = Get-Content $templatePath -Raw -Encoding UTF8
        $templateBody = ($templateRaw -replace "^#[^\n]*\n+", "").TrimStart()
        $block        = "$sectionTitle`n`n$templateBody`n$endMarker"

        $claudeDir = Split-Path $ClaudeMdPath -Parent
        if ($claudeDir -and -not (Test-Path $claudeDir)) {
            New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
        }

        if (-not (Test-Path $ClaudeMdPath)) {
            Set-Content -Path $ClaudeMdPath -Value ($block + "`n") -Encoding UTF8
            Write-Host "  [OK]   CLAUDE.md globale creato con la sezione linee guida" -ForegroundColor Green
        } else {
            $existing = Get-Content $ClaudeMdPath -Raw -Encoding UTF8
            $pattern  = "(?s)" + [regex]::Escape($sectionTitle) + ".*?" + [regex]::Escape($endMarker)

            if ($existing -match $pattern) {
                if ($Update) {
                    # MatchEvaluator invece della stringa: nel blocco un eventuale '$' non va interpretato come riferimento
                    $newContent = [regex]::Replace($existing, $pattern, { param($m) $block })
                    Set-Content -Path $ClaudeMdPath -Value $newContent -Encoding UTF8 -NoNewline
                    Write-Host "  [UPD]  Sezione globale aggiornata" -ForegroundColor Green
                } else {
                    Write-Host "  [SKIP] Sezione globale gia presente (usa -Global -Update per aggiornarla)" -ForegroundColor DarkGray
                }
            } elseif ($existing -match [regex]::Escape($sectionTitle)) {
                Write-Host "  [WARN] Intestazione presente ma sentinel '$endMarker' mancante - verifica manualmente" -ForegroundColor Yellow
            } else {
                $newContent = $existing.TrimEnd() + "`n`n" + $block + "`n"
                Set-Content -Path $ClaudeMdPath -Value $newContent -Encoding UTF8 -NoNewline
                Write-Host "  [OK]   Sezione globale inserita nel CLAUDE.md esistente" -ForegroundColor Green
            }
        }
    }
    finally {
        if ($tempDir) { Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Write-Host "  Completato: installazione globale" -ForegroundColor Cyan
    Write-Host "  Nota: Claude Code carica questo file a ogni sessione; un CLAUDE.md di progetto ha precedenza." -ForegroundColor DarkGray
}
