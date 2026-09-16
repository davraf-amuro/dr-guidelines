# Piano: revisione suite dr-* — core agnostico, domini arbitrari, feedback via issue
Data: 2026-09-16
Stato: COMPLETATO PARZIALE — blocchi A, B, C, E, F completati e verificati; blocco D (repo `dr-esp32` e `dr-travelguide`) differito su decisione dell'utente al gate D1.

## Verifica finale

Eseguita il 2026-09-16 con `/dr-verify-plan`, in contesto isolato da chi ha implementato (`plan-tracking` Fase 4 punto 4). Esito: 16 file di Scope su 17 `CORRISPONDE`, un `NON CORRISPONDE` su `README.md`, poi corretto. Le correzioni scaturite dalla verifica:

1. **`README.md` del repo legacy dichiarava un'archiviazione mai avvenuta.** Il footer diceva "Repository archiviato il 2026-09-16" mentre `gh repo view` riporta `isArchived: false`; il repository per giunta è **pubblico**, quindi l'affermazione falsa era visibile a chiunque. Corretto e pushato (`b44855e`).
2. **`README.md` del core**, righe 3 e 47: la frase di apertura descriveva ancora il core come "meccanismo di installazione per progetti .NET 10", e il flusso di `/dr-scaffold` riportava il gate prerequisiti .NET incondizionato, cioè il comportamento precedente alla Fase C3. Riscritte entrambe.
3. **Violazione della compatibilità duale** (regola non negoziabile di `CLAUDE.md`): `.github/prompts/dr-scaffold.prompt.md`, l'equivalente Copilot della skill, non era stato aggiornato con la Fase 0-pre e il gate condizionale. Le due superfici si sarebbero comportate diversamente. Allineato.
4. **Documentazione di un comportamento eliminato**: `dr-scaffold-guidelines`, `dr-scaffold-solution`, `docs/onboarding.md`, `docs/test-progetto-host.md`, `docs/bozza-manuale-installazione.md` e `.template.config/template.json` descrivevano ancora il rilevamento automatico dello stack e l'output `[SKIP] Directory.Build.props, global.json (host non .NET)`, che il codice non può più produrre dopo la rimozione di `Test-DotnetHost`. Riscritti.
5. **Omissioni nella tabella "Cosa viene configurato"** del README: mancava `.ai/dr-scaffolding-catalog.json`, e il manifest non era descritto come lock file con il commit.

I criteri 10 e 11 sono marcati `[~] DIFFERITO` insieme alle fasi D1-D3 a cui appartengono, invece di essere spuntati: la parte architetturale (ramo di fallback) è completa, i due domini specifici no.

## Obiettivo
Chiudere il repo legacy, svuotare `dr-guidelines` del contenuto .NET e trasformarlo nell'indice che instrada l'agente verso i pacchetti-guida di qualsiasi dominio, a partire da ESP32 e guida turistica.

## Contesto

Origine: `TODO/01-revisione.md`. Analisi multi-agente del 2026-09-16 (`/dr-warroom`): convergenza ARCH/BE/UI/UX su "core svuotato, catalogo come registry unico, `dr-segnala-miglioria` esteso invece che riprogettato". DBADMIN: nessun intervento database, JSON versionato in git è la scelta corretta.

Decisioni utente del 2026-09-16:
- ESP32 e guida turistica sono esigenze **attuali**, da implementare presto → la generalizzazione del catalogo entra in questo piano, non viene rimandata.
- Pacchetto ESP32 → toolchain **PlatformIO** (VS Code), che copre anche Arduino core come framework.
- Pacchetto guida turistica → **contenuto documentale + sito web standalone per cellulare** (mobile-first, fruibile offline).

### Delta legacy misurato (ricalcolato in Fase A1 dopo `git pull`, 2026-09-16)

La pull ha portato 2 commit remoti (`2460b8f`, `897af0e`) che non erano nella misurazione iniziale e che **ampliano il delta da 2 a 5 elementi**. Il legacy è avanti su:

| # | Elemento | Stato | Fase |
|---|---|---|---|
| 1 | `no-hardcoded-values.instructions.md` | **Assente in tutti i 7 repo dr-*** → destinazione `dr-guidelines` (trasversale) | A2 |
| 2 | `.editorconfig` | Nel legacy ha `end_of_line = lf` + commento esplicativo; nel core manca (4 righe) | A3 |
| 3 | Skill `verify-plan` | **Assente nella suite** — verifica finale di un piano affidata a un subagente senza il contesto di chi ha implementato. Nel core va come `dr-verify-plan` (regola prefisso) | A2b |
| 4 | `plan-tracking.instructions.md` | Legacy **v1.4** (2026-08-19), core **v1.3**: la Fase 4 punto 3 rimanda a dev-cycle invece di duplicare, e il nuovo punto 4 impone la verifica in contesto isolato. **Merge bidirezionale**: il core ha la correzione `/dr-promote-to` che il legacy non ha | A3b |
| 5 | Propagazione di `.claude/settings.json` ai progetti host | `setup.ps1` del legacy la implementa (~65 righe, con merge delle voci `permissions.allow` esistenti); `dr-guidelines-install-lib.ps1` **non ha alcuna occorrenza** di `settings.json` | A3c |

Sei file sono più recenti **nei dr-*** (docker-swarm-compose, frontend-organization, mcp-server-discovery, minimal-api-architecture, readme-structure, più le skill già rinominate con prefisso `dr-`): nessuna propagazione, il legacy è indietro.

