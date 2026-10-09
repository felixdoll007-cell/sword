---
name: roblox-code
description: Code- und Sicherheitsregeln für dieses Roblox-Projekt. Vor jedem Schreiben oder Ändern von Luau-Code unter src/ oder tests/ laden.
---

# Code-Regeln

## Ort und Werkzeuge
- Code nur in Dateien unter `src/`, Sync per Rojo. Nie Skripte direkt in Studio anlegen oder ändern.
- `src/shared` → ReplicatedStorage.Shared (Server und Client sehen es)
- `src/server` → ServerScriptService.Server (nur Server)
- `src/client` → StarterPlayerScripts.Client (nur Client)
- Nach jedem Schritt `.\check.ps1` (Build, Tests, Selene, StyLua). Erst wenn grün: Commit.

## Spielregeln als reine Funktionen
- Wurfberechnung, Belohnungen, Rebirth-Kosten, Wandberechnung, Zahlen-Abkürzung:
  reine Funktionen in `src/shared`, ohne `game`, Instances oder Services.
- Eingaben rein, Ergebnis raus, keine versteckten Zustände, kein Zufall innerhalb der Funktion
  (Zufallswert als Parameter übergeben).
- Jede reine Funktion hat Tests in `tests/<Name>.spec.luau`, inklusive Randfälle:
  0, negative Werte, sehr große Zahlen (1e15, 1e30, 1e300), genau auf der Grenze.

## Config
- Alle einstellbaren Zahlen in `src/shared/Config/`. Keine Zahlen fest im restlichen Code
  (Ausnahme: 0, 1 und offensichtliche Dinge wie Schleifenzähler).
- Config enthält nichts Geheimes, der Client kann sie lesen.

## Netzwerk
- Alle RemoteEvents und RemoteFunctions werden in genau einer Datei definiert:
  `src/shared/Remotes.luau`. Sonst nirgends `Instance.new("RemoteEvent")`.
- Client meldet nur Absichten ("ThrowRequested", "PurchaseRequested").
  Nie Stärke, Ergebnisse, Belohnungen oder Preise vom Client übernehmen.
- Keine RemoteFunction vom Server zum Client aufrufen (Client kann den Server hängen lassen).

## Server-Prüfung jeder Client-Nachricht
Reihenfolge in jedem Handler:
1. Rate-Limit pro Spieler (Werte aus der Config). Zu viele → still verwerfen.
2. Datentyp prüfen (`typeof`), auch auf NaN und inf bei Zahlen.
3. Wertebereich prüfen.
4. Ist die Aktion gerade erlaubt (richtiger Ort, kein laufender Wurf, genug Währung)?
5. Erst dann rechnen, und zwar nur mit Werten, die der Server selbst kennt.

## Zustand pro Spieler auf dem Server
- Alles, was der Server pro Spieler im Speicher hält (Rate-Limits, Wurfsperre, laufender Wurf,
  geladene Daten nach dem Speichern), wird bei PlayerRemoving gelöscht. Sonst wächst der
  Speicher mit jedem Spieler, der den Server verlässt.

## Spielerdaten
- Nur der Server liest und schreibt.
- Laden mit pcall und Wiederholung. Schlägt Laden endgültig fehl: Spieler nicht mit
  leeren Daten spielen lassen, die gespeicherten Daten sonst nie überschreiben.
- Jeder gespeicherte Datensatz hat ein Feld `version`. Beim Laden werden fehlende Felder
  mit Standardwerten aus der Config ergänzt, damit alte Spielstände nach Erweiterungen
  weiter laden. Ändert sich die Bedeutung eines Felds: Version erhöhen und Umwandlung schreiben.
- Speichern mit `UpdateAsync`, pcall und Wiederholung mit Wartezeit.
- Automatisches Zwischenspeichern in festem Abstand (Wert aus der Config).
- Speichern bei PlayerRemoving und in `game:BindToClose`, dort auf alle Speichervorgänge warten.
- Zeitstempel nur vom Server (`os.time()`).

## Verboten
- `loadstring`, `require` auf Asset-IDs, `getfenv`/`setfenv`.
- Geheimes in ReplicatedStorage oder Client-Code.
- API-Keys im Code oder Repo. Nur Umgebungsvariablen.
- Toolbox-Assets mit Skripten: erst alle Skripte entfernen und dem Nutzer auflisten, was entfernt wurde.

## Performance
- Wände und Effekte nur auf dem Client. Logik auf dem Server.
- Bei Meshes vor dem Import die Anzahl der Dreiecke nennen.

## Stil
- Texte im Spiel auf Englisch.
- Namen auf Englisch, sprechend. Module geben eine Tabelle zurück.
- `--!strict` am Anfang jeder neuen Datei.

## Bekannte Fallen
Jeder Fehler, der uns Zeit gekostet hat, kommt hier hinein: was passiert ist, Ursache, Regel.

(noch keine)
