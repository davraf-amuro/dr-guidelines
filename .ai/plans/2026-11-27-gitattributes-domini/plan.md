# Piano: `.gitattributes` identico al core negli 8 repo di dominio
Data: 2026-11-27
Stato: COMPLETATO
Issue: dr-dotnet-backend#8, dr-minimalapi#7, dr-efdb#4, dr-fe#6, dr-winsvc#3, dr-devops#3, dr-ux-lcars#1, dr-ux-kitt#1 (tutte `davraf-amuro/<repo>`); origine dr-guidelines#34
Branch: `plan/gitattributes` in ciascun repo (autonomia concessa dall'utente il 2026-11-27: piano, commit, PR, merge e cancellazione del branch senza approvazione per fase)

## Obiettivo
Ogni repo di dominio ha il `.gitattributes` del core e un index normalizzato (`git ls-files --eol` senza `i/crlf` né `i/mixed` sui file di testo).

## Scope
### File da modificare (per ciascun repo)
- [x] `.gitattributes` — CREATE, copia byte per byte di `dr-guidelines/.gitattributes`
- [x] file già tracciati con index CRLF/misto — rinormalizzati da `git add --renormalize .` (solo fine riga)

### Perimetro negativo
- Nessun altro contenuto modificato; nessun `.editorconfig`; nessun file del core

## Fasi
### Fase 1: per ciascuno degli 8 repo, in serie (sub-agente sonnet)
- **Stato**: [x]
- **Azione**: da `main` aggiornato: branch `plan/gitattributes`, copia `.gitattributes`, `git add --renormalize .`, controllo `git diff --cached --ignore-cr-at-eol --stat` = solo `.gitattributes` + cambi di fine riga; Gate (lint del repo se esiste, altrimenti "non applicabile" con motivo; index pulito); commit `chore: .gitattributes identico al core dr-guidelines` con `Closes #N`; push; PR; CI verde; merge `--merge --delete-branch`; `main` locale aggiornato
- **Verifica passo**: issue chiusa, solo `main` sul remoto, `git ls-files --eol` senza `i/crlf|i/mixed` su file di testo

### Fase 2: Verifica finale
- **Stato**: [x]
- **Modello**: sessione — controllo meccanico al posto di opus (confronto byte per byte, conteggi): scelta dichiarata

**Esito (2026-11-27)** — 8/8: `.gitattributes` identico al core (`cmp`), 0 righe `i/crlf|i/mixed`, issue CLOSED, solo `main` sul remoto. PR: dr-dotnet-backend#10, dr-minimalapi#8, dr-efdb#5, dr-fe#7, dr-winsvc#4, dr-devops#4, dr-ux-lcars#2, dr-ux-kitt#2. Nessun file oltre a `.gitattributes` (index già LF ovunque). Lint non applicabile: repo senza csproj/sln/package.json.

## Criteri di verifica finale
- [x] 8 `.gitattributes` identici al core
- [x] 8 index senza `i/crlf|i/mixed` su file di testo
- [x] 8 issue chiuse, 8 PR unite, nessun branch residuo
