# Piano: Rendere non aggirabile la verifica lint prima di ogni git push
Data: 2026-11-03
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#33
Branch: `plan/issue-33-gate-lint-non-aggirabile` (approvato 2026-11-27)

## Obiettivo
Prima di ogni `git push` (e del commit che lo precede nei flussi commit+push) l'agente esegue il comando di verifica di dominio e ne cita comando ed exit code: senza esito citato il push non è consentito.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/33
- Problema: in un host .NET (Microcosmos) un agente Claude Code ha fatto commit+push senza eseguire `dotnet format ... --verify-no-changes`; il lint era rosso (8 violazioni in 4 file: 4 IDE1006, 4 CS1573). Il gate esiste solo in prosa e nessun punto del ciclo obbliga a mostrarne l'esito.

**Verifica sui file (2026-11-03)**
- `.github/copilot-instructions.md`, sezione "Gate di Push — Verifica obbligatoria": rimanda al "comando dichiarato dall'istruzione di dominio", tabella sugli exit code, nessun obbligo di citare comando ed esito. Confermato.
- ⚠️ Discrepanza: la issue cita "la checklist pre-push di `dev-cycle.instructions.md`, se presente": **non esiste**. La Fase 0 di dev-cycle non ha voci su lint o push.
- `dr-dotnet-backend/.github/instructions/dotnet-project-type.instructions.md:65-80` ("Gate di Push — Lint .NET"): `dotnet format <percorso>.csproj --verify-no-changes`, segnaposto senza esempio, nessuna indicazione relativo/assoluto né su più csproj. È in un **altro repo**.
- `.claude/skills/dr-promote-to/SKILL.md:35-47`: lint prima del commit, ma solo dentro la skill.
- `templates/global-claude.md` (sorgente di `~/.claude/CLAUDE.md` via `/dr-install-global`): ripete la tabella con `<percorso>` e senza obbligo di citare l'esito.
- `Merge-ClaudeSettings` (`dr-guidelines-install-lib.ps1:586-652`) fonde solo le voci permesso e dichiara di non toccare `hooks` (riga 590): un hook Claude Code distribuito dall'installer richiederebbe di estendere il merge.

**Prova empirica del "falso exit 0 con percorso assoluto"** (sub-agente, progetto `dotnet new console` minimo con violazione IDE1006 resa errore): exit 2 con percorso relativo, exit 2 con assoluto, exit 2 da dentro la cartella. **Non riprodotto.** Può dipendere dal contesto dell'host (solution, `.editorconfig`, `global.json`, percorso con spazi) → nella regola il percorso relativo si motiva con "lo stesso comando della CI", non con il falso exit 0.

**Consultazione** — `/dr-prompt-engineer` (sub-agente in sola lettura):
- Perché è aggirabile: rimando indiretto al comando; "verifica pulita" dichiarabile a parole; uscita "non applicabile" facile da abusare; commit non coperto; dev-cycle senza voce; segnaposto `<percorso>` senza esempio.
- Testo proposto (fonte unica in `copilot-instructions.md`, gli altri rimandano):
  > ⛔ Prima di ogni `git push`, e del `git commit` che lo precede in un flusso commit+push, **esegui** il comando di verifica del dominio e **cita nell'output il comando eseguito e il suo exit code** (es. `dotnet format src/X/X.csproj --verify-no-changes` → exit 0). Nessun esito citato = push non consentito. Exit non-zero = STOP. "Non applicabile" si dichiara solo se nessun pacchetto di dominio fornisce un comando. In .NET usa lo stesso percorso relativo del csproj della CI, lanciato dalla radice del repo.
- Rinforzo meccanico: (a) hook Claude Code `PreToolUse` su `git push` — blocca davvero, ma copre un solo agente e richiede di estendere `Merge-ClaudeSettings` ai `hooks`; (b) git hook `pre-push` in `.githooks/` con `core.hooksPath` — neutro rispetto all'agente e vale per gli umani, ma `core.hooksPath` è config locale (va impostato dall'installer) e si aggira con `--no-verify`; (c) sola checklist — costo zero, resta prosa. **Raccomandazione**: ora (c) + testo rafforzato; (b) come passo successivo opzionale; (a) per ora no.

