# Piano: documentazione della suite corretta, semplice ed esaustiva
Data: 2026-10-11
Stato: COMPLETATO — verificato in contesto isolato il 2026-10-11 (vedi Esito verifica)

## Obiettivo
Ogni affermazione della documentazione della suite dr-* corrisponde a codice, catalogo e file reali; niente manca di ciò che i repository contengono; il testo è breve e chiaro.

## Scope

### File da modificare
- [ ] `dr-guidelines/README.md` — struttura di `readme-structure.instructions.md`
- [ ] `dr-guidelines/docs/*.md` — footer di `doc-versioning.instructions.md`
- [ ] `README.md` di dr-dotnet-backend, dr-minimalapi, dr-winsvc, dr-efdb, dr-fe, dr-devops, dr-ux-lcars

### Perimetro negativo
- Non toccherò: istruzioni, prompt, skill, installer, catalogo (solo se un documento rivela un errore nel codice: lo segnalo, non lo correggo qui), `TODO/`, `.ai/` degli altri piani, `davraf-guidelines`.
- Nessun file cancellato. Nessun tag, nessun push senza richiesta esplicita.

## Fasi (formato atomico — obbligatorio)

### Fase 1: revisione in sola lettura
- **Stato**: [x]
- **Precondizione**: `main` aggiornato in tutti i repository
- **File**: tutti quelli in Scope
- **Operazione**: verifica
- **Azione**: tre revisori indipendenti (README core; `docs/` del core; README dei pacchetti) confrontano ogni affermazione con i file reali e riportano problemi con file:riga, gravità e correzione proposta
- **Tool ammessi**: sub-agenti Explore (sola lettura)
- **Verifica passo**: tre rapporti ricevuti
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: correzioni di correttezza (gravità ALTA)
- **Stato**: [x]
- **Precondizione**: Fase 1 completata
- **File**: quelli segnalati
- **Operazione**: EDIT
- **Azione**: correggere ogni affermazione falsa o fuorviante, dopo averla ricontrollata sul file sorgente
- **Tool ammessi**: nessuno
- **Verifica passo**: ogni finding ALTA chiuso o dichiarato non riprodotto
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: completezza e semplicità (gravità MEDIA e BASSA)
- **Stato**: [x]
- **Precondizione**: Fase 2 completata
- **File**: quelli segnalati
- **Operazione**: EDIT
- **Azione**: aggiungere ciò che manca, aggiornare l'obsoleto, accorciare i passaggi contorti; un fatto in un posto solo, gli altri rimandano
- **Tool ammessi**: nessuno
- **Verifica passo**: ogni finding chiuso o motivato come non applicato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: footer e commit
- **Stato**: [x]
- **Precondizione**: Fasi 2-3 completate
- **File**: tutti i file toccati
- **Operazione**: EDIT + commit (nessun push)
- **Azione**: footer aggiornati secondo `doc-versioning`; un commit per repository
- **Tool ammessi**: git
- **Verifica passo**: `git status` pulito; footer aggiornati
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: verifica finale in contesto isolato
- **Stato**: [x]
- **Precondizione**: Fase 4 completata
- **File**: tutti quelli toccati
- **Operazione**: verifica
- **Azione**: verifica finale secondo `plan-tracking.instructions.md`, Fase 4, punto 4 (su Claude Code: `/dr-verify-plan`)
- **Tool ammessi**: `/dr-verify-plan`
- **Verifica passo**: nessuna divergenza aperta
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

## Esito revisione (2026-10-11)

- README dei 7 pacchetti: 47 segnalazioni (12 ALTA). Corrette: skill di segnalazione `/dr-file-feedback` al posto di quella dismessa; `copilot-instructions.md` portato dal core; riga `[dep]` reale al posto di una inesistente; pacchetti opzionali e domini allineati al catalogo; tabelle "File citati" a 3 colonne complete; `suggests` e `[sugg]`; file non copiati; footer conformi.
- README del core: 26 segnalazioni (3 ALTA). Corrette: `-Update` sovrascrive `.gitignore`/`.editorconfig`/`.gitattributes`; FAQ senza `git clean -fd`; repo Private richiedono anche `gh auth setup-git`; tabella dei parametri; elenco dipendenze; `sourceFiles` accorciato.
- `docs/`: 55 segnalazioni (11 ALTA). Corrette da due agenti, ciascuno ricontrollando le fonti.
- Scope esteso: `dr-minimalapi/.github/instructions/minimal-api-architecture.instructions.md` riga 500, nome skill `dr-create-launch-profiles` (fonte del dato riportato dal README).

Non corretti, fuori perimetro (codice o catalogo, da segnalare all'utente):
- `dr-guidelines-install-lib.ps1` ~riga 755: `git diff <vecchio> HEAD` su clone `--depth 1` fallisce, l'elenco dei file cambiati non compare mai
- `scaffolding-catalog.json`: descrizione di dr-minimalapi ("scaffolding CRUD") non corrisponde al contenuto del repo
- `.template.config/template.json`: template `dotnet new` con identità pre-split, non documentato
- dr-minimalapi: le istruzioni cercano `db-schema` in `.claude/settings.json`, le skill di scaffolding lo registrano in `.mcp.json`

## Esito verifica (Fase 5)

Verifica isolata: criteri soddisfatti, 12 affermazioni su 14 confermate; 7 divergenze introdotte dalla revisione, tutte corrette:
- `test-progetto-host.md`: `
` letterale nell'output atteso; `-SourceRoot ..uori` diventato `..uori` (carattere `` perso)
- `dr-ux-lcars/README.md`: punto "Stack richiesto" rimesso nell'elenco
- README core: motivo del consiglio "prima il backend, poi il frontend Vue"
- README dei pacchetti: eccezione `obsoleteArtifacts` alla frase "l'installer non cancella"
- `scaffolding-windows-service.md`: cartella `Workers/Options/` (dal prompt di `dr-winsvc`) al posto di "Da verificare"
- `scaffolding-minimal-api.md`: `.vscode/` obbligatorio per l'istruzione, la skill lo genera in modo guidato
- README core: `-NoDependencies` senza `-Package` è ignorato, non rifiutato

## Criteri di verifica finale
- [x] Nessun finding ALTA aperto
- [x] README core conforme alle 12 sezioni di `readme-structure.instructions.md`
- [x] Tabelle dei pacchetti, dei file installati, delle istruzioni, delle skill e dei documenti corrispondono ai file reali e al catalogo
- [x] Footer conformi su ogni file toccato
- [x] Commit per repository, nessun push
