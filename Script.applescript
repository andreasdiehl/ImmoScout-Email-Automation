-- =====================================================
-- ImmobilienScout E-Mail Processor mit Templates
-- Version mit E-Mail-Validierung und Auto-Update
-- =====================================================

-- VERSION & UPDATE
property scriptVersion : "1.0.1"
property githubRawURL : "https://raw.githubusercontent.com/andreasdiehl/ImmoScout-Email-Automation/main/Script.applescript"
property autoUpdateCheck : true -- false um Auto-Update zu deaktivieren

-- ========================================
-- KONFIGURATION:
-- ========================================
-- VERFÜGBARE VARIABLEN FÜR BETREFF UND BODY:
-- {SCOUT_ID}      - Scout-ID der Immobilie (z.B. 162188779)
-- {TITEL}         - Titel der Immobilie
-- {REFERENZ_ID}   - Ihre Referenz-ID (z.B. OMS 4-1-12)
-- {ANREDE}        - Anrede des Interessenten (Frau/Herr)
-- {VORNAME}       - Vorname des Interessenten
-- {NACHNAME}      - Nachname des Interessenten
-- {EMAIL}         - E-Mail des Interessenten
-- {NACHRICHT}     - Nachricht des Interessenten

-- 1. ABSENDER E-MAIL (die geprüft werden soll)
property absenderEmail : "nicolosi@wohnwert.im"

-- 2. TEMPLATES-ORDNER (der Ordner in dem die Templates liegen)
property templatesOrdner : "ImmoScout Templates"

-- 3. DEINE ABSENDER-ADRESSE (mit der E-Mails erstellt werden)
property absenderAdresse : "andreas.diehl@gmail.com"

-- 4. BETREFF FÜR ANTWORT-E-MAILS
property antwortBetreff : "Ihre Anfrage zu Objekt {REFERENZ_ID}"

-- 5a. ECHTE EMPFÄNGER-DATEN VERWENDEN?
--    true  = Echte E-Mail-Adresse des Interessenten (PRODUKTIV)
--    false = Test-E-Mail verwenden (SICHER ZUM TESTEN!)
property echteDaten : false

-- 5b. TEST E-MAIL-ADRESSE (wird verwendet wenn echteDaten = false)
property testEmail : "andreas.diehl@gmail.com"

-- 6. VERHALTEN - Was soll passieren?
--    "save" = Als Entwurf speichern (zur Review)
--    "send" = Direkt senden (VORSICHT!)
property verhalten : "save"

-- 7. ORIGINAL E-MAIL LÖSCHEN?
--    true  = Original-E-Mail wird nach Verarbeitung gelöscht (in Papierkorb)
--    false = Original-E-Mail bleibt im Posteingang
property originalLoeschen : false

-- ========================================
-- AB HIER NICHTS ÄNDERN
-- ========================================

