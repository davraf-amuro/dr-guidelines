# Minimal API Template - .NET 10

Template per progetti Minimal API basati su **.NET 10** e **C# 14.0** con standard di codice e architettura predefiniti.

## 📋 Cosa Include Questo Template

Questo template fornisce:

- ✅ **GitHub Copilot Instructions** - Linee guida automatiche per l'AI
- ✅ **EditorConfig** - Standard di codice consistenti
- ✅ **Directory.Build.props** - Configurazione MSBuild centralizzata
- ✅ **GitIgnore e GitAttributes** - Configurazione Git ottimizzata
- ✅ **Global.json** - Versione .NET SDK bloccata

## 🚀 Come Usare Questo Template

### Setup Iniziale

1. **Copia il contenuto** di questa cartella nella root del tuo nuovo progetto Visual Studio
2. **Aggiorna le informazioni** in `Directory.Build.props`:
   - Modifica `<Product>` con il nome del tuo progetto
   - Aggiorna `<Copyright>` con l'anno corrente
3. **Verifica** che GitHub Copilot sia abilitato in Visual Studio
4. **Apri la solution** in Visual Studio 2022+

### Struttura Raccomandata

```
YourProject/
├── .github/
│   ├── copilot-instructions.md          # Istruzioni per Copilot
│   └── instructions/
│       ├── minimal-api-architecture.instructions.md
│       └── database-provider.instructions.md
├── src/
│   └── YourProject.Api/
│       ├── Endpoints/                   # Minimal API endpoints
│       ├── Infrastructure/              # Data access
│       ├── Dto/                         # Data transfer objects
│       └── Program.cs
├── test/
│   └── YourProject.Tests/
├── .editorconfig                        # Stile di codice
├── .gitignore                           # File ignorati da Git
├── .gitattributes                       # Line endings Git
├── Directory.Build.props                # Configurazione MSBuild
├── global.json                          # Versione .NET SDK
└── README.md                            # Questo file

```

## 🤖 GitHub Copilot

GitHub Copilot leggerà automaticamente le istruzioni in `.github/copilot-instructions.md` e seguirà le convenzioni definite.

### Istruzioni Modulari

Il template include istruzioni dettagliate per:

- **Minimal API Architecture** - Pattern per endpoint, versioning, routing
- **Database Provider** - Template per provider EF Core con filtri e proiezioni

Per aggiungere nuove istruzioni, crea file `.md` in `.github/instructions/` e referenziali nel file principale.

## 📐 Standard di Codice

### Convenzioni di Naming

- **Namespace**: `snake_case` per progetti (es. `minimal_api_template.api`)
- **Classi/Metodi**: `PascalCase`
- **Parametri/Variabili**: `camelCase`
- **Campi privati**: `_camelCase` (con underscore)
- **Interfacce**: `IPascalCase` (prefisso I)
- **Metodi async**: suffisso `Async`

### Best Practices

- Usa **primary constructors** per dependency injection
- Preferisci **async/await** per operazioni I/O
- Segui il pattern **minimal API** senza controller
- Usa **file-scoped namespaces** (C# 10+)
- Abilita **nullable reference types**

## 🔧 Configurazione

### .editorconfig

Definisce regole di formattazione e naming conventions. Visual Studio e Copilot seguiranno automaticamente queste regole.

### Directory.Build.props

Impostazioni comuni per tutti i progetti nella solution:
- Target framework: .NET 10
- Nullable reference types abilitati
- ImplicitUsings abilitati
- Generazione documentazione XML

### global.json

Blocca la versione .NET SDK per garantire build consistenti nel team.

## 📚 Tecnologie Raccomandate

- **.NET 10.0** - Framework
- **ASP.NET Core Minimal API** - Web framework
- **Entity Framework Core 10** - ORM (opzionale)
- **Serilog** - Logging
- **Scalar** - API documentation (invece di Swagger)
- **Asp.Versioning.Mvc.ApiExplorer** - API versioning

### ❌ Cosa NON Usare

- ❌ MVC Controllers (usa Minimal API)
- ❌ Swagger UI (usa Scalar)
- ❌ IRepository pattern (EF Core DbContext è sufficiente)
- ❌ AutoMapper (usa extension methods manuali)

## 🤝 Contribuire

Questo template è mantenuto internamente. Per suggerimenti o miglioramenti, contatta il team di sviluppo.

## 📄 Licenza

© 2025 Voisoft per Unidata spa. All rights reserved.

---

*Template versione 1.0 - Generato Gennaio 2025*
