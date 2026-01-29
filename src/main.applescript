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
property loggingAktiv : true
property aktuellerLogPfad : ""
property scoutIds : ""
property letzteFehlermeldung : ""
property fehlerDetails : {}

-- ========================================
-- AB HIER NICHTS ÄNDERN
-- ========================================

on run
	set letzteFehlermeldung to ""
	set fehlerDetails to {}
	
	-- Log initialisieren und alte Logs aufräumen
	my initializeLog()
	my cleanupOldLogs()
	
	my logLine("=== Run gestartet | Version " & scriptVersion & " ===")
	

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
	
	my logLine("Config geladen | absenderEmail=" & absenderEmail & " | templatesOrdner=" & templatesOrdner & " | echteDaten=" & echteDaten & " | verhalten=" & verhalten & " | originalLoeschen=" & originalLoeschen & " | ignoriereEmailsVorTagen=" & ignoriereEmailsVorTagen & " | scoutIds=" & scoutIds)
	
	tell application "Mail"
		activate
		
		set verarbeiteteEmails to 0
		set fehlerAnzahl to 0
		set relevanteEmails to {}
		set geseheneMessageIDs to {}
		set gesamtGefundeneEmails to 0
		
		-- Berechne Stichtag
		set stichtag to (current date) - (ignoriereEmailsVorTagen * days)
		
		-- Prüfe Templates-Ordner
		try
			set templateMailbox to mailbox templatesOrdner
		on error errMsg
			my logLine("FEHLER | Templates-Ordner nicht gefunden | templatesOrdner='" & templatesOrdner & "'")
			display dialog "❌ Templates-Ordner nicht gefunden." & return & return & "Gesucht: '" & templatesOrdner & "'" & return & "Ort: unter 'Auf meinem Mac'." & return & return & "Details: " & errMsg buttons {"OK"}
			return
		end try
		
		-- Suche E-Mails von ImmobilienScout
		repeat with einAccount in accounts
			try
				set accountName to name of einAccount
				my logLine("DEBUG | Durchsuche Account: " & accountName)
				
				set posteingang to mailbox "INBOX" of einAccount
				my logLine("DEBUG | INBOX gefunden in: " & accountName)
				
				set gefundeneNachrichten to (messages of posteingang whose sender contains absenderEmail)
				set anzahlGefunden to count of gefundeneNachrichten
				set gesamtGefundeneEmails to gesamtGefundeneEmails + anzahlGefunden
				my logLine("DEBUG | " & anzahlGefunden & " Nachrichten gefunden in: " & accountName)
				
				repeat with eineNachricht in gefundeneNachrichten
					my logLine("DEBUG | Verarbeite Nachricht...")
					set emailDatum to date received of eineNachricht
					my logLine("DEBUG | Datum erhalten: " & emailDatum)
					
					-- Nur E-Mails nach Stichtag
					if emailDatum ≥ stichtag then
						my logLine("DEBUG | Email ist nach Stichtag - hole Message-ID")
						-- Verwende Message-ID für zuverlässige Deduplizierung
						set messageID to message id of eineNachricht
						my logLine("DEBUG | Message-ID erhalten: " & messageID)
						if messageID is not in geseheneMessageIDs then
							set end of relevanteEmails to eineNachricht
							set end of geseheneMessageIDs to messageID
							my logLine("DEBUG | Email zur Liste hinzugefügt")
						else
							my logLine("DEBUG | Email bereits gesehen (Duplikat)")
						end if
					end if
				end repeat
			on error errMsg
				my logLine("FEHLER | Fehler beim Durchsuchen von Account: " & accountName & " | " & errMsg)
				set end of fehlerDetails to "❌ Fehler beim Durchsuchen eines Accounts: " & errMsg
			end try
		end repeat
		
		if (count of relevanteEmails) = 0 then
			display dialog "Keine neuen E-Mails gefunden." & return & return & "(Filter: Letzte " & ignoriereEmailsVorTagen & " Tage)" buttons {"OK"}
			return
		end if
		
		-- Bestätigung mit vollständigem Config-Status
		if verhalten is "send" then
			set aktion to "⚠️ E-MAILS WERDEN DIREKT GESENDET!"
		else
			set aktion to "📝 Entwürfe werden erstellt"
		end if
		
		if not echteDaten then
			set modus to "🧪 TEST-MODUS: Alle E-Mails an " & testEmail
		else
			set modus to "✅ PRODUKTIV-MODUS: An echte Empfänger"
		end if
		
		if originalLoeschen then
			set loeschenInfo to "🗑️ Originale löschen: JA"
		else
			set loeschenInfo to "📥 Originale löschen: NEIN"
		end if
		
		set zeitfilter to "📅 Zeitfilter: Letzte " & ignoriereEmailsVorTagen & " Tage"
		
		if my trim(scoutIds) is "" then
			set scoutFilter to "🏠 Scout-IDs: Alle"
		else
			set scoutFilter to "🏠 Scout-IDs: " & scoutIds
		end if
		
		set anzahlRelevant to count of relevanteEmails
		set dialogText to "📨 " & gesamtGefundeneEmails & " E-Mail(s) gefunden, " & anzahlRelevant & " zur Verarbeitung" & return & return & "⚙️ AKTIVE EINSTELLUNGEN:" & return & modus & return & aktion & return & loeschenInfo & return & zeitfilter & return & scoutFilter & return & return & "Fortfahren?"
		set antwort to display dialog dialogText buttons {"Abbrechen", "Ja"} default button "Ja"
		
		if button returned of antwort = "Ja" then
			repeat with eineEmail in relevanteEmails
				try
					set letzteFehlermeldung to ""
					set erfolg to my verarbeiteEmail(eineEmail, templateMailbox, verhalten, echteDaten)
					
					if erfolg then
						set verarbeiteteEmails to verarbeiteteEmails + 1
						if originalLoeschen then
							my logLine("OK | Original gelöscht")
							delete eineEmail
						end if
					else
						set fehlerAnzahl to fehlerAnzahl + 1
						-- Sammle sprechende Fehlermeldung + Kontext
						set ctx to my emailKontext(eineEmail)
						if letzteFehlermeldung is "" then
							set end of fehlerDetails to "❌ Unbekannter Fehler." & return & ctx
						else
							set end of fehlerDetails to letzteFehlermeldung & return & ctx
						end if
					end if
				on error errMsg
					set fehlerAnzahl to fehlerAnzahl + 1
					set ctx to my emailKontext(eineEmail)
					set end of fehlerDetails to "❌ Unerwarteter Script-Fehler beim Verarbeiten." & return & "Details: " & errMsg & return & ctx
				end try
			end repeat
			
			-- Erfolgsmeldung mit Log-Zugriff
			if verhalten is "save" then
				set meldung to "✅ " & verarbeiteteEmails & " Entwurf/Entwürfe erstellt!"
			else
				set meldung to "✅ " & verarbeiteteEmails & " E-Mail(s) gesendet!"
			end if
			
			if fehlerAnzahl > 0 then
				set meldung to meldung & return & "⚠️ " & fehlerAnzahl & " Problem(e)"
			end if
			
			if not echteDaten then
				set meldung to meldung & return & "🧪 TEST-MODUS aktiv"
			end if
			
			-- Dialog mit Log-Button
			set dialogButtons to {"OK", "📋 Log anzeigen"}
			set antwortFinal to display dialog meldung buttons dialogButtons default button "OK"
			
			-- Log öffnen wenn gewünscht (in TextEdit zum Bearbeiten/Löschen)
			if button returned of antwortFinal is "📋 Log anzeigen" then
				if aktuellerLogPfad is not "" then
					try
						set logDateiPfad to POSIX path of aktuellerLogPfad
						do shell script "open -a TextEdit " & quoted form of logDateiPfad
					on error
						display dialog "❌ Log-Datei konnte nicht geöffnet werden." & return & return & "Pfad: " & aktuellerLogPfad buttons {"OK"}
					end try
				else
					display dialog "ℹ️ Keine Log-Datei verfügbar." & return & return & "Die Log-Datei wurde möglicherweise nicht erstellt." buttons {"OK"}
				end if
			end if
			
		end if
		
	end tell
