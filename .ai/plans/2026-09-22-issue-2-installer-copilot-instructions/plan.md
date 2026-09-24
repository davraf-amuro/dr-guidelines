# Piano: L'installer copia `.github/copilot-instructions.md` nel progetto host
Data: 2026-09-22
Stato: COMPLETATO — verificato il 2026-09-22 in contesto isolato (vedi Consuntivo)
Issue: davraf-amuro/dr-guidelines#2

## Obiettivo
Far copiare al core `.github/copilot-instructions.md` nell'host, così che il riferimento `@.github/copilot-instructions.md` iniettato in `CLAUDE.md` punti a un file esistente, ed eliminare il workaround documentato nel README.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/2
- Origine: revisione del piano `2026-09-16-riscrittura-doc-dr`, sezione "Problemi emersi, fuori perimetro". Non rilevato da un progetto host.

**Sintesi del problema.** La sezione che l'installer inietta in `CLAUDE.md` richiama `@.github/copilot-instructions.md`, ma nessuna funzione di copia porta quel file nell'host. Copilot resta senza le istruzioni principali: rilevamento del dominio dai pacchetti installati, convenzioni trasversali, gate di push.

**Esito della verifica sui file** (eseguita il 2026-09-22):

| Affermazione della issue | Esito |
|---|---|
| `Copy-CoreConfigFiles` copia solo `.editorconfig`, `.gitignore`, `.gitattributes` | Confermato. Copia anche `.mcp.json` (da `.mcp.example.json`) con logica propria: mai sovrascritto se diverge, `[WARN]` invece di `[UPD]` |
| La funzione sta a **riga 176** | **Discrepanza**: `Copy-CoreConfigFiles` è a **riga 207** di `dr-guidelines-install-lib.ps1`. L'esecutore cerchi la funzione per nome, non per riga |
| Il workaround è documentato a **README righe 136 e 442** | **Discrepanza parziale**: riga 136 confermata; il secondo punto è a **riga 455**, non 442. Esiste anche la riga 192, che documenta il file in tabella e **non** va toccata (descrive cosa fa il file, non il workaround) |
| Copilot non riceve le istruzioni principali | Confermato: la ricerca di `copilot-instructions` in `dr-guidelines-install-lib.ps1` e `dr-guidelines-install.ps1` non produce nessuna occorrenza |

**Punto d'innesto individuato.** `Copy-CoreConfigFiles` è invocata solo dentro `if ($pkg.IsCore)`, quindi è la sede giusta: `copilot-instructions.md` appartiene al core e non deve essere duplicato dai pacchetti di dominio. `Copy-InstructionsAndPrompts` è invece per-pacchetto e itera su `.github/instructions` e `.github/prompts`: non è la sede adatta.

`Copy-GuidelineFile` (già usata da `Copy-CoreConfigFiles`) crea da sé la directory di destinazione mancante e produce la semantica `[OK]` / `[SKIP]` / `[UPD]` richiesta dalla issue. Non serve codice nuovo: serve una riga di chiamata.

**Consultazione:** nessuna. Bug puntuale con soluzione univoca — instradamento di `/dr-issues-to-plans`, passo 4, riga "Bug puntuale con soluzione univoca".

## Decisioni aperte

Entrambe risolte in Fase 0 il 2026-09-22, sulla proposta del piano, per delega esplicita dell'utente ("parti dal primo e procedi con tutti").

1. ~~**Comportamento con `-Update` se l'host ha personalizzato il file.**~~ **RISOLTA: sovrascrive**, con `Copy-GuidelineFile -Update`, come per tutti i file di `.github/instructions/`. È contenuto del pacchetto, e chi lo personalizza nell'host perde comunque la modifica al primo `-Update`, esattamente come già accade per le istruzioni modulari. Scartato il trattamento riservato a `.mcp.json` (confronto di hash e `[WARN]`), che serve a proteggere un file in cui l'host aggiunge roba propria — non è questo il caso.
2. ~~**Dove elencare il file nell'output dell'installer.**~~ **RISOLTA: resta sotto l'intestazione esistente** "File di configurazione:", per non moltiplicare le sezioni di output per un solo file.

