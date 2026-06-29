# davraf-guidelines

Linee guida personali e configurazioni per progetti .NET 10, integrate con GitHub Copilot e Claude Code.

## 🚀 Avvio Rapido — Nuovo Progetto

Apri **PowerShell** (utente normale, senza admin) ed esegui:

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/davraf-guidelines/main/CreateNewSolution.ps1 | iex
```

Lo script:
1. Chiede il **nome del progetto** tramite finestra di dialogo
2. Apre un **folder picker** nativo per scegliere la cartella di destinazione
3. Crea la cartella `<destinazione>/<nome-progetto>/`
4. Aggiunge `davraf-guidelines` come **git submodule** (o scarica ZIP se git non è disponibile)
5. Esegue `setup.ps1` che copia i file di configurazione nel progetto

---

## 🔧 Progetto Esistente — Aggiungere le Guidelines

Se hai già un progetto .NET con repository git, esegui dalla **root del progetto**:

```powershell
# 1. Aggiungi davraf-guidelines come submodule
git submodule add https://github.com/davraf-amuro/davraf-guidelines.git davraf-guidelines

# 2. Esegui il setup
.\davraf-guidelines\setup.ps1
```

> `setup.ps1` è sicuro su progetti esistenti: salta i file già presenti (`[SKIP]`), copia i file `.github/` uno per uno senza sovrascrivere, e aggiunge la regola a `CLAUDE.md` solo se non è già presente.

---

## 📦 Cosa viene configurato

Dopo l'esecuzione di `setup.ps1`, il tuo progetto avrà:

| File/Cartella | Provenienza | Scopo |
|---------------|-------------|-------|
| `.editorconfig` | copia | Stile di codice e naming conventions |
| `Directory.Build.props` | copia | Configurazione MSBuild centralizzata (.NET 10, Nullable) |
| `global.json` | copia | Versione .NET SDK |
| `.gitignore` | copia | File ignorati da Git |
| `.gitattributes` | copia | Normalizzazione line endings |
| `.mcp.json` | copia (non sovrascritto) | Server MCP consigliati — non sovrascritto se già presente con contenuto diverso |
| `.github/` | copia file per file | Istruzioni Copilot e prompt modulari |
| `.claude/skills/` | copia | Skill Claude Code (warroom, professor, tattico, tech, ecc.) |
| `docs/` | creato vuoto | Cartella destinazione documentazione generata (professor, card, onboarding) |
| `CLAUDE.md` | generato / merge | Istruzioni per Claude Code — sezione Davraf Guidelines iniettata automaticamente |

---

## 🔄 Aggiornare le Guidelines

Quando le guidelines vengono aggiornate, esegui dalla root del tuo progetto:

```powershell
# 1. Aggiorna il submodule all'ultima versione
git submodule update --remote davraf-guidelines

# 2. Propaga le modifiche ai file copiati nel progetto
.\davraf-guidelines\setup.ps1 -Update
```

Il flag `-Update` sovrascrive i file di configurazione già presenti (`.editorconfig`, `Directory.Build.props`, `.github/`, ecc.) con la versione aggiornata delle guidelines. `CLAUDE.md` non viene mai sovrascritto automaticamente — la sezione `## Davraf Guidelines` viene aggiornata, le sezioni specifiche del progetto sono preservate.

---

## 🤖 Istruzioni Modulari (Copilot / Claude)

Le istruzioni sono organizzate per contesto in `.github/instructions/`:

| File | Quando usarlo |
|------|---------------|
| `copilot-instructions.md` | Istruzioni principali — letto automaticamente da Copilot |
| `dev-cycle.instructions.md` | Ciclo obbligatorio per ogni task AI: dichiara, esegui, verifica |
| `plan-tracking.instructions.md` | Piano su disco in `.ai/plans/<YYYY-MM-DD>-<slug>/` per ogni task con ≥ 2 operazioni. Le fasi usano un **formato atomico** (un passo per file/operazione, con precondizione e criterio di verifica) e una sezione **Regole esecutore**, così che il piano sia eseguibile da un agente in autonomia |
| `minimal-api-architecture.instructions.md` | Endpoint, versioning, OpenAPI, Service layer, Filter `ToExpression()` + DTO `Projection`, ottimizzazione EF |
| `database-provider.instructions.md` | EF Core: DbContext, provider CRUD con selector, Filter/Projection, tracking |
| `input-validation.instructions.md` | Validazione obbligatoria di ogni input esterno con `IValidator<T>` |
| `logging.instructions.md` | Logging strutturato con Serilog |
| `docker-swarm-compose.instructions.md` | Deploy con Docker Swarm |
| `windows-service.instructions.md` | Windows Service con .NET |
| `sensitive-data.instructions.md` | Gestione credenziali e dati sensibili |
| `doc-versioning.instructions.md` | Footer di revisione obbligatorio nei documenti in `docs/` |
| `mcp-tool-readme.instructions.md` | Creazione README per MCP server |
| `readme-structure.instructions.md` | Struttura obbligatoria di questo README |
| `mcp-server-discovery.instructions.md` | Ricerca e creazione MCP server |
| `code-organization.instructions.md` | Struttura classi e file, commenti obbligatori (tutti i linguaggi) |
| `frontend-organization.instructions.md` | Struttura componenti Vue e WPF/MVVM |

