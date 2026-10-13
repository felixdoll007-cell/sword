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
- Wurfkraft = Stärke × Faktor der Anzeige × Multiplikatoren × Glücksfaktor. (Stand jetzt: nur Stärke × Faktor. Pets wirken beim Training, nicht auf den Wurf; Glück kommt später.)
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
- Welt 1 hat ein festes Thema: Dojo / Japan. Ihre sechs Zonen sind Papier, Bambus, Holz,
  Stein, Eisen, Jade. Die Namen legen nur das Aussehen fest; wie hart eine Wand ist, hängt
  allein von ihrer Nummer ab.
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
- Rebirth-Button im Menü-Raster links, mit dem Fortschritt als Prozent oben auf dem Button. Er öffnet das Rebirth-Fenster: jetzt und danach nebeneinander, rote Warnzeile, Fortschrittsbalken, grüner Button. Voll per Touch bedienbar.
- Der Fortschritt zum nächsten Rebirth steht außerdem immer als Balken unten in der Mitte.
- Die Anzahl der Rebirths steht bei den Werten links unter dem Menü.
- Der Server prüft alles, der Client meldet nur den Wunsch.
- Zahlen (in `Config/Rebirth`): Multiplikator +1x pro Rebirth (2x, 3x, 4x ...). Die Schwellen stehen als Liste in der Config, abgeleitet aus Zieldauern reiner Trainingszeit pro Durchlauf mit den Bahnen aus Version 2: 3, 3, 3,5, 4, 4,5, 5, 6, 7, 8,5 und 10 Minuten. Das ergibt 200, 400, 2.500, 3.800, 13.500, 18.000, 50.000, 67.000, 92.000 und 120.000 Stärke. Ab Rebirth 11 dauert jeder Durchlauf 20 % länger als der vorige (Formel, schließt an den letzten Listenwert an).
- Rebirths sollen mit der Zeit länger dauern: am Anfang schnell, dann stetig steigend.
- Bekannt und hingenommen: Bei Rebirth 6, 10 und 12 erreicht man beim sofortigen Rebirth dieselbe Wand wie im Durchlauf davor, weil der Härtesprung zum nächsten Material größer ist als der Anstieg der Schwelle. Wer weitertrainiert, kommt weiter.
- Schaltet Trainingsbahnen frei. Welche Bahnen frei sind, wird aus der Zahl der Rebirths berechnet und nicht gespeichert.

## Waffen
- Fünf Waffen, in der Config: Wooden Sword (kostenlos, Start), Iron Dagger, Battle Axe, Ember Greatsword, Void Blade (Platzhalter).
- Jede Waffe kostet Coins und gibt einen Bonus auf die Stärke pro Trainingswurf (zusätzlich zu Bahn und Rebirth). Der Hauptwurf wird nicht verstärkt.
- Zahlen: Preise 0 / 500 / 8.000 / 120.000 / 800.000 Coins, Bonus +0 % / +25 % / +50 % / +100 % / +200 %.
- Waffen sind eine echte Beschleunigung: Nach einem Waffenkauf darf der nächste Durchlauf kürzer sein als der davor. Die Rebirth-Schwellen bleiben unverändert und rechnen ohne Waffen.
- Der Shop steht in der Welt, rechts neben der Wurfzone (nicht neben der Bahn, dort liegen die Gehwege): fünf Sockel nebeneinander, auf jedem die Waffe, darüber ein schwebendes Schild mit Name, Bonus ("+25% STRENGTH"), Preis und OWNED, EQUIPPED oder LOCKED.
- Am Sockel kauft man und rüstet aus, per Touch bedienbar. Ein Kauf rüstet die Waffe sofort aus. Zwischen gekauften Waffen wechselt man frei.
- Waffen kauft man ausschließlich an den Sockeln. Der Menü-Button Shop ist für spätere Käufe mit Robux gedacht und bis dahin gesperrt.
- Das Items-Fenster (Menü-Button Items, Reiter Weapons) zeigt jede Waffe als Kachel mit dem echten 3D-Modell und Bonus. Gekaufte Waffen rüstet man dort von überall durch Antippen aus, die ausgerüstete hat den grünen Haken. Nicht gekaufte sind abgedunkelt mit Schloss, Preis und dem Hinweis "Buy at the pedestal". Im Fenster gibt es weitere Reiter, sobald es mehr gibt (Pets).
- Jede Waffe hat eine Seltenheit (in der Config), die die Farbe ihrer Kachel und ihres Namens bestimmt: Wooden Sword Common, Iron Dagger Uncommon, Battle Axe Rare, Ember Greatsword Epic, Void Blade Legendary.
- Die ausgerüstete Waffe fliegt bei Hauptwurf, Training und für Zuschauer.
- Waffen und Coins bleiben beim Rebirth erhalten. Besitz und Ausrüstung werden gespeichert.
- Der Client meldet nur den Wunsch. Am Sockel prüft der Server Preis, Besitz, Coins und die Nähe zum Sockel; nur dort kann gekauft werden. Beim Ausrüsten im Items-Fenster prüft der Server, dass die gemeldete Waffe existiert, dass der Spieler sie besitzt und dass gerade kein Wurf läuft. Über das Fenster kann der Server nichts verkaufen, auch nicht für einen manipulierten Client.
- Waffen ohne Modell fliegen als grauer Platzhalter. Ein neues Modell braucht nur einen Config-Eintrag und die Vorlage in `ReplicatedStorage.Assets`.

