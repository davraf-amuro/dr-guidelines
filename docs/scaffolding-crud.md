# Scaffolding: CRUD endpoint per una tabella

Questa guida mostra cosa succede quando si chiede a Claude Code (con davraf-guidelines attive) di creare gli endpoint CRUD per una tabella — es. `"crea gli endpoint crud per la tabella MyTable"`.

Prerequisito: progetto Minimal API già esistente con la struttura di base.

---

## Gate preliminare — cosa chiede Claude prima di procedere

Claude raccoglie le informazioni necessarie in **un unico messaggio**:

| # | Domanda | Alternativa automatica |
|---|---------|------------------------|
| 1 | Campi dell'entità (nome e tipo) | Se MCP `db-schema` attivo → legge automaticamente lo schema dalla tabella |
| 2 | Nome tabella SQL (se diverso dal nome entità) | Usa il nome entità come default |
| 3 | Chiave primaria e tipo (int IDENTITY, Guid, composita) | Default: `int` con IDENTITY |

Se **MCP `db-schema` è attivo** nel progetto, Claude:
1. Legge la struttura della tabella automaticamente
2. Inferisce i tipi C# dai tipi SQL
3. Genera validator con regole da schema (es. `varchar(50)` → `MaximumLength(50)`)
4. Non chiede i campi all'utente

---

## File generati — esempio con tabella `MyTable`

```
src/<progetto>/
  Dto/
    MyTableDto.cs                    ← record completo con static Projection
    MyTableSummaryDto.cs             ← record ridotto
  Endpoints/
    MyTableMapping.cs                ← extension method con 6 endpoint CRUD
  Infrastructure/
    Provider/
      Entities/
        MyTable.cs                   ← entity con [Table] e [Column]
      Filters/
        MyTableFilter.cs             ← filtro con ToExpression()
    MyTableDbContext.cs              ← (solo se DbContext non esiste)
    MyTableProvider.cs               ← CRUD: Get, GetById, Create, Update, Delete
    MyTableProviderExtensions.cs     ← Add<Provider>Provider() per DI
  Services/
    MyTableService.cs                ← service layer tra handler e provider
  Validators/
    MyTableRequestValidator.cs       ← regole per POST e PUT
    MyTableFilterValidator.cs        ← regole per il filtro GET
```

---

## File chiave — esempio con entità `MyTable` (campi: Id, Nome, Prezzo, CreatedAt)

### `Entities/MyTable.cs`

```csharp
[Table("MyTable")]
public class MyTable
{
    [Column("Id")]
    public int Id { get; set; }

    [Column("Nome")]
    public string Nome { get; set; } = string.Empty;

    [Column("Prezzo")]
    public decimal Prezzo { get; set; }

    [Column("CreatedAt")]
    public DateTime CreatedAt { get; set; }
}
```

### `Dto/MyTableDto.cs`

```csharp
/// <summary>Response DTO for MyTable, with EF-translatable projection.</summary>
public record MyTableDto(int Id, string Nome, decimal Prezzo, DateTime CreatedAt)
{
    /// <summary>EF-translatable projection — new-initializer only, no extension methods.</summary>
    public static Expression<Func<MyTable, MyTableDto>> Projection =>
        e => new(e.Id, e.Nome, e.Prezzo, e.CreatedAt);
}

/// <summary>Reduced DTO — SELECT contains only Id and Nome.</summary>
public record MyTableSummaryDto(int Id, string Nome)
{
    public static Expression<Func<MyTable, MyTableSummaryDto>> Projection =>
        e => new(e.Id, e.Nome);
}
```

### `Filters/MyTableFilter.cs`

```csharp
/// <summary>Optional filters for querying MyTable. All fields nullable — none required.</summary>
public class MyTableFilter
{
    public string? Nome { get; set; }             // string → Contains
    public decimal? PrezzoMin { get; set; }       // numerici → uguaglianza o range
    public decimal? PrezzoMax { get; set; }
    public DateTime? CreatedAtFrom { get; set; }  // DateTime → coppia From/To
    public DateTime? CreatedAtTo { get; set; }

    /// <summary>Builds the EF-translatable WHERE expression from the populated fields.</summary>
    public Expression<Func<MyTable, bool>> ToExpression() =>
        e => (Nome == null || e.Nome.Contains(Nome))
          && (PrezzoMin == null || e.Prezzo >= PrezzoMin)
          && (PrezzoMax == null || e.Prezzo <= PrezzoMax)
          && (CreatedAtFrom == null || e.CreatedAt >= CreatedAtFrom)
          && (CreatedAtTo == null || e.CreatedAt <= CreatedAtTo);
}
```

### `Services/MyTableService.cs`

