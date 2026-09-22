# Card: dr-guidelines

## Identificazione

- **Progetto:** dr-guidelines — pacchetto **core** e catalogo della suite `dr-*`
- **Solution:** —
- **Workspace:** `dr-guidelines.code-workspace` nella cartella padre, con i 7 repo `dr-*` come cartelle sorelle
- **Repository:** https://github.com/davraf-amuro/dr-guidelines (Private)
- **Tipo Applicazione:** Repository di linee guida e configurazioni, distribuito come pacchetto installabile con `dr-guidelines-install.ps1`
- **Pattern Architetturale:** Configuration-as-Code / Guidelines-as-Code, catalogo JSON come fonte unica dei pacchetti
- **Versione Corrente:** Da verificare con il team (nessun tag di rilascio; gli host registrano il commit installato)
- **Owner/Team:** davide 'davraf' raffagli
- **Referente:** davide 'davraf' raffagli
- **Contatto Supporto:** d.raffagli@gmail.com · issue sul repository, via `/dr-file-feedback`

## Stack Tecnologico

- **Linguaggio Principale:** PowerShell 7, Markdown, JSON
- **Framework:** —
- **Target Framework:** —
- **SDK Version:** —

## Dipendenze

### Progetti Interni

- Nessuna dipendenza in ingresso: è il provider.
- Consumato dai 6 pacchetti di dominio (`dr-dotnet-backend`, `dr-minimalapi`, `dr-winsvc`, `dr-efdb`, `dr-fe`, `dr-devops`), i cui installer caricano `dr-guidelines-install-lib.ps1` e il catalogo da questo repo.

### Pacchetti Esterni

| Pacchetto | Versione | Scopo |
|-----------|----------|-------|
| `@fabriqa.ai/pdf-reader-mcp` | latest | MCP server per leggere PDF in Claude Code. Riferimento in `.mcp.example.json`; la config reale va in `.mcp.json`, ignorato da git |
| `gh` (GitHub CLI) | — | Prerequisito del bootstrap su repo Private |
| `git` | — | Prerequisito: l'installer clona i pacchetti |

## Database

| Connection String Key | Nome Database | Tipo | Server/Host | Username | Provider/ORM |
|-----------------------|---------------|------|-------------|----------|--------------|

## Servizi Esterni

| Tipo | Nome/Endpoint | Protocollo | Autenticazione | Scopo/Descrizione |
|------|---------------|------------|----------------|-------------------|
| API | GitHub REST API (`gh api repos/.../contents/...`) | HTTPS | Token di `gh auth login` (scope `repo`) | Download di installer, libreria e catalogo su repo Private |
| CDN | `raw.githubusercontent.com` | HTTPS | — | Stesso download via `irm`. Primo tentativo dell'installer; risponde `404` finché i repo sono Private |
| VCS | GitHub | HTTPS | Credential manager di git, o `gh auth setup-git` | `git clone --depth 1` del `main` di ogni pacchetto in `%TEMP%` |

## Configurazione e Hosting

- **Entrypoint:** `dr-guidelines-install.ps1` (core nella cartella corrente) · `-Update` (sovrascrive i file presenti) · `-Package <nome>` (pacchetto di dominio con dipendenze) · `-Global` / `-Global -Update` (sezione in `~/.claude/CLAUDE.md`) · `/dr-scaffold` (scaffolding guidato) · `/dr-install-global` (installazione globale guidata)
- **Ambiente Test:** non pubblicato
- **Ambiente Produzione:** non pubblicato

---

*Revisione v2.6 — 2026-09-16 16:09 — claude-opus-5*
