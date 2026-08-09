## Naming pacchetti e mappatura dominio→contenuto

Contesto: `davraf-guidelines` conteneva 11 skill, 19 instructions, 7 prompts misti tra contenuto trasversale e specifico per dominio tecnico.

Decisione: split in `dr-guidelines` (core, trasversale) + `dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`, `dr-dotnet-backend` (dominio), con prefisso `dr-` e senza "guidelines" ripetuto nei nomi pacchetto.

Motivazione: permettere a un progetto host di installare solo i pacchetti pertinenti al proprio stack, invece di importare tutto il contenuto.

Conseguenze: 7 repo GitHub indipendenti da mantenere; necessità di un installer per pacchetto invece di un unico `setup.ps1`.

---

## Skill `audit-api` isolata in `dr-dotnet-backend`

Contesto: `audit-api` copre sia Minimal API sia Windows Service tramite rilevamento del tipo progetto a runtime, non è legata a un solo dominio.

Decisione: pacchetto dedicato `dr-dotnet-backend`, non inclusa nel core né duplicata in `dr-minimalapi`/`dr-winsvc`.

Motivazione: evitare di forzare una dipendenza generica sul core per un contenuto non universale, ed evitare la duplicazione di manutenzione tra i due pacchetti dominio che la userebbero entrambi.

Conseguenze: `dr-minimalapi` e `dr-winsvc` devono dichiarare dipendenza su `dr-dotnet-backend` (vedi decisione successiva).

---

## Dipendenza tra pacchetti

Contesto: conseguenza diretta della decisione precedente.

Decisione: `dr-minimalapi` e `dr-winsvc` dichiarano dipendenza da `dr-dotnet-backend`; l'installer del pacchetto dipendente installa automaticamente la dipendenza se assente nel manifest host.

Motivazione: garantire che chi installa `dr-minimalapi` o `dr-winsvc` ottenga automaticamente anche `audit-api` senza doverlo sapere a priori.

Conseguenze: l'installer (fase 4, non ancora scritto) deve implementare logica di risoluzione dipendenze basata sul manifest `.ai/dr-guidelines-packages.json`.

---

## Repo legacy `davraf-guidelines`: archive, non cancellazione

Contesto: dopo lo split, il repo originale non serve più come sorgente attiva.

Decisione: aggiornare il README con redirect ai nuovi repo, poi archiviare su GitHub (non cancellare).

Motivazione: reversibilità — un repo archiviato si può de-archiviare, nessun dato viene perso.

Conseguenze: il repo resta leggibile/clonabile ma read-only una volta archiviato; l'archiviazione avviene solo in fase 7, dopo che i pacchetti nuovi sono validati.

---

## Creazione repo GitHub affidata a Claude via `gh` CLI

Contesto: proposta iniziale era creazione manuale da parte dell'utente; l'utente ha poi chiesto se Claude fosse in grado di farlo.

Decisione: Claude crea i 7 repo con `gh repo create`, uno alla volta con conferma esplicita dell'utente prima di ciascuno (poi confermato "tutti e 7" in un'unica conferma dopo il primo).

Motivazione: `gh` CLI risultava già installato e autenticato come `davraf-amuro` con scope `repo` sufficiente.

Conseguenze: nessuna — i repo sono stati creati con successo, nessun problema di permessi riscontrato.

---

## Visibilità repo: Private (non Public come raccomandato)

Contesto: il meccanismo di installazione approvato in fase 1 (`irm https://raw.githubusercontent.com/.../install.ps1 | iex`) richiede repo pubblici per funzionare senza autenticazione.

Decisione: repo creati Private nonostante il trade-off segnalato esplicitamente.

Motivazione: scelta esplicita dell'utente.

Conseguenze: necessario un gate esplicito prima di poter usare il meccanismo di installazione come progettato (vedi decisione successiva). Durante la fase Private, eventuali test dell'installer richiedono `git clone` autenticato, non l'`irm` pubblico.

---

## Gate Private → Public

Contesto: conseguenza diretta della decisione precedente.

Decisione: i 7 repo restano Private finché non è stato eseguito un test diretto di `install.ps1` su almeno un progetto host reale esistente (non una cartella di test sintetica). Solo dopo esito positivo si passa a Public.

