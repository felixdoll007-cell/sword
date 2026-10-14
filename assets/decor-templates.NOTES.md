# Deko-Vorlagen

Die Deko-Modelle liegen als Vorlagen in `ReplicatedStorage.Assets`. Sie leben **nur im Ort**,
nicht im Repo: Nach jeder Änderung an einer Vorlage muss der Ort in Studio gespeichert werden
(Strg+S). Rojo lässt diesen Ordner in Ruhe.

Das Spiel baut die Deko auf jedem Client aus diesen Vorlagen (`src/client/DecorView.luau`).
Jedes Deko-Teil steht einzeln in einer Liste in `src/shared/Config/Ui.luau` (Eintrag `decor`
der Zone); `src/shared/Rules/Decor.luau` macht daraus Orte in der Welt. Die Modelle selbst und
ihre Bewegungen stehen unter `world.decor` in derselben Datei.

## Vorlagen der Papier-Zone (importiert am 11.10.2026)

| Vorlage | Teile (Mesh-Namen) | Vorderseite | Bewegung |
|---|---|---|---|
| `paper_lantern` | Post, Lantern, Caps, Tassel, Glow | -X (dorthin hängt die Laterne) | Licht im Teil `Glow`, flackert leicht |
| `origami_crane` | Body, WingTips, Beak, Base, Rod | -X (Schnabel) | alles außer `Base` und `Rod` schwebt auf und ab |
| `paper_pinwheel` | Stick, BladesPink, BladesWhite, Hub | -Z (Rad) | `BladesPink`, `BladesWhite` und `Hub` drehen sich um die Mitte von `Hub` |
| `cherry_tree` | Trunk, BlossomPink, BlossomLight, Mound | egal (rund) | keine, steht still |

## Vorlagen der Bambus-Zone (importiert am 13.10.2026)

| Vorlage | Datei | Dreiecke | Teile (Mesh-Namen) | Vorderseite | Bewegung |
|---|---|---|---|---|---|
| `bamboo_cluster` | `assets/bamboo-cluster.glb` | 1148 | Stalks, Nodes, Leaves, Mound | egal (rund) | `Leaves` wippt ganz leicht um seine eigene Mitte |
| `stone_lantern` | `assets/stone-lantern.glb` | 608 | Stone, StoneDark, Moss, Glow | egal | Licht im Teil `Glow`, flackert leicht |
| `taiko_drum` | `assets/taiko-drum.glb` | 868 | Body, Skin, Symbol, Studs, Stand, Sticks | +X (ein Trommelfell), Schlägel lehnen bei -Z | keine, steht still |
| `shishi_odoshi` | `assets/shishi-odoshi.glb` | 840 | Basin, Water, Posts, Rocker, Stream, Pebbles | -Z (Becken) | `Rocker` kippt um seine eigene Mitte nach vorn und zurück |

Farben: Bambus kräftiges Bambusgrün, Knoten dunkelgrün, Blätter frisches Hellgrün, Hügel
dunkelbraun. Laterne hellgrau und dunkleres Grau, Moos moosgrün, `Glow` warmgelb (Neon).
Trommel kräftiges Rot, Fell creme, Zeichen schwarz, Nieten gold, Gestell dunkelbraun, Schlägel
helles Holz. Wasserspiel: Becken grau, Pfosten und Rohr bambusgrün, Strahl helles Türkis,
Kiesel hellgrau; `Water` ist türkis, 30 % durchsichtig und spiegelt leicht (SmoothPlastic,
Reflectance 0,25). Das Skript `tools/decor/prepare_paper_decor.luau` setzt nur Farben und
Neon; die Werte für `Water` wurden von Hand dazu gesetzt.

Im Modell steht das Rohr des Wasserspiels in der Stellung "gießt aus": das offene, schräg
geschnittene Ende zeigt nach vorn (-Z, über dem Becken) und liegt 16 Grad unter der Waagerechten.
Das Spiel dreht es für die Ruhelage zurück, bis das offene Ende leicht nach oben zeigt, und
kippt es von dort nach vorn unten (Werte in `Config/Ui`, world.decor.models.shishi_odoshi.tip).

Die Vorlagen bleiben so groß wie modelliert. Im Spiel stehen Laterne, Trommel und Wasserspiel
1,8-mal so groß, Bambus 1,4-mal (`size` in `Config/Ui`, world.decor.models).

## Wand-Modell der Bambus-Zone (importiert am 13.10.2026)

