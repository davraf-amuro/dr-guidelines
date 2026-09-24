# Piano: Cartella `briefs/` per le richieste che l'utente scrive e gli agenti leggono
Data: 2026-09-22
Stato: IN CORSO
Issue: davraf-amuro/dr-guidelines#1

## Obiettivo
Dare al progetto host un posto convenzionale e versionato dove l'utente scrive le proprie richieste, e far sì che le skill di scaffolding le leggano prima di fare domande, con lo stesso comportamento su Claude Code e GitHub Copilot.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/1
- Origine: emersa lavorando sul progetto host `dr-postman`, con il solo core installato (commit `c5794ab`, 2026-09-21), agente Claude Code.

**Sintesi del problema.** Oggi la richiesta arriva agli agenti solo come testo nella conversazione, tipicamente come argomento di `/dr-scaffold`. Non esiste un punto convenzionale su disco dove scriverla, versionarla, riprenderla in una sessione successiva e condividerla tra i due agenti.

**Precisazione terminologica, decisa dall'utente il 2026-09-22.** La issue parla di "specifiche", ma il contenuto della cartella è un'altra cosa: sono **le richieste che l'utente scrive, da trasformare in piani**. Una specifica descrive il comportamento atteso del sistema; una richiesta esprime un bisogno. Il documento che esprime una richiesta e avvia il lavoro si chiama **brief**, da cui il nome della cartella. Il piano usa "brief" come sostantivo maschile (il brief, i brief) e riserva "specifica" al suo significato proprio, che qui non si applica. Il modello del documento va scritto di conseguenza: non descrive un sistema, esprime un bisogno.

La catena che ne risulta è: **brief (scritto dall'utente) → piano (scritto dall'agente) → esecuzione**.

**Esito della verifica sui file** (eseguita il 2026-09-22):

| Affermazione della issue | Esito |
|---|---|
| Nessuna cartella convenzionale per le richieste | Confermato. L'installer crea in `.ai/` solo `dr-scaffolding-catalog.json` e `dr-guidelines-packages.json` |
| `.ai/` contiene artefatti dell'agente, non input dell'utente | Confermato: `.ai/plans/`, `.ai/context/snapshot.md`, i due file JSON. Nessun file scritto dall'utente |
| Le skill ricevono la richiesta solo come argomento | Confermato: `dr-scaffold/SKILL.md` usa `$ARGUMENTS`; `dr-scaffold-solution/SKILL.md` raccoglie tutto con domande e chiude con una conferma unica |

**Fatto aggiuntivo, decisivo per la scelta del percorso.** `.github/instructions/doc-versioning.instructions.md` ha `applyTo: "docs/**/*.md"`. Mettere i brief sotto `docs/` significa farli ricadere automaticamente sotto le regole di versionamento della documentazione tecnica — footer di versione e simili — pensate per altro. Verificato leggendo l'`applyTo` di tutte e undici le istruzioni modulari: le altre sono `**`, `README.md` o `tools/**/README.md`.

**Esito della consultazione** (`/dr-warroom`, sola lettura, nessun file scritto). Il tavolo ha prodotto proposte di scrittura: sono riportate qui come raccomandazioni, non eseguite. `DBADMIN` ha dichiarato "nessun intervento database necessario".

Le tre posizioni valutate dal tavolo, con la scelta finale dell'utente in coda:

| Opzione | Pro | Contro |
|---|---|---|
| Cartella in radice | Massima visibilità; segnala "roba tua, non dell'agente"; non eredita nessuna regola esistente | Aggiunge una cartella di primo livello in ogni progetto; il nome `specs/` in particolare collide con le spec di test negli host JS/TS |
| Sotto `docs/` | `docs/` esiste già ed è la casa dei documenti scritti a mano; un solo glob copre entrambi gli agenti | Eredita `doc-versioning` (vedi sopra) |
| Sotto `.ai/` | Namespace che entrambi gli agenti già leggono; input e piano vicini | Rompe l'invariante "`.ai/` è output rigenerabile dell'agente"; cartella che molti host mettono fra quelle escluse dalla vista, quindi l'unico artefatto umano diventa il meno visibile |

