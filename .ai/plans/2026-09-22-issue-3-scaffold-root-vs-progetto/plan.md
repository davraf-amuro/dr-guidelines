# Piano: `/dr-scaffold-solution` distingue la root del repository dalle cartelle di progetto
Data: 2026-09-22
Stato: PROPOSTO
Issue: davraf-amuro/dr-guidelines#3

## Obiettivo
Riscrivere la regola di STOP su cartella non vuota perché tolleri i file del core nella root del repository — dove sono attesi — e resti intransigente sulle cartelle di progetto, con lo stesso testo su Claude Code e GitHub Copilot.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/3
- Origine: revisione del piano `2026-09-16-riscrittura-doc-dr`, sezione "Problemi emersi, fuori perimetro". Non ancora riprodotto sul campo.

**Sintesi del problema.** Il flusso consigliato è "cartella vuota → installa il core → reload → `/dr-scaffold`". Quando `/dr-scaffold-solution` parte, la root contiene già `CLAUDE.md`, `.github/`, `.claude/`, `.ai/`, messi lì dall'installer. La regola attuale si ferma su qualsiasi destinazione non vuota, senza eccezione per quei file: lo scaffolding rischia di bloccarsi proprio nel flusso che la documentazione raccomanda.

**Esito della verifica sui file** (eseguita il 2026-09-22):

| Affermazione della issue | Esito |
|---|---|
| `dr-scaffold-solution/SKILL.md` riga 95 blocca su destinazione non vuota | Confermato, testo letterale: "Se un percorso di destinazione **esiste già** e non è vuoto: fermati e dillo. Non sovrascrivere, non 'fondere'." |
| `dr-scaffold-solution/SKILL.md` riga 259 idem | Confermato: "Cartella di destinazione già popolata → STOP, mai sovrascrivere." |
| `.github/prompts/dr-scaffold.prompt.md` va allineato | Confermato, ma i punti da correggere sono **tre**, non uno: riga 123, riga 260, riga 346. La issue cita il file genericamente |

**Esito della consultazione** (`/dr-prompt-engineer`, sola lettura, nessun file scritto). Diagnosi in cinque punti, tutti verificati sui file dal planner:

1. **Un termine per due referenti.** "Percorso di destinazione" copre sia la root del repository (che la Fase 0 definisce come la cartella corrente) sia le foglie che `dotnet new -o` e `create-vue` scrivono. Letta alla lettera, nel flusso consigliato la condizione "esiste già e non è vuoto" sulla root è **sempre vera**.
2. **Solo perimetro negativo.** Il testo dice cosa non fare, mai cosa è lecito trovare. Senza allow-list il modello non distingue i file del core dal lavoro vero dell'utente, e sceglie la lettura più conservativa: si blocca.
3. **Vocabolari scollegati.** La tabella di stato del prompt (riga 21) conosce la categoria "file di appoggio" (README/.gitignore/LICENSE); la regola di STOP non la usa e non la estende ai file del core.
4. **Contraddizione nel router.** `dr-scaffold/SKILL.md` riga 89 ("qualsiasi altro stato senza solution → `dr-scaffold-solution`") manda dentro proprio la cartella col core installato; la riga 95 di `dr-scaffold-solution` la butta fuori. Il commento del file chiama quella riga "la rete": il flusso consigliato regge per ripiego, non per intenzione.
5. **Tre soglie per una regola sola.** SKILL riga 95 dice "esiste già **e non è vuoto**"; `dr-scaffold-project/SKILL.md` riga 99 dice "esiste già" (blocca anche su cartella vuota) e riga 211 "Progetto o cartella già esistente → STOP"; nel prompt la riga 260 usa la forma stretta, la 123 quella larga.

La consultazione ha prodotto il testo di sostituzione per tutti e cinque i punti, riportato nelle Fasi. Vocabolario unico introdotto: **root del repository** (tollerante, allow-list chiusa) contro **cartella di progetto** (intransigente). Solo markdown e prosa: nessun costrutto esclusivo di un tool, compatibilità duale rispettata.

