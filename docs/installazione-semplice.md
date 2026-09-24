# Installare dr-guidelines senza essere un programmatore

Questa guida è per chi **non scrive codice**. Per esempio: chi vuole usare le skill di scrittura, di revisione dei testi o di documentazione dentro VS Code con Claude Code o GitHub Copilot.

Non serve sapere cosa sia Git o PowerShell. Devi solo copiare alcuni comandi e premere **Invio**. Ogni passo dice cosa vedrai a schermo e cosa fare se qualcosa va storto.

> ⏱️ **Tempo:** circa 15 minuti la prima volta. Le volte successive bastano 2 minuti (passi 4-6).

---

## 📖 Tre parole che incontrerai

| Parola | Cosa significa per te |
|---|---|
| **Cartella di lavoro** | La cartella del tuo computer dove tieni i documenti del progetto. Le linee guida si installano lì dentro |
| **Terminale** | Un riquadro di VS Code dove si scrivono comandi invece di cliccare. Lo apri dal menu, non devi installarlo |
| **Skill** | Un comando pronto per l'assistente AI. Si richiama scrivendo `/` seguito dal nome, per esempio `/dr-professor` |

---

## ✅ Passo 1 — Controlla di avere il necessario

Ti servono quattro cose. Le prime due probabilmente le hai già.

| # | Cosa | Come capire se ce l'hai |
|---|---|---|
| 1 | Windows 10 o 11 | Lo stai usando |
| 2 | VS Code con l'assistente AI | Apri VS Code: nella barra laterale vedi l'icona di **Claude Code** o di **GitHub Copilot** |
| 3 | Git | Lo verifichi al passo 2. Se manca, lo installi lì |
| 4 | PowerShell 7 | Lo verifichi al passo 2. Se manca, lo installi lì |

**Non ti servono:** account GitHub, programmi di sviluppo (.NET, Node.js), permessi speciali di amministratore sul progetto.

> ❓ **Manca VS Code o l'assistente AI?** Chiedi a chi ti ha proposto queste linee guida: la loro installazione dipende dall'abbonamento che usi e non è coperta da questa guida.

---

## ✅ Passo 2 — Installa Git e PowerShell 7 (una volta sola)

Git serve all'installatore per scaricare le linee guida. PowerShell 7 è la versione aggiornata del programma che esegue i comandi.

1. Apri VS Code
2. Menu **Terminale** → **Nuovo terminale**. In basso si apre un riquadro con un cursore che lampeggia
3. Copia questa riga, incollala nel riquadro con **clic destro** e premi **Invio**:

   ```powershell
   git --version
   ```

4. Guarda la risposta:

   | Vedi | Significa | Cosa fai |
   |---|---|---|
   | `git version 2.…` | Git c'è | Vai al punto 6 |
   | Un messaggio rosso con `non è riconosciuto` oppure `not recognized` | Git manca | Vai al punto 5 |

5. Installa Git. Incolla questa riga e premi **Invio**:

   ```powershell
   winget install --id Git.Git -e
   ```

   Se Windows chiede **"Vuoi consentire a questa app di apportare modifiche?"**, rispondi **Sì**. Attendi la scritta `Installazione riuscita` (o `Successfully installed`).

6. Installa PowerShell 7. Incolla questa riga e premi **Invio**:

   ```powershell
   winget install --id Microsoft.PowerShell -e
   ```

   Se leggi che è **già installato**, va bene lo stesso: vai avanti.

7. **Chiudi VS Code del tutto e riaprilo.** Senza questo passaggio VS Code non vede i programmi appena installati.

