# Piano: Riallineare il documento di architettura al codice a fine piano e verificarlo a freddo
Data: 2026-10-09
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#11

## Obiettivo
A fine piano un documento che descrive il sistema (es. `docs/architettura.md`) descrive il sistema realizzato: il piano contiene una fase di riallineamento e la verifica finale in contesto isolato confronta il documento col codice, segnalando le divergenze.

## Contesto
- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/11
- Problema: in dr-mailroom `docs/architettura.md` v1.0, scritto prima del codice, a fine implementazione era impreciso (chi crea il `Run`, origine del 409, momento del checkpoint, stato `Deleted` e due colonne mancanti, limiti noti solo nel piano). Nessun controllo l'ha intercettato.
- Verifica sui file (2026-10-09):
  - `.github/instructions/plan-tracking.instructions.md` v1.6: template (righe 35-70) e Fase 4 (righe 84-101) non parlano di documenti scritti prima del codice. Fase 4 punto 4 è già neutro ("contesto isolato… su Claude Code: `dr-verify-plan`").
  - `.claude/skills/dr-verify-plan/SKILL.md` v1.1: il subagente confronta i file di Scope con le Azioni del piano, non un documento col codice.
  - `architecture-doc.instructions.md` non esiste ancora: la crea il piano della issue #10.
  - Il template di `dr-issues-to-plans` impone che l'**ultima** fase sia la verifica isolata: la fase di riallineamento va quindi **penultima**, non "finale" come scrive la issue.
