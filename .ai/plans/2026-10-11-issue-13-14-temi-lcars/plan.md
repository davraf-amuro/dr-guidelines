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
- **Stato**: [ ]
- **Azione**: l'utente sceglie; il piano si aggiorna con nomi definitivi
- **Verifica passo**: D1–D3 annotate qui con data

### Fase 1: Contratto dei token in dr-fe
- **Stato**: [ ]
- **Azione**: `design-tokens.instructions.md` (`applyTo` su `**/*.css` e `**/*.vue`): elenco token semantici e coppie `on-*`, regole d'uso, soglie di contrasto, focus e area di tocco; nessun valore. Rimando da `frontend-organization.instructions.md`; README di dr-fe
- **Verifica passo**: nomi identici a `tokens.css` di `dr-mailroom-fe` `main`; frontmatter compatibile Claude Code + Copilot; nessun riferimento a temi specifici

### Fase 2: Repo del pacchetto
- **Stato**: [ ]
- **Azione**: creazione repo (conferma esplicita prima di `gh repo create`), scheletro copiato dal pacchetto più recente (installer che scarica la lib comune, README, LICENSE, issue template)
- **Verifica passo**: installer eseguito su cartella vuota di prova: copia instructions, prompt e script, scrive il manifest

### Fase 3: Istruzione del tema
- **Stato**: [ ]
- **Azione**: `lcars-theme.instructions.md`: ruoli `frame`/`trim`/`accent-1..4`, token di forma, tipografia Saira, guscio a gomito, voce attiva staccata, componenti condivisi, insidie note (`hidden md:flex` non nello style scoped), regole di contrasto
- **Verifica passo**: ogni regola delle issue (sezione "Struttura comune") ha una riga corrispondente; nessuna duplicazione del contratto di Fase 1 (solo rimando)

### Fase 4: Prompt di applicazione con i sorgenti di riferimento
- **Stato**: [ ]
- **Azione**: `dr-ux-lcars-apply.prompt.md`: chiede la palette, verifica che dr-fe sia nel manifest, individua la cartella `src/`, applica `tokens.css`, `main.css`, `App.vue`, `AppSidebar.vue`, `AppHeader.vue`, `BasePanel`, `BaseButton`, `BaseBadge`, `HazardStripe` (estratti da `dr-mailroom-fe` `main` e `fcc1502`, token rinominati per ruolo), `theme-color` in `index.html` e `site.webmanifest`. File esistente → diff + conferma, mai sovrascrittura silenziosa. Termina lanciando lo script contrasti e i comandi di verifica dell'host
- **Verifica passo**: le due palette differiscono solo nei valori; i componenti non contengono colori letterali né nomi di colore; tabelle palette identiche alle issue

### Fase 5: Script contrasti
- **Stato**: [ ]
- **Azione**: `scripts/lcars-contrast.mjs`: legge `tokens.css` dell'host (path come argomento, default `src/assets/styles/tokens.css`), calcola WCAG 2.x per tema chiaro e scuro (testo ≥ 4.5:1, bordi/focus ≥ 3:1, ogni coppia `on-*`, `--c-on-lcars` su ogni blocco), exit code non-zero se una coppia fallisce. Nessun `eval`, nessuna rete
- **Verifica passo**: sui valori delle issue riproduce i rapporti dichiarati (±0.01); con un colore peggiorato ad arte esce con errore

### Fase 6: Catalogo e documentazione dr-guidelines
- **Stato**: [ ]
- **Azione**: voce in `packages` (`appliesTo: ["node"]`, `dependencies` o `suggests` da D2, `rootFiles: ["scripts/lcars-contrast.mjs"]`); `dr-ux-lcars` in `optionalPackages` di `vue-fe`; `updatedAt`; README e `docs/` che elencano i pacchetti
- **Verifica passo**: JSON valido; `catalog-guard` di `.github/workflows/ci.yml` eseguito in locale passa

### Fase 7: Prova end-to-end e issue di seguito
- **Stato**: [ ]
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
