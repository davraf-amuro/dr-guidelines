# Piano: Campo di catalogo `suggests` per i rimandi non vincolanti fra pacchetti
Data: 2026-10-02
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#7

## Obiettivo
Rendere visibili al catalogo, e quindi a installer, skill e prompt, le relazioni "il pacchetto A cita una regola del pacchetto B ma non lo richiede", oggi espresse solo nel testo delle istruzioni con il rimando condizionale di `cross-package-references.instructions.md`.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/7 (nata dalla #5)
- Rimandi condizionali reali, verificati il 2026-10-02 col pattern canonico "Controlla `.ai/dr-guidelines-packages.json`: se elenca `<pacchetto>`":
  - `dr-fe` → `dr-minimalapi`: `frontend-organization.instructions.md` riga ~271 (schema di login deciso lato API)
  - `dr-efdb` → `dr-minimalapi`: `database-provider.instructions.md` riga ~203 (Service layer)
  - `dr-devops` → `dr-minimalapi`: `docker-swarm-compose.instructions.md` riga ~165 (lato codice di Data Protection e forwarded headers)
- `cross-package-references.instructions.md` (core) dice ancora che l'installer "risolve le dipendenze senza chiedere conferma" e "non legge `appliesTo`": obsoleto dopo la #6 (commit `97dfa69`), da correggere qui perché è la regola che introduce il nuovo campo.

**Esito della consultazione** (`/dr-warroom`, 2026-10-02). ARCH, BE, UI, UX convergenti; DBADMIN: nessun intervento database necessario.

- **Forma**: `suggests: [{ "package": "<nome>", "reason": "<una riga>" }]`. Nome con precedente in Composer e Debian. `reason` obbligatorio: senza, skill e installer non sanno spiegare cosa si perde e l'agente lo inventa. Il `reason` dice cosa manca senza il pacchetto, non lo ripete.
- **Guard bloccante** (`catalog-guard`): solo integrità del campo — pacchetto esistente, diverso da sé, non presente anche in `dependencies`, `reason` non vuoto e senza caratteri di controllo. **Nessun** controllo di compatibilità `appliesTo`: `dr-fe` (node) → `dr-minimalapi` (dotnet) è proprio il caso d'uso.
- **Confronto testo↔catalogo**: workflow separato, **non bloccante**, eseguito a mano (`workflow_dispatch`) e una volta a settimana. Clona i repo dei pacchetti, cerca il pattern canonico e segnala come warning le divergenze nei due versi. Tenerlo fuori dal guard evita che una modifica in un altro repo, o la rete, rompa PR che non c'entrano. Il pattern regex è fragile per natura: per questo segnala e non blocca.
- **Installer**: a fine installazione stampa `[sugg] <pacchetto> non installato: <reason>` per ogni voce di `suggests` assente dal manifest. Mai installa, mai chiede.
- **Skill / prompt**: nella conferma unica, pacchetto suggerito con `appliesTo` compatibile con lo stack rilevato → voce proposta, **non preselezionata**, col suo `reason`; incompatibile → una riga informativa, senza domanda.
- **`schemaVersion`**: resta 2. Il campo è opzionale e additivo; `ConvertFrom-Json` ignora i campi sconosciuti.

## Scope

- `scaffolding-catalog.json` — `suggests` su `dr-fe`, `dr-efdb`, `dr-devops`; `updatedAt`
- `dr-guidelines-install-lib.ps1` — registry con `Suggests`; stampa `[sugg]` a fine `Install-DrPackage`
- `.github/workflows/ci.yml` — `catalog-guard`: integrità di `suggests`
- `.github/workflows/suggests-text-check.yml` (nuovo) — confronto testo↔catalogo non bloccante
- `.github/instructions/cross-package-references.instructions.md` — nuovo obbligo: un rimando condizionale si dichiara anche in `suggests`; correzione delle frasi obsolete sull'installer; versione e footer
- `.claude/skills/dr-scaffold-guidelines/SKILL.md` — Fase 2: presentazione dei suggeriti
- `.claude/skills/dr-scaffold-solution/SKILL.md` — Gate B: stessa presentazione
- `.github/prompts/dr-scaffold.prompt.md` — stesso comportamento lato Copilot, se il prompt presenta la scelta dei pacchetti
- Documentazione del catalogo: `README.md` (descrizione dei campi di `packages`), `docs/onboarding.md` se elenca i campi

## Perimetro negativo

- Nessuna modifica ai repo dei pacchetti dominio (`dr-fe`, `dr-efdb`, `dr-devops`…): i loro rimandi sono già nella forma canonica
- Nessun bump di `schemaVersion`
- Nessuna installazione automatica dei suggeriti, nessun prompt nell'installer
- Il workflow testuale non apre issue e non fallisce: solo warning e riepilogo del job
- Issue #8 (`dr-devops` in `optionalPackages`/`intentMap`) fuori perimetro

## Fasi

### Fase 1: Catalogo e guard
- **Stato**: [x]
- **File**: `scaffolding-catalog.json`, `.github/workflows/ci.yml`
- **Azione**: tre voci `suggests` con `reason` concreti in italiano; controlli di integrità nel guard
- **Verifica passo**: JSON valido; script del guard eseguito in locale passa; fallisce con suggerimento verso pacchetto inesistente, verso sé stesso, duplicato in `dependencies`, `reason` vuoto (iniezioni in memoria)
- **Esito**: catalogo valido, `schemaVersion` 2, `updatedAt` 2026-10-02, tre `suggests` verso `dr-minimalapi`. Guard: passa sul catalogo (7 pacchetti, 5 tipologie), exit 1 con ciascuna delle quattro iniezioni; controlla anche `package` mancante, duplicati in `suggests` e caratteri di controllo nel `reason`.

### Fase 2: Installer
- **Stato**: [x]
- **File**: `dr-guidelines-install-lib.ps1`
- **Azione**: `Suggests` nel registry; a fine `Install-DrPackage` (anche con `-NoDependencies`) riga `[sugg]` per ogni suggerito assente dal manifest
- **Verifica passo**: parser 0 errori; prova in cartella temporanea con libreria e catalogo locali: `Install-DrPackage dr-fe` stampa `[sugg] dr-minimalapi …` e il manifest non contiene `dr-minimalapi`
- **Esito**: parser 0 errori. Prova in `$env:TEMP` (libreria e catalogo locali, `dr-fe` clonato da GitHub): stampa `[sugg] dr-minimalapi non installato: senza, lo schema di login…`, manifest con il solo `dr-fe`, cartella rimossa. Il controllo legge il manifest dopo l'installazione e considera solo i `suggests` del pacchetto richiesto, non quelli delle dipendenze.

### Fase 3: Workflow testo↔catalogo
- **Stato**: [x]
- **File**: `.github/workflows/suggests-text-check.yml`
- **Azione**: `workflow_dispatch` + `schedule` settimanale; clona shallow i repo dei pacchetti non core; cerca in `.github/instructions/*.md` il pattern "se elenca `<nome>`"; warning (`::warning::`) per rimando senza `suggests` e per `suggests` senza rimando; exit 0
- **Verifica passo**: YAML valido; lo script del job eseguito in locale contro i clone del workspace (`../dr-*`) riporta zero divergenze sul catalogo aggiornato e una divergenza se si toglie una voce `suggests` in memoria
- **Esito**: YAML valido (`yaml.safe_load`), `permissions: contents: read`, cron lunedì 06:00 UTC. Due step pwsh: clone shallow dei pacchetti non core (owner in allowlist, clone fallito → warning) e confronto; il secondo legge `CLONE_ROOT` (default `..`) ed è eseguibile in locale. Contro i clone del workspace: 6 pacchetti, 0 divergenze; con `suggests` di `dr-efdb` svuotato → 1 warning; con un `suggests` senza rimando (verso 2) → 1 warning. Exit sempre 0. Un rimando verso una `dependency` non è contato come divergenza.

### Fase 4: Regola, skill, prompt, documentazione
- **Stato**: [x]
- **File**: `cross-package-references.instructions.md`, le due skill, `dr-scaffold.prompt.md`, `README.md`, `docs/onboarding.md`
- **Azione**: come da Scope; il prompt Copilot usa solo costrutti neutri (niente `AskUserQuestion`, `$ARGUMENTS`)
- **Verifica passo**: grep di "non legge `appliesTo`" e "senza chiedere conferma" nella regola: nessuna occorrenza obsoleta; le tre superfici di scelta pacchetti descrivono lo stesso comportamento
- **Esito**: regola v1.1 con sezione "Ogni rimando condizionale si dichiara anche nel catalogo" e sezione dipendenze corretta (albero `[dep]`, `-NoDependencies`, guard su `appliesTo`); grep delle due frasi obsolete: 0 occorrenze. Suggeriti descritti allo stesso modo in `dr-scaffold-guidelines` (Fase 2, stato "suggerito"), `dr-scaffold-solution` (Gate B, punto 4) e `dr-scaffold.prompt.md` (A.2 e Sezione C punto 4, nessun costrutto esclusivo di Claude Code). `README.md`: campo `suggests` nella voce `packages`, riga `[sugg]`, footer v3.10. `docs/onboarding.md` non toccato: non elenca i campi di `packages`.

### Fase 5: Commit, push, chiusura issue
- **Stato**: [x]
- **Azione**: commit dei soli file di Scope; gate di push: nessun lint applicabile (verifica = parser e JSON); push su `main`; chiusura #7
- **Esito**: 2026-10-02 — JSON valido, parser 0 errori; nessun lint applicabile dichiarato; commit e push su `main`; #7 chiusa. `docs/onboarding.md` non toccato: non elenca i campi di `packages`

## Criteri di verifica finale
- [x] Catalogo valido con tre `suggests`, `schemaVersion` 2
- [x] Guard bloccante verifica l'integrità e passa sul catalogo
- [x] Installer stampa `[sugg]` senza installare né chiedere
- [x] Workflow testuale non bloccante, zero divergenze sul catalogo attuale
- [x] Regola `cross-package-references` aggiornata e senza frasi obsolete
- [x] Skill e prompt Copilot allineati, compatibilità duale rispettata nei file condivisi
- [x] Nessun file fuori Scope modificato
