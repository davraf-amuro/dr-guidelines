# Scaffolding: Windows Service .NET 10

Questa guida mostra cosa succede quando si chiede a Claude Code (con i pacchetti `dr-guidelines` e `dr-winsvc` installati) di creare un nuovo Windows Service. Descrive le domande preliminari, la struttura generata e le convenzioni applicate.

`/dr-scaffold` crea il progetto `dotnet new worker`. Worker e configurazione li scrive l'assistente seguendo `windows-service.instructions.md` di `dr-winsvc`.

---

## Gate preliminare — cosa chiede Claude prima di procedere

Prima di creare qualsiasi file, Claude raccoglie tutto in un unico messaggio:

| # | Domanda | Default proposto |
|---|---------|-----------------|
| 1 | Nome del progetto | `<nomecartella>.service` in lowercase (suffisso del catalogo `scaffolding-catalog.json`) |
| 2 | Nome dei worker da creare | Es. `SyncOrders`, `Cleanup` |
| 3 | IntervalSeconds per ogni worker | Chiede se non specificato |
| 4 | Entity Framework Core necessario? | Chiede prima di aggiungere il pacchetto |

---

## Struttura generata

```
<soluzione>/
  src/
    <progetto>.service/
      Workers/
        <Name>Worker.cs              ← un file per worker, eredita BackgroundService
      Infrastructure/
        Provider/                    ← solo se EF Core confermato
          Entities/
            <Entity>.cs
          Filters/
            <Entity>Filter.cs
          <Progetto>DbContext.cs
          <Progetto>Provider.cs
          <Progetto>ProviderExtensions.cs
      Properties/
      appsettings.json
      appsettings.local.json         ← non committato (.gitignore)
      Program.cs
      <progetto>.csproj
  test/
  docs/
```

---

## File chiave — esempio con worker `SyncOrders`

### `Workers/SyncOrdersWorker.cs`

```csharp
/// <summary>Background worker that synchronizes orders at a configurable interval.</summary>
public class SyncOrdersWorker(
    ILogger<SyncOrdersWorker> logger,
    IOptions<SyncOrdersOptions> options) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Worker {Worker} started", nameof(SyncOrdersWorker));

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await DoWorkAsync(stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error in worker {Worker}", nameof(SyncOrdersWorker));
            }

            await Task.Delay(TimeSpan.FromSeconds(options.Value.IntervalSeconds), stoppingToken);
        }

        logger.LogInformation("Worker {Worker} stopped", nameof(SyncOrdersWorker));
    }

    /// <summary>Executes the business logic for one cycle.</summary>
    private async Task DoWorkAsync(CancellationToken ct)
    {
        logger.LogInformation("Executing job {Worker}", nameof(SyncOrdersWorker));
        // logica business...
        await Task.CompletedTask;
    }
}
```

### `Program.cs`

```csharp
var builder = Host.CreateApplicationBuilder(args);

// Segreti e valori locali: file non committato, opzionale
builder.Configuration.AddJsonFile("appsettings.local.json", optional: true);

builder.Services.AddWindowsService(options =>
    options.ServiceName = builder.Configuration["Service:Name"]!);

// Configurazione strongly-typed per worker
builder.Services.Configure<SyncOrdersOptions>(
    builder.Configuration.GetSection("Workers:SyncOrders"));

// Registrazione worker
builder.Services.AddHostedService<SyncOrdersWorker>();

// Serilog
builder.Services.AddSerilog((services, cfg) => cfg.ReadFrom.Configuration(builder.Configuration));

var host = builder.Build();
host.Run();
```

### Configurazione strongly-typed

```csharp
// Workers/Options/<Worker>Options.cs — una classe per worker.
public class SyncOrdersOptions
{
    public int IntervalSeconds { get; set; } = 60;
}
```

### `appsettings.json`

```json
{
  "Service": {
    "Name": "MioServizio"
  },
  "Workers": {
    "SyncOrders": {
      "IntervalSeconds": 60
    }
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "System": "Warning"
      }
    }
  },
  "ConnectionStrings": {
    "MioDb": "Server=PLACEHOLDER;Database=PLACEHOLDER;Integrated Security=True;TrustServerCertificate=True"
  }
}
```

---

## Multi-worker — struttura con due worker

```csharp
// Program.cs con più worker
builder.Services.Configure<SyncOrdersOptions>(builder.Configuration.GetSection("Workers:SyncOrders"));
builder.Services.Configure<CleanupOptions>(builder.Configuration.GetSection("Workers:Cleanup"));

builder.Services.AddHostedService<SyncOrdersWorker>();
builder.Services.AddHostedService<CleanupWorker>();
```

```json
// appsettings.json
"Workers": {
  "SyncOrders": { "IntervalSeconds": 60 },
  "Cleanup":    { "IntervalSeconds": 3600 }
}
```

Ogni worker ha il proprio file `Workers/<Name>Worker.cs` e la propria classe `<Name>Options`. Non si condividono. Le istruzioni non fissano la cartella; il prompt `card-worker-service.prompt.md` di `dr-winsvc` le cerca in `Workers/Options/`.

---

## Convenzioni applicate automaticamente

| Convenzione | Dettaglio |
|---|---|
| Loop | `while (!stoppingToken.IsCancellationRequested)` — mai loop infiniti senza token |
| Delay | `Task.Delay(interval, stoppingToken)` — interrompibile allo stop del servizio |
| Error handling | `OperationCanceledException` catturata separatamente da `Exception` — evita log errato come errore |
| Graceful shutdown | `ExecuteAsync` con try/catch — il servizio non va in crash silenzioso |
| `Thread.Sleep` | **Vietato** — blocca il thread e il shutdown SCM |
| Primary constructors | Obbligatori su tutti i worker |
| CancellationToken | Sempre ultimo parametro nei metodi privati che materializzano I/O |
| Logging strutturato | Placeholder, mai string interpolation — es. `{Worker}`, `{@Filter}` |
| `appsettings.local.json` | Aggiunto e in `.gitignore` — credenziali reali solo qui |
| Commenti | `///` su ogni worker e metodo non banale |

---

## Pacchetti NuGet installati

| Pacchetto | Motivo |
|---|---|
| `Microsoft.Extensions.Hosting.WindowsServices` | `AddWindowsService` + integrazione SCM |
| `Serilog.Extensions.Hosting` | Serilog su `HostApplicationBuilder` (`AddSerilog`) |
| `Serilog.Sinks.File` | Sink file |
| `Serilog.Sinks.Console` | Sink console |
| `Microsoft.EntityFrameworkCore.SqlServer` | ORM (solo se confermato) |

---

## Deploy come servizio Windows

Dopo la build:

```powershell
# Pubblica
dotnet publish src/<progetto>/<progetto>.csproj -c Release -o C:\Services\<nomesvc>

# Installa come servizio SCM
sc.exe create "<ServiceName>" binPath="C:\Services\<nomesvc>\<progetto>.exe" start=auto
sc.exe start "<ServiceName>"
```

In PowerShell `sc` è un alias di `Set-Content`: usa sempre `sc.exe`.

Per disinstallare:
```powershell
sc.exe stop "<ServiceName>"
sc.exe delete "<ServiceName>"
```

---

*Revisione v1.2 — 2026-10-11 21:30 — claude-opus-5-5*
