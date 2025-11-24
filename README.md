# ImmobilienScout24 E-Mail Automation

Dieses Script ist für Apple User die mit Mac Mail arbeiten. Das Script bereitet automatisch Antworten auf ImmobilienScout24-Anfragen mit personalisierten Templates vor bzw. sendet diese direkt ab.

### 1️⃣ Script herunterladen oder aktualisieren
- Gehe zu: [Script.applescript](https://github.com/andreasdiehl/ImmoScout-Email-Automation/blob/main/Script.applescript)
- Klick **"Download"** (oben rechts)
![Donwload Script](https://github.com/user-attachments/assets/39390e42-fba4-4d4f-82df-34c60018eced)
- Richte einen Ordner auf dem Rechner ein (egal wo) z.B. in `Dokumente/Scripts/ und lege das Script dort ab bzw. ersetze ein bestehendes Script ersatzlos

### 2️⃣ Config herunterladen & konfigurieren
- Damit das Script arbeiten kann brauchst Du eine Config Datei 👉 bitte kontaktiere mich dafür
- Öffne die Config Datei in einem beliebigen Text Editor (Doppelklick oder rechte Maustaste "öffnen mit")
- Passe die Werte an wie gewünscht an
- **Speichern:** ⌘S die Config Script mit dem Namen config.txt nach deinen Anpassungen
- Lege die config.txt in den gleichen Ordner wie das Script

### 3️⃣ Templates-Ordner erstellen
1. Öffne **Mail**
2. Suche in der linken Sidebar die Option "Auf meinem Mac"
3. Erstelle eine neuen Ordner / Mailbox mit dem Namen `ImmoScout Templates` (oder wie in Config angegeben)

![neue mailbox](https://github.com/user-attachments/assets/288ea086-596e-409b-b1d5-55cf580e48ea)


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
5. Script macht seine und deine Arbeit
✅ Entwürfe sind im **Entwürfe-Ordner** in Mail oder sind versendet
✅ Eingehende Nachrichten wurden sofern konfiguriert gelöscht

## ❌ Troubleshooting

Hier ein paar gängige Fehlermeldungen und Ursachen.

### "Templates-Ordner nicht gefunden"
- Ordner muss unter **"Auf meinem Mac"** liegen (nicht in einem E-Mail-Account)
- Name muss exakt übereinstimmen mit `templatesOrdner` in Config

### "Kein passendes Template gefunden"
- Erstelle ein Template mit Betreff `default` als Fallback
- Oder erstelle ein spezifisches Template mit der Scout-ID

### "Ungültige E-Mail-Adresse"
- Prüfe die Config auf ordentliche E-Mail Formate
- Format: `name@domain.de`

### Nachricht wird nicht korrekt extrahiert
- Das Script sucht nach "Nachricht Ihrer Interessent:innen"
- Falls ImmobilienScout das Format ändert: Melde es dem Programmierer

---

**Lizenz:** MIT  
**Hinweis:** Inoffizielles Tool, keine Verbindung zu ImmobilienScout24
