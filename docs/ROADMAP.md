# Roadmap

Immer nur an der aktuellen Etappe arbeiten. Eine Etappe ist erst erledigt, wenn sie in
Studio getestet wurde.

## Etappe 0: Setup prüfen
- [x] `.\check.ps1` ist grün
- [x] `rojo serve` läuft, Studio ist verbunden, eine Änderung in `src/` erscheint in Studio
- [x] Privates GitHub-Repo angelegt, erster Push
- [x] Code-Skill angelegt

## Version 1: Fühlt sich der Wurf gut an?

Ziel von Version 1 ist nur diese eine Frage. Alles ist grau und aus einfachen Parts.

### Etappe 1: Regeln und Config
- [x] Config mit Materialien, Wänden pro Zone, Härteformel, Belohnung und Startwerten (sechs Zonen mit je fünf Wänden)
- [x] Wände als reine Funktion aus der Config berechnet
- [x] Wurfberechnung als reine Funktion: Wurfkraft rein, Liste der durchbrochenen Wände und Belohnung raus
- [x] Zahlen abkürzen als reine Funktion (1.5K, 3.2M, ...)
- [x] Tests dafür, auch mit sehr großen Zahlen

### Etappe 2: Die Bahn
- [x] Wurfzone und eine Bahn mit sechs Zonen zu je fünf Wänden aus einfachen Parts
- [x] Wände existieren nur auf dem Client und brechen nur für den eigenen Spieler sichtbar

### Etappe 3: Der Wurf
- [x] Wurf auslösen per Button und Taste E, Server berechnet das Ergebnis
- [x] Schwert fliegt, Kamera folgt (Schwerter anderer Spieler sind nicht sichtbar)
- [x] Figur kann sich während des Flugs nicht bewegen
- [x] Kamera kommt in jedem Fall zurück: nach dem Wurf, beim Sterben, beim Neu-Spawnen, bei einem Abbruch
- [x] Wände brechen, Tempo hängt von der Kraft ab, Flug hat Mindest- und Höchstdauer
- [x] Bruchstücke pro Wand begrenzt (Wert in der Config)
- [x] Abprallen an der zu harten Wand; brechen alle Wände, steckt das Schwert am Bahnende im Boden
- [x] Server sperrt den nächsten Wurf, bis der vorige vorbei ist
- [x] Prüfung und Begrenzung der Nachrichten auf dem Server

### Etappe 4: Die Anzeige
- [x] Zeiger mit rotem und grünem Bereich, erster Druck startet, zweiter Druck stoppt
- [x] Figur steht still, solange die Anzeige läuft; Anzeige läuft ab, wenn nicht gedrückt wird
- [x] Faktor zwischen 0,5 und 1,5 fließt in die Wurfkraft ein, kurz als "x1.4" sichtbar
- [x] Server taktet die Anzeige selbst; zu alte Zeitpunkte werden auf die erlaubte Verzögerung begrenzt, Unmögliches abgelehnt
- [x] Per Touch bedienbar, im Hoch- und Querformat gut erreichbar

### Etappe 5: Training
- [x] Trainingsfeld neben der Wurfzone mit kurzer Bahn und einer Wand
- [x] Auf dem Feld wirft die Figur automatisch im Takt aus der Config; der Server prüft die Position und schreibt die Stärke im eigenen Takt gut
- [x] Verlässt der Spieler das Feld, hört das Training auf
- [x] Einrasten auf dem Feld; Loslassen durch gehaltene Richtung oder Sprung meldet "Training verlassen", der Server stoppt das Training bis zum vollständigen Verlassen
- [x] Einfache Armbewegung per Code (ohne hochgeladene Animation)
- [x] Trainingswand bricht und steht gleich wieder, sparsam für schwache Handys
- [x] Aus Etappe 7 vorgezogen: Stärke als schlichter Text, abgekürzt, mit "+1" bei jedem Trainingswurf

