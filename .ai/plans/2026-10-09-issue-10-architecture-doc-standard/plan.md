# Piano: Documento di architettura standard (docs/architettura.md) — istruzione, prompt, dr-professor
Data: 2026-10-09
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#10

## Obiettivo
Quando un piano o l'utente chiede il documento di architettura, Claude Code (via `dr-professor`) e Copilot (via prompt) producono sempre la stessa struttura in 8 sezioni con diagrammi Mermaid, definita in un'unica istruzione.

## Contesto
- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/10
- Problema: nessuna istruzione o template descrive il documento di architettura; struttura e formato degli schemi dipendono dall'agente. In dr-mailroom l'agente ha scelto da solo Mermaid, tabelle D/T/C e "Cosa il servizio non fa": risultato apprezzato, da rendere standard.
- Verifica sui file (2026-10-09): `architecture-doc.instructions.md` e `architecture-doc.prompt.md` non esistono; `.claude/skills/dr-professor/SKILL.md` ha la tabella "Template per task singolo" (righe 42-47) senza voce di architettura e procede "con lo stile generico" (riga 49); `doc-versioning.instructions.md` (`applyTo: docs/**/*.md`) copre già `docs/architettura.md`; l'installer copia tutto `.github/instructions` e `.github/prompts` (nessuna modifica a catalogo/installer).
- Consultazione `/dr-prompt-engineer` (sola lettura):
  - **Fonte unica = l'istruzione** (sezioni, ordine, condizioni, schema ID, solo Mermaid). Il prompt contiene solo la procedura (fonti da leggere, rimando all'istruzione, fallback "Da verificare", checklist), frontmatter come `onboarding-senior` (`tools: ['search/codebase','edit/editFiles']`).
  - **Sezioni condizionali**, con frase fissa invece della sezione vuota: Modello dati solo se c'è persistenza ("Il progetto non persiste dati."); Decisioni T solo se c'è stato un warroom; Limiti noti vuoti → "Nessun limite noto alla revisione vN".
  - **Decisioni**: oggi il template di piano non ha sezione Decisioni né ID, e il warroom non resta su disco → la regola "ogni decisione del piano compare" va resa verificabile: decisioni senza ID ricostruite e marcate "Da verificare". ID stabili, mai rinumerati; superate → "Sostituita da …". Possibile collisione con fasi chiamate "D1-D3" in piani esistenti.
  - Ambiguità da chiudere: definire "flusso principale" (percorso che attraversa ≥ 2 componenti); "cosa resta fuori" nell'Introduzione rimanda a "Cosa il sistema non fa"; footer = `doc-versioning`.
  - Nome `architettura.md` coerente con `docs/` (italiano kebab-case); `architecture-doc.*` coerente con `.github/`.
  - dr-professor: riga nel task singolo; passo **condizionale** nella documentazione completa, dopo la card e prima di onboarding (condizione: esiste un piano in `.ai/plans/` oppure `docs/architettura.md` esiste già).
  - Altri file: `README.md` (tabella istruzioni modulari), `docs/onboarding.md` (tabella regola→istruzione, righe 108-109), `docs/test-progetto-host.md:142` (conteggio prompt), `docs/bozza-manuale-installazione.md` (documento vivo).
  - Predisposizioni per #11: l'istruzione definisce lo schema ID e una sezione di riallineamento a fine implementazione può viverci (fonte unica, vedi piano #11).
- Correlazioni: #11 dipende da questo piano (va eseguito dopo). Il piano #12 modifica anch'esso la tabella "Documentazione completa" di dr-professor: eseguire in sequenza, rinumerando.

