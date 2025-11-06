-- =====================================================
-- ImmobilienScout E-Mail Processor
-- Mit externer Config und Datum-Filter
-- =====================================================

property scriptVersion : "1.1.0"

-- ========================================
-- KONFIGURATION (wird aus config.txt geladen)
-- ========================================

property absenderEmail : ""
property templatesOrdner : ""
property absenderAdresse : ""
property antwortBetreff : ""
property echteDaten : false
property testEmail : ""
property verhalten : "save"
property originalLoeschen : false
property ignoriereEmailsVorTagen : 30

-- ========================================
-- AB HIER NICHTS ÄNDERN
-- ========================================

on run
	-- LADE CONFIG
	set configErfolg to my ladeConfig()
	if not configErfolg then
		return
	end if
	
	-- VALIDIERE KONFIGURATION
	set validierungErfolg to my validiereKonfiguration()
	if not validierungErfolg then
		return
	end if
	
	tell application "Mail"
		activate
		
		set verarbeiteteEmails to 0
		set fehlerAnzahl to 0
		set relevanteEmails to {}
		set geseheneBetreffe to {}
		
		-- Berechne Stichtag
		set stichtag to (current date) - (ignoriereEmailsVorTagen * days)
		
		-- Prüfe Templates-Ordner
		try
			set templateMailbox to mailbox templatesOrdner
		on error
			display dialog "❌ Templates-Ordner nicht gefunden!" & return & return & "Ordner: '" & templatesOrdner & "'" & return & "unter 'Auf meinem Mac'" buttons {"OK"}
			return
		end try
		
		-- Suche E-Mails von ImmobilienScout
		repeat with einAccount in accounts
			try
				set posteingang to mailbox "INBOX" of einAccount
				set gefundeneNachrichten to (messages of posteingang whose sender contains absenderEmail)
				
				repeat with eineNachricht in gefundeneNachrichten
					set emailDatum to date received of eineNachricht
					
					-- Nur E-Mails nach Stichtag
					if emailDatum ≥ stichtag then
						set derBetreff to subject of eineNachricht
						if derBetreff is not in geseheneBetreffe then
							set end of relevanteEmails to eineNachricht
							set end of geseheneBetreffe to derBetreff
						end if
					end if
				end repeat
			end try
		end repeat
		
		if (count of relevanteEmails) = 0 then
			display dialog "Keine neuen E-Mails gefunden." & return & return & "(Filter: Letzte " & ignoriereEmailsVorTagen & " Tage)" buttons {"OK"}
			return
		end if
		
		-- Bestätigung
		if verhalten is "send" then
			set aktion to "⚠️ E-MAILS WERDEN DIREKT GESENDET!"
		else
			set aktion to "Entwürfe werden erstellt"
		end if
		
		if not echteDaten then
			set empfaengerInfo to return & "🧪 TEST-MODUS: Alle E-Mails an " & testEmail
		else
			set empfaengerInfo to ""
		end if
		
		if originalLoeschen then
			set loeschenInfo to return & "🗑️ Originale werden gelöscht"
		else
			set loeschenInfo to ""
		end if
		
		set dialogText to "📨 " & (count of relevanteEmails) & " E-Mail(s) gefunden" & return & "(Letzte " & ignoriereEmailsVorTagen & " Tage)" & return & return & aktion & empfaengerInfo & loeschenInfo & return & return & "Fortfahren?"
		set antwort to display dialog dialogText buttons {"Abbrechen", "Ja"} default button "Ja"
		
		if button returned of antwort = "Ja" then
			repeat with eineEmail in relevanteEmails
				try
					set erfolg to my verarbeiteEmail(eineEmail, templateMailbox, verhalten, echteDaten)
					if erfolg then
						set verarbeiteteEmails to verarbeiteteEmails + 1
						if originalLoeschen then
							delete eineEmail
						end if
					else
						set fehlerAnzahl to fehlerAnzahl + 1
					end if
				on error
					set fehlerAnzahl to fehlerAnzahl + 1
				end try
			end repeat
			
			-- Erfolgsmeldung
			if verhalten is "save" then
				set meldung to "✅ " & verarbeiteteEmails & " Entwurf/Entwürfe erstellt!"
			else
				set meldung to "✅ " & verarbeiteteEmails & " E-Mail(s) gesendet!"
			end if
			
			if fehlerAnzahl > 0 then
				set meldung to meldung & return & "⚠️ " & fehlerAnzahl & " Fehler"
			end if
			
			if not echteDaten then
				set meldung to meldung & return & "🧪 TEST-MODUS aktiv"
			end if
			
			display dialog meldung buttons {"OK"}
		end if
		
	end tell
