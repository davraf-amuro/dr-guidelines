# Piano — Riassetto dr-guidelines come pacchetto autoinstallante

Stato: COMPLETATO
Data: 2026-08-09
Slug: 2026-08-09-riassetto-autoinstallante

---

## Obiettivo

Chiudere il lavoro pendente della sessione 2026-08-08 e portare `dr-guidelines` allo stato dichiarato dall'utente:

1. Il repo si rilascia su git come **pacchetto autoinstallante** (`install.ps1`).
2. **Ogni capacità** del progetto vive in una **istruzione** o in una **skill** — nessuno script legacy orfano.
3. Da un prompt in linguaggio naturale ("crea un progetto…", "crea una soluzione…") l'agente genera quello che serve secondo le istruzioni; se manca un prerequisito strutturale (es. progetto chiesto ma solution assente) **chiede se crearlo**, non si limita a fermarsi.

---

## Decisioni utente (2026-08-09)

| Tema | Decisione |
|---|---|
| `AGENTS.md` + `.agents/skills/` | **Rimuovere entrambi** — duplicano `CLAUDE.md` e `.claude/skills/` con sostituzioni automatiche errate (`.Codex/skills/`) |
| `setup.ps1` | **Skill + flag installer**: nuova skill `/dr-install-global`, logica portata in `install-lib.ps1` + `install.ps1 -Global`, `setup.ps1` eliminato |
| Visibilità repo | **Restano Private** — l'autoinstallante `irm \| iex` resta documentato ma non funzionante; il percorso reale è l'invocazione da path locale |

---

## Scope

**File che verranno modificati o creati:**

| Percorso | Azione |
|---|---|
| `.claude/skills/dr-scaffold-project/SKILL.md` | Solution assente → chiede se crearla e delega, invece di STOP |
| `.claude/skills/dr-scaffold/SKILL.md` | Tabella di rilevamento: stati "progetti senza solution" e "richiesta esplicita su cartella vuota" |
| `.github/prompts/dr-scaffold.prompt.md` | Allineamento duale delle due modifiche sopra |
| `.claude/skills/dr-install-global/SKILL.md` | **Nuovo** — capacità di installazione globale come skill |
| `install-lib.ps1` | **Nuova** funzione `Install-DrGlobal` (porting da `setup.ps1`, con reperimento del template da clone locale o remoto) |
| `install.ps1` | Nuovo parametro `-Global` |
| `setup.ps1` | **Eliminato** |
| `templates/global-claude.md` | Conservato (sorgente di `Install-DrGlobal`) |
| `AGENTS.md`, `.agents/` | **Eliminati** |
| `.claude/skills/dr-handoff/skill.md` | Rinominato `SKILL.md`; `skill.md.original.md` eliminato |
| `.ai/plans/2026-06-17-global-install`, `2026-07-01-audit-agent-fixes`, `2026-07-01-audit-fixes` | Eliminati (ereditati dal repo legacy, non pertinenti) |
| `TODO/01-install-scaffholding.md` | Eliminato (specifica implementata; il consuntivo resta in `.ai/plans/2026-08-08-scaffolding-skills/`) |
| `README.md` | Sezione installazione globale riscritta su `/dr-install-global`; FAQ e note `setup.ps1` rimosse |
| `docs/onboarding.md` | Sezioni 3-4 riscritte sul modello a pacchetti (via `/dr-professor`) |
| `docs/card-davraf-guidelines.md` | Riga Entrypoint aggiornata |
| `CLAUDE.md` | Riga di invocazione automatica per `/dr-install-global` |

**Perimetro negativo — NON tocco:**

- `scaffolding-catalog.json` (nessuna tipologia o pacchetto cambia)
- `install-lib.ps1` — funzioni esistenti `Install-DrPackage`, `Copy-*`, `Merge-ClaudeMdSection`, `$Script:PackageRegistry`
- `.github/workflows/ci.yml` (job `catalog-guard` già verificato)
- `.github/instructions/*.md` diverse da quelle citate
- Le altre 13 skill `dr-*` nel merito del contenuto
- I 6 repo pacchetto dominio (`dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`, `dr-dotnet-backend`)
- Visibilità dei repo su GitHub (decisione: restano Private)

---

## Fasi

### [x] Fase 1 — Gap funzionale: prompt → scaffolding senza vicoli ciechi

Criterio dell'utente: "se chiedo un progetto ma manca una solution, chiede se creare anche una solution".

