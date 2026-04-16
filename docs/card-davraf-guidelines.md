# Card: davraf-guidelines

## Identificazione

- **Progetto:** davraf-guidelines
- **Solution:**
- **Workspace:**
- **Repository:** https://github.com/davraf-amuro/davraf-guidelines
- **Tipo Applicazione:** Repository di linee guida e configurazioni — usato come git submodule
- **Pattern Architetturale:** Configuration-as-Code / Guidelines-as-Code
- **Versione Corrente:** Da verificare con il team
- **Owner/Team:** davide 'davraf' raffagli
- **Contatto Supporto:** dev-support@unidata.it

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
| — | — | — | — | — | — |

## Servizi Esterni

| Tipo | Nome/Endpoint | Protocollo | Autenticazione | Scopo/Descrizione |
|------|---------------|------------|----------------|-------------------|
| CDN | `raw.githubusercontent.com` | HTTPS | — | Download `CreateNewSolution.ps1` tramite `irm` |
| VCS | GitHub | HTTPS/SSH | PAT / SSH key | Hosting repository e submodule |

## Configurazione e Hosting

- **Entrypoint:** `setup.ps1` (copia file di configurazione nel progetto host) · `CreateNewSolution.ps1` (bootstrap nuovo progetto)
- **Deploy:** Non applicabile — repository usato come submodule
- **URL Produzione:** —

## Documentazione API

- **OpenAPI/Swagger:** Non applicabile
- **Documentazione UI:** Non applicabile
- **Versioning API:** Non applicabile
- **Versioni Supportate:** —

---

*Revisione v1.0 — 2026-04-16 11:00 — claude-sonnet-4-6*
