# Stil-Regeln für Oberfläche und Welt

Vorbild für Aufbau und Stilmittel sind die Bilder aus "+1 Stone Skipping". Wir übernehmen
Aufbau, Raster und Stilmittel. Wir übernehmen keine Grafiken, Symbole, Namen oder Texte
daraus. Alle Symbole und Modelle sind eigene.

## Grundsatz
Wenige Elemente, konsequent wiederholt: eine Schrift, ein Rahmenstil, eine Textur.
Wenn ein neues Element nicht aus den Bausteinen unten gebaut werden kann, erst nachfragen.

## Schrift
- Eine einzige sehr fette, runde Schrift für alles. Nimm die fetteste eingebaute
  Roblox-Schrift, die dem Vorbild am nächsten kommt (prüfen: Montserrat Black,
  Fredoka One). Keine zweite Schrift.
- Text ist immer weiß oder farbig mit dickem schwarzem Rand (UIStroke) und einem
  kleinen harten Schatten nach unten.
- Überschriften von Fenstern: sehr groß, weiß, ragen oben über den Fensterrand hinaus.
- Zahlen immer abgekürzt (1.5K, 3.2M), nie mehr als vier Zeichen plus Einheit.
- Text darf nie so klein werden, dass er am Handy unlesbar ist. Lieber kürzen.

## Farben

### Bedeutungsfarben, im ganzen Spiel gleich
| Bedeutung | Farbe |
|---|---|
| Bestätigen, Kaufen, Ausrüsten, UNLOCKED, OWNED | kräftiges Grün |
| Schließen, Ablegen, Warnung, LOCKED | kräftiges Rot |
| Positiver Zahlenwert (+25%) | helles Grün |
| Fortschritt | kräftiges Blau auf hellgrauem Grund |
| Hinweis-Punkt mit Ausrufezeichen | Rot, rund, oben rechts am Element |

### Eigene Farben des Spiels
| Zweck | Farbe |
|---|---|
| Stärke (Strength) | Glut-Orange |
| Coins | Gold-Gelb |
| Rebirths | Stahlblau |
| Fensterfläche außen | dunkles Blaugrau, leicht durchsichtig |
| Fensterfläche innen | fast schwarzes Blaugrau, deckend |

### Seltenheit (für Waffen, später Pets und Trails)
Common grau, Uncommon grün, Rare blau, Epic lila, Legendary gold, Secret Regenbogen.
Die Seltenheit zeigt sich als Farbe des Rahmens und des Namens.

## Bausteine der Oberfläche

### Noppen-Textur
Flächen von Buttons, Balken und Angebots-Karten tragen eine dezente, gekachelte
Noppen-Textur in etwas hellerem Ton der Grundfarbe. Eine einzige Kachel-Grafik für alles.

### Button
- Rechteck mit leicht runden Ecken, Noppen-Textur, schwarzer Rand.
- Unten eine dunklere Kante in der Grundfarbe, damit er erhaben wirkt.
- Beim Drücken sackt er um die Höhe dieser Kante ein. Beim Überfahren wird er leicht größer.
- Farbe nach Bedeutung, siehe oben.
- Glanz-Button (Karte am Ei-Stand): statt Noppen ein Farbverlauf von hell oben nach kräftig
  unten mit hellem Glanzstreifen. Er kann ein Symbol links der Beschriftung tragen (Schloss
  für "kommt noch"), eine Preis-Pille, die halb unter ihm hängt, und ein schräges helles
  Schildchen mit der Taste links oben.

### Menü-Button (Raster links)
- Quadrat, dunkle Fläche, heller runder Rand.
- Symbol groß in der Mitte, darf leicht über den Rand ragen. Beschriftung unten.
- Fortschritt als Prozentzahl oben auf dem Button, wo es einen gibt (Rebirth).

### Fenster
- Dunkle, leicht durchsichtige Fläche, schwarzer Rand. Der Hintergrund dahinter ist
  weichgezeichnet.
- Überschrift oben mittig, ragt über den Rand.
- Großes Symbol oben links, ragt über die Ecke.
- Roter runder Schließen-Button mit weißem X oben rechts, ragt über die Ecke.
- Inhalt in einer dunkleren Innenfläche mit runden Ecken.
- Hat ein Fenster mehrere Bereiche, sitzen die Reiter links außen am Fenster,
  der aktive Reiter ist heller.
- Öffnen: kurzes Aufploppen von klein nach groß. Schließen: schnell.
- Es ist immer nur ein Fenster offen.
- Kein Fenster ist die Karte am Ei-Stand: dunkel und leicht durchsichtig, runde Ecken, dünner
  heller Rand, kein X, Titel in Türkis. Sie zeigt sich von selbst, wenn man davorsteht.

### Kachel für einen Gegenstand
- Quadrat mit runden Ecken, heller Rand in der Farbe der Seltenheit.
- Gegenstand groß in der Mitte, Wert unten ("+25%") in hellem Grün.
- Ausgerüstet: grüner runder Haken oben rechts und hellerer Rahmen.
- Gesperrt: abgedunkelt, kleines Schloss oben rechts.
- Gefüllte Kachel: Fläche in der Farbe der Seltenheit, etwas dunkler, Rand etwas heller, Wert
  unten in Weiß.
