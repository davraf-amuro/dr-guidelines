# Piano: TODO/ fuori dal versionamento e documenti allineati ai repo Public
Data: 2026-09-24
Stato: IN CORSO

## Obiettivo
1. Togliere `TODO/01-revisione.md` dal repository (committato per errore in `e98848d`) senza cancellarlo dal disco, e impedire che succeda di nuovo.
2. Correggere i testi che affermano come stato attuale "i repo `dr-*` sono Private": dal 2026-09-21 tutti e 7 sono `PUBLIC` (verificato con `gh repo view` il 2026-09-24).

## Contesto
- `TODO/` è una cartella locale di appunti: non va committata. `.gitignore` non la esclude.
- Visibilità: `bozza-manuale-installazione.md` riga 187 registra già il passaggio a Public. Il resto della documentazione no.
- La forma `gh api` funziona con repo sia Public sia Private ed è quella provata sul campo. La forma breve `irm ... | iex` ora è applicabile ma non è ancora provata sul campo (bozza, riga 187).

## Decisioni
1. **`gh api` resta la forma di riferimento.** È verificata e continua a funzionare anche se i repo tornassero Private. `irm` si cita come alternativa, ora valida.
2. **Si corregge solo quello che afferma lo stato attuale.** Testi condizionali ("su repo Private…", "finché sono Private…", "se non sono pubblici…") descrivono un caso e restano. Restano anche le righe storiche o di stato delle prove.
3. **Il comportamento delle skill non cambia.** Il gate "gh autenticato → STOP" resta, perché `gh api` richiede comunque `gh` autenticato. Cambia solo la motivazione scritta accanto.
4. **Gli installer `.ps1` restano fuori scope.** Commenti e messaggi descrivono il ramo di ripiego su repo Private, e restano corretti.

## Scope

### File da modificare
- `dr-guidelines/.gitignore`: aggiungere `TODO/`
- `dr-guidelines`: `git rm --cached TODO/01-revisione.md`
- `dr-guidelines`: `README.md`, `docs/guida-nuova-soluzione.md`, `docs/onboarding.md`, `docs/card-dr-guidelines.md`, `docs/test-progetto-host.md`, `.github/instructions/readme-structure.instructions.md`, `.github/prompts/dr-scaffold.prompt.md`, `.github/prompts/dr-get-latest.prompt.md`, `.claude/skills/dr-scaffold/SKILL.md`, `.claude/skills/dr-scaffold-guidelines/SKILL.md`, più altre righe della ricerca che affermano lo stato attuale
- `README.md` dei 6 pacchetti di dominio (`dr-fe`, `dr-devops`, `dr-efdb`, `dr-minimalapi`, `dr-winsvc`, `dr-dotnet-backend`): la parentesi "(i repo sono Private)" e la frase su git che deve leggere i repo Private

### Perimetro negativo
- Nessun `*.ps1`
- Nessuna modifica alla logica delle skill o dei prompt (gate, passi, ordine)
- Nessuna occorrenza di `private` come parola chiave C#
- `.ai/`, piani e handoff storici

## Fasi
### Fase 1: TODO/ fuori dal versionamento
- **Stato**: [x] — `TODO/` in `.gitignore`, file tolto dall'indice e presente su disco. Nota: `.gitignore` viene copiato negli host, quindi `TODO/` sarà ignorata anche lì
- **Verifica passo**: `git ls-files TODO/` vuoto; il file esiste ancora su disco; `git check-ignore TODO/01-revisione.md` lo riconosce

### Fase 2: dr-guidelines, documenti e superfici agente
- **Stato**: [x] — 11 file corretti, più `docs/card-dr-guidelines.md` riga 48 ("finché i repo sono Private" affermava lo stato attuale)
- **Verifica passo**: una nuova ricerca di `Private` in `dr-guidelines` restituisce solo righe condizionali, storiche, `.ps1` o `.ai/`

### Fase 3: README dei 6 pacchetti di dominio
- **Stato**: [x] — 6 README aggiornati
- **Verifica passo**: nessun README di dominio afferma che i repo sono Private

### Fase 4: Gate di push e push
- **Stato**: [ ]
- **Verifica passo**: nessun target di lint applicabile, dichiarato. Parser PowerShell non necessario (nessun `.ps1` toccato). `catalog-guard` non necessario (catalogo non toccato). Commit e push nei 7 repo, CI di `dr-guidelines` verde

## Criteri di verifica finale
- [ ] `TODO/01-revisione.md` non tracciato, presente su disco, ignorato
- [ ] Nessun testo afferma che i repo sono oggi Private
- [ ] Nessun `.ps1` e nessuna logica di skill o prompt modificati
- [ ] Working tree pulito e 0 commit da pushare in tutti e 7 i repo