on run
	-- AUTO-UPDATE CHECK
	if autoUpdateCheck then
		set updateVerfuegbar to my pruefeUpdate()
		if updateVerfuegbar then
			set antwort to button returned of (display dialog "🆕 Neue Script-Version verfügbar!" & return & return & "Aktuelle Version: " & scriptVersion & return & "Möchten Sie jetzt aktualisieren?" buttons {"Später", "Jetzt updaten"} default button "Jetzt updaten" with icon note)
			
			if antwort is "Jetzt updaten" then
				my fuehreUpdateAus()
				return -- Script wird neu gestartet
			end if
		end if
	end if
	
	-- VALIDIERE KONFIGURATION
	set validierungErfolg to my validiereKonfiguration()
	if not validierungErfolg then
		return
	end if
	
	tell application "Mail"
		activate
		
		-- Validiere Konfiguration
		if verhalten is not "save" and verhalten is not "send" then
			set dialogText to "❌ KONFIGURATIONSFEHLER!" & return & return & "Die Variable 'verhalten' (Zeile 44) muss entweder 'save' oder 'send' sein." & return & return & "Aktuell: '" & verhalten & "'" & return & return & "Bitte korrigieren!"
			display dialog dialogText buttons {"OK"} with icon stop
			return
		end if
		
		set verarbeiteteEmails to 0
		set fehlerAnzahl to 0
		set relevanteEmails to {}
		set geseheneBetreffe to {}
		
		-- Prüfe Templates-Ordner
		try
			set templateMailbox to mailbox templatesOrdner
		on error
			set dialogText to "❌ Templates-Ordner nicht gefunden!" & return & return & "Bitte erstelle den Ordner:" & return & "'" & templatesOrdner & "'" & return & return & "unter 'Auf meinem Mac' in Mail."
			display dialog dialogText buttons {"OK"}
			return
		end try
		
		-- Suche E-Mails von ImmobilienScout
		repeat with einAccount in accounts
			try
				set posteingang to mailbox "INBOX" of einAccount
				set gefundeneNachrichten to (messages of posteingang whose sender contains absenderEmail)
				
				repeat with eineNachricht in gefundeneNachrichten
					set derBetreff to subject of eineNachricht
					if derBetreff is not in geseheneBetreffe then
						set end of relevanteEmails to eineNachricht
						set end of geseheneBetreffe to derBetreff
					end if
				end repeat
			end try
		end repeat
		
		if (count of relevanteEmails) = 0 then
			display dialog "Keine E-Mails von ImmobilienScout gefunden." buttons {"OK"}
			return
		end if
		
		-- Bestätigung mit Warnungen
		if verhalten is "send" then
			set aktion to "⚠️ E-MAILS WERDEN DIREKT GESENDET!"
		else
			set aktion to "Entwürfe werden erstellt"
		end if
		
		if not echteDaten then
			set empfaengerInfo to return & "🧪 TEST-MODUS: Alle E-Mails gehen an " & testEmail
		else
			set empfaengerInfo to ""
		end if
		
		if originalLoeschen then
			set loeschenInfo to return & "🗑️ Original-E-Mails werden gelöscht"
		else
			set loeschenInfo to ""
		end if
		
		set dialogText to "Es wurden " & (count of relevanteEmails) & " E-Mail(s) gefunden." & return & return & aktion & empfaengerInfo & loeschenInfo & return & return & "Fortfahren?"
		set antwort to display dialog dialogText buttons {"Abbrechen", "Ja"} default button "Ja"
		
		if button returned of antwort = "Ja" then
			repeat with eineEmail in relevanteEmails
				try
					set erfolg to my verarbeiteEmail(eineEmail, templateMailbox, verhalten, echteDaten)
					if erfolg then
						set verarbeiteteEmails to verarbeiteteEmails + 1
						
						-- Original löschen wenn konfiguriert
						if originalLoeschen then
							delete eineEmail
						end if
					else
						set fehlerAnzahl to fehlerAnzahl + 1
					end if
				on error errMsg
					set fehlerAnzahl to fehlerAnzahl + 1
				end try
			end repeat
			
			-- Erfolgsmeldung
			if verhalten is "save" then
				set meldung to "✅ " & (verarbeiteteEmails as string) & " Entwurf/Entwürfe erstellt!" & return & return & "Die Entwürfe findest du im Entwürfe-Ordner."
			else
				set meldung to "✅ " & (verarbeiteteEmails as string) & " E-Mail(s) gesendet!"
			end if
			
			if fehlerAnzahl > 0 then
				set meldung to meldung & return & return & "⚠️ " & (fehlerAnzahl as string) & " Fehler (kein Template gefunden oder ungültige E-Mail)"
			end if
			
			if not echteDaten then
				set meldung to meldung & return & "🧪 TEST-MODUS war aktiv"
			end if
			
			if originalLoeschen and verarbeiteteEmails > 0 then
				set meldung to meldung & return & "🗑️ " & (verarbeiteteEmails as string) & " Original-E-Mail(s) gelöscht"
			end if
			
			display dialog meldung buttons {"OK"}
		end if
		
	end tell
