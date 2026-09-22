# Piano: nomi delle skill in inglese
Data: 2026-09-22
Stato: COMPLETATO

## Obiettivo
Portare in inglese i nomi delle skill `dr-*` non conformi, propagare il rename a ogni riferimento e dare all'installer un modo per rimuovere le cartelle obsolete dai progetti host.

## Decisioni approvate dall'utente

| Attuale | Nuovo | Scelta |
|---|---|---|
| `dr-pianifica-issue` | `dr-issues-to-plans` | 1-d |
| `dr-segnala-miglioria` | `dr-file-feedback` | 2-c |
| `dr-tattico` | `dr-prompt-engineer` | 3 |
| `dr-CreateLaunchProfiles` | `dr-create-launch-profiles` | 4-b |
| `dr-professor` | invariata | 5-a |
| `dr-tech` | invariata | 6-a |
| `dr-warroom` | invariata | 7-a |

Matrice B, scelte consigliate confermate dall'utente: 8-c (elimina skill legacy in `davraf-guidelines`), 9-b (elimina `~/.claude/skills/tavolo`), 10-b (lista cartelle obsolete gestita dall'installer).

Regola di riferimento: memoria `skill-names-in-english` — nomi di skill e agenti in inglese, kebab-case, verbo + oggetto, prefisso `dr-` invariato. Contenuto e descrizioni restano in italiano.

## Scope

### File da modificare
- [x] `.claude/skills/dr-pianifica-issue/` — rinomina cartella + campo `name:`
- [x] `.claude/skills/dr-segnala-miglioria/` — rinomina cartella + campo `name:`
- [x] `.claude/skills/dr-tattico/` — rinomina cartella + campo `name:`
- [x] `.claude/skills/dr-CreateLaunchProfiles/` — rinomina cartella + campo `name:`
- [x] `.github/prompts/dr-pianifica-issue.prompt.md` — rinomina file + contenuto
- [x] `.github/prompts/dr-segnala-miglioria.prompt.md` — rinomina file + contenuto
- [x] `.github/prompts/dr-scaffold.prompt.md` — riferimento a `dr-CreateLaunchProfiles`
- [x] `.claude/skills/dr-scaffold/SKILL.md` — riferimento a `dr-segnala-miglioria`
- [x] `.claude/skills/dr-scaffold-solution/SKILL.md` — riferimento a `dr-CreateLaunchProfiles`
- [x] `CLAUDE.md` — tabella di invocazione automatica
- [x] `templates/global-claude.md` — tabella skill del template globale
- [x] `README.md` — elenco skill
- [x] `docs/bozza-manuale-installazione.md`, `docs/card-dr-guidelines.md`, `docs/guida-nuova-soluzione.md`, `docs/onboarding.md`, `docs/test-progetto-host.md`
- [x] `scaffolding-catalog.json` — campo `skill` del fallback + nuovo `obsoleteArtifacts`
- [x] `dr-guidelines-install-lib.ps1` — `Remove-ObsoleteArtifacts` + mappatura nel registry

### Fuori repo (fasi separate, conferma esplicita per ognuna)
- [ ] `E:/Davide/Progetti/davraf-guidelines/.claude/skills/` — 12 skill legacy senza prefisso
- [ ] `C:/Users/draff/.claude/skills/tavolo/` — doppione italiano di `dr-warroom`

### Perimetro negativo
- Non toccherò `.ai/plans/**` esistenti né `.ai/handoff/**`: sono traccia storica, i nomi vecchi restano com'è
- Non toccherò `dr-professor`, `dr-tech`, `dr-warroom` e le 12 skill già conformi
- Non toccherò le skill dei pacchetti di dominio (`dr-audit-api`, `dr-audit-fe`): già in inglese
- Non scriverò `~/.claude/CLAUDE.md`: si aggiorna solo il template in repo, la propagazione con `/dr-install-global` resta una scelta successiva dell'utente
- Nessun `git push`, nessun commit automatico

## Fasi (formato atomico)

