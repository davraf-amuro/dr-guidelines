# Piano: dr-professor — l'aggiornamento della documentazione confronta i documenti col codice
Data: 2026-10-30
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#31
Branch: main (scelta utente)
Agenti paralleli: 1 — serie obbligata: la fase 2 rigenera da script la copia della fase 1

## Obiettivo
Con "aggiorna la documentazione", `dr-professor` confronta ogni sezione dei documenti toccati col codice, dichiara cosa non ha controllato, si verifica a freddo, rispetta cartella e lingua reali del progetto e non ripropone la wiki card se esiste già.

## Scope
### File da modificare
- [x] `.claude/skills/dr-professor/SKILL.md` — i sei comportamenti attesi della issue
- [x] `.agents/skills/dr-professor/SKILL.md` — copia Codex rigenerata da `scripts/sync-codex.ps1` (mai a mano)

### Perimetro negativo
- Non toccherò: i template in `.github/prompts/*.prompt.md` (il `docs/` dei template viene rimappato dalla skill, non riscritto), `doc-versioning.instructions.md`, `readme-structure.instructions.md`, `dr-verify-plan`, installer e catalogo
- Non toccherò: le issue di `dr-mcp-dbschema` (#3, #4, #5), repo fuori dal workspace: piano separato se l'utente lo chiede
- Nessun commento, label o chiusura sulla issue senza conferma: la chiusura avviene col merge della PR (`Closes #31`)

## Fasi (formato atomico — obbligatorio)

### Fase 1: Riscrivi le sezioni di dr-professor
- **Stato**: [x]
- **Dipende da**: —
- **Modello**: sessione
- **Precondizione**: `.claude/skills/dr-professor/SKILL.md` alla v1.1
- **File**: `.claude/skills/dr-professor/SKILL.md`
- **Operazione**: EDIT
- **Azione**: aggiungi o modifica, senza riscrivere ciò che è corretto:
  1. **Cartella dei documenti** (sezione "Il tuo ruolo"): se il progetto ha già una cartella di documentazione con altro nome (`DOC/`, `doc/`, `documentation/`), usala per tutti i percorsi `docs/` dei template e dichiara il conflitto con la regola `docs/` in una riga; `docs/` si crea solo se non ne esiste nessuna.
  2. **Lingua** (nuova sottosezione prima di scrivere): leggi `AGENTS.md`, `CLAUDE.md` e `.github/copilot-instructions.md` del progetto; lingua dichiarata per la documentazione diversa dall'italiano dei template → scrivi in quella lingua (strutture dei template tradotte); nessuna indicazione o indicazioni in conflitto → chiedi.
  3. **Wiki card** (nota ² e tabella task singolo): prima della domanda cerca una wiki card esistente (`*-wiki.md` nella cartella dei documenti, anche se esclusa da git via `.gitignore` o `.git/info/exclude`); se esiste, niente domanda: il passo 6 la aggiorna solo su richiesta esplicita, altrimenti dichiara che è stata lasciata com'è.
  4. **Confronto col codice** (nuova sezione "Aggiornare documenti esistenti"): per ogni documento toccato, ogni sezione si confronta col codice, non solo i punti citati nella richiesta. Inventario agnostico dallo stack: cartelle del codice (es. .NET: `Endpoints/`, `Services/`, `Infrastructure/`, `Middleware/`), registrazioni (DI, routing), file di configurazione, conteggi, percorsi e link citati, descrizione della CI rispetto ai workflow reali. Una differenza dentro il perimetro scelto dall'utente si corregge; fuori dal perimetro si elenca come "Differenze fuori perimetro" senza correggerla.
  5. **Rendiconto finale** obbligatorio per gli aggiornamenti: tabella "Controllato / Non controllato" (documenti, sezioni o aree di codice non confrontate, con motivo). Senza la sezione "Non controllato" il task non si dichiara finito.
  6. **Verifica a freddo** prima di dichiarare finito: con un piano → `/dr-verify-plan`; senza piano, su Claude Code → sub-agente nuovo con `model: opus` che riceve solo documenti toccati, diff e richiesta di confrontarli col codice; su Copilot e Codex → nuova chat con gli stessi input, oppure dichiara che la verifica non è isolata.
  7. "Cosa NON fare": aggiungi "Non dichiarare aggiornato un documento confrontato solo in parte" e "Non riproporre la wiki card se esiste già".
  8. Footer: `*Skill v1.2 - dr-professor - 2026-10-30 — claude-opus-5-5 — confronto col codice, rendiconto del non controllato, verifica a freddo, cartella e lingua reali, wiki card esistente (davraf-amuro/dr-guidelines#31)*`
- **Tool ammessi**: Edit
- **Verifica passo**: i sei punti della sezione "Comportamento atteso" della issue sono coperti ciascuno da una regola esplicita nella skill; nessuna regola corretta della v1.1 è stata rimossa
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Rigenera la copia Codex
- **Stato**: [x]
- **Dipende da**: 1
- **Modello**: sessione
- **Precondizione**: fase 1 `[x]`
- **File**: `.agents/skills/dr-professor/SKILL.md`
- **Operazione**: EDIT (generato)
- **Azione**: `pwsh ./scripts/sync-codex.ps1`, poi `pwsh ./scripts/sync-codex.ps1 -Check`
- **Tool ammessi**: PowerShell
- **Verifica passo**: `-Check` esce con 0 e `git status` mostra modificati solo i due file di Scope (più `plan.md`)
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Verifica finale isolata
- **Stato**: [x]
- **Dipende da**: 2
- **Modello**: opus
- **Precondizione**: fasi 1–2 `[x]`
- **File**: `.ai/plans/2026-10-30-issue-31-professor-confronto-codice/plan.md`
- **Operazione**: EDIT
- **Azione**: `/dr-verify-plan` sul piano, poi controlli locali della CI (parse `.ps1`, JSON, `sync-codex -Check`) e controllo fine riga
- **Tool ammessi**: Agent (opus), PowerShell
- **Verifica passo**: verifica isolata senza divergenze, controlli CI locali verdi
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] Ognuno dei 6 comportamenti attesi della issue #31 ha una regola esplicita in `dr-professor`
- [x] Le regole restano agnostiche dallo stack (l'esempio .NET è un esempio, non l'unico inventario)
- [x] Ogni regola specifica di Claude Code (sub-agente, `model: opus`, `/dr-verify-plan`) ha accanto l'alternativa per Copilot e Codex
- [x] `.agents/skills/dr-professor/SKILL.md` generata dallo script, `sync-codex.ps1 -Check` esce con 0
- [x] Footer della skill a v1.2 con riferimento alla issue
- [x] Nessun file fuori Scope modificato

## Esito verifica
- Verifica isolata (sub-agente opus, 2026-10-30): CONFORME, nessuna divergenza
- Osservazioni non bloccanti applicate dopo la verifica: ricerca della wiki card estesa ai documenti esclusi da git senza `-wiki` nel nome (caso reale della issue: `DOC/card-coverage-api.md`); frase su `docs/` in "Il tuo ruolo" allineata alla regola della cartella reale
- Gate di Push: parse `.ps1`, JSON, `sync-codex -Check` e fine riga puliti; lint non applicabile (repo di documenti e script)
