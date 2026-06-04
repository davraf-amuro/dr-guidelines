# Copilot Instructions (AI Agent)

Progetto .NET 10. Rileva il tipo dal codice prima di procedere.

## Tipo di progetto

| Segnale nel codice | Tipo | Istruzione modulare |
|--------------------|------|---------------------|
| ``Workers/*.cs`` presente | Windows Service | ``windows-service.instructions.md`` |
| ``Endpoints/*.cs`` presente | Minimal API | ``minimal-api-architecture.instructions.md`` |

Leggi sempre l'istruzione modulare corretta prima di generare o modificare codice.

## Convenzioni essenziali (tutti i tipi)
- Primary constructors, async/await per I/O
- Logging strutturato con placeholder (no string interpolation nei log)
- Naming: namespace snake_case, classi PascalCase, variabili camelCase
- Validazione input: ogni endpoint con body usa ``IValidator<T>``; segui ``input-validation.instructions.md``

## Checklist Post-Generazione
- [ ] Tipo rilevato correttamente, istruzione modulare letta
- [ ] Ho seguito le istruzioni modulari pertinenti
- [ ] Logging strutturato e async/await usati dove serve

## Verifica post-modifica (qualsiasi file)
Dopo ogni modifica a un file:
1. Rileggi il file modificato
2. Confronta il contenuto con quanto richiesto
3. Solo se corrispondono, dichiara la modifica completata

## Ciclo di sviluppo obbligatorio
Ogni task segue il ciclo definito in ``dev-cycle.instructions.md``:
- **Dichiara** scope e file prima di agire
- **Esegui** un'operazione alla volta
- **Verifica** (rileggi) dopo ogni modifica
- **Segnala** incertezza - non assumere silenziosamente

Task con >= 2 operazioni: crea piano su disco in ``.ai/plans/`` prima di procedere.
Segui ``plan-tracking.instructions.md`` per struttura e verifica finale.

*Template v1.5 - .NET 10 - Token-optimized for AI agents* - Last Update 2026-06-04 - claude-sonnet-4-6
