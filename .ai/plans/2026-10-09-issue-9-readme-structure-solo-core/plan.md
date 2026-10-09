# Piano: readme-structure.instructions.md limitato al repo dr-guidelines, footer README unico negli host
Data: 2026-10-09
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#9

## Obiettivo
Negli host il README segue una sola fonte (`readme-generator.prompt.md`) con un solo footer; `readme-structure.instructions.md` resta in vigore solo nel repo dr-guidelines e non viene più distribuito.

## Contesto
- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/9 (con commento del proprietario su dr-mailroom)
- Problema: `readme-structure.instructions.md` (`applyTo: "README.md"`, v2.2) descrive le 12 sezioni del README di dr-guidelines ma viene installato in ogni host, dove contraddice `readme-generator.prompt.md` ("Nessuna sezione extra"). Footer divergenti.
- Verifica sui file (2026-10-09):
  - `dr-guidelines-install-lib.ps1` `Copy-InstructionsAndPrompts` (riga 121) copia **tutti** i file di `.github/instructions` e `.github/prompts`: nessun filtro.
  - `Remove-ObsoleteArtifacts` (riga 162) rimuove per percorso, solo con `-Update` (riga 620), leggendo `packages[].obsoleteArtifacts` del catalogo (dr-guidelines: righe 155-162).
  - `.claude/skills/dr-professor/SKILL.md` riga 70: per il README rimanda al footer di readme-structure (`*Documento aggiornato: …*`), mentre le righe 27 e 47 instradano su `readme-generator`, il cui footer è `*Revisione v{N} — {YYYY-MM-DD HH:MM} — {modello-llm}*`: la skill si contraddice.
  - Altri riferimenti: `.github/copilot-instructions.md:17` (cita `readme-structure` come esempio valido per tutti), `docs/onboarding.md:109`, `README.md:205` (corretti nel repo core, restano).
- Consultazione `/dr-prompt-engineer` (sola lettura):
  - `applyTo` più stretto **non funziona**: è un glob relativo al workspace, `README.md` è uguale in ogni repo.
  - Raccomandata l'opzione A: campo di catalogo "non distribuire" letto da `Copy-InstructionsAndPrompts`, più la stessa voce in `obsoleteArtifacts` per ripulire gli host già installati. Il file resta in `.github/instructions` e in dr-guidelines funziona con Claude Code e Copilot.
  - Alternativa B: spostare il file fuori da `.github/instructions` (es. `docs/maintainers/`), senza toccare l'installer, ma Copilot perde l'aggancio automatico.
  - Footer host consigliato: `*Revisione v{N} — {YYYY-MM-DD HH:MM} — {modello-llm}*` (come `doc-versioning`).
  - ⚠️ **Rischio**: in dr-mailroom l'adattamento locale ha lo **stesso nome** `readme-structure.instructions.md`; con `obsoleteArtifacts` il prossimo `-Update` lo cancellerebbe. Va rinominato prima (es. `readme-local.instructions.md`).
  - La sovrascrittura delle personalizzazioni locali da parte di `-Update` è un problema **sistemico** (`Copy-GuidelineFile` usa `-Force` su ogni file): fuori perimetro, da issue separata. In perimetro resta solo documentare la convenzione "personalizzazione locale = file con nome proprio, non distribuito dal pacchetto".

## Decisioni aperte
1. **Meccanismo** — (A, consigliata) campo di catalogo + filtro nell'installer; (B) spostare il file fuori da `.github/instructions`. Il piano è scritto per **A**.
2. **Nome del campo di catalogo** — proposta `coreOnlyArtifacts` (percorsi relativi presenti nel repo del pacchetto ma mai copiati negli host).
3. **Pulizia host** — aggiungere `.github/instructions/readme-structure.instructions.md` a `obsoleteArtifacts` (sì/no), sapendo che cancella l'adattamento di dr-mailroom se non rinominato prima.
4. **Footer** — formato unico per i README host (consigliato `*Revisione v{N} — {YYYY-MM-DD HH:MM} — {modello-llm}*`); se applicarlo anche al README di dr-guidelines (cambia readme-structure §12 e il footer di `README.md`) o lasciare lì il formato attuale.
5. **Nome convenzionale dei file locali** — proposta `*-local.instructions.md`.
6. **Issue separata** sulla protezione delle personalizzazioni da `-Update`: aprirla con `/dr-file-feedback` (sì/no).