Motivazione: condizione posta esplicitamente dall'utente, più stringente della proposta iniziale di Claude (che prevedeva anche un test sintetico come sufficiente).

Conseguenze: il meccanismo di installazione pubblico non è verificabile end-to-end finché il gate non è soddisfatto; questo è tracciato come fase 2b aperta nel piano.

---

## Licenza MIT per tutti i pacchetti

Contesto: il repo originale non aveva alcuna licenza.

Decisione: licenza MIT su tutti e 7 i repo, applicata alla creazione (`gh repo create --license mit`).

Motivazione: scelta dell'utente tra le opzioni proposte (MIT permissiva vs nessuna licenza).

Conseguenze: nessuna already-esistente — LICENSE presente come primo commit in ogni repo, poi unito alla history estratta via merge.

---

## Nessun README/gitignore auto-generato alla creazione repo

Contesto: `gh repo create` supporta la generazione automatica di README/gitignore iniziali.

Decisione: nessuno dei due generato automaticamente.

Motivazione: il contenuto reale sarebbe arrivato in fase 3 via `git filter-repo`; un commit iniziale con README/gitignore avrebbe creato history divergente da gestire.

Conseguenze: ogni repo, alla creazione, conteneva solo il file LICENSE come primo commit.

---

## Migrazione contenuto con `git filter-repo`, non copy-paste

Contesto: serviva portare il contenuto specifico di ogni dominio nei nuovi repo.

Decisione: uso di `git filter-repo` per estrarre i path pertinenti mantenendo la history originale (commit, autore, data) invece di una copia secca dei file correnti.

Motivazione: preservare blame/history per i file migrati.

Conseguenze: richiesta installazione di `git-filter-repo` (non presente di default) via `pip install --user git-filter-repo`; necessario clone `--no-local` per ogni estrazione (limite tecnico di `filter-repo` sui clone locali ottimizzati con hardlink).

---

## Merge `--allow-unrelated-histories` invece di force-push

Contesto: ogni repo target aveva già un commit LICENSE (history non correlata a quella estratta da `filter-repo`).

Decisione: `git fetch` + `git merge origin/main --allow-unrelated-histories` per unire le due history, poi push normale (fast-forward per il remoto), invece di `git push --force`.

Motivazione: evitare un'operazione distruttiva (force-push) anche se i repo erano appena creati e a basso rischio.

Conseguenze: ogni repo pacchetto contiene sia il commit LICENSE sia la history estratta, unite da un commit di merge; nessuna history sovrascritta.

---

# Decisioni sessione 2026-08-08 — sistema di scaffolding

## Scaffolding diviso in orchestratore + tre pezzi

Contesto: `TODO/01-install-scaffholding.md` poneva la domanda aperta "scaffolding unico o diviso in parti". Al tavolo `/dr-warroom` tutti e cinque i ruoli hanno escluso il monolite; ARCH, BE e UI proponevano tre pezzi indipendenti, UX un solo punto d'ingresso che smista.

Decisione: `/dr-scaffold` (router che rileva lo stato della cartella e delega) + `dr-scaffold-solution` + `dr-scaffold-project` + `dr-scaffold-guidelines`, con i tre sotto-pezzi invocabili anche direttamente.

Motivazione: i tre flussi hanno cicli di vita diversi (una volta, N volte, su repo esistente); un monolite farebbe attraversare rami morti a chi ha già una solution e renderebbe il rollback tutto-o-nulla. Il router evita che l'utente debba sapere quale pezzo serve.

Conseguenze: 4 file `SKILL.md` invece di 1; il router non scrive nulla e non può recuperare un prerequisito mancante, quindi il gate prerequisiti sta lì e blocca prima della delega.

---

## Skill Claude Code più prompt duale per Copilot

Contesto: la regola fondamentale del progetto impone compatibilità con Claude Code e GitHub Copilot, con esenzione esplicita per `.claude/skills/`. ARCH sosteneva che lo scaffolding *genera* struttura e non è una regola condivisa, quindi le sole skill basterebbero; UI e BE osservavano che il catalogo è comunque un file dati, quindi il costo del prompt duale è solo di rendering.

