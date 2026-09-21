# Piano: CI `catalog-guard` riparata + issue per i problemi aperti di `riscrittura-doc-dr`
Data: 2026-09-21
Stato: COMPLETATO

## Obiettivo
Riportare verde la CI del core e trasformare in issue GitHub i 6 problemi ancora aperti elencati in `.ai/plans/2026-09-16-riscrittura-doc-dr/plan.md`, sezione "Problemi emersi, fuori perimetro".

## Contesto
Decisione utente del 2026-09-21 (opzione B della revisione piani): correggere subito il problema n. 1 (CI), aprire issue per gli altri. Il problema n. 4 (header installer solo `irm`) è superato: repo `PUBLIC`.

**Conflitto con `plan-tracking`** ("non aprire nuovo piano se esiste piano `IN CORSO`"): il piano `2026-09-21-dr-pianifica-issue` è `IN CORSO` con 0 fasi eseguite. Fase 0 lo porta a `INTERROTTO`; si riprende subito dopo la chiusura di questo piano (è il prossimo della revisione).

**Causa del rosso CI** (3 run falliti dal 2026-09-16, primo su `aee84a4`): dopo la Fase C2 di `revisione-suite-dr` la lib non definisce più il registry al caricamento (`$Script:PackageRegistry = $null`, costruito da `Get-DrPackageRegistry` leggendo il catalogo). `ci.yml:63` legge ancora la variabile → `$null.Keys` → errore. In più il confronto registry ↔ catalogo è diventato tautologico: il registry **è** il catalogo.

Label: nei repo esistono solo le label di default (`bug`, `enhancement`, …); `problema` e `miglioria` dichiarate nei modelli `ISSUE_TEMPLATE` non esistono. Le issue si creano **senza label** (la mancanza è parte della issue I3).