## Scope

### File da modificare
- [x] `dr-guidelines-install-lib.ps1` — aggiungere la copia di `.github/copilot-instructions.md` in `Copy-CoreConfigFiles`
- [x] `README.md` — rimuovere il workaround "copialo a mano" (righe 136 e 455), più la riga di tabella che documenta il file ora copiato e la riga di versione

### Perimetro negativo
- Non toccherò: `dr-guidelines-install.ps1` (l'entry point non contiene logica di copia)
- Non toccherò: `Copy-InstructionsAndPrompts`, `Copy-Skills`, `Copy-PackageRootFiles`, `Merge-ClaudeSettings`, `Merge-ClaudeMdSection`
- Non toccherò: la logica di `.mcp.json` dentro `Copy-CoreConfigFiles`
- Non toccherò: `README.md` riga 192 (tabella descrittiva del file, non è il workaround)
- Non toccherò: `.github/copilot-instructions.md` stesso — il contenuto è corretto, manca solo la copia
- Non toccherò: gli altri repository `dr-*`

## Fasi (formato atomico — obbligatorio)

### Fase 1: Copia di `copilot-instructions.md` nell'installer
- **Stato**: [x]
- **Precondizione**: in `dr-guidelines-install-lib.ps1` esiste la funzione `Copy-CoreConfigFiles`, e al suo interno il ciclo `foreach` su `@(".editorconfig", ".gitignore", ".gitattributes")`
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: dentro `Copy-CoreConfigFiles`, dopo il `foreach` sui tre file di configurazione e prima del blocco `.mcp.json`, aggiungere una chiamata `Copy-GuidelineFile` con sorgente `Join-Path $TempRoot ".github\copilot-instructions.md"` e destinazione `Join-Path $HostRoot ".github\copilot-instructions.md"`, passando `-Update:$Update`. Aggiungere un commento di una riga che spieghi perché il file sta qui e non in `Copy-InstructionsAndPrompts`: è contenuto del solo core, e `Copy-CoreConfigFiles` viene invocata soltanto sotto `IsCore`.
- **Tool ammessi**: nessuno
- **Verifica passo**: la ricerca di `copilot-instructions` in `dr-guidelines-install-lib.ps1` restituisce la nuova riga dentro il corpo di `Copy-CoreConfigFiles`; il blocco `.mcp.json` è rimasto intatto
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Verifica di sintassi dello script
- **Stato**: [x]
- **Precondizione**: Fase 1 completata
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: nessuna modifica — sola verifica
- **Azione**: far analizzare il file dal parser PowerShell senza eseguirlo, con `[System.Management.Automation.Language.Parser]::ParseFile()`, e controllare che la collezione di errori sia vuota.
- **Tool ammessi**: PowerShell (sola lettura)
- **Verifica passo**: nessun errore di parsing riportato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Prova di installazione in una cartella usa e getta
- **Stato**: [x]
- **Precondizione**: Fase 2 completata; `git` e PowerShell 7+ disponibili
- **File**: nessuno del repository — si opera in una cartella temporanea fuori dal progetto
- **Operazione**: nessuna modifica al repository
- **Azione**: eseguire `dr-guidelines-install.ps1` in una cartella temporanea vuota e controllare che `.github/copilot-instructions.md` compaia nell'host con il tag `[OK]`. Rieseguire con `-Update` e controllare il tag `[UPD]`. Al termine, cancellare la cartella temporanea.
- **Tool ammessi**: PowerShell
- **Verifica passo**: il file `.github/copilot-instructions.md` esiste nella cartella di prova ed è identico al sorgente del repository; l'output mostra `[OK]` alla prima esecuzione e `[UPD]` alla seconda
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere
- **Nota**: l'installer clona da GitHub. Finché la correzione non è pushata, il clone porta la versione vecchia della libreria: in quel caso eseguire la prova invocando la libreria locale, oppure rimandare questa fase a dopo la push e dichiararlo qui nel piano.
- **Esito 2026-09-22**: eseguita **sulla libreria locale**, come previsto dalla nota, perché la correzione non è ancora pushata e il clone avrebbe portato la versione vecchia. `Copy-CoreConfigFiles` invocata con `TempRoot` = radice del repository e `HostRoot` = cartella usa e getta nello scratchpad. Output: `[OK] copilot-instructions.md` alla prima esecuzione, `[UPD] copilot-instructions.md` con `-Update`, `.github/` creata automaticamente da `Copy-GuidelineFile`, hash del file di destinazione identico al sorgente. `.mcp.json` si è comportato come prima (`[OK]` poi `[SKIP] identico`). Cartella di prova cancellata. Resta da fare, dopo la push, una prova con il clone reale.

### Fase 4: Rimozione del workaround dal README
- **Stato**: [x]
- **Precondizione**: Fase 3 completata o esplicitamente rimandata
- **File**: `README.md`
- **Operazione**: EDIT
- **Azione**: eliminare l'avviso di riga 136 (`> ⚠️ **Non viene copiato .github/copilot-instructions.md**…`) e, nella risposta alla domanda di riga 455, togliere la frase sul workaround lasciando l'indicazione utile: verificare che il file sia presente e committato, poi riavviare VS o VS Code. Lasciare intatta la riga 192.
- **Tool ammessi**: nessuno
- **Verifica passo**: nel README non compare più nessuna forma di "copialo a mano" o "non copia"; le occorrenze di `copilot-instructions` rimaste sono la riga 192 e la risposta della FAQ, entrambe senza workaround
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Aggiornamento della versione del documento
- **Stato**: [x]
- **Precondizione**: Fase 4 completata
- **File**: `README.md`
- **Operazione**: EDIT
- **Azione**: aggiornare la riga finale di versione secondo `doc-versioning.instructions.md` — data odierna, modello usato e una frase sulla modifica.
- **Tool ammessi**: nessuno
- **Verifica passo**: la riga finale del README riporta la data odierna e cita la copia di `copilot-instructions.md`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: Verifica finale in contesto isolato
- **Stato**: [x]
- **Precondizione**: Fasi 1-5 completate
- **File**: tutti quelli elencati in "Scope"
- **Operazione**: nessuna modifica — sola verifica
- **Azione**: eseguire il controllo finale di `plan-tracking.instructions.md`, Fase 4 punto 4, in un contesto isolato dalla conversazione che ha scritto il codice: nuova sessione, sub-agente o secondo revisore. Su Claude Code corrisponde alla skill `/dr-verify-plan`.
- **Tool ammessi**: quelli del revisore, in sola lettura
- **Verifica passo**: il revisore conferma ogni criterio della sezione seguente
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [ ] `Copy-CoreConfigFiles` copia `.github/copilot-instructions.md` con `Copy-GuidelineFile` e la semantica `[OK]` / `[SKIP]` / `[UPD]`
- [ ] `dr-guidelines-install-lib.ps1` viene analizzato dal parser PowerShell senza errori
- [ ] In una installazione di prova il file compare nell'host, identico al sorgente
- [ ] `README.md` non contiene più il workaround "copialo a mano" (righe 136 e 455)
- [ ] `README.md` riga 192 è invariata
- [ ] La logica di `.mcp.json` è invariata
- [x] Nessun file fuori da "Scope" è stato modificato

## Consuntivo

**Verifica finale**: eseguita il 2026-09-22 con `/dr-verify-plan`, sub-agente in sola lettura, senza accesso alla conversazione di implementazione. Esito: tutte le fasi CORRISPONDONO, tutti e sette i criteri SODDISFATTI. Il revisore ha confermato con letture proprie che `Copy-CoreConfigFiles` è invocata in un solo punto, dentro `if ($pkg.IsCore)`, che il parser PowerShell non dà errori, che la riga di tabella "Quando usarlo" è byte-identica, che il blocco `.mcp.json` è integro, e che i sei repository fratelli sono puliti. Il criterio 3 è stato confermato per ispezione statica: il revisore, vincolato alla sola lettura, non ha rieseguito la prova runtime, ma ha verificato che la semantica di `Copy-GuidelineFile` rende l'esito descritto l'unico possibile.

**Due correzioni applicate dopo la verifica**, entrambe dentro `README.md`, cioè nel perimetro di Scope, su rilievo del revisore:

1. La FAQ consigliava `-Update` per recuperare il file mancante. Sbagliato: `Copy-GuidelineFile` stampa `[OK]` quando la destinazione non esiste, quindi basta un rilancio normale. `-Update` avrebbe sovrascritto *tutti* gli altri file del core per recuperarne uno. Ora la FAQ dice di rilanciare l'installer senza opzioni.
2. Mancava l'avviso a chi aveva copiato il file a mano seguendo il README precedente e poi l'aveva personalizzato: con la Decisione 1 quel file ora viene sovrascritto senza preavviso. Aggiunto un riquadro che lo dichiara e indica dove spostare le personalizzazioni.

**Rilievi del revisore non applicati, con motivo:**

- **Fallimento silenzioso se il sorgente sparisce.** `Copy-GuidelineFile` esce senza stampare nulla se il file sorgente non esiste (`if (-not (Test-Path $SrcFile)) { return }`). Se un domani `.github/copilot-instructions.md` venisse rinominato nel core, l'host tornerebbe ad avere il riferimento penzolante — lo stesso bug appena corretto, ma invisibile. Per confronto `Merge-ClaudeSettings` emette un `[WARN]` nello stesso caso. È comportamento pre-esistente della funzione, fuori dal perimetro di questo piano, ma ora fa da unica guardia sull'invariante che il piano garantisce: **candidato a issue separata**, insieme al guard in CI.
- **Formato della riga di versione.** Il piano citava `doc-versioning.instructions.md` per la Fase 5, ma quell'istruzione ha `applyTo: "docs/**/*.md"` e non copre il `README.md` di radice, che ha una convenzione propria. È stata mantenuta la convenzione del README. Il riferimento normativo nel testo della Fase 5 era impreciso.
- **Prefisso di percorso nell'output.** `Copy-GuidelineFile` stampa solo il nome del file, quindi nel log compare `copilot-instructions.md` senza `.github/`: è l'unico file della sezione che finisce in una sottocartella. Cosmetico, coerente con la Decisione 2 e con il resto della funzione.

**Prova end-to-end eseguita il 2026-09-24, dopo la push.** Era l'ultimo punto in sospeso. `dr-guidelines-install.ps1` lanciato in una cartella vuota, con clone reale da GitHub al commit `176afb1`:

- prima installazione → `[OK] copilot-instructions.md`;
- rilancio senza opzioni → `[SKIP]`, come tutti gli altri file già presenti;
- rilancio con `-Update` → `[UPD]`, coerente con la Decisione 1.

Controllo decisivo sull'host prodotto: tutti i riferimenti `@<file>.md` contenuti nel `CLAUDE.md` iniettato puntano a file che esistono davvero — `.github/copilot-instructions.md` e `.github/instructions/mcp-server-discovery.instructions.md`. Nessun riferimento penzolante. Il difetto della issue è chiuso lungo tutto il percorso, non solo nel codice.

Verificato nella stessa prova che `.github/ISSUE_TEMPLATE/` **non** viene distribuito nell'host, il che conferma la premessa su cui poggia la correzione della issue #4.
