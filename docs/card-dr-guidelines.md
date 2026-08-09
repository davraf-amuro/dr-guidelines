# Card: dr-guidelines

## Identificazione

- **Progetto:** dr-guidelines — pacchetto **core** della suite `dr-*`
- **Solution:** —
- **Workspace:** `E:\Davide\Progetti\dr-guidelines-workspace\` (7 repo `dr-*` come cartelle sorelle)
- **Repository:** https://github.com/davraf-amuro/dr-guidelines (Private)
- **Tipo Applicazione:** Repository di linee guida e configurazioni — distribuito come pacchetto autoinstallante via `install.ps1`
- **Pattern Architetturale:** Configuration-as-Code / Guidelines-as-Code
- **Versione Corrente:** Da verificare con il team
- **Owner/Team:** davide 'davraf' raffagli
- **Referente:** davide 'davraf' raffagli
- **Contatto Supporto:** d.raffagli@gmail.com

## Stack Tecnologico

- **Linguaggio Principale:** PowerShell, Markdown
- **Framework:** —
- **Target Framework:** —
- **SDK Version:** —

## Dipendenze

### Progetti Interni

- Nessuna (è il progetto provider, non il consumatore)

### Pacchetti Esterni

| Pacchetto | Versione | Scopo |
|-----------|----------|-------|
| `@fabriqa.ai/pdf-reader-mcp` | latest | MCP server per lettura PDF in Claude Code (riferimento committato in `.mcp.example.json`; la config reale va in `.mcp.json`, in `.gitignore`) |

## Database

| Connection String Key | Nome Database | Tipo | Server/Host | Username | Provider/ORM |
|-----------------------|---------------|------|-------------|----------|--------------|

## Servizi Esterni

| Tipo | Nome/Endpoint | Protocollo | Autenticazione | Scopo/Descrizione |
|------|---------------|------------|----------------|-------------------|
| CDN | `raw.githubusercontent.com` | HTTPS | — | Download di `install.ps1`/`install-lib.ps1` tramite `irm` (richiede repo Public) |
| VCS | GitHub | HTTPS/SSH | PAT / SSH key | Hosting dei 7 repo `dr-*`; `git clone --depth 1` eseguito dall'installer |

## Configurazione e Hosting

- **Entrypoint:** `install.ps1` (installa il pacchetto core nel progetto host) · `install.ps1 -Update` (aggiorna i file già presenti) · `install.ps1 -Global` / `-Global -Update` (scrive la sezione linee guida in `~/.claude/CLAUDE.md`) · `/dr-scaffold` (scaffolding guidato di un progetto nuovo, nessuno script) · `/dr-install-global` (installazione globale guidata)
- **Ambiente Test:** non pubblicato
- **Ambiente Produzione:** non pubblicato

---

*Revisione v2.4 — 2026-08-09 10:20 — claude-opus-5*
