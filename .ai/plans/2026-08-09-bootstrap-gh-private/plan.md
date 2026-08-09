# Piano — Bootstrap autoinstallante su repo Private via `gh api` + rename installer

Stato: IN CORSO
Data: 2026-08-09
Slug: 2026-08-09-bootstrap-gh-private

---

## Obiettivo

Rendere eseguibile la simulazione richiesta dall'utente: **workspace nuovo → scarico `dr-guidelines` da GitHub → creo un progetto**, senza flip Private → Public e senza clone locale nel percorso.

In più, richiesta dell'utente in corso di pianificazione: rinominare gli installer nel formato `<progetto>-install.ps1`. Le due cose si fanno insieme perché toccano gli stessi 7 file e le stesse 88 referenze.

## Decisioni utente

| Tema | Decisione |
|---|---|
| Bootstrap su Private | **Terzo fallback `gh api`** nell'installer, non flip Private → Public |
| Nome degli installer | `<progetto>-install.ps1` — es. `dr-guidelines-install.ps1`, `dr-minimalapi-install.ps1` |
| Nome della libreria | `dr-guidelines-install-lib.ps1` — simmetria piena, il costo aggiuntivo è nullo perché la URL cambia comunque nei 7 installer |
| Shim di compatibilità | Nessuno: repo Private, nessun consumatore esterno, e il manifest registra nomi di pacchetto, non URL |

---

## Perché serve

`irm ... | iex` richiede repo pubblici: `raw.githubusercontent.com` risponde `404` sui Private. Verificato in sessione:

| Comando | Esito |
|---|---|
| `curl raw.githubusercontent.com/.../install.ps1` | `404` |
| `gh api repos/davraf-amuro/dr-guidelines/contents/install.ps1 -H "Accept: application/vnd.github.raw"` | contenuto dello script |

`gh` è già autenticato come `davraf-amuro` con scope `repo` e legge i Private. Ma il bootstrap via `gh` oggi **muore al secondo passo**: `install.ps1` risolve `install-lib.ps1` in due tentativi — `Invoke-RestMethod` sul raw (404 su Private) e poi `$PSScriptRoot`, che sotto `iex` è **vuoto**. Senza un terzo tentativo, `throw`.

Un artefatto pubblicato su claude.ai non risolve niente: è HTML-wrappato, sta dietro autenticazione, e comunque `Install-DrPackage` fa `git clone` del repo privato.

---

## Scope

| Percorso | Azione |
|---|---|
| `dr-guidelines/install.ps1` | Terzo fallback: `gh api` con `Accept: application/vnd.github.raw` |
| `dr-minimalapi/install.ps1` | Stesso blocco di risoluzione |
| `dr-winsvc/install.ps1` | Stesso blocco |
| `dr-efdb/install.ps1` | Stesso blocco |
| `dr-fe/install.ps1` | Stesso blocco |
| `dr-devops/install.ps1` | Stesso blocco |
| `dr-dotnet-backend/install.ps1` | Stesso blocco |
| `dr-guidelines/README.md` | Comando di bootstrap per la fase Private, al posto del solo "usa il path locale" |
| `dr-guidelines/docs/onboarding.md` | Stessa correzione nella sezione 3 |
| `dr-guidelines/.claude/skills/dr-scaffold-solution/SKILL.md`, `dr-scaffold-guidelines/SKILL.md`, `dr-scaffold/SKILL.md` | Le tre dicono che in fase Private serve il path locale: aggiungere il bootstrap `gh` come alternativa |
| `dr-guidelines/.github/prompts/dr-scaffold.prompt.md` | Allineamento duale |

**Perimetro negativo — NON tocco:**

