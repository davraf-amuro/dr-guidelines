# Piano: Dipendenze implicite da `dr-minimalapi` non dichiarate nel catalogo
Data: 2026-09-22
Stato: PROPOSTO
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

1. **`dr-efdb`: dipendenza dichiarata o rimando condizionale?** È l'unica vera divergenza del tavolo, e dipende da una domanda a monte: `dr-efdb` deve restare installabile con `dr-winsvc` senza `dr-minimalapi`, com'è oggi nel catalogo, oppure si accetta che sia di fatto un pacchetto per Minimal API? Se resta valido per i Worker, rimando condizionale; se è per API, dipendenza.
2. **Accogliere la proposta di ARCH** di spostare la regola sul Service layer da `dr-minimalapi` a `dr-dotnet-backend`? Risolverebbe il rimando alla radice — `dr-efdb` dipenderebbe da un pacchetto .NET di base — ma tocca il contenuto di due repository in più e imporrebbe la regola anche ai Worker, che oggi non ce l'hanno. Decisione di merito architetturale, che il tavolo non può prendere.
3. **Grado di dettaglio del riassunto in `dr-devops`**: solo il "cosa" (serve un portachiavi condiviso, la fiducia va limitata al proxy noto) o anche il "come"? Qualunque scelta oltre il "cosa" richiede di riscrivere la riga "fonte unica, non duplicare qui", altrimenti il file si contraddice.
4. **Forma del condizionale**: testo puro, oppure ancorato al manifest `.ai/dr-guidelines-packages.json` con obbligo di dichiarare il ramo applicato. La seconda è più robusta ma va verificata per compatibilità duale — è un'istruzione in `.github/instructions/`, quindi deve funzionare anche con GitHub Copilot, che non ha garanzia di leggere quel file.
5. **Schema del catalogo**: introdurre un campo per i rimandi non vincolanti (`suggests`, `optionalDependencies` o simile)? Risolverebbe la classe di problema per tutti i casi futuri, ma comporta una nuova `schemaVersion`, l'aggiornamento del guard di catalogo in CI e della skill `dr-scaffold-guidelines`. Fuori dal perimetro di questa issue se la si vuole tenere piccola.
6. **Il comportamento dell'installer va cambiato?** Oggi risolve le dipendenze in automatico, ricorsivamente, senza filtro per `appliesTo` e senza conferma. È un problema autonomo che questa issue rivela ma non copre: probabilmente merita una issue separata.
7. **Il rilievo su `DataProtectionKeys`** sollevato da DBADMIN — in scale-out la tabella deve esistere prima dell'avvio di repliche concorrenti, per evitare una corsa sulla creazione — è un miglioramento di contenuto per `dr-minimalapi`, estraneo a questa issue. Tenerlo o scartarlo esplicitamente.

## Scope

Il piano tocca quattro repository distinti, tutti presenti come cartelle sorelle in `e:\Davide\Progetti\dr-guidelines-workspace\`. Commit e push sono separati per repository. Il gate di push per questi repository è "assenza di target di verifica dichiarata" — sono repository di soli documenti — e va dichiarata esplicitamente, come prescrive `copilot-instructions.md`.

### File da modificare
- [ ] `dr-guidelines/scaffolding-catalog.json` — solo se la decisione 1 sceglie la dipendenza dichiarata
- [ ] `dr-efdb/.github/instructions/database-provider.instructions.md` — solo se la decisione 1 sceglie il rimando condizionale
- [ ] `dr-efdb/README.md` — la frase sui rimandi va allineata in entrambi gli esiti
- [ ] `dr-fe/.github/instructions/frontend-organization.instructions.md` — rimando condizionale più riassunto minimo, nella regola e nella checklist
- [ ] `dr-fe/README.md` — frase sui rimandi
- [ ] `dr-devops/.github/instructions/docker-swarm-compose.instructions.md` — rimando condizionale, riassunto al livello deciso, e riscrittura coerente della riga "fonte unica"
- [ ] `dr-devops/README.md` — frase sui rimandi
- [ ] `dr-guidelines/docs/bozza-manuale-installazione.md` — annotare la convenzione decisa
- [ ] *(condizionato alla decisione 4)* una sede unica per la convenzione del condizionale, in `dr-guidelines/.github/instructions/`

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
- **Stato**: [ ]
- **Precondizione**: il piano è stato approvato per l'esecuzione
- **File**: questo `plan.md`
- **Operazione**: EDIT
- **Azione**: sottoporre all'utente le decisioni aperte, a partire dalla 1, dalla 3 e dalla 4, che cambiano il contenuto delle fasi successive. Annotare qui le risposte. Le decisioni 5 e 6 possono essere rimandate a una issue separata, ma la scelta va scritta.
- **Tool ammessi**: nessuno
- **Verifica passo**: ogni decisione aperta ha una risposta scritta in questo file
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 0: <cosa>` in plan.md, non procedere

