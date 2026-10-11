# Deko-Vorlagen

Die Deko-Modelle liegen als Vorlagen in `ReplicatedStorage.Assets`. Sie leben **nur im Ort**,
nicht im Repo: Nach jeder Änderung an einer Vorlage muss der Ort in Studio gespeichert werden
(Strg+S). Rojo lässt diesen Ordner in Ruhe.

Das Spiel baut die Deko auf jedem Client aus diesen Vorlagen (`src/client/DecorView.luau`).
Wo welches Modell steht, rechnet `src/shared/Rules/Decor.luau`; alle Werte stehen in
`src/shared/Config/Ui.luau` (world.decor und der Eintrag `decor` jeder Zone).

## Vorlagen der Papier-Zone (importiert am 11.10.2026)

| Vorlage | Teile (Mesh-Namen) | Vorderseite | Bewegung |
|---|---|---|---|
| `paper_lantern` | Post, Lantern, Caps, Tassel, Glow | -X (dorthin hängt die Laterne) | Licht im Teil `Glow`, flackert leicht |
| `origami_crane` | Body, WingTips, Beak, Base, Rod | -X (Schnabel) | alles außer `Base` und `Rod` schwebt auf und ab |
| `paper_pinwheel` | Stick, BladesPink, BladesWhite, Hub | -Z (Rad) | `BladesPink`, `BladesWhite` und `Hub` drehen sich um die Mitte von `Hub` |

Die Farben wurden einmalig mit `tools/decor/prepare_paper_decor.luau` gesetzt (Form und Größe
unverändert). Das Skript hat außerdem alle Teile verankert und ihnen die Kollision genommen.

## Was eine neue Deko-Vorlage braucht
- Ein `Model` in `ReplicatedStorage.Assets`, dessen Drehpunkt (Pivot) unten in der Mitte der
  Standfläche liegt. Dorthin stellt das Spiel das Modell auf den Gehweg.
- Einen Eintrag in `Config/Ui` unter `world.decor.models` mit dem Namen der Vorlage und der
  Richtung ihrer Vorderseite. Die Vorderseite wird zur Bahn gedreht.
- Für eine Bewegung müssen die bewegten Teile eigene Meshes mit festen Namen sein; die Namen
  stehen im selben Eintrag. Passt die Aufteilung nicht, bleibt das Modell einfach still.
- Die Zone, in der sie stehen soll, nennt die Vorlage in ihrer Liste `decor.order`.

Fehlt eine Vorlage im Ort, lässt das Spiel diese Deko weg und schreibt eine Warnung in die
Ausgabe; alles andere läuft normal weiter.