**Effetti collaterali da non rompere, segnalati dalla consultazione e verificati:**

- **`create-vue`, SKILL riga 158.** La tolleranza vale **solo** per la root. La cartella del frontend resta una cartella di progetto, quindi assente o vuota, e l'ordine "create-vue prima dell'install del core" (4.5 prima di 4.7) non va toccato. Da evitare qualsiasi formulazione generica del tipo "i file del core sono tollerati ovunque": renderebbe incoerente il testo di 4.5 e inviterebbe a invertire l'ordine.
- **Modalità multi-repo.** La cartella corrente contiene il `.code-workspace` e non è una root di repository: le root sono `backend/` e `frontend/`, create ex novo. Il testo proposto dice "root del repository", non "cartella corrente", quindi è già corretto — ma va verificato esplicitamente (Fase 7).
- **`*.csproj` sciolti**, SKILL riga 145 e prompt riga 24: si agganciano senza spostarli. Il nuovo testo non lo contraddice.
- **Rischio opposto, allentare troppo.** Mitigato nel testo proposto: allow-list chiusa ed enumerata invece di una regola generica sui dotfile (che tollererebbe `.vs/`, `.idea/`, `node_modules/`, una `src/` piena); `*.slnx`/`*.sln` nella root escluso dalla tolleranza perché è un segnale di instradamento; fallback "elenca e chiedi" invece di "prosegui" sul contenuto sconosciuto.

**Avvertenza operativa.** Ogni sostituzione è più lunga della riga che rimpiazza, quindi i numeri di riga slittano. Applicare dal basso verso l'alto dentro ciascun file (346 → 260 → 123; 259 → 95), oppure localizzare per testo letterale invece che per numero di riga.

## Decisioni aperte

1. **Estensione dell'allow-list della root.** Il testo proposto elenca `.git/`, `.github/`, `.claude/`, `.ai/`, `CLAUDE.md`, `README.md`, `LICENSE`, `.gitignore`, `.gitattributes`, `.editorconfig` più la formula aperta "config radice dei pacchetti `dr-*`". Vanno nominati esplicitamente anche `Directory.Build.props`, `global.json`, `.mcp.json`, `.vscode/`, `*.code-workspace`? Nominarli è più prevedibile; la formula aperta invecchia meglio quando nasce un pacchetto nuovo.
2. **Contenuto inatteso nella root: chiedere o bloccare?** La proposta è "elenca e chiedi" — STOP morbido, con l'utente nel giro. L'alternativa conservativa è lo STOP duro anche lì. È un cambio di postura, non di parole.
3. **Soglia per le cartelle di progetto: "assente o vuota" oppure "assente"?** La proposta ammette la cartella vuota, allineandosi alla riga 95 attuale. `dr-scaffold-project` riga 99 oggi blocca anche su cartella vuota: va allineato, o la differenza è voluta?
4. **Ampiezza dell'intervento oltre i cinque punti della issue.** Tre superfici hanno lo stesso vocabolario difettoso e la issue non le cita: la tabella di stato del prompt (riga 21), la tabella di instradamento di `dr-scaffold/SKILL.md` (righe 83 e 89), la regola gemella di `dr-scaffold-project/SKILL.md` (righe 99 e 211). Senza allinearle, il flusso consigliato continua a reggere solo grazie alla "riga rete". Dentro o fuori scope? La Fase 6 è condizionata a questa risposta.
5. **Aggiungere un controllo eseguibile?** Per esempio un `Get-ChildItem` della root prima del dry-run, con l'allow-list applicata, invece della sola regola dichiarativa. Sarebbe compatibile con entrambi gli agenti — tutti e due eseguono `pwsh` in questo progetto — ma alza il costo di manutenzione del testo.

## Scope

