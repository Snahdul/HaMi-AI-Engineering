# ADR-0001: Öffentliches Showcase statt Spiegelung privater Projekte

- **Status:** Vorgeschlagen (Review ausstehend)
- **Datum:** 2026-11-15

## Kontext
HaMi AI Engineering soll reale Softwareentwicklung mit ChatGPT anhand nachvollziehbarer Artefakte zeigen. Die zugrunde liegenden Projektrepositories sind privat und dürfen nicht automatisch offengelegt werden.

## Entscheidungsvorschlag
Ein eigenständiges öffentliches Repository dient als kuratierte Referenz. Erfahrungen werden neu formuliert und abstrahiert.

**Öffentlich:** Methodik, freigegebene Fallstudien, eigenständige Demo, neue öffentliche Issues, ADRs und Pull Requests.

**Nicht öffentlich:** Private Quellen, interne Infrastruktur, Zugangsdaten und private Schlüssel, personenbezogene Angaben, fremde Inhalte ohne Veröffentlichungserlaubnis sowie vollständige Chatprotokolle.

## Konsequenzen
Ein öffentlicher Entwicklungsverlauf wird möglich, ohne den Schutz privater Projekte aufzugeben. Die Fallstudien sind jedoch kein Beleg für den vollständigen Inhalt privater Implementierungen.

## Prüfung vor Veröffentlichung
Jede Änderung wird auf Geheimnisse, private Referenzen, Rechte Dritter, nachweisbare Aussagen und ausreichende Abstraktion geprüft.