### Fase 1a *(se la decisione 1 sceglie la dipendenza dichiarata)*: Catalogo
- **Stato**: [ ]
- **Precondizione**: Fase 0 completata, decisione 1 = dipendenza dichiarata
- **File**: `dr-guidelines/scaffolding-catalog.json`
- **Operazione**: EDIT
- **Azione**: valorizzare `dependencies` della voce `dr-efdb` con `dr-minimalapi`, e aggiornare `updatedAt`. Verificare che il guard di catalogo in CI, che controlla la risolvibilità di ogni nome dichiarato, continui a passare.
- **Tool ammessi**: nessuno
- **Verifica passo**: il file è JSON valido; il nome dichiarato esiste tra i `packages`; il guard di CI passa
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1a: <cosa>` in plan.md, non procedere

### Fase 1b *(se la decisione 1 sceglie il rimando condizionale)*: Testo di `dr-efdb`
- **Stato**: [ ]
- **Precondizione**: Fase 0 completata, decisione 1 = rimando condizionale
- **File**: `dr-efdb/.github/instructions/database-provider.instructions.md`
- **Operazione**: EDIT
- **Azione**: rendere condizionale il rimando nella sezione "8️⃣ Uso negli Endpoint (tramite Service)", nella forma decisa al punto 4, e aggiungere il riassunto minimo della regola per il caso in cui `dr-minimalapi` non sia installato. Aggiornare il footer di versione dell'istruzione.
- **Tool ammessi**: nessuno
- **Verifica passo**: il rimando non è più incondizionato e il testo resta utilizzabile anche senza `dr-minimalapi`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1b: <cosa>` in plan.md, non procedere

### Fase 2: README di `dr-efdb`
- **Stato**: [ ]
- **Precondizione**: Fase 1a o 1b completata
- **File**: `dr-efdb/README.md`
- **Operazione**: EDIT
- **Azione**: allineare la frase che oggi dichiara che `dr-minimalapi` non è una dipendenza dichiarata e che senza quel pacchetto il file citato non è presente nell'host. Con la dipendenza dichiarata quella frase diventa falsa; con il rimando condizionale va aggiornata per descrivere il nuovo comportamento. Aggiornare la riga di versione.
- **Tool ammessi**: nessuno
- **Verifica passo**: il README descrive il comportamento effettivo dopo la Fase 1
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Testo di `dr-fe`
- **Stato**: [ ]
- **Precondizione**: Fase 0 completata; decisione 4 presa
- **File**: `dr-fe/.github/instructions/frontend-organization.instructions.md`
- **Operazione**: EDIT
- **Azione**: nella regola "La login non si implementa nel frontend", rendere condizionale il rimando e aggiungere il riassunto minimo orientato al client — non un digest della matrice .NET. Le tre righe proposte in consultazione: stesso dominio, cookie `HttpOnly`; domini diversi o client non-browser, bearer opaco tenuto in memoria; servizio a servizio, chiave API. Allineare la voce corrispondente nella checklist finale. Aggiornare il footer di versione. Nessuna modifica al catalogo in questa fase.
- **Tool ammessi**: nessuno
- **Verifica passo**: regola e checklist dicono la stessa cosa; il testo resta utilizzabile in un repository Vue senza nessun pacchetto .NET installato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: README di `dr-fe`
- **Stato**: [ ]
- **Precondizione**: Fase 3 completata
- **File**: `dr-fe/README.md`
- **Operazione**: EDIT
- **Azione**: allineare la frase sui rimandi ad altri pacchetti e aggiornare la riga di versione.
- **Tool ammessi**: nessuno
- **Verifica passo**: il README descrive il comportamento effettivo dopo la Fase 3
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Testo di `dr-devops`
- **Stato**: [ ]
- **Precondizione**: Fase 0 completata; decisioni 3 e 4 prese
- **File**: `dr-devops/.github/instructions/docker-swarm-compose.instructions.md`
- **Operazione**: EDIT
- **Azione**: nel blocco Data Protection, rendere condizionale il rimando e aggiungere il riassunto al livello di dettaglio deciso al punto 3, reso indipendente dallo stack — `appliesTo` è `any`. **Riscrivere coerentemente la frase "fonte unica, non duplicare qui la configurazione"**: se il file ora contiene un riassunto, quella riga com'è oggi lo contraddice. Aggiornare il footer di versione.
- **Tool ammessi**: nessuno
- **Verifica passo**: il file non contiene più un'affermazione che contraddice il proprio contenuto; il testo resta utilizzabile in un repository di sola infrastruttura
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: README di `dr-devops`
- **Stato**: [ ]
- **Precondizione**: Fase 5 completata
- **File**: `dr-devops/README.md`
- **Operazione**: EDIT
- **Azione**: allineare la frase sui rimandi e aggiornare la riga di versione.
- **Tool ammessi**: nessuno
- **Verifica passo**: il README descrive il comportamento effettivo dopo la Fase 5
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7 *(condizionata alla decisione 4)*: Convenzione scritta una volta sola
- **Stato**: [ ]
- **Precondizione**: la decisione 4 ha scelto la forma ancorata al manifest
- **File**: una sede unica in `dr-guidelines/.github/instructions/`
- **Operazione**: CREATE o EDIT
- **Azione**: scrivere la convenzione del rimando condizionale come regola riusabile, invece di ripeterla a mano in tre file. **Verifica di compatibilità duale obbligatoria prima di scrivere**: è un file condiviso, deve funzionare anche con GitHub Copilot. Se la compatibilità non è garantita, fermarsi e chiedere all'utente, come impone la regola fondamentale del progetto.
- **Tool ammessi**: nessuno
- **Verifica passo**: la convenzione è scritta in un solo posto e i tre file la citano invece di riformularla; nessun costrutto esclusivo di un tool
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

