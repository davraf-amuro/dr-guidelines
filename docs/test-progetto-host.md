# Collaudo dell'installer su un progetto host di prova

Procedura per verificare che installer, manifest e skill dei pacchetti `dr-*` funzionino davvero, su una cartella di prova. Copre quello che la [guida alla soluzione nuova](guida-nuova-soluzione.md) non mette alla prova: dipendenze, idempotenza, `-Update`, aggiornamento dopo un push.

> **Da non confondere con la guida utente.** Qui si collauda il meccanismo passo per passo, a mano. Per creare un progetto vero segui [`guida-nuova-soluzione.md`](guida-nuova-soluzione.md).

---

## 🎯 Cosa si verifica

| Cosa | Come |
|---|---|
| L'installer del core copia i file attesi | Ispezione della cartella dopo l'esecuzione |
| Merge della sezione `<!-- dr-guidelines -->` in `CLAUDE.md` | Contenuto prima e dopo |
| Dipendenze automatiche | `dr-minimalapi` deve installare anche `dr-dotnet-backend` |
| Idempotenza (`[SKIP]`) e `-Update` (`[UPD]`) | Doppia esecuzione dell'installer |
| Manifest `.ai/dr-guidelines-packages.json` | Una voce per pacchetto, con commit |
| Si installa il `main` remoto, non il clone locale | Modifica non pushata che non deve arrivare |
| Skill caricate da Claude Code | `/dr-snapshot` e `/dr-get-latest` dal progetto di prova |

> Aggiornamento 2026-09-22: i 7 repo `dr-*` sono **pubblici** dal 2026-09-21 e il gate 2b del piano di split (`.ai/plans/2026-07-22-dr-guidelines-split/plan.md`) è chiuso. Questo collaudo resta una prova del meccanismo su cartella sintetica, non su un progetto host reale.

---

## ✅ Prerequisiti

| Requisito | Verifica |
|---|---|
| PowerShell 7+ | `pwsh --version` |
| git | `git --version` |
| `gh` autenticato con scope `repo` | `gh auth status` |
| git con credenziali per i repo Private | `git ls-remote https://github.com/davraf-amuro/dr-guidelines.git` risponde senza chiedere credenziali. Se non va: `gh auth setup-git` |
| VS Code con Claude Code | Per il passo 8 |
| Clone locale di `dr-guidelines` e `dr-minimalapi` come cartelle sorelle | Solo per il passo 7 e il punto 4 del passo 8 |

**Non serve che i repo siano Public.** L'installer si scarica con `gh api`, che legge i repo Private. La forma `irm https://raw.githubusercontent.com/... | iex` risponde `404` finché restano Private.

**Il workspace `dr-*` clonato serve solo ai passi 7 e 8.4.** Tutti gli altri comandi scaricano da GitHub.

---

## 1️⃣ Creare la cartella di prova

Fuori dal workspace dei repo `dr-*`. Nell'esempio: `E:\Davide\Progetti\dr-guidelines-workspace\dr-test-01`.

```powershell
New-Item -ItemType Directory E:\Davide\Progetti\dr-guidelines-workspace\dr-test-01
Set-Location E:\Davide\Progetti\dr-guidelines-workspace\dr-test-01
```

**Commit iniziale: consigliato per il collaudo, non richiesto dall'installer.** L'installer non chiede nulla a git sul progetto host. Il commit serve a tornare indietro con due comandi tra un test e l'altro:

```powershell
git init
"# dr-test-01" | Set-Content README.md -Encoding UTF8
git add README.md
git commit -m "chore: init progetto host di prova"
```

---

## 2️⃣ Aprire la cartella in una finestra separata

```powershell
code E:\Davide\Progetti\dr-guidelines-workspace\dr-test-01
```

**Non aggiungerla al workspace `dr-guidelines.code-workspace`.** In quel workspace Claude Code vede le skill dei repo sorgente: il test delle skill installate non sarebbe attendibile.

---

## 3️⃣ Installare il core

Dal terminale della finestra di prova:

```powershell
Set-Location E:\Davide\Progetti\dr-guidelines-workspace\dr-test-01
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
```

⚠️ L'installer usa la cartella corrente come root del progetto host. Lanciato da un'altra cartella, scrive lì senza errori.

**Cosa succede dentro:**

1. `dr-guidelines-install.ps1` cerca la libreria `dr-guidelines-install-lib.ps1`: raw pubblico (`404`) → clone locale (assente: lo script arriva da uno stream) → `gh api` (riesce)
2. La libreria carica `scaffolding-catalog.json` con la stessa catena e costruisce l'elenco dei pacchetti
3. `Install-DrPackage` clona il `main` di `dr-guidelines` in `%TEMP%\dr-install-<guid>`
4. Copia i file nella cartella di prova, fonde `.claude/settings.json` e `CLAUDE.md`, aggiorna il manifest
5. Cancella la cartella temporanea

**Nella cartella di prova non arriva nessun repository:** niente `.gitmodules`, niente `.git` di `dr-guidelines`.

**Output atteso** (estratto):

