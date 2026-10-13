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
- [x] Nachbesserung: Trainings-Animation bewegt nur Oberkörper und rechten Arm, Hüfte und Beine nicht
- [x] Nachbesserung: eigene Haltung der Waffe (per Code, ohne Upload), Griffwinkel pro Waffe in der Config, Wurfanimation hat Vorrang
- [x] Nachbesserung: Laufhaltung entfernt, die Haltung vom Stehen gilt in jeder Bewegung; Waffe ist nach dem Respawn wieder in der Hand
- [ ] Animationen von mir angesehen und hochgeladen, Nummern in der Config
- [ ] Von mir getestet

### Zwischenblock: Menü-Symbole freistellen (Vorgriff auf Version 4)
- [x] Skript `tools/icons/cut_out_icons.py`: macht den Magenta-Hintergrund der Rohbilder in `assets/icons/roh` durchsichtig (auch in den Lücken innen), entfernt den rosa Saum an der Kontur, schneidet quadratisch zu und speichert 512x512 als PNG in `assets/icons`
- [x] Sechs Symbole (shop, rebirth, pets, trails, inventory, gifts) und `assets/icons/vorschau.png` erzeugt
- [ ] Von mir angesehen
- Nur lokal: nichts ist nach Roblox hochgeladen oder in die Oberfläche eingebaut.

### Block: Oberfläche im neuen Stil (Vorgriff auf Version 4)
- [x] `docs/STYLE.md`, Abschnitt Symbole: Menü-Symbole sind fertige Bilder, der Shop ist ein Korb
- [x] Bausteine als wiederverwendbare Module in `src/client/Ui`: Text mit Rand, Button, Menü-Button, Fenster, Kachel, Fortschrittsbalken (dazu Symbol-Platzhalter, Kurzmeldung, Waffen-Vorschau)
- [x] Alle Farben, Größen, Zeiten und Texte der Oberfläche in `Config/Ui`; die Anordnung für jedes Bildschirmformat rechnet `Rules/UiLayout` (mit Tests für Handy, Tablet und Monitor, hoch und quer)
- [x] Werte links unter dem Menü, Fortschrittsbalken unten mittig, Wurf-Button und Anzeige mit dem Zeiger im neuen Stil
- [x] Rebirth-Fenster als Vorher-Nachher mit Warnzeile, Balken und grünem Button
- [x] Menü-Raster links mit sechs Buttons; Shop-Fenster mit Waffen-Kacheln (3D-Modell), Kaufen und Ausrüsten über den Server; vier Buttons gesperrt mit "Coming soon" und Schalter in der Config (das Shop-Fenster wurde im Block "Shop und Items trennen" zum Items-Fenster)
- [x] Einblendungen "+..." im selben Schriftstil
- [x] Zahlen nie länger als vier Zeichen vor der Einheit
- Noppen-Textur: vorerst nicht. Buttons und Balken bleiben einfarbig, der Platz für die Nummer in `Config/Ui` bleibt.
- [x] Nachtrag: Symbole für Stärke und Coins eingetragen, Rebirths zeigt das Rebirth-Symbol in klein; Menü-Button heißt ITEMS; alle Menü-Beschriftungen in derselben Schriftgröße mit Abstand zum Rand
- [ ] Symbole für Schloss, Haken und Schließen (bis dahin Platzhalter)
- [ ] Von mir getestet
- Nicht umgestellt: die Schilder in der Welt (Trainingsbahnen, Shop-Sockel). Sie stehen in STYLE.md, waren aber nicht Teil dieses Blocks.