### File da modificare
- [ ] `.claude/skills/dr-scaffold-solution/SKILL.md` — righe 95 e 259
- [ ] `.github/prompts/dr-scaffold.prompt.md` — righe 123, 260, 346
- [ ] *(condizionato alla decisione aperta 4)* `.claude/skills/dr-scaffold/SKILL.md` righe 83 e 89; `.claude/skills/dr-scaffold-project/SKILL.md` righe 99 e 211; `.github/prompts/dr-scaffold.prompt.md` riga 21

### Perimetro negativo
- Non toccherò: `.claude/skills/dr-scaffold-solution/SKILL.md` riga 158 (ordine `create-vue` → install del core) né la sezione 4.5
- Non toccherò: la riga 192 (`Install-DrPackage`, `(Get-Location).Path`, `Push-Location`/`Pop-Location`)
- Non toccherò: la riga 145 sui `*.csproj` sciolti agganciati senza spostarli
- Non toccherò: la regola "una sola conferma alla Fase 3" né il divieto di `git push`
- Non toccherò: `dr-guidelines-install.ps1`, `dr-guidelines-install-lib.ps1`, `scaffolding-catalog.json`
- Non toccherò: le fasi 6 del blocco condizionato, se la decisione aperta 4 è "fuori scope"
- Non toccherò: gli altri repository `dr-*`

## Fasi (formato atomico — obbligatorio)

> Applicare le fasi 1-5 **dal basso verso l'alto** per file (prima la 5, poi la 4, poi la 3; prima la 2, poi la 1) oppure localizzare per testo letterale: ogni sostituzione allunga il file e sposta le righe successive.

### Fase 1: Regola normativa nella skill
- **Stato**: [ ]
- **Precondizione**: `.claude/skills/dr-scaffold-solution/SKILL.md` riga 95 contiene ancora "Se un percorso di destinazione **esiste già** e non è vuoto: fermati e dillo. Non sovrascrivere, non 'fondere'."
- **File**: `.claude/skills/dr-scaffold-solution/SKILL.md`
- **Operazione**: EDIT
- **Azione**: sostituire quella riga singola con il blocco seguente:

  ```markdown
  **Cosa deve essere vuoto, e cosa no.** Due livelli, con regole diverse:

  - **Root del repository** — ci si aspetta di trovarci i file del core già installati: `.git/`, `.github/`, `.claude/`, `.ai/`, `CLAUDE.md`, `README.md`, `LICENSE`, `.gitignore`, `.gitattributes`, `.editorconfig` e i file di configurazione radice portati dai pacchetti `dr-*`. Lasciali intatti e **prosegui**: "installa il core, poi `/dr-scaffold`" è il flusso consigliato, non un conflitto.
  - **Cartelle di progetto** — `src/<nome>`, `test/<nome>` e la cartella del frontend devono essere **assenti o vuote**. Se una esiste e contiene qualcosa: fermati e dillo. Non sovrascrivere, non "fondere", mai `--force` su `dotnet new`.

  Nella root trovi altro — sorgenti, cartelle sconosciute, un `*.slnx`/`*.sln` già presente: **elenca cosa hai trovato e chiedi** prima di scrivere. Un file solution nella root significa che il caso è "aggiungi un progetto", non "solution da zero".
  ```
- **Tool ammessi**: nessuno
- **Verifica passo**: il blocco è presente e nella sezione non resta nessuna occorrenza non qualificata di "percorso di destinazione"
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Eco della regola nella sezione "Regole" della skill
- **Stato**: [ ]
- **Precondizione**: Fase 1 completata; la voce "Cartella di destinazione già popolata → STOP, mai sovrascrivere." esiste ancora nella sezione "Regole"
- **File**: `.claude/skills/dr-scaffold-solution/SKILL.md`
- **Operazione**: EDIT
- **Azione**: sostituire quella voce con:

  ```markdown
  - Root del repository: i file del core (`.github/`, `.claude/`, `.ai/`, `CLAUDE.md`, config radice) sono attesi, si lasciano stare. Cartella di progetto (`src/<nome>`, `test/<nome>`, frontend) esistente e non vuota → STOP, mai sovrascrivere. Altro contenuto inatteso nella root → elenca e chiedi.
  ```
