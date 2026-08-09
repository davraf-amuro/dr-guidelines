# Test end-to-end: progetto host `test-uno` + pacchetti `dr-*`

Procedura passo passo per creare un progetto host di prova (`test-uno`) dentro il workspace multi-repo e installarci sopra `dr-guidelines` (core) più un pacchetto dominio, verificando che l'installer, il manifest e le skill funzionino.

---

## 🎯 Obiettivo

| Cosa si verifica | Come |
|---|---|
| `install.ps1` core copia i file attesi | Ispezione albero `test-uno/` dopo l'esecuzione |
| Merge sezione `<!-- dr-guidelines -->` in `CLAUDE.md` | Confronto contenuto prima/dopo |
| Risoluzione automatica dipendenze | `dr-minimalapi` → deve tirarsi dietro `dr-dotnet-backend` |
| Idempotenza (`[SKIP]`) e `-Update` (`[UPD]`) | Doppia esecuzione dell'installer |
| Manifest `.ai/dr-guidelines-packages.json` | Contenuto JSON dopo ogni installazione |
| Skill `dr-*` caricate da Claude Code | Invocazione di `/dr-snapshot` nel progetto host |

> ⚠️ **Questo test NON chiude il gate 2b del piano di split.** Il gate (`.ai/plans/2026-07-22-dr-guidelines-split/plan.md`, fase 2b) richiede esplicitamente un **progetto host reale esistente**, non una cartella di test sintetica. `test-uno` serve a validare il meccanismo, non a sbloccare il flip Private → Public dei 7 repo.

---

## ✅ Prerequisiti

| Requisito | Verifica |
|---|---|
| PowerShell 7+ (`pwsh`) | `$PSVersionTable.PSVersion` |
| Git installato e autenticato sui repo **Private** `davraf-amuro/dr-*` | `git ls-remote https://github.com/davraf-amuro/dr-guidelines.git` deve rispondere senza chiedere credenziali |
| Workspace clonato in `E:\Davide\Progetti\dr-guidelines-workspace\` con tutti e 7 i repo | `Get-ChildItem E:\Davide\Progetti\dr-guidelines-workspace -Directory` |
| Claude Code / VS Code per la parte skill (passi 6-8) | — |

**Perché conta l'autenticazione git:** i 7 repo `dr-*` sono attualmente **Private**. `Install-DrPackage` fa `git clone --depth 1 https://github.com/davraf-amuro/<pacchetto>.git` in una temp dir: senza credential manager attivo il clone fallisce con `git clone fallito per ... (repo Private? verifica autenticazione git/gh)`.

**Conseguenza sul bootstrap:** il percorso pubblico `irm .../install.ps1 | iex` **non funziona** finché i repo restano Private (raw.githubusercontent risponde 404). Tutto il test usa quindi l'**invocazione da path locale**, che attiva il fallback `$PSScriptRoot` presente in ogni `install.ps1`.

---

## 1️⃣ Creare il progetto host `test-uno`

Da PowerShell:

```powershell
Set-Location E:\Davide\Progetti\dr-guidelines-workspace
New-Item -ItemType Directory -Path .\test-uno | Out-Null
Set-Location .\test-uno
git init
```

Serve almeno un commit iniziale, così il rollback con `git checkout -- .` ha un riferimento:

```powershell
"# test-uno`n`nProgetto host di prova per i pacchetti dr-*." | Set-Content README.md -Encoding UTF8
git add README.md
git commit -m "chore: init progetto host di prova"
```

