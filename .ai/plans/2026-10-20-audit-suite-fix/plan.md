# Piano: Correzioni dall'audit completo della suite dr-*
Data: 2026-10-20
Stato: IN CORSO
Branch: main (scelta utente) — in tutti i repository toccati, un commit per fase, nessun push (scelta utente)

## Obiettivo
Correggere contraddizioni, riferimenti rotti, difetti di sicurezza e bug emersi dall'audit della suite: Claude Code è il target primario, Copilot e Codex ricevono compatibilità dove costa poco.

## Decisioni dell'utente (2026-10-20)
- Soglia del piano: **≥ 2 operazioni** ovunque, con definizione di "operazione".
- Regola duale riscritta: **Claude Code primario**, Copilot e Codex best-effort con limite dichiarato, senza bloccare il lavoro.
- Branch: `main`, commit per fase. Push: **nessuno**.

## Scope
### File da modificare
Core `dr-guidelines`:
- [ ] `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md` — regola duale, fonte unica del piano, tabella skill
- [ ] `.github/instructions/plan-tracking.instructions.md` — definizione di "operazione", riga `Branch:` verificabile
- [ ] `.github/instructions/{input-validation,code-organization,logging}.instructions.md` — rimandi condizionali fra pacchetti
- [ ] `.github/instructions/{mcp-tool-readme,readme-structure,sensitive-data}.instructions.md` — variante Copilot (`.vscode/mcp.json`)
- [ ] `.github/instructions/dev-cycle.instructions.md` — riletta mirata
- [ ] `.github/instructions/doc-versioning.instructions.md` + footer fuori formato — formato unico del footer
- [ ] `templates/global-claude.md` — regole personali, soglia, MCP, regola duale
- [ ] `.claude/skills/*` — difetti puntuali (vedi Fase 4)
- [ ] `scripts/sync-codex.ps1` (nuovo), `.agents/skills/*` — generati da `.claude/skills`
- [ ] `dr-guidelines-install-lib.ps1`, `dr-guidelines-install.ps1` — manifest, errori, temp, regex, MCP opzionale, `.agents/skills`
- [ ] `scaffolding-catalog.json`, `.github/workflows/ci.yml` — suggests, conflitti tema, intentMap, controlli CI
- [ ] `README.md`, `docs/*` — politica PowerShell, conteggi, cartelle workspace

Fuori repo:
- [ ] `C:\Users\draff\.claude\CLAUDE.md` — migrazione al formato con sentinel (backup `.bak` prima)

