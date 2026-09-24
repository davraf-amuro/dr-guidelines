# Piano: Dipendenze implicite da `dr-minimalapi` non dichiarate nel catalogo
Data: 2026-09-22
Stato: COMPLETATO — verificato il 2026-09-24 in contesto isolato (vedi Consuntivo)
Issue: davraf-amuro/dr-guidelines#5

## Obiettivo
Chiudere i tre rimandi a `minimal-api-architecture.instructions.md` che oggi si rompono in silenzio, scegliendo per ciascun pacchetto fra dipendenza dichiarata e rimando condizionale con riassunto minimo.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/5
- Origine: revisione del piano `2026-09-16-riscrittura-doc-dr`, sezione "Problemi emersi, fuori perimetro".

**Sintesi del problema.** Tre pacchetti rimandano a `minimal-api-architecture.instructions.md` (pacchetto `dr-minimalapi`) come fonte unica, ma nel catalogo hanno `dependencies: []`. Un host che installa uno di questi senza `dr-minimalapi` riceve un rimando a un file che non ha: l'agente non trova la fonte e improvvisa.

**Esito della verifica sui file** (eseguita il 2026-09-22): tutti e tre i rimandi esistono e dicono quello che la issue riporta.

| Pacchetto | Rimando verificato |
|---|---|
| `dr-efdb` | `database-provider.instructions.md`, sezione "8️⃣ Uso negli Endpoint (tramite Service)": "iniettano il Service (`Services/<Entity>Service.cs`, vedi `minimal-api-architecture.instructions.md` regola 12)" |
| `dr-fe` | `frontend-organization.instructions.md`, "La login non si implementa nel frontend": "Segui `minimal-api-architecture.instructions.md`, sezione 'Autenticazione', che è la fonte unica per la scelta dello schema"; e nella checklist finale la voce corrispondente |
| `dr-devops` | `docker-swarm-compose.instructions.md`: "Il lato codice — `PersistKeysToDbContext` / `PersistKeysToFileSystem`, `SetApplicationName` e `UseForwardedHeaders` — è definito in `minimal-api-architecture.instructions.md`, sezione 'Autenticazione': **fonte unica**, non duplicare qui" |

Catalogo attuale, verificato: `dr-efdb` `appliesTo: [dotnet]` `dependencies: []`; `dr-fe` `appliesTo: [node]` `dependencies: []`; `dr-devops` `appliesTo: [any]` `dependencies: []`; `dr-minimalapi` `appliesTo: [dotnet]` `dependencies: [dr-dotnet-backend]`.

**Comportamento dell'installer, verificato nel codice.** È il fatto che determina tutto il resto:

- `Get-DrPackageRegistry` costruisce il registry con **solo** `Repo`, `IsCore`, `Dependencies`, `RootFiles`, `ObsoleteArtifacts`. **`appliesTo` non viene letto affatto dall'installer.**
- `Install-DrPackage`, per ogni dipendenza non installata, stampa "Dipendenza mancante: … installazione automatica" e richiama sé stesso. **Risoluzione automatica, ricorsiva, senza conferma dell'utente.**
- `Copy-PackageRootFiles` copia i `rootFiles` nella radice host, e `dr-dotnet-backend` porta `Directory.Build.props` e `global.json`.

Conseguenza: dichiarare `dr-minimalapi` come dipendenza di `dr-fe` o `dr-devops` installerebbe **silenziosamente** due pacchetti .NET e due file di progetto .NET nella radice di un host che .NET non è. `appliesTo` è consumato solo da `dr-scaffold-guidelines`, dal prompt `dr-scaffold` e dal guard di catalogo in CI — mai dall'installer.

**Esito della consultazione** (`/dr-warroom`, sola lettura, nessun file scritto). `DBADMIN` ha dichiarato "nessun intervento database necessario per questo argomento".

| Pacchetto | Esito del tavolo | Motivazione |
|---|---|---|
| `dr-efdb` | **(a) dipendenza dichiarata**, tre voti; ARCH chiede prima una verifica di merito | Stesso stack e tipicamente stesso repository dell'API: i pacchetti trascinati sono pertinenti, i file .NET in radice non contaminano nulla |
| `dr-fe` | **(b) rimando condizionale**, unanime | La decisione citata vive in un altro repository per definizione. Nel caso dichiarato tipico — repository Vue separato dall'API — il file non sta mai su disco: è un rimando morto per costruzione, non un caso limite |
| `dr-devops` | **(b) condizionale, rinforzato**, con divergenza sul grado di dettaglio | `appliesTo: [any]` copre repository di sola infrastruttura senza .NET, dove la dipendenza dura è insensata |