```csharp
/// <summary>Application service for MyTable: handlers depend on this, never on the provider.</summary>
public class MyTableService(MyTableProvider provider)
{
    /// <summary>Returns rows matching the filter, projected to the full DTO.</summary>
    public Task<List<MyTableDto>> GetAllAsync(MyTableFilter filter, CancellationToken ct) =>
        provider.GetMyTableAsync(filter, MyTableDto.Projection, ct);

    /// <summary>Returns rows matching the filter, projected to the reduced DTO (optimized SELECT).</summary>
    public Task<List<MyTableSummaryDto>> GetSummariesAsync(MyTableFilter filter, CancellationToken ct) =>
        provider.GetMyTableAsync(filter, MyTableSummaryDto.Projection, ct);

    /// <summary>Returns the row with the given Id, or null if not found.</summary>
    public Task<MyTableDto?> GetByIdAsync(int id, CancellationToken ct) =>
        provider.GetMyTableByIdAsync(id, MyTableDto.Projection, ct);

    /// <summary>Creates a new row from the validated request and returns the persisted DTO.</summary>
    public async Task<MyTableDto> CreateAsync(MyTableRequest request, CancellationToken ct)
    {
        var entity = ToEntity(request);
        var created = await provider.CreateMyTableAsync(entity, ct);
        return new MyTableDto(created.Id, created.Nome, created.Prezzo, created.CreatedAt);
    }

    /// <summary>Updates the row with the given Id. False if it does not exist.</summary>
    public Task<bool> UpdateAsync(int id, MyTableRequest request, CancellationToken ct)
    {
        var entity = ToEntity(request);
        entity.Id = id;
        return provider.UpdateMyTableAsync(entity, ct);
    }

    /// <summary>Deletes the row with the given Id. False if it does not exist.</summary>
    public Task<bool> DeleteAsync(int id, CancellationToken ct) =>
        provider.DeleteMyTableAsync(id, ct);

    /// <summary>Maps a validated request to the entity.</summary>
    private static MyTable ToEntity(MyTableRequest r) => new()
    {
        Nome = r.Nome!,
        Prezzo = r.Prezzo!.Value,
        CreatedAt = DateTime.UtcNow
    };
}
```

### `Validators/MyTableRequestValidator.cs`

```csharp
public class MyTableRequestValidator : AbstractValidator<MyTableRequest>
{
    public MyTableRequestValidator()
    {
        RuleFor(x => x.Nome)
            .NotEmpty()
            .MaximumLength(100);  // da schema varchar(100)

        RuleFor(x => x.Prezzo)
            .NotNull()
            .GreaterThan(0);
    }
}
```

### `Endpoints/MyTableMapping.cs` — endpoint generati

| Metodo | URL | Response | Descrizione |
|--------|-----|----------|-------------|
| `GET` | `/api/v1/mytable` | `200 List<MyTableDto>` / `404` / `400` | Lista con filtro opzionale |
| `GET` | `/api/v1/mytable/summary` | `200 List<MyTableSummaryDto>` / `404` / `400` | Lista ridotta |
| `GET` | `/api/v1/mytable/{id}` | `200 MyTableDto` / `404` | Riga per Id |
| `POST` | `/api/v1/mytable` | `201 MyTableDto` / `400` | Crea riga |
| `PUT` | `/api/v1/mytable/{id}` | `204` / `400` / `404` | Aggiorna riga |
| `DELETE` | `/api/v1/mytable/{id}` | `204` / `404` | Elimina riga |

---

## Regole dei tipi applicati automaticamente ai filtri

| Tipo colonna SQL | Tipo C# | Campo filter | Predicato in ToExpression |
|---|---|---|---|
| `varchar(N)` / `nvarchar(N)` | `string` | `string? Campo` | `(Campo == null \|\| e.Campo.Contains(Campo))` |
| `int` / `bigint` | `int` / `long` | `int? Campo` | `(Campo == null \|\| e.Campo == Campo)` |
| `decimal` / `numeric` | `decimal` | `decimal? CampoMin`, `decimal? CampoMax` | range `>=` / `<=` |
| `datetime` / `datetime2` | `DateTime` | `DateTime? CampoFrom`, `DateTime? CampoTo` | range `>=` / `<=` |
| `bit` | `bool` | `bool? Campo` | `(Campo == null \|\| e.Campo == Campo)` |
| `uniqueidentifier` | `Guid` | `Guid? Campo` | `(Campo == null \|\| e.Campo == Campo)` |

Tutti i campi filter sono **nullable** — nessun filtro è obbligatorio.

---

## Cosa NON viene generato

| Componente | Motivo |
|---|---|
| Repository pattern (`IRepository<T>`) | Vietato da convenzione — si usa il Provider direttamente |
| AutoMapper | Vietato — la Projection EF è la mappatura |
| MediatR | Vietato — gli handler chiamano il Service direttamente |
| Soft delete | Non incluso di default — va aggiunto manualmente se richiesto |
| Paginazione | Non inclusa di default — il filtro copre i casi d'uso comuni |

---

## Modifiche a file esistenti

| File | Modifica |
|---|---|
| `Program.cs` | Aggiunge `Add<Progetto>Provider(configuration)` e `AddScoped<MyTableService>()` |
| `appsettings.json` | Aggiunge connection string con placeholder |
| `appsettings.local.json` | Aggiunge connection string con valori reali (non committato) |
| `.gitignore` | Aggiunge `appsettings.local.json` se non presente |

---

*Revisione v1.0 — 2026-06-13 15:30 — claude-sonnet-4-6*