- **Tool ammessi**: nessuno
- **Verifica passo**: la voce nuova è presente e dice la stessa cosa del blocco della Fase 1, in forma sintetica
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Specchio Copilot della regola normativa
- **Stato**: [ ]
- **Precondizione**: `.github/prompts/dr-scaffold.prompt.md` riga 123 contiene ancora "Percorso di destinazione già esistente e non vuoto → STOP. Non sovrascrivere, non fondere."
- **File**: `.github/prompts/dr-scaffold.prompt.md`
- **Operazione**: EDIT
- **Azione**: sostituire quella riga con:

  ```markdown
  Due livelli, con regole diverse. **Root del repository**: i file del core già installati (`.git/`, `.github/`, `.claude/`, `.ai/`, `CLAUDE.md`, `README.md`, `LICENSE`, `.gitignore`, `.gitattributes`, `.editorconfig`, config radice dei pacchetti `dr-*`) sono attesi — lasciali intatti e prosegui. **Cartelle di progetto** (`src/<nome>`, `test/<nome>`, frontend): devono essere assenti o vuote; se esistono e contengono qualcosa → STOP, non sovrascrivere, non fondere. Altro contenuto nella root (sorgenti, cartelle sconosciute, un `*.slnx`/`*.sln` già presente) → elenca cosa hai trovato e chiedi: una solution nella root significa Sezione B, non Sezione A.
  ```
- **Tool ammessi**: nessuno
- **Verifica passo**: il testo è presente e coincide nel merito con il blocco della Fase 1
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: Sezione B del prompt — vale solo la cartella del progetto
- **Stato**: [ ]
- **Precondizione**: `.github/prompts/dr-scaffold.prompt.md` riga 260 contiene ancora "Dry-run + una conferma. Cartella di destinazione già esistente → STOP."
- **File**: `.github/prompts/dr-scaffold.prompt.md`
- **Operazione**: EDIT
- **Azione**: sostituire quel punto con:

  ```markdown
  4. Dry-run + una conferma. La cartella del nuovo progetto (`<targetPath>\<nome>`) deve essere assente o vuota: esiste e contiene qualcosa → STOP, mai `--force` su `dotnet new`. Il resto del repository qui è popolato per definizione — c'è una solution: non è un motivo per fermarsi.
  ```
- **Tool ammessi**: nessuno
- **Verifica passo**: il punto 4 della Sezione B non parla più di "cartella di destinazione" in senso generico
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Eco della regola nelle "Regole" del prompt
- **Stato**: [ ]
- **Precondizione**: `.github/prompts/dr-scaffold.prompt.md` riga 346 contiene ancora "Percorso di destinazione già popolato → STOP, mai sovrascrivere, mai `--force` su `dotnet new`."
- **File**: `.github/prompts/dr-scaffold.prompt.md`
- **Operazione**: EDIT
- **Azione**: sostituire quella voce con:

  ```markdown
  - Root del repository: i file del core (`.github/`, `.claude/`, `.ai/`, `CLAUDE.md`, config radice) sono attesi e si lasciano intatti. Cartella di progetto (`src/<nome>`, `test/<nome>`, frontend) esistente e non vuota → STOP, mai sovrascrivere, mai `--force` su `dotnet new`. Contenuto inatteso nella root → elenca e chiedi.
  ```
