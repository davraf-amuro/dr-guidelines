# Piano: Wiki card — conferma esplicita prima di leggere i segreti, generata per ultima
Data: 2026-10-09
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#12

## Obiettivo
La wiki card si genera solo dopo una conferma esplicita dell'utente, con `docs/*-wiki.md` verificato in `.gitignore` prima della scrittura, ed è sempre l'ultimo passo della documentazione completa; senza conferma si salta senza bloccare gli altri documenti.

## Contesto
- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/12
- Problema: in dr-mailroom `/dr-professor scrivi la documentazione` ha letto `appsettings.local.json` e `.env` al passo 1 (card). L'auto mode di Claude Code ha bloccato la wiki card (Credential Leakage) e poi anche endpoint e onboarding, privi di segreti.
- Verifica sui file (2026-10-09):
  - `.github/prompts/card-wiki-generator.prompt.md` (v1.0): righe 10 e 17-24 ordinano di leggere i valori reali senza gate. Il controllo `.gitignore` è solo una nota (riga 12) e una voce di checklist post-generazione (riga 165). `.env` non è tra le sorgenti elencate, ma nessuna regola limita le letture. Nessun fallback per rifiuto.
  - `.github/prompts/card-project-generator.prompt.md` (v2.3): righe 25-30 e 46-48 accoppiano card standard e wiki card "per ogni progetto"; colonna "Template wiki card" nella tabella di rilevamento (righe 39-44); regola riga 113; checklist righe 126, 129, 130.
  - `.claude/skills/dr-professor/SKILL.md`: tabella "Documentazione completa" passo 1 = card (che trascina la wiki); "senza attendere conferma tra un passo e l'altro" (riga 20) contrasta con una conferma dentro un passo.
  - `.gitignore` del core contiene già `docs/*-wiki.md` (riga 11), ma un host può avere un `.gitignore` divergente: serve il controllo a runtime.
- Consultazione `/dr-prompt-engineer` (sola lettura): raccomanda di **separare** la wiki card da card-project-generator (che genera solo la card standard) e di renderla l'ultimo passo di dr-professor; domanda di conferma in testo prescritto, neutro (niente nomi di tool nei prompt `.github`); verifica `.gitignore` prima della scrittura, proponendo l'aggiunta del pattern nella stessa domanda; regola "un passo saltato o bloccato non interrompe i successivi". Nota: anche con conferma il classifier può negare la scrittura; il fallback copre anche quel caso.

## Decisioni aperte
1. **Separare o riordinare** — (A, consigliata) card-project-generator genera solo la card standard, la wiki card è un passo separato e ultimo; (B) card-project-generator le tiene entrambe con la wiki per ultima. Il piano è scritto per **A**: con B cambiano le Fasi 2 e 3.
2. **`.gitignore` senza pattern** — (A, consigliata) chiedere di aggiungerlo nella stessa domanda di conferma e aggiungerlo solo su sì; (B) solo segnalare e saltare la wiki card.
3. **Elenco file con segreti** — chiuso (tabella sorgenti + `.env`) o aperto ("e simili"). Consigliato: elenco esplicito con `.env` e `*.local.*`, più "qualsiasi file escluso da git che contiene valori di configurazione".
4. **Momento della domanda nella documentazione completa** — (A, consigliata) all'inizio, una sola interruzione, risposta valida fino all'ultimo passo; (B) al momento del passo wiki.

### Decisioni prese (utente, 2026-10-09: "tutte le consigliate")
1. A — wiki card separata da card-project-generator, ultimo passo in dr-professor.
2. A — pattern assente: chiedere l'aggiunta nella stessa domanda; si aggiunge solo su sì.
3. Elenco esplicito (tabella sorgenti + `.env`, `*.local.*`) più "qualsiasi file escluso da git che contiene valori di configurazione".
4. A — nella documentazione completa la domanda si pone all'inizio, una sola volta; la risposta vale fino all'ultimo passo.

## Scope
### File da modificare
- [x] `.github/prompts/card-wiki-generator.prompt.md` — gate di conferma, verifica `.gitignore` prima della scrittura, fallback "salta e dichiara", checklist, footer v1.1
- [x] `.github/prompts/card-project-generator.prompt.md` — solo card standard, rimando alla wiki card come passo separato, checklist, footer v2.4
- [x] `.claude/skills/dr-professor/SKILL.md` — wiki card come ultimo passo condizionato, riga task singolo, regola "passo saltato non blocca i successivi"
- [x] `docs/` e `README.md` — solo se descrivono l'ordine card → wiki (da verificare in Fase 4)

