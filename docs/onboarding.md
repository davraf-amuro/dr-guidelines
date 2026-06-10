# Onboarding — davraf-guidelines

## 1. Il progetto in tre righe

`davraf-guidelines` è un repository di linee guida e configurazioni per progetti .NET 10 Minimal API. Si usa come **git submodule**: lo script `setup.ps1` copia i file di configurazione nel progetto host e collega `.github/` via junction. Contiene anche skill per Claude Code e istruzioni per GitHub Copilot.

---

## 2. Stack e scelte tecniche

| Tecnologia | Versione | Motivo |
|---|---|---|
| PowerShell | 5.1+ / 7+ | Script di setup e automazione cross-platform |
| Markdown | — | Istruzioni AI-readable e documentazione |
| Git submodule | — | Permette aggiornamenti centralizzati nelle guidelines |
| Claude Code skills | — | Standard di progetto — automazione task ripetitivi |
| GitHub Copilot instructions | — | Standard di progetto — guida AI su convenzioni .NET 10 |

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

**Aggiornare guidelines:**
```powershell
git submodule update --remote davraf-guidelines
.\davraf-guidelines\setup.ps1 -Update
```

---

## 4. Struttura del codice

```
davraf-guidelines/
  .claude/
    skills/           ← Skill Claude Code (warroom, professor, tattico, tech, audit-*, promote-to, get-latest)
  .github/
    instructions/     ← Istruzioni modulari per Copilot e Claude Code (.instructions.md)
    prompts/          ← Template prompt per generazione documentazione
    copilot-instructions.md   ← Entry point istruzioni Copilot (letto automaticamente)
  docs/               ← Documentazione generata (card progetto, onboarding, ecc.)
  setup.ps1           ← Copia file di configurazione nel progetto host
  CreateNewSolution.ps1  ← Bootstrap nuovo progetto da zero
  CLAUDE.md           ← Istruzioni Claude Code per questo repository
  .editorconfig       ← Naming conventions e stile codice
  Directory.Build.props  ← Configurazione MSBuild centralizzata
  global.json         ← Versione .NET SDK
```

**Dove vivono le cose che tocchi più spesso:**
- Aggiungi un'istruzione AI → `.github/instructions/`
- Aggiungi una skill Claude → `.claude/skills/`
- Aggiungi un prompt doc → `.github/prompts/`
- Aggiorna file configurazione distribuiti da `setup.ps1` → root del repository

---

## 5. Convenzioni obbligatorie

Ricavate da `.github/instructions/`:

| Regola | Fonte |
|---|---|
| Ogni modifica richiede piano approvato (`EnterPlanMode` → `ExitPlanMode`) | `CLAUDE.md` |
| Ogni nuova regola deve essere compatibile sia con Claude Code che con GitHub Copilot | `CLAUDE.md` |
| Ogni classe/componente in file dedicato, cartella = ruolo | `code-organization.instructions.md` |
| Componenti frontend: `shared/` per generici, `[domain]/` per specifici | `frontend-organization.instructions.md` |
| Dati sensibili mai in file committati — solo placeholder | `sensitive-data.instructions.md` |
| `.mcp.json` → in `.gitignore`; committare `.mcp.example.json` | `sensitive-data.instructions.md` |
| Footer obbligatorio nei file `docs/`: `*Revisione vN — YYYY-MM-DD HH:MM — modello*` | `doc-versioning.instructions.md` |
| MCP server: cerca prima di creare; repo dedicato `mcp-<dominio>` | `mcp-server-discovery.instructions.md` |
| Ogni nuovo progetto include `HealthMapping.cs`: `/health` (infrastruttura) + `GET /api/v1/status` (consumer, in Scalar) | `minimal-api-architecture.instructions.md` |
| CRUD di entità: Service layer obbligatorio — gli handler iniettano solo `Services/<Entity>Service.cs`, mai il provider | `minimal-api-architecture.instructions.md` (regola 12) |
| GET list: Filter con `ToExpression()` (WHERE solo sui filtri valorizzati) + DTO record con `static Projection` EF-traducibile (SELECT solo colonne del DTO); almeno `<Entity>Dto` + `<Entity>SummaryDto` | `minimal-api-architecture.instructions.md` (regola 9) · `database-provider.instructions.md` |
| Ogni endpoint con body valida con `IValidator<T>` prima della logica | `input-validation.instructions.md` |
| `///` su provider/service/handler/validator + commento inline su ogni operazione DB | `minimal-api-architecture.instructions.md` (regola 13) · `code-organization.instructions.md` (Regola 6) |

---

## 6. Flusso di lavoro

**Branch:** Da verificare con il team — repository ha solo `main`.

**Aggiungere un'istruzione:**
1. Crea `.github/instructions/<nome>.instructions.md` con frontmatter `applyTo: "**"`
2. Aggiorna sezione "Istruzioni Modulari" in `README.md`
3. Verifica compatibilità con entrambi gli agenti AI (Copilot + Claude Code)

**Aggiungere una skill Claude:**
1. Crea `.claude/skills/<nome>/SKILL.md`
2. Aggiorna sezione "Claude Code Skills" in `README.md`
3. Aggiungi voce alla tabella di invocazione automatica in `CLAUDE.md`

**Aggiornare le guidelines in un progetto host:**
```powershell
git submodule update --remote davraf-guidelines
.\davraf-guidelines\setup.ps1 -Update
```

La cartella `.github/` si aggiorna automaticamente (junction). I file copiati (`.editorconfig`, `Directory.Build.props`, ecc.) vengono aggiornati dal flag `-Update`. `CLAUDE.md` non viene mai sovrascritto.

---

## 7. Dati sensibili e configurazione locale

Nessun dato sensibile in questo repository. Se si aggiunge un MCP server con autenticazione:
- Configurazione reale → `.mcp.json` (in `.gitignore`)
- Placeholder committato → `.mcp.example.json`

Dettagli: `.github/instructions/sensitive-data.instructions.md`

---

## 8. Dove chiedere / cosa leggere dopo

| Risorsa | Scopo |
|---|---|
| `.github/copilot-instructions.md` | Convenzioni .NET 10 Minimal API — punto di partenza per sviluppo |
| `.github/instructions/dev-cycle.instructions.md` | Ciclo obbligatorio per ogni task AI |
| `.github/instructions/code-organization.instructions.md` | Organizzazione classi e file (tutti i linguaggi) |
| `.github/instructions/frontend-organization.instructions.md` | Struttura componenti Vue e WPF |
| `.github/instructions/minimal-api-architecture.instructions.md` | Regole endpoint, versioning, OpenAPI; Service layer, Filter `ToExpression()` + DTO `Projection`; pattern starter HealthMapping |
| `docs/card-davraf-guidelines.md` | Scheda riassuntiva del progetto |
| `README.md` | Guida completa all'uso come submodule |

---

*Revisione v1.3 — 2026-06-10 22:00 — claude-fable-5*
