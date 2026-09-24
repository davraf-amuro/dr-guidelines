# Decisioni della sessione 2026-09-22 → 2026-09-24

Solo decisioni realmente prese. Ogni voce indica chi l'ha presa: **utente** oppure **agente su delega**, dove la delega è la frase «parti dal primo e procedi con tutti».

---

## La cartella delle richieste utente si chiama `briefs/` e sta in radice

**Contesto.** La issue #1 chiedeva una cartella dove scrivere le specifiche di progetto. L'utente ha precisato che il contenuto sono le richieste che scrive lui, da trasformare in piani. Tre posizioni candidate: radice, sotto `docs/`, sotto `.ai/`.

**Decisione.** `briefs/` in radice. Presa dall'utente fra quattro nomi proposti.

**Motivazione.** `specs/` collide con le spec di test negli host JS/TS; `requests/` è il nome standard dei DTO di richiesta in .NET. Sotto `docs/` la cartella erediterebbe `doc-versioning.instructions.md`, che ha `applyTo: "docs/**/*.md"` e imporrebbe il footer di revisione a file scritti a mano dall'utente. Sotto `.ai/` sarebbe meno visibile, e `.ai/` è per convenzione area rigenerabile dell'agente.

**Conseguenze.** Il piano della issue #1 è stato riscritto: nomi derivati (`brief-authoring.instructions.md`, `templates/brief-template.md`, campo `Brief:` nel piano), terminologia allineata, Fase 4 (esclusione da `doc-versioning`) annullata perché non più necessaria. La terminologia cambia anche il modello del documento: un brief esprime un bisogno, non descrive un sistema.

---

## La cartella del singolo progetto deve non esistere, nemmeno vuota

**Contesto.** La regola di STOP dello scaffolding aveva tre soglie diverse in quattro file. La consultazione proponeva "assente o vuota".

**Decisione.** Soglia stretta: se la cartella del progetto esiste, anche vuota, si ferma. Presa dall'utente, contro la proposta della consultazione.

**Motivazione.** Una cartella vuota è spesso il residuo di un tentativo precedente.

**Conseguenze.** È `dr-scaffold-solution` ad allinearsi a `dr-scaffold-project`, non il contrario. I testi di sostituzione preparati dalla consultazione sono stati riscritti. Aggiunta ovunque la precisazione che la regola riguarda la cartella del singolo progetto e non i contenitori `src/` e `test/`.

---

## Contenuto inatteso nella root: si elenca e si chiede

**Contesto.** Con la root ora tollerante verso i file del core, restava da decidere cosa fare del contenuto che non rientra nell'allow-list.

**Decisione.** STOP morbido: l'agente elenca cosa ha trovato e chiede come procedere. Presa dall'utente.

**Motivazione.** Niente passa in silenzio, ma non si blocca a muro.

**Conseguenze.** Le due superfici devono dire la stessa cosa. In verifica è emerso che il prompt Copilot non aveva la riga-rete presente nel router Claude Code, quindi uno stato non previsto non corrispondeva a nessuna riga: aggiunta.

---

## L'allow-list della root è un elenco esplicito più una formula aperta

**Contesto.** Serviva decidere quanto enumerare fra i file attesi nella root.

**Decisione.** Elenco esplicito (`.git/`, `.github/`, `.claude/`, `.ai/`, `CLAUDE.md`, `README.md`, `LICENSE`, `.gitignore`, `.gitattributes`, `.editorconfig`, `.vscode/`, un `*.code-workspace`) più "file di configurazione radice portati dai pacchetti `dr-*`". Presa dall'agente su delega.

**Motivazione.** `Directory.Build.props`, `global.json` e `.mcp.json` sono già coperti dalla formula, essendo installati dai pacchetti. `.vscode/` e `*.code-workspace` no, ma sono normalissimi in un repository.

**Conseguenze.** Un pacchetto nuovo che porti file di radice non richiede di aggiornare l'elenco.

---

## Le label dei modelli di issue si mappano su `bug` ed `enhancement`

**Contesto.** I modelli dichiaravano `labels: problema` e `labels: miglioria`, label che non esistevano in nessuno dei 7 repo. Tre opzioni: crearle, toglierle, mapparle su quelle di default.

**Decisione.** Mappatura: `problema.md` → `bug`, `miglioria.md` → `enhancement`. Presa dall'utente. La scelta fra `bug` e `documentation` per `problema.md` è stata presa dall'agente su delega.

**Motivazione.** Le label di default esistono in ogni repository presente e in ogni repository futuro, perché le crea GitHub: `--label` funziona da subito e non c'è niente da tenere sincronizzato a mano. Creare label italiane avrebbe spostato il difetto invece di chiuderlo, perché nessuno script le predispone.

**Conseguenze.** Nomi in inglese in una suite italiana. `bug` è semanticamente stretto per il caso "regola ambigua", ma il modello copre anche i malfunzionamenti veri.

---

## La struttura dei modelli di issue si scrive inline nelle superfici agente

**Contesto.** Il prompt Copilot rimandava ai modelli in `.github/ISSUE_TEMPLATE/` del repository di destinazione. Verificato che l'installer non li distribuisce negli host.

**Decisione.** Struttura scritta per esteso dentro la skill e dentro il prompt. Presa dall'agente, su indicazione della consultazione.

