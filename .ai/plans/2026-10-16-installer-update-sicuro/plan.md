# Piano: installer dr-* — aggiornamento che non perde le personalizzazioni dell'host
Data: 2026-10-16
Stato: COMPLETATO

Verifica indipendente (dr-verify-plan): due divergenze trovate e corrette. D1: un file personalizzato e invariato a monte ora dà `[SKIP]` invece di un `.new` ricorrente. D2: testo dei `sourceFiles` in `docs/onboarding.md`. Riverifica: entrambe risolte.

## Obiettivo
Correggere i difetti emersi dalla verifica di installer e aggiornamento (punti 1, 2, 3, 5, 9 del report /dr-tech del 2026-10-16) e riallineare la documentazione.

## Contesto (dalla verifica sul campo)
1. `-Update` sovrascrive senza avviso `.gitignore`, `.editorconfig`, `.gitattributes`, `.github/copilot-instructions.md` e i `rootFiles` (`Directory.Build.props`, `global.json`): le personalizzazioni dell'host spariscono.
2. `Merge-ClaudeMdSection` usa `[regex]::Replace` con stringa: `$_` / `$&` nel `CLAUDE.md` sorgente corrompono il file host (provato).
3. `-Global` non riconosce il blocco legacy `## Linee guida globali (Davraf)` scritto dal vecchio `setup.ps1`: accoderebbe un secondo blocco con regole in parte diverse.
5. `Set-Content -Encoding UTF8` scrive BOM su PowerShell 5.1 e non su 7: file diversi a seconda di chi lancia.
9. `/dr-get-latest` (skill e prompt) parla di sezioni `<!-- dr-<pacchetto> -->` per ogni pacchetto: solo il core ne scrive una.

## Decisione di design — punto 1 (confronto a tre vie)
Per i file di configurazione del core e i `rootFiles`, con `-Update`:
- file host identico alla nuova versione → `[=]`, nulla da fare;
- file host identico alla versione del **commit installato in precedenza** (blob id dal manifest, `git rev-parse <old>:<path>` contro `git hash-object --path`) → non personalizzato → si sovrascrive `[UPD]`;
- altrimenti (personalizzato, o versione precedente non ricostruibile) → la nuova versione va in `<file>.new`, l'originale non si tocca `[NEW]`.
Istruzioni, prompt, skill e catalogo restano sovrascritti come oggi: sono contenuto gestito (le personalizzazioni vanno nei file `-local`).

## Scope
### File da modificare
- [x] `dr-guidelines-install-lib.ps1` — punti 1, 2, 3, 5
- [x] `dr-guidelines-install.ps1` — descrizione di `-Update`
- [x] `.claude/skills/dr-get-latest/SKILL.md` — punto 9 + esito `.new`
- [x] `.github/prompts/dr-get-latest.prompt.md` — punto 9 + esito `.new`
- [x] `.claude/skills/dr-install-global/SKILL.md` — esito `[WARN]` legacy
- [x] `README.md` — tabella file, sezione aggiornamento, FAQ
- [x] `docs/installazione-semplice.md` — avviso aggiornamento
- [x] `docs/onboarding.md` — riga `-Update`
- [x] `docs/bozza-manuale-installazione.md` — esiti dei test del 2026-10-16

### Perimetro negativo
- Non toccherò: wrapper `<pacchetto>-install.ps1` negli altri repo, `scaffolding-catalog.json`, il `~/.claude/CLAUDE.md` reale dell'utente, i punti 4, 6, 7, 8, 10 del report (candidati a issue), il comportamento di istruzioni/prompt/skill.

## Fasi

### Fase 1: Libreria — file protetti con confronto a tre vie
- **Stato**: [x]
- **Precondizione**: `Copy-GuidelineFile` sovrascrive con `-Update` (riga ~139)
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: nuova funzione `Copy-ProtectedFile`; `Install-DrPackageContent` calcola il commit di riferimento e lo passa a `Copy-CoreConfigFiles` e `Copy-PackageRootFiles`, che la usano; elenco finale dei `.new`
- **Tool ammessi**: nessuno
- **Verifica passo**: prova in scratch — file personalizzato → `.new` e originale intatto; file non personalizzato con commit vecchio → `[UPD]`; file identico → `[=]`
- **Su divergenza**: STOP

### Fase 2: Libreria — MatchEvaluator in `Merge-ClaudeMdSection`
- **Stato**: [x]
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Verifica passo**: sorgente con `$_` e `$&` → testo letterale nell'host

### Fase 3: Libreria — blocco globale legacy
- **Stato**: [x]
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: in `Install-DrGlobal`, intestazione `## Linee guida globali (Davraf)` presente e sezione nuova assente → `[WARN]`, nessuna scrittura
- **Verifica passo**: `Install-DrGlobal -ClaudeMdPath <copia scratch>` → `[WARN]`, file invariato

### Fase 4: Libreria — UTF-8 senza BOM
- **Stato**: [x]
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: helper `Write-DrUtf8File`, sostituisce ogni `Set-Content -Encoding UTF8`
- **Verifica passo**: nessun `Set-Content` residuo; install su PS 5.1 → `CLAUDE.md` senza BOM

### Fase 5: Wrapper core — descrizione `-Update`
- **Stato**: [x]
- **File**: `dr-guidelines-install.ps1`

### Fase 6: Skill e prompt `dr-get-latest`, skill `dr-install-global`
- **Stato**: [x]

### Fase 7: Riallinea i documenti al codice
- **Stato**: [x]
- **File**: `README.md`, `docs/installazione-semplice.md`, `docs/onboarding.md`, `docs/bozza-manuale-installazione.md`
- **Azione**: descrivere `[=]`/`[UPD]`/`[NEW]` per i file protetti, il `[WARN]` legacy, footer +0.1

### Fase 8: Verifica finale end-to-end
- **Stato**: [x]
- **Azione**: installazione + `-Update` in scratch con la libreria locale (PS 7 e PS 5.1), poi pulizia scratch

## Criteri di verifica finale
- [x] `-Update` non perde mai una personalizzazione di `.gitignore`/`.editorconfig`/`.gitattributes`/`copilot-instructions.md`/`rootFiles`
- [x] Un file non personalizzato si aggiorna ancora in automatico (`[UPD]`)
- [x] `$_` e `$&` nel `CLAUDE.md` sorgente arrivano letterali
- [x] `-Global` su blocco legacy → `[WARN]` e file invariato
- [x] Nessun `Set-Content -Encoding UTF8` nella libreria
- [x] Documentazione coerente col nuovo comportamento (nessun "sovrascritta con `-Update`" riferito ai file protetti)
