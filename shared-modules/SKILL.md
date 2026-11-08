---
name: shared-modules
description: Beschreibt das Verzeichnis shared/ mit dem Code, den Client (src/) und Server gemeinsam verwenden. Zod-Schemas, Regeln, Berechnungen, Datums- und Textfunktionen, was wohin gehört und was dort nicht erlaubt ist. Verwenden beim Anlegen oder Ändern von Dateien in shared/, wenn eine Regel oder Berechnung auf beiden Seiten gebraucht wird, und vor jedem Commit mit neuen Dateien in shared/.
---

# Aufbau von shared/

`shared/` enthält den Code, den der Client (`src/`) und das Backend gemeinsam verwenden. Importiert wird über den
Alias `@shared/*`.

Weil derselbe Code im Browser und auf dem Server läuft, ist er rein: keine Requests, kein Zugriff auf die
Datenbank, kein Zustand. Die Regeln laufen im Client vor dem Absenden und auf dem Server noch einmal,
nur die Prüfung auf dem Server ist verbindlich (Skill `architecture`, `service.md`).

Für `src/` gilt der Skill `ui-modules`, für das Backend der Skill `backend-modules`.

# Wohin gehört eine Datei?

| Die Datei …                                                              | gehört nach                  | Beispiel                     |
|--------------------------------------------------------------------------|------------------------------|------------------------------|
| enthält die Zod-Schemas und Typen eines Aggregats (Lesen, Anlegen, Ändern) | `shared/<aggregat>.ts`     | `todo.ts`, `user.ts`         |
| prüft Regeln eines Aggregats oder rechnet mit seinen Daten               | `shared/<aggregat>-rules.ts` | `todo-rules.ts`              |
| wertet Daten mehrerer Aggregate für Berichte aus                         | `shared/<thema>.ts`          | `todo-report.ts`             |
| rechnet mit Tagen, Wochen oder Zeiträumen, ohne Fachlichkeit             | `shared/<thema>.ts`          | `day-range.ts`, `week.ts`    |
| legt fest, wie Tage, Uhrzeiten, Monate und Jahre als Text aussehen       | `shared/date-schemas.ts`     |                              |
| macht aus Zeiten und Dauern Text für UI und Server                       | `shared/format.ts`           |                              |
| ist ein Test                                                             | daneben als `<name>.test.ts` | `todo-rules.test.ts`         |
| hilft nur Tests                                                          | `shared/test-dates.ts`       |                              |

Was nur die UI braucht, z. B. eine CSS-Klasse für ein überfälliges Todo, gehört nach `src/lib/`, nicht nach
`shared/`. Was nur der Server braucht, z. B. Passwort-Hashes oder Transaktionen, gehört zu den Hilfen des
Backends (Skill `backend-modules`).

# Was in shared/ erlaubt ist

- **Imports:** andere Dateien aus `shared/`, `zod`, `temporal-polyfill` und die Bibliotheken, die aus dem
  Datenbankschema Zod-Schemas erzeugen (z. B. `drizzle-zod` mit dem Schema der Tabellen). Welche das im Projekt
  sind, nennt der Projekt-Skill.
- **Nicht erlaubt:** React, Browser-APIs (`window`, `document`, `localStorage`, `fetch`), Node-APIs
  (`node:*`, `process`, `Buffer`), die Datenbankverbindung und alles aus `src/` oder dem Backend.
- Keine Geheimnisse in Schemas: Hashes und Schlüssel werden mit `.omit(…)` entfernt, sie verlassen nie
  das Backend (z. B. `passwordHash` in `user.ts`).

# Konventionen

- **Regeln** liefern `null`, wenn alles gültig ist, sonst eine verständliche Meldung auf Deutsch, z. B.
  `checkDueDate` in `todo-rules.ts`. Der Server wirft die Meldung als `RuleError` und antwortet mit 422.
- **Tage** sind Texte `"JJJJ-MM-TT"` mit Branded Types wie `Day`, `Month`, `Year` und `TimeOfDay` aus
  `date-schemas.ts`. Ein `Day` entsteht nur über das Schema, einen Parser oder die Helfer für Zeiträume
  (z. B. `addDays`, `monthOf`) oder aus einem Zeitpunkt mit einer Funktion wie `localDay`. Ein Cast `as Day`
  steht nur in diesen Helfern.
- **Lokale Zeit** gilt in einer festen Zeitzone `TZ` des Projekts (z. B. Europe/Berlin). Mit Kalendertagen und
  Monaten wird über `Temporal` gerechnet (`addDays`, `addMonths`), nie durch Addieren von 24 Stunden.
  Dauern und Abstände zwischen Zeitpunkten dürfen in Millisekunden mit `getTime()` gerechnet werden.
- **Feste IDs** von Rollen und Einstellungen stehen als Konstanten in der Datei des Aggregats, z. B.
  `ADMIN_ROLE_ID` in `role.ts`. Der Code verweist nur über die ID auf sie, nie über den Namen.
- Jede Regel und Berechnung bekommt einen Test daneben (Skill `architecture`, `testing.md`).

# Prüfung vor dem Commit

Neue Dateien in `shared/` gegen die Tabelle und die erlaubten Imports prüfen. Bei einem Verstoß wird nicht
committet. Stattdessen dem User die Datei, die verletzte Regel und den richtigen Ort nennen.
