# Piano: Soggetto del log sempre presente e isolabile + riordino regole logging
Data: 2026-10-20
Stato: COMPLETATO
Branch: main (scelta utente) — in tutti i repository toccati

## Obiettivo
Quando l'utente individua un soggetto (valore di un campo scelto da lui: ID, Codice, ecc.), ogni evento di log del flusso lo riporta nella proprietà fissa `Subject` (`<Campo>=<valore>`), così i log di quel soggetto si isolano con un solo filtro. Contestualmente: regola di logging del core resa agnostica, parte Serilog spostata nel pacchetto .NET, configurazione Serilog unica per Minimal API, Windows Service e deploy.

## Decisioni
- **D1 — Forma del soggetto** (utente): proprietà fissa `Subject`, valore `<Campo>=<valore>` (es. `OrderId=42`), `-` quando assente. Slot `S:{Subject}` nei template testuali. Filtro: `grep "S:OrderId=42"` sui file, `Subject = 'OrderId=42'` sui sink strutturati.
- **D2 — Incongruenze risolte in questo piano** (utente).
- **D3 — Split invece di spostamento** (proposta agente): `logging.instructions.md` resta nel core ma diventa agnostica (placeholder, soggetto, cosa non loggare); il contenuto Serilog va in `dr-dotnet-backend/.github/instructions/serilog-logging.instructions.md`. Motivo: stesso percorso in due pacchetti = l'ultimo installer che gira sovrascrive l'altro; con nomi diversi nessun conflitto, e il `-Update` del core sostituisce da solo la vecchia versione .NET negli host. Nessuna voce `obsoleteArtifacts` necessaria.
- **D4 — Configurazione Serilog unica** (approvata dall'utente: i programmi possono girare in Docker o altri container, quindi `appsettings` sovrascrivibile da variabili d'ambiente): livelli, sink e template in `appsettings.json` (sezione `Serilog`, letta con `ReadFrom.Configuration`); enricher in codice (`FromLogContext`, `WithThreadId`, `TaskIdEnricher`). Motivo: è già la forma usata da `dr-winsvc` e quella che `dr-devops` presuppone (override `SERILOG__WRITETO__1__ARGS__PATH`); oggi `logging.instructions.md` scrive i sink in codice e l'override di devops non avrebbe effetto.

## Scope
### File da modificare
**dr-guidelines**
- [x] `.github/instructions/logging.instructions.md` — riscritta agnostica: placeholder, regola del soggetto, rimando alle istruzioni di dominio; v2.0
- [x] `.github/copilot-instructions.md` — regola del soggetto in "Convenzioni essenziali" + checklist post-generazione; v2.4
- [x] `README.md` — riga di `logging.instructions.md` nella tabella (non più "esempi Serilog")
- [x] `docs/scaffolding-minimal-api.md` — riga `Serilog.Enrichers.Thread`: rimando a `serilog-logging.instructions.md` (+ footer di revisione)
- [x] `AGENTS.md` — non riporta le convenzioni essenziali: nessuna modifica

**dr-dotnet-backend**
- [x] `.github/instructions/serilog-logging.instructions.md` — CREATE: contenuto Serilog di oggi riallineato a D4 + soggetto (`FromLogContext`, `BeginScope`, slot `S:{Subject}`)
- [x] `README.md` — nuova riga nella tabella dei file; riga "file di altri pacchetti" aggiornata
- [x] `.claude/skills/dr-audit-api/SKILL.md` — fase 0 legge anche `serilog-logging.instructions.md`; controllo `Subject` (esente dalla compatibilità duale)

