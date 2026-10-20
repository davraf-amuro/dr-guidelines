# Progetto

`dr-guidelines` — pacchetto core della suite `dr-*`: istruzioni, prompt e skill per Claude Code (agente primario), GitHub Copilot e Codex (best-effort), installabili con PowerShell.

- Repo: `davraf-amuro/dr-guidelines`
- Workspace: `E:\Davide\Progetti\dr-guidelines-workspace\` — 9 repo: `dr-guidelines`, `dr-dotnet-backend`, `dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`, `dr-ux-kitt`, `dr-ux-lcars`
- `davraf-guidelines`: deprecato, fuori perimetro

---

# Obiettivo

Audit e correzione della suite `dr-*` (regole, istruzioni, skill, installer, compatibilità Codex), poi revisione di documentazione, README e commenti degli script.

---

# Stato corrente

- Piano `.ai/plans/2026-10-20-audit-suite-fix/plan.md`: `Stato: COMPLETATO`, verificato da sub-agente indipendente
- Revisione docs/README/commenti: completata e committata in tutti i 9 repo
- Bug `$PSScriptRoot` nel messaggio di ripiego degli installer: corretto in tutti i 9 repo
- Tutti i 9 repo pubblicati su `origin/main` il 2026-10-20 (core fino a `335b113`, più il commit di questo handoff)
- Working tree pulito in tutti i 9 repo
- Nessun piano `IN CORSO` in `.ai/plans/`

---

# Componenti completati

- Regola "Claude Code agente primario, Copilot/Codex best-effort" in `CLAUDE.md`, `templates/global-claude.md`, `~/.claude/CLAUDE.md`
- Soglia piano ≥ 2 operazioni con definizione di "operazione" (`plan-tracking.instructions.md` v1.9)
- Conferma di una riga per skill irreversibili invocate da frase
- Rimandi condizionali al manifest nelle istruzioni condivise; formato footer unico
- Skill: rollback con `git clean -nd` + conferma, `*.slnx`, lint prima del commit in `dr-promote-to`, catalogo `.ai/dr-scaffolding-catalog.json`
- `scripts/sync-codex.ps1`: genera `.agents/skills/` e `AGENTS.md` da `.claude/skills/` e `CLAUDE.md`; `-Check` in CI
- Installer: manifest aggiornato solo a prima installazione o `-Update`, errori bloccanti, `-WithMcp`, `-ForceRemoteLib`, `.gitignore` host senza voci solo-core, copia `.agents/skills`
- Catalogo: `suggests`, `conflictsWith` kitt↔lcars, frasi `intentMap`
- CI: `permissions: contents: read`, parse PowerShell, JSON, `sync-codex -Check`
- Satelliti: `dr-efdb` (logging sensibile solo Development, niente `ex.Message`), `dr-minimalapi` (Serilog obbligatorio), `dr-winsvc`, `dr-dotnet-backend`, `dr-fe`, `dr-ux-*`, `dr-devops`
- Revisione di `README.md`, 9 documenti in `docs/`, 8 README satellite, commenti di 11 script `.ps1`

---

# Componenti in lavorazione

Nessuno

---

# Componenti mancanti

- Release con tag e checksum per l'installazione `irm | iex` (fuori scope dichiarato)
- Rinomina dei token di `design-tokens` (fuori scope: romperebbe kitt e lcars)
- `input-validation.instructions.md` del core ancora specifica .NET
- Permessi distribuiti in `.claude/settings.json` (fuori scope)
- Installazione di `AGENTS.md` negli host (limite dichiarato)

---

# File modificati

Sessione 2026-10-20, commit in `dr-guidelines` da `7d0b6fe` a `335b113`:

- `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md` — regola agente primario, piano a fonte unica, tabella skill
- `.github/instructions/*.instructions.md` — rimandi condizionali, `.vscode/mcp.json`, footer
- `templates/global-claude.md` — allineato a regole e nomi `dr-*`
- `.claude/skills/*/SKILL.md`, `.agents/skills/*/SKILL.md` — correzioni skill; copie Codex generate
- `scripts/sync-codex.ps1`, `templates/codex-skill-preamble.md`, `templates/codex-agents-preamble.md` — nuovi
- `dr-guidelines-install.ps1`, `dr-guidelines-install-lib.ps1` — fix installer, commenti, messaggio `$PSScriptRoot`
- `scaffolding-catalog.json`, `.github/workflows/ci.yml` — catalogo e CI
- `README.md`, `docs/*.md` — revisione
- `.ai/plans/2026-10-20-audit-suite-fix/plan.md` — piano
- `.ai/handoff/*.md` — questo handoff

Satelliti: `README.md`, `<repo>-install.ps1` (commenti + `$PSScriptRoot`), istruzioni di dominio (fase 7 dell'audit).

Fuori repo:
- `C:\Users\draff\.claude\CLAUDE.md` — migrato al formato con titolo e sentinel; backup `CLAUDE.md.bak-2026-10-20`
- `dr-guidelines.code-workspace` — 9 cartelle, senza `davraf-guidelines`

---

# Decisioni progettuali

Vedi `.ai/handoff/DECISIONI.md`.

---

# Problemi aperti

- **Limitazione** — il core ha `suggests` (dr-minimalapi, dr-dotnet-backend): 2 righe `[sugg]` a ogni installazione, anche su host non .NET
- **Limitazione** — `AGENTS.md` non installato negli host
- **Attività incompleta** — numerazione footer: `doc-versioning` prescrive +0.1, i file usano contatore minore (v3.24 → v3.25). Decisione utente mancante
- **Attività incompleta** — `docs/scaffolding-windows-service.md`: domande 1-3 del gate non fissate da istruzioni, marcate "Da verificare". Decidere se `dr-winsvc` ha un gate formale
- **Attività incompleta** — `README.md` FAQ "Non sono un programmatore": dice che `gh` non serve, ma `/dr-scaffold` lo richiede
- **Attività incompleta** — forma `irm | iex` dichiarata "non provata sul campo" in `docs/installazione-semplice.md`
- **Limitazione** — `dr-guidelines-install-lib.ps1`, `dr-guidelines-install.ps1`, `scripts/sync-codex.ps1`, installer kitt/lcars: LF su disco, `.gitattributes` impone CRLF al checkout (warning git, nessun effetto funzionale osservato)

---

# TODO

1. Controllare l'esito della CI su GitHub dopo il push del 2026-10-20
2. Aggiungere a `README.md` (FAQ) la nota: `gh` autenticato richiesto da `/dr-scaffold`
3. Decidere e applicare lo schema di numerazione footer (regola o file)
4. Decidere gate formale per `dr-winsvc` e aggiornare `docs/scaffolding-windows-service.md`
5. Provare sul campo `irm | iex` e aggiornare `docs/installazione-semplice.md`

---

# Validazione

- Build: non applicabile (nessun progetto compilabile)
- Test: smoke test installer su host temporaneo (prima installazione, riesecuzione, `-Update`) — superato
- Lint: nessun comando di lint applicabile (repo di documenti e script PowerShell), dichiarato prima del push; parse di tutti i `.ps1` — 0 errori; JSON validi; YAML CI valido; `sync-codex.ps1 -Check` — exit 0; script `.ps1` solo ASCII
- CI su GitHub dopo il push: Sconosciuto

---

# Rischi

- CI non ancora osservata dopo il push: eventuale fallimento non noto
- `~/.claude/CLAUDE.md`: modifiche manuali dentro il blocco sentinel si perdono al prossimo `-Global -Update`

---

# Prossimo passo consigliato

Controllare l'esito della CI di `davraf-amuro/dr-guidelines` con `gh run list --repo davraf-amuro/dr-guidelines --limit 3`.

---

# Informazioni mancanti

- Schema di numerazione footer preferito dall'utente
- Esito della CI dopo il push
