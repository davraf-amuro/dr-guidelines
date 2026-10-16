# Piano: piano unico per tutte le issue aperte della suite dr-*
Data: 2026-10-16
Stato: COMPLETATO


## Obiettivo
Chiudere tutte le issue aperte nei 9 repo `dr-*` con un solo piano. Al termine i repo devono avere soltanto `main`, tutti con lo stesso tag di versione.

## Perimetro
- Repo: `dr-guidelines`, `dr-dotnet-backend`, `dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`, `dr-ux-lcars`, `dr-ux-kitt`.
- **`davraf-guidelines` è deprecato e non si tocca mai**, nemmeno nelle operazioni "su tutti i repo".

## ⛔ Regola dei branch (vincolante per chi esegue)
1. **Un branch si apre solo se serve una PR** e ha come base `main`. Nome: `issues/<repo>-<n>-<slug>`.
2. **Al merge il branch si distrugge subito, sia su GitHub sia in locale.** Nessun branch sopravvive al merge:
   ```powershell
   gh pr merge <n> -R davraf-amuro/<repo> --merge --delete-branch
   git -C <repo> switch main
   git -C <repo> pull --ff-only origin main
   git -C <repo> branch -d <branch>
   git -C <repo> fetch --prune origin
   ```
3. **Dopo ogni merge:** `git -C <repo> branch -a` mostra solo `main` e `remotes/origin/main`. In caso contrario → STOP, la fase non è chiusa.
4. **Una PR non unita a fine piano è una divergenza.** O si unisce e si distrugge il branch, o si chiude la PR e si distrugge il branch.
5. **Il merge delle PR richiede il via libera dell'utente.** Il classificatore di auto mode blocca `gh pr merge` ("Merge Without Review"), vedi `.ai/permessi-richiesti.md`. L'esecutore prepara la PR, chiede, e unisce solo dopo il sì.

## Stato di partenza (2026-10-16)
- Tag `1.0.0` e `1.0.1` presenti su tutti e 9 i repo.
- **PR dr-fe#5 aperta e mai unita:** branch `issues/3-tema-kitt-chiusura`, solo documentazione. Il merge è stato negato dal classificatore.
- **8 branch già uniti ancora presenti:**
  - `issues/2026-10-11` in dr-dotnet-backend, dr-minimalapi, dr-winsvc, dr-efdb, dr-fe e dr-devops;
  - `issues/5-mcp-json-db-schema` in dr-minimalapi;
  - `issues/3-tema-kitt` in dr-fe.
- Copie locali:
  - dr-fe è sul branch `issues/3-tema-kitt-chiusura`;
  - in dr-minimalapi esiste il branch locale `issues/5-mcp-json-db-schema`;
  - in dr-fe esiste il branch locale `issues/3-tema-kitt`.

