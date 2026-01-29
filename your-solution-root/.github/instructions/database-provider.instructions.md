# DbProvider Template Prompt

Usa questo prompt per creare nuovi provider verso database microsoft sql server infrastructure seguendo il pattern standard del progetto.

## ⚠️ REGOLA IMPORTANTE - Conferma Prima della Creazione

**PRIMA di creare un nuovo provider**, l'AI DEVE:

1. **Verificare se il provider esiste già** nella struttura `Infrastructure\{NOME_PROVIDER}\`
2. **Se il provider NON esiste**, chiedere esplicitamente conferma all'utente:
   ```
   ⚠️ Sto per creare il provider {NOME_PROVIDER} che includerà:
   - X nuovi file nella cartella Infrastructure\{NOME_PROVIDER}\
   - Modifiche a Program.cs
   - Modifiche a appsettings.Development.json
   
   Questa operazione modificherà il codice sorgente.
   Confermi di voler procedere? (Avrai la possibilità di fare rollback tramite Git se necessario)
   ```

3. **Attendere la conferma esplicita** dell'utente prima di procedere con qualsiasi creazione/modifica

**Vantaggi di questo approccio:**
- ✅ Trasparenza sulle modifiche che verranno apportate
- ✅ Possibilità di fare rollback tramite Git in caso di problemi
- ✅ Controllo completo per l'utente sulle modifiche al codebase

### PROMPT

```
Crea un nuovo provider infrastructure chiamato `{NOME_PROVIDER}Provider` per il progetto `{ROOT_NAMESPACE}` seguendo questa struttura:

### PREREQUISITI

**Pacchetti NuGet:**
Prima di procedere, verifica che il progetto abbia installati i seguenti pacchetti NuGet per Entity Framework Core verso SQL Server:
- `Microsoft.EntityFrameworkCore.SqlServer`

Se i pacchetti sono già presenti, NON aggiornarli. Installa solo se mancanti.

### STRUTTURA FOLDER
Crea la seguente struttura sotto `src\{ROOT_NAMESPACE}\Infrastructure\{NOME_PROVIDER}\`:
- `{NOME_PROVIDER}DbContext.cs` (nella root della folder)
- `{NOME_PROVIDER}Provider.cs` (nella root della folder)
- `{NOME_PROVIDER}ProviderExtensions.cs` (nella root della folder - extension method per registrazione DI)
- `Entities\{NOME_ENTITA}.cs` (una o più entità)
- `Filters\{NOME_ENTITA}Filter.cs` (filtri corrispondenti)

### SPECIFICHE

**DbContext:**
- Namespace: `{ROOT_NAMESPACE}.Infrastructure.{NOME_PROVIDER}`
- Usa primary constructor con parametri OBBLIGATORI: 
  - `DbContextOptions<{NOME_PROVIDER}DbContext> options`
  - `ILoggerFactory loggerFactory`
- Eredita da `DbContext(options)`
- Esempio costruttore e OnConfiguring:
```csharp
public class {NOME_PROVIDER}DbContext(DbContextOptions<{NOME_PROVIDER}DbContext> options, ILoggerFactory loggerFactory) : DbContext(options)
{
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured && loggerFactory != null)
        {
            optionsBuilder.UseLoggerFactory(loggerFactory);
            optionsBuilder.EnableSensitiveDataLogging();
            optionsBuilder.LogTo(Console.WriteLine, LogLevel.Information);
        }
    }
    
    // DbSet properties qui
}
```
- DbSet per ogni entità: `public virtual DbSet<{ENTITA}> {ENTITA} { get; set; }`
- Override di `OnModelCreating` per configurare chiavi ed entità (usa Fluent API)

**Provider:**
- Namespace: `{ROOT_NAMESPACE}.Infrastructure.{NOME_PROVIDER}`
- Usa primary constructor con questi parametri OBBLIGATORI: 
  - `{NOME_PROVIDER}DbContext context` (il DbContext specifico)
  - `ILogger<{NOME_PROVIDER}Provider> logger`
- Esempio: `public class AntifrodeProvider(AntifrodeDbContext context, ILogger<AntifrodeProvider> logger)`
- Implementa metodi async per query con filtri
- Pattern: metodi che restituiscono `IQueryable<T>` o `List<T>`
- Usa `AsNoTracking()` per query read-only
- Logging delle operazioni di filtering con `logger.LogInformation`
- Supporto per proiezioni generiche con `Expression<Func<T, TResult>>`
- **IMPORTANTE**: Tutti i metodi che materializzano query (ToListAsync, FirstOrDefaultAsync, etc.) DEVONO accettare `CancellationToken cancellationToken` come ultimo parametro

**Entità (Entities\):**
- Namespace: `{ROOT_NAMESPACE}.Infrastructure.{NOME_PROVIDER}.Entities`
- Usa attributo `[Table("{NOME_TABELLA}")]` per mapping della tabella
- **OBBLIGATORIO**: Ogni proprietà deve avere l'attributo `[Column("{NomeColonna}")]` usando lo stesso nome del campo
- Esempio:
```csharp
[Table("Nome_Tabella")]
public class MiaEntity
{
    [Column("Id")]
    public int Id { get; set; }
    