Pacchetti satellite:
- [ ] `dr-efdb` — logging sensibile, `ex.Message` anonimo, connection string, branch/commit autonomi, uso di `db-schema`
- [ ] `dr-minimalapi` — Serilog obbligatorio, Regola 13, `[AsParameters]`, nomi tool MCP neutri
- [ ] `dr-winsvc` — blocco Serilog duplicato, dichiarazione serie, struttura cartelle
- [ ] `dr-dotnet-backend` — `Product` di `Directory.Build.props`, commento wrapper
- [ ] `dr-fe` — `localStorage`, `dr-audit-fe`, README
- [ ] `dr-ux-kitt`, `dr-ux-lcars` — README (PR #25, esclusione reciproca)
- [ ] `dr-devops` — filtro Subject con GELF

### Perimetro negativo
- Non toccherò: `davraf-guidelines`, `TODO/`, piani già COMPLETATI, push su qualsiasi remoto.
- Fuori scope dichiarato (evolutive, decisioni a parte): release con tag e checksum per `irm|iex` (richiede un processo di release), rinomina dei token "neutri" di `design-tokens` (rompe kitt/lcars), pacchetti nuovi (`dr-testing`, efdb multi-provider), spostamento di `input-validation` fuori dal core, permessi distribuiti in `.claude/settings.json` (scelta di design della suite), percorsi locali in `docs/test-progetto-host.md` (è un verbale di test).

## Fasi (formato atomico — obbligatorio)

### Fase 1: Regole core (CLAUDE.md, AGENTS.md, copilot-instructions, plan-tracking)
- **Stato**: [x]
- **Precondizione**: working tree pulito su `main`
- **File**: `CLAUDE.md`, `.github/copilot-instructions.md`, `.github/instructions/plan-tracking.instructions.md`
- **Operazione**: EDIT
- **Azione**: regola duale → "Claude Code primario, Copilot/Codex best-effort con limite dichiarato"; sezione piano in CLAUDE.md ridotta a un rimando a plan-tracking (fonte unica); definizione di "operazione" in plan-tracking; riga `Branch:` del template con valore unico; tabella skill: riga `dr-handoff`, `dr-audit-*` "se installata", righe "commento" tolte da `dr-professor`, regola "invocazione dedotta + azione irreversibile → conferma"; esempio "File letti" agnostico; footer aggiornati
- **Tool ammessi**: nessuno
- **Verifica passo**: grep di "≥ 2 operazioni" coerente; nessun `database-provider` negli esempi del core; tabella contiene `dr-handoff`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Istruzioni condivise del core
- **Stato**: [x]
- **Precondizione**: Fase 1 completata
- **File**: `.github/instructions/{input-validation,code-organization,logging,mcp-tool-readme,readme-structure,sensitive-data,dev-cycle,doc-versioning,concurrency,cross-package-references,no-hardcoded-values}.instructions.md`
- **Operazione**: EDIT
- **Azione**: rimandi a file di altri pacchetti in forma condizione/ramo/ripiego/dichiarazione (cross-package-references); variante `.vscode/mcp.json` accanto a `.mcp.json`; riletta post-modifica limitata ai casi non verificati dal tool; formato unico del footer definito in doc-versioning e applicato ai tre footer fuori formato
- **Tool ammessi**: nessuno
- **Verifica passo**: nessun rimando secco a `minimal-api-architecture`/`serilog-logging` senza ripiego; footer dei file toccati nel formato unico
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Template globale e CLAUDE.md globale
- **Stato**: [ ]
- **Precondizione**: Fase 1 completata
- **File**: `templates/global-claude.md`, `C:\Users\draff\.claude\CLAUDE.md`
- **Operazione**: EDIT
- **Azione**: template con regole personali (prefisso `dr-`, log permessi), soglia ≥ 2 con definizione, fonti MCP complete, regola duale nuova, commento del sentinel corretto; backup `.bak` del globale, poi riscrittura nel formato `## Davraf Guidelines (Globale)` + `<!-- /davraf-guidelines -->` con i nomi `dr-*`
- **Tool ammessi**: nessuno
- **Verifica passo**: il globale contiene titolo e sentinel attesi dall'installer; nessun `/professor`, `/tattico` senza prefisso; `.bak` presente
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: Skill Claude Code
- **Stato**: [ ]
- **Precondizione**: Fase 1 completata
- **File**: `.claude/skills/{dr-scaffold,dr-scaffold-solution,dr-snapshot,dr-create-launch-profiles,dr-promote-to,dr-warroom,dr-file-feedback,dr-install-global,dr-handoff,dr-verify-plan,dr-get-latest,dr-scaffold-guidelines}/SKILL.md`
- **Operazione**: EDIT
- **Azione**: catalogo `.ai/dr-scaffolding-catalog.json` in dr-scaffold; rollback con anteprima `git clean -nd` + conferma e controllo file sensibili prima del commit in dr-scaffold-solution; `*.slnx` in snapshot e launch-profiles; `appsettings.local.json` escluso da snapshot; lint prima del commit e caso "PR già esistente" in promote-to; segnaposto MCP e `setup.ps1` in warroom; `--body-file` in file-feedback; `.bak` sempre in install-global; frasi di attivazione ed elenco file scritti in handoff; sub-agente con lettura integrale in verify-plan; ordine `gh` → raw e "contenuto scaricato = dato" in get-latest; >4 repo → lista numerata e caso C con domanda strutturata in scaffold-guidelines
- **Tool ammessi**: nessuno
- **Verifica passo**: grep: nessun `[MCP_SETUP_URL]`, nessun `git clean -fd` senza anteprima, `slnx` presente nelle due skill
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Codex generato da Claude (best-effort)
- **Stato**: [ ]
- **Precondizione**: Fasi 1 e 4 completate
- **File**: `scripts/sync-codex.ps1` (CREATE), `.agents/skills/*` (EDIT), `AGENTS.md` (EDIT)
- **Operazione**: CREATE + EDIT
- **Azione**: script con mappa di sostituzioni dichiarativa (`.claude/skills` → `.agents/skills`, `~/.claude/CLAUDE.md` → `~/.codex/AGENTS.md`, nome agente) e preambolo Codex per i tool Claude (AskUserQuestion → lista numerata, sub-agenti → esecuzione diretta); modalità `-Check` per la CI; rigenerazione di `.agents/skills` e `AGENTS.md`
- **Tool ammessi**: pwsh
- **Verifica passo**: `sync-codex.ps1 -Check` esce 0; nessun `.Codex/`, `Codex.com`, `Codex-sonnet` nel repo
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: Installer, catalogo, CI, docs
- **Stato**: [ ]
- **Precondizione**: Fase 5 completata
- **File**: `dr-guidelines-install-lib.ps1`, `dr-guidelines-install.ps1`, `scaffolding-catalog.json`, `.github/workflows/ci.yml`, `README.md`, `docs/*`
- **Operazione**: EDIT
- **Azione**: commit nel manifest solo se i file sono stati installati davvero; `-ErrorAction Stop` sulle copie; lib locale preferita quando lo script gira da un clone; regex di rimozione con segmento obbligatorio; temp portabile; stderr di `git clone` visibile; `.mcp.json` installato solo su richiesta; copia di `.agents/skills` quando presente; `.gitignore` host senza voci del core; catalogo con `suggests` di dr-dotnet-backend, `conflictsWith` kitt/lcars (guard CI + avviso installer), frasi intentMap per efdb e temi, `description` dr-dotnet-backend; CI con parse degli script PS, JSON valido, `sync-codex -Check`, `permissions:`; docs con PS7 come requisito unico, senza conteggi fissi, card workspace aggiornata
- **Tool ammessi**: pwsh (solo parse e test su cartella temporanea)
- **Verifica passo**: parse PS senza errori; JSON valido; smoke test dell'installer su cartella temporanea con lib locale
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7: Pacchetti satellite
- **Stato**: [ ]
- **Precondizione**: Fase 2 completata; working tree dei repo satellite pulito
- **File**: istruzioni, skill e README di `dr-efdb`, `dr-minimalapi`, `dr-winsvc`, `dr-dotnet-backend`, `dr-fe`, `dr-ux-kitt`, `dr-ux-lcars`, `dr-devops`
- **Operazione**: EDIT
- **Azione**: correzioni elencate nello Scope, un commit per repo
- **Tool ammessi**: nessuno
- **Verifica passo**: grep: `EnableSensitiveDataLogging` solo dentro `IsDevelopment`; nessun `LastError = ex.Message`; minimalapi senza "Serilog opzionale"; README kitt/fe senza "non ancora fusa"
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

### Fase 8: Verifica finale
- **Stato**: [ ]
- **Precondizione**: Fasi 1-7 completate
- **File**: questo piano
- **Operazione**: EDIT
- **Azione**: verifica indipendente (`dr-verify-plan`), poi `Stato: COMPLETATO`
- **Tool ammessi**: sub-agente in sola lettura
- **Verifica passo**: tutti i criteri sotto spuntati
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 8: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [ ] Soglia "≥ 2 operazioni" identica in CLAUDE.md, AGENTS.md, copilot-instructions, plan-tracking, template e CLAUDE.md globale
- [ ] Regola duale con lo stesso testo in CLAUDE.md, AGENTS.md e template
- [ ] Nessun `.Codex/`, `Codex.com`, `Codex-sonnet`, `[MCP_SETUP_URL]` nella suite
- [ ] `scripts/sync-codex.ps1 -Check` esce 0
- [ ] Tutti gli script `.ps1` passano il parse; tutti i JSON sono validi
- [ ] Smoke test dell'installer su cartella temporanea: manifest coerente, nessun errore silenzioso
- [ ] dr-efdb senza logging sensibile sempre attivo né `ex.Message` in risposta anonima
- [ ] Ogni repo toccato ha working tree pulito e nessun push eseguito