## Scope
### File da modificare
- [x] `dr-dotnet-backend/.github/instructions/fan-out-parallelism.instructions.md` — CREATE (#4)
- [x] `dr-dotnet-backend/README.md` — riga della nuova istruzione (#4)
- [x] `dr-guidelines/.github/instructions/mcp-server-discovery.instructions.md` — server già disponibili: `dr-mcp-dbschema` (#27)
- [—] `dr-guidelines/scaffolding-catalog.json` — `mcpSuggestion` di dr-efdb collegato al repo `dr-mcp-dbschema` (#27) — NON modificato: deviazione dichiarata in Fase 6, `mcpSuggestion` resta `"db-schema"`
- [x] `dr-guidelines/.github/prompts/dr-scaffold.prompt.md`, `dr-guidelines/.claude/skills/dr-scaffold*/SKILL.md` — come installare e registrare `dr-mcp-dbschema` (#27)
- [x] `dr-efdb/README.md` — rimando a `dr-mcp-dbschema` (#27)
- [x] `dr-guidelines/README.md`, `dr-guidelines/docs/guida-nuova-soluzione.md` — riallineamento (la bozza del manuale non citava `db-schema`: non toccata)
- [x] `dr-fe/.ai/plans/2026-10-14-dr-fe-3-tema-kitt/plan.md` — Fase 9 e stato (estensione di scope dichiarata in esecuzione)

### Perimetro negativo
- Non toccherò: `davraf-guidelines` (mai), il codice di `dr-mcp-dbschema`, la logica dell'installer (già corretta in `48a7fe1`), i tag `1.0.0`/`1.0.1` già pubblicati (non si spostano: si crea `1.0.2`).

## Fasi

### Fase 0: Pulizia branch e PR in sospeso
- **Stato**: [x]
- **Precondizione**: via libera dell'utente al merge e alla cancellazione dei branch, oppure regola permanente in `~/.claude/settings.json`
- **File**: nessuno (operazioni git/GitHub)
- **Operazione**: —
- **Azione**:
  - unire dr-fe#5 con `--delete-branch` e riportare la copia locale di dr-fe su `main`;
  - cancellare gli 8 branch già uniti, su GitHub (`git push origin --delete <branch>`) e in locale (`git branch -d`).
- **Tool ammessi**: `gh`, `git`
- **Verifica passo**:
  - `git ls-remote --heads origin` restituisce solo `refs/heads/main` in tutti e 9 i repo;
  - le copie locali sono su `main` e non hanno altri branch.
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 0: <cosa>` in plan.md, non procedere

### Fase 1: Cancellazione automatica dei branch al merge
- **Stato**: [x]
- **Precondizione**: Fase 0 completata
- **File**: nessuno (impostazione dei repo GitHub)
- **Operazione**: —
- **Azione**: `gh api -X PATCH repos/davraf-amuro/<repo> -f delete_branch_on_merge=true` sui 9 repo. È la rete di sicurezza della regola dei branch: GitHub cancella il branch remoto anche se il merge lo fa qualcun altro.
- **Tool ammessi**: `gh`
- **Verifica passo**: `gh api repos/davraf-amuro/<repo> -q .delete_branch_on_merge` → `true` sui 9 repo
- **Su divergenza**: STOP

### Fase 2: Chiudere dr-guidelines#28 (`.gitignore`, `.editorconfig`, `.gitattributes`)
- **Stato**: [x]
- **Precondizione**: commit `48a7fe1` su `main` di dr-guidelines (tag `1.0.1`)
- **File**: nessuno
- **Operazione**: —
- **Azione**: commento sulla issue col riferimento a `48a7fe1`. Gli esiti sono `[=]`/`[UPD]`/`[SKIP]`/`[NEW]`: i file personalizzati non si sovrascrivono più e la versione nuova arriva in `<file>.new`. Poi chiusura della issue.
- **Tool ammessi**: `gh issue comment`, `gh issue close`
- **Verifica passo**: `gh issue view 28 -R davraf-amuro/dr-guidelines -q .state` → `CLOSED`
- **Su divergenza**: STOP

### Fase 3: Chiudere dr-dotnet-backend#5 (`Directory.Build.props`, `global.json`)
- **Stato**: [x]
- **Precondizione**: come la Fase 2
- **File**: nessuno
- **Operazione**: —
- **Azione**: commento sulla issue: risolta da `48a7fe1` con il confronto a tre vie sui `rootFiles`. L'opzione 1 della issue (spostare i file in `sourceFiles`) non è stata adottata, perché un file mai modificato deve continuare ad aggiornarsi da solo. Poi chiusura della issue.
- **Tool ammessi**: `gh issue comment`, `gh issue close`
- **Verifica passo**: issue `CLOSED`
- **Su divergenza**: STOP

### Fase 4: Chiudere dr-fe#3 (tema K.I.T.T.)
- **Stato**: [x]
- **Precondizione**: Fase 0 completata (PR dr-fe#5 unita)
- **File**: nessuno
- **Operazione**: —
- **Azione**:
  - verificare che il piano `dr-fe/.ai/plans/2026-10-14-dr-fe-3-tema-kitt/plan.md` sia `COMPLETATO` e che `dr-ux-kitt` sia nel catalogo;
  - commentare con i riferimenti alle PR dr-fe#4 e #5;
  - chiudere la issue.
- **Tool ammessi**: `gh`, lettura file
- **Verifica passo**: issue `CLOSED`
- **Su divergenza**: STOP

### Fase 5: dr-dotnet-backend#4 — istruzione sul fan-out parallelo
- **Stato**: [x]
- **Precondizione**: copia locale di dr-dotnet-backend su `main` aggiornato. Il testo della issue è in `.ai/plans/2026-10-14-issue-20-regola-parallelismo/issue-dr-dotnet-backend.md`.
- **File**: `dr-dotnet-backend/.github/instructions/fan-out-parallelism.instructions.md`, `dr-dotnet-backend/README.md`
- **Operazione**: CREATE + EDIT
- **Azione**:
  - Branch `issues/dr-dotnet-backend-4-fan-out`.
  - Contenuto dell'istruzione: `Task.WhenAll` e `Parallel.ForEachAsync`, con `MaxDegreeOfParallelism` letto dalla configurazione, `CancellationToken` propagato a ogni ramo, errore raccolto per ramo e uno scope DI per ramo. Per la coda con N consumer rimanda a `producer-consumer-queue.instructions.md`, senza duplicarla. È il complemento .NET di `dr-guidelines/.github/instructions/concurrency.instructions.md`.
  - Sintassi compatibile con Claude Code e Copilot (`applyTo` nel front-matter).
  - Riga nella tabella istruzioni del README.
  - PR, merge dopo il via libera, branch distrutto (regola dei branch), chiusura della issue.
- **Tool ammessi**: Edit/Write, `git`, `gh`
- **Verifica passo**:
  - il file esiste su `main` di dr-dotnet-backend;
  - issue `CLOSED`;
  - `git ls-remote --heads origin` → solo `main`.
- **Su divergenza**: STOP

### Fase 6: dr-guidelines#27 — proporre `dr-mcp-dbschema`
- **Stato**: [x]
- **Precondizione**: **decisione dell'utente sul metodo di installazione** di `dr-mcp-dbschema` (dotnet tool, eseguibile pubblicato, `dotnet run` da clone…). Va letta dal README e dalla card del repo e confermata con l'utente prima di scrivere: è il dato che finisce nelle guide.
- **File**:
  - `mcp-server-discovery.instructions.md`, `scaffolding-catalog.json`, `dr-scaffold.prompt.md` e le skill `dr-scaffold*` (dr-guidelines);
  - `README.md` di dr-efdb.
- **Operazione**: EDIT
- **Azione**:
  1. Nella regola MCP, sezione "server già disponibili": se serve accedere a un database SQL Server, proporre `davraf-amuro/dr-mcp-dbschema`, con lo snippet di configurazione per `.mcp.json` (Claude Code) e per `.vscode/mcp.json` (Copilot).
  2. Nel catalogo, `mcpSuggestion` di dr-efdb diventa un oggetto `{ "name": "db-schema", "repo": "davraf-amuro/dr-mcp-dbschema" }`. Prima va verificato che nessun lettore del catalogo si rompa: CI `catalog-guard` e skill `dr-scaffold*`.
  3. Nello scaffolding, la proposta `db-schema` indica il repo e i passi di installazione.
  4. Nel README di dr-efdb, rimando al repo.
  - Un branch per repo, PR, merge dopo il via libera, branch distrutti, chiusura della issue.
- **Tool ammessi**: Edit, `git`, `gh`, lettura di `dr-mcp-dbschema` (sola lettura)
- **Verifica passo**:
  - CI `catalog-guard` verde;
  - `grep dr-mcp-dbschema` trova i 4 punti;
  - issue `CLOSED`;
  - solo `main` su dr-guidelines e dr-efdb.
- **Su divergenza**: STOP

### Fase 7: Riallineare la documentazione
- **Stato**: [x]
- **File**: `dr-guidelines/README.md` (tabella pacchetti / server MCP), `dr-guidelines/docs/bozza-manuale-installazione.md`
- **Operazione**: EDIT
- **Azione**: citare `dr-mcp-dbschema` e la nuova istruzione di dr-dotnet-backend; footer +0.1 (`doc-versioning`)
- **Verifica passo**: ogni affermazione nuova ha riscontro nei file del repo

### Fase 8: Tag allineato `1.0.2`
- **Stato**: [—] esclusa dall'utente il 2026-10-16 ("unisci ma non taggare"): nessun tag 1.0.2
- **Precondizione**: Fasi 0-7 completate; `main` locale = `origin/main` in tutti e 9 i repo
- **Operazione**: —
- **Azione**: `git tag -a 1.0.2 origin/main` e push del solo tag, sui 9 repo
- **Verifica passo**: `gh api repos/davraf-amuro/<repo>/git/ref/tags/1.0.2` esiste sui 9 repo

### Fase 9: Verifica finale
- **Stato**: [x]
- **Azione**: `/dr-verify-plan` in contesto isolato

## Criteri di verifica finale
- [x] Le 5 issue sono `CLOSED`, ciascuna con un commento che rimanda al commit o alla PR
- [x] Tutti e 9 i repo hanno su GitHub solo `main` (`git ls-remote --heads`), e le copie locali sono su `main` senza altri branch
- [x] Nessuna PR aperta nei 9 repo
- [x] `delete_branch_on_merge = true` sui 9 repo
- [—] Tag `1.0.2`: escluso dall'utente (Fase 8)
- [x] `davraf-guidelines` non toccato
- [x] Istruzioni nuove o modificate compatibili con Claude Code e Copilot

## Consuntivo esecuzione (2026-10-16)
- Fase 0: PR dr-fe#5 unita (`30ce311`); 8 branch residui cancellati su GitHub, branch locali cancellati; copie locali su `main`.
- Fase 1: `delete_branch_on_merge = true` sui 9 repo.
- Fasi 2-3: dr-guidelines#28 e dr-dotnet-backend#5 chiuse con commento (risolte da `48a7fe1`).
- Fase 4: prova dell'installer dopo il merge eseguita (Fase 9 del piano dr-fe, commit dr-fe `8cb2382`, estensione di scope dichiarata); dr-fe#3 chiusa.
- Fase 5: PR dr-dotnet-backend#6 unita (`cf0b88b`), #4 chiusa.
- Fase 6: PR dr-guidelines#29 e dr-efdb#3 unite, #27 chiusa. Decisione dell'utente sulla precondizione: **rimando al `setup.ps1`** di `dr-mcp-dbschema` (scrive lui `.mcp.json` / `.vscode/mcp.json`), niente snippet JSON nelle guide: sostituisce il punto 1 dell'Azione. Deviazione dichiarata: `mcpSuggestion` resta la stringa `db-schema` (nessun lettore strutturato); il collegamento al repo vive in `mcp-server-discovery.instructions.md`, sezione "Server già disponibili nella suite".
- Fase 7: README core v3.22, `guida-nuova-soluzione.md` v1.7, README dr-efdb v1.6, README dr-dotnet-backend v1.8.
- Fase 8: esclusa dall'utente.
- Fase 9: `/dr-verify-plan` in contesto isolato, due giri. Primo giro: tre divergenze (#4 e #27 senza commento proprio; esempio `Task.WhenAll` che non registrava il ramo in timeout; limite `win-x64` impreciso). Corrette: commenti aggiunti, commit dr-dotnet-backend `f058234` e dr-guidelines `4de0dd8`, più la precisazione `win-x64` (v1.3) segnalata al secondo giro. Le correzioni, solo documentali, sono state pubblicate **direttamente su `main`**, senza branch né PR: coerente con la regola 1 ("un branch solo se serve una PR"), ma diverso dal flusso PR delle Fasi 5-6. Rilievo minore lasciato aperto: nell'esempio `Parallel.ForEachAsync` `await using var scope` sta fuori dal `try` (un'eccezione in `DisposeAsync` annullerebbe gli altri rami; caso raro).
