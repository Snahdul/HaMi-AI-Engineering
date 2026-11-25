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

## .NET-Build- und Paketstandard

Für HaMi-.NET-Solutions verwenden wir die nativen MSBuild- und NuGet-Mechanismen. Die gemeinsame Konfiguration liegt im passenden Repository-/Solution-Teilbaum, nicht in einem externen, impliziten Build-Service. Projektbezogene Abweichungen müssen nachvollziehbar bleiben.

| Datei | Verantwortung |
| --- | --- |
| `global.json` | Gewähltes .NET SDK und dessen Roll-forward-Verhalten |
| `Directory.Build.props` | Gemeinsame Build-Eigenschaften und Qualitätsvorgaben, z. B. TargetFramework, Nullable, ImplicitUsings, TreatWarningsAsErrors, soweit identisch |
| `Directory.Packages.props` | NuGet Central Package Management (CPM), eine geprüfte Version je Paket und zentralem Geltungsbereich |
| `*.csproj` | Projektspezifischer OutputType, tatsächliche PackageReference ohne lokale Version, ProjectReference, Ressourcen und begründete projektspezifische Eigenschaften |
| `.editorconfig` | Formatierungs- und Analyseregeln |
| `Directory.Build.targets` | Gemeinsame Build-Targets nur bei konkretem Bedarf; keine Infrastruktur auf Vorrat |

CPM wird mit `ManagePackageVersionsCentrally=true` und `PackageVersion` aktiviert. Die zentrale Versionstabelle ist keine Liste globaler Paketabhängigkeiten. Jedes Projekt referenziert nur die benötigten Pakete. Transitive Pinning oder VersionOverride nicht pauschal aktivieren; begründete native Sicherheits-Pins und andere Versionseinschränkungen einschließlich exakter Versionsbereiche erhalten. Bei mehreren Target Frameworks bzw. getrennten Build-Kontexten sind begründete Bedingungen und Ausnahmen zulässig.

Bei einer Migration bestehender Solutions zunächst die tatsächlichen Projekte, Imports, direkten und aufgelösten transitiven Abhängigkeiten sowie die SDK-/Build-Einstellungen erfassen. Reines Zentralisierungs-Refactoring versionserhaltend durchführen; Paketupdates, zusätzliche Referenzen, geänderte Qualitätsgates oder SDK-Wechsel sind eigene Entscheidungen. Vorher/nachher Restore-Graph, relevante Builds und Tests vergleichen. MSBuild und NuGet suchen ihre jeweiligen Props-Dateien vom Projektverzeichnis aufwärts; näher gelegene Dateien können die zentrale Konfiguration begrenzen. Isolierte Sandbox-/Replay-Samples oder historische Referenzprojekte behalten die selbstständige Buildfähigkeit; notwendige Props müssen Teil des geprüften Build-Kontexts sein oder die benötigten Eigenschaften und Versionen bleiben ausdrücklich lokal. Keine stillschweigende Abhängigkeit von Dateien außerhalb des kopierten Kontexts.

Einführung im jeweiligen Projekt erfolgt als nachvollziehbarer Issue-/PR-Auftrag; keine pauschale Migration aller bestehenden Repositories. Erste Referenz: [HaMi AI Engineering Agent, Issue #70](https://github.com/Snahdul/HaMi-AI-Engineering-Agent/issues/70), [Commit 451a6f51](https://github.com/Snahdul/HaMi-AI-Engineering-Agent/commit/451a6f51d063a938e0b5d1ec547df0f3e21e4df6) im Draft-PR #71; technische Abnahme noch ausstehend. Die Standardentscheidung ist vom Projektinhaber am 25.11.2026 bestätigt, ihre Veröffentlichung bleibt der PR-Freigabe vorbehalten.

Referenzen: [MSBuild: Customize the build by folder](https://learn.microsoft.com/en-us/visualstudio/msbuild/customize-by-directory), [NuGet: Central Package Management](https://learn.microsoft.com/nuget/consume-packages/Central-Package-Management).

## Öffentliches Workflow-Beispiel: Dokumentations-PR #9

Die ausführliche [Fallstudie zur Entstehung von HaMi AI Engineering](../case-studies/hami-ai-engineering.md) verbindet diesen PR mit den nachfolgenden Issues, Sicherheitsprüfungen und dokumentierten Korrekturen.

Der bereits gemergte [Pull Request #9](https://github.com/Snahdul/HaMi-AI-Engineering/pull/9) zeigt einen realen, öffentlich überprüfbaren Ausschnitt unserer Zusammenarbeit:

1. **Auftrag und Anforderungen:** Die bestehenden [Issues #1](https://github.com/Snahdul/HaMi-AI-Engineering/issues/1), [#2](https://github.com/Snahdul/HaMi-AI-Engineering/issues/2), [#3](https://github.com/Snahdul/HaMi-AI-Engineering/issues/3), [#5](https://github.com/Snahdul/HaMi-AI-Engineering/issues/5) und [#7](https://github.com/Snahdul/HaMi-AI-Engineering/issues/7) beschreiben die jeweiligen Ziele und Folgearbeiten.
2. **Änderung im Feature-Branch:** `docs/initial-project-foundation` enthielt Methodik, Verantwortlichkeiten, Kurzfassungen von Fallstudien, ADR und Projektvorlagen. Insgesamt betraf der PR 14 Dateien.
3. **KI-gestützte Vorprüfung:** Der PR dokumentiert eine Prüfung durch ChatGPT-Assistenz und eine automatisierte Codex-Review-Zusammenfassung. Sie ersetzen keine menschliche Freigabe.
4. **Menschliche Entscheidung:** Der Repositoryinhaber integrierte den PR am 15.11.2026 in `main`; [Merge-Commit `38cb9ffd`](https://github.com/Snahdul/HaMi-AI-Engineering/commit/38cb9ffdf2ebc39dd1ad41d126c206e63e01ea27).
5. **Offene Folgearbeiten:** Die Veröffentlichung der beschlossenen Lizenzaufteilung über [Draft-PR #13](https://github.com/Snahdul/HaMi-AI-Engineering/pull/13) ([#1](https://github.com/Snahdul/HaMi-AI-Engineering/issues/1)), nachprüfbare HaMiPulse-Belege ([#3](https://github.com/Snahdul/HaMi-AI-Engineering/issues/3)) und ausführbarer Demo-Code ([#7](https://github.com/Snahdul/HaMi-AI-Engineering/issues/7)) bleiben ausdrücklich offen.

**Nachweisgrenze:** Es handelt sich um einen Dokumentations-PR. Anwendungstests wurden dafür nicht ausgeführt; ein erfolgreicher automatisierter CI-Lauf ist nicht belegt. Die zugrunde liegenden privaten Softwareprojekte werden damit weder offengelegt noch vollständig unabhängig verifizierbar.

