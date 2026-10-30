# Piano: chiusura dei punti aperti dell'handoff e issue #30 (fine riga)
Data: 2026-10-29
Stato: COMPLETATO
Branch: main (piano approvato senza scelta di branch dedicato: nessun branch creato)
Issue: davraf-amuro/dr-guidelines#30

## Obiettivo
Chiudere la issue #30 (coerenza dei fine riga + controllo nel Gate di Push) e i punti aperti 2-5 di `.ai/handoff/NEXT_PROMPT.md`, con le decisioni dell'utente del 2026-10-29.

## Decisioni dell'utente (2026-10-29)
- Footer: **contatore minore** (v3.9 → v3.10), maggiore +1 se la struttura cambia radicalmente
- `dr-winsvc`: domande 1-3 dello scaffolding → **gate formale** nell'istruzione
- Prova `irm | iex`: **sì**, in una cartella della scratchpad, fuori dai repo

## Note di analisi
- #30 punto 1 è **già risolto** nel core: `.editorconfig` ha `[*] end_of_line = lf` dal commit `aee84a4`; dr-clerk aveva una copia precedente. Resta un'incoerenza minore: `.gitattributes` impone `eol=crlf` su `*.ps1` e `*.sln`, `.editorconfig` no
- Rilevamento agnostico provato in questo repo: `git ls-files --eol` + filtro `w/` contro `attr/...eol=` (trova i `w/crlf` di `.ai/plans/`, con `core.autocrlf=true`)
- `Copy-CoreConfigFiles` restituisce i file `.new` nella pipeline: il nuovo controllo dell'installer scrive solo con `Write-Host` e si chiama dopo, non dentro

## Scope
### File da modificare — dr-guidelines
- [x] `.editorconfig` — sezione `[*.{ps1,sln}] end_of_line = crlf`, coerente con `.gitattributes`
- [x] `.github/copilot-instructions.md` — Gate di Push: controllo fine riga agnostico + procedura di normalizzazione del solo working tree
- [x] `.claude/skills/dr-promote-to/SKILL.md` — stesso controllo nel passo 2
- [x] `templates/global-claude.md` — una riga sul controllo fine riga nel Gate di Push globale
- [x] `dr-guidelines-install-lib.ps1` — `Test-DrEolConsistency`: avviso se `[*] end_of_line` di `.editorconfig` e `* ... eol=` di `.gitattributes` dell'host divergono (vale anche per `/dr-get-latest`, che riesegue l'installer)
- [x] `.github/instructions/doc-versioning.instructions.md` — regola del contatore minore
- [x] `README.md` — FAQ "Non sono un programmatore": `/dr-scaffold` richiede `gh` autenticato
- [x] `docs/scaffolding-windows-service.md` — via il "Da verificare", rimando al gate formale
- [x] `.agents/skills/`, `AGENTS.md` — rigenerati con `scripts/sync-codex.ps1`
- [x] `.ai/handoff/HANDOFF.md`, `.ai/handoff/NEXT_PROMPT.md` — punti chiusi
- [x] commit in dr-guidelines (`Closes #30` nel messaggio)

### File da modificare — dr-winsvc
- [x] `.github/instructions/windows-service.instructions.md` — sezione "Gate preliminare" con le domande 1-4
- [x] commit in dr-winsvc

