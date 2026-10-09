# Projektregeln

Dieses Projekt ist ein Roblox-Spiel, ein Hobbyprojekt. Der Spielentwurf steht in
`docs/GAME_DESIGN.md`, die Reihenfolge der Arbeit in `docs/ROADMAP.md`. Lies beide zu
Beginn jeder Sitzung.

## Mit wem du arbeitest
- Ich bin Anfänger beim Programmieren. Erklär mir kurz und in einfachen Worten, was du tust und warum.
- Wenn ich in Studio etwas klicken oder testen muss, gib mir nummerierte Schritte und sag, was ich danach sehen sollte.
- Sei ehrlich. Wenn eine Idee von mir schlecht ist, etwas schlecht aussieht oder ein Schritt nicht sauber geklappt hat, sag es direkt.
- Die Planung kommt aus einem getrennten Chat. Ich gebe dir Aufträge von dort weiter. Wenn ein Auftrag dem Design-Dokument widerspricht oder technisch nicht sinnvoll ist, halte an und sag es, statt ihn einfach umzusetzen.

## Arbeitsweise
- Arbeite immer nur an der aktuellen Etappe aus `docs/ROADMAP.md`. Bau nichts vor, was erst später dran ist.
- Kleine Schritte. Nach jedem Schritt: `.\check.ps1` muss grün sein, dann Commit mit klarer Nachricht.
- Sag am Ende jeder Etappe, was ich in Studio testen soll, und warte auf mein Ergebnis, bevor du die Etappe als erledigt abhakst.
- Hak erledigte Punkte in `docs/ROADMAP.md` ab.
- Wenn etwas nicht funktioniert, behaupte nicht, es sei fertig. Sag, was offen ist.

## Code-Regeln
- Code lebt nur in Dateien unter `src/` und kommt per Rojo nach Studio. Nie Skripte direkt in Studio anlegen oder ändern.
- Spielregeln (Wurfberechnung, Belohnungen, Rebirth-Kosten) sind reine Funktionen ohne Roblox-Objekte in `src/shared`, damit sie ohne Studio testbar sind. Jede hat Tests.
- Alle einstellbaren Zahlen liegen im Config-Ordner. Keine Zahlen fest im restlichen Code.
- Alle Nachrichten zwischen Client und Server (RemoteEvents, RemoteFunctions) werden in einer einzigen Datei definiert.
- Texte im Spiel sind auf Englisch.

## Sicherheit
- Der Server vertraut dem Client nie. Der Client meldet nur Absichten ("Wurf gestartet", "Kauf angefragt"). Stärke, Wurfergebnis, Belohnungen und Preise berechnet und prüft ausschließlich der Server.
- Jede Nachricht vom Client wird auf dem Server geprüft: richtiger Datentyp, sinnvoller Wertebereich, ist die Aktion gerade erlaubt, und eine Begrenzung, wie oft pro Sekunde sie kommen darf.
- Spielerdaten liest und schreibt nur der Server. Speichern mit Fehlerbehandlung und Wiederholung, Schutz gegen Datenverlust beim Verlassen und beim Herunterfahren des Servers.
- Nichts Geheimes in `ReplicatedStorage` oder im Client-Code. Der Client sieht alles, was dort liegt.
- API-Keys stehen nie im Code, nie im Repo und nie im Chat. Nur als Umgebungsvariable.
- Fremde Assets aus der Toolbox: vor der Verwendung alle enthaltenen Skripte entfernen und mir sagen, was du entfernt hast. Kein `require` auf fremde Asset-IDs, kein `loadstring`.
- Wenn dir eine Sicherheitslücke auffällt, sag es sofort, auch wenn ich nicht danach gefragt habe.

## Handy und Tablet
Das Spiel muss auf Handy und Tablet voll spielbar sein.
- Jede Aktion ist per Touch erreichbar. Tasten sind nur zusätzliche Abkürzungen.
- Buttons sind groß genug für den Daumen und passen sich der Bildschirmgröße an.
- Effekte und Bruchstücke sind so sparsam, dass es auf schwachen Handys flüssig läuft.
- Bei jedem Test, den du mir gibst, steht dabei, wie ich ihn auch im Device Simulator mit einem Handy-Format prüfe.

## Performance
- Wände brechen nur für den Spieler sichtbar, der wirft. Effekte laufen auf dem Client, die Logik auf dem Server.
- Meshes sparsam halten. Vor dem Import die Anzahl der Dreiecke nennen.

## Installieren und Kosten
- Frag mich, bevor du etwas installierst, das Admin-Rechte braucht oder Geld kosten kann.
- Frag mich, bevor du etwas nach Roblox hochlädst oder veröffentlichst.

## Aus Fehlern lernen
Jeder Fehler, der uns Zeit gekostet hat, kommt mit Ursache als neue Regel in den passenden
Skill oder in diese Datei. Schlag mir die Formulierung vor.