### Block: Shop und Items trennen
- [x] Menü-Button ITEMS ist frei und öffnet das Waffen-Fenster mit der Überschrift ITEMS und dem Reiter WEAPONS links außen (Fenster-Baustein kann jetzt Reiter, ein weiterer Reiter braucht nur einen Eintrag)
- [x] Gekaufte Waffen: Antippen der Kachel rüstet aus, die ausgerüstete hat den grünen Haken
- [x] Nicht gekaufte Waffen: abgedunkelt mit Schloss, Preis und Hinweis "Buy at the pedestal", kein Kaufen im Fenster
- [x] Server: Die Nachricht aus dem Fenster kann nur noch ausrüsten (nur gekaufte Waffen), nie kaufen
- [x] Menü-Button SHOP ist gesperrt mit Schloss und "Coming soon", über den Schalter in der Config
- [x] Von mir getestet

### Block: Wurfzone in fertiger Optik (Vorgriff auf Version 4)
- [x] Boden der Wurfzone in zwei Tönen Glut-Orange, leicht erhöhter dunklerer Rand rundherum (ohne Springen begehbar)
- [x] Schriftzug "THROW ZONE" auf dem Boden, in der Schrift der Oberfläche
- [x] Boden um die Wurfzone in zwei Tönen Grün
- [x] Korrektur: Das Grün liegt in drei Stücken neben Wurfzone und Bahn auf gleicher Höhe, nie unter oder über einem anderen Boden (das flackerte), und endet vor den Trainingsbahnen
- [x] Alle Farben und Größen in `Config/Ui` (world); Lage von Rand, Schriftzug und Grün als getestete reine Funktionen
- [x] Kachelbild für Schachbrett und Noppen erzeugt: `assets/textures/floor-tile.png` (Skript `tools/textures/make_floor_tile.py`)
- [x] Kachelbild von mir angesehen und hochgeladen, Nummer in `Config/Ui` (world.floorTile.image)
- [ ] Von mir getestet
- Nichts liegt nur im Ort: Alles wird beim Start aus dem Code gebaut, Speichern in Studio ist dafür nicht nötig.

### Block: Papier-Zone in fertiger Optik (Vorgriff auf Version 4)
- [x] Bahnboden von der Wurflinie bis Wand 5 in zwei Cremetönen mit der Noppen-Kachel; dahinter grau wie bisher (der Bahnboden besteht jetzt aus Abschnitten hintereinander, nie übereinander)
- [x] Gehwege links und rechts entlang der Papier-Zone: 1 Stud höher, zwei Töne Kirschblüten-Rosa mit Noppen, dunkelrote Kante zur Bahn; das Grün um die Wurfzone spart sie aus
- [x] Papier-Wände cremeweiß mit dünnem dunkelrotem Rahmen (als Bild auf der Wand, kein zusätzliches Teil); Bruchstücke in derselben Farbe
- [x] "WOOD" schwebt am Ende der Papier-Zone über der Bahn, in der Schrift der Oberfläche, zur Kamera gedreht
- [x] Alle Farben und Maße in `Config/Ui` (world.lane); eine weitere Zone braucht nur einen Eintrag mit Farben und Namen
- [ ] Von mir getestet

### Block: Deko für die Papier-Zone (Vorgriff auf Version 4)
- [x] Drei importierte Modelle nach Mesh-Namen eingefärbt und als Vorlagen in `ReplicatedStorage.Assets` abgelegt: `paper_lantern`, `origami_crane`, `paper_pinwheel` (Form und Größe unverändert)
- [x] Auf beiden Gehwegen der Papier-Zone verteilt: abwechselnd, gleicher Abstand, zur Bahn gedreht, ohne Kollision; Abstand und Reihenfolge in der Config
- [x] Kleine Bewegungen nur auf dem Client: Laternenlicht flackert leicht, Kranich schwebt, Windrad dreht sich; Stärke und Tempo in der Config
- [ ] Von mir getestet
- Wichtig: Die Vorlagen liegen nur im Ort, nicht im Repo. Der Ort muss in Studio gespeichert sein. Details in `assets/decor-templates.NOTES.md`.