### Etappe 6: Belohnung und Speichern
- [x] Währung nach Wurfweite und Stärke aus dem Hauptwurf; der Server schreibt beim Berechnen gut, der Client zeigt die Belohnung Wand für Wand während des Flugs ("+..." fliegt über dem Schwert mit, Zonen-Bonus größer, Zahlen oben zählen mit und stimmen am Ende exakt mit dem Server überein)
- [x] Speichern und Laden mit ProfileStore (Session-Locking), Versionsnummer, fehlende Felder auffüllen, Zwischenspeichern aus der Config
- [x] Trennung der Testdaten: eigenes privates Test-Spiel, Speichername mit Umgebung, Testwerte werden nie gespeichert (Mock)
- [x] Aus Etappe 7 vorgezogen: Währung als schlichter Text neben der Stärke
- Entschieden: ProfileStore 1.0.3, unverändert in `src/server/Packages`, geprüft (siehe Notiz dort).

### Etappe 7: Einfache Anzeige der Werte
- [x] Stärke und Währung auf dem Bildschirm, abgekürzt, noch ohne Gestaltung
- Erledigt durch Vorziehen: Stärke in Etappe 5, Währung in Etappe 6. Keine eigene Arbeit mehr nötig.

**Stand 10.10.2026: Version 1 ist gebaut.** Alle Etappen 0 bis 7 sind erledigt und in Studio getestet.

**Als Nächstes: Spieltest.** Macht der Wurf Spaß? Erst danach geht es weiter.

## Bekannte Einschränkungen (später verbessern)
- Anzeige bei sehr schlechter Verbindung: Nach dem zweiten Druck kann der Zeiger bis zu 2 Sekunden stehen bleiben, bevor das Schwert fliegt, weil der Client auf die Antwort des Servers wartet. Idee für später: Schwert sofort lokal starten und mit der Antwort abgleichen.

## Version 2: Rebirth und weitere Trainingsbahnen

Ab hier wird in Blöcken gebaut (siehe CLAUDE.md): Ein Block ist eine Funktion, die der Spieler bemerkt,
komplett mit Logik, Anzeige, Speichern und Tests. Getestet wird am Ende des Blocks.

### Block A: Rebirth
- [x] Zahlen freigegeben: erste Schwelle, Steigerung, Multiplikator pro Rebirth
- [x] Rebirth-Regeln als reine Funktionen mit Tests: Schwelle, Multiplikator, was bleibt und was zurückgesetzt wird
- [x] Server: prüft den Wunsch (Begrenzung, Schwelle erreicht, kein Wurf läuft), führt den Rebirth aus
- [x] Multiplikator wirkt auf alle Stärke-Gewinne (Training und Hauptwurf)
- [x] Rebirths werden gespeichert; alte Spielstände laden weiter
- [x] Rebirth-Button mit Fenster: Fortschritt, was man verliert, was man bekommt, Bestätigen; per Touch bedienbar
- [x] Anzahl der Rebirths steht bei den Werten oben
- [x] Von mir getestet

### Block B: Trainingsbahnen (erst nach dem Test von Block A)
- [x] Vier Bahnen nebeneinander: Voraussetzung 0, 2, 4, 6 Rebirths; Multiplikator 1x, 4x, 10x, 20x; höhere Bahnen haben mehr Wände
- [x] Schild über jeder Bahn mit Multiplikator und Voraussetzung, bei gesperrten Bahnen "LOCKED"
- [x] Auf gesperrten Bahnen rastet man nicht ein und trainiert nicht (Entscheidung des Servers)
- [x] Freischaltung wird aus den Rebirths berechnet, nicht gespeichert
- [x] Mehrere Spieler auf derselben Bahn schieben sich nicht weg
- [x] Von mir getestet

### Block C: Andere Spieler sichtbar
- [x] Training: Andere Spieler in der Nähe sehen die Armbewegung und das kleine Schwert; die Trainingswand bricht nur beim Spieler selbst
- [x] Hauptwurf: Andere sehen das Ausholen und das Schwert losfliegen; es verblasst nach kurzer Strecke und berührt keine Wände
- [x] Der Server meldet diese Ereignisse selbst weiter (eigener Takt, eigene Wurfprüfung); Clients können nichts für andere auslösen
- [x] Nur innerhalb einer Entfernung aus der Config, mit Obergrenze für gleichzeitig dargestellte fremde Würfe
- [x] Vorbereitung: Jede Bahn hat in der Config eine Art der Freischaltung (jetzt nur "Rebirths", später "Kauf" ohne Umbau)
- [x] Vorbereitung: Weitere Bahnen nur durch Einträge in der Config, inklusive Platz auf der Map; der Balance-Test deckt das ab
- [x] Von mir getestet (zwei Spieler: einer trainiert und wirft, der andere schaut zu)

