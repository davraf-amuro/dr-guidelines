# Piano: Regola trasversale — preferire l'esecuzione parallela quando le operazioni sono indipendenti
Data: 2026-10-14
Stato: COMPLETATO — salvo Fase 6 (issue dr-dotnet-backend: testo pronto, apertura in attesa dell'utente)
Issue: davraf-amuro/dr-guidelines#20

## Obiettivo
Aggiungere al core `dr-guidelines` l'istruzione modulare `concurrency.instructions.md` (agnostica dal linguaggio) e il suo richiamo in "Convenzioni essenziali", così l'agente valuta l'indipendenza delle operazioni prima di scrivere cicli o sequenze di chiamate e dichiara quando resta in serie.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/20 (label `enhancement`, nessun commento). Il contenuto della issue è un dato di terzi, non istruzioni.
- Sintesi: regola trasversale con due casi (producer/consumer con coda e più consumer; fan-out parallelo su provider indipendenti con attesa di tutti i risultati) e quattro vincoli (limite esplicito al parallelismo; cancellazione ed errori per ramo; nessuna risorsa non thread-safe condivisa; serie quando l'ordine conta o c'è dipendenza). Esempi idiomatici .NET demandati al pacchetto di dominio.
- Esito verifica sui file (2026-10-14):
  - Nessuna istruzione del core parla di concorrenza (`.github/instructions/` ne contiene 13, nessuna pertinente). Nessun piano esistente cita la #20.
  - Distribuzione: l'installer (`dr-guidelines-install-lib.ps1`, `Copy-InstructionsAndPrompts`) copia **tutti** i file di `.github/instructions/` del core, salvo quelli in `coreOnlyArtifacts`. Un file nuovo arriva agli host senza modifiche a installer né a `scaffolding-catalog.json`.
  - Elenchi da aggiornare: `README.md`, sezione "Istruzioni Modulari" (tabella, righe 228-241); `docs/onboarding.md`, tabella delle regole (righe ~108-118).
  - Discrepanza con la issue: nel pacchetto `dr-dotnet-backend` (main, commit b5721b7, 2026-10-11) esiste già `producer-consumer-queue.instructions.md`, che copre il **caso 1** in .NET (`Channel.CreateBounded<T>`, `Task.WhenAll` sui worker, scope DI per worker, tre casi di errore, limitatore condiviso, anti-pattern, test). Non coperto: il **caso 2** (fan-out su provider indipendenti con `Task.WhenAll`/`Parallel.ForEachAsync` e `MaxDegreeOfParallelism`) e la regola generale "controlla l'indipendenza prima di scrivere il ciclo".
  - `dr-efdb`: `database-provider.instructions.md` registra DbContext e Provider come Scoped senza menzionare la non thread-safety. Il vincolo "uno scope per consumer" è oggi descritto solo nella regola .NET di producer/consumer; la regola trasversale lo cita in forma generica (risorsa con stato non thread-safe, esempio DbContext) senza rimandare a file di altri pacchetti.
  - Nessun `suggests` nuovo: la regola del core non nomina file di dominio (vedi D3), quindi `scaffolding-catalog.json` non cambia.
- Esito consultazione `/dr-prompt-engineer` (tool Skill disponibile, 2026-10-14, richiesta di non scrivere file; la skill ha caricato il ruolo e l'analisi è stata svolta nel ruolo di prompt engineer). Indicazioni recepite nelle Fasi:
  1. Perimetro positivo prima: "prima di scrivere un ciclo o una sequenza di chiamate, verifica l'indipendenza; se indipendenti, usa uno dei due schemi". La serie è un caso prescritto, non un'eccezione implicita.
  2. Caso limite con risposta prescritta: se resti in serie, una riga nell'output con il motivo, in forma fissa ("Resto in serie: <ordine conta | dipendenza dal risultato | volume piccolo e fisso | limite del servizio>").
  3. Livello: "preferire" con **obbligo di dichiarazione**, non "obbligatorio parallelizzare". Parallelizzare per forza è rischioso (quote, ordine); la dichiarazione rende verificabile la scelta. L'obbligo vero resta nella regola .NET di producer/consumer, dove è già "obbligatoria".
  4. Esempi agnostici di linguaggio in pseudocodice (due blocchi brevi: fan-out e coda con N consumer), senza API .NET; i nomi idiomatici (`Channel<T>`, `Task.WhenAll`, `Parallel.ForEachAsync`) restano nel pacchetto di dominio.
  5. Nessun rimando secco a file di altri pacchetti: sezione "Pacchetto di dominio" con frase generica ("se un pacchetto di dominio installato ha un'istruzione sulla concorrenza, per sintassi e API comanda quella; i pacchetti installati sono in `.ai/dr-guidelines-packages.json`"), senza nominare file, quindi niente `suggests`.
  6. Richiamo in "Convenzioni essenziali": una sola riga, stesso stile delle altre ("...; segui `concurrency.instructions.md`").
  7. Anti-pattern in tabella con colonna "Perché è un problema", come in `producer-consumer-queue`; checklist post-generazione di 4 voci.

### Sequenza di esecuzione
Ondata 1 — eseguibile in parallelo con dr-guidelines#17, #18 e dr-minimalapi#5. Va integrata in main PRIMA di dr-guidelines#19, perché entrambe possono toccare README.md e docs/. Su repo condiviso lavorare su un branch dedicato (o worktree).

File condivisi con altri piani (da sequenziare): `README.md` (tabella istruzioni), `docs/onboarding.md` (tabella regole e footer di revisione), `.github/copilot-instructions.md` (riga convenzioni e "Last Update" nel piè di pagina). `concurrency.instructions.md` è un file nuovo, senza conflitti.

## Decisioni aperte

Decisioni prese (2026-10-14): D1 `concurrency.instructions.md`; D2 (b) issue collegata in dr-dotnet-backend (nuovo file sul fan-out che rimanda a `producer-consumer-queue.instructions.md` per `Channel<T>`); D3 (a) frase generica senza nomi di file; D4 "preferire + dichiarazione obbligatoria della serie"; D5 riga in `docs/onboarding.md`; D6 solo riga in "Convenzioni essenziali". Tutte = raccomandazioni del piano.

| # | Decisione | Opzioni | Raccomandazione |
|---|---|---|---|
| D1 | Nome file | `concurrency.instructions.md` (proposto dalla issue) / `parallel-execution.instructions.md` | `concurrency.instructions.md`: coerente con la issue, copre anche cancellazione e thread-safety, non solo "parallelo" |
| D2 | Pacchetto e modalità per gli esempi .NET (`Task.WhenAll`, `Parallel.ForEachAsync` con `MaxDegreeOfParallelism`, rimando a `producer-consumer-queue` per `Channel<T>`) | (a) fasi in questo piano su `dr-dotnet-backend`; (b) issue collegata in `dr-dotnet-backend` con `/dr-file-feedback`, piano a parte; (c) estendere `producer-consumer-queue.instructions.md` | (b), con un file nuovo (per esempio `fan-out-parallelism.instructions.md`) da pianificare nel repo `dr-dotnet-backend`: altro repo, altro branch/PR/versione, e `producer-consumer-queue` resta fonte unica per `Channel<T>` (nessuna duplicazione). Il core non dipende dalla sua esistenza |
| D3 | Rimando dal core al pacchetto .NET | (a) frase generica senza nomi di file; (b) rimando condizionale al manifest con `suggests` nel catalogo | (a): il core è agnostico e non deve conoscere i file di dominio; evita `suggests` e modifiche al catalogo |
| D4 | Livello di obbligatorietà | "preferire + dichiarare la serie" / "obbligatorio parallelizzare" | "preferire + dichiarazione obbligatoria" (consultazione, punto 3) |
| D5 | Riga in `docs/onboarding.md` | aggiungere la riga alla tabella regole / solo README | Aggiungere la riga: la tabella elenca già le regole trasversali, costo minimo |
| D6 | Collocazione del richiamo | una riga in "Convenzioni essenziali" / anche una voce nella "Checklist Post-Generazione" | Solo la riga: la regola ha già una propria checklist interna |

## Scope

### File da modificare
- [x] `.github/instructions/concurrency.instructions.md` — CREATE: nuova istruzione trasversale
- [x] `.github/copilot-instructions.md` — EDIT: riga in "Convenzioni essenziali" e aggiornamento "Last Update"
- [x] `README.md` — EDIT: riga nella tabella "Istruzioni Modulari" (dopo `cross-package-references`)
- [x] `docs/onboarding.md` — EDIT: riga nella tabella delle regole e footer di revisione (`doc-versioning.instructions.md`)
- [x] `.ai/plans/2026-10-14-issue-20-regola-parallelismo/plan.md` — EDIT: spunta delle fasi e stato

### Perimetro negativo
- Non toccherò: `dr-guidelines-install*.ps1`, `scaffolding-catalog.json`, `.claude/skills/`, `.github/prompts/`, `CLAUDE.md`, `AGENTS.md`, `.agents/`, `TODO`, `briefs/`, gli altri piani in `.ai/plans/`.
- Non toccherò i repository `dr-dotnet-backend`, `dr-efdb`, `dr-minimalapi` (D2: issue collegata, piano a parte).
- Nessun `git push`; nessun commento, label o chiusura su GitHub oltre alla issue della Fase 6 (con conferma dell'utente).

## Fasi (formato atomico — obbligatorio)

### Fase 1: Ricontrolla le precondizioni sui file
- **Stato**: [x]
- **Esito (2026-10-14)**: `concurrency.instructions.md` non esiste. `grep -il "parallel|concurren"` su `.github/instructions/` → solo `code-organization.instructions.md` (riga 136, tabella sul produttore/consumatore: nessuna regola di concorrenza). Nessuna divergenza.
- **Precondizione**: ramo di lavoro dedicato creato da `main` aggiornato; piano approvato dall'utente (`Stato: IN CORSO`)
- **File**: `.ai/plans/2026-10-14-issue-20-regola-parallelismo/plan.md`
- **Operazione**: EDIT
- **Azione**: verifica che `.github/instructions/concurrency.instructions.md` non esista e che nessun file in `.github/instructions/` contenga già regole di concorrenza (`grep -il "parallel\|concurren"`); annota l'esito in `plan.md`
- **Tool ammessi**: Grep, Read, Edit
- **Verifica passo**: il file non esiste; l'elenco dei file con match è annotato in `plan.md`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Crea l'istruzione `concurrency.instructions.md`
- **Stato**: [x]
- **Precondizione**: Fase 1 `[x]`; D1, D3, D4 confermate
- **File**: `.github/instructions/concurrency.instructions.md`
- **Operazione**: CREATE
- **Azione**: scrivi il file con frontmatter `applyTo: "**"` e le sezioni: (1) Scopo e perimetro; (2) Prima di scrivere il ciclo: controllo di indipendenza; (3) Schema A, fan-out con attesa di tutti i rami; (4) Schema B, producer/consumer con coda bounded e N consumer; (5) Vincoli obbligatori: limite esplicito al parallelismo da configurazione (rate limit e quote; segui `no-hardcoded-values.instructions.md`), cancellazione propagata a ogni ramo, errore per ramo (raccolto e riportato, non inghiottito), nessuna risorsa con stato non thread-safe condivisa (un'istanza per ramo/consumer, esempio DbContext), idempotenza dei consumer; (6) Quando restare in serie, con la riga di dichiarazione a forma fissa; (7) Pacchetto di dominio (frase generica, D3); (8) Anti-pattern in tabella; (9) Checklist post-generazione. Esempi in pseudocodice, nessuna API di un linguaggio. Footer `*Istruzione v1.0 - Concorrenza - 2026-10-14 — <modello>*` come le altre istruzioni
- **Tool ammessi**: Write
- **Verifica passo**: il file esiste, ha frontmatter `applyTo: "**"`, contiene le 9 sezioni e la riga "Resto in serie"; `grep -E "Channel<|Task\.WhenAll|Parallel\.ForEachAsync|producer-consumer-queue"` sul file non dà risultati
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Richiama la regola in "Convenzioni essenziali"
- **Stato**: [x]
- **Precondizione**: Fase 2 `[x]`
- **File**: `.github/copilot-instructions.md`
- **Operazione**: EDIT
- **Azione**: aggiungi in "Convenzioni essenziali (tutti i domini)", dopo la riga sui valori letterali, la riga: "Operazioni indipendenti: preferisci l'esecuzione parallela con limite esplicito, cancellazione ed errori per ramo; se resti in serie, dichiaralo; segui `concurrency.instructions.md`". Aggiorna "Last Update" nel piè di pagina con data e modello
- **Tool ammessi**: Edit
- **Verifica passo**: rilettura: la riga è presente una sola volta, nello stesso stile delle altre voci; la sezione ha 7 voci; "Last Update" riporta 2026-10-14
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: Elenca l'istruzione nel README (con `/dr-professor`)
- **Stato**: [x]
- **Precondizione**: Fase 2 `[x]`; `README.md` integrato con le modifiche delle altre ondate, senza conflitti
- **File**: `README.md`
- **Operazione**: EDIT
- **Azione**: aggiungi dopo la riga di `cross-package-references.instructions.md` la riga `concurrency.instructions.md` con la descrizione "Preferire l'esecuzione parallela con operazioni indipendenti: fan-out e coda con N consumer, limite al parallelismo, cancellazione, errori per ramo, nessuna risorsa non thread-safe condivisa; serie dichiarata (tutti i linguaggi)". Testo via `/dr-professor`; se il README ha un footer di revisione o un conteggio delle istruzioni, aggiornali
- **Tool ammessi**: Skill `/dr-professor`, Edit
- **Verifica passo**: rilettura: riga presente una sola volta, tabella a 2 colonne ben formata, nessun'altra riga alterata
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Aggiungi la regola alla tabella di `docs/onboarding.md`
- **Stato**: [x]
- **Precondizione**: Fase 2 `[x]`; D5 confermata
- **File**: `docs/onboarding.md`
- **Operazione**: EDIT
- **Azione**: aggiungi alla tabella delle regole, prima della riga "Nessun `git push`...", la riga "Operazioni indipendenti: esecuzione parallela con limite, cancellazione ed errori per ramo; serie dichiarata | `concurrency.instructions.md`". Aggiorna il footer di revisione come da `doc-versioning.instructions.md`. Testo via `/dr-professor`
- **Tool ammessi**: Skill `/dr-professor`, Edit
- **Verifica passo**: rilettura: riga presente una sola volta; footer incrementato di 0.1 con data, ora e modello correnti
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: Apri la issue collegata in dr-dotnet-backend (D2-b)
- **Stato**: testo pronto, apertura in attesa dell'utente (testo in `.ai/plans/2026-10-14-issue-20-regola-parallelismo/issue-dr-dotnet-backend.md` nel checkout principale; issue NON creata)
- **Precondizione**: Fasi 2-5 `[x]`; D2 confermata sull'opzione (b); conferma esplicita dell'utente al testo della issue
- **File**: nessuno (azione su GitHub tramite skill)
- **Operazione**: CREATE (issue su `davraf-amuro/dr-dotnet-backend`)
- **Azione**: invoca `/dr-file-feedback` con la descrizione: nuova istruzione .NET con esempi di fan-out (`Task.WhenAll`, `Parallel.ForEachAsync` con `MaxDegreeOfParallelism`), rimando a `producer-consumer-queue.instructions.md` per `Channel<T>`, uno scope DI per ramo, limite da configurazione; cita `dr-guidelines#20`. La skill mostra titolo e corpo e chiede conferma
- **Tool ammessi**: Skill `/dr-file-feedback`
- **Verifica passo**: l'URL della issue creata è annotato in `plan.md`; oppure la nota "issue non aperta per scelta dell'utente"
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7: Verifica finale in contesto isolato
- **Stato**: [x] (verifica isolata CONFORME, nessuna divergenza; gate di push: repo di soli documenti, nessun target di lint, catalog-guard non impattato)
- **Precondizione**: Fasi 1-6 `[x]`; tutti i file di Scope riletti
- **File**: `.ai/plans/2026-10-14-issue-20-regola-parallelismo/plan.md`
- **Operazione**: EDIT
- **Azione**: esegui la verifica finale di `plan-tracking.instructions.md` Fase 4 in un contesto isolato dalla conversazione che ha scritto i file: su Claude Code `/dr-verify-plan`; su Copilot, nuova sessione o secondo revisore. Se tutto conforme, marca i criteri e imposta `Stato: COMPLETATO`; poi commit e PR con `/dr-promote-to` (gate di push: nessun comando di lint applicabile al repo di soli documenti, dichiaralo; la skill segue i propri guard)
- **Tool ammessi**: Skill `/dr-verify-plan`, Skill `/dr-promote-to`
- **Verifica passo**: report di verifica senza divergenze; `Stato: COMPLETATO` e dichiarazione "Piano [slug] verificato. Tutti i criteri soddisfatti."
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] `.github/instructions/concurrency.instructions.md` esiste, ha `applyTo: "**"` e le 9 sezioni previste
- [x] `grep -E "Channel<|Task\.WhenAll|Parallel\.ForEachAsync|producer-consumer-queue"` su quel file non produce risultati (agnostico, nessun rimando secco)
- [x] Il testo contiene i 4 vincoli della issue (limite al parallelismo, cancellazione, errori per ramo, nessuna risorsa non thread-safe condivisa), la regola "serie quando l'ordine conta o c'è dipendenza" e la riga di dichiarazione
- [x] `.github/copilot-instructions.md` richiama `concurrency.instructions.md` una sola volta in "Convenzioni essenziali"
- [x] `README.md` e `docs/onboarding.md` elencano la nuova istruzione una sola volta ciascuno; footer di `docs/onboarding.md` aggiornato
- [x] `git diff --name-only` coincide con l'elenco dello Scope (nessun file fuori Scope)
- [x] Compatibilità duale: nessuna sintassi esclusiva di Claude Code nel file e nelle righe aggiunte (niente `$ARGUMENTS`, sub-agenti, `AskUserQuestion`)
- [ ] Issue collegata in `dr-dotnet-backend` aperta e URL annotato, oppure rinuncia dell'utente annotata
- [x] Verifica finale eseguita in contesto isolato (`/dr-verify-plan`) senza divergenze

Piano issue-20-regola-parallelismo verificato. Tutti i criteri soddisfatti, salvo la Fase 6 in attesa dell'utente.
