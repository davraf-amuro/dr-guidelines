# BOZZA — Manuale di installazione `dr-*` in una cartella vuota

> 🚧 **Documento in lavorazione.** Non è ancora il manuale utente: è il taccuino dove annotiamo i passaggi **verificati sul campo**, mano a mano che li proviamo. Quando tutti i passaggi saranno confermati, questo file diventa la base del manuale definitivo.
>
> Regola del taccuino: qui entra **solo** ciò che è stato eseguito e ha funzionato. Tutto il resto sta nella sezione [Da verificare](#-da-verificare), esplicitamente marcato.
>
> 📘 **La guida per l'utente è [`guida-nuova-soluzione.md`](guida-nuova-soluzione.md)** (2026-09-16). Questo taccuino resta la fonte degli esiti: quando un passaggio qui diventa verificato, va aggiornata anche la tabella "Cosa è stato provato sul campo" della guida.

---

## 🎯 Scenario coperto

Un utente apre **VS Code con Claude Code** su una **cartella vuota** e vuole installarci le linee guida `dr-*`.

| Dettaglio | Valore |
|---|---|
| Cartella di prova | `E:\Davide\Progetti\dr-guidelines-workspace\dr-test-01` |
| Fuori dal workspace `dr-guidelines` | Sì — nessuna skill `dr-*` disponibile all'inizio |
| Sistema | Windows 11, PowerShell 7 |
| Data della sessione di verifica | 2026-08-12 |

**Il vincolo che determina tutto il resto:** in una cartella vuota Claude Code non ha nessuna skill `dr-*`. Le skill arrivano **insieme** al pacchetto core. Quindi il primo comando è per forza manuale, dato nel terminale. Non esiste un `/dr-...` da invocare prima dell'installazione.

---

## ✅ Passo 0 — Verificare i prerequisiti

Sei comandi di sola lettura. Nessuno scrive niente.

```powershell
dotnet --list-sdks
git --version
pwsh --version
gh auth status
node --version    # solo se il progetto avrà un frontend
npm --version     # solo se il progetto avrà un frontend
```

| Requisito | Esito atteso | Se manca |
|---|---|---|
| .NET SDK 10.x | almeno una riga `10.*` | STOP — nessun progetto .NET è creabile |
| git | qualsiasi versione | STOP — l'installer clona i pacchetti |
| PowerShell 7+ | `7.*` | STOP — gli installer girano su `pwsh` |
| `gh` autenticato | `Logged in to github.com` | STOP se i repo `dr-*` sono Private |
| node + npm | qualsiasi versione | Blocca solo il frontend, il resto procede |

**Esito reale rilevato nella sessione del 2026-08-12** — tutto verde:

| Requisito | Valore rilevato |
|---|---|
| .NET SDK | `10.0.302` |
| git | `2.46.2.windows.1` |
| PowerShell | `7.6.4` |
| `gh` | `davraf-amuro`, scopes `gist`, `read:org`, `repo`, `workflow` |
| node / npm | `v26.5.0` / `10.7.0` |

**Perché il gate va prima di scrivere:** su un progetto .NET l'installer di `dr-dotnet-backend` copia un `global.json` che pinna l'SDK (`10.0.100`, `rollForward: latestMinor`). Se l'SDK installato non lo soddisfa, **ogni** comando `dotnet` successivo in quella cartella fallisce con un errore che sembra un problema di `dotnet new` e invece è il pin.

I prerequisiti da verificare dipendono dal dominio: l'SDK .NET serve solo ai domini .NET, node/npm a quelli frontend, PlatformIO a quelli firmware. Un progetto di soli contenuti richiede solo git.

---

## ⏭️ Passo 0-bis (opzionale) — `git init`

**`git init` non è un prerequisito dell'installer.** `Install-DrPackage` scrive nella cartella corrente e non chiede nulla a git riguardo al progetto host.

Serve solo se vuoi il rollback comodo mentre fai prove:

```powershell
git init
"# dr-test-01" | Set-Content README.md -Encoding UTF8
git add README.md
git commit -m "chore: init progetto host di prova"
```

Con un commit di partenza puoi annullare tutto in due comandi:

```powershell
git clean -fd          # rimuove i file non tracciati aggiunti dall'installer
git checkout -- .      # ripristina i file tracciati modificati
```

Senza commit iniziale, la pulizia va fatta a mano file per file. Per un progetto reale il `git init` lo farai comunque; per un test è comodità, non obbligo.

---

## ✅ Passo 1 — Installare il pacchetto core `dr-guidelines`

Comando **verificato e funzionante** (2026-08-12):

```powershell
Set-Location E:\Davide\Progetti\dr-guidelines-workspace\dr-test-01
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
```

### Cosa fa, riga per riga

| Pezzo | Effetto |
|---|---|
| `Set-Location <cartella>` | Posiziona la shell nella cartella di destinazione |
| `gh api repos/.../contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw"` | Scarica **un solo file**: il testo dell'installer |
| `[scriptblock]::Create(...)` | Trasforma quel testo in uno script eseguibile |
| `& ...` | Lo esegue nella cartella corrente |

### ⚠️ `Set-Location` è obbligatorio

L'installer usa `(Get-Location).Path` come root del progetto host. Lanciato da un'altra cartella, i file finiscono nel posto sbagliato — e non c'è nessun messaggio d'errore, perché dal punto di vista dello script è un'installazione riuscita.

### ⚠️ Nessun repository finisce nella tua cartella

Punto di confusione emerso durante la sessione, da spiegare a chiare lettere nel manuale finale.

| Cosa **non** succede | Cosa succede davvero |
|---|---|
| Il repo `dr-guidelines` **non** viene clonato nella tua cartella | Viene scaricato un singolo file: l'installer |
| Nessun submodule git | Nessuna voce in `.gitmodules` |
| Nessun `.git` di `dr-guidelines` | Il `.git` presente è solo il tuo, se hai fatto `git init` |

L'installer **sì** esegue un `git clone --depth 1` al suo interno, ma lo fa in `%TEMP%\dr-install-<guid>`, ne copia i file utili nella tua cartella e poi **cancella la temp dir**. È trasporto interno, invisibile all'utente.

### Forma alternativa breve (solo su repo Public)

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1 | iex
```

| Visibilità repo | `irm ... \| iex` | `gh api ...` |
|---|---|---|
| Public | Funziona | Funziona |
| Private | **404** — `raw.githubusercontent.com` non serve repo privati | Funziona (usa il token di `gh`) |

**Consiglio operativo:** parti sempre dalla forma `gh api`. Funziona in entrambi i casi, quindi non devi sapere in che stato sono i repo.

---

## ✅ Passo 2 — Verificare cosa è stato installato

```powershell
Get-ChildItem -Force | Select-Object Name
Get-ChildItem .github\instructions | Select-Object Name
Get-ChildItem .claude\skills -Directory | Select-Object Name
Get-Content .ai\dr-guidelines-packages.json
```

Contenuto atteso in una cartella **non .NET** (è il caso della cartella vuota):

| Elemento | Presente? | Note |
|---|---|---|
| `.editorconfig`, `.gitignore`, `.gitattributes` | Sì | Sempre copiati dal core |
| `Directory.Build.props`, `global.json` | **No** | Non appartengono al core: li installa `dr-dotnet-backend`, che li dichiara nei propri `rootFiles` del catalogo. Un host senza quel pacchetto non li riceve. ⚠️ Descrive l'installer dopo `aee84a4` (2026-09-16). Il 2026-08-12 girava la versione precedente, che rilevava lo stack e saltava questi file sugli host non .NET: esito equivalente, meccanismo diverso, da riverificare |
| `.claude/settings.json` | Sì | Copiato se assente; se esiste, vengono aggiunte solo le voci `permissions.allow` mancanti, senza toccare le altre chiavi |
| `.mcp.json` | Sì | Generato da `.mcp.example.json`, solo perché assente. Il `.gitignore` copiato lo esclude dai commit |
| `.github/instructions/` | Sì | 10 file `*.instructions.md` al 2026-08-12. Al 2026-09-16 il core ne ha 11 (aggiunto `no-hardcoded-values`) |
| `.github/prompts/` | Sì | `card-project-generator`, `card-wiki-generator`, `onboarding-senior`, `readme-generator`, `dr-scaffold` al 2026-08-12. Al 2026-09-16 anche `dr-get-latest` e `dr-file-feedback` |
| `.claude/skills/` | Sì | Il taccuino del 2026-08-12 riportava 10 cartelle, ma nei commit di quel giorno (`faf6a6c`, `cffb1f2`) le skill del core erano 15: conteggio da rifare. Al 2026-09-16 il core ne ha 16 |
| `CLAUDE.md` | Sì | Contiene i marker `<!-- dr-guidelines -->` … `<!-- /dr-guidelines -->` |
| `.ai/dr-guidelines-packages.json` | Sì | Manifest dei pacchetti installati |
| `.ai/dr-scaffolding-catalog.json` | Sì | Catalogo tipologie/pacchetti, letto dalle skill `dr-scaffold*` |
| `briefs/` | Sì | Cartella vuota per le richieste dell'utente, creata solo se assente. Qui ci scrivi i brief e li indichi all'agente, che ne ricava un piano da approvare. ⚠️ Introdotta il 2026-09-24 (issue #1): da verificare su `dr-postman`. Git non versiona le cartelle vuote: finché resta vuota non compare nei commit |

---

## 🚧 Passo 3 — Riavviare Claude Code (da provare)

Claude Code legge `.claude/skills/` **all'avvio della sessione**. Le skill appena installate non compaiono finché non riavvii.

1. Chiudi e riapri Claude Code sulla cartella, oppure esegui `Developer: Reload Window` in VS Code
2. Verifica che `/dr-scaffold` sia disponibile nell'elenco delle skill

Da qui in poi non servono più comandi manuali: `/dr-scaffold` fa il gate prerequisiti, rileva lo stato della cartella e delega alla skill giusta.

---

## 🚧 Da verificare

Passaggi non ancora eseguiti sul campo in questa sessione. Non promuoverli a "verificato" senza averli provati.

| # | Passaggio | Stato |
|---|---|---|
| 1 | Riavvio di Claude Code → le skill `dr-*` compaiono davvero | ☐ Da provare |
| 2 | `/dr-scaffold` su cartella con solo il core installato → delega a `dr-scaffold-solution` | ☐ Da provare |
| 3 | Creazione di una solution `.slnx` + primo progetto | ☐ Da provare |
| 4 | Installazione di un pacchetto dominio (`dr-minimalapi`) e risoluzione automatica della dipendenza `dr-dotnet-backend` | ☐ Da provare |
| 5 | Idempotenza: seconda esecuzione dell'installer senza flag → nessun file sovrascritto (righe `[SKIP]`, più `Nessuna novita'` e `[OK] Manifest aggiornato`, che si riscrive sempre) | ☐ Da provare |
| 6 | `-Update`: sovrascrive i file e ri-mergia la sezione in `CLAUDE.md` preservando il contenuto host fuori dai marker | ☐ Da provare |
| 7 | `/dr-snapshot` eseguita dal progetto host | ☐ Da provare |
| 8 | `/dr-get-latest` dal progetto host | ☐ Da provare |
| 9 | Visibilità attuale dei repo `davraf-amuro/dr-*` (Public o Private) | ✅ 2026-09-21: tutti e 7 (`dr-guidelines`, `dr-devops`, `dr-fe`, `dr-efdb`, `dr-winsvc`, `dr-minimalapi`, `dr-dotnet-backend`) → `PUBLIC`, dopo una scansione segreti su tutta la history (solo placeholder documentati). Accesso anonimo verificato con `git ls-remote` senza credenziali. Il 2026-09-16 erano `PRIVATE`. La forma breve `irm ... \| iex` del Passo 1 diventa quindi applicabile: ☐ da provare sul campo |
| 10 | Nome del catalogo dopo la copia: nel repo sorgente il file sta in root e si chiama `scaffolding-catalog.json`; `test-progetto-host.md` lo dà per `.ai/dr-scaffolding-catalog.json` nell'host. Rinomina prevista o discrepanza? | 🟡 Rinomina prevista nel codice: `Copy-ScaffoldingCatalog` in `dr-guidelines-install-lib.ps1` copia il file come `.ai\dr-scaffolding-catalog.json`. ☐ Conferma sul campo con `Get-ChildItem .ai` nella cartella host |
| 11 | Il test prova sempre il `main` **remoto**: `Install-DrPackage` fa `git clone --depth 1` da `github.com` anche se l'installer è lanciato da path locale. Modifiche non pushate non vengono installate | ☐ Da provare: modifica locale non pushata → assente nella cartella host |
| 12 | Passi 1 e 2 di questo taccuino dopo la riscrittura della libreria (`aee84a4`, 2026-09-16: catalogo come fonte dei pacchetti, `rootFiles`, nessun rilevamento dello stack). Le prove del 2026-08-12 riguardano la versione precedente | ☐ Da riverificare in una cartella vuota |
| 13 | Guida per non programmatori [`installazione-semplice.md`](installazione-semplice.md): percorso completo su un PC senza Git, con `winget install` di Git e PowerShell 7, forma `irm ... \| iex`, e verifica che PowerShell 5.1 preinstallato basti o no | ☐ Da provare con un utente non tecnico |

---

## 📝 Correzioni rispetto a `docs/test-progetto-host.md`

Annotate qui perché il manuale finale non le riperda.

| # | Cosa dice `test-progetto-host.md` | Correzione |
|---|---|---|
| 1 | Il passo 1️⃣ è `git init` + commit iniziale, presentato come primo passo della procedura | `git init` **non è un prerequisito**. L'installer non lo richiede. Va documentato come passo **opzionale**, utile solo per il rollback durante i test. Metterlo per primo fa credere che l'installazione lo richieda |
| 2 | Il passo 3️⃣ descrive `git clone` tra i passaggi interni | Il wording va reso esplicito: il clone avviene **in `%TEMP%`** ed è invisibile all'utente. Detto senza contesto, fa credere che il repo finisca nella cartella del progetto. È stato un fraintendimento reale in sessione |
| 3 | La procedura usa la forma a **path locale** (`& ..\dr-guidelines\dr-guidelines-install.ps1`) | Funziona solo se hai già il workspace multi-repo clonato di fianco. Per il manuale utente la forma di riferimento è **`gh api`**: nessun clone locale richiesto, funziona sia su repo Public che Private |
| 4 | La cartella di test si chiama `test-uno` | Nella sessione del 2026-08-12 è stata usata `dr-test-01`. Il nome è irrilevante per la procedura — il manuale finale dovrebbe usare un segnaposto generico |

**Recepite il 2026-09-16** in `test-progetto-host.md` v2.0: `git init` è consigliato ma dichiarato non richiesto, il clone in `%TEMP%` è spiegato, la forma di riferimento è `gh api`, la cartella di prova è `dr-test-01` fuori dal workspace e aperta in finestra separata.

---

## ❓ Domande emerse in sessione

Aperte, da risolvere prima che il manuale sia considerato completo.

| # | Domanda | Stato al 2026-08-12 |
|---|---|---|
| 1 | I pacchetti `dr-*` coprono l'autenticazione? | ✅ **Risolta il 2026-08-12.** All'apertura della domanda: no. L'unica menzione era una riga in `minimal-api-architecture.instructions.md` (riga 16) che citava `SimpleAuthenticationTools` in versione API Key — adatta a chiamate servizio-a-servizio, non a utenti umani. Nessuna voce nel catalogo, nessuna domanda nel flusso di scaffolding, nessun check nell'audit, niente in `dr-fe`. Intervento eseguito su tre file, vedi sotto |

**Come è stata chiusa** — piano `.ai/plans/2026-08-12-auth-guidelines/plan.md`:

| Pacchetto | File | Contenuto aggiunto |
|---|---|---|
| `dr-minimalapi` | `minimal-api-architecture.instructions.md` | Sezione "Autenticazione": matrice di scelta a cinque rami, motivazione di ASP.NET Identity, coesistenza cookie/bearer, sottosezione "Rilascio in container". Punto auth nel gate di raccolta informazioni. `AddJwtBearer` per utenti umani in "Vietato" |
| `dr-fe` | `frontend-organization.instructions.md` | Regola 7: la login non si implementa nel frontend, domanda obbligatoria all'utente, comportamento del client HTTP secondo lo schema, collocazione dei file |
| `dr-devops` | `docker-swarm-compose.instructions.md` | Sezione 6: persistenza del portachiavi Data Protection lato stack |

**Le decisioni fissate:**

| Caso | Schema |
|---|---|
| Utenti umani, frontend browser stesso dominio | ASP.NET Identity + cookie `HttpOnly` |
| Utenti umani, domini diversi o client non-browser previsto | Identity + `AddBearerToken` (token opachi) |
| Entrambi | Stessi endpoint `MapIdentityApi`, si aggiunge solo lo schema |
| Nessun utente umano, servizio-a-servizio | `SimpleAuthenticationTools` (API Key) |
| Auth non richiesta | Nessuna |

**Il caso container, emerso durante la stesura.** Nessun file del workspace nominava `Data Protection` né `ForwardedHeaders`. Sono le due cause di rottura silenziosa dell'auth in container:

1. Portachiavi Data Protection non persistito → ricreare il container invalida ogni sessione; con `replicas > 1` ogni replica ha il proprio portachiavi, quindi 401 a intermittenza
2. TLS terminato sul reverse proxy → l'app riceve `http`, non emette il cookie `Secure`. Trappola Docker: `UseForwardedHeaders` di default si fida solo del loopback, mentre il proxy arriva dall'IP di un altro container, quindi le intestazioni vengono ignorate senza errore

Entrambe ora coperte dalla sottosezione "Rilascio in container" di `minimal-api-architecture` e dalla sezione 6 di `docker-swarm-compose`.

### Caso reale che ha esposto il buco (2026-08-12)

Prompt dato in `dr-test-01`: applicazione familiare con frontend browser, **login per differenziare gli utenti**, maschera profilo con email e cambio password, registrazione fatture di casa (una tantum e periodiche) e grafico spese 12 mesi passati + 12 mesi di previsione.

Cosa ha fatto l'agente: ha aperto una `AskUserQuestion` intitolata *"Confermi ASP.NET Identity + JWT per l'autenticazione?"*, con tre opzioni — Identity + JWT (preselezionata), tabella utenti custom con hash password, Identity + JWT con OAuth Google/Microsoft dall'inizio.

| Aspetto | Valutazione |
|---|---|
| Aver chiesto conferma | **Corretto.** La riga 16 impone di chiedere prima di aggiungere il pacchetto auth. E la domanda verteva su *quale schema*, non su *se* fare la login: il requisito era stato recepito |
| Le opzioni proposte | **Fuori guideline.** ASP.NET Identity, JWT e OAuth non compaiono in nessun file `dr-*`. L'agente le ha prodotte dalla conoscenza generale del modello |
| Coerenza del pacchetto citato dalle guidelines | **Inadatta al caso.** `SimpleAuthenticationTools` è citato in versione API Key, pensata per chiamate servizio-a-servizio. Non copre utenti umani con registrazione, profilo e cambio password |

**Conclusione:** finché manca una linea guida sull'autenticazione di utenti interattivi, ogni progetto con login otterrà uno schema improvvisato e diverso dal precedente. È il caso d'uso che giustifica il pacchetto `dr-auth` (o almeno una sezione dedicata).

Punti che la futura linea guida dovrebbe fissare:

- ASP.NET Identity come base quando servono registrazione, profilo, cambio password, reset e lockout — non riscriverli a mano
- Scelta esplicita **cookie vs JWT**: cookie per frontend solo-browser same-origin, JWT quando è previsto un client non-browser. Da decidere in fase di raccolta requisiti, non a valle
- Se e quando proporre OAuth esterno (richiede registrazione app presso il provider: non è a costo zero)
- Quando `SimpleAuthenticationTools` resta la scelta giusta — API interne senza utenti umani

---

## 🧩 Come si comportano le dipendenze fra pacchetti

Scoperto leggendo `dr-guidelines-install-lib.ps1` durante il lavoro sulla issue #5, il 2026-09-24. Riguarda chi installa, quindi vale la pena saperlo prima di scegliere i pacchetti.

**Le dipendenze si risolvono da sole, e non si possono rifiutare.** `Install-DrPackage` legge il manifest dell'host e, per ogni dipendenza non ancora installata, stampa `Dipendenza mancante: <nome> -> installazione automatica` e richiama sé stesso. È ricorsivo: la dipendenza di una dipendenza arriva comunque. Nessuna conferma viene chiesta. `-Update` invece non si propaga: riguarda solo il pacchetto chiesto esplicitamente.

**Il filtro per stack non esiste in questa fase.** `Get-DrPackageRegistry` costruisce il registro con `Repo`, `IsCore`, `Dependencies`, `RootFiles` e `ObsoleteArtifacts`: **`appliesTo` non viene letto affatto dall'installer**. Quel campo è consumato solo da `/dr-scaffold-guidelines`, dal prompt di scaffolding e dal guard di catalogo in CI, cioè quando si *propone* un pacchetto — non quando lo si installa.

Conseguenza pratica: una dipendenza dichiarata da un pacchetto `node` o `any` verso un pacchetto `dotnet` porterebbe i file di progetto .NET (`Directory.Build.props`, `global.json`, che arrivano con `dr-dotnet-backend`) nella radice di un host che .NET non è, senza che nessuno lo chieda. È il motivo per cui `dr-fe` e `dr-devops` citano `dr-minimalapi` con un rimando condizionale invece che con una dipendenza.

**La convenzione che ne è nata**: `cross-package-references.instructions.md`. Un rimando a una regola di un altro pacchetto si scrive sempre condizionale al manifest `.ai/dr-guidelines-packages.json`, con un ripiego che dice *cosa* serve senza spiegare *come* si fa, e con l'obbligo per l'agente di dichiarare nell'output quale dei due rami ha applicato. Senza quella dichiarazione non c'è modo di sapere se la regola è stata seguita o aggirata.

---

## 🔗 Riferimenti

| Documento | Contenuto |
|---|---|
| [`test-progetto-host.md`](test-progetto-host.md) | Procedura di test end-to-end completa, comprese verifiche di idempotenza e `-Update` |
| [`../README.md`](../README.md) | Panoramica dei pacchetti `dr-*` |
| [`../dr-guidelines-install.ps1`](../dr-guidelines-install.ps1) | Installer: header con tutte le forme di invocazione supportate |
| [`../dr-guidelines-install-lib.ps1`](../dr-guidelines-install-lib.ps1) | Registry dei pacchetti e orchestratore `Install-DrPackage` |
| [`onboarding.md`](onboarding.md) | Onboarding developer senior |

---

*Revisione v1.8 — 2026-09-24 — claude-opus-5-5 — `briefs/` fra i risultati attesi del Passo 2*