end run

-- ========================================
-- E-MAIL VALIDIERUNG
-- ========================================

on validiereEmail(emailAdresse)
	if emailAdresse is "" then
		return false
	end if
	
	-- Prüfe grundlegendes Format: text@text.text
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
	
	-- Prüfe ob beide Teile vorhanden
	if (length of lokalerTeil) < 1 or (length of domainTeil) < 3 then
		return false
	end if
	
	-- Prüfe ob Domain einen Punkt enthält
	if domainTeil does not contain "." then
		return false
	end if
	
	-- Prüfe ob Domain nicht mit Punkt beginnt oder endet
	if domainTeil starts with "." or domainTeil ends with "." then
		return false
	end if
	
	return true
end validiereEmail

on validiereKonfiguration()
	tell application "Mail" to activate
	
	set fehlerListe to {}
	
	-- Validiere absenderEmail
	if not my validiereEmail(absenderEmail) then
		set end of fehlerListe to "❌ Überwachte Absender-Adresse (Zeile 27): '" & absenderEmail & "'"
	end if
	
	-- Validiere absenderAdresse
	if not my validiereEmail(absenderAdresse) then
		set end of fehlerListe to "❌ Ihre Absender-Adresse (Zeile 33): '" & absenderAdresse & "'"
	end if
	
	-- Validiere testEmail
	if not my validiereEmail(testEmail) then
		set end of fehlerListe to "❌ Test-E-Mail-Adresse (Zeile 42): '" & testEmail & "'"
	end if
	
	if (count of fehlerListe) > 0 then
		set AppleScript's text item delimiters to return
		set fehlerText to fehlerListe as string
		set AppleScript's text item delimiters to ""
		
		set dialogText to "❌ KONFIGURATIONSFEHLER: Ungültige E-Mail-Adressen!" & return & return & fehlerText & return & return & "Bitte korrigiere die E-Mail-Adressen im Script." & return & return & "Gültiges Format: name@domain.de"
		
		display dialog dialogText buttons {"OK"} with icon stop
		
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
		
		-- Empfänger bestimmen: Echt oder Test
		if echteDaten then
			-- Validiere Interessenten-Email vor Verwendung
			if not my validiereEmail(interessentEmail) then
				set dialogText to "⚠️ WARNUNG: Ungültige Empfänger-E-Mail!" & return & return & "Extrahierte E-Mail: '" & interessentEmail & "'" & return & return & "Diese E-Mail wird übersprungen."
				display dialog dialogText buttons {"OK"} with icon caution
				return false
			end if
			set empfaengerEmail to interessentEmail
		else
			set empfaengerEmail to testEmail
		end if
		
		-- Finde passendes Template
		set templateNachricht to my findeTemplate(templateMailbox, scoutID)
		
		if templateNachricht is missing value then
			-- Zeige Fehlermeldung mit verfügbaren Templates
			set alleTemplates to messages of templateMailbox
			set templateListe to ""
			repeat with einTemplate in alleTemplates
				set templateListe to templateListe & "  • " & (subject of einTemplate) & return
			end repeat
			
			set dialogText to "❌ Kein passendes Template gefunden!" & return & return & "Scout-ID: " & scoutID & return & return & "Verfügbare Templates:" & return & templateListe & return & "Benötigt wird:" & return & "  • '" & scoutID & "' (für diese Scout-ID)" & return & "  ODER" & return & "  • 'default' (als Fallback)"
			display dialog dialogText buttons {"OK"}
			
			return false
		end if
		
		-- Kopiere nur den BODY vom Template
		set templateBody to content of templateNachricht
		
		-- Ersetze Platzhalter im Betreff (aus Config)
		set neuerBetreff to my ersetzePlatzhalter(antwortBetreff, scoutID, titel, referenzID, anrede, vorname, nachname, interessentEmail, nachricht)
		
		-- Ersetze Platzhalter im Body (aus Template)
		set neuerBody to my ersetzePlatzhalter(templateBody, scoutID, titel, referenzID, anrede, vorname, nachname, interessentEmail, nachricht)
		
		-- Erstelle Entwurf
		try
			set neuerEntwurf to make new outgoing message with properties {subject:neuerBetreff, content:neuerBody, visible:false}
			
			tell neuerEntwurf
				make new to recipient at end of to recipients with properties {address:empfaengerEmail}
				set sender to absenderAdresse
			end tell
			
			-- Senden oder speichern
			if verhalten is "send" then
				send neuerEntwurf
			end if
			
			return true
			
		on error errMsg
			set dialogText to "❌ Fehler beim Erstellen des Entwurfs:" & return & return & errMsg
			display dialog dialogText buttons {"OK"}
			return false
		end try
		
	end tell
