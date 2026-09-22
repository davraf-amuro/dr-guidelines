# Piano: Il canale di feedback usa i modelli `ISSUE_TEMPLATE` e applica una label che esiste
Data: 2026-09-22
Stato: PROPOSTO
Issue: davraf-amuro/dr-guidelines#4

## Obiettivo
Far comporre a `/dr-file-feedback` e al prompt Copilot gemello un corpo issue con le stesse sezioni del modello pertinente, e risolvere le label dichiarate nei modelli ma inesistenti nei repository.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/4
- Origine: revisione del piano `2026-09-16-riscrittura-doc-dr`, sezione "Problemi emersi, fuori perimetro".

**Sintesi del problema.** Le due superfici del canale di feedback producono issue diverse: la skill Claude Code compone titolo e corpo da sé, il prompt Copilot rimanda ai modelli in `.github/ISSUE_TEMPLATE/`. I modelli dichiarano `labels: miglioria` e `labels: problema`, ma quelle label non esistono in nessun repository della suite.

**Esito della verifica sui file** (eseguita il 2026-09-22):

| Affermazione della issue | Esito |
|---|---|
| La skill compone titolo e corpo da sé | Confermato: passo 3, "Corpo: contesto, descrizione del problema/miglioria, riferimento a file/riga se disponibile". Nessun riferimento ai modelli |
| Il prompt Copilot usa i modelli | Confermato, riga 32: "Usa il modello presente nel repository di destinazione, in `.github/ISSUE_TEMPLATE/`" |
| I modelli dichiarano `labels: problema` / `labels: miglioria` | Confermato nel front matter di entrambi |
| Nei sette repo esistono solo le label di default | Confermato con `gh label list` su tutti e sette: `bug`, `documentation`, `duplicate`, `enhancement`, `good first issue`, `help wanted`, `invalid`, `question`, `wontfix`. `miglioria` e `problema` non esistono da nessuna parte |
| Il percorso `.claude/skills/dr-segnala-miglioria/SKILL.md` | **Discrepanza**: la skill è stata rinominata dal commit `4bc6f71`. I percorsi reali sono `.claude/skills/dr-file-feedback/SKILL.md` e `.github/prompts/dr-file-feedback.prompt.md` |

**Esito della consultazione** (`/dr-prompt-engineer`, sola lettura, nessun file scritto). Ha portato **tre fatti che la issue non conosce**, tutti verificati dal planner:

1. **I modelli non arrivano mai nel progetto host.** `Copy-InstructionsAndPrompts` copia solo `.github/instructions/` e `.github/prompts/`, `Copy-Skills` copia `.claude/skills/`. La ricerca di `ISSUE_TEMPLATE` nei due file `.ps1` non produce nessuna occorrenza. Quindi il prompt Copilot, quando gira in un host, istruisce l'agente a usare un file che sul disco non c'è: l'agente non lo trova e improvvisa. Questo cambia la natura della correzione — non basta dire "usa il modello", la struttura va scritta **inline nelle due superfici**.
2. **Il front matter `labels:` non si applica comunque.** Vale solo quando la issue nasce dal selettore web dei modelli. Né `gh issue create --body`, né l'URL precompilato `issues/new?title=&body=` passano dal modello. Quindi oggi **nessuna delle due superfici applica una label, e non la applicherebbe nemmeno se `miglioria` e `problema` esistessero**: manca `--label` nei comandi, che è anche il punto in cui una label inesistente farebbe fallire `gh`.
3. **I modelli sono byte-identici in tutti e sette i repo** (confronto a coppie: nessuna differenza), il che rende la propagazione una copia meccanica.

Inoltre: la **variante "nuovo pacchetto"** della skill (caso di gap di catalogo, delegato da `/dr-scaffold`, con destinazione fissa `davraf-amuro/dr-guidelines` — confermato in `scaffolding-catalog.json`, `fallback.issueRepo`) non corrisponde a nessuno dei due modelli esistenti: "Pacchetto e file interessati" non ha senso per un pacchetto che non esiste.

