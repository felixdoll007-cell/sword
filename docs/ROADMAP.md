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
- [ ] Config mit Materialien, Wänden pro Zone, Härteformel, Belohnung und Startwerten (sechs Zonen mit je fünf Wänden)
- [ ] Wände als reine Funktion aus der Config berechnet
- [ ] Wurfberechnung als reine Funktion: Wurfkraft rein, Liste der durchbrochenen Wände und Belohnung raus
- [ ] Zahlen abkürzen als reine Funktion (1.5K, 3.2M, ...)
- [ ] Tests dafür, auch mit sehr großen Zahlen

### Etappe 2: Die Bahn
- [ ] Wurfzone und eine Bahn mit sechs Zonen zu je fünf Wänden aus einfachen Parts
- [ ] Wände existieren nur auf dem Client und brechen nur für den eigenen Spieler sichtbar

### Etappe 3: Der Wurf
- [ ] Wurf auslösen, Server berechnet das Ergebnis
- [ ] Schwert fliegt, Kamera folgt (Schwerter anderer Spieler sind nicht sichtbar)
- [ ] Wände werden nur in der Nähe des Schwerts aufgebaut
- [ ] Wände brechen, Tempo hängt von der Kraft ab
- [ ] Abprallen an der zu harten Wand
- [ ] Server sperrt den nächsten Wurf, bis der vorige vorbei ist
- [ ] Prüfung und Begrenzung der Nachrichten auf dem Server

### Etappe 4: Die Anzeige
- [ ] Zeiger mit rotem und grünem Bereich
- [ ] Faktor zwischen 0,5 und 1,5 fließt in die Wurfkraft ein
- [ ] Server taktet die Anzeige selbst und lehnt unmögliche Werte ab

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