| Vorlage | Datei | Dreiecke | Teile (Mesh-Namen) | Größe wie modelliert |
|---|---|---|---|---|
| `bamboo_wall` | `assets/bamboo-wall.glb` | 1464 | Stalks, Nodes, Rope, Beam | 21,2 x 12 x 3,6 Studs (Rohre allein 19,9 x 11,2 x 2,4) |

Farben: Stalks kräftiges Bambusgrün, Nodes dunkelgrün, Rope warmes Braun, Beam dunkelbraun.
Der Drehpunkt der Vorlage ist die Mitte ihres Fußes. Im Spiel wird sie gleichmäßig etwa
1,5-mal vergrößert, damit die Rohre die 30 Studs breite Wand ganz bedecken (Werte in
`Config/Ui`, world.lane.zones.Bamboo.wall.model).

## Vorlagen der Holz-Zone (importiert am 13.10.2026)

| Vorlage | Datei | Dreiecke | Teile (Mesh-Namen) | Vorderseite | Bewegung |
|---|---|---|---|---|---|
| `training_dummy` | `assets/training-dummy.glb` | 460 | Post, Arms, Frame, Cloth | -Z (Arme) | `Cloth` weht leicht um seine obere Kante |
| `weapon_rack` | `assets/weapon-rack.glb` | 1146 | Rack, Weapons, Grips, Roof | -Z | keine |
| `sake_barrels` | `assets/sake-barrels.glb` | 1180 | Straw, Ropes, Lids, LabelRed, LabelBlue, LabelYellow, Symbols | -Z (Etiketten) | keine |
| `ema_rack` | `assets/ema-rack.glb` | 634 | Frame, Plaques, Cords, Roof | -Z | `Plaques` schaukelt leicht um seine obere Kante |
| `wooden_wall` | `assets/wooden-wall.glb` | 1408 | Planks, Posts, Nails, Roof, Base | beide Seiten gleich | Wand-Modell, 30,8 x 16,4 x 2,6 Studs |

Farben: Puppe mit Pfosten und Armen in warmem hellem Holzbraun, Gestell dunkelbraun, Tuch
weiß. Waffenständer dunkelbraun, Waffen helles Holz, Griffe dunkelrot, Dach dunkles
Schiefergrau. Fässer strohgelb, Seile dunkelbraun, Deckel helles Holz, Etiketten rot, blau
und gelb, Zeichen weiß. Täfelchen-Gestell dunkelbraun, Täfelchen helles Holz, Schnüre rot,
Dach dunkelrot. Holzwand: Planken mittleres Holzbraun, Pfosten dunkelbraun, Nägel fast
schwarz, Dach schiefergrau, Sockel grau. Der Drehpunkt jeder Vorlage ist die Mitte ihres Fußes.

`Cloth` und `Plaques` sind je ein einziges Mesh: Es bewegt sich das ganze Tuch und alle
Täfelchen gemeinsam, nicht einzelne Enden oder einzelne Täfelchen.

## Vorlagen der Stein-Zone (importiert am 14.10.2026)

| Vorlage | Datei | Dreiecke | Teile (Mesh-Namen) | Vorderseite | Größe wie modelliert |
|---|---|---|---|---|---|
| `torii_gate` | `assets/torii-gate.glb` | 674 | Red, Black, Plaque | beide Seiten gleich | 26 x 20 x 3,3 Studs; Säulen bei 9 bis 12,2 Studs von der Mitte, unterer Balken ab 12,6 Studs Höhe |
| `komainu` | `assets/komainu.glb` | 1120 | Statue, Mane, Base, Moss, Mouth | -Z (Maul) | 4,1 x 6,9 x 4,1 |
| `bonsai` | `assets/bonsai.glb` | 950 | Trunk, Foliage, FoliageLight, Pot, Moss, Stand | -Z | 6,2 x 6,1 x 3,2 |
| `mossy_rocks` | `assets/mossy-rocks.glb` | 547 | Rock, RockDark, Moss, Grass | -Z (Gras) | 7,1 x 3,8 x 5,4 |
| `stone_wall` | `assets/stone-wall.glb` | 1428 | Stones, StonesDark, Gaps, Moss, Cap | beide Seiten gleich | 30 x 16,2 x 2 (Wand-Modell; im Spiel 1,03-mal, weil die Steine nur 29,2 breit sind) |

Farben: Torii zinnoberrot, schwarz, Tafel dunkelgrau. Löwe hellgrau, Mähne etwas dunkler,
Sockel dunkelgrau, Moos moosgrün, Maul dunkelrot. Bonsai: Stamm dunkelbraun, Laub kräftiges
Dunkelgrün und helles Grün, Topf kobaltblau, Moos moosgrün, Ständer grau. Moosfelsen mittleres
und dunkleres Grau, Moos moosgrün, Gras hellgrün. Steinmauer: Steine mittleres und dunkleres
Grau, Fugen fast schwarz, Moos moosgrün, Abdeckung hellgrau. Der Drehpunkt jeder Vorlage ist die
Mitte ihres Fußes.

