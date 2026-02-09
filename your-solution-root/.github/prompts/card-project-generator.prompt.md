# Prompt: Card Project Generator (AI Agent)

Genera schede riassuntive per ogni progetto. Non inventare dati. Lascia vuoto se non trovi info.

## Output
- Crea/aggiorna docs/card-<nome_progetto>.md
- Se c'e una solution (.sln/.slnx), riferiscila nel campo Solution
- Se non c'e solution ma c'e .code-workspace, usa il campo Workspace

## Analisi (se presenti)
- .csproj, appsettings*.json, launchSettings.json
- Program.cs o entry point
- DbContext, provider/repository, using statements

## Template card
```markdown
# Card: [Nome Progetto]

## Identificazione
- **Progetto:**
- **Solution:** [NomeSolution.sln]
- **Workspace:** [NomeWorkspace.code-workspace]
- **Repository:** [URL senza branch]
- **Tipo Applicazione:**
- **Pattern Architetturale:**
- **Versione Corrente:**
- **Owner/Team:**
- **Contatto Supporto:**

## Stack Tecnologico
- **Linguaggio Principale:**
- **Framework:**
- **Target Framework:**
- **SDK Version:**

## Dipendenze

### Progetti Interni
- ...

### Pacchetti Esterni
| Pacchetto | Versione | Scopo |
|-----------|----------|-------|
| ... | ... | ... |

## Database
| Connection String Key | Nome Database | Tipo | Server/Host | Username | Provider/ORM |
|-----------------------|---------------|------|-------------|----------|--------------|
| ... | ... | ... | ... | ... | ... |

## Servizi Esterni
| Tipo | Nome/Endpoint | Protocollo | Autenticazione | Scopo/Descrizione |
|------|---------------|------------|----------------|-------------------|
| ... | ... | ... | ... | ... |

## Configurazione e Hosting
- **Entrypoint:** Program.cs o localhost[/path-ui]

## Documentazione API
- **OpenAPI/Swagger:**
- **Documentazione UI:**
- **Versioning API:**
- **Versioni Supportate:**

---
*Card generata il: yyyy-MM-dd | Versione template: 2.0 | LLM: GitHub Copilot*
```

## Regole
- Non inventare dati; campi senza info restano vuoti
- Tabelle senza dati: lascia solo header
- Info sensibili: indica solo il nome variabile, mai il valore
- Se molti progetti: una card per progetto + opzionale card-solution.md
- Risposta del prompt: indica solo le card generate, non riepilogare i dati

## ✅ Checklist Post-Generazione
- [ ] docs/ esiste e contiene le card
- [ ] Campi vuoti lasciati vuoti, niente dati inventati
- [ ] Tabelle compilate solo con dati reali
- [ ] Nessun segreto esposto
- [ ] Footer con data e LLM presente

*Template v1.1 - .NET 10 - Token-optimized for AI agents* - Last Update 2026-02-09 10:00
