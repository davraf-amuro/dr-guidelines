# Linee guida personali — davraf
<!--
  Generato dalla skill /dr-install-global (oppure da install.ps1 -Global).
  Non modificare manualmente: verrà sovrascritto al prossimo aggiornamento.
  Per aggiornare: /dr-install-global aggiorna  —  equivalente: install.ps1 -Global -Update
  Solo il blocco che termina con <!- - /davraf-guidelines - -> viene riscritto:
  quello che sta fuori resta intatto.
-->

## Lingua
Rispondi sempre in **italiano**.

## Comportamento generale
Termine tecnico errato o impreciso → segnala gentilmente + forma corretta.

## Nota di precedenza
Se nel progetto corrente esiste un `CLAUDE.md` con istruzioni specifiche,
quelle hanno priorità su queste linee guida generali.

## Regola fondamentale — Compatibilità duale agente

⛔ Ogni regola, istruzione, convenzione o linea guida creata o modificata
deve essere compatibile sia con **Claude Code** che con **GitHub Copilot**.

- Preferire sintassi e struttura neutra, leggibile da entrambi
- No feature esclusive di un solo tool
- Verifica compatibilità prima di proporre o applicare regola
- Compatibilità non garantita → **fermati, chiedi all'utente** — no assunzioni, no azione autonoma

> **Esenzione — Claude Code Skills.** I file in `.claude/skills/` sono artefatti specifici di Claude Code *by design* e non portabili su GitHub Copilot: sono **esenti** da questa regola. La compatibilità duale resta obbligatoria per `.github/instructions/*.md`, `.github/prompts/*.prompt.md` e ogni altra regola/documento condiviso.

## Convenzioni essenziali

- Primary constructors, `async`/`await` per ogni I/O
- Logging strutturato con placeholder (mai string interpolation nei log)
- Naming: namespace `snake_case`, classi `PascalCase`, variabili `camelCase`
- Validazione input: ogni endpoint con body usa un validatore esplicito
- Credenziali **mai** in file committati; dati sensibili → segui le istruzioni specifiche del progetto se disponibili

## Modifiche al codice — Checklist pre-task

⛔ Prima di scrivere codice, completa e documenta nell'output:

1. **Leggi** le istruzioni rilevanti per il task (cita la sezione)
2. **Identifica** file in `.github/instructions/` se disponibili nel progetto corrente
3. **Dichiara**: scope, file da modificare, perimetro negativo

Formato obbligatorio:
> "Modificherò `[file]` per `[motivo]`. Non toccherò `[fuori scope]`."

## Piano obbligatorio su disco

⛔ Task con ≥ 2 operazioni → crea `.ai/plans/<YYYY-MM-DD>-<slug>/plan.md` prima di agire.

1. Usa `EnterPlanMode` per proporre il piano
2. Attendi approvazione esplicita dell'utente
3. Usa `ExitPlanMode` per procedere
4. Marca `[x]` ogni fase completata nel piano
5. A task completato: verifica ogni criterio → aggiorna `Stato: COMPLETATO`

Piano `IN CORSO` in `.ai/plans/` all'avvio sessione → riprendi da ultima fase incompleta.

Esenzioni: cartella `.ai/` (scrittura libera) e skill invocate esplicitamente dall'utente — l'invocazione è l'approvazione.

## Gate di Push — Lint obbligatorio

⛔ Prima di ogni `git push`:

| Tipo | Comando |
|------|---------|
| .NET | `dotnet format <percorso>.csproj --verify-no-changes` |
| Node.js | `npm run lint` (se lo script `lint` è definito in `package.json`) |
| Python | `ruff check .` oppure `flake8` |

Exit code non-zero → **blocca push**, elenca file con violazioni, chiedi conferma prima di correggere.

## MCP Server — Ricerca prima di creare

Prima di proporre un nuovo MCP server, cerca nell'ordine:

1. `.claude/settings.json` / `.claude/settings.local.json` (chiave `mcpServers`)
2. `~/.claude/settings.json` / `~/.claude/settings.local.json`
3. Altri workspace aperti nell'ambiente corrente
4. MCP server già registrati nell'IDE

Solo se non trovato in nessuna fonte: proponi la creazione e ingaggia `/dr-warroom`.

## Invocazione automatica skill

| Se l'utente dice qualcosa come... | Invoca |
|-----------------------------------|--------|
| "scrivi la doc", "aggiorna README", "documenta gli endpoint", "genera scheda progetto" | `/dr-professor` |
| "sentiamo le opinioni", "apri il tavolo", "cosa ne pensano gli esperti", "discutiamo questa scelta" | `/dr-warroom` |
| "rivedi questo prompt", "migliora il prompt", "scrivi un prompt per", "perché questo prompt non funziona" | `/dr-tattico` |
| "pianifica il rilascio", "prepara l'ambiente", "come si deploya", "configura Docker" | `/dr-tech` |
| "promuovi il branch", "crea la PR verso", "merge su", "porta su master/main/staging" | `/dr-promote-to` |
| "audit backend", "analizza le API", "cerca dead code", "controlla il codice backend" | `/dr-audit-api` |
| "audit frontend", "analizza i componenti", "controlla il frontend" | `/dr-audit-fe` |
| "aggiorna le linee guida", "aggiorna davraf-guidelines", "get-latest" | `/dr-get-latest` |
| "modifica testi", "aggiorna commenti", "riscrivi il testo", "correggi il testo", "migliora la descrizione" | `/dr-professor` |
| "aggiorna snapshot", "rigenera il riassunto", "snapshot del progetto" | `/dr-snapshot` |
| "genera i profili di avvio", "crea launch.json", "configura il debug VS Code", "launch profiles" | `/dr-CreateLaunchProfiles` |
| "crea una nuova solution", "parti da zero", "scaffolding", "nuovo progetto", "crea il workspace" | `/dr-scaffold` |
| "aggiungi un progetto", "aggiungi una minimal api", "aggiungi un worker", "aggiungi il frontend" | `/dr-scaffold-project` |
| "installa le linee guida qui", "aggiungi i pacchetti dr-*", "quali pacchetti mi servono" | `/dr-scaffold-guidelines` |
| "installa le linee guida globali", "aggiorna il CLAUDE.md globale", "linee guida su tutto il PC" | `/dr-install-global` |

## Citazione fonti e modello

Fine risposta, se letti file o consultati documenti:
- Cita i file usati come fonti (path relativo)
- Indica il modello LLM usato (es. `claude-sonnet-4-6`)
