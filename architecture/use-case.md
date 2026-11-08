---
name: use-case
description: Beschreibt eine Aufgabe, die der Anwender mit der Software erledigen möchte, und wie sie im Code als Hook umgesetzt wird.
---

# Use Case

Ein Use Case ist eine Aufgabe, die ein Anwender mit der Software erledigt, formuliert in der Sprache der Domain:

- „Der User sieht seine offenen Todos.“
- „Der User legt ein Todo an.“
- „Der Administrator setzt das Passwort eines Users zurück.“

Der Name beginnt mit einem Verb und nennt das Domain-Objekt: `useShowOpenTodos`, `useAddTodo`,
`useResetPassword`. Technische Wörter wie „fetch“, „post“ oder „mutation“ gehören nicht in den Namen.

## Typ, Epic und Status

Jeder Use Case ist in einer Markdown-Datei beschrieben, z. B. `features/use-case/todo-add.md`.
Im Frontmatter dieser Datei stehen optional sein Typ und seine Epics, dazu immer sein Status:

```yaml
---
name: todo-add-due-date
type: change
changes: todo-add
epics: todos, erinnerungen
state: open
---
```

**Typ.** Es gibt drei Typen:

- **story**: eine neue Aufgabe des Anwenders. Ohne Angabe ist ein Use Case eine Story.
- **change**: eine Änderung an einem bestehenden Use Case oder an seinem Code. Auch ein Change ist ein
  Use Case. Er wird als eigene Datei in `features/changes/` beschrieben, damit die Beschreibung des
  ursprünglichen Use Case nicht zu groß und unlesbar wird. Im Feld `changes` steht der `name` des
  Use Case, den er ändert.
- **setup**: keine Aufgabe des Anwenders, sondern eine Voraussetzung für die Entwicklung oder den
  Betrieb, z. B. die lokale Umgebung. Setups liegen in `features/boundaries/`.

**Epic.** Ein Epic ist ein größeres fachliches Ziel, zu dem mehrere Use Cases beitragen, z. B. tragen
„Todo anlegen“ und „Todo erledigen“ zum Epic „todos“ bei. Ein Use Case kann zu mehreren Epics
beitragen. Ein Epic wird im Code nicht umgesetzt und ist kein Ordner. Es dient nur dazu, Use Cases zu
finden, etwa „alle Use Cases, die etwas mit Erinnerungen machen“. Ein Epic kann mehrere Features betreffen.

**Status.** Das Feld `state` steht direkt unter `epics` und gilt für jede Beschreibung, ob Story,
Change oder Setup:

- **open**: noch nicht umgesetzt.
- **later**: zurückgestellt, wird vorerst nicht umgesetzt. Soll daran gearbeitet werden, wird `state` wieder auf
  `open` gesetzt.
- **resolved**: umgesetzt. Wer eine Story oder einen Change umsetzt, setzt `state` im selben Commit auf
  `resolved`.

**Erledigte Beschreibungen.** Ein erledigter Change beschreibt den Stand zur Zeit der Umsetzung und bleibt
eingefroren: Sein Text und seine Verweise auf Code werden nicht angepasst, auch nicht, wenn sie veraltet sind. Nur
das Frontmatter, z. B. `state`, darf sich ändern. Was heute gilt, steht im Use Case, den er ändert (Feld
`changes`), und im Code. Verweise auf Code aus einem erledigten Change werden deshalb nicht ungeprüft übernommen,
denn Dateien und Funktionen können inzwischen umbenannt oder verschoben sein.

Ein Use Case dagegen ist die Stelle, an der der aktuelle Stand steht. Er wird auch im Status `resolved`
angepasst, samt seiner Verweise auf Code: Beim Umsetzen eines Changes wird im selben Commit der geänderte Use Case
aktualisiert, sodass Regeln, Beispiele und Abschnitte zur Umsetzung danach den neuen Stand beschreiben.

Dabei wird der Change nicht in den Use Case kopiert. Übernommen werden nur Begründungen, die weiter gelten, als
kurzer Satz bei der Regel, die sie begründen. Beispiel: „Erledigte Todos bleiben sichtbar: Sie verschwinden erst
nach 30 Tagen aus der Liste.“ Der Plan (Dateien, Schritte, „Fertig, wenn“) bleibt im Change. Ändert ein Change
mehrere Use Cases, bekommt jeder die Begründungen, die ihn betreffen. Der erledigte Change bleibt in
`features/changes/` stehen.

Eine Übersicht aller Beschreibungen nach Epic und Status erzeugt der Skill `overview` in `generated/overview.md`.
Sie wird nicht von Hand bearbeitet und nicht committet. Ändert sich `name`, `type`, `epics` oder `state` einer
Beschreibung, wird sie neu erzeugt. Ob es ein Skript gibt, das neue Beschreibungen anlegt, steht im Projekt-Skill.

