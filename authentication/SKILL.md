---
name: authentication
description: Wie wird der Anwender angemeldet und wie werden Anwender und Passwörter verwaltet. Eigene Benutzerverwaltung mit Passwort, Sessions in der Datenbank, Passkeys und Tokens für Agents. Verwenden bei Arbeiten an Login, Logout, Passwörtern oder dem Anlegen von Anwendern.
---

# Anmeldung

Unser Standard ist eine eigene Benutzerverwaltung ohne externen Anmeldedienst (kein OAuth). Die Regeln unten
gelten unabhängig von Plattform und Datenbank. Endpoints, Dateien, Tabellen und Skripte des Projekts beschreibt
der Projekt-Skill.

## Anwender

- Der Administrator legt neue Anwender an und legt dabei das Passwort fest.
- Der erste Administrator wird per Skript angelegt, ebenso sein Passwort (Skill `authorization`, Bootstrap).
- Gespeichert wird nur ein Hash des Passworts, nie das Passwort selbst.

## Passwörter

- Hashing mit bcrypt (Kostenfaktor 12). Der Hash enthält den Salt, eine eigene Salt-Spalte ist nicht nötig.
- bcrypt berücksichtigt nur die ersten 72 Bytes. Längere Passwörter werden abgelehnt.
- Mindestens 8 Zeichen. Die Regeln stehen in `shared/` und gelten im Frontend und im Backend.
- Der Anwender kann sein Passwort selbst ändern. Dabei muss er das alte Passwort angeben.
- Der Administrator kann das Passwort eines Anwenders zurücksetzen und legt dabei ein neues fest.
  Das alte Passwort wird dafür nicht benötigt.
- Der Hash verlässt nie das Backend: Abfragen lesen nur freigegebene Spalten, die Zod-Schemas in `shared/`
  kennen keinen `passwordHash`.

## Login

- Der Anwender meldet sich mit E-Mail und Passwort an (die E-Mail ist eindeutig) oder mit einem Passkey.
- Bei unbekannter E-Mail oder falschem Passwort kommt dieselbe Fehlermeldung, und die Antwort dauert gleich
  lang, damit nicht erkennbar ist, welche E-Mails existieren.
- Ein User ohne Passwort-Hash kann sich nicht anmelden, bis der Administrator ein Passwort setzt.

Übliche Endpoints: `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/auth/me` (der angemeldete User,
sonst `401`), `POST /api/auth/password` (eigenes Passwort ändern) und `POST /api/auth/reset-password` (Admin).

## Sessions

Sessions stehen in der Datenbank, nicht im Arbeitsspeicher. So funktionieren sie auch auf zustandslosen Servern.

- Nach erfolgreichem Login erzeugt das Backend eine zufällige Session-ID (32 Bytes, kryptografisch sicher).
- Gespeichert werden der SHA-256-Hash der Session-ID, die User-ID und der Ablaufzeitpunkt. Die Session-ID selbst
  steht nur im Cookie.
- Cookie: `HttpOnly`, `SameSite=Strict`, `Path=/`, über HTTPS zusätzlich `Secure`. Lokal über http fehlt
  `Secure`, weil Safari solche Cookies auf `http://localhost` verwirft.
- Bei jedem API-Aufruf liest das Backend die Session über den Hash der Session-ID. Fehlt sie oder ist sie
  abgelaufen, antwortet es mit `401 Unauthorized`.
- Eine Session läuft nach 8 Stunden Inaktivität ab. Jeder gültige API-Aufruf verlängert sie wieder auf 8 Stunden.
- Abgelaufene Sessions werden beim nächsten Login gelöscht.
- Jeder Endpoint läuft hinter derselben gemeinsamen Prüfung der Session (z. B. `withSession(handler)`). Sie prüft
  danach auch die Rolle (Skill `authorization`) und antwortet ohne sie mit `403 Forbidden`.

## Logout

- Logout löscht die Session und setzt das Cookie mit `Max-Age=0` zurück.
- Ändert der Anwender sein Passwort, werden alle seine anderen Sessions gelöscht. Die aktuelle bleibt bestehen.
- Setzt der Administrator ein Passwort zurück, werden alle Sessions und alle Passkeys dieses Anwenders gelöscht.

## Passkeys

Statt mit E-Mail und Passwort kann sich der User mit einem Passkey (WebAuthn) anmelden. Das Passwort bleibt
bestehen.

- Bibliotheken `@simplewebauthn/server` und `@simplewebauthn/browser`. Kein externer Anmeldedienst.
- Gespeichert wird der öffentliche Schlüssel, nie der private. Challenges gelten 5 Minuten und nur einmal.
- Domain und Origin der Relying Party kommen aus Umgebungsvariablen, nicht aus der URL der Anfrage. In der
  Produktion beide setzen, sonst ist ein Passkey an die Domain gebunden, unter der er eingetragen wurde,
  z. B. eine Deploy-Vorschau.
- User Verification ist Pflicht, Passkeys sind auffindbar (Resident Key): beim Anmelden ist keine E-Mail nötig.
- Nach der Prüfung entsteht dieselbe Session wie beim Login mit Passwort.
- Passwortänderung lässt die Passkeys bestehen. Der Admin-Reset löscht sie mit den Sessions.

## Tokens für Agents

Ein Agent (z. B. Claude Code über einen MCP-Server) meldet sich nicht mit Passwort und Cookie an, sondern mit einem
persönlichen API-Token im Header `Authorization: Bearer <präfix>_…`.

- Aufgebaut wie die Sessions: gespeichert wird nur der SHA-256-Hash. Das Token (ein Präfix des Projekts und
  32 zufällige Bytes als base64url) steht nur einmal in der Antwort beim Erzeugen.
- Der User wählt beim Erzeugen die Gültigkeit (z. B. 30 Tage, 90 Tage, 1 Jahr oder kein Ablauf). Widerrufen
  löscht das Token.
- Geprüft wird mit einer eigenen Hülle analog zur Session (z. B. `withToken`): ohne gültiges Token `401` mit
  `WWW-Authenticate: Bearer`, danach dieselbe Rollenprüfung. Die Prüfung des Tokens liest kein Session-Cookie und
  die der Session kein Token. Ein Endpoint nimmt also genau eine der beiden Anmeldungen an.
- Passwortänderung und Reset lassen die Tokens bestehen. Wird der User gelöscht, verschwinden sie.

## Frontend

- Ein `UserProvider` fragt `GET /api/auth/me`. Ohne Session zeigt er die Login-Seite statt der Anwendung.
- `useCurrentUser()` liefert immer den angemeldeten User, eine Auswahl anderer User gibt es nicht.
- Antwortet ein API-Aufruf mit `401`, setzt `src/query-client.ts` den Anmeldestatus zurück, und die Login-Seite
  erscheint.
- Beim Logout werden alle Daten aus dem Query-Cache und aus dem localStorage entfernt.
