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

### ❌ Cosa NON Usare

- ❌ **MVC Controllers** - Usa Minimal API
- ❌ **Swagger UI** - Usa Scalar
- ❌ **IRepository pattern** - EF Core DbContext è sufficiente
- ❌ **AutoMapper** - Usa extension methods manuali
- ❌ **MediatR** - Non necessario per la complessità attuale

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
        var group = routes.MapGroup("api/d106")
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

### ✅ REGOLA 2: Usa Route Groups

**✅ CORRETTO:**
```csharp
var group = routes.MapGroup("api/d106")
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

### ✅ REGOLA 3: Dependency Injection nei Parametri

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

### ✅ REGOLA 4: Metadata OpenAPI Completi

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

### ✅ REGOLA 5: Registrazione in Program.cs

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

---

## Entity Framework Core - Best Practices

### ✅ REGOLA 1: Provider Pattern per Business Logic (OBBLIGATORIO)

**Quando usi un Provider con EF Core, devi SEMPRE usare un selector per la proiezione. NON restituire MAI direttamente un'entity, eccetto per stored procedure.**

**✅ CORRETTO:**
```csharp
// Infrastructure/Antifrode/AntifrodeProvider.cs
public class AntifrodeProvider(
    AntifrodeDbContext context, 
    ILogger<AntifrodeProvider> logger)
{
    // ✅ SEMPRE con selector - proiezione lato database
    public async Task<List<TResult>> GetLogsAsync<TResult>(
        Log106Filter filter,
        Expression<Func<Log106, TResult>> selector)
    {
        var query = context.Log106.AsNoTracking();
        
        if (filter.FromLogDate.HasValue)
            query = query.Where(l => l.LogDate >= filter.FromLogDate.Value);
        
        return await query.Select(selector).ToListAsync();
    }
    
    // ✅ ECCEZIONE: Stored procedure - può restituire entity
    public async Task<List<Log106>> ExecuteStoredProcedureAsync(
        int businessGroup,
        CancellationToken cancellationToken)
    {
        return await context.Log106
            .FromSqlRaw("EXEC sp_GetLogs @BusinessGroup = {0}", businessGroup)
            .ToListAsync(cancellationToken);
    }
}
```

**❌ VIETATO:**
```csharp
// NON accedere al DbContext direttamente dagli endpoint
group.MapGet("/", async (AntifrodeDbContext context) => 
{
    var logs = await context.Log106.ToListAsync(); // NO!
});

// NON restituire entity direttamente dal Provider (eccetto stored procedure)
public async Task<List<Log106>> GetLogsAsync(Log106Filter filter) // NO!
{
    return await context.Log106.ToListAsync(); // NO!
}
```

### ✅ REGOLA 2: Proiezione nel Database

**Questa regola vale solo se non stai usando una classe Provider nella cartella Infrastructure.**

**✅ CORRETTO:**
```csharp
// Proiezione lato database (SQL SELECT ottimizzato)
return await query
    .AsNoTracking()
    .Select(l => new Log106Result 
    { 
        LogDate = l.LogDate,
        BusinessGroup = l.BusinessGroup 
    })
    .ToListAsync();
```

**❌ EVITARE:**
```csharp
// Materializzazione completa poi proiezione in memoria
var logs = await query.ToListAsync(); // Carica TUTTO dal DB
return logs.Select(l => l.ToLog106Result()).ToList(); // Proietta in memoria
```

### ✅ REGOLA 3: AsNoTracking per Read-Only

**✅ CORRETTO:**
```csharp
// Default nel DbContext
options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);

// Oppure esplicito per query
var query = context.Log106.AsNoTracking();
```

### ✅ REGOLA 4: CancellationToken Sempre

**✅ CORRETTO:**
```csharp
public async Task<List<Log106>> GetLogsAsync(
    Log106Filter filter,
    CancellationToken cancellationToken)
{
    return await query.ToListAsync(cancellationToken);
}
```

### ✅ REGOLA 5: Filtri come Oggetti Dedicati

**✅ CORRETTO:**
```csharp
// Infrastructure/Antifrode/Filters/Log106Filter.cs
public class Log106Filter
{
    public DateTime? FromLogDate { get; set; }
    public DateTime? ToLogDate { get; set; }
    public int? BusinessGroup { get; set; }
}

// Uso
var filter = new Log106Filter
{
    FromLogDate = FromDate,
    ToLogDate = ToDate
};
var result = await provider.GetLogsAsync(filter);
```

---

## DTO e Mapping

### ✅ REGOLA 1: DTO Separati da Entities

**✅ CORRETTO:**
```csharp
// Infrastructure/Antifrode/Entities/Log106.cs (Database entity)
[Table("Log_106")]
public class Log106
{
    public DateTime LogDate { get; set; }
    public int BusinessGroup { get; set; }
}

