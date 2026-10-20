# Linee guida personali — davraf
<!--
  Sorgente del blocco globale scritto da /dr-install-global (oppure da dr-guidelines-install.ps1 -Global).
  Nel file installato l'installer sostituisce questo titolo con "## Davraf Guidelines (Globale)"
  e chiude il blocco con il sentinel "/davraf-guidelines": ai successivi aggiornamenti
  viene riscritto solo quel blocco, quello che sta fuori resta intatto.
  Per aggiornare: /dr-install-global aggiorna  —  equivalente: dr-guidelines-install.ps1 -Global -Update
-->

## Lingua
Rispondi sempre in **italiano**.

## Comportamento generale
Termine tecnico errato o impreciso → segnala gentilmente + forma corretta.

## Nota di precedenza
Se nel progetto corrente esiste un `CLAUDE.md` con istruzioni specifiche,
quelle hanno priorità su queste linee guida generali.

## Agente primario e compatibilità

⛔ **Claude Code è l'agente primario**: ogni regola, istruzione, convenzione o linea guida creata o modificata deve funzionare con Claude Code.

GitHub Copilot e Codex sono **secondari, best-effort**:
- Nei file condivisi preferire sintassi e struttura neutra, leggibile da tutti gli agenti
- Feature esclusiva di Claude Code in un file condiviso → ammessa solo con l'alternativa per gli altri agenti accanto, oppure con il limite dichiarato (es. "Su Copilot: <alternativa>" / "Su Copilot non disponibile")
- Compatibilità secondaria costosa o incerta → **dichiara il limite e procedi**: non blocca il lavoro

## Convenzioni essenziali