end run

-- ========================================
-- CONFIG LADEN
-- ========================================

on ladeConfig()
	try
		-- 1. Get current username
		set username to do shell script "whoami"
		my logLine("INFO | Username: " & username)
		
		-- 2. Find app/script location
		set appPfad to path to me
		tell application "Finder"
			set parentOrdner to (container of appPfad) as text
		end tell
		my logLine("INFO | App location: " & parentOrdner)
		
		-- 3. Build config path: ../config/{username}.txt
		set configPfad to parentOrdner & "config:" & username & ".txt"
		my logLine("INFO | Looking for config: " & configPfad)
		
		-- 4. Check if config exists
		tell application "Finder"
			if not (exists file configPfad) then
				set dText to "❌ Konfigurationsdatei fehlt!" & return & return & "Erwartet: config/" & username & ".txt" & return & return & "Bitte erstelle diese Datei im config-Ordner."
				
				set antwort to display dialog dText buttons {"Ordner öffnen", "Abbrechen"} default button "Ordner öffnen" with icon stop
				
				if button returned of antwort is "Ordner öffnen" then
					set configOrdner to (parentOrdner as text) & "config:"
					try
						open folder configOrdner
					on error
						-- Config folder doesn't exist, open parent
						open parentOrdner
					end try
				end if
				return false
			end if
		end tell
		
		-- 5. Read config file
		try
			set configDatei to open for access file configPfad
			set configInhalt to read configDatei as «class utf8»
			close access configDatei
		on error errMsg
			try
				close access file configPfad
			end try
			display dialog "❌ Fehler beim Lesen der Config." & return & return & "Details: " & errMsg buttons {"OK"}
			return false
		end try
		
		-- 6. Parse config (existing logic)
		set AppleScript's text item delimiters to {return, linefeed}
		set zeilen to paragraphs of configInhalt
		
		repeat with eineZeile in zeilen
			set eineZeile to my trim(eineZeile)
			if eineZeile does not start with "#" and eineZeile does not start with "//" and (length of eineZeile) > 0 then
				if eineZeile contains "=" then
					set AppleScript's text item delimiters to "="
					set teile to text items of eineZeile
					if (count of teile) ≥ 2 then
						set schluessel to my trim(item 1 of teile)
						set wert to my trim(item 2 of teile)
						if schluessel is "absenderEmail" then
							set absenderEmail to wert
						else if schluessel is "templatesOrdner" then
							set templatesOrdner to wert
						else if schluessel is "absenderAdresse" then
							set absenderAdresse to wert
						else if schluessel is "antwortBetreff" then
							set antwortBetreff to wert
						else if schluessel is "echteDaten" then
							if wert is "true" then
								set echteDaten to true
							else
								set echteDaten to false
							end if
						else if schluessel is "verhalten" then
							set verhalten to wert
						else if schluessel is "originalLoeschen" then
							if wert is "true" then
								set originalLoeschen to true
							else
								set originalLoeschen to false
							end if
						else if schluessel is "ignoriereEmailsVorTagen" then
							try
								set ignoriereEmailsVorTagen to wert as integer
							end try
						else if schluessel is "testEmail" then
							set testEmail to wert
						else if schluessel is "scoutIds" then
							set scoutIds to wert
						end if
					end if
					set AppleScript's text item delimiters to {return, linefeed}
				end if
			end if
		end repeat
		
		set AppleScript's text item delimiters to ""
		
		-- Log loaded config
		my logLine("Config geladen | absenderEmail=" & absenderEmail & " | templatesOrdner=" & templatesOrdner & " | echteDaten=" & echteDaten & " | testEmail=" & testEmail & " | verhalten=" & verhalten & " | originalLoeschen=" & originalLoeschen & " | ignoriereEmailsVorTagen=" & ignoriereEmailsVorTagen & " | scoutIds=" & scoutIds)
		
		return true
		
	on error errMsg
		display dialog "❌ Fehler beim Laden der Config." & return & return & "Details: " & errMsg buttons {"OK"}
		return false
	end try