Cinque file divergono con **stessa data di commit** (database-provider, database-startup-resilience, gitlab-ci-cd, portainer-swarm-stack, windows-service) più tre prompt (card-minimal-api, card-worker-service, endpoints-analyzer): divergenza presumibilmente cosmetica introdotta dalla migrazione, da ispezionare prima di chiudere il legacy.

Tutte le altre 11 skill del legacy risultano presenti nella suite con il prefisso `dr-`.

### Debito rilevato durante l'analisi

- **Doppio registry dei pacchetti**: `$Script:PackageRegistry` in `dr-guidelines-install-lib.ps1` (righe 12-20) e l'array `packages` in `scaffolding-catalog.json`. Aggiungere un pacchetto oggi richiede due modifiche allineate a mano.
- **Contenuto .NET nel core**: `Directory.Build.props`, `global.json`, e `.github/copilot-instructions.md` che si apre con "Progetto .NET 10" più la tabella di rilevamento tipo e il gate di push lint.
- **Asimmetria Claude/Copilot**: `dr-segnala-miglioria` e `dr-get-latest` non hanno equivalente in `.github/prompts/`; l'utente Copilot non ha canale di feedback.
- **Vicolo cieco sui domini non coperti**: oggi nessun ramo previsto se l'attività richiesta non ha un pacchetto.

## Scope

### File da modificare
- [x] `.github/instructions/no-hardcoded-values.instructions.md` — CREATE, propagato dal legacy
- [x] `.editorconfig` — EDIT, aggiunta `end_of_line = lf`
- [x] `.claude/skills/dr-verify-plan/SKILL.md` — CREATE, propagato dal legacy con prefisso `dr-`
- [x] `.github/instructions/plan-tracking.instructions.md` — EDIT, merge v1.4 mantenendo `/dr-promote-to`
- [x] `.claude/settings.json` + `dr-guidelines-install-lib.ps1` — EDIT, propagazione dei permessi al progetto host
- [x] `scaffolding-catalog.json` — EDIT, schemaVersion 2 + intentMap + nuovi domini
- [x] `dr-guidelines-install-lib.ps1` — EDIT, registry letto dal catalogo, rimozione copia file .NET
- [x] `.github/copilot-instructions.md` — EDIT, reso agnostico dallo stack
- [x] `README.md` — EDIT, tabella pacchetti aggiornata
- [x] `.claude/skills/dr-segnala-miglioria/SKILL.md` — EDIT, ramo "dominio non coperto"
- [x] `.claude/skills/dr-scaffold/SKILL.md` — EDIT, routing per intento
- [x] `.github/prompts/dr-segnala-miglioria.prompt.md` — CREATE (parità Copilot)
- [x] `.github/prompts/dr-get-latest.prompt.md` — CREATE (parità Copilot)
- [x] `.github/ISSUE_TEMPLATE/` — CREATE in tutti i repo dr-*
- [ ] Repo nuovo `dr-esp32` — CREATE
- [ ] Repo nuovo `dr-travelguide` — CREATE
- [x] Repo `dr-dotnet-backend` — riceve `Directory.Build.props`, `global.json` e le regole .NET del core

### Perimetro negativo
- Non toccherò i progetti host già esistenti che hanno installato i pacchetti dr-*
- Non farò `git push` (regola esecutore 6 di `plan-tracking`): il push resta gesto umano dopo gate lint
- Non archivierò `davraf-guidelines` su GitHub senza conferma esplicita nella Fase A5
- Non introdurrò semver/release: la suite resta "sempre latest" fino a decisione separata
- Non toccherò le skill non citate nello Scope
- Non sposterò il pinning SHA e l'hardening supply chain dentro le fasi bloccanti: vivono in Fase F

---

## Fasi

### Fase A1: pull del legacy
- **Stato**: [x] — eseguita 2026-09-16. `git pull --ff-only` ha portato `2460b8f` e `897af0e`; HEAD legacy = `897af0e`. Delta ricalcolato e riscritto nella sezione Contesto: **5 elementi**, non 2. Le fasi A2b, A3b e A3c coprono i tre elementi emersi.
- **Precondizione**: `E:\Davide\Progetti\davraf-guidelines` è un clone git con remote `davraf-amuro/davraf-guidelines`
- **File**: nessuno (sola lettura)
- **Operazione**: verifica
- **Azione**: eseguire `git pull` nel repo legacy e ricalcolare il delta verso i 7 repo dr-* (confronto file per file di `.github/instructions/`, `.github/prompts/`, `.claude/skills/`, file di configurazione radice). Registrare in questo plan.md l'elenco aggiornato dei file dove il legacy è avanti.
- **Tool ammessi**: Bash/PowerShell (git read-only, diff)
- **Verifica passo**: il delta ricalcolato è scritto in plan.md; se coincide con quello già misurato, dichiararlo esplicitamente
- **Su divergenza**: STOP — se la pull porta commit non previsti, scrivi `⚠️ Divergenza Fase A1: <cosa>` e rivedi le fasi A2-A4

