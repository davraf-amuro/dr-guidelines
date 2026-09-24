# Onboarding — dr-guidelines

## 1. Il progetto in tre righe

`dr-guidelines` è il pacchetto **core** e il **catalogo** della suite `dr-*`: istruzioni, prompt e skill per Claude Code e GitHub Copilot, validi per qualsiasi stack. Non ha un entrypoint applicativo: si **installa** in un progetto host con `dr-guidelines-install.ps1`, che clona il pacchetto in `%TEMP%` e ne copia i file nella root del repository. Le regole di dominio (Minimal API, Windows Service, EF Core, frontend, DevOps) vivono in sei pacchetti separati, elencati in `scaffolding-catalog.json`.

---

## 2. Stack e scelte tecniche

| Tecnologia | Versione | Motivo |
|---|---|---|
| PowerShell | 7+ | Installer scritto solo in PowerShell. Richiede `git` per clonare i pacchetti e, su repo Private, `gh` per scaricare installer, libreria e catalogo |
| Markdown | — | Formato leggibile sia da Claude Code che da GitHub Copilot |
| JSON (`scaffolding-catalog.json`) | `schemaVersion: 2` | **Unica fonte** di pacchetti, domini, intenti e tipologie di progetto. L'installer costruisce il registry da qui, le skill `dr-scaffold*` leggono da qui |
| `gh` CLI | — | Bootstrap su repo Private: `gh api` scarica installer, libreria e catalogo senza clone locale |
| Claude Code skills | — | Automazione dei task ripetitivi: scaffolding, documentazione, audit, promozione branch |
| GitHub Copilot instructions e prompt | — | Stesse regole sull'altro agente: la compatibilità duale è una regola di progetto |

**Perché pacchetti e non submodule:** il submodule imponeva tutto il contenuto a ogni host e legava l'aggiornamento a `git submodule update`. Con i pacchetti, ogni repository installa solo ciò che serve al suo dominio e registra cosa ha installato, con il commit di provenienza, in `.ai/dr-guidelines-packages.json`.

**Perché il core non è .NET:** `Directory.Build.props` e `global.json` stanno in `dr-dotnet-backend`, dichiarati come `rootFiles` nel catalogo. Un frontend, un firmware o una raccolta di documenti non li riceve.

---

## 3. Come si usa

Questo repository non si avvia: si installa in un altro progetto.

**Nuovo progetto da zero:** segui [`guida-nuova-soluzione.md`](guida-nuova-soluzione.md). In sintesi: cartella vuota → installa il core → `Developer: Reload Window` → `/dr-scaffold <richiesta>`.

**Progetto esistente**, dalla root del repository host:

```powershell
& ([scriptblock]::Create((gh api repos/davraf-amuro/dr-guidelines/contents/dr-guidelines-install.ps1 -H "Accept: application/vnd.github.raw" | Out-String)))
```

I repo `dr-*` sono **Public** dal 2026-09-21: `irm https://raw.githubusercontent.com/... | iex` funziona, ma su un repo Private risponderebbe `404`. La forma `gh api` funziona in entrambi i casi.

**Flag dell'installer:**

| Flag | Effetto |
|---|---|
| nessuno | Installa il core nella cartella corrente, salta i file già presenti |
| `-Update` | Sovrascrive i file presenti e riscrive la sezione `<!-- dr-guidelines -->` di `CLAUDE.md` |
| `-Package <nome>` | Installa un pacchetto di dominio al posto del core, con le dipendenze mancanti |
| `-Global` | Scrive la sezione linee guida in `~/.claude/CLAUDE.md`, non tocca il progetto. Incompatibile con `-Package` |

**Da sapere prima di toccare l'installer:**

- `Install-DrPackage` fa **sempre** `git clone --depth 1` del `main` da github.com, anche se l'installer è lanciato da un clone locale. Una modifica non pushata non arriva mai in un host.
- Il clone locale serve solo a trovare, tramite `$PSScriptRoot`, la libreria `dr-guidelines-install-lib.ps1`, il catalogo e il template di `-Global`. Il contenuto dei pacchetti arriva comunque dal clone temporaneo.

