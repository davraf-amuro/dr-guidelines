# Testo issue pronto — NON ancora aperta (attende conferma dell'utente)

Repo: `davraf-amuro/dr-dotnet-backend`
Label: `enhancement` (template `miglioria.md`)

## Titolo

Nuova istruzione .NET sul fan-out parallelo (Task.WhenAll, Parallel.ForEachAsync) a complemento di producer-consumer-queue

## Corpo

## Cosa proponi

Aggiungere un'istruzione .NET nuova (per esempio `fan-out-parallelism.instructions.md`) che dia gli esempi idiomatici del fan-out su operazioni indipendenti: `Task.WhenAll` e `Parallel.ForEachAsync` con `MaxDegreeOfParallelism` letto dalla configurazione, `CancellationToken` propagato a ogni ramo, errore raccolto per ramo, uno scope DI per ramo. Per la coda con N consumer l'istruzione rimanda a `producer-consumer-queue.instructions.md` (fonte unica per `Channel<T>`), senza duplicarla.

## Da dove nasce

Da `davraf-amuro/dr-guidelines#20`: il core introduce `concurrency.instructions.md`, una regola trasversale e agnostica dal linguaggio ("preferire il parallelismo con operazioni indipendenti, dichiarare la serie"). Il core non contiene API di alcun linguaggio e rimanda al pacchetto di dominio per la sintassi. In `dr-dotnet-backend` esiste già `producer-consumer-queue.instructions.md`, che copre il caso producer/consumer; manca il caso del fan-out su provider indipendenti con attesa di tutti i risultati.

## Pacchetto e file interessati

- Pacchetto: dr-dotnet-backend
- File: nuovo `.github/instructions/fan-out-parallelism.instructions.md` (nome proposto); eventuale riga di rimando nella tabella delle istruzioni del README del pacchetto e voce nel catalogo, se serve

## Come si comporta oggi l'agente

Davanti a più chiamate indipendenti (per esempio la stessa richiesta a più provider) l'agente scrive di solito un `foreach` con `await` in serie, oppure un `Task.WhenAll` senza limite al parallelismo, senza cancellazione propagata e senza raccolta degli errori per ramo. Per la coda con più consumer segue già `producer-consumer-queue.instructions.md`.

## Come dovrebbe comportarsi

- Prima di scrivere il ciclo verifica l'indipendenza (dipendenza, ordine, limite del servizio), come richiede la regola del core.
- Fan-out con `Task.WhenAll` o `Parallel.ForEachAsync`, con `MaxDegreeOfParallelism` da configurazione (Options), mai letterale.
- `CancellationToken` propagato a ogni ramo; errore per ramo raccolto e riportato, non inghiottito; esito completo/parziale/fallito deciso in modo esplicito.
- Uno scope DI per ramo (nessun `DbContext` o servizio Scoped condiviso fra rami).
- Per la coda con più consumer: rimando a `producer-consumer-queue.instructions.md`, nessuna duplicazione di `Channel<T>`.
- Se si resta in serie, lo si dichiara come da regola del core.

## Contesto di installazione

- Progetto host: backend .NET
- Pacchetti installati: dr-guidelines, dr-dotnet-backend
- Agente usato: Claude Code e GitHub Copilot

---

> Le modifiche non si applicano direttamente al pacchetto: passano da qui. Se hai già una proposta di testo, incollala pure — verrà valutata come punto di partenza.
