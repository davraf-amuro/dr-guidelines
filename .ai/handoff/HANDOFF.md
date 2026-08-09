# Progetto

`dr-guidelines` — pacchetto core della suite `dr-*`: linee guida, istruzioni modulari, prompt e skill per Claude Code e GitHub Copilot, distribuiti come pacchetti installabili via PowerShell.

Repo: `davraf-amuro/dr-guidelines` (Private). Workspace locale: `E:\Davide\Progetti\dr-guidelines-workspace\` con i 7 repo `dr-*` come sottocartelle sorelle.

---

# Obiettivo

Obiettivo della sessione corrente: implementare `TODO/01-install-scaffholding.md` — un sistema di scaffolding guidato (workspace VS Code → solution .NET 10 → progetti → pacchetti `dr-*`) realizzato come **prompt per l'agente AI**, non come script PowerShell.

Obiettivo di progetto in corso (piano precedente): completare lo split multi-repo avviato in `.ai/plans/2026-07-22-dr-guidelines-split/plan.md`.

---

# Stato corrente

- Sistema di scaffolding **implementato e verificato**: 4 skill, 1 prompt duale, 1 catalogo dati, 1 guardia CI, 2 modifiche all'installer. Piano `.ai/plans/2026-08-08-scaffolding-skills/plan.md` con `Stato: COMPLETATO`.
- Tutte le modifiche sono **non committate** (`git status` in sessione: 8 file modificati/eliminati, 6 percorsi untracked pertinenti).
- I 7 repo `dr-*` sono ancora **Private**: il bootstrap `irm ... | iex` risponde 404. L'unica modalità funzionante è l'invocazione da path locale (`& <workspace>\dr-<pkg>\install.ps1`), verificata in sessione.
- `scaffolding-catalog.json` non è ancora su `origin/main`: l'installer, che clona il remoto, stampa `[WARN] scaffolding-catalog.json non trovato nel pacchetto core` e prosegue.
- Stato dello split (piano 2026-07-22): fasi 1-5 risultano concluse (commit `4e079dd` installer, `f0435cd` rinomina skill `dr-`, skill `dr-segnala-miglioria` presente). Fase 6 (README) modificata in sessione ma non committata. Fasi 7-8 e gate 2b (Private → Public) aperti.

---

# Componenti completati

- `scaffolding-catalog.json` — 5 tipologie di progetto, 7 pacchetti con `repo`/`isCore`/`dependencies`/`appliesTo`, blocco `defaults` (framework `net10.0`, formato solution `slnx`, pattern nomi)
- `.claude/skills/dr-scaffold/SKILL.md` — router: gate prerequisiti, rilevamento stato cartella, delega
- `.claude/skills/dr-scaffold-solution/SKILL.md` — flusso completo da cartella vuota
- `.claude/skills/dr-scaffold-project/SKILL.md` — aggiunta progetto a solution esistente
- `.claude/skills/dr-scaffold-guidelines/SKILL.md` — installazione pacchetti su repo esistente
- `.github/prompts/dr-scaffold.prompt.md` — equivalente per GitHub Copilot, sezioni A/B/C
- `install-lib.ps1` — funzione `Test-DotnetHost` + copia condizionale di `Directory.Build.props`/`global.json`; funzione `Copy-ScaffoldingCatalog` che distribuisce il catalogo in `.ai/dr-scaffolding-catalog.json`
- `.github/workflows/ci.yml` — job `catalog-guard`
- `CreateNewSolution.ps1` eliminato; riferimenti aggiornati in `README.md`, `.github/instructions/readme-structure.instructions.md`, `docs/card-davraf-guidelines.md`, `docs/onboarding.md`
- `CLAUDE.md` — 3 righe di invocazione automatica per le nuove skill
- `docs/test-progetto-host.md` — procedura di test end-to-end del meccanismo pacchetti (untracked)

---

# Componenti in lavorazione

Nessuno.

---

# Componenti mancanti

- Commit e push del lavoro della sessione (nessun commit eseguito)
- Dogfooding di `/dr-scaffold` su una cartella vuota reale: i singoli comandi sono verificati, il flusso completo dell'orchestratore no
- Migrazione di `setup.ps1 -GlobalInstall`/`-GlobalUpdate` a `install.ps1` (TODO preesistente)
- Riscrittura di `docs/onboarding.md`: le sezioni 3-4 descrivono ancora il modello a submodule `davraf-guidelines`
- Fase 7 dello split: deprecazione/archiviazione del repo `davraf-guidelines`
- Fase 8 dello split: piano di migrazione dei progetti host esistenti
- Gate 2b: test dell'installer su un progetto host reale esistente, poi flip Private → Public

---

# File modificati

| Percorso | Motivo |
|---|---|
| `scaffolding-catalog.json` | Nuovo: catalogo tipologie progetto + pacchetti, fonte per skill e prompt |
| `.claude/skills/dr-scaffold/SKILL.md` | Nuovo: router dello scaffolding |
| `.claude/skills/dr-scaffold-solution/SKILL.md` | Nuovo: creazione workspace/solution/progetti/pacchetti |
| `.claude/skills/dr-scaffold-project/SKILL.md` | Nuovo: aggiunta progetto a solution esistente |
| `.claude/skills/dr-scaffold-guidelines/SKILL.md` | Nuovo: installazione pacchetti su repo esistente |
| `.github/prompts/dr-scaffold.prompt.md` | Nuovo: equivalente duale per Copilot |
| `install-lib.ps1` | Copia condizionale dei file .NET; distribuzione del catalogo in `.ai/` |
| `.github/workflows/ci.yml` | Job `catalog-guard`: allineamento catalogo ↔ `$Script:PackageRegistry` |
| `README.md` | Sezione "Avvio Rapido" riscritta su `/dr-scaffold`; 4 nuove skill documentate; FAQ sul fallback ZIP corretta |
| `CLAUDE.md` | 3 righe nella tabella di invocazione automatica |
| `.github/instructions/readme-structure.instructions.md` | Sezione 3 riscritta: prescriveva `CreateNewSolution.ps1` al README |
| `docs/card-davraf-guidelines.md` | Entrypoint e riga CDN aggiornati; footer v2.3 |
| `docs/onboarding.md` | Blocco "Nuovo progetto" e albero file aggiornati; footer v2.4 |
| `docs/test-progetto-host.md` | Nota errata su `.github/prompts/` corretta; note su catalogo e copia condizionale; footer v1.1 |
| `CreateNewSolution.ps1` | **Eliminato**: script era submodule, puntava al repo legacy `davraf-guidelines` |
| `.ai/plans/2026-08-08-scaffolding-skills/plan.md` | Nuovo: piano di sessione, `Stato: COMPLETATO` |

---

# Decisioni progettuali

Dettaglio completo in `DECISIONI.md`. Elenco sintetico delle decisioni prese in questa sessione:

- Scaffolding diviso in orchestratore + 3 pezzi — motivazione: cicli di vita e punti d'ingresso diversi; chi ha già una solution non attraversa rami morti
- Skill Claude Code **e** prompt Copilot — motivazione: rispetto della regola di compatibilità duale del progetto senza rinunciare ai widget su Claude Code
- Catalogo come file dati + guardia CI (registry PowerShell non refactorizzato) — motivazione: nessuna deriva silenziosa senza toccare un installer funzionante
- Copia condizionale di `Directory.Build.props`/`global.json` — motivazione: in un repo frontend sarebbero file inerti
- Unità di installazione = repository, non progetto — motivazione: gli artefatti del core sono letti solo dalla root
- Eliminato `CreateNewSolution.ps1`, conservato `setup.ps1` — motivazione: `-GlobalInstall` è una feature viva e non migrata
- Scope esteso a 3 file fuori piano — motivazione: `readme-structure.instructions.md` prescriveva lo script eliminato

---

# Problemi aperti

- **Limitazione**: repo Private → `irm ... | iex` risponde 404. Solo invocazione da path locale funziona. Blocca anche `/dr-get-latest`, che usa `Invoke-RestMethod` senza fallback locale.
- **Attività incompleta**: `scaffolding-catalog.json` non è su `origin/main` → l'installer stampa `[WARN] scaffolding-catalog.json non trovato nel pacchetto core`. Le skill ripiegano sul secondo percorso del fallback (root del clone `dr-guidelines`).
- **Attività incompleta**: nessun commit eseguito. Tutto il lavoro della sessione è nel working tree.
- **Debito tecnico**: `docs/onboarding.md` sezioni 3-4 descrivono il modello a submodule `davraf-guidelines`, superato. Corretti in sessione solo i riferimenti a `CreateNewSolution.ps1`.
- **Debito tecnico**: `.claude/skills/dr-handoff/` contiene `skill.md` e `skill.md.original.md` in minuscolo, mentre le altre 13 skill usano `SKILL.md`.
- **Debito tecnico**: `.ai/plans/` contiene 3 piani ereditati dal repo originale (`2026-06-17-global-install`, `2026-07-01-audit-agent-fixes`, `2026-07-01-audit-fixes`) non pertinenti a questo repo.
- **Attività incompleta**: gate 2b dello split (test su progetto host reale) aperto; `docs/test-progetto-host.md` dichiara esplicitamente che un progetto di test sintetico **non** lo chiude.
- **Sconosciuto**: `AGENTS.md` (5948 byte, `# Linee guida per Codex`) e `.agents/skills/` con 14 sottocartelle che rispecchiano `.claude/skills/` — inclusi i 4 `dr-scaffold*` creati in questa sessione. Timestamp 2026-08-08 14:30. Non prodotti da azioni dichiarate in questa sessione; origine e meccanismo di generazione non verificati. Entrambi untracked.

