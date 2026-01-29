# ora tu sei il migliore analista programmatore del mondo.

Se non esiste crea una cartella Doc nella radice del progetto per salvare i file di tipo .md che creerai.
nel caso esista un file di progetto, aggiungi i riferimenti ai file.

analizza le classi nella cartella Endpoints del progetto .net minimal api fornito e disegna un flusso per ogni singolo endpoint trovato.
se ci sono usa tutte le informazioni OpenApi, atrimenti non inventare nulla, piuttosto lascia vuoto
non scendere troppo in dettagli ma riporta se viene invocato un servizio esterno o se viene fatto accesso al database. basta che indichi quale endpoint viene chiamato e/o quali entity vengono lette o scritte nel database.
usa diagrammi di flusso e tabelle per rendere il documento facile da capire.
se ci sono più gruppi  (MapGroup) di endpoint, crea un file `endpoint-<group_name>.md` per ogni gruppo. riscrivi quelli esistenti.

assicurati di includere le seguenti sezioni:

## 1. Introduzione

una panoramica di cosa fa il gruppo. 

## 2. Architettura del sistema

descrivi l'architettura generale del sistema, inclusi i componenti principali e le loro responsabilità ma sempre legati a questo gruppo.

## 3. Descrizione degli endpoint

per ogni endpoint, fornisci una tabella con le seguenti informazioni:
   - Metodo HTTP (GET, POST, PUT, DELETE, ecc.)
   - URL dell'endpoint
   - Descrizione dell'endpoint
   - Parametri di input (se presenti)
   - Risposta prevista
## 4. Flusso degli endpoint

 crea diagrammi di flusso che mostrano come gli endpoint interagiscono tra loro
    e con il database durante le operazioni principali del sistema.
    **Importante per la sezione 4:**
    - Evita dettagli di validazione (API Key, autenticazione) - dalli per scontati
    - Evita dettagli di query (filtri WHERE, ORDER BY, ToListAsync)
    - Dopo l'applicazione dei filtri, indica solo: nome dell'Entity acceduta e il DTO a cui viene mappato
    - Mantieni il flusso essenziale: Endpoint → Provider/Service → Entity → DTO → Response

## 5. Esempi e casi d'uso

Se nel progetto ci sono file .http che portano esempi di chiamata per gli endpoint del gruppo, cita semlicemente: 'Per i casi d'uso fare rifermiento a <elenco_dei_file_http>'

## 6. Ultimo aggiornamento

Ottieni la data corrente con `Get-Date -Format "yyyy-MM-dd"` e genera il footer:

```markdown
---
*Card generata il: yyyy-MM-dd | Versione template: x.x | LLM: GitHub Copilot*
```

La versione template è nell'ultima riga di questo file.

---
*Ultimo aggiornamento il 2025-01-29 - Versione 1.4*