### Fase 1: rinomina dr-pianifica-issue
- **Stato**: [x]
- **Precondizione**: `.claude/skills/dr-pianifica-issue/SKILL.md` esiste
- **File**: `.claude/skills/dr-pianifica-issue/` → `.claude/skills/dr-issues-to-plans/`
- **Operazione**: EDIT
- **Azione**: `git mv` della cartella, poi sostituisci `name: dr-pianifica-issue` con `name: dr-issues-to-plans` nel frontmatter e aggiorna ogni `/dr-pianifica-issue` nel corpo
- **Tool ammessi**: Bash (git mv, sed)
- **Verifica passo**: `grep -r "dr-pianifica-issue" .claude/skills/` non restituisce nulla
- **Su divergenza**: STOP — annota `⚠️ Divergenza Fase 1` in plan.md

### Fase 2: rinomina dr-segnala-miglioria
- **Stato**: [x]
- **Precondizione**: Fase 1 completata
- **File**: `.claude/skills/dr-segnala-miglioria/` → `.claude/skills/dr-file-feedback/`
- **Operazione**: EDIT
- **Azione**: `git mv` della cartella, poi `name: dr-file-feedback` nel frontmatter e aggiorna i `/dr-segnala-miglioria` nel corpo
- **Tool ammessi**: Bash (git mv, sed)
- **Verifica passo**: cartella `dr-file-feedback/` esiste, campo `name:` coerente
- **Su divergenza**: STOP

### Fase 3: rinomina dr-tattico
- **Stato**: [x]
- **Precondizione**: Fase 2 completata
- **File**: `.claude/skills/dr-tattico/` → `.claude/skills/dr-prompt-engineer/`
- **Operazione**: EDIT
- **Azione**: `git mv` della cartella, poi `name: dr-prompt-engineer` nel frontmatter e aggiorna i `/dr-tattico` nel corpo
- **Tool ammessi**: Bash (git mv, sed)
- **Verifica passo**: cartella `dr-prompt-engineer/` esiste, campo `name:` coerente
- **Su divergenza**: STOP

### Fase 4: rinomina dr-CreateLaunchProfiles
- **Stato**: [x]
- **Precondizione**: Fase 3 completata
- **File**: `.claude/skills/dr-CreateLaunchProfiles/` → `.claude/skills/dr-create-launch-profiles/`
- **Operazione**: EDIT
- **Azione**: `git mv` della cartella, poi `name: dr-create-launch-profiles` nel frontmatter e aggiorna i `/dr-CreateLaunchProfiles` nel corpo
- **Tool ammessi**: Bash (git mv, sed)
- **Verifica passo**: cartella `dr-create-launch-profiles/` esiste, campo `name:` coerente
- **Su divergenza**: STOP

### Fase 5: rinomina i prompt Copilot gemelli
- **Stato**: [x]
- **Precondizione**: Fasi 1-4 completate
- **File**: `.github/prompts/dr-pianifica-issue.prompt.md`, `.github/prompts/dr-segnala-miglioria.prompt.md`
- **Operazione**: EDIT
- **Azione**: `git mv` in `dr-issues-to-plans.prompt.md` e `dr-file-feedback.prompt.md`, poi aggiorna i nomi citati nel contenuto dei due file
- **Tool ammessi**: Bash (git mv, sed)
- **Verifica passo**: i due nuovi file esistono, i due vecchi no
- **Su divergenza**: STOP

### Fase 6: riferimenti incrociati in skill e prompt
- **Stato**: [x]
- **Precondizione**: Fase 5 completata
- **File**: `.claude/skills/dr-scaffold/SKILL.md`, `.claude/skills/dr-scaffold-solution/SKILL.md`, `.claude/skills/dr-issues-to-plans/SKILL.md`, `.github/prompts/dr-scaffold.prompt.md`
- **Operazione**: EDIT
- **Azione**: sostituisci i 4 nomi vecchi con i nuovi in questi file
- **Tool ammessi**: Bash (sed)
- **Verifica passo**: `grep -rE "dr-pianifica-issue|dr-segnala-miglioria|dr-tattico|dr-CreateLaunchProfiles" .claude .github` senza risultati
- **Su divergenza**: STOP

### Fase 7: CLAUDE.md e template globale
- **Stato**: [x]
- **Precondizione**: Fase 6 completata
- **File**: `CLAUDE.md`, `templates/global-claude.md`
- **Operazione**: EDIT
- **Azione**: aggiorna le tabelle di invocazione automatica con i 4 nomi nuovi, lasciando invariate le righe di `dr-professor`, `dr-tech`, `dr-warroom`
- **Tool ammessi**: Bash (sed), Edit
- **Verifica passo**: rilettura delle due tabelle, nessun nome vecchio presente
- **Su divergenza**: STOP

