---
name: grill-me
description: Interviewt den User hartnäckig zu einem Plan, einer Entscheidung oder einer Idee, bis ein gemeinsames Verständnis erreicht ist. Verwenden, wenn der User seinen Plan prüfen lassen möchte oder „grill me“, „grill mich“, „löchere mich“ o. ä. sagt.
---

# Plan auf Herz und Nieren prüfen

Den User hartnäckig befragen, bis beide dasselbe Verständnis haben. Die Entscheidungen bilden einen
**Baum**: An jeder Entscheidung hängen die Entscheidungen, die von ihr abhängen.

## In Runden fragen

Die **Front** sind alle Entscheidungen, deren Voraussetzungen schon geklärt sind, also die Fragen, die
sich _jetzt_ stellen lassen, ohne Antworten zu erraten, die noch fehlen. Pro Runde die ganze Front
fragen, jede Frage nummeriert und mit einer Empfehlung. Dann auf die Antworten des Users warten.

Format einer Runde:

```
❓ **F1** - **<Titel der Frage>**: <Frage, auch mehrere Absätze, ggf. mit Auswahlmöglichkeiten>

➡️ <Empfehlung>

---

❓ **F2** - **<Titel der Frage>**: <Frage>

➡️ <Empfehlung>
```

Jede Frage so formulieren, dass „ja“ die Empfehlung annimmt.

Jede Antwort verändert den Baum: Geklärte Entscheidungen schieben die Front weiter und machen Fragen
frei, die von ihnen abhingen. Nach jeder Runde die Front neu bestimmen und die nächste Runde stellen.
Hängt eine Frage von einer anderen Frage ab, die in derselben Runde noch offen ist, gehört sie in eine
_spätere_ Runde.

## Fakten und Entscheidungen

- **Fakten sucht Claude selbst.** Braucht eine Frage einen Fakt aus der Umgebung (Code, Dateien,
  Konfiguration, Tools), selbst nachsehen und den User nicht danach fragen. Nur die Fragen, die von
  diesem Fakt abhängen, warten, bis er gefunden ist. Die übrigen Fragen der Front sofort stellen.
- **Entscheidungen trifft der User.** Jede Entscheidung vorlegen und auf die Antwort warten, nichts
  stillschweigend annehmen.

## Ende

Fertig ist die Befragung, wenn die Front leer ist: Jeder Zweig des Baums ist besucht, nichts ist
stillschweigend angenommen. Dann die getroffenen Entscheidungen kurz zusammenfassen. Erst handeln,
wenn der User bestätigt, dass das Verständnis gemeinsam ist.

Im Plan-Modus fließen die Entscheidungen in die Plan-Datei. Sie wird beim Verlassen des Plan-Modus zur
Freigabe vorgelegt.
