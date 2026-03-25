# davraf-guidelines

Linee guida personali e configurazioni per progetti .NET 10 Minimal API, integrate con GitHub Copilot e Claude Code.

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
| `.github/` | junction | Istruzioni Copilot e prompt modulari |
| `CLAUDE.md` | generato | Istruzioni per Claude Code |

---

## 🔄 Aggiornare le Guidelines

Quando le guidelines vengono aggiornate, esegui dalla root del tuo progetto:

```powershell
# 1. Aggiorna il submodule all'ultima versione
git submodule update --remote davraf-guidelines

# 2. Propaga le modifiche ai file copiati nel progetto
.\davraf-guidelines\setup.ps1 -Update
```

Il flag `-Update` sovrascrive i file di configurazione già presenti (`.editorconfig`, `Directory.Build.props`, ecc.) con la versione aggiornata delle guidelines. `CLAUDE.md` non viene mai sovrascritto.
La cartella `.github/` è collegata via junction e si aggiorna automaticamente al passo 1.

---

## 🤖 Istruzioni Modulari (Copilot / Claude)

Le istruzioni sono organizzate per contesto in `.github/instructions/`:

| File | Quando usarlo |
|------|---------------|
| `copilot-instructions.md` | Istruzioni principali — letto automaticamente da Copilot |
| `dev-cycle.instructions.md` | Ciclo obbligatorio per ogni task AI: dichiara, esegui, verifica |
| `minimal-api-architecture.instructions.md` | Endpoint, versioning, OpenAPI |
| `database-provider.instructions.md` | EF Core, DbContext, provider |
| `docker-swarm-compose.instructions.md` | Deploy con Docker Swarm |
| `windows-service.instructions.md` | Windows Service con .NET |
| `sensitive-data.instructions.md` | Gestione credenziali e dati sensibili |
| `mcp-tool-readme.instructions.md` | Creazione README per MCP server |
| `readme-structure.instructions.md` | Struttura obbligatoria di questo README |

---

## 🤖 Claude Code Skills

Questo repository include skill per **Claude Code** in `.claude/skills/`.

### `/warroom` — Tavolo di Lavoro Multi-Agente

Lancia 4 esperti in parallelo (ARCH, BE, UI, UX) per analizzare una domanda tecnica o di prodotto da più angolazioni.

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
Copy-Item .claude\skills\professor.md "$env:USERPROFILE\.claude\skills\professor.md"
```

**Uso:**
```
/professor aggiorna il README con la nuova skill appena aggiunta
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

---

*Documento aggiornato: Marzo 2026 — Revisione v1.1 — 2026-03-25 — claude-sonnet-4-6*