---

## 4. Struttura del codice

```
dr-guidelines/
  .ai/plans/            ← Piani di lavoro su disco (plan-tracking)
  .claude/
    settings.json       ← Permessi condivisi, fusi nel settings.json dell'host
    skills/             ← Skill Claude Code, una cartella per skill con SKILL.md
  .github/
    ISSUE_TEMPLATE/     ← miglioria.md, problema.md e nuovo-pacchetto.md, usati da /dr-file-feedback
    instructions/       ← Istruzioni modulari trasversali (.instructions.md)
    prompts/            ← Prompt duali: documentazione, scaffolding, segnalazioni
    workflows/ci.yml    ← Job build-and-test e catalog-guard
    copilot-instructions.md   ← Entry point Copilot: individua il dominio dai pacchetti installati
  .template.config/     ← Template dotnet new (Davraf.Guidelines)
  docs/                 ← Guide, onboarding, card, scaffolding per tipologia
  templates/
    global-claude.md    ← Contenuto della sezione scritta in ~/.claude/CLAUDE.md
  dr-guidelines-install.ps1      ← Entrypoint: carica la libreria, gestisce -Update, -Global, -Package
  dr-guidelines-install-lib.ps1  ← Get-DrCatalog, Get-DrPackageRegistry, Install-DrPackage, Install-DrGlobal
  scaffolding-catalog.json       ← Catalogo: kinds, domains, intentMap, fallback, projectTypes, packages
  CLAUDE.md             ← Istruzioni Claude Code; il corpo diventa la sezione iniettata negli host
  .editorconfig, .gitignore, .gitattributes   ← Copiati negli host
  .mcp.example.json     ← Server MCP consigliati; la config reale è .mcp.json, ignorato da git
```

**Dove vivono le cose che tocchi più spesso:**

| Cosa modificare | Dove |
|---|---|
| Nuova istruzione trasversale | `.github/instructions/<nome>.instructions.md` |
| Nuova skill Claude Code | `.claude/skills/dr-<nome>/SKILL.md` (prefisso `dr-` obbligatorio) |
| Nuovo prompt Copilot | `.github/prompts/<nome>.prompt.md` |
| Nuovo pacchetto, dominio o tipologia di progetto | Solo `scaffolding-catalog.json`. L'installer non va toccato |
| Contenuto delle linee guida globali | `templates/global-claude.md`, poi `/dr-install-global aggiorna` |
| File distribuiti agli host | Root del repository, poi `-Update` o `/dr-get-latest` negli host |

> ⚠️ **CI da allineare.** Il job `catalog-guard` di `ci.yml` confronta ancora il catalogo con `$Script:PackageRegistry`, cioè il doppio registry precedente. Ora la libreria costruisce il registry dal catalogo solo quando serve, quindi il job non trova il valore. La CI del push del 2026-09-16 (`aee84a4`) risulta fallita su `catalog-guard`; `build-and-test` passa.

---

## 5. Convenzioni obbligatorie

Ricavate da `.github/instructions/`, `.github/copilot-instructions.md` e `CLAUDE.md`:

| Regola | Fonte |
|---|---|
| Ogni regola o documento condiviso deve funzionare con Claude Code **e** GitHub Copilot. Esenti solo i file in `.claude/skills/` | `CLAUDE.md` |
| Prima di scrivere codice: leggi le istruzioni, dichiara scope e perimetro negativo | `CLAUDE.md`, `dev-cycle.instructions.md` |
| Task con ≥ 2 operazioni: piano su disco in `.ai/plans/<YYYY-MM-DD>-<slug>/` e approvazione | `plan-tracking.instructions.md` |
| Skill nuove con prefisso `dr-` | `CLAUDE.md` globale |
| Footer obbligatorio nei file `docs/`: `*Revisione vN — YYYY-MM-DD HH:MM — modello*` | `doc-versioning.instructions.md` |
| Struttura del `README.md` fissa in 12 sezioni | `readme-structure.instructions.md` |
| Dati sensibili mai in file committati; `.mcp.json` ignorato, `.mcp.example.json` committato | `sensitive-data.instructions.md` |
| MCP server: cerca prima di creare; repo dedicato `mcp-<dominio>` | `mcp-server-discovery.instructions.md` |
| Nessun `git push` senza verifica pulita, o senza dichiarare che non c'è un comando di verifica | `copilot-instructions.md` — Gate di Push |

