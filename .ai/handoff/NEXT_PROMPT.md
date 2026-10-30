Lavori sulla suite `dr-*` in `E:\Davide\Progetti\dr-guidelines-workspace\` (9 repo git: `dr-guidelines` core, `dr-dotnet-backend`, `dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`, `dr-ux-kitt`, `dr-ux-lcars`). `davraf-guidelines` è deprecato: non toccarlo. Rispondi in italiano.

Leggi prima: `dr-guidelines/CLAUDE.md`, `dr-guidelines/.github/copilot-instructions.md`, `dr-guidelines/.github/instructions/plan-tracking.instructions.md`, `dr-guidelines/.github/instructions/doc-versioning.instructions.md`, `dr-guidelines/.ai/handoff/HANDOFF.md`.

Regole chiave:
- Claude Code agente primario; Copilot e Codex best-effort
- Task con ≥ 2 operazioni → piano in `.ai/plans/<YYYY-MM-DD>-<slug>/plan.md`, approvazione esplicita prima di agire
- `.agents/skills/` e `AGENTS.md` si rigenerano con `pwsh ./scripts/sync-codex.ps1`, mai a mano
- Script `.ps1` solo ASCII
- Nessun `git push` senza richiesta esplicita dell'utente

Stato:
- Audit e correzioni della suite completati (piano `.ai/plans/2026-10-20-audit-suite-fix/plan.md`, `COMPLETATO`)
- Revisione docs/README/commenti e fix `$PSScriptRoot` committati
- Tutti i 9 repo pubblicati su `origin/main` il 2026-10-20
- 2026-10-29: piano `.ai/plans/2026-10-29-pending-handoff-e-issue-30/plan.md` — issue #30 (controllo fine riga nel Gate di Push, avviso dell'installer), footer a contatore minore, gate formale `dr-winsvc`, FAQ `gh`, `irm | iex` provata. Commit locali in `dr-guidelines` e `dr-winsvc`, **non pushati**

Problemi aperti:
1. Working tree di `dr-guidelines` non conforme al nuovo controllo fine riga (`.ps1` in LF, `plan.md` in CRLF): normalizzare con la procedura del Gate di Push prima della push
2. Push di `dr-guidelines` (chiude #30) e `dr-winsvc`: solo su richiesta dell'utente
3. `docs/installazione-semplice.md`: da provare con un utente non tecnico

Prossimo passo: esegui il controllo fine riga del Gate di Push (`.github/copilot-instructions.md`), proponi la normalizzazione, poi chiedi se fare push.
