# Piano: split multi-repo `davraf-guidelines` → `dr-guidelines` + pacchetti dominio

**Data:** 2026-07-22
**Skill/persona:** `/tech` (Ops)
**Stato:** IN CORSO — fasi 1-4 completate, si riprende da fase 5
**Nota:** copia attiva del piano, migrata da `e:\Davide\Progetti\davraf-guidelines\.ai\plans\2026-07-22-dr-guidelines-split\plan.md` — il lavoro prosegue da questo repo (`dr-guidelines` core, dentro il workspace multi-repo), non più dal repo originale.

## Obiettivo

1. Rinominare repo `davraf-guidelines` → `dr-guidelines`.
2. Smembrare contenuti (istruzioni, skill, prompt) in repo separati per dominio di competenza, così un progetto host installa solo i pacchetti che gli servono.
3. Sostituire il meccanismo di distribuzione a git submodule con installer standalone per pacchetto (nessun `.gitmodules` nel progetto host).
4. Aggiungere una skill per segnalare miglioria/aprire issue sul repo pacchetto pertinente in modo guidato.

## Perimetro

**Dentro:** naming, mappatura contenuti → pacchetti, disegno meccanismo installazione, disegno skill segnalazione, fasi di migrazione ad alto livello.

**Fuori (richiede conferma separata prima di eseguire):**
- Migrazione dei progetti host già esistenti che oggi usano il submodule (piano separato, dopo pilota)
- Sistema di release/versionamento semver completo (rimandato: si parte con "sempre latest", vedi Decisioni)

## Stato attuale rilevato (fonte: esplorazione repo 2026-07-22, prima dello split)

- **Skill** (`.claude/skills/`, 11): CreateLaunchProfiles, audit-api, audit-fe, get-latest, handoff, professor, promote-to, snapshot, tattico, tech, warroom.
- **Instructions** (`.github/instructions/*.md`, 19): code-organization, database-provider, database-startup-resilience, dev-cycle, doc-versioning, docker-swarm-compose, frontend-organization, gitlab-ci-cd, input-validation, logging, mcp-server-discovery, mcp-tool-readme, minimal-api-architecture, plan-tracking, portainer-swarm-stack, readme-structure, sensitive-data, windows-service.
- **Prompts** (`.github/prompts/*.prompt.md`, 7): card-minimal-api, card-project-generator, card-wiki-generator, card-worker-service, endpoints-analyzer, onboarding-senior, readme-generator.
- **Distribuzione originale**: `git submodule add https://github.com/davraf-amuro/davraf-guidelines.git davraf-guidelines` + `.\davraf-guidelines\setup.ps1`. Copiava (non linkava) file root, `.github/instructions`, `.github/prompts`, `.claude/skills/*`, merge sezione marcata in `CLAUDE.md` host.
- Nessun `LICENSE`, `CHANGELOG.md`, o issue-tracker referenziato nell'originale. Remote originale: `github.com/davraf-amuro/davraf-guidelines`.

## Decisioni confermate con l'utente (2026-07-22)

### 1. Naming e mappatura contenuti → pacchetti

- **`dr-guidelines`** (core, rinominato da `davraf-guidelines`) ← trasversale: `dev-cycle`, `plan-tracking`, `sensitive-data`, `input-validation`, `mcp-server-discovery`, `mcp-tool-readme`, `logging`, `code-organization`, `readme-structure`, `doc-versioning` + skill trasversali (dr-professor, dr-warroom, dr-tattico, dr-tech, dr-promote-to, dr-snapshot, dr-get-latest, dr-handoff, dr-CreateLaunchProfiles) + nuova skill `dr-segnala-miglioria` + installer orchestratore
- **`dr-minimalapi`** ← `minimal-api-architecture.instructions.md` + prompt `card-minimal-api`, `endpoints-analyzer`
- **`dr-winsvc`** ← `windows-service.instructions.md` + prompt `card-worker-service`
- **`dr-efdb`** ← `database-provider.instructions.md` + `database-startup-resilience.instructions.md`
- **`dr-fe`** ← `frontend-organization.instructions.md` + skill `dr-audit-fe`
- **`dr-devops`** ← `docker-swarm-compose.instructions.md`, `portainer-swarm-stack.instructions.md`, `gitlab-ci-cd.instructions.md`
- **`dr-dotnet-backend`** ← skill `dr-audit-api` (copre sia minimal-api sia windows-service via rilevamento runtime — pacchetto dedicato invece che nel core, per non forzare una dipendenza generica su un dominio specifico)

