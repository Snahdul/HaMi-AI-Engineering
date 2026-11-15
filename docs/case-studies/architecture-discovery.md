# Fallstudie: Deterministische Modul-Discovery in .NET

**Status:** Technische Erkenntnis; ein eigenständiges reproduzierbares Beispiel ist geplant.

## Problem
Ein modularer Monolith verwendet dynamische Assembly-Erkennung zur DI-Registrierung. Ein scheinbar harmloser Codeumbau kann dazu führen, dass eine Assembly zum Zeitpunkt der Erkennung noch nicht geladen ist.

## Technische Ursache
`AppDomain.CurrentDomain.GetAssemblies()` gibt die **zu diesem Zeitpunkt geladenen** Assemblies zurück – nicht automatisch alle Assemblies einer Anwendung. Als alleinige Quelle zur vollständigen Modul-Discovery ist die Methode daher ungeeignet.

## Architekturregel
Module oder Assemblies für die Registrierung werden explizit und deterministisch angegeben. Eine Startvalidierung überprüft erforderliche Registrierungen.

## Geplanter öffentlicher Nachweis
Ein minimales .NET-Beispiel soll die problematische Abhängigkeit von Ladezeitpunkten und die explizite Alternative dokumentieren.

Die Fallstudie enthält keine privaten Originalquellen.
