# Decisioni — sessione 2026-10-20

## Claude Code agente primario

**Contesto**: la regola precedente imponeva compatibilità piena con Claude Code e Copilot.

**Decisione**: Claude Code primario; Copilot e Codex best-effort. Compatibilità secondaria costosa o incerta → dichiarare il limite e procedere.

**Motivazione**: scelta utente.

**Conseguenze**: testo identico in `CLAUDE.md`, `templates/global-claude.md`, `~/.claude/CLAUDE.md`.

## Soglia del piano ≥ 2 operazioni

**Contesto**: soglie diverse fra file.

**Decisione**: ≥ 2 operazioni ovunque; "operazione" = file creato/modificato/cancellato o comando con effetti; più modifiche allo stesso file = una operazione.

**Motivazione**: scelta utente.

**Conseguenze**: fonte unica `plan-tracking.instructions.md`.

## Commit su main, push a fine sessione

**Contesto**: esecuzione del piano di audit; inizialmente scelto "nessun push".

**Decisione**: commit su `main`, uno per fase/repo; push di tutti i 9 repo su richiesta esplicita dell'utente a fine sessione.

**Motivazione**: scelta utente.

**Conseguenze**: ordine di push `dr-dotnet-backend`, altri satelliti, `dr-guidelines`.

## Copie Codex generate senza sostituzioni di testo

**Contesto**: il piano prevedeva una mappa di sostituzioni (`Claude Code` → `Codex`).

**Decisione**: `scripts/sync-codex.ps1` copia identici skill e `CLAUDE.md`, aggiunge un preambolo da `templates/codex-*-preamble.md`.

**Motivazione**: la sostituzione capovolgerebbe la regola sull'agente primario e aveva prodotto percorsi e URL inesistenti.

**Conseguenze**: `.agents/skills/` e `AGENTS.md` non si modificano a mano; CI con `-Check`.

## `.mcp.json` solo con `-WithMcp`

**Contesto**: l'installer copiava `.mcp.json` sempre.

**Decisione**: copia solo con `-WithMcp`; senza, riga `[sugg]`.

**Motivazione**: server MCP attivi senza scelta esplicita.

**Conseguenze**: documentato in README, docs e help degli script.

## `AGENTS.md` non installato negli host

**Contesto**: compatibilità Codex best-effort.

**Decisione**: l'installer porta `.agents/skills/`, non `AGENTS.md`.

**Motivazione**: compatibilità secondaria costosa; limite dichiarato.

**Conseguenze**: dichiarato in `CLAUDE.md`, README, onboarding.

## Correzione `$PSScriptRoot` senza piano

**Contesto**: 9 file modificati (≥ 2 operazioni).

**Decisione**: correzione eseguita su richiesta diretta dell'utente, dopo descrizione esatta del fix.

**Motivazione**: scope già descritto e chiesto dall'utente.

**Conseguenze**: nessun piano su disco per questa correzione.