end verarbeiteEmail

on fuehreUpdateAus()
	try
		-- Lade neue Version
		set neuesScript to do shell script "curl -s " & quoted form of githubRawURL
		
		if neuesScript is "" then
			display dialog "❌ Keine Verbindung zu GitHub" buttons {"OK"}
			return
		end if
		
		-- Config sichern und einsetzen
		set aktuelleConfig to {absenderEmail:absenderEmail, templatesOrdner:templatesOrdner, absenderAdresse:absenderAdresse, antwortBetreff:antwortBetreff, echteDaten:echteDaten, testEmail:testEmail, verhalten:verhalten, originalLoeschen:originalLoeschen}
		set neuesScript to my ersetzeConfigImScript(neuesScript, aktuelleConfig)
		
		-- In Temp speichern
		set tempPfad to "/tmp/immoscout_update.applescript"
		do shell script "cat > " & quoted form of tempPfad & " << 'EOF'" & return & neuesScript & return & "EOF"
		
		-- Ersetze im Hintergrund
		set scriptPfad to POSIX path of (path to me)
		do shell script "( sleep 3 && mv " & quoted form of tempPfad & " " & quoted form of scriptPfad & " ) > /dev/null 2>&1 &"
		
		display dialog "✅ Update installiert!" & return & return & "Bitte öffnen Sie das Script neu." buttons {"OK"}
		
		-- Beenden
		quit
	on error errMsg
		display dialog "❌ Fehler: " & errMsg buttons {"OK"}
	end try
end fuehreUpdateAus

on ersetzeConfigImScript(scriptText, configWerte)
	-- Ersetze alle Config-Properties
	set scriptText to my ersetzeProperty(scriptText, "absenderEmail", absenderEmail of configWerte)
	set scriptText to my ersetzeProperty(scriptText, "templatesOrdner", templatesOrdner of configWerte)
	set scriptText to my ersetzeProperty(scriptText, "absenderAdresse", absenderAdresse of configWerte)
	set scriptText to my ersetzeProperty(scriptText, "antwortBetreff", antwortBetreff of configWerte)
	set scriptText to my ersetzeProperty(scriptText, "echteDaten", echteDaten of configWerte as string)
	set scriptText to my ersetzeProperty(scriptText, "testEmail", testEmail of configWerte)
	set scriptText to my ersetzeProperty(scriptText, "verhalten", verhalten of configWerte)
	set scriptText to my ersetzeProperty(scriptText, "originalLoeschen", originalLoeschen of configWerte as string)
	
	return scriptText
end ersetzeConfigImScript

