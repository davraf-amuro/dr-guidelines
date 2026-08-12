# Piano: domanda breve quando la solution manca
Data: 2026-08-09
Stato: COMPLETATO

## Obiettivo
Quando `/dr-scaffold-project` non trova una solution, deve porre una sola domanda breve — "non trovo una solution, ne creiamo una? nome per il file `.slnx`?" — invece di chiedere destinazione, tipologia ed elencare il catalogo.

## Contesto (causa rilevata)
Sessione `2c0bc15c`, cwd `dr-guidelines`: la skill è stata invocata correttamente e ha raggiunto la Fase 0-bis, ma:
1. nessuna riga della tabella Fase 0-bis copre "cartella non vuota, senza solution e senza `.csproj`" (repo docs/tooling) → l'agente ha improvvisato;
2. la Fase 0-bis suggerisce la frase ma non impone che la prima domanda sia binaria + nome → l'agente ha chiesto destinazione e tipologia con l'intero catalogo in output.

## Scope
### File da modificare
- [x] `.claude/skills/dr-scaffold-project/SKILL.md` — riscrive Fase 0-bis: domanda unica breve + riga fallback
- [x] `.claude/skills/dr-scaffold/SKILL.md` — allinea Fase 1 (riga fallback + rimando alla domanda breve)
- [x] `.claude/skills/dr-scaffold-solution/SKILL.md` — aggiunge "nome solution" e "formato slnx" tra le risposte acquisite dal chiamante

### Perimetro negativo
- Non toccherò `scaffolding-catalog.json`, gli installer `dr-guidelines-install*.ps1`, `docs/`, `CLAUDE.md`
- Non toccherò le altre skill (`dr-scaffold-guidelines`, `dr-get-latest`, ecc.)
- Nessun `git commit`, nessun `git push`
- Non modificherò la copia installata in `e:\...\workspace\test\.claude\skills` (si aggiorna con `/dr-get-latest`)

## Fasi (formato atomico)

### Fase 1: Riscrivi Fase 0-bis in dr-scaffold-project
- **Stato**: [x]
- **Precondizione**: `.claude/skills/dr-scaffold-project/SKILL.md` contiene la sezione "Fase 0-bis"
- **File**: `.claude/skills/dr-scaffold-project/SKILL.md`
- **Operazione**: EDIT
- **Azione**: sostituire il corpo della Fase 0-bis con: (a) regola "prima domanda sempre binaria + nome solution, max 2 righe di preambolo"; (b) divieto esplicito di chiedere destinazione, tipologia, pacchetti o di elencare il catalogo in questa fase; (c) tabella ridotta ai soli casi che cambiano davvero la domanda (csproj sciolti, solution in sottocartella, repo solo frontend) più riga fallback "qualsiasi altro stato senza solution"; (d) elenco del contesto da passare a `/dr-scaffold-solution`, incluso il nome già ottenuto.
- **Tool ammessi**: Edit
- **Verifica passo**: rileggendo il file, la Fase 0-bis contiene la domanda binaria come primo passo e non contiene più richieste di destinazione/tipologia
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md

### Fase 2: Allinea la Fase 1 di dr-scaffold
- **Stato**: [x]
- **Precondizione**: Fase 1 del piano verificata
- **File**: `.claude/skills/dr-scaffold/SKILL.md`
- **Operazione**: EDIT
- **Azione**: aggiungere alla tabella di rilevamento la riga fallback "cartella non vuota, nessuna solution, nessun `.csproj`" → `dr-scaffold-solution`, e riformulare il paragrafo "Prerequisito mancante ≠ vicolo cieco" in modo che rimandi alla stessa domanda breve (binaria + nome), senza chiedere destinazione.
- **Tool ammessi**: Edit
- **Verifica passo**: rileggendo il file, la tabella ha la riga fallback e il paragrafo cita la domanda binaria + nome
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md

### Fase 3: Marca il nome solution come acquisito in dr-scaffold-solution
- **Stato**: [x]
- **Precondizione**: Fase 2 del piano verificata
- **File**: `.claude/skills/dr-scaffold-solution/SKILL.md`
- **Operazione**: EDIT
- **Azione**: nel paragrafo della Fase 1 che elenca le risposte già acquisite dal chiamante, aggiungere esplicitamente nome solution, formato `slnx` e assenza di workspace multi-repo, così la domanda non viene ripetuta dopo la delega.
- **Tool ammessi**: Edit
- **Verifica passo**: rileggendo il file, il paragrafo elenca il nome solution tra le risposte acquisite
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md

## Criteri di verifica finale
- [x] In `dr-scaffold-project` la Fase 0-bis impone come primo output una domanda binaria + nome `.slnx` e vieta destinazione/tipologia/catalogo in quella fase
- [x] Entrambe le tabelle di rilevamento (`dr-scaffold-project` Fase 0-bis, `dr-scaffold` Fase 1) hanno una riga fallback che copre il caso `dr-guidelines` (cartella non vuota, zero solution, zero `.csproj`)
- [x] `dr-scaffold-solution` non ri-chiede il nome solution quando arriva dal router
- [x] Nessun file fuori dai tre elencati nello Scope risulta modificato (`git status --short`)