### Fase 8: README e docs
- **Stato**: [x]
- **Precondizione**: Fase 7 completata
- **File**: `README.md`, `docs/bozza-manuale-installazione.md`, `docs/card-dr-guidelines.md`, `docs/guida-nuova-soluzione.md`, `docs/onboarding.md`, `docs/test-progetto-host.md`
- **Operazione**: EDIT
- **Azione**: sostituisci i 4 nomi vecchi con i nuovi
- **Tool ammessi**: Bash (sed)
- **Verifica passo**: `grep -rE` dei 4 nomi vecchi su `README.md` e `docs/` senza risultati
- **Su divergenza**: STOP

### Fase 9: scaffolding-catalog.json
- **Stato**: [x]
- **Precondizione**: Fase 8 completata
- **File**: `scaffolding-catalog.json`
- **Operazione**: EDIT
- **Azione**: aggiorna il campo `skill` e la `description` del fallback da `dr-segnala-miglioria` a `dr-file-feedback`
- **Tool ammessi**: Bash (sed)
- **Verifica passo**: il file resta JSON valido e il campo `skill` vale `dr-file-feedback`
- **Su divergenza**: STOP

### Fase 10: obsoleteArtifacts nel catalogo
- **Stato**: [x]
- **Precondizione**: Fase 9 completata
- **File**: `scaffolding-catalog.json`
- **Operazione**: EDIT
- **Azione**: aggiungi al pacchetto `dr-guidelines` l'array `obsoleteArtifacts` con i 6 percorsi da rimuovere negli host: le 4 cartelle skill vecchie e i 2 prompt vecchi
- **Tool ammessi**: Edit
- **Verifica passo**: JSON valido, array presente con 6 voci
- **Su divergenza**: STOP

### Fase 11: Remove-ObsoleteArtifacts nell'installer
- **Stato**: [x]
- **Precondizione**: Fase 10 completata
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: mappa `obsoleteArtifacts` in `Get-DrPackageRegistry` accanto a `RootFiles`, aggiungi la funzione `Remove-ObsoleteArtifacts` (accetta solo percorsi relativi sotto `.claude/skills/` e `.github/`, stampa ogni rimozione) e chiamala da `Install-DrPackage` solo quando `-Update` è attivo
- **Tool ammessi**: Edit
- **Verifica passo**: il dot-sourcing della libreria in `pwsh -NoProfile` non produce errori di sintassi
- **Su divergenza**: STOP

### Fase 12: verifica repo pulito
- **Stato**: [x]
- **Precondizione**: Fasi 1-11 completate
- **File**: nessuno (sola lettura)
- **Operazione**: verifica
- **Azione**: `grep -rE "dr-pianifica-issue|dr-segnala-miglioria|dr-tattico|dr-CreateLaunchProfiles" --exclude-dir=.git --exclude-dir=.ai .`
- **Tool ammessi**: Bash (grep)
- **Verifica passo**: le uniche occorrenze ammesse sono le 6 voci dell'array `obsoleteArtifacts` in `scaffolding-catalog.json`, che per definizione contengono i nomi vecchi: sono l'elenco di cosa l'installer deve rimuovere negli host. Ogni altra occorrenza è un residuo di rename
- **Su divergenza**: STOP

### Fase 13: skill legacy in davraf-guidelines
- **Stato**: [-] NON ESEGUITA — l'utente non l'ha autorizzata alla conferma del 2026-09-22. Le 12 skill senza prefisso restano in quel repo.
- **Precondizione**: Fase 12 completata **e** conferma esplicita dell'utente in quel momento
- **File**: `E:/Davide/Progetti/davraf-guidelines/.claude/skills/` (12 cartelle senza prefisso)
- **Operazione**: DELETE
- **Azione**: mostra l'elenco, chiedi conferma, poi rimuovi le 12 cartelle con `git rm -r` se il repo è git, senza commit
- **Tool ammessi**: Bash (git status, git rm)
- **Verifica passo**: `.claude/skills/` di quel repo vuota e `git status` mostra le rimozioni non committate
- **Su divergenza**: STOP

