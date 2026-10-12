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

## Vorlagen der Trainingsbahn 1x (importiert am 11.10.2026)

Diese beiden baut der Server (`src/server/TrainingLook.luau`), sie stehen still.

| Vorlage | Teile (Mesh-Namen) | Vorderseite | Wo |
|---|---|---|---|
| `straw_target` | Straw, RingsRed, RingsWhite, Stand, Rope | -Z (Ringe), 3 Studs vor dem Standpunkt | am Ende des Wurfstreifens, zum Spieler gedreht |
| `hay_bale` | Hay, HayDark, Rope | egal | auf dem Themen-Boden, Liste `props` im Thema |

Die Farben wurden einmalig mit `tools/decor/prepare_paper_decor.luau` gesetzt (Form und Größe
unverändert). Das Skript hat außerdem alle Teile verankert und ihnen die Kollision genommen.

## Vorlagen der Pets (importiert am 11.10.2026)

Pets und das Ei baut jeder Client selbst (`src/client/Ui/PetPreview.luau`): als Bild in der
Oberfläche, als Begleiter hinter der Figur und als Ei auf dem Ei-Stand. Welches Pet welche
Vorlage nutzt, steht in `src/shared/Config/Pets.luau`.

| Vorlage | Teile (Mesh-Namen) | Farben |
|---|---|---|
| `pet_bunny` | Body, Accent, Nose, Eyes, EyeShine | weiß, rosa, rosa |
| `pet_fox` | Body, Accent, Nose, Eyes, EyeShine | orange, weiß, dunkelbraun |
| `pet_panda` | Body, Accent, Nose, Eyes, EyeShine | weiß, schwarz, schwarz |
| `pet_dragon` | Body, Accent, Nose, Eyes, EyeShine | lila, helles Türkis, gold |
| `pet_phoenix` | Body, Glow, Nose, Eyes, EyeShine | rot-orange, gelb (Neon), gold |
| `crystal_egg` | Shell, Band, Stars, Glow | kräftiges Türkis, gold, helles Mintgrün, helles Türkis (Neon) |

Bei allen Pets sind `Eyes` schwarz und `EyeShine` weiß. Das Mesh `Nose` ist je nach Pet etwas
anderes: beim Fuchs der dunkle Akzent, beim Drachen Hörner und Zacken, beim Phönix der
Schnabel. Vorderseite ist bei allen -Z, der Drehpunkt liegt in der Körpermitte.

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
