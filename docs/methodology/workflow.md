# Unser Engineering-Workflow

## 1. Ziel und Akzeptanzkriterien
Der Entwickler beschreibt Problem, Nutzen, Grenzen und das überprüfbare Ergebnis. Das GitHub Issue hält die vereinbarten Kriterien dauerhaft fest.

## 2. Kontext sichten
Bestehende Issues, Pull Requests und Architekturentscheidungen sind die verlässlichen Projektartefakte. ChatGPT darf Informationen aus freigegebenen Quellen auswerten, aber keine privaten Projektinhalte veröffentlichen.

## 3. Optionen analysieren
ChatGPT schlägt Lösungsvarianten samt Risiken und Trade-offs vor. Der Entwickler prüft sie und trifft die technische Entscheidung. Weitreichende Entscheidungen werden als ADR dokumentiert.

## 4. Schrittweise implementieren
Kleine Features und Fixes entstehen in separaten Branches. Der Pull Request beschreibt Änderung, Teststand und Auswirkungen. KI-Ausgaben gelten nie ohne Prüfung als freigegeben.

## 5. Testen und sichtbar prüfen
- Anforderungen und Randfälle validieren
- Builds, Unit- und Integrationstests soweit relevant ausführen
- Sicherheits- und Datenrisiken kontrollieren
- Das Ergebnis in der tatsächlichen Anwendung ausprobieren

Automatisierte Tests ersetzen keine fachliche Prüfung.

## 6. Review und Freigabe
Der Entwickler prüft den PR und entscheidet über die Integration. Ein Issue wird erst geschlossen, wenn Akzeptanzkriterien und Ergebnis nachvollziehbar sind.

## 7. Wissen dauerhaft erhalten
Architekturregeln, Problemursachen und Folgeaufgaben werden im Repository festgehalten, statt allein in Chatverläufen zu verbleiben.

**Leitlinie:** Ein sichtbares, nutzbares Zwischenergebnis schafft Orientierung für die weitere Optimierung; notwendige Sicherheits- und Qualitätsprüfungen bleiben erhalten.

## Öffentliches Workflow-Beispiel: Dokumentations-PR #9

Die ausführliche [Fallstudie zur Entstehung von HaMi AI Engineering](../case-studies/hami-ai-engineering.md) verbindet diesen PR mit den nachfolgenden Issues, Sicherheitsprüfungen und dokumentierten Korrekturen.

Der bereits gemergte [Pull Request #9](https://github.com/Snahdul/HaMi-AI-Engineering/pull/9) zeigt einen realen, öffentlich überprüfbaren Ausschnitt unserer Zusammenarbeit:

1. **Auftrag und Anforderungen:** Die bestehenden [Issues #1](https://github.com/Snahdul/HaMi-AI-Engineering/issues/1), [#2](https://github.com/Snahdul/HaMi-AI-Engineering/issues/2), [#3](https://github.com/Snahdul/HaMi-AI-Engineering/issues/3), [#5](https://github.com/Snahdul/HaMi-AI-Engineering/issues/5) und [#7](https://github.com/Snahdul/HaMi-AI-Engineering/issues/7) beschreiben die jeweiligen Ziele und Folgearbeiten.
2. **Änderung im Feature-Branch:** `docs/initial-project-foundation` enthielt Methodik, Verantwortlichkeiten, Kurzfassungen von Fallstudien, ADR und Projektvorlagen. Insgesamt betraf der PR 14 Dateien.
3. **KI-gestützte Vorprüfung:** Der PR dokumentiert eine Prüfung durch ChatGPT-Assistenz und eine automatisierte Codex-Review-Zusammenfassung. Sie ersetzen keine menschliche Freigabe.
4. **Menschliche Entscheidung:** Der Repositoryinhaber integrierte den PR am 15.11.2026 in `main`; [Merge-Commit `38cb9ffd`](https://github.com/Snahdul/HaMi-AI-Engineering/commit/38cb9ffdf2ebc39dd1ad41d126c206e63e01ea27).
5. **Offene Folgearbeiten:** Die Veröffentlichung der beschlossenen Lizenzaufteilung über [Draft-PR #13](https://github.com/Snahdul/HaMi-AI-Engineering/pull/13) ([#1](https://github.com/Snahdul/HaMi-AI-Engineering/issues/1)), nachprüfbare HaMiPulse-Belege ([#3](https://github.com/Snahdul/HaMi-AI-Engineering/issues/3)) und ausführbarer Demo-Code ([#7](https://github.com/Snahdul/HaMi-AI-Engineering/issues/7)) bleiben ausdrücklich offen.

**Nachweisgrenze:** Es handelt sich um einen Dokumentations-PR. Anwendungstests wurden dafür nicht ausgeführt; ein erfolgreicher automatisierter CI-Lauf ist nicht belegt. Die zugrunde liegenden privaten Softwareprojekte werden damit weder offengelegt noch vollständig unabhängig verifizierbar.

