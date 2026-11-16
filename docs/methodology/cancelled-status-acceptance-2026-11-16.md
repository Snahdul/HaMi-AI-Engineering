# Abnahmeprotokoll: Cancelled-Status für Pull Requests

**Datum:** 16.11.2026  
**Bezug:** [Issue #18](https://github.com/Snahdul/HaMi-AI-Engineering/issues/18), [PR #19](https://github.com/Snahdul/HaMi-AI-Engineering/pull/19).

Dieses Dokument dient der nachvollziehbaren Abnahme des Statusmodells im öffentlichen HaMi-AI-Engineering-Projekt. Der Dokumentations-PR selbst wird als isolierter Testfall verwendet; bestehende Arbeits-PRs bleiben unverändert.

## Erwartetes Verhalten

| PR-Zustand oder Aktion | Project-Status |
| --- | --- |
| Neuen internen Draft-PR eröffnen | Review |
| Ohne Merge schließen | Cancelled |
| Geschlossenen PR wiedereröffnen | Review |
| Erfolgreich mergen (gesonderter Test) | Done |

Die Statuswerte werden durch GitHub Projects (Single-Select-Feld `Status`) geführt. Die getrennten GitHub-Actions-Workflows lösen die Synchronisierung ereignisgesteuert aus; der privilegierte Workflow liest den aktuellen PR-Zustand erneut per REST API. Schließen und Wiedereröffnen des Test-PRs sind **keine** Mergefreigabe.

## Live-Nachweise

Die tatsächlichen Run-IDs, Statusübergänge und gegebenenfalls Fehlermeldungen werden nach dem Test ergänzt. Ein erfolgreicher Actions-Lauf ohne protokollierte Statusmutation gilt nicht als vollständig nachgewiesener Statuswechsel.

## Noch gesondert zu prüfen

- Der eingebaute Project-Workflow `Pull request merged` setzt gemergte PRs auf `Done`.
- Der tägliche Wiederherstellungslauf verarbeitet verpasste Ereignisse.
- Die Lebensdauer und Rotation des Project-Tokens bleiben im Sicherheits-Issue #10 dokumentiert.
