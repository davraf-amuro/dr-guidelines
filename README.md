# dr-guidelines

Pacchetto core della suite `dr-*`: catalogo dei pacchetti di dominio, linee guida trasversali, skill Claude Code e meccanismo di installazione, per progetti di qualsiasi stack integrati con GitHub Copilot e Claude Code.

## 🧩 Pacchetti dr-* disponibili

`dr-guidelines` (questo repo) è il **catalogo** della suite: dice quali pacchetti esistono, a quale dominio servono, dove stanno e come si installano, e porta le istruzioni valide per qualsiasi progetto. Le regole di un dominio specifico non vivono qui: vivono nei pacchetti, installabili singolarmente.

| Pacchetto | Repo | Scope |
|---|---|---|
| **dr-guidelines** (core) | [davraf-amuro/dr-guidelines](https://github.com/davraf-amuro/dr-guidelines) | Catalogo dei pacchetti, istruzioni/skill trasversali, meccanismo di installazione (`dr-guidelines-install.ps1`) |
| dr-minimalapi | [davraf-amuro/dr-minimalapi](https://github.com/davraf-amuro/dr-minimalapi) | Architettura Minimal API .NET, prompt endpoint/scaffolding. Dipende da `dr-dotnet-backend` |
| dr-winsvc | [davraf-amuro/dr-winsvc](https://github.com/davraf-amuro/dr-winsvc) | Windows Service .NET. Dipende da `dr-dotnet-backend` |
| dr-efdb | [davraf-amuro/dr-efdb](https://github.com/davraf-amuro/dr-efdb) | Entity Framework Core, provider database, resilienza avvio |
| dr-fe | [davraf-amuro/dr-fe](https://github.com/davraf-amuro/dr-fe) | Organizzazione frontend + audit |
| dr-devops | [davraf-amuro/dr-devops](https://github.com/davraf-amuro/dr-devops) | Docker Swarm, Portainer, CI/CD GitLab |
| dr-dotnet-backend | [davraf-amuro/dr-dotnet-backend](https://github.com/davraf-amuro/dr-dotnet-backend) | Base backend .NET: rilevamento tipo progetto, convenzioni .NET, `Directory.Build.props` e `global.json`, skill di audit |

Le dipendenze dichiarate (`dr-minimalapi`/`dr-winsvc` → `dr-dotnet-backend`) vengono installate automaticamente dall'installer se assenti.

### Aggiungere un dominio nuovo

Tutto passa da [`scaffolding-catalog.json`](scaffolding-catalog.json), che è l'unica fonte: l'installer legge da lì l'elenco dei pacchetti, e `/dr-scaffold` legge da lì domini e intenti. Per aggiungere un pacchetto servono quattro voci nello stesso file:

1. **`packages`** — nome, repository, dipendenze, e i `rootFiles` che il pacchetto installa nella radice del progetto host
2. **`kinds`** — se il dominio richiede una toolchain non ancora prevista, con i suoi prerequisiti (`dotnet`, `node`, `embedded`, `content`, `any`)
3. **`domains`** — etichetta leggibile, `kind`, pacchetti che lo compongono
4. **`intentMap`** — le frasi con cui un utente descriverebbe quel lavoro ("progetto per ESP32", "guida turistica")

Il repository del pacchetto contiene il proprio `<pacchetto>-install.ps1` (un thin wrapper che carica la libreria condivisa da questo repo) più le sue `.github/instructions/`, `.github/prompts/` e `.claude/skills/`. Nessuna modifica all'installer: l'elenco dei pacchetti non è scritto in nessuno script.

**Nessun pacchetto copre il dominio richiesto?** `/dr-scaffold` non finisce in un vicolo cieco: dichiara il gap, propone di proseguire con il solo core e offre di aprire una issue di richiesta nuovo pacchetto su questo repository.

> **Nota:** i 7 repo sono attualmente **Private**. Il bootstrap pubblico `irm ... | iex` richiede repo Public; finché restano Private si usa `gh api` (vedi [Finché i repo sono Private](#finché-i-repo-sono-private)), che è autenticato e scarica ugualmente da GitHub. Il `git clone` che l'installer fa per prendere il contenuto del pacchetto funziona già oggi grazie al credential manager.

---

## 🚀 Avvio Rapido — Nuovo Progetto

Lo scaffolding non è più uno script: è guidato dall'agente AI. Apri in VS Code la cartella dove vuoi creare il progetto e invoca:

```
/dr-scaffold
```

Il flusso:
1. **Risoluzione del dominio** — dalla richiesta ("una Minimal API", "un frontend") ricava il dominio leggendo la `intentMap` del catalogo. Nessun dominio corrispondente → lo dichiara e propone di aprire una issue, invece di assumere uno stack.
2. **Gate prerequisiti del dominio** — git, PowerShell 7 e `gh` autenticato sempre; SDK .NET 10 solo per i domini .NET, node/npm solo per quelli frontend. Nessuna scrittura finché il gate non passa.
3. **Rileva lo stato della cartella** e delega al pezzo giusto: cartella vuota → solution da zero; solution esistente → aggiunta di un progetto; progetti senza pacchetti → installazione guidelines. Se chiedi una tipologia e manca il contenitore che la regge (progetto senza solution), **propone di creare anche quello** invece di fermarsi. I domini senza contenitore di progetto (firmware, contenuti) vanno direttamente all'installazione dei pacchetti.
4. **Raccoglie tutte le risposte** — workspace VS Code multi-repo (per frontend e backend in repo separati), nome e formato solution, tipologie di progetto con nomi proposti, pacchetti `dr-*` per repository.
5. **Mostra il dry-run dell'albero** e chiede **una sola conferma**.
6. **Esegue** nell'ordine: `.code-workspace` → `dotnet new sln` → progetti in `src/` e `test/` → aggancio alla solution → frontend Vue → `git init` + commit iniziale → installer dei pacchetti → `dotnet format`.

Le tipologie di progetto e i pacchetti disponibili vengono letti da [`scaffolding-catalog.json`](scaffolding-catalog.json): aggiungerne una è una voce nel catalogo, non una modifica ai prompt.

In GitHub Copilot lo stesso flusso è disponibile come prompt: [`.github/prompts/dr-scaffold.prompt.md`](.github/prompts/dr-scaffold.prompt.md).

> Preferisci fare a mano? La struttura generata e le convenzioni applicate sono documentate in [`docs/scaffolding-minimal-api.md`](docs/scaffolding-minimal-api.md) e [`docs/scaffolding-windows-service.md`](docs/scaffolding-windows-service.md), poi segui la sezione successiva per i pacchetti.

---

## 🔧 Progetto Esistente — Aggiungere le Guidelines

Se hai già un progetto con repository git, esegui dalla **root del progetto**:

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1 | iex
```

Installa il pacchetto core: file di configurazione, istruzioni/skill trasversali, sezione `<!-- dr-guidelines -->` in `CLAUDE.md`. Sicuro su progetti esistenti: salta i file già presenti (`[SKIP]`), non sovrascrive nulla senza `-Update` esplicito.

Per aggiungere anche un pacchetto dominio (es. Minimal API), esegui il suo `<pacchetto>-install.ps1` allo stesso modo — vedi la tabella nella sezione [Pacchetti dr-* disponibili](#-pacchetti-dr--disponibili):

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/dr-minimalapi/main/dr-minimalapi-install.ps1 | iex
```

Oppure, senza scaricare un secondo installer, con il flag `-Package` sul core:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1))) -Package dr-minimalapi
```

Le dipendenze mancanti vengono installate da sole (`dr-minimalapi` tira `dr-dotnet-backend`). Un nome non in elenco produce un errore con i pacchetti disponibili. `-Package` e `-Global` sono mutuamente esclusivi.

Ogni installazione viene tracciata in `.ai/dr-guidelines-packages.json` nel progetto host.

### Finché i repo sono Private

`raw.githubusercontent.com` risponde `404` sui repo Private: il comando qui sopra non funziona. Usa `gh`, che è autenticato e li legge:

```powershell
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
```

Stesso schema per i pacchetti dominio, sostituendo nome repo e nome file. Prerequisito: `gh auth status` autenticato con scope `repo`. È l'unica via che scarica davvero da GitHub senza un clone locale — l'installer risolve poi la libreria condivisa con la stessa catena di tentativi (raw → clone locale → `gh api`).

---

## 📦 Cosa viene configurato

Dopo l'esecuzione di `dr-guidelines-install.ps1`, il progetto host avrà:

| File/Cartella | Provenienza | Scopo |
|---------------|-------------|-------|
| `.editorconfig` | copia | Stile di codice e naming conventions |
| `.gitignore` | copia | File ignorati da Git |
| `.gitattributes` | copia | Normalizzazione line endings |
| `.mcp.json` | copia da `.mcp.example.json` (solo se assente, mai sovrascritto) | Server MCP consigliati |
| `.github/instructions/`, `.github/prompts/` | copia file per file | Istruzioni Copilot/Claude e prompt modulari (contenuto core) |
| `.claude/skills/` | copia cartella per cartella | Skill Claude Code core (dr-warroom, dr-professor, dr-tattico, dr-tech, dr-get-latest, dr-segnala-miglioria, dr-verify-plan, ecc.) |
| `.claude/settings.json` | copia / merge additivo | Permessi condivisi: le voci `permissions.allow` mancanti vengono aggiunte, quelle già presenti e le altre chiavi (`mcpServers`, `env`, `hooks`) non vengono toccate |
| `CLAUDE.md` | generato / merge | Sezione `<!-- dr-guidelines --> ... <!-- /dr-guidelines -->` iniettata/aggiornata automaticamente, resto del file preservato |
| `.ai/dr-scaffolding-catalog.json` | copia | Catalogo di domini, tipologie e pacchetti, letto dalle skill `dr-scaffold*` nel progetto host |
| `.ai/dr-guidelines-packages.json` | generato / upsert | Manifest dei pacchetti `dr-*` installati, con il **commit** da cui proviene ciascuno: funge da lock file, e `-Update` lo usa per dire cosa è cambiato a monte |

I pacchetti dominio installano `.github/instructions/`, `.github/prompts/` e/o `.claude/skills/` propri, e i **file di radice che dichiarano nel catalogo** (campo `rootFiles`). Nessuna sezione `CLAUDE.md`: quella resta esclusiva del core.

> **Il core non è più un pacchetto .NET.** `Directory.Build.props` e `global.json` appartengono a `dr-dotnet-backend`, che li installa insieme alle convenzioni .NET: un progetto frontend, un firmware o un repository di documentazione non li riceve più. Un progetto .NET li ottiene installando quel pacchetto — che è già dipendenza obbligata di `dr-minimalapi` e `dr-winsvc`.

---

## 🔄 Aggiornare le Guidelines

**Un singolo pacchetto:**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1))) -Update
```

Il flag `-Update` sovrascrive i file già presenti con la versione corrente del pacchetto e ri-mergia la sezione `CLAUDE.md` (per il core). Sostituisci l'URL con quello del pacchetto dominio da aggiornare.

**Tutti i pacchetti tracciati nel progetto:**

```
/dr-get-latest
```

Legge `.ai/dr-guidelines-packages.json` e ri-esegue `<pacchetto>-install.ps1 -Update` per ciascun pacchetto elencato.

**Linee guida globali (`~/.claude/CLAUDE.md`, indipendenti dal progetto):**

```
/dr-install-global aggiorna
```

Equivalente da riga di comando:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1))) -Global -Update
```

Viene riscritta **solo** la sezione tra `## Davraf Guidelines (Globale)` e `<!-- /davraf-guidelines -->`: tutto ciò che sta fuori resta intatto. Senza `-Update`, una sezione già presente viene lasciata com'è (`[SKIP]`).

---

## 🤖 Istruzioni Modulari (Copilot / Claude)

Contenuto **core**, trasversale a qualsiasi stack. Le istruzioni specifiche di dominio (Minimal API, Windows Service, EF Core, frontend, DevOps) vivono nei rispettivi pacchetti — vedi la tabella in [Pacchetti dr-* disponibili](#-pacchetti-dr--disponibili).

| File | Quando usarlo |
|------|---------------|
| `.github/copilot-instructions.md` | Istruzioni principali — letto automaticamente da Copilot |
| `dev-cycle.instructions.md` | Ciclo obbligatorio per ogni task AI: dichiara, esegui, verifica |
| `plan-tracking.instructions.md` | Piano su disco in `.ai/plans/<YYYY-MM-DD>-<slug>/` per ogni task con ≥ 2 operazioni, formato atomico |
| `code-organization.instructions.md` | Struttura classi e file, commenti obbligatori (tutti i linguaggi) |
| `no-hardcoded-values.instructions.md` | Centralizzazione dei valori letterali: cosa estrarre, dove metterlo, cosa lasciare inline (tutti i linguaggi) |
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

Aggiorna tutti i pacchetti `dr-*` tracciati in `.ai/dr-guidelines-packages.json`, ri-eseguendo il rispettivo `<pacchetto>-install.ps1 -Update`.

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

> **Il pacchetto non si modifica nel progetto host.** Una correzione fatta solo nella copia locale si perde al primo `-Update`. Ogni repository `dr-*` ha `.github/ISSUE_TEMPLATE/` con due modelli — `miglioria.md` per una richiesta evolutiva, `problema.md` per un malfunzionamento — e la skill li usa per comporre la issue. Su GitHub Copilot lo stesso canale è [`.github/prompts/dr-segnala-miglioria.prompt.md`](.github/prompts/dr-segnala-miglioria.prompt.md).

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

### `/dr-verify-plan` — Verifica Indipendente di un Piano

Lancia un subagente senza il contesto della conversazione che ha implementato il piano: rilegge i file di Scope, li confronta con le azioni dichiarate e valuta i criteri di verifica, prima che il piano venga segnato `COMPLETATO`. Chi ha scritto il codice tende a confermarlo; un controllo a freddo no.

**Uso:**
```
/dr-verify-plan
```

---

### `/dr-scaffold` — Scaffolding Guidato (punto d'ingresso)

Verifica i prerequisiti, rileva lo stato della cartella corrente e delega al pezzo giusto. È il comando da usare quando non sai quale serve.

**Uso:**
```
/dr-scaffold
/dr-scaffold aggiungi un worker al progetto
```

---

### `/dr-scaffold-solution` — Solution da Zero

Workspace VS Code multi-repo, solution .NET 10 (formato `slnx`), progetti in `src/` e `test/`, frontend Vue, `git init` e pacchetti `dr-*`. Tutte le domande prima, dry-run dell'albero, **una sola** conferma.

**Uso:**
```
/dr-scaffold-solution
```

---

### `/dr-scaffold-project` — Aggiungi un Progetto

Aggiunge un progetto a una solution: tipologia dal catalogo, creazione, aggancio con `dotnet sln add`, build e `dotnet format` di verifica. Se la solution non esiste **non si ferma**: propone di crearla e passa il lavoro a `/dr-scaffold-solution` con la tipologia già scelta.

**Uso:**
```
/dr-scaffold-project worker chiamato ordini.service
```

---

### `/dr-scaffold-guidelines` — Installa i Pacchetti

Rileva lo stack, propone i pacchetti pertinenti marcando quelli già installati, esegue gli installer `<pacchetto>-install.ps1` dalla root del repository. Per **aggiornare** pacchetti già presenti usa invece `/dr-get-latest`.

**Uso:**
```
/dr-scaffold-guidelines
```

---

### `/dr-install-global` — Linee Guida su Tutto il PC

Installa o aggiorna la sezione linee guida in `~/.claude/CLAUDE.md`, il file che Claude Code carica in ogni sessione su qualsiasi progetto. Legge lo stato attuale, mostra cosa verrà scritto e cosa resta intatto, chiede **una conferma esplicita** — il target è fuori dal repository e nessun `git checkout` lo annulla.

**Uso:**
```
/dr-install-global
/dr-install-global aggiorna
```

---

## 🔌 MCP Servers

Questo repository include un `.mcp.example.json` di riferimento. La configurazione reale va in `.mcp.json` (in `.gitignore`, può contenere credenziali) — L'installer lo genera al primo utilizzo, senza mai sovrascriverlo dopo.

### `pdf-reader` — Lettura di file PDF

Permette a Claude Code di leggere e interrogare file PDF direttamente nel progetto.

**Prerequisito** (una volta sola, come amministratore):
```powershell
npm install -g @fabriqa.ai/pdf-reader-mcp
```

**Setup nel progetto** — copia `.mcp.example.json` in `.mcp.json` nella root del tuo progetto (o lascia fare all'installer), oppure aggiungi al `.mcp.json` esistente:
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
| [`docs/card-dr-guidelines.md`](docs/card-dr-guidelines.md) | Scheda riassuntiva del progetto (stack, dipendenze, ambienti) |
| [`docs/onboarding.md`](docs/onboarding.md) | Guida di onboarding per developer senior |
| [`docs/scaffolding-minimal-api.md`](docs/scaffolding-minimal-api.md) | Struttura generata da "crea una minimal api" — gate, file, convenzioni |
| [`docs/scaffolding-windows-service.md`](docs/scaffolding-windows-service.md) | Struttura generata da "crea un windows service" — gate, file, convenzioni |
| [`docs/scaffolding-crud.md`](docs/scaffolding-crud.md) | Struttura generata da "crea gli endpoint crud per la tabella X" — gate, file, regole tipi |
| [`docs/test-progetto-host.md`](docs/test-progetto-host.md) | Procedura di test end-to-end dell'installer su un progetto host di prova (`test-uno`) — passi, checklist, rollback, limiti in fase Private |

> `card-dr-guidelines.md`, `onboarding.md` e `test-progetto-host.md` sono allineati al modello a pacchetti. I tre `scaffolding-*.md` sono ereditati dal repo `davraf-guidelines` pre-split: descrivono la struttura interna dei progetti generati (Dto, Endpoints, Workers, Validators), contenuto ancora valido e indipendente dal meccanismo di distribuzione.

---

## ❓ FAQ

### Q: Posso usare le guidelines su un progetto già esistente?
**A:** SÌ — esegui `irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1 | iex` dalla root del progetto (vedi [Progetto Esistente](#-progetto-esistente--aggiungere-le-guidelines)). Aggiungi poi i pacchetti dominio pertinenti allo stesso modo.

### Q: L'installer richiede git installato?
**A:** SÌ — usa `git clone --depth 1` per scaricare il pacchetto in una cartella temporanea. Nessun fallback: senza git l'installazione non parte, e `/dr-scaffold` lo verifica nel gate prerequisiti prima di scrivere qualsiasi cosa.

### Q: I repo sono Private — `irm ... | iex` funziona lo stesso?
**A:** No — `raw.githubusercontent.com` risponde `404`. Ma non serve un clone locale: `gh api` legge i repo Private ed è già autenticato, quindi il bootstrap funziona lo stesso (vedi [Finché i repo sono Private](#finché-i-repo-sono-private)). Resta valida anche l'invocazione da path locale, se hai già il clone.

### Q: Devo committare i file `.github/`?
**A:** SÌ — L'installer li copia come cartelle reali, non junction/submodule.

### Q: Posso avere le guidelines attive su tutto il PC, senza installarle in ogni progetto?
**A:** SÌ — `/dr-install-global`, oppure `dr-guidelines-install.ps1 -Global`, scrive la sezione linee guida in `~/.claude/CLAUDE.md`, che Claude Code carica in ogni sessione. Non sostituisce l'installazione nel progetto: le regole globali sono trasversali, quelle di progetto (istruzioni modulari, skill, configurazione radice) arrivano solo con l'install nel repository, e in caso di conflitto ha precedenza il `CLAUDE.md` di progetto.

### Q: Posso usare .NET 8 invece di .NET 10?
**A:** SÌ — modifica `Directory.Build.props` e `global.json` nel tuo progetto dopo l'installazione.

### Q: GitHub Copilot non segue le istruzioni
**A:** Verifica che `.github/copilot-instructions.md` sia presente e committato. Riavvia VS/VS Code.

### Q: L'installer fallisce a metà — come ripristino?
**A:** Esegui `git checkout -- .` per rollback dei file modificati, poi ripeti l'installer — è idempotente, salta i file già a posto.

---

*Documento aggiornato: Agosto 2026 — Revisione v3.2 — 2026-08-09 — claude-opus-5*