    [Column("Nome")]
    public string? Nome { get; set; }
    
    [Column("DataCreazione")]
    public DateTime DataCreazione { get; set; }
}
```
- Proprietà con tipi appropriati (DateTime, int, string?, ecc.)
- Definisci le chiavi primarie (semplici o composite) usando Fluent API in `OnModelCreating`

**Filtri (Filters\):**
- Namespace: `{ROOT_NAMESPACE}.Infrastructure.{NOME_PROVIDER}.Filters`
- Proprietà nullable per filtri opzionali (es: `DateTime?`, `int?`)
- Nomi descrittivi tipo: `From{Campo}`, `To{Campo}`, `{Campo}Contains`
- **REGOLA IMPORTANTE**: Per ogni entità DEVE esistere il corrispondente filtro `Filters\{EntityName}Filter.cs`
  - Se viene creata una nuova entity o ne viene indicata una esistente, verificare che esista il filtro
  - Se il filtro non esiste, crearlo automaticamente con gli stessi campi dell'entity
  - Per campi di tipo `DateTime` o `DateTime?`, creare due proprietà nel filtro: `From{NomeCampo}` e `To{NomeCampo}` (entrambe `DateTime?`)
  - Per campi stringa, creare proprietà `{NomeCampo}Contains` (tipo `string?`)
  - Per campi numerici o booleani, usare lo stesso nome (nullable se appropriato)

### METODI PROVIDER OBBLIGATORI
Dopo aver creato tutte le classi, il provider DEVE contenere:

**Metodo con projection expression e CancellationToken** (OBBLIGATORIO):
```csharp
public async Task<List<TResult>> Get{EntityName}Async<TResult>(
    {EntityName}Filter filter,
    Expression<Func<{EntityName}, TResult>> selector,
    CancellationToken cancellationToken)
{
    var query = context.{EntityName}.AsNoTracking();

    // Applica tutti i filtri dalla filter class
    if (filter.FromData.HasValue)
        query = query.Where(e => e.Data >= filter.FromData.Value);

    if (filter.ToData.HasValue)
        query = query.Where(e => e.Data <= filter.ToData.Value);

    // ... altri filtri ...

    // Applica proiezione PRIMA di materializzare
    return await query.Select(selector).ToListAsync(cancellationToken);
}
```

**Note sul metodo:**
- Il metodo generico supporta sia il recupero dell'entità completa (passando `r => r` come selector) che proiezioni custom
- Il nome del metodo è `Get{EntityName}Async<TResult>` (senza "WithProjection" nel nome)
- Restituisce sempre `List<TResult>` per massima flessibilità
- Il parametro `selector` permette di selezionare solo i campi necessari, migliorando le performance

**ProviderExtensions (Extension Method per DI):**
- Namespace: `{ROOT_NAMESPACE}.Infrastructure.{NOME_PROVIDER}`
- Classe statica: `{NOME_PROVIDER}ProviderExtensions`
- Metodo di estensione: `Add{NOME_PROVIDER}Provider(this IServiceCollection services, IConfiguration configuration)`
- Configura DbContext e registra Provider come Scoped
- Esempio:
```csharp
using Microsoft.EntityFrameworkCore;

namespace {ROOT_NAMESPACE}.Infrastructure.{NOME_PROVIDER};

