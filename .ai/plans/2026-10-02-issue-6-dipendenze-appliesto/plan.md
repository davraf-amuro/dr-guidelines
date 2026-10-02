# Piano: Dipendenze fra pacchetti — compatibilità `appliesTo` in CI, albero annunciato, `-NoDependencies`
Data: 2026-10-02
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#6

## Obiettivo
Impedire che una dipendenza fra pacchetti con `appliesTo` incompatibili arrivi nel catalogo, e rendere visibile all'utente l'intero albero di dipendenze **prima** che l'installer scriva qualcosa, senza prompt interattivi che bloccherebbero agenti ed esecuzioni `irm | iex`.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/6
- Oggi `Install-DrPackage` (`dr-guidelines-install-lib.ps1`) per ogni dipendenza mancante stampa `Dipendenza mancante: <dep> -> installazione automatica` e si richiama ricorsivamente, senza conferma e senza insieme dei visitati. `Get-DrPackageRegistry` non legge `appliesTo`.
- L'installer non conosce il `kind` dell'host: nessun rilevamento dello stack.
- Dipendenze attuali: `dr-minimalapi -> dr-dotnet-backend`, `dr-winsvc -> dr-dotnet-backend`, tutte `dotnet -> dotnet`.

**Esito della consultazione** (`/dr-warroom`, 2026-10-02). ARCH, BE, UI, UX convergenti; DBADMIN: nessun intervento database necessario.

- Via (3), guard CI: **adottata**. Una dipendenza incompatibile è un errore di chi scrive il catalogo, va fermata dove il catalogo si valida.
- Via (2), annuncio dell'albero: **adottata senza prompt**. Un `Read-Host` blocca agenti e `irm | iex`; la conferma unica esiste già a monte nelle skill (`/dr-scaffold-guidelines`).
- Via (1), filtro a runtime sul kind dell'host: **scartata**. Richiederebbe un rilevamento dello stack euristico e fragile (es. un `.csproj` in `tools/` fa sembrare dotnet un host Vue), per un rischio oggi solo potenziale.
- Rischio aggiunto da BE: un ciclo nel catalogo (A -> B -> A) manda la ricorsione in loop infinito. Guard e installer lo devono intercettare.

**Regola di compatibilità** (decisa): una dipendenza `D` del pacchetto `P` è compatibile se `D.appliesTo` contiene `any`, oppure contiene ogni kind di `P.appliesTo`. Ne segue che un pacchetto `any` può dipendere solo da pacchetti `any`.

**Semantica di `-NoDependencies`** (decisa): le dipendenze mancanti non vengono installate; l'installer le elenca come avviso e procede col solo pacchetto richiesto. Chi passa lo switch ha scelto.

## Scope