### Perimetro negativo
- Non toccherò: `.gitignore` del core, installer `.ps1`, `sensitive-data.instructions.md`, i prompt `card-minimal-api`/`card-worker-service` dei pacchetti di dominio (se servono modifiche → `/dr-file-feedback` sul pacchetto), `readme-structure.instructions.md` (oggetto della issue #9).

## Fasi (formato atomico — obbligatorio)

### Fase 1: Gate di conferma in card-wiki-generator
- **Stato**: [x]
- **Precondizione**: Decisioni aperte 1-4 risolte dall'utente
- **File**: `.github/prompts/card-wiki-generator.prompt.md`
- **Operazione**: EDIT
- **Azione**: Aggiungi, prima di "File da analizzare", una sezione "Conferma prima di leggere" che: elenca i file con valori reali (decisione 3); prescrive la domanda testuale «Genero la wiki card con i valori reali presi da `<file trovati>`. È un documento privato, escluso da git. Confermi? (sì/no)» e l'attesa della risposta; verifica che `docs/*-wiki.md` sia in `.gitignore` **prima** di leggere e scrivere (comportamento secondo decisione 2); senza "sì" esplicito, o con scrittura negata, scrive esattamente «Wiki card saltata: conferma non ricevuta. Gli altri documenti non sono interessati.» e termina senza leggere i file. Aggiorna la checklist (conferma ricevuta, pattern verificato prima della scrittura) e il footer a v1.1 con data e modello.
- **Tool ammessi**: nessuno
- **Verifica passo**: il file contiene la sezione di conferma prima di "File da analizzare", il testo della domanda, il testo di fallback, la verifica `.gitignore` prima della scrittura; nessun nome di tool specifico di un solo agente; footer v1.1
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: card-project-generator genera solo la card standard
- **Stato**: [x]
- **Precondizione**: Fase 1 completata; decisione 1 = A
- **File**: `.github/prompts/card-project-generator.prompt.md`
- **Operazione**: EDIT
- **Azione**: Riduci la sezione Output alla sola card standard, con il rimando "La wiki card è un passo separato: `.github/prompts/card-wiki-generator.prompt.md`, da eseguire solo su richiesta esplicita e per ultima". Togli la colonna "Template wiki card" dalla tabella di rilevamento, il punto 2 "Genera wiki card", la regola sulla wiki card e le voci di checklist su wiki/"entrambe le card". Footer a v2.4.
- **Tool ammessi**: nessuno
- **Verifica passo**: `grep -n -i wiki` sul file restituisce solo il rimando; footer v2.4
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Wiki card ultima in dr-professor
- **Stato**: [x]
- **Precondizione**: Fase 2 completata
- **File**: `.claude/skills/dr-professor/SKILL.md`
- **Operazione**: EDIT
- **Azione**: Nella tabella "Documentazione completa" aggiungi come ultimo passo la wiki card (`card-wiki-generator.prompt.md` → `docs/card-<progetto>-wiki.md`, condizione "solo con conferma esplicita"); prescrivi la domanda secondo la decisione 4 (consentito `AskUserQuestion` se disponibile); aggiungi la regola "Un passo saltato o bloccato non interrompe i successivi: dichiaralo e prosegui". Aggiungi la riga "Wiki card operativa" nella tabella "Template per task singolo". Allinea la riga del passo 1 (solo card standard).
- **Tool ammessi**: nessuno
- **Verifica passo**: la wiki card è l'ultima riga della tabella, con condizione di conferma; la regola sul passo saltato è presente; la riga task singolo esiste
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: Allineamento documentazione
- **Stato**: [x]
- **Precondizione**: Fase 3 completata
- **File**: `README.md`, `docs/*.md` che descrivono l'ordine card → wiki (individuati con `grep -rn -i "wiki" README.md docs/`)
- **Operazione**: EDIT (solo se il grep trova testi che descrivono il vecchio ordine o l'accoppiamento)
- **Azione**: Aggiorna i soli passaggi che descrivono la wiki card generata insieme alla card standard; footer secondo `doc-versioning` (docs/) o footer del README. Nessun riscontro → dichiaralo in plan.md e marca la fase.
- **Tool ammessi**: `/dr-professor` per la riscrittura dei testi
- **Verifica passo**: nessun testo residuo afferma che card-project-generator genera anche la wiki card
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere
- **Esito (2026-10-09)**: nessun riscontro. `grep -rn -i wiki README.md docs/` trova solo `docs/bozza-manuale-installazione.md:154` e `docs/test-progetto-host.md:142`, che elencano i nomi dei prompt installati senza descrivere ordine o accoppiamento card → wiki. Nessun file modificato.

### Fase 5: Verifica finale in contesto isolato
- **Stato**: [x] — `/dr-verify-plan` 2026-10-09: 4/4 file CORRISPONDONO, 7/7 criteri SODDISFATTI
- **Precondizione**: Fasi 1-4 completate
- **File**: questo `plan.md`
- **Operazione**: EDIT
- **Azione**: Esegui la verifica finale di `plan-tracking.instructions.md` Fase 4, punto 4, in un contesto isolato (su Claude Code: `/dr-verify-plan`); poi aggiorna `Stato`.
- **Tool ammessi**: `/dr-verify-plan`
- **Verifica passo**: tutti i file CORRISPONDONO e tutti i criteri SODDISFATTI
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] `card-wiki-generator.prompt.md` chiede conferma esplicita **prima** di leggere qualsiasi file con valori reali
- [x] `card-wiki-generator.prompt.md` verifica `docs/*-wiki.md` in `.gitignore` prima della scrittura
- [x] `card-wiki-generator.prompt.md` contiene il fallback "salta e dichiara" che non blocca altri documenti
- [x] `card-project-generator.prompt.md` non genera più la wiki card (solo rimando)
- [x] In `dr-professor` la wiki card è l'ultimo passo della documentazione completa, condizionato alla conferma
- [x] I prompt in `.github/prompts/` non usano feature esclusive di un solo agente
- [x] Footer aggiornati: card-wiki-generator v1.1, card-project-generator v2.4
