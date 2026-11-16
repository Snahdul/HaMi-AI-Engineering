# GitHub-Project-Statusautomatisierung

**Status: Implementierungsentwurf in [Draft-PR #14](https://github.com/Snahdul/HaMi-AI-Engineering/pull/14).** Bis zu menschlicher Freigabe und Merge auf `main` ist der eigene Workflow nicht aktiv. Die Einrichtung und ihre Abnahme werden in [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10) geführt.

## Ziel und Zuständigkeit

GitHub Issues und Pull Requests haben eigene Zustände (`open`, `closed`, `draft`, `merged`). Das GitHub-Project-Feld `Status` ist davon unabhängig. Wir wollen die Projektkarte ohne manuelle Doppelpflege nachführen, **ohne** dadurch eine fachliche Abnahme oder einen Merge auszulösen.

GitHub Projects ist die führende Quelle für den sichtbaren Arbeitsstatus, GitHub Issues/PRs sind die Quelle für ihren technischen Zustand. Menschliche Veröffentlichungsfreigaben bleiben erforderlich.

## Gewünschte Übergänge

| Auslöser | Projektstatus | Mechanismus |
| --- | --- | --- |
| Neues Item im Projekt | Todo | GitHub Projects, integrierter Workflow `Item added` |
| Aktive Bearbeitung eines Issues | In Progress | Label `workflow:in-progress` → GitHub Action |
| Issue bereit für fachliches Review | Review | Label `workflow:review` → GitHub Action |
| Offener PR im Draft-Zustand | In Progress | GitHub Action, spätestens beim regelmäßigen Abgleich |
| Offener PR ohne Draft-Status | Review | GitHub Action, spätestens beim regelmäßigen Abgleich |
| Geschlossenes Issue | Done | GitHub Projects, integrierter Workflow `Item closed` (nur Issues) |
| Gemergter PR | Done | GitHub Projects, integrierter Workflow `Pull request merged` |

### Warum PRs nicht direkt über `pull_request_target` reagieren

GitHub beschreibt für öffentliche Repositories neue restriktive Standards für `pull_request_target`, deren Durchsetzung für den 02.12.2026 angekündigt ist. Außerdem ist dieses Ereignis privilegiert. Um eine Ausnahme von der GitHub-Sicherheitsrichtlinie zu vermeiden, verwendet unser Workflow **keine** `pull_request`- oder `pull_request_target`-Trigger und checkt auch keinen PR-Code aus.

Stattdessen läuft die Action über drei **vertrauenswürdige** Ereignisse:

- `issues:labeled`: Das Setzen eines der beiden Workflow-Labels startet sofort einen Statusabgleich des betroffenen Issues.
- `schedule`: Alle 15 Minuten wird der **aktuelle** Zustand offener, aus dem eigenen Repository stammender PRs und markierter Issues geprüft. Die GitHub-Ausführung kann sich verzögern; es gibt keine exakte Echtzeitgarantie.
- `workflow_dispatch`: Bei Bedarf kann der Repositoryinhaber einen konkreten Issue/PR und Zielstatus manuell angeben.

Die Synchronisierung erstellt **keine** neuen Projektkarten. Sie wartet darauf, dass `Auto-add` und `Item added → Todo` die Karte und den initialen Status eingerichtet haben. Bei einem geplanten Lauf wird ein noch fehlender Eintrag protokolliert und beim nächsten Lauf erneut berücksichtigt. Bei einer direkten Label- oder manuellen Ausführung werden mehrere Versuche vorgenommen.

## Bereits bestätigte Konfiguration

Für das öffentliche [GitHub Project #1](https://github.com/users/Snahdul/projects/1) wurden laut Screenshot und Bestätigung des Repositoryinhabers diese GitHub-Workflows eingerichtet:

- `Auto-add to project` mit `is:issue,pr is:open`.
- `Item added to project` → `Todo`.
- `Item closed` nur für Issues → `Done`.
- `Pull request merged` → `Done`.
- `Auto-close issue` **deaktiviert**, damit das bloße Verschieben auf `Done` keine fachliche Abnahme ersetzt.

Laut Nutzerbestätigung wurden die folgenden Repository-Konfigurationen angelegt, deren tatsächliche Funktionsfähigkeit noch getestet werden muss:

- GitHub-Actions-Secret `HAMI_PROJECT_TOKEN` (Tokenwert **niemals** in Chat, Issues, Code oder Screenshots teilen).
- GitHub-Actions-Variable `HAMI_PROJECT_NUMBER=1`.
- Repository-Labels `workflow:in-progress` und `workflow:review`.

Die technische GitHub-Integration konnte das Label `workflow:in-progress` bereits erfolgreich auf [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10) setzen. Das allein beweist **nicht** die spätere Projektsynchronisierung.

## Berechtigungen und Risiken

- Der Workflow benötigt einen **Personal Access Token (classic)** für GitHub Projects. Wir testen zunächst den Scope `project`, ohne vorsorglich `repo`, `workflow` oder Admin-Rechte hinzuzufügen. GitHubs Beispiele zeigen teils zusätzlich `repo`; etwaige `403`-Fehler müssen wir konkret auswerten.
- Der Scope `project` ist nicht auf ein einzelnes Benutzerprojekt beschränkt. Deshalb kurze Gültigkeit wählen, Token-Ablauf notieren und bei Verdacht auf Offenlegung sofort widerrufen.
- Das Secret wird ausschließlich in GitHub Actions gelesen; der Workflow führt keinen nicht vertrauenswürdigen PR-Code aus und setzt `permissions: {}` für den eingebauten `GITHUB_TOKEN`.
- Das Label `workflow:review` bedeutet **prüfbereit**, nicht freigegeben.
- Bei einem Wechsel zwischen `In Progress` und `Review` soll jeweils nur eines der beiden Statuslabels auf dem Issue verbleiben. Ein bereits vorhandenes Label erneut hinzuzufügen, löst nicht zuverlässig ein neues `labeled`-Ereignis aus.
- Ein erfolgreicher Action-Lauf beweist zunächst nur einen Projektstatuswechsel; eine inhaltliche Qualitätsprüfung bleibt separat.
- GitHubs Zeitplan-Workflows können bei wenig Repository-Aktivität deaktiviert werden. Die regelmäßigen Actions-Läufe müssen deshalb gelegentlich kontrolliert werden.

## Geplanter Test nach Freigabe

1. Workflow-Diff und Berechtigungsumfang prüfen; menschliche Freigabe von [PR #14](https://github.com/Snahdul/HaMi-AI-Engineering/pull/14) und Merge nach `main`.
2. In `Actions → HaMi GitHub Project status → Run workflow` den abgeschlossenen Issue **#2** explizit auf `Done` synchronisieren; Laufprotokoll und GitHub-Project-Board kontrollieren.
3. Bei einem aktiven Issue `workflow:in-progress` hinzufügen und nach einem Action-Lauf `In Progress` kontrollieren.
4. Danach das Label wechseln zu `workflow:review` und `Review` kontrollieren.
5. Einen neuen internen Draft-PR auf dem Board beobachten; nach der ersten geplanten Synchronisierung muss er `In Progress` erreichen. Nach `ready for review` muss die nächste Synchronisierung `Review` setzen.
6. PR-Merge und Issue-Abschluss mit den integrierten `Done`-Workflows prüfen.
7. Fehlerbehandlung, Token-Rotation und Testergebnisse in [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10) dokumentieren.

**Keine dieser Live-Prüfungen ist bisher erfolgreich nachgewiesen.**

## Referenzen

- [GitHub: Built-in automations](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-built-in-automations)
- [GitHub: Automating Projects using Actions](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/automating-projects-using-actions)
- [GitHub: Securely using pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)