```
=== dr-guidelines ===
  Repo    : davraf-amuro/dr-guidelines
  Progetto: E:\Davide\Progetti\dr-guidelines-workspace\dr-test-01
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
  .claude/settings.json:
  [OK]   .claude/settings.json
  Catalogo scaffolding:
  [OK]   dr-scaffolding-catalog.json
  CLAUDE.md:
  [OK]   CLAUDE.md creato con sezione dr-guidelines
  [OK]   Manifest aggiornato: dr-guidelines (a1b2c3d)
  Completato: dr-guidelines
```

---

## 4️⃣ Verificare l'installazione del core

```powershell
Get-ChildItem -Force | Select-Object Name
Get-ChildItem .github\instructions | Select-Object Name
Get-ChildItem .github\prompts | Select-Object Name
Get-ChildItem .claude\skills -Directory | Select-Object Name
Get-Content .ai\dr-guidelines-packages.json
git status --short
```

**Atteso** (conteggi del core al 2026-09-22):

| Elemento | Atteso |
|---|---|
| `.editorconfig`, `.gitignore`, `.gitattributes` | Presenti |
| `Directory.Build.props`, `global.json` | **Assenti**: appartengono a `dr-dotnet-backend`, arrivano al passo 5 |
| `.claude/settings.json` | Presente. Se esisteva già, solo le voci `permissions.allow` mancanti vengono aggiunte |
| `.mcp.json` | Generato da `.mcp.example.json`, perché assente |
| `.github/instructions/` | 11 file `*.instructions.md` |
| `.github/prompts/` | 8 prompt: `card-project-generator`, `card-wiki-generator`, `onboarding-senior`, `readme-generator`, `dr-scaffold`, `dr-get-latest`, `dr-file-feedback`, `dr-issues-to-plans` |
| `.claude/skills/` | 17 cartelle skill `dr-*` |
| `CLAUDE.md` | Contiene `<!-- dr-guidelines -->` … `<!-- /dr-guidelines -->` |
| `.ai/dr-scaffolding-catalog.json` | Presente: è `scaffolding-catalog.json` del core, copiato con questo nome |
| `.ai/dr-guidelines-packages.json` | `{"installed":[{"package":"dr-guidelines","installedAt":"<oggi>","commit":"<sha>"}]}` |
| `git status --short` | `.mcp.json` **non** compare: il `.gitignore` copiato lo esclude |

---

## 5️⃣ Installare un pacchetto di dominio

`dr-minimalapi` dipende da `dr-dotnet-backend`. Se manca dal manifest, l'installer lo installa **prima**, da solo.

```powershell
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String))) -Package dr-minimalapi
```

**Riga chiave dell'output:**

```
  Dipendenza mancante: dr-dotnet-backend -> installazione automatica
```

**Verifiche:**

```powershell
Get-Content .ai\dr-guidelines-packages.json                  # tre pacchetti
Get-ChildItem .github\prompts | Select-Object Name           # ora anche card-minimal-api, endpoints-analyzer
Get-ChildItem .claude\skills -Directory | Select-Object Name # ora anche dr-audit-api
Test-Path Directory.Build.props, global.json                 # True, True
```

Il manifest deve elencare `dr-guidelines`, `dr-dotnet-backend`, `dr-minimalapi`.

> I pacchetti di dominio non toccano `CLAUDE.md` né `.editorconfig`, `.gitignore`, `.gitattributes`: sono esclusiva del core. Copiano solo i file di radice dichiarati nel catalogo (`rootFiles`), come `global.json` per `dr-dotnet-backend`.

---

## 6️⃣ Verificare idempotenza e `-Update`

**Seconda esecuzione senza flag.** Nessun file deve essere sovrascritto:

```powershell
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
```

Atteso: nessuna riga `[OK]` o `[UPD]` sui file. Compaiono righe `[SKIP]`, `Nessuna novita': gia' al commit <sha>` e `[SKIP] Sezione dr-guidelines gia presente in CLAUDE.md (usa -Update per aggiornare)`. Fa eccezione `[OK]   Manifest aggiornato`: il manifest si riscrive a ogni esecuzione, con la data del giorno.

**`-Update` ripristina un file modificato:**