### Fase 14: rimozione di ~/.claude/skills/tavolo
- **Stato**: [x]
- **Precondizione**: Fase 12 completata **e** conferma esplicita dell'utente in quel momento (la Fase 13 è stata saltata su decisione dell'utente, non blocca questa)
- **File**: `C:/Users/draff/.claude/skills/tavolo/`
- **Operazione**: DELETE
- **Azione**: copia prima la cartella nello scratchpad di sessione come backup, mostra il path del backup, poi rimuovi l'originale
- **Tool ammessi**: Bash (cp, rm)
- **Verifica passo**: backup presente nello scratchpad e cartella originale assente
- **Su divergenza**: STOP

## Criteri di verifica finale
- [x] Le 4 cartelle skill hanno il nome nuovo e il campo `name:` del frontmatter corrisponde alla cartella
- [x] I 2 prompt Copilot gemelli hanno lo stesso nome della skill corrispondente
- [x] Nessuna occorrenza dei 4 nomi vecchi fuori da `.git/` e `.ai/`, **tranne** le 6 voci di `obsoleteArtifacts` in `scaffolding-catalog.json`, che devono contenerli
- [x] `scaffolding-catalog.json` è JSON valido e contiene `obsoleteArtifacts` con 6 voci
- [x] `dr-guidelines-install-lib.ps1` si carica senza errori di sintassi e `Remove-ObsoleteArtifacts` viene invocata solo con `-Update`
- [x] `dr-professor`, `dr-tech`, `dr-warroom` non sono rinominate; delle 12 skill già conformi solo `dr-scaffold` e `dr-scaffold-solution` cambiano, per i riferimenti incrociati previsti dalla Fase 6
- [x] `.ai/plans/` e `.ai/handoff/` preesistenti non sono stati modificati
- [x] Fasi 13 e 14 eseguite solo dopo conferma esplicita, oppure dichiarate non eseguite

## Note di esecuzione

- **Fase 11, bug corretto in corsa.** La prima stesura di `Remove-ObsoleteArtifacts` usava `-replace '/', [System.IO.Path]::DirectorySeparatorChar`. `-replace` è un operatore regex e `\` è un carattere di escape: il percorso risultante era corrotto. Sostituito con `String.Replace`, che non interpreta la stringa.
- **Prova a secco della pulizia.** Su un albero host finto nello scratchpad: le 6 voci obsolete rimosse, `dr-professor` e `dr-scaffold.prompt.md` intatti, e i tre guard (risalita `..`, percorso assoluto, percorso fuori da `.claude/skills/` e `.github/`) bloccano con eccezione.
- **Fase 13 non autorizzata.** Le 12 skill legacy in `davraf-guidelines` restano dove sono.
- **Backup di `tavolo`** in `<scratchpad>/backup-tavolo/` (2 file). Lo scratchpad è di sessione, non permanente.
- **Permessi perpetui.** I 4 permessi concessi durante il task sono in `.claude/settings.local.json`, non in `.claude/settings.json`: quest'ultimo viene fuso da `Merge-ClaudeSettings` nella allow list di ogni progetto host, e i permessi personali non vanno distribuiti.
- **Fuori perimetro, non fatto.** `~/.claude/CLAUDE.md` cita ancora `/dr-tattico` e `/dr-CreateLaunchProfiles`. Il template in repo (`templates/global-claude.md`) è aggiornato; la propagazione richiede `/dr-install-global`, che l'utente non ha autorizzato in questa sessione.
- **Nessun commit** e nessun `git push`: le modifiche restano nel working tree.
- **Verifica indipendente (`/dr-verify-plan`, sub-agente senza contesto di implementazione).** Tutti i file di Scope CORRISPONDONO; 7 criteri su 8 SODDISFATTI al primo giro. Il criterio 3 risultava NON SODDISFATTO alla lettera per 6 occorrenze in `scaffolding-catalog.json`: sono le voci di `obsoleteArtifacts` volute dalla Fase 10. Difetto di redazione del piano, non del lavoro — il criterio 3 e la Verifica passo della Fase 12 sono stati riformulati, il codice non è stato toccato. Il sub-agente ha inoltre eseguito i guard dal vivo con 7 input (incluso `.claude/skills/../../evil`, bloccato) e confermato: 0 errori di sintassi, nessun commit oltre `278ab26`, nessuna modifica ai piani storici né a `.ai/handoff/`.