### Fase A2: propaga `no-hardcoded-values`
- **Stato**: [x] — file copiato nel core (già multi-linguaggio: C#, TypeScript, Python — nessuna neutralizzazione necessaria) e citato nella tabella instructions del README.
- **Precondizione**: Fase A1 conferma che il file è assente in tutti i dr-*
- **File**: `.github/instructions/no-hardcoded-values.instructions.md`
- **Operazione**: CREATE
- **Azione**: copiare il file dal legacy nel core `dr-guidelines`, verificando che il frontmatter `applyTo: "**"` e il linguaggio restino agnostici dallo stack (regola trasversale, non .NET). Aggiungere il riferimento nell'elenco delle instructions del `README.md`.
- **Tool ammessi**: Read, Write, Edit
- **Verifica passo**: il file esiste nel core, il contenuto coincide con l'originale salvo eventuale neutralizzazione degli esempi, `README.md` lo cita
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase A2: <cosa>`

### Fase A2b: propaga la skill `verify-plan` come `dr-verify-plan`
- **Stato**: [x] — creata `.claude/skills/dr-verify-plan/SKILL.md`, frontmatter e footer aggiornati, nessun riferimento residuo senza prefisso; aggiunta anche la sezione nel README.
- **Precondizione**: Fase A2 verificata; `.claude/skills/dr-verify-plan/` non esiste nel core
- **File**: `.claude/skills/dr-verify-plan/SKILL.md`
- **Operazione**: CREATE
- **Azione**: copiare `SKILL.md` dal legacy applicando la regola del prefisso: `name: dr-verify-plan`, e ogni riferimento interno alla skill aggiornato. Mantenere invariati il perimetro non negoziabile e la regola che il subagente di verifica è read-only. Le skill sono esenti dal vincolo di compatibilità duale (artefatto Claude Code by design), quindi non serve un prompt Copilot equivalente.
- **Tool ammessi**: Read, Write
- **Verifica passo**: la skill esiste nel core, il frontmatter dichiara `dr-verify-plan`, nessun riferimento residuo al nome senza prefisso
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase A2b: <cosa>`

### Fase A3: propaga `.editorconfig`
- **Stato**: [x] — direttiva `end_of_line = lf` e relativo commento aggiunti dopo `trim_trailing_whitespace`.
- **Precondizione**: Fase A2 verificata
- **File**: `.editorconfig`
- **Operazione**: EDIT
- **Azione**: aggiungere la direttiva `end_of_line = lf` con il commento che ne spiega il motivo (allineamento a `.gitattributes`, altrimenti `dotnet format` usa il newline di piattaforma e lo stesso file risulta conforme su Linux e non su Windows).
- **Tool ammessi**: Edit
- **Verifica passo**: rileggendo il file, la direttiva è presente nella sezione corretta
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase A3: <cosa>`

### Fase A3b: merge di `plan-tracking` alla v1.4
- **Stato**: [x] — Fase 4 punti 3-4 portati dalla v1.4, riferimento scritto `dr-verify-plan`, eccezione `/dr-promote-to` conservata, footer v1.4.
- **Precondizione**: Fase A3 verificata; Fase A2b ha creato `dr-verify-plan` (la v1.4 la cita)
- **File**: `.github/instructions/plan-tracking.instructions.md`
- **Operazione**: EDIT
- **Azione**: portare il file del core alla v1.4 del legacy — Fase 4 punto 3 che rimanda a `dev-cycle.instructions.md` Fase 4 invece di duplicarne il testo, più il nuovo punto 4 che impone il controllo in contesto isolato da chi ha implementato. **Merge, non sovrascrittura**: il riferimento alla skill va scritto `dr-verify-plan` e la regola esecutore 6 deve mantenere l'eccezione `/dr-promote-to` già corretta nel core (il legacy ha ancora `/promote-to`). Aggiornare il footer di versione indicando il merge.
- **Tool ammessi**: Read, Edit
- **Verifica passo**: il file contiene il punto 4 sulla verifica isolata e cita `dr-verify-plan`; nessuna occorrenza di `/promote-to` senza prefisso; footer aggiornato
- **Su divergenza**: STOP — una sovrascrittura cieca reintrodurrebbe il nome skill sbagliato

### Fase A3c: propagazione di `.claude/settings.json` al progetto host
- **Stato**: [x] — aggiunta `Merge-ClaudeSettings` alla lib (merge additivo di `permissions.allow`, UTF-8 senza BOM), agganciata al ramo `IsCore`; aggiunte `Write(.ai/**)` ed `Edit(.ai/**)` al settings del core. Parser PowerShell: zero errori; JSON valido.
- **Precondizione**: Fase A3b verificata
- **File**: `dr-guidelines-install-lib.ps1`, `.claude/settings.json` (core)
- **Operazione**: EDIT
- **Azione**: portare nella lib condivisa il comportamento che oggi esiste solo in `setup.ps1` del legacy (righe ~346-405): copia di `.claude/settings.json` nel progetto host se assente, e se presente **merge additivo** delle voci `permissions.allow` mancanti senza rimuovere quelle già lì, con output `[OK]`/`[UPD] n voci aggiunte`/`[SKIP]` coerente col resto dell'installer. Il file del core contiene già `Edit(/.claude/skills/dr-*/**)`; valutare l'aggiunta di `Write(.ai/**)` ed `Edit(.ai/**)` presenti nel legacy, coerenti con l'esenzione della cartella `.ai/`.
- **Tool ammessi**: Read, Edit
- **Verifica passo**: parser PowerShell senza errori; a lettura del codice, un host con `settings.json` preesistente non perde voci; un host senza lo riceve
- **Su divergenza**: STOP — un merge che sovrascrive i permessi dell'utente è un regresso, non una propagazione

### Fase A4: ispezione delle divergenze a pari data
- **Stato**: [x] — **nessuna propagazione necessaria.** Sugli 8 file a pari data (5 instructions + 3 prompt) il confronto ignorando il ritorno a capo dà **zero righe di differenza**: i file dr-* hanno CRLF nel working tree Windows, il legacy LF. Verificati anche i 5 file dove i dr-* sono avanti: le righe presenti solo nel legacy sono footer di versione superati, rinomine già applicate (`/warroom` → `/dr-warroom`, `CreateLaunchProfiles` → `dr-CreateLaunchProfiles`) e, in `readme-structure`, 36 righe che descrivono il **meccanismo a submodule ormai abbandonato** (`setup.ps1`, `CreateNewSolution.ps1`): propagarle sarebbe un regresso. Controllati singolarmente i concetti a rischio di `minimal-api-architecture` (regola auth, MCP db-schema, nota `OutputPath`): tutti presenti e ampliati nella versione `dr-minimalapi`.
- **Precondizione**: Fase A3 verificata
- **File**: nessuno in scrittura (sola lettura, salvo correzioni puntuali)
- **Operazione**: verifica
- **Azione**: per gli 8 file che divergono a pari data di commit (5 instructions: database-provider, database-startup-resilience, gitlab-ci-cd, portainer-swarm-stack, windows-service; 3 prompt: card-minimal-api, card-worker-service, endpoints-analyzer) produrre il diff testuale e classificare ogni differenza come **cosmetica** (header, footer di versione, path) o **sostanziale** (regola mancante). Solo le sostanziali vengono portate nel pacchetto dr-* corrispondente.
- **Tool ammessi**: Bash (diff), Read, Edit
- **Verifica passo**: ogni file dell'elenco ha un esito registrato in plan.md; nessuna differenza sostanziale resta non portata
- **Su divergenza**: STOP — se emerge una regola presente solo nel legacy, elencala prima di modificare

### Fase A5: chiusura del legacy — GATE UTENTE
- **Stato**: [x] — README di redirect scritto, committato (`f4d188e`) e pushato su `davraf-amuro/davraf-guidelines`. Gate lint: nessun target applicabile nel repo (nessun `.csproj`, `package.json` o sorgente Python) — assenza dichiarata, non saltata. **Archiviazione GitHub rimandata per scelta esplicita dell'utente**: il repo resta scrivibile. Push autorizzato dall'utente nello stesso gate, in deroga alla regola esecutore 6.
- **Precondizione**: Fasi A1-A4 verificate, nessun contenuto del legacy resta non propagato
- **File**: `README.md` del repo `davraf-guidelines`
- **Operazione**: EDIT
- **Azione**: sostituire il README del legacy con un redirect ai repo della suite dr-* (tabella pacchetto → repo → scopo) e la nota che il repo non è più mantenuto. Poi **chiedere conferma esplicita all'utente** prima di archiviare il repo su GitHub (`gh repo archive`, reversibile). Senza conferma, fermarsi al README.
- **Tool ammessi**: Edit; `gh` solo dopo conferma
- **Verifica passo**: README di redirect scritto; archiviazione eseguita solo se confermata, altrimenti annotata come rimandata
- **Su divergenza**: STOP — l'archiviazione non è mai implicita

---

### Fase B1: spostamento dei file .NET nel pacchetto di dominio
- **Stato**: [x] — `Directory.Build.props` e `global.json` copiati in `dr-dotnet-backend` e rimossi dal core con `git rm`.
- **Precondizione**: Fase A5 conclusa (anche con archiviazione rimandata)
- **File**: `Directory.Build.props`, `global.json` (core) e loro copie in `dr-dotnet-backend`
- **Operazione**: CREATE in `dr-dotnet-backend`, DELETE nel core
- **Azione**: copiare `Directory.Build.props` e `global.json` in `dr-dotnet-backend`, poi rimuoverli dalla radice del core. Un progetto host .NET li riceve installando `dr-dotnet-backend`, che è già dipendenza obbligata di `dr-minimalapi` e `dr-winsvc`.
- **Tool ammessi**: Read, Write, Bash (git mv/rm)
- **Verifica passo**: i due file esistono in `dr-dotnet-backend` e non esistono più nel core
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase B1: <cosa>`

### Fase B2: installer allineato allo spostamento
- **Stato**: [x] — rimosso da `Copy-CoreConfigFiles` il ramo condizionale sui due file .NET. Rimossa anche `Test-DotnetHost`, diventata codice morto: era la guardia che serviva solo a quei file, e usarla per un pacchetto di dominio sarebbe un bug (in una cartella vuota salterebbe i file proprio quando servono).
- **Precondizione**: Fase B1 verificata
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: rimuovere dalla funzione che copia i file radice il ramo condizionale che gestisce `Directory.Build.props` e `global.json` (righe ~105-111, incluso il messaggio `[SKIP] ... (host non .NET)`); quei due file non appartengono più al core. Mantenere invariata la copia di `.editorconfig`, `.gitignore`, `.gitattributes`.
- **Tool ammessi**: Edit
- **Verifica passo**: nessuna occorrenza di `Directory.Build.props` o `global.json` resta nella lib; il parser PowerShell (`[System.Management.Automation.Language.Parser]::ParseFile`) riporta zero errori
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase B2: <cosa>`

### Fase B3: installer di `dr-dotnet-backend` copia i file radice .NET
- **Stato**: [x] — risolto con un meccanismo generico invece che con codice dedicato al singolo pacchetto: nuova `Copy-PackageRootFiles` nella lib, chiave `RootFiles` nel registry (`dr-dotnet-backend` dichiara i due file) e chiamata in `Install-DrPackage` per ogni pacchetto che la dichiara. Il campo `rootFiles` è stato aggiunto anche a `scaffolding-catalog.json`, pronto per la Fase C2. Thin wrapper del pacchetto non toccato. Parser PowerShell: zero errori.
- **Precondizione**: Fase B2 verificata
- **File**: `dr-dotnet-backend/dr-dotnet-backend-install.ps1` e/o la lib condivisa
- **Operazione**: EDIT
- **Azione**: fare in modo che l'installazione di `dr-dotnet-backend` copi nel progetto host `Directory.Build.props` e `global.json`, con la stessa semantica `[SKIP]`/`[UPD]` degli altri file. Se la lib condivisa non prevede file radice per pacchetto, introdurre il meccanismo lì (una sola volta, riusabile dagli altri domini).
- **Tool ammessi**: Read, Edit
- **Verifica passo**: parser PowerShell senza errori; a lettura del codice, un host che installa `dr-dotnet-backend` riceve i due file
- **Su divergenza**: STOP — se serve un meccanismo generico di "file radice per pacchetto", questo è giudizio architetturale: rimanda al planner

### Fase B4: `copilot-instructions.md` del core reso agnostico
- **Stato**: [x] — core riscritto alla v2.0 agnostica: sezione "Dominio del progetto" che legge i pacchetti installati da `.ai/dr-guidelines-packages.json`, convenzioni riformulate senza costrutti .NET, gate di push che rimanda al comando dichiarato dal dominio e impone di dichiarare l'assenza di target. Il contenuto .NET è ora in `dr-dotnet-backend/.github/instructions/dotnet-project-type.instructions.md` (tabella di rilevamento tipo, convenzioni .NET, file di progetto comuni, gate `dotnet format`). Nel `CLAUDE.md` del core il titolo "Standard di progetto .NET" è diventato "Standard di progetto (trasversali)".
- **Precondizione**: Fase B3 verificata
- **File**: `.github/copilot-instructions.md` (core) e `dr-dotnet-backend/.github/instructions/` (destinazione)
- **Operazione**: EDIT nel core, CREATE nel pacchetto
- **Azione**: togliere dal core l'apertura "Progetto .NET 10", la tabella di rilevamento tipo basata su `Workers/*.cs` / `Endpoints/*.cs` / `package.json`, la checklist post-generazione .NET e il gate di push lint con i comandi per stack. Spostare quel contenuto in un'istruzione di `dr-dotnet-backend`. Nel core resta: lingua, ciclo di sviluppo, piano su disco, verifica post-modifica, convenzioni trasversali, e un gate di push formulato in modo neutro ("esegui il lint dichiarato dal pacchetto di dominio installato; assenza di target va dichiarata, non saltata in silenzio").
- **Tool ammessi**: Read, Write, Edit
- **Verifica passo**: nel `copilot-instructions.md` del core nessuna occorrenza di `.csproj`, `dotnet`, `Workers/`, `Endpoints/`; il contenuto rimosso è presente in `dr-dotnet-backend`
- **Su divergenza**: STOP — nessuna regola trasversale va persa nello spostamento

---

### Fase C1: catalogo `schemaVersion: 2`
- **Stato**: [x] — catalogo portato a v2 con quattro blocchi nuovi: `kinds` (dotnet, node, embedded, content, any, ciascuno con i propri prerequisiti), `domains` (dotnet-backend, web-frontend, devops), `intentMap` (frasi in linguaggio naturale per dominio) e `fallback` (comportamento dichiara-e-proponi con repo e skill di destinazione). `projectTypes` e `packages` invariati e retrocompatibili. Validato con ConvertFrom-Json.
- **Precondizione**: Fase B4 verificata
- **File**: `scaffolding-catalog.json`
- **Operazione**: EDIT
- **Azione**: portare il catalogo a `schemaVersion: 2` con: (a) campo `domains[]` di primo livello — ogni dominio ha `id`, `label`, `packages[]`, `kind` esteso oltre `dotnet|node` per includere almeno `embedded` e `content`; (b) `appliesTo` dei pacchetti allineato ai nuovi `kind`; (c) blocco `intentMap[]` che associa frasi in linguaggio naturale ("progetto per ESP32", "guida turistica", "API REST") al dominio corrispondente; (d) campo `fallback` che descrive il comportamento quando nessun dominio corrisponde. Mantenere `projectTypes` retrocompatibile.
- **Tool ammessi**: Edit, Read
- **Verifica passo**: il JSON è valido (`ConvertFrom-Json` senza errori), contiene `schemaVersion: 2`, `domains`, `intentMap`, `fallback`, e ogni pacchetto esistente resta presente
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase C1: <cosa>`

### Fase C2: registry unico
- **Stato**: [x] — hashtable letterale sostituita da `Get-DrCatalog` + `Get-DrPackageRegistry`, che leggono `scaffolding-catalog.json` con la stessa catena di fallback dei wrapper (raw pubblico, copia locale, gh api) e nessun elenco incorporato di ripiego. Verificato a runtime: 7 pacchetti caricati con dipendenze e rootFiles corretti. **Anticipata qui una parte di F1**: siccome l'URL da clonare ora arriva da un file di dati, è stata aggiunta l'allowlist dell'owner, testata con un catalogo ostile e rifiutata come atteso.
- **Precondizione**: Fase C1 verificata
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: sostituire la hashtable letterale `$Script:PackageRegistry` (righe 12-20) con la lettura di `scaffolding-catalog.json` — scaricato dal repo core con la stessa catena di fallback già usata per la lib (raw pubblico → clone locale → `gh api`). Mantenere la forma della hashtable in memoria per non toccare le funzioni chiamanti. Se il catalogo non è raggiungibile, errore esplicito: nessun fallback silenzioso su un elenco incorporato.
- **Tool ammessi**: Read, Edit
- **Verifica passo**: nessuna lista di pacchetti resta scritta a mano nella lib; parser PowerShell senza errori; l'installazione del core in una cartella di prova completa senza errori
- **Su divergenza**: STOP — un doppio registry residuo vanifica la fase

### Fase C3: routing per intento nella skill di ingresso
- **Stato**: [x] — aggiunta la Fase 0-pre che risolve il dominio dalla `intentMap` del catalogo e ne ricava il `kind`. Il gate prerequisiti è ora condizionale: git/pwsh/gh sempre, SDK .NET solo per `dotnet`, node/npm solo per `node`, PlatformIO solo per `embedded`, niente toolchain per `content`. Aggiunta la tabella di delega per i kind senza contenitore di progetto, per non forzare una solution .NET su un dominio che non la prevede.
- **Precondizione**: Fase C2 verificata
- **File**: `.claude/skills/dr-scaffold/SKILL.md`
- **Operazione**: EDIT
- **Azione**: inserire, prima del gate prerequisiti, un passo di risoluzione dell'intento: leggere `intentMap` dal catalogo, individuare il dominio dell'attività richiesta e proporre i pacchetti di quel dominio. Il gate prerequisiti diventa **dipendente dal dominio** (SDK .NET 10 solo per domini `dotnet`; PlatformIO per `embedded`; node per `content`/`node`). Punto d'ingresso invariato: `/dr-scaffold`, una sola conferma finale, come oggi.
- **Tool ammessi**: Read, Edit
- **Verifica passo**: la skill non richiede più SDK .NET 10 in modo incondizionato; il passo di risoluzione intento è esplicito e legge dal catalogo
- **Su divergenza**: STOP — non duplicare la intent-map dentro la skill: la fonte è il catalogo

### Fase C4: ramo "dominio non coperto"
- **Stato**: [x] — `dr-scaffold` applica il blocco `fallback` quando nessun dominio corrisponde: dichiara il gap, offre il core generico o l'apertura di una issue. `dr-segnala-miglioria` ha ora il caso "gap di catalogo" (destinazione fissa `dr-guidelines`), la variante "nuovo pacchetto" per titolo e corpo, e la riga corrispondente nei casi limite. La conferma esplicita prima di creare la issue resta obbligatoria.
- **Precondizione**: Fase C3 verificata
- **File**: `.claude/skills/dr-scaffold/SKILL.md`, `.claude/skills/dr-segnala-miglioria/SKILL.md`
- **Operazione**: EDIT
- **Azione**: quando `intentMap` non produce corrispondenza, la skill dichiara all'utente che nessun pacchetto copre il dominio, propone di proseguire con il solo core generico e offre di aprire una issue di richiesta nuovo pacchetto sul repo `dr-guidelines` — delegando a `dr-segnala-miglioria`, che va esteso con il caso "gap di catalogo" oltre a "miglioria su pacchetto esistente". Conferma esplicita prima di aprire la issue, come già fa la skill.
- **Tool ammessi**: Read, Edit
- **Verifica passo**: entrambe le skill descrivono il ramo; nessun percorso porta a un vicolo cieco senza opzione offerta
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase C4: <cosa>`

---

### Fase D1: repo `dr-esp32` — GATE UTENTE sulla creazione
- **Stato**: [~] RIMANDATA — al gate della Fase D1 l'utente ha risposto "per ora non servono": nessun repo creato. Il contenuto della fase resta valido come specifica per quando servirà.
- **Precondizione**: Fase C4 verificata
- **File**: nuovo repo `davraf-amuro/dr-esp32`
- **Operazione**: CREATE
- **Azione**: chiedere conferma esplicita, poi creare il repo via `gh repo create` (privato, coerente con gli altri) con struttura identica agli altri pacchetti dominio: `.github/instructions/` + `dr-esp32-install.ps1` (thin wrapper, copia da `dr-minimalapi-install.ps1` sostituendo il nome del pacchetto) + `LICENSE`. Contenuto delle instructions, toolchain **PlatformIO**: struttura `platformio.ini` e `src/`/`lib/`/`include/`, gestione degli environment e dei target, librerie e versioni pinnate, convenzioni C/C++ per firmware, logging seriale, gestione della configurazione e dei segreti (WiFi, endpoint) fuori dal sorgente, build/upload/monitor da VS Code.
- **Tool ammessi**: `gh` (dopo conferma), Write
- **Verifica passo**: il repo esiste, contiene i file previsti, l'installer è un thin wrapper valido secondo il parser PowerShell
- **Su divergenza**: STOP — nessuna creazione di repo senza conferma per ciascuno

### Fase D2: repo `dr-travelguide` — GATE UTENTE sulla creazione
- **Stato**: [~] RIMANDATA — stesso gate della D1, stessa risposta. Il nome `dr-travelguide` resta non confermato.
- **Precondizione**: Fase D1 verificata
- **File**: nuovo repo `davraf-amuro/dr-travelguide`
- **Operazione**: CREATE
- **Azione**: chiedere conferma esplicita (incluso il nome, alternativa italiana possibile), poi creare il repo con la stessa struttura. Contenuto su due assi, come deciso: (a) **contenuto documentale** — struttura di una guida (itinerari, schede luogo, POI), convenzioni di stile e tono, gestione fonti e licenze delle immagini, organizzazione dei file Markdown, dati strutturati dei POI; (b) **sito standalone per cellulare** — sito statico mobile-first, funzionante offline (PWA, asset locali, nessuna dipendenza da servizi a runtime), generato dal contenuto del punto (a). Dichiarare `dr-fe` come dipendenza per le convenzioni frontend.
- **Tool ammessi**: `gh` (dopo conferma), Write
- **Verifica passo**: il repo esiste con entrambe le sezioni; la dipendenza da `dr-fe` è dichiarata nel catalogo
- **Su divergenza**: STOP — se il sito richiede uno stack non coperto da `dr-fe`, rimanda al planner

### Fase D3: registrazione dei due domini nel catalogo
- **Stato**: [~] RIMANDATA — dipende da D1 e D2. Nel catalogo restano comunque i `kind` `embedded` e `content` con i loro prerequisiti: sono predisposizione, non pacchetti. Finché non esiste un pacchetto per quei domini, una richiesta ESP32 o guida turistica cade nel ramo `fallback` (Fase C4), che dichiara il gap e offre l'apertura di una issue invece di fallire.
- **Precondizione**: Fasi D1 e D2 verificate
- **File**: `scaffolding-catalog.json`, `README.md`
- **Operazione**: EDIT
- **Azione**: aggiungere `dr-esp32` (kind `embedded`) e `dr-travelguide` (kind `content`, dipendenza `dr-fe`) all'array `packages`, i rispettivi `domains`, e le voci `intentMap` corrispondenti ("progetto ESP32", "firmware", "guida turistica", "itinerario"). Aggiornare la tabella dei pacchetti nel `README.md` del core.
- **Tool ammessi**: Edit
- **Verifica passo**: JSON valido; una richiesta come "crea una guida turistica" risolve a `dr-travelguide` leggendo il solo catalogo; README allineato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase D3: <cosa>`

---

### Fase E1: issue template in tutti i repo
- **Stato**: [x] — `miglioria.md` e `problema.md` creati in `.github/ISSUE_TEMPLATE/` di **tutti e 7** i repo della suite (i 9 previsti erano 7 + i due repo nuovi, rimandati con il blocco D). Campi: pacchetto e file interessati, comportamento osservato contro atteso, contesto di installazione letto dal manifest, agente usato. Ogni modello ricorda che una correzione fatta solo nella copia locale si perde al primo `-Update`.
- **Precondizione**: Fase D3 verificata
- **File**: `.github/ISSUE_TEMPLATE/` nei 9 repo (7 esistenti + 2 nuovi)
- **Operazione**: CREATE
- **Azione**: creare in ogni repo dr-* due template identici nella forma: `miglioria.md` (richiesta evolutiva) e `problema.md` (fix), ciascuno con i campi: pacchetto, versione/commit installato, progetto host, comportamento atteso vs osservato. Scritti in italiano, in Markdown neutro leggibile da entrambi gli agenti.
- **Tool ammessi**: Write
- **Verifica passo**: ogni repo dr-* contiene la cartella con i due file
- **Su divergenza**: STOP — un repo senza template rompe il punto 3 del TODO

### Fase E2: parità Copilot sul canale di feedback
- **Stato**: [x] — creati `dr-segnala-miglioria.prompt.md` e `dr-get-latest.prompt.md` in `.github/prompts/`, con la stessa semantica delle skill: lettura del manifest, deduzione del pacchetto dalla posizione del file, conferma esplicita prima di creare la issue, fallback su URL precompilato, guard sui repo sorgente e verifica unica di `gh` prima del ciclo di aggiornamento. Sintassi neutra, nessun costrutto esclusivo di Claude Code. Il caso "gap di catalogo" è presente in entrambe le superfici.
- **Precondizione**: Fase E1 verificata
- **File**: `.github/prompts/dr-segnala-miglioria.prompt.md`, `.github/prompts/dr-get-latest.prompt.md`
- **Operazione**: CREATE
- **Azione**: creare gli equivalenti Copilot delle due skill che oggi esistono solo per Claude Code, con la stessa semantica (lettura del manifest `.ai/dr-guidelines-packages.json`, determinazione del pacchetto, conferma esplicita prima di creare la issue, fallback su URL precompilato). Sintassi neutra, nessuna feature esclusiva di un solo agente.
- **Tool ammessi**: Read, Write
- **Verifica passo**: i due prompt esistono e non usano costrutti esclusivi Claude Code; un utente Copilot ha un canale di feedback
- **Su divergenza**: STOP — se una capacità non è replicabile su Copilot, dichiararlo nel prompt invece di fingere parità

### Fase E3: documentazione del nuovo assetto
- **Stato**: [x] — README: il core è descritto come catalogo e non più come pacchetto .NET, aggiunta la sezione "Aggiungere un dominio nuovo" (quattro voci nello stesso file, nessuna modifica agli script), tabella dei file installati corretta (`Directory.Build.props` e `global.json` non arrivano più dal core, `.claude/settings.json` documentato con il merge additivo), `dr-verify-plan` documentata, canale issue descritto sotto `dr-segnala-miglioria`. CLAUDE.md: tabella di invocazione aggiornata con le righe per `dr-segnala-miglioria` e `dr-verify-plan`, e rimosso il riferimento al submodule nella riga di `dr-get-latest`.
- **Precondizione**: Fase E2 verificata
- **File**: `README.md`, `CLAUDE.md` del core
- **Operazione**: EDIT
- **Azione**: aggiornare README (cos'è il core dopo lo svuotamento, come si aggiunge un dominio nuovo, tabella pacchetti completa) e la tabella di invocazione automatica in `CLAUDE.md` con le voci per i nuovi domini. Documentare esplicitamente la procedura "aggiungere un pacchetto di dominio" come singola modifica al catalogo.
- **Tool ammessi**: Edit
- **Verifica passo**: entrambi i file descrivono l'assetto reale post-fasi A-E; nessun riferimento residuo al core come pacchetto .NET
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase E3: <cosa>`

---

### Fase F1: hardening della distribuzione (non bloccante per i domini)
- **Stato**: [x] — (a) allowlist owner già applicata in C2 e testata con un catalogo ostile; (b) manifest promosso a lock file: `Update-DrManifest` registra il commit installato, letto con `git rev-parse HEAD` sul clone; (c) `-Update` confronta il commit registrato con quello remoto e stampa `Nessuna novità: già al commit <sha>` oppure `<vecchio> -> <nuovo>` con l'elenco dei file cambiati a monte. Verificato end-to-end in una cartella sandbox: prima installazione con commit registrato, seconda esecuzione con riconoscimento del "nessuna novità", nessun file .NET copiato dal core, e merge additivo di `settings.json` che conserva le voci dell'utente (`Bash(npm run test:*)`, `deny`, `env`) aggiungendo solo quella mancante.
- **Precondizione**: Fase E3 verificata
- **File**: `dr-guidelines-install-lib.ps1`, `.ai/dr-guidelines-packages.json` (formato)
- **Operazione**: EDIT
- **Azione**: (a) allowlist dell'owner: rifiutare qualsiasi `repo` del catalogo che non sia sotto `davraf-amuro`, prima del `git clone`; (b) promuovere il manifest host a lock file, registrando per ogni pacchetto il commit SHA installato oltre al nome; (c) `-Update` confronta lo SHA registrato con quello remoto e mostra cosa cambia prima di sovrascrivere.
- **Tool ammessi**: Read, Edit
- **Verifica passo**: un catalogo manomesso con un repo di terzi viene rifiutato; il manifest di una installazione di prova contiene lo SHA
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase F1: <cosa>`

---

## Criteri di verifica finale

- [x] Il repo legacy `davraf-guidelines` non contiene più nulla che non esista nella suite dr-*, ha un README di redirect, ed è archiviato o l'archiviazione è annotata come rimandata per scelta dell'utente
- [x] `no-hardcoded-values.instructions.md` è nel core; `.editorconfig` del core dichiara `end_of_line = lf`
- [x] La skill `dr-verify-plan` esiste nel core e `plan-tracking.instructions.md` è alla v1.4 citandola, senza aver perso l'eccezione `/dr-promote-to`
- [x] L'installer propaga `.claude/settings.json` al progetto host con merge additivo dei permessi
- [x] Nella radice del core non esistono più `Directory.Build.props` e `global.json`; un host .NET li riceve da `dr-dotnet-backend`
- [x] `.github/copilot-instructions.md` del core non contiene occorrenze di `dotnet`, `.csproj`, `Workers/`, `Endpoints/`
- [x] `scaffolding-catalog.json` è `schemaVersion: 2`, valido, con `domains`, `intentMap` e `fallback`
- [x] L'elenco dei pacchetti esiste in un solo posto: nessuna lista scritta a mano resta in `dr-guidelines-install-lib.ps1`
- [x] `/dr-scaffold` risolve l'intento leggendo la `intentMap` del catalogo e ha un ramo esplicito per i domini non coperti, che dichiara il gap e offre l'apertura di una issue
- [~] DIFFERITO con le fasi D1-D3 — `/dr-scaffold` risolve "crea una guida turistica" e "progetto per ESP32" nei **rispettivi domini** invece che nel fallback. Oggi entrambe le richieste cadono correttamente nel fallback, perché quei domini non hanno pacchetti
- [~] DIFFERITO con le fasi D1-D3 — i repo `dr-esp32` e `dr-travelguide` esistono, sono registrati nel catalogo e installabili con `-Package`
- [x] Tutti i repo dr-* hanno `.github/ISSUE_TEMPLATE/` con i due template
- [x] Esistono i prompt Copilot per segnalazione miglioria e aggiornamento pacchetti
- [x] Gate lint dichiarato ed eseguito prima di ogni push (nessun push fatto dall'esecutore)

## Decisioni rimandate

- Semver e release per pacchetto: la suite resta "sempre latest" (deciso nel piano split del 2026-07-22, non rivisto qui)
- Passaggio dei repo da Private a Public, che renderebbe funzionante il bootstrap `irm ... | iex` senza fallback `gh api`
- Nome definitivo di `dr-travelguide` (alternativa italiana) — da confermare in Fase D2