> `test-uno` deve essere un **repo git proprio**. La cartella padre `dr-guidelines-workspace\` non è un repo git (per progetto), quindi non eredita nulla.

---

## 2️⃣ Aggiungere `test-uno` al workspace VS Code

Apri `E:\Davide\Progetti\dr-guidelines-workspace\dr-guidelines.code-workspace` e aggiungi la voce in coda all'array `folders`:

```json
{
	"folders": [
		{ "path": "dr-guidelines" },
		{ "path": "dr-minimalapi" },
		{ "path": "dr-winsvc" },
		{ "path": "dr-efdb" },
		{ "path": "dr-fe" },
		{ "path": "dr-devops" },
		{ "path": "dr-dotnet-backend" },
		{ "path": "test-uno" },
		{ "path": "../davraf-guidelines" }
	]
}
```

Poi ricarica la finestra (`Developer: Reload Window`) oppure riapri il workspace:

```powershell
code E:\Davide\Progetti\dr-guidelines-workspace\dr-guidelines.code-workspace
```

---

## 3️⃣ Installare il pacchetto core `dr-guidelines`

⚠️ `Install-DrPackage` usa `(Get-Location).Path` come root del progetto host: **devi trovarti dentro `test-uno`** quando lanci lo script, altrimenti i file finiscono nella cartella sbagliata.

```powershell
Set-Location E:\Davide\Progetti\dr-guidelines-workspace\test-uno
& ..\dr-guidelines\install.ps1
```

**Cosa succede internamente:**

1. `install.ps1` tenta `irm .../dr-guidelines/main/install-lib.ps1` → fallisce (repo Private)
2. Il `catch` rileva `$PSScriptRoot` valorizzato → dot-source di `..\dr-guidelines\install-lib.ps1` locale
3. `Install-DrPackage -PackageName "dr-guidelines"` clona il repo in `%TEMP%\dr-install-<guid>`
4. Copia file, merge `CLAUDE.md`, upsert manifest, elimina la temp dir

**Output atteso** (estratto):

```
=== dr-guidelines ===
  Repo    : davraf-amuro/dr-guidelines
  Progetto: E:\Davide\Progetti\dr-guidelines-workspace\test-uno
  Clonazione davraf-amuro/dr-guidelines...
  .github/instructions/:
  [OK]   code-organization.instructions.md
  ...
  .claude/skills/:
  [OK]   dr-warroom/
  ...
  File di configurazione:
  [OK]   .editorconfig
  ...
  [OK]   .mcp.json
  CLAUDE.md:
  [OK]   CLAUDE.md creato con sezione dr-guidelines
  [OK]   Manifest aggiornato: dr-guidelines
  Completato: dr-guidelines
```

---

## 4️⃣ Verificare l'installazione del core

```powershell
Get-ChildItem -Force | Select-Object Name
Get-ChildItem .github\instructions | Select-Object Name
Get-ChildItem .claude\skills -Directory | Select-Object Name
Get-Content .ai\dr-guidelines-packages.json
```

**Atteso in `test-uno/`:**

| Elemento | Note |
|---|---|
| `.editorconfig`, `Directory.Build.props`, `global.json`, `.gitignore`, `.gitattributes` | Copiati dal core |
| `.mcp.json` | Generato da `.mcp.example.json`, **solo perché assente** |
| `.github/instructions/` | 10 file `*.instructions.md` |
| `.claude/skills/` | 10 cartelle skill `dr-*` |
| `CLAUDE.md` | Contiene `<!-- dr-guidelines -->` … `<!-- /dr-guidelines -->` |
| `.ai/dr-guidelines-packages.json` | `{"installed":[{"package":"dr-guidelines","installedAt":"<oggi>"}]}` |

**Nota `.github/prompts/`:** il core **ne ha** — `card-project-generator`, `card-wiki-generator`, `onboarding-senior`, `readme-generator` e `dr-scaffold`. I pacchetti dominio aggiungono i propri (es. `card-minimal-api`, `endpoints-analyzer` con `dr-minimalapi`).

**Nota `.ai/dr-scaffolding-catalog.json`:** il core distribuisce anche il catalogo delle tipologie di progetto e dei pacchetti, letto dalle skill `dr-scaffold*` nel progetto host.

**Nota `Directory.Build.props` e `global.json`:** vengono copiati **solo** se l'host è .NET (esiste almeno un `*.csproj`/`*.sln`/`*.slnx` entro 3 livelli). In un repo frontend l'installer stampa `[SKIP] Directory.Build.props, global.json (host non .NET)`: è il comportamento atteso.

**Controllo git — cosa risulta ignorato:** il `.gitignore` appena copiato esclude `.mcp.json` e `.claude/settings.local.json`. Verifica che `.mcp.json` **non** compaia tra i file da committare:

```powershell
git status --short
```

---

## 5️⃣ Installare un pacchetto dominio (test dipendenze)

`dr-minimalapi` dichiara dipendenza da `dr-dotnet-backend`: se manca dal manifest, l'installer la installa **prima**, automaticamente.

```powershell
& ..\dr-minimalapi\install.ps1
```

**Output atteso** — la riga chiave è:

```
  Dipendenza mancante: dr-dotnet-backend -> installazione automatica
