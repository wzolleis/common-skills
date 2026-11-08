---
name: authorization
description: Wie wird der Anwender autorisiert, welche Rollen gibt es und wie werden sie Benutzern und API-Endpoints zugeordnet. Verwenden bei Arbeiten an Rollen, Rollenzuordnung, Absicherung von Endpoints oder der Admin-Oberfläche.
---

# Grundlage

Die Anmeldung ist im Skill `authentication` beschrieben. Die Rollenprüfung setzt voraus, dass das Backend bei
jedem API-Aufruf den angemeldeten Benutzer kennt.

Die Regeln unten sind unser Standard. Tabellen, Migrationen, Dateien und Besonderheiten der Plattform beschreibt
der Projekt-Skill.

# Datenmodell

| Tabelle          | Inhalt                                                        |
|------------------|---------------------------------------------------------------|
| `roles`          | Rollen der Anwendung                                          |
| `user_roles`     | Zuordnung Benutzer -> Rolle (n:m)                             |
| `endpoint_roles` | Zuordnung Endpoint + HTTP-Methode -> Rolle (genau eine Rolle) |

`roles` hat eine `id` (UUID, Primärschlüssel) und einen eindeutigen `name`. Die Zuordnungen verweisen auf die
`id`, nie auf den Namen. Die festen Rollen haben feste IDs, die im Code als Konstanten in `shared/role.ts` stehen
(`ADMIN_ROLE_ID`, `USER_ROLE_ID`). Der Code verweist nur über diese IDs auf Rollen.
Die API liefert Rollen als `{id, name}`, `PUT /api/users/:id/roles` erwartet `{roleIds: [...]}`.

# Rollen

Ein Benutzer kann eine oder mehrere Rollen besitzen. Die Zuordnung pflegt ein Administrator in der Oberfläche.

## Rolle "User"

Die Rolle "User" steht wie jede andere Rolle in `roles`. Jeder neu angelegte Benutzer bekommt sie als normale
Zuordnung in `user_roles`, in derselben Transaktion wie das Anlegen. Im Code wird die Rolle "User" nicht als
Sonderfall behandelt: Es zählt nur, was in der Datenbank zugeordnet ist.

## Rolle "Administrator"

Ein Administrator darf jeden Endpoint mit jeder Methode aufrufen, unabhängig davon, welche Rolle dort zugeordnet
ist.

## Bootstrap

- Die Rollen "Administrator" und "User" sind fest vorgegeben und können weder umbenannt noch gelöscht werden.
- Der erste Administrator wird per Skript eingetragen (z. B. `node scripts/grant-admin.ts <email>`).
- Danach können alle Zuordnungen Benutzer -> Rolle in der Oberfläche geändert werden.
- Es muss immer mindestens ein Benutzer mit der Rolle "Administrator" existieren. Eine Änderung, die den letzten
  Administrator entfernen würde (Rolle entziehen oder Benutzer löschen), wird mit `409` abgelehnt. Dazu werden die
  Administrator-Zeilen bis zum Ende der Transaktion gesperrt, damit zwei gleichzeitige Änderungen nicht beide
  durchgehen.

# Zuordnung Rollen -> Endpoints

Gesichert werden ausschließlich die Backend-Endpoints (`/api/...`), nicht die Seiten im Frontend.
Die Zuordnung steht in `endpoint_roles` und wird **nur über Migrationen** gepflegt. Es gibt dafür keine
Oberfläche. Neue Einträge verweisen lesbar über den Namen auf die id:

```sql
INSERT INTO endpoint_roles (path, method, role_id)
SELECT '/api/todo-lists', 'POST', id
FROM roles
WHERE name = 'Administrator';
```

Wer einen neuen Endpoint baut, der nicht für alle User gedacht ist, legt die Einträge in derselben Änderung an.