public static class {NOME_PROVIDER}ProviderExtensions
{
    public static IServiceCollection Add{NOME_PROVIDER}Provider(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<{NOME_PROVIDER}DbContext>(options =>
        {
            options.UseSqlServer(configuration.GetConnectionString("{NOME_PROVIDER}Db"));
            options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
            options.EnableSensitiveDataLogging();
            options.EnableDetailedErrors(true);
        });

        services.AddScoped<{NOME_PROVIDER}Provider>();

        return services;
    }
}
```

### REGISTRAZIONE IN PROGRAM.CS
Aggiungi l'using e la chiamata all'extension method in `Program.cs`:
```csharp
// Add using
using {ROOT_NAMESPACE}.Infrastructure.{NOME_PROVIDER};

// In builder services section
builder.Services.Add{NOME_PROVIDER}Provider(builder.Configuration);
```

**Vantaggi dell'Extension Method:**
- Program.cs più pulito e leggibile
- Configurazione centralizzata nella folder del provider
- Facile da testare e riutilizzare
- Migliore separazione delle responsabilità

---

## 📐 Pattern Architetturali del Progetto

### Convenzioni Generali
- **Target Framework:** .NET 10
- **Primary Constructors:** Usa sempre primary constructors per dependency injection
- **Async/Await:** Tutti i metodi che accedono a dati devono essere async
- **Logging:** Usa `ILogger<T>` con structured logging (`LogInformation`, `LogWarning`, `LogError`)
- **Nullable Reference Types:** Attivi, usa `?` per proprietà nullable

### Infrastructure Layer
- **Posizione:** `src\{ROOT_NAMESPACE}\Infrastructure\{DomainName}\`
- **Struttura:** 
  - DbContext nella root
  - Provider nella root
  - Entities in sottocartella
  - Filters in sottocartella

### Dependency Injection
- **Lifetime:** 
  - DbContext: Scoped
  - Provider: Scoped
  - Services: Scoped (default)

### Entity Framework Core
- **Query Tracking:** NoTracking di default per performance
- **Logging:** Abilitato sensitive data logging e detailed errors
- **Mappings:** Preferire Fluent API in `OnModelCreating`

---

## 🔄 Riferimento: Provider Antifrode (Implementazione Esistente)

### Struttura File
```
src\{ROOT_NAMESPACE}\Infrastructure\Antifrode\
├── AntifrodeDbContext.cs
├── AntifrodeProvider.cs
├── AntifrodeProviderExtensions.cs
├── Entities\
│   └── Log106.cs
└── Filters\
    └── Log106Filter.cs
```

### AntifrodeDbContext.cs
```csharp
using {ROOT_NAMESPACE}.Infrastructure.Antifrode.Entities;
using Microsoft.EntityFrameworkCore;

namespace {ROOT_NAMESPACE}.Infrastructure.Antifrode;

public class AntifrodeDbContext(DbContextOptions<AntifrodeDbContext> options, ILoggerFactory loggerFactory) : DbContext(options)
{
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured && loggerFactory != null)
        {
            optionsBuilder.UseLoggerFactory(loggerFactory);
            optionsBuilder.EnableSensitiveDataLogging();
            optionsBuilder.LogTo(Console.WriteLine, LogLevel.Information);
        }
    }

    public virtual DbSet<Log106> Log106 { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Log106>(entity =>
        {
            entity.HasKey(e => new { e.LogDate, e.BusinessGroup });
        });
    }
}
```

### AntifrodeProvider.cs
```csharp
using System.Linq.Expressions;
using {ROOT_NAMESPACE}.Infrastructure.Antifrode.Entities;
using {ROOT_NAMESPACE}.Infrastructure.Antifrode.Filters;
using Microsoft.EntityFrameworkCore;

namespace {ROOT_NAMESPACE}.Infrastructure.Antifrode;