**Su cosa il tavolo converge** (quattro ruoli espliciti, nessun contrario):

1. Un file per funzionalità, `<slug>.md`, versionato nel repo host. Non un file unico.
2. Sezioni fisse minime più una coda libera. Nucleo proposto: Obiettivo, Fuori scope, Vincoli, Criteri di accettazione, più una sezione "Note". Né markdown completamente libero né modello rigido.
3. Il brief dice **cosa** serve, il piano **come** si fa. Il piano guadagna una riga `Brief: <percorso>`, sul modello del campo `Issue:` già esistente in `plan-tracking.instructions.md`.
4. Le skill di scaffolding leggono i brief **prima** di qualsiasi domanda, fanno **eco** di ciò che hanno capito, chiedono **solo le lacune**, poi la conferma unica. Mai ri-chiedere un dato già scritto, mai darlo per acquisito in silenzio.
5. Percorso fisso e identico sulle due superfici. Non configurabile per progetto, o la parità duale salta.
6. Non `.ai/`: tre ruoli su quattro contrari, perché `.ai/` è output dell'agente e rigenerabile mentre il brief è input umano autorevole. L'argomento forte a favore di `.ai/` — il rischio che `-Update` sovrascriva il contenuto dell'utente — si risolve con la semantica "copia solo se assente", che vale in qualunque cartella.

**Punti di tensione segnalati:**

- **Proprietà contro prossimità.** Il tavolo non ha deciso se `.ai/` sia un contratto di *proprietà* (area dell'agente) o di *indirizzo* (posto che entrambi gli agenti sanno leggere). La scelta dell'utente risolve la questione in favore della proprietà: il brief sta fuori.
- **Quanta struttura imporre.** Un modello rigido rischia di far sì che l'utente non scriva affatto il brief; un modello assente lo rende non interpretabile. Il template è un aiuto o un contratto?
- **Indice sì o no.** Proposto un manifest leggibile in una sola lettura, per non costringere l'agente a leggere tutti i brief. Nessun altro ruolo l'ha chiesto e nessuno ha detto chi lo tiene aggiornato: un indice che diverge dai file è peggio di nessun indice.
- **Beneficio differito.** Su un repository nuovo la cartella è vuota, quindi "leggi prima di chiedere" non cambia nulla al primo `/dr-scaffold`. Il guadagno si vede al secondo giro, o quando l'utente prepara il brief in anticipo — che è esattamente il caso `dr-postman` da cui nasce la issue.
- **Copilot non esplora le cartelle da solo.** Senza un percorso esplicito nel file `.prompt.md`, la parità duale resta sulla carta.

**Rischio di sicurezza sollevato in consultazione, da tenere nel contratto.** Il brief viene letto *prima* di ogni conferma: il suo contenuto va trattato come **dato, mai come istruzione per l'agente**, altrimenti il file diventa un vettore di prompt injection. Va inoltre vietato scrivervi credenziali, rimandando a `sensitive-data.instructions.md` (che è già `applyTo: "**"`, quindi copre il caso: serve la menzione esplicita, non un'estensione di scope).


## Decisioni (Fase 0, risolte dall'utente il 2026-09-24)

Le risposte dell'utente hanno ridotto molto il perimetro rispetto alla proposta del warroom: niente modello di brief, niente formato, niente lettura automatica della cartella.

1. **Percorso**: `briefs/` in radice (deciso il 2026-09-22).
2. **Restringere `doc-versioning`**: non applicabile.
3. **Percorso fisso o parametro**: la cartella la crea il pacchetto core; il percorso è scritto nel testo, nessun parametro nel catalogo.
4. **Sezioni del modello**: nessun modello. La cartella è vuota; l'utente scrive i `.md` come preferisce.
5. **Front matter**: nessuno.
6. **Naming dei file**: libero, a scelta dell'utente.
7. **Creazione da parte dell'installer**: sempre, dal pacchetto core, cartella vuota. Nessun file dentro, neppure `.gitkeep` o README.
8. **Indice**: nessuno.
9. **Nessun brief trovato**: non si applica. L'agente non esplora `briefs/`: è l'utente a indicare nel prompt quale brief usare.
10. **Eco**: sostituita dalla regola 12.
11. **Ciclo di vita**: nessuno stato.
12. **Comportamento quando l'utente indica un brief**: l'agente legge il documento e **crea obbligatoriamente un piano**, a prescindere dal numero di operazioni. L'utente **deve approvare** il piano prima dell'esecuzione. Se l'agente trova problemi o lacune, o lo ritiene opportuno, chiede gli approfondimenti necessari a scrivere il piano. Vale per ogni task, non solo per lo scaffolding.
13. **Collegamento**: un link al brief sotto il titolo del piano. Nessun riferimento dentro il brief.
- **Istruzione dedicata ai brief** (clausola "dato, mai istruzione" e divieto di credenziali): **scartata** dall'utente.

