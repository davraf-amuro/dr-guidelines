# Prompt per generazione README

Sei un agente che deve creare o aggiornare `docs/README.md` seguendo la struttura e lo stile del file di riferimento. Usa solo dati presenti nel repository, senza inventare informazioni.

## Obiettivo
Genera un README nella cartella `docs` con:
- titolo progetto
- panoramica breve
- sezione documentazione che elenca tutti i file presenti in `docs`
- sezione Quick Links mantenuta con la stessa struttura e URL del README di riferimento

## Istruzioni operative
1. Leggi `docs/README.md` e replica struttura, titoli, emoji e ordine delle sezioni.
2. Scrivi una panoramica breve e concreta del progetto.
3. Nella sezione **Documentazione (cartella `docs`)**, elenca tutti i file `.md` presenti in `docs` **escluso** il README stesso se autoreferenziale.
4. Per ogni file elencato, aggiungi una descrizione brevissima (una frase corta).
5. Mantieni la sezione **Quick Links** invariata (stessa struttura e URL).
6. Non aggiungere sezioni extra.

## Documenti da includere nella sezione documentazione
Elenca (con descrizione breve) tutti i file presenti in `docs` tranne readme.md se esiste

## Ultimo aggiornamento

Ottieni la data corrente con `Get-Date -Format "yyyy-MM-dd"` e genera il footer:

```markdown
---
*Card generata il: yyyy-MM-dd | Versione template: x.x | LLM: GitHub Copilot*
```

La versione template è nell'ultima riga di questo file.

## Regole
- Non inventare dati.
- Mantieni il tono conciso.
- Se un file non esiste, non inserirlo.

---
*Ultimo aggiornamento il 2025-01-29 - Versione 1.4*