**Perché la dipendenza dura su `dr-fe` fa danni concreti**, secondo UI: due righe di rimando trascinerebbero `Directory.Build.props` e `global.json` nella radice di un repository Vue che non avrà mai una solution, con conseguenze reali — OmniSharp che si attiva, passi di CI che eseguono `dotnet restore` o `format` dalla radice e falliscono su un progetto .NET fantasma.

**Perché il rimando morto è un rischio di sicurezza**, secondo BE: un agente che trova un rimando rotto non si ferma, produce una risposta plausibile — provider iniettato direttamente, schema di autenticazione arbitrario, nessuna persistenza delle chiavi di Data Protection, nessun `UseForwardedHeaders`. Il codice compila e supera una revisione superficiale; il difetto emerge in produzione multi-replica dietro proxy, e in modo intermittente: senza chiavi condivise i token emessi da una replica non sono validati dalle altre.

**Due fatti emersi in consultazione e verificati dal planner, che cambiano il peso della decisione su `dr-efdb`:**

1. `worker-service` ha `optionalPackages: ["dr-efdb"]` nel catalogo, e `dr-winsvc` non contiene nessuna regola sul Service layer. Una dipendenza dura su `dr-efdb` installerebbe l'architettura Minimal API anche in un progetto Worker, dove il partner naturale è `dr-winsvc`.
2. L'altro file di `dr-efdb`, `database-startup-resilience.instructions.md`, dichiara in apertura di applicarsi a una **Minimal API**. Il pacchetto è quindi già internamente ambiguo — il catalogo lo offre ai Worker, il contenuto parla di API — indipendentemente da questa issue.

**Punti di tensione:**

- **`dr-efdb`, dipendenza sì o no.** Tre ruoli la considerano a costo zero perché lo stack coincide; ARCH ribatte che `dependencies` è un meccanismo di installazione file, cieco ad `appliesTo`, e usarlo per esprimere "questa regola ne presuppone concettualmente un'altra" confonde due piani e produce esattamente il difetto osservato.
- **Quanto riassumere in `dr-devops`.** Il file dichiara oggi "fonte unica, non duplicare qui la configurazione": un riassunto che includa i tre metodi C# contraddice letteralmente quella riga e crea due versioni della stessa regola, destinate a divergere. Ma un riassunto troppo astratto non impedisce il guasto intermittente. La tensione è reale e non si risolve da sola: qualunque scelta vada oltre il "cosa" impone di **riscrivere anche quella riga**.
- **Condizionale morbido contro condizionale verificabile.** "Se `dr-minimalapi` è installato, seguilo" è un'istruzione che l'agente può ignorare senza accorgersene. L'alternativa è un'azione ispezionabile — consultare `.ai/dr-guidelines-packages.json` e dichiarare nell'output quale ramo si è applicato — al prezzo di un'istruzione più verbosa, che deve valere anche per GitHub Copilot.

## Decisioni aperte

Risolte in Fase 0 il 2026-09-24. Le decisioni 1, 3, 4 e 5-7 le ha prese l'utente; la 2 discende dalla 1.

