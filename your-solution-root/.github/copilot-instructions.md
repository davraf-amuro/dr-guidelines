# Copilot Instructions

Questo progetto è un **Minimal API Template** basato su **.NET 10** e **C# 14.0**.

## 📚 Istruzioni Modulari

Per approfondire argomenti specifici, consulta:

- **[Minimal Api Architecture](instructions/minimal-api-architecture.instructions.md)** - Regole e pattern per lo sviluppo di Minimal API endpoints con versioning, routing e OpenAPI
- **[Database Provider](instructions/database-provider.instructions.md)** - Template e best practices per la creazione di provider infrastructure con EF Core

## 🏗️ Architettura Generale

### Tecnologie Utilizzate
- **.NET 10** con **C# 14.0**
- **Minimal APIs** per endpoint RESTful
- **API Versioning** (Asp.Versioning) con URL segment reader
- **Scalar** per documentazione API
- **Problem Details** per gestione errori standardizzata

### Struttura Progetto
```
src/
??? minimal-api-template.api/
    ??? Program.cs              (entry point e configurazione)
    ??? Endpoints/              (endpoint organizzati per dominio)
    ??? Infrastructure/         (provider, DbContext, entities)
```

### Pattern e Convenzioni

#### Endpoint
- Organizzati per dominio in classi statiche con metodi di estensione
- Pattern: `app.Map{Domain}Endpoints(apiVersionSet)`
- Ogni endpoint deve specificare la versione API nel group

#### Versioning
- Default version: v1
- Reader: `UrlSegmentApiVersionReader` (es: `/api/v1/resource`)
- Format: `'v'VVV` (es: v1, v2)

#### Configurazione
- OpenAPI abilitato solo in Development
- Scalar UI per documentazione interattiva
- HTTPS Redirection abilitato
- Problem Details per errori consistenti

## ✨ Best Practices

### Codice
- Usa **primary constructors** per dependency injection
- Preferisci **async/await** per operazioni I/O
- Segui il pattern **minimal API** senza controller

### Logging
- Usa structured logging con placeholder: `{PropertyName}`
- Livelli appropriati: Information, Warning, Error

### Naming
- Namespace: `minimal_api_template.api` (snake_case per progetti)
- Classi/Metodi: PascalCase
- Parametri/variabili: camelCase

---

*Ultimo aggiornamento il 2025-01-29 - Versione 1.4*