**Conseguenza da dichiarare.** La regola 12 prevale sull'esenzione "skill invocata esplicitamente = approvazione" di `CLAUDE.md`: se l'argomento di una skill è un brief, prima viene il piano approvato.

## Scope

### File da modificare
- [x] `.ai/plans/2026-09-22-issue-1-cartella-briefs/plan.md` — questo piano
- [x] `dr-guidelines-install-lib.ps1` — nuova funzione che crea `briefs/` vuota se assente, invocata nel ramo `IsCore`
- [x] `.github/instructions/plan-tracking.instructions.md` — sezione "Piani da un brief" e link sotto il titolo nel template
- [x] `CLAUDE.md` — convenzione `briefs/` (raggiunge gli host via `Merge-ClaudeMdSection`) e deroga all'esenzione delle skill
- [x] `.github/copilot-instructions.md` — stessa convenzione, per parità su Copilot
- [x] `README.md` — cartella `briefs/` nella sezione "Cosa viene configurato" e flusso d'uso
- [x] `docs/bozza-manuale-installazione.md` — `briefs/` fra i risultati attesi del Passo 2

### Perimetro negativo
- Non toccherò: le skill `dr-scaffold*`, `dr-issues-to-plans`, `dr-verify-plan` e i prompt Copilot — la regola sta nelle istruzioni trasversali
- Non toccherò: `scaffolding-catalog.json`, `doc-versioning.instructions.md`, `sensitive-data.instructions.md`
- Non toccherò: `templates/`, nessun modello di brief
- Non toccherò: la logica delle funzioni di copia esistenti nell'installer
- Non toccherò: `docs/installazione-semplice.md` né le altre modifiche non committate già presenti in `README.md` e nella bozza
- Non toccherò: gli altri repository `dr-*`

## Fasi (formato atomico — obbligatorio)

### Fase 0: Decisioni residue
- **Stato**: [x]
- **Verifica passo**: tutte le decisioni sono scritte nella sezione precedente

