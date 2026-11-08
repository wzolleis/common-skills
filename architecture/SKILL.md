---
name: architecture
description: Wie wir die Software aufbauen. Use Cases, Datenmodelle, lesender und schreibender Datenzugriff, Caching, Services und Tests. Die Anzeige der Daten und die Eingabe der Daten in der UI. Verwenden beim Planen und Umsetzen eines Use Case oder Change und bei Fragen, wohin eine Funktion gehört.
---

# Architektur

Die Architektur beschreibt den Aufbau der Software und wie wir die Daten lesen und schreiben.
Außerdem betrachten wir die Eingabe und Anzeige der Daten.
Der Einsatz der Frameworks für das Routing und Laden bzw. Caching der Daten wird beschrieben.

Stack im Frontend: React, tanstack-router, tanstack-query, Zod, Tailwind und shadcn, Tests mit vitest. Plattform
und Datenbank des Backends beschreibt der Projekt-Skill.

## Use cases first

Das Definieren der Use Cases ist der Kern der Anwendung und definiert, wie alles andere zusammenarbeiten kann.
Analysiere genau in der Sprache der Domain, wer was erledigen möchte, und definiere die Komponenten entsprechend
der Antwort auf diese Frage.
Wenn die Use Cases sauber definiert sind, ist alles andere nur noch mechanische Codierung durch das Befolgen der
Regeln.

Jede Frage zu einem Use Case hat eine Komponente, die sie beantwortet:

```text
Who wants to do what?                    → use case (Hook)                  useCompleteTodo
In which states may it happen?           → narrowing find, input state      findOpenTodoById, OpenTodo
Who may do it?                           → actor flag, who-acts policy      mayEditOthersTodos
What else must hold? (time, values)      → policy, value constructor        cannotCompleteBeforeStartPolicy, createDueDate
What must we load to check it?           → required input field             assigneeIsListMember
What can go wrong?                       → typed domain error, HTTP status  TodoAlreadyDoneError, 409
What is true afterwards?                 → event and its fields             TodoCompletedEvent
Who sees the result?                     → view, visibility rule            TodoView, todoVisibilityFromReader
```

### Verweise auf Code in Beschreibungen

Eine Beschreibung in `features/` nennt nur wesentliche Stellen im Code, z. B. den Hook des Use Case, einen
zentralen Service oder eine Stelle, die ausdrücklich nicht geändert wird. Einzelne Hilfsfunktionen und Dateien,
die sich leicht ändern, gehören nicht hinein. Ist unklar, wohin eine neue Funktion gehört (View, Repository,
Service oder Use Case, welches Feature), fragt der Agent zurück, statt zu raten. Wie mit Verweisen in erledigten
Beschreibungen umgegangen wird, steht in [use-case.md](use-case.md) unter „Erledigte Beschreibungen“.

### Rechte und Rollen

Es gibt den Administrationsbereich, die Aktionen dort dürfen nur von Usern in der Rolle "Administrator"
durchgeführt werden.
Es gibt den User-Bereich, die Aktionen dort dürfen von den Usern in der Rolle "User" durchgeführt werden.
Geprüft wird auf dem Server, Details im Skill `authorization`.

## Layout