**Principio applicato nella correzione proposta.** Un'istruzione che rimanda a una risorsa non garantita è un'istruzione che il modello aggira in silenzio. La struttura autorevole va scritta dentro le due superfici; i modelli restano la fonte per chi apre la issue dal web. La duplicazione è il prezzo consapevole di questa scelta.

**Sulle label, tre opzioni:**

| Opzione | Pro | Contro |
|---|---|---|
| A — creare `miglioria` e `problema` nei sette repo | Tassonomia italiana coerente col resto della suite | Quattordici creazioni a mano, da rifare a ogni repo nuovo; nessuno script le predispone, quindi il difetto si ripresenta; `bug` ed `enhancement` restano inutilizzate |
| B — togliere `labels:` dai modelli | Zero divergenza, modelli finalmente veritieri, niente da predisporre | Issue senza label: nessun filtro per tipo, triage a mano |
| C — mappare sulle label di default (`miglioria` → `enhancement`, `problema` → `bug`) | Le label esistono già in tutti e sette i repo e in ogni repo futuro, perché le crea GitHub; `--label` funziona da subito senza operazioni preliminari; zero manutenzione | Nomi in inglese in una suite italiana; `bug` è semanticamente stretto per "regola ambigua" |

La consultazione raccomanda **C**, perché è l'unica che elimina la classe di difetto invece di spostarla: nessuna lista di label da tenere sincronizzata a mano su N repository. In ogni caso va aggiunto `--label` ai comandi, altrimenti la label non arriva mai, qualunque nome abbia.

**Sulla variante "nuovo pacchetto"**, tre opzioni, la prima raccomandata: un terzo modello presente **solo** in `dr-guidelines` (il gap di catalogo ha destinazione fissa lì); una sezione dentro `miglioria.md` (sconsigliata: sporca un modello comune a sette repo con un caso che ne riguarda uno); nessun modello, solo le superfici agente (sconsigliata: chi apre la issue dal web resta senza guida).

**Nota di compatibilità duale.** `SKILL.md` è esente perché sta in `.claude/skills/`. `.github/prompts/*.prompt.md` e i modelli `ISSUE_TEMPLATE` sono file condivisi: i testi proposti sono markdown neutro — tabelle e blocchi recintati — leggibili da entrambi gli agenti.

## Decisioni aperte

1. **Label**: A (italiane, da creare nei sette repo), B (nessuna label) o C (default `bug` ed `enhancement`). La consultazione raccomanda C. Il testo delle fasi assume C; con A basta sostituire i nomi nelle tabelle e nel front matter, più una fase di predisposizione delle label.
2. **Se C: `bug` o `documentation`** per `problema.md`. `documentation` è più preciso per "regola ambigua", `bug` più leggibile a colpo d'occhio.
3. **Terzo modello `nuovo-pacchetto.md`** in `dr-guidelines`: sì o no.
4. **Ambito di propagazione**: i modelli si toccano in tutti e sette i repo (sette commit separati, sono repository distinti) o solo in `dr-guidelines` in questo giro, rimandando gli altri sei?
5. **Se A**: aggiungere la predisposizione delle label a uno script di manutenzione, o accettare i comandi manuali a ogni repo nuovo?

## Scope

### File da modificare
- [ ] `.github/ISSUE_TEMPLATE/problema.md` e `miglioria.md` — front matter `labels:` allineato alla decisione 1
- [ ] `.github/ISSUE_TEMPLATE/nuovo-pacchetto.md` — CREATE, solo se la decisione 3 è sì
- [ ] `.claude/skills/dr-file-feedback/SKILL.md` — passo 3 (struttura del corpo), passo 5 (`--label`), regole inviolabili, casi limite
- [ ] `.github/prompts/dr-file-feedback.prompt.md` — passo 3, passo 5, regole, footer di versione
- [ ] `README.md` e `docs/onboarding.md` — solo se la decisione 3 aggiunge un terzo modello: entrambi citano "due modelli"
- [ ] Gli altri sei repository `dr-*`, file `.github/ISSUE_TEMPLATE/miglioria.md` e `problema.md` — solo se la decisione 4 include la propagazione

