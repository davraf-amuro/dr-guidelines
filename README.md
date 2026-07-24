# dr-guidelines

Pacchetto core della suite `dr-*`: linee guida trasversali, skill Claude Code e meccanismo di installazione per progetti .NET 10 integrati con GitHub Copilot e Claude Code.

## 🧩 Pacchetti dr-* disponibili

`dr-guidelines` (questo repo) è il core della suite. I contenuti specifici di dominio vivono in 6 pacchetti separati, installabili singolarmente in base allo stack del progetto:

| Pacchetto | Repo | Scope |
|---|---|---|
| **dr-guidelines** (core) | [davraf-amuro/dr-guidelines](https://github.com/davraf-amuro/dr-guidelines) | Istruzioni/skill trasversali, meccanismo di installazione (`install.ps1`) |
| dr-minimalapi | [davraf-amuro/dr-minimalapi](https://github.com/davraf-amuro/dr-minimalapi) | Architettura Minimal API .NET, prompt endpoint/scaffolding. Dipende da `dr-dotnet-backend` |
| dr-winsvc | [davraf-amuro/dr-winsvc](https://github.com/davraf-amuro/dr-winsvc) | Windows Service .NET. Dipende da `dr-dotnet-backend` |
| dr-efdb | [davraf-amuro/dr-efdb](https://github.com/davraf-amuro/dr-efdb) | Entity Framework Core, provider database, resilienza avvio |
| dr-fe | [davraf-amuro/dr-fe](https://github.com/davraf-amuro/dr-fe) | Organizzazione frontend + audit |
| dr-devops | [davraf-amuro/dr-devops](https://github.com/davraf-amuro/dr-devops) | Docker Swarm, Portainer, CI/CD GitLab |
| dr-dotnet-backend | [davraf-amuro/dr-dotnet-backend](https://github.com/davraf-amuro/dr-dotnet-backend) | Skill di audit backend .NET (Minimal API + Windows Service) |

Le dipendenze dichiarate (`dr-minimalapi`/`dr-winsvc` → `dr-dotnet-backend`) vengono installate automaticamente da `install.ps1` se assenti.

> **Nota:** i 7 repo sono attualmente **Private**. `install.ps1` funziona comunque via `git clone` autenticato (credential manager); il bootstrap pubblico `irm ... | iex` richiede repo Public — passaggio pianificato dopo un test su un progetto host reale.

---

## 🚀 Avvio Rapido — Nuovo Progetto

Apri **PowerShell** (utente normale, senza admin) ed esegui:

```powershell
# 1. Scarica lo script
irm https://raw.githubusercontent.com/davraf-amuro/davraf-guidelines/main/CreateNewSolution.ps1 -OutFile CreateNewSolution.ps1
# 2. Ispeziona il contenuto (mai eseguire script remoti alla cieca)
# 3. Esegui
.\CreateNewSolution.ps1
```

Lo script:
1. Chiede il **nome del progetto** tramite finestra di dialogo
2. Apre un **folder picker** nativo per scegliere la cartella di destinazione
3. Crea la cartella `<destinazione>/<nome-progetto>/`
4. Aggiunge `davraf-guidelines` come **git submodule** (o scarica ZIP se git non è disponibile)
5. Esegue `setup.ps1` che copia i file di configurazione nel progetto

> `CreateNewSolution.ps1` non è ancora stato migrato al nuovo modello a pacchetti (`install.ps1`): resta legato al repo legacy `davraf-guidelines`, tuttora attivo e non archiviato. Per un progetto nuovo con i pacchetti `dr-*`, crea la solution manualmente e segui la sezione successiva.

---

## 🔧 Progetto Esistente — Aggiungere le Guidelines

Se hai già un progetto con repository git, esegui dalla **root del progetto**:

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/install.ps1 | iex
```

Installa il pacchetto core: file di configurazione, istruzioni/skill trasversali, sezione `<!-- dr-guidelines -->` in `CLAUDE.md`. Sicuro su progetti esistenti: salta i file già presenti (`[SKIP]`), non sovrascrive nulla senza `-Update` esplicito.

Per aggiungere anche un pacchetto dominio (es. Minimal API), esegui il suo `install.ps1` allo stesso modo — vedi la tabella nella sezione [Pacchetti dr-* disponibili](#-pacchetti-dr--disponibili):

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/dr-minimalapi/main/install.ps1 | iex
```

Ogni installazione viene tracciata in `.ai/dr-guidelines-packages.json` nel progetto host.

---

## 📦 Cosa viene configurato

Dopo l'esecuzione di `install.ps1` (pacchetto core), il progetto host avrà:

| File/Cartella | Provenienza | Scopo |
|---------------|-------------|-------|
| `.editorconfig` | copia | Stile di codice e naming conventions |
| `Directory.Build.props` | copia | Configurazione MSBuild centralizzata (.NET 10, Nullable) |
| `global.json` | copia | Versione .NET SDK |
| `.gitignore` | copia | File ignorati da Git |
| `.gitattributes` | copia | Normalizzazione line endings |
| `.mcp.json` | copia da `.mcp.example.json` (solo se assente, mai sovrascritto) | Server MCP consigliati |
| `.github/instructions/`, `.github/prompts/` | copia file per file | Istruzioni Copilot/Claude e prompt modulari (contenuto core) |
| `.claude/skills/` | copia cartella per cartella | Skill Claude Code core (dr-warroom, dr-professor, dr-tattico, dr-tech, dr-get-latest, dr-segnala-miglioria, ecc.) |
| `CLAUDE.md` | generato / merge | Sezione `<!-- dr-guidelines --> ... <!-- /dr-guidelines -->` iniettata/aggiornata automaticamente, resto del file preservato |
| `.ai/dr-guidelines-packages.json` | generato / upsert | Manifest dei pacchetti `dr-*` installati nel progetto |

I pacchetti dominio installano solo `.github/instructions/`, `.github/prompts/` e/o `.claude/skills/` propri — nessun file di configurazione radice, nessuna sezione `CLAUDE.md` (esclusiva del core).

---

## 🔄 Aggiornare le Guidelines

**Un singolo pacchetto:**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/install.ps1))) -Update
```

Il flag `-Update` sovrascrive i file già presenti con la versione corrente del pacchetto e ri-mergia la sezione `CLAUDE.md` (per il core). Sostituisci l'URL con quello del pacchetto dominio da aggiornare.

**Tutti i pacchetti tracciati nel progetto:**

```
/dr-get-latest
```

Legge `.ai/dr-guidelines-packages.json` e ri-esegue `install.ps1 -Update` per ciascun pacchetto elencato.

**Installazione globale (legacy, non ancora migrata):**

```powershell
cd C:\tools\davraf-guidelines   # clone stabile del repo legacy
git pull
.\setup.ps1 -GlobalUpdate
```

`setup.ps1 -GlobalInstall`/`-GlobalUpdate` (scrittura di `~/.claude/CLAUDE.md`, indipendente dal progetto) resta disponibile ma non è ancora stata portata nel nuovo `install.ps1` — TODO aperto.

---

## 🤖 Istruzioni Modulari (Copilot / Claude)

Contenuto **core**, trasversale a qualsiasi stack. Le istruzioni specifiche di dominio (Minimal API, Windows Service, EF Core, frontend, DevOps) vivono nei rispettivi pacchetti — vedi la tabella in [Pacchetti dr-* disponibili](#-pacchetti-dr--disponibili).

| File | Quando usarlo |
|------|---------------|
| `.github/copilot-instructions.md` | Istruzioni principali — letto automaticamente da Copilot |
| `dev-cycle.instructions.md` | Ciclo obbligatorio per ogni task AI: dichiara, esegui, verifica |
| `plan-tracking.instructions.md` | Piano su disco in `.ai/plans/<YYYY-MM-DD>-<slug>/` per ogni task con ≥ 2 operazioni, formato atomico |
| `code-organization.instructions.md` | Struttura classi e file, commenti obbligatori (tutti i linguaggi) |
| `input-validation.instructions.md` | Validazione obbligatoria di ogni input esterno con `IValidator<T>` |
| `logging.instructions.md` | Logging strutturato con placeholder (mai string interpolation) |
| `sensitive-data.instructions.md` | Gestione credenziali e dati sensibili |
| `doc-versioning.instructions.md` | Footer di revisione obbligatorio nei documenti in `docs/` |
| `readme-structure.instructions.md` | Struttura obbligatoria di questo README |
| `mcp-tool-readme.instructions.md` | Creazione README per MCP server (`tools/**/README.md`) |
| `mcp-server-discovery.instructions.md` | Ricerca e creazione MCP server (cerca prima di creare) |

---

## 🤖 Claude Code Skills

Skill **core**, disponibili dopo l'installazione di `dr-guidelines`.

### `/dr-warroom` — Tavolo di Lavoro Multi-Agente

Lancia 5 esperti in parallelo (ARCH, BE, UI, UX, DBADMIN) per analizzare una domanda tecnica o di prodotto da più angolazioni.

**Uso:**
```
/dr-warroom come strutturiamo l'autenticazione in questa Minimal API?
```

### `/dr-professor` — Redazione Documentazione

Crea, aggiorna e revisiona documentazione tecnica con linguaggio chiaro e accessibile, rispettando le instruction files del progetto.

**Uso:**
```
/dr-professor aggiorna la documentazione del progetto
```

### `/dr-tattico` — Progettazione Prompt AI

Crea o revisiona prompt per agenti/assistenti IA, analizza pattern di fallimento e ambiguità.

**Uso:**
```
/dr-tattico rivedi il prompt di sistema dell'agente di onboarding
```

### `/dr-tech` — Rilascio e Infrastruttura

Specialista di deployment e infrastruttura IT: Docker, IIS, Git, Swagger/OpenAPI, preparazione ambienti.

**Uso:**
```
/dr-tech pianifica il rilascio della nuova versione su Docker Swarm
```

### `/dr-promote-to` — Commit, Push e Pull Request

Promuove il branch corrente verso un branch target: commit delle modifiche pendenti (se presenti), push, apertura PR. Chiede sempre conferma prima del merge a meno di `--merge` esplicito.

**Uso:**
```
/dr-promote-to main
/dr-promote-to staging --merge --delete
```

### `/dr-get-latest` — Aggiornamento Pacchetti

Aggiorna tutti i pacchetti `dr-*` tracciati in `.ai/dr-guidelines-packages.json`, ri-eseguendo il rispettivo `install.ps1 -Update`.

**Uso:**
```
/dr-get-latest
```

### `/dr-segnala-miglioria` — Apri una Issue nel Pacchetto Corretto

Determina il pacchetto `dr-*` pertinente (dal manifest o dal file citato), compone titolo/corpo, chiede conferma esplicita, poi apre la issue con `gh issue create` (o genera un URL precompilato se `gh` non è disponibile).

**Uso:**
```
/dr-segnala-miglioria la soglia batch size in database-provider.instructions.md non è chiara
```

### `/dr-snapshot` — Contesto Progetto per Claude

Genera o aggiorna `.ai/context/dr-snapshot.md`: riassunto denso del progetto leggibile in una sola Read, senza riscansionare il codice a ogni sessione.

**Uso:**
```
/dr-snapshot
```

### `/dr-CreateLaunchProfiles` — Profili di Avvio VS Code

Genera o aggiorna `.vscode/launch.json` e `.vscode/tasks.json`: rileva lo stack, chiede quali profili creare e applica solo quelli scelti senza sovrascrivere l'esistente.

**Uso:**
```
/dr-CreateLaunchProfiles
/dr-CreateLaunchProfiles vue + api
```

### `/dr-handoff` — Documentazione di Passaggio

Genera una documentazione completa di handoff per permettere a un altro sviluppatore o a un altro LLM di continuare il lavoro senza perdita di contesto.

**Uso:**
```
/dr-handoff
```

---

## 🔌 MCP Servers

Questo repository include un `.mcp.example.json` di riferimento. La configurazione reale va in `.mcp.json` (in `.gitignore`, può contenere credenziali) — `install.ps1` lo genera al primo utilizzo, senza mai sovrascriverlo dopo.

### `pdf-reader` — Lettura di file PDF

Permette a Claude Code di leggere e interrogare file PDF direttamente nel progetto.

**Prerequisito** (una volta sola, come amministratore):
```powershell
npm install -g @fabriqa.ai/pdf-reader-mcp
```

**Setup nel progetto** — copia `.mcp.example.json` in `.mcp.json` nella root del tuo progetto (o lascia fare a `install.ps1`), oppure aggiungi al `.mcp.json` esistente:
```json
{
  "mcpServers": {
    "pdf-reader": {
      "type": "stdio",
      "command": "pdf-reader-mcp"
    }
  }
}
```

Poi riavvia Claude Code per caricare il server.

---

## 📄 Documentazione

Documentazione generata nella cartella `docs/`:

| File | Contenuto |
|------|-----------|
| [`docs/card-davraf-guidelines.md`](docs/card-davraf-guidelines.md) | Scheda riassuntiva del progetto (stack, dipendenze, ambienti) — nome file da allineare al rename repo |
| [`docs/onboarding.md`](docs/onboarding.md) | Guida di onboarding per developer senior |
| [`docs/scaffolding-minimal-api.md`](docs/scaffolding-minimal-api.md) | Struttura generata da "crea una minimal api" — gate, file, convenzioni |
| [`docs/scaffolding-windows-service.md`](docs/scaffolding-windows-service.md) | Struttura generata da "crea un windows service" — gate, file, convenzioni |
| [`docs/scaffolding-crud.md`](docs/scaffolding-crud.md) | Struttura generata da "crea gli endpoint crud per la tabella X" — gate, file, regole tipi |

> Questi documenti sono ereditati dal repo `davraf-guidelines` pre-split e non ancora rivisti per il nuovo modello a pacchetti — contenuto ancora valido, riferimenti al nome repo da aggiornare in un passaggio successivo.

---

## ❓ FAQ

### Q: Posso usare le guidelines su un progetto già esistente?
**A:** SÌ — esegui `irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/install.ps1 | iex` dalla root del progetto (vedi [Progetto Esistente](#-progetto-esistente--aggiungere-le-guidelines)). Aggiungi poi i pacchetti dominio pertinenti allo stesso modo.

### Q: `install.ps1` richiede git installato?
**A:** SÌ — usa `git clone --depth 1` per scaricare il pacchetto in una cartella temporanea. `CreateNewSolution.ps1` (legacy) ha invece un fallback ZIP se git non è disponibile.

### Q: I repo sono Private — `irm ... | iex` funziona lo stesso?
**A:** No, non senza autenticazione: il bootstrap pubblico richiede repo Public. Finché restano Private, esegui `install.ps1` per path locale da un clone autenticato (`git clone`), oppure attendi il passaggio a Public (pianificato dopo un test su un progetto host reale).

### Q: Devo committare i file `.github/`?
**A:** SÌ — `install.ps1` li copia come cartelle reali, non junction/submodule.

### Q: Posso avere le guidelines attive su tutto il PC, senza installarle in ogni progetto?
**A:** Solo tramite il meccanismo legacy `setup.ps1 -GlobalInstall` (scrive `~/.claude/CLAUDE.md`), non ancora migrato al nuovo `install.ps1` — vedi nota in [Aggiornare le Guidelines](#-aggiornare-le-guidelines).

### Q: Posso usare .NET 8 invece di .NET 10?
**A:** SÌ — modifica `Directory.Build.props` e `global.json` nel tuo progetto dopo l'installazione.

### Q: GitHub Copilot non segue le istruzioni
**A:** Verifica che `.github/copilot-instructions.md` sia presente e committato. Riavvia VS/VS Code.

### Q: `install.ps1` fallisce a metà — come ripristino?
**A:** Esegui `git checkout -- .` per rollback dei file modificati, poi ripeti `install.ps1` — è idempotente, salta i file già a posto.

---

*Documento aggiornato: Luglio 2026 — Revisione v3.0 — 2026-07-23 — claude-sonnet-5*