## Bausteine

Ein Use Case setzt die übrigen Bausteine zusammen. Er verwendet nur die, die er braucht:

| Baustein                    | Aufgabe                                      | Wann im Use Case                         |
|-----------------------------|----------------------------------------------|------------------------------------------|
| [View](views.md)            | Daten lesen (`src/views/`)                   | wenn Daten angezeigt oder geprüft werden |
| [Repository](repository.md) | Daten schreiben (`src/api/` + `useMutation`) | wenn Daten geändert werden               |
| [Service](service.md)       | neue Werte berechnen, Regeln prüfen          | wenn etwas berechnet oder geprüft wird   |

Ein lesender Use Case hat also kein Repository. Ein schreibender Use Case hat eine View nur dann,
wenn er vorhandene Daten für eine Prüfung braucht, etwa um ein doppeltes Todo mit gleichem Titel zu erkennen.

## Ablage im Code

Jeder Use Case ist ein eigener Hook in einer eigenen Datei im Ordner `use-cases` des Features:

```text
src/features/todos/
├ use-cases/
│ ├ use-add-todo.ts
│ └ use-delete-todo.ts
└ components/
  └ todo-actions.tsx      ruft nur useDeleteTodo() auf
```

Die Komponente kümmert sich nur um die Anzeige. Sie ruft kein `useQuery` und kein `useMutation`
direkt auf, sondern den Hook des Use Case. Dadurch kann man den Use Case ohne Oberfläche testen.
Zeigt eine Komponente Daten nur unverändert an, ohne Berechnung und ohne Schreiben, darf sie die
[View](views.md) direkt aufrufen. Ein eigener Use Case wäre dann nur eine Weiterleitung.

## Fragen zum Use Case

Die Tabelle in [SKILL.md](SKILL.md) listet die Fragen, die für jeden Use Case beantwortet werden.
So landen die Antworten im Code:

- **Wer darf das?** Das prüft der Server über die Rollen (Skill `authorization`). Der Use Case
  prüft keine Rechte. Er zeigt aber die Fehlermeldung bei 403 an.
- **Welche Regeln gelten?** Die Regeln sind Services in `shared/`, z. B. `checkDueDate` oder
  `findDuplicate` in `shared/todo-rules.ts`. Der Use Case prüft sie vor dem Absenden, damit der
  Anwender sofort eine Rückmeldung bekommt. Das Backend prüft dieselben Regeln noch einmal,
  denn nur die Prüfung auf dem Server ist verbindlich.
- **Was kann schiefgehen?** Der Server antwortet mit einem HTTP-Status und einer Meldung, z. B.
  422 bei einer verletzten Regel oder 409 bei einem Konflikt. Der Use Case gibt den Fehler an die
  Komponente weiter, die ihn anzeigt.
- **Was ist danach wahr?** Das Repository invalidiert die betroffenen Query Keys. Jede View, die
  diese Daten zeigt, lädt sie dann neu.

## Beispiel: lesend

„Der User sieht seine offenen Todos.“ Das braucht eine View und einen Service, aber kein Repository.

```ts
// src/features/todos/use-cases/use-show-open-todos.ts
export function useShowOpenTodos(userId: string, today: Day) {
    const todos = useTodos(userId); // View

    const open = useMemo(
        () => todos.data && openTodos(todos.data, today), // Service: offen, nach Fälligkeit sortiert
        [todos.data, today],
    );

    return {
        open,
        isPending: todos.isPending,
        error: todos.error,
    };
}
```

## Beispiel: schreibend

„Der User legt ein Todo an.“ Das braucht einen Service für die Regel und ein Repository.

```ts
// src/features/todos/use-cases/use-add-todo.ts
export function useAddTodo(userId: string) {
    const qc = useQueryClient();

    const save = useMutation({
        mutationFn: (data: TodoCreate) => createTodo(userId, data),
        onSuccess: () => qc.invalidateQueries({queryKey: ["todos"]}),
    });

    return {
        problem: (dueDate: string, today: Day) => checkDueDate(dueDate, today), // Service, null = alles in Ordnung
        add: save.mutate,
        isSaving: save.isPending,
        error: save.error,
    };
}
```

## Abgrenzung

- Ein **Service** berechnet nur Werte. Er liest und schreibt keine Daten und kennt weder React noch
  tanstack/query. Den Ablauf steuert der Use Case.
- Ein Use Case ruft keinen anderen Use Case auf. Brauchen zwei Use Cases dieselbe Berechnung,
  gehört sie in einen Service. Brauchen sie dieselben Daten, verwenden beide dieselbe View mit
  demselben Query Key.