> ⚠️ **`winget` non è riconosciuto?** Il tuo Windows non ha lo strumento di installazione di Microsoft. Scarica Git da [git-scm.com](https://git-scm.com/download/win) e PowerShell da [aka.ms/powershell](https://aka.ms/powershell), poi installali con doppio clic e **Avanti** su tutte le schermate.

---

## ✅ Passo 3 — Crea la cartella di lavoro

Se hai già una cartella con i tuoi documenti, puoi usare quella. Le linee guida **non cancellano e non modificano** i tuoi file: aggiungono solo i propri.

Se parti da zero:

1. Apri **Esplora file**
2. Crea una cartella nuova, per esempio `Documenti\Progetto-Manuale`

---

## ✅ Passo 4 — Apri la cartella in VS Code

Questo è il passo più importante. **L'installatore scrive nella cartella aperta in VS Code.** Se apri la cartella sbagliata, i file finiscono lì e nessun messaggio te lo segnala.

1. In VS Code: menu **File** → **Apri cartella…**
2. Scegli la cartella del passo 3 e clicca **Seleziona cartella**
3. Se compare **"Ritieni attendibili gli autori dei file in questa cartella?"**, rispondi **Sì, mi fido degli autori**
4. Controlla in alto a sinistra: il nome della cartella deve essere quello giusto

---

## ✅ Passo 5 — Lancia l'installazione

1. Menu **Terminale** → **Nuovo terminale**. Il terminale si apre già dentro la tua cartella
2. Controlla la riga che precede il cursore. Deve finire con il nome della tua cartella, per esempio:

   ```text
   PS C:\Users\mario\Documenti\Progetto-Manuale>
   ```

   Se il nome è diverso, **fermati** e torna al passo 4.

3. Copia questa riga, incollala con **clic destro** e premi **Invio**:

   ```powershell
   irm https://raw.githubusercontent.com/davraf-amuro/dr-guidelines/main/dr-guidelines-install.ps1 | iex
   ```

4. Attendi 10-30 secondi. Scorreranno delle righe colorate.

**Cosa vedrai se va tutto bene:**

```text
=== dr-guidelines ===
  Repo    : davraf-amuro/dr-guidelines
  Progetto: C:\Users\mario\Documenti\Progetto-Manuale
  Clonazione davraf-amuro/dr-guidelines...
  [OK]   ...
  [OK]   ...
  Completato: dr-guidelines
```

| Etichetta | Significato |
|---|---|
| `[OK]` verde | File aggiunto |
| `[SKIP]` grigio | File già presente, lasciato com'è. Normale |
| `[WARN]` giallo | Avviso: un file esistente non è stato toccato. L'installazione prosegue |
| Scritta rossa | Errore: vai a [Se qualcosa va storto](#-se-qualcosa-va-storto) |

L'ultima riga importante è **`Completato: dr-guidelines`**.

> 🧪 **Stato delle prove.** Questo comando breve funziona da quando i repository sono pubblici (21 settembre 2026), ma non è ancora stato provato sul campo da un utente non tecnico. Se non funziona, segnalalo a chi ti ha proposto le linee guida: esiste una forma alternativa già verificata, descritta nel [README](../README.md#-progetto-esistente--aggiungere-le-guidelines).

---

## ✅ Passo 6 — Ricarica VS Code e verifica

L'assistente legge le skill solo quando VS Code si avvia. Va ricaricato.

1. Premi insieme **Ctrl + Maiusc + P**. In alto si apre una barra di ricerca
2. Scrivi `Reload Window` e premi **Invio** (in italiano può comparire come **Ricarica finestra**)
3. Nella barra laterale di Explorer devono essere comparsi questi elementi nuovi:

   | Elemento | A cosa serve |
   |---|---|
   | Cartella `.claude` | Skill e impostazioni di Claude Code |
   | Cartella `.github` | Istruzioni lette da Claude Code e da GitHub Copilot |
   | Cartella `.ai` | Elenco dei pacchetti installati |
   | File `CLAUDE.md` | Regole di base per l'assistente |

4. Apri la chat di **Claude Code** e scrivi `/dr-`. Deve comparire un elenco di skill, per esempio `/dr-professor`.

> 💡 **Usi GitHub Copilot?** Le istruzioni in `.github` vengono lette da sole, senza fare nulla. Le skill `/dr-…` sono invece di Claude Code: in Copilot Chat trovi al loro posto alcuni comandi equivalenti scrivendo `/`.

**Fatto.** Le linee guida sono installate. I file nuovi fanno parte del progetto: non cancellarli.

---

## 🛟 Se qualcosa va storto

| Cosa vedi | Perché succede | Cosa fai |
|---|---|---|
| `git` non riconosciuto | Git manca, oppure VS Code non è stato riaperto | Rifai il passo 2, poi chiudi e riapri VS Code |
| `git clone fallito per davraf-amuro/...` | Il computer non raggiunge GitHub: rete assente, rete aziendale con filtri o VPN | Verifica di poter aprire [github.com](https://github.com) nel browser. In ufficio chiedi al supporto IT se GitHub è bloccato |
| `Impossibile caricare dr-guidelines-install-lib.ps1` | Come sopra: GitHub non raggiungibile | Come sopra |
| Scritta rossa con `irm` o `Invoke-RestMethod` | Collegamento a Internet interrotto o bloccato | Riprova tra un minuto. Se si ripete, come sopra |
| Nessuna skill con `/dr-` | VS Code non è stato ricaricato | Rifai il passo 6. Se ancora niente, chiudi e riapri VS Code |
| Le cartelle `.claude`, `.github`, `.ai` sono finite nella cartella sbagliata | Era aperta un'altra cartella | Vedi sotto |

### Come togliere un'installazione dalla cartella sbagliata

Vale **solo se quella cartella prima non conteneva questi elementi**. Se hai dubbi, fermati e chiedi aiuto: alcuni progetti li hanno già di loro.

In Esplora file, nella cartella sbagliata, elimina:

- le cartelle `.claude`, `.github`, `.ai`
- i file `CLAUDE.md`, `.editorconfig`, `.gitattributes`, `.gitignore`, `.mcp.json`

Poi ripeti dal passo 4 con la cartella giusta.

---

## 🔄 Aggiornare in futuro

Le linee guida migliorano nel tempo. Per ricevere gli aggiornamenti, apri la chat di Claude Code nella tua cartella e scrivi:

```text
/dr-get-latest
```

L'assistente aggiorna tutti i pacchetti installati e ti dice cosa è cambiato. I tuoi documenti non vengono toccati.

---

## 🔗 Per saperne di più

| Documento | Per chi |
|---|---|
| [README](../README.md) | Panoramica completa dei pacchetti e di tutte le skill |
| [Guida nuova soluzione](guida-nuova-soluzione.md) | Programmatori che creano un progetto software da zero |
| [Taccuino delle prove](bozza-manuale-installazione.md) | Chi mantiene le linee guida: cosa è stato provato e cosa no |

---

*Revisione v1.0 — 2026-09-24 22:44 — claude-opus-5-5*
