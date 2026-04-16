---
applyTo: "**"
---

# Code Organization — Struttura e Responsabilità del Codice

Scopo: regole trasversali a tutti i linguaggi per organizzare il codice in modo leggibile, manutenibile e riusabile. Si applicano a qualsiasi progetto, indipendentemente dallo stack.

---

## Regola 1 — Una classe = un file

- Ogni classe, interfaccia, enum o tipo composto ha il suo file dedicato.
- Il nome del file corrisponde al nome della classe (case convention del linguaggio).
- Non raggruppare classi non correlate nello stesso file.

```
// ✅ corretto
UserDto.cs
EmailService.ts
order_mapper.py

// ❌ sbagliato
Models.cs         // contiene UserDto, OrderDto, ProductDto insieme
helpers.ts        // contiene logica email, parsing, validazione mescolati
```

---

## Regola 2 — Cartella = ruolo della classe

La cartella in cui si trova un file comunica il suo ruolo nel sistema. Usare la struttura più adatta al progetto, ma rispettare la semantica:

| Cartella | Contenuto |
|---|---|
| `Dto/` o `Models/` | Oggetti di trasporto dati. Solo proprietà, nessuna logica. |
| `Services/` | Logica applicativa. Orchestrazione di operazioni. |
| `Repositories/` o `Infrastructure/` | Accesso a dati persistenti (DB, file, API esterne). |
| `Mappers/` o `Transformers/` | Conversioni tra tipi (es. entità → DTO). |
| `Helpers/` o `Utils/` | Funzioni generiche riutilizzabili, stateless. |
| `Validators/` | Validazione di input e regole di business. |
| `Events/` o `Handlers/` | Definizione eventi e relativi gestori. |
| `Factories/` | Creazione di oggetti complessi o condizionali. |

Aggiungere nuove cartelle solo se motivate da un concetto di dominio reale — non per organizzazione arbitraria.

---

## Regola 3 — Separazione funzioni generiche vs specifiche (SRP)

**Principio**: se una funzione può essere usata da più di un contesto, non appartiene alla classe che la usa per prima.

### Sintomo da evitare

Un metodo privato cresce fino a diventare logica riutilizzabile ma rimane nascosto nella classe che lo ha originato. Questo rende impossibile il riuso e aumenta il coupling.

### Regola pratica

> Una funzione è generica se la sua implementazione non dipende dallo stato o dal contesto specifico della classe ospite.

```csharp
// ❌ sbagliato: GetTemplate è logica generica nascosta in EmailService
public class EmailService
{
    public async Task SendAsync(string to, string templateName)
    {
        var template = await GetTemplate(templateName); // ← dovrebbe stare altrove
        // ...
    }

    private async Task<string> GetTemplate(string name) { /* legge da disco/DB */ }
}

// ✅ corretto: GetTemplate estratto in TemplateService
public class TemplateService
{
    public async Task<string> GetAsync(string name) { /* logica generica */ }
}

public class EmailService(TemplateService templates)
{
    public async Task SendAsync(string to, string templateName)
    {
        var template = await templates.GetAsync(templateName);
        // ...
    }
}
```

```typescript
// ❌ sbagliato: parser CSV annidato nel servizio di importazione
class ImportService {
  import(raw: string) {
    const rows = this.parseCsv(raw); // ← logica generica
    // ...
  }
  private parseCsv(data: string): string[][] { /* ... */ }
}

// ✅ corretto: parser estratto
// utils/csv-parser.ts
export function parseCsv(data: string): string[][] { /* ... */ }

// services/import-service.ts
import { parseCsv } from '../utils/csv-parser';
class ImportService {
  import(raw: string) {
    const rows = parseCsv(raw);
    // ...
  }
}
```

---

## Regola 4 — Pattern adatti alla situazione

Scegliere il pattern giusto per il problema reale. Non applicare pattern per abitudine o per dimostrare architettura.

### Pattern e quando usarli

**Strategy** — comportamento intercambiabile a runtime
```
Problema: più provider di notifica (email, SMS, push), stessa interfaccia.
Soluzione: interfaccia INotificationSender, implementazioni separate per canale.
```

**Factory / Factory Method** — creazione condizionale o complessa
```
Problema: l'oggetto da creare dipende da configurazione o input.
Soluzione: factory che incapsula la logica di selezione e costruzione.
```

**Decorator** — aggiungere comportamento senza modificare la classe
```
Problema: aggiungere caching o logging a un servizio esistente.
Soluzione: wrapper che implementa la stessa interfaccia e delega al wrapped.
```

**Observer / Event** — disaccoppiamento produttore/consumatore
```
Problema: più componenti devono reagire a un evento (es. ordine creato).
Soluzione: evento pubblicato dal produttore, handler registrati separatamente.
```

**Pipeline / Chain of Responsibility** — trasformazioni sequenziali
```
Problema: un input deve passare per più step di trasformazione o validazione.
Soluzione: catena di handler, ognuno con una responsabilità sola.
```

### Regola di motivazione

Prima di applicare un pattern, dichiarare esplicitamente:
> "Uso [Pattern] perché [problema concreto che risolve in questo contesto]."

Se la risposta è "perché si fa così" o "perché l'ho sempre usato" → non applicarlo.

---

## Regola 5 — Dipendenze tra classi

- Le dipendenze vanno dichiarate esplicitamente (costruttore o parametro), non istanziate internamente.
- Una classe non crea le proprie dipendenze: le riceve.
- Evitare dipendenze circolari — se due classi dipendono l'una dall'altra, estrarre un terzo concetto che le disaccoppia.

---

## ✅ Checklist pre-commit

- [ ] Ogni classe, interfaccia o tipo ha il suo file dedicato?
- [ ] Il nome del file corrisponde al nome della classe?
- [ ] La cartella riflette il ruolo della classe nel sistema?
- [ ] Ci sono metodi privati che potrebbero essere estratti in un servizio/helper generico?
- [ ] Il pattern scelto è motivato da un problema concreto, non da abitudine?
- [ ] Le dipendenze sono iniettate, non istanziate internamente?

---

*Istruzione v1.0 - Code Organization - 2026-04-16 — claude-sonnet-4-6*