### Fase 8: Controllo incrociato dei rimandi residui
- **Stato**: [ ]
- **Precondizione**: Fasi 1-7 completate o saltate con nota
- **File**: nessuna modifica — sola verifica sui tre repository
- **Operazione**: nessuna modifica
- **Azione**: cercare ogni occorrenza di `minimal-api-architecture` nei file markdown di `dr-efdb`, `dr-fe` e `dr-devops`, e accertare che ognuna sia coperta da una clausola condizionale o da una dipendenza dichiarata. I modelli di issue vanno esclusi dal controllo: lì il riferimento è solo un esempio di compilazione.
- **Tool ammessi**: ricerca testuale in sola lettura
- **Verifica passo**: nessun rimando incondizionato residuo fuori dai modelli di issue
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 8: <cosa>` in plan.md, non procedere

### Fase 9: Documento vivo aggiornato
- **Stato**: [ ]
- **Precondizione**: Fase 8 completata
- **File**: `dr-guidelines/docs/bozza-manuale-installazione.md`
- **Operazione**: EDIT
- **Azione**: annotare la convenzione decisa e il comportamento verificato dell'installer sulle dipendenze — risoluzione automatica e ricorsiva, nessun filtro per `appliesTo` — perché è una scoperta che serve a chi installa.
- **Tool ammessi**: nessuno
- **Verifica passo**: il documento riporta la convenzione e il comportamento dell'installer
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 9: <cosa>` in plan.md, non procedere

### Fase 10: Verifica finale in contesto isolato
- **Stato**: [ ]
- **Precondizione**: Fasi 0-9 completate o saltate con nota
- **File**: tutti quelli elencati in "Scope", nei quattro repository
- **Operazione**: nessuna modifica — sola verifica
- **Azione**: eseguire il controllo finale di `plan-tracking.instructions.md`, Fase 4 punto 4, in un contesto isolato dalla conversazione che ha eseguito il piano: nuova sessione, sub-agente o secondo revisore. Su Claude Code corrisponde alla skill `/dr-verify-plan`.
- **Tool ammessi**: quelli del revisore, in sola lettura
- **Verifica passo**: il revisore conferma ogni criterio della sezione seguente
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 10: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [ ] Nessuno dei tre pacchetti contiene più un rimando a `minimal-api-architecture.instructions.md` che si rompe in silenzio: ogni rimando è condizionale o coperto da una dipendenza dichiarata
- [ ] Nessuna dipendenza dichiarata trascina pacchetti .NET in un host che .NET non è — in particolare `dr-fe` (`node`) e `dr-devops` (`any`) restano senza dipendenze .NET
- [ ] `dr-devops` non contiene più una riga che contraddice il proprio contenuto sul punto "fonte unica"
- [ ] I tre README descrivono il comportamento effettivo dopo le modifiche
- [ ] Se è stata dichiarata una dipendenza nel catalogo: il file è JSON valido e il guard di catalogo in CI passa
- [ ] Nessun costrutto esclusivo di un tool nei file condivisi: compatibilità duale rispettata
- [ ] Nessun `git push` è avvenuto senza la dichiarazione esplicita di assenza di target di verifica
- [ ] Nessun file fuori da "Scope" è stato modificato in nessuno dei quattro repository
