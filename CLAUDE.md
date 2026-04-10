# Linee guida per Claude Code

## Lingua
- Rispondi sempre in **italiano**

## Comportamento generale
- Se l'utente scrive un termine tecnico in modo errato o impreciso, segnalarlo gentilmente e fornire la forma corretta, in modo che possa imparare la terminologia giusta

## Standard di progetto .NET
@.github/copilot-instructions.md

## Regola MCP Server
@.github/instructions/mcp-server-discovery.instructions.md

## Modifiche al codice

⛔ STOP — Prima di scrivere qualsiasi codice, devi completare questi tre passi e documentarli nel tuo output:

1. **Leggi** `.github/copilot-instructions.md` e **cita** la sezione rilevante per il task corrente.
2. **Identifica e leggi** il file `.github/instructions/*.md` pertinente al task. Se non sei sicuro di quale, elenca i file disponibili e scegli.
3. **Dichiara** scope, file che modificherai e cosa NON toccherai — formato obbligatorio:
   > "Modificherò `[file]` per `[motivo]`. Non toccherò `[fuori scope]`."

Non procedere finché questi tre passi non sono completati e visibili nel tuo output.

⛔ OBBLIGO DI RENDICONTO — Prima di scrivere qualsiasi codice, elenca esplicitamente nel tuo output tutti i file che hai letto, nel formato:

```
File letti:
- .github/copilot-instructions.md  ✓
- .github/instructions/database-provider.instructions.md  ✓
```

Se non hai letto un file che avresti dovuto leggere, dichiaralo come `✗ non letto` e leggilo prima di procedere. Non è accettabile procedere senza questo elenco visibile.

---

### Checklist pre-task (obbligatoria, da compilare ad ogni task)

- [ ] Ho letto `.github/copilot-instructions.md`? (cita la sezione rilevante)
- [ ] Ho identificato e letto il file istruzioni modulare pertinente? (indica quale)
- [ ] Ho dichiarato scope, file da modificare e perimetro negativo?
- [ ] So esattamente quali file creerò/modificherò? (elencali)
- [ ] Ho verificato che la struttura richiesta non esista già nel progetto?

Se anche una risposta è NO → fermati e completa il passo prima di procedere.

---

⛔ OGNI MODIFICA — a qualsiasi file (codice, docs, config, test) — richiede un piano approvato.

1. Usa `EnterPlanMode` per proporre il piano
2. Dichiara: scope, file che modificherai, motivazione, perimetro negativo
3. Attendi approvazione esplicita dell'utente
4. Usa `ExitPlanMode` per procedere

Il hook `pre_tool_use.py` blocca `Edit`/`Write`/`MultiEdit` automaticamente (validità 30 minuti dall'ultimo `ExitPlanMode`). Percorsi esenti: `.claude/` · `.ai/`

## Citazione fonti e modello

Alla fine di ogni risposta, se sono stati letti file o consultati documenti:
- Cita i file usati come fonti (path relativo)
- Indica il modello LLM usato (es. `claude-sonnet-4-6`)

## Invocazione automatica delle skill

Quando l'utente esprime un intento che corrisponde a una delle skill disponibili,
**invoca direttamente la skill** senza attendere conferma. Usa il contesto della
conversazione come argomento passato alla skill.

| Se l'utente dice qualcosa come... | Invoca |
|-----------------------------------|--------|
| "vai professor", "scrivi la doc", "aggiorna il README", "genera la scheda del progetto", "documenta gli endpoint", "prepara l'onboarding" | `/professor [richiesta]` |
| "consulta il warroom", "sentiamo le opinioni", "apri il tavolo", "cosa ne pensano gli esperti", "discutiamo questa scelta" | `/warroom [domanda o contesto]` |
| "chiedi al tattico", "rivedi questo prompt", "migliora il prompt", "scrivi un prompt per", "perché questo prompt non funziona" | `/tattico [prompt o descrizione]` |
| "pianifica il rilascio", "prepara l'ambiente", "come si deploya", "configura Docker", "procedura di deploy" | `/tech [task]` |
| "promote", "promuovi il branch", "crea la PR verso", "merge su", "porta su master/main/staging" | `/promote-to [target-branch] [--merge] [--delete]` |
| "audit api", "fai l'audit del backend", "analizza le api", "cerca dead code", "controlla il codice backend" | `/audit-api [focus opzionale]` |
| "audit frontend", "fai l'audit del fe", "analizza il frontend", "controlla i componenti" | `/audit-fe [focus opzionale]` |

Quando invochi una skill, passa come argomento tutto il contesto utile già presente
nella conversazione (codice aperto, domanda originale, file citati) — non chiedere
all'utente di ripetere le informazioni.
