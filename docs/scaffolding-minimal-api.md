# Scaffolding: Minimal API .NET 10

Questa guida mostra cosa succede quando si chiede a Claude Code (con i pacchetti `dr-guidelines` e `dr-minimalapi` installati) di creare una nuova Minimal API. Descrive le domande preliminari, la struttura generata e le convenzioni applicate.

`/dr-scaffold` crea il progetto vuoto. Questa struttura la scrive l'assistente dopo, quando chiedi endpoint o entità, seguendo le istruzioni di `dr-minimalapi`. Le regole valide sono in `minimal-api-architecture.instructions.md`. Questo documento è una panoramica: sta nel repo `dr-guidelines` e non viene copiato nel progetto.

---

## Gate preliminare — cosa chiede Claude prima di procedere

Prima di creare qualsiasi file, Claude raccoglie **tutto in un unico messaggio**:

| # | Domanda | Default proposto |
|---|---------|-----------------|
| 1 | Nome entità + campi | Solo se il task coinvolge un'entità e non sono già indicati |
| 2 | Nome del progetto | `<nomecartella>.api` in lowercase — es. cartella `ordini/` → propone `ordini.api` |
| 3 | Aggiungere Serilog? | Nessun default — chiede esplicitamente |
| 4 | Entity Framework Core presente? | Se è già nel `.csproj` lo dichiara; altrimenti chiede. |
| 5 | Utenti umani con login? | Nessun default. Se sì, lo schema dipende dai client |
| 6 | Connessione DB (solo se MCP db-schema attivo) | Solo se sono disponibili più connessioni |

> ⚠️ Se il nome progetto non è ricavabile dal contesto, Claude si **ferma** e aspetta risposta. Non inventa nomi come `MyApi` o `WebApi`.

---

## Struttura generata

```
<soluzione>/
  src/
    <progetto>.api/
      Dto/
        <Entity>Dto.cs                    ← record completo con static Projection
        <Entity>SummaryDto.cs             ← record ridotto (SELECT ottimizzata)
      Endpoints/
        <Entity>Mapping.cs                ← extension method con MapGroup
        HealthMapping.cs                  ← /health + GET /api/v1/status
      Infrastructure/
        Provider/
          Entities/
            <Entity>.cs                   ← entity con [Table] e [Column]
          Filters/
            <Entity>Filter.cs             ← filtro con ToExpression()
          <Progetto>DbContext.cs          ← DbContext con NoTracking default
          <Progetto>Provider.cs           ← operazioni CRUD con Expression selector
          <Progetto>ProviderExtensions.cs ← Add<Progetto>Provider() per DI
      Properties/
        ApiVersionFactory.cs              ← ApiVersionFactory con Version1
        launchSettings.json               ← obbligatorio: profili IIS Express e Kestrel
      Services/
        <Entity>Service.cs                ← service layer tra handler e provider
      Transformers/
        AddDocumentInformations.cs        ← OpenAPI transformer (titolo, desc, contatto)
      Validators/
        <Entity>RequestValidator.cs       ← FluentValidation per POST/PUT/PATCH
        <Entity>FilterValidator.cs        ← FluentValidation per GET con filtro
      appsettings.json
      appsettings.local.json              ← non committato (.gitignore)
      Program.cs
      <progetto>.csproj
      <progetto>.http                     ← esempi di chiamate HTTP
  .vscode/                                ← `launch.json` e `tasks.json` (`coreclr`), obbligatori; `/dr-create-launch-profiles` li genera in modo guidato
    launch.json                           ← profili debug http e https (type: coreclr)
    tasks.json                            ← build task
  test/
  docs/
```

> Con `dr-efdb` installato il provider sta in `Infrastructure/<NomeProvider>/` (non in `Infrastructure/Provider/`). La struttura esatta è in `database-provider.instructions.md`.

---

## File chiave — esempio con entità `Prodotto`

### `Endpoints/ProdottoMapping.cs`

