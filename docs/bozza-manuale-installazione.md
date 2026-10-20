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
| PowerShell 7+ | `7.*` | STOP — gli installer girano su `pwsh`, che va impostato anche come terminale predefinito di VS Code (profilo **PowerShell**, non "Windows PowerShell") |
| `gh` autenticato | `Logged in to github.com` | STOP per la forma `gh api` e per `/dr-scaffold`, che lo richiede sempre. Con i repo `dr-*` Public la forma `irm ... \| iex` non lo usa |
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
git clean -nd          # ANTEPRIMA: elenca i file che verrebbero rimossi, non cancella nulla
git clean -fd          # solo dopo aver controllato l'elenco: rimuove i file non tracciati aggiunti dall'installer
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

**Libreria e catalogo.** Da stream (`gh api`, `irm | iex`) l'installer scarica libreria e catalogo da GitHub (prima il raw pubblico, poi `gh api`). Lanciato da un clone locale di `dr-guidelines` usa invece quelli locali, che hanno la precedenza; `-ForceRemoteLib` li ignora. Il contenuto dei pacchetti arriva comunque sempre da un clone del `main` remoto.

### Forma alternativa breve (solo su repo Public)

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1 | iex
```

| Visibilità repo | `irm ... \| iex` | `gh api ...` |
|---|---|---|
| Public | Dovrebbe funzionare, non ancora provato sul campo | Funziona |
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
| `.mcp.json` | Solo con `-WithMcp` | Generato da `.mcp.example.json`, solo perché assente; senza lo switch l'installer stampa `[sugg]`. Il `.gitignore` copiato lo esclude dai commit |
| `.github/copilot-instructions.md` | Sì | Lo copia solo il core; serve al rimando `@.github/copilot-instructions.md` in `CLAUDE.md` |
| `.github/instructions/` | Sì | Tutti i `*.instructions.md` del core tranne `readme-structure.instructions.md`, che non viene installato (`coreOnlyArtifacts`; nell'output compare `[CORE]` invece di `[OK]`) |
| `.github/prompts/` | Sì | I prompt del core, fra cui `card-project-generator`, `card-wiki-generator`, `onboarding-senior`, `readme-generator`, `architecture-doc`, `dr-scaffold`, `dr-get-latest`, `dr-file-feedback`, `dr-issues-to-plans` |
| `.claude/skills/`, `.agents/skills/` | Sì | Una cartella per ogni skill `dr-*` del core (`.agents/skills/` solo se il pacchetto la contiene). I conteggi non si riportano qui: cambiano a ogni skill aggiunta |
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
| 4 | Installazione di un pacchetto dominio (`dr-minimalapi`) e risoluzione automatica della dipendenza `dr-dotnet-backend` | ✅ 2026-10-16, cartella vuota: `[dep] dr-guidelines` (core implicito) → `[dep] dr-dotnet-backend` → `dr-minimalapi`, manifest con 3 voci e SHA completo, righe `[sugg]` per `dr-efdb`/`dr-fe`/`dr-devops`. Stesso esito con `dr-ux-kitt` (→ `dr-fe`) su Windows PowerShell 5.1. Vedi [Verifica installer del 2026-10-16](#-verifica-installer-del-2026-10-16) |
| 5 | Idempotenza: seconda esecuzione dell'installer senza flag → nessun file sovrascritto (righe `[SKIP]`, più `Nessuna novita'` se il `main` non è avanzato e `[SKIP] Manifest invariato`: senza `-Update` il manifest non avanza) | ☐ Da provare |
| 6 | `-Update`: sovrascrive i file e ri-mergia la sezione in `CLAUDE.md` preservando il contenuto host fuori dai marker | 🟡 2026-10-16: sezione ri-mergiata e testo host fuori dai marker preservato. Trovata e corretta la perdita delle personalizzazioni dei file di configurazione (ora `<file>.new`): provato con la libreria del working tree, ☐ da riprovare sul campo dopo il push su `main`. Vedi [Verifica installer del 2026-10-16](#-verifica-installer-del-2026-10-16) |
| 7 | `/dr-snapshot` eseguita dal progetto host | ☐ Da provare |
| 8 | `/dr-get-latest` dal progetto host | ☐ Da provare |
| 9 | Visibilità attuale dei repo `davraf-amuro/dr-*` (Public o Private) | ✅ Tutti e 9 `PUBLIC`: i 7 originali (`dr-guidelines`, `dr-devops`, `dr-fe`, `dr-efdb`, `dr-winsvc`, `dr-minimalapi`, `dr-dotnet-backend`) dal 2026-09-21, `dr-ux-lcars` dalla creazione (2026-10-11), `dr-ux-kitt` dalla creazione (2026-10-14). Per i 7 originali: dopo una scansione segreti su tutta la history (solo placeholder documentati). Accesso anonimo verificato con `git ls-remote` senza credenziali. Il 2026-09-16 erano `PRIVATE`. La forma breve `irm ... \| iex` del Passo 1 diventa quindi applicabile: ☐ da provare sul campo |
| 10 | Nome del catalogo dopo la copia: nel repo sorgente il file sta in root e si chiama `scaffolding-catalog.json`; `test-progetto-host.md` lo dà per `.ai/dr-scaffolding-catalog.json` nell'host. Rinomina prevista o discrepanza? | 🟡 Rinomina prevista nel codice: `Copy-ScaffoldingCatalog` in `dr-guidelines-install-lib.ps1` copia il file come `.ai\dr-scaffolding-catalog.json`. ☐ Conferma sul campo con `Get-ChildItem .ai` nella cartella host |
| 11 | Il test prova sempre il `main` **remoto**: `Install-DrPackage` fa `git clone --depth 1` da `github.com` anche se l'installer è lanciato da path locale. Modifiche non pushate non vengono installate | ☐ Da provare: modifica locale non pushata → assente nella cartella host |
| 12 | Passi 1 e 2 di questo taccuino dopo la riscrittura della libreria (`aee84a4`, 2026-09-16: catalogo come fonte dei pacchetti, `rootFiles`, nessun rilevamento dello stack). Le prove del 2026-08-12 riguardano la versione precedente | ☐ Da riverificare in una cartella vuota |
| 13 | Guida per non programmatori [`installazione-semplice.md`](installazione-semplice.md): percorso completo su un PC senza Git, con `winget install` di Git e PowerShell 7, forma `irm ... \| iex`, e impostazione di PowerShell 7 come terminale predefinito di VS Code (requisito unico: Windows PowerShell 5.1 non è un ambiente supportato) | ☐ Da provare con un utente non tecnico |
| 14 | `-Update` su un host installato prima del 2026-10-09 → riga `[DEL] .github/instructions/readme-structure.instructions.md` (voce in `obsoleteArtifacts`). Un adattamento locale salvato con lo **stesso nome** viene cancellato: va rinominato prima, per esempio in `readme-local.instructions.md` (caso `dr-mailroom`). I file `*-local.instructions.md` non vengono toccati | 🟡 2026-10-09: provato in locale con la libreria del working tree e un clone simulato (host vuoto → `[CORE]`, host con il file → `[DEL]`, `readme-local` preservato). ☐ Da provare sul campo dopo il push su `main` |

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
| 1 | I pacchetti `dr-*` coprono l'autenticazione? | ✅ Domanda chiusa il 2026-08-12. Dettagli in `.ai/plans/2026-08-12-auth-guidelines/plan.md`. |

---

## 🧩 Come si comportano le dipendenze fra pacchetti

Scoperto leggendo `dr-guidelines-install-lib.ps1` durante il lavoro sulla issue #5, il 2026-09-24; comportamento rivisto con la issue #6, il 2026-10-02. Riguarda chi installa, quindi vale la pena saperlo prima di scegliere i pacchetti.

**Le dipendenze si annunciano prima di scrivere.** `Install-DrPackage` legge il manifest dell'host e calcola l'intero albero delle dipendenze mancanti, anche quelle di una dipendenza, prima di clonare qualsiasi cosa. Lo stampa in un blocco unico, una riga per dipendenza nell'ordine in cui verranno installate:

```
  Dipendenze mancanti, installate prima di dr-minimalapi in questo ordine:
  [dep]  dr-dotnet-backend (richiesta da dr-minimalapi)
  Per installare solo dr-minimalapi usa -NoDependencies.
```

Poi installa le dipendenze in quell'ordine e infine il pacchetto chiesto. Nessuna conferma interattiva: un prompt bloccherebbe gli agenti e le esecuzioni `irm | iex`. La conferma, quando serve, sta a monte: `/dr-scaffold-guidelines` mostra le dipendenze in arrivo nella sua conferma unica. `-Update` non si propaga: riguarda solo il pacchetto chiesto esplicitamente.

**Il core è una dipendenza implicita.** Nessun pacchetto lo dichiara nel catalogo, ma `Install-DrPackage` lo aggiunge in testa all'albero quando manca dal manifest: `-Package dr-fe` in una cartella vuota stampa `[dep]  dr-guidelines (richiesta da dr-fe, core implicito)` e installa il core prima di `dr-fe`. Prima del 2026-10-11 non succedeva: l'host riceveva solo `dr-fe`, senza `CLAUDE.md` né istruzioni trasversali (issue dr-fe#1). Implicita, non scritta nel catalogo, perché vale anche per i pacchetti futuri senza ripeterla in ogni voce. Provato il 2026-10-11 con la libreria locale in una cartella temporanea: manifest con `dr-guidelines` e `dr-fe`; con `-NoDependencies` solo `dr-fe` e la riga `[skip] dr-guidelines`.

**Si possono rifiutare con `-NoDependencies`.** Con lo switch l'installer non installa le dipendenze mancanti: le elenca con il prefisso `[skip]`, stampa un avviso e installa solo il pacchetto chiesto. Chi passa lo switch ha scelto; le regole del pacchetto che rimandano alla dipendenza restano senza destinazione finché non la installi a parte. Dall'entry point: `dr-guidelines-install.ps1 -Package dr-minimalapi -NoDependencies`.

**Un ciclo nel catalogo è un errore, non un loop.** Se il catalogo dichiarasse A → B → A, l'installer si ferma con `Ciclo nelle dipendenze del catalogo: A -> B -> A` prima di clonare, a host intatto.

**La compatibilità con lo stack la garantisce il catalogo, non l'installer.** L'installer non conosce lo stack dell'host e non lo rileva: `appliesTo` lo legge, ma non filtra. A fermare una dipendenza sbagliata è il guard di catalogo in CI (`catalog-guard` in `.github/workflows/ci.yml`), con questa regola: una dipendenza `D` del pacchetto `P` è compatibile se `D.appliesTo` contiene `any`, oppure contiene ogni kind di `P.appliesTo`. Ne segue che un pacchetto `any` può dipendere solo da pacchetti `any`. Lo stesso guard fallisce su un ciclo.

Senza quella regola una dipendenza da un pacchetto `node` o `any` verso un pacchetto `dotnet` porterebbe i file di progetto .NET (`Directory.Build.props`, `global.json`, che arrivano con `dr-dotnet-backend`) nella radice di un host che .NET non è. È il motivo per cui `dr-fe` e `dr-devops` citano `dr-minimalapi` con un rimando condizionale invece che con una dipendenza.

**La convenzione che ne è nata**: `cross-package-references.instructions.md`. Un rimando a una regola di un altro pacchetto si scrive sempre condizionale al manifest `.ai/dr-guidelines-packages.json`, con un ripiego che dice *cosa* serve senza spiegare *come* si fa, e con l'obbligo per l'agente di dichiarare nell'output quale dei due rami ha applicato. Senza quella dichiarazione non c'è modo di sapere se la regola è stata seguita o aggirata.

---

## 🔍 Verifica installer del 2026-10-16

Prove in cartelle temporanee, con gli installer da path locale (la libreria arriva dal `main` remoto) e poi con la libreria del working tree caricata a mano.

**Funzionava già:** risoluzione delle dipendenze e core implicito; rimozione degli `obsoleteArtifacts` (`dr-tattico` → `[DEL]`); merge additivo di `.claude/settings.json` (le chiavi `deny` ed `env` dell'host restano); `.mcp.json` mai sovrascritto; elenco dei file modificati a monte con lo SHA completo del manifest; Windows PowerShell 5.1.

**Difetti trovati e corretti** (piano `.ai/plans/2026-10-16-installer-update-sicuro/`):

| # | Difetto | Correzione |
|---|---|---|
| 1 | `-Update` sovrascriveva `.gitignore`, `.editorconfig`, `.gitattributes`, `.github/copilot-instructions.md` e i `rootFiles`: le righe dell'host sparivano | Confronto a tre vie con la versione del commit installato. File mai modificato → `[UPD]`; personalizzato e cambiato a monte → `<file>.new` (`[NEW]`), originale intatto; personalizzato e invariato a monte → `[SKIP]` (niente `.new` ricorrente); identico → `[=]`. Provati tutti gli esiti |
| 2 | Un `$_` o `$&` nel `CLAUDE.md` sorgente incollava l'intero file host dentro la sezione | Sostituzione letterale (MatchEvaluator). Provato su PowerShell 7 (il codice resta compatibile con 5.1, che però non è un requisito supportato) |
| 3 | `-Global` non riconosceva il blocco legacy `## Linee guida globali (Davraf)` del vecchio `setup.ps1` e ne accodava un secondo | `[WARN]` e nessuna scrittura: il blocco legacy va rimosso a mano, poi si rilancia |
| 4 | `CLAUDE.md` e manifest con BOM su PowerShell 5.1, senza su 7 | Scrittura UTF-8 senza BOM con qualsiasi versione |

**Restano aperti** (candidati a issue): ~~il `.gitignore` distribuito porta `TODO/` negli host~~ (risolto: `Copy-CoreConfigFiles` toglie le voci marcate `solo-core`, quindi `TODO/` non arriva); `-SourceRoot` non è registrato nel manifest e i wrapper dei pacchetti non lo accettano; l'elenco "file modificati a monte" include file che non arrivano all'host (`.ai/plans/`, `docs/`); un file tolto da dentro una skill resta nell'host se non è in `obsoleteArtifacts`; nessun test automatico dell'installer.

---

## 📦 Sorgenti applicativi: `sourceFiles` e `-SourceRoot`

Aggiunti il 2026-10-11 (issue dr-guidelines#15). Prima l'installer copiava solo file piatti di `.github/instructions/` e `.github/prompts/` e i `rootFiles` alla stessa path della radice. Un frontend con `src/` in una sottocartella non era gestito, e `-Update` sovrascriveva senza confronto.

- **Catalogo**: `sourceFiles: [{ "from": "<percorso nel pacchetto>", "to": "<percorso relativo a -SourceRoot>" }]`. Il campo si valida già quando l'installer legge il catalogo (`Get-DrPackageRegistry`): un `from` o un `to` vuoto, assoluto (`C:/…`, `/…`) o con `..` ferma tutto prima di clonare. La CI (`catalog-guard`) costruisce lo stesso registry, quindi blocca un catalogo malformato.
- **`-SourceRoot`**: cartella dell'host relativa alla radice, solo con `-Package` (con il core da solo è un errore). Vale per il pacchetto e per le sue dipendenze. Il confine si verifica anche sul percorso risolto: nessun file finisce fuori da `-SourceRoot`.
- **Esiti per file**: `[OK]` copiato, `[SKIP]` già presente senza `-Update`, `[=]` invariato con `-Update`, `[NEW]` versione cambiata scritta in `<file>.new` (l'originale non si tocca), `[MISS]` voce del catalogo assente nel pacchetto.
- **Provato il 2026-10-11** con la libreria locale e un pacchetto finto in cartella temporanea: 15 controlli superati, tra cui copia in `frontend/`, salto, `.new`, file invariato, rifiuto di `../fuori`, di `C:/x` e di `/etc/a`. Nessun file scritto fuori dall'host.
- **Non ancora**: varianti scelte all'installazione (es. palette). Gli installer dei singoli pacchetti non accettano `-SourceRoot`: si passa dall'installer del core con `-Package`.

## 🔗 Riferimenti

| Documento | Contenuto |
|---|---|
| [`test-progetto-host.md`](test-progetto-host.md) | Procedura di test end-to-end completa, comprese verifiche di idempotenza e `-Update` |
| [`../README.md`](../README.md) | Panoramica dei pacchetti `dr-*` |
| [`../dr-guidelines-install.ps1`](../dr-guidelines-install.ps1) | Installer: header con tutte le forme di invocazione supportate |
| [`../dr-guidelines-install-lib.ps1`](../dr-guidelines-install-lib.ps1) | Registry dei pacchetti e orchestratore `Install-DrPackage` |
| [`onboarding.md`](onboarding.md) | Onboarding developer senior |

---

*Revisione v1.17 — 2026-10-20 21:00 — claude-opus-5-5*
