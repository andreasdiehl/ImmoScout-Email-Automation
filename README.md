# ImmoScout Email Automation

Eine AppleScript-Lösung zur automatisierten Beantwortung von ImmobilienScout24-Anfragen, optimiert für die Verteilung via **iCloud Drive**.

## 📁 Projekt-Struktur

```
ImmoScout-Automation/
├── ImmoScout.app              # Die exportierte App (Produktiv)
├── src/
│   └── main.applescript      # Der Quellcode (Development)
├── config/
│   ├── config.template.txt  # Vorlage für neue Nutzer
│   └── {username}.txt       # Benutzerspezifische Konfiguration
└── logs/
    └── {username}/          # Benutzerspezifische Log-Dateien
```

## 🚀 Verteilung via iCloud Drive

Dieses Tool ist für die Zusammenarbeit über einen gemeinsamen iCloud-Ordner konzipiert.

### 1. Setup (für Administratoren)

- Erstelle einen Ordner `ImmoScout-Automation` auf deinem iCloud Drive.
- Exportiere das Script aus dem Script Editor als **Programm** (`ImmoScout.app`) in diesen Ordner.
- Erstelle den Unterordner `config` und lege dort für jeden Nutzer eine Datei `username.txt` an (wobei `username` der macOS-Login ist).
- Teile den Hauptordner (`ImmoScout-Automation`) via iCloud-Freigabe mit den Kollegen.

### 2. Konfiguration

Jeder Nutzer benötigt eine eigene Konfigurationsdatei im `config`-Ordner. Das Script erkennt den Nutzer automatisch.
Beispiel für `andreas.txt`:

```ini
absenderEmail = ...
templatesOrdner = ImmoScout Templates
echteDaten = true
verhalten = save
```

## 🛠️ Entwicklung

### Lokale Entwicklung

1. Klone das Repository.
2. Erstelle deine Config unter `config/$(whoami).txt`.
3. Öffne `src/main.applescript` im Script Editor oder führe es via Terminal aus:
   ```bash
   osascript src/main.applescript
   ```

### Logs & Fehlerbehebung

Logs werden automatisch im Ordner `logs/{username}/` erstellt. So kann der Administrator bei Problemen direkt in die Logs der Kollegen schauen, da diese ebenfalls über iCloud synchronisiert werden.

## 📝 Features

- **Message-ID Deduplizierung:** Verhindert doppelte Entwürfe, auch bei mehreren Mail-Accounts.
- **Automatisches Cleanup:** Logs älter als 30 Tage werden automatisch gelöscht.
- **Sicherheits-Check:** Zeigt vor der Verarbeitung eine Zusammenfassung der Einstellungen an.