end run

-- ========================================
-- CONFIG LADEN
-- ========================================

on ladeConfig()
	try
		-- Suche config.txt im gleichen Ordner wie das Script
		set scriptPfad to path to me
		tell application "Finder"
			set scriptOrdner to container of scriptPfad as alias
		end tell
		
		set configPfad to ((scriptOrdner as text) & "config.txt")
		
		-- Prüfe ob Config existiert
		try
			set configDatei to open for access file configPfad
			set configInhalt to read configDatei
			close access configDatei
		on error
			try
				close access file configPfad
			end try
			-- Config existiert nicht → Erstelle Beispiel-Config
			my erstelleBeispielConfig(configPfad)
			return false
		end try
		
		-- Parse Config
		set AppleScript's text item delimiters to {return, linefeed}
		set zeilen to paragraphs of configInhalt
		
		repeat with eineZeile in zeilen
			set eineZeile to my trim(eineZeile)
			
			-- Überspringe Kommentare und leere Zeilen
			if eineZeile does not start with "#" and eineZeile does not start with "//" and (length of eineZeile) > 0 then
				
				if eineZeile contains "=" then
					set AppleScript's text item delimiters to "="
					set teile to text items of eineZeile
					if (count of teile) ≥ 2 then
						set schluessel to my trim(item 1 of teile)
						set wert to my trim(item 2 of teile)
						
						-- Setze Properties
						if schluessel is "absenderEmail" then
							set absenderEmail to wert
						else if schluessel is "templatesOrdner" then
							set templatesOrdner to wert
						else if schluessel is "absenderAdresse" then
							set absenderAdresse to wert
						else if schluessel is "antwortBetreff" then
							set antwortBetreff to wert
						else if schluessel is "echteDaten" then
							set echteDaten to (wert is "true")
						else if schluessel is "testEmail" then
							set testEmail to wert
						else if schluessel is "verhalten" then
							set verhalten to wert
						else if schluessel is "originalLoeschen" then
							set originalLoeschen to (wert is "true")
						else if schluessel is "ignoriereEmailsVorTagen" then
							try
								set ignoriereEmailsVorTagen to wert as integer
							end try
						end if
					end if
					set AppleScript's text item delimiters to {return, linefeed}
				end if
			end if
		end repeat
		
		set AppleScript's text item delimiters to ""
		return true
		
	on error errMsg
		display dialog "❌ Fehler beim Laden der Config:" & return & return & errMsg buttons {"OK"}
		return false
	end try
end ladeConfig

on erstelleBeispielConfig(configPfad)
	set beispielConfig to "# ImmobilienScout E-Mail Processor - Konfiguration
# Format: schluessel=wert (ohne Leerzeichen um das =)

# 1. VON WELCHER E-MAIL KOMMEN DIE IMMOSCOUT-ANFRAGEN?
absenderEmail=nicolosi@wohnwert.im

# 2. NAME DES TEMPLATE-ORDNERS IN MAIL
templatesOrdner=ImmoScout Templates

# 3. DEINE ABSENDER-ADRESSE
absenderAdresse=andreas.diehl@gmail.com

# 4. BETREFF FÜR ANTWORTEN (Platzhalter: {REFERENZ_ID}, {SCOUT_ID}, etc.)
antwortBetreff=Ihre Anfrage zu Objekt {REFERENZ_ID}

# 5. TEST-MODUS (false = Test, true = Produktiv)
echteDaten=false

# 6. TEST-E-MAIL-ADRESSE (wird verwendet wenn echteDaten=false)
testEmail=andreas.diehl@gmail.com

# 7. VERHALTEN (save = Entwurf, send = Direkt senden)
verhalten=save

# 8. ORIGINALE LÖSCHEN? (false = Behalten, true = Löschen)
originalLoeschen=false

# 9. NUR E-MAILS DER LETZTEN X TAGE BEARBEITEN
ignoriereEmailsVorTagen=30
"
	
	try
		set configDatei to open for access file configPfad with write permission
		set eof configDatei to 0
		write beispielConfig to configDatei
		close access configDatei
		
		display dialog "⚙️ Config-Datei erstellt!" & return & return & "Bitte bearbeite:" & return & "config.txt" & return & return & "im gleichen Ordner wie das Script." & return & return & "Danach Script neu starten." buttons {"Config öffnen"} default button "Config öffnen"
		
		tell application "TextEdit"
			activate
			open file configPfad
		end tell
		
	on error
		try
			close access file configPfad
		end try
		display dialog "❌ Konnte config.txt nicht erstellen!" buttons {"OK"}
	end try