- `dr-guidelines-install-lib.ps1` — `Get-DrPackageRegistry` (legge `AppliesTo`), nuova funzione di risoluzione dell'albero (ordine topologico, visitati, errore su ciclo), `Install-DrPackage` (annuncio albero prima di scrivere, switch `-NoDependencies`, nessuna ricorsione cieca)
- `dr-guidelines-install.ps1` — parametro `-NoDependencies` inoltrato a `Install-DrPackage`, help aggiornato
- `.github/workflows/ci.yml` — job `catalog-guard`: regola di compatibilità e rilevamento cicli
- `.claude/skills/dr-scaffold-guidelines/SKILL.md` — Fase 2: la conferma mostra anche le dipendenze transitive che arriveranno
- Documentazione del comportamento: `README.md` (riga ~21), `docs/bozza-manuale-installazione.md` (sezione "Come si comportano le dipendenze fra pacchetti"), `docs/guida-nuova-soluzione.md` (riga ~185), `docs/onboarding.md` (tabella parametri) se cita i parametri, `docs/test-progetto-host.md` (riga chiave dell'output, aggiunto in esecuzione: citava il vecchio messaggio)

## Perimetro negativo

- Nessun rilevamento del kind dell'host nell'installer
- Nessun `Read-Host` né prompt interattivo
- Nessuna modifica a `scaffolding-catalog.json` (né `schemaVersion`): la regola vale sui dati esistenti
- Nessuna modifica ai wrapper `<pacchetto>-install.ps1` degli altri repo `dr-*`: chiamano `Install-DrPackage` senza lo switch e mantengono il comportamento predefinito (installa le dipendenze, ora annunciate)
- Nessun campo `suggests` (è la issue #7)

## Fasi

### Fase 1: Libreria installer
- **Stato**: [x]
- **File**: `dr-guidelines-install-lib.ps1`
- **Azione**: registry con `AppliesTo`; funzione `Resolve-DrDependencyTree` (o nome equivalente) che restituisce l'ordine di installazione delle dipendenze mancanti, con insieme dei visitati ed errore esplicito su ciclo; `Install-DrPackage` stampa un blocco unico con prefisso costante (es. `[dep]`) prima di clonare, poi installa le dipendenze in ordine senza riannunciarle; `-NoDependencies` → elenco `[skip]` e avviso. `-Update` continua a non propagarsi alle dipendenze
- **Verifica passo**: parser PowerShell senza errori; prova in cartella temporanea dot-sourcing la libreria locale con catalogo locale precaricato: `dr-minimalapi` annuncia `dr-dotnet-backend` prima di installare; con `-NoDependencies` la dipendenza non arriva e l'avviso compare; catalogo modificato in memoria con ciclo → errore, nessun loop
- **Esito**: parser 0 errori; prova in %TEMP%: `dr-minimalapi` annuncia `[dep]  dr-dotnet-backend` prima della clonazione e il manifest contiene entrambi; con `-NoDependencies` riga `[skip]` + avviso, manifest solo `dr-minimalapi`; ciclo in memoria → `Ciclo nelle dipendenze del catalogo: dr-minimalapi -> dr-dotnet-backend -> dr-minimalapi`, 0 file scritti. Funzioni nuove: `Resolve-DrDependencyTree`, `Install-DrPackageContent`

### Fase 2: Entry point
- **Stato**: [x]
- **File**: `dr-guidelines-install.ps1`
- **Azione**: parametro `[switch]$NoDependencies`, inoltrato solo nel ramo `-Package`; help `.PARAMETER` aggiornati
- **Verifica passo**: parser senza errori; help descrive annuncio e switch
- **Esito**: parser 0 errori; `Get-Help -Parameter NoDependencies` mostra il testo; `.PARAMETER Package` descrive annuncio `[dep]` e ciclo

### Fase 3: Guard CI
- **Stato**: [x]
- **File**: `.github/workflows/ci.yml`
- **Azione**: nel `catalog-guard`, per ogni dipendenza applica la regola di compatibilità; rileva cicli nel grafo delle dipendenze
- **Verifica passo**: lo script del job eseguito in locale sul catalogo attuale passa; con una dipendenza `dr-fe -> dr-minimalapi` iniettata in memoria fallisce citando la coppia; con un ciclo iniettato fallisce
- **Esito**: script del job eseguito in locale: catalogo attuale exit 0; `dr-fe -> dr-minimalapi` exit 1 (`dipendenza incompatibile: 'dr-fe' (node) -> 'dr-minimalapi' (dotnet)`); ciclo exit 1. Cicli rilevati riusando `Resolve-DrDependencyTree`

### Fase 4: Skill e documentazione
- **Stato**: [x]
- **File**: `.claude/skills/dr-scaffold-guidelines/SKILL.md`, `README.md`, `docs/bozza-manuale-installazione.md`, `docs/guida-nuova-soluzione.md`, `docs/onboarding.md`
- **Azione**: descrivere il nuovo comportamento (albero annunciato, `-NoDependencies`, compatibilità garantita dal guard); la skill mostra nella sua conferma unica le dipendenze che arriveranno
- **Verifica passo**: grep di "installazione automatica" e "non si possono rifiutare" non trova più descrizioni obsolete
- **Esito**: aggiornati skill, README, bozza manuale, guida nuova soluzione, onboarding; grep di "installazione automatica"/"non si possono rifiutare" nei file di Scope: nessuna occorrenza (resta solo un output d'esempio storico in `docs/test-progetto-host.md`, fuori Scope)

### Fase 5: Commit, push, chiusura issue
- **Stato**: [x]
- **Azione**: commit dei soli file di Scope; gate di push: nessun lint applicabile (solo documenti e script PowerShell, verifica = parser); push su `main`; chiusura #6 con commento che rimanda al piano
- **Esito**: 2026-10-02 — parser 0 errori su entrambi gli script; nessun lint applicabile dichiarato; commit e push su `main`; #6 chiusa

## Criteri di verifica finale
- [x] Parser PowerShell: 0 errori su entrambi gli script
- [x] Albero di dipendenze annunciato prima di qualsiasi scrittura
- [x] `-NoDependencies` funzionante e documentato
- [x] Ciclo nel catalogo → errore, non loop (installer e CI)
- [x] Guard CI rifiuta dipendenze incompatibili e passa sul catalogo attuale
- [x] Nessun `Read-Host` introdotto
- [x] Documentazione allineata
- [x] Nessun file fuori Scope modificato
