# Piano: Sistema di scaffolding dr-* (skill + prompt duale + catalogo)
Data: 2026-08-08
Stato: COMPLETATO

## Obiettivo
Implementare `TODO/01-install-scaffholding.md`: scaffolding guidato (workspace → solution → progetti → pacchetti dr-*) come skill Claude Code + prompt Copilot, alimentati da un catalogo dati unico.

## Decisioni approvate dall'utente (warroom 2026-08-08 + AskUserQuestion)

| # | Decisione | Scelta |
|---|---|---|
| a | Punti d'ingresso | Orchestratore `/dr-scaffold` (router) + `dr-scaffold-solution` + `dr-scaffold-project` + `dr-scaffold-guidelines`, i tre sotto-pezzi invocabili anche da soli |
| b | Superficie | Skill Claude Code **+** `.github/prompts/dr-scaffold.prompt.md` duale (Copilot: liste numerate con default espliciti) |
| c | Config .NET in repo FE | Config **condizionale** nell'installer: `Directory.Build.props` e `global.json` non copiati se il repo non è .NET |
| d | Catalogo | `scaffolding-catalog.json` + **guardia CI** che confronta le chiavi con `$Script:PackageRegistry`; installer non refactorizzato |
| e | Legacy (scope esteso, approvato in corso d'opera) | `CreateNewSolution.ps1` eliminato **e** i 3 riferimenti pendenti aggiornati |

## Fatti verificati in questa sessione (vincolano l'implementazione)

- SDK rilevato `10.0.302`; `dotnet new sln` ha default **`slnx`** (`-f, --format <sln|slnx>`), non `sln`
- `dotnet sln <file>.slnx add` funziona e genera da sé le solution folder `/src/` e `/test/`
- `dotnet build` con `Directory.Build.props` + `global.json` del core: 0 warning, 0 errori
- `create-vue@3.23.0`: flag **booleani puri** (`--vitest=false` → `ERR_PARSE_ARGS_INVALID_OPTION_VALUE`); scrive un proprio `.editorconfig`/`.gitignore`/`.gitattributes` → FE va creato **prima** dell'install del core
- Script `lint` di create-vue usa `--fix` → non è un gate di verifica; serve variante senza `--fix`
- `.editorconfig` del core riga 8 `charset = utf-8` + template `dotnet new` con BOM (primi byte `239,187,191`) → `dotnet format --verify-no-changes` esce `2` su progetto vergine. **Confermato in Fase 14**: dopo `dotnet format` in scrittura il BOM è rimosso e la verifica esce `0`
- `Install-DrPackage` usa `(Get-Location).Path` (install-lib.ps1:210) ⇒ `Push-Location` sulla **root del repo**, non sulla cartella del progetto
- Installer testato end-to-end: core + `dr-minimalapi` (con dipendenza auto `dr-dotnet-backend`) + idempotenza `[SKIP]`

## Deviazione dalla raccomandazione del warroom (documentata)

Il tavolo raccomandava di eliminare `CreateNewSolution.ps1` **e** `setup.ps1`. Verifica successiva: `setup.ps1 -GlobalInstall`/`-GlobalUpdate` è una **feature viva e non migrata** (scrive `~/.claude/CLAUDE.md`), documentata in `README.md` e basata su `templates/global-claude.md`. Eliminarla toglierebbe una capacità in uso.

Decisione applicata: eliminato **solo** `CreateNewSolution.ps1`. `setup.ps1` e `templates/global-claude.md` intatti; la migrazione di `-GlobalInstall` a `install.ps1` resta il TODO già aperto.

## Scope

### File creati
- [x] `scaffolding-catalog.json` — catalogo tipologie progetto + pacchetti
- [x] `.claude/skills/dr-scaffold/SKILL.md` — router
- [x] `.claude/skills/dr-scaffold-solution/SKILL.md`
- [x] `.claude/skills/dr-scaffold-project/SKILL.md`
- [x] `.claude/skills/dr-scaffold-guidelines/SKILL.md`
- [x] `.github/prompts/dr-scaffold.prompt.md` — equivalente duale

### File modificati
- [x] `install-lib.ps1` — config .NET condizionale + copia catalogo in `.ai/`
- [x] `.github/workflows/ci.yml` — job `catalog-guard`
- [x] `README.md` — Avvio Rapido su `/dr-scaffold`, 4 nuove skill, FAQ corretta
- [x] `CLAUDE.md` — 3 righe nella tabella di invocazione
- [x] `docs/test-progetto-host.md` — nota `.github/prompts/` corretta + 2 note nuove, footer v1.1
- [x] `.github/instructions/readme-structure.instructions.md` — sezione 3 riscritta (**scope esteso**)
- [x] `docs/card-davraf-guidelines.md` — entrypoint e riga CDN (**scope esteso**), footer v2.3
- [x] `docs/onboarding.md` — bootstrap e albero file (**scope esteso**), footer v2.4

### File eliminati
- [x] `CreateNewSolution.ps1` — legacy era submodule (recuperabile: `git checkout -- CreateNewSolution.ps1`)

### Perimetro negativo rispettato
- Non toccati: `setup.ps1`, `templates/global-claude.md`, `.template.config/`, `Directory.Build.props`, `global.json`, `.editorconfig`, `.gitignore`, `.gitattributes`, `$Script:PackageRegistry`, le altre 9 istruzioni in `.github/instructions/`, le 10 skill preesistenti, i 4 prompt preesistenti, i tre `docs/scaffolding-*.md`, gli altri piani in `.ai/plans/`, i repo dei 6 pacchetti dominio.
- Nessun `git commit`, nessun `git push` eseguito.

## Fasi

### Fase 1: Catalogo dati — [x]
`scaffolding-catalog.json` creato: `schemaVersion`, `defaults` (framework, formato solution, pattern nomi), 5 `projectTypes[]`, 7 `packages[]`.
**Verifica**: JSON valido; chiavi identiche al registry (`identici: True`); nessuna divergenza su repo/isCore/dependencies.

### Fase 2: Installer — config .NET condizionale — [x]
Aggiunta `Test-DotnetHost` (ricerca `*.csproj`/`*.fsproj`/`*.vbproj`/`*.sln`/`*.slnx` con `-Depth 3`, così non scende in `node_modules`); `Copy-CoreConfigFiles` copia sempre `.editorconfig`/`.gitignore`/`.gitattributes` e i due file .NET solo su host .NET.
**Verifica**: host con `.csproj` → `[OK]` sui 2 file; host con solo `package.json` → `[SKIP] ... (host non .NET)` e file assenti.

### Fase 3: Installer — distribuzione del catalogo — [x]
Aggiunta `Copy-ScaffoldingCatalog`, chiamata nel ramo `IsCore` di `Install-DrPackage`; destinazione `<host>/.ai/dr-scaffolding-catalog.json`; sorgente assente → `[WARN]` e prosecuzione.
**Verifica**: file creato in entrambi gli scenari con chiamata diretta alla funzione.

### Fase 4: Guardia CI catalogo ↔ registry — [x]
Job `catalog-guard` in `ci.yml` (`shell: pwsh`): dot-sourcia `install-lib.ps1`, confronta nomi, repo, `isCore`, dipendenze, risolvibilità delle dipendenze, riferimenti a pacchetti nelle tipologie, unicità degli `id` e presenza di `dotnetTemplate`/`nodeScaffolder`.
**Verifica**: YAML valido (`jobs: ['build-and-test', 'catalog-guard']`); script eseguito in locale → `0` sul catalogo reale, `1` alterando due nomi pacchetto, con messaggi puntuali.

### Fase 5: Skill router `dr-scaffold` — [x]
Gate 0 prerequisiti (SDK/git/pwsh/gh/node) con la motivazione del pin `global.json`, rilevamento stato cartella, delega dichiarata. Nessuna scrittura.

### Fase 6: Skill `dr-scaffold-solution` — [x]
Due gate di raccolta, dry-run + conferma unica, esecuzione ordinata (workspace → sln → progetti → aggancio → FE → git → install → format → MCP/launch profiles), validazione nomi, tabella verifiche, sezione rollback.

### Fase 7: Skill `dr-scaffold-project` — [x]
Individuazione solution (STOP se ambigua), tipologia dal catalogo, dry-run + conferma, `dotnet new` + `dotnet sln add` + build + format, riferimenti tra progetti solo su richiesta, rimando a `dr-scaffold-guidelines` per i pacchetti mancanti.

### Fase 8: Skill `dr-scaffold-guidelines` — [x]
Guard repo sorgente, verifica root repo, rilevamento stack, catalogo con fallback ordinato, stato per pacchetto (installato/consigliato/opzionale), `Push-Location` + install, riepilogo con proposta `db-schema` e promemoria riavvio IDE. Confine con `/dr-get-latest` dichiarato.

### Fase 9: Prompt duale — [x]
`.github/prompts/dr-scaffold.prompt.md` con sezioni A/B/C, liste numerate e default espliciti.
**Verifica**: grep di `$ARGUMENTS`, `AskUserQuestion`, `EnterPlanMode`, `subagent`, `INPUT_UTENTE` → nessun risultato. Frontmatter allineato ai prompt esistenti.

### Fase 10: Rimozione legacy — [x]
⚠️ Divergenza rilevata e **risolta**: la precondizione dichiarava riferimenti solo in `README.md`, la verifica ne ha trovati in 4 file (3 nel perimetro negativo, tra cui `readme-structure.instructions.md:47` che *prescriveva* `CreateNewSolution.ps1` al README — senza aggiornarla, una rigenerazione lo avrebbe reintrodotto). Scope esteso ai 3 file su approvazione esplicita dell'utente.
**Verifica**: `CreateNewSolution.ps1` assente, `setup.ps1` e `templates/global-claude.md` presenti, `git status` mostra ` D CreateNewSolution.ps1`.

### Fase 11: README — [x]
**Verifica**: `grep -c CreateNewSolution README.md` → `0`; `dr-scaffold` → 12 occorrenze; `GlobalInstall` → 2 (preservati).

### Fase 12: Tabella invocazione skill — [x]
3 righe aggiunte in `CLAUDE.md` (`/dr-scaffold`, `/dr-scaffold-project`, `/dr-scaffold-guidelines`).

### Fase 13: Correzione doc di test — [x]
Nota `.github/prompts/` corretta (il core copia 5 prompt, non zero); aggiunte le note su `.ai/dr-scaffolding-catalog.json` e sulla copia condizionale dei file .NET; footer v1.1.

### Fase 14: Verifica end-to-end — [x]

| Scenario | Comando | Esito |
|---|---|---|
| Host .NET, installer reale | `& dr-guidelines\install.ps1` | `[OK]` su `.editorconfig`, `.gitignore`, `.gitattributes`, `Directory.Build.props`, `global.json`, `.mcp.json`; `CLAUDE.md` creato; manifest aggiornato |
| Host non .NET, installer reale | idem | `[SKIP] Directory.Build.props, global.json (host non .NET)`; i due file **assenti** sul disco; resto invariato |
| Idempotenza | secondo run | tutti `[SKIP]`, `[SKIP] Sezione dr-guidelines gia presente`, manifest con una sola voce |
| Guardia CI | script in locale | `0` sul catalogo reale, `1` con due nomi alterati |
| Claim `dotnet format` | progetto xunit isolato | prima: `error CHARSET`, exit `2`, BOM `239,187,191` — dopo `dotnet format`: BOM rimosso, exit `0` |

⚠️ **Limite noto (atteso, non un difetto)**: nei test l'installer clona `origin/main`, dove `scaffolding-catalog.json` non è ancora presente → stampa `[WARN] scaffolding-catalog.json non trovato nel pacchetto core` e prosegue. Il catalogo verrà distribuito ai progetti host **solo dopo il commit e il push** di questo lavoro. Fino a quel momento le skill lo trovano tramite il secondo percorso del fallback (root del clone `dr-guidelines`).

## Criteri di verifica finale
- [x] `scaffolding-catalog.json` valido, 7 pacchetti e 5 tipologie, allineato al registry
- [x] 4 skill `dr-scaffold*` create con frontmatter valido e perimetro non negoziabile (registrate e visibili in sessione)
- [x] `.github/prompts/dr-scaffold.prompt.md` privo di costrutti Claude-only
- [x] `install-lib.ps1`: config .NET condizionale + catalogo distribuito in `.ai/`
- [x] Guardia CI presente, verde in locale, rossa su catalogo alterato
- [x] `CreateNewSolution.ps1` eliminato; `setup.ps1` e `templates/global-claude.md` intatti
- [x] Nessun riferimento pendente a `CreateNewSolution` (README + i 3 file dello scope esteso)
- [x] `CLAUDE.md` con le 3 righe di invocazione
- [x] `docs/test-progetto-host.md` corretto, footer v1.1
- [x] Verifica end-to-end registrata con esito conforme sui due scenari
- [x] Nessun `git commit`/`git push` eseguito

## Lavoro residuo (fuori da questo piano)
- Commit + push: finché il catalogo non è su `origin/main`, l'installer stampa il `[WARN]` sopra.
- `docs/onboarding.md` è ancora largamente tarato sul modello a submodule `davraf-guidelines` (sezioni 3 e 4): qui sono stati corretti solo i riferimenti a `CreateNewSolution.ps1`. Riscrittura completa da valutare con `/dr-professor`.
- Migrazione di `setup.ps1 -GlobalInstall`/`-GlobalUpdate` a `install.ps1`: TODO preesistente, non affrontato.
- Dogfooding di `/dr-scaffold` su una cartella vuota reale: i comandi che compone sono stati verificati singolarmente, il flusso completo end-to-end no.
