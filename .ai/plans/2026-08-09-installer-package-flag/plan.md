# Piano: flag -Package sull'installer core, poi push
Data: 2026-08-09
Stato: IN CORSO

## Obiettivo
Un solo comando bootstrap deve poter installare qualsiasi pacchetto `dr-*` con le sue dipendenze; poi allineare i remoti per rendere possibile il test in sandbox.

## Contesto
`Install-DrPackage` ha già registry e risoluzione ricorsiva delle dipendenze (`dr-guidelines-install-lib.ps1` righe 12-19 e 256-264), ma `dr-guidelines-install.ps1` espone solo core e `-Global`. Per installare `dr-minimalapi` serve oggi l'installer di quel repo o `/dr-scaffold-guidelines`.

Stato git rilevato: solo `dr-guidelines` è sporco (5 voci); gli altri sei repo `dr-*` sono puliti e allineati con `origin/main` — nessun push necessario per loro. `davraf-guidelines` va solo aggiornato con una pull.

Gate di push: nessun `.csproj` e nessun `package.json` in nessuno dei repo `dr-*` → i comandi lint della tabella (`dotnet format`, `npm run lint`, `ruff`) non hanno un target applicabile. Il gate si risolve dichiarando l'assenza di target, non saltandolo in silenzio.

## Scope
### File da modificare
- [ ] `dr-guidelines-install.ps1` — parametro `-Package`, help aggiornato, mutua esclusione con `-Global`
- [ ] `README.md` — documenta `-Package` nella sezione di installazione dei pacchetti dominio

### Perimetro negativo
- Non toccherò `dr-guidelines-install-lib.ps1` (registry e dipendenze già a posto)
- Non toccherò le skill, il catalogo, `docs/`, `CLAUDE.md`
- Non farò push sui sei repo `dr-*` puliti né su `davraf-guidelines` (solo pull, come richiesto)
- Nessun tag, nessuna release

## Fasi (formato atomico)

### Fase 1: parametro -Package
- **Stato**: [ ]
- **Precondizione**: `dr-guidelines-install.ps1` ha il blocco `param(` con `$Update` e `$Global`
- **File**: `dr-guidelines-install.ps1`
- **Operazione**: EDIT
- **Azione**: aggiungere `[string]$Package` al blocco `param`, e in coda sostituire l'`if ($Global) {...} else {...}` con: `-Global` e `-Package` insieme → `throw` esplicito; `-Global` → `Install-DrGlobal`; `-Package` valorizzato → `Install-DrPackage -PackageName $Package`; altrimenti core come oggi. Aggiornare il commento-help (`.DESCRIPTION` con l'esempio del pacchetto dominio, `.PARAMETER Package`).
- **Tool ammessi**: Edit
- **Verifica passo**: rileggendo il file, `param` contiene `$Package`, la dispatch ha i tre rami e il blocco help descrive il parametro
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md

### Fase 2: sintassi PowerShell verificata
- **Stato**: [ ]
- **Precondizione**: Fase 1 verificata
- **File**: nessuno (sola lettura)
- **Operazione**: verifica
- **Azione**: eseguire il parser PowerShell sul file (`[System.Management.Automation.Language.Parser]::ParseFile`) e confermare zero errori di sintassi.
- **Tool ammessi**: PowerShell (read-only)
- **Verifica passo**: nessun errore riportato dal parser
- **Su divergenza**: STOP — correggi prima di proseguire

### Fase 3: README
- **Stato**: [ ]
- **Precondizione**: Fase 2 verificata
- **File**: `README.md`
- **Operazione**: EDIT
- **Azione**: nella sezione che spiega come aggiungere un pacchetto dominio, affiancare all'esecuzione di `<pacchetto>-install.ps1` la variante con `-Package <nome>` sull'installer del core, indicando che le dipendenze vengono risolte da sole.
- **Tool ammessi**: Edit
- **Verifica passo**: rileggendo il file, la sezione cita `-Package` con un esempio eseguibile
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md

### Fase 4: gate di push e commit
- **Stato**: [ ]
- **Precondizione**: Fasi 1-3 verificate
- **File**: nessuno (git)
- **Operazione**: verifica + commit
- **Azione**: dichiarare l'esito del gate lint (nessun target `.csproj`/`package.json` nel repo), poi `git add` dei file in scope e commit unico sul branch `main`.
- **Tool ammessi**: Bash/PowerShell (git)
- **Verifica passo**: `git status --short` pulito salvo file fuori scope dichiarati; `git log -1` mostra il commit
- **Su divergenza**: STOP

### Fase 5: push e pull
- **Stato**: [ ]
- **Precondizione**: Fase 4 verificata
- **File**: nessuno (git)
- **Operazione**: push/pull
- **Azione**: `git push` su `dr-guidelines`. Verificare di nuovo gli altri sei repo `dr-*`: push solo se risultano avanti rispetto a `origin`. Su `davraf-guidelines` eseguire solo `git pull`, mai push.
- **Tool ammessi**: Bash/PowerShell (git)
- **Verifica passo**: `dr-guidelines` allineato con `origin/main`; gli altri repo invariati; `davraf-guidelines` aggiornato
- **Su divergenza**: STOP — riporta l'errore senza forzare nulla

## Criteri di verifica finale
- [ ] `dr-guidelines-install.ps1 -Package dr-minimalapi` è una chiamata valida e documentata
- [ ] Parser PowerShell senza errori sul file modificato
- [ ] `dr-guidelines` pushato e allineato con `origin/main`
- [ ] Nessun push sui sei repo `dr-*` puliti né su `davraf-guidelines`, che risulta solo aggiornato via pull
- [ ] Nessun tag creato