Decisione: entrambe le superfici. Skill in `.claude/skills/dr-scaffold*/` con widget di scelta; `.github/prompts/dr-scaffold.prompt.md` con liste numerate e default espliciti.

Motivazione: scelta dell'utente tra le opzioni proposte; rispetta la regola di compatibilità duale senza rinunciare ai widget dove esistono.

Conseguenze: il prompt non contiene costrutti Claude-only (verificato a grep: nessun `$ARGUMENTS`, `AskUserQuestion`, `EnterPlanMode`, `subagent`); il flusso e l'ordine dei comandi sono duplicati in due file e vanno mantenuti allineati a mano.

---

## Catalogo come file dati con guardia CI, registry PowerShell invariato

Contesto: le tipologie di progetto e i pacchetti servivano a skill e prompt. DBADMIN e UI chiedevano che `install-lib.ps1` leggesse il JSON come fonte unica; ARCH accettava due copie con un test che fallisce sulla divergenza.

Decisione: `scaffolding-catalog.json` come fonte per skill e prompt; `$Script:PackageRegistry` in `install-lib.ps1` resta hardcoded; un job CI `catalog-guard` confronta nomi, `repo`, `isCore`, dipendenze, risolvibilità delle dipendenze e riferimenti delle tipologie, e fallisce sulla divergenza.

Motivazione: scelta dell'utente. L'alternativa (installer che legge il JSON) avrebbe richiesto di risolvere come reperire il catalogo quando `install.ps1` gira via `irm | iex` senza file locali, e un ri-test completo di un installer funzionante.

Conseguenze: due copie della stessa informazione, ma nessuna deriva silenziosa. Il job non è ancora stato eseguito su GitHub Actions: il dot-source di `install-lib.ps1` su runner Linux è verificato solo in locale con `pwsh`.

---

## Distribuzione del catalogo nel progetto host

Contesto: le skill installate girano nel progetto host, che non vede la root del clone `dr-guidelines`.

Decisione: il core copia `scaffolding-catalog.json` in `<host>/.ai/dr-scaffolding-catalog.json` (funzione `Copy-ScaffoldingCatalog`, chiamata solo per `IsCore`). Le skill lo cercano in ordine: manifest host → root del clone `dr-guidelines` → STOP e chiedono il percorso.

Motivazione: senza distribuzione, in un progetto host il catalogo sarebbe irraggiungibile.

Conseguenze: sorgente assente → `[WARN]` e prosecuzione, non errore. Finché il catalogo non è su `origin/main`, ogni installazione stampa quel warning e le skill usano il secondo percorso del fallback.

---

## Copia condizionale dei file di configurazione .NET

Contesto: `Copy-CoreConfigFiles` copiava `Directory.Build.props` e `global.json` in qualsiasi host, anche in un repo frontend dove sono file inerti.

Decisione: i due file vengono copiati solo se l'host è .NET — rilevamento con `Test-DotnetHost`, che cerca `*.csproj`/`*.fsproj`/`*.vbproj`/`*.sln`/`*.slnx` con `-Depth 3`. `.editorconfig`, `.gitignore`, `.gitattributes` restano sempre copiati.

Motivazione: scelta dell'utente tra le tre opzioni proposte (lasciare e documentare, condizionale, rimandare).

Conseguenze: modificato un installer già testato, quindi ri-verificato sui due scenari. Un host inizialmente non-.NET che aggiunge progetti .NET dopo richiede `install.ps1 -Update` per ottenere i due file; il messaggio `[SKIP]` lo dice. Il limite di profondità 3 evita di scendere in `node_modules` ma non rileverebbe progetti annidati più in basso.

---

## Unità di installazione: il repository, non il progetto

Contesto: `TODO/01-install-scaffholding.md` prescriveva "per ogni progetto creato → lancia gli install.ps1".

Decisione: gli `install.ps1` si eseguono una volta per repository, dalla root, con `Push-Location`/`Pop-Location`.

Motivazione: `.github/`, `.claude/`, `CLAUDE.md` e la configurazione radice vengono letti da Claude Code e Copilot solo dalla root del repo; dentro `src/<progetto>/` sono invisibili e un `Directory.Build.props` annidato altererebbe la build. `Install-DrPackage` usa `(Get-Location).Path` come host root, quindi la directory corrente decide dove finiscono i file.