- Consultazione `/dr-prompt-engineer` (sola lettura):
  - **Ordine**: prima #10, poi #11; altrimenti plan-tracking rimanda a una fonte inesistente.
  - **Fonte unica**: il *cosa* confrontare (flussi, modello dati, Limiti noti) sta in `architecture-doc.instructions.md`, sezione "Riallineamento a fine implementazione"; in plan-tracking solo il *quando*, con rimando. L'incremento di revisione lo dice già `doc-versioning`.
  - **plan-tracking**: Fase 0, nuova sottosezione "Documenti scritti prima del codice" (fase di riallineamento penultima, documento in Scope); Fase 4, nuovo punto "documento descrittivo in Scope → affermazioni confrontate col codice; differenza = divergenza". Copre Claude Code e Copilot.
  - **dr-verify-plan**: il principio "il subagente riceve solo il piano" regge: il documento entra nello Scope tramite la fase di riallineamento. Estensione: almeno 3 affermazioni verificabili a campione (un flusso, un'entità del modello dati, un limite noto), lettura in sola lettura anche di codice fuori Scope, esito CONFERMATA / DIVERGENTE + `file:riga`; DIVERGENTE = NON CORRISPONDE.
  - `dr-issues-to-plans` (skill e prompt), `dev-cycle`, `doc-versioning`, `copilot-instructions`: invariati.

## Decisioni aperte
1. **Ambito** — generalizzare a "documenti in `docs/` che descrivono il funzionamento del sistema" con `docs/architettura.md` come esempio (consigliato) o restare su `docs/architettura.md`.
2. **Trigger** — solo documento creato nello stesso piano prima dell'implementazione (come la issue) oppure anche piani che cambiano codice già descritto da un documento esistente (caso più frequente, oggi scoperto).
3. **Campione in dr-verify-plan** — numero di affermazioni (proposta: almeno 3) e autorizzazione esplicita a leggere codice fuori Scope.
4. **Incremento di revisione al riallineamento** — +0.1 come `doc-versioning`, o maggiore se cambiano i diagrammi.
5. **Dove vive la sezione di riallineamento** — già inclusa in `architecture-doc` dal piano #10 (decisione 7 di quel piano) o aggiunta qui (Fase 1).

### Decisioni prese (utente, 2026-10-09: "tutte le consigliate"; dove manca una consigliata, la più conservativa)
1. Generalizzato: "documenti in `docs/` che descrivono il funzionamento del sistema", con `docs/architettura.md` come esempio.
2. Trigger ampio: sia documento creato nel piano prima dell'implementazione, sia piano che cambia codice già descritto da un documento esistente.
3. Almeno 3 affermazioni a campione (un flusso, un'entità del modello dati, una voce di "Limiti noti"); lettura in sola lettura di codice fuori Scope ammessa esplicitamente.
4. +0.1 come `doc-versioning` (+1.0 solo se la struttura cambia radicalmente, regola già esistente).
5. La sezione "Riallineamento a fine implementazione" è già in `architecture-doc.instructions.md` v1.0 (piano #10, commit 0c0480c): la Fase 1 ne verifica solo la presenza, senza modifiche.

## Scope
### File da modificare
- [x] `.github/instructions/architecture-doc.instructions.md` — sezione "Riallineamento a fine implementazione" (solo se decisione 5 la assegna a questo piano) — verificato, non modificato (righe 124-138: tre ambiti presenti; il "quando" rimanda a `plan-tracking.instructions.md`)
- [x] `.github/instructions/plan-tracking.instructions.md` — Fase 0: sottosezione "Documenti scritti prima del codice"; Fase 4: nuovo punto; footer v1.7 — titolo effettivo "Documenti che descrivono il sistema" (trigger ampio, decisione 2); il nuovo punto è il sotto-punto 3a, senza rinumerare: i riferimenti "Fase 4, punto 4/5" in dr-verify-plan e dr-issues-to-plans restano validi
- [x] `.claude/skills/dr-verify-plan/SKILL.md` — istruzione al subagente estesa; passo 4: DIVERGENTE = NON CORRISPONDE; footer v1.2
- [x] `README.md` / `docs/` — solo se descrivono il contenuto di dr-verify-plan o della Fase 4 — README.md:375 esteso (confronto documento/codice), footer v3.14; `docs/`: nessun riscontro (grep senza risultati), non modificato

### Perimetro negativo
- Non toccherò: `dev-cycle.instructions.md`, `doc-versioning.instructions.md`, `copilot-instructions.md`, `dr-issues-to-plans` (skill e prompt), `dr-professor`, il template di piano oltre alla nuova sottosezione, il principio "il subagente non riceve diff né ragionamento".

## Fasi (formato atomico — obbligatorio)

### Fase 1: Sezione di riallineamento in architecture-doc (condizionale)
- **Stato**: [x]
- **Precondizione**: piano della issue #10 `COMPLETATO`; decisioni aperte 1-5 risolte; decisione 5 = "aggiunta qui"
- **File**: `.github/instructions/architecture-doc.instructions.md`
- **Operazione**: EDIT
- **Azione**: Aggiungi la sezione "Riallineamento a fine implementazione": confronta ogni "Come funziona <flusso>" (chi crea cosa, dove nasce un errore, quando si salva lo stato) e il Modello dati (tabelle, colonne, stati/enum) col codice reale; sposta in "Limiti noti" i limiti emersi durante l'implementazione; aggiorna la revisione (decisione 4). Footer v1.1. Decisione 5 = "già in #10" → verifica che la sezione esista e marca la fase.
- **Tool ammessi**: nessuno
- **Verifica passo**: la sezione esiste nell'istruzione con i tre ambiti (flussi, modello dati, limiti noti)
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: plan-tracking — quando riallineare
- **Stato**: [x]
- **Precondizione**: Fase 1 completata
- **File**: `.github/instructions/plan-tracking.instructions.md`
- **Operazione**: EDIT
- **Azione**: In Fase 0, dopo il template, aggiungi la sottosezione "Documenti scritti prima del codice": se il piano crea o modifica (secondo decisioni 1-2) un documento che descrive il sistema, inserisce una fase "Riallinea il documento al codice", con il documento in Scope, **subito prima** della verifica finale; il *cosa* confrontare sta nell'istruzione del documento (es. `architecture-doc.instructions.md`). In Fase 4 aggiungi un punto tra 3 e 4: "Documento descrittivo in Scope → le sue affermazioni si confrontano col codice reale; una differenza è una divergenza". Footer v1.7 con data e modello.
- **Tool ammessi**: nessuno
- **Verifica passo**: sottosezione presente in Fase 0, nuovo punto in Fase 4, numerazione coerente, testo neutro Claude/Copilot, footer v1.7
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: dr-verify-plan — confronto documento/codice
- **Stato**: [x]
- **Precondizione**: Fase 2 completata
- **File**: `.claude/skills/dr-verify-plan/SKILL.md`
- **Operazione**: EDIT
- **Azione**: Estendi l'istruzione al subagente: se lo Scope contiene un documento che descrive il sistema, scegli almeno N affermazioni verificabili (decisione 3: un flusso, un'entità del modello dati, una voce di "Limiti noti"), confrontale col codice reale leggendo anche file fuori Scope in sola lettura, riporta CONFERMATA / DIVERGENTE + `file:riga`; un'affermazione senza riscontro è DIVERGENTE. Al passo 4: DIVERGENTE equivale a NON CORRISPONDE. Lascia invariata la regola "nessun diff, nessun ragionamento dell'implementatore". Footer v1.2.
- **Tool ammessi**: nessuno
- **Verifica passo**: istruzione estesa presente; passo 4 aggiornato; regole di isolamento invariate; footer v1.2
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: Documentazione
- **Stato**: [x]
- **Precondizione**: Fase 3 completata
- **File**: `README.md`, `docs/*.md` individuati con `grep -rn -i "dr-verify-plan\|verifica finale" README.md docs/`
- **Operazione**: EDIT (solo se i testi descrivono cosa controlla dr-verify-plan)
- **Azione**: Aggiorna le descrizioni di dr-verify-plan e della verifica finale con il confronto documento/codice. Nessun riscontro → dichiaralo in plan.md e marca la fase.
- **Tool ammessi**: `/dr-professor`
- **Verifica passo**: nessuna descrizione residua contraddice il nuovo comportamento
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Verifica finale in contesto isolato
- **Stato**: [x] — `/dr-verify-plan` 2026-10-09: 4/4 file CORRISPONDONO, 6/6 criteri SODDISFATTI. Dopo la verifica: `architecture-doc.instructions.md` riga 126 allineata al trigger ampio della decisione 2 (v1.1)
- **Precondizione**: Fasi 1-4 completate
- **File**: questo `plan.md`
- **Operazione**: EDIT
- **Azione**: Esegui la verifica finale di `plan-tracking.instructions.md` Fase 4, punto 4, in un contesto isolato (su Claude Code: `/dr-verify-plan`); poi aggiorna `Stato`.
- **Tool ammessi**: `/dr-verify-plan`
- **Verifica passo**: tutti i file CORRISPONDONO e tutti i criteri SODDISFATTI
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] `plan-tracking.instructions.md` prescrive la fase di riallineamento penultima per i documenti descrittivi, con rimando all'istruzione del documento
- [x] `plan-tracking.instructions.md` Fase 4 tratta come divergenza una differenza documento/codice
- [x] `dr-verify-plan` confronta a campione documento e codice e riporta CONFERMATA / DIVERGENTE con `file:riga`
- [x] Il subagente di `dr-verify-plan` continua a non ricevere diff né ragionamento dell'implementatore
- [x] `architecture-doc.instructions.md` contiene la sezione di riallineamento (in #10 o qui)
- [x] Testi in `.github/` neutri, compatibili con Claude Code e Copilot