- `async`/`await` (o l'equivalente del linguaggio) per ogni I/O
- Logging strutturato con placeholder (mai string interpolation nei log)
- Naming coerente con le convenzioni del linguaggio; in C#: primary constructors, namespace `snake_case`, classi `PascalCase`, variabili `camelCase`
- Validazione input: ogni endpoint con body usa un validatore esplicito
- Credenziali **mai** in file committati; dati sensibili → segui le istruzioni specifiche del progetto se disponibili

## Modifiche al codice — Dichiarazione scope

Prima di scrivere codice, una riga:
> "Modificherò `[file]` per `[motivo]`. Non toccherò `[fuori scope]`."

## Piano obbligatorio su disco

⛔ Task con **≥ 2 operazioni** → crea `.ai/plans/<YYYY-MM-DD>-<slug>/plan.md` prima di agire.

**Operazione** = ogni file creato, modificato o cancellato, e ogni comando con effetti (commit, installazione, migrazione, scrittura su un servizio esterno). Più modifiche allo stesso file = una operazione; letture e ricerche non contano.

1. Usa `EnterPlanMode` per proporre il piano, con la proposta di un branch dedicato (`plan/<slug>`): la scelta dell'utente va nel campo `Branch:`
2. Attendi approvazione esplicita dell'utente (`ExitPlanMode`)
3. Marca `[x]` ogni fase completata nel piano
4. A task completato: verifica ogni criterio → aggiorna `Stato: COMPLETATO`

Piano `IN CORSO` in `.ai/plans/` all'avvio sessione → riprendi da ultima fase incompleta.

Esenzioni: cartella `.ai/` (scrittura libera) e skill invocate esplicitamente dall'utente con `/nome` — l'invocazione è l'approvazione.

## Gate di Push — Lint obbligatorio

⛔ Prima di ogni `git push`:

| Tipo | Comando |
|------|---------|
| .NET | `dotnet format <percorso>.csproj --verify-no-changes` |
| Node.js | `npm run lint` (se lo script `lint` è definito in `package.json`) |
| Python | `ruff check .` oppure `flake8` |

Exit code non-zero → **blocca push**, elenca file con violazioni, chiedi conferma prima di correggere. Nessun comando applicabile (repo di soli documenti) → dichiaralo prima della push.

## MCP Server — Ricerca prima di creare

Prima di proporre un nuovo MCP server, cerca nell'ordine:

1. Tool già esposti nella sessione
2. `.mcp.json` (radice progetto) e `.vscode/mcp.json` (chiave `servers`)
3. `.claude/settings.json` / `.claude/settings.local.json` (chiave `mcpServers`)
4. `~/.claude/settings.json` / `~/.claude/settings.local.json`
5. Altri workspace aperti nell'ambiente corrente e MCP server già registrati nell'IDE
6. Server della suite `dr-*` (es. `db-schema` → `davraf-amuro/dr-mcp-dbschema`)

Solo se non trovato in nessuna fonte: proponi la creazione e ingaggia `/dr-warroom`.

## Naming delle skill — prefisso `dr-`

⛔ Ogni skill creata **su richiesta dell'utente** ha il nome prefissato `dr-`, seguito da
cosa fa e su cosa opera, in inglese kebab-case: `dr-print-md`, non `print`.

- Distingue le skill proprie da quelle di terze parti, dai plugin e dalle skill di sistema
- Il nome deve restare specifico: se vale solo per il markdown, dillo nel nome

## Invocazione automatica skill

| Se l'utente dice qualcosa come... | Invoca |
|-----------------------------------|--------|
| "stampa", "manda in stampa", "prepara per la stampa", "stampa da X a Y" | `/dr-stampa-md` *(se installata)* |
| "scrivi la doc", "aggiorna README", "documenta gli endpoint", "genera scheda progetto" | `/dr-professor` |
| "sentiamo le opinioni", "apri il tavolo", "cosa ne pensano gli esperti", "discutiamo questa scelta" | `/dr-warroom` |
| "rivedi questo prompt", "migliora il prompt", "scrivi un prompt per", "perché questo prompt non funziona" | `/dr-prompt-engineer` |
| "pianifica il rilascio", "prepara l'ambiente", "come si deploya", "configura Docker" | `/dr-tech` |
| "promuovi il branch", "crea la PR verso", "merge su", "porta su master/main/staging" | `/dr-promote-to` |
| "audit backend", "analizza le API", "cerca dead code", "controlla il codice backend" | `/dr-audit-api` *(se installata)* |
| "audit frontend", "analizza i componenti", "controlla il frontend" | `/dr-audit-fe` *(se installata)* |
| "aggiorna i pacchetti", "aggiorna le linee guida", "get-latest" | `/dr-get-latest` |
| "modifica testi", "riscrivi il testo", "correggi il testo", "migliora la descrizione" | `/dr-professor` |
| "aggiorna snapshot", "rigenera il riassunto", "snapshot del progetto" | `/dr-snapshot` |
| "passa le consegne", "handoff", "documento di passaggio" | `/dr-handoff` |
| "genera i profili di avvio", "crea launch.json", "configura il debug VS Code", "launch profiles" | `/dr-create-launch-profiles` |
| "crea una nuova solution", "parti da zero", "scaffolding", "nuovo progetto", "crea il workspace" | `/dr-scaffold` |
| "aggiungi un progetto", "aggiungi una minimal api", "aggiungi un worker", "aggiungi il frontend" | `/dr-scaffold-project` |
| "installa le linee guida qui", "aggiungi i pacchetti dr-*", "quali pacchetti mi servono" | `/dr-scaffold-guidelines` |
| "installa le linee guida globali", "aggiorna il CLAUDE.md globale", "linee guida su tutto il PC" | `/dr-install-global` |

Skill *(se installata)* assente → dillo all'utente. Invocazione dedotta da una frase di una skill con azioni irreversibili (commit, push, merge, issue, scrittura fuori dal repository) → conferma in una riga cosa farà, poi invoca.

## Citazione fonti e modello

Solo se l'utente lo chiede: cita i file usati come fonti (path relativo) e il modello LLM usato.

## Log delle richieste di permesso

Ogni volta che chiedi un permesso all'utente per eseguire un comando (o il permesso viene
negato), registra la richiesta in un file di log del progetto corrente:

1. File: `.ai/permessi-richiesti.md` nella radice del progetto. Se non esiste, crealo con
   l'intestazione e la tabella.
2. Aggiungilo a `.gitignore` se non c'è già: il log resta locale, non si committa.
3. Aggiungi una riga alla tabella: data, tool, comando o azione, motivo, esito
   (concesso / negato).

Scopo: raccogliere i comandi ricorrenti e decidere quali abilitare in modo definitivo in
`~/.claude/settings.json` (profilo utente: i permessi perpetui non vanno nei settings di progetto).
