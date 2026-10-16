# Piano: destino del template dotnet new (.template.config/template.json)
Data: 2026-10-14
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#19

## Obiettivo
Una sola via documentata per installare il core: o il template `dotnet new` viene riallineato, documentato e provato, o viene rimosso insieme al suo unico riferimento.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/19 (label `enhancement`, nessun commento). Chiede di decidere se `.template.config/template.json` serve ancora; se serve, identità `dr-guidelines`, descrizione nel README, funzionamento provato; se non serve, rimozione.
- Consultazione: nessuna (la scelta tra tenere e rimuovere è dell'utente; qui sotto c'è solo la raccomandazione).
- Esito della verifica sul repository (lettura, 2026-10-14):
  - `.template.config/template.json` (unico file della cartella, 15 righe): riga 5 `"identity": "Davraf.Guidelines"`, riga 7 `"shortName": "davraf-guidelines"`, riga 6 `"name": "Davraf Guidelines – Copilot + EditorConfig per .NET 10"`, riga 8 `description` (promette di aggiungere `copilot-instructions.md`, le instruction trasversali, `.editorconfig`, `.gitignore`, `.gitattributes`), riga 11 `"type": "solution"`, riga 13 `"sourceName": "YourProject"`, riga 14 `"preferNameDirectory": false`.
  - Il file non dichiara `sources` né `exclude`: `dotnet new` copierebbe quindi tutto il contenuto della cartella radice (101 file tracciati: `.ai/plans/`, `.claude/skills/`, `docs/`, `LICENSE`, `README.md`, `CLAUDE.md`, installer, catalogo, più i file non tracciati presenti, per esempio `TODO/`, `AGENTS.md`, `.agents/`), escludendo solo i default del motore (`.git`, `bin`, `obj`, `.template.config`). La descrizione (5 file) non corrisponde a quello che il template farebbe davvero.
  - `sourceName` `YourProject` non compare in nessun altro file del repository (`grep -rn "YourProject"` dà solo `template.json:13`): il rinomina-progetto è inerte.
  - Riferimenti nel repository: un solo documento, `docs/onboarding.md:76` (`.template.config/     ← Template dotnet new (Davraf.Guidelines)`), nell'albero della sezione 4. Nessuna occorrenza in `README.md`, `dr-guidelines-install.ps1`, `dr-guidelines-install-lib.ps1`, `scaffolding-catalog.json`, `.github/workflows/*.yml`, skill (`.claude/skills/`), prompt (`.github/prompts/`). Nessun installer, skill o CI lo usa.
  - Le occorrenze di `dotnet new` nelle skill e nei prompt (`dr-scaffold*`) riguardano i template di progetto standard (`web`, `worker`, `xunit`, `sln`), non questo template.
  - Altre occorrenze di `Davraf.Guidelines`/`davraf-guidelines` nel repository: solo il sentinel `<!-- /davraf-guidelines -->` della sezione globale (`docs/onboarding.md:149`, `README.md:218`, `dr-guidelines-install-lib.ps1:804`, `dr-install-global`), che non c'entra con il template e non si tocca.
  - Storia: il file nasce con `b398507`; l'ultima modifica, `aee84a4` (2026-09-16, split), ha cambiato una riga (la descrizione). Il piano `2026-07-22-dr-guidelines-split` (riga 132) lo dichiarava "tooling ad uso esclusivo di dr-guidelines", fuori dal meccanismo di installazione; `2026-10-11-revisione-documentazione` (riga 81) lo ha segnalato come non documentato. `CreateNewSolution.ps1`, citato accanto al template nel piano di split, non esiste più.
  - Funzionerebbe dopo lo split? Tecnicamente `dotnet new install <clone locale>` lo registrerebbe, ma il risultato non è il core installato: mancano la gestione del manifest `.ai/dr-guidelines-packages.json` (lock file con commit), `-Update`, `-Package`, la risoluzione delle dipendenze dal catalogo; copia file che un host non deve avere (piani, skill di manutenzione del repo, `docs/` del core). Il core oggi si installa con `dr-guidelines-install.ps1` (README, sezione installazione). Non è stato eseguito `dotnet new` in questa fase (sola lettura): la prova pratica è nelle fasi del ramo A.

### Sequenza di esecuzione
Ondata 2 — eseguire DOPO l'integrazione in main di dr-guidelines#20, perché entrambe possono toccare README.md e docs/ (in particolare docs/onboarding.md). Su repo condiviso lavorare su un branch dedicato.

