# Piano: Fase 0-bis come finestra AskUserQuestion + ramo senza solution
Data: 2026-08-09
Stato: COMPLETATO

## Obiettivo
La Fase 0-bis di `/dr-scaffold-project` deve aprire una finestra `AskUserQuestion` con tre vie — sì col nome di default, nome libero via "Altro", no e si procede senza solution — invece di una domanda scritta a testo libero che si ferma in caso di rifiuto.

## Contesto
Iterazione precedente (piano `2026-08-09-scaffold-solution-mancante`) ha ridotto la domanda a una riga di testo. Richiesta ulteriore: deve essere una **finestra** con opzioni, e il "No" non deve più essere uno stop ma un ramo eseguibile — progetto creato senza aggancio a nessuna solution.

Vincolo dello strumento: `AskUserQuestion` non offre campo testo dentro un'opzione. Il testo libero è l'opzione "Altro", aggiunta in automatico. Quindi: opzione 1 = sì col nome proposto, opzione 2 = no/senza solution, "Altro" = sì con nome digitato.

## Scope
### File da modificare
- [x] `.claude/skills/dr-scaffold-project/SKILL.md` — Fase 0-bis come finestra a opzioni; nuovo ramo "senza solution" propagato a Fase 2, 3, 4
- [x] `.claude/skills/dr-scaffold/SKILL.md` — allinea il paragrafo "Prerequisito mancante ≠ vicolo cieco" alla nuova forma a opzioni

### Perimetro negativo
- Non toccherò `.claude/skills/dr-scaffold-solution/SKILL.md`, `scaffolding-catalog.json`, gli installer, `docs/`, `CLAUDE.md`
- Non toccherò la copia installata in `e:\...\workspace\test\.claude\skills`
- Nessun `git commit`, nessun `git push`

## Fasi (formato atomico)

### Fase 1: Fase 0-bis come finestra a opzioni
- **Stato**: [x]
- **Precondizione**: `dr-scaffold-project/SKILL.md` contiene la sezione "Fase 0-bis — Solution assente: una domanda, breve"
- **File**: `.claude/skills/dr-scaffold-project/SKILL.md`
- **Operazione**: EDIT
- **Azione**: sostituire la "Forma obbligatoria" testuale con la specifica della finestra `AskUserQuestion`: una sola domanda ("Non esiste nessuna solution in `<path>`. Ne creo una `.slnx`?"), header breve, opzione 1 `Sì, crea <cartella>.slnx` (nome di default = cartella corrente in lowercase, validato col pattern del catalogo), opzione 2 `No, procedi senza solution`, più nota che l'opzione "Altro" automatica raccoglie il nome scelto dall'utente ed equivale a un sì. Mantenere i divieti (no destinazione, no tipologia, no catalogo/pacchetti/dry-run) e la tabella degli stati, adattando le tre righe speciali alla stessa forma a opzioni.
- **Tool ammessi**: Edit
- **Verifica passo**: rileggendo il file, la Fase 0-bis descrive la finestra con le due opzioni e il ruolo di "Altro"; i divieti sono intatti
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md

### Fase 2: Ramo "senza solution" nelle fasi di esecuzione
- **Stato**: [x]
- **Precondizione**: Fase 1 verificata
- **File**: `.claude/skills/dr-scaffold-project/SKILL.md`
- **Operazione**: EDIT
- **Azione**: definire il ramo scelto con "No, procedi senza solution" — progetto creato in `targetPath\<nome>`, nessun `dotnet sln add`, dry-run di Fase 2 senza riga di aggancio, Fase 3 con `dotnet build <targetPath>\<nome>\<nome>.csproj` e `dotnet format <...>.csproj` al posto della solution, tabella di verifica di Fase 4 con le righe sul `.csproj` invece che sulla solution, e avviso finale che il progetto resta sciolto e va agganciato in seguito con `dotnet sln add`. Aggiornare il blocco Rollback con la variante senza solution (nessun `git checkout --` del file solution).
- **Tool ammessi**: Edit
- **Verifica passo**: rileggendo il file, ogni fase da 2 a 4 e il rollback distinguono i due rami e nessun comando del ramo senza solution cita un file solution
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md

### Fase 3: Allinea il router
- **Stato**: [x]
- **Precondizione**: Fase 2 verificata
- **File**: `.claude/skills/dr-scaffold/SKILL.md`
- **Operazione**: EDIT
- **Azione**: nel paragrafo "Prerequisito mancante ≠ vicolo cieco", sostituire la citazione della domanda testuale con il rimando alla finestra a opzioni della Fase 0-bis di `/dr-scaffold-project`, citando le due opzioni e "Altro" come campo del nome.
- **Tool ammessi**: Edit
- **Verifica passo**: rileggendo il file, il paragrafo descrive la finestra e non contiene più la domanda in forma di citazione testuale singola
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md

## Criteri di verifica finale
- [x] La Fase 0-bis specifica una `AskUserQuestion` con opzione sì (nome di default), opzione "No, procedi senza solution" e "Altro" come campo nome
- [x] Il ramo senza solution è eseguibile end-to-end: creazione, build, format, verifica e rollback non citano mai un file solution
- [x] `dr-scaffold/SKILL.md` descrive la stessa finestra
- [x] `git status --short` mostra i due SKILL.md di questo piano più `.ai/plans/`; `dr-scaffold-solution/SKILL.md` risulta modificato come residuo non committato del piano `2026-08-09-scaffold-solution-mancante`, non da questo
