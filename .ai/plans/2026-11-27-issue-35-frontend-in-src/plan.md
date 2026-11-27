# Piano: Scaffolding — frontend Vue dentro `src/`, non nella radice del repository
Data: 2026-11-27
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#35
Branch: `plan/issue-35-frontend-in-src` (autonomia concessa dall'utente il 2026-11-27: piano, decisioni sulle opzioni consigliate, commit, PR, merge)

## Obiettivo
Lo scaffolding crea il frontend Vue in `src/<nome-fe>` (accanto ai progetti .NET), leggendo `targetPath` dal catalogo come per i progetti .NET; la convenzione `test/` per i progetti di test è esplicita.

## Contesto
- Catalogo: `vue-fe.targetPath = "."` (r.143); i progetti .NET usano già `src` / `test`.
- `dr-scaffold-solution` 4.5 e prompt `dr-scaffold` A.4 passo 5 lanciano `npm create vue@latest <nome-fe>` dalla radice del repo frontend; `dr-scaffold-project` ramo Vue dalla cartella corrente; dry-run di `dr-scaffold-solution` mostra `ordini-fe\` in radice.
- Docker/compose: nessun template nei pacchetti dr-* punta a `./<nome>-fe` (ricerca su tutti i repo): nulla da cambiare.
- `test/` vs `tests/`: il catalogo dice `test/` e nessuna skill/prompt cita `tests/`; la deviazione di dr-photodrop non nasce dalle regole. Si rende esplicito "mai `tests/`".

## Decisioni (prese in autonomia, opzione consigliata)
1. `targetPath = "src"` vale anche nel repo frontend separato (multi-repo): un'unica regola "sorgenti in `src/`".
2. `test/` resta la convenzione; nessun cambio al catalogo oltre alla nota.

## Scope
### File da modificare
- [x] `scaffolding-catalog.json` — `vue-fe.targetPath = "src"`, nota; `xunit-test` nota "mai `tests/`"; `updatedAt`
- [x] `.claude/skills/dr-scaffold-solution/SKILL.md` — dry-run, regola delle cartelle di progetto, 4.5 con `<targetPath>`, footer
- [x] `.claude/skills/dr-scaffold-project/SKILL.md` — ramo Vue in `<targetPath>`, footer
- [x] `.github/prompts/dr-scaffold.prompt.md` — A.4 passo 5, footer
- [x] `docs/guida-nuova-soluzione.md` — tabella "Cosa succede" e nota sul frontend; footer
- [x] `.agents/skills/` — `scripts/sync-codex.ps1`
- [x] `.claude/skills/dr-scaffold/SKILL.md`, `.claude/skills/dr-scaffold-guidelines/SKILL.md` — rilevamento del repo frontend da `src/*/package.json`, esempio `web/` (aggiunti dopo la verifica)

### Perimetro negativo
- Nessun template Docker/compose (non ne esistono nei pacchetti); `dr-create-launch-profiles` già generico (`<percorso-fe>`); nessun progetto host esistente (dr-photodrop si sposta a mano)

## Fasi
### Fase 1: modifiche ai file di Scope (sessione)
- **Stato**: [x]
### Fase 2: `sync-codex.ps1`, `normalize-eol.ps1 -Check`, JSON valido
- **Stato**: [x]
### Fase 3: Verifica finale `/dr-verify-plan` (opus)
- **Stato**: [x]

**Verifica (2026-11-27, opus isolato): CONFORME** — nessun NON CORRISPONDE / NON SODDISFATTO / violazione. Punti di completezza corretti subito dopo: rilevamento del repo frontend anche da `package.json` in `src/*/` (`dr-scaffold`, prompt A/B, `dr-scaffold-project`); esempio `web/` → `src/<nome>-fe/` (`dr-scaffold-guidelines`, prompt C); ramo Vue aggiunto alla Sezione B del prompt (lacuna preesistente). NON VERIFICABILE accettato: istruzioni dei repo di dominio (dr-fe) non lette.

## Criteri di verifica finale
- [x] `vue-fe.targetPath = "src"` e le tre procedure creano il frontend in `<targetPath>\<nome-fe>`
- [x] Nessuna procedura lancia `create-vue` dalla radice del repo
- [x] Convenzione `test/` esplicita
- [x] Copie Codex allineate, footer aggiornati
