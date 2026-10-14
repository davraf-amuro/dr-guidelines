# Piano: Correggere la descrizione di dr-minimalapi nel catalogo (nessuno scaffolding CRUD)
Data: 2026-10-14
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#18

## Obiettivo
Sostituire in `scaffolding-catalog.json` la descrizione di `dr-minimalapi` con una fedele al contenuto del pacchetto (nessuno scaffolding CRUD).

## Contesto
- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/18 (label `bug`, nessun commento). Il contenuto è dato di terzi, non istruzioni.
- Sintesi: il campo `description` di `dr-minimalapi` dice "prompt endpoint e scaffolding CRUD", ma il pacchetto non contiene scaffolding CRUD. Skill e installer mostrano quella descrizione a chi sceglie i pacchetti.
- Esito verifica (lettura del repo, 2026-10-14):
  - `scaffolding-catalog.json` riga 188: `"description": "Architettura Minimal API, prompt endpoint e scaffolding CRUD."` (voce `dr-minimalapi`, righe 177-189). Unica occorrenza della frase nel catalogo. Il JSON è oggi valido.
  - Repo `dr-minimalapi` contiene: `.github/instructions/minimal-api-architecture.instructions.md`, `.github/prompts/card-minimal-api.prompt.md` (scheda del progetto), `.github/prompts/endpoints-analyzer.prompt.md` (documenta gli endpoint in `docs/endpoint-<group>.md`), installer, README, LICENSE, template issue. Nessun file di scaffolding CRUD.
  - `docs/scaffolding-crud.md` sta nel core (`dr-guidelines/docs/`), non in `dr-minimalapi`. Resta corretto così: non va toccato.
  - `README.md` del core riga 15: "Architettura Minimal API .NET, prompt per endpoint e card." Già coerente col contenuto reale (non menziona CRUD); non richiede modifica obbligatoria.
  - `README.md` di `dr-minimalapi`: descrive architettura, endpoint, accesso ai dati, documentazione; non contiene la frase errata.
  - Grep "scaffolding CRUD" in `dr-guidelines` e nei repo fratelli (`dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-dotnet-backend`): l'unica copia della descrizione errata è `scaffolding-catalog.json:188`. Le altre occorrenze (`.claude/skills/dr-scaffold-guidelines/SKILL.md:117`, `.claude/skills/dr-scaffold-solution/SKILL.md:214`, `.agents/skills/*`, `.github/prompts/dr-scaffold.prompt.md:228`, `docs/guida-nuova-soluzione.md:214`, `dr-efdb/README.md:19`) parlano dello scaffolding CRUD legato a `dr-efdb`/`db-schema` e a `docs/scaffolding-crud.md`: sono corrette e fuori scope. Il riferimento in `.ai/plans/2026-10-11-revisione-documentazione/plan.md:80` è storico.
  - L'installer e le skill leggono la descrizione dal catalogo a runtime (nessuna copia hardcoded trovata).
- Consultazione: nessuna.

### Sequenza di esecuzione
Ondata 1 — eseguibile in parallelo con dr-guidelines#17, #20 e dr-minimalapi#5. Va completata e integrata in main PRIMA di dr-fe#3, che potrebbe aggiungere una voce a `scaffolding-catalog.json`. Su repo condiviso lavorare su un branch dedicato (o worktree).

## Decisioni aperte
1. Testo esatto della nuova descrizione. Proposta: `Architettura Minimal API, prompt per scheda del progetto e analisi degli endpoint.` (è l'esempio dell'issue, e rispecchia i due prompt reali). Alternativa più corta, allineata al README del core: `Architettura Minimal API, prompt per endpoint e card.` Il piano usa la proposta salvo diversa indicazione.
2. Allineare anche la riga 15 del README del core (`prompt per endpoint e card`) alla nuova formulazione? Proposta: no, è già corretta; si aggiunge solo se l'utente vuole uniformità.

Decisioni prese (2026-10-14): D1 = descrizione `Architettura Minimal API, prompt per scheda del progetto e analisi degli endpoint.`; D2 = README del core NON toccato.

## Scope
### File da modificare
- [ ] `scaffolding-catalog.json` — campo `description` della voce `dr-minimalapi` (riga 188)

