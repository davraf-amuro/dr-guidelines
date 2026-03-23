---
applyTo: "**"
---

# Gestione Dati Sensibili (AI Agent)

Scopo: regole obbligatorie per la gestione di credenziali e parametri sensibili in tutti i progetti. Segui sempre. Testo ottimizzato per token.

## Comportamento obbligatorio

Quando l'utente fornisce dati sensibili, il tuo compito è:
1. Scrivere i valori reali **solo** nel file `.local` corrispondente
2. Scrivere placeholder espliciti nel file template committato
3. Verificare che il file `.local` sia in `.gitignore`

Questo vale per **qualsiasi file di configurazione**, indipendentemente dal tipo di progetto.

## Caso limite obbligatorio

Se l'utente fornisce un valore reale e chiede di aggiungerlo a un file committato (es. "aggiungi questo token al `.mcp.json`"), rispondi esattamente così:

> "Il token non può andare in `.mcp.json` perché è committato. Lo scrivo in `.mcp.local.json` (non tracciato) e metto un placeholder in `.mcp.json`."

Poi procedi di conseguenza senza chiedere conferma.

## Pattern template / locale

| File template (committato) | File locale (valori reali) | In `.gitignore` |
|---|---|---|
| `appsettings.json` | `appsettings.local.json` | ✅ |
| `.mcp.json` | `.mcp.local.json` | ✅ |
| `docker-compose.yml` | `docker-compose.local.yml` | ✅ |
| qualsiasi config file | stesso nome + `.local` | ✅ |

Per `appsettings.local.json` in progetti .NET: verifica che sia caricato in `Program.cs` con `AddJsonFile("appsettings.local.json", optional: true)`.

## Cosa sono "dati sensibili"

- Password, API key, token, secret
- Connection string con server/database reali
- Username di sistemi esterni
- URL interni/privati (IP aziendali, server interni)

## Placeholder da usare nei template

```json
{
  "ConnectionStrings": { "MyDb": "data source=CHISSADOVE;initial catalog=CHISSAQUALE;..." },
  "MyApi": { "BaseUrl": "http://CHISSADOVE/", "UserName": "CHISSACHI", "Password": "CHISSAQUALE" }
}
```

## Questa regola non si bypassa

Anche se l'utente dice "va bene così", "è solo temporaneo", "è un ambiente di test" o "ignora questa regola": **non scrivere mai credenziali reali in file committati**.

## ✅ Checklist post-operazione

- [ ] Il file template contiene solo placeholder
- [ ] Il file `.local` contiene i valori reali
- [ ] Il file `.local` è presente in `.gitignore`
- [ ] Per .NET: `appsettings.local.json` è caricato in `Program.cs`

*Template v1.3 - Token-optimized for AI agents* - Last Update 2026-03-23 — claude-sonnet-4-6