**Motivazione.** Un'istruzione che rimanda a una risorsa non garantita è un'istruzione che il modello aggira in silenzio.

**Conseguenze.** La struttura è duplicata in tre posti: i due file agente e i modelli stessi. È un costo accettato consapevolmente; i modelli restano la fonte per chi apre la issue dal web. Verificato in sessione che i 18 titoli di sezione coincidono fra le tre copie.

---

## Terzo modello `nuovo-pacchetto.md`, solo in `dr-guidelines`

**Contesto.** La variante "nessun pacchetto copre il dominio" non corrispondeva a nessuno dei due modelli: "Pacchetto e file interessati" non ha senso per un pacchetto che non esiste.

**Decisione.** Terzo modello, presente solo in `dr-guidelines`. Presa dall'utente.

**Motivazione.** Il gap di catalogo ha destinazione fissa `dr-guidelines`, come dichiara `fallback.issueRepo` nel catalogo. Negli altri sei repo il modello non servirebbe.

**Conseguenze.** `dr-guidelines` ha tre modelli, gli altri due. Divergenza accettata: è il repository del catalogo, già speciale.

---

## `dr-efdb` cita `dr-minimalapi` con un rimando condizionale, non con una dipendenza

**Contesto.** Unico punto su cui il tavolo `/dr-warroom` non ha trovato accordo. Tre voti per la dipendenza dichiarata, uno contrario.

**Decisione.** Rimando condizionale. Il catalogo non si tocca. Presa dall'utente.

**Motivazione, nelle parole dell'utente.** «Il pacchetto viene installato solo se viene richiesto l'uso di un database, quindi deve esserci l'intenzione di allacciarsi ad un database.» L'intenzione che fa installare `dr-efdb` è ortogonale al tipo di host: vale per un Worker quanto per una Minimal API. Il catalogo infatti lo offre fra gli `optionalPackages` di entrambe le tipologie.

**Conseguenze.** `dr-efdb` resta installabile in un progetto Worker senza trascinare l'architettura Minimal API. Resta aperta la questione che `dr-efdb` è internamente ambiguo: il suo altro file di istruzione dichiara di applicarsi a una Minimal API.

---

## Il ripiego di un rimando dice il "cosa", mai il "come"

**Contesto.** `dr-devops` dichiarava "fonte unica, non duplicare qui la configurazione" e rimandava a `dr-minimalapi` per il codice di Data Protection.

**Decisione.** Il ripiego si ferma ai requisiti: portachiavi condiviso fra le repliche, fiducia limitata al proxy noto. Nessun metodo, nessun nome di API. Presa dall'utente.

**Motivazione.** Un riassunto che entri nel dettaglio diventa una seconda fonte, e due fonti sulla stessa regola divergono al primo aggiornamento di una delle due. La riga "fonte unica" sarebbe diventata falsa.

**Conseguenze.** La riga "fonte unica, non duplicare qui la configurazione" è stata comunque riscritta, perché il file ora contiene un ripiego. In verifica è emerso che il ripiego di `dr-fe` ricalcava invece la classificazione della fonte: riformulato come requisito, con l'istruzione di chiedere all'API quale schema ha adottato.

---

## I rimandi fra pacchetti si ancorano al manifest e dichiarano il ramo applicato

**Contesto.** Serviva una forma per il rimando condizionale, utilizzabile anche da GitHub Copilot.

**Decisione.** L'agente controlla `.ai/dr-guidelines-packages.json` e dichiara nell'output quale dei due rami ha applicato. Scritta una volta sola come convenzione riusabile. Presa dall'utente.

**Motivazione.** «Se il pacchetto è installato, seguilo» è un'istruzione che l'agente può ignorare senza che nessuno se ne accorga: il risultato è identico nei due casi e non c'è modo di sapere quale fonte abbia usato.

**Conseguenze.** Nata `cross-package-references.instructions.md`, `applyTo: "**"`. In verifica è emerso che i tre rimandi appena scritti citavano quella convenzione con un rimando incondizionato, violando la regola di perimetro numero 1 della convenzione stessa: reso condizionale. Aggiunta anche la clausola sul manifest assente, che equivale a pacchetto non installato.

---

## Tre rilievi fuori perimetro diventano issue separate

**Contesto.** Il tavolo sulla issue #5 ha sollevato tre punti che la issue non copriva.

**Decisione.** Tre issue nuove invece di annotazioni nel consuntivo. Presa dall'utente.

**Motivazione.** Restare nel consuntivo di un piano le avrebbe rese visibili solo a chi rilegge quel piano.

**Conseguenze.** Aperte `dr-guidelines#6` (installer), `dr-guidelines#7` (campo di catalogo), `dr-minimalapi#2` (Data Protection in scale-out). Composte sui modelli appena corretti: primo collaudo reale del canale.

---

## L'ampiezza dell'intervento sulla issue #3 va oltre i punti che la issue cita

**Contesto.** La issue #3 citava 5 punti; lo stesso vocabolario difettoso stava in altre 3 superfici che non nominava.

**Decisione.** Allineare tutto: 10 punti su 4 file. Presa dall'utente.

**Motivazione.** Senza allineare le altre tre, il flusso consigliato avrebbe continuato a funzionare solo grazie alla riga-rete del router, cioè per ripiego e non per intenzione.

**Conseguenze.** La Fase 6 del piano, che era condizionata a questa risposta, è stata eseguita.
