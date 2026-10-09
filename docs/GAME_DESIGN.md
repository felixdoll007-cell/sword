# Game Design

Arbeitstitel: offen. Name der Währung: offen, im Dokument "Währung" genannt.

## Idee in einem Satz
Du trainierst Wurfstärke, wirfst ein Schwert durch eine lange Reihe immer härterer Wände
und kommst mit jedem Durchlauf ein Stück weiter.

Vorbild für Aufbau und Gefühl ist "+1 Stone Skipping". Wir übernehmen das Prinzip, nicht
dessen Map, Texte oder Grafiken.

## Der Kreislauf
1. **Trainieren** gibt Stärke.
2. **Werfen** mit Stärke bringt dich durch Wände und gibt Währung.
3. **Währung** kauft Pets, die Stärke-Multiplikator und Glück geben.
4. **Rebirth** setzt Stärke zurück, gibt einen dauerhaften Multiplikator und schaltet bessere Trainingsbahnen frei.

## Die Map
Klein und sauber gemacht. Drei Bereiche:
- **Lobby** mit Shop, Pets, Rebirth.
- **Trainingsbahnen** nebeneinander, jede mit Anzeige von Multiplikator und Voraussetzung.
- **Wurfzone** vor einer langen, breiten Bahn mit den Wänden, unterteilt in Zonen.

## Training
- Der Spieler stellt sich auf eine Trainingsbahn und bleibt dort stehen.
- Die Figur wirft automatisch in festem Takt, als kleine Version des echten Wurfs.
- Jeder Trainingswurf durchbricht die Wände der Bahn und gibt Stärke.
- Bahnen unterscheiden sich durch Multiplikator und Anzahl der Wände. Bahn 1 hat eine Wand, höhere Bahnen mehr.
- Höhere Bahnen brauchen eine Mindestzahl an Rebirths.

## Der Hauptwurf
- Der Spieler steht in der Wurfzone und löst den Wurf aus.
- Eine Anzeige mit einem Zeiger, der sich auf und ab bewegt: außen rot, Mitte grün. Je näher an der Mitte, desto höher der Faktor für den Wurf.
- Der Faktor der Anzeige liegt zwischen 0,5 und 1,5. Der Server taktet die Anzeige selbst und lehnt unmögliche Werte ab. Ganz verhindern lässt sich perfektes Timing durch Cheats nicht, deshalb ist der Bereich bewusst klein.
- **Glückswurf:** Mit kleiner Chance wird der Wurf deutlich stärker. Die Chance hängt vom Glückswert ab. Ausgewürfelt wird nur auf dem Server.
- Die Kamera folgt dem Schwert von hinten.

### Berechnung
- Wurfkraft = Stärke × Faktor der Anzeige × Multiplikatoren (Rebirth, Pets) × Glücksfaktor.
- Jede Wand hat eine Härte. Durchbricht das Schwert eine Wand, sinkt die verbleibende Wurfkraft um deren Härte.
- Reicht die verbleibende Kraft nicht für die nächste Wand, endet der Wurf dort.
- Die Härte steigt von Wand zu Wand stark an, sodass jede neue Wand ein spürbares Ziel ist.
- Die Berechnung läuft vollständig auf dem Server.
- Der Server sperrt den nächsten Wurf, bis der vorige vorbei ist. Die Dauer berechnet er selbst.

### Große Zahlen
Stärke und Härte werden sehr groß (weit über eine Billion). Das ist von Anfang an
eingeplant: Die Berechnung muss damit umgehen, und angezeigt werden Zahlen abgekürzt
(1.5K, 3.2M, ...).

### Tempo
Je größer die Wurfkraft im Verhältnis zur Härte einer Wand, desto schneller fliegt das
Schwert hindurch. Schwache Wände kosten später fast keine Zeit. Ein Wurf soll auch im
späten Spiel nur wenige Sekunden dauern.

### Das Ende des Wurfs
An der ersten Wand, die zu hart ist, prallt das Schwert ab und hinterlässt nur einen
Kratzer, mit eigener Animation. Der Spieler soll ohne Text sehen, welche Wand sein
nächstes Ziel ist.

## Wände und Zonen
- Die Bahn besteht aus Zonen mit je mehreren Wänden aus einem Material.
- Reihenfolge der Materialien, vorläufig: Papier, Holz, Stein, Eisen, Obsidian, Bedrock.
- Die Wände werden aus der Config berechnet: Materialien, Wände pro Zone und eine Formel für die Härte. Sie werden nicht einzeln von Hand eingetragen.
- Version 1 hat sechs Zonen mit je fünf Wänden.
- Gebaut werden nur die Wände in der Nähe des Schwerts.
- Die Struktur erlaubt später weitere Welten hinter der letzten Zone.
- Jeder Spieler hat seine eigenen Wände. Sie existieren nur auf seinem Client und brechen nur für ihn sichtbar. Der Server baut keine Wände, er rechnet nur.
- In Version 1 sieht man die Schwerter anderer Spieler nicht.
- Nach dem Wurf stehen alle Wände wieder.

## Belohnung
- Währung gibt es danach, wie weit der Wurf gekommen ist. Jede durchbrochene Wand zählt, härtere Wände geben mehr.
- Eine vollständig durchbrochene Zone gibt einen Bonus.
- Durchbrochene Wände im Hauptwurf geben zusätzlich etwas Stärke, deutlich weniger als Training.

## Rebirth
- Verfügbar ab einer bestimmten Stärke. Die Schwelle steigt mit jedem Rebirth.
- Setzt Stärke auf null. Währung und Pets bleiben.
- Gibt einen dauerhaften Multiplikator auf Stärke.
- Schaltet Trainingsbahnen frei. Welche Bahnen frei sind, wird aus der Zahl der Rebirths berechnet und nicht gespeichert.

## Pets
- Kosten Währung.
- Geben Stärke-Multiplikator und Glück.
- Kommt nach Version 1.

## Später
- Spuren und Effekte für das Schwert
- Verschiedene Wurfwaffen (Schwert, Axt, Wurfmesser)
- Offline-Fortschritt: bei der Rückkehr Stärke für die Zeit der Abwesenheit, höchstens drei Stunden und mit reduzierter Rate
- Weitere Welten
- Bestenlisten

## Speichern
Gespeichert werden pro Spieler: Stärke, Währung, Rebirths, weiteste Wand, Pets,
Zeitpunkt des letzten Verlassens. Freigeschaltete Bahnen werden nicht gespeichert, sondern
aus den Rebirths berechnet.

## Aussehen
Details sind wichtiger als Umfang. Wenige kräftige Farben, einheitliche Klötzchen-Optik,
dicke Schrift mit Umriss, klare große Buttons. Genaue Regeln kommen in `docs/STYLE.md`,
sobald die Mechanik steht.

## Balance
Alle Zahlen stehen im Config-Ordner und werden beim Spielen eingestellt. Ziel: Der Spieler
erreicht in den ersten Minuten schnell mehrere Wände, danach etwa alle paar Minuten ein
neues Ziel. Es soll sich nie zäh anfühlen und nie geschenkt.

## Offene Punkte
- Name des Spiels
- Name der Währung
- Wie stark der Glückswurf ausfällt und wie selten er ist