### Decisioni prese (utente, 2026-10-09: "tutte le consigliate"; dove manca una consigliata, la più conservativa)
1. A — campo di catalogo + filtro nell'installer.
2. Nome del campo: `coreOnlyArtifacts`.
3. Sì — `.github/instructions/readme-structure.instructions.md` anche in `obsoleteArtifacts`. Il README documenta che un adattamento locale con lo stesso nome va rinominato **prima** di `-Update` (caso dr-mailroom).
4. Footer unico `*Revisione v{N} — {YYYY-MM-DD HH:MM} — {modello-llm}*` per i README host **e** per il README di dr-guidelines (readme-structure §1 riga 12, §12 e footer di `README.md` allineati).
5. Convenzione file locali: `*-local.instructions.md`.
6. No — nessuna issue aperta ora (azione verso l'esterno, nessuna consigliata): la Fase 7 si salta; la proposta resta nel riepilogo all'utente.

## Scope
### File da modificare
- [x] `scaffolding-catalog.json` — campo `coreOnlyArtifacts` sul pacchetto dr-guidelines; eventuale voce in `obsoleteArtifacts`
- [x] `dr-guidelines-install-lib.ps1` — lettura del campo in `Get-DrPackageRegistry` e filtro in `Copy-InstructionsAndPrompts`
- [x] `.claude/skills/dr-professor/SKILL.md` — riga 70: README host = footer di `readme-generator`; readme-structure vale solo in dr-guidelines
- [x] `.github/copilot-instructions.md` — riga 17: esempio `readme-structure` sostituito da `readme-generator`
- [x] `.github/instructions/readme-structure.instructions.md` — nota d'ambito ("vale solo in questo repo, non distribuito"); footer §12 solo se decisione 4 lo chiede
- [x] `README.md` — sezione "Aggiornare le Guidelines" o FAQ: convenzione per le personalizzazioni locali; footer secondo decisione 4
- [x] `docs/bozza-manuale-installazione.md` — documento vivo: annotare la modifica

### Perimetro negativo
- Non toccherò: `Copy-GuidelineFile` e la logica di sovrascrittura di `-Update` (problema sistemico, issue separata); `readme-generator.prompt.md` salvo il footer se la decisione 4 sceglie l'altro formato; gli altri file in `.github/instructions/`; i pacchetti di dominio; il repo dr-mailroom.

## Fasi (formato atomico — obbligatorio)

### Fase 1: Campo di catalogo
- **Stato**: [x] — `coreOnlyArtifacts` aggiunto e voce in `obsoleteArtifacts`; `ConvertFrom-Json` ok
- **Precondizione**: Decisioni aperte 1-6 risolte dall'utente
- **File**: `scaffolding-catalog.json`
- **Operazione**: EDIT
- **Azione**: Nel pacchetto `dr-guidelines` aggiungi il campo (nome da decisione 2) con valore `[".github/instructions/readme-structure.instructions.md"]`; se la decisione 3 è sì, aggiungi lo stesso percorso a `obsoleteArtifacts`.
- **Tool ammessi**: nessuno
- **Verifica passo**: `Get-Content scaffolding-catalog.json | ConvertFrom-Json` senza errori; il campo esiste con il percorso atteso
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Filtro nell'installer
- **Stato**: [x] — `CoreOnlyArtifacts` nel registry, parametro `-CoreOnly` con validazione in `Copy-InstructionsAndPrompts`, passato da `Install-DrPackageContent`. `Install-DrGlobal` non copia `.github/`: nessun filtro necessario. Parser: 0 errori.
  - **Prova eseguita**: l'installer reale (`dr-guidelines-install.ps1`) carica libreria e catalogo dal raw di `main` e clona il pacchetto da GitHub, quindi non riflette il working tree e non ha una modalità "clone locale" per i file. Prova fatta con lo script `scratchpad/test-install-9.ps1`: dot-source della lib locale, `$Script:Catalog` = catalogo locale, `git` simulato (il "clone" copia il working tree), poi `Install-DrPackage -PackageName dr-guidelines` (percorso reale fino a `Copy-InstructionsAndPrompts` e `Remove-ObsoleteArtifacts`).
  - Esito: host vuoto → `readme-structure` assente (`[CORE]`), 11/11 altri file presenti; `-Update` su host con `readme-structure` + `readme-local.instructions.md` → `[DEL] readme-structure`, `readme-local` preservato; percorsi non validi (`../`, risalita, assoluto, fuori `.github/instructions|prompts`, sottocartelle) rifiutati; backslash e maiuscole normalizzati.
  - CI locale: script del job `catalog-guard` di `.github/workflows/ci.yml` eseguito → "Catalogo allineato: 7 pacchetti, 5 tipologie." (exit 0). Job `build-and-test`: nessun progetto .NET, non applicabile.
- **Precondizione**: Fase 1 completata
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: In `Get-DrPackageRegistry` leggi il nuovo campo come array (stesso schema di `ObsoleteArtifacts`, riga 89); passalo a `Copy-InstructionsAndPrompts`, che salta i file il cui percorso relativo `.github/<sub>/<nome>` è nell'elenco, stampando `[CORE] <nome>` in grigio. Stesse validazioni di percorso di `Remove-ObsoleteArtifacts` (no risalita, solo `.github/`).
- **Tool ammessi**: nessuno
- **Verifica passo**: installazione di prova in una cartella temporanea (`dr-guidelines-install.ps1` da clone locale, cartella nello scratchpad) → `readme-structure.instructions.md` assente, tutti gli altri file di `.github/instructions` presenti; con `-Update` su un host che ha il file e decisione 3 = sì → file rimosso
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: dr-professor — fonte unica del README host
- **Stato**: [x] — `SKILL.md:76` riscritta: README = `readme-generator` e il suo footer; readme-structure solo nel repo dr-guidelines
- **Precondizione**: Fase 2 completata
- **File**: `.claude/skills/dr-professor/SKILL.md`
- **Operazione**: EDIT
- **Azione**: Riscrivi l'eccezione README (riga 70): il README segue `readme-generator.prompt.md` e il suo footer; solo nel repo dr-guidelines, dove `readme-structure.instructions.md` esiste, vale quella struttura con il suo footer.
- **Tool ammessi**: nessuno
- **Verifica passo**: nessuna frase della skill impone readme-structure in un host; il footer README citato coincide con quello di `readme-generator`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: copilot-instructions — esempio corretto
- **Stato**: [x] — riga 17 → `readme-generator` ("istruzione modulare o il prompt"); footer v2.1 2026-10-09; grep readme-structure vuoto
- **Precondizione**: Fase 3 completata
- **File**: `.github/copilot-instructions.md`
- **Operazione**: EDIT
- **Azione**: Alla riga 17 sostituisci l'esempio `readme-structure` con `readme-generator`; aggiorna il footer del file.
- **Tool ammessi**: nessuno
- **Verifica passo**: `grep -n readme-structure .github/copilot-instructions.md` vuoto
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Nota d'ambito in readme-structure
- **Stato**: [x] — nota d'ambito riga 7; tabella riga 31 e §12 (righe 108-110) al formato `*Revisione v{N} — {YYYY-MM-DD HH:MM} — {modello-llm}*`; §7 riga 83: i file `coreOnlyArtifacts` restano in tabella marcati "solo questo repo"; footer template v2.3
- **Precondizione**: Fase 4 completata
- **File**: `.github/instructions/readme-structure.instructions.md`
- **Operazione**: EDIT
- **Azione**: Sotto il titolo aggiungi: "Vale solo nel repo dr-guidelines: l'installer non la distribuisce (campo `<nome>` del catalogo). Nei progetti host il README segue `.github/prompts/readme-generator.prompt.md`." Se decisione 4 lo chiede, cambia il footer in tabella §1 riga 12 e §12. Aggiorna il footer di template (v2.3).
- **Tool ammessi**: nessuno
- **Verifica passo**: nota d'ambito presente; footer template v2.3
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: Documentazione
- **Stato**: [x] — README: §5 riga 132 (esclusi i `coreOnlyArtifacts`), §6 riga 172 (rimozione con `-Update` + rimando FAQ), §7 riga 207 ("Solo in questo repo"), FAQ righe 470-474 (convenzione `*-local.instructions.md`; readme-structure rimosso, rinominare prima), footer `*Revisione v3.12 — 2026-10-09 14:40 — claude-opus-5-5*`. Bozza: riga 153 (`[CORE]`, 11 su 12), voce 14 in "Da verificare", footer v1.9. Modifiche scritte direttamente, senza `/dr-professor`. `docs/onboarding.md:109` (regola valida nel repo core) fuori Scope, non toccato.
- **Precondizione**: Fase 5 completata
- **File**: `README.md`, `docs/bozza-manuale-installazione.md`
- **Operazione**: EDIT
- **Azione**: Nel README aggiungi la voce FAQ "Come personalizzo un'istruzione senza perderla con `-Update`?" → file con nome proprio (decisione 5), mai lo stesso nome di un file del pacchetto; aggiorna la tabella "Cosa viene configurato" se elenca readme-structure tra i file installati; footer (decisione 4). Nella bozza annota il cambio. Rispetta `readme-structure.instructions.md` per il README.
- **Tool ammessi**: `/dr-professor`
- **Verifica passo**: la FAQ esiste; nessun testo dice che readme-structure viene installato negli host; footer aggiornati
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7: Issue separata sulle personalizzazioni (condizionale)
- **Stato**: [x] — saltata per decisione 6
- **Precondizione**: Fase 6 completata; decisione 6 = sì
- **File**: nessuno (GitHub)
- **Operazione**: nessuna su file
- **Azione**: Apri con `/dr-file-feedback` una issue su dr-guidelines: "-Update sovrascrive le personalizzazioni locali dei file distribuiti", con le due proposte (marcatore/hash con `[KEEP]`, oppure `.ai/dr-guidelines-overrides.json`). Decisione 6 = no → marca la fase come saltata.
- **Tool ammessi**: `/dr-file-feedback`
- **Verifica passo**: URL della nuova issue annotato in plan.md, oppure "saltata per decisione 6"
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

### Fase 8: Verifica finale in contesto isolato
- **Stato**: [x] — `/dr-verify-plan` 2026-10-09: 7/7 file CORRISPONDONO, 7/7 criteri SODDISFATTI (prova di installazione locale e -Update ripetute dal verificatore)
- **Precondizione**: Fasi 1-7 completate
- **File**: questo `plan.md`
- **Operazione**: EDIT
- **Azione**: Esegui la verifica finale di `plan-tracking.instructions.md` Fase 4, punto 4, in un contesto isolato (su Claude Code: `/dr-verify-plan`); poi aggiorna `Stato`.
- **Tool ammessi**: `/dr-verify-plan`
- **Verifica passo**: tutti i file CORRISPONDONO e tutti i criteri SODDISFATTI
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 8: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] Installazione di prova in un host vuoto: `readme-structure.instructions.md` non viene copiato, gli altri file sì
- [x] Il catalogo resta JSON valido e il nuovo campo è letto dall'installer
- [x] `dr-professor` non impone readme-structure né il suo footer nei progetti host
- [x] `.github/copilot-instructions.md` non cita più readme-structure come esempio generico
- [x] `readme-structure.instructions.md` dichiara il proprio ambito (solo dr-guidelines)
- [x] README documenta la convenzione per le personalizzazioni locali
- [x] Nessuna feature esclusiva di un solo agente in `.github/`