1. ~~**`dr-efdb`: dipendenza dichiarata o rimando condizionale?**~~ **RISOLTA dall'utente: rimando condizionale.** Motivazione data: «il pacchetto viene installato solo se viene richiesto l'uso di un database, quindi deve esserci l'intenzione di allacciarsi ad un database». L'intenzione che fa installare `dr-efdb` è quindi *mi serve un database*, che è ortogonale al tipo di host: vale per un Worker quanto per una Minimal API. Una dipendenza dura trascinerebbe l'architettura Minimal API in un progetto Worker, dove il partner naturale è `dr-winsvc` — coerente con il catalogo, che offre `dr-efdb` fra gli `optionalPackages` sia di `minimal-api` sia di `worker-service`. Il catalogo **non si tocca**.
2. ~~**Spostare la regola sul Service layer in `dr-dotnet-backend`.**~~ **NON APPLICABILE in questo piano.** Era l'alternativa (c) proposta da ARCH, subordinata alla decisione 1. Con il rimando condizionale il problema si chiude senza toccare il contenuto di altri due repository né imporre la regola ai Worker, che oggi non ce l'hanno. Resta una questione architetturale aperta, indipendente da questa issue.
3. ~~**Grado di dettaglio del riassunto in `dr-devops`.**~~ **RISOLTA dall'utente: solo il "cosa".** Il riassunto dice che in scale-out serve un portachiavi condiviso fra le repliche e che la fiducia va limitata al proxy noto; non entra nei metodi concreti. Così la riga "fonte unica, non duplicare qui la configurazione" resta vera e non nasce una seconda fonte destinata a divergere.
4. ~~**Forma del condizionale.**~~ **RISOLTA dall'utente: ancorato al manifest.** L'agente controlla `.ai/dr-guidelines-packages.json` e **dichiara nell'output** quale ramo ha applicato. Più verboso di un "se è installato, seguilo", ma verificabile: senza la dichiarazione non si saprebbe se la regola è stata seguita o aggirata in silenzio. Da scrivere una volta sola come convenzione riusabile (Fase 7), non ripetuta a mano in tre file, e con verifica di compatibilità duale prima di scrivere.
5. ~~**Campo di catalogo per i rimandi non vincolanti.**~~ **RISOLTA dall'utente: issue separata.** Fuori dal perimetro di questa.
6. ~~**Comportamento dell'installer sulle dipendenze.**~~ **RISOLTA dall'utente: issue separata.** È il difetto che questa issue rivela ma non copre: risoluzione automatica e ricorsiva, nessun filtro per `appliesTo`, nessuna conferma.
7. ~~**Rilievo su `DataProtectionKeys`.**~~ **RISOLTA dall'utente: issue separata**, su `dr-minimalapi`.

## Scope

Il piano tocca quattro repository distinti, tutti presenti come cartelle sorelle in `e:\Davide\Progetti\dr-guidelines-workspace\`. Commit e push sono separati per repository. Il gate di push per questi repository è "assenza di target di verifica dichiarata" — sono repository di soli documenti — e va dichiarata esplicitamente, come prescrive `copilot-instructions.md`.

### File da modificare
- [x] `dr-guidelines/scaffolding-catalog.json` — **non toccato**: la decisione 1 ha scelto il rimando condizionale
- [x] `dr-efdb/.github/instructions/database-provider.instructions.md`
- [x] `dr-efdb/README.md` — la frase sui rimandi va allineata in entrambi gli esiti
- [x] `dr-fe/.github/instructions/frontend-organization.instructions.md` — rimando condizionale più riassunto minimo, nella regola e nella checklist
- [x] `dr-fe/README.md` — frase sui rimandi
- [x] `dr-devops/.github/instructions/docker-swarm-compose.instructions.md` — rimando condizionale, riassunto al livello deciso, e riscrittura coerente della riga "fonte unica"
- [x] `dr-devops/README.md` — frase sui rimandi
- [x] `dr-guidelines/docs/bozza-manuale-installazione.md` — annotare la convenzione decisa
- [x] `dr-guidelines/README.md` — riga nella tabella delle istruzioni modulari (aggiunta in verifica: `readme-structure.instructions.md` la impone)
- [x] `dr-guidelines/.github/instructions/cross-package-references.instructions.md` — CREATE, la convenzione scritta una volta sola (decisione 4)

### Perimetro negativo
- Non toccherò: `dr-minimalapi` e il contenuto di `minimal-api-architecture.instructions.md`, a meno che la decisione 2 non accolga lo spostamento della regola sul Service layer
- Non toccherò: `dr-guidelines-install-lib.ps1` — il comportamento dell'installer sulle dipendenze è la decisione aperta 6, e va trattato a parte
- Non toccherò: lo schema del catalogo né `schemaVersion` — decisione aperta 5, fuori perimetro salvo indicazione contraria
- Non toccherò: `dr-winsvc`, `dr-dotnet-backend`, salvo decisione 2
- Non toccherò: `.github/ISSUE_TEMPLATE/miglioria.md` dei vari repository, dove `minimal-api-architecture.instructions.md` compare solo come esempio di compilazione
- Non toccherò: il pattern Projection di `dr-efdb`, che DBADMIN chiede esplicitamente di lasciare com'è per non rompere la portabilità multi-provider
- Non farò: nessun `git push` senza aver dichiarato l'assenza di target di verifica

## Fasi (formato atomico — obbligatorio)

### Fase 0: Decisioni bloccanti
- **Stato**: [x]
- **Precondizione**: il piano è stato approvato per l'esecuzione
- **File**: questo `plan.md`
- **Operazione**: EDIT
- **Azione**: sottoporre all'utente le decisioni aperte, a partire dalla 1, dalla 3 e dalla 4, che cambiano il contenuto delle fasi successive. Annotare qui le risposte. Le decisioni 5 e 6 possono essere rimandate a una issue separata, ma la scelta va scritta.
- **Tool ammessi**: nessuno
- **Verifica passo**: ogni decisione aperta ha una risposta scritta in questo file
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 0: <cosa>` in plan.md, non procedere