**dr-minimalapi**
- [x] `README.md` — tabella file citati: `logging` non più fonte Serilog, riga `serilog-logging` (aggiunto dopo la verifica, approvato dall'utente)
- [x] `.github/instructions/minimal-api-architecture.instructions.md` — sezione Serilog rimanda a `serilog-logging.instructions.md` come fonte unica; checklist

**dr-winsvc**
- [x] `README.md` — tabella file citati: riga `serilog-logging` (aggiunto dopo la verifica, approvato dall'utente)
- [x] `.github/instructions/windows-service.instructions.md` — Program.cs con enricher in codice, sezione `Serilog` di appsettings completa come da D4, rimando alla fonte unica; worker d'esempio con `BeginScope` del soggetto; checklist

### Perimetro negativo
- Non toccherò: installer `*.ps1`, `scaffolding-catalog.json`, `obsoleteArtifacts`
- Non toccherò: `dr-efdb`, `dr-devops`, `dr-fe`, `davraf-guidelines`
- Non toccherò: `docs/test-progetto-host.md` (l'esempio su `logging.instructions.md` resta valido: il file resta nel core)
- Non toccherò: `templates/global-claude.md`, skill fuori da `dr-audit-api`
- Nessun `git push` senza conferma dell'utente

## Fasi (formato atomico — obbligatorio)

### Fase 1: Crea serilog-logging in dr-dotnet-backend
- **Stato**: [x]
- **Precondizione**: piano approvato; `dr-dotnet-backend` su `main`, working tree pulito
- **File**: `dr-dotnet-backend/.github/instructions/serilog-logging.instructions.md`
- **Operazione**: CREATE
- **Azione**: porta il contenuto Serilog attuale di `logging.instructions.md`; applica D4 (blocco `Serilog` di appsettings con Console e File, template con `T:{ThreadId} A:{TaskId} S:{Subject}`; Program.cs `ReadFrom.Configuration` + `Enrich.FromLogContext()` + `WithThreadId()` + `With<TaskIdEnricher>()` + `With<SubjectDefaultEnricher>()` per il `-`); sezione "Soggetto del log" con pattern `logger.BeginScope(new Dictionary<string, object> { ["Subject"] = $"OrderId={id}" })` — **verificare** che il valore della chiave non usi interpolazione nel messaggio di log (l'interpolazione è nel valore della proprietà, non nel template: dichiararlo); errori comuni; checklist; footer v1.0
- **Tool ammessi**: nessuno
- **Verifica passo**: file riletto; template identici fra appsettings d'esempio e sezione template; nessun `$"` dentro `Log*(`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: logging.instructions agnostica nel core
- **Stato**: [x]
- **Precondizione**: Fase 1 `[x]`
- **File**: `dr-guidelines/.github/instructions/logging.instructions.md`
- **Operazione**: EDIT
- **Azione**: riscrivi senza riferimenti a uno stack: placeholder sempre, mai interpolazione; regola del soggetto (D1: proprietà `Subject`, valore `<Campo>=<valore>`, `-` se assente, impostata una volta all'ingresso del flusso tramite il meccanismo di contesto/scope del linguaggio, mai concatenata nel messaggio, presente anche nei template testuali); come isolare; rimando: configurazione concreta nell'istruzione di dominio (.NET → `serilog-logging.instructions.md` di `dr-dotnet-backend`); checklist; footer v2.0
- **Tool ammessi**: nessuno
- **Verifica passo**: file riletto; nessun nome di libreria .NET nel corpo tranne il rimando
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: copilot-instructions del core
- **Stato**: [x]
- **Precondizione**: Fase 2 `[x]`
- **File**: `dr-guidelines/.github/copilot-instructions.md`
- **Operazione**: EDIT
- **Azione**: in "Convenzioni essenziali" aggiungi la regola del soggetto con rimando a `logging.instructions.md`; voce in "Checklist Post-Generazione"; footer v2.4
- **Tool ammessi**: nessuno
- **Verifica passo**: file riletto; regola agnostica
- **Nota**: `AGENTS.md` non riporta le convenzioni essenziali → nessuna modifica necessaria
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: Documentazione core
- **Stato**: [x]
- **Precondizione**: Fase 3 `[x]`
- **File**: `dr-guidelines/README.md`, `dr-guidelines/docs/scaffolding-minimal-api.md`, `dr-guidelines/AGENTS.md`
- **Operazione**: EDIT
- **Azione**: README riga tabella → "Logging strutturato con placeholder e soggetto isolabile (tutti i linguaggi)"; scaffolding-minimal-api riga 246 → rimando a `serilog-logging.instructions.md` + footer revisione (`doc-versioning`); AGENTS.md allineato solo se riporta le convenzioni
- **Tool ammessi**: nessuno
- **Verifica passo**: tre file riletti
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: dr-dotnet-backend README e skill audit
- **Stato**: [x]
- **Precondizione**: Fase 1 `[x]`
- **File**: `dr-dotnet-backend/README.md`, `dr-dotnet-backend/.claude/skills/dr-audit-api/SKILL.md`
- **Operazione**: EDIT
- **Azione**: README: riga del nuovo file nella tabella dei file; riga 47 invariata nella sostanza (`logging` resta core) + `serilog-logging` come file proprio. SKILL: fase 0 legge `serilog-logging.instructions.md`; aggiungi controllo `[WARNING]` soggetto concatenato nel messaggio invece che in scope
- **Tool ammessi**: nessuno
- **Verifica passo**: file riletti
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: dr-minimalapi
- **Stato**: [x]
- **Precondizione**: Fase 1 `[x]`; `dr-minimalapi` su `main`, pulito
- **File**: `dr-minimalapi/.github/instructions/minimal-api-architecture.instructions.md`
- **Operazione**: EDIT
- **Azione**: sezione "Serilog — configurazione completa" e checklist: fonte unica = `serilog-logging.instructions.md` (pacchetto `dr-dotnet-backend`); footer
- **Tool ammessi**: nessuno
- **Verifica passo**: nessun riferimento residuo a `logging.instructions.md` come fonte Serilog
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7: dr-winsvc
- **Stato**: [x]
- **Precondizione**: Fase 1 `[x]`; `dr-winsvc` su `main`, pulito
- **File**: `dr-winsvc/.github/instructions/windows-service.instructions.md`
- **Operazione**: EDIT
- **Azione**: i due Program.cs aggiungono gli enricher come da `serilog-logging`; appsettings d'esempio con sezione `Serilog` completa (o rimando esplicito al blocco della fonte unica); worker d'esempio apre `BeginScope` del soggetto per ogni elemento elaborato; checklist; footer v1.4
- **Tool ammessi**: nessuno
- **Verifica passo**: Program.cs e appsettings coerenti con `serilog-logging`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

### Fase 8: Commit
- **Stato**: [x]
- **Precondizione**: Fasi 1–7 `[x]`
- **File**: i quattro repository
- **Operazione**: EDIT (git)
- **Azione**: un commit per repository su `main`; nessun push (si chiede all'utente; gate: repo di soli documenti → assenza di target dichiarata)
- **Tool ammessi**: git
- **Verifica passo**: `git status` pulito nei quattro repo
- **Nota**: commit dr-dotnet-backend 4d08824, dr-minimalapi 36c9434, dr-winsvc 67ede08, dr-guidelines 0a11b4e. In dr-guidelines restano modifiche di un'altra sessione (branch per piano, install multi-repo): escluse dal commit, compresa la riga "branch dedicato" di `copilot-instructions.md`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 8: <cosa>` in plan.md, non procedere

### Fase 9: Verifica finale
- **Stato**: [x]
- **Precondizione**: Fase 8 `[x]`
- **File**: questo `plan.md`
- **Operazione**: EDIT
- **Azione**: `/dr-verify-plan`; aggiorna Stato
- **Tool ammessi**: skill `dr-verify-plan`
- **Verifica passo**: tutti i criteri `[x]`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 9: <cosa>` in plan.md, non procedere

## Consuntivo verifica
- Prima verifica indipendente: divergenza su `dr-minimalapi/README.md` e `dr-winsvc/README.md` (fuori Scope) + imprecisioni negli esempi. Scope esteso con approvazione dell'utente; corretto in 8eae946, 7d79eeb, 8dc1927, 8e1e6ed.
- Seconda verifica indipendente: 8/8 criteri soddisfatti; rifiniture minori applicate (commento `S:OrderId=42`, nome del campo solo costante, voce `TaskId`, blocco `WriteTo` completo in dr-winsvc).

## Criteri di verifica finale
- [x] `logging.instructions.md` del core è agnostica e contiene la regola del soggetto (D1)
- [x] `serilog-logging.instructions.md` esiste in `dr-dotnet-backend` con `FromLogContext`, scope del soggetto e `S:{Subject}` in entrambi i template
- [x] Minimal API, Windows Service e override di `dr-devops` usano la stessa forma di configurazione (D4)
- [x] Nessun riferimento residuo a `logging.instructions.md` come fonte della configurazione Serilog nella suite
- [x] Nessun esempio usa interpolazione nel template di un messaggio di log
- [x] Regole condivise compatibili Claude Code / Copilot
- [x] Footer aggiornati (versione, 2026-10-20, modello, motivo)
- [x] Nessun file fuori Scope modificato