---

# TODO

1. Committare il lavoro della sessione (16 percorsi elencati in "File modificati") e pushare su `origin/main`, così il catalogo arriva ai progetti host e il `[WARN]` sparisce
2. Verificare che il job CI `catalog-guard` passi sul remoto dopo il push
3. Eseguire `/dr-scaffold` su una cartella vuota reale in una **sessione nuova** (le skill si caricano all'avvio) e registrare l'esito
4. Chiarire l'origine di `AGENTS.md` e `.agents/skills/`: decidere se committarli, ignorarli o rimuoverli
5. Eseguire il gate 2b: installare i pacchetti su un progetto host reale esistente seguendo `docs/test-progetto-host.md`, poi valutare il flip Private → Public
6. Riscrivere `docs/onboarding.md` sezioni 3-4 sul modello a pacchetti (`/dr-professor`)
7. Migrare `setup.ps1 -GlobalInstall`/`-GlobalUpdate` a `install.ps1`
8. Decidere su `.claude/skills/dr-handoff/skill.md.original.md` e sui 3 piani ereditati in `.ai/plans/`
9. Fasi 7-8 dello split: archiviazione di `davraf-guidelines`, migrazione progetti host

---

# Validazione

Il repo contiene documentazione, catalogo JSON, workflow e script PowerShell: non ha una build applicativa né una suite di test propria.

- Build: Sconosciuto per il repo. In sessione è stata eseguita una build di verifica su una solution usa-e-getta nello scratchpad (`dotnet build demo.slnx`): `Avvisi: 0  Errori: 0`
- Test: Sconosciuto (nessun test automatico nel repo)
- Lint: Sconosciuto per il repo. In sessione `dotnet format --verify-no-changes` è stato eseguito su progetti di prova, non sul repo

Verifiche osservate in sessione (output visibile in conversazione):

- Catalogo ↔ registry: chiavi identiche (`identici: True`), nessuna divergenza su `repo`/`isCore`/`dependencies`
- Script della guardia CI eseguito in locale: exit `0` sul catalogo reale, exit `1` alterando due nomi pacchetto, con messaggi puntuali
- `ci.yml` validato con parser YAML: `jobs: ['build-and-test', 'catalog-guard']`, 2 step nel nuovo job
- Installer reale su host .NET di prova: `[OK]` su tutti i file, `Directory.Build.props` e `global.json` copiati, `CLAUDE.md` creato, manifest scritto
- Installer reale su host non-.NET di prova: `[SKIP] Directory.Build.props, global.json (host non .NET)`, i due file assenti su disco
- Secondo run dell'installer: tutti `[SKIP]`, `[SKIP] Sezione dr-guidelines gia presente in CLAUDE.md`, manifest con una sola voce
- `dotnet new sln` su SDK `10.0.302`: default `slnx` (opzione `-f, --format <sln|slnx>`, "Impostazione predefinita: slnx")
- `dotnet sln <file>.slnx add`: progetti aggiunti, solution folder `/src/` e `/test/` generate automaticamente
- `create-vue@3.23.0`: `--vitest=false` fallisce con `ERR_PARSE_ARGS_INVALID_OPTION_VALUE`; con soli flag booleani lo scaffold riesce e produce `.editorconfig`/`.gitignore`/`.gitattributes` propri
- `dotnet format`: prima BOM `239,187,191` e `error CHARSET` con exit `2`; dopo il format in scrittura BOM rimosso e `--verify-no-changes` exit `0`
- Grep sul prompt duale: nessuna occorrenza di `$ARGUMENTS`, `AskUserQuestion`, `EnterPlanMode`, `subagent`, `INPUT_UTENTE`
- Grep su `CreateNewSolution` (esclusi `.ai/` e `.git/`): nessun riferimento residuo
- Ambiente: `dotnet 10.0.302`, `node v26.5.0`, `npm 10.7.0`, `git 2.46.2.windows.1`, `pwsh 7.6.3`, `gh 2.89.0` autenticato come `davraf-amuro` con scope `repo`

---

# Rischi

- Il lavoro non è committato: una perdita del working tree annullerebbe la sessione. `CreateNewSolution.ps1` è eliminato solo nel working tree (recuperabile con `git checkout -- CreateNewSolution.ps1` finché la cancellazione non è committata)
- Finché il catalogo non è su `origin/main`, ogni installazione su progetto host non lo riceve e le skill dipendono dal fallback sul clone locale di `dr-guidelines`
- Il job `catalog-guard` non è mai stato eseguito su GitHub Actions: verificato solo in locale con `pwsh`. Il dot-source di `install-lib.ps1` su runner Linux non è stato provato
- `AGENTS.md` e `.agents/skills/` di origine non verificata: se un meccanismo li rigenera automaticamente, potrebbe sovrascrivere modifiche manuali
- Il flusso completo di `/dr-scaffold` non è stato eseguito end-to-end: eventuali errori di orchestrazione emergeranno al primo uso reale
- I repo Private mantengono `/dr-get-latest` non funzionante: gli aggiornamenti richiedono la sequenza manuale `install.ps1 -Update` da path locale

---

# Prossimo passo consigliato

Committare il lavoro della sessione e pushare su `origin/main`, così `scaffolding-catalog.json` diventa disponibile ai progetti host e il job `catalog-guard` viene eseguito per la prima volta su GitHub Actions.

---

# Informazioni mancanti

- Origine e meccanismo di generazione di `AGENTS.md` e `.agents/skills/`
- Se esiste un progetto host reale già individuato per il gate 2b
- Se i 7 repo devono passare a Public e con quale tempistica
