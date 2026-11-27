# Piano: Evitare i fine riga CRLF nei file scritti da installer e generatori su Windows
Data: 2026-11-03
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#34
Branch: `plan/issue-34-eol-installer-generatori` (approvato 2026-11-27)

## Obiettivo
Nessun file con attributo `eol=lf` esce in CRLF o misto dall'installer, dagli script della suite o dai generatori eseguiti seguendo le regole; il Gate di Push corregge in place senza cancellare file.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/34 (label `bug`)
- Problema: su Windows con `core.autocrlf=true` (default di Git for Windows) dopo install + scaffolding 28 file dell'host hanno working tree `w/crlf` o `w/mixed` con `attr eol=lf`. Il Gate di Push (#30) li rileva ma non li previene, e la sua procedura "cancella + `git checkout`" non vale per i file con modifiche in corso.

**Verifica sui file (2026-11-03)**
- `dr-guidelines-install-lib.ps1:155` — `git clone --quiet --depth 1` senza `-c core.autocrlf=false`: confermato.
- `Copy-Item` alle righe 186, 308, 326, 391, 517, 524, 577, 606: confermato (la issue ne cita 4, sono 8).
- `core.autocrlf=true` da `C:/Program Files/Git/etc/gitconfig` anche su questa macchina: confermato.
- Nessun `.gitattributes` in dr-dotnet-backend, dr-minimalapi, dr-efdb, dr-fe — e neppure in dr-winsvc, dr-devops, dr-ux-lcars, dr-ux-kitt (8 repo, la issue ne cita 4).
- L'installer porta già nell'host il `.gitattributes` del core (`* text=auto eol=lf`, `.ps1/.cmd/.bat/.sln` in CRLF) — `dr-guidelines-install-lib.ps1:549` — e controlla la concordanza con `.editorconfig` (righe 658-683).
- Altre scritture di testo dell'installer non citate dalla issue: `Merge-ClaudeSettings` riscrive `settings.json` con `ConvertTo-Json` (righe 644-648), il manifest esce da `ConvertTo-Json` + `` "`n" `` (riga 827) → probabile origine di `.ai/dr-guidelines-packages.json` in `w/mixed`. `Write-DrUtf8File` (righe 717-723) non normalizza. Ipotesi da provare (Fase 1).
- ⚠️ Discrepanza: la issue colloca "Verifica post-modifica" in `dev-cycle.instructions.md`; la sezione sta in `.github/copilot-instructions.md`. `dev-cycle.instructions.md` non ha una sezione con quel nome.
- `scripts/` contiene solo `sync-codex.ps1`, che l'installer non porta nell'host: oggi non esiste un meccanismo per portare script nell'host, va previsto (Fase 4).

**Consultazione** — `/dr-tech` (sub-agente in sola lettura):
- Cause della issue confermate. Il clone con `-c core.autocrlf=false -c core.eol=lf` basta per i cloni nuovi anche senza `.gitattributes` nei pacchetti; non copre i file *generati* dall'installer (`ConvertTo-Json`) → una funzione unica di scrittura testo che normalizza a LF.
- Alla copia: normalizzare secondo `git -C <host> check-attr eol`, default LF salvo `.ps1/.cmd/.bat/.sln`.
- `.gitattributes` nei repo pacchetto = igiene, non il fix; se si aggiunge, identico al core.
- `normalize-eol.ps1`: parametri `-Path` (default: file modificati/non tracciati da `git status --porcelain`), `-Check` (exit 1 se ci sono differenze); salta binari (`check-attr text` unset/binary, byte NUL nei primi 8 KB); conserva il BOM esistente; scrive con `WriteAllBytes`; lavora in place, quindi vale anche per file con modifiche in corso.
- Hook `PostToolUse`: sconsigliato come primo passo (latenza `pwsh` 0,3-1 s a ogni comando, rumore su file estranei, Copilot/Codex scoperti). Normalizzare a fine scaffolding e al Gate; hook da rivalutare se il problema si ripresenta.
- Gate: raccomandato blocco sull'**index** (`i/crlf` dove serve `eol=lf`), working tree solo avviso con `normalize-eol.ps1 -Check`. La regex compare in `copilot-instructions.md` e in `dr-promote-to/SKILL.md` righe 49-56: vanno cambiate insieme.

