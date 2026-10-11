# Piano: temi UX LCARS Enterprise-D ed Enterprise-E come pacchetto dr-*
Data: 2026-10-11
Stato: PROPOSTO
Issue: davraf-amuro/dr-guidelines#13, davraf-amuro/dr-guidelines#14
Branch: plan/issue-13-14-ux-lcars

## Obiettivo
Rendere installabili i temi LCARS Enterprise-D ed Enterprise-E in qualsiasi frontend Vue con dr-fe, con struttura scritta una volta, palette intercambiabili, contrasti WCAG verificabili e nessun file dell'host sovrascritto senza conferma.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/13 e https://github.com/davraf-amuro/dr-guidelines/issues/14 — stessa struttura, cambia solo la palette; domanda aperta sulla forma del pacchetto (1 per tema / cumulativo / per tematica).
- Verificato il 2026-10-11:
  - `dr-fe` **non spedisce codice**: solo `frontend-organization.instructions.md`, skill `dr-audit-fe`, installer. Il tema base "Hangar Federale" citato dalle issue vive solo in `dr-mailroom-fe`, non in dr-fe. Il contratto dei token semantici (`--c-bg`, `--c-ink`, `--c-federal`/`--c-on-federal`, …) **non è scritto in nessun pacchetto**.
  - Riferimento implementativo: `dr-mailroom-fe`, commit `fcc1502` (E) e `0c81f5d` (D, sopra E), entrambi su `main` (le issue dicono "solo locale": superato). Piani `.ai/plans/2026-10-09-lcars-enterprise-{d,e}/` COMPLETATI.
  - Installer (`dr-guidelines-install-lib.ps1`): `Copy-InstructionsAndPrompts` copia solo **file piatti** di `.github/instructions/` e `.github/prompts/` (niente sottocartelle); `rootFiles` copia alla stessa path relativa, salta se esiste, sovrascrive con `-Update`. Nessuna scelta di variante, nessuna cartella sorgente configurabile.
  - Analisi palette: D ed E hanno **gli stessi ruoli**. D = gomito arancio + 4 voci (pervinca, pesca, lilla, rosso); E = gomito tortora che riusa la voce tortora. I "5 colori vs 4" delle issue non esistono come ruoli.

**Esito della consultazione** (`/dr-warroom`, 2026-10-11 — ARCH, BE, UI, UX, DBADMIN):

1. **Un solo pacchetto**, struttura LCARS scritta una volta + due palette (`enterprise-d`, `enterprise-e`). Bocciata l'opzione 1 (struttura duplicata in due repo, divergenza certa). Bocciata la scelta di variante nell'installer (meccanismo inesistente).
2. **Contratto dei token semantici in dr-fe**, come istruzione: nomi, coppie `on-*`, regole (caution mai come testo, focus 3px, tocco 44px, soglie 4.5:1 e 3:1). Solo nomi e regole, nessun valore: i valori sono del tema.
3. **Nessuna modifica all'installer** in questo piano. I sorgenti (`tokens.css`, `main.css`, guscio e condivisi) si spediscono come blocchi di riferimento in un prompt `.github/prompts/*.prompt.md` (file piatto, compatibile Claude Code + Copilot, caricato solo su invocazione); l'agente li applica mostrando il diff e chiedendo conferma per ogni file esistente. Estensione dell'installer → issue separata.
4. **Token decorativi per ruolo**: `--c-lcars-frame` (gomito, segmento lungo, pannello hero), `--c-lcars-trim` (coda, pulsante tema, staffa pannelli), `--c-lcars-accent-1..4` (voci di navigazione, segmenti della testata), `--c-on-lcars`. Mappa: D frame=arancio, trim=lilla, accent=pervinca/pesca/lilla/rosso; E frame=tortora, trim=acciaio, accent=blu/tortora/acciaio/ruggine.
5. **Script contrasti nel pacchetto** (Node, zero dipendenze, legge solo `tokens.css` locale), spedito come `rootFiles`; l'host lo rilancia dopo ogni modifica di colore. Lint, test, build e screenshot restano verifiche dell'host.
6. DBADMIN: nessun intervento database.