**Stand 11.10.2026: Version 2 ist gebaut.** Block A (Rebirth), Block B (Trainingsbahnen) und Block C (andere Spieler sichtbar) sind erledigt und getestet.

### Zwischenblock: Schwertmodell (Vorgriff auf Version 4)
- [x] Importiertes Modell `ember_greatsword` als Vorlage in `ReplicatedStorage.Assets`, Farben gesetzt, Glut als Neon; Rojo lässt die Vorlage in Ruhe
- [x] Hauptwurf, Trainingswurf (kleiner) und die Würfe anderer Spieler benutzen das Modell; ohne Vorlage gibt es das graue Schwert als Ersatz
- [x] Spitze zeigt in Flugrichtung; Abprallen und Steckenbleiben wie vorher
- [x] Teile sind verschweißt, bewegt wird nur ein verankertes Teil
- [ ] Von mir getestet
- Wichtig: Die Vorlage liegt nur im Ort, nicht im Repo. Der Ort muss in Studio auf Roblox gespeichert sein. Details in `assets/ember-greatsword-roblox.NOTES.md`.

### Block: Waffen-Shop
- [x] Fünf Waffen in der Config mit Preis und Trainingsbonus; Regeln als reine Funktionen mit Tests
- [x] Shop in der Welt: fünf Sockel mit Waffe und Schild (Name, Bonus, Preis, OWNED / EQUIPPED / LOCKED)
- [x] Am Sockel kaufen und ausrüsten, per Touch bedienbar; der Server prüft Preis, Besitz, Coins und Nähe
- [x] Die ausgerüstete Waffe fliegt bei Hauptwurf, Training und für Zuschauer; Waffen ohne Modell als grauer Platzhalter
- [x] Besitz und Ausrüstung werden gespeichert; alte Spielstände laden weiter
- [x] Balance-Test: kein Durchlauf unter 3 Minuten, jede Waffe in ihrem Fenster leistbar; Zieldauern weiter ohne Waffen
- [ ] Von mir getestet

### Block: Wurf fertig machen
- [x] Waffe in der rechten Hand, für alle sichtbar; beim Wurf verlässt sie die Hand und erscheint danach wieder
- [x] Wurfanimation für den ganzen Körper: eine für den Hauptwurf, eine kürzere für das Training; als echte Roblox-Animationen, im Editor nachbesserbar; Ersatz per Code, solange nichts hochgeladen ist (erste Fassung gebaut, Anleitung in `docs/ANIMATIONS.md`)
- [x] Kamera bleibt bei der Figur, bis die Waffe die Hand verlässt; Flugplan und Wurfsperre des Servers rechnen diese Zeit ein
- [x] Alle Zeiten in der Config
- [ ] Animationen von mir angesehen und hochgeladen, Nummern in der Config
- [ ] Von mir getestet

## Version 3: Pets, Glück und Glückswurf
## Version 4: Aussehen: Map, UI, Effekte, Sound
## Version 5: Offline-Fortschritt, Welten, Bestenlisten

## Vor dem Veröffentlichen: Block Käufe
Kommt vor dem öffentlichen Start, noch nicht geplant im Detail. Bis dahin wird keine Kauflogik gebaut.
- [ ] Robux-Bahn: Trainingsbahn mit Freischaltung "Kauf" (die Config-Struktur dafür steht seit Block C)
- [ ] Prüfung der Käufe ausschließlich auf dem Server; ein Kauf wird erst gutgeschrieben, wenn er sicher gespeichert ist
- [ ] Abgleich mit den Roblox-Regeln für Käufe, bevor etwas verkauft wird
- Mit weiteren Welten: Wände nur in der Nähe des Schwerts aufbauen. In Version 1 stehen alle 30 Wände immer.