// Dto/Log106Result.cs (API contract)
public class Log106Result
{
    [JsonPropertyName("logDate")]
    public DateTime LogDate { get; set; }
    
    [JsonPropertyName("businessGroup")]
    public int BusinessGroup { get; set; }
}
```

### ✅ REGOLA 2: Extension Methods per Mapping

**✅ CORRETTO:**
```csharp
// Dto/Log106Extension.cs
public static class Log106Extension
{
    public static Log106Result ToLog106Result(this Log106 entity)
    {
        return new Log106Result
        {
            LogDate = entity.LogDate,
            BusinessGroup = entity.BusinessGroup,
            RagioneSociale = entity.RagioneSociale,
            CallsCount = entity.CallsCount
        };
    }
}

// Uso negli endpoint
var result = dbEntity.ToLog106Result();
```

**❌ EVITARE:**
```csharp
// NO AutoMapper, NO service di mapping
services.AddAutoMapper(...); // Non usare
```

### ✅ REGOLA 3: JsonPropertyName Espliciti

**✅ CORRETTO:**
```csharp
public class Log106Result
{
    [JsonPropertyName("logDate")]        // camelCase per JSON
    public DateTime LogDate { get; set; } // PascalCase per C#
}
```

---

## API Versioning

### ✅ REGOLA 1: Versioni in ApiVersionFactory (OBBLIGATORIO)

**Crea sempre il versioning anche se l'utente non lo richiede esplicitamente. Suggerisci di introdurre il versionamento se nel progetto manca**

**✅ CORRETTO:**
```csharp
// Endpoints/ApiVersionFactory.cs
public static class ApiVersionFactory
{
    public static readonly ApiVersion Version1 = new(1, 0);
    public static readonly ApiVersion Version2 = new(2, 0);
}

// Uso
.MapToApiVersion(ApiVersionFactory.Version1)
```

### ✅ REGOLA 2: URL-based Versioning

**✅ CORRETTO:**
```
/api/v1/d106
/api/v2/d106
```

**❌ EVITARE:**
```
/api/d106?version=1.0  # NO query string versioning
/api/d106 (header)     # NO header versioning
```

### ✅ REGOLA 3: File Separati per Versioni Diverse

**✅ CORRETTO:**
```csharp
// Endpoints/TestMapping.cs
public static IEndpointRouteBuilder MapTestV1Endpoints(...) { }
public static IEndpointRouteBuilder MapTestV2Endpoints(...) { }
```

---

## Logging

### ✅ REGOLA 1: Structured Logging

**✅ CORRETTO:**
```csharp
logger.LogInformation(
    "Processing logs from {FromDate} to {ToDate}", 
    fromDate, 
    toDate);
```

**❌ EVITARE:**
```csharp
logger.LogInformation(
    $"Processing logs from {fromDate} to {toDate}"); // NO string interpolation
```

### ✅ REGOLA 2: Log Levels Appropriati

- `Verbose` - Solo in development, query SQL dettagliate
- `Information` - Operazioni normali, inizio/fine processing
- `Warning` - Situazioni anomale ma gestibili (es. nessun dato trovato)
- `Error` - Eccezioni, errori che richiedono attenzione

**✅ CORRETTO:**
```csharp
logger.LogInformation("Applying FromLogDate filter: {FromLogDate}", filter.FromLogDate);
logger.LogWarning("No data found for business group {BusinessGroup}", businessGroup);
logger.LogError(ex, "Database query failed for filter {@Filter}", filter);
```

### ✅ REGOLA 3: MAI Loggare Dati Sensibili

**❌ VIETATO:**
```csharp
logger.LogInformation("API Key: {ApiKey}", apiKey); // NO!
logger.LogInformation("Password: {Password}", password); // NO!
```

---

## Error Handling

### ✅ REGOLA 1: ProblemDetails per Errori (OBBLIGATORIO)

**Installa il pacchetto nuget Tinyhelpers.AspNetCore.**

**✅ CORRETTO:**
```csharp
if (!result.Any())
{
    var problem = new ProblemDetails
    {
        Title = "Data Not Found",
        Status = StatusCodes.Status404NotFound,
        Detail = "No logs found for the specified date range.",
        Type = "https://tools.ietf.org/html/rfc7231#section-6.5.4"
    };
    return TypedResults.Problem(problem);
}
```

### ✅ REGOLA 2: TypedResults per Type-Safety

**✅ CORRETTO:**
```csharp
return TypedResults.Ok(result);           // 200
return TypedResults.NotFound();           // 404
return TypedResults.Problem(problem);     // 4xx/5xx
return TypedResults.BadRequest(problem);  // 400
```

**❌ EVITARE:**
```csharp
return Results.Ok(result); // Meno type-safe
```

### ✅ REGOLA 3: Exception Handler Globale

```csharp
// Program.cs - già configurato
builder.Services.AddDefaultExceptionHandler();
app.UseExceptionHandler();
```

**NON gestire eccezioni negli handler** a meno che non serva logica specifica.

---

## Authentication & Security

### ✅ REGOLA 1: RequireAuthorization su Endpoint Pubblici

**✅ CORRETTO:**
```csharp
group.MapGet("/", Handler)
    .RequireAuthorization(); // ✅ Sempre per endpoint che richiedono auth