## Wurf: Waffe in der Hand, Animation, Kamera
- Die ausgerüstete Waffe hängt an der rechten Hand der Figur, für alle Spieler sichtbar. Beim Wurf verlässt genau diese Waffe die Hand und erscheint danach wieder.
- Wurfanimation für den ganzen Körper: ausholen, Oberkörper drehen, werfen, nachschwingen. Eine für den Hauptwurf, eine kürzere für das Training.
- Die Animationen sind echte Roblox-Animationen (hochgeladen auf das Konto, dem das Spiel gehört). Der Client spielt sie auf der eigenen Figur, Roblox überträgt sie an alle anderen. Sie lassen sich im Animations-Editor nachbessern. Ohne hochgeladene Animation läuft als Ersatz die Schulterbewegung per Code.
- In jeder Animation gibt es den Moment "Release". Dieselbe Zeit steht in der Config. Bis dahin bleibt die Kamera bei der Figur, erst dann folgt sie der Waffe. Flugplan und Wurfsperre des Servers rechnen diese Zeit ein.
- Alle Zeiten stehen in der Config.
- Die Trainings-Animation bewegt nur Oberkörper und rechten Arm. Hüfte und Beine bleiben, wie sie sind.
- Haltung der Waffe, solange nicht geworfen wird: Der rechte Arm ist leicht angewinkelt vor dem Körper, die Klinge zeigt schräg nach oben und vom Körper weg. Die Haltung ist in jeder Bewegung dieselbe: Stehen, Laufen, Springen, Fallen, Landen. Der Rest des Körpers bewegt sich normal mit den Standard-Animationen von Roblox. Die Klinge fährt nie durch den Körper.
- Die Haltung macht jeder Client per Code für alle Figuren in der Nähe, sie steuert nur Schulter, Ellbogen und Handgelenk des rechten Arms. Dafür wird nichts hochgeladen. Die Wurfanimation hat Vorrang; danach gleitet der Arm weich in die Haltung zurück, die Dauer steht in der Config.
- Der Griffwinkel (wie die Waffe in der Hand sitzt) steht pro Waffe in der Config.

## Pets
- Pets schlüpfen aus Eiern. Am Ei-Stand in der Welt (neben den Shop-Sockeln) kauft man ein Ei
  für Coins; der Server würfelt, welches Pet schlüpft. Der Client zeigt nur das Ergebnis.
- Fünf Pets, je eine Seltenheit: Bunny (Common), Fox (Uncommon), Panda (Rare), Dragon (Epic),
  Phoenix (Legendary). Chancen im Starter Egg: 50 / 30 / 14 / 5 / 1 Prozent.