**Sovrapposizione con #33** — il piano `2026-11-03-issue-33-gate-lint-non-aggirabile` tocca le stesse sezioni (Gate di Push in `copilot-instructions.md`, passo 2 di `dr-promote-to`). Eseguire i due piani in serie, non in parallelo; chi parte per secondo rilegge le sezioni prima delle sue fasi.

## Decisioni (risolte dall'utente, 2026-11-27)

1. **Gate**: blocco **solo sull'index** (`i/crlf` dove serve `eol=lf`); working tree = avviso con `normalize-eol.ps1 -Check`.
2. **Hook `PostToolUse`**: **rimandato** → Fase 9 esclusa; la regola lo dichiara "rimandato".
3. **`.gitattributes` negli 8 repo di dominio**: **sì, issue collegate** → Fase 12 si esegue (conferma per ogni issue).
4. **`normalize-eol.ps1` nell'host**: **`scripts/` copiata dall'installer core**, aggiornata con `-Update`.

## Scope
### File da modificare
- [x] `dr-guidelines-install-lib.ps1` — clone con `-c core.autocrlf=false -c core.eol=lf`, scrittura testo normalizzata, normalizzazione alla copia, copia di `scripts/normalize-eol.ps1` nell'host
- [x] `scripts/normalize-eol.ps1` — CREATE: normalizzazione in place secondo `git check-attr eol`
- [x] `.github/instructions/line-endings.instructions.md` — CREATE: regola "dopo un generatore, normalizza"
- [x] `.github/copilot-instructions.md` — "Verifica post-modifica" richiama la regola; "Controllo fine riga" usa lo script al posto di cancella+checkout (e blocco su index se Decisione 1 lo conferma); footer
- [x] `.claude/skills/dr-promote-to/SKILL.md` — passo 2 allineato al Gate; footer
- [x] `.claude/skills/dr-scaffold-solution/SKILL.md` — script come ultimo passo prima della build; footer
- [x] `.claude/skills/dr-scaffold-project/SKILL.md` — idem; footer
- [x] `.github/prompts/dr-scaffold.prompt.md` — Sezioni A e B + checklist (da Fase 2)
- [x] `templates/global-claude.md` — riga del controllo fine riga allineata (da Fase 2)
- [x] `scaffolding-catalog.json` — core: `rootFiles: ["scripts/normalize-eol.ps1"]` (da Fase 2)
- [x] `README.md` — tabella istruzioni + "Cosa viene configurato" (da Fase 2)
- [x] `.agents/skills/` — rigenerato da `scripts/sync-codex.ps1`, mai a mano
- ~~`CHANGELOG.md`~~ — non esiste
- ~~`.claude/settings.json`~~ — Decisione 2 = rimandato

