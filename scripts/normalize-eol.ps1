<#
.SYNOPSIS
    Normalizza in place il fine riga dei file di testo secondo .gitattributes.
.DESCRIPTION
    Per ogni file legge `git check-attr text eol` e riscrive il contenuto col fine riga voluto:
      - eol=lf / eol=crlf               -> quello
      - eol non specificato             -> LF, salvo .ps1 .cmd .bat .sln (CRLF)
      - text unset o attributo binary   -> file saltato
      - byte NUL nei primi 8 KB         -> file saltato (binario o UTF-16)
    Fuori da un repository git valgono le sole regole di default.

    Lavora sui byte (CR e LF non compaiono mai dentro una sequenza UTF-8 multibyte): il BOM e
    ogni altro byte restano identici, cambia solo il fine riga. Vale anche per i file con
    modifiche in corso: non usa `git checkout` e non tocca l'index.

    Senza -Path prende i file modificati, aggiunti e non tracciati (`git status --porcelain`) e i
    file tracciati che `git ls-files --eol` segnala fuori norma nel working tree (es. committati
    con autocrlf=true prima di .gitattributes: per git non sono modificati).

    Esempi:
        pwsh scripts/normalize-eol.ps1                       # file modificati e nuovi del repo
        pwsh scripts/normalize-eol.ps1 -Path src/Api         # cartella, ricorsiva
        pwsh scripts/normalize-eol.ps1 -Path a.md,b.json     # piu' percorsi (nomi con virgola: non supportati)
        pwsh scripts/normalize-eol.ps1 -Check                # solo verifica, exit 1 se c'e' da correggere
.PARAMETER Path
    File o cartelle da normalizzare (cartelle in modo ricorsivo, escluse .git, bin, obj, node_modules).
.PARAMETER ListFile
    File UTF-8 con un percorso per riga, in aggiunta a -Path. Nessun limite di virgole o lunghezza.
.PARAMETER Check
    Non scrive nulla: elenca i file da correggere ed esce con 1 se ce ne sono, 0 altrimenti.
.PARAMETER Quiet
    Nessun output per i file corretti; restano avvisi ed errori.
