---
applyTo: "docs/**/*.md,.github/**/*.md,.claude/skills/**/*.md"
---

# Versionamento della documentazione

Ogni volta che un documento in `docs/`, un'istruzione, un prompt o una skill viene creato o modificato, il footer deve essere aggiornato. Due formati: uno per i documenti, uno per le regole.

## Formato footer — documenti in `docs/`

```
*Revisione v{N} — {YYYY-MM-DD HH:MM} — {modello-llm}*
```

Esempi:
```
*Revisione v1.0 — 2026-03-23 14:30 — claude-sonnet-4-6*
*Revisione v1.1 — 2026-03-23 15:45 — claude-sonnet-4-6*
```

## Regole

| Campo | Regola |
|-------|--------|
| `v{N}` | Formato `major.minor` con due contatori interi: il minore cresce di 1 a ogni modifica (v1.9 → v1.10, v3.24 → v3.25, non v2.0); il maggiore cresce di 1 e il minore torna a 0 se la struttura cambia radicalmente (v3.25 → v4.0) |
| `{YYYY-MM-DD HH:MM}` | Data e ora locale al momento della modifica |
| `{modello-llm}` | ID del modello usato (es. `claude-sonnet-4-6`, `claude-opus-4-8`) |

## Formato footer — istruzioni, prompt, skill

Vale per `.github/instructions/*.md`, `.github/prompts/*.prompt.md`, `.claude/skills/*/SKILL.md` e i `CLAUDE.md` dei pacchetti:

```
*{Tipo} v{X.Y} - {Nome} - {YYYY-MM-DD} — {modello-llm} — {nota}*
```

- `{Tipo}`: `Istruzione`, `Prompt` o `Skill`
- `{X.Y}`: stessi contatori interi di `v{N}`: `Y` +1 a ogni modifica (v1.9 → v1.10), `X` +1 e `Y` a 0 se cambia il comportamento richiesto in modo incompatibile
- `{nota}`: cosa è cambiato in questa versione, in breve (obbligatoria; `prima versione` alla creazione)
- Un solo paio di asterischi attorno all'intera riga

## Quando aggiornare

- Sempre, anche per modifiche minori (aggiunta di una riga, correzione typo)
- Il footer va in fondo al file, come ultima riga
- Se il documento non ha ancora un footer, aggiungilo alla prima modifica partendo da `v1.0`

*Istruzione v1.2 - Doc Versioning - 2026-10-29 — claude-opus-5-5 — versione come contatore minore intero (v1.9 → v1.10), non incremento decimale di 0.1*
