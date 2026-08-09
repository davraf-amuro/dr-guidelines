# Cronologia sessione corrente

Sessione 2026-08-08, repo `dr-guidelines`, branch `main`.

- Cosa fatto: ricognizione del repo e della modalità di test del meccanismo pacchetti (`install.ps1`, `install-lib.ps1`, `docs/test-progetto-host.md`, contenuto dei 6 pacchetti dominio locali).
  Perché: l'utente chiedeva come provare il progetto, partendo dall'ipotesi che non si potesse scaricare da git.
  Risultato: premessa corretta — `gh auth status` autenticato come `davraf-amuro` con scope `repo` e `git ls-remote` funzionante, quindi il `git clone` dell'installer funziona; ciò che non funziona è il bootstrap `irm ... | iex` (raw 404 su repo Private).

- Cosa fatto: install reale del core e di `dr-minimalapi` in un progetto host usa-e-getta nello scratchpad, più un secondo run.
  Perché: verificare sul campo invece di descrivere la procedura.
  Risultato: core installato (10 instructions, 4 prompt, 10 skill, 5 config, `.mcp.json`, `CLAUDE.md`); dipendenza `dr-dotnet-backend` installata automaticamente prima di `dr-minimalapi`; manifest con 3 pacchetti; secondo run tutti `[SKIP]`.

- Cosa fatto: rilevata e segnalata una nota errata in `docs/test-progetto-host.md:149` ("il core non ha `.github/prompts/`").
  Perché: l'output reale dell'installer mostrava 4 prompt copiati.
  Risultato: correzione applicata più tardi nella sessione (Fase 13 del piano).

- Cosa fatto: constatato che lo scaffolding di una solution non esiste: solo la specifica in `TODO/01-install-scaffholding.md`, più `CreateNewSolution.ps1` e `setup.ps1` dell'era submodule.
  Perché: l'utente chiedeva come partire da zero con una solution.
  Risultato: perimetro del lavoro successivo definito.

- Cosa fatto: invocato `/dr-warroom` sulla progettazione del sistema di scaffolding (5 agenti in parallelo: ARCH, BE, UI, UX, DBADMIN).
  Perché: richiesta esplicita dell'utente e decisione con più opzioni valide.
  Risultato: convergenza su tre pezzi, catalogo dati unico, una sola conferma dopo dry-run, legacy rimosso. Segnalazioni tecniche puntuali: `(Get-Location).Path` come host root richiede `Push-Location`; validazione regex dei nomi; verdict DBADMIN "nessun intervento database necessario".

- Cosa fatto: invocato `/dr-tech` per il runbook operativo, con verifiche eseguite sulla macchina (`dotnet new sln --help`, creazione solution + progetti, build, `create-vue`, `dotnet format`).
  Perché: richiesta esplicita dell'utente; servivano comandi esatti, non ipotesi.
  Risultato: `dotnet new sln` ha default `slnx` su SDK 10.0.302; `dotnet sln add` genera le solution folder; build 0 warning/0 errori con `Directory.Build.props` del core; flag di `create-vue` booleani puri; `dotnet format --verify-no-changes` esce `2` su solution vergine per BOM vs `charset = utf-8`.

- Cosa fatto: interruzione utente su un `dotnet format` in scrittura.
  Risultato: comando non eseguito in quel punto; la verifica del rimedio è stata rifatta più tardi su un progetto isolato.

