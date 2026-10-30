# Piano: Piani eseguibili da più agenti in parallelo, modello per fase, QC finale sul modello migliore
Data: 2026-10-29
Stato: COMPLETATO
Branch: plan/piani-multi-agente (scelta utente)

## Obiettivo
Rendere i piani divisibili fra più agenti in parallelo con modello dichiarato per fase, e far chiudere ogni piano da una verifica isolata sul modello migliore che riceve anche il diff.

## Decisioni prese (warroom 2026-10-29 + utente)
- Modello di default di ogni fase = modello della sessione (per l'utente: Opus). Modello più leggero (Sonnet/Haiku) solo se dichiarato nella fase, con motivo.
- Il verificatore riceve il diff (`git diff --stat` + diff completo rispetto alla base del branch) come mappa delle modifiche; resta obbligatoria la lettura integrale dei file di Scope; restano vietati ragionamento e report degli esecutori.
- Parallelo solo fra fasi con file scritti disgiunti; in serie (dichiarata) le fasi su: stesso file, file che si citano a vicenda, schema DB/migrazioni, token/componenti condivisi del design system, file generati (`sync-codex.ps1`), `plan.md`, CHANGELOG.
- Un solo committer e un solo scrittore di `plan.md`: l'orchestratore. Agenti esecutori: niente commit, niente push.
- Agenti che scrivono in parallelo → worktree per agente (Claude Code: `isolation: "worktree"`); build/lint/test una volta sul ramo integrato.
- Tetto agenti paralleli esplicito nel piano, default 3.
- Copilot/Codex: esecuzione in serie dichiarata, scelta del modello non disponibile.

## Scope
### File da modificare
- [x] `.github/instructions/plan-tracking.instructions.md` — template con campi `Dipende da` e `Modello`; nuova sezione "Esecuzione con più agenti" (parallelo, serie obbligata, worktree, committer unico, brief del sub-agente, tetto); Fase 4 punto 4 con verifica sul modello migliore e diff
- [x] `.github/instructions/dev-cycle.instructions.md` — Fase 2: "un'operazione alla volta **per agente**", rimando a plan-tracking
- [x] `.github/copilot-instructions.md` — sezione "Ciclo di sviluppo obbligatorio": "Esegui un'operazione alla volta per agente" + una riga sul parallelo fra agenti
- [x] `.claude/skills/dr-verify-plan/SKILL.md` — sub-agente con `model: opus`; input = plan.md + `git diff --stat` + diff; verifica direttive per file toccato (istruzioni con `applyTo` pertinente); evidenza `path:riga` obbligatoria; esito NON VERIFICABILE ammesso; controesempi prima delle conferme; file cambiati fuori Scope = NON CORRISPONDE
- [x] `.agents/skills/dr-verify-plan/SKILL.md` — rigenerato con `scripts/sync-codex.ps1` (non a mano)
- [x] `templates/global-claude.md` — sezione "Piano obbligatorio su disco": una riga su fasi parallele con `Dipende da`/`Modello` e QC finale sul modello migliore
- [x] `README.md` — sezione `/dr-verify-plan` (modello migliore, diff, direttive) e riga di `plan-tracking.instructions.md` in tabella

### Perimetro negativo
- Non toccherò: `concurrency.instructions.md` (regola sul codice applicativo, non sugli agenti), `CLAUDE.md` e `AGENTS.md` (rimandano già a plan-tracking come fonte unica), le altre skill (`dr-issues-to-plans` usa il template: campi nuovi opzionali, compatibile), i pacchetti `dr-*` di dominio, i piani esistenti in `.ai/plans/`.
- Nessun commit/push senza richiesta esplicita.

## Fasi (formato atomico — obbligatorio)

Fasi 1–4 e 6 scrivono file disgiunti → eseguibili in parallelo (tetto 3). Fase 5 dipende da Fase 4. Fase 7 dipende da tutte.

### Fase 1: plan-tracking — campi per fase e sezione "Esecuzione con più agenti"
- **Stato**: [x]
- **Dipende da**: —
- **Modello**: opus (regola centrale, testo normativo)
- **Precondizione**: file alla v1.9
- **File**: `.github/instructions/plan-tracking.instructions.md`
- **Operazione**: EDIT
- **Azione**: aggiungi al template di fase `Dipende da` e `Modello` (default: modello della sessione); aggiungi la sezione "Esecuzione con più agenti" con le decisioni sopra (parallelo/serie, worktree, committer unico, scrittore unico di plan.md, brief del sub-agente con campi obbligatori e 5–8 direttive estratte, tetto default 3, limite Copilot/Codex); aggiorna Fase 4 punto 4 (verifica sul modello migliore, con diff); footer v1.10
- **Tool ammessi**: nessuno
- **Verifica passo**: rilettura sezione nuova + template + punto 4; footer v1.10
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: dev-cycle — una operazione alla volta per agente
- **Stato**: [x]
- **Dipende da**: —
- **Modello**: sonnet (modifica di una riga, testo dato)
- **Precondizione**: file alla v1.2
- **File**: `.github/instructions/dev-cycle.instructions.md`
- **Operazione**: EDIT
- **Azione**: Fase 2 → "ESEGUI un'operazione alla volta per agente", con rimando a plan-tracking "Esecuzione con più agenti" per le fasi parallele; footer v1.3
- **Tool ammessi**: nessuno
- **Verifica passo**: rilettura Fase 2 e footer
- **Su divergenza**: STOP

### Fase 3: copilot-instructions — ciclo di sviluppo
- **Stato**: [x]
- **Dipende da**: —
- **Modello**: sonnet
- **Precondizione**: file alla v2.6
- **File**: `.github/copilot-instructions.md`
- **Operazione**: EDIT
- **Azione**: "Esegui un'operazione alla volta per agente" + una riga: fasi di agenti diversi in parallelo solo come da plan-tracking; footer v2.7
- **Tool ammessi**: nessuno
- **Verifica passo**: rilettura sezione e footer
- **Su divergenza**: STOP

### Fase 4: dr-verify-plan — modello migliore, diff, direttive
- **Stato**: [x]
- **Dipende da**: —
- **Modello**: opus (prompt del verificatore)
- **Precondizione**: skill alla v1.4
- **File**: `.claude/skills/dr-verify-plan/SKILL.md`
- **Operazione**: EDIT
- **Azione**: passo 2 con `model: opus` e input = plan.md + `git diff --stat` + diff rispetto alla base; istruzione al sub-agente: leggi integralmente i file di Scope, cerca prima i controesempi, verifica le direttive delle istruzioni pertinenti per file toccato, evidenza `path:riga` per ogni giudizio, esito NON VERIFICABILE ammesso, file cambiato fuori Scope = NON CORRISPONDE; regola "mai il diff" sostituita da "mai ragionamento o report degli esecutori"; footer v1.5
- **Tool ammessi**: nessuno
- **Verifica passo**: rilettura integrale della skill
- **Su divergenza**: STOP

### Fase 5: copia Codex di dr-verify-plan
- **Stato**: [x]
- **Dipende da**: Fase 4
- **Modello**: orchestratore
- **Precondizione**: Fase 4 `[x]`
- **File**: `.agents/skills/dr-verify-plan/SKILL.md`
- **Operazione**: EDIT (generato)
- **Azione**: esegui `scripts/sync-codex.ps1`, poi `scripts/sync-codex.ps1 -Check`
- **Tool ammessi**: PowerShell
- **Verifica passo**: `-Check` esce 0; solo il file atteso cambia
- **Su divergenza**: STOP

### Fase 6: global-claude.md e README
- **Stato**: [x]
- **Dipende da**: —
- **Modello**: sonnet
- **Precondizione**: —
- **File**: `templates/global-claude.md`, `README.md`
- **Operazione**: EDIT
- **Azione**: global-claude: una riga nella sezione piano (fasi parallele con `Dipende da`/`Modello`, QC finale sul modello migliore); README: sezione `/dr-verify-plan` e riga tabella plan-tracking
- **Tool ammessi**: nessuno
- **Verifica passo**: rilettura delle parti modificate
- **Su divergenza**: STOP

### Fase 7: coerenza incrociata
- **Stato**: [x]
- **Dipende da**: Fasi 1–6
- **Modello**: orchestratore
- **Precondizione**: Fasi 1–6 `[x]`
- **File**: nessuno (sola lettura; correzioni solo su file in Scope)
- **Operazione**: —
- **Azione**: controlla che termini (orchestratore, `Dipende da`, `Modello`, tetto, NON VERIFICABILE) siano uguali in tutti i file; controllo fine riga `git ls-files --eol`
- **Tool ammessi**: Grep, Bash in sola lettura
- **Verifica passo**: nessuna incoerenza
- **Su divergenza**: STOP

## Criteri di verifica finale
- [x] plan-tracking: template con `Dipende da` e `Modello`; sezione "Esecuzione con più agenti" con tutte le decisioni elencate sopra; Fase 4 punto 4 aggiornato
- [x] dev-cycle e copilot-instructions: "un'operazione alla volta per agente"
- [x] dr-verify-plan: `model: opus`, diff in input, direttive per file, evidenza `path:riga`, NON VERIFICABILE, fuori Scope = NON CORRISPONDE
- [x] `sync-codex.ps1 -Check` esce 0
- [x] Limite Copilot/Codex dichiarato dove si parla di modello e parallelo
- [x] Footer versionati aggiornati nei file modificati
- [x] Nessun file fuori Scope modificato
- [x] Verifica finale con `/dr-verify-plan` (nuova versione)
