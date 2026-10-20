# Piano: Regola — alla creazione di un piano, proporre sempre l'esecuzione in un branch
Data: 2026-10-20
Stato: COMPLETATO
Branch: main (scelta utente)

## Obiettivo
Ogni piano sottoposto all'utente contiene la proposta di eseguirlo in un branch dedicato; l'utente decide, la scelta resta scritta nel piano.

## Scope
### File da modificare
- [x] `.github/instructions/plan-tracking.instructions.md` — nuova sezione "Branch di esecuzione", campo `Branch:` nel template, riga in "Piani proposti", footer v1.8
- [x] `CLAUDE.md` — passo "proponi il branch" nella sezione "Piano obbligatorio su disco"
- [x] `AGENTS.md` — stesso passo, sezione speculare
- [x] `.github/copilot-instructions.md` — una riga nel "Ciclo di sviluppo obbligatorio", footer v2.3

### Perimetro negativo
- Non toccherò: skill in `.claude/skills/` e `.agents/skills/`, prompt `.github/prompts/`, `dev-cycle.instructions.md`, README/docs, piani esistenti, repo dr-* di dominio
- Nessun branch creato, nessun commit, nessuna push senza richiesta

## Contenuto della regola (fonte: plan-tracking)
- Quando l'agente sottopone un piano all'approvazione (EnterPlanMode o equivalente), **propone** di eseguirlo in un branch dedicato creato da `main` aggiornato, con nome suggerito `plan/<slug>` (o il nome già fissato dal piano, es. `issues/<repo>-<n>-<slug>`)
- L'utente sceglie: branch dedicato oppure branch corrente. L'agente non crea il branch senza risposta esplicita
- La scelta si scrive nel campo d'intestazione `Branch:` del piano
- Branch accettato → creato prima della prima fase di esecuzione
- Piani `PROPOSTO`: la proposta si fa al passaggio a `IN CORSO`, non alla scrittura
- Compatibile Copilot: nessun tool specifico, solo testo e git

## Fasi

### Fase 1: plan-tracking
- **Stato**: [x]
- **Precondizione**: piano approvato
- **File**: `.github/instructions/plan-tracking.instructions.md`
- **Operazione**: EDIT
- **Azione**: aggiungi campo `Branch:` al template, sezione "Branch di esecuzione", riga tabella PROPOSTO, footer v1.8
- **Tool ammessi**: nessuno
- **Verifica passo**: rilettura — sezione e campo presenti, nessuna altra sezione alterata
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: CLAUDE.md
- **Stato**: [x]
- **Precondizione**: Fase 1 `[x]`
- **File**: `CLAUDE.md`
- **Operazione**: EDIT
- **Azione**: nella lista "Piano obbligatorio su disco" aggiungi il passo di proposta del branch
- **Tool ammessi**: nessuno
- **Verifica passo**: rilettura — passo presente, numerazione coerente
- **Su divergenza**: STOP

### Fase 3: AGENTS.md
- **Stato**: [x]
- **Precondizione**: Fase 2 `[x]`
- **File**: `AGENTS.md`
- **Operazione**: EDIT
- **Azione**: stessa modifica della Fase 2
- **Tool ammessi**: nessuno
- **Verifica passo**: rilettura — testo allineato a CLAUDE.md
- **Su divergenza**: STOP

### Fase 4: copilot-instructions
- **Stato**: [x]
- **Precondizione**: Fase 3 `[x]`
- **File**: `.github/copilot-instructions.md`
- **Operazione**: EDIT
- **Azione**: nel "Ciclo di sviluppo obbligatorio" aggiungi la riga sulla proposta del branch; footer v2.3
- **Tool ammessi**: nessuno
- **Verifica passo**: rilettura
- **Su divergenza**: STOP

### Fase 5: verifica finale
- **Stato**: [x]
- **Precondizione**: Fasi 1–4 `[x]`
- **File**: questo plan.md
- **Operazione**: EDIT
- **Azione**: verifica criteri (a freddo con `dr-verify-plan` se l'utente lo chiede), `Stato: COMPLETATO`
- **Tool ammessi**: nessuno
- **Verifica passo**: tutti i criteri `[x]`
- **Su divergenza**: STOP

## Criteri di verifica finale
- [x] plan-tracking: template con `Branch:`, sezione "Branch di esecuzione", eccezione PROPOSTO, footer v1.8
- [x] CLAUDE.md, AGENTS.md e copilot-instructions rimandano alla regola con lo stesso significato
- [x] Nessun riferimento a tool esclusivi di un solo agente nella regola
- [x] Nessun file fuori Scope modificato (`git status`)