end ladeConfig


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
		set end of fehlerListe to "❌ absenderEmail ist ungültig: '" & absenderEmail & "'"
	end if
	
	if not my validiereEmail(absenderAdresse) then
		set end of fehlerListe to "❌ absenderAdresse ist ungültig: '" & absenderAdresse & "'"
	end if
	
	if not my validiereEmail(testEmail) then
		set end of fehlerListe to "❌ testEmail ist ungültig: '" & testEmail & "'"
	end if
	
	if verhalten is not "save" and verhalten is not "send" then
		set end of fehlerListe to "❌ verhalten muss 'save' oder 'send' sein (aktuell: '" & verhalten & "')"
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
		try
			set emailInhalt to content of dieEmail
			set originalBetreff to subject of dieEmail
			
			my logLine("Verarbeite Mail | Betreff='" & originalBetreff & "'")
		on error errMsg
			set letzteFehlermeldung to "❌ Konnte Inhalt/Betreff der E-Mail nicht lesen." & return & "Details: " & errMsg
			return false
		end try
		
		-- Extrahiere Daten
		set scoutID to my extrahiereScoutID(emailInhalt)
		set titel to my extrahiereTitel(emailInhalt)
		set referenzID to my extrahiereReferenzID(emailInhalt, originalBetreff)
		set anrede to my extrahiereNaechsteZeile(emailInhalt, "Anrede:")
		set vorname to my extrahiereNaechsteZeile(emailInhalt, "Vorname:")
		set nachname to my extrahiereNaechsteZeile(emailInhalt, "Nachname:")
		set interessentEmail to my extrahiereNaechsteZeile(emailInhalt, "E-Mail:")
		set nachricht to my extrahiereNachricht(emailInhalt)
		
		-- Scout-ID Allowlist prüfen
		if not my istScoutIdErlaubt(scoutID) then
			my logLine("SKIP | Scout-ID nicht erlaubt | scoutID='" & scoutID & "' | erlaubt='" & scoutIds & "' | Betreff='" & originalBetreff & "'")
			
			if my trim(scoutIds) is "" then
				-- sollte nicht passieren, aber sicher ist sicher
				set letzteFehlermeldung to "⚠️ E-Mail wurde übersprungen, obwohl kein Scout-ID Filter gesetzt ist." & return & "Scout-ID: '" & scoutID & "'"
			else
				set letzteFehlermeldung to "ℹ️ E-Mail übersprungen: Scout-ID ist nicht erlaubt." & return & "Scout-ID: '" & scoutID & "'" & return & "Erlaubt (config scoutIds): " & scoutIds
			end if
			-- WICHTIG: return false bedeutet normalerweise Fehler/Übersprungen.
			-- Damit es nicht als "Fehler" gezählt wird, müsste man den Caller anpassen 
			-- oder hier false returnen und im Caller prüfen, ob letzteFehlermeldung mit "ℹ️" beginnt.
			return false
		end if
		
		-- Empfänger bestimmen
		if echteDaten then
			if interessentEmail is "" then
				set letzteFehlermeldung to "❌ Produktiv-Modus: Keine Empfänger-E-Mail in der Anfrage gefunden." & return & "Feld 'E-Mail:' war leer."
				return false
			end if
			
			if not my validiereEmail(interessentEmail) then
				my logLine("FEHLER | Ungültige Empfänger-Mail | interessentEmail='" & interessentEmail & "' | scoutID='" & scoutID & "' | Betreff='" & originalBetreff & "'")
				set letzteFehlermeldung to "❌ Produktiv-Modus: Empfänger-E-Mail ist ungültig." & return & "Gefunden: '" & interessentEmail & "'"
				return false
			end if
			
			set empfaengerEmail to interessentEmail
		else
			if not my validiereEmail(testEmail) then
				set letzteFehlermeldung to "❌ Test-Modus: testEmail aus config ist ungültig." & return & "testEmail='" & testEmail & "'"
				return false
			end if
			set empfaengerEmail to testEmail
		end if
		
		-- Template finden
		set templateNachricht to my findeTemplate(templateMailbox, scoutID)
		
		if templateNachricht is missing value then
			-- Liste verfügbarer Templates
			try
				set alleTemplates to messages of templateMailbox
				set templateListe to ""
				repeat with einTemplate in alleTemplates
					set templateListe to templateListe & "  • " & (subject of einTemplate) & return
				end repeat
				
				my logLine("FEHLER | Kein Template gefunden | scoutID='" & scoutID & "' | templatesOrdner='" & templatesOrdner & "' | Betreff='" & originalBetreff & "'")
				
				set letzteFehlermeldung to "❌ Kein Template gefunden." & return & "Scout-ID: '" & scoutID & "'" & return & return & "Erwartet: Template-Mail mit Betreff = Scout-ID" & return & "oder Betreff = 'default'." & return & return & "Verfügbare Template-Betreffe:" & return & templateListe
			on error errMsg
				set letzteFehlermeldung to "❌ Kein Template gefunden und konnte Template-Liste nicht lesen." & return & "Scout-ID: '" & scoutID & "'" & return & "Details: " & errMsg
			end try
			return false
		end if
		
		-- Template-Body lesen
		try
			set templateBody to content of templateNachricht
		on error errMsg
			set letzteFehlermeldung to "❌ Konnte Template-Inhalt nicht lesen." & return & "Template-Betreff: '" & (subject of templateNachricht as string) & "'" & return & "Details: " & errMsg
			return false
		end try
		
		-- Platzhalter ersetzen
		try
			set neuerBetreff to my ersetzePlatzhalter(antwortBetreff, scoutID, titel, referenzID, anrede, vorname, nachname, interessentEmail, nachricht)
			set neuerBody to my ersetzePlatzhalter(templateBody, scoutID, titel, referenzID, anrede, vorname, nachname, interessentEmail, nachricht)
		on error errMsg
			set letzteFehlermeldung to "❌ Fehler beim Ersetzen der Platzhalter." & return & "Details: " & errMsg
			return false
		end try
		
		-- Entwurf erstellen / senden
		try
			set neuerEntwurf to make new outgoing message with properties {subject:neuerBetreff, content:neuerBody, visible:false}
			
			tell neuerEntwurf
				make new to recipient at end of to recipients with properties {address:empfaengerEmail}
				set sender to absenderAdresse
			end tell
			
			if verhalten is "send" then
				try
					send neuerEntwurf
				on error errMsg
					set letzteFehlermeldung to "❌ Konnte E-Mail nicht senden." & return & "Prüfe Mail-Account/SMTP." & return & "Details: " & errMsg
					return false
				end try
			end if
			
			if verhalten is "send" then
				my logLine("OK | Gesendet | an=" & empfaengerEmail & " | scoutID='" & scoutID & "' | Betreff='" & neuerBetreff & "'")
			else
				my logLine("OK | Entwurf erstellt | an=" & empfaengerEmail & " | scoutID='" & scoutID & "' | Betreff='" & neuerBetreff & "'")
			end if
			
			return true
			
		on error errMsg
			set letzteFehlermeldung to "❌ Fehler beim Erstellen des Entwurfs." & return & "Details: " & errMsg
			return false
		end try
		
	end tell