public class AntifrodeProvider(AntifrodeDbContext context, ILogger<AntifrodeProvider> logger)
{
    public async Task<List<TResult>> GetLog106Async<TResult>(
        Log106Filter filter,
        Expression<Func<Log106, TResult>> selector,
        CancellationToken cancellationToken)
    {
        var query = context.Log106.AsNoTracking();

        if (filter.FromLogDate.HasValue)
        {
            logger.LogInformation("Filtering Log106 by FromLogDate: {FromLogDate}", filter.FromLogDate.Value);
            query = query.Where(l => l.LogDate >= filter.FromLogDate.Value);
        }

        if (filter.ToLogDate.HasValue)
        {
            logger.LogInformation("Filtering Log106 by ToLogDate: {ToLogDate}", filter.ToLogDate.Value);
            query = query.Where(l => l.LogDate <= filter.ToLogDate.Value);
        }

        // Applica proiezione PRIMA di materializzare
        return await query.Select(selector).ToListAsync(cancellationToken);
    }
}
```

### AntifrodeProviderExtensions.cs
```csharp
using Microsoft.EntityFrameworkCore;

namespace {ROOT_NAMESPACE}.Infrastructure.Antifrode;

public static class AntifrodeProviderExtensions
{
    public static IServiceCollection AddAntifrodeProvider(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<AntifrodeDbContext>(options =>
        {
            options.UseSqlServer(configuration.GetConnectionString("AntifrodeDb"));
            options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
            options.EnableSensitiveDataLogging();
            options.EnableDetailedErrors(true);
        });

        services.AddScoped<AntifrodeProvider>();

        return services;
    }
}
```

### Entities\Log106.cs
```csharp
using System.ComponentModel.DataAnnotations.Schema;

namespace {ROOT_NAMESPACE}.Infrastructure.Antifrode.Entities;

[Table("Log_106")]
public class Log106
{
    [Column("LogDate")]
    public DateTime LogDate { get; set; }
    
    [Column("BusinessGroup")]
    public int BusinessGroup { get; set; }
    
    [Column("RagioneSociale")]
    public string? RagioneSociale { get; set; }
    
    [Column("CallsCount")]
    public int CallsCount { get; set; }
}
```

### Filters\Log106Filter.cs
```csharp
namespace {ROOT_NAMESPACE}.Infrastructure.Antifrode.Filters;

public class Log106Filter
{
    public DateTime? FromLogDate { get; set; }
    public DateTime? ToLogDate { get; set; }
}
```

### Registrazione in Program.cs
```csharp
// Add using
using {ROOT_NAMESPACE}.Infrastructure.Antifrode;