### Fase 1a: ~~Catalogo~~ — NON ESEGUITA
- **Stato**: [x] non applicabile
- **Motivo**: la decisione 1 ha scelto il rimando condizionale, quindi `scaffolding-catalog.json` resta invariato.
- **Precondizione**: Fase 0 completata, decisione 1 = dipendenza dichiarata
- **File**: `dr-guidelines/scaffolding-catalog.json`
- **Operazione**: EDIT
- **Azione**: valorizzare `dependencies` della voce `dr-efdb` con `dr-minimalapi`, e aggiornare `updatedAt`. Verificare che il guard di catalogo in CI, che controlla la risolvibilità di ogni nome dichiarato, continui a passare.
- **Tool ammessi**: nessuno
- **Verifica passo**: il file è JSON valido; il nome dichiarato esiste tra i `packages`; il guard di CI passa
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1a: <cosa>` in plan.md, non procedere

### Fase 1b *(se la decisione 1 sceglie il rimando condizionale)*: Testo di `dr-efdb`
- **Stato**: [x]
- **Precondizione**: Fase 0 completata, decisione 1 = rimando condizionale
- **File**: `dr-efdb/.github/instructions/database-provider.instructions.md`
- **Operazione**: EDIT
- **Azione**: rendere condizionale il rimando nella sezione "8️⃣ Uso negli Endpoint (tramite Service)", nella forma decisa al punto 4, e aggiungere il riassunto minimo della regola per il caso in cui `dr-minimalapi` non sia installato. Aggiornare il footer di versione dell'istruzione.
- **Tool ammessi**: nessuno
- **Verifica passo**: il rimando non è più incondizionato e il testo resta utilizzabile anche senza `dr-minimalapi`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1b: <cosa>` in plan.md, non procedere

### Fase 2: README di `dr-efdb`
- **Stato**: [x]
- **Precondizione**: Fase 1a o 1b completata
- **File**: `dr-efdb/README.md`
- **Operazione**: EDIT
- **Azione**: allineare la frase che oggi dichiara che `dr-minimalapi` non è una dipendenza dichiarata e che senza quel pacchetto il file citato non è presente nell'host. Con la dipendenza dichiarata quella frase diventa falsa; con il rimando condizionale va aggiornata per descrivere il nuovo comportamento. Aggiornare la riga di versione.
- **Tool ammessi**: nessuno
- **Verifica passo**: il README descrive il comportamento effettivo dopo la Fase 1
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Testo di `dr-fe`
- **Stato**: [x]
- **Precondizione**: Fase 0 completata; decisione 4 presa
- **File**: `dr-fe/.github/instructions/frontend-organization.instructions.md`
- **Operazione**: EDIT
- **Azione**: nella regola "La login non si implementa nel frontend", rendere condizionale il rimando e aggiungere il riassunto minimo orientato al client — non un digest della matrice .NET. Le tre righe proposte in consultazione: stesso dominio, cookie `HttpOnly`; domini diversi o client non-browser, bearer opaco tenuto in memoria; servizio a servizio, chiave API. Allineare la voce corrispondente nella checklist finale. Aggiornare il footer di versione. Nessuna modifica al catalogo in questa fase.
- **Tool ammessi**: nessuno
- **Verifica passo**: regola e checklist dicono la stessa cosa; il testo resta utilizzabile in un repository Vue senza nessun pacchetto .NET installato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: README di `dr-fe`
- **Stato**: [x]
- **Precondizione**: Fase 3 completata
- **File**: `dr-fe/README.md`
- **Operazione**: EDIT
- **Azione**: allineare la frase sui rimandi ad altri pacchetti e aggiornare la riga di versione.
- **Tool ammessi**: nessuno
- **Verifica passo**: il README descrive il comportamento effettivo dopo la Fase 3
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Testo di `dr-devops`
- **Stato**: [x]
- **Precondizione**: Fase 0 completata; decisioni 3 e 4 prese
- **File**: `dr-devops/.github/instructions/docker-swarm-compose.instructions.md`
- **Operazione**: EDIT
- **Azione**: nel blocco Data Protection, rendere condizionale il rimando e aggiungere il riassunto al livello di dettaglio deciso al punto 3, reso indipendente dallo stack — `appliesTo` è `any`. **Riscrivere coerentemente la frase "fonte unica, non duplicare qui la configurazione"**: se il file ora contiene un riassunto, quella riga com'è oggi lo contraddice. Aggiornare il footer di versione.
- **Tool ammessi**: nessuno
- **Verifica passo**: il file non contiene più un'affermazione che contraddice il proprio contenuto; il testo resta utilizzabile in un repository di sola infrastruttura
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: README di `dr-devops`
- **Stato**: [x]
- **Precondizione**: Fase 5 completata
- **File**: `dr-devops/README.md`
- **Operazione**: EDIT
- **Azione**: allineare la frase sui rimandi e aggiornare la riga di versione.
- **Tool ammessi**: nessuno
- **Verifica passo**: il README descrive il comportamento effettivo dopo la Fase 5
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7 *(condizionata alla decisione 4)*: Convenzione scritta una volta sola
- **Stato**: [x]
- **Precondizione**: la decisione 4 ha scelto la forma ancorata al manifest
- **File**: una sede unica in `dr-guidelines/.github/instructions/`
- **Operazione**: CREATE o EDIT
- **Azione**: scrivere la convenzione del rimando condizionale come regola riusabile, invece di ripeterla a mano in tre file. **Verifica di compatibilità duale obbligatoria prima di scrivere**: è un file condiviso, deve funzionare anche con GitHub Copilot. Se la compatibilità non è garantita, fermarsi e chiedere all'utente, come impone la regola fondamentale del progetto.
- **Tool ammessi**: nessuno
- **Verifica passo**: la convenzione è scritta in un solo posto e i tre file la citano invece di riformularla; nessun costrutto esclusivo di un tool
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