---

## 🤖 Claude Code Skills

Questo repository include skill per **Claude Code** in `.claude/skills/`.

### `/warroom` — Tavolo di Lavoro Multi-Agente

Lancia 5 esperti in parallelo per analizzare una domanda tecnica o di prodotto da più angolazioni.

| Agente | Ruolo |
|--------|-------|
| **ARCH** | Architetto software — coesione, debito tecnico, pattern |
| **BE** | Backend senior — complessità implementativa, sicurezza, carico |
| **UI** | Frontend senior — componenti, design system, accessibilità |
| **UX** | UX designer — flussi reali, bisogni utente, percezione |
| **DBADMIN** | DBA watchdog — sorveglia le proposte e interviene solo quando logica di database può ridurre la complessità del codice |

**Setup globale** (una volta sola):
```powershell
Copy-Item -Recurse .claude\skills\warroom "$env:USERPROFILE\.claude\skills\warroom"
```

**Uso:**
```
/warroom come strutturiamo l'autenticazione in questa Minimal API?
```

### `/professor` — Redazione Documentazione

Esperto tecnico che crea, aggiorna e revisiona documentazione con linguaggio chiaro e accessibile. Rispetta le instruction files del progetto prima di scrivere.

**Setup globale** (una volta sola):
```powershell
Copy-Item -Recurse .claude\skills\professor "$env:USERPROFILE\.claude\skills\professor"
```

**Uso:**
```
/professor aggiorna la documentazione del progetto
```

### `/tattico` — Progettazione Prompt AI

Esperto nella creazione e revisione di prompt per agenti e assistenti IA. Analizza pattern di fallimento, identifica ambiguità e suggerisce miglioramenti strutturali.

**Setup globale** (una volta sola):
```powershell
Copy-Item -Recurse .claude\skills\tattico "$env:USERPROFILE\.claude\skills\tattico"
```

**Uso:**
```
/tattico rivedi il prompt di sistema dell'agente di onboarding
```

### `/tech` — Rilascio e Infrastruttura

Specialista di deployment e infrastruttura IT. Conosce Docker, IIS, Git, Swagger/OpenAPI e la preparazione di ambienti per l'esecuzione di software.

**Setup globale** (una volta sola):
```powershell
Copy-Item -Recurse .claude\skills\tech "$env:USERPROFILE\.claude\skills\tech"
```

**Uso:**
```
/tech pianifica il rilascio della nuova versione su Docker Swarm
```

### `/audit-api` — Audit Backend .NET

Esegue un audit completo di qualsiasi backend C# .NET 10 — **Minimal API**, **Windows Service**, o soluzioni multi-progetto. Rileva automaticamente il tipo di progetto e carica le istruzioni modulari pertinenti prima di procedere.

**Fasi di audit** (in ordine di gravità del danno potenziale):

| Fase | Area | Cosa trova |
|------|------|------------|
| 0 | Orientamento | Rileva tipo progetto, carica istruzioni modulari pertinenti |
| 1 | Sicurezza | Credenziali hardcoded, logging di dati sensibili, input non validati |
| 2 | EF Core / Accesso dati | Full table scan silente, projection non EF-traducibile, N+1, tracking errato |
| 3 | Architettura | Handler → provider diretto (violazione service layer), pattern vietati (AutoMapper, MediatR) |
| 4 | Dead code | Classi, DTO, registrazioni DI non usate |
| 5 | Pattern tipo-specifici | Conformità a `minimal-api-architecture` o `windows-service` instructions |
| 6 | Qualità codice | Commenti XML mancanti, SRP violato, struttura file errata |
| 7 | Performance | `.Result`/`.Wait()`, CancellationToken mancante, paginazione assente |

Ogni finding riporta severità (`[ERROR]` / `[WARNING]` / `[INFO]`), file:riga, descrizione e riferimento all'istruzione modulare violata. Non modifica file: propone un plan mode al termine.

**Setup globale** (una volta sola):
```powershell
Copy-Item -Recurse .claude\skills\audit-api "$env:USERPROFILE\.claude\skills\audit-api"
```

**Uso:**
```
/audit-api
/audit-api sicurezza
/audit-api Fase 2
```

### `/audit-fe` — Audit Frontend