### Block: Papier-Zone, Rand neu ordnen (Vorgriff auf Version 4)
- [x] Kirschblütenbaum eingefärbt und als Vorlage `cherry_tree` in `ReplicatedStorage.Assets` abgelegt
- [x] Gehwege doppelt so breit und in zwei Stufen (innen 1 Stud, außen 2,5 Studs hoch), in zwei Tönen Sandbeige mit Noppen, dunkelrote Kante zur Bahn bleibt
- [x] Gehwege nicht begehbar: unsichtbarer Zaun an allen offenen Seiten (vorn, hinten, außen); zur Bahn hin steht schon die Sperre der Bahn. Hält nur Spieler auf
- [x] Deko als feste Liste in der Config, nur auf der äußeren Stufe: zwei Laternen als Tor, pro Seite drei weitere Teile in unregelmäßigem Abstand, drei Bäume ganz außen; elf Teile, jedes anders gedreht und bis zu 15 % größer oder kleiner
- [x] Leuchten, Schweben und Drehen unverändert, der Baum steht still
- [ ] Von mir getestet
- Wichtig: Die Vorlagen liegen nur im Ort. Nach dem Import des Baums muss der Ort in Studio gespeichert werden.

### Block: Himmel, Licht und Boden außen herum (Vorgriff auf Version 4)
- [x] Licht als "Stimmung" in der Config (`world.moods`), beim Start vom Client gesetzt: heller Nachmittag, warme Sonne, aufgehellte Schatten, leichter Schein um leuchtende Teile, Farben etwas kräftiger
- [x] Himmel mit eingebauten Mitteln: Roblox-Himmelsbild, heller Dunst am Horizont
- [x] Boden außen herum: ruhiges Grün ohne Muster bis weit hinter alles (vier große Platten), 0,3 Studs unter allen Böden; keine graue Grundplatte mehr
- [x] Shop-Sockel stehen jetzt neben der Wurfzone (z = 6 statt -6): Der erste ragte seit dem Verbreitern der Gehwege 1 Stud in den Gehweg
- [ ] Von mir getestet
- Bewusst die günstige Beleuchtungsart behalten (weich, am Handy flüssig). Schärfere Schatten wären eine Einstellung in `default.project.json`.

### Block: Trainingsbahn 1x in fertiger Optik, alle Schilder im neuen Stil (Vorgriff auf Version 4)
- [x] Strohballen und Zielscheibe eingefärbt und als Vorlagen `hay_bale` und `straw_target` in `ReplicatedStorage.Assets` abgelegt
- [x] Trainingsbahn 1x (Thema Stroh) in vier Schichten: Rahmen in Holzbeige, Boden in zwei Strohgelb-Tönen mit vier Strohballen und sechs Strohbüscheln, tiefer liegender Wurfstreifen in Sand mit gestuftem Steinrand (zehn Steine) und Zielscheibe am Ende, orange Startplatte mit vier Eck-Winkeln und Pfeil
- [x] Die bisherige Wand der Bahn 1x bleibt unsichtbar an ihrer Stelle; Bruchstücke sind strohgelb
- [x] Schilder aller vier Trainingsbahnen schwebend und zur Kamera gedreht: Pille mit Rebirth-Symbol und Zahl, UNLOCKED oder LOCKED, Wirkung in Weiß
- [x] Schilder der fünf Shop-Sockel im selben Stil; Sockel dunkles Blaugrau mit Noppen
- [x] Farben und Maße in `Config/Ui` (world.training, world.signs, world.shop); eine weitere Bahn braucht eine Zeile in `laneThemes` und ein Thema
- [x] Farbkorrektur: Boden satteres, dunkleres Strohgelb, Wurfstreifen warmes helles Braun statt Sand, Rahmen dunkleres Holzbraun
- [ ] Von mir getestet
- Abweichung: Bei der Bahn 1x folgt die unsichtbare Sperre jetzt dem Umriss des neuen Feldes statt dem alten schmalen Boden. Einrasten, Wurfweg, Treffer und Stärke sind unverändert.
- Wichtig: Die Vorlagen liegen nur im Ort. Der Ort muss in Studio gespeichert sein.

