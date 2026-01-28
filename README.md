# ImmoScout Email Automation

Eine lokale macOS App zur automatisierten Beantwortung von ImmobilienScout24-Anfragen.

## 📁 Struktur

- `src/` - Quellcode (AppleScript)
- `scripts/` - Build-Skripte
- `config/` - Vorlagen für die Konfiguration

## 📦 Installation (für End-Nutzer)

1. **Download**: Lade die aktuelle Version unter "Releases" rechts auf dieser Seite herunter (`ImmoScoutAutomation.zip`).
2. **Installieren**: Entpacke die Zip und ziehe die App in deinen **Programme** Ordner.
3. **Konfiguration**:
   Erstelle einmalig den Ordner für deine Einstellungen:
   ```bash
   mkdir -p "$HOME/Library/Application Support/ImmoScout-Automation"
   ```
   Lade die `config.template.txt` herunter, speichere sie in diesem Ordner als `config.txt` und trage deine Daten ein.
4. **Starten**: Einfach Doppelklick auf die App.

Die App prüft beim Start automatisch auf Updates und meldet sich, wenn eine neue Version verfügbar ist.

## ⚙️ Konfiguration (Wichtig!)

Die Konfiguration liegt sicher abgetrennt von der App unter:
`~/Library/Application Support/ImmoScout-Automation/config.txt`

**Du musst diese Datei einmalig anlegen:**

1. Terminal: Ordner erstellen
   ```bash
   mkdir -p "$HOME/Library/Application Support/ImmoScout-Automation"
   ```
2. Finder: `config/config.template.txt` in diesen neuen Ordner kopieren.
3. Datei in `config.txt` umbenennen und bearbeiten.

Ohne diese Datei startet die App nicht!

## 🔨 Manuelles Bauen

Wenn du nur die `.app` neu bauen willst ohne Installation:

```bash
./scripts/build.sh
```

Die App liegt dann im Ordner `build/`.
