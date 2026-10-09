# ProfileStore (fremder Code)

Unverändert übernommen. Nicht von Hand bearbeiten; für ein Update die neue Version
genauso prüfen und diese Notiz ersetzen.

- **Quelle:** https://github.com/MadStudioRoblox/ProfileStore (MAD STUDIO, loleris)
- **Version:** 1.0.3 (laut `wally.toml`)
- **Commit:** `45c9847cbcf1fc260369c50eb335aba7c35aecdd` (31.07.2025)
- **Datei:** `ProfileStore.luau`, 2242 Zeilen
- **SHA-256:** `ad43737203688b8e88cab34ebe8c483000c157e53bfb41e35f1b49ee89d0c95f`
- **Lizenz:** Apache 2.0, siehe `ProfileStore.LICENSE.txt`
- **Übernommen am:** 10.10.2026, geprüft von Claude, freigegeben vom Projektinhaber

## Prüfergebnis

- Kein `loadstring`, kein `getfenv`/`setfenv`, kein `require` auf Asset-IDs oder fremde Module
  (nur eine auskommentierte Beispielzeile).
- Kein Internetzugriff. `HttpService` wird nur für `GenerateGUID` benutzt.
- Benutzte Dienste: `DataStoreService`, `MessagingService` (Absprache zwischen Servern beim
  Session-Locking), `RunService`, `HttpService` (nur GUID).
- Kein Kick, kein Teleport, keine Käufe, kein Einfügen von Assets.
- `BindToClose`: wartet beim Herunterfahren, bis alle Spielstände gespeichert sind.
- Mock-Modus vorhanden: `ProfileStore.Mock` speichert nur im Arbeitsspeicher. Ohne
  API-Zugriff in Studio schaltet die Bibliothek von selbst auf einen Ersatzspeicher um.
- Hinweis: In Studio schreibt sie beim Start einmal den Schlüssel `____PS` in den Speicher
  `____PS`, um den Zugriff zu prüfen. Im veröffentlichten Spiel nicht.
- Hinweis: Unter einem Schlüssel liegende Daten, die nicht von ProfileStore stammen, werden
  durch einen leeren Spielstand ersetzt (Signal `OnOverwrite`).

## Einbindung

- Selene und StyLua prüfen diesen Ordner nicht (`selene.toml`, `.styluaignore`), damit die
  Datei unverändert bleiben kann.
- `.gitattributes` markiert den Ordner als `-text`, damit Git die Datei nie umwandelt.