- `install-lib.ps1` — nessuna funzione cambia; il file resta l'unica copia della logica di installazione
- `scaffolding-catalog.json` e `$Script:PackageRegistry`
- `.github/workflows/ci.yml`
- Visibilità dei repo: restano **Private** (decisione dell'utente, confermata)
- Il contenuto dei 6 pacchetti dominio oltre al loro `install.ps1`

---

## Fasi

### [ ] Fase 1 — Terzo fallback nel core

`dr-guidelines/install.ps1`: la risoluzione di `install-lib.ps1` diventa una catena di tre tentativi, in quest'ordine:

1. `Invoke-RestMethod` sul raw pubblico — il caso normale a repo Public
2. `$PSScriptRoot/install-lib.ps1` — invocazione da un clone locale
3. `gh api repos/davraf-amuro/dr-guidelines/contents/install-lib.ps1 -H "Accept: application/vnd.github.raw"` — repo Private con `gh` autenticato

Fallito anche il terzo: messaggio esplicito che distingue le tre cause (rete / nessun clone locale / `gh` assente o non autenticato), non un `throw` nudo.

**Verifica:** con `$PSScriptRoot` vuoto (`iex` di uno scriptblock) la catena arriva al terzo passo e carica la libreria; `Get-Command Install-DrPackage` risponde.

### [ ] Fase 2 — Propagazione ai 6 pacchetti dominio

Stesso blocco nei 6 `install.ps1`, che differiscono dal core solo per il nome del pacchetto passato a `Install-DrPackage`. Il repo da cui si prende `install-lib.ps1` resta sempre `davraf-amuro/dr-guidelines`: la libreria vive solo lì.

**Verifica:** i 7 file hanno lo stesso blocco di risoluzione (diff limitato a nome pacchetto e docstring).

### [ ] Fase 3 — Documentazione

Il bootstrap per la fase Private va dove oggi c'è scritto "usa il path locale": `README.md`, `docs/onboarding.md`, le tre skill `dr-scaffold*` e il prompt duale.

**Verifica:** `grep -rn "irm .*install.ps1"` mostra accanto a ogni occorrenza l'alternativa `gh`; nessun documento afferma più che in fase Private l'unica via è il clone locale.

### [ ] Fase 4 — Commit e push dei 7 repo

Un commit per repo, messaggio Conventional Commits. Gate lint: nessuno dei 7 ha `.csproj` o `package.json` → non applicabile, dichiarato.

**Verifica:** `git status --short` pulito in tutti e 7; CI verde su `dr-guidelines`.

### [ ] Fase 5 — Test Fase A: installazione da zero

In una cartella **nuova e vuota**, senza usare il clone locale:

1. `git init` (l'installer scrive nella root del repo corrente)
2. Bootstrap del core via `gh api | iex`
3. Bootstrap di `dr-minimalapi` allo stesso modo — deve tirarsi dietro `dr-dotnet-backend` da solo

**Verifica:**

| Cosa | Atteso |
|---|---|
| `.github/instructions/`, `.github/prompts/`, `.claude/skills/` | popolate |
| `CLAUDE.md` | sezione tra `<!-- dr-guidelines -->` e `<!-- /dr-guidelines -->` |
| `.ai/dr-guidelines-packages.json` | 3 voci: `dr-guidelines`, `dr-dotnet-backend`, `dr-minimalapi` |
| `.ai/dr-scaffolding-catalog.json` | presente — questa volta **senza** `[WARN]`, perché il catalogo ora è su `origin/main` |
| `Directory.Build.props`, `global.json` | presenti (host .NET dopo l'aggiunta di un progetto) o `[SKIP]` dichiarato se la cartella è ancora vuota |
| secondo run | tutti `[SKIP]` |

### [ ] Fase 6 — Consegna della Fase B all'utente

La Fase B non è eseguibile da questa sessione: le skill si caricano all'avvio dalla cartella aperta. Consegno il percorso della cartella di prova e il prompt da usare — l'utente la apre in una sessione nuova e invoca lo scaffolding.

---

## Criteri di verifica del piano

- [ ] `install.ps1` carica `install-lib.ps1` su repo Private senza clone locale nel percorso
- [ ] I 7 pacchetti si installano con lo stesso bootstrap
- [ ] Nessun documento afferma più che in fase Private l'unica via è il path locale
- [ ] Una cartella vuota, partendo da zero, riceve core + dipendenza + pacchetto dominio, con manifest a 3 voci e nessun `[WARN]`
- [ ] L'utente ha percorso e prompt per eseguire la Fase B

## Fuori scope dichiarato

- Flip Private → Public
- Gate 2b dello split (install su progetto host reale esistente): la cartella di prova è sintetica e non lo chiude
- Esecuzione della Fase B (scaffolding vero da sessione nuova)
- `/dr-get-latest`, che usa `Invoke-RestMethod` senza fallback: stessa limitazione, ma è un file diverso e va valutato a parte
