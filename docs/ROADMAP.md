# Roadmap

Immer nur an der aktuellen Etappe arbeiten. Eine Etappe ist erst erledigt, wenn sie in
Studio getestet wurde.

## Etappe 0: Setup prüfen
- [ ] `.\check.ps1` ist grün
- [ ] `rojo serve` läuft, Studio ist verbunden, eine Änderung in `src/` erscheint in Studio
- [ ] Privates GitHub-Repo angelegt, erster Push
- [ ] Code-Skill angelegt

## Version 1: Fühlt sich der Wurf gut an?

Ziel von Version 1 ist nur diese eine Frage. Alles ist grau und aus einfachen Parts.

### Etappe 1: Regeln und Config
- [ ] Config mit Wänden (Material, Härte, Belohnung) und Startwerten
- [ ] Wurfberechnung als reine Funktion: Wurfkraft rein, Liste der durchbrochenen Wände und Belohnung raus
- [ ] Tests dafür

### Etappe 2: Die Bahn
- [ ] Wurfzone und eine Bahn mit sechs Wänden aus einfachen Parts
- [ ] Wände existieren pro Spieler und brechen nur für ihn sichtbar

### Etappe 3: Der Wurf
- [ ] Wurf auslösen, Server berechnet das Ergebnis
- [ ] Schwert fliegt, Kamera folgt
- [ ] Wände brechen, Tempo hängt von der Kraft ab
- [ ] Abprallen an der zu harten Wand
- [ ] Prüfung und Begrenzung der Nachrichten auf dem Server

### Etappe 4: Die Anzeige
- [ ] Zeiger mit rotem und grünem Bereich
- [ ] Faktor fließt in die Wurfkraft ein, Server prüft die Plausibilität

### Etappe 5: Training
- [ ] Eine Trainingsbahn mit automatischem Wurf, gibt Stärke

### Etappe 6: Belohnung und Speichern
- [ ] Währung nach Wurfweite
- [ ] Speichern und Laden aller Werte, mit Fehlerbehandlung

### Etappe 7: Einfache Anzeige der Werte
- [ ] Stärke und Währung auf dem Bildschirm, noch ohne Gestaltung

**Dann testen:** Macht der Wurf Spaß? Erst danach geht es weiter.

## Version 2: Rebirth und weitere Trainingsbahnen
## Version 3: Pets, Glück und Glückswurf
## Version 4: Aussehen: Map, UI, Effekte, Sound
## Version 5: Offline-Fortschritt, Welten, Bestenlisten
