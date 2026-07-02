# Piano: Supporto installazione globale (GlobalInstall / GlobalUpdate)
Data: 2026-06-17
Stato: COMPLETATO

## Obiettivo
Aggiungere una seconda modalità di installazione a setup.ps1 che installa le linee guida in `~/.claude/CLAUDE.md` (globale PC) invece che nel progetto corrente, mantenendo le due modalità completamente indipendenti e coesistenti.

## Scope

### File da creare
- [x] `templates/global-claude.md` — template CLAUDE.md per installazione globale (contenuto universale, senza istruzioni tipo-progetto)

### File da modificare
- [x] `setup.ps1` — aggiungere param `-GlobalInstall` e `-GlobalUpdate`; blocco di esecuzione separato con `exit 0` finale

### Perimetro negativo
- Non toccherò: `CLAUDE.md` del progetto, `.github/`, `.claude/skills/`, logica project-mode esistente
- Non cambierò comportamento di `-Update` o `-IncludeWorkflows`

## Fasi
- [x] 1. Creare `templates/global-claude.md` con contenuto universale (lingua, convenzioni core, piano, lint gate, skill table, MCP discovery — no tipo-progetto)
- [x] 2. Aggiungere a `setup.ps1`: param switches, blocco GlobalInstall/GlobalUpdate, `exit 0` per evitare project-mode, messaggio finale con istruzione aggiornamento
- [x] 3. Verificare coesistenza: le due modalità non si interferiscono (global non tocca progetto, project non tocca global)

## Design coesistenza

| Scenario | Risultato |
|----------|-----------|
| Solo `-GlobalInstall` | Scrive `~/.claude/CLAUDE.md`, ignora progetto |
| Solo run normale / `-Update` | Scrive nel progetto, ignora global |
| Entrambi attivi su stesso PC | Claude carica global first, poi project; project ha precedenza sui conflitti |
| Utente vuole solo globale | Clona repo standalone, `setup.ps1 -GlobalInstall` |
| Utente vuole solo progetto | Submodule + `setup.ps1` (comportamento attuale) |

## Criteri di verifica finale
- [x] `templates/global-claude.md` esiste e contiene sezione lingua, convenzioni, piano, lint, skill, MCP, citazione
- [x] `templates/global-claude.md` NON contiene istruzioni tipo-progetto (minimal-api, windows-service, rilevamento tipo)
- [x] `setup.ps1 -GlobalInstall` scrive in `~/.claude/CLAUDE.md` con sentinel `<!-- /davraf-guidelines -->`
- [x] `setup.ps1 -GlobalUpdate` fa `git pull` + aggiorna sezione in `~/.claude/CLAUDE.md`
- [x] Run normale `setup.ps1` NON tocca `~/.claude/CLAUDE.md` (blocco protetto da `exit 0`)
- [x] `-Update` normale NON tocca `~/.claude/CLAUDE.md` (blocco protetto da `exit 0`)
- [x] Nessuna modifica alla logica project-mode esistente
