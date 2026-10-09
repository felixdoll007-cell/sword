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
- [ ] Zeiger mit rotem und grünem Bereich, erster Druck startet, zweiter Druck stoppt
- [ ] Figur steht still, solange die Anzeige läuft; Anzeige läuft ab, wenn nicht gedrückt wird
- [ ] Faktor zwischen 0,5 und 1,5 fließt in die Wurfkraft ein, kurz als "x1.4" sichtbar
- [ ] Server taktet die Anzeige selbst; zu alte Zeitpunkte werden auf die erlaubte Verzögerung begrenzt, Unmögliches abgelehnt
- [ ] Per Touch bedienbar, im Hoch- und Querformat gut erreichbar

### Etappe 5: Training
- [ ] Eine Trainingsbahn mit automatischem Wurf, gibt Stärke

### Etappe 6: Belohnung und Speichern
- [ ] Währung nach Wurfweite
- [ ] Speichern und Laden aller Werte, mit Fehlerbehandlung
- Vorher prüfen: bewährte Bibliothek mit Session-Locking statt eigener Lösung? Vor- und Nachteile nennen, dann entscheiden.

### Etappe 7: Einfache Anzeige der Werte
- [ ] Stärke und Währung auf dem Bildschirm, abgekürzt, noch ohne Gestaltung

**Dann testen:** Macht der Wurf Spaß? Erst danach geht es weiter.

## Version 2: Rebirth und weitere Trainingsbahnen
## Version 3: Pets, Glück und Glückswurf
## Version 4: Aussehen: Map, UI, Effekte, Sound
## Version 5: Offline-Fortschritt, Welten, Bestenlisten
- Mit weiteren Welten: Wände nur in der Nähe des Schwerts aufbauen. In Version 1 stehen alle 30 Wände immer.