### Perimetro negativo
- Non toccherò: `.gitattributes`; gli altri 7 repo; i file `w/crlf` del working tree locale (solo segnalati); `davraf-guidelines`; `TODO/`
- Nessun `git push`: si chiede a fine piano (la #30 si chiude solo col push)
- Nessuno script `scripts/check-eol.ps1` (punto 5 opzionale della issue): il comando sta inline nel gate, così funziona negli host senza copiare script

## Fasi

### Fase 1: `.editorconfig` coerente con `.gitattributes`
- **Stato**: [x]
- **File**: `.editorconfig`
- **Operazione**: EDIT
- **Azione**: estendere la sezione `[*.{cmd,bat}]` a `[*.{cmd,bat,ps1,sln}]` con `end_of_line = crlf`
- **Verifica passo**: ogni estensione con `eol=crlf` in `.gitattributes` ha `end_of_line = crlf` in `.editorconfig`

### Fase 2: Gate di Push con controllo fine riga
- **Stato**: [x]
- **File**: `.github/copilot-instructions.md`, `.claude/skills/dr-promote-to/SKILL.md`, `templates/global-claude.md`
- **Operazione**: EDIT
- **Azione**: aggiungere il controllo `git ls-files --eol` (file `w/` diverso dall'`eol=` imposto da `.gitattributes`), la procedura (elenca, chiedi conferma, rinormalizza solo il working tree dei file senza modifiche, commit solo se cambia l'index); footer aggiornati
- **Verifica passo**: i tre file citano lo stesso comando; footer con contatore minore

### Fase 3: avviso dell'installer
- **Stato**: [x]
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: funzione `Test-DrEolConsistency -HostRoot`, chiamata sotto `IsCore` dopo `Copy-CoreConfigFiles`; solo `Write-Host`, solo ASCII
- **Verifica passo**: parse PowerShell senza errori; prova su cartella temporanea con file incoerenti → `[WARN]`, coerenti → nessun avviso

### Fase 4: doc-versioning, README, doc winsvc
- **Stato**: [x]
- **File**: `.github/instructions/doc-versioning.instructions.md`, `README.md`, `docs/scaffolding-windows-service.md`
- **Operazione**: EDIT
- **Verifica passo**: nessun "0.1" residuo nella regola; FAQ cita `gh auth login`; nessun "Da verificare" nel doc winsvc

### Fase 5: gate formale in dr-winsvc
- **Stato**: [x]
- **File**: `../dr-winsvc/.github/instructions/windows-service.instructions.md`
- **Operazione**: EDIT
- **Azione**: sezione "Gate preliminare (obbligatorio)" con le domande 1-4 e i default; footer v1.6
- **Verifica passo**: sezione presente prima di "Struttura progetto"; coerente con la tabella del doc del core

### Fase 6: sync Codex
- **Stato**: [x]
- **Azione**: `pwsh ./scripts/sync-codex.ps1`
- **Verifica passo**: `.agents/skills/dr-promote-to/SKILL.md` contiene il controllo fine riga

### Fase 7: prova `irm | iex`
- **Stato**: [x]
- **Azione**: in una cartella vuota della scratchpad, `irm <raw installer main> | iex`; registrare l'esito
- **Verifica passo**: installazione completata o errore documentato in HANDOFF

### Fase 8: handoff e commit
- **Stato**: [x]
- **Azione**: aggiornare HANDOFF/NEXT_PROMPT; commit in dr-guidelines e dr-winsvc sul branch scelto
- **Verifica passo**: `git status` pulito in entrambi i repo (esclusa `TODO/`)

## Criteri di verifica finale
- [x] `.editorconfig` e `.gitattributes` coerenti su ogni estensione
- [x] Gate di Push con controllo fine riga in copilot-instructions, dr-promote-to (Claude e Codex) e template globale
- [x] Installer avvisa su incoerenza `.editorconfig`/`.gitattributes` nell'host
- [x] doc-versioning descrive il contatore minore
- [x] FAQ README cita `gh` per `/dr-scaffold`
- [x] Gate formale in `windows-service.instructions.md`; doc del core senza "Da verificare"
- [x] Esito prova `irm | iex` registrato
- [x] Commit fatti; push chiesto all'utente

## Esito
- Scope esteso (stessa finalità della Fase 7): `docs/installazione-semplice.md`, `docs/bozza-manuale-installazione.md` e la nota in `README.md` sulle forme `irm` riportano la prova del 2026-10-29
- Il nuovo controllo fine riga segnala 20 file del working tree locale di questo repo (3 `.ps1` in LF dove `.gitattributes` vuole CRLF, 17 `plan.md` in CRLF): non normalizzati, come da perimetro negativo; da fare prima della push
- Nessun `git push` eseguito

Piano 2026-10-29-pending-handoff-e-issue-30 verificato. Tutti i criteri soddisfatti.
