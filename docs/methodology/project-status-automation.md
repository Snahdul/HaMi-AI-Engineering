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
| PR ohne Merge geschlossen | Cancelled | `pull_request:closed` → Secret-freies Signal → geschützter Statusabgleich |
| PR aus `Cancelled` wiedereröffnet | Review / In Progress | `pull_request:reopened` und aktuelle Labels |

Die beiden Workflow-Labels sollen im Normalfall gegenseitig exklusiv sein. Ein PR braucht **kein** Label, um automatisch in `Review` zu gelangen. Ein geschlossener, nicht gemergter PR gehört in `Cancelled`, nicht in `Done`. **Issue-Abschlüsse bleiben unverändert:** `Item closed` ist im Project nur für Issues aktiviert und setzt `Done`.

## Ereignisgesteuerte PR-Synchronisierung ohne Polling-Verzögerung

Zwei getrennte Workflow-Dateien sorgen für eine Sicherheitsgrenze:

1. **`.github/workflows/pr-status-signal.yml`** – `HaMi PR status signal`: lauscht auf die PR-Ereignisse `opened`, `reopened`, `closed`, `labeled`, `unlabeled`, `ready_for_review`, `converted_to_draft`, `synchronize`. Dieser Workflow hat `permissions: {}`, verwendet **keine Secrets**, checkt **keinen PR-Code** aus und verarbeitet nur interne PRs.
2. **`.github/workflows/project-status.yml`** – `HaMi GitHub Project status`: reagiert über `workflow_run: completed` auf ein **erfolgreiches** PR-Signal. Diese zweite Workflow-Datei wird aus dem geschützten Default-Branch ausgeführt und darf das GitHub-Actions-Secret `HAMI_PROJECT_TOKEN` verwenden. Sie prüft die PR-Quelle erneut, ermittelt den konkreten PR (über dessen Nummer oder, falls GitHub sie nicht liefert, über den internen Head-Branch) und liest seinen **aktuellen** Status, `merged_at` und seine Labels über GitHubs API. Ein offener PR wird anhand der Labels eingeordnet; ein geschlossener PR mit `merged_at == null` erhält `Cancelled`. Bei bereits gemergten PRs greift ausschließlich die bestehende eingebaute `Done`-Automatik.

Das Ergebnis ist ereignisgetrieben: **kein festes 15-Minuten-Wartefenster**. GitHub-Actions-Queues können trotzdem eine variable Ausführungsverzögerung verursachen. Die beiden Stufen werden asynchron durch GitHub abgewickelt; Sekundenlatenz ist nicht garantiert.

**Ausfallsicherung:** Ein geplanter Abgleich läuft zusätzlich **täglich um 03:17 UTC**, um verpasste Ereignisse, ältere offene PRs **und ohne Merge geschlossene PRs** nachzuführen. Die tägliche Ausführung ist keine Voraussetzung für den normalen Statuswechsel.

## Voraussetzung: fünfter Project-Statuswert

