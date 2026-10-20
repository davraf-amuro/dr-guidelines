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
- Tutti i 9 repo pubblicati su `origin/main` il 2026-10-20; working tree pulito

Problemi aperti:
1. Esito CI dopo il push: non verificato
2. `README.md` FAQ "Non sono un programmatore": manca la nota che `/dr-scaffold` richiede `gh` autenticato
3. Numerazione footer: `doc-versioning` dice +0.1, i file usano contatore minore (v3.24 → v3.25) — chiedere all'utente quale schema
4. `docs/scaffolding-windows-service.md`: domande 1-3 del gate "Da verificare" — chiedere se `dr-winsvc` deve avere un gate formale
5. Forma `irm | iex` non provata sul campo

Prossimo passo: esegui `gh run list --repo davraf-amuro/dr-guidelines --limit 3` e riporta l'esito della CI; se fallita, leggi il log con `gh run view <id> --log-failed` e proponi la correzione.