## Decisioni da prendere prima di eseguire (Fase 0)

- **D1 — Nome del pacchetto.** Consigliato `dr-ux-lcars` (LCARS è la struttura; Enterprise-D/E sono palette; un futuro tema LCARS non-Enterprise ci sta dentro). Alternativa delle issue: `dr-ux-enterprise`.
- **D2 — Legame con dr-fe.** Consigliato `dependencies: ["dr-fe"]` (4 voci su 5: senza contratto dei token il tema non ha regole). Alternativa: `suggests`.
- **D3 — Nomi di marchio in repo pubblico.** "LCARS", "Enterprise", "Star Trek" sono marchi Paramount. Rischio basso per un uso personale, ma il repo `dr-guidelines` è pubblico: confermare i nomi o sceglierne di neutri (es. `dr-ux-console`, palette `warm`/`cool`).

## Scope

- Repo `dr-fe`: nuova istruzione `.github/instructions/design-tokens.instructions.md` (contratto token semantici); rimando da `frontend-organization.instructions.md`; README
- Nuovo repo `davraf-amuro/dr-ux-lcars` (nome da D1): `dr-ux-lcars-install.ps1`, `README.md`, `LICENSE`, `.github/ISSUE_TEMPLATE/` (come gli altri pacchetti), `.github/instructions/lcars-theme.instructions.md`, `.github/prompts/dr-ux-lcars-apply.prompt.md`, `scripts/lcars-contrast.mjs` (rootFiles)
- Repo `dr-guidelines`: `scaffolding-catalog.json` (voce pacchetto, `optionalPackages` di `vue-fe`, `updatedAt`), `README.md` e `docs/` dove elencano i pacchetti
- `dr-mailroom-fe`: solo branch di prova per la verifica end-to-end, nessun merge

## Perimetro negativo

- Nessuna modifica a `dr-guidelines-install-lib.ps1` né agli installer esistenti (estensione → issue separata, Fase 7)
- Nessun tema base "Hangar Federale" spedito da dr-fe
- Nessun altro tema oltre D ed E
- `main` di `dr-mailroom-fe` non si tocca
- `.ai/plans/` storici non si toccano

## Fasi

### Fase 0: Decisioni D1, D2, D3
- **Stato**: [x]
- **Azione**: l'utente sceglie; il piano si aggiorna con nomi definitivi
- **Verifica passo**: D1–D3 annotate qui con data
- **Esito** (utente, 2026-10-11): D1 → `dr-ux-lcars` (repo `davraf-amuro/dr-ux-lcars`); D2 → `dependencies: ["dr-fe"]`; D3 → nomi LCARS mantenuti, palette `enterprise-d` ed `enterprise-e`

### Fase 1: Contratto dei token in dr-fe
- **Stato**: [x]
- **Esito**: dr-fe branch `feat/design-tokens`, commit `d0d5b15`: nuova `design-tokens.instructions.md` v1.0 (`applyTo: "**/*.css,**/*.vue"`, 7 regole, nessun valore), rimando e cartella `assets/styles/` in `frontend-organization` v1.3, README v1.3. Confronto automatico: 19/19 nomi identici a `tokens.css` del tema base (`fcc1502^`, escluso `--panel-bevel` proprio del tema)
- **Azione**: `design-tokens.instructions.md` (`applyTo` su `**/*.css` e `**/*.vue`): elenco token semantici e coppie `on-*`, regole d'uso, soglie di contrasto, focus e area di tocco; nessun valore. Rimando da `frontend-organization.instructions.md`; README di dr-fe
- **Verifica passo**: nomi identici a `tokens.css` di `dr-mailroom-fe` `main`; frontmatter compatibile Claude Code + Copilot; nessun riferimento a temi specifici