```csharp
namespace mio_progetto.api.Endpoints;

public static class ProdottoMapping
{
    public static IEndpointRouteBuilder MapProdottoEndpoints(
        this IEndpointRouteBuilder routes,
        ApiVersionSet versionSet)
    {
        var group = routes.MapGroup("api/v{version:apiVersion}/prodotti")
            .WithTags("Prodotti")
            .WithApiVersionSet(versionSet)
            .MapToApiVersion(ApiVersionFactory.Version1);

        group.MapGet("/", GetListHandler)
            .Produces<List<ProdottoDto>>(StatusCodes.Status200OK)
            .Produces<ProblemDetails>(StatusCodes.Status404NotFound)
            .Produces<ProblemDetails>(StatusCodes.Status400BadRequest)
            .WithName("GetProdottoList")
            .WithSummary("Lista prodotti con filtro")
            .WithDescription("Restituisce i prodotti che corrispondono ai filtri. 404 se nessun risultato.");

        group.MapGet("/summary", GetSummaryHandler)
            .Produces<List<ProdottoSummaryDto>>(StatusCodes.Status200OK)
            .Produces<ProblemDetails>(StatusCodes.Status404NotFound)
            .Produces<ProblemDetails>(StatusCodes.Status400BadRequest)
            .WithName("GetProdottoSummary")
            .WithSummary("Lista prodotti (sommario)")
            .WithDescription("Versione ridotta — solo Id e Nome.");

        group.MapGet("/{id:int}", GetByIdHandler)
            .Produces<ProdottoDto>(StatusCodes.Status200OK)
            .Produces<ProblemDetails>(StatusCodes.Status404NotFound)
            .WithName("GetProdottoById")
            .WithSummary("Prodotto per Id")
            .WithDescription("Restituisce il prodotto con l'Id specificato.");

        group.MapPost("/", PostHandler)
            .Produces<ProdottoDto>(StatusCodes.Status201Created)
            .Produces<ProblemDetails>(StatusCodes.Status400BadRequest)
            .WithName("PostProdotto")
            .WithSummary("Crea prodotto")
            .WithDescription("Crea un nuovo prodotto e restituisce la risorsa creata.");

        group.MapPut("/{id:int}", PutHandler)
            .Produces(StatusCodes.Status204NoContent)
            .Produces<ProblemDetails>(StatusCodes.Status400BadRequest)
            .Produces<ProblemDetails>(StatusCodes.Status404NotFound)
            .WithName("PutProdotto")
            .WithSummary("Aggiorna prodotto")
            .WithDescription("Aggiorna il prodotto con l'Id specificato.");

        group.MapDelete("/{id:int}", DeleteHandler)
            .Produces(StatusCodes.Status204NoContent)
            .Produces<ProblemDetails>(StatusCodes.Status404NotFound)
            .WithName("DeleteProdotto")
            .WithSummary("Elimina prodotto")
            .WithDescription("Elimina il prodotto con l'Id specificato.");

        return routes;
    }

    // handler privati...
}
```

### `Infrastructure/Provider/Filters/ProdottoFilter.cs`

```csharp
/// <summary>Optional filters for querying Prodotto. All fields nullable — none required.</summary>
public class ProdottoFilter
{
    public string? Nome { get; set; }
    public decimal? PrezzoMin { get; set; }
    public decimal? PrezzoMax { get; set; }
    public DateTime? CreatedAtFrom { get; set; }
    public DateTime? CreatedAtTo { get; set; }

    /// <summary>Builds the EF-translatable WHERE expression from the populated fields.</summary>
    public Expression<Func<Prodotto, bool>> ToExpression() =>
        e => (Nome == null || e.Nome.Contains(Nome))
          && (PrezzoMin == null || e.Prezzo >= PrezzoMin)
          && (PrezzoMax == null || e.Prezzo <= PrezzoMax)
          && (CreatedAtFrom == null || e.CreatedAt >= CreatedAtFrom)
          && (CreatedAtTo == null || e.CreatedAt <= CreatedAtTo);
}
```

### `Dto/ProdottoDto.cs`

```csharp
/// <summary>Response DTO for a Prodotto row, with EF-translatable projection.</summary>
public record ProdottoDto(int Id, string Nome, decimal Prezzo, DateTime CreatedAt)
{
    /// <summary>EF-translatable projection (new-initializer, primitive member access only).</summary>
    public static Expression<Func<Prodotto, ProdottoDto>> Projection =>
        e => new(e.Id, e.Nome, e.Prezzo, e.CreatedAt);
}
```

### `Dto/ProdottoSummaryDto.cs`

```csharp
/// <summary>Reduced DTO — SELECT contains only Id and Nome.</summary>
public record ProdottoSummaryDto(int Id, string Nome)
{
    public static Expression<Func<Prodotto, ProdottoSummaryDto>> Projection =>
        e => new(e.Id, e.Nome);
}
```