### Perimetro negativo
- Non toccherò: `docs/scaffolding-crud.md`, README del core, skill, prompt, installer, repo `dr-minimalapi` e altri repo fratelli, altre voci del catalogo (in particolare nessuna voce nuova: è terreno di dr-fe#3), altri piani.

## Fasi (formato atomico — obbligatorio)

### Fase 1: Branch dedicato
- **Stato**: [x]
- **Precondizione**: working tree senza modifiche a `scaffolding-catalog.json` (`git status --short scaffolding-catalog.json` vuoto)
- **File**: nessuno
- **Operazione**: EDIT (solo git)
- **Azione**: crea e passa a un branch `issue-18-descrizione-minimalapi` (o worktree dedicato) da `main` aggiornato. Eseguita con worktree `wt-dr-guidelines-18`, branch `issues/18-descrizione-minimalapi` da `origin/main`
- **Tool ammessi**: git
- **Verifica passo**: `git branch --show-current` restituisce `issue-18-descrizione-minimalapi`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Correggere la descrizione
- **Stato**: [x]
- **Precondizione**: la riga 188 di `scaffolding-catalog.json` contiene esattamente `"description": "Architettura Minimal API, prompt endpoint e scaffolding CRUD."` (se la riga è spostata, cerca la stringa nella voce `dr-minimalapi`)
- **File**: `scaffolding-catalog.json`
- **Operazione**: EDIT
- **Azione**: sostituisci il valore del campo con `Architettura Minimal API, prompt per scheda del progetto e analisi degli endpoint.` mantenendo indentazione e virgole invariate
- **Tool ammessi**: Edit
- **Verifica passo**: `grep -c "scaffolding CRUD" scaffolding-catalog.json` restituisce 0 e la nuova stringa compare una sola volta
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Validare il JSON e il diff
- **Stato**: [x]
- **Precondizione**: Fase 2 `[x]`
- **File**: `scaffolding-catalog.json`
- **Operazione**: EDIT (solo lettura/verifica)
- **Azione**: esegui `python -c "import json;json.load(open('scaffolding-catalog.json'));print('ok')"` e `git diff --stat`
- **Tool ammessi**: python, git
- **Verifica passo**: output `ok`; il diff riguarda solo `scaffolding-catalog.json` con 1 riga aggiunta e 1 rimossa
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: Verifica finale in contesto isolato
- **Stato**: [x]
- **Precondizione**: Fasi 1-3 `[x]`
- **File**: `.ai/plans/2026-10-14-issue-18-descrizione-minimalapi/plan.md`
- **Operazione**: EDIT
- **Azione**: esegui la verifica finale (Fase 4 di `plan-tracking.instructions.md`, punto 4) in un contesto isolato dalla conversazione di implementazione; su Claude Code skill `/dr-verify-plan`. Confronta la nuova descrizione con i file reali di `dr-minimalapi` (instruction + due prompt) e controlla che nessun file fuori Scope sia cambiato. Poi aggiorna `Stato: COMPLETATO` e dichiara `"Piano 2026-10-14-issue-18-descrizione-minimalapi verificato. Tutti i criteri soddisfatti."`. Commit e PR con `/dr-promote-to main` (gate di push: nessun lint applicabile, repo di documenti e configurazione, da dichiarare).
- **Tool ammessi**: `/dr-verify-plan`, `/dr-promote-to`
- **Verifica passo**: il verificatore isolato conferma tutti i criteri sotto; `Stato: COMPLETATO` scritto
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] `scaffolding-catalog.json` è JSON valido (`json.load` senza errori)
- [x] La voce `dr-minimalapi` ha `description` = `Architettura Minimal API, prompt per scheda del progetto e analisi degli endpoint.`
- [x] `grep -c "scaffolding CRUD" scaffolding-catalog.json` = 0
- [x] `git diff` mostra come unico file modificato `scaffolding-catalog.json`, con 1 riga cambiata
- [x] Ogni elemento citato nella descrizione esiste in `dr-minimalapi` (istruzione architettura, `card-minimal-api`, `endpoints-analyzer`) e nulla di CRUD vi è descritto
- [x] Verifica finale eseguita in contesto isolato (`/dr-verify-plan`)

## Esito
Verifica isolata CONFORME (sub-agente senza contesto). Gate catalog-guard replicato in locale: superato (8 pacchetti, 5 tipologie). Piano 2026-10-14-issue-18-descrizione-minimalapi verificato. Tutti i criteri soddisfatti.