### Fase 2: Repo del pacchetto
- **Stato**: [~] (locale fatto; creazione su GitHub e prova installer in attesa di conferma)
- **Esito parziale**: repo locale `../dr-ux-lcars` (`git init -b main`), commit `a9632e2`: installer ricavato da `dr-fe-install.ps1` (dipendenze installate dalla lib: `Resolve-DrDependencyTree`), README, LICENSE, issue template. Vincolo scoperto: l'installer legge il catalogo da `main` di dr-guidelines su GitHub e clona il pacchetto da GitHub, quindi la prova con l'installer reale richiede repo creato e push (Fase 7b)
- **Azione**: creazione repo (conferma esplicita prima di `gh repo create`), scheletro copiato dal pacchetto più recente (installer che scarica la lib comune, README, LICENSE, issue template)
- **Verifica passo**: installer eseguito su cartella vuota di prova: copia instructions, prompt e script, scrive il manifest

### Fase 3: Istruzione del tema
- **Stato**: [x]
- **Esito**: `lcars-theme.instructions.md` v1.0, 6 regole. Ruoli verificati sul codice: `frame` (gomito, segmento lungo, hero), `trim` (coda, pulsante tema, staffa, 2° segmento), `accent-1..4` (voci; 3° segmento = accent-1, 4° = accent-4). D ed E hanno gli stessi ruoli: nessun `accent-5`. Deviazione accettata: in E i segmenti 2-3 della testata passano da blu/acciaio ad acciaio/blu. Etichetta del gomito spostata in `--lcars-label` (CSS `content`), così i componenti sono identici tra palette
- **Azione**: `lcars-theme.instructions.md`: ruoli `frame`/`trim`/`accent-1..4`, token di forma, tipografia Saira, guscio a gomito, voce attiva staccata, componenti condivisi, insidie note (`hidden md:flex` non nello style scoped), regole di contrasto
- **Verifica passo**: ogni regola delle issue (sezione "Struttura comune") ha una riga corrispondente; nessuna duplicazione del contratto di Fase 1 (solo rimando)

### Fase 4: Prompt di applicazione con i sorgenti di riferimento
- **Stato**: [x]
- **Esito**: `dr-ux-lcars-apply.prompt.md` v1.0 (frontmatter `agent`/`description`/`tools` come i prompt del core). Sorgenti generalizzati: voci di navigazione, marchio, stato e icone restano dell'host; mobile con `grid-flow-col auto-cols-fr` invece di `grid-cols-4`; `--font-mono` di sistema (JetBrains Mono era una dipendenza dell'app di prova). Blocchi `tokens.css` estratti dal prompt e passati allo script: 48/48 conformi per entrambe le palette. Nessun nome di colore nei riferimenti dei componenti
- **Azione**: `dr-ux-lcars-apply.prompt.md`: chiede la palette, verifica che dr-fe sia nel manifest, individua la cartella `src/`, applica `tokens.css`, `main.css`, `App.vue`, `AppSidebar.vue`, `AppHeader.vue`, `BasePanel`, `BaseButton`, `BaseBadge`, `HazardStripe` (estratti da `dr-mailroom-fe` `main` e `fcc1502`, token rinominati per ruolo), `theme-color` in `index.html` e `site.webmanifest`. File esistente → diff + conferma, mai sovrascrittura silenziosa. Termina lanciando lo script contrasti e i comandi di verifica dell'host
- **Verifica passo**: le due palette differiscono solo nei valori; i componenti non contengono colori letterali né nomi di colore; tabelle palette identiche alle issue

### Fase 5: Script contrasti
- **Stato**: [x]
- **Esito**: `scripts/lcars-contrast.mjs` (Node, `node:fs` soltanto). Rapporti identici alle tabelle delle issue (es. D 4.74/5.20, 8.39, 5.66; E 4.57/5.19, 4.87). Negativi: accent-4 a `#555555` → exit 1 (2.70:1); blocco `prefers-color-scheme` divergente dal tema scuro → exit 2; file assente → exit 2. Aggiunta soglia 4.5:1 per `federal`/`alert`/`ok` usati come testo, riportata in dr-fe (commit `a9284b6`)
- **Azione**: `scripts/lcars-contrast.mjs`: legge `tokens.css` dell'host (path come argomento, default `src/assets/styles/tokens.css`), calcola WCAG 2.x per tema chiaro e scuro (testo ≥ 4.5:1, bordi/focus ≥ 3:1, ogni coppia `on-*`, `--c-on-lcars` su ogni blocco), exit code non-zero se una coppia fallisce. Nessun `eval`, nessuna rete
- **Verifica passo**: sui valori delle issue riproduce i rapporti dichiarati (±0.01); con un colore peggiorato ad arte esce con errore