## Decisioni prese (2026-10-14): D1 = B

D1 = ramo B (rimozione del template). D2 e D3 non applicabili. Le fasi del ramo A sono non applicabili (D1 = B).

## Decisioni aperte (storico)

1. **Tenere o rimuovere il template?** Scelta dell'utente.
   - Raccomandazione: **rimuovere (ramo B)**. Motivi: due vie per lo stesso risultato, una non provata; il template non è usato da installer, skill o CI; senza `sources` distribuirebbe l'intero repository, non i 5 file promessi; non gestisce manifest, aggiornamenti e dipendenze, che sono il valore dell'installer; mantenerlo costerebbe una seconda superficie da tenere allineata a ogni cambio di catalogo; l'installer funziona già da un clone locale e via raw da GitHub. Rimuoverlo è reversibile (resta nella storia git).
   - Tenerlo ha senso solo se l'utente vuole un'esperienza `dotnet new` per chi non ha PowerShell: in quel caso il ramo A.
2. (solo ramo A) **Cosa copia il template?** Raccomandazione: `sources` con `exclude` per `.ai/plans/**`, `TODO/**`, `.agents/**`, `AGENTS.md`, `docs/**`, `LICENSE`, `README.md`, `.github/workflows/**`, `.template.config/**`; decidere se `.claude/skills/` e l'installer vanno inclusi.
3. (solo ramo A) **Identità**: raccomandazione `identity` `dr-guidelines`, `shortName` `dr-guidelines`, `author` invariato, `name` e `description` riscritti sul contenuto reale; se `sourceName` resta inerte, rimuoverlo.

## Scope

### File da modificare
- [ ] `.template.config/template.json` — ramo B: eliminato; ramo A: aggiornato
- [ ] `docs/onboarding.md` — ramo B: via la riga 76 dell'albero; ramo A: riga 76 con la nuova identità; in entrambi i casi footer (`doc-versioning.instructions.md`)
- [ ] `README.md` — solo ramo A: sezione che spiega come usare il template (con `/dr-professor`)

### Perimetro negativo
- Non toccherò: installer (`dr-guidelines-install*.ps1`), `scaffolding-catalog.json`, skill, prompt, workflow CI, sentinel `<!-- /davraf-guidelines -->`, altri piani, `TODO/`, `AGENTS.md`, `.agents/`, `davraf-guidelines`, altri repository `dr-*`.
- Nessun push senza richiesta esplicita; la issue non viene chiusa dal piano.

## Fasi (formato atomico — obbligatorio)

### Fase 1: decisione dell'utente
- **Stato**: [x] (D1 = B, annotata sopra)
- **Precondizione**: piano approvato per l'esecuzione; `dr-guidelines#20` integrato in `main` (Ondata 2)
- **File**: `.ai/plans/2026-10-14-issue-19-template-dotnet-new/plan.md`
- **Operazione**: EDIT
- **Azione**: chiedere all'utente "rimuovere (ramo B) o tenere (ramo A)?" e annotare la scelta in questo file; marcare le fasi del ramo non scelto come `[-] non applicabile`
- **Tool ammessi**: nessuno
- **Verifica passo**: in plan.md è scritto un solo ramo scelto e le fasi dell'altro sono marcate non applicabili
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: branch dedicato
- **Stato**: [x] (worktree `wt-dr-guidelines-19`, branch `issues/19-template-dotnet-new` da origin/main)
- **Precondizione**: Fase 1 completata; `git status` senza modifiche tracciate; `main` contiene l'integrazione di #20 (`git log main` la mostra)
- **File**: nessuno
- **Operazione**: CREATE (branch)
- **Azione**: creare e passare al branch `issues/19-template-dotnet-new` da `main` aggiornato
- **Tool ammessi**: git
- **Verifica passo**: `git branch --show-current` restituisce `issues/19-template-dotnet-new`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

---

### RAMO B — rimozione (raccomandato)

