# GitHub-Project-Statusautomatisierung

**Aktueller Stand:** Der Basis-Workflow aus [PR #14](https://github.com/Snahdul/HaMi-AI-Engineering/pull/14) und die Standardregel `offener PR → Review` aus [PR #15](https://github.com/Snahdul/HaMi-AI-Engineering/pull/15) sind in `main`. Die ereignisgesteuerte PR-Synchronisierung wird separat im Folge-PR vorbereitet und ist bis zu dessen Freigabe und Merge **nicht aktiv**. Nachweise und verbleibende Arbeiten stehen in [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10).

## Statusmodell

GitHub Issue/PR-Zustände und das GitHub-Project-Feld `Status` sind unabhängig. Die Spalte `Review` bedeutet, dass Arbeit zur **menschlichen Prüfung** bereitsteht, nicht dass sie bereits freigegeben wurde. GitHub-Drafts dürfen in `Review` stehen.

| Ereignis | Project-Status | Verantwortlicher Mechanismus |
| --- | --- | --- |
| Issue/PR wird zum Project hinzugefügt | Todo | GitHub Projects: `Auto-add` und `Item added` |
| Issue erhält `workflow:in-progress` | In Progress | Vertrauenswürdiger `issues:labeled`-Workflow |
| Issue erhält `workflow:review` | Review | Vertrauenswürdiger `issues:labeled`-Workflow |
| Interner PR wird eröffnet oder ändert seinen Status bzw. seine Labels | Review | Secret-freier PR-Signal-Workflow → geschützter `workflow_run` |
| PR mit `workflow:in-progress` | In Progress | Explizite Ausnahme bei noch laufender Entwicklung |
| PR mit `workflow:review` | Review | Vorrang vor einem widersprüchlichen In-Progress-Label |
| Issue geschlossen | Done | GitHub Projects: `Item closed` (nur Issues) |
| PR gemergt | Done | GitHub Projects: `Pull request merged` |

Die beiden Workflow-Labels sollen im Normalfall gegenseitig exklusiv sein. Ein PR braucht **kein** Label, um automatisch in `Review` zu gelangen.

## Ereignisgesteuerte PR-Synchronisierung ohne Polling-Verzögerung

Zwei getrennte Workflow-Dateien sorgen für eine Sicherheitsgrenze:

1. **`.github/workflows/pr-status-signal.yml`** – `HaMi PR status signal`: lauscht auf die PR-Ereignisse `opened`, `reopened`, `labeled`, `unlabeled`, `ready_for_review`, `converted_to_draft`, `synchronize`. Dieser Workflow hat `permissions: {}`, verwendet **keine Secrets**, checkt **keinen PR-Code** aus und verarbeitet nur interne PRs.
2. **`.github/workflows/project-status.yml`** – `HaMi GitHub Project status`: reagiert über `workflow_run: completed` auf ein **erfolgreiches** PR-Signal. Diese zweite Workflow-Datei wird aus dem geschützten Default-Branch ausgeführt und darf das GitHub-Actions-Secret `HAMI_PROJECT_TOKEN` verwenden. Sie prüft die PR-Quelle erneut, ermittelt den konkreten PR (über dessen Nummer oder, falls GitHub sie nicht liefert, über den internen Head-Branch) und liest seinen **aktuellen** Status und seine Labels über GitHubs API. Erst dann wird das Project-Statusfeld aktualisiert.

Das Ergebnis ist ereignisgetrieben: **kein festes 15-Minuten-Wartefenster**. GitHub-Actions-Queues können trotzdem eine variable Ausführungsverzögerung verursachen. Die beiden Stufen werden asynchron durch GitHub abgewickelt; Sekundenlatenz ist nicht garantiert.

**Ausfallsicherung:** Ein geplanter Abgleich läuft zusätzlich **täglich um 03:17 UTC**, um verpasste Ereignisse oder ältere offene PRs nachzuführen. Die tägliche Ausführung ist keine Voraussetzung für den normalen Statuswechsel.

## Sicherheitsarchitektur

- Das öffentliche Repository verwendet **kein `pull_request_target`**. GitHub kündigt für öffentliche Repositories eine Sperre dieses Triggers ab 02.12.2026 an. Wir müssen diese Schutzregel nicht außer Kraft setzen.
- Der unprivilegierte `pull_request`-Workflow läuft ohne Secrets und ohne Repository-Schreibrechte. Er übergibt **keine ausgeführten PR-Dateien, Artefakte oder Skripte** an den privilegierten Workflow.
- Nur der geschützte Default-Branch enthält die ausgeführte privilegierte Workflow-Datei. Das `workflow_run`-Ereignis wird anhand des erfolgreichen Signal-Workflows, des Pull-Request-Ereignisses und der Head-Repository-Identität überprüft; anschließend wird die Quelle des PRs erneut aus GitHub-REST-Daten verifiziert.
- Die Fall-Back-Suche bei einer fehlenden PR-Nummer vergleicht einen Head-Branch als **Datenwert**; sie interpretiert PR-Titel, Branch-Namen oder Inhalte nie als Shell-Code.
- `HAMI_PROJECT_TOKEN` ist ein GitHub-Repository-Secret mit klassischem PAT und `project`-Scope. Es darf nie in Code, Issue, Chat oder Logs erscheinen. Die Projektvariable `HAMI_PROJECT_NUMBER` hat den Wert `1`.
- Die GitHub-Integration kann PR-Labels setzen/entfernen; der 2-stufige Workflow übernimmt die Änderungen am Projektstatus.
- `permissions: {}` verhindert zusätzliche Schreibrechte über den eingebauten `GITHUB_TOKEN`; das PAT bleibt auf den kontrollierten Projektzugriff beschränkt. Sein `project`-Scope gilt jedoch für alle erreichbaren Benutzerprojekte – Ablaufdatum, Rotation und Notfallwiderruf bleiben wichtig.

## Nachgewiesene Grundlage

Die ursprüngliche PR-Statusautomatisierung [#14](https://github.com/Snahdul/HaMi-AI-Engineering/pull/14) wurde gemergt. Nach Korrektur des Secret-Namens wurden am 16.11.2026 drei erfolgreiche Actions-Läufe für Issue #10 protokolliert:

- [Run #5](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43874798638): Secret und GraphQL-Lesezugriff bestätigt.
- [Run #6](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43874900326): tatsächliche Mutation `In Progress → Review`.
- [Run #7](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43874977190): tatsächliche Mutation `Review → In Progress`.

Die neuen Ereignistrigger selbst sind **noch nicht live getestet**.

## Abnahmeplan für den Folge-PR

1. Beide Workflow-Dateien und ihre Sicherheit prüfen. Keine GitHub-Workflows aktivieren, bevor die menschliche PR-Freigabe erfolgt.
2. Folge-PR nach ausdrücklicher Freigabe in `main` mergen. Erst dann kann der privilegierte Workflow auf den unprivilegierten PR-Signal-Workflow reagieren.
3. An [PR #12](https://github.com/Snahdul/HaMi-AI-Engineering/pull/12) oder [PR #13](https://github.com/Snahdul/HaMi-AI-Engineering/pull/13) ein `pull_request:labeled`-Ereignis auslösen, etwa indem `workflow:review` entfernt und erneut hinzugefügt wird.
4. Kontrollieren: Ein **erfolgreicher Signal-Lauf ohne Secrets** startet anschließend einen **erfolgreichen `workflow_run`** im geschützten Workflow; dieser findet den richtigen Project-Eintrag mit Status `Review`.
5. Zusätzlich an einem PR den Ausnahmefall `workflow:in-progress` testen, danach Label entfernen und den ursprünglichen Review-Status wiederherstellen.
6. Optional abschließend die eingebauten `Done`-Automationen und den täglichen Wiederherstellungslauf prüfen; Ergebnisse und Token-Rotationsverfahren in [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10) dokumentieren.

**Die PR-Statusregeln lösen niemals eigenständig einen Merge aus; die fachliche und rechtliche Freigabe bleibt menschlich.**

## Quellen

- [GitHub: Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [GitHub: Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use)
- [GitHub: Automating Projects using Actions](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/automating-projects-using-actions)
- [GitHub: Default policy for pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)
