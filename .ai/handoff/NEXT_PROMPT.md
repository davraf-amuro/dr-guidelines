# Prompt per riprendere il lavoro

Rispondi sempre in italiano.

## Contesto progetto

Repo: `dr-guidelines` (`davraf-amuro/dr-guidelines`, Private), pacchetto **core** della suite `dr-*`: istruzioni modulari, prompt e skill per Claude Code e GitHub Copilot, distribuiti come pacchetti installabili via PowerShell. Nessun codice applicativo, nessuna build, nessun test.

Percorso locale: `E:\Davide\Progetti\dr-guidelines-workspace\dr-guidelines`. Workspace multi-root con i 7 repo come cartelle sorelle: `dr-guidelines`, `dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`, `dr-dotnet-backend`.

Vincoli di progetto (in `CLAUDE.md`):
- ogni regola condivisa deve funzionare sia su Claude Code sia su GitHub Copilot; esenzione solo per `.claude/skills/`
- task con ≥ 2 operazioni: piano su disco in `.ai/plans/<YYYY-MM-DD>-<slug>/plan.md` prima di agire
- nessun `git push` senza lint clean
- file in `docs/` richiedono footer `*Revisione v{N} — {YYYY-MM-DD HH:MM} — {modello}*`

Meccanismo pacchetti: `install.ps1` (thin wrapper) → `install-lib.ps1` espone `Install-DrPackage`, che clona il pacchetto da GitHub in una temp dir, copia i file usando `(Get-Location).Path` come root host, mergia una sezione marcata in `CLAUDE.md` e aggiorna `.ai/dr-guidelines-packages.json`.

I repo sono Private: `irm ... | iex` risponde 404. Unica modalità funzionante: `& <workspace>\dr-<pkg>\install.ps1` da path locale, con `Push-Location` sulla root del repo host.

## Obiettivo

Chiudere la sessione precedente portando in remoto il sistema di scaffolding appena implementato, poi proseguire con il gate 2b dello split (test su progetto host reale, quindi valutazione del flip Private → Public).

## Stato corrente

Sistema di scaffolding implementato e verificato in locale, **non committato**. Piano `.ai/plans/2026-08-08-scaffolding-skills/plan.md` con `Stato: COMPLETATO`.

Creati:
- `scaffolding-catalog.json` — 5 tipologie di progetto, 7 pacchetti, blocco `defaults`
- `.claude/skills/dr-scaffold/SKILL.md` — router: gate prerequisiti, rilevamento stato cartella, delega
- `.claude/skills/dr-scaffold-solution/SKILL.md`
- `.claude/skills/dr-scaffold-project/SKILL.md`
- `.claude/skills/dr-scaffold-guidelines/SKILL.md`
- `.github/prompts/dr-scaffold.prompt.md` — equivalente per Copilot, sezioni A/B/C

Modificati: `install-lib.ps1` (`Test-DotnetHost` + copia condizionale di `Directory.Build.props`/`global.json`; `Copy-ScaffoldingCatalog` → `.ai/dr-scaffolding-catalog.json`), `.github/workflows/ci.yml` (job `catalog-guard`), `README.md`, `CLAUDE.md`, `.github/instructions/readme-structure.instructions.md`, `docs/card-davraf-guidelines.md`, `docs/onboarding.md`, `docs/test-progetto-host.md`.

Eliminato: `CreateNewSolution.ps1` (solo nel working tree). `setup.ps1` e `templates/global-claude.md` intatti per scelta.

Verificato in sessione: catalogo allineato al registry; guardia CI exit `0` sul catalogo reale e `1` su catalogo alterato; installer reale su host .NET e non-.NET conforme; secondo run tutti `[SKIP]`; `dotnet new sln` ha default `slnx` su SDK `10.0.302`; `dotnet format` rimuove il BOM e porta `--verify-no-changes` a exit `0`.

Ambiente: `dotnet 10.0.302`, `node v26.5.0`, `npm 10.7.0`, `git 2.46.2`, `pwsh 7.6.3`, `gh 2.89.0` autenticato come `davraf-amuro` con scope `repo`.

## File rilevanti

- `.ai/plans/2026-08-08-scaffolding-skills/plan.md` — piano completato, consuntivo per fase, limiti noti, lavoro residuo
- `.ai/handoff/HANDOFF.md` — stato, problemi aperti, TODO ordinati, rischi
- `.ai/handoff/DECISIONI.md` — decisioni con contesto, motivazione e conseguenze
- `.ai/plans/2026-07-22-dr-guidelines-split/plan.md` — piano dello split multi-repo, fasi 7-8 e gate 2b aperti
- `docs/test-progetto-host.md` — procedura di test del meccanismo pacchetti
- `install-lib.ps1` — registry pacchetti e `Install-DrPackage`
- `scaffolding-catalog.json` — catalogo tipologie e pacchetti
- `TODO/01-install-scaffholding.md` — specifica originale dello scaffolding, implementata

## Problemi aperti

- Nessun commit eseguito: tutto il lavoro è nel working tree
- `scaffolding-catalog.json` non è su `origin/main` → l'installer stampa `[WARN] scaffolding-catalog.json non trovato nel pacchetto core` e le skill ripiegano sul catalogo nel clone locale
- Job `catalog-guard` mai eseguito su GitHub Actions: il dot-source di `install-lib.ps1` su runner Linux è verificato solo in locale
- Flusso completo di `/dr-scaffold` non eseguito end-to-end su una cartella vuota reale
- `AGENTS.md` (`# Linee guida per Codex`) e `.agents/skills/` con 14 sottocartelle che rispecchiano `.claude/skills/`, timestamp 2026-08-08 14:30, untracked: origine e meccanismo di generazione Sconosciuti
- `/dr-get-latest` non funziona con repo Private: usa `Invoke-RestMethod` senza fallback locale
- `docs/onboarding.md` sezioni 3-4 descrivono ancora il modello a submodule `davraf-guidelines`
- `.claude/skills/dr-handoff/` usa `skill.md` minuscolo e contiene `skill.md.original.md`, a differenza delle altre 13 skill
- `.ai/plans/` contiene 3 piani ereditati dal repo originale, non pertinenti
- Gate 2b dello split aperto: `docs/test-progetto-host.md` dichiara che un progetto sintetico non lo chiude

## Prossimo passo

Committare il lavoro della sessione e pushare su `origin/main`, verificando prima che nessun file contenga credenziali e che la cancellazione di `CreateNewSolution.ps1` sia intenzionale. Dopo il push, controllare l'esito del job `catalog-guard` su GitHub Actions.