**Sovrapposizione con #34** — il piano `2026-11-03-issue-34-eol-installer-generatori` tocca le stesse sezioni (Gate di Push in `copilot-instructions.md`, passo 2 di `dr-promote-to`). Eseguire in serie; chi parte per secondo rilegge le sezioni. Ordine consigliato: prima #33 (testo breve), poi #34.

## Decisioni (risolte dall'utente, 2026-11-27)

1. **Commit**: **sì**, vincolato anche il commit che precede la push.
2. **Rinforzo meccanico**: **solo regola + checklist** → Fase 6 esclusa.
3. **Hook `pre-push`**: non applicabile (Decisione 2).
4. **`--no-verify`**: **vietato** in prosa, salvo richiesta esplicita dell'utente.
5. **`dr-dotnet-backend`**: **sì, issue collegata** → Fase 7 si esegue (testo mostrato prima).

**Nota 2026-11-27** — il piano #34 è stato eseguito per primo (PR #38): il Gate in `copilot-instructions.md` (v2.8) e il passo 2 di `dr-promote-to` (v1.3) sono cambiati; le Fasi 2 e 4 rileggono le sezioni prima di modificarle.

## Scope
### File da modificare
- [x] `.github/copilot-instructions.md` — Gate di Push: esecuzione obbligatoria, citazione comando + exit code, commit coperto, "non applicabile" ristretto, percorso relativo come in CI; footer
- [x] `.github/instructions/dev-cycle.instructions.md` — voce di checklist Fase 0 (o Fase 4) per i task che terminano in push; footer
- [x] `.claude/skills/dr-promote-to/SKILL.md` — passo 2 cita comando ed exit code nell'output, rimando alla fonte unica; footer
- ~~`.github/prompts/*` equivalente di `dr-promote-to`~~ — non esiste (Fase 1)
- [x] `templates/global-claude.md` — sezione "Gate di Push" allineata (rimando + obbligo di citare l'esito)
- ~~`CLAUDE.md` del repo~~ — non ripete il Gate (Fase 1)
- [x] `.agents/skills/` — rigenerato da `scripts/sync-codex.ps1`, mai a mano
- ~~`.githooks/pre-push` + `dr-guidelines-install-lib.ps1`~~ — Decisione 2 = nessun hook
- [x] `docs/onboarding.md` — riga del Gate in tabella allineata alla nuova regola; footer (aggiunto dopo la Verifica 1)

### Perimetro negativo
- Non toccherò: `dr-dotnet-backend` e gli altri repo di dominio (al più issue collegata, Decisione 5)
- Non toccherò: `~/.claude/CLAUDE.md` direttamente — si aggiorna con `/dr-install-global aggiorna` dopo il merge, su richiesta dell'utente
- Non toccherò: il controllo fine riga del Gate (scope di #34)
- Non toccherò: `Merge-ClaudeSettings` e i `hooks` di Claude Code
- Non toccherò: `AGENTS.md` e `.agents/skills/` a mano
- Non scriverò nella regola che il percorso assoluto dà falso exit 0 (non riprodotto)

## Fasi (formato atomico — obbligatorio)

Serie obbligata: le Fasi 2-5 toccano file che si citano a vicenda (regola e skill/template che la richiamano). Fase 8 generata da script, dopo tutte le skill.

### Fase 1: Mappa delle copie del gate
- **Stato**: [x]

**Esito Fase 1 (2026-11-27)** — copie del Gate con comandi o tabella: `copilot-instructions.md:68` (fonte), `dr-promote-to/SKILL.md:35-47`, `templates/global-claude.md:59-69`. Citazioni coerenti, da non toccare: `plan-tracking:129,254`, `line-endings:7,50`, `docs/onboarding.md:128,162`, skill/prompt di scaffolding (`--verify-no-changes` come verifica di scaffolding), `docs/guida-nuova-soluzione.md:203`. `CLAUDE.md` del repo non ripete il Gate; nessun prompt equivalente di `dr-promote-to`. **Nessun file in più nello Scope**; `CLAUDE.md` e `.github/prompts/*` escono dallo Scope.
- **Dipende da**: —
- **Modello**: sonnet — ricerca testuale
- **Precondizione**: —
- **File**: nessuno
- **Operazione**: nessuna (lettura)
- **Azione**: cerca in `.github/`, `.claude/skills/`, `templates/`, `CLAUDE.md`, `docs/`, `README.md` ogni testo che ripete il Gate di Push o la tabella dei comandi lint; elenca file:riga in `plan.md` e aggiorna lo Scope
- **Tool ammessi**: Grep, Read
- **Verifica passo**: elenco in `plan.md`; Scope aggiornato o "nessun file in più"
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Gate di Push — fonte unica rafforzata
- **Stato**: [x]
- **Dipende da**: 1
- **Modello**: sessione — testo di regole (consultazione `/dr-prompt-engineer` già fatta in fase di piano: testo adottato quasi alla lettera, nessuna nuova consultazione)
- **Precondizione**: Decisioni 1 e 4 risolte; se il piano #34 è già stato eseguito, rileggi la sezione
- **File**: `.github/copilot-instructions.md`
- **Operazione**: EDIT
- **Azione**: nella sezione "Gate di Push — Verifica obbligatoria" inserisci il testo della consultazione adattato alle Decisioni 1 e 4: esecuzione obbligatoria, citazione nell'output di comando ed exit code, "nessun esito citato = push non consentito", commit coperto (se Decisione 1), "non applicabile" solo se nessun pacchetto di dominio fornisce un comando, percorso relativo come in CI dalla radice del repo; `--no-verify` vietato (se Decisione 4). Footer v2.8 (o successiva) con riferimento a #33
- **Tool ammessi**: Edit
- **Verifica passo**: la sezione contiene le frasi "cita nell'output" e "nessun esito citato"; nessuna menzione del falso exit 0
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Voce di checklist in dev-cycle
- **Stato**: [x]
- **Dipende da**: 2
- **Modello**: sonnet — modifica testuale data
- **Precondizione**: Fase 2 completata
- **File**: `.github/instructions/dev-cycle.instructions.md`
- **Operazione**: EDIT
- **Azione**: aggiungi alla checklist (Fase 0, o Fase 4 se più coerente con la struttura) la voce "Il task termina in commit+push → ho eseguito la verifica di dominio e citato comando ed exit code (Gate di Push in `copilot-instructions.md`)"; footer
- **Tool ammessi**: Edit
- **Verifica passo**: voce presente, rimanda alla fonte unica senza ripetere la tabella
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: `dr-promote-to` e prompt equivalente
- **Stato**: [x]
- **Dipende da**: 2
- **Modello**: sonnet — modifica testuale data
- **Precondizione**: Fase 2 completata
- **File**: `.claude/skills/dr-promote-to/SKILL.md` (e prompt Copilot equivalente trovato in Fase 1)
- **Operazione**: EDIT
- **Azione**: al passo 2 aggiungi l'obbligo di riportare nell'output comando ed exit code prima del commit, esempio .NET con percorso relativo `src/<Nome>/<Nome>.csproj`, rimando alla fonte unica; footer con riferimento a #33
- **Tool ammessi**: Edit
- **Verifica passo**: passo 2 contiene l'obbligo di citazione; la tabella dei comandi resta coerente con la Fase 2
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Template globale
- **Stato**: [x]
- **Dipende da**: 2
- **Modello**: sonnet — modifica testuale data
- **Precondizione**: Fase 2 completata
- **File**: `templates/global-claude.md`
- **Operazione**: EDIT
- **Azione**: sezione "Gate di Push — Lint obbligatorio": aggiungi l'obbligo di citare comando ed exit code, il commit coperto (se Decisione 1), l'esempio di percorso relativo; resta autonoma (il globale non ha `copilot-instructions.md` accanto)
- **Tool ammessi**: Edit
- **Verifica passo**: sezione allineata alla Fase 2 nelle regole, senza riferimenti a file che fuori dal repo non esistono
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: Git hook `pre-push` (condizionale — solo se Decisione 2 lo include)
- **Stato**: [-] esclusa: Decisione 2 = solo regola + checklist
- **Dipende da**: 2
- **Modello**: sessione — installer
- **Precondizione**: Decisioni 2 e 3 risolte
- **File**: `.githooks/pre-push` (CREATE), `dr-guidelines-install-lib.ps1` (EDIT)
- **Operazione**: CREATE + EDIT
- **Azione**: hook che rileva lo stack (csproj → `dotnet format <csproj relativi> --verify-no-changes`; `package.json` con script `lint` → `npm run lint`; nessuno → exit 0 con messaggio); l'installer lo copia e imposta `core.hooksPath` secondo la Decisione 3 (opt-in: solo con flag)
- **Tool ammessi**: Write, Edit, pwsh
- **Verifica passo**: in un host di prova con violazione IDE1006 `git push` fallisce con l'output del lint; in un repo di soli documenti passa
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7: Issue collegata su dr-dotnet-backend (condizionale — solo se Decisione 5 = sì)
- **Stato**: [x]

**Esito Fase 7 (2026-11-27)** — testo confermato dall'utente: davraf-amuro/dr-dotnet-backend#9
- **Dipende da**: 2
- **Modello**: sessione
- **Precondizione**: Decisione 5 = sì; conferma dell'utente sul testo
- **File**: nessuno (GitHub)
- **Operazione**: scrittura su servizio esterno
- **Azione**: `/dr-file-feedback` su `davraf-amuro/dr-dotnet-backend`: esempio di percorso relativo e caso "più csproj" in `dotnet-project-type.instructions.md:65-80`, link a #33
- **Tool ammessi**: `/dr-file-feedback`
- **Verifica passo**: URL della issue annotato in `plan.md`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

### Fase 8: Rigenera la copia Codex
- **Stato**: [x]
- **Dipende da**: 4
- **Modello**: haiku — comando singolo
- **Precondizione**: skill modificate
- **File**: `.agents/skills/`, `AGENTS.md` (generati)
- **Operazione**: EDIT (generato)
- **Azione**: esegui `scripts/sync-codex.ps1`
- **Tool ammessi**: pwsh
- **Verifica passo**: `git status` mostra aggiornata la copia Codex di `dr-promote-to`, nessun file inatteso
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 8: <cosa>` in plan.md, non procedere

### Fase 9: Verifica finale in contesto isolato
- **Stato**: [x]

**Verifica 1 (2026-11-27, opus isolato): CONFORME** — nessun NON CORRISPONDE / NON SODDISFATTO / violazione. Punti minori corretti subito dopo: comando di riserva e definizione di "stack con lint noto" nella fonte unica; "commit e push" anche nella frase in grassetto e al passo 3 del blocco; "non applicabile" dichiarato prima del commit anche nel template; "in questa sessione" per `--no-verify` in skill e template; `docs/onboarding.md:128` allineato (aggiunto allo Scope); voci di Scope escluse annotate.
- **Dipende da**: tutte le precedenti eseguite
- **Modello**: opus
- **Precondizione**: fasi eseguite `[x]` o condizionali escluse con motivo
- **File**: `plan.md`
- **Operazione**: EDIT
- **Azione**: verifica finale di `plan-tracking.instructions.md`, Fase 4 punto 4 — su Claude Code `/dr-verify-plan`; su Copilot/Codex nuova chat con solo `plan.md`, file di Scope e diff
- **Tool ammessi**: `/dr-verify-plan`
- **Verifica passo**: esito "conforme" registrato, `Stato: COMPLETATO`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 9: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] Gate di Push in `copilot-instructions.md` obbliga a eseguire il comando e citare comando + exit code; "nessun esito citato = push non consentito"
- [x] Commit coperto se Decisione 1 = sì
- [x] "Non applicabile" ammesso solo se nessun pacchetto di dominio fornisce un comando
- [x] Voce di checklist presente in `dev-cycle.instructions.md`
- [x] `dr-promote-to`, prompt equivalente e `templates/global-claude.md` allineati alla fonte unica, senza contraddizioni
- [x] Nessuna affermazione sul falso exit 0 col percorso assoluto
- [x] Hook `pre-push` funzionante solo se scelto; altrimenti assente
- [x] `.agents/skills/` rigenerato con `sync-codex.ps1`
- [x] Footer aggiornati sui file modificati
