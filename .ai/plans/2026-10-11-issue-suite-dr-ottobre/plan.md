# Piano: le 10 issue aperte della suite dr-* in un solo percorso ordinato
Data: 2026-10-11
Stato: IN CORSO — approvato il 2026-10-11
Issue: davraf-amuro/dr-guidelines#15, davraf-amuro/dr-fe#1, davraf-amuro/dr-dotnet-backend#1, davraf-amuro/dr-dotnet-backend#2, davraf-amuro/dr-minimalapi#1, davraf-amuro/dr-minimalapi#2, davraf-amuro/dr-minimalapi#3, davraf-amuro/dr-efdb#1, davraf-amuro/dr-winsvc#1, davraf-amuro/dr-devops#1
Branch: issues/2026-10-11 (creato il 2026-10-11 da `main` aggiornato in dr-guidelines, dr-dotnet-backend, dr-minimalapi, dr-winsvc, dr-efdb, dr-fe, dr-devops; solo locale)

## Obiettivo
Chiudere le 10 issue aperte in un ordine guidato dalle dipendenze: prima le correzioni isolate, poi il contratto installer/catalogo, poi i contenuti che dipendono da decisioni di perimetro, infine la nuova istruzione producer/consumer.

## Contesto

### Issue e verifica sui file (2026-10-11)

