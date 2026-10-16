# Aggiornamento pacchetti dr-* nei progetti host

Stato: COMPLETATO
Data: 2026-10-16

## Obiettivo

Portare all'ultimo `main` remoto i pacchetti dr-* nei 3 progetti host che li hanno installati, con un commit dedicato per progetto e rollback immediato.

## Inventario (rilevato 2026-10-16)

| Progetto | Pacchetto | Commit installato | Indietro di |
|----------|-----------|-------------------|-------------|
| `my-home` | dr-guidelines | — (manifest senza `commit`, 2026-08-12) | ? |
| `dr-mailroom-fe` | dr-guidelines | 916b257 | 36 |
| `dr-mailroom-fe` | dr-fe | 6f66968 | 10 |
| `dr-mailroom` | dr-guidelines | 916b257 | 36 |
| `dr-mailroom` | dr-dotnet-backend | 3c12474 | 10 |
| `dr-mailroom` | dr-minimalapi | e92bd3e | 12 |
| `dr-mailroom` | dr-efdb | fdc9030 | 9 |

Stato git: tutti i working tree puliti. `dr-mailroom` e `dr-mailroom-fe`: `main` ahead 1 (commit non pushato). `my-home`: nessun remote.
Repo pacchetto: tutti PUBLIC → `raw.githubusercontent.com` funziona; `gh` autenticato come fallback.

## Scope

- Modifica: file gestiti dagli installer nei 3 progetti host (`.github/instructions/`, `.github/prompts/`, `.claude/skills/`, sezioni marcate di `CLAUDE.md`, `.ai/dr-guidelines-packages.json`, `.ai/dr-scaffolding-catalog.json`, eventuali file sorgente → `<file>.new`).
- Non tocca: codice applicativo, contenuto di `CLAUDE.md` fuori dai marcatori, repo pacchetto, questo repo (salvo il piano).
- Non si fa push senza conferma esplicita.

## Ordine

Pilota sul progetto meno rischioso, poi i due con remote: `my-home` → `dr-mailroom-fe` → `dr-mailroom`.
In ogni progetto: `dr-guidelines` per primo (core), poi i domini rispettando le dipendenze (`dr-dotnet-backend` prima di `dr-minimalapi` ed `dr-efdb`).

## Fasi

### Fase 0 — Prerequisiti (per ogni progetto)
- [x] Working tree pulito (`git status --short` vuoto)
- [x] Decisione utente sul commit già ahead in `dr-mailroom` / `dr-mailroom-fe`: pusharlo prima (consigliato, così l'update resta isolato) oppure lasciarlo
- [x] Branch dedicato: `git switch -c chore/dr-update-2026-10-16`

### Fase 1 — my-home (pilota)
- [x] `dr-guidelines-install.ps1 -Update`
- [x] Verifica: skill obsolete rimosse (`dr-tattico`, `dr-segnala-miglioria`, `dr-CreateLaunchProfiles`, `readme-structure.instructions.md`); manifest con campo `commit` = HEAD di `dr-guidelines/main`
- [x] Commit locale (nessun push: niente remote)

### Fase 2 — dr-mailroom-fe
- [x] Update in ordine: `dr-guidelines`, `dr-fe`
- [x] Verifica (vedi sotto); `npm run lint` se definito
- [x] Commit sul branch

### Fase 3 — dr-mailroom
- [x] Update in ordine: `dr-guidelines`, `dr-dotnet-backend`, `dr-minimalapi`, `dr-efdb`
- [x] Verifica (vedi sotto); `dotnet build` + `dotnet format <sln|csproj> --verify-no-changes`
- [x] Commit sul branch

### Fase 4 — Integrazione
- [x] Per i progetti con remote: merge su `main` o PR (`/dr-promote-to main`) — solo dopo conferma
- [x] Gate push: lint/format pulito

Comando per ogni pacchetto, dalla root del progetto host:

```powershell
& ([scriptblock]::Create((Invoke-RestMethod -Uri "https://raw.githubusercontent.com/davraf-amuro/<pkg>/main/<pkg>-install.ps1"))) -Update
```

## Verifica per progetto

1. `.ai/dr-guidelines-packages.json`: ogni voce ha `commit` = HEAD remoto del pacchetto
2. `git diff --stat`: solo percorsi in scope
3. `git diff CLAUDE.md`: modifiche solo tra `<!-- dr-<pkg> -->` e `<!-- /dr-<pkg> -->`
4. Nessun `*.new` residuo; se presenti → confronto manuale con l'originale, decisione utente
5. Build/lint del dominio pulito (Fase 2/3)

## Rollback

Working tree pulito + branch dedicato → rollback banale:

```powershell
git switch main
git branch -D chore/dr-update-2026-10-16
```

Prima del commit basta `git restore . ; git clean -fd -- .github .claude .ai`. Fallimento di un singolo pacchetto: si annota, si continua con gli altri (comportamento di `dr-get-latest`), si decide a fine fase.

## Esito esecuzione (2026-10-16)

- Fase 0: gate puliti (`dotnet format` 0, `npm run lint:check` 0), pushati 3fc6d86 (dr-mailroom) e 55f6609 (dr-mailroom-fe)
- Fase 1: my-home 822304a (solo locale)
- Fase 2: dr-mailroom-fe a356a40 su `chore/dr-update-2026-10-16`, lint 0
- Fase 3: dr-mailroom 45553ee su `chore/dr-update-2026-10-16`, build 0 errori, format 0

### Bug installer trovato

Con `-Update` gli installer sovrascrivono per intero i file di configurazione radice del progetto host:
- `dr-guidelines`: `.gitignore`, `.editorconfig`, `.gitattributes` → in dr-mailroom-fe persi gli ignore di `public/config.json` (chiave API), `dist/`, `test-results/`; in dr-mailroom persi gli ignore di `/Gmail/`, `client_secret*.json`, `.env`, `/data/`
- `dr-dotnet-backend`: `Directory.Build.props` riportato ai segnaposto del template (`YourCompany`), `global.json`
- Mitigazione applicata: file ripristinati con `git restore`, aggiunte a mano solo le voci nuove del core
- Issue aperte: davraf-amuro/dr-guidelines#28, davraf-amuro/dr-dotnet-backend#5
- Fase 4: fast-forward su `main` e push — dr-mailroom 45553ee, dr-mailroom-fe a356a40; my-home 822304a solo locale

## Fuori piano (proposte)

- `dr-get-latest`: aggiungere controllo working tree pulito / commit non pushati e richiamo ai `*.new` → issue via `/dr-file-feedback` (qui interverrebbe `/dr-prompt-engineer`)
- Valutare modalità multi-progetto della skill: con 3 host il giro manuale è ancora sostenibile

## Criteri di completamento

- [x] 3 progetti con manifest allineato a HEAD remoto di ogni pacchetto
- [x] Nessun file fuori scope modificato
- [x] Build/lint puliti in dr-mailroom e dr-mailroom-fe
- [x] Commit dedicato in ogni progetto; push solo se confermato