end verarbeiteEmail

-- ========================================
-- HILFSFUNKTIONEN
-- ========================================

on emailKontext(dieEmail)
	tell application "Mail"
		try
			set s to subject of dieEmail as string
		on error
			set s to "(Betreff nicht lesbar)"
		end try
		
		try
			set d to (date received of dieEmail) as string
		on error
			set d to "(Datum nicht lesbar)"
		end try
		
		try
			set snd to sender of dieEmail as string
		on error
			set snd to "(Absender nicht lesbar)"
		end try
	end tell
	
	return "Kontext:" & return & "• Betreff: " & s & return & "• Datum: " & d & return & "• Absender: " & snd
end emailKontext

on istScoutIdErlaubt(scoutID)
	-- leer = alles erlauben
	if my trim(scoutIds) is "" then
		return true
	end if
	
	-- ohne scoutID: nicht erlauben
	if scoutID is "" then
		return false
	end if
	
	set AppleScript's text item delimiters to ","
	set itemsList to text items of scoutIds
	set AppleScript's text item delimiters to ""
	
	repeat with x in itemsList
		if my trim(x as string) is (scoutID as string) then
			return true
		end if
	end repeat
	
	return false
end istScoutIdErlaubt

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

-- ========================================
-- LOGGING FUNKTIONEN
-- ========================================