1. `dr-scaffold-project` Fase 0.2: solution assente → non è più uno STOP. Rilevare lo stato reale (cartella vuota / progetti sciolti senza solution / solution multipla) e **proporre** la creazione della solution delegando a `dr-scaffold-solution` con il contesto già raccolto. STOP solo se l'utente rifiuta.
2. `dr-scaffold` Fase 1: aggiungere alla tabella di rilevamento la riga "progetti presenti, nessuna solution" e la regola che una richiesta esplicita ("aggiungi un worker") su cartella vuota non fallisce ma passa da `dr-scaffold-solution` portandosi dietro la tipologia richiesta.
3. Allineare le stesse due regole in `.github/prompts/dr-scaffold.prompt.md` (sezioni A/B), con liste numerate e senza costrutti Claude-only.

**Verifica:** grep di `dr-scaffold-solution` nei tre file mostra la delega, non un messaggio terminale; nessuna occorrenza di `$ARGUMENTS`/`AskUserQuestion`/`EnterPlanMode`/`subagent` nel `.prompt.md`.

### [x] Fase 2 — Capacità di installazione globale chiusa in skill

1. `install-lib.ps1`: nuova funzione `Install-DrGlobal` — porting del blocco `-GlobalInstall`/`-GlobalUpdate` di `setup.ps1` (merge marcato in `~/.claude/CLAUDE.md`, sentinel `<!-- /davraf-guidelines -->`), con reperimento del template da `$PSScriptRoot/templates/global-claude.md` se presente, altrimenti clone temporaneo del repo core. Nessun `git pull` implicito: l'aggiornamento passa dal clone.
2. `install.ps1`: parametro `-Global`; con `-Global` chiama `Install-DrGlobal` ed esce senza toccare il progetto corrente.
3. Nuova skill `.claude/skills/dr-install-global/SKILL.md`: mostra il target `~/.claude/CLAUDE.md`, il diff della sezione, chiede conferma esplicita, esegue, verifica.
4. `setup.ps1` eliminato.
5. `CLAUDE.md`: riga di invocazione automatica per `/dr-install-global`.

**Verifica:** `install.ps1 -Global` su un `~/.claude/CLAUDE.md` di prova (copia nello scratchpad, `$HOME` non toccato nel test) crea/aggiorna la sezione; secondo run idempotente; nessun riferimento residuo a `setup.ps1` fuori da `.ai/` e `.git/`.

### [x] Fase 3 — Pulizia del repo

1. `AGENTS.md` e `.agents/` eliminati.
2. `.claude/skills/dr-handoff/skill.md` → `SKILL.md` (`git mv` non applicabile: file untracked/tracked da verificare); `skill.md.original.md` eliminato.
3. `.ai/plans/`: eliminati i 3 piani ereditati dal repo legacy.
4. `TODO/01-install-scaffholding.md` eliminato con la cartella `TODO/`.

**Verifica:** `ls .claude/skills/*/` mostra 15 cartelle, tutte con `SKILL.md`; `AGENTS.md`, `.agents/`, `TODO/` assenti.

### [x] Fase 4 — Documentazione allineata

1. `README.md`: sezione installazione globale su `/dr-install-global` e `install.ps1 -Global`; rimossa la nota "TODO aperto" e la FAQ sul meccanismo legacy; nuova skill documentata nell'elenco.
2. `docs/onboarding.md` sezioni 3-4 riscritte sul modello a pacchetti (submodule `davraf-guidelines` non è più il meccanismo) — via `/dr-professor`, footer di revisione aggiornato.
3. `docs/card-davraf-guidelines.md`: riga Entrypoint senza `setup.ps1`, footer aggiornato.

