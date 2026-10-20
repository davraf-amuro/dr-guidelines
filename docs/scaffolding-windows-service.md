# Scaffolding: Windows Service .NET 10

Questa guida mostra cosa succede quando si chiede a Claude Code (con i pacchetti `dr-guidelines` e `dr-winsvc` installati) di creare un nuovo Windows Service. Descrive le domande preliminari, la struttura generata e le convenzioni applicate.

`/dr-scaffold` (che delega a `/dr-scaffold-project` o `/dr-scaffold-solution`) crea il progetto `dotnet new worker`. Worker e configurazione li scrive l'assistente seguendo `windows-service.instructions.md` di `dr-winsvc`.

---

## Gate preliminare — cosa chiede Claude prima di procedere

Prima di creare qualsiasi file, Claude raccoglie tutto in un unico messaggio:

| # | Domanda | Default proposto |
|---|---------|-----------------|
| 1 | Nome del progetto | `<nomecartella>.service` in lowercase (suffisso del catalogo `scaffolding-catalog.json`) |
| 2 | Nome dei worker da creare | Es. `SyncOrders`, `Cleanup` |
| 3 | IntervalSeconds per ogni worker | Chiede se non specificato |
| 4 | Entity Framework Core necessario? | Chiede prima di aggiungere il pacchetto |

Solo la domanda 4 è fissata da `windows-service.instructions.md`. Le domande 1-3 sono la prassi dello scaffolding: le istruzioni non prevedono un gate. Da verificare.

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
        Logging/                     ← TaskIdEnricher, LogSubject, SubjectDefaultEnricher (da serilog-logging.instructions.md)
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

// Serilog: configurazione da serilog-logging.instructions.md (dr-dotnet-backend), fonte unica
builder.Services.AddSerilog((_, lc) => lc
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .Enrich.WithThreadId()
    .Enrich.With<TaskIdEnricher>()
    .Enrich.With<SubjectDefaultEnricher>());

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
  "ConnectionStrings": {
    "MioDb": "Server=PLACEHOLDER;Database=PLACEHOLDER;Integrated Security=True;TrustServerCertificate=True"
  }
}
```

- `ConnectionStrings` c'è solo se EF Core è confermato; il valore reale sta in `appsettings.local.json`.
- La sezione `Serilog` non si ricopia qui: si prende da `serilog-logging.instructions.md` (fonte unica). Nel worker l'override `Microsoft.AspNetCore` non serve. Il file di log è uno solo (`logs/app-.log`), non uno per worker.

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
| `Serilog.Settings.Configuration` | Lettura della sezione `Serilog` di `appsettings.json` |
| `Serilog.Sinks.File` | Sink file |
| `Serilog.Sinks.Console` | Sink console |
| `Serilog.Enrichers.Thread` | Enricher `ThreadId` |
| `Microsoft.EntityFrameworkCore.SqlServer` | ORM (solo se confermato) |

---

## Deploy come servizio Windows

Dopo la build:

```powershell
# Pubblica
dotnet publish src/<progetto>/<progetto>.csproj -c Release -o C:\Services\<nomesvc>

# Installa come servizio SCM
sc.exe create "<ServiceName>" binPath= "C:\Services\<nomesvc>\<progetto>.exe" start= auto
sc.exe start "<ServiceName>"
```

In PowerShell `sc` è un alias di `Set-Content`: usa sempre `sc.exe`. Con `sc.exe` lo spazio dopo `=` (`binPath= `, `start= `) è obbligatorio.

Per disinstallare:
```powershell
sc.exe stop "<ServiceName>"
sc.exe delete "<ServiceName>"
```

---

*Revisione v1.3 — 2026-10-20 21:00 — claude-opus-5-5*