// In builder services section
builder.Services.AddAntifrodeProvider(builder.Configuration);
```

---

## 📝 Note e Best Practices

### Performance
- Usa sempre `AsNoTracking()` per query read-only
- Applica proiezioni con `Select(selector)` PRIMA di `ToListAsync()` per ridurre dati trasferiti
- Evita `Include()` se non necessario
- Passa sempre `CancellationToken` ai metodi async per permettere cancellazione delle query

### Logging
- Log solo informazioni significative (applicazione filtri, errori, operazioni importanti)
- Usa structured logging con placeholder: `{PropertyName}`
- Livelli: Information per operazioni normali, Warning per situazioni anomale, Error per eccezioni

### Filtri
- Usa nullable types (`DateTime?`, `int?`, `string?`) per filtri opzionali
- Pattern nomi: `From{Campo}`, `To{Campo}`, `{Campo}Contains`, `Solo{Condizione}`
- Valida i filtri nel provider se necessario (es: FromDate <= ToDate)
- **Ogni entity DEVE avere il suo filtro corrispondente**, anche se vuoto inizialmente

### CancellationToken
- Tutti i metodi async che materializzano query (ToListAsync, FirstOrDefaultAsync, etc.) devono accettare CancellationToken
- Passa il token ai metodi EF Core: `ToListAsync(cancellationToken)`, `FirstOrDefaultAsync(cancellationToken)`, etc.
- Nei metodi che restituiscono IQueryable (query non materializzate) il CancellationToken non è necessario

### Testing
- Testa provider con filtri vuoti, singoli e multipli
- Verifica proiezioni custom con `Expression<Func<T, TResult>>`
- Mock del DbContext usando `DbContextOptions<T>` in-memory

### Controllo Versione (Git)
- **Prima della creazione**: L'AI chiede sempre conferma per nuovi provider
- **Durante lo sviluppo**: Fai commit frequenti per poter fare rollback granulare
- **In caso di problemi**: Usa `git status` per vedere i file modificati
- **Rollback completo**: `git reset --hard HEAD` (attenzione: annulla TUTTE le modifiche non committate)
- **Rollback selettivo**: `git checkout -- <file>` per ripristinare singoli file
- **Best practice**: Crea un branch dedicato per il nuovo provider: `git checkout -b feature/add-{provider}-provider`

---

## 🔌 Connection String Examples

### SQL Server - Standard Authentication
```json
{
  "ConnectionStrings": {
    "AntifrodeDb": "Server=localhost;Database=AntifrodeDB;User Id=sa;Password=YourPassword;TrustServerCertificate=True;Encrypt=False"
  }
}
```

### SQL Server - Windows Authentication
```json
{
  "ConnectionStrings": {
    "AntifrodeDb": "Server=localhost;Database=AntifrodeDB;Integrated Security=True;TrustServerCertificate=True"
  }
}
```

### SQL Server - Azure SQL Database
```json
{
  "ConnectionStrings": {
    "AntifrodeDb": "Server=tcp:myserver.database.windows.net,1433;Database=AntifrodeDB;User ID=username@myserver;Password=YourPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }
}
```

### Best Practices Connection Strings
- **Development**: Usa `appsettings.Development.json` per connection string locali
- **Production**: Usa User Secrets, Azure Key Vault o variabili d'ambiente
- **Never commit**: Non committare mai password in plain text nel repository
- **TrustServerCertificate**: Usa `True` solo in development, `False` in production

---

## 🧪 Testing Examples

### Unit Test con In-Memory Database

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace YourProject.Tests;

public class AntifrodeProviderTests
{
    private AntifrodeDbContext CreateInMemoryContext()
    {
        var options = new DbContextOptionsBuilder<AntifrodeDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        var loggerFactory = NullLoggerFactory.Instance;
        return new AntifrodeDbContext(options, loggerFactory);
    }

    [Fact]
    public async Task GetLog106Async_WithDateFilter_ReturnsFilteredResults()
    {
        // Arrange
        using var context = CreateInMemoryContext();
        context.Log106.AddRange(
            new Log106 { LogDate = new DateTime(2025, 1, 1), BusinessGroup = 1, CallsCount = 10 },
            new Log106 { LogDate = new DateTime(2025, 1, 15), BusinessGroup = 2, CallsCount = 20 },
            new Log106 { LogDate = new DateTime(2025, 2, 1), BusinessGroup = 3, CallsCount = 30 }
        );
        await context.SaveChangesAsync();

        var logger = NullLogger<AntifrodeProvider>.Instance;
        var provider = new AntifrodeProvider(context, logger);

        var filter = new Log106Filter
        {
            FromLogDate = new DateTime(2025, 1, 1),
            ToLogDate = new DateTime(2025, 1, 31)
        };

        // Act
        var results = await provider.GetLog106Async(filter, x => x, CancellationToken.None);

        // Assert
        Assert.Equal(2, results.Count);
        Assert.All(results, r => Assert.True(r.LogDate.Month == 1));
    }

    [Fact]
    public async Task GetLog106Async_WithProjection_ReturnsOnlySelectedFields()
    {
        // Arrange
        using var context = CreateInMemoryContext();
        context.Log106.Add(new Log106
        {
            LogDate = new DateTime(2025, 1, 1),
            BusinessGroup = 1,
            CallsCount = 100,
            RagioneSociale = "Test Company"
        });
        await context.SaveChangesAsync();

        var logger = NullLogger<AntifrodeProvider>.Instance;
        var provider = new AntifrodeProvider(context, logger);

        var filter = new Log106Filter();

        // Act - Proiezione custom
        var results = await provider.GetLog106Async(
            filter,
            x => new { x.LogDate, x.CallsCount },
            CancellationToken.None);

        // Assert
        Assert.Single(results);
        Assert.Equal(100, results[0].CallsCount);
    }

    [Fact]
    public async Task GetLog106Async_EmptyFilter_ReturnsAllResults()
    {
        // Arrange
        using var context = CreateInMemoryContext();
        context.Log106.AddRange(
            new Log106 { LogDate = new DateTime(2025, 1, 1), BusinessGroup = 1, CallsCount = 10 },
            new Log106 { LogDate = new DateTime(2025, 2, 1), BusinessGroup = 2, CallsCount = 20 }
        );
        await context.SaveChangesAsync();

        var logger = NullLogger<AntifrodeProvider>.Instance;
        var provider = new AntifrodeProvider(context, logger);

        var filter = new Log106Filter(); // Filtro vuoto

        // Act
        var results = await provider.GetLog106Async(filter, x => x, CancellationToken.None);

        // Assert
        Assert.Equal(2, results.Count);
    }
}
```

### Integration Test con Database Reale

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace YourProject.IntegrationTests;

public class AntifrodeProviderIntegrationTests : IDisposable
{
    private readonly AntifrodeDbContext _context;
    private readonly AntifrodeProvider _provider;

    public AntifrodeProviderIntegrationTests()
    {
        var configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.Test.json")
            .Build();

        var options = new DbContextOptionsBuilder<AntifrodeDbContext>()
            .UseSqlServer(configuration.GetConnectionString("TestDb"))
            .Options;

        var loggerFactory = NullLoggerFactory.Instance;
        _context = new AntifrodeDbContext(options, loggerFactory);

        var logger = NullLogger<AntifrodeProvider>.Instance;
        _provider = new AntifrodeProvider(_context, logger);
    }

    [Fact]
    public async Task GetLog106Async_WithRealDatabase_ExecutesCorrectly()
    {
        // Arrange
        var filter = new Log106Filter
        {
            FromLogDate = DateTime.Now.AddDays(-7),
            ToLogDate = DateTime.Now
        };

        // Act
        var results = await _provider.GetLog106Async(filter, x => x, CancellationToken.None);

        // Assert
        Assert.NotNull(results);
        // Ulteriori assertions basate sui dati reali
    }

    public void Dispose()
    {
        _context.Dispose();
    }
}
```

### Pacchetti NuGet per Testing
```xml
<ItemGroup>
  <PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" Version="10.0.0" />
  <PackageReference Include="xunit" Version="2.9.0" />
  <PackageReference Include="xunit.runner.visualstudio" Version="2.8.2" />
  <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.11.0" />
</ItemGroup>
```

---

## 🚀 Quick Start

Per creare un nuovo provider:

0. **⚠️ IMPORTANTE**: L'AI chiederà conferma prima di procedere se il provider non esiste
1. Copia il prompt template dalla sezione principale
2. Sostituisci i placeholder `{NOME_PROVIDER}`, `{NOME_ENTITA}`, `{ROOT_NAMESPACE}`, ecc.
3. Specifica i dettagli nella sezione "DETTAGLI IMPLEMENTAZIONE"
4. Fornisci il prompt completo all'AI
5. **Conferma la creazione** quando richiesto dall'AI
6. L'AI genererà tutti i file necessari e aggiungerà la registrazione in `Program.cs`
7. (Opzionale) Se qualcosa va storto, fai rollback tramite Git: `git reset --hard HEAD` o `git checkout -- .`

### ✅ Checklist Post-Generazione
Dopo la generazione automatica, verificare:
- [ ] Per ogni entity esiste il corrispondente filtro in `Filters\{EntityName}Filter.cs`
- [ ] I campi DateTime nell'entity hanno filtri `From{Campo}` e `To{Campo}` nel filtro
- [ ] Il provider contiene il metodo `Get{EntityName}Async<TResult>` con signature expression e `CancellationToken`
- [ ] Il metodo restituisce `List<TResult>` e accetta `Expression<Func<{EntityName}, TResult>> selector`
- [ ] Tutti i metodi che materializzano query hanno il parametro `CancellationToken cancellationToken`
- [ ] Il logging è presente per ogni filtro applicato
- [ ] Il file `{NOME_PROVIDER}ProviderExtensions.cs` è stato creato nella cartella del provider
- [ ] L'extension method configura correttamente DbContext e Provider
- [ ] La registrazione in `Program.cs` usa l'extension method `Add{NOME_PROVIDER}Provider(builder.Configuration)`
- [ ] Il namespace dell'extension è stato aggiunto in `Program.cs`
- [ ] La connection string è stata aggiunta in `appsettings.Development.json`

---

*Ultimo aggiornamento il 2025-01-29 - Versione 1.4*
