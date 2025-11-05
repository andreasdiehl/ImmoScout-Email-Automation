# ImmobilienScout24 E-Mail Automation

Automatische Antworten auf ImmobilienScout24-Anfragen mit personalisierten Templates.

## 🚀 Quick Start (5 Minuten Setup)

### 1️⃣ Script herunterladen
- Gehe zu: [Script.applescript](https://github.com/andreasdiehl/ImmoScout-Email-Automation/blob/main/Script.applescript)
- Klicke **"Raw"** (oben rechts)
![Immoscout RAW](https://github.com/user-attachments/assets/7e53ef06-4cf8-4cf2-8ed5-909db561ac3e)

- **⌘S** → Speichern als `ImmobilienScout.applescript`
- Speichere es z.B. in `Dokumente/Scripts/`

### 2️⃣ Script konfigurieren
Öffne das Script im **Script-Editor** und passe **Zeilen 24-51** an:

```applescript
property absenderEmail : "deine@immoscout-email.de"      -- Von welcher Adresse kommen die Anfragen?
property templatesOrdner : "ImmoScout Templates"          -- Name des Template-Ordners in Mail
property absenderAdresse : "dein@email.de"               -- Deine Absender-Adresse
property testEmail : "dein@email.de"                     -- Für Test-Modus
```

**Speichern:** ⌘S

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

**Das war's!** ⏱️ Dauert 30 Sekunden.

## ⚙️ Einstellungen

### Test-Modus (Standard)
```applescript
property echteDaten : false  -- Alle E-Mails gehen an deine Test-Adresse
property verhalten : "save"   -- Erstellt nur Entwürfe
```
→ **Sicher zum Testen!** Keine echten E-Mails werden versendet.

### Produktiv-Modus
```applescript
property echteDaten : true   -- Echte Empfänger-Adressen verwenden
property verhalten : "save"   -- Weiterhin als Entwurf (empfohlen)
```
→ Entwürfe gehen an echte Interessenten, aber du prüfst sie noch.

### Voll-Automatisch (Vorsicht!)
```applescript
property echteDaten : true
property verhalten : "send"   -- Direkt versenden!
```
→ ⚠️ E-Mails werden **sofort versendet** ohne Prüfung!

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

## 🔄 Updates

### Neue Version installieren:
1. Lade neue Version von GitHub
2. **Kopiere deine Config** (Zeilen 24-51) aus dem alten Script
3. **Füge sie in das neue Script** ein
4. Speichern & fertig!

Deine Templates bleiben unverändert! ✅

## 💡 Best Practices

### Template-Strategie
- ✅ **Ein `default` Template** für Standard-Anfragen
- ✅ **Spezielle Templates** nur für besondere Objekte
- ✅ **Persönlich bleiben:** Nutze `{NACHRICHT}` um auf Fragen einzugehen

### Workflow-Empfehlung
- **Woche 1-2:** Test-Modus, alle Entwürfe prüfen
- **Ab Woche 3:** Produktiv-Modus, Entwürfe schnell durchgehen
- **Optional:** Vertrauenswürdige Templates auf Direktversand umstellen

### Zeitsparend
- Morgens einmal Script starten: 30 Sekunden
- Entwürfe durchsehen: 2 Minuten
- **Zeitersparnis:** ~20 Minuten pro Tag! ⏰

## 📋 Checkliste für den Start

- [ ] Script heruntergeladen & konfiguriert
- [ ] Templates-Ordner in Mail erstellt
- [ ] Mindestens ein `default` Template erstellt
- [ ] Test-Modus aktiv (echteDaten = false)
- [ ] Script einmal getestet mit Test-Anfrage
- [ ] Entwurf geprüft → Alles korrekt?
- [ ] Produktiv-Modus aktivieren
- [ ] Fertig! 🎉

## ❓ Support

Bei Fragen oder Problemen: Wende dich an deinen Programmierer.

---

**Version:** 1.0.0  
**Lizenz:** MIT  
**Hinweis:** Inoffizielles Tool, keine Verbindung zu ImmobilienScout24 GmbH
