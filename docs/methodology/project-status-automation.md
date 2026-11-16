# GitHub-Project-Statusautomatisierung

**Status:** Implementierungsentwurf in einem Draft-PR. **Nicht aktiv**, bis der Workflow geprüft, gemergt und konfiguriert wurde. Verfolgt in [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10); organisatorische Regel in [Issue #1](https://github.com/Snahdul/HaMi-AI-Engineering/issues/1).

## Motivation

Issue/PR-Zustände und GitHub-Project-Statuswerte sind unabhängig. Die GitHub-Integration von ChatGPT kann derzeit Issues und PRs verändern, aber keine GitHub-Project-Items schreiben. Daher brauchen wir entweder einen GitHub-eigenen Status-Workflow oder einen autorisierten Schreibzugriff über die GitHub-Projects-API.

## Architektur und Zuständigkeit

1. **GitHub Projects (eingebaut):** `Item added to project → Todo`, `Issue/PR closed → Done` und `PR merged → Done`. Für diese Workflows werden keine neuen Zugangsdaten benötigt. Automatisches Hinzufügen neuer Issues und PRs kann projektseitig aktiviert werden.
2. **Repository-Action `project-status.yml`:** Mit einem im Repository als Secret hinterlegten Projekt-Token setzt sie `In Progress` oder `Review`, wenn ein vertrauenswürdiges Ereignis eintritt. Bei PR-Ereignissen wird ausschließlich die bereits geprüfte Workflow-Datei aus `main` ausgeführt; es wird kein PR-Code ausgecheckt.
3. **Menschliche Entscheidung:** Die eigentliche Freigabe und der Merge werden dadurch *nicht* automatisiert. Die Action ändert nur das Project-Statusfeld, nicht den Issue- oder PR-Zustand.

| Ereignis | Zielstatus |
| --- | --- |
| Neues Issue/PR im Projekt | Todo (GitHub-eigener Workflow) |
| PR aus demselben Repository geöffnet, wieder geöffnet oder zu Draft zurückgesetzt | In Progress |
| PR als ready for review markiert | Review |
| Issue erhält Label `workflow:in-progress` | In Progress |
| Issue erhält Label `workflow:review` | Review |
| Issue abgeschlossen oder PR gemergt | Done (GitHub-eigener Workflow) |
| Manuelle GitHub-Actions-Ausführung | Explizit ausgewählter Status; geeignet zur kontrollierten Korrektur |

GitHub-Project-Statuswerte sind kein Ersatz für die menschliche Publikationsfreigabe.

## Einmalige Einrichtung – GitHub-Oberfläche

### A. Eingebaute Projekt-Workflows prüfen (ohne Token)

Im **öffentlichen GitHub Project** unter Menü `… → Workflows` folgende Regeln kontrollieren und gegebenenfalls aktivieren:

- `Item added to project` → `Status: Todo`.
- `Item closed` → `Status: Done` (Issues und PRs).
- `Pull request merged` → `Status: Done`.
- Bei Bedarf `Auto-add to project` für Issues und PRs des Repositories `Snahdul/HaMi-AI-Engineering` einschalten.

**Wichtig:** Die GitHub-eigenen Regeln sind im Projekt zu konfigurieren. Sie werden durch diese Repository-Action weder angelegt noch geändert. Auf dem GitHub-Free-Plan ist die Anzahl von Auto-add-Workflows begrenzt.

### B. Token bewusst minimal halten

Für das **benutzereigene** Project ist laut GitHub-Dokumentation ein **Personal Access Token (classic)** mit dem Scope `project` vorgesehen. Es handelt sich nicht um ein Fine-grained Token. Das Token wird **ausschließlich im eigenen GitHub-Konto erstellt und niemals in Chats, Issues, Pull Requests, Quelltext oder Screenshots geteilt**.

- GitHub-Konto → `Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token (classic)`.
- Beschreibender Name, z. B. `HaMi-Project-Status-Actions`; **kurze Laufzeit** (z. B. 30–90 Tage).
- Zunächst ausschließlich Scope `project` wählen. **Kein `repo`, `admin:repo_hook`, `workflow` oder `delete_repo` vorsorglich gewähren**. Bei einem reproduzierbaren `403` die konkret fehlende Berechtigung prüfen, bevor Rechte erhöht werden.
- Das Scope `project` ist **nicht auf dieses einzelne Project beschränkt**. Es kann andere Projekte des Kontos betreffen. Diese Einschränkung ist bei der Freigabe bewusst zu berücksichtigen.
- Bei Verdacht auf Offenlegung: Token widerrufen, im Repository ersetzen und Läufe kontrollieren.

### C. Repository-Secret und Variable anlegen

Im Repository `Snahdul/HaMi-AI-Engineering` → `Settings → Secrets and variables → Actions`:

- Unter **Secrets** ein Repository-Secret `HAMI_PROJECT_TOKEN` mit dem Tokenwert anlegen. Der Wert bleibt ausschließlich in GitHub.
- Unter **Variables** die Repository-Variable `HAMI_PROJECT_NUMBER` mit der Zahl aus der Projekt-URL setzen. Bei einem Benutzerprojekt lautet die URL beispielsweise `https://github.com/users/Snahdul/projects/5`; der Wert wäre dann `5`. **Die Zahl ist ein Beispiel, nicht die behauptete Nummer dieses Projekts.**
- Im Repository unter `Settings → Actions → General` kontrollieren: Workflow-Berechtigungen bleiben auf lesende Standardrechte begrenzt; Actions dürfen keine Pull Requests erstellen und genehmigen. Diese Einstellung ist Teil von [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10).

### D. Labels für gezielte Issue-Statuswechsel

Einmalig im Repository unter `Issues → Labels` die Labels `workflow:in-progress` und `workflow:review` anlegen. Anschließend kann ChatGPT über die vorhandene GitHub-Integration bei Aufgabenbeginn bzw. nach Abschluss der technischen Prüfungen das entsprechende Label setzen. Ein neues Label-Ereignis startet die Action.

Das Label `workflow:review` soll erst nach tatsächlicher Reviewbereitschaft gesetzt werden. Bei Rücknahme einer Freigabe kann die Action über `workflow_dispatch` oder ein neues `workflow:in-progress`-Label-Ereignis den Status korrigieren.

## Sicherheitsgrenzen des Workflows

- **`pull_request_target` nur für PR-Metadaten:** Der Workflow stammt aus dem geschützten Default-Branch; kein Checkout, kein Ausführen von PR-Code oder externen Skripten. Das erhöhte Vertrauensniveau wird bewusst auf diese Aufgabe begrenzt.
- PR-Events von Forks sind vom Job ausgeschlossen; nur PRs aus dem eigenen Repository sind zugelassen.
- Das Projekt-Token wird nur aus einem GitHub-Actions-Secret gelesen; Workflow-Code darf es nicht ausgeben.
- Die Action verwendet ausschließlich die node IDs des jeweiligen GitHub-Ereignisses oder eine bewusst gestartete `workflow_dispatch`-Aktion.
- **Race-Condition-Schutz:** Die Action fügt selbst keine Items hinzu. Sie wartet auf `Auto-add` und den ersten gesetzten Status (normalerweise `Todo`), bevor sie den Status verändert. Bei Verzögerung über 90 Sekunden schlägt der Lauf sichtbar fehl; er kann dann manuell neu gestartet werden. Gleichzeitige Läufe pro Item werden abgebrochen/ersetzt und abgeschlossene Issues bzw. PRs nicht nachträglich zurückgestuft.
- `permissions: {}` verhindert zusätzliche Repositoryrechte des temporären `GITHUB_TOKEN`.
- Bei fehlender Variable, Secret, Feld- oder Statusoption schlägt der Lauf sichtbar fehl, anstatt einen Erfolg zu behaupten.

## Abnahme- und Funktionstest nach Einrichtung

1. GitHub-Project-Nummer, Token-Secret und Labelnamen kontrollieren.
2. Workflow-PR einschließlich des sicherheitsrelevanten `pull_request_target`-Triggers fachlich/sicherheitstechnisch prüfen und ausdrücklich freigeben; erst danach in `main` mergen.
3. Unter `Actions → HaMi GitHub Project status → Run workflow` das bereits abgeschlossene **Issue #2** mit Status **Done** setzen und den Board-Wert kontrollieren. Dies dient als idempotenter Test ohne ungewollte Änderungen aktiver Aufgaben.
4. Mit einem aktiven Issue den Übergang `Todo → In Progress` per Label testen; anschließend kontrolliert `In Progress → Review`.
5. Neuen internen Draft-PR öffnen; prüfen, dass der `Auto-add`-Workflow zuerst `Todo` setzt und die Action danach zuverlässig `In Progress` schreibt. Später `ready for review` und `merged` getrennt prüfen. Bei einem Verzögerungsfehler kann die manuelle Workflow-Ausführung zur Korrektur genutzt werden.
6. Prüfergebnisse in [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10) dokumentieren. **Bis dahin ist die Automatisierung nicht als produktiv oder getestet zu bezeichnen.**

## Quellen

- [GitHub: integrierte Projektautomatisierungen](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-built-in-automations)
- [GitHub: Items automatisch hinzufügen](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/adding-items-automatically)
- [GitHub: Automating Projects using Actions](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/automating-projects-using-actions)
- [GitHub: Using the API to manage Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
