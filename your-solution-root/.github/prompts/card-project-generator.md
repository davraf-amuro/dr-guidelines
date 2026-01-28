# PROMPT PER LA GENERAZIONE DELLA SCHEDA

Sei un analista programmatore che deve generare una scheda riassuntiva con i dati salienti del sorgente.
Non inserire dati non richiesti.
Non inventare dati che non esistono.

## 1. Creazione del file di riepilogo

Nella radice del sorgente assicurati ci sia una cartella chiamata `docs`
In questa cartella, per ogni progetto del sorgente, crea un file markdown chiamato `card-<nome_progetto>.md` o aggiornalo se già esiste
Se ti trovi in una solution di Visual Studio (.sln o .slnx) tenda di referenziare cartella e files nei file .sln/.slnx

## 2. Analisi Automatica

Prima di generare la card, analizza i seguenti file (se presenti):
- `.csproj` o file di progetto per identificare target framework, versioni, pacchetti
- `appsettings.json` e `appsettings.*.json` per configurazioni, connection strings, endpoints
- `launchSettings.json` per porte e profili
- `Program.cs` o entry point per pattern architetturali
- `DbContext` o classi repository per connessioni database
- Using statements per identificare framework utilizzati

## 3. Template del File di Riepilogo

Ogni file `card-<nome_progetto>.md` deve seguire questa struttura:

```markdown
# 🎯 Card: [Nome Progetto]

## 📋 Identificazione
- **Progetto:** 
- **Solution:** [solo se presente file .sln o .slnx, riporta il nome del file tra parentesi, es: NomeSolution.sln]
- **Workspace:** [solo se NON presente solution ma presente workspace VS Code .code-workspace, riporta il nome del file tra parentesi, es: NomeWorkspace.code-workspace]
- **Repository:** [URL Git/TFS senza branch]
- **Tipo Applicazione:** [Web API / Console App / Class Library / Desktop / Worker Service]
- **Pattern Architetturale:** [Minimal API / Clean Architecture / MVC / N-Tier / ecc.]
- **Versione Corrente:** 
- **Owner/Team:** 
- **Contatto Supporto:** 

## 🔧 Stack Tecnologico
- **Linguaggio Principale:** [es: C# 14.0]
- **Framework:** [es: .NET 10]
- **Target Framework:** [es: net10.0]
- **SDK Version:** 

## 📚 Dipendenze

### Progetti Interni
[Elenco progetti referenziati nella stessa solution]
- NomeProgetto.Core v1.0
- NomeProgetto.Shared v2.3

### Pacchetti Esterni
| Pacchetto | Versione | Scopo |
|-----------|----------|-------|
| Microsoft.EntityFrameworkCore | x.x.x | ORM per database |
| ... | ... | ... |

## 💾 Database

| Connection String Key | Nome Database | Tipo | Server/Host | Username | Provider/ORM |
|-----------------------|---------------|------|-------------|----------|--------------|
| ... | ... | SQL Server / PostgreSQL / MySQL / MongoDB | ... | ... | EF Core / Dapper / ADO.NET |

## 🌐 Servizi Esterni

| Tipo | Nome/Endpoint | Protocollo | Autenticazione | Scopo/Descrizione |
|------|---------------|------------|----------------|-------------------|
| REST API | https://api.example.com | HTTPS/REST | Bearer Token | Servizio notifiche |
| Message Bus | rabbitmq://server:5672 | AMQP | User/Password | Code messaggi asincroni |
| SOAP Service | https://legacy.example.com/service.asmx | SOAP/XML | Basic Auth | Integrazione sistema legacy |
| SignalR Hub | https://hub.example.com | WebSocket | JWT | Real-time notifications |

## ⚙️ Configurazione e Hosting

### Entry Point
- **Entrypoint:** se si tratta di api riporta semplicemente `Program.cs` o `localhost`. se è presente uan UI come swagger o scalar riporta il path `localhost/[path-della-ui]` come configurato. se si tratta di una dll o file eseguibile riporta la prima funzione di avvio.

## 📝 Documentazione API

- **OpenAPI/Swagger:** [URL o path, es: /swagger - solo Development]
- **Documentazione UI:** [Swagger UI / Scalar / ReDoc / Altra]
- **Versioning API:** [URL Segment / Query String / Header / Nessuno]
- **Versioni Supportate:** [es: v1, v2]

## 4. Regole di Compilazione

- Se un campo/sezione non ha dati disponibili, **lascialo vuoto** ma mantieni la struttura
- Non inventare dati che non esistono nel codice sorgente
- Per le tabelle, se non ci sono dati, lascia solo l'header
- Usa emoji solo come da template (migliora la leggibilità)
- Inserisci valori reali estratti dall'analisi dei file
- Per informazioni sensibili (password, secret keys) indica solo il **nome della variabile**, mai il valore
- Se la solution contiene molti progetti, crea una card per ogni progetto + opzionalmente una `card-solution.md` con overview generale
- non riepilogare nella risposta del prompt i dati estratti, dimmi solo card generate

## 5. Ultimo aggiornamento

indica sempre in fondo alla scheda la data dell'ultima generazione e il motore llm usato.
esempio
*Card generata il: [data] | Versione template: 2.0*

---
*Ultimo aggiornamento template: 2026 - v2.0*