```text
shared/                 Geteilt zwischen Client und Backend (Einzelheiten im Skill shared-modules)
├ <thema>.ts            Zod-Schemas und Typen eines Aggregats, z. B. todo.ts
├ <thema>-rules.ts      Services: Regeln und Berechnungen (siehe service.md)
└ <thema>-report.ts     Services: Auswertungen für Berichte

src/
├ api/                  Ein File pro Aggregat, ohne React: fetch… für die View, create/update/delete… für das
│                       Repository (siehe views.md, repository.md). http.ts enthält request und ApiError.
├ views/                Ein File pro Aggregat mit den lesenden Hooks, z. B. useTodos (siehe views.md)
├ features/             Fachliche Bereiche, siehe unten
├ routes/               Routen für das file-basierte Routing von tanstack-router. Eine Route bindet
│                       nur die Seite aus features/…/components ein. routeTree.gen.ts wird erzeugt, nicht bearbeiten.
├ application/          Layout, Navigationsmenü und Breadcrumb
├ components/           Fachlich neutrale Komponenten; ui/ enthält die shadcn-Komponenten
├ lib/                  Hilfsfunktionen für Frameworks und Bibliotheken (format, use-now, user-context)
├ tests/                Tests, die zu keiner einzelnen Komponente gehören. routes.test.tsx prüft, dass
│                       jede Route eine Ansicht hat und diese angezeigt werden kann.
└ query-client.ts       QueryClient, Persistenz im localStorage, globale Fehlerbehandlung (401)

src/features/
├ <aggregat>/           Ein Ordner pro Aggregat oder Thema, z. B. todos, todo-lists, users
├ auth/                 Anmeldung und Passwort
└ dashboard/            Startseite und die Dashboards von Admin- und User-Bereich

src/features/todos/     Aufbau eines Aggregats, jeder Ordner nur bei Bedarf
├ use-cases/            Ein Hook pro Use Case (siehe use-case.md)
├ components/           Komponenten für die Ansichten des Aggregats, Tests daneben (*.test.tsx).
│                       Enthält auch die Seiten, die eine Route aus src/routes einbindet
└ actions/              Actions, die auf dem Dashboard erscheinen
```

Das Backend (Endpoints, Datenbankschema, Migrationen, Skripte) beschreibt der Skill `backend-modules`, die
konkreten Verzeichnisse der Projekt-Skill.

### Admin- und User-Bereich in einem Feature

Unterhalb von `src/features` wird nicht nach `admin/` und `user/` getrennt. Ein Feature liegt in einem
einzigen Ordner, auch wenn es Seiten für beide Bereiche hat. Komponenten, Use Cases und Actions
verwenden beide Seiten gemeinsam.

Hat ein Feature Seiten für beide Bereiche, bekommt die Seite des Administrationsbereichs das Präfix
`admin`: die Datei heißt `admin-…`, die Komponente `Admin…`. Die Datei der Seite des User-Bereichs
bleibt ohne Präfix:

```text
src/features/todo-lists/
└ components/
  ├ todo-list-table.tsx
  ├ todo-lists-page.tsx         TodoListsPage, eingebunden von src/routes/user/todo-lists.tsx
  └ admin-todo-lists-page.tsx   AdminTodoListsPage, eingebunden von src/routes/admin/todo-lists.tsx
```

Gibt es ein Feature nur in einem Bereich, z. B. `users` nur für Administratoren, entfällt das Präfix.
Welcher Bereich eine Seite zeigt, entscheidet die Route unter `src/routes/admin/` oder `src/routes/user/`.
Die Rechte prüft der Server, nicht der Ordner.

### Imports

Import-Aliase: `@/` → `src/`, `@shared/` → `shared/`, `@features/` → `src/features/`.
Importiert wird ohne Dateiendung: `@/api/todos`, nicht `@/api/todos.ts`. Das prüft eine ESLint-Regel
(`no-restricted-imports`). Ausnahmen:

- Generierte Dateien (`src/components/ui/`, `src/routeTree.gen.ts`) behalten die Imports, die der
  Generator schreibt.
- Skripte, die direkt mit `node` laufen, brauchen die Endung.

## References

- [use-case.md](use-case.md): Was ein Use Case ist, wo er liegt und wie er die anderen Bausteine verwendet. Zuerst
  lesen.
- [views.md](views.md): Daten lesen, ein Hook pro Aggregat in `src/views/`
- [repository.md](repository.md): Daten schreiben, API-Funktionen in `src/api/` und `useMutation`, Query Keys invalidieren
- [service.md](service.md): Werte berechnen und Regeln prüfen, als reine Funktionen in `shared/`
- [testing.md](testing.md): Wann sich ein Test lohnt, auf welcher Ebene er liegt und wie er geschrieben wird