.NOTES
    Compatibile con Windows PowerShell 5.1 e PowerShell 7.
    Distribuito dal pacchetto core dr-guidelines (issue davraf-amuro/dr-guidelines#34).
#>
[CmdletBinding()]
param(
    # Con `pwsh -File` un array "a,b" arriva come stringa unica: si divide sulle virgole (sotto).
    # ValueFromRemainingArguments: anche `script.ps1 a b` senza -Path raccoglie tutti i percorsi
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Path,
    # File di testo UTF-8 con un percorso per riga: per chi passa molti percorsi o percorsi con
    # la virgola (es. l'installer del core), senza limiti di lunghezza della riga di comando
    [string]$ListFile,
    [switch]$Check,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$Path = @($Path | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($ListFile) {
    $Path += @([System.IO.File]::ReadAllLines($ListFile, [System.Text.Encoding]::UTF8) | Where-Object { $_.Trim() })
}
$crlfExtensions   = @('.ps1', '.cmd', '.bat', '.sln')
$skipDirs         = @('.git', 'bin', 'obj', 'node_modules')
# Percorsi per ogni chiamata a `git check-attr`: tiene la riga di comando lontana dal limite di Windows
$attrChunkSize    = 100
# Byte letti per riconoscere un binario (stessa soglia euristica di git)
$binaryProbeBytes = 8000
# Fuori norma per il Gate di Push: working tree con un fine riga diverso da quello di .gitattributes
$eolMismatch      = 'w/(crlf|mixed)\s+attr/[^\t]*eol=lf|w/(lf|mixed)\s+attr/[^\t]*eol=crlf'
# ISO-8859-1 mappa ogni byte su un carattere e ritorno: la conversione testo <-> byte e' esatta
$latin1 = [System.Text.Encoding]::GetEncoding(28591)

# Output di git in UTF-8: i nomi di file con lettere accentate non si devono sporcare
$previousEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

try {
    # Esegue git e restituisce lo stdout come testo. ErrorActionPreference locale a Continue:
    # su Windows PowerShell 5.1 lo stderr di un comando nativo con 'Stop' diventa un errore
    # che ferma lo script (es. rev-parse fuori da un repository)
    function Invoke-GitText([string[]]$GitArgs) {
        $ErrorActionPreference = 'Continue'
        return (& git @GitArgs 2>$null | Out-String)
    }

    $repoRoot = $null
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $top = (Invoke-GitText @('rev-parse', '--show-toplevel')).Trim()
        if ($LASTEXITCODE -eq 0 -and $top) { $repoRoot = [System.IO.Path]::GetFullPath($top) }
    }
    $sep = [System.IO.Path]::DirectorySeparatorChar

    # Percorso relativo alla radice del repository con '/', o $null se il file sta fuori
    function Get-RepoRelativePath([string]$FullPath) {
        if (-not $repoRoot) { return $null }
        $prefix = $repoRoot.TrimEnd($sep, '/') + $sep
        if ($FullPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $FullPath.Substring($prefix.Length).Replace($sep, '/')
        }
        return $null
    }

    # --- Elenco dei file ---
    $files = [System.Collections.Generic.List[string]]::new()
    # -ListFile vuoto resta "elenco esplicito": non deve allargarsi a tutto il repository
    if ($Path -or $ListFile) {
        foreach ($p in $Path) {
            $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($p)
            if (Test-Path -LiteralPath $full -PathType Leaf) {
                $files.Add($full)
            } elseif (Test-Path -LiteralPath $full -PathType Container) {
                $stack = [System.Collections.Generic.Stack[string]]::new()
                $stack.Push($full)
                while ($stack.Count -gt 0) {
                    $dir = $stack.Pop()
                    foreach ($f in [System.IO.Directory]::GetFiles($dir)) { $files.Add($f) }
                    foreach ($d in [System.IO.Directory]::GetDirectories($dir)) {
                        if ($skipDirs -notcontains [System.IO.Path]::GetFileName($d)) { $stack.Push($d) }
                    }
                }
            } else {
                Write-Warning "Percorso non trovato: $p"
            }
        }
    } else {
        if (-not $repoRoot) { throw "Senza -Path serve un repository git: indica i file da normalizzare." }
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

        # 1. File modificati, aggiunti e non tracciati.
        # -z: un record per voce, nessun quoting; nelle rinomine segue un secondo campo col nome vecchio
        $records = (Invoke-GitText @('-C', $repoRoot, 'status', '--porcelain', '-z', '--untracked-files=all')).Split([char]0)
        for ($i = 0; $i -lt $records.Count; $i++) {
            $rec = $records[$i]
            if ($rec.Length -lt 4) { continue }
            $xy  = $rec.Substring(0, 2)
            $rel = $rec.Substring(3)
            if ($xy -match 'R|C') { $i++ }
            if ($xy -match 'D') { continue }
            if ($seen.Add($rel)) { $files.Add([System.IO.Path]::Combine($repoRoot, $rel.Replace('/', $sep))) }
        }

        # 2. File tracciati e non modificati per git, ma col fine riga fuori norma nel working tree:
        # es. committati con autocrlf=true prima che arrivasse .gitattributes. git status non li vede.
        foreach ($rec in (Invoke-GitText @('-C', $repoRoot, 'ls-files', '--eol', '-z')).Split([char]0)) {
            $tab = $rec.IndexOf("`t")
            if ($tab -lt 0) { continue }
            $rel = $rec.Substring($tab + 1)
            if ($rec.Substring(0, $tab) -match $eolMismatch -and $seen.Add($rel)) {
                $files.Add([System.IO.Path]::Combine($repoRoot, $rel.Replace('/', $sep)))
            }
        }
    }

    # --- Attributi git, in blocchi per non superare la lunghezza della riga di comando ---
    $attrs = @{}
    $relPaths = @($files | ForEach-Object { Get-RepoRelativePath $_ } | Where-Object { $_ })
    for ($start = 0; $start -lt $relPaths.Count; $start += $attrChunkSize) {
        $chunk = $relPaths[$start..([Math]::Min($start + $attrChunkSize - 1, $relPaths.Count - 1))]
        $out   = Invoke-GitText (@('-C', $repoRoot, 'check-attr', '-z', 'text', 'eol', '--') + $chunk)
        $parts = $out.Split([char]0)
        for ($j = 0; $j + 2 -lt $parts.Count; $j += 3) {
            $key = $parts[$j]
            if (-not $attrs.ContainsKey($key)) { $attrs[$key] = @{} }
            $attrs[$key][$parts[$j + 1]] = $parts[$j + 2]
        }
    }

    # --- Normalizzazione ---
    $pending = 0
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
        $rel  = Get-RepoRelativePath $file
        $show = if ($rel) { $rel } else { $file }

        $eol = 'unspecified'
        if ($rel -and $attrs.ContainsKey($rel)) {
            $a = $attrs[$rel]
            if ($a['text'] -eq 'unset') { continue }
            if ($a['eol'] -in @('lf', 'crlf')) { $eol = $a['eol'] }
        }
        if ($eol -eq 'unspecified') {
            $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
            $eol = if ($crlfExtensions -contains $ext) { 'crlf' } else { 'lf' }
        }

        $bytes = [System.IO.File]::ReadAllBytes($file)
        if ($bytes.Length -eq 0) { continue }
        $probe = [Math]::Min($bytes.Length, $binaryProbeBytes)
        if ([Array]::IndexOf($bytes, [byte]0, 0, $probe) -ge 0) { continue }

        $text   = $latin1.GetString($bytes)
        $target = if ($eol -eq 'crlf') { "`r`n" } else { "`n" }
        $fixed  = [regex]::Replace($text, "`r`n|`r|`n", $target)
        if ($fixed -ceq $text) { continue }

        $pending++
        if ($Check) {
            Write-Host "  [EOL]  $show -> $eol (da correggere)" -ForegroundColor Yellow
        } else {
            [System.IO.File]::WriteAllBytes($file, $latin1.GetBytes($fixed))
            if (-not $Quiet) { Write-Host "  [EOL]  $show -> $eol" -ForegroundColor Green }
        }
    }

    if ($Check -and $pending -gt 0) {
        Write-Host "  $pending file con fine riga da correggere: rilancia senza -Check." -ForegroundColor Yellow
        exit 1
    }
    if (-not $Quiet -and $pending -eq 0) {
        Write-Host "  Fine riga: nessun file da correggere" -ForegroundColor DarkGray
    }
    exit 0
}
finally {
    [Console]::OutputEncoding = $previousEncoding
}
