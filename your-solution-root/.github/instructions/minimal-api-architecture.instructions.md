# Design Guidelines - Minimal Api csharp

Linee guida di progettazione specifiche per progetti Minimal Api scritti in .Net 10 chsarp. Queste regole devono essere seguite quando si sviluppa o estende l'applicazione.

## Framework e Tecnologie

### Stack Tecnologico

- **.NET 10.0** - Target framework.
- **ASP.NET Core Minimal API** - Web framework (NO Controllers)
- **Entity Framework Core 10** - ORM, chiedere se serve prima di scaricare il pacchetto
- **Serilog** - Logging
- **SimpleAuthenticationTools** - API Key authentication, chiedere se serve prima di scaricare il pacchetto
- **Tinyhelpers.AspNetCore** - supporto per l'uso di ProblemDetails, installa sempre il pacchetto.
- **Scalar** - API documentation (invece di Swagger UI)
- **Asp.Versioning.Mvc.ApiExplorer** - API versioning support obbligatorio per scalar

### ❌ Cosa NON Usare

- ❌ **MVC Controllers** - Usa Minimal API
- ❌ **Swagger UI** - Usa Scalar
- ❌ **IRepository pattern** - EF Core DbContext è sufficiente
- ❌ **AutoMapper** - Usa extension methods manuali
- ❌ **MediatR** - Non necessario per la complessità attuale

---

## 📑 Indice delle Regole

Questo documento contiene 9 regole fondamentali per lo sviluppo di Minimal API:

1. **[REGOLA 1: Endpoint sempre in Extension Methods](#-regola-1-endpoint-sempre-in-extension-methods)** - Organizzazione degli endpoint in classi statiche
2. **[REGOLA 2: Formato URL Standardizzato](#-regola-2-formato-url-standardizzato-obbligatorio)** - Pattern obbligatorio `api/v{version:apiVersion}/{gruppo}`
3. **[REGOLA 3: Usa Route Groups](#-regola-3-usa-route-groups)** - Configurazione comune per gruppi di endpoint
4. **[REGOLA 4: Configurazione standard del versioning](#-regola-4-configurazione-standard-del-versioning)** - Setup API versioning con URL segment reader
5. **[REGOLA 5: Dependency Injection nei Parametri](#-regola-5-dependency-injection-nei-parametri)** - Parametri espliciti vs AsParameters
6. **[REGOLA 6: Metadata OpenAPI Completi](#-regola-6-metadata-openapi-completi)** - Documenta tutti gli endpoint
7. **[REGOLA 7: Registrazione in Program.cs](#-regola-7-registrazione-in-programcs)** - Chiamata agli extension methods
8. **[REGOLA 8: Trasformatore OpenAPI](#-regola-8-trasformatore-openapi-con-informazioni-di-progetto)** - Informazioni del progetto nella documentazione
9. **[REGOLA 9: Endpoint GET con database provider](#-regola-9-endpoint-get-che-usa-un-database-provider)** - Pattern completo per endpoint con EF Core

---

## Architettura del Progetto

### Struttura delle Cartelle

```
SolutionFolder/
├── docs/                   # Documentation
├── src/                    # Source code
│   └── minimal-api-project/
│       ├── Dto/                    # Data Transfer Objects (API contracts)
│       ├── Endpoints/              # Minimal API endpoint mappings
│       ├── Infrastructure/         # Data access layer
│       │   └── Provider/           
│       │       ├── Entities/       # Domain entities (database models)
│       │       ├── Filters/        # Query filter objects
│       │       ├── *DbContext.cs   # EF Core contexts
│       │       └── *Provider.cs    # Business logic providers
│       ├── Transformers/           # OpenAPI document transformers
│       └── Program.cs             # Application bootstrap
└── test/                   # Test projects
```

### Principi di Organizzazione

1. **Un file per gruppo di endpoint correlati** (es. `D106Mapping.cs`, `TestMapping.cs`)
2. **Provider per logica business** (es. `AntifrodeProvider.cs`)
3. **DTO separati da Entities** - Mai esporre direttamente le entity
4. **Extension methods per mapping** - Entity → DTO conversions
5. **Filtri dedicati per query** - Oggetti per parametri di ricerca

---

## Minimal API - Regole di Sviluppo

### ✅ REGOLA 1: Endpoint sempre in Extension Methods

**✅ CORRETTO:**
```csharp
// File: Endpoints/D106Mapping.cs
public static class D106Mapping
{
    public static IEndpointRouteBuilder MapD106Endpoints(
        this IEndpointRouteBuilder routes, 
        ApiVersionSet versionSet)
    {
        var group = routes.MapGroup("api/v{version:apiVersion}/d106")
            .WithTags("D106")
            .WithApiVersionSet(versionSet)
            .MapToApiVersion(ApiVersionFactory.Version1);

        group.MapGet("/", GetLogsHandler)
            .RequireAuthorization()
            .Produces<IEnumerable<Log106Result>>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status404NotFound);

        return routes;
    }

    private static async Task<IResult> GetLogsHandler(
        DateTime FromDate, 
        DateTime ToDate, 
        AntifrodeProvider provider, 
        CancellationToken cancellationToken)
    {
        // Handler logic here
    }
}
```

**❌ ERRATO:**
```csharp
// NON mettere endpoint direttamente in Program.cs
app.MapGet("/api/d106", async (DateTime FromDate, ...) => 
{
    // NO! Troppo codice in Program.cs
});
```

### ✅ REGOLA 2: Formato URL Standardizzato (OBBLIGATORIO)

**Le URL devono sempre seguire il formato: `api/v{version:apiVersion}/{nomeGruppo}/{comando}`**

**✅ CORRETTO:**
```csharp
// Formato: api/v{version:apiVersion}/{gruppo}/{comando}
var group = routes.MapGroup("api/v{version:apiVersion}/weatherforecast")
    .WithTags("WeatherForecast")
    .WithApiVersionSet(versionSet)
    .MapToApiVersion(ApiVersionFactory.Version1);

group.MapGet("/", Handler);  // Diventa: GET /api/v1/weatherforecast/
group.MapGet("/daily", Handler);  // Diventa: GET /api/v1/weatherforecast/daily
```

**Esempi di URL generate:**
```
GET  https://localhost:7029/api/v1/weatherforecast/
GET  https://localhost:7029/api/v1/d106/
POST https://localhost:7029/api/v2/orders/create
```

**❌ ERRATO:**
```csharp
// NO - versione dopo il gruppo
routes.MapGroup("api/weatherforecast/v{version:apiVersion}")  // NO!

// NO - senza versione nell'URL
routes.MapGroup("api/weatherforecast")  // NO!

// NO - versione hardcoded
routes.MapGroup("api/v1/weatherforecast")  // NO! Usa placeholder {version:apiVersion}
```

**Regole del formato URL:**
1. Sempre `api/` come prefisso
2. Segmento versione con placeholder: `v{version:apiVersion}`
3. Nome gruppo in minuscolo (es. `weatherforecast`, `d106`, `orders`)
4. Comando finale opzionale per endpoint specifici (es. `/`, `/daily`, `/create`)

**Test nei file .http:**
```http
# ✅ CORRETTO
GET https://localhost:7029/api/v1/weatherforecast/
GET https://localhost:7029/api/v1/d106/?FromDate=2025-09-01&ToDate=2025-09-01

# ❌ ERRATO
GET https://localhost:7029/api/weatherforecast/v1/  # NO! Versione dopo il gruppo
```

### ✅ REGOLA 3: Usa Route Groups

**✅ CORRETTO:**
```csharp
var group = routes.MapGroup("api/v{version:apiVersion}/d106")
    .WithTags("D106")
    .WithApiVersionSet(versionSet)
    .MapToApiVersion(ApiVersionFactory.Version1);

// Applica configurazione comune a tutti gli endpoint del gruppo
group.MapGet("/", Handler1).RequireAuthorization();
group.MapPost("/", Handler2).RequireAuthorization();
```

**❌ EVITARE:**
```csharp
// Ripetizione di configurazione per ogni endpoint
routes.MapGet("api/d106", Handler1)
    .WithTags("D106")
    .RequireAuthorization();
routes.MapPost("api/d106", Handler2)
    .WithTags("D106")
    .RequireAuthorization();
```

### ✅ REGOLA 4: Configurazione standard del versioning

Usa sempre versioning basato su segmento URL e configura l'API Explorer con il formato di gruppo e la sostituzione della versione nell'URL. Assicurati che il pacchetto `Asp.Versioning.Mvc.ApiExplorer` sia installato.

**✅ CORRETTO (Program.cs):**
```csharp
builder.Services.AddApiVersioning(options =>
{
    options.ApiVersionReader = new UrlSegmentApiVersionReader();
    options.DefaultApiVersion = ApiVersionFactory.Version1;
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
})
.AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";
    options.SubstituteApiVersionInUrl = true;
});
```

**❌ EVITARE:**
- Versionamento via query string o header
- Mancata sostituzione della versione nell'URL per l'API Explorer

### ✅ REGOLA 5: Dependency Injection nei Parametri

**✅ CORRETTO (Parametri Espliciti):**
```csharp
private static async Task<IResult> Handler(
    DateTime FromDate,                    // Query parameter
    DateTime ToDate,                      // Query parameter
    AntifrodeProvider provider,           // Injected service
    ILogger<D106Mapping> logger,          // Injected logger
    CancellationToken cancellationToken)  // Cancellation token
{
    // ...
}
```

**✅ ALTERNATIVA (AsParameters - per molti parametri):**

Se più di due parametri, chiedi all'utente se raggrupparli in un oggetto con `[AsParameters]`:

```csharp
// Definisci la classe dei parametri
public class GetLogsParameters
{
    [FromQuery] public DateTime FromDate { get; init; }
    [FromQuery] public DateTime ToDate { get; init; }
    [FromQuery] public int? BusinessGroup { get; init; }
}

// Handler semplificato
private static async Task<IResult> Handler(
    [AsParameters] GetLogsParameters parameters,
    AntifrodeProvider provider,
    ILogger<D106Mapping> logger,
    CancellationToken cancellationToken)
{
    // Accesso: parameters.FromDate, parameters.ToDate
}
```

**Quando usare AsParameters:**
- ✅ Più di 2 query/route parameters
- ✅ Parametri riutilizzabili in più endpoint
- ✅ Migliore organizzazione e validazione centralizzata

**Ordine parametri raccomandato:**
1. Route parameters (se presenti)
2. Query parameters (o `[AsParameters]` object)
3. Body parameters (se POST/PUT)
4. Servizi iniettati
5. CancellationToken (sempre ultimo)

### ✅ REGOLA 6: Metadata OpenAPI Completi

**✅ CORRETTO:**
```csharp
group.MapGet("/", Handler)
    .RequireAuthorization()
    .Produces<IEnumerable<Log106Result>>(StatusCodes.Status200OK)
    .Produces(StatusCodes.Status404NotFound)
    .Produces(StatusCodes.Status400BadRequest)
    .Produces(StatusCodes.Status401Unauthorized)
    .WithName("GetD106Logs")
    .WithSummary("Retrieve D106 logs for date range")
    .WithDescription("Returns aggregated log entries...");
```

### ✅ REGOLA 7: Registrazione in Program.cs

```csharp
// Program.cs
var versionSet = app.NewApiVersionSet()
    .HasApiVersion(ApiVersionFactory.Version1)
    .Build();

// Chiama extension methods
app.MapD106Endpoints(versionSet);
app.MapTestV1Endpoints(versionSet);
app.MapTestV2Endpoints(versionSet);
```

### ✅ REGOLA 8: Trasformatore OpenAPI con informazioni di progetto

Crea sempre nella cartella `Transformers` una classe chiamata `AddDocumentInformations` che implementa `IOpenApiDocumentTransformer` per impostare le informazioni di base del progetto nella documentazione OpenAPI.

**Convenzioni di denominazione:**
- **Title**: Nome della solution (es. "Microcosmos API", "WeatherForecast API")
- **Name**: "Voisoft per Unidata spa, @ " + anno di creazione del progetto (es. "Voisoft per Unidata spa, @ 2025")
- **Description**: Breve descrizione dello scopo dell'API
- **Version**: Versione del documento (tipicamente "v1")
- **Contact**: Informazioni di contatto del team

**✅ CORRETTO:**
```csharp
// File: Transformers/AddDocumentInformations.cs
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi.Models;

namespace YourProject.Transformers;

public class AddDocumentInformations : IOpenApiDocumentTransformer
{
    public Task TransformAsync(OpenApiDocument document, OpenApiDocumentTransformerContext context, CancellationToken cancellationToken)
    {
        document.Info.Title = "Microcosmos API";  // Nome della solution
        document.Info.Description = "In caso di pericolo rompere il vetro";
        document.Info.Version = "v1";
        document.Info.Contact = new OpenApiContact
        {
            Name = "Voisoft per Unidata spa, @ 2025",  // Anno di creazione
            Url = new Uri("https://www.twt.it/"),
            Email = "tron@twt.it"
        };

        return Task.CompletedTask;
    }
}
```

**Registrazione in Program.cs:**
```csharp
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer<AddDocumentInformations>();
});
```

**❌ EVITARE:**
- Hardcodare informazioni generiche senza personalizzarle per il progetto
- Omettere l'anno di creazione nel campo Name
- Dimenticare di registrare il transformer nella pipeline OpenAPI

### ✅ REGOLA 9: Endpoint GET che usa un database provider

Usa questo pattern quando devi esporre un GET che richiama una funzione del provider (es. `AntifrodeProvider.GetLog106Async`). Mantieni versione in URL, filtri dedicati, mapping manuale e ProblemDetails per assenza dati.

```csharp
// File: Endpoints/D106Mapping.cs
public static class D106Mapping
{
    public static IEndpointRouteBuilder MapD106Endpoints(
        this IEndpointRouteBuilder routes,
        ApiVersionSet versionSet)
    {
        var group = routes.MapGroup("api/v{version:apiVersion}/d106")
            .WithTags("D106")
            .WithApiVersionSet(versionSet)
            .MapToApiVersion(ApiVersionFactory.Version1);

        group.MapGet("/", GetLogsHandler)
            .RequireAuthorization()
            .Produces<IEnumerable<Log106Result>>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status204NoContent)
            .Produces(StatusCodes.Status400BadRequest)
            .Produces(StatusCodes.Status404NotFound)
            .WithSummary("Recupera i log D106 per intervallo di date")
            .WithDescription("Legge dal provider e mappa le entity in DTO");

        return routes;
    }

    private static async Task<IResult> GetLogsHandler(
        DateTime FromDate,
        DateTime ToDate,
        AntifrodeProvider provider,
        CancellationToken cancellationToken)
    {
        var filter = new Log106Filter
        {
            FromLogDate = FromDate,
            ToLogDate = ToDate
        };

        var result = await provider.GetLog106Async(filter, l => l.ToLog106Result(), cancellationToken);
        if (!result.Any())
        {
            var problem = new ProblemDetails
            {
                Title = "Data Not Found",
                Status = StatusCodes.Status404NotFound,
                Detail = "No logs found for the specified date range."
            };

            return TypedResults.Problem(problem);
        }

        return Results.Ok(result);
    }
}
```

**Regole chiave:**
- Gruppo con URL `api/v{version:apiVersion}/{dominio}` e `RequireAuthorization` a livello di endpoint.
- Parametri query espliciti (o `[AsParameters]` se >2), servizi DI dopo i parametri, `CancellationToken` per ultimo.
- Guarda l'entità restituita dal provider e crea nella cartella Dto una classe dedicata (es. `Log106Result`). Crea un extension method per il mapping (es. `ToLog106Result`)
- Usa i parametri per istanziare il filtro dedicato (es. `Log106Filter`) e passalo al provider insieme alla proiezione verso DTO (`ToLog106Result`).
- Se nessun dato, restituisci `TypedResults.Problem` con 404; altrimenti `Results.Ok` con la lista di DTO.
- Dichiarare `.Produces(...)` coerenti con gli esiti (200/204/400/404) e metadata OpenAPI (summary/description).
- Aggiungi un test .http per verificare l'endpoint.

---

## 🔧 Troubleshooting - Errori Comuni

### Errore: "The ApiVersionReader must be capable of reading the API version from the URL path segment"

**Causa:** Stai usando `MapToApiVersion` ma il version reader non è `UrlSegmentApiVersionReader`.

**Soluzione:**
```csharp
// ✅ CORRETTO
builder.Services.AddApiVersioning(options =>
{
    options.ApiVersionReader = new UrlSegmentApiVersionReader(); // OBBLIGATORIO
    // ...
});
```

### Errore: "No route matches the supplied values"

**Causa:** Il placeholder `{version:apiVersion}` non è nel path corretto.

**Soluzione:** Assicurati che il formato sia `api/v{version:apiVersion}/{gruppo}`:
```csharp
// ❌ ERRATO
var group = routes.MapGroup("api/weatherforecast/v{version:apiVersion}");

// ✅ CORRETTO
var group = routes.MapGroup("api/v{version:apiVersion}/weatherforecast");
```

### Errore: "An API version is required, but was not specified"

**Causa:** L'endpoint non ha una versione assegnata tramite `MapToApiVersion`.

**Soluzione:**
```csharp
// ✅ CORRETTO
var group = routes.MapGroup("api/v{version:apiVersion}/weatherforecast")
    .WithApiVersionSet(versionSet)
    .MapToApiVersion(ApiVersionFactory.Version1); // OBBLIGATORIO
```

### Errore: Scalar non mostra alcun endpoint

**Causa:** Manca la configurazione dell'API Explorer con formato gruppo e sostituzione URL.

**Soluzione:**
```csharp
// ✅ CORRETTO
builder.Services.AddApiVersioning(options => { /* ... */ })
    .AddApiExplorer(options =>  // OBBLIGATORIO per Scalar
    {
        options.GroupNameFormat = "'v'VVV";
        options.SubstituteApiVersionInUrl = true;
    });
```

### Errore: "Cannot resolve service for type 'MyProvider'"

**Causa:** Provider non registrato in Program.cs o registrato con lifetime errato.

**Soluzione:**
```csharp
// ✅ CORRETTO - Usa extension method
builder.Services.AddMyProvider(builder.Configuration);

// Oppure registrazione diretta come Scoped
builder.Services.AddScoped<MyProvider>();
```

### Errore: 404 su endpoint che dovrebbe esistere

**Causa:** Extension method non chiamato in Program.cs.

**Soluzione:**
```csharp
// ✅ CORRETTO - Verifica che sia chiamato DOPO app.MapOpenApi()
app.MapOpenApi(); // Prima
app.MapWeatherForecastEndpoints(versionSet); // Dopo
```

### Errore: "The JSON value could not be converted to System.DateTime"

**Causa:** Formato data non valido nella query string.

**Soluzione:** Usa formato ISO 8601:
```http
# ✅ CORRETTO
GET https://localhost:7029/api/v1/logs?FromDate=2025-01-22&ToDate=2025-01-23

# ❌ ERRATO
GET https://localhost:7029/api/v1/logs?FromDate=22/01/2025&ToDate=23/01/2025
```

### Warning: "This async method lacks 'await' operators"

**Causa:** Metodo dichiarato async ma non usa await.

**Soluzione:**
```csharp
// Se non hai operazioni async, rimuovi async/await
private static IResult Handler(MyProvider provider)
{
    var result = provider.GetData(); // Sincrono
    return Results.Ok(result);
}

// Se hai operazioni async, usa await
private static async Task<IResult> Handler(MyProvider provider, CancellationToken ct)
{
    var result = await provider.GetDataAsync(ct); // Asincrono
    return Results.Ok(result);
}
```

### Errore: "AmbiguousMatchException: The request matched multiple endpoints"

**Causa:** Due endpoint con stesso HTTP verb e route.

**Soluzione:** Usa route diverse o parametri di query/route per disambiguare:
```csharp
// ❌ ERRATO - Route ambigue
group.MapGet("/", Handler1);
group.MapGet("/", Handler2);

// ✅ CORRETTO
group.MapGet("/", Handler1);
group.MapGet("/detailed", Handler2);
```

### Problema: Scalar mostra endpoint ma non gruppi/tags

**Causa:** Manca `WithTags()` nel group.

**Soluzione:**
```csharp
// ✅ CORRETTO
var group = routes.MapGroup("api/v{version:apiVersion}/weatherforecast")
    .WithTags("WeatherForecast") // IMPORTANTE per organizzazione in Scalar
    .WithApiVersionSet(versionSet)
    .MapToApiVersion(ApiVersionFactory.Version1);
```

---

## 📚 Risorse Aggiuntive

### Documentazione Ufficiale
- [ASP.NET Core Minimal APIs](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis)
- [API Versioning](https://github.com/dotnet/aspnet-api-versioning/wiki)
- [Scalar Documentation](https://scalar.com/docs)
- [OpenAPI in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/)

### Best Practices
- Usa sempre `CancellationToken` per operazioni async
- Preferisci `TypedResults` a `Results` per type safety
- Documenta tutti gli status code possibili con `.Produces()`
- Usa route groups per evitare ripetizioni
- Testa gli endpoint con file `.http` durante lo sviluppo

---

*Documento generato il 2025 - Versione 1.1*

