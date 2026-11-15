# HaMi AI Engineering

**Human-led, AI-assisted Software Engineering**

Dieses öffentliche Referenzprojekt dokumentiert die Zusammenarbeit eines erfahrenen C#/.NET-Entwicklers mit ChatGPT: von der Anforderung über Architektur, Implementierung und Tests bis zur menschlichen Freigabe und nachvollziehbaren Dokumentation.

**Nicht möglichst viel KI-generierter Code ist das Ziel, sondern überprüfbare Ergebnisse, nachvollziehbare Entscheidungen und dauerhaft nutzbares Projektwissen.**

## Was hier gezeigt wird

- **Engineering-Workflow:** GitHub Issues als Arbeitsaufträge, Pull Requests als überprüfbare Änderungen und Architecture Decision Records (ADRs).
- **Verantwortlichkeiten:** Der Entwickler definiert Ziele, prüft und entscheidet. ChatGPT unterstützt mit Analyse, Lösungsvarianten, Umsetzung, Fehlersuche und Dokumentation.
- **Fallstudien:** HaMiPulse, Tara, Architekturpraxis und HaMiHeimnetz – bewusst abstrahiert und ohne vertrauliche Inhalte.
- **Demonstration:** Eine kleine .NET-Anwendung, deren Entwicklung öffentlich nachvollziehbar ist (geplant).

## Der Ablauf

```text
Ziel & Akzeptanzkriterien (Mensch)
         ↓
GitHub Issue als persistenter Arbeitsauftrag
         ↓
Analyse und Lösungsvarianten (Entwickler + ChatGPT)
         ↓
Implementierung in einem Feature-Branch
         ↓
Tests, Review und Pull Request
         ↓
Menschliche Freigabe und Integration
         ↓
Dokumentation, Erkenntnisse, Issue-Abschluss
```

## Dokumentation

| Thema | Dokument |
| --- | --- |
| Entwicklungsmethodik | [Workflow](docs/methodology/workflow.md) |
| Rollen und Grenzen | [Verantwortlichkeiten](docs/methodology/responsibilities.md) |
| Erste Fallstudie | [HaMiPulse – Flugkarte](docs/case-studies/hami-pulse.md) |
| Publikationsgrenzen | [ADR-0001](docs/decisions/ADR-0001-publication-boundary.md) |
| Roadmap | [Roadmap](docs/ROADMAP.md) |
| Geplante .NET-Demo | [Demo](demo/README.md) |

## Transparenz

Dieses Repository ist eine **kuratierte öffentliche Darstellung** der Arbeitsweise, kein vollständiger Export privater Projekte oder Chats. Private Quelltexte, Zugangsdaten, personenbezogene Daten und echte Infrastrukturtopologien werden nicht übernommen.

Erfahrungsberichte, Konzepte und nachweisbare Ergebnisse werden voneinander unterschieden. Entscheidungen und Freigaben bleiben beim Entwickler.

## Weiterführendes Profil

[Berufliches Profil und Projekte](https://millmann.biz)

## Lizenzen

Die Nachnutzung wird bewusst nach **Softwarecode** und **Dokumentation** getrennt:

| Bestandteil | Lizenz |
| --- | --- |
| Eigenständig veröffentlichter Softwarecode, insbesondere die geplante .NET-Demo | [MIT](LICENSE) |
| Eigene Dokumentation, Methodik, Fallstudien und erläuternde Diagramme | [CC BY 4.0](LICENSE-DOCS.md) |

Die Lizenzen gelten nur für Inhalte, für die der jeweilige Rechteinhaber eine entsprechende Freigabe erteilen kann. **Private HaMi-Projekte, deren Quelltexte, interne Infrastruktur, Zugangsdaten und Inhalte Dritter sind nicht Teil dieser Freigabe.** Für Screenshots und sonstige Fremdinhalte erfolgt eine separate Rechteprüfung vor Veröffentlichung.

Die Entscheidung und die technische Veröffentlichung werden in [Issue #1](https://github.com/Snahdul/HaMi-AI-Engineering/issues/1) dokumentiert.