end erstelleBeispielConfig

-- ========================================
-- E-MAIL VALIDIERUNG
-- ========================================

on validiereEmail(emailAdresse)
	if emailAdresse is "" then
		return false
	end if
	
	if emailAdresse does not contain "@" then
		return false
	end if
	
	set AppleScript's text item delimiters to "@"
	set teile to text items of emailAdresse
	set AppleScript's text item delimiters to ""
	
	if (count of teile) is not 2 then
		return false
	end if
	
	set lokalerTeil to item 1 of teile
	set domainTeil to item 2 of teile
	
	if (length of lokalerTeil) < 1 or (length of domainTeil) < 3 then
		return false
	end if
	
	if domainTeil does not contain "." then
		return false
	end if
	
	if domainTeil starts with "." or domainTeil ends with "." then
		return false
	end if
	
	return true
end validiereEmail

on validiereKonfiguration()
	set fehlerListe to {}
	
	if not my validiereEmail(absenderEmail) then
		set end of fehlerListe to "❌ absenderEmail: '" & absenderEmail & "'"
	end if
	
	if not my validiereEmail(absenderAdresse) then
		set end of fehlerListe to "❌ absenderAdresse: '" & absenderAdresse & "'"
	end if
	
	if not my validiereEmail(testEmail) then
		set end of fehlerListe to "❌ testEmail: '" & testEmail & "'"
	end if
	
	if verhalten is not "save" and verhalten is not "send" then
		set end of fehlerListe to "❌ verhalten muss 'save' oder 'send' sein"
	end if
	
	if (count of fehlerListe) > 0 then
		set AppleScript's text item delimiters to return
		set fehlerText to fehlerListe as string
		set AppleScript's text item delimiters to ""
		
		display dialog "❌ Ungültige Werte in config.txt:" & return & return & fehlerText buttons {"OK"}
		return false
	end if
	
	return true
end validiereKonfiguration

-- ========================================
-- E-MAIL VERARBEITUNG
-- ========================================

on verarbeiteEmail(dieEmail, templateMailbox, verhalten, echteDaten)
	tell application "Mail"
		set emailInhalt to content of dieEmail
		set emailAbsender to extract address from sender of dieEmail
		set originalBetreff to subject of dieEmail
		
		-- Extrahiere Daten
		set scoutID to my extrahiereScoutID(emailInhalt)
		set titel to my extrahiereTitel(emailInhalt)
		set referenzID to my extrahiereReferenzID(emailInhalt, originalBetreff)
		set anrede to my extrahiereNaechsteZeile(emailInhalt, "Anrede:")
		set vorname to my extrahiereNaechsteZeile(emailInhalt, "Vorname:")
		set nachname to my extrahiereNaechsteZeile(emailInhalt, "Nachname:")
		set interessentEmail to my extrahiereNaechsteZeile(emailInhalt, "E-Mail:")
		set nachricht to my extrahiereNachricht(emailInhalt)
		
		-- Empfänger bestimmen
		if echteDaten then
			if not my validiereEmail(interessentEmail) then
				display dialog "⚠️ Ungültige E-Mail: '" & interessentEmail & "'" & return & "Wird übersprungen." buttons {"OK"}
				return false
			end if
			set empfaengerEmail to interessentEmail
		else
			set empfaengerEmail to testEmail
		end if
		
		-- Finde Template
		set templateNachricht to my findeTemplate(templateMailbox, scoutID)
		
		if templateNachricht is missing value then
			set alleTemplates to messages of templateMailbox
			set templateListe to ""
			repeat with einTemplate in alleTemplates
				set templateListe to templateListe & "  • " & (subject of einTemplate) & return
			end repeat
			
			display dialog "❌ Kein Template gefunden!" & return & return & "Scout-ID: " & scoutID & return & return & "Verfügbare:" & return & templateListe buttons {"OK"}
			return false
		end if
		
		set templateBody to content of templateNachricht
		
		-- Ersetze Platzhalter
		set neuerBetreff to my ersetzePlatzhalter(antwortBetreff, scoutID, titel, referenzID, anrede, vorname, nachname, interessentEmail, nachricht)
		set neuerBody to my ersetzePlatzhalter(templateBody, scoutID, titel, referenzID, anrede, vorname, nachname, interessentEmail, nachricht)
		
		-- Erstelle Entwurf
		try
			set neuerEntwurf to make new outgoing message with properties {subject:neuerBetreff, content:neuerBody, visible:false}
			
			tell neuerEntwurf
				make new to recipient at end of to recipients with properties {address:empfaengerEmail}
				set sender to absenderAdresse
			end tell
			
			if verhalten is "send" then
				send neuerEntwurf
			end if
			
			return true
			
		on error errMsg
			display dialog "❌ Fehler:" & return & return & errMsg buttons {"OK"}
			return false
		end try
		
	end tell