### Fase 8: Controllo incrociato dei rimandi residui
- **Stato**: [x]
- **Precondizione**: Fasi 1-7 completate o saltate con nota
- **File**: nessuna modifica — sola verifica sui tre repository
- **Operazione**: nessuna modifica
- **Azione**: cercare ogni occorrenza di `minimal-api-architecture` nei file markdown di `dr-efdb`, `dr-fe` e `dr-devops`, e accertare che ognuna sia coperta da una clausola condizionale o da una dipendenza dichiarata. I modelli di issue vanno esclusi dal controllo: lì il riferimento è solo un esempio di compilazione.
- **Tool ammessi**: ricerca testuale in sola lettura
- **Verifica passo**: nessun rimando incondizionato residuo fuori dai modelli di issue
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 8: <cosa>` in plan.md, non procedere

### Fase 9: Documento vivo aggiornato
- **Stato**: [x]
- **Precondizione**: Fase 8 completata
- **File**: `dr-guidelines/docs/bozza-manuale-installazione.md`
- **Operazione**: EDIT
- **Azione**: annotare la convenzione decisa e il comportamento verificato dell'installer sulle dipendenze — risoluzione automatica e ricorsiva, nessun filtro per `appliesTo` — perché è una scoperta che serve a chi installa.
- **Tool ammessi**: nessuno
- **Verifica passo**: il documento riporta la convenzione e il comportamento dell'installer
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 9: <cosa>` in plan.md, non procedere

### Fase 10: Verifica finale in contesto isolato
- **Stato**: [x]
- **Precondizione**: Fasi 0-9 completate o saltate con nota
- **File**: tutti quelli elencati in "Scope", nei quattro repository
- **Operazione**: nessuna modifica — sola verifica
- **Azione**: eseguire il controllo finale di `plan-tracking.instructions.md`, Fase 4 punto 4, in un contesto isolato dalla conversazione che ha eseguito il piano: nuova sessione, sub-agente o secondo revisore. Su Claude Code corrisponde alla skill `/dr-verify-plan`.
- **Tool ammessi**: quelli del revisore, in sola lettura
- **Verifica passo**: il revisore conferma ogni criterio della sezione seguente
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 10: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] Nessuno dei tre pacchetti contiene più un rimando a `minimal-api-architecture.instructions.md` che si rompe in silenzio: ogni rimando è condizionale o coperto da una dipendenza dichiarata
- [x] Nessuna dipendenza dichiarata trascina pacchetti .NET in un host che .NET non è — in particolare `dr-fe` (`node`) e `dr-devops` (`any`) restano senza dipendenze .NET
- [x] `dr-devops` non contiene più una riga che contraddice il proprio contenuto sul punto "fonte unica"
- [x] I tre README descrivono il comportamento effettivo dopo le modifiche
- [x] Se è stata dichiarata una dipendenza nel catalogo: il file è JSON valido e il guard di catalogo in CI passa
- [x] Nessun costrutto esclusivo di un tool nei file condivisi: compatibilità duale rispettata
- [x] Nessun `git push` è avvenuto senza la dichiarazione esplicita di assenza di target di verifica
- [x] Nessun file fuori da "Scope" è stato modificato in nessuno dei quattro repository