- Cosa fatto: raccolte 4 decisioni con `AskUserQuestion` (punti d'ingresso, superficie duale, config .NET nei repo frontend, gestione del catalogo).
  Perché: ognuna cambiava materialmente il lavoro da produrre.
  Risultato: orchestratore + due sotto-skill; skill + prompt duale; config condizionale nell'installer; `catalog.json` con guardia CI.

- Cosa fatto: scritto il piano su disco (`.ai/plans/2026-08-08-scaffolding-skills/plan.md`), `EnterPlanMode`, `ExitPlanMode`.
  Perché: convenzione di progetto per task con ≥ 2 operazioni.
  Risultato: piano approvato dall'utente.

- Cosa fatto: creato `scaffolding-catalog.json` (5 tipologie, 7 pacchetti) e confrontato con `$Script:PackageRegistry`.
  Risultato: chiavi identiche, nessuna divergenza su `repo`/`isCore`/`dependencies`.

- Cosa fatto: modificato `install-lib.ps1` — `Test-DotnetHost` + copia condizionale di `Directory.Build.props`/`global.json`, e `Copy-ScaffoldingCatalog` per distribuire il catalogo in `.ai/dr-scaffolding-catalog.json`.
  Risultato: testato su due host di prova — host .NET riceve i due file, host con solo `package.json` mostra `[SKIP] ... (host non .NET)`; catalogo copiato in entrambi.

- Cosa fatto: aggiunto il job `catalog-guard` a `.github/workflows/ci.yml` e provato lo stesso script in locale.
  Risultato: YAML valido (`jobs: ['build-and-test', 'catalog-guard']`); exit `0` sul catalogo reale, exit `1` alterando due nomi pacchetto.

- Cosa fatto: create le 4 skill `dr-scaffold`, `dr-scaffold-solution`, `dr-scaffold-project`, `dr-scaffold-guidelines`.
  Risultato: frontmatter valido, blocco `INPUT_UTENTE` e perimetro non negoziabile presenti in tutte; registrate e visibili nella lista skill della sessione.

- Cosa fatto: creato `.github/prompts/dr-scaffold.prompt.md` (sezioni A/B/C, liste numerate con default espliciti).
  Perché: obbligo di compatibilità duale su `.github/prompts/`.
  Risultato: grep di `$ARGUMENTS`, `AskUserQuestion`, `EnterPlanMode`, `subagent`, `INPUT_UTENTE` → nessuna occorrenza.

- Cosa fatto: verificata la precondizione della fase di rimozione legacy.
  Risultato: divergenza — i riferimenti a `CreateNewSolution` erano in 4 file, non solo `README.md`; 3 erano nel perimetro negativo, incluso `readme-structure.instructions.md:47` che *prescriveva* quello script al README. Divergenza registrata nel piano e portata all'utente.

- Cosa fatto: chiesto all'utente come procedere sullo scope.
  Risultato: scope esteso ai 3 file, approvato.

- Cosa fatto: eliminato `CreateNewSolution.ps1`; aggiornati `README.md`, `.github/instructions/readme-structure.instructions.md`, `docs/card-davraf-guidelines.md`, `docs/onboarding.md`; aggiunte 3 righe alla tabella di invocazione in `CLAUDE.md`; corretta e versionata `docs/test-progetto-host.md`.
  Risultato: `grep -c CreateNewSolution README.md` → `0`; nessun riferimento residuo nel repo (esclusi `.ai/` e `.git/`); `setup.ps1` e `templates/global-claude.md` intatti; footer aggiornati (card v2.3, onboarding v2.4, test-progetto-host v1.1, readme-structure v2.1).

- Cosa fatto: verifica end-to-end — installer reale su host .NET e host non-.NET, secondo run per l'idempotenza, guardia CI in locale.
  Risultato: tutti gli esiti conformi. `[WARN] scaffolding-catalog.json non trovato nel pacchetto core` su entrambi gli host, atteso: l'installer clona `origin/main`, dove il catalogo non è ancora presente.

- Cosa fatto: verificato su un progetto xunit isolato il rimedio all'errore CHARSET.
  Perché: le skill affermano che `dotnet format` risolve; l'affermazione non era ancora provata.
  Risultato: prima BOM `239,187,191` ed exit `2`; dopo `dotnet format` BOM rimosso ed exit `0`.

- Cosa fatto: chiuso il piano con `Stato: COMPLETATO`, consuntivo per fase, limite noto e lavoro residuo.

- Cosa fatto: rilevati `AGENTS.md` (`# Linee guida per Codex`) e `.agents/skills/` con 14 sottocartelle che rispecchiano `.claude/skills/`, inclusi i 4 `dr-scaffold*`, timestamp 14:30.
  Risultato: segnalati all'utente come non prodotti da azioni dichiarate in sessione; non modificati. Origine: Sconosciuto.

- Cosa fatto: nessun `git add`, `git commit` o `git push` in tutta la sessione.
  Risultato: tutte le modifiche restano nel working tree.