## Vorlagen der Trainingsbahn 1x (importiert am 11.10.2026)

Diese beiden baut der Server (`src/server/TrainingLook.luau`), sie stehen still.

| Vorlage | Teile (Mesh-Namen) | Vorderseite | Wo |
|---|---|---|---|
| `straw_target` | Straw, RingsRed, RingsWhite, Stand, Rope | -Z (Ringe), 3 Studs vor dem Standpunkt | am Ende des Wurfstreifens, zum Spieler gedreht |
| `hay_bale` | Hay, HayDark, Rope | egal | auf dem Themen-Boden, Liste `props` im Thema |

Die Farben wurden einmalig mit `tools/decor/prepare_paper_decor.luau` gesetzt (Form und Größe
unverändert). Das Skript hat außerdem alle Teile verankert und ihnen die Kollision genommen.

## Vorlagen der Pets (zweite Fassung, importiert am 12.10.2026)

Pets und das Ei baut jeder Client selbst (`src/client/Ui/PetPreview.luau`): als Bild in der
Oberfläche, als Begleiter hinter der Figur und als Ei auf dem Ei-Stand. Welches Pet welche
Vorlage nutzt, steht in `src/shared/Config/Pets.luau`.

| Vorlage | Teile (Mesh-Namen) | Farben |
|---|---|---|
| `pet_bunny` | Body, Accent | weiß, rosa |
| `pet_fox` | Body, AccentWhite, AccentDark | kräftiges Orange, weiß, dunkelbraun |
| `pet_panda` | Body, Accent, AccentPink | weiß, schwarz, rosa |
| `pet_dragon` | Body, Accent, Gold | kräftiges Lila, helles Türkis, gold |
| `pet_phoenix` | Body, Glow, Gold | rot-orange, gelb (Neon), gold |
| `crystal_egg` | Shell, Band, Stars, Glow | kräftiges Türkis, gold, helles Mintgrün, helles Türkis (Neon) |

Alle Pets haben dazu große Augen aus drei Meshes: `EyeWhite` weiß, `Pupil` sehr dunkles Braun,
`EyeShine` weiß (Neon). Vorderseite ist bei allen -Z, der Drehpunkt liegt in der Körpermitte.
Die Dateien sind `assets/*-pet-v2.glb`. Die erste Fassung (`assets/*-pet.glb`, mit `Eyes` und
`Nose`) wurde am 12.10.2026 unter denselben Namen ersetzt und aus dem Ort gelöscht.

Das Ei am Stand und in der Schlüpf-Anzeige ist `crystal_egg` (importiert am 12.10.2026, Datei
`assets/crystal-egg.glb`, 3,1 x 4,1 x 2,9 Studs). Am Stand wird es als Ganzes vergrößert
(`Config/Ui`, world.eggStand.eggScale), die Vorlage selbst bleibt unverändert. Das alte Ei mit Nest (`pet_egg`)
wurde am 12.10.2026 aus dem Ort gelöscht; seine Datei `assets/pet-egg.glb` liegt weiter im Repo.

Fehlt eine Pet-Vorlage im Ort, zeigt das Spiel an ihrer Stelle eine graue Kugel.

## Was eine neue Deko-Vorlage braucht
- Ein `Model` in `ReplicatedStorage.Assets`, dessen Drehpunkt (Pivot) unten in der Mitte der
  Standfläche liegt. Dorthin stellt das Spiel das Modell auf die äußere Stufe des Gehwegs.
- Einen Eintrag in `Config/Ui` unter `world.decor.models` mit dem Namen der Vorlage und der
  Richtung ihrer Vorderseite. Die Vorderseite wird zur Bahn gedreht.
- Für eine Bewegung müssen die bewegten Teile eigene Meshes mit festen Namen sein; die Namen
  stehen im selben Eintrag. Passt die Aufteilung nicht, bleibt das Modell einfach still.
- Die Zone, in der sie stehen soll, führt jedes Teil in ihrer Liste `decor.pieces` auf: Modell,
  Seite, Abstand vom Anfang der Zone, Lage auf der äußeren Stufe, Drehung und Größe.

Fehlt eine Vorlage im Ort, lässt das Spiel diese Deko weg und schreibt eine Warnung in die
Ausgabe; alles andere läuft normal weiter.
