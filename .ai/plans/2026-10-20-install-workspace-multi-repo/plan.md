# Piano: installazione pacchetti dr-* consapevole del workspace (multi-repo, monorepo misto)
Data: 2026-10-20
Stato: COMPLETATO
Branch: main (scelta utente)

## Obiettivo
`dr-scaffold-guidelines` (e la Sezione C del prompt Copilot gemello) mappano il workspace, ragionano per root git e gestiscono in modo prescritto multi-repo, monorepo misto FE+BE e cartella contenitore.

## Scope
### File da modificare
- [x] `.claude/skills/dr-scaffold-guidelines/SKILL.md` — Fase 1 (mappa workspace, classificazione A/B/C/D), Fase 2 (tabella per repo, seconda conferma), Fase 3 (ciclo per repo), Fase 4 (verifica per repo), Regole
- [x] `.github/prompts/dr-scaffold.prompt.md` — Sezione C: stessa logica in forma portabile (liste numerate, niente `AskUserQuestion`), footer versione v1.5

### Perimetro negativo
- Non toccherò: `.agents/skills/` (bozza Codex, si riallinea a parte), i pacchetti `dr-fe` / `dr-minimalapi` (restringere `applyTo` è materia di issue), `scaffolding-catalog.json`, gli installer `*.ps1`, le altre skill `dr-scaffold*`, `dr-get-latest`.

## Fasi (formato atomico — obbligatorio)

### Fase 1: Skill — Fase 1 "Rileva il contesto"
- **Stato**: [x]
- **Precondizione**: SKILL.md contiene la riga `| Entrambi | multi-stack: proponi i pacchetti di entrambi |`
- **File**: `.claude/skills/dr-scaffold-guidelines/SKILL.md`
- **Operazione**: EDIT
- **Azione**: sostituire il punto 3 con: mappa del workspace (fonti `*.code-workspace`, working directory, sottocartelle con `.git` fino a 2 livelli, esclusioni), root git come unità, guard Fase 0 per repo, rilevamento stack per repo con euristica `package.json` (dipendenze framework vs solo tooling), tabella casi A/B/C/D con testo prescritto del caso C; rinumerare i punti successivi
- **Tool ammessi**: nessuno
- **Verifica passo**: la riga "Entrambi → multi-stack" non esiste più; i casi A, B, C, D sono presenti; il testo esatto del caso C cita `applyTo: "**"`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Skill — Fasi 2, 3, 4 e Regole
- **Stato**: [x]
- **Precondizione**: Fase 1 completata
- **File**: `.claude/skills/dr-scaffold-guidelines/SKILL.md`
- **Operazione**: EDIT
- **Azione**: Fase 2 → tabella per repo + seconda conferma multiSelect non preselezionata (solo caso B); Fase 3 → ciclo `Push-Location`/`Pop-Location` per repo, repo corrente per primo, errore di un repo non blocca gli altri; Fase 4 → verifiche per repo e riepilogo una riga per repo; Regole → solo cartelle con `.git`, niente pacchetti FE in repo BE per contagio, repo non scelto non si tocca, ambiguità (annidati, submodule) → chiedi
- **Tool ammessi**: nessuno
- **Verifica passo**: rilettura: ogni punto dell'azione è presente; flusso caso A identico a prima
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Prompt Copilot — Sezione C
- **Stato**: [x]
- **Precondizione**: Fasi 1-2 completate
- **File**: `.github/prompts/dr-scaffold.prompt.md`
- **Operazione**: EDIT
- **Azione**: riportare in Sezione C la stessa logica (mappa workspace, casi A/B/C/D, euristica `package.json`, tabella per repo, seconda conferma come lista numerata senza default, ciclo per repo); aggiornare footer a `Template v1.5 — 2026-10-20`
- **Tool ammessi**: nessuno
- **Verifica passo**: nessun riferimento a `AskUserQuestion`/`$ARGUMENTS`/sub-agenti nella Sezione C; riga "Entrambi | multi-stack" rimossa; footer v1.5
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] Skill e prompt descrivono gli stessi quattro casi con lo stesso comportamento
- [x] Caso C ha il testo prescritto con le tre opzioni (a/b/c)
- [x] Nessun repo diverso dal corrente viene toccato senza scelta esplicita
- [x] Caso A (repo singolo, stack singolo) invariato rispetto a prima
- [x] `.agents/skills/` non modificata (`git status`)
- [x] Prompt Copilot privo di feature esclusive Claude Code
