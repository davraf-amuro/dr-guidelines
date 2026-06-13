# Onboarding — davraf-guidelines

## 1. Il progetto in tre righe

`davraf-guidelines` è un repository di linee guida e configurazioni per progetti .NET 10. Si usa come **git submodule**: `setup.ps1` copia i file di configurazione nel progetto host e installa `.claude/skills/` e `.github/`. Contiene skill per Claude Code, istruzioni per GitHub Copilot e template per la generazione automatica di documentazione.

---

## 2. Stack e scelte tecniche

| Tecnologia | Versione | Motivo |
|---|---|---|
| PowerShell | 5.1+ / 7+ | Script di setup cross-platform senza dipendenze esterne |
| Markdown | — | Formato leggibile sia da Claude Code che da GitHub Copilot |
| Git submodule | — | Aggiornamenti centralizzati propagabili via `git submodule update --remote` |
| Claude Code skills | — | Standard di progetto — automazione task ripetitivi (doc, audit, promozione branch) |
| GitHub Copilot instructions | — | Standard di progetto — guida il modello su convenzioni .NET 10 |

---

## 3. Come avviare il progetto

Questo repository non ha un entrypoint applicativo. Si usa in due modi:

**Nuovo progetto:**
```powershell
irm https://raw.githubusercontent.com/davraf-amuro/davraf-guidelines/main/CreateNewSolution.ps1 | iex
```

**Progetto esistente:**
```powershell
git submodule add https://github.com/davraf-amuro/davraf-guidelines.git davraf-guidelines
.\davraf-guidelines\setup.ps1
```

**Aggiornare le guidelines in un progetto host:**
```powershell
git submodule update --remote davraf-guidelines
.\davraf-guidelines\setup.ps1 -Update
```

---

## 4. Struttura del codice

```
davraf-guidelines/
  .claude/
    skills/           ← Skill Claude Code (warroom, professor, tattico, tech, audit-api, audit-fe, promote-to, get-latest)
  .github/
    instructions/     ← Istruzioni modulari per Copilot e Claude Code (.instructions.md)
    prompts/          ← Template per generazione documentazione (card, onboarding, README, endpoints)
    copilot-instructions.md   ← Entry point istruzioni Copilot (letto automaticamente dall'IDE)
  docs/               ← Documentazione generata (card progetto, wiki card, onboarding)
  setup.ps1           ← Copia file di configurazione nel progetto host
  CreateNewSolution.ps1  ← Bootstrap nuovo progetto da zero
  CLAUDE.md           ← Istruzioni Claude Code per questo repository
  .editorconfig       ← Naming conventions e stile codice
  Directory.Build.props  ← Configurazione MSBuild centralizzata (.NET 10, Nullable)
  global.json         ← Versione .NET SDK fissata
  .mcp.json           ← Server MCP consigliati (pdf-reader)
```

**Dove vivono le cose che tocchi più spesso:**

| Cosa modificare | Dove |
|---|---|
| Nuova istruzione AI | `.github/instructions/<nome>.instructions.md` |
| Nuova skill Claude Code | `.claude/skills/<nome>/SKILL.md` |
| Nuovo template documentazione | `.github/prompts/<nome>.prompt.md` |
| File distribuiti da setup.ps1 | Root del repository (poi `setup.ps1 -Update` nei progetti host) |

---

## 5. Convenzioni obbligatorie

Ricavate da `.github/instructions/` e `CLAUDE.md`:

| Regola | Fonte |
|---|---|
| Ogni modifica richiede piano approvato (`EnterPlanMode` → `ExitPlanMode`) | `CLAUDE.md` |
| Ogni nuova regola deve essere compatibile con Claude Code **e** GitHub Copilot | `CLAUDE.md` |
| Task con ≥ 2 operazioni: crea piano su disco in `.ai/plans/<YYYY-MM-DD>-<slug>/` | `plan-tracking.instructions.md` |
| Footer obbligatorio nei file `docs/`: `*Revisione vN — YYYY-MM-DD HH:MM — modello*` | `doc-versioning.instructions.md` |
| Dati sensibili mai in file committati — solo placeholder | `sensitive-data.instructions.md` |
| `.mcp.json` con credenziali → in `.gitignore`; committare `.mcp.example.json` | `sensitive-data.instructions.md` |
| MCP server: cerca prima di creare; repo dedicato `mcp-<dominio>` | `mcp-server-discovery.instructions.md` |
| Nuova skill aggiunta: aggiorna sezione "Claude Code Skills" in `README.md` | `readme-structure.instructions.md` |
| Nuova istruzione aggiunta: aggiorna tabella "Istruzioni Modulari" in `README.md` | `readme-structure.instructions.md` |

---

## 6. Flusso di lavoro

**Branch:** Solo `main`. Nessuna branch strategy definita.

**Aggiungere un'istruzione modulare:**
1. Crea `.github/instructions/<nome>.instructions.md` con frontmatter `applyTo: "**"`
2. Aggiungi riga nella sezione "Istruzioni Modulari" del `README.md`
3. Verifica compatibilità con entrambi gli agenti AI (Copilot + Claude Code)

**Aggiungere una skill Claude Code:**
1. Crea `.claude/skills/<nome>/SKILL.md`
2. Aggiungi voce H3 nella sezione "Claude Code Skills" del `README.md`
3. Aggiungi voce alla tabella di invocazione automatica in `CLAUDE.md`

**Aggiornare le guidelines in un progetto host:**
```powershell
git submodule update --remote davraf-guidelines
.\davraf-guidelines\setup.ps1 -Update
```

Il flag `-Update` sovrascrive i file di configurazione già presenti (`.editorconfig`, `Directory.Build.props`, `.github/`, ecc.) con la versione aggiornata. `CLAUDE.md` non viene mai sovrascritto automaticamente (la sezione `## Davraf Guidelines` viene aggiornata, le sezioni specifiche del progetto sono preservate).

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
| `.github/copilot-instructions.md` | Convenzioni .NET 10 — punto di partenza per qualsiasi task AI |
| `.github/instructions/dev-cycle.instructions.md` | Ciclo obbligatorio per ogni task: dichiara → esegui → verifica |
| `.github/instructions/plan-tracking.instructions.md` | Struttura piani in `.ai/plans/` per task con ≥ 2 operazioni |
| `.github/instructions/minimal-api-architecture.instructions.md` | Architettura endpoint, Service layer, Filter + Projection |
| `.github/instructions/code-organization.instructions.md` | Organizzazione classi e file (tutti i linguaggi) |
| `.github/instructions/sensitive-data.instructions.md` | Gestione credenziali e file locali |
| `docs/card-davraf-guidelines.md` | Scheda riassuntiva del progetto |
| `README.md` | Guida completa all'uso come submodule |

---

*Revisione v2.0 — 2026-06-13 15:30 — claude-sonnet-4-6*
