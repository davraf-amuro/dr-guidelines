# Onboarding — dr-guidelines

## 1. Il progetto in tre righe

`dr-guidelines` è il pacchetto **core** della suite `dr-*`: linee guida, istruzioni modulari, prompt e skill per Claude Code e GitHub Copilot. Non si usa come submodule e non ha un entrypoint applicativo: si **installa** in un progetto host con `dr-guidelines-install.ps1`, che clona il pacchetto e ne copia i file nella root del repository. I contenuti specifici di dominio (Minimal API, Windows Service, EF Core, frontend, DevOps) vivono in sei pacchetti separati, installabili allo stesso modo.

---

## 2. Stack e scelte tecniche

| Tecnologia | Versione | Motivo |
|---|---|---|
| PowerShell | 7+ | Installer senza dipendenze esterne; `pwsh` è un prerequisito verificato prima di scrivere |
| Markdown | — | Formato leggibile sia da Claude Code che da GitHub Copilot |
| Pacchetti installabili | — | Un progetto host installa solo i pacchetti pertinenti al proprio stack, invece di importare tutto |
| JSON (`scaffolding-catalog.json`) | schema v1 | Tipologie di progetto e pacchetti come dato, non come testo duplicato in ogni skill |
| Claude Code skills | — | Automazione dei task ripetitivi (doc, audit, scaffolding, promozione branch) |
| GitHub Copilot instructions | — | Stesse convenzioni sull'altro agente: la compatibilità duale è una regola di progetto |

**Perché non più submodule:** il submodule imponeva l'intero contenuto a ogni progetto host e legava l'aggiornamento a un `git submodule update`. Con i pacchetti, ogni repository dichiara cosa ha installato in `.ai/dr-guidelines-packages.json` e aggiorna solo quello.

---

## 3. Come si usa

Questo repository non si avvia: si installa, oppure genera struttura in un altro progetto.

**Nuovo progetto da zero** — apri in VS Code la cartella di destinazione e invoca lo scaffolding guidato (nessuno script da scaricare a mano):

```
/dr-scaffold
```

Rileva lo stato della cartella e delega al pezzo giusto: solution da zero, aggiunta di un progetto, o sola installazione dei pacchetti. Con GitHub Copilot lo stesso flusso è in `.github/prompts/dr-scaffold.prompt.md`. Tipologie e pacchetti si leggono da `scaffolding-catalog.json`.

**Progetto esistente** — dalla root del repository host:

```powershell
irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1 | iex
```

> Finché i repo `dr-*` sono **Private**, `raw.githubusercontent.com` risponde `404`. Il bootstrap funziona lo stesso passando da `gh`, che è autenticato e legge i Private:
>
> ```powershell
> & ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
> ```
>
> In alternativa, se hai già il clone: `& <workspace>\dr-guidelines\dr-guidelines-install.ps1`, eseguito dalla root del repo host.

**Linee guida su tutto il PC** — scrive la sezione in `~/.claude/CLAUDE.md`, che Claude Code carica in ogni sessione:

```
/dr-install-global
```

Equivalente da riga di comando: `dr-guidelines-install.ps1 -Global`. Non sostituisce l'installazione nel progetto: le regole globali sono trasversali, e in caso di conflitto ha precedenza il `CLAUDE.md` del progetto aperto.

**Aggiornare** — un pacchetto alla volta con `<pacchetto>-install.ps1 -Update`, tutti quelli tracciati nel manifest con `/dr-get-latest`, la sezione globale con `/dr-install-global aggiorna`.

---

## 4. Struttura del codice

```
dr-guidelines/
  .claude/
    skills/           ← Skill Claude Code, una cartella per skill con SKILL.md
  .github/
    instructions/     ← Istruzioni modulari per Copilot e Claude Code (.instructions.md)
    prompts/          ← Prompt duali: generazione doc e scaffolding (.prompt.md)
    workflows/        ← CI, incluso il job catalog-guard
    copilot-instructions.md   ← Entry point istruzioni Copilot (letto automaticamente dall'IDE)
  docs/               ← Documentazione (card progetto, onboarding, scaffolding per tipologia)
  templates/
    global-claude.md  ← Contenuto della sezione scritta in ~/.claude/CLAUDE.md
  dr-guidelines-install.ps1      ← Entrypoint: installa il core nel progetto host; -Update, -Global
  dr-guidelines-install-lib.ps1  ← Registry pacchetti dr-*, Install-DrPackage, Install-DrGlobal
  scaffolding-catalog.json  ← Catalogo tipologie di progetto e pacchetti, letto da skill e prompt
  CLAUDE.md           ← Istruzioni Claude Code per questo repository
  .editorconfig       ← Naming conventions e stile codice
  Directory.Build.props  ← Configurazione MSBuild centralizzata (.NET 10, Nullable)
  global.json         ← Versione .NET SDK fissata
  .mcp.example.json   ← Server MCP consigliati — la config reale va in `.mcp.json`, in `.gitignore`
```

`Directory.Build.props` e `global.json` vengono copiati **solo** in un host .NET: in un repo frontend sarebbero file inerti, e l'installer li salta dichiarandolo (`[SKIP] ... (host non .NET)`).

**Dove vivono le cose che tocchi più spesso:**

| Cosa modificare | Dove |
|---|---|
| Nuova istruzione AI | `.github/instructions/<nome>.instructions.md` |
| Nuova skill Claude Code | `.claude/skills/<nome>/SKILL.md` |
| Nuovo template documentazione | `.github/prompts/<nome>.prompt.md` |
| Contenuto delle linee guida globali | `templates/global-claude.md` (poi `/dr-install-global aggiorna` per propagare) |
| Nuova tipologia di progetto o pacchetto | `scaffolding-catalog.json` **e** `$Script:PackageRegistry` in `dr-guidelines-install-lib.ps1` — il job CI `catalog-guard` fallisce se divergono |
| File distribuiti ai progetti host | Root del repository (poi `<pacchetto>-install.ps1 -Update` negli host) |