### Fase B1: rimuovere il template
- **Stato**: [x] (`git rm`; `.template.config` assente)
- **Precondizione**: Fase 2 completata; scelta ramo B in Fase 1; `grep -rn "template.config" --exclude-dir=.git --exclude-dir=.ai .` dà solo `docs/onboarding.md:76`
- **File**: `.template.config/template.json`
- **Operazione**: DELETE
- **Azione**: `git rm .template.config/template.json` (la cartella sparisce con l'unico file)
- **Tool ammessi**: git
- **Verifica passo**: `Test-Path .template.config` restituisce False
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase B1: <cosa>` in plan.md, non procedere

### Fase B2: togliere la riga dall'albero di onboarding
- **Stato**: [x] (riga rimossa; grep pulito)
- **Precondizione**: Fase B1 completata
- **File**: `docs/onboarding.md`
- **Operazione**: EDIT
- **Azione**: con `/dr-professor`, eliminare la riga `.template.config/     ← Template dotnet new (Davraf.Guidelines)` dall'albero della sezione 4, senza altre modifiche al testo
- **Tool ammessi**: nessuno
- **Verifica passo**: `grep -n "template.config\|Davraf.Guidelines" docs/onboarding.md` non dà risultati; l'albero resta ben formato (rilettura)
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase B2: <cosa>` in plan.md, non procedere

### Fase B3: riallineare onboarding al codice e aggiornare il footer
- **Stato**: [x] (albero allineato a `git ls-files`: aggiunte `.ai/handoff/` e `LICENSE`; footer v4.0)
- **Precondizione**: Fase B2 completata
- **File**: `docs/onboarding.md`
- **Operazione**: EDIT
- **Azione**: confrontare l'albero della sezione 4 con `git ls-files` (ogni voce esiste, nessuna voce manca) e aggiornare il footer secondo `doc-versioning.instructions.md`
- **Tool ammessi**: git (sola lettura)
- **Verifica passo**: ogni voce dell'albero corrisponde a un percorso reale; footer con versione e data aggiornate
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase B3: <cosa>` in plan.md, non procedere

---

### RAMO A — tenere, aggiornare, documentare, provare

### Fase A1: provare il comportamento attuale
- **Stato**: [-] non applicabile (D1 = B)
- **Precondizione**: Fase 2 completata; scelta ramo A; `dotnet --version` risponde
- **File**: nessuno (cartelle di prova nella scratchpad, fuori dal repository)
- **Operazione**: nessuna (verifica)
- **Azione**: in una cartella vuota di prova, `dotnet new install <percorso del repo>`, poi `dotnet new davraf-guidelines -o <cartella di prova>/out`; elencare i file generati e confrontarli con la `description`; poi `dotnet new uninstall <percorso>`
- **Tool ammessi**: dotnet (solo cartelle di prova)
- **Verifica passo**: elenco dei file generati annotato in plan.md; la discrepanza con la descrizione (se confermata) è registrata
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase A1: <cosa>` in plan.md, non procedere

### Fase A2: aggiornare identità e contenuto del template
- **Stato**: [-] non applicabile (D1 = B)
- **Precondizione**: Fase A1 completata; decisioni 2 e 3 prese dall'utente
- **File**: `.template.config/template.json`
- **Operazione**: EDIT
- **Azione**: impostare `identity` e `shortName` a `dr-guidelines`, riscrivere `name` e `description` sul contenuto reale, aggiungere `sources` con le `exclude` decise, togliere `sourceName` se inerte
- **Tool ammessi**: nessuno
- **Verifica passo**: il JSON è valido (`ConvertFrom-Json` senza errori); `grep -n "Davraf.Guidelines\|davraf-guidelines" .template.config/template.json` non dà risultati
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase A2: <cosa>` in plan.md, non procedere

### Fase A3: riprovare il template aggiornato
- **Stato**: [-] non applicabile (D1 = B)
- **Precondizione**: Fase A2 completata
- **File**: nessuno (cartelle di prova nella scratchpad)
- **Operazione**: nessuna (verifica)
- **Azione**: ripetere install, `dotnet new dr-guidelines -o <cartella di prova>/out`, elenco dei file, uninstall; confrontare con la `description` e con i file che l'installer scrive in un host
- **Tool ammessi**: dotnet (solo cartelle di prova)
- **Verifica passo**: l'elenco dei file generati coincide con quello dichiarato nella descrizione; nessun file di `.ai/plans/`, `TODO/`, `docs/` nell'output; prova ed esito annotati in plan.md
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase A3: <cosa>` in plan.md, non procedere

### Fase A4: documentare l'uso nel README
- **Stato**: [-] non applicabile (D1 = B)
- **Precondizione**: Fase A3 completata
- **File**: `README.md`
- **Operazione**: EDIT
- **Azione**: con `/dr-professor`, aggiungere nella sezione di installazione un paragrafo breve: quando preferire il template all'installer, i due comandi (`dotnet new install`, `dotnet new dr-guidelines`) e cosa non fa rispetto all'installer (manifest, `-Update`, dipendenze); struttura secondo `readme-structure.instructions.md`
- **Tool ammessi**: nessuno
- **Verifica passo**: il README contiene i comandi esatti provati in A3; il paragrafo dichiara la differenza con l'installer
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase A4: <cosa>` in plan.md, non procedere

### Fase A5: albero di onboarding, riallineamento e footer
- **Stato**: [-] non applicabile (D1 = B)
- **Precondizione**: Fase A4 completata
- **File**: `docs/onboarding.md`
- **Operazione**: EDIT
- **Azione**: con `/dr-professor`, aggiornare la riga 76 con la nuova identità e un rimando al README; confrontare l'albero con `git ls-files`; aggiornare il footer secondo `doc-versioning.instructions.md`
- **Tool ammessi**: git (sola lettura)
- **Verifica passo**: `grep -n "Davraf.Guidelines" docs/onboarding.md` non dà risultati; ogni voce dell'albero corrisponde a un percorso reale; footer aggiornato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase A5: <cosa>` in plan.md, non procedere

---

### Fase 3: verifica finale in contesto isolato
- **Stato**: [x] (verifica isolata CONFORME, nessuna divergenza)
- **Precondizione**: tutte le fasi del ramo scelto completate
- **File**: tutti quelli di Scope toccati dal ramo scelto
- **Operazione**: nessuna (verifica)
- **Azione**: rileggere plan.md e ogni file di Scope in un contesto isolato dalla conversazione che ha modificato i file (su Claude Code: `/dr-verify-plan`; altrimenti nuova sessione o secondo revisore); confrontare le affermazioni di `docs/onboarding.md` (e `README.md` nel ramo A) con i file reali
- **Tool ammessi**: sub-agente di sola lettura (`/dr-verify-plan`)
- **Verifica passo**: rapporto del verificatore senza divergenze, oppure divergenze corrette e ri-verificate
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: commit e PR
- **Stato**: [x] (PR aperta verso main; gate di push: repo di soli documenti, nessun target di lint, catalog-guard eseguito)
- **Precondizione**: Fase 3 senza divergenze; piano `Stato: COMPLETATO`; richiesta esplicita dell'utente di pubblicare
- **File**: tutti quelli di Scope toccati
- **Operazione**: nessuna (git)
- **Azione**: invocare `/dr-promote-to main` (commit, gate di push, PR; il corpo della PR cita `davraf-amuro/dr-guidelines#19`); repository di soli documenti: la skill dichiara l'assenza di target di lint
- **Tool ammessi**: `/dr-promote-to`
- **Verifica passo**: PR aperta verso `main`; `git status` pulito
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] Una scelta (ramo A o B) è annotata in plan.md e le fasi dell'altro ramo sono marcate non applicabili
- [x] Ramo B: `Test-Path .template.config` è False e `grep -rn "template.config" --exclude-dir=.git --exclude-dir=.ai .` non dà risultati
- [x] Ramo B: `grep -rn "Davraf.Guidelines" --exclude-dir=.git --exclude-dir=.ai .` non dà risultati
- [-] Ramo A: `template.json` ha `identity` e `shortName` `dr-guidelines`, JSON valido, nessun `Davraf.Guidelines`/`davraf-guidelines` nel file (non applicabile, D1 = B)
- [-] Ramo A: la prova `dotnet new` (install, generazione, uninstall) è documentata in plan.md e i file generati coincidono con la descrizione (non applicabile, D1 = B)
- [-] Ramo A: il README spiega l'uso del template con i comandi provati e la differenza dall'installer (non applicabile, D1 = B)
- [x] L'albero della sezione 4 di `docs/onboarding.md` corrisponde a `git ls-files` per le voci elencate; footer aggiornato
- [x] Nessun file fuori da Scope modificato (`git diff --name-only main` elenca solo file di Scope e plan.md)
- [x] Verifica in contesto isolato eseguita senza divergenze aperte

Piano issue-19-template-dotnet-new verificato. Tutti i criteri soddisfatti.