- **Tool ammessi**: nessuno
- **Verifica passo**: la voce nuova è presente e coincide con quella della Fase 2
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6 *(condizionata alla decisione aperta 4)*: Allineamento delle superfici non citate dalla issue
- **Stato**: [ ]
- **Precondizione**: l'utente ha risposto "dentro scope" alla decisione aperta 4. Risposta "fuori scope" → salta la fase e annotalo qui.
- **File**: `.github/prompts/dr-scaffold.prompt.md` (riga 21), `.claude/skills/dr-scaffold/SKILL.md` (righe 83 e 89), `.claude/skills/dr-scaffold-project/SKILL.md` (righe 99 e 211)
- **Operazione**: EDIT
- **Azione**: portare in queste cinque posizioni lo stesso vocabolario delle fasi precedenti — root del repository contro cartella di progetto. In particolare: nelle due tabelle di stato, la riga "cartella vuota o con soli file di appoggio" va estesa ai file del core; in `dr-scaffold-project` le due formulazioni ("cartella di destinazione esiste già", "progetto o cartella già esistente") vanno portate alla soglia decisa al punto 3 delle decisioni aperte.
- **Tool ammessi**: nessuno
- **Verifica passo**: nelle cinque posizioni non resta nessuna occorrenza non qualificata di "destinazione"; la soglia è la stessa in tutti e quattro i file
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7: Controllo di coerenza sui testi
- **Stato**: [ ]
- **Precondizione**: Fasi 1-5 completate, Fase 6 completata o saltata
- **File**: tutti quelli di "Scope"
- **Operazione**: nessuna modifica — sola verifica
- **Azione**: rileggere i punti modificati e confrontare il merito di SKILL e prompt, che devono dire la stessa cosa. Cercare nei file ogni occorrenza residua di "cartella di destinazione" e "percorso di destinazione" non qualificata. Rileggere la riga 158 della skill e accertare che l'ordine `create-vue` → install del core sia intatto e non contraddetto. Rileggere la sezione multi-repo e accertare che la tolleranza della root non venga applicata per errore alla cartella che contiene il `.code-workspace`.
- **Tool ammessi**: nessuno (sola lettura)
- **Verifica passo**: nessuna occorrenza non qualificata residua; riga 158 invariata; multi-repo coerente
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

### Fase 8: Aggiornamento delle versioni dei documenti
- **Stato**: [ ]
- **Precondizione**: Fase 7 completata
- **File**: i file modificati che riportano una riga di versione
- **Operazione**: EDIT
- **Azione**: aggiornare la riga finale di versione secondo `doc-versioning.instructions.md` — data odierna, modello usato e una frase sulla modifica.
- **Tool ammessi**: nessuno
- **Verifica passo**: ogni file modificato che prevede la riga di versione la riporta aggiornata alla data odierna
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 8: <cosa>` in plan.md, non procedere

### Fase 9: Verifica finale in contesto isolato
- **Stato**: [ ]
- **Precondizione**: Fasi 1-8 completate o saltate con nota
- **File**: tutti quelli elencati in "Scope"
- **Operazione**: nessuna modifica — sola verifica
- **Azione**: eseguire il controllo finale di `plan-tracking.instructions.md`, Fase 4 punto 4, in un contesto isolato dalla conversazione che ha scritto le modifiche: nuova sessione, sub-agente o secondo revisore. Su Claude Code corrisponde alla skill `/dr-verify-plan`.
- **Tool ammessi**: quelli del revisore, in sola lettura
- **Verifica passo**: il revisore conferma ogni criterio della sezione seguente
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 9: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [ ] Nel testo finale "destinazione" non compare più da sola: ogni occorrenza è qualificata come *root del repository* o *cartella di progetto*
- [ ] Lo scenario "cartella con `CLAUDE.md`, `.github/`, `.claude/`, `.ai/` e nient'altro" è esplicitamente **prosegui**, su entrambe le superfici
- [ ] Lo scenario "`src/<nome>` già popolata" è esplicitamente **STOP**, su entrambe le superfici
- [ ] La cartella del frontend resta trattata come cartella di progetto, e la riga 158 (ordine `create-vue` → install del core) è invariata e non contraddetta
- [ ] `*.slnx`/`*.sln` nella root non rientra nella tolleranza: resta un segnale di instradamento verso "aggiungi un progetto"
- [ ] Nessun costrutto esclusivo di un tool nei testi inseriti: solo markdown e prosa, compatibilità duale rispettata
- [ ] Nessun file fuori da "Scope" è stato modificato
