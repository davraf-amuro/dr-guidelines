Stai riprendendo il lavoro su `dr-guidelines`, pacchetto core della suite `dr-*`: linee guida, istruzioni modulari, prompt e skill per Claude Code e GitHub Copilot, distribuiti come pacchetti installabili via PowerShell.

Workspace: `E:\Davide\Progetti\dr-guidelines-workspace\`, con i 7 repository `dr-*` come sottocartelle sorelle (`dr-guidelines`, `dr-dotnet-backend`, `dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`). Repository su GitHub sotto `davraf-amuro`.

Rispondi sempre in italiano.

## Regole del progetto da rispettare

- `CLAUDE.md` nella radice e `.github/copilot-instructions.md` sono vincolanti. Leggili prima di scrivere codice.
- Ogni regola, istruzione o convenzione condivisa deve funzionare **sia con Claude Code sia con GitHub Copilot**. Esenti solo i file in `.claude/skills/`. Se la compatibilità non è garantita, fermati e chiedi.
- Task con due o più operazioni: piano su disco in `.ai/plans/<YYYY-MM-DD>-<slug>/plan.md` prima di agire, secondo `.github/instructions/plan-tracking.instructions.md`.
- Un piano si chiude solo dopo verifica in contesto isolato, con `/dr-verify-plan`.
- Prima di ogni `git push`: questi repository non hanno un target di lint applicabile (documenti più due script PowerShell). Va **dichiarato esplicitamente**, e al suo posto si eseguono il parser PowerShell sugli `.ps1` e il `catalog-guard` della CI in locale.
- La cartella `TODO/` è locale e non si committa.

## Stato

- Le issue `#2`, `#3`, `#4`, `#5` di `dr-guidelines` sono chiuse: i rispettivi piani in `.ai/plans/` sono `COMPLETATO`, verificati e pushati.
- Tutti e 7 i repository hanno working tree pulito e niente da pushare. CI verde.
- Resta aperta la issue `#1`, con piano `PROPOSTO`.
- Tre issue di follow-up aperte: `dr-guidelines#6`, `dr-guidelines#7`, `dr-minimalapi#2`.

## File rilevanti

- `.ai/handoff/HANDOFF.md` — stato completo, file modificati, problemi aperti, validazione eseguita
- `.ai/handoff/DECISIONI.md` — decisioni della sessione precedente con motivazioni e conseguenze
- `.ai/plans/2026-09-22-issue-1-cartella-briefs/plan.md` — il piano da eseguire
- `.github/instructions/cross-package-references.instructions.md` — convenzione introdotta nella sessione precedente
- `.github/instructions/plan-tracking.instructions.md` — formato dei piani e stato `PROPOSTO`

## Problemi aperti

- L'installer risolve le dipendenze in automatico e ricorsivamente, senza conferma e senza leggere `appliesTo` (`dr-guidelines#6`).
- Il catalogo non ha un campo per i rimandi non vincolanti (`dr-guidelines#7`).
- `PersistKeysToDbContext` in scale-out: tabella da creare prima delle repliche concorrenti (`dr-minimalapi#2`).
- Non tracciati: `dr-file-feedback.prompt.md` dichiara `tools: ['search/codebase']` ma prescrive comandi `gh`; `dr-efdb` è offerto ai Worker ma i suoi file di istruzione sono scritti per una Minimal API; `dr-scaffold-solution` esegue `git init` incondizionato e reinstalla il core anche quando è già nel manifest; `Copy-GuidelineFile` esce in silenzio se il file sorgente non esiste.

## Prossimo passo

Apri `.ai/plans/2026-09-22-issue-1-cartella-briefs/plan.md` e leggi la sezione "Decisioni aperte". Le decisioni 1 e 2 sono già risolte: la cartella si chiama `briefs/` e sta in radice. Le altre 11 sono aperte e la Fase 0 del piano consiste esattamente nel chiuderle con l'utente.

Sottoponi all'utente le decisioni 3 e 4, che sono quelle da cui dipendono più fasi:

- **3** — il percorso `briefs/` va scritto fisso nel testo delle istruzioni, oppure come parametro nel blocco `defaults` di `scaffolding-catalog.json`, accanto a `sourcePath` e `testPath`? Il parametro evita di ripetere lo stesso percorso in circa sei file; il testo fisso è più semplice da leggere per Copilot.
- **4** — quali sezioni obbligatorie per il modello di brief? Il nucleo proposto è Obiettivo, Fuori scope, Vincoli, Criteri di accettazione, Note. Va riletto sapendo che un brief esprime un bisogno e non descrive un sistema: "Criteri di accettazione" potrebbe diventare "Come capiamo che è fatto".

Annota le risposte nel piano, poi prosegui con le fasi 1 e 2 (l'istruzione `brief-authoring.instructions.md` e il modello `templates/brief-template.md`). Non toccare nessun file di prodotto prima che le decisioni siano scritte nel piano.
