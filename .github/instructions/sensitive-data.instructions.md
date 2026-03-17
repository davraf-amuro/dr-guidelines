---
applyTo: "**"
---

# Gestione Dati Sensibili (AI Agent)

Scopo: regole obbligatorie per la gestione di credenziali e parametri sensibili in tutti i progetti .NET. Segui sempre. Testo ottimizzato per token.

## Regola fondamentale

Quando l'utente fornisce dati sensibili (credenziali, password, API key, connection string con server/database reali), **non metterli mai in file committati**.

| File | Cosa contiene | Committato |
|------|---------------|-----------|
| `appsettings.json` | Placeholder fake (es. `CHISSACHI`, `CHISSAQUALE`, `CHISSADOVE`) | ✅ Sì |
| `appsettings.local.json` | Valori reali forniti dall'utente | ❌ No |

## Cosa sono "dati sensibili"

- Password, API key, token, secret
- Connection string con server/database reali
- Username di accesso a sistemi esterni
- URL interni/privati (es. IP aziendali)

## Procedura

1. L'utente fornisce un valore reale → mettilo in `appsettings.local.json`
2. In `appsettings.json` → scrivi un placeholder ovvio come `CHISSACHI`, `CHISSAQUALE`, `CHISSADOVE`
3. Verifica che `appsettings.local.json` sia in `.gitignore`
4. Verifica che `appsettings.local.json` sia caricato in `Program.cs` (`AddJsonFile("appsettings.local.json", optional: true)`)

## Placeholder consigliati (stile progetto)

```json
{
  "ConnectionStrings": {
    "MyDb": "data source=CHISSADOVE;initial catalog=CHISSAQUALE;..."
  },
  "MyApi": {
    "BaseUrl": "http://CHISSADOVE/",
    "UserName": "CHISSACHI",
    "Password": "CHISSAQUALE"
  }
}
```

## Vietato

- Mettere credenziali reali in `appsettings.json`
- Mettere credenziali reali in `appsettings.Development.json` o altri file committati
- Lasciare campi vuoti `""` in `appsettings.json` (usa placeholder espliciti)

## ✅ Checklist

- [ ] `appsettings.json` ha solo placeholder per tutti i dati sensibili
- [ ] `appsettings.local.json` ha i valori reali
- [ ] `appsettings.local.json` è in `.gitignore`
- [ ] `appsettings.local.json` è caricato in `Program.cs`

*Template v1.1 - .NET 10 - Token-optimized for AI agents* - Last Update 2026-03-17 21:28
