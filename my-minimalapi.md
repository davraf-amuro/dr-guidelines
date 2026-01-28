# Minimal API Template - .NET 10

La mia idea di progetto Minimal API basati su **.NET 10** e **C# 14.0** con standard di codice e architettura predefiniti.

### Struttura del progetto

```
YourProject/                             # cartella della solution o workspace
├── .github/
│   ├── copilot-instructions.md          # Istruzioni per Copilot
│   └── instructions/
│       └── (files).instructions.md
├── src/                                 # sottocartella per i progetti
│   └── YourProject.Api/                 # cartella di progetto
│       ├── Endpoints/                   # Minimal API endpoints
│       ├── Dto/                         # Data transfer objects
│       ├── Infrastructure/              # providers di servizi esterni, come database o client verso altre risorse
│       └── Program.cs
├── test/                                # sottocartella per i progetti di test
│   └── YourProject.Tests/
├── .editorconfig                        # Stile di codice
├── .gitignore                           # File ignorati da Git
├── .gitattributes                       # Line endings Git
├── Directory.Build.props                # Configurazione MSBuild
├── global.json                          # Versione .NET SDK
└── README.md                            # presentazione della solution

```

## 📐 Standard di Codice

### Convenzioni di Naming

- **Namespace**: `snake_case` per progetti (es. `minimal_api_template.api`)
- **Metodi async**: suffisso `Async`

### Best Practices

- Usa **primary constructors** per dependency injection
- Preferisci **async/await** per operazioni I/O
- Segui il pattern **minimal API** senza controller
- Usa **file-scoped namespaces** (C# 10+)
- Abilita **nullable reference types**

## 📚 Tecnologie Raccomandate

- **.NET 10.0** - Framework
- **Entity Framework Core 10** - ORM (opzionale)
- **Serilog** - Logging
- **Scalar** - API documentation (invece di Swagger)
- **Asp.Versioning.Mvc.ApiExplorer** - API versioning
- **ASP.NET Core Minimal API** - Web framework

### ❌ Cosa NON Usare

- ❌ MVC Controllers (usa Minimal API)
- ❌ Swagger UI (usa Scalar)
- ❌ IRepository pattern (EF Core DbContext è sufficiente)
- ❌ AutoMapper (usa extension methods manuali)

---

*versione 1.0 - Gennaio 2026*
