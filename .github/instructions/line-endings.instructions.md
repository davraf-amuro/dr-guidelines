---
applyTo: "**"
---

# Line endings — Fine riga dei file scritti da generatori e script

Regola trasversale (tutti gli stack). Il fine riga di ogni file lo decide `.gitattributes`: di default LF, CRLF solo per `.ps1`, `.cmd`, `.bat`, `.sln`. Su Windows con `core.autocrlf=true` (il default di Git for Windows), i generatori e le scritture da shell producono invece CRLF o fine riga misti. Il Gate di Push li rileva, ma è meglio che non nascano.

---

## 1. Quando si applica

Dopo ogni comando che **crea o riscrive file** nel repository senza passare dall'editor:

- generatori: `dotnet new`, `dotnet ef migrations add`, `dotnet add package`, `dotnet sln add`, `npm create`, `npm init`
- scritture da PowerShell: `Set-Content`, `Out-File`, `ConvertTo-Json | ...`, here-string scritte su file
- copie da altri repository o cartelle (`Copy-Item`, `cp`)
- installazione del core su un repository **esistente**: `.gitattributes` ed `.editorconfig` arrivano dopo i file già committati, che con `core.autocrlf=true` restano in CRLF nel working tree (il lint .NET fallisce con `ENDOFLINE`); qui lo script va lanciato senza `-Path`

Non serve dopo una modifica fatta con lo strumento di modifica dell'agente (es. Edit di Claude Code) su un file già allineato.

---

## 2. Cosa fare

Esegui lo script del core sui file toccati:

```powershell
pwsh scripts/normalize-eol.ps1 -Path <file-o-cartella>[,<altro>]
```

Senza `-Path` prende i file modificati, aggiunti e non tracciati di `git status`, più i file tracciati che `git ls-files --eol` segnala fuori norma nel working tree (es. committati prima che arrivasse `.gitattributes`):

```powershell
pwsh scripts/normalize-eol.ps1
```

Senza PowerShell 7 vale `powershell -ExecutionPolicy Bypass -File scripts/normalize-eol.ps1` (Windows PowerShell 5.1). Molti percorsi, o percorsi con la virgola → `-ListFile <file>` con un percorso per riga.

Lo script:
- legge `git check-attr text eol` per ogni file e riscrive in place solo il fine riga
- conserva BOM e contenuto, salta i binari: vale anche per file con modifiche in corso
- con `-Check` non scrive nulla ed esce con `1` se c'è qualcosa da correggere

Lo porta nell'host l'installer del core (`scripts/normalize-eol.ps1`). Lo script assente → reinstalla il core con `-Update`; non sostituirlo con `git checkout` dei file.

---

## 3. Limiti dichiarati

- **Claude Code**: nessun hook automatico. Un hook `PostToolUse` è rimandato (costo di 0,3-1 s a ogni comando): la normalizzazione si chiede in questa regola, a fine scaffolding e al Gate di Push.
- **Copilot e Codex**: stessa regola, eseguita a mano dall'agente o dall'utente.
- Percorsi con la virgola: non supportati da `-Path` (la virgola separa i valori); usa `-ListFile`.

---

## ✅ Checklist

- [ ] Dopo generatori, copie o scritture da shell: `scripts/normalize-eol.ps1` eseguito sui file toccati
- [ ] `scripts/normalize-eol.ps1 -Check` esce `0` prima del commit

---

*Istruzione v1.1 - Line Endings - 2026-11-27 — claude-opus-5-5 — caso dell'install del core su un repository esistente (davraf-amuro/dr-dotnet-backend#7)*
