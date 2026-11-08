---
name: performance
description: Was wir unter Performance verstehen (die vom User wahrgenommene Antwortzeit), wie wir sie messen und welche Mittel wir einsetzen. Verwenden bei lesenden und schreibenden Zugriffen auf das Backend (Views, Use Cases, Endpoints, SQL), beim Aufnehmen einer neuen Dependency oder einer neuen Version einer Dependency, bei Änderungen an der Konfiguration von Vite oder TypeScript und wenn der User meldet, dass etwas langsam ist.
---

# Ziel

Im Vordergrund steht die vom User wahrgenommene Antwortzeit: wie schnell eine Seite erscheint und wie schnell
eine Änderung sichtbar wird. Optimiert wird nur nach einer Messung, nicht auf Verdacht.

Cache, `staleTime` und Invalidierung sind im Skill `architecture` beschrieben (`views.md`, `repository.md`).
Dieser Skill wiederholt sie nicht, sondern sagt, was davon für die Performance wichtig ist.

# Messen

- **Backend:** Jeder Endpoint misst seine Zeit und schreibt sie in den Header `Server-Timing`: die Gesamtzeit,
  einen Kaltstart (`cold`) und jeden SQL-Schritt. Im Browser unter DevTools → Network → Timing zu sehen. Wie das
  im Projekt umgesetzt ist, beschreibt der Projekt-Skill.
- **Frontend:** `npm run build` zeigt die Größe jedes Chunks, roh und mit gzip. Bei Änderungen an Dependencies
  oder an der Konfiguration die Ausgabe vorher und nachher vergleichen.

# Lesen

- **Cache statt Prefetching.** Daten gelten eine Weile als frisch und liegen im localStorage. Eine besuchte Seite
  erscheint beim nächsten Mal sofort. Kein eigenes Prefetching von Daten einbauen.
- **Im Client rechnen, wenn die Daten klein sind.** Lädt eine View alle Todos eines Users auf einmal, rechnen
  Auswertungen (offen, überfällig, erledigt pro Woche) daraus mit `useMemo`. Ein Wechsel des Filters oder Zeitraums
  braucht dann keinen neuen Request.
- **Grenze:** Wachsen die Daten so, dass „alles laden“ selbst langsam wird, müssen sie nach Zeitraum oder Seite
  geladen werden. Umgestellt wird nur nach Absprache mit dem User.
- **Routen vorladen:** Mit `defaultPreload: "intent"` in `createRouter` lädt tanstack-router den Chunk einer Seite
  schon beim Hover über einen Link. Ob das eingeschaltet ist, steht im Projekt-Skill.

# Schreiben

Für alle Aggregate gilt `repository.md` im Skill `architecture`: Nach dem Schreiben werden die betroffenen Daten
mit `invalidateQueries` ungültig gemacht und neu geladen. Die Änderung erscheint, sobald der Server geantwortet
hat.

## Optimistic Write

Die UI zeigt die Änderung sofort und wartet nicht auf den Server. **Nur nach Absprache mit dem User einsetzen.**
Für welche Aggregate es im Projekt umgesetzt ist, steht im Projekt-Skill.

- Die UI prüft vor dem Absenden dieselben Regeln aus `shared/` wie der Server (z. B. `checkDueDate`). Der Server
  prüft sie noch einmal, weil das Backend auch über andere Zugänge erreichbar sein kann (REST, MCP). Eine Ablehnung
  (422) ist deshalb selten. Sie kommt vor, wenn der Cache veraltet ist (ein anderes Gerät oder ein Agent hat
  inzwischen geändert) oder bei Prüfungen, die nur der Server kennt (Unique-Index, Fremdschlüssel, Rechte).
- Muster mit tanstack-query: `onMutate` hält laufende Abfragen an (`cancelQueries`), merkt sich den alten
  Stand und setzt den neuen (`setQueryData`). `onError` stellt den alten Stand wieder her und zeigt den Fehler.
  `onSettled` lädt die Daten neu (`invalidateQueries`).
- Fehler erscheinen als Toast über eine gemeinsame Funktion in `src/lib/` (z. B. `notifyError`), weil der Dialog
  dann schon geschlossen ist. Die Toast-Bibliothek nicht direkt importieren.
- Ein neues Todo hat bis zur Antwort eine vorläufige Id, Ändern und Löschen sind dafür gesperrt.

# Backend

- Abfragen pro Request zählen: Weniger Abfragen sind meist schneller als parallele, vor allem, wenn der Pool nur
  wenige Verbindungen hat.
- Keine Abfrage pro Element in einer Schleife (N+1), sondern eine Abfrage mit `IN (…)` (z. B. `inArray`).
- Transaktionen kurz halten, besonders wenn sie Zeilen sperren.
- Auf Serverless-Plattformen gibt es Kaltstarts. Sie stehen im `Server-Timing` als `cold`.

# Dependencies

Beim Aufnehmen einer neuen Dependency oder einer neuen Version einer Dependency:

- `npm run build` vorher und nachher vergleichen: Wird der Haupt-Chunk oder das CSS deutlich größer?
- Keine zweite Bibliothek für dasselbe Thema, z. B. kein Luxon neben Temporal.
- Vorhandene Pakete bevorzugen. Welche das im Projekt sind, nennt der Projekt-Skill.

# Ladezeit beim Start

Den Ablauf beim Öffnen der App mit Messwerten (Größe des Haupt-Chunks und des CSS, mit Datum) hält der
Projekt-Skill fest, damit eine spätere Messung einen Vergleich hat.
