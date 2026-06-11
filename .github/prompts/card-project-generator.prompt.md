---
agent: 'agent'
description: 'Genera schede riassuntive per ogni progetto nella solution'
tools: ['search/codebase']
---

# Prompt: Card Project Generator (AI Agent)

Genera schede riassuntive per ogni progetto. Non inventare dati. Lascia vuoto se non trovi info.

## Output

Per ogni progetto genera **due card**:

| Card | File | Dati sensibili | Committata |
|------|------|----------------|------------|
| Card standard | `docs/card-<nome_progetto>.md` | No — solo nomi variabili | Sì |
| Wiki card operativa | `docs/card-<nome_progetto>-wiki.md` | Sì — valori reali | No (gitignore) |

- Se c'e una solution (``.sln``/``.slnx``), riferiscila nel campo Solution
- Se non c'e solution ma c'e ``.code-workspace``, usa il campo Workspace

## Rilevamento tipo di progetto

Prima di generare la card standard, rileva il tipo del progetto e usa il template dedicato:

| Segnale nel codice | Tipo rilevato | Template card standard | Template wiki card |
|--------------------|---------------|------------------------|--------------------|
| ``Workers/*.cs`` presente | Windows Service (.NET Worker Service) | ``.github/prompts/card-worker-service.prompt.md`` | ``.github/prompts/card-wiki-generator.prompt.md`` |
| ``Endpoints/*.cs`` presente | Minimal API (.NET 10) | ``.github/prompts/card-minimal-api.prompt.md`` | ``.github/prompts/card-wiki-generator.prompt.md`` |
| ``package.json`` presente (senza ``.csproj``) | Frontend SPA/SSR | Usa template generico, sezione Stack da ``package.json`` | ``.github/prompts/card-wiki-generator.prompt.md`` |
| Nessuno dei precedenti | Tipo non rilevato | Usa template generico sotto | ``.github/prompts/card-wiki-generator.prompt.md`` |

Per ogni progetto:
1. **Genera card standard** — usa il template specifico. Non usare il template generico se esiste uno dedicato.
2. **Genera wiki card** — usa sempre ``.github/prompts/card-wiki-generator.prompt.md`` indipendentemente dal tipo.

## Analisi (se presenti)
- ``.csproj``, ``appsettings*.json``, ``launchSettings.json``
- ``Program.cs`` o entry point
- ``DbContext``, provider/repository, using statements

## Template generico (fallback)

Usato solo se il tipo non corrisponde a nessun template dedicato.

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
- **Contatto Supporto:** [Da compilare]

## Stack Tecnologico
- **Linguaggio Principale:**
- **Framework:**
- **Target Framework:**
- **SDK Version:**

## Dipendenze

### Progetti Interni
-

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
- **Deploy:** [locale | Docker | Swarm Portainer | ...]
- **URL Produzione:** [se Swarm Portainer: ricava porta da docker-compose_swarm.yaml]

---
*Revisione v1.0 - {YYYY-MM-DD HH:MM} - {modello-llm}*
```

## Regole
- Non inventare dati; campi senza info restano vuoti
- Tabelle senza dati: lascia solo header
- Card standard: indica solo il nome variabile, mai il valore reale
- Wiki card: riporta i valori reali da tutti i file config — leggi ``.github/prompts/card-wiki-generator.prompt.md``
- Se molti progetti: una card per progetto + opzionale ``card-solution.md``
- Risposta del prompt: indica solo le card generate, non riepilogare i dati

## Aggiungere una nuova tipologia

Per ogni nuovo tipo di progetto:
1. Crea ``.github/prompts/card-<tipo>.prompt.md`` con le sezioni specifiche
2. Aggiungi una riga alla tabella "Rilevamento tipo" sopra

## Checklist Post-Generazione
- [ ] Tipo rilevato correttamente, template dedicato usato se disponibile
- [ ] ``docs/`` esiste e contiene le card standard
- [ ] ``docs/`` esiste e contiene le wiki card (``*-wiki.md``)
- [ ] Campi vuoti lasciati vuoti, niente dati inventati
- [ ] Card standard: nessun segreto esposto
- [ ] Wiki card: valori reali compilati, header sensibile presente
- [ ] ``docs/*-wiki.md`` è in ``.gitignore``
- [ ] Footer con data e LLM presente in entrambe le card

*Template v2.1 - .NET 10 - Token-optimized for AI agents* - Last Update 2026-06-11 - claude-sonnet-4-6