```

### ✅ REGOLA 2: API Keys in Secrets

**❌ MAI:**
```csharp
// appsettings.json (committato in Git)
"ApiKey": "HGMS05SZAKU" // NO!
```

**✅ CORRETTO:**
```bash
# User Secrets (development)
dotnet user-secrets set "Authentication:ApiKey:ApiKeys:0:Value" "key"

# Environment Variables (production)
export Authentication__ApiKey__ApiKeys__0__Value="key"
```

---

## Configuration

### ✅ REGOLA 1: Gerarchia Configurazione

1. `appsettings.json` (default, committato)
2. `appsettings.{Environment}.json` (environment-specific, gitignored)
3. User Secrets (development)
4. Environment Variables (production/Docker)

### ✅ REGOLA 2: Supporto Environment Variables

```csharp
// Program.cs - già presente
builder.Configuration.AddEnvironmentVariables();
```

**Naming:**
```bash
ConnectionStrings__AntifrodeDb="..."           # __ per nested properties
Authentication__ApiKey__ApiKeys__0__Value="..."
```

---

## Testing

### ✅ File .http per Test Manuali

**✅ CORRETTO:**
```http
# D106.Api.http
@D106.Api_HostAddress = https://localhost:5001
@apiKey = test-key

### Test singolo giorno
GET {{D106.Api_HostAddress}}/api/v1/d106?FromDate=2025-09-01&ToDate=2025-09-01
Accept: application/json
X-API-KEY: {{apiKey}}
```

---

## Naming Conventions

### Files

- **Endpoints**: `{Resource}Mapping.cs` (es. `D106Mapping.cs`)
- **Providers**: `{Context}Provider.cs` (es. `AntifrodeProvider.cs`)
- **DbContext**: `{Context}DbContext.cs` (es. `AntifrodeDbContext.cs`)
- **Entities**: `{EntityName}.cs` (es. `Log106.cs`)
- **DTOs**: `{EntityName}Result.cs` o `{EntityName}Request.cs`
- **Filters**: `{EntityName}Filter.cs`
- **Extensions**: `{EntityName}Extension.cs`

### Classes & Methods

```csharp
// PascalCase per tutto pubblico
public class AntifrodeProvider { }
public async Task<List<Log106>> GetLogsAsync() { }

// camelCase con _ per campi privati
private readonly ILogger<AntifrodeProvider> _logger;

// Suffisso Async per metodi asincroni
public async Task<IResult> GetLogsAsync() { }
```

---

## Checklist Nuova Feature

Quando aggiungi una nuova feature, assicurati di:

- [ ] Endpoint in file `*Mapping.cs` separato
- [ ] Extension method per registrazione endpoint
- [ ] Route group con configurazione comune
- [ ] Metadata OpenAPI completi (`.Produces`, `.WithSummary`)
- [ ] Business logic in Provider, non in endpoint handler
- [ ] DTO separato da Entity
- [ ] Extension method per Entity → DTO mapping
- [ ] AsNoTracking per query read-only
- [ ] CancellationToken nei metodi async
- [ ] Structured logging con parametri
- [ ] ProblemDetails per errori
- [ ] RequireAuthorization se necessario
- [ ] Test in file `.http`
- [ ] Documentazione aggiornata

---

## Anti-Patterns da Evitare

❌ **NO MVC Controllers**
```csharp
[ApiController] // Non usare
[Route("api/[controller]")]
public class D106Controller : ControllerBase { }
```

❌ **NO IRepository pattern**
```csharp
public interface ILog106Repository { } // EF Core DbContext è sufficiente
```

❌ **NO Service layer superfluo**
```csharp
public class D106Service // Usa Provider solo se serve business logic
{
    public async Task<List<Log106>> GetAll() => await _repo.GetAll();
}
```

❌ **NO AutoMapper**
```csharp
services.AddAutoMapper(...); // Usa extension methods manuali
```

❌ **NO logica negli endpoint**
```csharp
group.MapGet("/", async (DbContext context) =>
{
    // 50 righe di codice qui... NO!
    // Sposta la logica in un Provider
});
```

---

## Risorse

- [ASP.NET Core Minimal APIs](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis)
- [EF Core Best Practices](https://learn.microsoft.com/en-us/ef/core/performance/)
- [Serilog Best Practices](https://github.com/serilog/serilog/wiki/Writing-Log-Events)
- [API Versioning](https://github.com/dotnet/aspnet-api-versioning)

---

**Ultimo aggiornamento**: 2025-01-20

Per domande su queste linee guida, apri una Discussion su GitLab o consulta il team.
