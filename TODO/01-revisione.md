# Revisione del progetto

## aggiornare davraf-gudelines

fai pull di davraf-guidelines, assicurati che abbiamo l'ultima versione. se effettivamente il sorgente si aggiorna allora propaga i cambiamenti su tutti i progetti.

## progetto di partenza

dr-gudelines forse è troppo specifico, vorrei ristrutturare i progetti in questo modo:

1- un progetto principale che contenga solo le informazioni riguardo a cosa servono gli altri progetti, da dove e come scaricarli, come installarli. lo scopo è che l'utente chieda di fare un'attività come creare una guida turistica, creare un progetto api o per esp23 o altro e il progetto principale contenga le informazioni per guidare l'AI nel recuperare i pacchetti guide necessari per eseguire il lavoro.

2-i progetti secondari che contengono guide, skill, agenti o altro specializzati per un particolare ambito. ogni progetto dovrà essere disponibile come pacchetto su git in modo che la AI legga il percorso dal progetto principale e sappia come scaricarlo ed installarlo.

3- tutti i progetti devono avere un sistema per recepire richieste di fix o evolutive da parte degli utenti che li usano. non deve essere modificato il progetto direttamente ma avviata una request/issue su git.

crea nuovi progetti nel workspace o modifica quelli attuali come credi.

