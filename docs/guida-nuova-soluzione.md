# Creare una soluzione da zero con i pacchetti `dr-*`

Questa guida parte da una cartella vuota e arriva a una solution pronta, con le linee guida `dr-*` installate. Servono sei passi. A mano scrivi quattro comandi: tutto il resto lo fa l'agente.

> **Per chi è:** chi usa VS Code con Claude Code (o GitHub Copilot) su Windows e vuole avviare un progetto nuovo seguendo le guide `dr-*`.

---

## ⚡ La versione corta

Se hai già tutti i prerequisiti, questi sono gli unici comandi da scrivere a mano:

```powershell
# 1. Crea la cartella e aprila in una finestra VS Code nuova
New-Item -ItemType Directory C:\Progetti\ordini
code C:\Progetti\ordini

# 2. Nel terminale della finestra nuova: installa il core
Set-Location C:\Progetti\ordini
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
```

Poi:

1. Ricarica la finestra: `Ctrl+Shift+P` → `Developer: Reload Window`
2. In Claude Code scrivi `/dr-scaffold crea una Minimal API per gli ordini`
3. Rispondi alle domande e conferma l'anteprima

`C:\Progetti\ordini` è un esempio: usa il percorso che preferisci.

---

## 🧭 L'ordine conta

L'errore più naturale è creare prima la solution a mano e poi "scaricare le linee guida". L'ordine giusto è l'opposto.

| Ordine | Perché |
|---|---|
| 1. Prima il core `dr-guidelines` | In una cartella vuota Claude Code non ha nessuna skill `dr-*`. Le skill arrivano **con** il core |
| 2. Poi la solution, con `/dr-scaffold` | È il punto d'ingresso: passa il lavoro a `/dr-scaffold-solution`, che crea solution e progetti, fa il `git init` e installa i pacchetti del dominio giusto |

Se crei la solution a mano, salti proprio la parte che applica le convenzioni.

---

## ✅ Passo 1 — Controlla i prerequisiti

Sono comandi di sola lettura: non scrivono niente.

```powershell
git --version
pwsh --version
gh auth status
dotnet --list-sdks   # solo per progetti .NET
node --version       # solo se ci sarà un frontend
npm --version        # solo se ci sarà un frontend
```

| Requisito | Cosa devi vedere | Se manca |
|---|---|---|
| git | una versione qualsiasi | Installalo: l'installer scarica i pacchetti con `git clone` |
| PowerShell 7+ | `7.*` | Installalo: gli installer girano su `pwsh` |
| `gh` autenticato | `Logged in to github.com` | Esegui `gh auth login` con scope `repo`: i repo `dr-*` sono **Private** |
| .NET SDK 10 | almeno una riga `10.*` | Solo per progetti .NET: senza, nessun progetto .NET è creabile |
| node + npm | una versione qualsiasi | Solo per il frontend: il resto del progetto procede lo stesso |

`/dr-scaffold` ripete questo controllo da solo prima di scrivere qualsiasi cosa. Farlo prima ti evita di arrivare fino al passo 5 per scoprire che manca qualcosa.

---

## 📁 Passo 2 — Crea la cartella e aprila in una finestra nuova

```powershell
New-Item -ItemType Directory C:\Progetti\ordini
code C:\Progetti\ordini
```

**Usa una finestra VS Code separata.** Non aggiungere la cartella a un workspace che contiene già i repo `dr-*`: Claude Code vedrebbe le skill di quel workspace, non quelle installate nel tuo progetto.

**Non serve `git init`.** Lo fa lo scaffolding al passo 5 (`/dr-scaffold-solution`), dopo aver creato i progetti, con un commit iniziale che diventa il tuo punto di ripristino.

---

## ⬇️ Passo 3 — Installa il core `dr-guidelines`

Nel terminale della finestra nuova:

```powershell
Set-Location C:\Progetti\ordini
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
```

### Cosa vedi

Estratto indicativo, ricostruito dal codice dell'installer attuale:

```
=== dr-guidelines ===
  Repo    : davraf-amuro/dr-guidelines
  Progetto: C:\Progetti\ordini
  Clonazione davraf-amuro/dr-guidelines...
  .github/instructions/:
  [OK]   code-organization.instructions.md
  ...
  CLAUDE.md:
  [OK]   CLAUDE.md creato con sezione dr-guidelines
  [OK]   Manifest aggiornato: dr-guidelines (a1b2c3d)
  Completato: dr-guidelines
```

La riga `Progetto:` deve mostrare la tua cartella. Se mostra un altro percorso, fermati: vedi [Se qualcosa va storto](#-se-qualcosa-va-storto).

### Tre cose da sapere

| Cosa | Dettaglio |
|---|---|
| **`Set-Location` è obbligatorio** | L'installer scrive nella cartella in cui ti trovi. Da un'altra cartella i file finiscono lì, senza nessun errore |
| **Nella tua cartella non arriva nessun repository** | L'installer clona il pacchetto in `%TEMP%`, copia i file che servono e cancella la copia temporanea. Niente submodule, niente `.git` di `dr-guidelines` |
| **Si installa sempre il `main` pubblicato su GitHub** | Anche se lanci l'installer da un clone locale. Una modifica ai pacchetti non ancora pushata non arriva nel progetto |

### Perché non `irm ... | iex`

Esiste una forma più corta:

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1 | iex
```

Funziona solo se i repo sono **Public**. Oggi i repo `dr-*` sono Private e quell'indirizzo risponde `404`. La forma `gh api` funziona in entrambi i casi: usa sempre quella.

---

## 🔄 Passo 4 — Ricarica la finestra

Claude Code legge le skill **all'avvio della sessione**. Quelle appena installate non compaiono finché non ricarichi.

1. `Ctrl+Shift+P` → `Developer: Reload Window`
2. Apri Claude Code e scrivi `/dr-` : nell'elenco deve comparire `/dr-scaffold`

**Con GitHub Copilot:** lo stesso flusso è nel prompt `.github/prompts/dr-scaffold.prompt.md`, installato dal core.

---

## 🏗️ Passo 5 — Chiedi la soluzione a `/dr-scaffold`

Descrivi cosa vuoi costruire, con parole tue:

| Esempio di richiesta | Cosa viene proposto |
|---|---|
| `/dr-scaffold crea una Minimal API per gli ordini` | Solution `.slnx` + progetto `ordini.api` + pacchetto `dr-minimalapi` |
| `/dr-scaffold crea un servizio windows che importa file` | Solution + progetto `.service` + pacchetto `dr-winsvc` |
| `/dr-scaffold crea una Minimal API con frontend Vue` | Solution + API + frontend `ordini-fe` + pacchetti `dr-minimalapi` e `dr-fe`. Vedi la nota sul frontend qui sotto |
| `/dr-scaffold` | Nessun indizio: ti mostra i domini disponibili e chiede quale |

Tipologie di progetto e pacchetti non sono scritti nella skill: arrivano dal catalogo [`scaffolding-catalog.json`](../scaffolding-catalog.json).

> **Nota sul frontend Vue.** Il catalogo chiede di creare il frontend **prima** di installare il core, perché `create-vue` scrive propri `.editorconfig`, `.gitignore` e `.gitattributes`. In questa guida il core è già installato al passo 3. `npm create vue@latest <nome>` scrive in una sottocartella nuova, quindi i due gruppi di file non dovrebbero scontrarsi, ma il percorso non è ancora stato provato sul campo. Se vuoi andare sul sicuro al primo progetto, parti dal solo backend e aggiungi il frontend dopo.

### Cosa succede, in ordine

| # | Fase | Cosa fa | Ti chiede qualcosa? |
|---|---|---|---|
| 1 | Dominio | Capisce dalla tua frase quale dominio serve (.NET, frontend, DevOps) | Solo se la richiesta è generica |
| 2 | Prerequisiti | Controlla gli strumenti del dominio scelto | No, si ferma se manca qualcosa |
| 3 | Stato cartella | Vede che manca la solution e passa a `/dr-scaffold-solution` | Può chiederti conferma per creare la solution |
| 4 | Domande | Nome della solution, tipologie di progetto e loro nomi, pacchetti per repository | Sì, tutte insieme |
| 5 | Anteprima | Mostra l'albero di cartelle e i comandi che eseguirà | **Una sola conferma** |
| 6 | Esecuzione | `dotnet new sln` → progetti in `src/` e `test/` → aggancio alla solution → frontend → `git init` + commit → pacchetti `dr-*` → `dotnet format` | No |

### Le domande del punto 4

Alcune possono arrivare già decise dal passaggio precedente: in quel caso la skill te le mostra come acquisite invece di richiederle.

| Domanda | Risposta tipica |
|---|---|
| Workspace multi-repo? | **No**, al primo progetto. Serve solo se frontend e backend staranno in repository git separati |
| Nome della solution | Proposto: nome della cartella in minuscolo |
| Formato | `slnx`, il default dell'SDK 10. `sln` solo per Visual Studio più vecchio |
| Tipologie di progetto | Minimal API, Worker/Windows Service, class library, test xUnit, frontend Vue |
| Nomi dei progetti | Proposti con suffisso: `ordini.api`, `ordini.service`, `ordini.tests`, `ordini-fe` |
| Pacchetti `dr-*` | Già preselezionati in base alle tipologie. `dr-efdb` e `dr-devops` sono opzionali |

I nomi devono iniziare con una lettera e contenere solo lettere, cifre, `.`, `_`, `-` (massimo 64 caratteri). Niente spazi.

Le dipendenze tra pacchetti non le scegli tu: `dr-minimalapi` e `dr-winsvc` si portano dietro `dr-dotnet-backend` da soli.

---

## ✔️ Passo 6 — Controlla il risultato

La skill esegue queste verifiche da sola e si ferma alla prima che fallisce. Puoi ripeterle quando vuoi:

| Comando | Cosa devi vedere |
|---|---|
| `dotnet sln ordini.slnx list` | Tutti i progetti elencati |
| `dotnet build ordini.slnx --nologo` | `Avvisi: 0  Errori: 0` |
| `Get-Content .ai\dr-guidelines-packages.json` | Una voce per ogni pacchetto installato, con la data di oggi |
| `git status --short` | `.mcp.json` **non** compare: è ignorato apposta, può contenere credenziali |
| `dotnet format ordini.slnx --verify-no-changes` | Exit code `0` |

---

## ➡️ E adesso

| Vuoi… | Usa |
|---|---|
| Profili di avvio e debug in VS Code | `/dr-CreateLaunchProfiles` |
| Aggiungere un progetto alla solution | `/dr-scaffold aggiungi un worker` |
| Aggiornare le linee guida più avanti | `/dr-get-latest` |
| Leggere la struttura interna di una Minimal API | [`scaffolding-minimal-api.md`](scaffolding-minimal-api.md) |
| Leggere la struttura interna di un Windows Service | [`scaffolding-windows-service.md`](scaffolding-windows-service.md) |
| Segnalare un errore nelle linee guida | `/dr-segnala-miglioria <descrizione>` |

Se hai scelto `dr-efdb`, la skill propone di registrare il server MCP `db-schema` in `.mcp.json`. Senza quel server lo scaffolding CRUD deve chiederti i campi della tabella a mano.

**Cosa non fa lo scaffolding:** non crea il repository remoto e non fa `git push`. Il primo push lo fai tu, quando vuoi.

---

## 🔧 Se il progetto esiste già

La procedura cambia poco:

1. Dalla **root del repository** (deve contenere `.git`), installa il core con il comando del passo 3
2. Ricarica la finestra
3. Scrivi `/dr-scaffold-guidelines`: propone i pacchetti adatti allo stack che trova e segna quelli già installati

L'installer non sovrascrive i file: uno già presente viene saltato con `[SKIP]`. Uniche modifiche a file esistenti: le voci mancanti in `.claude/settings.json`, la sezione `<!-- dr-guidelines -->` in `CLAUDE.md` e il manifest `.ai/dr-guidelines-packages.json`, riscritto a ogni esecuzione. Il resto resta intatto.

---

## 🆘 Se qualcosa va storto

| Sintomo | Causa | Cosa fare |
|---|---|---|
| `404` scaricando l'installer | Hai usato `irm https://raw.githubusercontent.com/...` su un repo Private | Usa la forma `gh api` del passo 3 |
| `gh` non riconosciuto, richiesta di `gh auth login`, oppure `Not Found (HTTP 404)` da `gh api` | `gh` non installato, non autenticato, o account senza accesso ai repo `dr-*` | Installa `gh`, esegui `gh auth login` con scope `repo`, poi riprova. Il comando non scrive niente finché il download non riesce |
| `git clone fallito per davraf-amuro/...` | git non ha le credenziali per i repo Private | `gh auth setup-git`, poi riprova |
| La riga `Progetto:` mostra la cartella sbagliata | Mancava `Set-Location` | Annulla (riga sotto) e rilancia dalla cartella giusta |
| `/dr-scaffold` non compare | Le skill si leggono all'avvio | `Developer: Reload Window` |
| Ogni comando `dotnet` fallisce dopo l'installazione | `global.json` di `dr-dotnet-backend` richiede l'SDK 10 | `dotnet --list-sdks`: installa l'SDK 10 |
| `Nessun pacchetto dr-* copre ...` | Nessun pacchetto per quel dominio | Scegli se proseguire con il solo core o aprire una issue: la skill te lo propone |
| Hai corretto un pacchetto `dr-*` ma nel progetto non cambia niente | La correzione non è pushata su `main` | Push nel repo del pacchetto, poi `/dr-get-latest` |

### Tornare indietro

**Dopo il commit iniziale** (passo 5 completato o quasi):

```powershell
git clean -fd          # rimuove i file non tracciati aggiunti dopo il commit
git checkout -- .      # ripristina i file tracciati modificati
```

**Prima del commit iniziale** (per esempio subito dopo il passo 3): la cartella non è ancora un repository. Il modo più semplice è cancellarla e ripartire dal passo 2.

> ⚠️ **Cancellare la cartella è irreversibile.** Controlla il percorso con `Get-Location` prima di eseguire `Remove-Item <cartella> -Recurse -Force`.

---

## 🧪 Cosa è stato provato sul campo

Questa guida unisce passaggi eseguiti davvero e passaggi descritti a partire dalle skill. La tabella dice quali sono quali.

| Passo | Stato |
|---|---|
| 1 — Prerequisiti | ✅ Verificato il 2026-08-12 |
| 2 — Cartella vuota fuori dal workspace `dr-*` | ✅ Verificato il 2026-08-12 |
| 3 — Installazione del core con `gh api` su repo Private | ⚠️ Verificato il 2026-08-12 con la versione precedente dell'installer. Il 2026-09-16 (`aee84a4`) la libreria è stata riscritta: catalogo come fonte dei pacchetti, `rootFiles`. ☐ Da riverificare |
| 4 — Le skill compaiono dopo il reload | ☐ Da verificare |
| 5 — `/dr-scaffold` da cartella con solo il core fino alla solution | ☐ Da verificare |
| 5 — Dipendenza `dr-dotnet-backend` installata in automatico | ☐ Da verificare |
| 6 — Verifiche finali | ☐ Da verificare |
| Workspace multi-repo partendo da una cartella con il core | ☐ Da verificare: il core resta anche nella cartella che contiene il `.code-workspace` |
| Frontend Vue con il core già installato nella cartella | ☐ Da verificare: vedi la nota sul frontend al passo 5 |
| `/dr-scaffold-solution` su una cartella che contiene già il core | ☐ Da verificare: la skill si ferma se una cartella di destinazione è già popolata. Va confermato che i file del core non facciano scattare il blocco |

Il taccuino delle prove, con esiti e correzioni, è [`bozza-manuale-installazione.md`](bozza-manuale-installazione.md).

---

*Revisione v1.0 — 2026-09-16 16:12 — claude-opus-5*