### 2. Dipendenza tra pacchetti
`dr-minimalapi` e `dr-winsvc` dichiarano dipendenza da `dr-dotnet-backend` (installer la installa automaticamente se assente).

### 3. Repo legacy `davraf-guidelines`
Dopo lo split: README con redirect ai nuovi repo, poi **archiviato** su GitHub (reversibile, nessuna cancellazione). Resta pienamente operativo; i progetti host che oggi lo usano come submodule non sono impattati fino a un'eventuale migrazione volontaria (fase 8).

### 4. Creazione repo GitHub
Creati da Claude via `gh` CLI (autenticato come `davraf-amuro`, scope `repo`), uno alla volta con conferma esplicita utente. Parametri:

| Repo | Descrizione |
|---|---|
| `dr-guidelines` | Linee guida trasversali e skill core per Claude Code / GitHub Copilot (dev-cycle, plan-tracking, sicurezza, documentazione) |
| `dr-minimalapi` | Linee guida e prompt per architettura Minimal API .NET |
| `dr-winsvc` | Linee guida e prompt per Windows Service .NET |
| `dr-efdb` | Linee guida per Entity Framework Core e provider database |
| `dr-fe` | Linee guida e audit per organizzazione frontend |
| `dr-devops` | Linee guida Docker Swarm, Portainer, CI/CD GitLab |
| `dr-dotnet-backend` | Skill di audit per backend .NET (Minimal API + Windows Service) |

Comuni a tutti: **Private** (temporaneo — vedi gate sotto), **licenza MIT**, branch default `main`.

**Gate visibilità Private → Public:** i 7 repo restano **Private** finché non è stato eseguito un test diretto dell'installer (`install.ps1`) su **almeno un progetto host reale esistente** (non una cartella di test sintetica). Solo dopo esito positivo si passa i repo a Public — necessario perché il meccanismo approvato (`irm https://raw.githubusercontent.com/.../install.ps1 | iex`) richiede repo pubblici per funzionare senza autenticazione. Durante la fase privata, i test si fanno con `git clone` autenticato (via `gh`/credential manager), non con l'`irm` pubblico.

### 5. Default non bloccanti (rivedibili in corso d'opera)
- Versionamento: nessun semver/release in fase 1, installer usa sempre branch `main` ("latest"); manifest host traccia solo `installedAt`.
- Skill `dr-segnala-miglioria`: solo Claude Code (esente da regola dual-agent per definizione in `CLAUDE.md`); equivalente Copilot solo se richiesto in futuro.

## Meccanismo di installazione (sostituto submodule)