on ersetzeProperty(scriptText, propertyName, neuerWert)
	try
		-- Finde die Zeile mit: property propertyName : "..."
		set suchMuster to "property " & propertyName & " : "
		
		if scriptText contains suchMuster then
			set AppleScript's text item delimiters to suchMuster
			set teile to text items of scriptText
			
			if (count of teile) > 1 then
				set nachProperty to item 2 of teile
				
				-- Finde das Ende der Zeile
				set AppleScript's text item delimiters to {return, linefeed}
				set zeilen to text items of nachProperty
				set alteZeile to item 1 of zeilen
				
				-- Bestimme Anführungszeichen (String oder Boolean)
				if neuerWert is "true" or neuerWert is "false" then
					set neueZeile to neuerWert
				else
					set neueZeile to "\"" & neuerWert & "\""
				end if
				
				-- Ersetze die Zeile
				set AppleScript's text item delimiters to suchMuster & alteZeile
				set teile to text items of scriptText
				set AppleScript's text item delimiters to suchMuster & neueZeile
				set scriptText to teile as string
			end if
		end if
		
		set AppleScript's text item delimiters to ""
	on error
		set AppleScript's text item delimiters to ""
	end try
	
	return scriptText
end ersetzeProperty

-- ========================================
-- HILFSFUNKTIONEN
-- ========================================

on findeTemplate(templateMailbox, scoutID)
	tell application "Mail"
		set alleTemplates to messages of templateMailbox
		
		-- Suche nach spezifischem Template: "162188779"
		if scoutID is not "" then
			repeat with einTemplate in alleTemplates
				if (subject of einTemplate) is scoutID then
					return einTemplate
				end if
			end repeat
		end if
		
		-- Fallback: "default"
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
	-- Suche nach verschiedenen Varianten der Nachricht-Überschrift
	set nachNachricht to ""
	set nachrichtGefunden to false
	
	-- Variante 1: "Nachricht Ihrer Interessent:innen" (mit Doppelpunkt)
	if inhalt contains "Nachricht Ihrer Interessent:innen" then
		set AppleScript's text item delimiters to "Nachricht Ihrer Interessent:innen"
		set teile to text items of inhalt
		if (count of teile) > 1 then
			set nachNachricht to item 2 of teile
			set nachrichtGefunden to true
		end if
		set AppleScript's text item delimiters to ""
	end if
	
	-- Variante 2: "Nachricht Ihrer Interessent" (ohne :innen)
	if not nachrichtGefunden and inhalt contains "Nachricht Ihrer Interessent" then
		set AppleScript's text item delimiters to "Nachricht Ihrer Interessent"
		set teile to text items of inhalt
		if (count of teile) > 1 then
			set nachNachricht to item 2 of teile
			set nachrichtGefunden to true
		end if
		set AppleScript's text item delimiters to ""
	end if
	
	-- Variante 3: nur "Nachricht" als Fallback
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
	
	-- Jetzt Text verarbeiten
	set AppleScript's text item delimiters to {return, linefeed}
	set zeilen to text items of nachNachricht
	
	set nachrichtText to ""
	set textBegonnen to false
	
	repeat with eineZeile in zeilen
		set eineZeile to my trim(eineZeile)
		
		-- Überspringe Header und kurze Zeilen am Anfang
		if not textBegonnen then
			-- Beginne mit Zeilen die "Sehr" oder "Hallo" oder ähnliches enthalten, oder >20 Zeichen haben
			if (length of eineZeile) > 15 and not (eineZeile contains "Von:") and not (eineZeile contains "Betreff:") and not (eineZeile contains "Datum:") and not (eineZeile contains "Nachrichtenverlauf") then
				set textBegonnen to true
			end if
		end if
		
		if textBegonnen then
			-- Stoppe bei Signatur oder Nachrichtenverlauf
			if eineZeile contains "Mit freundlichen Grüßen" or eineZeile contains "Mit freundlichen Gr" or eineZeile contains "Beste Grüße" or eineZeile contains "Viele Grüße" or eineZeile contains "Nachrichtenverlauf" then
				if nachrichtText is not "" and (eineZeile contains "Mit freundlichen" or eineZeile contains "Beste Grüße" or eineZeile contains "Viele Grüße") then
					set nachrichtText to nachrichtText & return & return & eineZeile
				end if
				exit repeat
			end if
			
			-- Füge Zeile hinzu
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