### Perimetro negativo
- Non toccherò: il guard della skill che vieta `gh issue create` senza conferma esplicita di titolo e corpo — resta invariato
- Non toccherò: il passo 2 della skill (deduzione del pacchetto dal manifest) né il caso a parte del gap di catalogo nella sua logica di instradamento
- Non toccherò: `dr-guidelines-install-lib.ps1` — la distribuzione dei modelli agli host non è l'obiettivo di questa issue, e la correzione proposta la rende superflua scrivendo la struttura inline
- Non toccherò: le label esistenti nei repository, se la decisione 1 sceglie B o C
- Non toccherò: le issue già aperte — nessuna modifica, nessuna etichettatura retroattiva
- Non toccherò: le altre skill e gli altri prompt

## Fasi (formato atomico — obbligatorio)

### Fase 0: Decisioni bloccanti
- **Stato**: [ ]
- **Precondizione**: il piano è stato approvato per l'esecuzione
- **File**: questo `plan.md`
- **Operazione**: EDIT
- **Azione**: sottoporre all'utente le decisioni aperte 1-5 e annotarne qui le risposte. Le fasi 1, 2, 5, 6 e 7 dipendono dall'esito.
- **Tool ammessi**: nessuno
- **Verifica passo**: ogni decisione aperta ha una risposta scritta in questo file
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 0: <cosa>` in plan.md, non procedere

### Fase 1: Front matter dei modelli
- **Stato**: [ ]
- **Precondizione**: Fase 0 completata, decisione 1 presa
- **File**: `.github/ISSUE_TEMPLATE/problema.md`, `.github/ISSUE_TEMPLATE/miglioria.md`
- **Operazione**: EDIT
- **Azione**: allineare la riga `labels:` alla decisione. Con l'opzione B, rimuovere la riga. Con A o C, scrivere il nome deciso. Le sezioni del corpo dei modelli non si toccano.
- **Tool ammessi**: nessuno
- **Verifica passo**: il front matter dichiara solo label che esistono davvero nel repository, oppure nessuna label
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2 *(condizionata alla decisione 3)*: Terzo modello
- **Stato**: [ ]
- **Precondizione**: la decisione 3 è "sì"
- **File**: `.github/ISSUE_TEMPLATE/nuovo-pacchetto.md`
- **Operazione**: CREATE
- **Azione**: creare il modello con front matter `name: Richiesta di nuovo pacchetto`, label coerente con la decisione 1, e le sezioni: Dominio richiesto; Cosa voleva fare l'utente (con le sue parole, non parafrasate); Perché i pacchetti esistenti non bastano (se il dominio somiglia a un pacchetto esistente, dirlo: può essere un'estensione, non un repository nuovo); Kind proposto (`dotnet`, `node`, `any` o nuovo, con motivazione); Cosa dovrebbe contenere il pacchetto; Contesto di installazione. Solo in `dr-guidelines`: il gap di catalogo ha destinazione fissa lì.
- **Tool ammessi**: nessuno
- **Verifica passo**: il file esiste solo in `dr-guidelines` e le sue sezioni coincidono con quelle che le fasi 3 e 4 scrivono nelle due superfici
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Struttura del corpo nella skill
- **Stato**: [ ]
- **Precondizione**: Fasi 1 e 2 completate o saltate
- **File**: `.claude/skills/dr-file-feedback/SKILL.md`
- **Operazione**: EDIT
- **Azione**: riscrivere il passo 3 perché contenga, **inline**, la struttura di ciascun modello: sezioni, ordine e titoli di livello `##`. Dichiarare esplicitamente che i modelli vivono nel repository di destinazione e **non** sono installati nel progetto host, quindi non vanno cercati su disco né letti via rete: la struttura autorevole è quella scritta nella skill. Aggiungere una tabella che associa il tipo di segnalazione al modello e alla label. Aggiungere le regole di compilazione: "Contesto di installazione" si compila dal manifest letto al passo 1 e mai si inventa; nessuna sezione vuota e nessun commento segnaposto nel corpo — dato non disponibile, scrivere `Non disponibile`; nessuna sezione in più né rinominata.
- **Tool ammessi**: nessuno
- **Verifica passo**: il passo 3 elenca le sezioni di ogni modello e non rimanda più a un file da cercare su disco
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: Struttura del corpo nel prompt Copilot
- **Stato**: [ ]
- **Precondizione**: Fase 3 completata
- **File**: `.github/prompts/dr-file-feedback.prompt.md`
- **Operazione**: EDIT
- **Azione**: riscrivere il passo 3 con lo stesso contenuto della Fase 3, adattato alla superficie (l'agente dichiarato nel "Contesto di installazione" è GitHub Copilot). Sostituire la riga 32, che oggi rimanda ai modelli nel repository di destinazione. Markdown neutro: tabelle e blocchi recintati.
- **Tool ammessi**: nessuno
- **Verifica passo**: le sezioni elencate nel prompt coincidono, una a una e nello stesso ordine, con quelle della Fase 3
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Applicazione della label nei comandi
- **Stato**: [ ]
- **Precondizione**: Fasi 3 e 4 completate; la decisione 1 non è B
- **File**: `.claude/skills/dr-file-feedback/SKILL.md`, `.github/prompts/dr-file-feedback.prompt.md`
- **Operazione**: EDIT
- **Azione**: aggiungere `--label <label>` al comando `gh issue create` e `&labels=<label>` all'URL precompilato di ripiego, in entrambe le superfici. Aggiungere la regola di ripiego: se il comando fallisce perché la label non esiste nel repository, **non crearla** — ripetere una sola volta senza `--label` e dichiarare all'utente che la issue è stata aperta senza label.
- **Tool ammessi**: nessuno
- **Verifica passo**: entrambe le superfici passano la label e gestiscono il fallimento senza creare nulla nel repository di destinazione
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: Regole inviolabili e casi limite
- **Stato**: [ ]
- **Precondizione**: Fase 5 completata o saltata
- **File**: `.claude/skills/dr-file-feedback/SKILL.md`, `.github/prompts/dr-file-feedback.prompt.md`
- **Operazione**: EDIT
- **Azione**: aggiungere alle regole di entrambe le superfici il divieto di creare label, milestone o altri oggetti nel repository di destinazione — il canale apre issue, nient'altro — e il divieto di comporre il corpo in forma libera, perché la struttura del modello scelto è vincolante. Aggiungere ai casi limite della skill: label inesistente nel repository (riprova una volta senza, dichiaralo, non crearla) e modello non deducibile (chiedi all'utente se è un problema o una miglioria, non scegliere al posto suo). Il guard esistente sulla conferma di titolo e corpo resta invariato.
- **Tool ammessi**: nessuno
- **Verifica passo**: le due regole nuove sono presenti in entrambe le superfici; il guard sulla conferma è invariato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7 *(condizionata alla decisione 3)*: Documentazione allineata
- **Stato**: [ ]
- **Precondizione**: la Fase 2 ha aggiunto un terzo modello
- **File**: `README.md`, `docs/onboarding.md`
- **Operazione**: EDIT
- **Azione**: aggiornare i punti in cui i documenti parlano di "due modelli", e le rispettive righe di versione secondo `doc-versioning.instructions.md`.
- **Tool ammessi**: nessuno
- **Verifica passo**: nessuno dei due documenti afferma più che i modelli sono due
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