end verarbeiteEmail

-- ========================================
-- HILFSFUNKTIONEN
-- ========================================

on findeTemplate(templateMailbox, scoutID)
	tell application "Mail"
		set alleTemplates to messages of templateMailbox
		
		if scoutID is not "" then
			repeat with einTemplate in alleTemplates
				if (subject of einTemplate) is scoutID then
					return einTemplate
				end if
			end repeat
		end if
		
		repeat with einTemplate in alleTemplates
			if (subject of einTemplate) is "default" then
				return einTemplate
			end if
		end repeat
		
	end tell
	return missing value
end findeTemplate

on extrahiereScoutID(inhalt)
	if inhalt contains "Scout-ID:" then
		try
			set AppleScript's text item delimiters to "Scout-ID:"
			set teile to text items of inhalt
			if (count of teile) > 1 then
				set nachLabel to item 2 of teile
				set scoutID to ""
				repeat with i from 1 to (length of nachLabel)
					set zeichen to character i of nachLabel
					if zeichen is in "0123456789" then
						set scoutID to scoutID & zeichen
					else if (length of scoutID) > 7 then
						exit repeat
					end if
				end repeat
				set AppleScript's text item delimiters to ""
				if (length of scoutID) > 7 then
					return scoutID
				end if
			end if
		end try
		set AppleScript's text item delimiters to ""
	end if
	return ""
end extrahiereScoutID

on extrahiereTitel(inhalt)
	try
		set AppleScript's text item delimiters to {return, linefeed}
		set zeilen to paragraphs of inhalt
		
		repeat with eineZeile in zeilen
			set eineZeile to my trim(eineZeile)
			if ((eineZeile contains "Zimmer" or eineZeile contains "Wohnung" or eineZeile contains "Neubau") and not (eineZeile contains "Scout-ID") and not (eineZeile contains "Zimmer:") and (length of eineZeile) > 20 and (length of eineZeile) < 200) then
				set AppleScript's text item delimiters to ""
				return eineZeile
			end if
		end repeat
		set AppleScript's text item delimiters to ""
	end try
	return ""
end extrahiereTitel

on extrahiereReferenzID(inhalt, betreff)
	if betreff contains "Objekt" then
		try
			set AppleScript's text item delimiters to "Objekt"
			set teile to text items of betreff
			if (count of teile) > 1 then
				set nachObjekt to item 2 of teile
				set AppleScript's text item delimiters to ""
				return my trim(nachObjekt)
			end if
		end try
		set AppleScript's text item delimiters to ""
	end if
	
	if inhalt contains "Immobilie" then
		try
			set AppleScript's text item delimiters to "Immobilie"
			set teile to text items of inhalt
			if (count of teile) > 1 then
				set nachImmobilie to item 2 of teile
				set AppleScript's text item delimiters to {return, linefeed}
				set zeilen to text items of nachImmobilie
				if (count of zeilen) > 0 then
					set AppleScript's text item delimiters to ""
					return my trim(item 1 of zeilen)
				end if
			end if
		end try
		set AppleScript's text item delimiters to ""
	end if
	
	return ""
end extrahiereReferenzID

on extrahiereNaechsteZeile(inhalt, labelText)
	if inhalt contains labelText then
		try
			set AppleScript's text item delimiters to labelText
			set teile to text items of inhalt
			if (count of teile) > 1 then
				set nachLabel to item 2 of teile
				set AppleScript's text item delimiters to {return, linefeed}
				set zeilen to text items of nachLabel
				
				repeat with eineZeile in zeilen
					set eineZeile to my trim(eineZeile)
					if (length of eineZeile) > 0 and (length of eineZeile) < 100 then
						set AppleScript's text item delimiters to ""
						return eineZeile
					end if
				end repeat
			end if
		end try
		set AppleScript's text item delimiters to ""
	end if
	return ""
end extrahiereNaechsteZeile