- Wirkung: Ausgerüstete Pets geben einen Bonus auf den Grundwert jedes Trainingswurfs:
  +5 / +10 / +15 / +30 / +60 Prozent. Die Boni der ausgerüsteten Pets werden addiert und zum
  Grundwert gezählt; danach gelten Bahn, Waffe und Rebirth wie bisher. Drei Legendary ergeben
  also +180 % und bleiben damit unter der besten Waffe. Auf den Hauptwurf wirken Pets nicht
  (noch nicht: Glück und Glückswurf kommen später).
- Bis zu drei Pets sind ausgerüstet, bis zu 30 kann man besitzen. Jedes Pet ist ein eigener
  Eintrag, auch zwei gleiche. Ist das Inventar voll, gibt es kein Ei.
- Ei-Preis: 150 Coins für das erste Ei, jedes weitere 20 % teurer (pro Spieler gezählt und
  gespeichert). Startpreis und Steigerung stehen in der Config; mit Steigerung 1 ist der
  Preis fest. Grund für die Steigerung: Coins wachsen mit jedem Rebirth stark, bei festem
  Preis hätte nach 20 Minuten fast jeder ein Legendary.
- Ausgerüstete Pets schweben hinter der Figur her. Jeder Client zeichnet und bewegt sie
  selbst; der Server veröffentlicht nur, wer welche Pets besitzt und ausgerüstet hat.
- Oberfläche: Der Menü-Button Pets öffnet das Items-Fenster auf dem Reiter Pets. Dort stehen
  die Pets als Kacheln mit 3D-Modell, Name und Rahmen in der Farbe der Seltenheit und dem
  Bonus. Antippen rüstet aus oder legt ab. Dazu "EQUIP BEST" und Löschen mit Rückfrage.
- Pets bleiben beim Rebirth erhalten und werden mit dem Rest gespeichert.
- Der Server prüft alles: Coins, Platz, Besitz, Zahl der ausgerüsteten Pets, Nähe zum
  Ei-Stand, und dass nicht zu schnell hintereinander geschlüpft wird.
- Der Ei-Stand: ein Sockel in dunklem Blaugrau mit Noppen, die oberen Kanten als leuchtende
  türkise Leisten. Darüber schwebt das Ei (türkis mit goldenem Band, ohne Nest), wippt langsam
  und dreht sich langsam. Darüber das Schild mit Name und eigenem Preis.
- Steht man am Stand, erscheint oberhalb der Bildmitte eine Karte nach dem Entwurf in
  `docs/mocups`: dunkler, leicht durchsichtiger Hintergrund mit runden Ecken und dünnem hellem
  Rand, ohne X. Oben "STARTER EGG" in Türkis, darunter die fünf Pets als Glanz-Kacheln
  (Farbverlauf in der Seltenheit, Glanzstreifen, dunkler Rand, Pet groß, Chance unten; drei
  oben, zwei unten mittig), darunter drei Buttons in einer Reihe: HATCH in Grün mit der
  Preis-Pille halb unter dem Button, MULTI in Gelb und AUTO in Lila. MULTI und AUTO tragen ein
  Schloss und haben noch keine Funktion, Antippen zeigt nur "Coming soon". Mit Tastatur sitzt
  ein schräges "E"-Schildchen links oben an HATCH und E schlüpft auch, auf Touch wird keine
  Taste gezeigt. Die Karte ist am PC etwa ein Drittel der Bildschirmhöhe hoch, hochkant etwas
  mehr. Sie sitzt fest auf dem Bildschirm (nicht in der Welt), immer rechts vom Menü: Sie
  verdeckt weder Menü noch Werte. Geht man weg, verschwindet sie.
- Schlüpfen: Die Welt wird weichgezeichnet und abgedunkelt, die übrige Oberfläche (Menü,
  Werte, Balken, Buttons) ist währenddessen ausgeblendet. Hinter dem großen Ei (unser
  3D-Modell) liegt ein weicher heller Schein, dahinter drehen sich langsam breite helle
  Strahlen, abwechselnd breit und schmal (beides ohne Bild, aus Ringen und schmalen Streifen).
  Das Ei wackelt immer stärker, unten steht groß "TAP TO HATCH" und pulsiert leicht. Antippen
  öffnet sofort, sonst öffnet es sich nach drei Sekunden. Dann ein
  weißer Blitz, das Pet mit Name, Seltenheit in ihrer Farbe und "+N%", und die Strahlen nehmen
  die Farbe der Seltenheit an. Das Pet bleibt stehen, bis man antippt ("TAP TO CONTINUE").
