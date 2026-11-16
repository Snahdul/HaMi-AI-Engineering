# GitHub-Project-Statusautomatisierung

**Aktueller Stand (16.11.2026):** Basis-Workflow [PR #14](https://github.com/Snahdul/HaMi-AI-Engineering/pull/14), Review-Regel [PR #15](https://github.com/Snahdul/HaMi-AI-Engineering/pull/15) und zweistufiger PR-Trigger [PR #16](https://github.com/Snahdul/HaMi-AI-Engineering/pull/16) sind in `main`. Die Statusänderung von Issues und der periodische PR-Abgleich sind durch erfolgreiche Actions-Läufe belegt. **Der ereignisgesteuerte Statuswechsel eines offenen PRs ist jetzt durch drei vollständige Actions-Paare und echte ProjectV2-Mutationen nachgewiesen**, siehe Testprotokoll zu PR #17 unten. Nachweise und offene Arbeiten stehen in [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10).

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

Die neue Signalkette wurde in [Run #43879352888](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43879352888) und [Run #43879383218](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43879383218) **beide Male erfolgreich ausgeführt**. Der betroffene PR #16 war beim geschützten Folge-Lauf bereits gemergt; damit ist noch **keine PR-Statusmutation** durch die neue Kette nachgewiesen. Der frühere [geplante Lauf #43878014136](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43878014136) hat PR #12 und #13 nachweislich auf `Review` gesetzt.

**Nachtest älterer PR-Branches:** An PR #12 löste das Entfernen und erneute Setzen von `workflow:review` im GitHub-Web-UI keinen neuen Signal-Lauf aus. Die Workflow-Datei fehlt im Head- und synthetischen Merge-Commit von PR #12/#13, weil ihre PR-Branchstände vor PR #16 liegen. Dies wurde am 16.11.2026 anhand der GitHub-Refs festgestellt. Ein neuer PR aus aktuellem `main` dient deshalb als isolierter End-to-End-Test.

## Erfolgreicher End-to-End-Test mit offenem PR #17 (16.11.2026)

Der Dokumentations-[PR #17](https://github.com/Snahdul/HaMi-AI-Engineering/pull/17) wurde als **Draft** auf einem Branch aus aktuellem `main` eröffnet. Er blieb während aller drei Statuswechsel **offen**; die Aktionen wurden über GitHub-Events ausgelöst und nicht manuell über `workflow_dispatch`.

| Auslöser | Signal-Workflow ohne Secret | Folge-Workflow mit Projekt-Secret | Im Job-Log bestätigte Mutation |
| --- | --- | --- | --- |
| `pull_request:opened` | [Run #43881762513](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43881762513) – success | [Run #43881792315](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43881792315) – success | `Todo → Review` |
| Label `workflow:in-progress` gesetzt | [Run #43881902199](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43881902199) – success | [Run #43881926076](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43881926076) – success | `Review → In Progress` |
| Label `workflow:in-progress` entfernt | [Run #43882056882](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43882056882) – success | [Run #43882100019](https://github.com/Snahdul/HaMi-AI-Engineering/actions/runs/43882100019) – success | `In Progress → Review` |

**Bewertung:** Alle drei ausgelösten Signal-Workflows haben den geschützten `workflow_run` gestartet, und die Statusänderung wurde jeweils durch eine echte GraphQL-`updateProjectV2ItemFieldValue`-Mutation im Job protokolliert. Der Test belegt den Normalbetrieb **ohne festen 15-Minuten-Pollingzyklus**. GitHub-Actions-Queues können weiterhin Verzögerungen verursachen.

**Noch offen:** Menschliche Dokumentations-/Mergefreigabe für PR #17, separate Prüfung des täglichen Wiederherstellungslaufs und der GitHub-Projects-`Done`-Automationen sowie Token-Ablauf/-Rotation in [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10).

**Die PR-Statusregeln lösen niemals eigenständig einen Merge aus; die fachliche und rechtliche Freigabe bleibt menschlich.**

## Quellen

- [GitHub: Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [GitHub: Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use)
- [GitHub: Automating Projects using Actions](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/automating-projects-using-actions)
- [GitHub: Default policy for pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)
