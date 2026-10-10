# Schwert-Vorlage im Spiel (ember_greatsword)

Das Schwert, das im Spiel fliegt, ist eine Vorlage im Ort selbst:
`ReplicatedStorage.Assets.ember_greatsword`. Sie liegt **nicht** im Repo, weil ihre Meshes
hochgeladene Roblox-Assets sind. Sie bleibt nur erhalten, wenn der Ort in Studio auf Roblox
gespeichert wird. Rojo lässt sie in Ruhe (`$ignoreUnknownInstances` für ReplicatedStorage in
`default.project.json`).

Fehlt die Vorlage, baut der Client ein schlichtes graues Schwert und schreibt eine Warnung in
die Ausgabe. Das Spiel läuft dann trotzdem.

## Herkunft
- Original: `assets/ember-greatsword.glb` (19 Teile, 1.680 Dreiecke)
- Für Roblox vorbereitet mit `tools/prepare_greatsword.py`: `assets/ember-greatsword-roblox.glb`
  (5 Teile nach Material, 1.484 Dreiecke, 1,87 × 6,00 × 0,30 Studs, Nullpunkt in der Griffmitte)
- In Studio importiert am 10.10.2026 (3D importieren, Meshes nicht zusammengeführt, Einheit Stud)

## Die fünf Teile

| Teil | Mesh-Asset | Farbe | Material |
|---|---|---|---|
| dark_steel | rbxassetid://100447046097331 | 77, 82, 91 | Plastic |
| ornate_iron | rbxassetid://105483651690629 | 42, 38, 41 | Plastic |
| ember_glow | rbxassetid://80172884226947 | 255, 90, 30 | Neon |
| old_bronze | rbxassetid://84838777058042 | 140, 106, 60 | Plastic |
| grip_leather | rbxassetid://140354186994688 | 43, 27, 21 | Plastic |

## So ist die Vorlage eingerichtet
- Ein Modell `ember_greatsword` mit den fünf MeshParts direkt darin, alle verankert,
  `CanCollide`, `CanTouch` und `CanQuery` aus, `Massless` an.
- `PrimaryPart` ist `dark_steel`. Dessen `PivotOffset` legt den Drehpunkt des Modells an die
  **Klingenspitze**: Ohne Drehung zeigt die Spitze nach -Z, die flache Seite der Klinge nach oben.
  Das ist die Vereinbarung, mit der `src/client/SwordView.luau` jedes Schwert bewegt.

## Vorlage neu anlegen, falls sie verloren geht
1. `assets/ember-greatsword-roblox.glb` in Studio importieren (Meshes nicht zusammenführen,
   Einheit Stud). Das lädt die fünf Meshes erneut hoch; sie bekommen neue Asset-Nummern.
2. Farben und Material wie in der Tabelle setzen.
3. Die fünf MeshParts in ein Modell `ember_greatsword` unter `ReplicatedStorage.Assets` legen,
   `PrimaryPart` und Drehpunkt wie oben einrichten.
4. Den Ort auf Roblox speichern.