- Ein Eintrag besteht aus Pfad, HTTP-Methode und genau einer Rolle.
- Methoden: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`.
- Der Pfad ist das Muster des Endpoints, nicht die konkrete URL, z. B. `/api/users/:userId/todos/:id` und nicht
  `/api/users/7/todos/42`.
- Pro Kombination aus Pfad und Methode gibt es höchstens einen Eintrag.
- Gibt es für Pfad und Methode keinen Eintrag, gilt die Rolle "User".
- Zugriff hat, wer die zugeordnete Rolle besitzt, sowie jeder Administrator.

Beispiel: Gemeinsame Todo-Listen pflegt nur der Administrator, lesen dürfen alle.

| Pfad                  | Methode  | Rolle                     |
|-----------------------|----------|---------------------------|
| `/api/todo-lists`     | `POST`   | Administrator             |
| `/api/todo-lists/:id` | `PATCH`  | Administrator             |
| `/api/todo-lists/:id` | `DELETE` | Administrator             |
| `/api/todo-lists`     | `GET`    | (kein Eintrag, also User) |

Endpoints für Administratoren, die Daten aller User zeigen (z. B. `GET /api/admin/api-tokens`), bekommen einen
Eintrag mit der Rolle Administrator. Der Admin-Reset `POST /api/auth/reset-password` braucht unbedingt einen,
sonst kann jeder angemeldete User fremde Passwörter setzen. Umfasst ein Pfadmuster auch Aktionen ohne
Rollenprüfung (z. B. `/api/auth/:action` mit Login und Logout), prüft der Endpoint die Rolle für den Reset selbst,
mit dem konkreten Pfad.

# Durchsetzung

Die Berechtigung wird **nur im Backend** geprüft, bei jedem API-Aufruf, in derselben gemeinsamen Hülle wie die
Session: erst die Session, dann die Rolle. Der konkrete Pfad der Anfrage wird mit den Mustern aus `endpoint_roles`
verglichen (`/api/users/42` passt zu `/api/users/:id`, `:name` steht für genau ein Segment). Passen mehrere, gilt
der genaueste mit den wenigsten Parametern. Ein neuer Endpoint braucht dafür nichts weiter als die Hülle.

| Situation                          | Antwort des Backends |
|------------------------------------|----------------------|
| nicht angemeldet                   | `401 Unauthorized`   |
| angemeldet, aber Rolle fehlt       | `403 Forbidden`      |
| Rolle vorhanden oder Administrator | normale Verarbeitung |

Das Frontend blendet nichts anhand von Rollen aus. Antwortet das Backend mit `403`, zeigt die UI die Meldung des
Backends an ("Dir fehlen die notwendigen Rechte für diese Aktion"), dort, wo die Seite oder der Dialog ohnehin
Fehler anzeigt. Bei `401` und `403` wiederholt tanstack-query eine Abfrage nicht (`retry` in
`src/query-client.ts`).

# Daten eines Users

Die Rolle entscheidet, ob ein Endpoint aufgerufen werden darf, aber nicht, wessen Daten. Daten, die einem User
gehören (z. B. seine Todos), darf jeder User nur für sich selbst lesen und ändern, ein Administrator für alle. Wem
die Daten gehören, steht im Pfad: `/api/users/:userId/todos`, mit `/:id` für einen Datensatz. Der Body enthält
keine `userId`, der Endpoint setzt sie aus dem Pfad.

- Jeder dieser Endpoints prüft zuerst mit einer gemeinsamen Funktion (z. B. `ensureAccess(session.user.id,
  userId)`), ob der angemeldete User auf die Daten von `userId` zugreifen darf. Sonst antwortet er mit `403`.
- Gehört ein Datensatz unter `/api/users/U/…/:id` nicht U, ist er „nicht gefunden“, nicht 403. So verrät die API
  nicht, dass es ihn gibt.

## Zugang für Agents

Ein MCP-Server für Agents nimmt nur ein Agent-Token an (Skill `authentication`). Jedes Tool arbeitet nur mit den
Daten des Users, dem das Token gehört, **auch bei einem Administrator**. Kein Tool hat eine `userId` als Eingabe.
Einen fremden Datensatz behandeln die Tools wie einen unbekannten („nicht gefunden“), nicht mit `403`.
Schreibende Tools verwenden denselben Store wie der REST-Endpoint, damit dieselben Regeln gelten.