- Die Vorlagen der Pets und des Eis liegen nur im Ort (siehe `assets/decor-templates.NOTES.md`).

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
dicke Schrift mit Umriss, klare große Buttons. Die genauen Regeln stehen in `docs/STYLE.md`.

Die Oberfläche ist aus wiederverwendbaren Bausteinen gebaut (Text mit Rand, Button,
Menü-Button, Fenster, Kachel, Fortschrittsbalken). Alle Farben, Größen, Zeiten und Texte
stehen in `Config/Ui`. Aufbau des Bildschirms:
- Links: Menü-Raster in zwei Spalten (Shop, Rebirth, Pets, Trails, Items, Gifts), darunter
  Stärke, Coins und Rebirths, je mit Symbol und Zahl in ihrer Farbe. Shop, Pets, Trails und
  Gifts sind abgedunkelt mit Schloss und sagen beim Antippen "Coming soon"; jeder Button hat
  einen Schalter in der Config. Rebirth und Items öffnen ihr Fenster.
- Unten mittig: Fortschritt zum nächsten Rebirth, darüber der Wurf-Button (nur in der
  Wurfzone), rechts daneben die Anzeige mit dem Zeiger.
- Hochformat am Handy: Alles unten in der Mitte rückt nach oben, damit Joystick und
  Sprung-Button frei bleiben. Fenster füllen fast den ganzen Bildschirm.
- Es ist immer nur ein Fenster offen. Dahinter ist die Welt weichgezeichnet und abgedunkelt.
- Zahlen sind immer abgekürzt und haben nie mehr als vier Zeichen vor der Einheit
  (15.3K, aber 153K).
- Die Noppen-Textur ist vorbereitet, aber vorerst aus: Buttons und Balken sind einfarbig.
  Sie bräuchte eine hochgeladene Kachel-Grafik, deren Nummer in `Config/Ui` (studs) käme.

Die Welt bekommt denselben Stil Stück für Stück. Fertig ist die Wurfzone als Muster:
Schachbrett-Boden in zwei Tönen Glut-Orange mit Noppen, dunklerer, leicht erhöhter Rand,
der Schriftzug "THROW ZONE" auf dem Boden und drumherum ein Schachbrett in zwei Tönen Grün.
Schachbrett und Noppen sind ein einziges Kachelbild, das als Textur auf einem großen Teil
liegt (wenige große Teile statt vieler kleiner). Farben und Größen stehen in `Config/Ui`
(world). Die Papier-Zone (Wurflinie bis Wand 5) ist das Muster für die Zonen der Bahn: Boden in
zwei Cremetönen, cremeweiße Wände mit dünnem dunkelrotem Rahmen, und am Ende schwebt der
Name der nächsten Zone ("BAMBOO") über der Bahn. Jede weitere Zone braucht nur einen Eintrag
mit Farben, Namen, Wandmuster und Deko-Liste in `Config/Ui` (world.lane.zones). Eine Zone
endet an ihrer letzten Wand; das Stück bis zur ersten Wand der nächsten Zone gehört zur
nächsten Zone. Hinter Wand 10 und auf den Trainingsbahnen 4x bis 20x ist der Boden noch grau.

Die Bambus-Zone (Wand 6 bis 10) ist die zweite fertige Zone: Boden in zwei Tönen hellem,
frischem Grün, Gehwege in zwei Tönen hellem Steingrau mit dunkel bambusgrüner Kante, und
Bambuswände: grün, mit fünf etwas dunkleren senkrechten Streifen wie Rohre und einem braunen
Band in der oberen Hälfte wie eine Schnur. Streifen und Band sind ein Bild auf der Wand, keine
zusätzlichen Teile. Hinter ihr schwebt "WOOD" in Holzbraun. Ihre Deko: am Anfang zwei
Steinlaternen als Tor, ganz außen vier Bambusgruppen (eine bis 20 % größer), dazwischen eine
Taiko-Trommel, zwei Wasserspiele und eine weitere Steinlaterne, zusammen zehn Teile. Die
Bambusblätter wippen ganz leicht, die Steinlaternen leuchten schwach und flackern, das Rohr
des Wasserspiels kippt alle paar Sekunden langsam nach vorn und schnellt zurück.