## Version 3: Pets, Glück und Glückswurf

### Block: Pets
- [x] Zahlen geklärt und freigegeben: Boni 5 / 10 / 15 / 30 / 60 % auf den Grundwert, Chancen 50 / 30 / 14 / 5 / 1, Ei ab 150 Coins und je Ei 20 % teurer (die zuerst geplanten +1 bis +20 hätten das Spiel gesprengt)
- [x] Sechs Modelle (fünf Pets, ein Ei) eingefärbt und als Vorlagen in `ReplicatedStorage.Assets` abgelegt
- [x] Daten: eigene Pets als einzelne Einträge, bis zu drei ausgerüstet, Platz für 30, gezählte Eier; gespeichert mit dem Rest, alte Spielstände laden ohne Pets
- [x] Ei-Stand in der Welt: Sockel, wackelndes Ei, Schild mit Name und eigenem Preis, HATCH-Button und Übersicht der fünf Pets mit Chancen, wenn man davorsteht
- [x] Schlüpfen: Server zieht Coins ab und würfelt; der Client zeigt Ei, Aufplatzen und das Pet mit Name, Seltenheit und Bonus, etwa zwei Sekunden, per Antippen überspringbar; klare Meldung bei vollem Inventar oder zu wenig Coins
- [x] Wirkung: Summe der ausgerüsteten Boni bei jedem Trainingswurf, auf dem Server berechnet
- [x] Begleiter: ausgerüstete Pets schweben hinter der Figur, auf jedem Client gezeichnet
- [x] Oberfläche: Menü-Button PETS öffnet das Items-Fenster auf dem Reiter PETS; Kacheln, Ausrüsten und Ablegen, EQUIP BEST, Löschen mit Rückfrage
- [x] Sicherheit: alle Pet-Nachrichten auf dem Server geprüft (Typ, Besitz, Anzahl, Nähe zum Stand, Begrenzung pro Sekunde, Pause zwischen zwei Eiern); Tests für Würfeln, Kaufen, Ausrüsten, Löschen, Speichern und falsche Werte
- [x] Balance-Test: mit Waffen und Pets ist kein Durchlauf im Schnitt kürzer als 2 Minuten
- [ ] Von mir getestet
- Wichtig: Die Vorlagen liegen nur im Ort. Der Ort muss in Studio gespeichert sein.
- Nicht gebaut (kommt später): Glück, Glückswurf, Secret, Tauschen, Verschmelzen, Robux-Käufe.