## Scope
### File da modificare
- [ ] `.ai/plans/2026-09-21-dr-pianifica-issue/plan.md` — `Stato: INTERROTTO` con motivo
- [ ] `.github/workflows/ci.yml` — job `catalog-guard` riscritto sul registry dal catalogo
- [ ] `.ai/plans/2026-09-16-riscrittura-doc-dr/plan.md` — esito di ciascuno degli 8 problemi (corretto / superato / issue #n)
- [ ] GitHub: 7 issue (4 su `dr-guidelines`, 1 su `dr-minimalapi`, 1 su `dr-efdb`, 1 su `dr-winsvc`)

### Perimetro negativo
- Non toccherò: `dr-guidelines-install-lib.ps1`, `scaffolding-catalog.json`, skill, instructions, prompt, README — le correzioni dei problemi 2, 3, 5, 6, 7, 8 passano dalle issue
- Nessun file nei repo `dr-minimalapi`, `dr-efdb`, `dr-winsvc`
- Nessuna label creata nei repo
- `TODO/`, `.gitignore`, `docs/bozza-manuale-installazione.md` (modifiche locali estranee) esclusi dai commit

## Fasi (formato atomico — obbligatorio)

### Fase 0: sospensione del piano 12
- **Stato**: [x] — riga 3 del piano 12 ora `INTERROTTO` con motivo
- **Precondizione**: questo piano approvato dall'utente
- **File**: `.ai/plans/2026-09-21-dr-pianifica-issue/plan.md`
- **Operazione**: EDIT
- **Azione**: `Stato: IN CORSO` → `Stato: INTERROTTO — sospeso il 2026-09-21 per il piano 2026-09-21-fix-ci-e-issue-riscrittura-doc; si riprende alla sua chiusura`
- **Tool ammessi**: Edit
- **Verifica passo**: la riga 3 del file riporta `INTERROTTO`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 0: <cosa>` in plan.md, non procedere

### Fase 1: `catalog-guard` sul registry costruito dal catalogo
- **Stato**: [x] — step riscritto e rinominato `Verify scaffolding-catalog.json consistency`; zero occorrenze di `$Script:PackageRegistry`; YAML valido (`jobs: build-and-test, catalog-guard`)
- **Precondizione**: Fase 0 verificata
- **File**: `.github/workflows/ci.yml`
- **Operazione**: EDIT
- **Azione**: nello step del job `catalog-guard`: (a) dopo il dot-source della lib, precaricare `$Script:Catalog` con il `scaffolding-catalog.json` del checkout, così la verifica riguarda il commit in esame e non il `main` pubblicato; (b) ottenere il registry con `Get-DrPackageRegistry`, che applica anche l'allowlist dell'owner; (c) rimuovere il confronto nomi/repo/isCore/dipendenze registry ↔ catalogo, tautologico; (d) mantenere: nomi pacchetto duplicati, dipendenze risolvibili, controlli su `projectTypes`; (e) aggiungere i riferimenti dello schema v2: `domains[].packages` e `domains[].kind` esistenti, `intentMap[].domain` esistente, `packages[].appliesTo` tra i `kinds`. Aggiornare il commento sul caricamento della lib
- **Tool ammessi**: Read, Edit
- **Verifica passo**: nessuna occorrenza di `$Script:PackageRegistry` nel file; YAML valido
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: prova locale della guardia
- **Stato**: [x] — catalogo reale: exit `0`, `Catalogo allineato: 7 pacchetti, 5 tipologie.`; dipendenza inesistente: exit `1`, `dipendenza non risolvibile: 'dr-minimalapi' -> 'dr-inesistente'`; intentMap alterata: exit `1`, `intentMap punta al dominio inesistente`; owner estraneo: exit `1`, `owner non consentito 'estraneo'`. I tre casi rossi provano anche che la guardia legge il catalogo del checkout, non il `main` remoto
- **Precondizione**: Fase 1 verificata
- **File**: nessuno nel repo (script di prova nello scratchpad)
- **Operazione**: verifica
- **Azione**: eseguire lo step estratto da `ci.yml` con `pwsh -NoProfile -Command ". '<script>'"` (stessa forma di GitHub Actions) dalla root del repo → atteso exit `0` e `Catalogo allineato`. Poi su una copia nello scratchpad con catalogo alterato (dipendenza inesistente; `intentMap` verso dominio inesistente; repo con owner estraneo) → atteso exit `≠ 0` con il problema nominato
- **Tool ammessi**: Bash/PowerShell (sola lettura sul repo, scrittura solo nello scratchpad)
- **Verifica passo**: 1 esito verde + 3 esiti rossi, ciascuno con il messaggio atteso
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: creazione delle 7 issue
- **Stato**: [x] — create il 2026-09-22, senza label; `gh issue list` sui 4 repo le mostra aperte con titolo corretto:
  | # | Issue |
  |---|---|
  | I1 | `davraf-amuro/dr-guidelines#2` |
  | I2 | `davraf-amuro/dr-guidelines#3` |
  | I3 | `davraf-amuro/dr-guidelines#4` |
  | I4 | `davraf-amuro/dr-guidelines#5` |
  | I5 | `davraf-amuro/dr-minimalapi#1` |
  | I6 | `davraf-amuro/dr-efdb#1` |
  | I7 | `davraf-amuro/dr-winsvc#1` |

  URL: `https://github.com/<repo>/issues/<n>` — es. https://github.com/davraf-amuro/dr-guidelines/issues/2
- **Precondizione**: testi approvati con questo piano (sezione "Testi delle issue")
- **File**: nessuno (GitHub)
- **Operazione**: CREATE
- **Azione**: `gh issue create --repo <repo> --title <titolo> --body-file <file nello scratchpad>` per ciascuna issue, nell'ordine I1-I7, senza label. Annotare numero e URL in plan.md
- **Tool ammessi**: Bash (`gh issue create`)
- **Verifica passo**: `gh issue list` sui 4 repo mostra le 7 issue aperte
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: esito dei problemi nel piano 11
- **Stato**: [x] — 8 punti su 8 con esito: 1 corretto, 1 superato, 6 → issue (7 issue: il punto sui rimandi a `src/test-guideline.api/` ne ha due)
- **Precondizione**: Fase 3 verificata
- **File**: `.ai/plans/2026-09-16-riscrittura-doc-dr/plan.md`
- **Operazione**: EDIT
- **Azione**: per ciascuno degli 8 punti della sezione "Problemi emersi, fuori perimetro" aggiungere l'esito: n. 1 corretto (questo piano), n. 4 superato (repo `PUBLIC`), gli altri `→ <repo>#<n>`
- **Tool ammessi**: Edit
- **Verifica passo**: 8 punti su 8 hanno un esito
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: commit e push
- **Stato**: [x] — gate di push: nessun target applicabile (`git ls-files` di solution, `.csproj`, `package.json`, `*.py` → 0), dichiarato. Commit `03d2095` fix(ci) (solo `ci.yml`) e `06dffd0` docs(plan) (i tre `plan.md`); push `c5794ab..06dffd0`, che ha portato anche i 5 commit di chiusura piani del 2026-09-21. CI sul nuovo `HEAD`: `success`, `catalog-guard=success`, `build-and-test=success`, log `Catalogo allineato: 7 pacchetti, 5 tipologie.`
- **Precondizione**: Fasi 0-4 verificate
- **File**: `ci.yml`, i tre `plan.md` di Scope, questo `plan.md`
- **Operazione**: commit + push
- **Azione**: un commit `fix(ci)` per `ci.yml`, un commit `docs(plan)` per i piani; gate di push: nessun comando di verifica applicabile (nessuna solution, nessun `package.json`, nessun sorgente Python) → dichiararlo; `git push origin main` (porta anche i commit locali di oggi sui piani — erano 5, non 6: corretto dopo la verifica). **L'approvazione di questo piano vale come richiesta di push.**
- **Tool ammessi**: Bash (git), `gh run list`
- **Verifica passo**: `git status --short` senza i file di Scope; run CI sul nuovo `HEAD` con `catalog-guard` verde
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

## Testi delle issue

Contesto di installazione comune a tutte: *rilevato in revisione (piano `2026-09-16-riscrittura-doc-dr`, sezione "Problemi emersi, fuori perimetro"), non da un progetto host.*

### I1 — `davraf-amuro/dr-guidelines` — problema
**Titolo:** L'installer non copia `.github/copilot-instructions.md` nel progetto host
**Corpo:**
- **Cosa è andato storto:** la sezione `CLAUDE.md` iniettata nell'host richiama `@.github/copilot-instructions.md`, ma `dr-guidelines-install-lib.ps1` copia solo `.github/instructions/`, `.github/prompts/`, `.claude/skills/` e i file radice `.editorconfig`, `.gitignore`, `.gitattributes`.
- **File:** `dr-guidelines-install-lib.ps1` (`Copy-CoreConfigFiles`, riga 176); `README.md` righe 136 e 442 documentano il workaround "copialo a mano".
- **Osservato:** nell'host il riferimento `@.github/copilot-instructions.md` punta a un file inesistente; Copilot non riceve le istruzioni principali.
- **Atteso:** il core installa anche `.github/copilot-instructions.md`, con la stessa semantica `[SKIP]`/`[UPD]`; README senza workaround.

### I2 — `davraf-amuro/dr-guidelines` — problema (da verificare)
**Titolo:** `/dr-scaffold-solution` potrebbe fermarsi su una cartella in cui il core è già installato
**Corpo:**
- **Cosa è andato storto:** il flusso documentato è "cartella vuota → installa il core → reload → `/dr-scaffold`", quindi la root contiene già `CLAUDE.md`, `.github/`, `.claude/`, `.ai/`. La skill dice "Se un percorso di destinazione esiste già e non è vuoto: fermati" (`SKILL.md` riga 95) e "Cartella di destinazione già popolata → STOP" (riga 259), senza eccezione per i file del core.
- **File:** `.claude/skills/dr-scaffold-solution/SKILL.md` righe 95, 259; `.github/prompts/dr-scaffold.prompt.md` (parità duale).
- **Osservato:** non provato sul campo; rischio emerso in verifica.
- **Atteso:** la regola distingue la root del repo (dove i file del core sono attesi) dalle cartelle di progetto `src/<nome>`, `test/<nome>`, che devono essere assenti o vuote.

### I3 — `davraf-amuro/dr-guidelines` — miglioria
**Titolo:** `/dr-segnala-miglioria` non usa i modelli `ISSUE_TEMPLATE` e le label dei modelli non esistono
**Corpo:**
- **Cosa manca:** la skill compone titolo e corpo da sé; il prompt Copilot `dr-segnala-miglioria.prompt.md` usa invece i modelli `miglioria.md` / `problema.md` → issue diverse a seconda dell'agente. Inoltre i modelli dichiarano `labels: problema` / `miglioria`, ma nei 7 repo esistono solo le label di default di GitHub: la label non viene mai applicata, e `gh issue create --label problema` fallirebbe.
- **File:** `.claude/skills/dr-segnala-miglioria/SKILL.md`; `.github/ISSUE_TEMPLATE/*.md` nei 7 repo.
- **Atteso:** skill e prompt producono lo stesso corpo, strutturato sul modello; label create nei repo (o rimosse dai modelli) e applicate da entrambe le superfici.

### I4 — `davraf-amuro/dr-guidelines` — problema
**Titolo:** Dipendenze implicite da `dr-minimalapi` non dichiarate nel catalogo
**Corpo:**
- **Cosa è andato storto:** tre pacchetti rimandano a `minimal-api-architecture.instructions.md` come fonte unica, ma nel catalogo hanno `dependencies: []`:
  - `dr-efdb` — `database-provider.instructions.md:201` (regola 12, Service)
  - `dr-fe` — `frontend-organization.instructions.md:269` e `:330` (schema auth)
  - `dr-devops` — `docker-swarm-compose.instructions.md:165` (Data Protection, ForwardedHeaders)
- **Osservato:** un host che installa solo uno di questi pacchetti riceve un rimando a un file che non ha.
- **Atteso:** decidere per ciascuno fra dipendenza dichiarata in `scaffolding-catalog.json` oppure rimando condizionale ("se `dr-minimalapi` è installato…"). Nota: `dr-fe` e `dr-devops` hanno `appliesTo` diversi da `dotnet`, una dipendenza dura porterebbe `dr-dotnet-backend` anche in host non .NET.

### I5 — `davraf-amuro/dr-minimalapi` — problema
**Titolo:** Rimando a un'implementazione di riferimento inesistente (`src/test-guideline.api/`)
**Corpo:**
- **File:** `.github/instructions/minimal-api-architecture.instructions.md` riga 452.
- **Osservato:** l'istruzione rimanda a `src/test-guideline.api/` (ModelKits); il progetto non esiste in nessun repo della suite né nell'host → l'agente cerca file assenti.
- **Atteso:** rimando rimosso, oppure esempio minimo incluso nell'istruzione o in un `docs/` del pacchetto.

### I6 — `davraf-amuro/dr-efdb` — problema
**Titolo:** Rimando a un'implementazione di riferimento inesistente (`src/test-guideline.api/`)
**Corpo:**
- **File:** `.github/instructions/database-provider.instructions.md` righe 231-234.
- **Osservato:** "Invece di duplicare codice, CONSULTA l'implementazione di riferimento ModelKits" con 3 percorsi sotto `src/test-guideline.api/`, che non esiste → la regola chiede di consultare codice che l'agente non può trovare.
- **Atteso:** come `dr-minimalapi` (issue gemella): rimando rimosso o esempio incluso nel pacchetto.

### I7 — `davraf-amuro/dr-winsvc` — problema
**Titolo:** Esempio Serilog non compilabile su `HostApplicationBuilder` + prompt `card-worker-service` da riallineare
**Corpo:**
- **File:** `.github/instructions/windows-service.instructions.md` righe 60 e 79; `.github/prompts/card-worker-service.prompt.md`.
- **Osservato:** gli esempi usano `var builder = Host.CreateApplicationBuilder(args);` e poi `builder.Host.UseSerilog(...)`. `HostApplicationBuilder` non ha la proprietà `Host` (esiste su `WebApplicationBuilder`) → il codice generato non compila.
- **Atteso:** `builder.Services.AddSerilog((services, cfg) => cfg.ReadFrom.Configuration(builder.Configuration));` (pacchetto `Serilog.Extensions.Hosting`). Verificare inoltre l'allineamento di `card-worker-service.prompt.md` a `windows-service.instructions.md`, segnalato in revisione ma non ancora confrontato.

## Criteri di verifica finale
- [x] Piano 12 in `INTERROTTO` con motivo
- [x] `ci.yml` non contiene `$Script:PackageRegistry`; verifica sul catalogo del checkout, non sul `main` remoto
- [x] Guardia locale: verde sul catalogo reale, rossa sui 3 cataloghi alterati
- [x] 7 issue aperte, numeri registrati qui e nel piano 11
- [x] Piano 11: 8 problemi su 8 con esito
- [x] Push eseguito; CI verde sul nuovo `HEAD`, job `catalog-guard` compreso
- [x] Nessun file fuori Scope nei commit (`git show --stat`)
- [x] Verifica indipendente con `/dr-verify-plan`

## Verifica finale

Eseguita il 2026-09-22 con `/dr-verify-plan` (sub-agente Explore, contesto isolato, solo piano + file su disco). Esito: 3 file di Scope su 3 `CORRISPONDE`, issue `CORRISPONDE` per repo, titolo, stato e assenza di label; criteri 1-7 `SODDISFATTO`. Il sub-agente ha rieseguito la guardia estratta da `ci.yml` con i cataloghi alterati in memoria: stessi 4 esiti della Fase 2. CI su `06dffd0` (run `35661154389`): `success`.

Limiti della verifica, dichiarati: l'utente ha rifiutato al sub-agente `gh issue view` (corpi delle issue I4-I7) e `git status` nei repo `dr-minimalapi`, `dr-efdb`, `dr-winsvc` (perimetro negativo). I corpi sono stati scritti da file approvati con il piano; il perimetro sui repo sorelle non ha criterio dedicato.

Correzioni scaturite: testo della Fase 5 ("6 commit" → erano 5) e URL delle issue aggiunti alla Fase 3. Osservazione non corretta, accettata: nel caso "owner estraneo" la guardia fallisce con l'eccezione della lib invece che nell'elenco `Catalogo NON allineato`; il problema è comunque nominato ed è l'exit code a far fallire il job.

**Piano fix-ci-e-issue-riscrittura-doc verificato. Tutti i criteri soddisfatti.**