---

## 6. Flusso di lavoro

**Branch:** `main` è il branch principale e quello che gli host installano. Branch di lavoro temporanei si promuovono con `/dr-promote-to main`.

**Aggiungere un'istruzione trasversale:**
1. Crea `.github/instructions/<nome>.instructions.md` con frontmatter `applyTo`
2. Aggiungi la riga in "Istruzioni Modulari" del `README.md`
3. Verifica che sia leggibile da entrambi gli agenti

**Aggiungere una skill:**
1. Crea `.claude/skills/dr-<nome>/SKILL.md`
2. Aggiungi la voce H3 in "Claude Code Skills" del `README.md`
3. Aggiungi la riga alla tabella di invocazione automatica in `CLAUDE.md`
4. Se la capacità serve anche su Copilot, aggiungi il prompt in `.github/prompts/`

**Aggiungere un pacchetto di dominio:** crea il repo `davraf-amuro/dr-<nome>` con il proprio `dr-<nome>-install.ps1` e le cartelle `.github/` e `.claude/`, poi aggiungi le voci `packages`, `domains`, `intentMap` (ed eventualmente `kinds`) al catalogo. L'installer accetta solo repository dell'owner `davraf-amuro`.

**Provare una modifica in un host:**
1. Push su `main` del repo modificato
2. Nell'host: `/dr-get-latest`, oppure l'installer del pacchetto con `-Update`

La procedura completa di collaudo è in [`test-progetto-host.md`](test-progetto-host.md).

**Modificare le linee guida globali:**
1. Modifica `templates/global-claude.md`, commit e push
2. `/dr-install-global aggiorna`

Riscrive solo il blocco tra `## Davraf Guidelines (Globale)` e `<!-- /davraf-guidelines -->`.

**Gate di push:** questo repository non ha un comando di lint. Prima del push dichiaralo esplicitamente, come richiesto dal Gate di Push.

---

## 7. Dati sensibili e configurazione locale

Il repository non contiene dati sensibili committati. Se aggiungi un MCP server con autenticazione:

- configurazione reale → `.mcp.json`, ignorato da git
- placeholder committato → `.mcp.example.json`

Dettagli: `.github/instructions/sensitive-data.instructions.md`.

---

## 8. Dove chiedere / cosa leggere dopo

| Risorsa | Scopo |
|---|---|
| `README.md` | Pacchetti, installazione, skill, FAQ |
| [`guida-nuova-soluzione.md`](guida-nuova-soluzione.md) | Percorso utente dalla cartella vuota alla solution |
| [`bozza-manuale-installazione.md`](bozza-manuale-installazione.md) | Cosa è stato provato sul campo e cosa no |
| [`test-progetto-host.md`](test-progetto-host.md) | Collaudo dell'installer su un progetto di prova |
| `.github/copilot-instructions.md` | Regole trasversali, punto di partenza di ogni task AI |
| `.github/instructions/dev-cycle.instructions.md` | Ciclo obbligatorio: dichiara → esegui → verifica |
| `.github/instructions/plan-tracking.instructions.md` | Struttura dei piani in `.ai/plans/` |
| `scaffolding-catalog.json` | Pacchetti, domini, tipologie di progetto |
| Issue su `davraf-amuro/dr-guidelines` | Richieste di nuovi pacchetti e problemi del core, via `/dr-file-feedback` |

---

*Revisione v3.3 — 2026-09-23 09:15 — claude-opus-5*