on logsOrdnerPfad()
	try
		-- 1. Get current username
		set username to do shell script "whoami"
		
		-- 2. Find app location
		set appPfad to path to me
		tell application "Finder"
			set parentOrdner to (container of appPfad) as text
		end tell
		
		-- 3. Build path: ../logs/{username}/
		set logsOrdner to parentOrdner & "logs:" & username & ":"
		
		-- 4. Create folder if not exists
		try
			set logsOrdnerPosix to POSIX path of logsOrdner
			do shell script "mkdir -p " & quoted form of logsOrdnerPosix
		end try
		
		return logsOrdner
		
	on error errMsg
		-- Absolute fallback if everything fails
		return (path to startup disk as text) & "tmp:immoscout_logs:"
	end try
end logsOrdnerPfad

-- Initialisiert eine neue Log-Datei für diesen Run
on initializeLog()
	try
		-- Timestamp für Dateinamen
		set zeitstempel to (do shell script "date '+%Y-%m-%d_%H-%M-%S'")
		set logDateiName to "run_" & zeitstempel & ".log"
		
		-- Pfad holen
		set logsOrdner to my logsOrdnerPfad()
		set aktuellerLogPfad to logsOrdner & logDateiName
		
		-- Log-Datei erstellen (leer)
		set f to open for access file aktuellerLogPfad with write permission
		close access f
		

		
	on error errMsg
		try
			close access file aktuellerLogPfad
		on error
			-- Ignore errors during close
		end try
	end try
