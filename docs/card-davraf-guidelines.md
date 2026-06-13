# Card: davraf-guidelines

## Identificazione

- **Progetto:** davraf-guidelines
- **Solution:** —
- **Workspace:** —
- **Repository:** https://github.com/davraf-amuro/davraf-guidelines
- **Tipo Applicazione:** Repository di linee guida e configurazioni — usato come git submodule
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
| `@fabriqa.ai/pdf-reader-mcp` | latest | MCP server per lettura PDF in Claude Code |

## Database

| Connection String Key | Nome Database | Tipo | Server/Host | Username | Provider/ORM |
|-----------------------|---------------|------|-------------|----------|--------------|

## Servizi Esterni

| Tipo | Nome/Endpoint | Protocollo | Autenticazione | Scopo/Descrizione |
|------|---------------|------------|----------------|-------------------|
| CDN | `raw.githubusercontent.com` | HTTPS | — | Download `CreateNewSolution.ps1` tramite `irm` |
| VCS | GitHub | HTTPS/SSH | PAT / SSH key | Hosting repository e submodule |

## Configurazione e Hosting

- **Entrypoint:** `setup.ps1` (copia file di configurazione nel progetto host) · `CreateNewSolution.ps1` (bootstrap nuovo progetto)
- **Ambiente Test:** non pubblicato
- **Ambiente Produzione:** non pubblicato

---

*Revisione v2.0 — 2026-06-13 15:30 — claude-sonnet-4-6*
