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

function Assert-DrRelativePath {
    # Il catalogo e i parametri sono dati: un percorso che esce dalla cartella prevista e' un
    # errore da fermare prima di scrivere, non un caso da gestire. Restituisce il percorso con '/'.
    param([string]$Path, [string]$Field, [switch]$AllowCurrent)

    if ([string]::IsNullOrWhiteSpace($Path)) { throw "${Field}: percorso vuoto." }
    $normalized = $Path.Trim() -replace '\\', '/'
    if ([System.IO.Path]::IsPathRooted($normalized) -or $normalized -match '^[A-Za-z]:' -or $normalized.StartsWith('/')) {
        throw "${Field}: percorso assoluto non ammesso '$Path'."
    }
    if ($normalized -match '(^|/)\.\.(/|$)') {
        throw "${Field}: risalita '..' non ammessa '$Path'."
    }
    if (-not $AllowCurrent -and $normalized -match '^\.?/?$') {
        throw "${Field}: serve un file, non la cartella corrente."
    }
    return $normalized
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
            AppliesTo         = @($p.appliesTo         | Where-Object { $_ })
            Dependencies      = @($p.dependencies      | Where-Object { $_ })
            RootFiles         = @($p.rootFiles         | Where-Object { $_ })
            ObsoleteArtifacts = @($p.obsoleteArtifacts | Where-Object { $_ })
            # File che valgono solo nel repo del pacchetto: presenti nel clone, mai copiati negli host
            CoreOnlyArtifacts = @($p.coreOnlyArtifacts | Where-Object { $_ })
            # Rimandi non vincolanti: mai installati, solo segnalati a fine installazione
            Suggests          = @($p.suggests          | Where-Object { $_ -and $_.package })
            # Sorgenti applicativi: destinazione relativa alla cartella sorgente dell'host (-SourceRoot)
            SourceFiles       = @(foreach ($sf in @($p.sourceFiles | Where-Object { $null -ne $_ })) {
                [PSCustomObject]@{
                    From = Assert-DrRelativePath -Path $sf.from -Field "pacchetto '$($p.name)', sourceFiles.from"
                    To   = Assert-DrRelativePath -Path $sf.to   -Field "pacchetto '$($p.name)', sourceFiles.to"
                }
            })
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

function Copy-ProtectedFile {
    <#
    .SYNOPSIS
        Copia un file di configurazione che l'host puo' aver personalizzato (.gitignore, rootFiles, ...).
    .DESCRIPTION
        Senza -Update un file presente si salta. Con -Update il confronto e' a tre vie:
          - host uguale alla nuova versione                 -> [=], nulla da scrivere
          - host uguale alla versione del commit di riferimento (quello installato prima)
                                                             -> mai personalizzato, si sovrascrive
          - personalizzato, ma invariato a monte dal riferimento
                                                             -> [SKIP], nulla da proporre
          - altrimenti                                       -> nuova versione in '<file>.new',
                                                                l'originale non si tocca
        Senza commit di riferimento non si sa se il file e' stato personalizzato: si sceglie
        la via prudente, '.new'. Il confronto col riferimento usa gli id dei blob git (hash-object
        con gli stessi attributi del pacchetto), quindi regge alle conversioni dei fine riga.
        Restituisce il percorso relativo del '.new' scritto; altrimenti nulla.
    #>
    param(
        [string]$TempRoot,
        [string]$HostRoot,
        [string]$RelativePath,
        [string]$BaselineCommit,
        [switch]$Update
    )
    $src     = Join-Path $TempRoot $RelativePath
    $dest    = Join-Path $HostRoot $RelativePath
    $gitPath = $RelativePath -replace '\\', '/'
    if (-not (Test-Path $src -PathType Leaf)) { return }

    if (-not (Test-Path $dest)) {
        Copy-GuidelineFile -SrcFile $src -DestFile $dest
        return
    }
    if (-not $Update) {
        Write-Host "  [SKIP] $gitPath" -ForegroundColor DarkGray
        return
    }
    if ((Get-FileHash $src).Hash -eq (Get-FileHash $dest).Hash) {
        Write-Host "  [=]    $gitPath invariato" -ForegroundColor DarkGray
        return
    }

    if ($BaselineCommit) {
        $baseBlob = (git -C $TempRoot rev-parse --verify --quiet "${BaselineCommit}:$gitPath" 2>$null | Out-String).Trim()
        $hostBlob = (git -C $TempRoot hash-object "--path=$gitPath" $dest 2>$null | Out-String).Trim()
        if ($baseBlob -and $baseBlob -eq $hostBlob) {
            Copy-Item -Path $src -Destination $dest -Force
            Write-Host "  [UPD]  $gitPath" -ForegroundColor Green
            return
        }
        # Personalizzato, ma a monte non e' cambiato nulla dal riferimento: non c'e' niente da
        # proporre. Senza questo controllo il '.new' ricomparirebbe a ogni aggiornamento.
        $srcBlob = (git -C $TempRoot rev-parse --verify --quiet "HEAD:$gitPath" 2>$null | Out-String).Trim()
        if ($baseBlob -and $baseBlob -eq $srcBlob) {
            Write-Host "  [SKIP] $gitPath personalizzato, invariato a monte" -ForegroundColor DarkGray
            return
        }
    }

    $replaced = Test-Path "$dest.new"
    Copy-Item -Path $src -Destination "$dest.new" -Force
    $note = if ($replaced) { "; sostituito il .new precedente" } else { "" }
    Write-Host "  [NEW]  $gitPath.new (personalizzato nell'host: l'originale non e' stato toccato$note)" -ForegroundColor Yellow
    return "$gitPath.new"
}

function Copy-InstructionsAndPrompts {
    param([string]$TempRoot, [string]$HostRoot, [string[]]$CoreOnly = @(), [switch]$Update)

    # coreOnlyArtifacts: file che regolano solo il repo del pacchetto (es. la struttura del suo
    # README) e che in un host contraddirebbero le regole generali. Stanno nel clone ma non si copiano.
    # Stesse validazioni di Remove-ObsoleteArtifacts: il catalogo e' un file di dati.
    $skip = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($relative in @($CoreOnly | Where-Object { $_ })) {
        $normalized = $relative -replace '\\', '/'
        if ($normalized -match '(^|/)\.\.(/|$)' -or [System.IO.Path]::IsPathRooted($normalized)) {
            throw "coreOnlyArtifacts: percorso non relativo o con risalita '$relative'."
        }
        if ($normalized -notmatch '^\.github/(instructions|prompts)/[^/]+$') {
            throw "coreOnlyArtifacts: '$relative' non e' un file di .github/instructions/ o .github/prompts/."
        }
        $null = $skip.Add($normalized)
    }

    foreach ($sub in @("instructions", "prompts")) {
        $srcDir = Join-Path $TempRoot ".github\$sub"
        if (-not (Test-Path $srcDir)) { continue }

        $destDir = Join-Path $HostRoot ".github\$sub"
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

        Write-Host "  .github/$sub/:" -ForegroundColor White
        foreach ($f in Get-ChildItem $srcDir -File) {
            if ($skip.Contains(".github/$sub/$($f.Name)")) {
                Write-Host "  [CORE] $($f.Name)" -ForegroundColor DarkGray
                continue
            }
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
    param([string]$TempRoot, [string]$HostRoot, [string[]]$RootFiles, [string]$BaselineCommit, [switch]$Update)

    # File di radice propri di un pacchetto di dominio (es. Directory.Build.props per .NET).
    # Chi installa il pacchetto ha gia' dichiarato il dominio: nessun rilevamento dello stack,
    # altrimenti in una cartella vuota i file verrebbero saltati proprio quando servono.
    # L'host li personalizza di solito: con -Update si sovrascrivono solo se mai modificati.
    if (-not $RootFiles -or $RootFiles.Count -eq 0) { return }

    Write-Host "  File di configurazione del pacchetto:" -ForegroundColor White
    foreach ($file in $RootFiles) {
        Copy-ProtectedFile -TempRoot $TempRoot -HostRoot $HostRoot -RelativePath $file -BaselineCommit $BaselineCommit -Update:$Update
    }
}

function Resolve-DrSourceRoot {
    # Valida -SourceRoot e restituisce il percorso assoluto, con separatore finale.
    # Si chiama prima di clonare o scrivere qualsiasi cosa: un -SourceRoot sbagliato ferma
    # l'installazione a host intatto, anche quando nessun pacchetto ha 'sourceFiles'.
    param([string]$HostRoot, [string]$SourceRoot = ".")

    $sep      = [System.IO.Path]::DirectorySeparatorChar
    $hostFull = [System.IO.Path]::GetFullPath($HostRoot).TrimEnd($sep) + $sep
    $relRoot  = Assert-DrRelativePath -Path $SourceRoot -Field "-SourceRoot" -AllowCurrent
    $rootFull = [System.IO.Path]::GetFullPath((Join-Path $HostRoot $relRoot.Replace('/', $sep))).TrimEnd($sep) + $sep
    if (-not $rootFull.StartsWith($hostFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "-SourceRoot '$SourceRoot' esce dalla radice dell'host."
    }
    return $rootFull
}

function Copy-PackageSourceFiles {
    <#
    .SYNOPSIS
        Copia i sorgenti applicativi di un pacchetto (campo 'sourceFiles' del catalogo).
    .DESCRIPTION
        La destinazione di ogni voce e' relativa a SourceRoot, una cartella dell'host
        (es. 'frontend' quando src/ sta in una sottocartella). Nessun file finisce fuori
        da SourceRoot ne' fuori dalla radice dell'host.

        I sorgenti appartengono all'host dal momento in cui sono copiati: non si
        sovrascrivono mai. Senza -Update un file presente si salta; con -Update, se il
        contenuto e' cambiato a monte, la nuova versione va in '<file>.new' accanto
        all'originale e il confronto resta a chi conosce il codice.
    #>
    param(
        [string]$TempRoot,
        [string]$HostRoot,
        [string]$SourceRoot = ".",
        [object[]]$SourceFiles,
        [switch]$Update
    )
    if (-not $SourceFiles -or $SourceFiles.Count -eq 0) { return }

    $sep      = [System.IO.Path]::DirectorySeparatorChar
    $rootFull = Resolve-DrSourceRoot -HostRoot $HostRoot -SourceRoot $SourceRoot

    Write-Host "  Sorgenti applicativi (in $SourceRoot):" -ForegroundColor White
    $newFiles = @()
    foreach ($sf in $SourceFiles) {
        $src  = Join-Path $TempRoot $sf.From.Replace('/', $sep)
        $dest = [System.IO.Path]::GetFullPath((Join-Path $rootFull $sf.To.Replace('/', $sep)))
        # Doppio controllo dopo la normalizzazione: Assert-DrRelativePath ha gia' rifiutato '..',
        # ma il confine si verifica sul percorso risolto, non sulla stringa del catalogo
        if (-not $dest.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "sourceFiles: '$($sf.To)' esce da -SourceRoot."
        }
        if (-not (Test-Path $src -PathType Leaf)) {
            Write-Host "  [MISS] $($sf.From) non presente nel pacchetto" -ForegroundColor Yellow
            continue
        }

        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

        if (-not (Test-Path $dest)) {
            Copy-Item -Path $src -Destination $dest
            Write-Host "  [OK]   $($sf.To)" -ForegroundColor Green
        } elseif (-not $Update) {
            Write-Host "  [SKIP] $($sf.To)" -ForegroundColor DarkGray
        } elseif ((Get-FileHash $src).Hash -eq (Get-FileHash $dest).Hash) {
            Write-Host "  [=]    $($sf.To) invariato" -ForegroundColor DarkGray
        } else {
            Copy-Item -Path $src -Destination "$dest.new" -Force
            $newFiles += "$($sf.To).new"
            Write-Host "  [NEW]  $($sf.To).new (l'originale non e' stato toccato)" -ForegroundColor Yellow
        }
    }

    if ($newFiles.Count -gt 0) {
        Write-Host "  Versioni nuove da confrontare a mano con l'originale, poi da eliminare:" -ForegroundColor Yellow
        $newFiles | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    }
}

function Copy-CoreConfigFiles {
    param([string]$TempRoot, [string]$HostRoot, [string]$BaselineCommit, [switch]$Update)

    # File che l'host personalizza di solito (un .gitignore di create-vue, una regola Copilot
    # locale): con -Update si sovrascrivono solo se mai modificati, altrimenti '<file>.new'.
    Write-Host "  File di configurazione:" -ForegroundColor White
    foreach ($file in @(".editorconfig", ".gitignore", ".gitattributes")) {
        Copy-ProtectedFile -TempRoot $TempRoot -HostRoot $HostRoot -RelativePath $file -BaselineCommit $BaselineCommit -Update:$Update
    }

    # copilot-instructions.md sta qui e non in Copy-InstructionsAndPrompts perche' e' contenuto
    # del solo core: questa funzione e' invocata sotto IsCore, quella e' per-pacchetto e
    # duplicherebbe il file a ogni pacchetto di dominio installato. Senza questa copia il
    # riferimento @.github/copilot-instructions.md iniettato in CLAUDE.md punta al nulla.
    Copy-ProtectedFile -TempRoot $TempRoot -HostRoot $HostRoot -RelativePath ".github/copilot-instructions.md" -BaselineCommit $BaselineCommit -Update:$Update

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

function Write-DrUtf8File {
    # UTF-8 senza BOM con qualsiasi versione di PowerShell: Set-Content -Encoding UTF8 scrive il
    # BOM su 5.1 e non su 7, e lo stesso file cambierebbe a seconda di chi lancia l'installer.
    param([string]$Path, [string]$Content)
    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    [System.IO.File]::WriteAllText($full, $Content, [System.Text.UTF8Encoding]::new($false))
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
        Write-DrUtf8File -Path $DestClaudeMd -Content ($block + "`n")
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
        # MatchEvaluator invece della stringa: '$_' o '$&' nel CLAUDE.md sorgente non vanno
        # interpretati come riferimenti di sostituzione (incollerebbero l'intero file)
        $newContent = [regex]::Replace($existing, $pattern, { param($m) $block })
        Write-DrUtf8File -Path $DestClaudeMd -Content $newContent
        Write-Host "  [UPD]  Sezione $PackageName aggiornata in CLAUDE.md" -ForegroundColor Green
    } else {
        $newContent = $existing.TrimEnd() + "`n`n" + $block + "`n"
        Write-DrUtf8File -Path $DestClaudeMd -Content $newContent
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
    Write-DrUtf8File -Path $path -Content (($manifest | ConvertTo-Json -Depth 5) + "`n")

    $shortCommit = if ($Commit) { $Commit.Substring(0, [Math]::Min(7, $Commit.Length)) } else { "sconosciuto" }
    Write-Host "  [OK]   Manifest aggiornato: $PackageName ($shortCommit)" -ForegroundColor Green
}

function Resolve-DrDependencyTree {
    <#
    .SYNOPSIS
        Restituisce, in ordine di installazione, le dipendenze mancanti di un pacchetto.
    .DESCRIPTION
        Visita in profondita' l'intero grafo delle dipendenze a partire da PackageName.
        Ogni voce restituita ha Name e RequiredBy (il primo pacchetto che la richiede);
        l'ordine e' topologico: una dipendenza precede sempre chi la richiede.
        Il pacchetto di partenza non compare nell'elenco, le dipendenze gia' nel manifest nemmeno.

        Un ciclo nel catalogo (A -> B -> A) e' un errore di chi lo scrive: si ferma qui,
        prima di qualsiasi clonazione, invece di mandare la ricorsione in loop.
    #>
    param(
        [Parameter(Mandatory)][string]$PackageName,
        [Parameter(Mandatory)][hashtable]$Registry,
        $Manifest
    )

    $order   = [System.Collections.Generic.List[object]]::new()
    $visited = [System.Collections.Generic.HashSet[string]]::new()
    $stack   = [System.Collections.Generic.List[string]]::new()

    function Invoke-DrDependencyVisit([string]$Name, [string]$Parent) {
        if ($stack.Contains($Name)) {
            $start = $stack.IndexOf($Name)
            $cycle = @($stack.GetRange($start, $stack.Count - $start)) + $Name
            throw "Ciclo nelle dipendenze del catalogo: $($cycle -join ' -> '). Correggi scaffolding-catalog.json."
        }
        if ($visited.Contains($Name)) { return }
        if (-not $Registry.ContainsKey($Name)) {
            throw "Dipendenza sconosciuta: '$Parent' -> '$Name' non e' nel catalogo."
        }

        $stack.Add($Name)
        foreach ($dep in $Registry[$Name].Dependencies) { Invoke-DrDependencyVisit $dep $Name }
        $stack.RemoveAt($stack.Count - 1)
        $null = $visited.Add($Name)

        if ($Parent -and -not (Test-DrPackageInstalled -Manifest $Manifest -PackageName $Name)) {
            $order.Add([PSCustomObject]@{ Name = $Name; RequiredBy = $Parent })
        }
    }

    Invoke-DrDependencyVisit $PackageName ""
    return $order.ToArray()
}

function Install-DrPackage {
    <#
    .SYNOPSIS
        Installa un pacchetto dr-* nel progetto corrente, con le dipendenze mancanti.
    .DESCRIPTION
        Prima di clonare qualsiasi cosa calcola l'albero delle dipendenze mancanti e lo
        annuncia in un blocco unico, una riga '[dep]' per dipendenza, nell'ordine in cui
        verranno installate. Nessuna conferma interattiva: bloccherebbe agenti ed esecuzioni
        'irm | iex'. La conferma, quando serve, sta a monte nelle skill.
        Il core (voce del catalogo con isCore) e' una dipendenza implicita di ogni altro
        pacchetto: se manca dal manifest e' il primo '[dep]' dell'albero.
        A fine installazione, per ogni voce 'suggests' del pacchetto assente dal manifest,
        stampa una riga '[sugg]' col motivo: il suggerito non si installa e non si chiede nulla.
    .PARAMETER Update
        Sovrascrive i file gia' presenti. Non si propaga alle dipendenze: riguarda solo
        il pacchetto richiesto esplicitamente.
    .PARAMETER NoDependencies
        Non installa le dipendenze mancanti: le elenca come '[skip]' con un avviso e
        installa solo il pacchetto richiesto.
    .PARAMETER SourceRoot
        Cartella dell'host, relativa alla radice, dove finiscono i 'sourceFiles' dei
        pacchetti (default: la radice). Vale per il pacchetto e per le sue dipendenze.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        [switch]$Update,
        [switch]$NoDependencies,
        [string]$SourceRoot = "."
    )

    $registry = Get-DrPackageRegistry
    if (-not $registry.ContainsKey($PackageName)) {
        throw "Pacchetto sconosciuto: $PackageName. Pacchetti disponibili: $($registry.Keys -join ', ')"
    }

    $pkg      = $registry[$PackageName]
    $hostRoot = (Get-Location).Path
    # Prima di qualsiasi clone o scrittura: un -SourceRoot non valido lascia l'host intatto
    $null = Resolve-DrSourceRoot -HostRoot $hostRoot -SourceRoot $SourceRoot

    Write-Host ""
    Write-Host "=== $PackageName ===" -ForegroundColor Cyan
    Write-Host "  Repo    : $($pkg.Repo)"
    Write-Host "  Progetto: $hostRoot"

    # Albero calcolato tutto prima di scrivere: un ciclo nel catalogo fallisce qui, a host intatto
    $manifest = Read-DrManifest -HostRoot $hostRoot
    $missing  = @(Resolve-DrDependencyTree -PackageName $PackageName -Registry $registry -Manifest $manifest)

    # Il core e' una dipendenza implicita di ogni pacchetto di dominio: senza, l'host non ha
    # CLAUDE.md, istruzioni trasversali ne' skill di base. Va per primo perche' le altre
    # dipendenze ne presuppongono i file. Implicita e non scritta nel catalogo: vale anche
    # per i pacchetti futuri senza doverla ripetere in ogni voce.
    $coreName = $registry.Keys | Where-Object { $registry[$_].IsCore } | Select-Object -First 1
    if ($coreName -and $PackageName -ne $coreName -and
        -not (Test-DrPackageInstalled -Manifest $manifest -PackageName $coreName) -and
        -not ($missing | Where-Object { $_.Name -eq $coreName })) {
        $missing = @([PSCustomObject]@{ Name = $coreName; RequiredBy = "$PackageName, core implicito" }) + $missing
    }

    if ($missing.Count -gt 0) {
        if ($NoDependencies) {
            Write-Host "  Dipendenze mancanti NON installate (-NoDependencies):" -ForegroundColor Yellow
            $missing | ForEach-Object { Write-Host "  [skip] $($_.Name) (richiesta da $($_.RequiredBy))" -ForegroundColor Yellow }
            Write-Host "  Attenzione: $PackageName rimanda a regole di questi pacchetti; installali a parte se servono." -ForegroundColor Yellow
            $missing = @()
        } else {
            Write-Host "  Dipendenze mancanti, installate prima di $PackageName in questo ordine:" -ForegroundColor White
            $missing | ForEach-Object { Write-Host "  [dep]  $($_.Name) (richiesta da $($_.RequiredBy))" -ForegroundColor Yellow }
            Write-Host "  Per installare solo $PackageName usa -NoDependencies." -ForegroundColor DarkGray
        }
    } elseif ($pkg.Dependencies.Count -gt 0) {
        Write-Host "  Dipendenze: tutte gia' installate" -ForegroundColor DarkGray
    }

    # -Update non si propaga: le dipendenze si installano senza sovrascrivere nulla
    foreach ($dep in $missing) {
        Write-Host ""
        Write-Host "=== $($dep.Name) (dipendenza di $($dep.RequiredBy)) ===" -ForegroundColor Cyan
        Write-Host "  Repo    : $($registry[$dep.Name].Repo)"
        Install-DrPackageContent -PackageName $dep.Name -Package $registry[$dep.Name] -HostRoot $hostRoot -SourceRoot $SourceRoot
    }

    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "=== $PackageName ===" -ForegroundColor Cyan
    }
    Install-DrPackageContent -PackageName $PackageName -Package $pkg -HostRoot $hostRoot -SourceRoot $SourceRoot -Update:$Update

    # Suggeriti: manifest riletto dopo l'installazione, vale anche con -NoDependencies
    $manifest    = Read-DrManifest -HostRoot $hostRoot
    $suggMissing = @($pkg.Suggests | Where-Object { -not (Test-DrPackageInstalled -Manifest $manifest -PackageName $_.package) })
    if ($suggMissing.Count -gt 0) {
        Write-Host "  Pacchetti suggeriti (non installati, nessuna azione automatica):" -ForegroundColor DarkGray
        $suggMissing | ForEach-Object { Write-Host "  [sugg] $($_.package) non installato: $($_.reason)" -ForegroundColor Yellow }
    }
}

function Install-DrPackageContent {
    # Clona un solo pacchetto e ne copia il contenuto nell'host. Nessuna risoluzione delle
    # dipendenze: l'ordine lo decide Install-DrPackage, che e' l'unico punto d'ingresso.
    param(
        [Parameter(Mandatory)][string]$PackageName,
        [Parameter(Mandatory)][hashtable]$Package,
        [Parameter(Mandatory)][string]$HostRoot,
        [string]$SourceRoot = ".",
        [switch]$Update
    )

    $pkg      = $Package
    $hostRoot = $HostRoot
    $manifest = Read-DrManifest -HostRoot $hostRoot

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
        # Commit di riferimento per Copy-ProtectedFile: la versione che l'host ha ricevuto l'ultima
        # volta. Resta vuoto se non e' ricostruibile (manifest senza commit, fetch fallito).
        $baselineCommit = $null

        if ($oldCommit -and $newCommit) {
            if ($oldCommit -eq $newCommit) {
                $baselineCommit = $newCommit
                Write-Host "  Nessuna novita': gia' al commit $($newCommit.Substring(0,7))" -ForegroundColor DarkGray
            } else {
                Write-Host "  Aggiornamento: $($oldCommit.Substring(0,7)) -> $($newCommit.Substring(0,7))" -ForegroundColor White
                # Il clone e' --depth 1: il vecchio commit non e' nella history locale, quindi
                # il diff fallirebbe. Lo si recupera con un fetch mirato per SHA (--depth 1, senza blob:
                # solo l'albero) e poi si confrontano i due alberi. Se il fetch fallisce (commit non piu'
                # raggiungibile, rete assente) si dichiara che l'elenco non e' disponibile.
                git -C $tempDir fetch --quiet --depth 1 --filter=blob:none origin "$oldCommit" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $baselineCommit = $oldCommit
                    $changed = @(git -C $tempDir diff --name-only --no-renames "$oldCommit" HEAD 2>$null)
                    if ($LASTEXITCODE -eq 0 -and $changed.Count -gt 0) {
                        Write-Host "  File modificati a monte:" -ForegroundColor White
                        $changed | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
                    } elseif ($LASTEXITCODE -eq 0) {
                        Write-Host "  File modificati a monte: nessun file modificato" -ForegroundColor DarkGray
                    } else {
                        Write-Host "  File modificati a monte: elenco non disponibile (diff fallito)" -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "  File modificati a monte: elenco non disponibile (commit precedente non raggiungibile)" -ForegroundColor DarkGray
                }
            }
        }

        Copy-InstructionsAndPrompts -TempRoot $tempDir -HostRoot $hostRoot -CoreOnly $pkg.CoreOnlyArtifacts -Update:$Update
        Copy-Skills -TempRoot $tempDir -HostRoot $hostRoot -Update:$Update

        if ($Update -and $pkg.ObsoleteArtifacts) {
            Remove-ObsoleteArtifacts -HostRoot $hostRoot -Artifacts $pkg.ObsoleteArtifacts
        }

        $newFiles = @()
        if ($pkg.RootFiles) {
            $newFiles += @(Copy-PackageRootFiles -TempRoot $tempDir -HostRoot $hostRoot -RootFiles $pkg.RootFiles -BaselineCommit $baselineCommit -Update:$Update)
        }

        if ($pkg.SourceFiles) {
            Copy-PackageSourceFiles -TempRoot $tempDir -HostRoot $hostRoot -SourceRoot $SourceRoot -SourceFiles $pkg.SourceFiles -Update:$Update
        }

        if ($pkg.IsCore) {
            $newFiles += @(Copy-CoreConfigFiles -TempRoot $tempDir -HostRoot $hostRoot -BaselineCommit $baselineCommit -Update:$Update)
            Merge-ClaudeSettings -TempRoot $tempDir -HostRoot $hostRoot
            Copy-ScaffoldingCatalog -TempRoot $tempDir -HostRoot $hostRoot -Update:$Update
            New-BriefsFolder -HostRoot $hostRoot
            Write-Host "  CLAUDE.md:" -ForegroundColor White
            Merge-ClaudeMdSection -SrcClaudeMd (Join-Path $tempDir "CLAUDE.md") -DestClaudeMd (Join-Path $hostRoot "CLAUDE.md") -PackageName $PackageName -Update:$Update
        }

        $newFiles = @($newFiles | Where-Object { $_ })
        if ($newFiles.Count -gt 0) {
            Write-Host "  File personalizzati nell'host: la versione nuova e' accanto, da confrontare a mano e poi eliminare:" -ForegroundColor Yellow
            $newFiles | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
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
    $legacyTitle  = "## Linee guida globali (Davraf)"

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
            Write-DrUtf8File -Path $ClaudeMdPath -Content ($block + "`n")
            Write-Host "  [OK]   CLAUDE.md globale creato con la sezione linee guida" -ForegroundColor Green
        } else {
            $existing = Get-Content $ClaudeMdPath -Raw -Encoding UTF8
            $pattern  = "(?s)" + [regex]::Escape($sectionTitle) + ".*?" + [regex]::Escape($endMarker)

            if ($existing -match $pattern) {
                if ($Update) {
                    # MatchEvaluator invece della stringa: nel blocco un eventuale '$' non va interpretato come riferimento
                    $newContent = [regex]::Replace($existing, $pattern, { param($m) $block })
                    Write-DrUtf8File -Path $ClaudeMdPath -Content $newContent
                    Write-Host "  [UPD]  Sezione globale aggiornata" -ForegroundColor Green
                } else {
                    Write-Host "  [SKIP] Sezione globale gia presente (usa -Global -Update per aggiornarla)" -ForegroundColor DarkGray
                }
            } elseif ($existing -match [regex]::Escape($sectionTitle)) {
                Write-Host "  [WARN] Intestazione presente ma sentinel '$endMarker' mancante - verifica manualmente" -ForegroundColor Yellow
            } elseif ($existing -match ("(?m)^" + [regex]::Escape($legacyTitle))) {
                # Blocco scritto dal vecchio davraf-guidelines/setup.ps1: senza sentinel non se ne
                # conosce la fine, quindi non si sostituisce. Accodare creerebbe due copie delle regole.
                Write-Host "  [WARN] Trovato il blocco legacy '$legacyTitle' (vecchio setup.ps1): nulla e' stato scritto." -ForegroundColor Yellow
                Write-Host "         Rimuovi a mano quel blocco da $ClaudeMdPath, poi rilancia con -Global." -ForegroundColor Yellow
            } else {
                $newContent = $existing.TrimEnd() + "`n`n" + $block + "`n"
                Write-DrUtf8File -Path $ClaudeMdPath -Content $newContent
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
