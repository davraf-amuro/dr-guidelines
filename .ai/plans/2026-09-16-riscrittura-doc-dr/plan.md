# Piano: riscrittura documentazione suite dr-*
Data: 2026-09-16
Stato: COMPLETATO

## Obiettivo
Riscrivere la documentazione di tutti i repo `dr-*`, README compresi, con priorità a istruzioni facili per creare una soluzione da zero. Poi commit e push per repo.

## Contesto
Richiesta utente via `/dr-professor` (invocazione esplicita = approvazione, esenzione EnterPlanMode).
Fatti verificati in sessione: repo Private, bootstrap `gh api` funzionante, installer che clona sempre `main` remoto, ordine core → reload → `/dr-scaffold`.

## Scope

### dr-guidelines
- [x] `docs/guida-nuova-soluzione.md` — CREATE, guida passo passo per soluzione da zero
- [x] `README.md` — EDIT, Avvio Rapido con bootstrap, comandi Private-first, FAQ, tabella docs
- [x] `docs/onboarding.md` — EDIT, registry unico dal catalogo, schema v2, core agnostico
- [x] `docs/card-dr-guidelines.md` — EDIT, entrypoint e servizi esterni aggiornati
- [x] `docs/test-progetto-host.md` — EDIT, allineato alle correzioni della bozza
- [x] `docs/bozza-manuale-installazione.md` — EDIT, rimando alla guida, correzioni marcate come recepite

### Repo dominio (README nuovi)
- [x] `dr-dotnet-backend/README.md` — CREATE
- [x] `dr-minimalapi/README.md` — CREATE
- [x] `dr-winsvc/README.md` — CREATE
- [x] `dr-efdb/README.md` — CREATE
- [x] `dr-fe/README.md` — CREATE
- [x] `dr-devops/README.md` — CREATE

### Perimetro negativo
- Nessuna modifica a script, catalogo, skill, instructions, prompt, CI
- `README.md` core: aggiunta nota e FAQ sulla mancata copia di `.github/copilot-instructions.md` (bug installer segnalato, non corretto)
- `docs/scaffolding-*.md`: solo rinomina del riferimento `davraf-guidelines` nell'intro (fatto, footer v1.1), nessuna riscrittura
- Non committare `TODO/` né `.ai/plans/2026-08-12-auth-guidelines/plan.md`

## Fasi
- [x] Fase 1 — README repo dominio (sub-agenti)
- [x] Fase 2 — Guida nuova soluzione
- [x] Fase 3 — README core
- [x] Fase 4 — onboarding, card, test-progetto-host, bozza
- [x] Fase 5 — Verifica rilettura + commit e push per repo

## Verifica finale

Tre passaggi di `/dr-verify-plan`, in contesto isolato (`plan-tracking` Fase 4 punto 4):

1. **Prima verifica:** tutti i file corrispondevano al piano, ma con 16 affermazioni imprecise e due criteri non soddisfatti (passaggi non provati, footer). Le principali: ✅ del passo 3 riferito all'installer precedente ad `aee84a4`, passo 7 del collaudo che non lanciava l'installer dal percorso locale, ordine core/frontend Vue opposto al catalogo, FAQ rimossa, numerazione dei footer.
2. **Seconda verifica:** 13 rilievi risolti. Emersi orari dei footer non reali, il rischio che `/dr-scaffold-solution` si fermi su una cartella già popolata dal core, conteggio storico delle skill errato nella bozza (15, non 10).
3. **Terza verifica:** tutto risolto tranne una frase del README core che dava per provata l'installazione del core, e l'omissione del manifest tra i file riscritti. Corrette.

Push eseguiti il 2026-09-16: `dr-guidelines` `0d16e73`; `dr-dotnet-backend` `0999348`; `dr-minimalapi` `83ce74d`; `dr-winsvc` `05f43b7`; `dr-efdb` `e86891a`; `dr-fe` `f02cc00`; `dr-devops` `6840e33`. Gate di push: nessun comando di verifica applicabile (repository di documentazione e script, nessuna solution), dichiarato prima del push.

## Problemi emersi, fuori perimetro (non corretti)

- Job CI `catalog-guard` fallito da `aee84a4`: legge ancora `$Script:PackageRegistry`
- L'installer non copia `.github/copilot-instructions.md` negli host, ma la sezione `CLAUDE.md` iniettata lo richiama
- `/dr-scaffold-solution` potrebbe bloccarsi su cartella con il core già installato (regola "Cartella di destinazione già popolata → STOP")
- Header degli installer: aggiornamento, `-Package` e `-Global` documentati solo con `irm` (404 su Private)
- `/dr-segnala-miglioria`: la skill non usa i modelli `ISSUE_TEMPLATE`, il prompt Copilot sì; nessuno dei due applica le label
- Dipendenze implicite non dichiarate nel catalogo (`dr-efdb`, `dr-fe`, `dr-devops` rimandano a file di `dr-minimalapi`)
- Rimandi a un'implementazione di riferimento inesistente (`src/test-guideline.api/`) in `dr-efdb` e `dr-minimalapi`
- `card-worker-service.prompt.md` non allineato a `windows-service.instructions.md`; esempio Serilog su `HostApplicationBuilder` probabilmente non compilabile

## Criteri di verifica
- [x] Ogni comando di installazione documentato funziona su repo Private (forma `gh api` presente)
- [x] Nessun riferimento a `install.ps1` nudo, `$Script:PackageRegistry` come fonte, `setup.ps1`, submodule come modello attuale
- [x] Passaggi non provati sul campo marcati come tali
- [x] Footer conformi a doc-versioning (docs/) e readme-structure (README)
- [x] 7 repo con README
