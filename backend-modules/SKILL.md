---
name: backend-modules
description: Beschreibt den Aufbau des Backends (Endpoints, gemeinsame Hilfen, Datenbankschema, Migrationen, Skripte), was wohin gehört und wer wen importieren darf. Verwenden beim Anlegen oder Verschieben von Dateien im Backend, beim Anlegen eines neuen Endpoints und vor jedem Commit mit neuen Backend-Dateien.
---

# Aufbau der Module im Backend

Das Backend nimmt die Requests unter `/api/…` an und läuft nur auf dem Server. Dazu gehören das Datenbankschema,
die Migrationen und die Skripte für die Kommandozeile. `shared/` läuft auf Server und Client: dort stehen die
Schemas und Regeln, die beide Seiten verwenden.

Welche Plattform, welche Datenbank und welche Verzeichnisse das Projekt verwendet, beschreibt der Projekt-Skill.
Dieser Skill legt fest, welche Bausteine es gibt und wie sie zusammenhängen.

Für die UI unter `src/` gilt der Skill `ui-modules`, für `shared/` der Skill `shared-modules`.
Wie Services und Repositories aufgebaut sind, beschreibt der Skill `architecture`.

# Bausteine

| Baustein                | Aufgabe                                                                    | Beispiel Todo-Liste            |
|-------------------------|----------------------------------------------------------------------------|--------------------------------|
| Endpoint                | nimmt die Requests eines Aggregats an (`/api/<aggregat>`), eine Datei pro Aggregat | `todos.ts`             |
| Hilfen (`lib/`)         | HTTP, Session, Rollen, IDs, Fehlerklassen, für mehrere Endpoints           | `lib/http.ts`, `lib/session.ts` |
| Store                   | liest und schreibt ein Aggregat, wenn mehrere Zugänge (REST, MCP) dieselben Regeln brauchen | `lib/todos-store.ts` |
| Schema und Typ          | Zod-Schema eines Aggregats                                                 | `shared/todo.ts`               |
| Regel oder Berechnung   | für Client und Server                                                      | `shared/todo-rules.ts`         |
| Datenbankschema         | beschreibt die Tabellen, eine Datei für alle                               | `db/schema.ts`                 |
| Migration               | nur mit dem Generator des Projekts, nie von Hand                           | `db/migrations/`               |
| Skript                  | per Hand oder über `npm run` gestartet (Seed, Migration, Admin, Passwort, Prüfungen), gemeinsame Hilfen in `scripts/lib/` | `scripts/grant-admin.ts` |
| Test                    | neben der getesteten Datei als `<name>.test.ts`                            | `lib/id.test.ts`               |

# Wer darf wen importieren?

- Ein Endpoint → Hilfen, `@shared/`, Datenbankschema. Ein Endpoint importiert keinen anderen Endpoint.
- Hilfen → `@shared/`, Datenbank, nie einen Endpoint.
- `shared/` → `shared/`, Bibliotheken und das Datenbankschema (für erzeugte Zod-Schemas). Nie das Backend, `src/`
  oder die Datenbankverbindung.
- Datenbankschema → nur Typen aus `shared/`.
- Nichts im Backend importiert aus `src/`.

# Konventionen eines Endpoints

- Eine Datei pro Aggregat, die Pfade stehen in der Datei.
- Jeder Endpoint läuft hinter der Prüfung der Anmeldung und der Rolle (Skills `authentication` und
  `authorization`). Ohne Anmeldung läuft nur die Anmeldung selbst.
- Body lesen und Fehler beantworten über gemeinsame Hilfen, nicht pro Endpoint neu. Datenbank-Fehler mit eigener
  Meldung (z. B. ein doppelter Eintrag) prüft der Endpoint vorher selbst.
- Fehlerklassen aus den Hilfen (`NotFoundError`, `ForbiddenError`, `RuleError`).
- Änderungen an den Daten eines Users laufen in einer Transaktion, die die Zeile des Users sperrt, damit sich
  zwei gleichzeitige Änderungen nicht überholen.
- Die Regeln aus `shared/` prüft der Server noch einmal (Skill `architecture`, `service.md`).

# Prüfung vor dem Commit

Neue und verschobene Backend-Dateien gegen die Bausteine und die Import-Regeln prüfen. Bei einem Verstoß wird
nicht committet. Stattdessen dem User die Datei, die verletzte Regel und den richtigen Ort nennen.