Ogni pacchetto espone un `install.ps1` standalone, eseguibile senza clonare prima il repo:

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/dr-minimalapi/main/install.ps1 | iex
```

Comportamento:
1. Clona shallow in temp dir (o scarica release zip)
2. Se il pacchetto dichiara dipendenze (es. `dr-minimalapi` → `dr-dotnet-backend`) e non risultano nel manifest host, le installa prima
3. Copia file (skip esistenti, `-Update` per override — comportamento invariato rispetto all'originale)
4. Merge sezione marcata dedicata in `CLAUDE.md` host, es. `<!-- dr-minimalapi --> ... <!-- /dr-minimalapi -->` (marker per pacchetto → update/rimozione isolata)
5. Elimina temp dir — nessun `.gitmodules`, nessun riferimento submodule persistito

Manifest tracciamento nel progetto host, `.ai/dr-guidelines-packages.json`:
```json
{
  "installed": [
    { "package": "dr-guidelines", "installedAt": "2026-07-22" },
    { "package": "dr-minimalapi", "installedAt": "2026-07-22" },
    { "package": "dr-dotnet-backend", "installedAt": "2026-07-22" }
  ]
}
```
Usi: `/dr-get-latest` sa quali pacchetti aggiornare; skill `dr-segnala-miglioria` sa in quale repo aprire issue.

## Nuova skill `dr-segnala-miglioria` (in `dr-guidelines` core)

- Legge `.ai/dr-guidelines-packages.json` per capire a quale repo pacchetto appartiene il file segnalato (chiede se ambiguo)
- Compone titolo/corpo issue, li mostra per conferma esplicita — mai invio automatico
- Se confermato: `gh issue create --repo davraf-amuro/<pacchetto> --title ... --body ...`
- Fallback senza `gh` autenticato: genera URL precompilato `.../issues/new?title=...&body=...` da aprire manualmente

## Workspace locale di sviluppo (autoring, non riguarda i progetti consumer)

I 7 repo restano indipendenti (proprio `.git`, proprio remote ciascuno) — niente submodule/monorepo per l'autoring. Cartella padre normale (non un repo git) con i 7 clone come sottocartelle sorelle + file `dr-guidelines.code-workspace` (VS Code multi-root workspace), già creati:

```
E:\Davide\Progetti\dr-guidelines-workspace\        ← cartella normale, NON è un repo git
├── dr-guidelines\            ← QUESTO REPO, contiene questo piano
├── dr-minimalapi\
├── dr-winsvc\
├── dr-efdb\
├── dr-fe\
├── dr-devops\
├── dr-dotnet-backend\
└── dr-guidelines.code-workspace
```

Apertura: `code dr-guidelines.code-workspace`.

## Fasi

- [x] 1. Conferma naming, mappatura, decisioni — **completato 2026-07-22**
- [x] 2. Creazione dei 7 repo via `gh CLI` (Private, MIT) + clone in `E:\Davide\Progetti\dr-guidelines-workspace\` + `.code-workspace` — **completato 2026-07-22**
- [ ] 2b. Gate: repo restano Private finché test diretto `install.ps1` su ≥1 progetto host reale non ha esito positivo → poi flip a Public
- [x] 3. Estrazione contenuti con history (`git filter-repo`) da `davraf-guidelines` verso ciascun repo nuovo — **completato 2026-07-22**: pilota `dr-minimalapi` validato (clone `--no-local` → filter-repo per path → merge `--allow-unrelated-histories` con LICENSE remoto → push → sync clone locale), poi replicato su `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`, `dr-dotnet-backend` (keep-path) e `dr-guidelines` core (invert-paths, tutto tranne i 13 path assegnati ai 6 pacchetti dominio). Tutti e 7 i repo pushati e sincronizzati nel workspace locale, nessuna history persa, nessun force-push usato.
  - Nota housekeeping (non bloccante, da valutare in fase 6): `dr-guidelines` core ha ereditato anche `.claude/skills/dr-handoff/skill.md.original.md` (backup file già presente nell'originale) e i vecchi `.ai/plans/*` della repo originale — nessuna azione richiesta ora.
- [x] 4. Scrittura `install.ps1` per pacchetto (con gestione dipendenze) + formato manifest `.ai/dr-guidelines-packages.json` + aggiornamento `/dr-get-latest` — **completato 2026-07-22**

  ### Decisioni di scope fase 4 (confermate con l'utente 2026-07-22)
  - Asset di scaffolding del repo core (`CreateNewSolution.ps1`, `.template.config/`, `templates/global-claude.md`) **non entrano** nel meccanismo di installazione — restano tooling ad uso esclusivo di `dr-guidelines` (dotnet template, installazione globale manuale). Nessun impatto su install.ps1.
  - Feature `-GlobalInstall`/`-GlobalUpdate` (scrittura `~/.claude/CLAUDE.md`) del vecchio `setup.ps1` **rimandata**: non implementata in fase 4, resta TODO separato da valutare dopo il gate Private→Public.

  ### Design meccanismo (derivato da analisi contenuto reale dei 7 repo)
  - Verificato: i pacchetti dominio (es. `dr-minimalapi`) contengono solo `.github/instructions/*`, `.github/prompts/*.prompt.md` e/o `.claude/skills/*/`; nessun CLAUDE.md proprio. Solo `dr-guidelines` core ha file di config radice (`.editorconfig`, `Directory.Build.props`, `global.json`, `.gitignore`, `.gitattributes`, `.mcp.example.json`) e sezione `CLAUDE.md` da mergiare.
  - Conseguenza: **nessun file-manifest per pacchetto necessario** — la copia è generica: "copia tutto ciò che esiste in `.github/instructions`, `.github/prompts`, `.claude/skills` nel clone del pacchetto"; per il core si aggiunge copia file di config radice + merge sezione `CLAUDE.md` (marker `<!-- dr-guidelines -->` / `<!-- /dr-guidelines -->`).
  - Libreria condivisa `install-lib.ps1` (in `dr-guidelines` core, root) contiene:
    - `$Script:PackageRegistry` — tabella statica `{PackageName -> {Repo, IsCore, Dependencies[]}}`, unica fonte di verità per tutti e 7 i pacchetti (aggiungere qui un pacchetto futuro = unica modifica necessaria)
    - `Install-DrPackage -PackageName -Update` — orchestratore: risolve dipendenze mancanti (lookup manifest host, richiama sé stessa ricorsivamente se assente, senza propagare `-Update` alle dipendenze auto-installate), clona shallow (`git clone --depth 1`) il repo in temp dir, copia genericamente instructions/prompts/skills (skip-esistenti salvo `-Update`, stessa semantica del vecchio `setup.ps1`), se `IsCore` copia anche config radice + merge `CLAUDE.md`, aggiorna `.ai/dr-guidelines-packages.json` (upsert `{package, installedAt}`), rimuove temp dir
  - Ogni pacchetto ha un `install.ps1` thin wrapper (~10 righe, quasi identico tra i 7): tenta `irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/install-lib.ps1 | iex`; se fallisce (repo Private, no auth — limite noto gate 2b) e lo script gira da un path locale (`$PSScriptRoot` valorizzato, cioè invocazione diretta non da `iex`), fallback a dot-source del clone locale del workspace (`dr-guidelines\install-lib.ps1` sibling); poi chiama `Install-DrPackage -PackageName "<nome>" -Update:$Update`.
  - Manifest host `.ai/dr-guidelines-packages.json` — schema invariato da quanto già approvato: `{"installed":[{"package":"...", "installedAt":"YYYY-MM-DD"}]}`.
  - `/dr-get-latest` riscritta: legge il manifest host, per ciascun pacchetto tracciato ri-esegue il relativo `install.ps1` con `-Update` (stesso meccanismo di fetch usato in installazione, niente più submodule/diff-guard — coerente col default già approvato "sempre latest su main").

  ### Fasi atomiche
  - [x] 4.1 — CREATE `dr-guidelines/install-lib.ps1` (registry + funzioni condivise + orchestratore `Install-DrPackage`) — **completato 2026-07-22**
  - [x] 4.2 — CREATE `dr-guidelines/install.ps1` (thin wrapper, `PackageName="dr-guidelines"`) — **completato 2026-07-22**
  - [x] 4.3 — CREATE `install.ps1` per `dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`, `dr-dotnet-backend` (thin wrapper, stesso template, `PackageName` variabile) — **completato 2026-07-22**
  - [x] 4.4 — EDIT `dr-guidelines/.claude/skills/dr-get-latest/SKILL.md` (riscrittura per modello manifest multi-pacchetto, rimuove riferimenti a submodule/`setup.ps1`) — **completato 2026-07-22**
  - [x] 4.5 — Test locale end-to-end (cartella di prova fuori workspace) — **completato 2026-07-22**: `dr-minimalapi` → dipendenza `dr-dotnet-backend` installata automaticamente, file instructions/prompts/skills copiati correttamente; skip senza `-Update` verificato (dipendenza già presente non reinstallata); `-Update` verificato con sovrascrittura di una modifica locale di test; percorso core `dr-guidelines` verificato separatamente (config radice + creazione/merge/skip/update sezione `<!-- dr-guidelines -->` in `CLAUDE.md`, contenuto host fuori marker preservato in entrambi i casi). Manifest `.ai/dr-guidelines-packages.json` corretto in ogni scenario.
  - [x] 4.6 — Commit su ciascuno degli 7 repo interessati (non push, gate lint + conferma utente restano validi per fase push) — **completato 2026-07-22**: `dr-guidelines` (`install-lib.ps1`, `install.ps1`, `dr-get-latest/SKILL.md`), 6× pacchetti dominio (`install.ps1`). Nessun push eseguito.

  **Fase 4 completata 2026-07-22.**
  Nota housekeeping (non bloccante): cartella `TODO/01-install-scaffholding.md` trovata non tracciata in `dr-guidelines` durante questa fase — nota utente su un'idea futura (scaffolding interattivo a prompt per workspace/solution/progetti), non toccata, fuori scope fase 4, segnalata all'utente.
- [ ] 5. Nuova skill `dr-segnala-miglioria` in `dr-guidelines` core — **prossimo passo**

  ### Decisioni di scope (confermate con l'utente 2026-07-22)
  - Cleanup housekeeping (3 cartelle `.ai/plans/*` non pertinenti + `.claude/skills/dr-handoff/skill.md.original.md`): **fatto ora**, in fase 6, commit dedicato
  - Gate 2b (Private→Public) e fase 7 (archiviazione `davraf-guidelines`): **rimandati** — nessun progetto host reale disponibile in questa sessione per il test richiesto dal gate

  ### Fasi atomiche
  - [ ] 5.1 — CREATE `dr-guidelines/.claude/skills/dr-segnala-miglioria/SKILL.md` (legge manifest host per determinare il pacchetto, compone titolo/corpo, conferma esplicita obbligatoria, `gh issue create` o URL precompilato di fallback)

- [ ] 6. README per ciascun pacchetto + aggiornamento README core

  ### Analisi preliminare
  - `README.md` core esistente è interamente tarato sul vecchio modello (submodule + `setup.ps1`, repo `davraf-guidelines`) — da riscrivere per il nuovo modello `install.ps1`
  - `.github/instructions/readme-structure.instructions.md` (struttura obbligatoria del README, `applyTo: "README.md"`) è anch'essa tarata sul vecchio modello: sezione 3 (Progetto Esistente) e sezione 5 (Aggiornare) descrivono submodule/setup.ps1; **nessuna sezione prevista per la famiglia di pacchetti dr-*** — gap strutturale emerso dallo split, non presente al momento in cui l'istruzione fu scritta
  - `CreateNewSolution.ps1` (sezione 2 "Avvio Rapido") resta **invariato** per decisione già presa (fase 4) — punta ancora al repo legacy `davraf-guidelines` (submodule+setup.ps1), che resta valido finché non archiviato in fase 7: nessuna modifica necessaria a questa sezione ora

  ### Fasi atomiche
  - [ ] 6.1 — EDIT `dr-guidelines/.github/instructions/readme-structure.instructions.md`: aggiunta sezione "Pacchetti dr-* disponibili" (tabella nome/repo/scope) dopo titolo+tagline; sezione 3 e 5 riscritte per `install.ps1`/`-Update`/`/dr-get-latest` (non più submodule/setup.ps1); note sezioni 6-7 aggiornate per riflettere che ora descrivono solo il contenuto **core** (i pacchetti dominio hanno le proprie istruzioni/skill, non più nel core)
  - [ ] 6.2 — EDIT `dr-guidelines/README.md`: riscritto secondo la struttura aggiornata al passo 6.1
  - [ ] 6.3 — CREATE `README.md` per `dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`, `dr-dotnet-backend` (titolo+tagline, install/update via `irm`/scriptblock, nota dipendenza se presente, tabella contenuto instructions/prompts/skills, footer stile `readme-structure`)
  - [ ] 6.4 — DELETE `dr-guidelines/.ai/plans/2026-06-17-global-install/`, `.ai/plans/2026-07-01-audit-agent-fixes/`, `.ai/plans/2026-07-01-audit-fixes/` (non pertinenti al nuovo repo, ereditati da filter-repo)
  - [ ] 6.5 — DELETE `dr-guidelines/.claude/skills/dr-handoff/skill.md.original.md` (file di backup ereditato)
  - [ ] 6.6 — Commit su ciascuno dei 7 repo interessati (non push, gate lint + conferma restano validi per fase push)
- [ ] 7. Deprecazione repo vecchio `davraf-guidelines` (redirect + archive)
- [ ] 8. Piano di migrazione progetti host esistenti (separato, dopo pilota su 1 progetto)

## Rollback

- Fasi 1-6 sono additive: nessuna modifica distruttiva al repo originale. Rollback = non procedere alla fase successiva, repo `davraf-guidelines` resta operativo invariato.
- Fase 7 (archive GitHub) è reversibile: un repo archiviato si può de-archiviare, nessuna cancellazione dati.

## Punti di verifica

- Dopo fase 3: `git log --follow` sul repo estratto mostra history preservata per i file del dominio migrato. **Verificato.**
- Dopo fase 4: `install.ps1` testato su un progetto host di prova — file copiati = attesi, dipendenza `dr-dotnet-backend` installata automaticamente dove serve, merge `CLAUDE.md` corretto, nessun `.gitmodules`, manifest scritto correttamente.
- Dopo fase 5: skill genera issue/URL puntando al repo pacchetto corretto per almeno un caso per dominio.
- Dopo fase 7: repo vecchio raggiungibile ma archiviato, README rimanda ai nuovi repo.
