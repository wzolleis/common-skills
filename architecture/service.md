---
name: service
description: Reine Funktionen in shared/, die Werte berechnen und Regeln prüfen. Client und Backend verwenden dieselben. Lesen, wenn eine Berechnung oder Geschäftsregel entsteht oder sich ändert.
---

# Service

Ein Service berechnet aus Daten einen neuen Wert oder prüft eine Geschäftsregel. Beispiele:

- `openTodos` liefert die offenen Todos, nach Fälligkeit sortiert.
- `checkDueDate` prüft, ob ein Fälligkeitsdatum gültig ist.
- `countOverdue` zählt die Todos, deren Fälligkeit vor einem Tag liegt.

Ein [Use Case](use-case.md) ruft den Service im Client auf. Das Backend ruft dieselbe Funktion
noch einmal auf, denn nur die Prüfung auf dem Server ist verbindlich.

## Ablage

Services liegen in `shared/`, eine Datei pro Thema der Domain:

| Datei               | Inhalt                                                    |
|---------------------|-----------------------------------------------------------|
| `<thema>-rules.ts`  | Regeln und Berechnungen, z. B. `todo-rules.ts`            |
| `<thema>-report.ts` | Auswertungen für Berichte, z. B. `todo-report.ts`         |
| `<thema>.ts`        | **kein Service**: nur Zod-Schemas und Typen, z. B. `todo.ts` |

Feste Werte der Domain stehen als Konstante in derselben Datei wie die Funktionen,
z. B. `MAX_TITLE_LENGTH` oder `DONE_VISIBLE_DAYS`.

## Rein heißt

- **Keine Daten lesen oder schreiben.** Kein `fetch`, keine Datenbank, kein tanstack/query, kein React.
  Alles, was die Funktion braucht, kommt als Parameter, z. B. der heutige Tag für `countOverdue`.
- **Keine aktuelle Zeit.** Kein `new Date()` und kein `Date.now()`. Braucht die Funktion die Zeit,
  bekommt sie `now: Date` oder `today: Day` als Parameter.
- **Tage als Text.** Ein Tag ist ein String `JJJJ-MM-TT` in der Zeitzone des Projekts (Skill `shared-modules`).
  Solche Strings lassen sich direkt vergleichen.
- **Keine Seiteneffekte.** Die Funktion ändert ihre Parameter nicht und gibt ein neues Ergebnis zurück.

## Namen und Rückgabewerte

| Präfix              | Rückgabe           | Bedeutung                                                     | Beispiel                          |
|---------------------|--------------------|---------------------------------------------------------------|-----------------------------------|
| `check…`            | `string \| null`   | `null` = gültig, sonst eine deutsche Meldung für den Anwender | `checkDueDate`, `checkTitle`      |
| `find…`             | Objekt oder `null` | das gesuchte Element, z. B. den Konflikt                      | `findDuplicate`                   |
| `is…`               | `boolean`          | einfache Ja/Nein-Frage                                        | `isValidDay`, `isOverdue`         |
| `count…`, `…Totals` | Zahl oder Objekt   | berechneter Wert                                              | `countOverdue`, `todoTotals`      |
| `…Message`          | `string`           | Meldung zu einem gefundenen Konflikt                          | `duplicateMessage`                |

Die Meldungen aus `check…` und `…Message` sieht der Anwender direkt. Sie sind daher auf Deutsch und
verständlich formuliert.

```ts
/** null = gültig, sonst eine verständliche Fehlermeldung */
export function checkDueDate(dueDate: string, today: Day): string | null {
    if (!isValidDay(dueDate)) return "Ungültiges Datum";
    if (dueDate < today) return "Das Fälligkeitsdatum liegt in der Vergangenheit"; // ISO-Daten lassen sich als Text vergleichen
    return null;
}
```

## Verletzte Regel auf dem Server

Das Backend wirft bei einer Meldung einen `RuleError`. Innerhalb einer Transaktion wird dadurch alles
zurückgerollt. Im `catch` wird der Fehler zu 422 mit `{error: <Meldung>}`:

```ts
const problem = checkDueDate(next.dueDate, today);
if (problem) throw new RuleError(problem);
// …
if (err instanceof RuleError) return ruleViolation(err);
```

Der Client zeigt dann dieselbe Meldung, die er auch selbst berechnet hätte. Wo `RuleError` im Projekt liegt,
steht im Projekt-Skill.

## Tests

Jede Datei hat einen Test daneben (`todo-rules.test.ts`). Weil Services rein sind, braucht der
Test keine Mocks und keine Fake-Timer: Eingabe übergeben, Ergebnis prüfen. Jede `check…`-Funktion
wird mit mindestens einem gültigen und einem ungültigen Fall getestet.

```ts
describe("checkDueDate", () => {
    it("akzeptiert heute und einen Tag in der Zukunft", () => {
        expect(checkDueDate("2026-06-08", "2026-06-08" as Day)).toBeNull();
        expect(checkDueDate("2026-06-12", "2026-06-08" as Day)).toBeNull();
    });
    it("lehnt einen Tag in der Vergangenheit ab", () => {
        expect(checkDueDate("2026-06-07", "2026-06-08" as Day)).toBe("Das Fälligkeitsdatum liegt in der Vergangenheit");
    });
});
```
