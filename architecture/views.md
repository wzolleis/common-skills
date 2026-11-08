---
name: views
description: Wie der Client Daten liest. Ein Hook pro Aggregat in src/views/ mit useQuery, festem Query Key und Anzeige von Laden und Fehlern. Lesen, wenn eine Komponente oder ein Use Case Daten vom Server braucht.
---

# View

Eine View liest die Daten eines Aggregats vom Server und hält sie im Cache von tanstack/query.
Sie ist ein Hook, **keine Komponente**: Die Komponente zeigt an, die View liefert die Daten.

Jede View legt für ihr Aggregat einmal fest:

- den **Query Key**, unter dem die Daten im Cache liegen
- die **`fetch…`-Funktion** aus `src/api/<aggregat>.ts`, die sie lädt
- **wann** geladen wird (`enabled`)

Alle Komponenten und [Use Cases](use-case.md), die dieses Aggregat brauchen, verwenden dieselbe View.
Sie schreiben `useQuery` für ein Aggregat nicht selbst. So gibt es pro Aggregat nur einen Key,
und das [Repository](repository.md) kann sich darauf verlassen, welche Keys es invalidieren muss.

## Ablage

Eine Datei pro Aggregat in `src/views/`, der Hook heißt `use<Aggregat>`:

```text
src/views/
├ todos.ts         useTodos(userId)
├ todo-lists.ts    useTodoLists()
├ users.ts         useUsers()
└ roles.ts         useRoles(), useUserRoles(userId)
```

`src/views/` ist der einzige Ort, an dem `useQuery` für Serverdaten steht. `src/api/` bleibt ohne React.

## Aufbau

```ts
// src/views/todos.ts
import {useQuery} from "@tanstack/react-query";
import {fetchTodos} from "@/api/todos";

// Alle Keys beginnen mit "todos": ein invalidate auf ["todos"] trifft alle User

/** Todos eines Users */
export const useTodos = (userId: string | undefined, enabled = true) =>
    useQuery({
        queryKey: ["todos", userId],
        queryFn: () => fetchTodos(userId!),
        enabled: enabled && !!userId,
    });
```

Regeln:

- **Query Key:** zuerst der Name des Aggregats, dann die Parameter in fester Reihenfolge, meist die
  User-ID: `["todos", userId]`, `["users", userId, "roles"]`. Der Name ist derselbe wie im Pfad
  der API. Die Tabelle aller Keys steht im Projekt-Skill.
- **Fehlende User-ID:** Der Parameter darf `undefined` sein, solange der aktuelle User noch nicht
  geladen ist. Dann gilt `enabled: !!userId`, und `userId!` in `queryFn` ist sicher.
- **Erst bei Bedarf laden:** Der Parameter `enabled` erlaubt es der Komponente, das Laden
  aufzuschieben, z. B. bis ein Dialog geöffnet wird: `useUserRoles(user.id, open)`.
- **Filtern auf dem Server:** Daten eines Users werden über seinen Pfad `/api/users/:userId/<aggregat>`
  beim Server angefragt und nicht im Client aus allen Daten herausgesucht.
- **Rückgabe unverändert:** Die View gibt das Ergebnis von `useQuery` zurück. Umrechnen und
  Zusammenfassen ist Aufgabe des Use Case mit einem [Service](service.md).

## In der Komponente

```tsx
const {currentUser} = useCurrentUser();
const todos = useTodos(currentUser?.id);

if (todos.isPending) return <Loading/>;
if (todos.isError) return <LoadError error={todos.error} onRetry={() => todos.refetch()}/>;
return <TodoTable todos={todos.data}/>;
```

- **Jeden Zustand anzeigen:** Laden („Lade…“), Fehler (Meldung mit `role="alert"` und „Erneut
  versuchen“) und Daten. Die Meldung kommt verständlich vom Server (`ApiError`). Laden und Fehler zeigen
  gemeinsame Komponenten aus `src/components/` (Skill `ui-styling`).
- **Mehrere Views:** Braucht eine Ansicht mehrere Aggregate, ruft sie mehrere Views auf. Sie zeigt
  „Lade…“, solange eine davon lädt, und den ersten Fehler.
- **Abgeleitete Werte mit `useMemo`** aus den Daten der Views berechnen, z. B. die Zahl der überfälligen Todos
  mit `countOverdue`. Sie bekommen keinen eigenen Query Key, denn so sind sie nach jedem Invalidieren
  automatisch aktuell.
- **Kein `fetch` in `useEffect`** und keine Kopie der Daten in `useState`. Eingaben in Formularen
  dürfen mit `useState` beginnen, die Liste selbst kommt immer aus der View.

## Cache

Die Einstellungen gelten für alle Views und stehen in `src/query-client.ts`. Unser Standard:

- Daten gelten **5 Minuten** als frisch (`staleTime`). Danach lädt eine View sie beim nächsten
  Anzeigen im Hintergrund neu, und bis dahin zeigt sie die alten Daten.
- Der Cache wird **einen Tag** im **localStorage** gehalten. Nach einem Neuladen der Seite erscheinen
  die Daten sofort und werden dann aktualisiert. Ändert sich das Datenformat eines Endpoints,
  muss `buster` erhöht werden.
- Bei **401** wird nicht erneut versucht und die Anmeldung erscheint. Bei **403** wird ebenfalls nicht
  erneut versucht. Andere Fehler werden bis zu dreimal wiederholt.
- Views setzen keine eigenen Werte für `staleTime` oder `retry`. Ausnahmen brauchen einen Kommentar
  mit dem Grund.