### `Services/ProdottoService.cs`

```csharp
/// <summary>Application service for Prodotti: handlers depend on this, never on the provider.</summary>
public class ProdottoService(ProdottiProvider provider)
{
    /// <summary>Returns prodotti matching the filter, projected to the full DTO.</summary>
    public Task<List<ProdottoDto>> GetAllAsync(ProdottoFilter filter, CancellationToken ct) =>
        provider.GetProdottoAsync(filter, ProdottoDto.Projection, ct);

    /// <summary>Returns prodotti matching the filter, projected to the reduced DTO (optimized SELECT).</summary>
    public Task<List<ProdottoSummaryDto>> GetSummariesAsync(ProdottoFilter filter, CancellationToken ct) =>
        provider.GetProdottoAsync(filter, ProdottoSummaryDto.Projection, ct);

    /// <summary>Returns the prodotto with the given Id, or null if not found.</summary>
    public Task<ProdottoDto?> GetByIdAsync(int id, CancellationToken ct) =>
        provider.GetProdottoByIdAsync(id, ProdottoDto.Projection, ct);

    // CreateAsync, UpdateAsync, DeleteAsync...
}
```

---

## Convenzioni applicate automaticamente

| Convenzione | Dettaglio |
|---|---|
| URL formato | `api/v{version:apiVersion}/{gruppo}/{comando?}` |
| Versioning | `UrlSegmentApiVersionReader`, `GroupNameFormat = 'v'VVV` |
| Metadata OpenAPI | `WithSummary`, `WithDescription`, `WithTags`, `WithName`, tutti i `Produces` — obbligatori su ogni endpoint |
| DTO multipli | `<Entity>Dto` completo + `<Entity>SummaryDto` ridotto — SELECT ottimizzata |
| Filtro | `<Entity>Filter` con tutti campi nullable e `ToExpression()` |
| Service layer | Handler → Service → Provider (mai handler → provider direttamente) |
| Health check | `HealthMapping.cs` con `/health` (infrastruttura) + `GET /api/v1/status` (consumer) |
| Avvio con DB irraggiungibile | L'API parte; `/api/v1/status` mostra lo stato del DB; le richieste che lo usano rispondono 503. Con `dr-efdb` vale `database-startup-resilience.instructions.md`. |
| Validation | `IValidator<T>` su ogni input (body e query filter con ≥ 1 campo) |
| Tracking EF | `NoTracking` come default; `AsTracking()` esplicito su Update/Delete |
| Commenti | `///` su tutti i `public` method di provider/service/handler/validator |
| File sensibili | `appsettings.local.json` in `.gitignore`, mai credenziali reali in file committati |
| Debug VS Code | `launch.json` + `tasks.json` con `type: coreclr` (http + https) |
| Serilog | Solo se confermato — `AddSerilog` in Program.cs, sezione in appsettings.json, `logs/` in .gitignore |

---

## Pacchetti NuGet installati

| Pacchetto | Motivo |
|---|---|
| `Asp.Versioning.Mvc.ApiExplorer` | Versioning + Scalar |
| `Tinyhelpers.AspNetCore` | Helper Minimal API |
| `Scalar.AspNetCore` | Documentazione Scalar (`MapScalarApiReference`). Nome dedotto dal codice: le istruzioni non lo scrivono. Da verificare |
| `Microsoft.AspNetCore.OpenApi` | `AddOpenApi` e transformer. Nome dedotto dal codice: le istruzioni non lo scrivono. Da verificare |
| `FluentValidation` | Validazione input |
| `Microsoft.EntityFrameworkCore.SqlServer` | ORM (se richiesto) |
| `Serilog.AspNetCore` | Logging su file + console (se confermato); include `Serilog.Settings.Configuration` per leggere la sezione `Serilog` di `appsettings.json` |
| `Serilog.Sinks.File` | Sink file Serilog (se Serilog confermato) |
| `Serilog.Sinks.Console` | Sink console Serilog (se Serilog confermato) |
| `Serilog.Enrichers.Thread` | Enricher `ThreadId` (se Serilog confermato, da `serilog-logging.instructions.md` di `dr-dotnet-backend`) |

---

*Revisione v1.3 — 2026-10-20 18:20 — claude-opus-5-5*