---

## 5. Convenzioni obbligatorie

Ricavate da `.github/instructions/` e `CLAUDE.md`:

| Regola | Fonte |
|---|---|
| Ogni modifica richiede piano approvato (`EnterPlanMode` → `ExitPlanMode`) | `CLAUDE.md` |
| Ogni nuova regola deve essere compatibile con Claude Code **e** GitHub Copilot; esenzione solo per `.claude/skills/` | `CLAUDE.md` |
| Task con ≥ 2 operazioni: crea piano su disco in `.ai/plans/<YYYY-MM-DD>-<slug>/` | `plan-tracking.instructions.md` |
| Footer obbligatorio nei file `docs/`: `*Revisione vN — YYYY-MM-DD HH:MM — modello*` | `doc-versioning.instructions.md` |
| Dati sensibili mai in file committati — solo placeholder | `sensitive-data.instructions.md` |
| `.mcp.json` con credenziali → in `.gitignore`; committare `.mcp.example.json` | `sensitive-data.instructions.md` |
| MCP server: cerca prima di creare; repo dedicato `mcp-<dominio>` | `mcp-server-discovery.instructions.md` |
| Nuova skill aggiunta: aggiorna sezione "Claude Code Skills" in `README.md` | `readme-structure.instructions.md` |
| Nuova istruzione aggiunta: aggiorna tabella "Istruzioni Modulari" in `README.md` | `readme-structure.instructions.md` |
| Nessun `git push` senza lint clean | `copilot-instructions.md` — Gate di Push |

---

## 6. Flusso di lavoro

**Branch:** `main` come branch principale; branch di lavoro temporanei (es. `fix/<slug>`) promossi verso `main` con la skill `/dr-promote-to`.

**Aggiungere un'istruzione modulare:**
1. Crea `.github/instructions/<nome>.instructions.md` con frontmatter `applyTo: "**"`
2. Aggiungi la riga nella sezione "Istruzioni Modulari" del `README.md`
3. Verifica la compatibilità con entrambi gli agenti (Copilot + Claude Code)

**Aggiungere una skill Claude Code:**
1. Crea `.claude/skills/<nome>/SKILL.md` — maiuscolo, come le altre
2. Aggiungi la voce H3 nella sezione "Claude Code Skills" del `README.md`
3. Aggiungi la riga alla tabella di invocazione automatica in `CLAUDE.md`
4. Se la skill copre una capacità utile anche su Copilot, aggiungi il prompt duale in `.github/prompts/`

**Aggiornare le guidelines in un progetto host:**
```powershell
Push-Location <root-repo-host>
& <workspace>\dr-guidelines\dr-guidelines-install.ps1 -Update
Pop-Location
```

`-Update` sovrascrive i file di configurazione già presenti con la versione aggiornata. `CLAUDE.md` non viene mai sovrascritto per intero: viene riscritta solo la sezione tra `<!-- dr-guidelines -->` e `<!-- /dr-guidelines -->`, le sezioni specifiche del progetto restano.

`Install-DrPackage` usa la **directory corrente** come root dell'host: `Push-Location`/`Pop-Location` non sono cerimoniali, decidono dove finiscono i file.

**Modificare le linee guida globali e propagarle:**
1. Modifica `templates/global-claude.md` e committa
2. Da qualsiasi clone aggiornato del repository:
```
/dr-install-global aggiorna
```
Riscrive solo il blocco tra `## Davraf Guidelines (Globale)` e `<!-- /davraf-guidelines -->`; il resto di `~/.claude/CLAUDE.md` resta intatto.

**Aggiungere una tipologia di progetto o un pacchetto:** aggiorna `scaffolding-catalog.json` **e** `$Script:PackageRegistry` in `dr-guidelines-install-lib.ps1`. Sono due copie della stessa informazione per scelta esplicita — il job CI `catalog-guard` confronta nomi, `repo`, `isCore` e dipendenze e fallisce sulla divergenza.

---

## 7. Dati sensibili e configurazione locale

Questo repository non contiene dati sensibili committati. Se si aggiunge un MCP server con autenticazione:
- Configurazione reale → `.mcp.json` (in `.gitignore`)
- Placeholder committato → `.mcp.example.json`

Dettagli: `.github/instructions/sensitive-data.instructions.md`

---

## 8. Dove chiedere / cosa leggere dopo

| Risorsa | Scopo |
|---|---|
| `README.md` | Guida completa: pacchetti, installazione, skill, FAQ |
| `.github/copilot-instructions.md` | Convenzioni .NET 10 — punto di partenza per qualsiasi task AI |
| `.github/instructions/dev-cycle.instructions.md` | Ciclo obbligatorio per ogni task: dichiara → esegui → verifica |
| `.github/instructions/plan-tracking.instructions.md` | Struttura dei piani in `.ai/plans/` per task con ≥ 2 operazioni |
| `.github/instructions/code-organization.instructions.md` | Organizzazione classi e file (tutti i linguaggi) |
| `.github/instructions/sensitive-data.instructions.md` | Gestione credenziali e file locali |
| `docs/card-dr-guidelines.md` | Scheda riassuntiva del progetto |
| `docs/test-progetto-host.md` | Procedura di test end-to-end dell'installer su un progetto host di prova |
| `scaffolding-catalog.json` | Tipologie di progetto e pacchetti disponibili |

---

*Revisione v3.1 — 2026-08-09 11:40 — claude-opus-5*