- Glanz-Kachel (Pets am Ei-Stand): Farbverlauf in der Seltenheit von hell oben nach kräftig
  unten, heller Glanzstreifen oben, dunkler Rand, Gegenstand füllt die Kachel fast ganz, Wert
  unten in Weiß.

### Pille
Dunkle, ganz runde Fläche mit schwarzem Rand, links ein Symbol, rechts eine kurze Zahl in ihrer
Farbe. Für das, was etwas kostet oder braucht: auf Schildern in der Welt und am Button
(im Button rechts der Beschriftung, oder halb unter dem Button wie bei HATCH).

### Vorher-Nachher (Rebirth)
Zwei gleiche Karten nebeneinander mit Pfeil dazwischen, darunter eine rote Warnzeile,
darunter der Fortschrittsbalken, darunter der grüne Button.

### Angebots-Karte (Shop)
Breite Karte mit Noppen-Textur und kräftiger Farbe, schwarzer Rand. Gegenstand links
groß, Name und Wirkung rechts, Button unten rechts.

### Fortschrittsbalken
Breit, runde Ecken, Noppen-Textur, schwarzer Rand. Text liegt auf dem Balken:
links der Stand, rechts der Status.

## Aufbau des Bildschirms
- **Links mittig:** Raster der Menü-Buttons, zwei Spalten.
- **Links unten:** die Werte untereinander: Symbol links, Zahl rechts daneben,
  jede Zahl in ihrer Farbe.
- **Unten mittig:** Fortschritt zum nächsten Rebirth, darüber der Wurf-Button,
  wenn man in der Wurfzone steht.
- **Rechts:** bleibt vorerst frei (später Angebote).
- **Oben links:** frei lassen, dort sitzen die Knöpfe von Roblox.
- Die Anzeige mit dem Zeiger sitzt beim Wurf-Button und folgt demselben Stil.

## Handy
- Alles per Daumen erreichbar, Buttons mindestens daumengroß.
- Im Hochformat rückt das Menü-Raster auf eine Spalte oder wird kleiner, nichts überlappt.
- Joystick unten links und Sprung-Button unten rechts bleiben frei.
- Fenster füllen am Handy fast den ganzen Bildschirm.

## Symbole
- Gegenstände (Waffen, später Pets) werden nicht als Bild gezeigt, sondern als das echte
  3D-Modell in einem ViewportFrame, leicht schräg gedreht. So brauchen sie kein
  eigenes Bild und sehen immer aus wie im Spiel.
- Feste Symbole sind eigene, einfache, kräftige Zeichnungen mit schwarzem Rand. Motive aus
  unserer Welt: Flamme oder Faust für Stärke, Münze für Coins.
- Die sechs Menü-Symbole (Shop, Rebirth, Pets, Trails, Items, Gifts) sind fertige Bilder:
  freigestellt, 512x512, ohne Text, hochgeladen. Der Shop ist ein Korb. Ihre Nummern stehen in
  `Config/Ui` (menu). Die Beschriftung ist echter Text, nicht Teil des Bildes.
- Stärke und Coins sind ebenfalls fertige Bilder (Nummern in `Config/Ui`, icons). Rebirths
  bei den Werten zeigt das Rebirth-Symbol des Menüs in klein.
- Es fehlen noch: Schloss, Haken und Schließen. Solange ein Symbol fehlt, steht
  ein schlichter Platzhalter in der richtigen Farbe. Sobald es ein Bild gibt, kommt seine
  Nummer in `Config/Ui` (icons) und der Platzhalter verschwindet von selbst.

## Schilder in der Welt
- Dunkle Pille mit Symbol und Zahl für die Voraussetzung.
- Darunter UNLOCKED in Grün oder LOCKED in Rot.
- Darunter die Wirkung groß in Weiß ("4x STRENGTH").
- Alles in derselben Schrift mit schwarzem Rand, immer zur Kamera gedreht.

## Welt
- Bausteine-Optik: Flächen mit Noppen, Schachbrett aus zwei Tönen derselben Farbe.
- Jede Trainingsbahn hat eine eigene Farbe und ein kleines Thema.
- Welt 1 ist ein Dojo in Japan. Jede Zone der Wurfbahn zeigt am Rand die Umgebung ihres
  Materials: Papier mit Origami und Laternen, Bambus mit Bambusgruppen, Steinlaternen,
  Trommel und Wasserspiel, Holz als Dojo-Hof mit Waffenständern, Trainingspuppen, Sake-Fässern
  und Täfelchen-Gestellen. Stein, Eisen und Jade folgen im selben Thema.
- Der Name der nächsten Zone schwebt in der Ferne über der Bahn.
- Wurfzone mit großem Schriftzug auf dem Boden.

## Arbeitsweise für Claude Code
- Die Oberfläche entsteht aus wiederverwendbaren Bausteinen (Button, Fenster, Kachel,
  Balken), nicht jedes Fenster einzeln.
- Alle Farben, Größen und Zeiten stehen an einer Stelle.
- Aussehen prüfe ich selbst. Keine Screenshot-Schleifen.
- Formen, Farben und Größe der Waffen-Modelle kommen aus Claude Design und werden
  nicht verändert.
