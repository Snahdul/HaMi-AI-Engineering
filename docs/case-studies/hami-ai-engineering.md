# Fallstudie 01: Die Entstehung von HaMi AI Engineering

**Human-led, AI-assisted Software Engineering**

> **Status:** Öffentlicher Entwurf im [Draft-PR #11](https://github.com/Snahdul/HaMi-AI-Engineering/pull/11), Stand 16.11.2026. Der nachweislich abgeschlossene Teil ist der [erste Dokumentations-PR #9](https://github.com/Snahdul/HaMi-AI-Engineering/pull/9). Folgearbeiten bleiben als solche gekennzeichnet.

## Ausgangsfrage

Wie lässt sich die Zusammenarbeit eines erfahrenen Entwicklers mit ChatGPT **öffentlich überprüfbar** zeigen, ohne private Repositories, Chatverläufe, Kundeninformationen oder interne Infrastruktur zu veröffentlichen?

Eine reine Beschreibung von Arbeitsregeln wäre kein überzeugender Beleg. Deshalb ist **die Entstehung dieses Referenzprojekts selbst** die erste Fallstudie. Hier existieren öffentliche Issues, Pull Requests, Commits und Review-Kommentare, die Dritte unabhängig voneinander nachlesen können.

## Ergebnis: Ein echter öffentlicher Entwicklungsverlauf

Am 15.11.2026 wurde das [erste Dokumentationspaket über PR #9](https://github.com/Snahdul/HaMi-AI-Engineering/pull/9) in `main` integriert. Es enthält Methodik, Rollen, Sicherheitsgrenzen, eine Architekturentscheidung im Vorschlagsstatus, Projektvorlagen sowie ausdrücklich als Kurzfassungen gekennzeichnete Fallstudien. Die erste Integration ist **ein belegtes Dokumentationsergebnis**, noch keine ausführbare .NET-Anwendung.

| Schritt | Beobachtbare Handlung | Öffentlicher Beleg |
| --- | --- | --- |
| 1. Aufgaben und Grenzen | Projektziele, Publikationsregeln und initiale Issues wurden formuliert. | [Issue #1](https://github.com/Snahdul/HaMi-AI-Engineering/issues/1) und [initiale Issues](https://github.com/Snahdul/HaMi-AI-Engineering/issues) |
| 2. Änderungsumfang | Feature-Branch `docs/initial-project-foundation`, drei Commits, 14 geänderte Dateien. | [PR #9](https://github.com/Snahdul/HaMi-AI-Engineering/pull/9) |
| 3. Assistierte Prüfung | Ein Codex-Code-Review zum anfänglichen PR-Stand und eine dokumentierte ChatGPT-Review-Vorprüfung. | [Codex-Zusammenfassung](https://github.com/Snahdul/HaMi-AI-Engineering/pull/9#issuecomment-6895529368), [Review-Vorprüfung](https://github.com/Snahdul/HaMi-AI-Engineering/pull/9#pullrequestreview-5911283352) |
| 4. Menschliche Entscheidung | Integration nach Review durch den Repositoryinhaber am 15.11.2026. | [Merge-Commit `38cb9ffd`](https://github.com/Snahdul/HaMi-AI-Engineering/commit/38cb9ffdf2ebc39dd1ad41d126c206e63e01ea27) |
| 5. Kontrollen und offene Punkte | Schutz von `main`, Publikationsgrenzen und noch offene administrative Kontrollen wurden dokumentiert. | [Issue #10](https://github.com/Snahdul/HaMi-AI-Engineering/issues/10), [Ruleset `protect-main`](https://github.com/Snahdul/HaMi-AI-Engineering/rules/27316867) |
| 6. Weiterentwicklung | Öffentliche Prozessfallstudie, technische HaMiPulse-Fallstudie und Lizenzdateien werden in getrennten **Draft-PRs** vorbereitet. | [PR #11](https://github.com/Snahdul/HaMi-AI-Engineering/pull/11), [PR #12](https://github.com/Snahdul/HaMi-AI-Engineering/pull/12), [PR #13](https://github.com/Snahdul/HaMi-AI-Engineering/pull/13) |

Die Reviews sind keine pauschale Qualitätsgarantie: Die Codex-Zusammenfassung bezieht sich auf den von ihr genannten Commit, und die dokumentierte Vorprüfung ersetzt keine menschliche Entscheidung. Für PR #9 wurde **kein Anwendungstest** durchgeführt; ein erfolgreicher automatisierter CI-Lauf wurde nicht belegt.

## Wer verantwortet welche Arbeit?

| Aufgabe | Entwickler | ChatGPT / KI-Unterstützung |
| --- | --- | --- |
| Ziel, Umfang, Priorität | Legt fest und entscheidet | Strukturiert Anforderungen und stellt Rückfragen |
| Architektur und Veröffentlichungsgrenzen | Bewertet Risiken und gibt Entscheidungen frei | Stellt Lösungsoptionen und Risiken gegenüber |
| Änderungen im Repository | Verantwortet Umfang und Freigabe | Bereitet Texte und Änderungen im Feature-Branch vor |
| Review | Prüft Befunde und entscheidet über Merge | Hilft bei Diff-Prüfung, Plausibilitäts- und Sicherheitskontrolle |
| Projektgedächtnis | Bestimmt verbindliche Artefakte und Status | Liest und aktualisiert freigegebene Issues/PRs |

**GitHub ist die persistente Quelle für Arbeitsaufträge, Entscheidungen und Ergebnisse; ChatGPT ist ein Assistenzwerkzeug.** Ein Chatverlauf ist weder die alleinige Dokumentation noch eine eigenständige Freigabeinstanz.

## Ein tatsächlicher Prozessfehler: Aufgaben aktiv, Board noch auf „Todo“

Bei einer Sichtprüfung fiel auf, dass mehrere bereits bearbeitete Issues und Draft-PRs im öffentlichen GitHub Project weiterhin in `Todo` standen. **Ursache auf Prozessebene:** Der Status eines GitHub-Issues bzw. Draft-PRs und das Statusfeld eines GitHub-Project-Items sind verschieden. Die eingesetzte GitHub-Integration kann Issues und PRs verändern, aber nicht die Statusfelder des Project-Boards schreiben.

**Korrektur:** Der Repositoryinhaber verschob die fünf bereits vorhandenen aktiven Karten manuell nach `In Progress`. Die neuen Draft-PRs #12 und #13 wurden in das Board aufgenommen; ihre Verschiebung nach `In Progress` blieb nach der vorliegenden Sichtprüfung noch offen.

**Erkenntnis:** Ein erfolgreiches GitHub-API-Update ist **kein Nachweis für einen korrekten Project-Status**. Künftige Arbeitsabläufe müssen die Board-Pflege ausdrücklich berücksichtigen. Der Screenshot der manuellen Sichtprüfung ist hier nicht öffentlich veröffentlicht; die Board-Korrektur ist daher **als berichteter Vorgang, nicht als durch diese Datei unabhängig verifizierter Nachweis** gekennzeichnet. Die zugehörige Nacharbeit wird in [Issue #1](https://github.com/Snahdul/HaMi-AI-Engineering/issues/1) nachgehalten.

Gerade diese Korrektur zeigt, warum überprüfbare Prozesse wichtiger sind als eine bloße Selbstdarstellung eines immer fehlerfreien KI-Workflows.

## Was die Fallstudie belegt – und was nicht

**Öffentlich prüfbar:**

- Ein realer Anforderungs- und Dokumentationsprozess mit Feature-Branch, PR, Reviews und Merge.
- Der bewusst geschützte Default-Branch und eine dokumentierte Sicherheitsbaseline, einschließlich offener Kontrollen.
- Die anschließende Bearbeitung weiterer klar abgegrenzter Aufgaben in Draft-PRs.

**Nicht damit bewiesen:**

- Die vollständige Entstehungsgeschichte privater HaMi-Projekte oder unveröffentlichte Chatverläufe.
- Die funktionale Qualität einer produktiven Software allein durch Dokumentation.
- Ein vollständiges Security-Audit oder automatisierte Anwendungstests.
- Die Abnahme noch offener Draft-PRs oder eine bereits veröffentlichte Lizenzentscheidung: Die Lizenzaufteilung wurde beschlossen, ihre Dateien befinden sich in [PR #13](https://github.com/Snahdul/HaMi-AI-Engineering/pull/13).

## Nächste Nachweise

1. **Prozess:** Diese Fallstudie in [Issue #2](https://github.com/Snahdul/HaMi-AI-Engineering/issues/2) über [PR #11](https://github.com/Snahdul/HaMi-AI-Engineering/pull/11) prüfen und menschlich freigeben.
2. **Technische Praxis:** [HaMiPulse](hami-pulse.md) ergänzt Architektur, Fehlersuche und ein sichtbar überprüfbares Anwendungsergebnis; öffentliche Belege sind in [Issue #3](https://github.com/Snahdul/HaMi-AI-Engineering/issues/3) noch zu vervollständigen.
3. **Reproduzierbare Implementierung:** Die geplante [öffentliche .NET-Demo](../../demo/README.md) soll vollständigen Quellcode, Tests und Startanleitung liefern ([Issue #7](https://github.com/Snahdul/HaMi-AI-Engineering/issues/7)).

**Publikationsgrenze:** Keine privaten Repositories, Zugangsdaten, internen Netzadressen, unbereinigten Logs oder vollständigen privaten Chats übernehmen. Vor jedem Merge sind Inhalt, Nachweisstand und Rechte erneut zu prüfen.