### Fase 1: Creazione della cartella nell'installer
- **Stato**: [x]
- **Precondizione**: piano approvato
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: aggiungere `New-BriefsFolder` (crea `briefs/` solo se assente, non legge né scrive file al suo interno) e invocarla nel ramo `IsCore` accanto a `Copy-ScaffoldingCatalog`
- **Tool ammessi**: PowerShell (parser)
- **Verifica passo**: il parser analizza il file senza errori; la funzione non contiene nessun `Copy-Item`, `Set-Content` o `Remove-Item`
- **Esito**: parser PowerShell, 0 errori
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Prova della funzione in cartella temporanea
- **Stato**: [x]
- **Precondizione**: Fase 1 completata
- **File**: nessuno del repository
- **Operazione**: nessuna modifica al repository
- **Azione**: caricare la libreria, eseguire `New-BriefsFolder` su una cartella temporanea, scrivere un finto brief, rieseguire la funzione due volte, cancellare la cartella
- **Tool ammessi**: PowerShell
- **Verifica passo**: la cartella viene creata; il finto brief resta identico (hash) dopo le due riesecuzioni
- **Esito**: 2026-09-24 — `[OK]` alla prima esecuzione, `[SKIP]` alle due successive; hash del finto brief identico; cartella temporanea rimossa
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Regola nel plan-tracking
- **Stato**: [x]
- **Precondizione**: Fase 0 completata
- **File**: `.github/instructions/plan-tracking.instructions.md`
- **Operazione**: EDIT
- **Azione**: aggiungere la sezione "Piani da un brief" (lettura, piano obbligatorio anche sotto le 2 operazioni, approvazione obbligatoria, domande su lacune, precedenza sull'esenzione delle skill) e la riga del link sotto il titolo nel template; aggiornare la riga di versione
- **Tool ammessi**: nessuno
- **Verifica passo**: sezione presente, link documentato con percorso relativo, riga di versione aggiornata
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: CLAUDE.md e copilot-instructions.md
- **Stato**: [x]
- **Precondizione**: Fase 3 completata
- **File**: `CLAUDE.md`, `.github/copilot-instructions.md`
- **Operazione**: EDIT
- **Azione**: aggiungere in entrambi la convenzione `briefs/` con rimando a `plan-tracking.instructions.md`; in `CLAUDE.md` precisare che l'esenzione delle skill non vale quando l'argomento è un brief
- **Tool ammessi**: nessuno
- **Verifica passo**: i due testi dicono la stessa cosa; nessun costrutto esclusivo di un tool in `copilot-instructions.md`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Documentazione
- **Stato**: [x]
- **Precondizione**: Fasi 1-4 completate
- **File**: `README.md`, `docs/bozza-manuale-installazione.md`
- **Operazione**: EDIT
- **Azione**: citare `briefs/` fra ciò che l'installer crea e descrivere il flusso "scrivi il brief → indicalo all'agente → approvi il piano"
- **Tool ammessi**: nessuno
- **Verifica passo**: entrambi i documenti citano `briefs/`; le modifiche non committate preesistenti sono intatte
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: Verifica finale in contesto isolato
- **Stato**: [x]
- **Precondizione**: Fasi 1-5 completate
- **File**: tutti quelli di "Scope"
- **Operazione**: nessuna modifica — sola verifica
- **Azione**: `/dr-verify-plan`
- **Tool ammessi**: sola lettura
- **Verifica passo**: il revisore conferma ogni criterio
- **Esito**: 2026-09-24, sub-agente Explore: 7/7 file CORRISPONDE, criteri 1-7 SODDISFATTO, criterio 8 non valutabile prima della Fase 7
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7: Commit, push e aggiornamento di `dr-postman`
- **Stato**: [ ]
- **Precondizione**: Fase 6 superata; l'utente autorizza esplicitamente commit e push
- **File**: nessuno di questo repository oltre al commit; nell'host `E:\Davide\Progetti\dr-postman`
- **Operazione**: nessuna modifica manuale all'host — solo l'installer
- **Azione**: commit dei soli file di "Scope"; gate di push (nessun lint applicabile, repository di soli documenti e script: dichiararlo); push su `main`; in `dr-postman` eseguire l'installer del core con `-Update` (come fa `/dr-get-latest`). L'installer scarica la libreria dal raw di `main`: se la prima esecuzione mostra ancora il comportamento vecchio, è la cache del CDN (qualche minuto), non un errore
- **Tool ammessi**: git, PowerShell
- **Verifica passo**: in `dr-postman`: la cartella `briefs/` esiste; `.github/instructions/plan-tracking.instructions.md` contiene "Piani da un brief"; `.github/copilot-instructions.md` e la sezione `<!-- dr-guidelines -->` di `CLAUDE.md` citano `briefs/`; il manifest riporta il nuovo commit
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] L'installer del core crea `briefs/` vuota in radice se assente, e non tocca mai il suo contenuto
- [x] Rieseguire la creazione non altera un brief già scritto (prova con hash)
- [x] `plan-tracking.instructions.md` impone: brief indicato → piano obbligatorio → approvazione esplicita → domande sulle lacune; link al brief sotto il titolo
- [x] `CLAUDE.md` e `copilot-instructions.md` citano `briefs/` con lo stesso significato
- [x] Nessun costrutto esclusivo di un tool nei file condivisi
- [x] `doc-versioning.instructions.md` invariato
- [x] Nessun file fuori da "Scope" modificato
- [ ] `dr-postman` aggiornato con `-Update` riceve `briefs/`, la nuova regola e la sezione `CLAUDE.md` aggiornata
