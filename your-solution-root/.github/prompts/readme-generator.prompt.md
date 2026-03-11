# Prompt: README Generator (AI Agent)

Crea o aggiorna README.md usando solo dati presenti nel repository. Non inventare.

## Obiettivo
- Titolo progetto
- Panoramica breve
- Sezione Documentazione (docs/) con elenco file .md
- Sezione Quick Links invariata

## Istruzioni operative
1) Panoramica breve (max 3 righe): tipo applicazione, stack principale, scopo
2) Elenca tutti i .md in docs/ (escludi readme.md se autoreferenziale)
3) Una descrizione breve per ogni file
4) Quick Links identici a quelli del README di riferimento
5) Nessuna sezione extra

## Template
```markdown
# NomeProgetto

Breve descrizione del progetto (tipo app, stack, scopo). Max 3 righe.

## Documentazione

| File | Descrizione |
|------|-------------|
| [endpoint-xxx.md](docs/endpoint-xxx.md) | Endpoint del gruppo xxx |
| [card-progetto.md](docs/card-progetto.md) | Card riassuntiva del progetto |

## Quick Links
- ...

---
*Aggiornato il: yyyy-MM-dd | LLM: {LLM}*
```

## Footer
Usa la data odierna nel formato `yyyy-MM-dd`:
```markdown
---
*Aggiornato il: yyyy-MM-dd | LLM: {LLM}*
```

## Regole
- Non inventare dati
- Tono conciso
- Se un file non esiste, non inserirlo

## ✅ Checklist Post-Generazione
- [ ] README.md aggiornato con titolo e panoramica (max 3 righe)
- [ ] Documentazione: tutti i .md in docs/ elencati
- [ ] Quick Links invariati
- [ ] Nessuna sezione extra
- [ ] Footer con data e LLM

*Template v1.2 - .NET 10 - Token-optimized for AI agents* - Last Update 2026-03-11
