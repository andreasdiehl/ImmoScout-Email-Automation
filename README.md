# ImmobilienScout24 E-Mail Automation

Automatische Antworten auf ImmobilienScout24-Anfragen mit personalisierten Templates.

### 1️⃣ Script herunterladen oder aktualisieren
- Gehe zu: [Script.applescript](https://github.com/andreasdiehl/ImmoScout-Email-Automation/blob/main/Script.applescript)
- Klick **"Dowbload"** (oben rechts)
![Donwload Script](https://github.com/user-attachments/assets/39390e42-fba4-4d4f-82df-34c60018eced)
- Richte dir einen Ordner ein (egal wo) z.B. in `Dokumente/Scripts/ und lege das Script dort ab bzw. ersetze das alte Script ersatzlos

### 2️⃣ Script herunterladen & konfigurieren
- Gehe zu: [Script.applescript](https://github.com/andreasdiehl/ImmoScout-Email-Automation/blob/main/Script.applescript)
- Klick **"Dowbload"** (oben rechts)
- Öffne die Config Datei z.B. **Script-Editor** oder in einem beliebigen Text Editor (Doppelklick oder rechte Maustaste "öffnen mit")
- Passe die folegnden Wertean:

```applescript
property absenderEmail : "deine@immoscout-email.de"      -- Von welcher Adresse kommen die Anfragen?
property templatesOrdner : "ImmoScout Templates"         -- Name des Template-Ordners in Mail
property absenderAdresse : "dein@email.de"               -- Deine Absender-Adresse
property testEmail : "dein@email.de"                     -- Für Test-Modus
property echteDaten : true / false                       -- Alle E-Mails gehen an deine testEmail
property verhalten : save / send                         -- Erstellt nur Entwürfe (save) oder sendet die Nachricht direkt (send)
```
- **Speichern:** ⌘S die Config Script nach deinen Anpassungen und lege die Config in den gleichen Ordner wie das Script


### 3️⃣ Templates-Ordner erstellen
1. Öffne **Mail**
2. Rechtsklick auf **"Auf meinem Mac"** → **"Neuer Ordner"**
3. Name: `ImmoScout Templates` (oder wie in Config angegeben)

### 4️⃣ Templates erstellen

**Für jedes Objekt ein Template erstellen:**

**Variante A: Objekt-spezifisches Template**
- Neue E-Mail erstellen (⌘N)
- **Betreff:** Die Scout-ID deines Objekts (z.B. `162188779`)
- **Inhalt:** Deine Antwort-Vorlage (siehe Platzhalter unten)
- E-Mail in den Ordner `ImmoScout Templates` verschieben

**Variante B: Standard-Template (Fallback)**
- **Betreff:** `default`
- Gilt für alle Objekte ohne spezifisches Template

**Verfügbare Platzhalter:**
```
{SCOUT_ID}      → Scout-ID der Immobilie
{TITEL}         → Objekttitel
{REFERENZ_ID}   → Deine Referenz-ID
{ANREDE}        → Frau/Herr
{VORNAME}       → Vorname
{NACHNAME}      → Nachname
{EMAIL}         → E-Mail-Adresse
{NACHRICHT}     → Komplette Nachricht des Interessenten
```

**Beispiel-Template:**
```
Sehr geehrte(r) {ANREDE} {NACHNAME},

vielen Dank für Ihr Interesse an "{TITEL}" (Objekt: {REFERENZ_ID}).

Ihre Nachricht:
"{NACHRICHT}"

Gerne lade ich Sie zu einer Besichtigung ein. 
Bitte schlagen Sie mir 2-3 Wunschtermine vor.

Mit freundlichen Grüßen
Ihr Immobilien-Team
```

## 💼 Tägliche Verwendung

### So gehst du vor:
1. **Doppelklick** auf das Script
2. Script prüft deinen Posteingang nach neuen ImmobilienScout-Anfragen
3. Dialog: *"5 E-Mail(s) gefunden → Fortfahren?"*
4. **Klick "Ja"**
5. ✅ Entwürfe sind im **Entwürfe-Ordner** in Mail
6. Prüfe die Entwürfe und versende sie

## 🔧 Troubleshooting

### "Templates-Ordner nicht gefunden"
- Ordner muss unter **"Auf meinem Mac"** liegen (nicht in einem E-Mail-Account)
- Name muss exakt übereinstimmen mit `templatesOrdner` in Config

### "Kein passendes Template gefunden"
- Erstelle ein Template mit Betreff `default` als Fallback
- Oder erstelle ein spezifisches Template mit der Scout-ID

### "Ungültige E-Mail-Adresse"
- Prüfe die Config (Zeilen 24-51)
- Format: `name@domain.de`

### Nachricht wird nicht korrekt extrahiert
- Das Script sucht nach "Nachricht Ihrer Interessent:innen"
- Falls ImmobilienScout das Format ändert: Melde es dem Programmierer

---

**Version:** 1.0.0  
**Lizenz:** MIT  
**Hinweis:** Inoffizielles Tool, keine Verbindung zu ImmobilienScout24 GmbH
