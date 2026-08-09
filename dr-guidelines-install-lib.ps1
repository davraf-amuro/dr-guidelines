<#
.SYNOPSIS
    Libreria condivisa per l'installazione dei pacchetti dr-* (dr-guidelines e domini).
.DESCRIPTION
    Non eseguire direttamente. Viene fetchata a runtime da ciascun <pacchetto>-install.ps1
    (thin wrapper) e dot-sourced/eval'd per esporre Install-DrPackage, Install-DrGlobal
    e il registro pacchetti.

    Vive solo in dr-guidelines: anche gli installer dei pacchetti dominio la prendono da qui.
#>

$Script:PackageRegistry = @{
    "dr-guidelines"     = @{ Repo = "davraf-amuro/dr-guidelines";     IsCore = $true;  Dependencies = @() }
    "dr-minimalapi"     = @{ Repo = "davraf-amuro/dr-minimalapi";     IsCore = $false; Dependencies = @("dr-dotnet-backend") }
    "dr-winsvc"         = @{ Repo = "davraf-amuro/dr-winsvc";         IsCore = $false; Dependencies = @("dr-dotnet-backend") }
    "dr-efdb"           = @{ Repo = "davraf-amuro/dr-efdb";           IsCore = $false; Dependencies = @() }
    "dr-fe"             = @{ Repo = "davraf-amuro/dr-fe";             IsCore = $false; Dependencies = @() }
    "dr-devops"         = @{ Repo = "davraf-amuro/dr-devops";         IsCore = $false; Dependencies = @() }
    "dr-dotnet-backend" = @{ Repo = "davraf-amuro/dr-dotnet-backend"; IsCore = $false; Dependencies = @() }
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

function Test-DotnetHost {
    param([string]$HostRoot)

    # Profondita' 3: copre root, src\<progetto>\x.csproj e test\<progetto>\x.csproj senza scendere in node_modules
    foreach ($pattern in @("*.csproj", "*.fsproj", "*.vbproj", "*.sln", "*.slnx")) {
        $found = Get-ChildItem -Path $HostRoot -Filter $pattern -Recurse -Depth 3 -File -ErrorAction SilentlyContinue |
                 Select-Object -First 1
        if ($found) { return $true }
    }
    return $false
}

function Copy-CoreConfigFiles {
    param([string]$TempRoot, [string]$HostRoot, [switch]$Update)

    Write-Host "  File di configurazione:" -ForegroundColor White
    foreach ($file in @(".editorconfig", ".gitignore", ".gitattributes")) {
        Copy-GuidelineFile -SrcFile (Join-Path $TempRoot $file) -DestFile (Join-Path $HostRoot $file) -Update:$Update
    }

    # Directory.Build.props e global.json sono .NET-only: in un repo frontend resterebbero file inerti
    if (Test-DotnetHost -HostRoot $HostRoot) {
        foreach ($file in @("Directory.Build.props", "global.json")) {
            Copy-GuidelineFile -SrcFile (Join-Path $TempRoot $file) -DestFile (Join-Path $HostRoot $file) -Update:$Update
        }
    } else {
        Write-Host "  [SKIP] Directory.Build.props, global.json (host non .NET)" -ForegroundColor DarkGray
        Write-Host "         Se aggiungi progetti .NET, rilancia l'installer con -Update per ottenerli." -ForegroundColor DarkGray
    }

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

function Update-DrManifest {
    param([string]$HostRoot, [string]$PackageName)

    $path = Get-DrManifestPath -HostRoot $HostRoot
    $dir  = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $manifest      = Read-DrManifest -HostRoot $HostRoot
    $installedList = @($manifest.installed)
    $existing      = $installedList | Where-Object { $_.package -eq $PackageName }
    $today         = Get-Date -Format "yyyy-MM-dd"

    if ($existing) {
        $existing.installedAt = $today
    } else {
        $installedList += [PSCustomObject]@{ package = $PackageName; installedAt = $today }
    }

    $manifest.installed = $installedList
    ($manifest | ConvertTo-Json -Depth 5) | Set-Content -Path $path -Encoding UTF8
    Write-Host "  [OK]   Manifest aggiornato: $PackageName" -ForegroundColor Green
}

function Install-DrPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        [switch]$Update
    )

    if (-not $Script:PackageRegistry.ContainsKey($PackageName)) {
        throw "Pacchetto sconosciuto: $PackageName. Pacchetti disponibili: $($Script:PackageRegistry.Keys -join ', ')"
    }

    $pkg      = $Script:PackageRegistry[$PackageName]
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

        Copy-InstructionsAndPrompts -TempRoot $tempDir -HostRoot $hostRoot -Update:$Update
        Copy-Skills -TempRoot $tempDir -HostRoot $hostRoot -Update:$Update

        if ($pkg.IsCore) {
            Copy-CoreConfigFiles -TempRoot $tempDir -HostRoot $hostRoot -Update:$Update
            Copy-ScaffoldingCatalog -TempRoot $tempDir -HostRoot $hostRoot -Update:$Update
            Write-Host "  CLAUDE.md:" -ForegroundColor White
            Merge-ClaudeMdSection -SrcClaudeMd (Join-Path $tempDir "CLAUDE.md") -DestClaudeMd (Join-Path $hostRoot "CLAUDE.md") -PackageName $PackageName -Update:$Update
        }

        Update-DrManifest -HostRoot $hostRoot -PackageName $PackageName
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
            $repo    = $Script:PackageRegistry["dr-guidelines"].Repo
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