end initializeLog

-- Löscht Log-Dateien die älter als 30 Tage sind
on cleanupOldLogs()
	try
		set logsOrdner to my logsOrdnerPfad()
		set logsOrdnerPosix to POSIX path of logsOrdner
		
		-- Finde und lösche Dateien älter als 30 Tage
		do shell script "find " & quoted form of logsOrdnerPosix & " -name 'run_*.log' -type f -mtime +30 -delete"
		
	on error errMsg
		-- Fehler beim Cleanup - nicht kritisch, einfach ignorieren
	end try
end cleanupOldLogs

on logLine(msg)
	if not loggingAktiv then return
	
	try
		set ts to (do shell script "date '+%Y-%m-%d %H:%M:%S'")
		set logString to ts & " | " & msg & linefeed
		
		-- Verwende aktuellen Log-Pfad
		if aktuellerLogPfad is "" then
			-- Fallback falls initializeLog() nicht aufgerufen wurde
			my initializeLog()
		end if
		
		set f to open for access file aktuellerLogPfad with write permission
		-- ans Ende springen und anhängen
		set eof f to (get eof f)
		write logString to f starting at eof
		close access f
	on error errMsg
		-- notfalls still schlucken, damit das Script nicht crasht
		try
			close access file aktuellerLogPfad
		end try
	end try
end logLine