### Fase 8 *(condizionata alla decisione 4)*: Propagazione agli altri sei repository
- **Stato**: [ ]
- **Precondizione**: la decisione 4 include la propagazione; Fase 1 completata
- **File**: `.github/ISSUE_TEMPLATE/miglioria.md` e `problema.md` in `dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`, `dr-dotnet-backend`
- **Operazione**: EDIT
- **Azione**: copiare negli altri sei repository il contenuto dei modelli allineato alla Fase 1. Erano byte-identici prima della modifica, quindi la copia è meccanica. Sei commit separati: sono repository distinti. Il terzo modello **non** si propaga: resta solo in `dr-guidelines`.
- **Tool ammessi**: nessuno
- **Verifica passo**: i modelli dei sette repository tornano byte-identici tra loro, con la sola eccezione del terzo modello presente solo in `dr-guidelines`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 8: <cosa>` in plan.md, non procedere

### Fase 9 *(condizionata: solo se la decisione 1 è A)*: Predisposizione delle label
- **Stato**: [ ]
- **Precondizione**: la decisione 1 ha scelto le label italiane
- **File**: nessuno — operazione su GitHub
- **Operazione**: nessuna modifica a file
- **Azione**: creare le label decise nei sette repository. Se la decisione 5 lo prevede, aggiungere anche la predisposizione a uno script di manutenzione, così che un repository nuovo non riapra il difetto.
- **Tool ammessi**: `gh` (creazione label)
- **Verifica passo**: l'elenco delle label di ciascuno dei sette repository contiene i nomi decisi
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 9: <cosa>` in plan.md, non procedere

