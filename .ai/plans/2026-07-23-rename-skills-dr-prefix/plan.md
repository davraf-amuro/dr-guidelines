# Piano: rinomina tutte le skill con prefisso `dr-`

**Data:** 2026-07-23
**Stato:** COMPLETATO

## Obiettivo

Rinominare tutte le Claude Code skill della suite `dr-*` aggiungendo il prefisso `dr-` (nome cartella + campo `name` in frontmatter), aggiornando ogni riferimento vivo nei repo.

## Scope

### Skill da rinominare (12)

| Repo | Vecchio nome | Nuovo nome |
|---|---|---|
| dr-guidelines | CreateLaunchProfiles | dr-CreateLaunchProfiles |
| dr-guidelines | get-latest | dr-get-latest |
| dr-guidelines | handoff | dr-handoff |
| dr-guidelines | professor | dr-professor |
| dr-guidelines | promote-to | dr-promote-to |
| dr-guidelines | segnala-miglioria | dr-segnala-miglioria |
| dr-guidelines | snapshot | dr-snapshot |
| dr-guidelines | tattico | dr-tattico |
| dr-guidelines | tech | dr-tech |
| dr-guidelines | warroom | dr-warroom |
| dr-fe | audit-fe | dr-audit-fe |
| dr-dotnet-backend | audit-api | dr-audit-api |

### File da modificare (riferimenti vivi, mappati via grep in sessione)

- `dr-guidelines/README.md` — tutte le sezioni H3 + comandi d'uso
- `dr-guidelines/CLAUDE.md` — tabella invocazione automatica skill
- `dr-guidelines/.github/instructions/readme-structure.instructions.md` — 1 rif. a `/get-latest`
- `dr-guidelines/.github/instructions/plan-tracking.instructions.md` — 2 rif. a `/promote-to`
- `dr-guidelines/.github/instructions/mcp-server-discovery.instructions.md` — 6 rif. a `/warroom`
- `dr-guidelines/templates/global-claude.md` — tabella invocazione (usata da `setup.ps1 -GlobalInstall`)
- `dr-guidelines/docs/onboarding.md` — elenco skill + rif. a `/promote-to`
- `dr-guidelines/.claude/settings.json` — permesso `Edit(/.claude/skills/promote-to/**)`
- `dr-guidelines/.ai/plans/2026-07-22-dr-guidelines-split/plan.md` — mensioni sparse, aggiornamento leggero
- `dr-guidelines/.claude/skills/segnala-miglioria/SKILL.md` — esempio path `.claude/skills/audit-api/`
- `dr-dotnet-backend/.claude/skills/audit-api/SKILL.md` → `name:` field
- `dr-fe/.claude/skills/audit-fe/SKILL.md` → `name:` field

### Perimetro negativo

- Non tocco `.ai/handoff/*.md` (HANDOFF.md, SESSION.md, DECISIONI.md, NEXT_PROMPT.md) — snapshot storico di sessione precedente, per design non riscritto
- Non tocco `.ai/plans/2026-06-17-global-install/`, `.ai/plans/2026-07-01-audit-*/`, `.claude/skills/handoff/skill.md.original.md` — già destinati a cancellazione nel task housekeeping fase 6 in corso (separato)
- Non tocco `.ai/context/snapshot.md` come nome file di output della skill `dr-snapshot` — è una convenzione di path indipendente dal nome comando, non necessita rename
- Non eseguo `git push` su nessuno dei repo interessati senza gate lint + conferma esplicita

## Fasi

- [x] 1. Rename cartelle skill (`git mv`) nei 3 repo interessati (dr-guidelines ×10, dr-fe ×1, dr-dotnet-backend ×1)
- [x] 2. Update campo `name:` (+ descrizioni che si auto-citano) in ciascun `SKILL.md`/`skill.md` rinominato
- [x] 3. Update riferimenti nei file elencati sopra in `dr-guidelines` — **scope esteso**: trovato durante grep un riferimento vivo aggiuntivo non mappato in fase di pianificazione, `dr-minimalapi/.github/instructions/minimal-api-architecture.instructions.md` (menzione skill `CreateLaunchProfiles`), corretto
- [x] 4. Verifica: grep residuo dei vecchi nomi (esclusi i file in perimetro negativo) → zero risultati residui rilevanti (solo 3 menzioni generiche "il warroom"/"del warroom" come nome comune, deliberatamente non toccate)
- [x] 5. Commit su ciascuno dei 4 repo interessati (dr-guidelines, dr-fe, dr-dotnet-backend, dr-minimalapi — quest'ultimo aggiunto per lo scope esteso al passo 3), nessun push

## Criteri di verifica finale

- [x] Nessuna cartella skill con nome vecchio residua nei 3 repo con skill rinominate
- [x] Ogni `SKILL.md`/`skill.md` rinominato ha `name:` coerente con la cartella
- [x] Grep dei vecchi nomi (fuori perimetro negativo) restituisce zero match rilevanti
- [x] Commit creati su 4 repo, nessun push eseguito

**Piano rename-skills-dr-prefix verificato. Tutti i criteri soddisfatti.**