Die Bahn ist die Hauptsache, der Rand ist Kulisse. Links und rechts der Papier-Zone liegen
breite Gehwege in zwei Stufen (innen etwa 1 Stud, außen etwa 2,5 Studs hoch) in ruhigem
Sandbeige, zur Bahn hin mit dunkelroter Kante. Man kann sie nicht betreten: Ein unsichtbarer
Zaun hält Spieler ab, nicht aber die geworfene Waffe oder die Kamera.

Deko steht nur auf der äußeren Stufe und wird von Hand gesetzt (feste Liste in der Config),
damit sie nicht aufgereiht wirkt: am Anfang der Zone je eine Laterne wie ein Tor, danach pro
Seite höchstens drei weitere Teile (Laterne, Kranich, Windrad) in unregelmäßigem Abstand,
dazu zwei bis drei Kirschblütenbäume ganz außen. Höchstens zwölf Teile pro Zone, jedes leicht
anders gedreht und bis zu 15 % größer oder kleiner. Die Deko hat keine Kollision. Jeder
Client baut sie selbst aus Vorlagen und bewegt sie leicht: Das Laternenlicht flackert, der
Kranich schwebt, das Windrad dreht sich, der Baum steht still. Die Vorlagen liegen nur im Ort
(siehe `assets/decor-templates.NOTES.md`).

Himmel und Licht sind eine "Stimmung": ein vollständiger Satz Werte (Tageszeit, Sonne, Licht
in den Schatten, Dunst, Schein, Farbabstimmung) in `Config/Ui` (world.moods). Das Spiel
startet mit einem hellen, warmen Nachmittag; der Dunst am Horizont lässt die Ferne weich
auslaufen. Jeder Client setzt die Stimmung selbst, damit spätere Zonen eine eigene bekommen
können. Der Himmel ist das eingebaute Roblox-Himmelsbild. Der Boden der ganzen Welt ist ein
ruhiges, einfarbiges Grün, das weit über alles hinausreicht und klar unter allen Böden liegt.

Trainingsbahnen bekommen je ein Thema. Fertig ist die Bahn 1x (Stroh, Gelb) als Muster, in vier
Schichten von außen nach innen: ein leicht erhöhter Rahmen, der Themen-Boden mit Requisiten
(Strohballen, Streu), der tiefer liegende Wurfstreifen mit gestuftem Steinrand und der
Zielscheibe am Ende, und die erhöhte Startplatte mit Eck-Winkeln und Pfeil. Die Zielscheibe
steht dort, wo für die Logik die Wand der Bahn steht; die Wand selbst ist unsichtbar. Alles vor
der Startplatte ist durch eine unsichtbare Sperre abgetrennt. Die Bahnen 4x, 10x und 20x sind
noch grau.

Schilder in der Welt schweben ohne Tafel und drehen sich zur Kamera, in der Schrift der
Oberfläche. Trainingsbahn: dunkle Pille mit Rebirth-Symbol und nötiger Zahl, darunter UNLOCKED
(grün) oder LOCKED (rot), darunter die Wirkung ("4x STRENGTH"). Shop-Sockel: Name, Bonus in
hellem Grün, Pille mit Coin-Symbol und Preis (oder FREE), darunter OWNED oder EQUIPPED (grün)
oder LOCKED (rot). Die Sockel sind dunkles Blaugrau mit Noppen.

## Balance
Alle Zahlen stehen im Config-Ordner und werden beim Spielen eingestellt. Ziel: Der Spieler
erreicht in den ersten Minuten schnell mehrere Wände, danach etwa alle paar Minuten ein
neues Ziel. Es soll sich nie zäh anfühlen und nie geschenkt.

## Offene Punkte
- Name des Spiels
- Name der Währung
- Wie stark der Glückswurf ausfällt und wie selten er ist