### Block: Ei-Stand und Schlüpfen schöner (nur Aussehen)
- [x] Neues Ei ohne Nest eingefärbt (Shell türkis, Band gold, Stars mintgrün, Glow helles Türkis als Neon) und als Vorlage `crystal_egg` in `ReplicatedStorage.Assets` abgelegt; das Original im Workspace ist weg, `pet_egg` wird nicht mehr verwendet
- [x] Ständer: Ei 1,9-fach, schwebt über dem Sockel, wippt und dreht sich langsam; Sockel 7 statt 5 Studs breit mit türkisen Neon-Leisten an den oberen Kanten; Schild höher
- [x] Übersicht beim Davorstehen (erste Fassung, ersetzt durch das Kärtchen unten): schwebendes Fenster "STARTER EGG" aus dem Fenster-Baustein, gefüllte Kacheln in der Farbe der Seltenheit mit Chance in Weiß, grüner HATCH-Button mit Preis-Pille, Platz rechts daneben frei; quer eine Reihe, hoch zwei
- [x] Schlüpf-Anzeige: Welt weichgezeichnet und abgedunkelt, drehende Strahlen aus Streifen (kein Bild), Ei wackelt immer stärker, "TAP TO HATCH", öffnet nach drei Sekunden von selbst, weißer Blitz, Pet mit Name, Seltenheit und "+N%", Strahlen in der Farbe der Seltenheit, Antippen schließt
- [x] Bausteine erweitert: Pille als eigener Baustein (Schilder und Button), Button mit Pille, gefüllte Kachel
- [x] Alle Größen, Farben und Zeiten in `Config/Ui` (eggWindow, hatch, pill, world.eggStand, layout.eggWindow); Lage des Fensters als getestete reine Funktion
- [x] Nachbesserung: Übersicht als kompaktes Kärtchen statt Fenster (halb durchsichtig, ohne X und Rahmen, Titel klein in Türkis, kleine Kacheln in drei Spalten, HATCH so breit wie die Reihe, am PC mit Taste E), fest oberhalb der Bildmitte und rechts vom Menü
- [x] Nachbesserung: Beim Schlüpfen ist die übrige Oberfläche ausgeblendet; Ei und Pet rund 1,4-mal so groß; weicher heller Schein hinter dem Ei, Strahlen kräftiger
- [x] Altes `pet_egg` aus dem Ort gelöscht
- [x] Fünf Pets durch die zweite Fassung mit großen Augen ersetzt (gleiche Vorlagen-Namen, Form und Größe unverändert), alte Vorlagen gelöscht
- [x] Nach Entwurf (`docs/mocups`): Karte mit Glanz-Kacheln (Farbverlauf, Glanzstreifen, dunkler Rand, Pet groß) und drei Buttons in einer Reihe: HATCH grün mit schrägem "E"-Schildchen und Preis-Pille halb unter dem Button, MULTI gelb und AUTO lila mit Schloss, beide ohne Funktion ("Coming soon"); am PC etwa ein Drittel der Bildschirmhöhe
- [x] Nach Entwurf: Schlüpf-Anzeige mit breiten hellen Strahlen (abwechselnd breit und schmal), kräftigerem Schein, Ei 1,5-mal so groß, "TAP TO HATCH" groß unten und leicht pulsierend
- [ ] Von mir getestet
- Unverändert: Preise, Chancen, Würfeln, Speichern, Server-Prüfungen.
- Wichtig: Die Vorlage liegt nur im Ort. Der Ort muss in Studio gespeichert sein (Strg+S).
### Block: Bambus-Zone in fertiger Optik (Vorgriff auf Version 4, nur Aussehen)
- [x] Welt 1 hat das Thema Dojo / Japan; die Zonen heißen Papier, Bambus, Holz, Stein, Eisen, Jade (nur Namen und Aussehen, Härte und Belohnung unverändert)
- [x] Bahnboden der Zone in zwei Tönen hellem Grün, Gehwege in zwei Tönen hellem Steingrau mit dunkel bambusgrüner Kante, unsichtbarer Zaun wie bei Papier; schließt ohne Überlappung an die Papier-Zone an
- [x] Wände 6 bis 10 als Bambuswand: grün, fünf dunklere senkrechte Streifen, braunes Band in der oberen Hälfte (als Bild auf der Wand, keine zusätzlichen Teile)
- [x] "BAMBOO" in Bambusgrün hinter der Papier-Zone, "WOOD" in Holzbraun hinter der Bambus-Zone
- [x] Vier neue Vorlagen eingefärbt und in `ReplicatedStorage.Assets` abgelegt: `bamboo_cluster`, `stone_lantern`, `taiko_drum`, `shishi_odoshi`
- [x] Zehn Deko-Teile an festen Plätzen: zwei Steinlaternen als Tor, vier Bambusgruppen ganz außen, Trommel, zwei Wasserspiele, eine weitere Steinlaterne
- [x] Bewegungen auf dem Client: Bambusblätter wippen, Steinlaternen flackern, das Rohr des Wasserspiels kippt alle sieben Sekunden
- [x] Korrektur: Deko größer (Laterne, Trommel, Wasserspiel 1,8-mal, Bambus 1,4-mal), Gehwege in wärmerem, dunklerem Steingrau, Wasserspiel richtig herum (ruht mit dem offenen Ende nach oben, kippt nach vorn unten)
- [ ] Von mir getestet
- Unverändert: Wurf, Flug, Schaden, Coins, wer welche Wände sieht, die Bahn ab Wand 11.
- Wichtig: Die Vorlagen liegen nur im Ort. Der Ort muss in Studio gespeichert sein (Strg+S).

