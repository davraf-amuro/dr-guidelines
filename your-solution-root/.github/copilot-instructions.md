# Copilot Instructions (AI Agent)

Progetto: Minimal API Template su .NET 10 e C# 14.

## Istruzioni modulari
- Minimal API rules: instructions/minimal-api-architecture.instructions.md
- Database provider rules: instructions/database-provider.instructions.md

## Stack e architettura
- Minimal APIs + Asp.Versioning (UrlSegmentApiVersionReader)
- Scalar per documentazione, ProblemDetails per errori
- Struttura base: src/<project>/Program.cs, Endpoints/, Infrastructure/

## Convenzioni essenziali
- Endpoint in extension methods: app.Map{Domain}Endpoints(versionSet)
- Versioning URL: /api/v{version}/...
- OpenAPI in Development, Scalar UI
- Primary constructors, async/await per I/O
- Logging strutturato con placeholder
- Naming: namespace snake_case, classi PascalCase, variabili camelCase

## ✅ Checklist Post-Generazione
- [ ] Ho seguito le istruzioni modulari pertinenti
- [ ] Endpoint creati come extension methods e mappati in Program.cs
- [ ] Versioning URL segment configurato correttamente
- [ ] OpenAPI + Scalar coerenti con le regole del progetto
- [ ] Logging strutturato e async/await usati dove serve

*Template v1.1 - .NET 10 - Token-optimized for AI agents* - Last Update 2026-02-09 10:00