### Fase 10: Prova a secco del canale
- **Stato**: [ ]
- **Precondizione**: Fasi 3-6 completate
- **File**: nessuno
- **Operazione**: nessuna modifica
- **Azione**: invocare `/dr-file-feedback` su un caso di prova e **fermarsi al passo di conferma**, senza mai confermare: nessuna issue viene creata. Controllare che il corpo mostrato abbia esattamente le sezioni del modello pertinente, nessuna sezione vuota e nessun commento segnaposto.
- **Tool ammessi**: quelli della skill, fermandosi prima della creazione
- **Verifica passo**: il corpo proposto rispetta la struttura; nessuna issue risulta creata nel repository di destinazione
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 10: <cosa>` in plan.md, non procedere

### Fase 11: Verifica finale in contesto isolato
- **Stato**: [ ]
- **Precondizione**: Fasi 0-10 completate o saltate con nota
- **File**: tutti quelli elencati in "Scope"
- **Operazione**: nessuna modifica — sola verifica
- **Azione**: eseguire il controllo finale di `plan-tracking.instructions.md`, Fase 4 punto 4, in un contesto isolato dalla conversazione che ha eseguito il piano: nuova sessione, sub-agente o secondo revisore. Su Claude Code corrisponde alla skill `/dr-verify-plan`.
- **Tool ammessi**: quelli del revisore, in sola lettura
- **Verifica passo**: il revisore conferma ogni criterio della sezione seguente
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 11: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [ ] Le due superfici compongono il corpo sulle stesse sezioni, nello stesso ordine, con gli stessi titoli
- [ ] Nessuna delle due superfici rimanda più a un modello da cercare su disco nel progetto host
- [ ] Nessun front matter dichiara una label che non esiste nel repository
- [ ] Se la decisione 1 non è B: entrambe le superfici passano la label nel comando e nell'URL di ripiego, e gestiscono il fallimento senza creare label
- [ ] Il guard "mai aprire una issue senza conferma esplicita di titolo e corpo" è invariato
- [ ] La variante "nuovo pacchetto" ha una struttura propria e non usa sezioni prive di senso per un pacchetto inesistente
- [ ] Nessun costrutto esclusivo di un tool nei file condivisi: compatibilità duale rispettata
- [ ] Nessun file fuori da "Scope" è stato modificato, e nessuna issue è stata creata durante l'esecuzione del piano
