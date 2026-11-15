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