Conseguenze: nel caso multi-repo si esegue un ciclo di install per repo, con set di pacchetti diverso (backend: core + pacchetti .NET; frontend: core + `dr-fe`).

---

## Ordine di esecuzione: frontend prima del core, formattazione dopo

Contesto: verifiche eseguite in sessione su `create-vue@3.23.0` e su `dotnet format`.

Decisione: nello scaffolding, `npm create vue@latest` va eseguito **prima** dell'install del core; `dotnet format` in scrittura va eseguito **dopo** l'install del core, come ultimo passo.

Motivazione: `create-vue` scrive un proprio `.editorconfig`/`.gitignore`/`.gitattributes` e su cartella non vuota chiede di sovrascrivere; eseguendolo prima, l'installer fa `[SKIP]` e la configurazione Vue sopravvive. `dotnet format` serve dopo perché i template `dotnet new` scrivono UTF-8 con BOM mentre `.editorconfig` del core impone `charset = utf-8`: senza quel passo `dotnet format --verify-no-changes` esce `2` e il gate di push del progetto blocca il primo `git push`.

Conseguenze: l'ordine dei passi è vincolante, non estetico, ed è documentato come tale nelle skill e nel prompt.

---

## Un solo gate di conferma dopo il dry-run

Contesto: il flusso compie operazioni che vanno da "innocue" a "difficili da annullare" (merge in `CLAUDE.md`, file sparsi in `.github/` e `.claude/`).

Decisione: tutte le domande prima, poi dry-run dell'albero completo, poi **una** conferma; da quel punto l'esecuzione procede senza altre domande, salvo divergenze. Eccezione: `-Update` su un repo con `CLAUDE.md` già scritto richiede conferma propria. L'ordine mette `git init` e commit iniziale prima degli install, così il rollback resta `git clean -fd`.

Motivazione: posizione UX al tavolo — spezzare in cinque conferme non aggiunge sicurezza, aggiunge fatica; il rischio si governa con il dry-run e con l'ordine delle operazioni.

Conseguenze: il dry-run diventa il punto critico di correttezza: se descrive male l'albero, l'utente conferma qualcosa che non ha capito.

---

## Eliminato `CreateNewSolution.ps1`, conservato `setup.ps1`

Contesto: il tavolo raccomandava di eliminare entrambi gli script legacy. Verifica successiva: `setup.ps1 -GlobalInstall`/`-GlobalUpdate` scrive `~/.claude/CLAUDE.md`, usa `templates/global-claude.md` ed è documentato in `README.md`; la migrazione a `install.ps1` è un TODO aperto, non fatta.

Decisione: eliminato solo `CreateNewSolution.ps1`. `setup.ps1` e `templates/global-claude.md` intatti.

Motivazione: `CreateNewSolution.ps1` è davvero superseduto da `/dr-scaffold-solution` e puntava al repo legacy `davraf-guidelines`; `setup.ps1` è una capacità in uso e non sostituita.

Conseguenze: deviazione documentata rispetto alla raccomandazione del warroom. La cancellazione è nel working tree e resta reversibile con `git checkout -- CreateNewSolution.ps1` finché non è committata.

---

## Scope esteso ai riferimenti pendenti

Contesto: la precondizione della fase di rimozione legacy dichiarava riferimenti a `CreateNewSolution` solo in `README.md`. La verifica ne ha trovati in 4 file; 3 erano nel perimetro negativo del piano, tra cui `.github/instructions/readme-structure.instructions.md:47`, che *prescriveva* di mostrare quello script nel README.

Decisione: scope esteso a `.github/instructions/readme-structure.instructions.md`, `docs/card-davraf-guidelines.md`, `docs/onboarding.md`, previa approvazione esplicita dell'utente.

Motivazione: senza aggiornare l'istruzione, una futura rigenerazione del README avrebbe reintrodotto il riferimento a un file eliminato.

Conseguenze: divergenza registrata nel piano e poi risolta. In `docs/onboarding.md` sono stati corretti solo i riferimenti allo script eliminato: le sezioni 3-4 restano tarate sul modello a submodule e sono elencate come debito tecnico.