```powershell
Add-Content .github\instructions\logging.instructions.md "`n<!-- modifica locale di test -->"
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String))) -Update
Select-String -Path .github\instructions\logging.instructions.md -Pattern "modifica locale di test"
```

Atteso: righe `[UPD]`, `[UPD]  Sezione dr-guidelines aggiornata in CLAUDE.md`, e l'ultimo comando **senza risultati**.

**`-Update` preserva il contenuto di `CLAUDE.md` fuori dai marker:**

```powershell
Add-Content CLAUDE.md "`n## Sezione mia del progetto`n`nQuesta riga deve sopravvivere all'update."
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String))) -Update
Select-String -Path CLAUDE.md -Pattern "deve sopravvivere"
```

Atteso: la riga **c'è ancora**.

---

## 7️⃣ Verificare che si installi il `main` remoto

Serve il clone locale: il test ha senso solo lanciando l'installer **dal percorso locale**. Con la forma `gh api` il risultato sarebbe scontato.

1. Nel clone locale di `dr-minimalapi` aggiungi una riga riconoscibile a `.github/instructions/minimal-api-architecture.instructions.md`, **senza commit né push**
2. Dalla cartella di prova lancia l'installer dal percorso locale:
   ```powershell
   Set-Location E:\Davide\Progetti\dr-guidelines-workspace\dr-test-01
   & ..\dr-minimalapi\dr-minimalapi-install.ps1 -Update
   ```
3. Cerca la riga nella copia installata:
   ```powershell
   Select-String -Path .github\instructions\minimal-api-architecture.instructions.md -Pattern "<testo della riga>"
   ```

Atteso: **nessun risultato**. Dal clone locale l'installer prende solo la libreria; il contenuto del pacchetto lo clona dal `main` su GitHub. Poi annulla la modifica nel clone locale con `git checkout -- <file>`.

---

## 8️⃣ Verificare le skill in Claude Code

1. Nella finestra della cartella di prova: `Developer: Reload Window`. Le skill si leggono all'avvio della sessione
2. Invoca `/dr-snapshot`. Atteso: nasce `.ai/context/snapshot.md`
3. Invoca `/dr-get-latest`. Atteso: aggiorna i tre pacchetti del manifest. Su repo Private la skill usa la forma `gh api`
4. Controprova della guard: apri Claude Code su un repo sorgente (per esempio `dr-guidelines`) e invoca `/dr-get-latest`. Atteso, testuale:

> "Sei in un repo sorgente dr-*: qui non esiste un manifest pacchetti da aggiornare. Usa `git pull` per allinearti al remoto."

---

## 📋 Checklist finale

| # | Criterio | Esito |
|---|----------|-------|
| 1 | Cartella di prova fuori dal workspace `dr-*`, aperta in finestra separata | ☐ |
| 2 | Config radice del core presenti; `Directory.Build.props` e `global.json` solo dopo `dr-dotnet-backend` | ☐ |
| 3 | `.mcp.json` generato e ignorato da git | ☐ |
| 4 | 11 istruzioni, 8 prompt, 17 skill dopo il solo core | ☐ |
| 5 | `CLAUDE.md` con sezione `<!-- dr-guidelines -->` | ☐ |
| 6 | Manifest con 3 pacchetti dopo il passo 5 | ☐ |
| 7 | `dr-dotnet-backend` installato in automatico | ☐ |
| 8 | Seconda esecuzione senza flag → nessun file sovrascritto (solo `[SKIP]`, più la riga del manifest) | ☐ |
| 9 | `-Update` sovrascrive e riscrive la sezione | ☐ |
| 10 | Contenuto di `CLAUDE.md` fuori dai marker preservato | ☐ |
| 11 | Modifica non pushata non arriva nell'host | ☐ |
| 12 | Nessun `.gitmodules` né repo annidato nella cartella di prova | ☐ |
| 13 | `/dr-snapshot` funziona dall'host | ☐ |
| 14 | `/dr-get-latest` funziona dall'host e si ferma nel repo sorgente | ☐ |

Verifica del criterio 12:

```powershell
Test-Path .gitmodules                 # atteso: False
Get-ChildItem -Recurse -Force -Directory -Filter .git | Select-Object FullName   # solo la .git della cartella di prova
```

---

## ♻️ Rollback e pulizia

**Tornare al commit iniziale mantenendo la cartella:**

```powershell
Set-Location E:\Davide\Progetti\dr-guidelines-workspace\dr-test-01
git clean -fd          # rimuove i file non tracciati aggiunti dall'installer
git checkout -- .      # ripristina i file tracciati modificati
```

`.mcp.json` resta: è ignorato da git e `git clean -fd` non lo tocca. Cancellalo a mano se vuoi ripartire da zero.

**Eliminare la cartella di prova:**

```powershell
Set-Location E:\Davide\Progetti\dr-guidelines-workspace
Remove-Item .\dr-test-01 -Recurse -Force
```

> ⚠️ `Remove-Item -Recurse -Force` è irreversibile e cancella anche il repository git locale della cartella di prova. Nessun remote è coinvolto: la cartella non viene mai pushata.

---

## 🔗 Riferimenti

| Documento | Contenuto |
|-----------|-----------|
| [`guida-nuova-soluzione.md`](guida-nuova-soluzione.md) | Percorso utente: dalla cartella vuota alla solution |
| [`bozza-manuale-installazione.md`](bozza-manuale-installazione.md) | Esiti delle prove sul campo |
| [`../README.md`](../README.md) | Pacchetti, installazione, aggiornamento |
| [`../dr-guidelines-install-lib.ps1`](../dr-guidelines-install-lib.ps1) | `Get-DrCatalog`, `Install-DrPackage`, `Install-DrGlobal` |
| [`onboarding.md`](onboarding.md) | Onboarding per chi sviluppa il core |

---

*Revisione v2.1 — 2026-09-22 06:46 — claude-opus-5*
