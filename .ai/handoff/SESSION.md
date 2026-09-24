# Sessione 2026-09-22 → 2026-09-24

## 1. Lettura delle issue aperte

- **Cosa**: `/dr-issues-to-plans` sul repository corrente. `gh` autenticato come `davraf-amuro`. Lette 5 issue aperte, verificato che nessun piano esistente avesse il campo `Issue:` e che nessun piano fosse `IN CORSO`.
- **Perché**: la skill impone di non duplicare issue già pianificate e di consigliare il completamento dei piani in corso prima di aprirne altri.
- **Risultato**: 5 issue tutte pianificabili.

## 2. Verifica dei file citati dalle issue

- **Cosa**: letti i file, le righe e le funzioni che ciascuna issue nomina.
- **Perché**: la skill impone di verificare che quanto la issue riporta esista ancora e dica quello che afferma.
- **Risultato**: tre discrepanze, tutte annotate nei piani. `Copy-CoreConfigFiles` è a riga 207, non 176. Il secondo punto del README è a riga 455, non 442. I punti da correggere nel prompt Copilot sono tre, non uno. La issue #4 cita `dr-segnala-miglioria`, skill rinominata in `dr-file-feedback` dal commit `4bc6f71`.

## 3. Consultazioni

- **Cosa**: 4 sub-agenti in parallelo — `/dr-warroom` per le issue #1 e #5, `/dr-prompt-engineer` per le #3 e #4 — con divieto esplicito di scrivere file.
- **Perché**: instradamento previsto dalla tabella al passo 4 di `/dr-issues-to-plans`.
- **Risultato**: tre fatti che le issue non conoscevano e che hanno cambiato la soluzione. Gli `ISSUE_TEMPLATE` non vengono distribuiti negli host. L'installer risolve le dipendenze senza leggere `appliesTo`. `doc-versioning.instructions.md` cattura `docs/**/*.md`, il che esclude `docs/` come sede dei brief.

## 4. Scrittura dei 5 piani

- **Cosa**: un `plan.md` per issue in `.ai/plans/`, stato `PROPOSTO`, campo `Issue:`, fasi atomiche e criteri misurabili.
- **Perché**: `plan-tracking.instructions.md`, sezione "Piani proposti": scrivere un piano non significa eseguirlo.
- **Risultato**: commit `821c738`.

## 5. Scelta del nome della cartella per la issue #1

- **Cosa**: proposti 4 nomi con pro e contro; l'utente ha scelto `briefs/`.
- **Perché**: la issue parlava di "specifiche", ma l'utente ha precisato che il contenuto sono le richieste che scrive lui, da trasformare in piani.
- **Risultato**: piano riscritto con la terminologia corretta e rinominata la cartella in `2026-09-22-issue-1-cartella-briefs`. La distinzione è sostanziale: una specifica descrive il comportamento di un sistema, un brief esprime un bisogno, e il modello del documento cambia di conseguenza.

## 6. Esecuzione del piano della issue #2

- **Cosa**: aggiunta la copia di `.github/copilot-instructions.md` in `Copy-CoreConfigFiles`; rimosso il workaround dal README.
- **Perché**: il `CLAUDE.md` iniettato negli host richiamava un file che l'installer non copiava.
- **Risultato**: commit `6457a3c`. Verifica isolata: tutti i criteri soddisfatti. Due correzioni dopo la verifica: la FAQ consigliava `-Update` dove basta un rilancio normale, e mancava l'avviso a chi aveva copiato il file a mano.

## 7. Esecuzione del piano della issue #3

- **Cosa**: riscritta la regola di STOP su 10 posizioni in 4 file.
- **Perché**: la regola si fermava su qualsiasi cartella non vuota, quindi anche nel flusso consigliato dalla documentazione, dove il core è già installato.
- **Risultato**: commit `a3e0f2c`. Verifica isolata: 10 punti su 10. Tre correzioni dopo la verifica, fra cui l'aggiunta al prompt Copilot della riga-rete che il router Claude Code aveva già: senza, le due superfici documentavano modelli mentali diversi.

## 8. Esecuzione del piano della issue #4

- **Cosa**: struttura dei modelli scritta inline nelle due superfici, label mappate su `bug`/`enhancement`, terzo modello `nuovo-pacchetto.md`, propagazione ai 7 repo.
- **Perché**: i modelli non arrivano negli host, e il front matter `labels:` non si applica con `gh issue create`.
- **Risultato**: commit `77541d7` più 6 commit nei repo pacchetto. Verifica isolata: 18 titoli di sezione su 18 coincidono fra skill, prompt e modelli reali. Due correzioni dopo la verifica: mancava `any` fra i `kind`, e "Progetto host" non aveva una sorgente dichiarata.

## 9. Esecuzione del piano della issue #5

- **Cosa**: nuova istruzione `cross-package-references.instructions.md`; i tre rimandi di `dr-efdb`, `dr-fe`, `dr-devops` resi condizionali al manifest.
- **Perché**: i tre pacchetti citavano una regola di `dr-minimalapi` senza dichiararlo come dipendenza, e il rimando si rompeva in silenzio.
- **Risultato**: commit `176afb1` più 3 commit nei repo pacchetto. Verifica isolata: 9 voci di scope su 9. Quattro correzioni dopo la verifica, fra cui una notevole: i tre blocchi appena scritti citavano la nuova convenzione con un rimando **incondizionato**, cioè violando la regola che la convenzione stessa introduce.

## 10. Issue di follow-up

- **Cosa**: aperte `dr-guidelines#6`, `dr-guidelines#7`, `dr-minimalapi#2`, composte sui modelli appena introdotti e con `--label`.
- **Perché**: tre rilievi emersi in consultazione erano fuori dal perimetro della issue #5; l'utente ha scelto di tracciarli.
- **Risultato**: primo uso reale del canale di feedback dopo la correzione, riuscito.

## 11. Verifica dei processi di installazione

- **Cosa**: parser PowerShell sui due script, `catalog-guard` della CI eseguito in locale, simulazione della copia con libreria locale.
- **Perché**: richiesta esplicita dell'utente prima del push.
- **Risultato**: 0 errori, 0 problemi, tutti i file dei quattro piani presenti nell'host simulato.

## 12. Push e prova end-to-end

- **Cosa**: dichiarata l'assenza di un target di lint applicabile (repository di documenti più due script PowerShell), pushati i 7 repository, poi installazione reale in cartella vuota con clone da GitHub.
- **Perché**: la prova end-to-end era l'ultimo punto in sospeso del piano #2 ed era impossibile prima del push, perché l'installer clona il remoto.
- **Risultato**: `[OK]` alla prima installazione, `[SKIP]` al rilancio, `[UPD]` con `-Update`. Nessun riferimento penzolante nel `CLAUDE.md` dell'host. CI verde. Issue #2, #3, #4, #5 chiuse da GitHub tramite `Closes`. Commit `fe9dee9`.
