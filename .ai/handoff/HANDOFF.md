# Progetto

`dr-guidelines` — pacchetto core della suite `dr-*`: linee guida, istruzioni modulari, prompt e skill per Claude Code e GitHub Copilot, distribuiti come pacchetti installabili via PowerShell.

Repo: `davraf-amuro/dr-guidelines`. Workspace locale: `E:\Davide\Progetti\dr-guidelines-workspace\` con i 7 repo `dr-*` come sottocartelle sorelle.

---

# Obiettivo

Chiudere le issue aperte sui repository `dr-*` passando per piani su disco: ogni issue diventa un piano in `.ai/plans/`, il piano si esegue, un revisore indipendente lo verifica, poi si committa.

---

# Stato corrente

- Le 5 issue aperte al 2026-09-22 sono state trasformate in altrettanti piani (commit `821c738`).
- 4 piani su 5 sono `COMPLETATO`, verificati in contesto isolato e pushati. Le issue `#2`, `#3`, `#4`, `#5` risultano `CLOSED` su GitHub.
- Il piano della issue `#1` è `PROPOSTO`: nessun file di prodotto è stato toccato per quella issue.
- Tutti e 7 i repository hanno working tree pulito e 0 commit da pushare.
- CI di `dr-guidelines` verde sugli ultimi due commit (`176afb1`, `fe9dee9`).
- 3 issue di follow-up aperte: `dr-guidelines#6`, `dr-guidelines#7`, `dr-minimalapi#2`.

---

# Componenti completati

- **Issue #2** — `Copy-CoreConfigFiles` in `dr-guidelines-install-lib.ps1` copia `.github/copilot-instructions.md` nell'host, con semantica `[OK]`/`[SKIP]`/`[UPD]`. Verificato end-to-end con clone reale da GitHub: nell'host prodotto nessun riferimento `@<file>.md` del `CLAUDE.md` iniettato è penzolante.
- **Issue #3** — regola di STOP dello scaffolding riscritta su due livelli: root del repository (file del core attesi, si prosegue) contro cartella del singolo progetto (deve non esistere, nemmeno vuota). Allineate 10 posizioni su 4 file: `dr-scaffold-solution/SKILL.md`, `dr-scaffold/SKILL.md`, `dr-scaffold-project/SKILL.md`, `dr-scaffold.prompt.md`.
- **Issue #4** — struttura dei modelli `ISSUE_TEMPLATE` scritta inline in `dr-file-feedback` (skill e prompt), perché i modelli non vengono distribuiti negli host. Label mappate su `bug`/`enhancement`, passate con `--label` e `&labels=`. Aggiunto `nuovo-pacchetto.md`, solo in `dr-guidelines`. Modelli condivisi propagati byte-identici ai 7 repo.
- **Issue #5** — nuova istruzione `cross-package-references.instructions.md`: un rimando a una regola di un altro pacchetto è sempre condizionale al manifest, con ripiego che dice *cosa* serve senza spiegare *come*, e obbligo di dichiarare nell'output quale ramo si è applicato. Applicata ai tre rimandi di `dr-efdb`, `dr-fe`, `dr-devops`.

---

# Componenti in lavorazione

Nessuno. Nessun piano è in stato `IN CORSO`.

---

# Componenti mancanti