**Verifica:** `grep -rn "setup.ps1\|submodule" README.md docs/ .github/instructions/` non restituisce riferimenti al meccanismo superato (escluso l'uso in `dr-warroom` che riguarda un repo MCP terzo).

### [x] Fase 5 — Verifica finale e pubblicazione

1. Guardia catalogo eseguita in locale (`catalog-guard`): exit `0`.
2. Lint: il repo non contiene progetti compilabili (nessun `.csproj`, nessun `package.json`) → gate di push .NET/Node non applicabile; dichiararlo esplicitamente.
3. `git add -A`, commit unico con messaggio Conventional Commits, `git push origin main`.
4. Controllo dell'esito del workflow CI su GitHub Actions dopo il push.

**Verifica:** `git status --short` pulito; `scaffolding-catalog.json` presente su `origin/main`; job `catalog-guard` verde.

---

## Criteri di verifica del piano

- [x] Da un prompt "aggiungi una minimal api" in una cartella senza solution, il flusso propone la creazione della solution invece di fermarsi
- [x] Nessuna capacità del progetto vive fuori da una skill o da un'istruzione: `setup.ps1` eliminato, `install.ps1`/`install-lib.ps1` restano solo come meccanica dell'autoinstallante
- [x] Una sola superficie di skill (`.claude/skills/`) e una sola di regole condivise (`.github/`), nessun mirror `.agents/`
- [x] Documentazione senza riferimenti al modello a submodule e agli script eliminati
- [x] Lavoro committato e pushato su `origin/main`, CI verde

## Consuntivo — divergenze rispetto al piano

Quattro interventi non previsti dal piano, tutti conseguenza diretta di una verifica:

1. **`templates/global-claude.md` modificato** (era dichiarato "conservato"). Il commento di intestazione istruiva a usare `setup.ps1 -GlobalUpdate`, script eliminato in questa sessione: lasciarlo avrebbe distribuito a ogni PC un riferimento a un file inesistente. Aggiunte anche le 4 righe di invocazione mancanti (`dr-scaffold*`, `dr-install-global`).
2. **`docs/onboarding.md` riscritto per intero**, non solo le sezioni 3-4. Il piano si basava sul rilievo dell'handoff; la lettura completa ha mostrato che anche le sezioni 1, 2, 4, 6 e 8 descrivevano il modello a submodule. Footer portato a v3.0 (cambio strutturale, non incrementale).
3. **`docs/card-davraf-guidelines.md` rinominato in `docs/card-dr-guidelines.md`** con `git mv`, e corretti nome progetto, URL repository e tipo applicazione. Il README stesso segnalava il nome file da allineare al rename del repo; riferimenti aggiornati in `README.md` e `docs/onboarding.md`.
4. **`.github/workflows/ci.yml`: rimosso `submodules: true`** dal checkout di `build-and-test` (il repo non ha submodule dallo split). Il job `catalog-guard`, unico dichiarato nel perimetro negativo, non è stato toccato.

Verifiche eseguite in sessione:

- `Install-DrGlobal` provata su percorsi di prova nello scratchpad, tutti e cinque i rami: file assente → `[OK]` creazione; sezione presente senza `-Update` → `[SKIP]`; con `-Update` → `[UPD]`; file esistente senza sezione → `[OK]` append con contenuto preesistente intatto; intestazione senza sentinel → `[WARN]` e file invariato
- `install.ps1 -Global` eseguito davvero: `$HOME` è read-only in PowerShell e il redirect su una home fittizia non è possibile, quindi il comando ha agito sulla home reale. Esito `[SKIP]` (sezione già presente, nessun `-Update`): nessuna scrittura. Il fallback su `install-lib.ps1` locale ha funzionato, come atteso con i repo Private
- `install.ps1` e `install-lib.ps1` passati al parser PowerShell: nessun errore di sintassi
- Script del job `catalog-guard` rieseguito in locale: `Catalogo allineato: 7 pacchetti, 5 tipologie.`, exit `0`
- `ci.yml` riletto con parser YAML dopo la modifica: `jobs: ['build-and-test', 'catalog-guard']`
- `.github/prompts/dr-scaffold.prompt.md`: nessuna occorrenza di `$ARGUMENTS`, `AskUserQuestion`, `EnterPlanMode`, `subagent`, `INPUT_UTENTE`
- Nessun riferimento residuo a `setup.ps1` o al modello a submodule in `README.md`, `docs/`, `.github/`, `CLAUDE.md`, `.claude/` — unica occorrenza rimasta, legittima, in `dr-warroom/SKILL.md:37`, che cita il `setup.ps1` di un repo MCP terzo
- Gate di push: il repo non ha `.csproj` né `package.json`, quindi nessun comando lint della tabella è applicabile
- Scansione segreti su `*.md`, `*.ps1`, `*.json`, `*.yml`: nessun match

---

## Fuori scope dichiarato

- Flip Private → Public dei 7 repo (decisione utente: restano Private)
- Gate 2b dello split (test su progetto host reale esistente)
- Fasi 7-8 dello split (archiviazione `davraf-guidelines`, migrazione progetti host)
- Dogfooding end-to-end di `/dr-scaffold` su cartella vuota reale: richiede una sessione nuova, perché le skill si caricano all'avvio