| # | Issue | Verifica |
|---|---|---|
| A | [dr-winsvc#1](https://github.com/davraf-amuro/dr-winsvc/issues/1) — Serilog non compila su `HostApplicationBuilder` | Confermato: `windows-service.instructions.md` righe 60 e 79 usano `builder.Host.UseSerilog` dopo `Host.CreateApplicationBuilder` (righe 52, 68). ⚠️ `card-worker-service.prompt.md` **non** contiene né `Serilog` né `CreateApplicationBuilder` né `AddWindowsService`: il disallineamento non è un errore copiato, va fatto il confronto puntuale |
| B | [dr-minimalapi#1](https://github.com/davraf-amuro/dr-minimalapi/issues/1) — rimando a `src/test-guideline.api/` | Confermato: `minimal-api-architecture.instructions.md` riga 452 |
| C | [dr-efdb#1](https://github.com/davraf-amuro/dr-efdb/issues/1) — gemella di B | Confermato: `database-provider.instructions.md` righe 233-238, sezione "📖 Riferimento: Implementazione ModelKits" |
| D | [dr-fe#1](https://github.com/davraf-amuro/dr-fe/issues/1) — `-Package dr-fe` non installa il core | Confermato: `README.md` righe 33-37. Catalogo: `dependencies: []` anche per dr-dotnet-backend, dr-efdb, dr-devops; dr-minimalapi e dr-winsvc dipendono solo da dr-dotnet-backend; dr-ux-lcars da dr-fe. **Nessun** pacchetto dichiara il core. L'installer ha già `Resolve-DrDependencyTree` (`dr-guidelines-install-lib.ps1` riga 467): il difetto è sistemico, non solo del README di dr-fe |
| E | [dr-guidelines#15](https://github.com/davraf-amuro/dr-guidelines/issues/15) — installer: sorgenti applicativi | Confermato: `Copy-InstructionsAndPrompts` (riga 123) copia file piatti, `Copy-PackageRootFiles` (riga 217) copia alla stessa path relativa; unico uso di `rootFiles` fuori dal backend: `scripts/lcars-contrast.mjs` di dr-ux-lcars |
| F | [dr-devops#1](https://github.com/davraf-amuro/dr-devops/issues/1) — Docker senza Swarm | Confermato: le 3 istruzioni coprono solo `docker-compose_swarm.yaml`, `.gitlab-ci.yml` e Portainer; il README dichiara "compose Docker Swarm" ma non che il compose a host singolo è escluso |
| G | [dr-minimalapi#3](https://github.com/davraf-amuro/dr-minimalapi/issues/3) — rimandi secchi | Confermato: righe 95 (`database-startup-resilience`, dr-efdb), 179 (`frontend-organization`, dr-fe), 201 (`database-startup-resilience` + `docker-swarm-compose`, dr-devops). Regola di riferimento: `dr-guidelines/.github/instructions/cross-package-references.instructions.md` |
| H | [dr-minimalapi#2](https://github.com/davraf-amuro/dr-minimalapi/issues/2) — Data Protection, tabella chiavi | Confermato: riga 190 prescrive `PersistKeysToDbContext<TDbContext>()`, nessuna indicazione su quando applicare la migrazione |
| I | [dr-dotnet-backend#1](https://github.com/davraf-amuro/dr-dotnet-backend/issues/1) — tabella "Tipo di progetto" | Confermato: `dotnet-project-type.instructions.md` riga 13 (tabella), riga 17 (`Workers/*.cs` → Windows Service senza condizione su `AddWindowsService`); nessuna riga per class library né EF Core |
| J | [dr-dotnet-backend#2](https://github.com/davraf-amuro/dr-dotnet-backend/issues/2) — producer/consumer con coda bounded | File nuovo; rimandi in `dotnet-project-type` righe 29 ("Convenzioni .NET") e 71 ("Checklist Post-Generazione"); skill `.claude/skills/dr-audit-api/` presente; seguito core: `code-organization.instructions.md` riga 121, "Regola 4 — Pattern adatti alla situazione" |

### Esito della consultazione (`/dr-warroom`, 2026-10-11 — ARCH, BE, UI, UX, DBADMIN)

- **Convergenza su D (dr-fe#1): 4 su 4 per l'opzione (b)**, il core installato se manca dal manifest. Un README a due comandi si dimentica e invecchia, un comportamento dell'installer si verifica.
- **Convergenza su F (dr-devops#1): 4 su 4 per dichiarare ora il perimetro** (solo Swarm/Portainer/GitLab) e rimandare un'istruzione Docker per host singolo.
- **#15 a perimetro minimo** (ARCH, BE): voce di catalogo distinta per i sorgenti, destinazione relativa a una cartella configurabile, in `-Update` mai sovrascrivere ma scrivere `.new`. Varianti escluse per ora. UI le vorrebbe subito per le palette LCARS, ma oggi le palette passano dal prompt con conferma, che funziona.
- **Rischio di sicurezza (BE)**: una destinazione configurabile va normalizzata e confinata alla radice dell'host, rifiutando `..` e i percorsi assoluti (path traversal). Un `-Update` che sovrascrive i sorgenti dell'host è una perdita di dati silenziosa.
- **Accoppiamenti (ARCH)**: I e J toccano lo stesso file, quindi vanno nella stessa ondata. G (riga 201) dipende dal perimetro deciso per F: i rimandi condizionali verso dr-devops si scrivono dopo aver fissato cosa copre dr-devops.
- **Tensione sull'ordine**: ARCH vuole prima le correzioni puntuali, BE, UI e UX prima l'installer. Il piano mette per prime le correzioni isolate (A, B, C): non dipendono da nulla e chiudono subito tre issue. Il contratto installer/catalogo (D, E) viene subito dopo, prima di qualunque contenuto nuovo.
- **Tensione sulle gemelle B e C**: ARCH vuole rimuovere il rimando (un esempio inline si disallinea), BE e UI vogliono un esempio minimo inline. Resta decisione aperta D3.
- **DBADMIN, verdetto "Soluzione applicativa accettabile"**, con contenuti da scrivere nelle istruzioni:
  - H: migrazione come passo di deploy separato e serializzato (job one-shot o `dotnet ef migrations bundle`), mai `Migrate()` all'avvio con più repliche;
  - J: checkpoint ed elementi salvati in una sola transazione (un solo `SaveChanges` sullo stesso `DbContext`); idempotenza tramite vincolo UNIQUE sulla chiave naturale più upsert, non tramite un controllo "esiste già?" lato applicazione; il worker deve tollerare una riga assente o già elaborata; con più produttori, il cursore va protetto con concorrenza ottimistica.

## Decisioni prese dall'utente (2026-10-11)

- **D1 = minimo**: `sourceFiles` + `-SourceRoot` + `.new` in `-Update` + path confinato; varianti fuori piano.
- **D2 = (b)**: il core si installa se manca dal manifest (convergenza 4/4 del warroom, nessuna obiezione dell'utente).
- **D3 = (2)**: esempio minimo inline in `dr-efdb`, rimando condizionale da `dr-minimalapi`.
- **D4 = no**: solo dichiarazione del perimetro di dr-devops, nessuna nuova issue.
- **D5 = completo**: istruzione + rimandi + controlli `dr-audit-api` + riga core, in fasi separate (Fasi 18-21).

## Decisioni aperte (testo originale, sciolte sopra)

- **D1 — Perimetro di #15 (E).** Consigliato: minimo, cioè campo `sourceFiles` con destinazione relativa a una cartella scelta all'installazione, `.new` in `-Update` e path confinato alla radice. Le varianti diventano un'issue successiva. Alternativa: varianti incluse subito (più lavoro e più test, utile solo a dr-ux-lcars).
- **D2 — Forma della correzione D.** Consigliato (b): `Install-DrPackage` installa `dr-guidelines` quando manca dal manifest, prima delle dipendenze; con `-NoDependencies` lo elenca come `[skip]`, come le altre dipendenze. Alternativa (c): aggiungere `"dr-guidelines"` a `dependencies` di ogni pacchetto non-core nel catalogo. Funziona già con l'albero delle dipendenze, ma va ripetuto in ogni voce e in ogni pacchetto futuro.
- **D3 — Gemelle B e C.** (1) togliere il rimando e basta (ARCH); (2) togliere il rimando e mettere un esempio minimo inline nella sola istruzione `dr-efdb`, a cui `dr-minimalapi` rimanda in modo condizionale (BE, UI, raccomandato perché evita duplicati); (3) cartella `docs/` nel pacchetto. Sconsigliata: va mantenuta e l'installer non la copia.
- **D4 — Seguito di F.** Il piano dichiara il perimetro. Va decisa anche l'apertura di una nuova issue "Docker per host singolo" su dr-devops (azione esterna, solo con il tuo sì) oppure niente.
- **D5 — Perimetro di J.** Consigliato: istruzione + rimandi in `dotnet-project-type` + controlli `dr-audit-api` + riga nel core, in fasi separate così si può fermare dopo la prima. Alternativa (ARCH): solo istruzione e rimandi, il resto in issue successive.

## Scope

### File da modificare
- [ ] `dr-winsvc/.github/instructions/windows-service.instructions.md` — A
- [ ] `dr-winsvc/.github/prompts/card-worker-service.prompt.md` — A, solo se il confronto trova differenze
- [ ] `dr-minimalapi/.github/instructions/minimal-api-architecture.instructions.md` — B, G, H
- [ ] `dr-efdb/.github/instructions/database-provider.instructions.md` — C
- [ ] `dr-guidelines/dr-guidelines-install-lib.ps1` — D, E
- [ ] `dr-guidelines/dr-guidelines-install.ps1` — D, E (help dei parametri)
- [ ] `dr-guidelines/scaffolding-catalog.json` — E (schema `sourceFiles`, `updatedAt`); B e G: `suggests` di dr-minimalapi verso dr-efdb, dr-fe, dr-devops (obbligo di `cross-package-references`, sezione "Ogni rimando condizionale si dichiara anche nel catalogo" — emerso in Fase 4)
- [ ] `dr-guidelines/README.md`, `dr-guidelines/docs/installazione-semplice.md`, `dr-guidelines/docs/bozza-manuale-installazione.md` — D, E, dove descrivono `-Package` e i campi del catalogo
- [ ] `dr-fe/README.md` — D
- [ ] `README.md` degli altri pacchetti con la sezione "Via core, un solo installer" — D, solo se la frase va corretta
- [ ] `dr-devops/README.md` — F
- [ ] voce `dr-devops` di `dr-guidelines/scaffolding-catalog.json` (descrizione) — F
- [ ] `dr-dotnet-backend/.github/instructions/dotnet-project-type.instructions.md` — I, J
- [ ] `dr-dotnet-backend/.github/instructions/producer-consumer-queue.instructions.md` (nuovo) — J
- [ ] `dr-dotnet-backend/.claude/skills/dr-audit-api/SKILL.md` — I, J
- [ ] `dr-dotnet-backend/README.md` — J (elenco file)
- [ ] `dr-guidelines/.github/instructions/code-organization.instructions.md` — J (seguito core)

### Perimetro negativo
- Non toccherò: `dr-ux-lcars` (nessuna issue; l'adozione di `sourceFiles` da parte sua è un'issue successiva), `davraf-guidelines` e le skill legacy, `TODO/`, i piani esistenti, i branch `main`.
- Nessun push, nessuna PR, nessun commento o chiusura di issue senza tuo via libera esplicito alla fase di rilascio.
- Nessuna nuova istruzione Docker per host singolo in questo piano (D4).

## Fasi (formato atomico — obbligatorio)

Ogni modifica a un'istruzione rispetta la compatibilità duale Claude Code + Copilot (CLAUDE.md, regola fondamentale): niente feature esclusive di un solo tool. Footer di versione aggiornato secondo `doc-versioning.instructions.md`. Un commit per issue, sul branch `issues/2026-10-11` del repo interessato, con `Refs <owner/repo>#<n>`.

### Ondata 1 — Correzioni isolate (A, B, C)

### Fase 1: correggere Serilog negli esempi di dr-winsvc
- **Stato**: [x]
- **Precondizione**: decisioni D1-D5 registrate nel piano; `dr-winsvc` su `issues/2026-10-11`
- **File**: `dr-winsvc/.github/instructions/windows-service.instructions.md`
- **Operazione**: EDIT
- **Azione**: nei due esempi (righe ~60 e ~79) sostituire `builder.Host.UseSerilog((ctx, cfg) => cfg.ReadFrom.Configuration(ctx.Configuration));` con `builder.Services.AddSerilog((services, cfg) => cfg.ReadFrom.Configuration(builder.Configuration));` e citare il pacchetto `Serilog.Extensions.Hosting`
- **Tool ammessi**: nessuno
- **Verifica passo**: `grep -n "builder.Host" windows-service.instructions.md` → nessun risultato; `AddSerilog` presente 2 volte
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: confrontare `card-worker-service.prompt.md` con l'istruzione
- **Stato**: [x]
- **Precondizione**: Fase 1 completata
- **File**: `dr-winsvc/.github/prompts/card-worker-service.prompt.md`
- **Operazione**: EDIT (solo se ci sono differenze)
- **Azione**: confrontare punto per punto il prompt con le regole 1-8 e gli esempi di `windows-service.instructions.md`; elencare le differenze nel piano sotto questa fase; correggere solo quelle in contrasto con l'istruzione
- **Tool ammessi**: nessuno
- **Verifica passo**: elenco differenze scritto qui; ogni differenza marcata "corretta" o "non in contrasto"
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere
- **Esito confronto (2026-10-11)**:
  - "Pattern Architetturale" fisso (`BackgroundService + IServiceScopeFactory + Typed HttpClient`), in contrasto con "non inventare dati": l'istruzione non prescrive quei componenti → **corretto** (ricavato dal codice)
  - Riga `Enabled` sempre presente, l'istruzione prevede solo `IntervalSeconds` (regola 11) → **corretto** (righe solo per i campi presenti)
  - `StagingWorkerBase<T>` come alternativa a `BackgroundService` → non in contrasto (progetti esistenti)
  - Deploy `sc create` / `sc start` → non in contrasto

### Fase 3: chiudere il rimando ModelKits in dr-efdb
- **Stato**: [x]
- **Precondizione**: D3 decisa
- **File**: `dr-efdb/.github/instructions/database-provider.instructions.md`
- **Operazione**: EDIT
- **Azione**: sostituire la sezione "📖 Riferimento: Implementazione ModelKits" (righe ~233-238) secondo D3: (1) rimozione; (2) esempio minimo inline (DbContext, filtro con `ToExpression()`, DTO con `static Projection`, Service), coerente con le regole già scritte nel file
- **Tool ammessi**: nessuno
- **Verifica passo**: `grep -rn "test-guideline" dr-efdb/` → nessun risultato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: chiudere il rimando ModelKits in dr-minimalapi
- **Stato**: [x]
- **Precondizione**: Fase 3 completata
- **File**: `dr-minimalapi/.github/instructions/minimal-api-architecture.instructions.md`
- **Operazione**: EDIT
- **Azione**: alla riga ~452 togliere il rimando a `src/test-guideline.api/`; con D3=(2) sostituirlo con un rimando **condizionale** (struttura di `cross-package-references`) all'esempio di `database-provider.instructions.md` di dr-efdb
- **Tool ammessi**: nessuno
- **Verifica passo**: `grep -rn "test-guideline" dr-minimalapi/` → nessun risultato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: commit dell'ondata 1
- **Stato**: [x]
- **Precondizione**: Fasi 1-4 completate e rilette
- **File**: —
- **Operazione**: commit (nessun push)
- **Azione**: un commit per repo su `issues/2026-10-11`: dr-winsvc (`Refs davraf-amuro/dr-winsvc#1`), dr-efdb (`Refs davraf-amuro/dr-efdb#1`), dr-minimalapi (`Refs davraf-amuro/dr-minimalapi#1`)
- **Tool ammessi**: git
- **Verifica passo**: `git log -1` nei tre repo mostra il commit; `git status` pulito
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Ondata 2 — Contratto installer e catalogo (D, E)

### Fase 6: installare il core quando manca (D)
- **Stato**: [x]
- **Precondizione**: D2 decisa
- **File**: `dr-guidelines/dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: con D2=(b), in `Install-DrPackage` per un pacchetto diverso da `dr-guidelines` aggiungere `dr-guidelines` in testa all'elenco delle dipendenze mancanti se non è nel manifest; con `-NoDependencies` elencarlo come `[skip]`. Con D2=(c), saltare questa fase e aggiungere `"dr-guidelines"` alle `dependencies` di ogni voce non-core in `scaffolding-catalog.json`
- **Tool ammessi**: nessuno
- **Verifica passo**: in una cartella temporanea con `git init`, `-Package dr-fe` produce un manifest con `dr-guidelines` e `dr-fe`; con `-NoDependencies` solo `dr-fe` e la riga `[skip] dr-guidelines`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere
- **Esito (2026-10-11)**: `-Package dr-fe` in host vuoto → manifest `dr-guidelines, dr-fe`, riga `[dep]  dr-guidelines (richiesta da dr-fe, core implicito)`; con `-NoDependencies` → solo `dr-fe` e `[skip] dr-guidelines`

### Fase 7: allineare la documentazione di `-Package` (D)
- **Stato**: [x]
- **Precondizione**: Fase 6 completata
- **File**: `dr-guidelines/dr-guidelines-install.ps1` (help `.PARAMETER Package`), `dr-guidelines/README.md`, `dr-guidelines/docs/installazione-semplice.md`, `dr-fe/README.md`, README degli altri pacchetti con "Via core, un solo installer"
- **Operazione**: EDIT
- **Azione**: descrivere che `-Package X` installa anche il core se manca; togliere "al posto del core" dove non è più vero (con `/dr-professor` per il testo)
- **Tool ammessi**: `/dr-professor`
- **Verifica passo**: `grep -rn "al posto del core"` sui repo della suite → nessun risultato in contrasto con il nuovo comportamento
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere
- **Scope esteso in esecuzione**: oltre ai file previsti, help dei wrapper `dr-fe`, `dr-efdb`, `dr-devops`, `dr-dotnet-backend` ("Nessuna dipendenza.") e la frase "l'installer però non lo impone" nei README di 6 pacchetti; `docs/onboarding.md`, `docs/card-dr-guidelines.md`. `dr-ux-lcars` non toccato: il suo testo non era in contrasto

### Fase 8: campo `sourceFiles` nel catalogo (E)
- **Stato**: [x]
- **Precondizione**: D1 decisa; Fase 6 completata
- **File**: `dr-guidelines/scaffolding-catalog.json`, `dr-guidelines/dr-guidelines-install-lib.ps1` (`Get-DrPackageRegistry`)
- **Operazione**: EDIT
- **Azione**: definire il campo opzionale `sourceFiles: [{ "from": "<path nel pacchetto>", "to": "<path relativo alla cartella sorgente>" }]` e la chiave della cartella di destinazione (default = radice host); leggerlo in `Get-DrPackageRegistry` come `SourceFiles`; aggiornare `updatedAt`. Nessun pacchetto esistente lo usa ancora
- **Tool ammessi**: nessuno
- **Verifica passo**: catalogo JSON valido (`ConvertFrom-Json` senza errori); il registry espone `SourceFiles` vuoto per tutti i pacchetti
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 8: <cosa>` in plan.md, non procedere
- **Esito**: nessuna modifica al JSON del catalogo (campo opzionale, nessun pacchetto lo usa); validazione `from`/`to` in `Get-DrPackageRegistry` tramite il nuovo `Assert-DrRelativePath`, ereditata dal `catalog-guard` della CI

### Fase 9: copia dei sorgenti con protezione dell'host (E)
- **Stato**: [x]
- **Precondizione**: Fase 8 completata
- **File**: `dr-guidelines/dr-guidelines-install-lib.ps1`, `dr-guidelines/dr-guidelines-install.ps1`
- **Operazione**: EDIT
- **Azione**: nuova funzione `Copy-PackageSourceFiles`, chiamata da `Install-DrPackageContent`: (1) parametro `-SourceRoot` (relativo alla radice host); (2) path di destinazione normalizzato e confinato alla radice, con rifiuto di `..` e dei percorsi assoluti; (3) file assente → copia; (4) file presente in installazione → salta e lo dice; (5) file presente in `-Update` → scrive `<file>.new` e non sovrascrive mai
- **Tool ammessi**: nessuno
- **Verifica passo**: test manuale in cartella temporanea con un pacchetto finto: copia, salto, `.new` in `-Update`, rifiuto di `to: "../x"` e di `to: "C:/x"`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 9: <cosa>` in plan.md, non procedere
- **Esito**: 15/15 controlli superati (`test-sourcefiles.ps1` nella scratchpad di sessione); guard di catalogo verde; regressione `-Package dr-ux-lcars -SourceRoot frontend` → `dr-guidelines, dr-fe, dr-ux-lcars`

### Fase 10: documentare `sourceFiles` (E)
- **Stato**: [x]
- **Precondizione**: Fase 9 completata
- **File**: `dr-guidelines/README.md`, `dr-guidelines/docs/bozza-manuale-installazione.md`
- **Operazione**: EDIT
- **Azione**: descrivere il campo, `-SourceRoot` e la regola `.new` in `-Update`; annotare nella bozza del manuale le scoperte dei test delle Fasi 6 e 9
- **Tool ammessi**: `/dr-professor`
- **Verifica passo**: il campo e il parametro sono citati con un esempio
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 10: <cosa>` in plan.md, non procedere

### Fase 11: commit dell'ondata 2
- **Stato**: [x]
- **Precondizione**: Fasi 6-10 completate e rilette
- **File**: —
- **Operazione**: commit (nessun push)
- **Azione**: dr-guidelines: due commit (`Refs davraf-amuro/dr-fe#1`, poi `Refs davraf-amuro/dr-guidelines#15`); dr-fe e gli altri README toccati: commit `Refs davraf-amuro/dr-fe#1`
- **Tool ammessi**: git
- **Verifica passo**: `git status` pulito nei repo toccati
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 11: <cosa>` in plan.md, non procedere

### Ondata 3 — Perimetro dr-devops, poi rimandi di dr-minimalapi (F, G, H)

### Fase 12: dichiarare il perimetro di dr-devops (F)
- **Stato**: [ ]
- **Precondizione**: D4 decisa
- **File**: `dr-devops/README.md`, voce `dr-devops` in `dr-guidelines/scaffolding-catalog.json`
- **Operazione**: EDIT
- **Azione**: dichiarare che il pacchetto copre Swarm, Portainer e GitLab CI/CD; `Dockerfile` e `docker-compose.yml` per host singolo **non** sono coperti, e l'agente deve dichiararlo nell'output invece di applicare per analogia le regole Swarm
- **Tool ammessi**: `/dr-professor` (D4 = no: nessuna nuova issue)
- **Verifica passo**: la frase di esclusione è presente in entrambi i file
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 12: <cosa>` in plan.md, non procedere

### Fase 13: rimandi condizionali in dr-minimalapi (G)
- **Stato**: [ ]
- **Precondizione**: Fase 12 completata
- **File**: `dr-minimalapi/.github/instructions/minimal-api-architecture.instructions.md`
- **Operazione**: EDIT
- **Azione**: riscrivere i rimandi delle righe ~95, ~179 e ~201 secondo `cross-package-references.instructions.md`: condizione sul manifest, ramo pieno con file e sezione, ripiego minimo (cosa serve, non come), dichiarazione nell'output del ramo applicato. Il rimando a `docker-swarm-compose` vale solo per lo stack Swarm (perimetro della Fase 12)
- **Tool ammessi**: nessuno
- **Verifica passo**: ogni occorrenza di `database-startup-resilience`, `frontend-organization`, `docker-swarm-compose` sta dentro una condizione sul manifest
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 13: <cosa>` in plan.md, non procedere

### Fase 14: Data Protection, ordine di creazione della tabella (H)
- **Stato**: [ ]
- **Precondizione**: Fase 13 completata
- **File**: `dr-minimalapi/.github/instructions/minimal-api-architecture.instructions.md`
- **Operazione**: EDIT
- **Azione**: nella sezione Autenticazione, dopo `PersistKeysToDbContext` (riga ~190), aggiungere: in scale-out la tabella `DataProtectionKeys` deve esistere prima che partano repliche concorrenti; migrazione applicata come passo di deploy separato e serializzato (job one-shot o `dotnet ef migrations bundle`), mai `Migrate()` all'avvio con più repliche; sintomo del difetto: autenticazione intermittente
- **Tool ammessi**: nessuno
- **Verifica passo**: la regola è presente nella sezione Autenticazione e non contraddice il rimando condizionale a `database-startup-resilience`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 14: <cosa>` in plan.md, non procedere

### Fase 15: commit dell'ondata 3
- **Stato**: [ ]
- **Precondizione**: Fasi 12-14 completate e rilette
- **File**: —
- **Operazione**: commit (nessun push)
- **Azione**: dr-devops `Refs davraf-amuro/dr-devops#1`; dr-guidelines (catalogo) `Refs davraf-amuro/dr-devops#1`; dr-minimalapi due commit `Refs davraf-amuro/dr-minimalapi#3` e `Refs davraf-amuro/dr-minimalapi#2`
- **Tool ammessi**: git
- **Verifica passo**: `git status` pulito nei repo toccati
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 15: <cosa>` in plan.md, non procedere

### Ondata 4 — dr-dotnet-backend (I, J)

### Fase 16: tabella "Tipo di progetto" estesa (I)
- **Stato**: [ ]
- **Precondizione**: `dr-dotnet-backend` su `issues/2026-10-11`
- **File**: `dr-dotnet-backend/.github/instructions/dotnet-project-type.instructions.md`
- **Operazione**: EDIT
- **Azione**: nella tabella (riga ~13): (1) riga class library (`.csproj` senza `Endpoints/` né `Workers/`, referenziata da un altro progetto) → nessuna istruzione di architettura propria, valgono quelle del progetto che la referenzia; (2) riga EF Core (`DbContext` o `Microsoft.EntityFrameworkCore.*`) → `database-provider` e `database-startup-resilience`, pacchetto `dr-efdb`, con proposta di installazione se manca dal manifest; (3) riga `Workers/` vincolata a `AddWindowsService`/`UseWindowsService`; i job in-process (Quartz.NET, `IHostedService`) in una Minimal API non sono Windows Service
- **Tool ammessi**: nessuno
- **Verifica passo**: le tre righe sono presenti; nessun caso dell'issue finisce più in "tipo non rilevato"
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 16: <cosa>` in plan.md, non procedere

### Fase 17: rilevamento di dr-audit-api allineato (I)
- **Stato**: [ ]
- **Precondizione**: Fase 16 completata
- **File**: `dr-dotnet-backend/.claude/skills/dr-audit-api/SKILL.md`
- **Operazione**: EDIT
- **Azione**: allineare la fase di rilevamento del tipo di progetto alle tre righe nuove
- **Tool ammessi**: `/dr-prompt-engineer` (consultivo)
- **Verifica passo**: class library, EF Core e job in-process sono riconosciuti nella fase di rilevamento
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 17: <cosa>` in plan.md, non procedere

### Fase 18: nuova istruzione producer/consumer (J)
- **Stato**: [ ]
- **Precondizione**: D5 decisa; Fase 16 completata
- **File**: `dr-dotnet-backend/.github/instructions/producer-consumer-queue.instructions.md`
- **Operazione**: CREATE
- **Azione**: scrivere l'istruzione con i contenuti dei criteri di accettazione dell'issue: regola, motivazione, elementi obbligatori 1-8, semantica FIFO con N worker (un worker solo o partizioni per chiave), tre tipi di errore, casi di non applicazione, anti-pattern, checklist, test minimi; più le indicazioni DBADMIN (checkpoint ed elementi in una transazione, idempotenza con vincolo UNIQUE e upsert, worker tollerante a riga assente o già elaborata, cursore con concorrenza ottimistica se ci sono più produttori). Frontmatter `applyTo` coerente con gli altri file del pacchetto
- **Tool ammessi**: `/dr-prompt-engineer` (consultivo)
- **Verifica passo**: tutti i criteri di accettazione dell'issue spuntabili sul file; nessun valore fisso negli esempi (worker e capienza da configurazione)
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 18: <cosa>` in plan.md, non procedere

### Fase 19: rimandi a producer/consumer (J)
- **Stato**: [ ]
- **Precondizione**: Fase 18 completata
- **File**: `dr-dotnet-backend/.github/instructions/dotnet-project-type.instructions.md`, `dr-dotnet-backend/README.md`
- **Operazione**: EDIT
- **Azione**: una riga di rimando in "Convenzioni .NET" (riga ~29) e una voce in "Checklist Post-Generazione" (riga ~71); nuova riga nella tabella dei file del README
- **Tool ammessi**: nessuno
- **Verifica passo**: `grep -n "producer-consumer-queue"` → 2 occorrenze nell'istruzione, 1 nel README
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 19: <cosa>` in plan.md, non procedere

### Fase 20: controlli producer/consumer in dr-audit-api (J, se D5 lo include)
- **Stato**: [ ]
- **Precondizione**: Fase 19 completata; D5 include i controlli di audit
- **File**: `dr-dotnet-backend/.claude/skills/dr-audit-api/SKILL.md`
- **Operazione**: EDIT
- **Azione**: aggiungere i controlli: ciclo parallelo che mescola acquisizione ed elaborazione; `DbContext` o servizi scoped condivisi tra task paralleli; code non bounded; worker senza gestione dell'errore sul singolo elemento
- **Tool ammessi**: nessuno
- **Verifica passo**: i quattro controlli sono presenti con severità
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 20: <cosa>` in plan.md, non procedere

### Fase 21: principio producer/consumer nel core (J, se D5 lo include)
- **Stato**: [ ]
- **Precondizione**: Fase 19 completata; D5 include il seguito core
- **File**: `dr-guidelines/.github/instructions/code-organization.instructions.md`
- **Operazione**: EDIT
- **Azione**: nella tabella della "Regola 4 — Pattern adatti alla situazione" (riga ~121) aggiungere la riga "Produttore/consumatore" con il solo principio, agnostico dallo stack; rimando condizionale al manifest verso l'istruzione di dr-dotnet-backend
- **Tool ammessi**: nessuno
- **Verifica passo**: riga presente, nessun riferimento .NET non condizionale
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 21: <cosa>` in plan.md, non procedere

### Fase 22: commit dell'ondata 4
- **Stato**: [ ]
- **Precondizione**: Fasi 16-21 completate e rilette
- **File**: —
- **Operazione**: commit (nessun push)
- **Azione**: dr-dotnet-backend: `Refs davraf-amuro/dr-dotnet-backend#1`, poi `Refs davraf-amuro/dr-dotnet-backend#2`; dr-guidelines: `Refs davraf-amuro/dr-dotnet-backend#2`
- **Tool ammessi**: git
- **Verifica passo**: `git status` pulito nei repo toccati
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 22: <cosa>` in plan.md, non procedere

### Chiusura

### Fase 23: verifica finale in contesto isolato
- **Stato**: [ ]
- **Precondizione**: Fasi 1-22 completate
- **File**: tutti quelli in Scope
- **Operazione**: verifica
- **Azione**: verifica finale secondo `plan-tracking.instructions.md`, Fase 4, punto 4, in un contesto isolato dalla conversazione che ha scritto le modifiche (su Claude Code: `/dr-verify-plan`)
- **Tool ammessi**: `/dr-verify-plan`
- **Verifica passo**: ogni criterio di verifica finale soddisfatto, nessuna nota `⚠️ Divergenza` aperta
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 23: <cosa>` in plan.md, non procedere

### Fase 24: rilascio (solo con tuo via libera esplicito)
- **Stato**: [ ]
- **Precondizione**: Fase 23 superata; via libera esplicito dell'utente
- **File**: —
- **Operazione**: push + PR
- **Azione**: per ogni repo toccato, gate di push: repository di soli documenti → assenza di target dichiarata; per `dr-guidelines` gli script PowerShell sono verificati dai test manuali delle Fasi 6 e 9. Poi `/dr-promote-to main` con `Closes <owner/repo>#<n>` nel corpo della PR
- **Tool ammessi**: `/dr-promote-to`
- **Verifica passo**: una PR per repo, ognuna collegata alle sue issue
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 24: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [ ] `grep -rn "test-guideline"` sui repo della suite → nessun risultato
- [ ] `grep -n "builder.Host" dr-winsvc/.github/instructions/windows-service.instructions.md` → nessun risultato
- [ ] In una cartella vuota `-Package dr-fe` installa `dr-guidelines` + `dr-fe` (D2=b) o le dipendenze del catalogo includono il core (D2=c)
- [ ] `sourceFiles`: copia, salto e `.new` in `-Update` verificati; destinazioni con `..` o assolute rifiutate
- [ ] `dr-devops` dichiara nel README e nel catalogo che il compose a host singolo non è coperto
- [ ] In `minimal-api-architecture.instructions.md` ogni rimando a dr-efdb, dr-fe e dr-devops è condizionale al manifest
- [ ] La regola su `DataProtectionKeys` prima delle repliche è presente
- [ ] La tabella "Tipo di progetto" copre class library, EF Core e job in-process; `dr-audit-api` è allineata
- [ ] `producer-consumer-queue.instructions.md` soddisfa tutti i criteri di accettazione di dr-dotnet-backend#2 nel perimetro di D5
- [ ] Ogni istruzione toccata è leggibile da Claude Code e da GitHub Copilot (nessuna feature esclusiva), con footer di versione aggiornato
- [ ] Un commit per issue con `Refs`; nessun push senza via libera