## Consuntivo

**Verifica finale**: eseguita il 2026-09-24 con `/dr-verify-plan`, sub-agente in sola lettura, senza accesso alla conversazione di implementazione. Esito: **9 voci di Scope su 9 CORRISPONDONO, tutti e sei i criteri SODDISFATTI**, perimetro negativo intatto in tutti e sette i repository del workspace — catalogo invariato, `dr-minimalapi` non toccato, `dr-guidelines-install-lib.ps1` non toccato.

Il controllo di merito ha smontato i tre rimandi nei quattro elementi che la convenzione impone — condizione sul manifest, ramo pieno con la fonte citata, ripiego che dice il "cosa", dichiarazione del ramo applicato — e li ha trovati tutti e quattro presenti in tutti e tre. `dr-devops` è il caso migliore: due requisiti senza stack e nessuna traccia dei metodi .NET. Le simulazioni su un host con `dr-fe` senza `dr-minimalapi` (aggiunta di una login) e con `dr-devops` (alzare le repliche) mostrano che l'agente applica il ripiego, lo dichiara, e nel secondo caso intercetta il guasto intermittente che la issue voleva prevenire.

**Quattro correzioni applicate dopo la verifica:**

1. **Il primo esempio d'uso della convenzione violava la convenzione.** I tre blocchi riscritti chiudevano con "Vedi `cross-package-references.instructions.md`" — un rimando **incondizionato** a un file di un altro pacchetto, cioè esattamente ciò che la regola di perimetro numero 1 vieta. Il core non è dipendenza dichiarata di nessun pacchetto e l'installer non lo impone, quindi in un host con il solo `dr-fe` quel file non c'è. Reso condizionale in tutti e tre.
2. **Il README del core non elencava la nuova istruzione.** `readme-structure.instructions.md` lo impone due volte, e `docs/onboarding.md` lo elenca come secondo dei tre passi per aggiungere un'istruzione trasversale. Era un buco dello Scope, non una violazione del perimetro: lo Scope semplicemente non prevedeva `README.md`. Riga aggiunta, footer incrementato.
3. **Il ripiego di `dr-fe` ricalcava la classificazione della fonte.** Riproduceva tre righe della matrice a cinque di `dr-minimalapi`, omettendo fra l'altro il caso "entrambi i tipi di client", che è il più frequente. Senza i pacchetti e i metodi .NET, quindi formalmente conforme alla Fase 3, ma la classificazione **è** il cuore della decisione: se a monte la matrice cambia, quel ripiego non se ne accorge e nessun controllo se ne accorgerebbe. Riformulato come due requisiti lato client — il token non passa dal frontend quando può non passarci, e se ci passa sta in memoria — più l'istruzione di **chiedere all'API** quale schema ha adottato invece di sceglierlo. Rimossa anche la contraddizione con la riga soprastante, che diceva "lo schema non si decide qui" per poi assegnarne uno per scenario.
4. **Il caso "manifest assente" non era coperto.** La convenzione diceva "se elenca / se non elenca", lasciando scoperto l'host che il manifest non ce l'ha. Aggiunta la riga: manifest assente o illeggibile equivale a pacchetto non installato.

**Rilievo non applicato:** in `dr-efdb` il titolo della sezione ("Uso negli Endpoint") e la riga che la apre restano formulati per una API, con la cartella `Services/<Entity>Service.cs`, mentre il blocco che segue avverte di non dare per scontato di essere in una API. È una frizione di tono, non un rimando rotto, e riscrivere la sezione intera andava oltre il perimetro di questa issue. `dr-efdb` è già internamente ambiguo su questo punto — l'altro suo file, `database-startup-resilience.instructions.md`, dichiara in apertura di applicarsi a una Minimal API — e la questione va affrontata per intero o non affrontata.