### Perimetro negativo
- Non toccherò: i repo di dominio (dr-dotnet-backend, dr-minimalapi, dr-efdb, dr-fe, dr-winsvc, dr-devops, dr-ux-lcars, dr-ux-kitt) — solo issue collegate se Decisione 3 lo chiede
- Non toccherò: `.gitattributes` e `.editorconfig` del core (già corretti)
- Non toccherò: la regola lint del Gate (scope di #33)
- Non toccherò: `AGENTS.md` e `.agents/skills/` a mano
- Non toccherò: progetti host esistenti (es. dr-partsbin): la correzione dei loro 28 file si fa lì con lo script, dopo il rilascio

## Fasi (formato atomico — obbligatorio)

Parallelismo: Fasi 1 e 2 sono letture; Fasi 3-4 (installer) e 5 (script) hanno file disgiunti ma 4 dipende da 5. Fasi 6-8 toccano file che si citano a vicenda → serie. Fase 10 (sync-codex) è generata da script → serie, dopo tutte le skill.

### Fase 1: Prova delle ipotesi sull'installer
- **Stato**: [x]

**Esito Fase 1 (2026-11-27)** — host di prova `git init` + `dr-guidelines-install.ps1 -Package dr-fe` (core come dipendenza), `core.autocrlf=true` di sistema, pwsh 7.6:

| File | `git ls-files --eol` | Causa |
|---|---|---|
| `.claude/skills/dr-audit-fe/SKILL.md` | `w/crlf` | clone di dr-fe (nessun `.gitattributes`) con `autocrlf=true` → `Copy-Item` (riga 391) |
| `.github/instructions/design-tokens.instructions.md` | `w/crlf` | idem → `Copy-GuidelineFile` (riga 186) |
| `.github/instructions/frontend-organization.instructions.md` | `w/crlf` | idem |
| `.ai/dr-guidelines-packages.json` | `w/mixed` | `ConvertTo-Json` emette CRLF (confermato su pwsh 7.6 **e** 5.1) + `` "`n" `` finale → `Update-DrManifest` riga 827 |

- File del core: tutti `w/lf` (il core ha `.gitattributes`: il suo `eol=` vince su `autocrlf`).
- `Merge-ClaudeSettings` (riga 644) usa lo stesso `ConvertTo-Json`: CRLF certo quando aggiunge voci (non riprodotto, scrive solo al secondo giro).
- `Write-DrUtf8File` per CLAUDE.md: contenuto già LF (sorgente LF + `` "`n" ``) → nessun problema oggi, ma non normalizza.
- Nessun pacchetto copia oggi file `.ps1/.cmd/.bat/.sln` nell'host: dopo il clone con `autocrlf=false` i file dei repo senza `.gitattributes` escono come nel blob (LF). Il primo `.ps1` copiato sarà `scripts/normalize-eol.ps1` dal core, che ha `*.ps1 eol=crlf` → CRLF al checkout.
- **Scelta implementativa Fase 3c**: invece di duplicare la logica nella libreria, a fine `Install-DrPackageContent` l'installer esegue la copia host di `scripts/normalize-eol.ps1` sui file scritti in quel giro (unica fonte della logica). I domini dipendono dal core → lo script c'è sempre; se manca (es. `-NoDependencies` su host senza core) → `[WARN]` e si prosegue.
- **Dipende da**: —
- **Modello**: sessione
- **Precondizione**: Git for Windows con `core.autocrlf=true` di sistema
- **File**: nessuno nel repo (cartella temporanea nella scratchpad)
- **Operazione**: nessuna (lettura/prova)
- **Azione**: in una cartella temporanea `git init` + installer core e un pacchetto di dominio (es. dr-fe); registra `git ls-files --eol` dopo `git add`; prova `ConvertTo-Json` su PowerShell 7 (e 5.1 se presente) per stabilire se emette CRLF. Annota nel piano quali file escono `w/crlf|w/mixed` e da quale riga dell'installer
- **Tool ammessi**: pwsh, git
- **Verifica passo**: elenco dei file colpiti con causa scritto in `plan.md` sotto "Esito Fase 1"
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 1: <cosa>` in plan.md, non procedere

### Fase 2: Mappa dei punti da allineare
- **Stato**: [x]

**Esito Fase 2 (2026-11-27, sub-agente sonnet)**
- Regex del Gate: `.github/copilot-instructions.md:86` (passi 90-95), `.claude/skills/dr-promote-to/SKILL.md:52` (passi 54-55), **`templates/global-claude.md:71`** (in prosa, con "elimina + `git checkout`") → file in più nello Scope.
- `git add --renormalize`: solo `copilot-instructions.md:93`. Gli altri `git checkout --` trovati sono Rollback di scaffolding, fuori scope.
- Scaffolding: `dr-scaffold-solution` passo 4.8 (r.205-213) + tabella Fase 5 (r.229-234); `dr-scaffold-project` dopo r.111/116 e r.125/128; **`.github/prompts/dr-scaffold.prompt.md`** A.8 (r.217-222), B (r.272-273), checklist r.380 → file in più. Nessun prompt per `dr-promote-to`/`dr-scaffold-solution`/`dr-scaffold-project`.
- Distribuzione di `scripts/`: precedente nel catalogo, `rootFiles: ["scripts/lcars-contrast.mjs"]` → per il core si usa **`rootFiles` in `scaffolding-catalog.json`** (passa da `Copy-PackageRootFiles` → `Copy-ProtectedFile`, `-Update` a tre vie già gestito). Nessun nuovo codice di copia.
- Istruzioni: `Copy-InstructionsAndPrompts` copia tutta `.github/instructions/` → `line-endings.instructions.md` arriva da sola.
- Indici: `README.md` tabella istruzioni (r.235-249) e "Cosa viene configurato" (r.156-168) → file in più. `CHANGELOG.md` non esiste.
- **Dipende da**: —
- **Modello**: sonnet — ricerca testuale
- **Precondizione**: —
- **File**: nessuno
- **Operazione**: nessuna (lettura)
- **Azione**: cerca in `.github/`, `.claude/skills/`, `docs/`, `README.md` ogni occorrenza della regex del controllo fine riga, di "cancella" + `git checkout` per il fine riga e dei passi finali di scaffolding (`dotnet format`, `dotnet build`); elenca file e righe in `plan.md` e aggiorna lo Scope se ne emergono altri
- **Tool ammessi**: Grep, Read
- **Verifica passo**: elenco file:riga in `plan.md`; Scope aggiornato o "nessun file in più"
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 2: <cosa>` in plan.md, non procedere

### Fase 3: Installer — clone e scrittura testo in LF
- **Stato**: [x]
- **Dipende da**: 1
- **Modello**: sessione — installer
- **Precondizione**: esito Fase 1 registrato
- **File**: `dr-guidelines-install-lib.ps1`
- **Operazione**: EDIT
- **Azione**: (a) riga 155: `git clone -c core.autocrlf=false -c core.eol=lf --quiet --depth 1 ...`; (b) `Write-DrUtf8File` e la riscrittura di `settings.json` (righe 644-648) normalizzano il contenuto a LF prima di scrivere; (c) dopo ogni `Copy-Item` di file di testo, normalizzazione secondo `git -C <host> check-attr eol` (default LF, CRLF per `.ps1/.cmd/.bat/.sln`), saltando i binari
- **Tool ammessi**: Edit
- **Verifica passo**: ripetendo la prova della Fase 1 con l'installer modificato, `git ls-files --eol | Select-String 'w/(crlf|mixed)\s+attr/[^\t]*eol=lf'` non restituisce righe
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 3: <cosa>` in plan.md, non procedere

### Fase 4: Script `normalize-eol.ps1`
- **Stato**: [x]
- **Dipende da**: —
- **Modello**: sessione
- **Precondizione**: `scripts/normalize-eol.ps1` non esiste
- **File**: `scripts/normalize-eol.ps1`
- **Operazione**: CREATE
- **Azione**: script con `-Path` (default: file modificati e non tracciati da `git status --porcelain`), `-Check` (solo report, exit 1 se ci sono differenze), `-Quiet`; per ogni file salta i binari (`git check-attr text`/`binary`, byte NUL nei primi 8 KB), legge `git check-attr eol` (unspecified → LF, salvo `.ps1/.cmd/.bat/.sln`), converte `\r\n|\r|\n` al fine riga voluto conservando il BOM, scrive con `WriteAllBytes` in place. Il file stesso è `.ps1` → CRLF
- **Tool ammessi**: Write, pwsh
- **Verifica passo**: su un file `.md` misto con modifiche in corso, `-Check` esce 1, la normalizzazione lo porta a `w/lf`, il diff di contenuto (`git diff --ignore-cr-at-eol`) resta identico; su un `.png` nessuna modifica; seconda esecuzione `-Check` esce 0
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 4: <cosa>` in plan.md, non procedere

### Fase 5: Installer porta lo script nell'host
- **Stato**: [x]
- **Dipende da**: 3, 4
- **Modello**: sessione — installer
- **Precondizione**: Decisione aperta 4 risolta
- **File**: `dr-guidelines-install-lib.ps1` (ed eventualmente il catalogo/manifest dei file core)
- **Operazione**: EDIT
- **Azione**: aggiungi `scripts/normalize-eol.ps1` ai file che l'installer core copia nell'host secondo la Decisione 4, con lo stesso trattamento di aggiornamento (`-Update`) degli altri file core
- **Tool ammessi**: Edit
- **Verifica passo**: installazione di prova in cartella temporanea → `scripts/normalize-eol.ps1` presente nell'host; `-Update` lo aggiorna
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 5: <cosa>` in plan.md, non procedere

### Fase 6: Regola `line-endings.instructions.md`
- **Stato**: [x]
- **Dipende da**: 4
- **Modello**: sessione — testo di regole (consultare `/dr-prompt-engineer` sul testo)
- **Precondizione**: script della Fase 4 verificato
- **File**: `.github/instructions/line-endings.instructions.md`
- **Operazione**: CREATE
- **Azione**: regola breve: dopo ogni generatore o comando che scrive file (`dotnet new`, `dotnet ef`, `dotnet add`, `dotnet sln`, `npm create`, scritture da PowerShell) esegui `scripts/normalize-eol.ps1 -Path <file toccati>`; senza percorsi lo script prende i file modificati e non tracciati. Limite dichiarato: su Copilot e Codex si esegue a mano; su Claude Code, hook solo se Decisione 2 = adesso. Footer secondo `doc-versioning.instructions.md`
- **Tool ammessi**: Write
- **Verifica passo**: file presente, comando citato coincide con i parametri dello script, limite Copilot/Codex dichiarato
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 6: <cosa>` in plan.md, non procedere

### Fase 7: Gate di Push e Verifica post-modifica
- **Stato**: [x]
- **Dipende da**: 6
- **Modello**: sessione
- **Precondizione**: Decisione 1 risolta; se il piano #33 è già stato eseguito, rileggi le sezioni prima di modificarle
- **File**: `.github/copilot-instructions.md`
- **Operazione**: EDIT
- **Azione**: (a) "Verifica post-modifica": rimando a `line-endings.instructions.md` per i file scritti da generatori; (b) "Controllo fine riga": sostituisci il punto 3 (cancella + `git checkout`) con `scripts/normalize-eol.ps1`, che vale anche per i file con modifiche in corso; se Decisione 1 = index, la regex blocca su `i/crlf ... eol=lf` e il working tree diventa avviso con `-Check`; (c) footer v2.8
- **Tool ammessi**: Edit
- **Verifica passo**: nessuna occorrenza residua della procedura "elimina il file e ripristinalo con `git checkout`"; regex coerente con la Decisione 1
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 7: <cosa>` in plan.md, non procedere

### Fase 8: Skill e prompt allineati
- **Stato**: [x]
- **Dipende da**: 2, 7
- **Modello**: sonnet — modifiche testuali date dalla Fase 7
- **Precondizione**: Fase 7 completata
- **File**: `.claude/skills/dr-promote-to/SKILL.md`, `.claude/skills/dr-scaffold-solution/SKILL.md`, `.claude/skills/dr-scaffold-project/SKILL.md`, prompt Copilot equivalenti trovati in Fase 2
- **Operazione**: EDIT
- **Azione**: `dr-promote-to` passo 2 con la stessa regex e procedura della Fase 7; `dr-scaffold-solution` e `dr-scaffold-project` eseguono `scripts/normalize-eol.ps1` come ultimo passo dopo `dotnet format` e prima di `dotnet build`; footer di ogni file con riferimento a #34
- **Tool ammessi**: Edit
- **Verifica passo**: regex identica in `copilot-instructions.md` e `dr-promote-to`; passo dello script presente nelle due skill di scaffolding e nei prompt equivalenti
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 8: <cosa>` in plan.md, non procedere

### Fase 9: Hook `PostToolUse` (condizionale — solo se Decisione 2 = adesso)
- **Stato**: [-] esclusa: Decisione 2 = rimandato
- **Dipende da**: 4, 5
- **Modello**: sessione — permessi/settings
- **Precondizione**: Decisione 2 = adesso
- **File**: `.claude/settings.json` (del pacchetto core, fuso nell'host da `Merge-ClaudeSettings`)
- **Operazione**: EDIT
- **Azione**: hook `PostToolUse` con matcher `Bash|PowerShell` che lancia `scripts/normalize-eol.ps1 -Quiet` solo se lo script esiste; verifica che `Merge-ClaudeSettings` fonda anche la chiave `hooks` (oggi dichiara di non toccarla, riga 590): se no, adeguala in `dr-guidelines-install-lib.ps1`
- **Tool ammessi**: Edit
- **Verifica passo**: in un host di prova, dopo `dotnet new globaljson` lanciato da Claude Code, `global.json` è `w/lf` senza intervento manuale
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 9: <cosa>` in plan.md, non procedere

### Fase 10: Rigenera la copia Codex
- **Stato**: [x]
- **Dipende da**: 8
- **Modello**: haiku — comando singolo
- **Precondizione**: tutte le skill modificate
- **File**: `.agents/skills/`, `AGENTS.md` (generati)
- **Operazione**: EDIT (generato)
- **Azione**: esegui `scripts/sync-codex.ps1`
- **Tool ammessi**: pwsh
- **Verifica passo**: `git status` mostra le copie Codex delle skill modificate aggiornate, nessun altro file inatteso
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 10: <cosa>` in plan.md, non procedere

### Fase 11: Prova end-to-end dei criteri della issue
- **Stato**: [x]

**Esito Fase 11 (2026-11-27)** — host `git init`, `core.autocrlf=true`, install core + dr-dotnet-backend + dr-minimalapi + dr-efdb + dr-fe con la libreria del branch (core clonato da `main` con sovrapposti `scripts/normalize-eol.ps1` e catalogo del branch: non ancora pubblicati). Poi `dotnet new sln/web`, `dotnet sln add`, `dotnet add package` ×2, `dotnet build`, `dotnet ef migrations add InitialCreate`, `dotnet format`.
- Dopo i generatori, prima della regola: **7** righe fuori norma (file scritti da `dotnet`); file dell'installer tutti in norma.
- `scripts/normalize-eol.ps1` → exit 0; Gate working tree: **0 righe**; Gate index: **0 righe**; `-Check` exit 0. Migrazione `InitialCreate` generata.
- Limite della prova: core da `main` + sovrapposizione, non dal branch pubblicato; Windows PowerShell 5.1 provato su installer `-Update` (Fase 3), non su questa sequenza.
- **Dipende da**: 3, 5, 8 (e 9 se eseguita)
- **Modello**: sessione
- **Precondizione**: Windows con `core.autocrlf=true`
- **File**: nessuno nel repo (cartella temporanea)
- **Operazione**: nessuna (prova)
- **Azione**: riproduci i passi della issue: nuovo repo, install core + dr-dotnet-backend, dr-minimalapi, dr-efdb, dr-fe dal branch del piano; scaffolding .NET 10 seguendo le skill; `dotnet ef migrations add InitialCreate`; normalizzazione secondo la regola; `git add`; controllo del Gate
- **Tool ammessi**: pwsh, git, dotnet
- **Verifica passo**: `git ls-files --eol | Select-String 'w/(crlf|mixed)\s+attr/[^\t]*eol=lf'` → nessuna riga
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 11: <cosa>` in plan.md, non procedere

### Fase 12: Issue collegate sui repo di dominio (condizionale — solo se Decisione 3 = sì)
- **Stato**: [x]

**Esito Fase 12 (2026-11-27)** — testo confermato dall'utente una volta per tutte e 8; nessun duplicato trovato prima:
dr-dotnet-backend#8, dr-minimalapi#7, dr-efdb#4, dr-fe#6, dr-winsvc#3, dr-devops#3, dr-ux-lcars#1, dr-ux-kitt#1 (tutte `davraf-amuro/<repo>`).
- **Dipende da**: 11
- **Modello**: sessione
- **Precondizione**: Decisione 3 = sì; conferma dell'utente prima di ogni issue
- **File**: nessuno (GitHub)
- **Operazione**: scrittura su servizio esterno
- **Azione**: `/dr-file-feedback` per ciascuno degli 8 repo: aggiungere `.gitattributes` identico al core, con link a #34
- **Tool ammessi**: `/dr-file-feedback`
- **Verifica passo**: URL delle issue aperte annotati in `plan.md`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 12: <cosa>` in plan.md, non procedere

### Fase 13: Verifica finale in contesto isolato
- **Stato**: [x]

**Verifica 2 (2026-11-27, opus isolato): CONFORME** — tutte le divergenze della Verifica 1 RISOLTE (riprodotte su 5.1 e 7), nessun file fuori perimetro, tutti i criteri SODDISFATTI. Violazioni minori segnalate e corrette subito dopo: commento di `Register-DrWrittenFile`, percorso dello script centralizzato in `$Script:DrEolScript` (lib), `updatedAt` del catalogo → 2026-11-27; messaggio `[WARN]` precisato ("core non installato o da aggiornare"). Riparse 5.1/7 senza errori, install di prova pulita.
NON VERIFICABILE accettato: comportamento sotto ISE (corretto dal codice, non automatizzabile).
Fuori Scope, da valutare a parte: `README.md:83` e `docs/guida-nuova-soluzione.md:172` descrivono il flusso fermandosi a `dotnet format`; `<file>.ps1.new` esce in LF; `-Check` con soli percorsi inesistenti esce 0.

**Verifica 1 (2026-11-27, opus isolato): NON CONFORME**
- ⚠️ Divergenza: in `dr-scaffold-solution` (4.6 commit prima di 4.7 install) i file di `dotnet new` restano `w/crlf` ma non modificati per git → `normalize-eol.ps1` senza `-Path` non li vede, `-Check` falso pulito. Correzione: senza `-Path` lo script prende anche i file tracciati che `git ls-files --eol` segnala fuori norma.
- ⚠️ Divergenza: PS 5.1 fuori da un repo git → `git rev-parse 2>$null` con `ErrorActionPreference=Stop` lancia NativeCommandError. Correzione: chiamate git con `Continue` locale.
- ⚠️ Divergenza: virgola nel percorso dell'host → `Invoke-DrEolNormalize` non normalizza nulla senza avviso. Correzione: elenco passato con `-ListFile` (un percorso per riga), niente virgole.
- ⚠️ Divergenza: host PowerShell non standard (ISE) → motore scelto da `$PSHOME`, non da `Get-Process`.
- ⚠️ Divergenza: footer `README.md` senza ora (readme-structure); `Get-RepoRelativePath` senza commento; soglie `100`/`8000` non centralizzate.
- Note minori recepite: `dr-promote-to` ripete il controllo dell'index dopo il commit; frase imprecisa su "prossimo `git add`" in copilot-instructions; `global-claude.md` precisa "se installato dal core"; ramo Frontend di `dr-scaffold-project` col passo dello script; regola cita anche `powershell`.
- **Dipende da**: tutte le precedenti eseguite
- **Modello**: opus
- **Precondizione**: tutte le fasi eseguite `[x]` o condizionali escluse con motivo
- **File**: `plan.md`
- **Operazione**: EDIT
- **Azione**: verifica finale di `plan-tracking.instructions.md`, Fase 4 punto 4 — su Claude Code `/dr-verify-plan`; su Copilot/Codex nuova chat con solo `plan.md`, file di Scope e diff
- **Tool ammessi**: `/dr-verify-plan`
- **Verifica passo**: esito "conforme" registrato, `Stato: COMPLETATO`
- **Su divergenza**: STOP — scrivi `⚠️ Divergenza Fase 13: <cosa>` in plan.md, non procedere

## Criteri di verifica finale
- [x] Installazione su Windows con `core.autocrlf=true` → `git ls-files --eol` senza righe `w/crlf|w/mixed` su `attr eol=lf` (Fase 3)
- [x] Stesso risultato dopo `dotnet ef migrations add` e `dotnet add package` seguendo la regola (Fase 11)
- [x] `scripts/normalize-eol.ps1` normalizza in place file con modifiche in corso senza cambiarne il contenuto e salta i binari
- [x] Nessuna occorrenza residua della procedura "cancella + `git checkout`" in regole, skill e prompt
- [x] Regex del Gate identica in `copilot-instructions.md` e `dr-promote-to`, coerente con la Decisione 1
- [x] Limite Copilot/Codex dichiarato nella regola
- [x] Hook presente e funzionante solo se Decisione 2 = adesso; altrimenti dichiarato "rimandato" nella regola
- [x] `.agents/skills/` rigenerato con `sync-codex.ps1`
- [x] Footer aggiornati sui file modificati
