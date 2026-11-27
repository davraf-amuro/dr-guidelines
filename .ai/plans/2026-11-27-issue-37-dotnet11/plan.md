# Piano: .NET 11 consigliato, versione non rigida, file .NET non imposti ai progetti esistenti
Data: 2026-11-27
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#37, davraf-amuro/dr-dotnet-backend#7, davraf-amuro/dr-dotnet-backend#9
Branch: `plan/issue-37-dotnet11` in ogni repo toccato (autonomia concessa dall'utente il 2026-11-27: piano, decisioni sulle opzioni consigliate, commit, PR, merge)

## Obiettivo
I nuovi progetti nascono su .NET 11 con versione letta da un solo punto (catalogo), un SDK più nuovo sul PC non blocca più i progetti (`global.json` con `latestMajor`), e su un progetto .NET esistente l'installer non impone `Directory.Build.props`/`global.json`.

## Contesto
- `dr-dotnet-backend/global.json`: `10.0.100` + `latestMinor` → con il solo SDK 11 installato nessun comando `dotnet` funziona (caso reale 2026-11-24).
- `dr-dotnet-backend/Directory.Build.props`: `net10.0`, `LangVersion 14.0`, segnaposto `YourCompany`/`YourProduct`, `EnforceCodeStyleInBuild` + `AnalysisLevel=latest` + `GenerateDocumentationFile` (dr-dotnet-backend#7: rompono il lint di un progetto esistente).
- Catalogo: `defaults.dotnetFramework = "net10.0"` esiste già, ma skill e prompt scrivono `--framework net10.0` a mano; etichette "(.NET 10)".
- Riferimenti a .NET 10 in 28 file di 6 repo (ricerca 2026-11-27): core (skill/prompt di scaffolding, `dr-create-launch-profiles`, `card-project-generator`, docs, README, catalogo), dr-dotnet-backend, dr-minimalapi, dr-winsvc, dr-efdb, dr-devops (immagini `sdk:10.0`/`aspnet:10.0`).
- Verifica sul PC: SDK 10.0.404 e 11.0.100; runtime 11.0.0; `net11.0` compila con `LangVersion 15`, `16` rifiutata (CS1617).
- .NET 11 è STS con supporto a 24 mesi (fine intorno a nov 2028, come .NET 10 LTS): dato della issue, da verificare in Fase 1.

## Decisioni (prese in autonomia, opzione consigliata o proposta della issue)
1. Default `net11.0`; fonte unica `defaults.dotnetFramework` del catalogo; skill/prompt leggono `<tfm>` da lì.
2. `global.json`: `"version": "11.0.100"`, `"rollForward": "latestMajor"` (minimo 11, accetta SDK più nuovi).
3. `LangVersion` tolta da `Directory.Build.props`: il default del compilatore segue il TFM (C# 15 su `net11.0`), un cambio di TFM non richiede di toccarla.
4. Segnaposto di assembly (`Authors`, `Company`, `Copyright`, `Product`) tolti: commento con l'esempio.
5. dr-dotnet-backend#7: sul progetto .NET esistente (nell'host c'è già un `*.csproj`/`*.sln`/`*.slnx`) i `rootFiles` mancanti si scrivono come `<file>.new` con avviso; campo di catalogo `existingProjectMarkers` per pacchetto (logica generica nella libreria). Le skill di scaffolding, che creano i progetti prima dell'install, rinominano i `.new` (progetto nuovo = adozione).
6. Testi ".NET 10" → ".NET 11" dove si parla della versione consigliata; formulazione per versione corrente dove possibile.

## Scope
### dr-guidelines (core) — sessione
- [x] `scaffolding-catalog.json` — `defaults.dotnetFramework = net11.0`, etichette, `existingProjectMarkers` su dr-dotnet-backend, `updatedAt`
- [x] `dr-guidelines-install-lib.ps1` — `Copy-PackageRootFiles`: progetto esistente → `.new` + avviso generico (rieseguire il lint del Gate di Push; testo .NET tolto dopo la Verifica 1)
- [x] skill `dr-scaffold`, `dr-scaffold-solution`, `dr-scaffold-project`, `dr-create-launch-profiles` + prompt `dr-scaffold`, `card-project-generator` — `<tfm>` dal catalogo, rinomina dei `.new` nello scaffolding
- [x] `docs/scaffolding-minimal-api.md`, `docs/scaffolding-windows-service.md`, `docs/bozza-manuale-installazione.md`, `README.md` — versione e comportamento sui progetti esistenti
- [x] `.agents/skills/` — `sync-codex.ps1`
- [x] `.claude/skills/dr-scaffold-guidelines/SKILL.md`, `.github/instructions/line-endings.instructions.md`, `docs/guida-nuova-soluzione.md` — progetto esistente: `.new` non rinominati, `normalize-eol.ps1` dopo l'install del core (aggiunti in Fase 4)
### dr-dotnet-backend — sub-agente
- [x] `global.json`, `Directory.Build.props` (Decisioni 2-4), `README.md` (i due file cambiano build e lint; comportamento `.new`), `.github/instructions/dotnet-project-type.instructions.md` (#9: esempio relativo, solution, più csproj, citazione dell'esito; .NET 11), `serilog-logging.instructions.md`, `.claude/skills/dr-audit-api/SKILL.md` (+ copia Codex se presente)
### dr-minimalapi, dr-winsvc, dr-efdb, dr-devops — sub-agenti
- [x] riferimenti a .NET 10 → .NET 11 nei file trovati dalla ricerca (istruzioni, prompt/card, README; immagini Docker in dr-devops)

- [x] `.github/workflows/ci.yml` — `dotnet-version: '11.0.x'` (aggiunto dopo la Verifica 1)

### Perimetro negativo
- Nessun progetto host esistente; nessuna modifica al Gate di Push del core (#33 chiuso); nessun cambio di logica a tre vie di `Copy-ProtectedFile`

## Fasi
### Fase 1: verifiche di fatto (sessione)
- **Stato**: [x]

**Esito Fase 1 (2026-11-27)**
- .NET 11: STS, rilascio 10 nov 2026, fine supporto **14 nov 2028** (policy ufficiale dotnet.microsoft.com/platform/support/policy/dotnet-core; blog "Announcing .NET 11"). Confermato.
- `global.json` sul PC (SDK 10.0.404 + 11.0.100): `10.0.100`+`latestMinor` → 10.0.404; `11.0.100`+`latestMajor` → 11.0.100; `10.0.100`+`latestMajor` → 11.0.100; `12.0.100`+`latestMajor` → errore (il minimo non si abbassa). Scelta `11.0.100`+`latestMajor` confermata.
- `net11.0`: `LangVersion` 15 valida, 16 rifiutata (CS1617) → default del compilatore = C# 15.
- **Azione**: data di fine supporto .NET 11 (fonte Microsoft); comportamento di `rollForward: latestMajor` con solo SDK 11 e con SDK 10+11 in un progetto di prova
### Fase 2: core (sessione, dopo il merge di #35)
- **Stato**: [x]

**Esito Fase 2** — catalogo (`net11.0`, etichette senza versione, prerequisito SDK 11+, `existingProjectMarkers`), libreria (`Test-DrExistingProject`, `Copy-PackageRootFiles` con `.new` + `[WARN]`), skill/prompt con `<tfm>` dal catalogo e passi 4.7-bis/7-bis di adozione, gate SDK 11+ e `latestMajor` in skill/prompt/docs, README (Q&A e nota progetto esistente). `card-project-generator.prompt.md`: BOM tolto dalla riscrittura (conforme a `.editorconfig`). Parse 5.1/7 = 0 errori, JSON valido.
### Fase 3: repo di dominio in parallelo (sub-agenti, un repo ciascuno)
- **Stato**: [x]

**Esito Fase 3** — PR unite: dr-dotnet-backend#11 (chiude #7 e #9: `global.json` 11.0.100 + `latestMajor`, `Directory.Build.props` `net11.0` senza `LangVersion` e segnaposto, istruzioni e README), dr-minimalapi#9, dr-winsvc#5, dr-efdb#6, dr-devops#5. Residuo voluto: `Asp.Versioning v10.0.0+` (versione della libreria, non del runtime). Prova nel sub-agente: `dotnet new web` → `net11.0`, build e `dotnet format --verify-no-changes` exit 0.
### Fase 4: prova end-to-end (sessione)
- **Stato**: [x]
- **Azione**: host di prova con progetto .NET esistente pulito → install dr-minimalapi → `Directory.Build.props.new`/`global.json.new`, lint invariato; scaffolding nuovo → file adottati, `net11.0`, build e `dotnet format --verify-no-changes` exit 0; `-Update` con `global.json` personalizzato → `.new`/`[SKIP]`, mai sovrascritto
**Esito Fase 4 (2026-11-27)** — libreria del branch, domini da `main` aggiornato:
- A, progetto esistente (`net10.0`, lint exit 0): install dr-minimalapi → `Directory.Build.props.new` + `global.json.new` + `[WARN]`, originali assenti. Lint dopo: exit 2 per `ENDOFLINE` (`.gitattributes`/`.editorconfig` del core su working tree CRLF, non i file .NET) → `normalize-eol.ps1` senza `-Path` → lint exit 0, diff solo fine riga. Da qui le aggiunte a `dr-scaffold-guidelines` e `line-endings`.
- B, scaffolding nuovo: `.new` adottati col passo 4.7-bis, SDK 11.0.100, TFM `net11.0`, build 0 avvisi/0 errori, lint exit 0.
- C, `-Update` di dr-dotnet-backend con `global.json` personalizzato: `[SKIP] global.json personalizzato`, file invariato.

### Fase 5: verifica finale opus, PR e merge per repo
- **Stato**: [x]

**Verifica 2 (2026-11-27, opus isolato): QUASI CONFORME** — divergenze della Verifica 1 tutte risolte (bug di profondità riprodotto e corretto su 5.1 e 7; progetto esistente, scaffolding nuovo e `-Update` riprodotti con esito atteso). Rimasti e corretti subito: `dr-audit-api` r.163 `C# 14` → `C# 12+` (footer v2.5 già lo dichiarava; PR dr-dotnet-backend#13), etichette "(.NET 11)" nei README di dr-minimalapi (#11) e dr-winsvc (#7); riga di Scope sull'avviso allineata. Fuori piano, segnalato: alcuni file dei domini in CRLF solo nel working tree locale (index LF).
**Verifica 1 (2026-11-27, opus isolato): NON CONFORME**
- ⚠️ Divergenza: `dr-scaffold-project` — gate `10.*` rimasto (r.20) e titolo "ramo senza solution" rovinato da una sostituzione su prefisso non riletta. Corretti; verifica post-modifica dei file scritti da script.
- ⚠️ Divergenza: `Test-DrExistingProject` — `@($sub, $depth + 1)` creava un array di 3 elementi: limite di profondità mai applicato. Corretto con oggetti `Dir`/`Depth`, costanti `DrMarkerScanDepth`/`DrMarkerSkipDirs` in testa (+ `.vs`, `packages`, `TestResults`), salto dei reparse point, `UnauthorizedAccessException` gestita. Provato su 5.1 e 7 (profondità 5 → falso, 4 → vero, `Bin` escluso).
- ⚠️ Divergenza: 4.7-bis / 7-bis adottavano i `.new` anche con `*.csproj` già esistenti agganciati. Ora solo se tutti i progetti sono nati nello scaffolding.
- ⚠️ Divergenza: progetto esistente con file `.cs` con BOM → lint `CHARSET` dopo l'install del core (`.editorconfig`), non risolto da `normalize-eol`. Aggiunti: lint di partenza e di confronto, proposta di `dotnet format` in scrittura con conferma (`dr-scaffold-guidelines`, prompt Sezione C 7-bis, guida).
- ⚠️ Divergenza: `docs/guida-nuova-soluzione.md` e `docs/bozza-manuale-installazione.md` senza il comportamento su progetto esistente. Aggiunto.
- Minori corretti: `[WARN]`/`[NEW]` senza testo .NET nella funzione generica; `<tfm>` definito nella Sezione B del prompt; `ci.yml` `11.0.x`; nei domini (PR dr-dotnet-backend#12, dr-minimalapi#10, dr-winsvc#6): etichette e prerequisito nel README di dr-dotnet-backend, `/dr-scaffold-project` tolto dall'adozione, commento delle tre voci in `Directory.Build.props`, `C# 12+` in `dr-audit-api`, `C# 15` nelle card, footer ripulito in dr-winsvc.

## Criteri di verifica finale
- [x] Nessun `net10.0` / "(.NET 10)" come default nei repo toccati (restano solo citazioni storiche)
- [x] `global.json` con `latestMajor`; `dotnet --version` funziona nel progetto con solo SDK 11
- [x] Progetto esistente: nessun `Directory.Build.props`/`global.json` imposto, `.new` + avviso; lint invariato
- [x] Scaffolding nuovo: file adottati, build e lint verdi su `net11.0`
- [x] `-Update` non sovrascrive un `global.json` personalizzato
- [x] dr-dotnet-backend#9 coperta in `dotnet-project-type.instructions.md`
- [x] Copie Codex allineate, footer aggiornati