## Decisioni aperte
1. **Forma degli ID** — `D1/T1/C1` (come la issue) o `D-01/T-01/C-01`; ID validi solo nel documento o globali di progetto.
2. **Sezione "Decisioni" nel template dei piani** — aggiungerla ora (sconfina in plan-tracking, vicino a #11) o lasciarla a un'issue successiva.
3. **Passo nella documentazione completa** — condizionale (consigliato) o sempre.
4. **onboarding-senior rimanda ad architettura.md** quando esiste (evita doppia motivazione delle scelte) — sì/no; tocca `onboarding-senior.prompt.md`.
5. **Numero massimo di sezioni "Come funziona <flusso>"** — proposta: da 1 a 5.
6. **Un documento per repo o per solution** (progetti multi-repo).
7. **Sezione "Riallineamento a fine implementazione"** dentro l'istruzione (contenuto richiesto da #11): includerla già qui (v1.0) o aggiungerla con #11 (v1.1).

### Decisioni prese (utente, 2026-10-09: "tutte le consigliate"; dove manca una consigliata, la più conservativa)
1. ID `D1/T1/C1` (come la issue), validi solo dentro il documento; stabili, mai rinumerati; superati → "Sostituita da <ID>".
2. No — il template dei piani non cambia in questo piano.
3. Passo condizionale nella documentazione completa (esiste un piano in `.ai/plans/` oppure `docs/architettura.md` esiste già).
4. No — `onboarding-senior.prompt.md` non si tocca: la Fase 4 si salta.
5. Da 1 a 5 sezioni "Come funziona <flusso>".
6. Un documento per repo.
7. Sì — la sezione "Riallineamento a fine implementazione" entra già qui (istruzione v1.0); il piano #11 ne verificherà la presenza.

Nota di coordinamento: dopo la issue #12 la documentazione completa di dr-professor ha 5 passi (card, endpoint, onboarding, README, wiki card ultima). Il nuovo passo va dopo la card: 1 card, 2 architettura, 3 endpoint, 4 onboarding, 5 README, 6 wiki card.

## Scope
### File da modificare
- [x] `.github/instructions/architecture-doc.instructions.md` — CREATE: struttura obbligatoria e regole (fonte unica)
- [x] `.github/prompts/architecture-doc.prompt.md` — CREATE: procedura di generazione per Copilot
- [x] `.claude/skills/dr-professor/SKILL.md` — riga task singolo + passo condizionale nella documentazione completa
- [x] `.github/prompts/onboarding-senior.prompt.md` — solo se decisione 4 = sì — non toccato, decisione 4
- [x] `.github/copilot-instructions.md` — riga 17, aggiungere `architecture-doc` agli esempi (facoltativo)
- [x] `README.md`, `docs/onboarding.md`, `docs/test-progetto-host.md`, `docs/bozza-manuale-installazione.md` — elenchi e conteggi

### Perimetro negativo
- Non toccherò: `plan-tracking.instructions.md` e `dr-verify-plan` (issue #11; eccezione: decisione 2 = sì), installer e catalogo, `doc-versioning.instructions.md`, `readme-structure.instructions.md` (issue #9), `card-*` (issue #12), pacchetti di dominio.

## Fasi (formato atomico — obbligatorio)

### Fase 1: Istruzione architecture-doc
- **Stato**: [x]
- **Precondizione**: Decisioni aperte 1-7 risolte dall'utente
- **File**: `.github/instructions/architecture-doc.instructions.md`
- **Operazione**: CREATE
- **Azione**: Crea l'istruzione con `applyTo: "docs/architettura.md"` e le 8 sezioni della issue in ordine (Introduzione; Come sono fatti i componenti con flowchart + tabella `Componente | Ruolo`; Decisioni `# | Tema | Decisione` con prefissi D/T/C secondo decisione 1, ID stabili e "Sostituita da"; una "Come funziona <flusso>" per flusso principale con diagramma + "Regole che valgono"; Modello dati con tabella + erDiagram, condizionale; Cosa il sistema non fa; Limiti noti `Limite | Effetto | Come si rimedia`; footer `doc-versioning`). Per ogni sezione condizionale la frase fissa. Definisci "flusso principale", "solo Mermaid", "mai inventare: Da verificare", la regola "ogni decisione del piano compare" con il fallback per i piani senza ID. Sezione di riallineamento secondo decisione 7. Footer di template v1.0.
- **Tool ammessi**: nessuno
- **Verifica passo**: le 8 sezioni compaiono in ordine con le tabelle e i tipi di diagramma richiesti; nessuna sintassi esclusiva di un solo agente; footer presente
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Prompt architecture-doc
- **Stato**: [x]
- **Precondizione**: Fase 1 completata
- **File**: `.github/prompts/architecture-doc.prompt.md`
- **Operazione**: CREATE
- **Azione**: Crea il prompt con frontmatter come `onboarding-senior.prompt.md`; procedura: leggi i piani in `.ai/plans/`, il manifest `.ai/dr-guidelines-packages.json` e le istruzioni installate (decisioni C), entry point, componenti, persistenza (DbContext/migrazioni o equivalente); applica `.github/instructions/architecture-doc.instructions.md` senza ricopiarne la struttura; fallback "Da verificare"; checklist post-generazione (8 sezioni, Mermaid, decisioni del piano presenti, footer).
- **Tool ammessi**: nessuno
- **Verifica passo**: il prompt rimanda all'istruzione e non duplica l'elenco delle sezioni; checklist presente
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Integrazione in dr-professor
- **Stato**: [x]
- **Precondizione**: Fase 2 completata
- **File**: `.claude/skills/dr-professor/SKILL.md`
- **Operazione**: EDIT
- **Azione**: Aggiungi la riga `Documento di architettura | .github/prompts/architecture-doc.prompt.md | docs/architettura.md` in "Template per task singolo"; nella tabella "Documentazione completa" aggiungi il passo dopo la card e prima di onboarding, con la condizione della decisione 3, rinumerando i passi.
- **Tool ammessi**: nessuno
- **Verifica passo**: la riga task singolo esiste; il passo compare nella posizione indicata con condizione; numerazione continua
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: Rimando da onboarding (condizionale)
- **Stato**: [x] — saltata per decisione 4
- **Precondizione**: Fase 3 completata; decisione 4 = sì
- **File**: `.github/prompts/onboarding-senior.prompt.md`
- **Operazione**: EDIT
- **Azione**: Nella sezione sulle scelte tecniche: se `docs/architettura.md` esiste, rimanda alle sue Decisioni invece di rimotivarle. Aggiorna il footer. Decisione 4 = no → marca la fase come saltata.
- **Tool ammessi**: nessuno
- **Verifica passo**: rimando presente, oppure fase dichiarata saltata
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Documentazione e riferimenti
- **Stato**: [x]
- **Precondizione**: Fase 4 completata o saltata
- **File**: `README.md`, `docs/onboarding.md`, `docs/test-progetto-host.md`, `docs/bozza-manuale-installazione.md`, `.github/copilot-instructions.md`
- **Operazione**: EDIT
- **Azione**: Aggiungi `architecture-doc.instructions.md` alla tabella "Istruzioni Modulari" del README (rispettando `readme-structure.instructions.md`) e alla tabella regola→istruzione di `docs/onboarding.md`; aggiorna il conteggio dei prompt in `docs/test-progetto-host.md`; annota nella bozza; aggiungi `architecture-doc` agli esempi di `copilot-instructions.md` riga 17. Footer secondo le rispettive regole.
- **Tool ammessi**: `/dr-professor`
- **Verifica passo**: `grep -rn "architecture-doc" README.md docs/ .github/copilot-instructions.md` trova le nuove voci; conteggi corretti
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: Verifica finale in contesto isolato
- **Stato**: [x] — `/dr-verify-plan` 2026-10-09: 9/9 file CORRISPONDONO, 5/5 criteri SODDISFATTI; corretto dopo la verifica il conteggio skill (17) in `docs/bozza-manuale-installazione.md:155`
- **Precondizione**: Fasi 1-5 completate
- **File**: questo `plan.md`
- **Operazione**: EDIT
- **Azione**: Esegui la verifica finale di `plan-tracking.instructions.md` Fase 4, punto 4, in un contesto isolato (su Claude Code: `/dr-verify-plan`); poi aggiorna `Stato`.
- **Tool ammessi**: `/dr-verify-plan`
- **Verifica passo**: tutti i file CORRISPONDONO e tutti i criteri SODDISFATTI
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] `architecture-doc.instructions.md` esiste, `applyTo: "docs/architettura.md"`, 8 sezioni in ordine, solo Mermaid, sezioni condizionali con frase fissa
- [x] `architecture-doc.prompt.md` esiste, rimanda all'istruzione senza duplicarla
- [x] `dr-professor` instrada il task "documento di architettura" sul prompt e lo include nella documentazione completa con condizione
- [x] README e docs elencano la nuova istruzione e il nuovo prompt
- [x] Istruzione e prompt sono markdown neutro, compatibili con Claude Code e Copilot
