# Piano: chiedere come inviare i log a Graylog (GELF) nei deploy in container
Data: 2026-11-27
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#36
Branch: `plan/issue-36-graylog-gelf` in dr-dotnet-backend e dr-devops (autonomia concessa dall'utente il 2026-11-27: piano, decisioni sulle opzioni consigliate, commit, PR, merge)

## Obiettivo
Quando un task riguarda il deploy in container o la sezione `logging` dello stack, l'agente chiede come inviare i log a Graylog — (a) solo driver `gelf` di Docker, (b) sink Serilog Graylog — con i limiti di ciascuna, e registra la scelta in un file del progetto host così non la richiede.

## Contesto
- `dr-dotnet-backend/.github/instructions/serilog-logging.instructions.md:173`: descrive solo il ripiego (driver GELF → testo, filtro per ricerca di testo) e rimanda a dr-devops §5.
- `dr-devops/.github/instructions/docker-swarm-compose.instructions.md` §5 (r.115-147): sezione `logging` GELF facoltativa, `${GELF_ADDRESS}` come IP parametrizzato (dato sensibile), rischi di deploy.
- Le issue indicano il core (`dr-guidelines`) come pacchetto, ma la regola Serilog vive in dr-dotnet-backend e quella dello stack in dr-devops: il core non cambia (`logging.instructions.md:39` cita già GELF come sink strutturato).
- Sink verificato (2026-11-27, ricerca web): `Serilog.Sinks.Graylog` (serilog-contrib), `WriteTo` con `"Name": "Graylog"`, `Args` `hostnameOrAddress`, `port`, `transportType` (`Udp` di default; `Http` esplicito). Opzioni complete: `GraylogSinkOptions` della versione installata.

## Decisioni (prese in autonomia, opzione consigliata)
1. Domanda e opzioni nella regola Serilog (dr-dotnet-backend), fonte unica; dr-devops §5 rimanda alla domanda prima di aggiungere la sezione `logging`.
2. Opzione (b) **sostituisce** il driver `gelf` (driver di default `json-file`): evita log doppi sul collector e riporta i log in Portainer / `docker service logs`. Tenere entrambi = doppioni, da dichiarare.
3. Scelta registrata in `.github/instructions/project-logging.instructions.md` del progetto host (file dell'host, nessun pacchetto lo distribuisce: l'installer non lo tocca; letto da Claude Code, Copilot e Codex). Prima di chiedere, l'agente lo cerca.
4. Sink all'indice `2` nel file di configurazione dell'ambiente che spedisce (es. `appsettings.Production.json`, chiavi per indice; corretto dopo la Verifica 1) (dopo `Console` 0 e `File` 1, che restano), indirizzo e porta da variabili d'ambiente (`SERILOG__WRITETO__2__ARGS__HOSTNAMEORADDRESS`): l'indirizzo del collector è dato sensibile, mai nel repo.

## Scope
- [x] `dr-dotnet-backend/.github/instructions/serilog-logging.instructions.md` — sezione "Log verso Graylog (GELF)": quando chiedere, opzioni (a)/(b) con limiti, dove registrare la scelta, configurazione di (b), checklist, footer
- [x] `dr-dotnet-backend/README.md` — una riga sul nuovo comportamento (se il README elenca le regole), footer
- [x] `dr-devops/.github/instructions/docker-swarm-compose.instructions.md` — §5: prima di aggiungere `logging` chiedi (rimando condizionale al manifest per dr-dotnet-backend), opzione (b) = niente driver `gelf`; checklist; footer

- [x] `dr-guidelines/scaffolding-catalog.json` — voci `suggests` dr-devops → dr-dotnet-backend e dr-dotnet-backend → dr-devops (regola cross-package-references; aggiunto dopo la Verifica 1, branch a parte nel core dopo il merge di #37)

### Perimetro negativo
- Nessuna altra modifica al core; nessun progetto host; nessun pacchetto NuGet aggiunto ai template

## Fasi
### Fase 1: dr-dotnet-backend (sessione)
- **Stato**: [x]
### Fase 2: dr-devops (sessione)
- **Stato**: [x]
### Fase 3: verifica finale opus, PR e merge per repo
- **Stato**: [x]

**Verifica 1 (2026-11-27, opus isolato): NON CONFORME**
- ⚠️ Divergenza: "Docker legge solo stdout" errato (moby `gelf.go`: stdout → 6, stderr → 3); la causa è il sink `Console` che scrive tutto su stdout. Corretto.
- ⚠️ Divergenza: "lascialo fuori dall'`appsettings.Development.json`" senza effetto (sovrapposizione per indice). Ora il sink va solo nel file dell'ambiente che spedisce, con chiavi per indice (`"WriteTo": { "2": {...} }`, `"Using": { "2": ... }`). **Provato** (console net11.0, Serilog.Settings.Configuration): Development → 2 sink, Production → 3 sink, i primi intatti.
- ⚠️ Divergenza: `transportType` e `port` obbligatori in JSON; con `Http` serve lo schema; chiavi = parametri di `Graylog(...)`. Corretto.
- ⚠️ Divergenza: manca la variabile nel blocco `environment:` del compose (trappola §3 di dr-devops). Aggiunta in entrambe le regole.
- ⚠️ Divergenza: rimandi fra pacchetti senza voce `suggests` nel catalogo (cross-package-references) e rimando di serilog → dr-devops senza ripiego. Ripiego aggiunto; catalogo in Scope.
- Minori: `Serilog.Sinks.Graylog` nella tabella NuGet come condizionale; campi `_Subject` col prefisso; dr-devops §5 apertura e §7 passo 4 allineati.

**Verifica 2 (2026-11-27, opus isolato): divergenze della Verifica 1 RISOLTE** (sovrapposizione per indice riprodotta anche col vero `GraylogSink` 3.1.1 e con l'override `SERILOG__WRITETO__2__...`; firma di `Graylog(...)` letta per riflessione). Nuovi riscontri, corretti subito sulla base delle evidenze della verifica (riletti, nessuna terza verifica):
- ⚠️ Divergenza: ricerca `_Subject:` errata — Graylog toglie il `_` iniziale (`GelfDecoder.java`) → `Subject:"..."`.
- ⚠️ Divergenza: variabile `SERILOG__WRITETO__2__...` in un ambiente senza l'indice 2 → crash all'avvio (riprodotto) → la variabile va solo nello stack dell'ambiente che spedisce; avviso sull'indirizzo vuoto/errato (log persi in silenzio, solo SelfLog) e controllo dopo il deploy.
- Minori: segnaposto `CHISSADOVE` al posto di `""` (sensitive-data); `Http` senza schema accettato (`UriBuilder`), schema obbligatorio solo per `https`; ripiego di dr-devops con registrazione della scelta; ora reale nei footer (corretti anche i footer del core e di dr-minimalapi/dr-winsvc scritti oggi con un'ora stimata).

## Criteri di verifica finale
- [x] La regola chiede (a)/(b) con limiti solo per deploy in container / sezione `logging`, e non richiede se la scelta è già registrata
- [x] Opzione (b) configurata da file (`appsettings.<Ambiente>.json`), coerente con indici e override per ambiente della regola Serilog; indirizzo da variabile d'ambiente
- [x] dr-devops §5 rimanda alla domanda e non contraddice l'opzione (b)
- [x] Nessun nome di pacchetto o chiave di configurazione non verificati
- [x] Footer aggiornati
