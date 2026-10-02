# Piano: `dr-devops` coerente fra catalogo, skill e guida
Data: 2026-10-02
Stato: COMPLETATO
Issue: davraf-amuro/dr-guidelines#8

## Obiettivo
Catalogo, skill di scaffolding e guida dicono la stessa cosa su `dr-devops`: quando è opzionale e quali richieste lo chiamano in causa, in linea con ciò che il pacchetto copre davvero.

## Contesto

- Issue: https://github.com/davraf-amuro/dr-guidelines/issues/8
- Verificato il 2026-10-02 nel clone `../dr-devops`: le tre istruzioni coprono compose Docker Swarm (`applyTo: docker-compose_swarm.yaml`, "worker service / Minimal API .NET 10"), stack Portainer, pipeline GitLab (`.gitlab-ci.yml`) di progetti .NET 10. Nessuna regola su nginx, frontend, `Dockerfile` o `docker-compose.yml` semplice: è davraf-amuro/dr-devops#1, aperta.
- Oggi `intentMap` instrada "deploy", "docker", "container", "pipeline", "ci/cd" a `devops`; `dr-devops` non è in nessun `optionalPackages`; `dr-scaffold-solution/SKILL.md` riga ~70 e `docs/guida-nuova-soluzione.md` riga ~181 lo dicono opzionale "se serve CI/CD o Docker".

**Esito della consultazione** (`/dr-tech`, 2026-10-02):

1. `optionalPackages`: `dr-devops` su `minimal-api` e `worker-service`. Non su `vue-fe` (nessuna regola si applica al container nginx del frontend; si aggiunge quando dr-devops#1 lo coprirà), non su `classlib`/`xunit-test` (non si distribuiscono).
2. `intentMap` del dominio `devops`: frasi precise — `docker swarm`, `swarm`, `portainer`, `stack portainer`, `deploy su swarm`, `gitlab ci`, `pipeline gitlab`, `ci/cd gitlab`. Tolte le generiche `deploy`, `docker`, `container`, `pipeline`, `ci/cd`: instradavano "containerizzo l'API con docker compose" o "CI/CD con GitHub Actions" verso un pacchetto che non li copre. Senza corrispondenza scatta il `fallback` del catalogo (dichiarazione + proposta di issue), esito più onesto di un'installazione inutile.
3. `label` del dominio `devops`: "Deploy Docker Swarm/Portainer e CI/CD GitLab".
4. Testo per skill e guida: "`dr-devops` se il deploy è su Docker Swarm/Portainer o la pipeline è GitLab CI/CD; Docker su host singolo non è ancora coperto (dr-devops#1)".

## Scope

- `scaffolding-catalog.json` — `domains[devops].label`, `intentMap[devops].phrases`, `projectTypes[minimal-api|worker-service].optionalPackages`, `updatedAt` invariato se già 2026-10-02
- `.claude/skills/dr-scaffold-solution/SKILL.md` — Fase 2 punto 2
- `docs/guida-nuova-soluzione.md` — riga ~181
- Altri testi del repo che descrivono `dr-devops` come "Docker" generico o elencano le frasi dell'intentMap (da individuare con grep: `README.md`, `.github/prompts/dr-scaffold.prompt.md`, altre skill `dr-scaffold*`, `docs/`) — solo se affermano una copertura che il pacchetto non ha

## Perimetro negativo

- Nessuna modifica al repo `dr-devops` (la copertura di Docker su host singolo è dr-devops#1)
- Nessuna modifica a `vue-fe`, `classlib`, `xunit-test`
- Nessuna modifica a installer o workflow
- `.ai/plans/` storici non si toccano

## Fasi

### Fase 1: Catalogo
- **Stato**: [x]
- **Azione**: come da Scope
- **Verifica passo**: JSON valido; script del job `catalog-guard` di `.github/workflows/ci.yml` eseguito in locale passa
- **Esito**: label e 8 frasi `intentMap` aggiornate; `dr-devops` opzionale solo in `minimal-api` e `worker-service`; `updatedAt` già 2026-10-02. ConvertFrom-Json ok, catalog-guard locale exit 0 ("7 pacchetti, 5 tipologie").

### Fase 2: Skill, guida e testi allineati
- **Stato**: [x]
- **Azione**: testo del punto 4 del Contesto dove serve; grep per altre affermazioni di copertura generica
- **Verifica passo**: grep di "CI/CD o Docker" e simili non trova più affermazioni scorrette fuori da `.ai/plans/`; i file condivisi (`.github/**`, `docs/**`) restano compatibili Claude Code + Copilot
- **Esito**: testo del punto 4 in `dr-scaffold-solution/SKILL.md` (Fase 2 punto 2) e `docs/guida-nuova-soluzione.md` (tabella pacchetti, footer v1.2). Grep su README, `.github/**`, altre skill `dr-scaffold*`, `docs/`: le altre menzioni sono già corrette (README "Docker Swarm, Portainer, CI/CD GitLab") o riguardano `/dr-tech`, non `dr-devops`. Nessuna lista delle frasi `intentMap` fuori dal catalogo. Grep finale: zero occorrenze residue.

### Fase 3: Commit, push, chiusura issue
- **Stato**: [x]
- **Azione**: commit dei soli file di Scope; gate di push: nessun lint applicabile (verifica = JSON e guard); push su `main`; chiusura #8 con rimando a dr-devops#1
- **Esito**: 2026-10-02 — JSON valido, guard locale exit 0; nessun lint applicabile dichiarato; commit e push su `main`; #8 chiusa. Nota: durante l'esecuzione l'agente ha creato per errore un file vuoto non tracciato `../dr-devops/scaffolding-catalog.json`, da rimuovere a mano

## Criteri di verifica finale
- [x] `dr-devops` opzionale in `minimal-api` e `worker-service`, assente altrove
- [x] Frasi `intentMap` del dominio `devops` corrispondono alla copertura reale
- [x] Skill, guida e catalogo concordano
- [x] Guard CI verde
- [x] Nessun file fuori Scope modificato
