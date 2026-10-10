# Waffen-Vorlagen im Spiel

Die Vorlagen liegen im Ort selbst unter `ReplicatedStorage.Assets`, nicht im Repo, weil ihre
Meshes hochgeladene Roblox-Assets sind. Sie bleiben nur erhalten, wenn der Ort in Studio auf
Roblox gespeichert wird. Rojo lässt sie in Ruhe (`$ignoreUnknownInstances` für
ReplicatedStorage in `default.project.json`).

Für das Glut-Schwert gibt es eine eigene Notiz: `ember-greatsword-roblox.NOTES.md`.

## Gemeinsame Einrichtung aller Vorlagen
- Ein Modell mit den MeshParts direkt darin, alle verankert, `CanCollide`, `CanTouch` und
  `CanQuery` aus, `Massless` an, Material Plastic.
- `PrimaryPart` ist das längste Teil. Dessen `PivotOffset` legt den Drehpunkt des Modells an die
  **Spitze**: Ohne Drehung zeigt die Spitze nach -Z, die flache Seite nach oben.
  Das ist die Vereinbarung, mit der `src/client/SwordView.luau` jede Waffe bewegt.
- Die Farben stammen aus den Materialien der Dateien, umgerechnet von "linear" in normale
  Bildschirmfarben (wie beim Glut-Schwert).

## Importiert am 10.10.2026 (3D importieren, Meshes nicht zusammengeführt)

### wooden_sword (Datei `training-sword.glb`, im Import hieß das Modell `training_sword`)
Größe 0,90 × 4,00 × 0,35 Studs, Spitze 3,34 über der Griffmitte.

| Teil | Mesh-Asset | Farbe |
|---|---|---|
| light_wood | rbxassetid://120993282527287 | 207, 168, 117 |
| dark_wood | rbxassetid://114282704677603 | 107, 69, 41 |
| cloth_wrap | rbxassetid://137551304842444 | 125, 70, 54 |

### iron_dagger (Datei `iron-dagger.glb`)
Größe 0,56 × 2,50 × 0,24 Studs, Spitze 2,00 über der Griffmitte.

| Teil | Mesh-Asset | Farbe |
|---|---|---|
| iron | rbxassetid://133152180595143 | 144, 149, 160 |
| dark_iron | rbxassetid://136207886450610 | 74, 77, 84 |
| leather | rbxassetid://75755536010462 | 42, 24, 16 |

### battle_axe (Datei `battle-axe.glb`)
Größe 1,30 × 5,14 × 0,23 Studs, Spitze 4,14 über der Griffmitte.

| Teil | Mesh-Asset | Farbe |
|---|---|---|
| steel | rbxassetid://95078754373664 | 163, 168, 178 |
| dark_iron | rbxassetid://114564699744063 | 74, 77, 84 |
| haft_wood | rbxassetid://95464016108713 | 138, 94, 59 |
| cloth_wrap | rbxassetid://123251319820774 | 125, 70, 54 |

## Zuordnung im Waffen-Shop

Die Zuordnung steht in `src/shared/Config/Weapons.luau` (Feld `template`).

| Waffe im Shop | Vorlage |
|---|---|
| Wooden Sword | wooden_sword |
| Iron Dagger | iron_dagger |
| Battle Axe | battle_axe |
| Ember Greatsword | ember_greatsword |
| Void Blade | keine, grauer Platzhalter |

## Ein neues Modell einbinden
1. Modell in Studio importieren (Meshes nicht zusammenführen), Farben setzen.
2. Als Modell unter `ReplicatedStorage.Assets` ablegen und wie oben einrichten
   (`PrimaryPart`, Drehpunkt an der Spitze).
3. Beim Eintrag der Waffe in `Config/Weapons.luau` `template = "<Name des Modells>"` setzen.
4. Den Ort auf Roblox speichern.
