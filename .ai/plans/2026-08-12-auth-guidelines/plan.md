# Piano — Linea guida autenticazione nei pacchetti dr-*

**Stato:** IN CORSO
**Data:** 2026-08-12
**Slug:** `2026-08-12-auth-guidelines`
**Modello:** claude-opus-5

---

## Obiettivo

Colmare il buco emerso in sessione: i pacchetti `dr-*` non contengono nessuna linea guida sull'autenticazione di **utenti umani**. L'unica riga esistente (`minimal-api-architecture.instructions.md:16`) cita `SimpleAuthenticationTools` in versione API Key, adatta a chiamate servizio-a-servizio ma non a un'applicazione con login, profilo e cambio password.

Conseguenza osservata: a un prompt che chiedeva esplicitamente una login, l'agente ha proposto ASP.NET Identity + JWT — opzione corretta come mestiere ma **non prevista da nessuna guideline**, quindi non riproducibile e diversa a ogni progetto.

## Motivazione

Senza regola scritta, ogni progetto con login riceve uno schema improvvisato dal modello. Con la regola, la scelta è deterministica e documentata.

---

## Decisioni prese con l'utente

| # | Decisione | Motivazione |
|---|---|---|
| 1 | Base = **ASP.NET Identity** | Copre registrazione, login, profilo, cambio password, reset e lockout senza codice a mano. `/manage/info` gestisce email e password: sono esattamente le maschere richieste |
| 2 | **Cookie `HttpOnly`** per frontend browser same-origin | Nessun token da custodire nel FE, non leggibile da JavaScript, logout immediato |
| 3 | **Bearer opachi** (`AddBearerToken`) per client non-browser | L'utente ha dichiarato che vuole un'app Android in futuro |
| 4 | Cookie e bearer **coesistono** | `MapIdentityApi<TUser>()` espone `/login?useCookies=true` (cookie) e `/login` (bearer) dagli stessi endpoint, sulla stessa anagrafica. Nessuna migrazione futura |
| 5 | **JWT sconsigliato** per utenti umani | Nessuna revoca prima della scadenza: cambio password o logout non invalidano il token emesso |
| 6 | `SimpleAuthenticationTools` (API Key) resta, ma **circoscritto** | Vale solo per API senza utenti umani, chiamate servizio-a-servizio |
| 7 | Nessun pacchetto `dr-auth` nuovo | L'utente ha chiesto una "correzione alle dr-*": si interviene sui pacchetti esistenti |
| 8 | La regola copre anche il **rilascio in container** | L'utente rilascia su container dietro `nginx-proxy`. Nessun file del workspace nomina Data Protection o ForwardedHeaders: senza queste due regole l'auth si rompe in produzione in modo silenzioso |

### Le due rotture silenziose in container

| # | Causa | Sintomo |
|---|---|---|
| 1 | Portachiavi **Data Protection** non persistito. Cookie Identity e token opachi di `AddBearerToken` sono cifrati con quelle chiavi; il default le scrive dentro il filesystem del container | Ricreazione del container → chiavi nuove → tutti gli utenti sloggati a ogni deploy. Con `replicas > 1` ogni replica ha il suo portachiavi → 401 intermittenti, diagnosticati a lungo come bug applicativo |
| 2 | **TLS terminato sul reverse proxy**: l'app riceve `http` e conclude che la connessione non è sicura | Cookie `Secure` non emesso, redirect con schema sbagliato. Trappola Docker: `UseForwardedHeaders` di default si fida solo del loopback, mentre il proxy arriva dall'IP di un altro container → intestazioni ignorate senza errore visibile finché non si configurano `KnownNetworks`/`KnownProxies` |

---

## Scope

### File da modificare

| # | Repo | File | Intervento |
|---|---|---|---|
| 1 | `dr-minimalapi` | `.github/instructions/minimal-api-architecture.instructions.md` | Riscrittura riga 16; nuovo punto nel gate "Raccolta informazioni iniziale"; nuova sezione "Autenticazione" con sottosezione "Rilascio in container"; riga in "Vietato" |
| 2 | `dr-fe` | `.github/instructions/frontend-organization.instructions.md` | Nuova "Regola 7 — Autenticazione lato frontend" |
| 3 | `dr-devops` | `.github/instructions/docker-swarm-compose.instructions.md` | Nuova sezione "6. Chiavi Data Protection"; rinumerazione della sezione successiva |
| 4 | `dr-guidelines` | `docs/bozza-manuale-installazione.md` | Chiusura della domanda #1 in "Domande emerse"; bump footer |

### Perimetro negativo — cosa NON si tocca

- `dr-winsvc`, `dr-efdb`, `dr-dotnet-backend`: nessun contenuto auth pertinente
- `dr-devops`: gli altri due file (`gitlab-ci-cd`, `portainer-swarm-stack`)
- `scaffolding-catalog.json`: nessun nuovo pacchetto, nessuna nuova tipologia di progetto
- `docs/test-progetto-host.md`: fuori scope
- Le skill `dr-scaffold*`: leggono le instructions, non le duplicano
- Nessun codice applicativo: solo file di istruzione markdown
- Nessun `git push`: i commit si propongono, la push si chiede a parte

---

## Vincoli

