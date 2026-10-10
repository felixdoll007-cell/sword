# Wurfanimationen

Es gibt zwei Animationen: `ThrowMain` für den Wurf in der Wurfzone und die kürzere
`ThrowTraining` für die Trainingsbahnen.

## Wo sie liegen
- Im Ort (nicht im Repo): `ReplicatedStorage > Assets > ThrowAnimationRig`. Das ist eine einfache
  R15-Figur. In ihr liegt `AnimSaves` mit den beiden Animationen. Dort speichert auch der
  Animations-Editor von Studio.
- Hochgeladen bei Roblox: Die Nummern stehen in `src/shared/Config/Animations.luau` (`assetId`).
  Das Spiel benutzt nur die hochgeladenen Versionen. Die Figur im Ort ist die Werkstatt.
- `tools/animations/build_throw_animations.luau` ist die erste Fassung als Text. Dieses Skript
  baut die Animationen neu und **überschreibt dabei alles, was im Editor geändert wurde**.
  Nach der ersten Überarbeitung im Editor wird es nicht mehr ausgeführt.

## Was das Spiel abspielt
1. Steht eine Nummer in der Config, spielt jeder Client die hochgeladene Animation auf der eigenen
   Figur. Roblox zeigt sie von selbst allen anderen Spielern.
2. Steht keine Nummer drin (`assetId = 0`) und das Spiel läuft in Studio, wird die Animation aus
   `AnimSaves` als Vorschau benutzt, nur für die eigene Figur.
3. Sonst läuft der einfache Armschwung per Code (`src/client/ArmSwing.luau`).

## Was die Animationen bewegen
- `ThrowMain` bewegt den ganzen Körper.
- `ThrowTraining` bewegt nur Oberkörper, Kopf und rechten Arm. Hüfte, Beine und linker Arm sind
  nicht enthalten. Ein Körperteil, das in einer Animation enthalten ist, wird von ihr festgehalten,
  auch wenn es sich nicht dreht. So zog die erste Fassung bei jedem Trainingswurf die Beine zurück.
  Im Editor deshalb für Hüfte und Beine keine Schlüsselbilder in `ThrowTraining` anlegen.
- Die Priorität beider Animationen ist "Action". Daran erkennt das Spiel, dass ein Wurf läuft, und
  die Haltung der Waffe (`Config/HoldPose`) gibt den Arm frei. Die Priorität nicht ändern.

## Der Moment "Release"
In jeder Animation gibt es eine Markierung `Release`: der Moment, in dem die Waffe die Hand
verlässt. Dieselbe Zeit steht in der Config als `releaseSeconds`.
- Das Spiel richtet sich nach der Zahl in der Config, nicht nach der Markierung.
- Wird der Moment im Editor verschoben, muss `releaseSeconds` angepasst werden. Sonst verlässt die
  Waffe die Hand zu früh oder zu spät.
- Beim Hauptwurf rechnet der Server diese Zeit in den Flugplan und in die Wurfsperre ein.
- Die Trainings-Animation muss mit Flug in die Zeit zwischen zwei Trainingswürfen passen. Ein
  Test prüft das.
- Beim Loslassen sollte die Waffe ungefähr die Bahn entlang zeigen. Zeigt sie mehr als
  `launchMaxAngleDegrees` (Config/ThrowVisuals) daneben, startet die fliegende Waffe gerade
  ausgerichtet statt in der Richtung der Hand.

## Ansehen und ändern
1. Im Explorer `ThrowAnimationRig` aus `ReplicatedStorage > Assets` in den `Workspace` ziehen.
   Die Figur steht dann neben der Wurfzone.
2. Reiter Avatar, "Animation" öffnen (nicht den "Graph Editor"), die Figur `ThrowAnimationRig`
   anklicken.
3. Im Editor oben links über das Menü mit den drei Punkten "Laden" (Load) wählen: `ThrowMain`
   oder `ThrowTraining`.
4. Abspielen, ändern, über dasselbe Menü speichern (Save).
5. Die Figur danach wieder nach `ReplicatedStorage > Assets` ziehen. Sonst steht sie im Spiel
   herum und die Vorschau in Studio findet die Animationen nicht.

## Hochladen
- Im Editor über das Menü mit den drei Punkten "In Roblox veröffentlichen" (Publish to Roblox).
  Als Ersteller das Konto wählen, dem das Spiel gehört. Fremde Animationen spielt Roblox im Spiel
  nicht ab.
- Roblox zeigt danach eine Nummer. Diese Nummer kommt als `assetId` in die Config.
- Nach jeder Änderung neu hochladen. Das ergibt eine neue Nummer.
