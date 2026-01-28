# ImmoScout Email Automation

Eine lokale macOS App zur automatisierten Beantwortung von ImmobilienScout24-Anfragen.

## 📁 Struktur

- `src/` - Quellcode (AppleScript)
- `scripts/` - Build-Skripte
- `config/` - Vorlagen für die Konfiguration

## 🚀 Installation & Update

Einfach das Installations-Skript ausführen. Es baut die App und schiebt sie in den Programme-Ordner.

1. Terminal öffnen
2. Navigiere in diesen Ordner (`cd ~/Desktop/ImmoScout` oder wo auch immer er liegt)
3. Führe aus:
   ```bash
   ./install.sh
   ```

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
