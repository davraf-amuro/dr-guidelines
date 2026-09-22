# Piano: L'installer copia `.github/copilot-instructions.md` nel progetto host
Data: 2026-09-22
Stato: PROPOSTO
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

1. **Comportamento con `-Update` se l'host ha personalizzato il file.** `Copy-GuidelineFile -Update` sovrascrive senza chiedere, come per tutti i file di `.github/instructions/`. In alternativa si può dare a `copilot-instructions.md` il trattamento riservato a `.mcp.json`: confronto di hash e `[WARN]` invece della sovrascrittura. *Proposta:* sovrascrivere come gli altri file di istruzione — è contenuto del pacchetto, e chi lo personalizza nell'host perde comunque la modifica al primo `-Update`, esattamente come già accade per `.github/instructions/*.md`. Decisione dell'utente.
2. **Dove elencare il file nell'output dell'installer.** Oggi `Copy-CoreConfigFiles` stampa l'intestazione "File di configurazione:". `copilot-instructions.md` è un'istruzione, non una configurazione. Serve un'intestazione separata o si accetta quella esistente? *Proposta:* accettare quella esistente, per non moltiplicare le sezioni di output.

## Scope

### File da modificare
- [ ] `dr-guidelines-install-lib.ps1` — aggiungere la copia di `.github/copilot-instructions.md` in `Copy-CoreConfigFiles`
- [ ] `README.md` — rimuovere il workaround "copialo a mano" (righe 136 e 455)

### Perimetro negativo
- Non toccherò: `dr-guidelines-install.ps1` (l'entry point non contiene logica di copia)
- Non toccherò: `Copy-InstructionsAndPrompts`, `Copy-Skills`, `Copy-PackageRootFiles`, `Merge-ClaudeSettings`, `Merge-ClaudeMdSection`
- Non toccherò: la logica di `.mcp.json` dentro `Copy-CoreConfigFiles`
- Non toccherò: `README.md` riga 192 (tabella descrittiva del file, non è il workaround)
- Non toccherò: `.github/copilot-instructions.md` stesso — il contenuto è corretto, manca solo la copia
- Non toccherò: gli altri repository `dr-*`

## Fasi (formato atomico — obbligatorio)

### Fase 1: Copia di `copilot-instructions.md` nell'installer
- **Stato**: [ ]
- **Precondizione**: in `dr-guidelines-install-lib.ps1` esiste la funzione `Copy-CoreConfigFiles`, e al suo interno il ciclo `foreach` su `@(".editorconfig", ".gitignore", ".gitattributes")`
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: dentro `Copy-CoreConfigFiles`, dopo il `foreach` sui tre file di configurazione e prima del blocco `.mcp.json`, aggiungere una chiamata `Copy-GuidelineFile` con sorgente `Join-Path $TempRoot ".github\copilot-instructions.md"` e destinazione `Join-Path $HostRoot ".github\copilot-instructions.md"`, passando `-Update:$Update`. Aggiungere un commento di una riga che spieghi perché il file sta qui e non in `Copy-InstructionsAndPrompts`: è contenuto del solo core, e `Copy-CoreConfigFiles` viene invocata soltanto sotto `IsCore`.
- **Tool ammessi**: nessuno
- **Verifica passo**: la ricerca di `copilot-instructions` in `dr-guidelines-install-lib.ps1` restituisce la nuova riga dentro il corpo di `Copy-CoreConfigFiles`; il blocco `.mcp.json` è rimasto intatto
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Verifica di sintassi dello script
- **Stato**: [ ]
- **Precondizione**: Fase 1 completata
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: nessuna modifica — sola verifica
- **Azione**: far analizzare il file dal parser PowerShell senza eseguirlo, con `[System.Management.Automation.Language.Parser]::ParseFile()`, e controllare che la collezione di errori sia vuota.
- **Tool ammessi**: PowerShell (sola lettura)
- **Verifica passo**: nessun errore di parsing riportato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Prova di installazione in una cartella usa e getta
- **Stato**: [ ]
- **Precondizione**: Fase 2 completata; `git` e PowerShell 7+ disponibili
- **File**: nessuno del repository — si opera in una cartella temporanea fuori dal progetto
- **Operazione**: nessuna modifica al repository
- **Azione**: eseguire `dr-guidelines-install.ps1` in una cartella temporanea vuota e controllare che `.github/copilot-instructions.md` compaia nell'host con il tag `[OK]`. Rieseguire con `-Update` e controllare il tag `[UPD]`. Al termine, cancellare la cartella temporanea.
- **Tool ammessi**: PowerShell
- **Verifica passo**: il file `.github/copilot-instructions.md` esiste nella cartella di prova ed è identico al sorgente del repository; l'output mostra `[OK]` alla prima esecuzione e `[UPD]` alla seconda
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere
- **Nota**: l'installer clona da GitHub. Finché la correzione non è pushata, il clone porta la versione vecchia della libreria: in quel caso eseguire la prova invocando la libreria locale, oppure rimandare questa fase a dopo la push e dichiararlo qui nel piano.

### Fase 4: Rimozione del workaround dal README
- **Stato**: [ ]
- **Precondizione**: Fase 3 completata o esplicitamente rimandata
- **File**: `README.md`
- **Operazione**: EDIT
- **Azione**: eliminare l'avviso di riga 136 (`> ⚠️ **Non viene copiato .github/copilot-instructions.md**…`) e, nella risposta alla domanda di riga 455, togliere la frase sul workaround lasciando l'indicazione utile: verificare che il file sia presente e committato, poi riavviare VS o VS Code. Lasciare intatta la riga 192.
- **Tool ammessi**: nessuno
- **Verifica passo**: nel README non compare più nessuna forma di "copialo a mano" o "non copia"; le occorrenze di `copilot-instructions` rimaste sono la riga 192 e la risposta della FAQ, entrambe senza workaround
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Aggiornamento della versione del documento
- **Stato**: [ ]
- **Precondizione**: Fase 4 completata
- **File**: `README.md`
- **Operazione**: EDIT
- **Azione**: aggiornare la riga finale di versione secondo `doc-versioning.instructions.md` — data odierna, modello usato e una frase sulla modifica.
- **Tool ammessi**: nessuno
- **Verifica passo**: la riga finale del README riporta la data odierna e cita la copia di `copilot-instructions.md`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: Verifica finale in contesto isolato
- **Stato**: [ ]
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
- [ ] Nessun file fuori da "Scope" è stato modificato