- **Cartella `briefs/`** (issue #1): posto convenzionale dove l'utente scrive le richieste che diventeranno piani. Piano scritto in `.ai/plans/2026-09-22-issue-1-cartella-briefs/plan.md`, stato `PROPOSTO`, 18 fasi, 11 decisioni aperte su 13. Il nome `briefs/` in radice è deciso; il resto no.
- I tre punti delle issue di follow-up `#6`, `#7`, `dr-minimalapi#2`.

---

# File modificati

## `dr-guidelines`

| Percorso | Motivo |
|---|---|
| `dr-guidelines-install-lib.ps1` | Copia di `.github/copilot-instructions.md` in `Copy-CoreConfigFiles` (issue #2) |
| `README.md` | Rimosso il workaround "copialo a mano"; riga di tabella per il file ora copiato; terzo modello di issue; riga per la nuova istruzione modulare |
| `.claude/skills/dr-scaffold-solution/SKILL.md` | Regola root contro cartella di progetto (issue #3) |
| `.claude/skills/dr-scaffold/SKILL.md` | Tabella di instradamento estesa ai file del core (issue #3) |
| `.claude/skills/dr-scaffold-project/SKILL.md` | Soglia allineata: cartella del progetto assente (issue #3) |
| `.github/prompts/dr-scaffold.prompt.md` | Specchio Copilot della regola, più la riga-rete che mancava (issue #3) |
| `.claude/skills/dr-file-feedback/SKILL.md` | Struttura dei modelli inline, `--label`, regole e casi limite (issue #4) |
| `.github/prompts/dr-file-feedback.prompt.md` | Stessi interventi sulla superficie Copilot (issue #4) |
| `.github/ISSUE_TEMPLATE/problema.md`, `miglioria.md` | Front matter `labels:` su `bug` / `enhancement` (issue #4) |
| `.github/ISSUE_TEMPLATE/nuovo-pacchetto.md` | Nuovo, per il gap di catalogo (issue #4) |
| `.github/instructions/cross-package-references.instructions.md` | Nuovo, convenzione sui rimandi fra pacchetti (issue #5) |
| `docs/guida-nuova-soluzione.md` | La riga sullo scenario "cartella col core" affermava il comportamento vecchio |
| `docs/onboarding.md` | Elenco dei modelli di issue |
| `docs/bozza-manuale-installazione.md` | Sezione sul comportamento dell'installer con le dipendenze |
| `.ai/plans/2026-09-22-issue-*/plan.md` | 5 piani: tracciamento, decisioni risolte, consuntivi |

## `dr-efdb`, `dr-fe`, `dr-devops`

| Percorso | Motivo |
|---|---|
| `.github/instructions/<file>.instructions.md` | Rimando a `dr-minimalapi` reso condizionale al manifest, con ripiego (issue #5) |
| `README.md` | Riga "Rimandi ad altri pacchetti" allineata, con la motivazione della non-dipendenza |
| `.github/ISSUE_TEMPLATE/miglioria.md`, `problema.md` | Label allineate (issue #4) |

## `dr-minimalapi`, `dr-winsvc`, `dr-dotnet-backend`

| Percorso | Motivo |
|---|---|
| `.github/ISSUE_TEMPLATE/miglioria.md`, `problema.md` | Label allineate (issue #4) |

---

# Decisioni progettuali

Elenco completo con contesto e conseguenze in `DECISIONI.md`. In sintesi:

| Decisione | Motivazione |
|---|---|
| Cartella delle richieste utente chiamata `briefs/`, in radice | Non collide con nessuna convenzione di stack; in radice non eredita `doc-versioning`, che cattura `docs/**/*.md` |
| Cartella del singolo progetto: deve non esistere, nemmeno vuota | Una cartella vuota è spesso il residuo di un tentativo precedente |
| Label mappate su `bug` / `enhancement`, non create nuove | Le label di default esistono in ogni repo presente e futuro, perché le crea GitHub: niente da tenere sincronizzato a mano |
| Struttura dei modelli di issue scritta inline nelle superfici agente | I modelli non vengono distribuiti negli host: un rimando a una risorsa non garantita viene aggirato in silenzio |
| `dr-efdb` cita `dr-minimalapi` con rimando condizionale, non con dipendenza | Il pacchetto si installa sull'intenzione "mi serve un database", ortogonale al tipo di host: vale anche per un Worker |
| Rimandi fra pacchetti ancorati al manifest, con dichiarazione del ramo applicato | Senza la dichiarazione non c'è modo di sapere se la regola è stata seguita o aggirata |
| Ripiego di un rimando: dice il "cosa", mai il "come" | Un ripiego che entra nel dettaglio diventa una seconda fonte, e due fonti sulla stessa regola divergono |

---

# Problemi aperti

| Problema | Tipo | Dove |
|---|---|---|
| L'installer risolve le dipendenze in automatico e ricorsivamente, senza conferma e senza leggere `appliesTo` | Debito tecnico | `dr-guidelines#6` |
| Il catalogo non ha un campo per i rimandi non vincolanti: la relazione fra pacchetti che si citano è invisibile agli strumenti | Limitazione | `dr-guidelines#7` |
| `PersistKeysToDbContext` in scale-out: la tabella deve esistere prima delle repliche concorrenti, non documentato | Limitazione | `dr-minimalapi#2` |
| `dr-file-feedback.prompt.md` dichiara `tools: ['search/codebase']` ma prescrive comandi `gh`: su VS Code il passo potrebbe cadere sempre sul ripiego via URL | Debito tecnico, preesistente | Non tracciato |
| `dr-efdb` è internamente ambiguo: il catalogo lo offre ai Worker, i suoi due file di istruzione sono scritti per una Minimal API | Debito tecnico | Non tracciato |
| `dr-scaffold-solution` esegue `git init` incondizionato, pur avendo ora `.git/` fra i contenuti attesi della root | Debito tecnico | Non tracciato |
| `dr-scaffold-solution` reinstalla il core anche quando il manifest lo contiene già | Debito tecnico | Non tracciato |
| `Copy-GuidelineFile` esce in silenzio se il file sorgente non esiste: se un file del core venisse rinominato, l'host tornerebbe ad avere un riferimento penzolante senza alcun avviso | Debito tecnico | Non tracciato |
| Piano issue #1 fermo con 11 decisioni aperte | Attività incompleta | `dr-guidelines#1` |

---

# TODO

1. Rispondere alle 11 decisioni aperte del piano `2026-09-22-issue-1-cartella-briefs` (Fase 0 del piano), a partire dalla 3 (percorso fisso nel testo o parametro nel catalogo) e dalla 4 (sezioni obbligatorie del modello).
2. Eseguire il piano della issue #1 dopo l'approvazione, seguendo le sue 18 fasi.
3. Valutare i 4 debiti tecnici "Non tracciato" della tabella qui sopra: aprire una issue per quelli che si vogliono affrontare, con `/dr-file-feedback`.
4. Affrontare `dr-guidelines#6`: è il più rilevante dei tre follow-up, perché riguarda un comportamento dell'installer che oggi non fa danni solo per assenza di casi.

---

# Validazione

Esiti osservati in sessione, sui comandi effettivamente eseguiti:

- **Parser PowerShell** su `dr-guidelines-install.ps1` e `dr-guidelines-install-lib.ps1`: 0 errori.
- **`catalog-guard` della CI, eseguito in locale**: nessun problema. Verifica pacchetti duplicati, dipendenze risolvibili, `appliesTo` esistenti, domini, `intentMap`, tipologie.
- **Installazione end-to-end** in cartella vuota, con clone reale da GitHub al commit `176afb1`: prima esecuzione `[OK]` su tutti i file, rilancio senza opzioni `[SKIP]`, rilancio con `-Update` `[UPD]`. 12 istruzioni modulari, 8 prompt, 17 skill, `copilot-instructions.md`, catalogo e manifest. `.github/ISSUE_TEMPLATE/` correttamente non distribuito.
- **CI GitHub Actions** su `dr-guidelines`: `success` su `176afb1` e `fe9dee9`.
- **Verifica dei piani in contesto isolato**: 4 sub-agenti indipendenti, uno per piano, senza accesso alla conversazione di implementazione. Tutti i criteri soddisfatti; le correzioni emerse sono state applicate e sono descritte nei consuntivi dei rispettivi `plan.md`.

Build e test applicativi: non applicabili, il repository non contiene progetti .NET o Node.

---

# Rischi

- Il ripiego scritto in `dr-fe` e quello in `dr-devops` sono copie ridotte di regole che vivono in `dr-minimalapi`. Se la fonte cambia, nessun controllo automatico se ne accorge. La convenzione impone che il ripiego resti al "cosa" proprio per limitare questa deriva, ma non la elimina.
- La convenzione `cross-package-references` è nuova e ha un solo insieme di casi d'uso: i tre rimandi sistemati. Un quarto caso con caratteristiche diverse potrebbe non essere coperto.
- `TODO/` in `dr-guidelines` è una cartella locale non tracciata e non va committata.

---

# Prossimo passo consigliato

Rispondere alle 11 decisioni aperte nella sezione "Decisioni aperte" di `.ai/plans/2026-09-22-issue-1-cartella-briefs/plan.md`. Finché restano aperte, quel piano non è eseguibile: la sua Fase 0 è esattamente questa raccolta.

---

# Informazioni mancanti

- Se e quando i debiti tecnici elencati come "Non tracciato" vadano trasformati in issue.
- Per l'issue #1: se la cartella `briefs/` debba essere creata dall'installer in ogni host o solo su richiesta esplicita (decisione aperta 7 del piano).