Rileva automaticamente lo stack frontend usato nel progetto (React, Vue, Angular, Blazor…), poi esegue un audit in tre fasi:
1. **Dead code** — componenti, hook, import, route non usati
2. **Pattern compliance** — convenzioni del framework rilevato, struttura cartelle, naming
3. **Performance** — re-render inutili, chiamate API ridondanti, lazy loading mancante

Produce un report strutturato per severità. Non modifica file: propone un plan mode al termine.

**Setup globale** (una volta sola):
```powershell
Copy-Item -Recurse .claude\skills\audit-fe "$env:USERPROFILE\.claude\skills\audit-fe"
```

**Uso:**
```
/audit-fe
```

### `/promote-to` — Commit, Push e Pull Request

Promuove il branch corrente verso un branch target: fa commit delle modifiche pendenti (se presenti), push e apre una Pull Request su GitHub. Chiede sempre conferma prima del merge, a meno che non sia passato `--merge`.

**Sintassi:**
```
/promote-to <target-branch> [--merge] [--delete]
```

| Flag | Comportamento |
|------|---------------|
| *(nessuno)* | commit → push → PR → chiede "eseguo il merge?" |
| `--merge` | commit → push → PR → merge automatico senza chiedere |
| `--delete` | dopo il merge, elimina il branch sorgente |
| `--merge --delete` | tutto automatico: PR + merge + eliminazione branch |

> Il branch sorgente non viene **mai** eliminato senza `--delete` esplicito.

**Setup globale** (una volta sola):
```powershell
Copy-Item -Recurse .claude\skills\promote-to "$env:USERPROFILE\.claude\skills\promote-to"
```

**Uso:**
```
/promote-to master
/promote-to staging --merge
/promote-to main --delete
/promote-to staging --merge --delete
```

### `/get-latest` — Aggiornamento Submodule

Aggiorna il submodule `davraf-guidelines` all'ultima versione remota e propaga le modifiche ai file copiati nel progetto host tramite `setup.ps1 -Update`.

**Setup globale** (una volta sola):
```powershell
Copy-Item -Recurse .claude\skills\get-latest "$env:USERPROFILE\.claude\skills\get-latest"
```

**Uso:**
```
/get-latest
```

---

## 🔌 MCP Servers

Questo repository include un `.mcp.json` di riferimento con i MCP server consigliati.

### `pdf-reader` — Lettura di file PDF

Permette a Claude Code di leggere e interrogare file PDF direttamente nel progetto.

**Prerequisito** (una volta sola, come amministratore):
```powershell
npm install -g @fabriqa.ai/pdf-reader-mcp
```

**Setup nel progetto** — aggiungi al `.mcp.json` della root del tuo progetto:
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
| [`docs/card-davraf-guidelines.md`](docs/card-davraf-guidelines.md) | Scheda riassuntiva del progetto (stack, dipendenze, ambienti) |
| [`docs/onboarding.md`](docs/onboarding.md) | Guida di onboarding per developer senior |
| [`docs/scaffolding-minimal-api.md`](docs/scaffolding-minimal-api.md) | Struttura generata da "crea una minimal api" — gate, file, convenzioni |
| [`docs/scaffolding-windows-service.md`](docs/scaffolding-windows-service.md) | Struttura generata da "crea un windows service" — gate, file, convenzioni |
| [`docs/scaffolding-crud.md`](docs/scaffolding-crud.md) | Struttura generata da "crea gli endpoint crud per la tabella X" — gate, file, regole tipi |

---

## ❓ FAQ

### Q: Posso usare le guidelines su un progetto già esistente?
**A:** SÌ — `CreateNewSolution.ps1` funziona solo per nuovi progetti (esce se la cartella esiste già). Per un progetto esistente, aggiungi manualmente il submodule ed esegui `setup.ps1` come descritto nella sezione [Progetto Esistente](#-progetto-esistente--aggiungere-le-guidelines).

### Q: Devo committare i file `.github/`?
**A:** SÌ se hai `.github/` come cartella normale. Se usi junction, il contenuto è nel submodule.

### Q: Funziona senza git installato?
**A:** SÌ — `CreateNewSolution.ps1` scarica automaticamente uno ZIP delle guidelines come fallback.

### Q: Posso usare .NET 8 invece di .NET 10?
**A:** SÌ — modifica `Directory.Build.props` e `global.json` nel tuo progetto dopo il setup.

### Q: GitHub Copilot non segue le istruzioni
**A:** Verifica che `.github/copilot-instructions.md` sia presente e committato. Riavvia VS/VS Code.

### Q: `setup.ps1` fallisce a metà — come ripristino?
**A:** Esegui `git checkout -- .` per rollback dei file modificati dallo script, poi ripeti `setup.ps1` senza parametri.

---

*Documento aggiornato: Giugno 2026 — Revisione v2.1 — 2026-06-29 — claude-opus-4-8*