Am 16.11.2026 hat der Repositoryinhaber im [GitHub Project #1](https://github.com/users/Snahdul/projects/1) die Option **`Cancelled`** (exakte Schreibweise) im Single-Select-Feld **`Status`** ergänzt und alle bestehenden Optionen beibehalten. Die Einstellung wurde per Screenshot kontrolliert. [PR #19](https://github.com/Snahdul/HaMi-AI-Engineering/pull/19) wurde nach ausdrücklicher menschlicher Freigabe in `main` gemergt (Commit `fe3135cd`).

Die privilegierte Action validiert die Option bei jedem Statusabgleich und meldet einen **expliziten Fehler**, falls sie fehlt. Der nun fehlgeschlagene Live-Test bei PR #20 kam **erst nach** dieser Prüfung bis zur Projekt-Item-Auflösung; Ursache und geplanter Fallback sind nachstehend dokumentiert.

## Resilienz bei verspäteten oder fehlenden Project-Einträgen

Beim Live-Test von [PR #20](https://github.com/Snahdul/HaMi-AI-Engineering/pull/20) (16.11.2026) waren die `pull_request`-Signale für `opened`, `closed` und `reopened` erfolgreich. Die geschützten Folgeläufe konnten den zugehörigen ProjectV2-Eintrag jedoch nicht über die bestehende `projectV2.items`-Suche mit initialem Status auflösen und brachen jeweils nach mehreren Versuchen ab. Die PR-Timeline protokollierte zugleich `added_to_project_v2` und einen initialen Statuswechsel. **Welche Ebene die Diskrepanz verursacht hat, ist noch ungeklärt.**

Der geschützte Workflow soll deshalb nach drei begrenzten Leserversuchen bei **internen PRs** das Project-Item über `addProjectV2ItemById(projectId, contentId)` auflösen. Diese GitHub-GraphQL-Mutation ist laut [offizieller GitHub-Dokumentation](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects) **idempotent**: Ist der Eintrag bereits vorhanden, liefert die API seine bestehende Item-ID zurück. Erst nach dieser gesicherten Zuordnung wird der aktuelle Status direkt am Item nachgelesen und gegebenenfalls aktualisiert. Ein bestehendes `Done` wird bei einem weiterhin offenen PR unverändert respektiert.

Für Issues bleibt die ursprüngliche rein lesende Suche unverändert. Die Secret-freie PR-Signalstufe führt weiterhin keinerlei Project-Schreibzugriff aus. Ein Merge oder eine Änderung an fremden Repository-PRs wird dadurch nicht ausgelöst.

**Abnahmestand:** Der Resilienz-Fallback ist als Korrektur vorgeschlagen und strukturell geprüft, **noch nicht produktiv getestet**. Die konkrete Statusmutation `Review → Cancelled` ist für PR #20 bisher nicht bestätigt. Der Live-Test wird erst nach menschlicher Freigabe und Merge der Korrektur erneut durchgeführt; Details in [Issue #18](https://github.com/Snahdul/HaMi-AI-Engineering/issues/18).

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

**Stand 16.11.2026:** [PR #17](https://github.com/Snahdul/HaMi-AI-Engineering/pull/17) wurde nach menschlicher Freigabe gemergt (Commit `e0e82787`). Die PR-Timeline bestätigt eine automatische Project-Statusänderung durch `github-project-automation[bot]` unmittelbar nach dem Merge; der konkrete Wert `Done` wurde über die auslesbare REST-Timeline nicht separat bestätigt. Der tägliche Recovery-Lauf, der `Cancelled`-Fall und Token-Ablauf/-Rotation werden in [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10) und [Issue #18](https://github.com/Snahdul/HaMi-AI-Engineering/issues/18) geprüft.

**Die PR-Statusregeln lösen niemals eigenständig einen Merge aus; die fachliche und rechtliche Freigabe bleibt menschlich.**

## Abnahme des Status `Cancelled` (Issue #18)

1. Die Option `Cancelled` ist im GitHub-Project-Statusfeld angelegt; alle fünf Werte sind auswählbar.
2. Den Folge-PR nach fachlicher Freigabe in `main` mergen. **Nicht** zum Testen vorhandene Arbeits-PRs #12/#13 schließen.
3. Einen separaten Test-PR auf Basis des dann aktuellen `main` als Draft eröffnen und den Initialstatus `Review` sowie beide Actions-Stufen bestätigen.
4. Test-PR **ohne Merge** schließen. Die unprivilegierte `pull_request:closed`-Action und der geschützte `workflow_run` müssen den Wechsel `Review → Cancelled` protokollieren.
5. Den Test-PR wiedereröffnen und den Wechsel `Cancelled → Review` bestätigen; anschließend kontrolliert schließen oder zur Abnahme vorlegen.
6. Bei einem bereits **gemergten** PR muss `Done` erhalten bleiben. Der tägliche Recovery-Lauf darf keine gemergten PRs nach `Cancelled` verschieben.
7. Label-Ereignisse bei älteren PR-Branches ohne Signal-Workflow können ausbleiben; die tägliche Recovery muss geschlossene PRs dann nachführen.

Die manuelle Action `workflow_dispatch` akzeptiert `Cancelled` nur für **geschlossene, nicht gemergte PRs** und `Done` nur für **gemergte PRs**; bei Issues bleiben die bisherigen Statusregeln bestehen. Keine Test-PRs ohne menschliche Freigabe mergen. Ergebnisse in [Issue #18](https://github.com/Snahdul/HaMi-AI-Engineering/issues/18) dokumentieren.

## Quellen

- [GitHub: Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [GitHub: Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use)
- [GitHub: Automating Projects using Actions](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/automating-projects-using-actions)
- [GitHub: Default policy for pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)