on ersetzePlatzhalter(vorlage, scoutID, titel, referenzID, anrede, vorname, nachname, email, nachricht)
	set ergebnis to vorlage
	set ergebnis to my ersetzText(ergebnis, "{SCOUT_ID}", scoutID)
	set ergebnis to my ersetzText(ergebnis, "{TITEL}", titel)
	set ergebnis to my ersetzText(ergebnis, "{REFERENZ_ID}", referenzID)
	set ergebnis to my ersetzText(ergebnis, "{ANREDE}", anrede)
	set ergebnis to my ersetzText(ergebnis, "{VORNAME}", vorname)
	set ergebnis to my ersetzText(ergebnis, "{NACHNAME}", nachname)
	set ergebnis to my ersetzText(ergebnis, "{EMAIL}", email)
	set ergebnis to my ersetzText(ergebnis, "{NACHRICHT}", nachricht)
	return ergebnis
end ersetzePlatzhalter

on ersetzText(derText, suchText, ersatzText)
	set AppleScript's text item delimiters to suchText
	set teile to text items of derText
	set AppleScript's text item delimiters to ersatzText
	set neuerText to teile as string
	set AppleScript's text item delimiters to ""
	return neuerText
end ersetzText

on extrahiereNachricht(inhalt)
	set nachNachricht to ""
	set nachrichtGefunden to false
	
	if inhalt contains "Nachricht Ihrer Interessent:innen" then
		set AppleScript's text item delimiters to "Nachricht Ihrer Interessent:innen"
		set teile to text items of inhalt
		if (count of teile) > 1 then
			set nachNachricht to item 2 of teile
			set nachrichtGefunden to true
		end if
		set AppleScript's text item delimiters to ""
	end if
	
	if not nachrichtGefunden and inhalt contains "Nachricht Ihrer Interessent" then
		set AppleScript's text item delimiters to "Nachricht Ihrer Interessent"
		set teile to text items of inhalt
		if (count of teile) > 1 then
			set nachNachricht to item 2 of teile
			set nachrichtGefunden to true
		end if
		set AppleScript's text item delimiters to ""
	end if
	
	if not nachrichtGefunden and inhalt contains "Nachricht" then
		set AppleScript's text item delimiters to "Nachricht"
		set teile to text items of inhalt
		if (count of teile) > 1 then
			set nachNachricht to item 2 of teile
			set nachrichtGefunden to true
		end if
		set AppleScript's text item delimiters to ""
	end if
	
	if not nachrichtGefunden then
		return ""
	end if
	
	set AppleScript's text item delimiters to {return, linefeed}
	set zeilen to text items of nachNachricht
	
	set nachrichtText to ""
	set textBegonnen to false
	
	repeat with eineZeile in zeilen
		set eineZeile to my trim(eineZeile)
		
		if not textBegonnen then
			if (length of eineZeile) > 15 and not (eineZeile contains "Von:") and not (eineZeile contains "Betreff:") and not (eineZeile contains "Datum:") and not (eineZeile contains "Nachrichtenverlauf") then
				set textBegonnen to true
			end if
		end if
		
		if textBegonnen then
			if eineZeile contains "Mit freundlichen Grüßen" or eineZeile contains "Mit freundlichen Gr" or eineZeile contains "Beste Grüße" or eineZeile contains "Viele Grüße" or eineZeile contains "Nachrichtenverlauf" then
				if nachrichtText is not "" and (eineZeile contains "Mit freundlichen" or eineZeile contains "Beste Grüße" or eineZeile contains "Viele Grüße") then
					set nachrichtText to nachrichtText & return & return & eineZeile
				end if
				exit repeat
			end if
			
			if (length of eineZeile) > 0 then
				if nachrichtText is not "" then
					set nachrichtText to nachrichtText & return
				end if
				set nachrichtText to nachrichtText & eineZeile
			end if
		end if
	end repeat
	
	set AppleScript's text item delimiters to ""
	return my trim(nachrichtText)
end extrahiereNachricht

on trim(derText)
	if derText = "" then
		return ""
	end if
	
	set derText to derText as string
	
	repeat while derText begins with " " or derText begins with tab or derText begins with ":" or derText begins with return or derText begins with linefeed
		if (length of derText) > 1 then
			set derText to text 2 thru -1 of derText
		else
			return ""
		end if
	end repeat
	
	repeat while derText ends with " " or derText ends with tab or derText ends with return or derText ends with linefeed
		if (length of derText) > 1 then
			set derText to text 1 thru -2 of derText
		else
			return ""
		end if
	end repeat
	
	return derText
end trim