| Vincolo | Come viene rispettato |
|---|---|
| **Compatibilità duale Claude Code / GitHub Copilot** | I file `.github/instructions/*.md` sono soggetti alla regola. Si usa solo markdown neutro: tabelle, liste, titoli. Nessun `$ARGUMENTS`, nessun riferimento a sub-agenti, `AskUserQuestion` o `EnterPlanMode`. Dove serve una domanda all'utente, si scrive "chiedi all'utente" in prosa — istruzione eseguibile da entrambi gli agenti |
| **Gate di push — lint** | Modifiche a soli file markdown in repo senza `.csproj` né `package.json`: nessun comando lint applicabile. Da dichiarare esplicitamente al momento della push |
| **Tre repository distinti** | `dr-minimalapi`, `dr-fe` e `dr-guidelines` sono repo separati: tre commit distinti, ciascuno nel proprio repo |
| **Versionamento** | `docs/bozza-manuale-installazione.md` segue `doc-versioning.instructions.md` (+0.1). I file `.github/instructions/*.md` seguono il footer già presente nel file, se c'è |

---

## Fasi

### [x] Fase 1 — `dr-minimalapi`: regola auth lato API

File: `dr-minimalapi/.github/instructions/minimal-api-architecture.instructions.md`

1. [ ] Sostituire la riga 16 con un rimando alla nuova sezione, mantenendo il principio "nessun pattern auth di default"
2. [ ] Aggiungere al gate "Raccolta informazioni iniziale" un punto sull'autenticazione, accanto a quello su Serilog: chiedere se il progetto prevede utenti umani con login
3. [ ] Aggiungere la sezione "Autenticazione" con la matrice di scelta:
   - utenti umani → ASP.NET Identity; cookie per browser same-origin, bearer opachi per client non-browser; nota sulla coesistenza via `MapIdentityApi`
   - nessun utente umano, solo servizio-a-servizio → `SimpleAuthenticationTools` (API Key)
   - auth non richiesta → non proporla
4. [ ] Aggiungere la sottosezione "Rilascio in container": portachiavi Data Protection persistito e condiviso (`PersistKeysToDbContext` default, `PersistKeysToFileSystem` su volume alternativa, sempre con `SetApplicationName`); `UseForwardedHeaders` come primo middleware con `KnownNetworks`/`KnownProxies` configurati per la rete Docker; rimando a `database-startup-resilience.instructions.md`
5. [ ] Aggiungere in "Vietato": `AddJwtBearer` per utenti umani, salvo richiesta esplicita e motivata (nessuna revoca prima della scadenza)
6. [ ] Rileggere il file e verificare che nessuna sezione preesistente sia stata alterata

### [x] Fase 2 — `dr-fe`: regola auth lato frontend

File: `dr-fe/.github/instructions/frontend-organization.instructions.md`

1. [ ] Aggiungere la sezione "Autenticazione lato frontend" con:
   - obbligo di **chiedere** all'utente se il frontend prevede una login, quando non è già dichiarato
   - regola di propagazione: la login non si implementa nel FE — utenti, password e sessioni stanno nell'API. Risposta affermativa → il progetto API deve adottare uno schema utenti (rimando alla sezione di `minimal-api-architecture`)
   - cookie: configurare il client HTTP con l'invio delle credenziali; nessun token da custodire
   - bearer: token mai in `localStorage` quando è evitabile; storage in memoria + refresh
   - route guard e stato utente: dove collocarli nella struttura già descritta dal file
2. [ ] Rileggere il file e verificare la coerenza con la struttura cartelle già documentata

### [x] Fase 3 — `dr-devops`: portachiavi lato stack

File: `dr-devops/.github/instructions/docker-swarm-compose.instructions.md`

1. [ ] Inserire la sezione "6. Chiavi Data Protection (servizi con autenticazione)" prima di "Adattare per un nuovo progetto"
2. [ ] Rinumerare "Adattare per un nuovo progetto" da 6 a 7
3. [ ] Aggiungere una voce alla checklist post-modifica in coda al file
4. [ ] Rileggere e verificare la coerenza della numerazione

### [x] Fase 4 — `dr-guidelines`: aggiornare la bozza del manuale

File: `dr-guidelines/docs/bozza-manuale-installazione.md`

1. [ ] Chiudere la domanda #1 in "Domande emerse": da aperta a risolta, con il rimando ai due file modificati
2. [ ] Bump footer a v1.3 con data e ora correnti

### [ ] Fase 5 — Commit

1. [ ] `git status` nei quattro repo, per non includere modifiche estranee
2. [ ] Un commit per repo, messaggio in Conventional Commits
3. [ ] **Nessuna push senza richiesta esplicita dell'utente**

---

## Criteri di verifica

| # | Criterio | Come si verifica |
|---|---|---|
| 1 | La riga 16 di `minimal-api-architecture` non cita più `SimpleAuthenticationTools` come unica opzione | Rilettura del file |
| 2 | Esiste una sezione "Autenticazione" con i tre rami (utenti umani / servizio-a-servizio / nessuna auth) | Rilettura del file |
| 3 | Il gate "Raccolta informazioni iniziale" contiene il punto sull'autenticazione | Rilettura del file |
| 4 | `AddJwtBearer` per utenti umani compare in "Vietato" con la motivazione | Rilettura del file |
| 5 | La sottosezione "Rilascio in container" copre Data Protection e ForwardedHeaders, con la nota su `KnownProxies` | Rilettura del file |
| 6 | `frontend-organization` contiene la Regola 7 e la regola di propagazione all'API | Rilettura del file |
| 7 | `docker-swarm-compose` ha la sezione 6 sul portachiavi e la numerazione successiva coerente | Rilettura del file |
| 8 | Nessun file usa sintassi esclusiva di Claude Code | Ricerca di `$ARGUMENTS`, `AskUserQuestion`, `EnterPlanMode`, `sub-agente` nei tre file di istruzione: zero occorrenze |
| 9 | La domanda #1 della bozza risulta risolta e il footer è a v1.3 | Rilettura del file |
| 10 | Nessun file fuori dal perimetro dichiarato è stato modificato | `git status` nei quattro repo |

---

*Piano creato il 2026-08-12 — claude-opus-5*
