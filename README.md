# dr-guidelines

Pacchetto core della suite `dr-*`: catalogo dei pacchetti, linee guida trasversali, skill Claude Code e installer, per progetti di qualsiasi stack seguiti con GitHub Copilot e Claude Code.

## 🧩 Pacchetti dr-* disponibili

`dr-guidelines` (questo repo) è il **catalogo** della suite. Dice quali pacchetti esistono, a quale dominio servono, dove stanno e come si installano. Porta anche le istruzioni valide per qualsiasi progetto. Le regole di un dominio specifico vivono nei pacchetti, installabili uno per uno.

| Pacchetto | Repo | Scope |
|---|---|---|
| **dr-guidelines** (core) | [davraf-amuro/dr-guidelines](https://github.com/davraf-amuro/dr-guidelines) | Catalogo dei pacchetti, istruzioni e skill trasversali, installer (`dr-guidelines-install.ps1`) |
| dr-dotnet-backend | [davraf-amuro/dr-dotnet-backend](https://github.com/davraf-amuro/dr-dotnet-backend) | Base backend .NET: rilevamento tipo progetto, `Directory.Build.props` e `global.json`, skill `/dr-audit-api` |
| dr-minimalapi | [davraf-amuro/dr-minimalapi](https://github.com/davraf-amuro/dr-minimalapi) | Architettura Minimal API .NET, prompt per endpoint e card. Dipende da `dr-dotnet-backend` |
| dr-winsvc | [davraf-amuro/dr-winsvc](https://github.com/davraf-amuro/dr-winsvc) | Windows Service / Worker .NET. Dipende da `dr-dotnet-backend` |
| dr-efdb | [davraf-amuro/dr-efdb](https://github.com/davraf-amuro/dr-efdb) | Entity Framework Core, provider database, resilienza all'avvio |
| dr-fe | [davraf-amuro/dr-fe](https://github.com/davraf-amuro/dr-fe) | Organizzazione del frontend, skill `/dr-audit-fe` |
| dr-devops | [davraf-amuro/dr-devops](https://github.com/davraf-amuro/dr-devops) | Docker Swarm, Portainer, CI/CD GitLab |

Le dipendenze si installano da sole: `dr-minimalapi` e `dr-winsvc` si portano dietro `dr-dotnet-backend` se manca. È il comportamento dell'installer, non ancora provato sul campo: vedi [`docs/bozza-manuale-installazione.md`](docs/bozza-manuale-installazione.md).

> **I 7 repo sono Private.** Per usarli non serve renderli pubblici: basta `gh` autenticato con scope `repo`. I comandi di questo README sono in forma `gh api`, che funziona sia a repo Private che Public. Le forme brevi `irm` compaiono solo come alternativa per quando i repo saranno Public.

### Aggiungere un dominio nuovo

Tutto passa da [`scaffolding-catalog.json`](scaffolding-catalog.json), l'unica fonte. L'installer legge da lì l'elenco dei pacchetti. `/dr-scaffold` legge da lì domini e intenti. Per un pacchetto nuovo servono quattro voci nello stesso file:

1. **`packages`** — nome, repository, dipendenze, `rootFiles` da installare nella radice del progetto host
2. **`kinds`** — solo se il dominio richiede una toolchain nuova, con i suoi prerequisiti (`dotnet`, `node`, `embedded`, `content`, `any`)
3. **`domains`** — etichetta leggibile, `kind`, pacchetti che lo compongono
4. **`intentMap`** — le frasi con cui un utente descriverebbe quel lavoro ("progetto per ESP32", "guida turistica")

Il repository del pacchetto contiene il proprio `<pacchetto>-install.ps1`, un wrapper sottile che carica la libreria condivisa da questo repo. Più le sue `.github/instructions/`, `.github/prompts/` e `.claude/skills/`. L'installer non va toccato.

**Nessun pacchetto copre il dominio richiesto?** `/dr-scaffold` lo dichiara, propone di proseguire con il solo core e offre di aprire una issue di richiesta nuovo pacchetto su questo repository.

---

## 🚀 Avvio Rapido — Nuovo Progetto

> 📘 **Guida passo passo:** [`docs/guida-nuova-soluzione.md`](docs/guida-nuova-soluzione.md) — dalla cartella vuota alla solution, con prerequisiti ed errori comuni.

**L'ordine conta:** prima si installa il core, poi si crea la solution. In una cartella vuota Claude Code non ha nessuna skill `dr-*`: arrivano con il core.

> Il percorso da cartella vuota a solution non è ancora stato provato sul campo con l'installer attuale: l'installazione del core è stata provata il 2026-08-12 con la versione precedente, il resto mai. Il catalogo chiede inoltre di creare un frontend Vue prima del core. Lo stato delle prove è nella guida.

```powershell
# 1. Cartella nuova, aperta in una finestra VS Code separata
New-Item -ItemType Directory C:\Progetti\ordini
code C:\Progetti\ordini

# 2. Nel terminale della finestra nuova: installa il core
Set-Location C:\Progetti\ordini
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
```

3. Ricarica la finestra: `Developer: Reload Window` (le skill si leggono all'avvio)
4. In Claude Code: `/dr-scaffold crea una Minimal API per gli ordini`

Lo scaffolding non è uno script: è guidato dall'agente. Il flusso di `/dr-scaffold`:

1. **Dominio** — ricava il dominio dalla richiesta leggendo la `intentMap` del catalogo. Nessuna corrispondenza → lo dichiara e propone una issue, invece di assumere uno stack
2. **Gate prerequisiti** — git, PowerShell 7 e `gh` autenticato sempre; SDK .NET 10 solo per i domini .NET; node/npm solo per il frontend. Nessuna scrittura finché il gate non passa
3. **Stato della cartella** — delega al pezzo giusto: cartella con solo il core → `/dr-scaffold-solution`; solution esistente → `/dr-scaffold-project`; progetti senza pacchetti → `/dr-scaffold-guidelines`
4. **Raccolta risposte** — nome e formato della solution, tipologie di progetto con nomi proposti, pacchetti `dr-*` per repository, eventuale workspace multi-repo
5. **Dry-run e conferma unica** — mostra l'albero e i comandi, chiede una sola conferma
6. **Esecuzione** — solution → progetti in `src/` e `test/` → aggancio → frontend Vue → `git init` + commit iniziale → pacchetti `dr-*` → `dotnet format`

Tipologie di progetto e pacchetti arrivano da [`scaffolding-catalog.json`](scaffolding-catalog.json): aggiungerne una è una voce nel catalogo, non una modifica ai prompt.

In GitHub Copilot lo stesso flusso è il prompt [`.github/prompts/dr-scaffold.prompt.md`](.github/prompts/dr-scaffold.prompt.md).

La struttura interna dei progetti generati è descritta in [`docs/scaffolding-minimal-api.md`](docs/scaffolding-minimal-api.md) e [`docs/scaffolding-windows-service.md`](docs/scaffolding-windows-service.md).

---

## 🔧 Progetto Esistente — Aggiungere le Guidelines

Dalla **root del repository** del progetto:

```powershell
Set-Location <root-del-progetto>
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
```

Il comando breve funziona solo quando i repo sono Public. Oggi risponde `404`:

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1 | iex
```

L'installer copia file di configurazione, istruzioni e skill trasversali, e la sezione `<!-- dr-guidelines -->` in `CLAUDE.md`. **Non è distruttivo:** un file già presente viene saltato (`[SKIP]`) e senza `-Update` nessun file viene sovrascritto. Uniche modifiche a file esistenti: le voci mancanti in `.claude/settings.json`, la sezione marcata in `CLAUDE.md` e il manifest `.ai/dr-guidelines-packages.json`, riscritto a ogni esecuzione.

Tre cose da sapere:

| Cosa | Dettaglio |
|---|---|
| La cartella corrente è la destinazione | Da un'altra cartella i file finiscono lì, senza errori. `Set-Location` prima di tutto |
| Nessun repo finisce nel progetto | L'installer clona il pacchetto in `%TEMP%`, copia i file e cancella la copia |
| Si installa il `main` di GitHub | Anche lanciando l'installer da un clone locale. Le modifiche non pushate non arrivano |

**Pacchetti di dominio.** Dopo il core, scegli i pacchetti adatti allo stack dalla tabella [Pacchetti dr-* disponibili](#-pacchetti-dr--disponibili). Il modo più semplice è ricaricare la finestra e chiedere `/dr-scaffold-guidelines`: propone i pacchetti e segna quelli già installati. A mano, con il flag `-Package` sul core:

```powershell
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String))) -Package dr-minimalapi
```

Oppure con l'installer del pacchetto. Gli installer si chiamano sempre `<pacchetto>-install.ps1`, mai `install.ps1`:

```powershell
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-minimalapi/contents/dr-minimalapi-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
```

Un nome di pacchetto sconosciuto produce un errore con l'elenco dei pacchetti disponibili. `-Package` e `-Global` non si usano insieme. Ogni installazione viene registrata in `.ai/dr-guidelines-packages.json`.

**Se `git clone` fallisce** con `git clone fallito per davraf-amuro/...`: git non ha le credenziali per i repo Private. Esegui `gh auth setup-git` e riprova.

---

## 📦 Cosa viene configurato

Dopo `dr-guidelines-install.ps1`, il progetto host contiene:

| File/Cartella | Provenienza | Scopo |
|---------------|-------------|-------|
| `.editorconfig` | copia | Stile di codice e naming conventions |
| `.gitignore` | copia | File ignorati da Git, compresi `.mcp.json` e `.claude/settings.local.json` |
| `.gitattributes` | copia | Normalizzazione dei fine riga |
| `.mcp.json` | copia da `.mcp.example.json`, solo se assente | Server MCP consigliati. Se esiste con contenuto diverso: `[WARN]`, mai sovrascritto |
| `.github/instructions/`, `.github/prompts/` | copia file per file | Istruzioni e prompt del core, per Copilot e Claude Code |
| `.claude/skills/` | copia cartella per cartella | Skill Claude Code del core (`/dr-scaffold`, `/dr-professor`, `/dr-get-latest`, …) |
| `.claude/settings.json` | copia se assente, altrimenti merge additivo | Permessi condivisi: aggiunge solo le voci `permissions.allow` mancanti. Le altre chiavi (`mcpServers`, `env`, `hooks`) restano intatte |
| `CLAUDE.md` | creato o aggiornato | Sezione `<!-- dr-guidelines --> ... <!-- /dr-guidelines -->`. Il resto del file resta com'è |
| `.ai/dr-scaffolding-catalog.json` | copia | Catalogo di domini, tipologie e pacchetti, letto dalle skill `dr-scaffold*` |
| `.ai/dr-guidelines-packages.json` | creato o aggiornato | Manifest dei pacchetti installati con il **commit** di provenienza: fa da lock file, e `-Update` lo usa per mostrare cosa è cambiato |

> ⚠️ **Non viene copiato `.github/copilot-instructions.md`**, anche se la sezione `CLAUDE.md` iniettata lo richiama con `@.github/copilot-instructions.md`. Comportamento attuale di `dr-guidelines-install-lib.ps1`, da correggere. Nel frattempo il file va copiato a mano.

I pacchetti di dominio installano le proprie `.github/instructions/`, `.github/prompts/`, `.claude/skills/` e i **file di radice dichiarati nel catalogo** (campo `rootFiles`). Non toccano `CLAUDE.md` né la configurazione del core.

> **Il core non è un pacchetto .NET.** `Directory.Build.props` e `global.json` appartengono a `dr-dotnet-backend`. Un frontend, un firmware o un repository di documenti non li riceve. Un progetto .NET li ottiene con quel pacchetto, che arriva da solo con `dr-minimalapi` e `dr-winsvc`.

---

## 🔄 Aggiornare le Guidelines

**Tutti i pacchetti del progetto, in un colpo solo:**

```
/dr-get-latest
```

Legge `.ai/dr-guidelines-packages.json` e riesegue l'installer di ogni pacchetto con `-Update`.

**Un solo pacchetto**, dalla root del progetto:

```powershell
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String))) -Update
```

A repo Public vale anche la forma breve:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1))) -Update
```

`-Update` sovrascrive i file già presenti con la versione corrente del pacchetto. Per il core riscrive anche la sezione in `CLAUDE.md`, lasciando intatto il resto. Per un pacchetto di dominio sostituisci nome del repo e dell'installer.

Nessun submodule e nessun `git submodule update`: la distribuzione non li usa.

**Linee guida globali** (`~/.claude/CLAUDE.md`, valide su tutti i progetti):

```
/dr-install-global aggiorna
```

Equivalente da riga di comando:

```powershell
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String))) -Global -Update
```

Viene riscritta **solo** la sezione tra `## Davraf Guidelines (Globale)` e `<!-- /davraf-guidelines -->`. Senza `-Update`, una sezione già presente resta com'è (`[SKIP]`).

---

## 🤖 Istruzioni Modulari (Copilot / Claude)

Contenuto **core**. Le istruzioni di dominio (Minimal API, Windows Service, EF Core, frontend, DevOps) vivono nei rispettivi pacchetti: vedi [Pacchetti dr-* disponibili](#-pacchetti-dr--disponibili).

| File | Quando usarlo |
|------|---------------|
| `.github/copilot-instructions.md` | Istruzioni principali, lette automaticamente da Copilot. Individuano il dominio dai pacchetti installati |
| `dev-cycle.instructions.md` | Ciclo obbligatorio per ogni task AI: dichiara, esegui, verifica |
| `plan-tracking.instructions.md` | Piano su disco in `.ai/plans/<YYYY-MM-DD>-<slug>/` per ogni task con ≥ 2 operazioni |
| `code-organization.instructions.md` | Struttura di classi e file, commenti obbligatori (tutti i linguaggi) |
| `no-hardcoded-values.instructions.md` | Centralizzazione dei valori letterali: cosa estrarre, dove, cosa lasciare inline (tutti i linguaggi) |
| `input-validation.instructions.md` | Un validatore per ogni input esterno (esempi con `IValidator<T>`) |
| `logging.instructions.md` | Logging strutturato con placeholder, mai interpolazione (esempi Serilog) |
| `sensitive-data.instructions.md` | Gestione di credenziali e dati sensibili |
| `doc-versioning.instructions.md` | Footer di revisione obbligatorio nei documenti in `docs/` |
| `readme-structure.instructions.md` | Struttura obbligatoria di questo README |
| `mcp-tool-readme.instructions.md` | README per MCP server (`tools/**/README.md`) |
| `mcp-server-discovery.instructions.md` | Ricerca e creazione di MCP server: cerca prima di creare |

---

## 🤖 Claude Code Skills

Skill **core**, disponibili dopo l'installazione di `dr-guidelines` e un riavvio di Claude Code.

### `/dr-scaffold` — Scaffolding Guidato (punto d'ingresso)

Risolve il dominio, verifica i prerequisiti, rileva lo stato della cartella e delega alla skill giusta. È il comando da usare quando non sai quale serve.

**Uso:**
```
/dr-scaffold crea una Minimal API per gli ordini
/dr-scaffold aggiungi un worker al progetto
```

### `/dr-scaffold-solution` — Solution da Zero

Solution .NET 10 (formato `slnx`), progetti in `src/` e `test/`, frontend Vue, eventuale workspace VS Code multi-repo, `git init` e pacchetti `dr-*`. Tutte le domande prima, dry-run dell'albero, **una sola** conferma.

**Uso:**
```
/dr-scaffold-solution
```

### `/dr-scaffold-project` — Aggiungi un Progetto

Aggiunge un progetto a una solution: tipologia dal catalogo, creazione, aggancio con `dotnet sln add`, build e `dotnet format` di verifica. Se la solution non esiste propone di crearla e passa il lavoro a `/dr-scaffold-solution`.

**Uso:**
```
/dr-scaffold-project worker chiamato ordini.service
```

### `/dr-scaffold-guidelines` — Installa i Pacchetti

Rileva lo stack, propone i pacchetti pertinenti segnando quelli già installati, esegue gli installer dalla root del repository. Per **aggiornare** pacchetti già presenti usa `/dr-get-latest`.

**Uso:**
```
/dr-scaffold-guidelines
```

### `/dr-get-latest` — Aggiornamento Pacchetti

Aggiorna tutti i pacchetti tracciati in `.ai/dr-guidelines-packages.json`, rieseguendo il rispettivo `<pacchetto>-install.ps1 -Update`.

**Uso:**
```
/dr-get-latest
```

### `/dr-install-global` — Linee Guida su Tutto il PC

Installa o aggiorna la sezione linee guida in `~/.claude/CLAUDE.md`, caricato da Claude Code in ogni sessione. Mostra cosa verrà scritto e cosa resta intatto, poi chiede **una conferma esplicita**: il file è fuori dal repository e nessun `git checkout` lo annulla.

**Uso:**
```
/dr-install-global
/dr-install-global aggiorna
```

### `/dr-segnala-miglioria` — Apri una Issue nel Pacchetto Corretto

Individua il pacchetto `dr-*` pertinente (dal manifest o dal file citato), compone titolo e corpo, chiede conferma, poi apre la issue con `gh issue create`. Senza `gh` genera un URL precompilato.

**Uso:**
```
/dr-segnala-miglioria la soglia batch size in database-provider.instructions.md non è chiara
```

> **Il pacchetto non si corregge nel progetto host.** Una modifica alla copia locale si perde al primo `-Update`. Ogni repository `dr-*` ha `.github/ISSUE_TEMPLATE/` con due modelli: `miglioria.md` per una richiesta evolutiva, `problema.md` per un malfunzionamento. Su GitHub Copilot lo stesso canale è [`.github/prompts/dr-segnala-miglioria.prompt.md`](.github/prompts/dr-segnala-miglioria.prompt.md).

### `/dr-pianifica-issue` — Piani dalle Issue Aperte

Legge le issue aperte (del repository corrente, di un altro con `--repo`, o di tutti i pacchetti `dr-*` con `--pacchetti`), consiglia di completare i piani già `IN CORSO` e, per le issue che scegli, scrive un piano in `.ai/plans/` consultando le skill di analisi pertinenti (`/dr-warroom`, `/dr-tattico`, `/dr-tech`, audit). Su GitHub legge soltanto: nessun commento, label o chiusura.

**Uso:**
```
/dr-pianifica-issue
/dr-pianifica-issue 12 15
/dr-pianifica-issue --pacchetti
```

> **Scrivere un piano non significa eseguirlo.** I piani nascono con `Stato: PROPOSTO` e il campo `Issue: <owner/repo>#<n>`: non ripartono all'avvio della sessione e diventano `IN CORSO` solo quando approvi quello da eseguire (`plan-tracking.instructions.md`, sezione "Piani proposti"). Su GitHub Copilot: [`.github/prompts/dr-pianifica-issue.prompt.md`](.github/prompts/dr-pianifica-issue.prompt.md).

### `/dr-warroom` — Tavolo di Lavoro Multi-Agente

Cinque esperti in parallelo (ARCH, BE, UI, UX, DBADMIN) analizzano una domanda tecnica o di prodotto e producono posizioni, tensioni e una raccomandazione.

**Uso:**
```
/dr-warroom come strutturiamo l'autenticazione in questa Minimal API?
```

### `/dr-professor` — Redazione Documentazione

Crea, aggiorna e revisiona documentazione tecnica con linguaggio chiaro, rispettando le istruzioni del progetto.

**Uso:**
```
/dr-professor aggiorna la documentazione del progetto
```

### `/dr-tattico` — Progettazione Prompt AI

Crea o revisiona prompt per agenti e assistenti IA, analizza fallimenti e ambiguità.

**Uso:**
```
/dr-tattico rivedi il prompt di sistema dell'agente di onboarding
```

### `/dr-tech` — Rilascio e Infrastruttura

Deployment e infrastruttura IT: Docker, IIS, Git, Swagger/OpenAPI, preparazione degli ambienti.

**Uso:**
```
/dr-tech pianifica il rilascio della nuova versione su Docker Swarm
```

### `/dr-promote-to` — Commit, Push e Pull Request

Promuove il branch corrente verso un branch target: commit delle modifiche pendenti, push, apertura della PR. Chiede conferma prima del merge, salvo `--merge` esplicito.

**Uso:**
```
/dr-promote-to main
/dr-promote-to staging --merge --delete
```

### `/dr-snapshot` — Contesto Progetto per Claude

Genera o aggiorna `.ai/context/snapshot.md`: riassunto denso del progetto, leggibile in una sola lettura senza riscansionare il codice a ogni sessione.

**Uso:**
```
/dr-snapshot
```

### `/dr-CreateLaunchProfiles` — Profili di Avvio VS Code

Genera o aggiorna `.vscode/launch.json` e `.vscode/tasks.json`. Rileva lo stack, chiede quali profili creare e applica solo quelli scelti, senza sovrascrivere l'esistente.

**Uso:**
```
/dr-CreateLaunchProfiles
/dr-CreateLaunchProfiles vue + api
```

### `/dr-handoff` — Documentazione di Passaggio

Genera la documentazione di handoff per far continuare il lavoro a un altro sviluppatore o a un altro LLM senza perdita di contesto.

**Uso:**
```
/dr-handoff
```

### `/dr-verify-plan` — Verifica Indipendente di un Piano

Lancia un subagente senza il contesto di chi ha implementato: rilegge i file di Scope, li confronta con il piano e valuta i criteri di verifica prima dello stato `COMPLETATO`. Chi ha scritto il codice tende a confermarlo; un controllo a freddo no.

**Uso:**
```
/dr-verify-plan
```

---

## 🔌 MCP Servers

Il repository include `.mcp.example.json` come riferimento. La configurazione reale sta in `.mcp.json`, ignorato da git perché può contenere credenziali. L'installer lo genera la prima volta e non lo sovrascrive più.

### `pdf-reader` — Lettura di file PDF

Permette a Claude Code di leggere e interrogare file PDF del progetto.

**Prerequisito** (una volta sola, come amministratore):
```powershell
npm install -g @fabriqa.ai/pdf-reader-mcp
```

**Setup nel progetto** — lascia fare all'installer, oppure aggiungi al `.mcp.json` esistente:
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

| File | Contenuto |
|------|-----------|
| [`docs/guida-nuova-soluzione.md`](docs/guida-nuova-soluzione.md) | **Da qui si parte.** Dalla cartella vuota alla solution: prerequisiti, installazione del core, `/dr-scaffold`, errori comuni |
| [`docs/bozza-manuale-installazione.md`](docs/bozza-manuale-installazione.md) | Taccuino delle prove sul campo: passaggi verificati, da verificare, correzioni emerse |
| [`docs/test-progetto-host.md`](docs/test-progetto-host.md) | Collaudo dell'installer su un progetto di prova: dipendenze, idempotenza, `-Update`, skill |
| [`docs/onboarding.md`](docs/onboarding.md) | Onboarding per chi sviluppa questo repository |
| [`docs/card-dr-guidelines.md`](docs/card-dr-guidelines.md) | Scheda riassuntiva del progetto |
| [`docs/scaffolding-minimal-api.md`](docs/scaffolding-minimal-api.md) | Struttura interna di una Minimal API generata: domande, file, convenzioni |
| [`docs/scaffolding-windows-service.md`](docs/scaffolding-windows-service.md) | Struttura interna di un Windows Service generato: domande, file, convenzioni |
| [`docs/scaffolding-crud.md`](docs/scaffolding-crud.md) | Endpoint CRUD per una tabella: domande, file, regole sui tipi |

> I tre `scaffolding-*.md` vengono dal repo `davraf-guidelines` precedente allo split. Descrivono la struttura interna dei progetti (Dto, Endpoints, Workers, Validators), contenuto ancora valido e indipendente dal meccanismo di installazione.

---

## ❓ FAQ

### Q: Devo rendere pubblici i repo `dr-*` per usarli o testarli?
**A:** No. Basta `gh` autenticato con scope `repo` (`gh auth status`). Usa la forma `gh api` dei comandi: funziona su repo Private e Public. Solo `irm https://raw.githubusercontent.com/... | iex` richiede repo Public.

### Q: I repo sono Private — `irm ... | iex` funziona lo stesso?
**A:** No: `raw.githubusercontent.com` risponde `404` sui repo Private. Usa la forma `gh api`, che è autenticata e scarica lo stesso da GitHub, senza clone locale. Vale anche per `-Update`, `-Package` e `-Global`: basta aggiungere il flag in coda al comando.

### Q: Creo prima la solution e poi installo le guidelines?
**A:** No, al contrario. Prima il core in una cartella vuota, poi ricarichi la finestra, poi `/dr-scaffold` crea la solution. Vedi [`docs/guida-nuova-soluzione.md`](docs/guida-nuova-soluzione.md).

### Q: Ho corretto un pacchetto `dr-*` ma il progetto host non cambia. Perché?
**A:** L'installer clona sempre il `main` da GitHub, anche se lo lanci da un clone locale. Fai push della correzione nel repo del pacchetto, poi `/dr-get-latest` nel progetto host.

### Q: Posso usare le guidelines su un progetto già esistente?
**A:** Sì. Dalla root del repository installa il core (vedi [Progetto Esistente](#-progetto-esistente--aggiungere-le-guidelines)), ricarica la finestra e usa `/dr-scaffold-guidelines` per i pacchetti di dominio.

### Q: L'installer richiede git?
**A:** Sì. Usa `git clone --depth 1` per scaricare il pacchetto in una cartella temporanea. Senza git l'installazione non parte, e `/dr-scaffold` lo verifica prima di scrivere.

### Q: `git clone fallito per davraf-amuro/...` — cosa faccio?
**A:** git non ha le credenziali per i repo Private. Esegui `gh auth setup-git`, poi rilancia l'installer.

### Q: Devo committare i file `.github/` e `.claude/`?
**A:** Sì. L'installer li copia come file reali, non come junction o submodule.

### Q: Posso avere le guidelines attive su tutto il PC, senza installarle in ogni progetto?
**A:** In parte. `/dr-install-global` scrive la sezione linee guida in `~/.claude/CLAUDE.md`, caricato in ogni sessione. Non sostituisce l'installazione nel progetto: istruzioni modulari, skill e configurazione radice arrivano solo installando nel repository. In caso di conflitto vale il `CLAUDE.md` del progetto.

### Q: Posso usare .NET 8 invece di .NET 10?
**A:** Sì. Dopo l'installazione di `dr-dotnet-backend`, modifica `Directory.Build.props` e `global.json` nel tuo progetto. Attenzione: un `-Update` di quel pacchetto li sovrascrive.

### Q: GitHub Copilot non segue le istruzioni
**A:** Verifica che `.github/copilot-instructions.md` sia presente e committato, poi riavvia VS o VS Code. Attenzione: oggi l'installer **non** copia quel file nel progetto host (copia solo `.github/instructions/` e `.github/prompts/`), anche se la sezione `CLAUDE.md` iniettata lo richiama. Finché non viene corretto, copialo a mano da questo repository.

### Q: L'installer fallisce a metà — come ripristino?
**A:** Se il repository ha già un commit: `git clean -fd` e `git checkout -- .`, poi rilancia. L'installer è idempotente e salta i file già a posto.

---

*Documento aggiornato: Settembre 2026 — Revisione v3.4 — 2026-09-22 — claude-opus-5*
