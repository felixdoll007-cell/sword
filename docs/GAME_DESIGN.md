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
- Version 2: vier Bahnen nebeneinander. Voraussetzung 0, 2, 4 und 6 Rebirths, Multiplikator 1x, 4x, 10x und 20x.
- Über jeder Bahn steht ein schlichtes Schild mit Multiplikator und Voraussetzung, bei gesperrten Bahnen "LOCKED".
- Auf dem Trainingsfeld rastet die Figur ein (Mitte, Blick zur Wand). Verlassen durch gehaltene Richtung oder Sprung. Auf gesperrten Bahnen rastet man nicht ein und trainiert nicht; das entscheidet der Server.
- Mehrere Spieler auf derselben Bahn schieben sich nicht weg.
- Jede Bahn hat in der Config eine Art der Freischaltung. Bisher gibt es nur "Rebirths". Später kommt "Kauf" dazu (Robux-Bahn), ohne Umbau der Struktur. Weitere Bahnen entstehen allein durch Einträge in der Config, inklusive Platz auf der Map.

## Der Hauptwurf
- Der Spieler steht in der Wurfzone und löst den Wurf aus.
- Eine Anzeige mit einem Zeiger, der sich auf und ab bewegt: außen rot, Mitte grün. Je näher an der Mitte, desto höher der Faktor für den Wurf.
- Der Faktor der Anzeige liegt zwischen 0,5 und 1,5. Der Server taktet die Anzeige selbst und lehnt unmögliche Werte ab. Ganz verhindern lässt sich perfektes Timing durch Cheats nicht, deshalb ist der Bereich bewusst klein.
- Ablauf: Erster Druck auf THROW startet die Anzeige, die Figur steht still. Zweiter Druck stoppt den Zeiger, kurz erscheint der Faktor (z. B. "x1.4"), dann fliegt das Schwert. Wird nicht gedrückt, verschwindet die Anzeige nach einer festen Zeit und die Figur kann sich wieder bewegen.
- Taktung: Server und Client rechnen die Zeigerposition mit derselben Formel aus der gemeinsamen Server-Zeit. Der Client schickt nur den Zeitpunkt des Drucks, der Server berechnet daraus den Faktor. Ist der Zeitpunkt älter als die erlaubte Verzögerung, wertet der Server den frühesten noch erlaubten Zeitpunkt. Abgelehnt wird nur Unmögliches: keine Zahl, vor dem Start der Anzeige, in der Zukunft, Anzeige abgelaufen.
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
- In Version 1 stehen alle Wände immer. Erst mit weiteren Welten werden nur die Wände in der Nähe des Schwerts gebaut.
- Die Struktur erlaubt später weitere Welten hinter der letzten Zone.
- Jeder Spieler hat seine eigenen Wände. Sie existieren nur auf seinem Client und brechen nur für ihn sichtbar. Der Server baut keine Wände, er rechnet nur.
- In Version 1 sieht man die Schwerter anderer Spieler nicht.
- Ab Version 2 (Block C): Andere Spieler in der Nähe sehen beim Training die Armbewegung und das kleine Schwert, beim Hauptwurf das Ausholen und das losfliegende Schwert. Das fremde Schwert verblasst nach kurzer Strecke und berührt keine Wände. Die Wände brechen weiter nur beim Spieler selbst.
- Der Server meldet diese Ereignisse selbst weiter, aus seinem eigenen Takt und seiner eigenen Wurfprüfung. Clients können keine Ereignisse für andere auslösen. Gezeigt wird nur innerhalb einer Entfernung aus der Config, mit Obergrenze für gleichzeitig dargestellte fremde Würfe.
- Nach dem Wurf stehen alle Wände wieder.

## Belohnung
- Währung gibt es danach, wie weit der Wurf gekommen ist. Jede durchbrochene Wand zählt, härtere Wände geben mehr.
- Eine vollständig durchbrochene Zone gibt einen Bonus.
- Durchbrochene Wände im Hauptwurf geben zusätzlich etwas Stärke, deutlich weniger als Training.

## Rebirth
- Verfügbar ab einer bestimmten Stärke. Die Schwelle steigt mit jedem Rebirth (Formel in der Config).
- Setzt die Stärke auf den Startwert. Währung, weiteste Wand, Rebirths und Pets bleiben.
- Gibt einen dauerhaften Multiplikator auf alle Stärke-Gewinne (Training und Hauptwurf).
- Rebirth-Button mit kleinem Fenster: Fortschritt bis zum nächsten Rebirth, was man verliert, was man bekommt, Bestätigen. Voll per Touch bedienbar.
- Die Anzahl der Rebirths steht bei den Werten oben.
- Der Server prüft alles, der Client meldet nur den Wunsch.
- Zahlen (in `Config/Rebirth`): Multiplikator +1x pro Rebirth (2x, 3x, 4x ...). Die Schwellen stehen als Liste in der Config, abgeleitet aus Zieldauern reiner Trainingszeit pro Durchlauf mit den Bahnen aus Version 2: 3, 3, 3,5, 4, 4,5, 5, 6, 7, 8,5 und 10 Minuten. Das ergibt 200, 400, 2.500, 3.800, 13.500, 18.000, 50.000, 67.000, 92.000 und 120.000 Stärke. Ab Rebirth 11 dauert jeder Durchlauf 20 % länger als der vorige (Formel, schließt an den letzten Listenwert an).
- Rebirths sollen mit der Zeit länger dauern: am Anfang schnell, dann stetig steigend.
- Bekannt und hingenommen: Bei Rebirth 6, 10 und 12 erreicht man beim sofortigen Rebirth dieselbe Wand wie im Durchlauf davor, weil der Härtesprung zum nächsten Material größer ist als der Anstieg der Schwelle. Wer weitertrainiert, kommt weiter.
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