```

**Verifica manifest dopo:**

```powershell
Get-Content .ai\dr-guidelines-packages.json
```

Deve elencare **tre** pacchetti: `dr-guidelines`, `dr-dotnet-backend`, `dr-minimalapi`.

**Verifica contenuto aggiunto:**

```powershell
Get-ChildItem .github\prompts | Select-Object Name          # card-minimal-api, endpoints-analyzer
Get-ChildItem .claude\skills -Directory | Select-Object Name # ora include dr-audit-api
```

> I pacchetti dominio **non** toccano `CLAUDE.md` né i file di configurazione radice: la sezione marcata e i config sono esclusiva del core (`IsCore = $true`).

---

## 6️⃣ Verificare idempotenza e `-Update`

**Seconda esecuzione senza flag** — nessun file deve essere sovrascritto:

```powershell
& ..\dr-guidelines\install.ps1
```

Atteso: tutte righe `[SKIP]`, più `[SKIP] Sezione dr-guidelines gia presente in CLAUDE.md (usa -Update per aggiornare)`.

**Test `-Update`** — modifica volutamente un file copiato, poi ripristina via installer:

```powershell
Add-Content .github\instructions\logging.instructions.md "`n<!-- modifica locale di test -->"
& ..\dr-guidelines\install.ps1 -Update
Select-String -Path .github\instructions\logging.instructions.md -Pattern "modifica locale di test"
```

Atteso: righe `[UPD]`, `[UPD]  Sezione dr-guidelines aggiornata in CLAUDE.md`, e l'ultimo comando **nessun risultato** (la modifica è stata sovrascritta).

**Test preservazione contenuto host in `CLAUDE.md`** — il merge non deve toccare nulla fuori dai marker:

```powershell
Add-Content CLAUDE.md "`n## Sezione mia del progetto`n`nQuesta riga deve sopravvivere all'update."
& ..\dr-guidelines\install.ps1 -Update
Select-String -Path CLAUDE.md -Pattern "deve sopravvivere"
```

Atteso: la riga **c'è ancora**.

---

## 7️⃣ Verificare le skill in Claude Code

1. Assicurati che `test-uno` sia nel workspace (passo 2) e **riavvia Claude Code** — le skill in `.claude/skills/` vengono lette all'avvio della sessione.
2. Con `test-uno` come cartella di lavoro, invoca:

```
/dr-snapshot
```

Atteso: genera `.ai/context/snapshot.md` con il riassunto del progetto host.

3. Prova la guard di `/dr-get-latest` **dal repo sorgente** (non dall'host): posizionati su `dr-guidelines` e invoca `/dr-get-latest`. Deve rispondere:

> "Sei in un repo sorgente dr-*: qui non esiste un manifest pacchetti da aggiornare. Usa `git pull` per allinearti al remoto."

---

## 8️⃣ Testare `/dr-get-latest` sul progetto host

Da `test-uno`:

```
/dr-get-latest
```

**Limite noto — fallirà finché i repo sono Private.** La skill esegue, per ogni pacchetto del manifest:

```powershell
& ([scriptblock]::Create((Invoke-RestMethod -Uri "https://raw.githubusercontent.com/davraf-amuro/<package>/main/install.ps1"))) -Update
```

Con repo Private, `Invoke-RestMethod` restituisce 404 e — poiché lo script arriva da `iex`, quindi `$PSScriptRoot` è vuoto — il fallback locale non si attiva. Comportamento atteso e corretto: la skill segnala il fallimento per pacchetto e prosegue con i successivi.

**Equivalente manuale funzionante durante la fase Private:**

```powershell
Set-Location E:\Davide\Progetti\dr-guidelines-workspace\test-uno
& ..\dr-guidelines\install.ps1     -Update
& ..\dr-dotnet-backend\install.ps1 -Update
& ..\dr-minimalapi\install.ps1     -Update
```

---

## 📋 Checklist di verifica finale

| # | Criterio | Esito |
|---|----------|-------|
| 1 | `test-uno` è un repo git con commit iniziale | ☐ |
| 2 | `test-uno` compare nel `.code-workspace` | ☐ |
| 3 | Config radice presenti (`.editorconfig`, `Directory.Build.props`, `global.json`, `.gitignore`, `.gitattributes`) | ☐ |
| 4 | `.mcp.json` generato e ignorato da git | ☐ |
| 5 | 10 file in `.github/instructions/` | ☐ |
| 6 | `CLAUDE.md` con sezione `<!-- dr-guidelines -->` | ☐ |
| 7 | Manifest con 3 pacchetti dopo il passo 5 | ☐ |
| 8 | Dipendenza `dr-dotnet-backend` installata automaticamente | ☐ |
| 9 | Seconda esecuzione senza flag → solo `[SKIP]` | ☐ |
| 10 | `-Update` sovrascrive i file e ri-mergia la sezione | ☐ |
| 11 | Contenuto host di `CLAUDE.md` fuori marker preservato | ☐ |
| 12 | Nessun `.gitmodules`, nessuna cartella `davraf-guidelines/` in `test-uno` | ☐ |
| 13 | `/dr-snapshot` eseguita con successo dall'host | ☐ |
| 14 | `/dr-get-latest` dal repo sorgente → guard attiva | ☐ |

Verifica rapida del criterio 12:

```powershell
Test-Path .gitmodules            # atteso: False
Test-Path .\davraf-guidelines    # atteso: False
```

---

## ♻️ Rollback e pulizia

**Annullare le modifiche mantenendo il progetto:**

```powershell
Set-Location E:\Davide\Progetti\dr-guidelines-workspace\test-uno
git clean -fd          # rimuove i file non tracciati aggiunti dall'installer
git checkout -- .      # ripristina i file tracciati modificati
```

**Eliminare del tutto il progetto di prova:**

```powershell
Set-Location E:\Davide\Progetti\dr-guidelines-workspace
Remove-Item .\test-uno -Recurse -Force
```

Poi rimuovi la voce `{ "path": "test-uno" }` dal `.code-workspace`.

> ⚠️ `Remove-Item -Recurse -Force` è irreversibile e cancella anche il repo git locale di `test-uno`. Nessun remote è coinvolto: `test-uno` non viene mai pushato.

---

## ⚠️ Limiti noti in fase Private

| Limite | Workaround |
|--------|-----------|
| `irm .../install.ps1 \| iex` non funziona (repo Private) | Invocazione da path locale: `& ..\<pacchetto>\install.ps1` |
| `/dr-get-latest` fallisce su tutti i pacchetti | Sequenza manuale `install.ps1 -Update` (passo 8) |
| Questo test non chiude il gate 2b dello split | Serve un progetto host **reale**, non sintetico |
| `git clone` dei pacchetti richiede credenziali valide | Credential manager git o `gh auth login` |

---

## 🔗 Riferimenti

| Documento | Contenuto |
|-----------|-----------|
| [`README.md`](../README.md) | Panoramica pacchetti `dr-*`, installazione e aggiornamento |
| [`.ai/plans/2026-07-22-dr-guidelines-split/plan.md`](../.ai/plans/2026-07-22-dr-guidelines-split/plan.md) | Piano di split, gate 2b, design dell'installer |
| [`install-lib.ps1`](../install-lib.ps1) | Registry pacchetti e orchestratore `Install-DrPackage` |
| [`docs/onboarding.md`](onboarding.md) | Onboarding developer senior |

---

*Revisione v1.1 — 2026-08-08 14:35 — claude-opus-5*