### Fase 6: Catalogo e documentazione dr-guidelines
- **Stato**: [x]
- **Esito**: commit `8263bd4`: voce `dr-ux-lcars`, `vue-fe.optionalPackages`, `updatedAt` 2026-10-11; README (tabella, dipendenze, 8 repo Public), `readme-structure` v2.4, `card-dr-guidelines` v2.7, `guida-nuova-soluzione` v1.4. JSON valido; catalog-guard locale exit 0 ("8 pacchetti, 5 tipologie"). Skill `dr-scaffold*` non toccate: leggono il catalogo
- **Azione**: voce in `packages` (`appliesTo: ["node"]`, `dependencies: ["dr-fe"]`, `rootFiles: ["scripts/lcars-contrast.mjs"]`); `dr-ux-lcars` in `optionalPackages` di `vue-fe`; `updatedAt`; README e `docs/` che elencano i pacchetti
- **Verifica passo**: JSON valido; `catalog-guard` di `.github/workflows/ci.yml` eseguito in locale passa

### Fase 7: Prova end-to-end e issue di seguito
- **Stato**: [~] (7a fatta; 7b e issue di seguito dopo creazione repo e push)
- **Esito 7a** (applicazione, 2026-10-11): worktree usa-e-getta di `dr-mailroom-fe` da `main` (palette D con nomi di colore), file del pacchetto copiati a mano. Baseline verde. Prompt con `enterprise-e`: contrasti 48/48, lint, format, type-check, vitest 209/209, build verdi dopo 2 correzioni al pacchetto (commit `fix`: spread con fallback segnalato da oxlint nello script; riferimenti non formattati secondo Prettier → aggiunto il passo di formattazione). Cambio a `enterprise-d` (Fase 2 del prompt): toccati solo `tokens.css`, `index.html`, `site.webmanifest`; tutto verde. Screenshot Playwright 375/1280 chiaro/scuro su `/mailboxes`, `/filters`, `/stats`: 12/12 identici pixel per pixel a `main` (una differenza al primo giro, assente alla ripetizione: temporizzazione del banner di stato). Worktree e branch di prova rimossi; `main` di dr-mailroom-fe non toccato (aveva 3 file modificati non committati dell'utente, rimasti intatti)
- **Da fare 7b**: installer reale (`-Package dr-ux-lcars`) su cartella di prova dopo push di catalogo, dr-fe e repo; issue di seguito sull'estensione dell'installer
- **Azione**: su un branch di prova di `dr-mailroom-fe` riportato al tema base: installazione del pacchetto, prompt con palette E, poi D; script contrasti; lint, format, type-check, vitest, build; screenshot 375/1280 chiaro/scuro. Aprire issue separata per l'estensione dell'installer (cartella sorgente, varianti, protezione in `-Update`)
- **Verifica passo**: tutte le verifiche verdi; risultato visivo equivalente ai commit di riferimento

### Fase 8: Commit, push, chiusura issue
- **Stato**: [ ]
- **Azione**: commit dei soli file di Scope in ciascun repo; gate di push (nessun lint applicabile ai repo di sole linee guida: dichiararlo; nell'host i comandi di dr-fe); chiusura #13 e #14 con rimando alla decisione del tavolo (conferma esplicita prima di chiudere)

## Criteri di verifica finale
- [ ] Contratto dei token semantici scritto in dr-fe, senza valori
- [ ] Un solo pacchetto con struttura unica e due palette che differiscono solo nei valori
- [ ] Token decorativi per ruolo (`frame`, `trim`, `accent-1..4`), nessun nome di colore nei componenti
- [ ] Nessun file dell'host sovrascritto senza diff e conferma
- [ ] Script contrasti riproduce i rapporti delle issue e fallisce su un colore non conforme
- [ ] Catalogo valido, `catalog-guard` verde
- [ ] Prova end-to-end verde su entrambe le palette
- [ ] Installer non modificato; issue di seguito aperta
- [ ] Ogni file condiviso compatibile Claude Code + GitHub Copilot