### Block: Bambus-Wände als Modell (Vorgriff auf Version 4, nur Aussehen)
- [x] Vorlage `bamboo_wall` eingefärbt und in `ReplicatedStorage.Assets` abgelegt (1464 Dreiecke)
- [x] Wände 6 bis 10: die Wand bleibt unsichtbar an ihrem Platz, das Modell steht auf dem Client an derselben Stelle, ohne Kollision, und bedeckt sie ganz
- [x] Kein Kratzer an Modell-Wänden: beim Abprallen wackelt das Modell kurz und ist bis zum Ende des Wurfs dunkler; beim Durchbrechen verschwindet es mit der Wand, Bruchstücke in Bambusgrün
- [x] Aufgemalte Streifen und Band der Bambus-Wände entfernt
- [x] Pro Zone in der Config: Wand-Modell (oder keins) und Kratzer an/aus
- [ ] Von mir getestet
- Entschieden: Eine Dunkel-Stufe beim Abprallen reicht. Wachsenden Schaden an einer Wand gibt es nicht und er wird kein eigener Block.
- Unverändert: Treffer, Schaden, Coins, Server, wer welche Wände sieht.
- Wichtig: Die Vorlage liegt nur im Ort. Der Ort muss in Studio gespeichert sein (Strg+S).

### Block: Holz-Zone in fertiger Optik (Vorgriff auf Version 4, nur Aussehen)
- [x] Bahnboden der Zone in zwei Tönen Honigbraun, Gehwege im Tatami-Look (zwei Töne grünliches Beige, dunkelbraune Kante), unsichtbarer Zaun wie bisher; schließt ohne Überlappung an die Bambus-Zone an
- [x] "STONE" in Steingrau hinter der Holz-Zone
- [x] Fünf neue Vorlagen eingefärbt und in `ReplicatedStorage.Assets` abgelegt: `training_dummy`, `weapon_rack`, `sake_barrels`, `ema_rack`, `wooden_wall`
- [x] Wände 11 bis 15 als Modell (Holzwand), Kratzer beim Abprallen bleibt an, Bruchstücke in Holzbraun
- [x] Neun Deko-Teile an festen Plätzen: zwei Waffenständer als Tor, drei Trainingspuppen, zwei Sake-Stapel, zwei Täfelchen-Gestelle
- [x] Bewegungen auf dem Client: das Tuch der Puppen weht leicht, die Täfelchen schaukeln leicht
- [ ] Von mir getestet
- Unverändert: Wurf, Flug, Schaden, Coins, wer welche Wände sieht, die Bahn ab Wand 16.
- Wichtig: Die Vorlagen liegen nur im Ort. Der Ort muss in Studio gespeichert sein (Strg+S).

## Version 4: Aussehen: Map, UI, Effekte, Sound
## Version 5: Offline-Fortschritt, Welten, Bestenlisten

## Vor dem Veröffentlichen: Block Käufe
Kommt vor dem öffentlichen Start, noch nicht geplant im Detail. Bis dahin wird keine Kauflogik gebaut.
- [ ] Robux-Bahn: Trainingsbahn mit Freischaltung "Kauf" (die Config-Struktur dafür steht seit Block C)
- [ ] Prüfung der Käufe ausschließlich auf dem Server; ein Kauf wird erst gutgeschrieben, wenn er sicher gespeichert ist
- [ ] Abgleich mit den Roblox-Regeln für Käufe, bevor etwas verkauft wird
- Mit weiteren Welten: Wände nur in der Nähe des Schwerts aufbauen. In Version 1 stehen alle 30 Wände immer.
