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
property logDateiName : "immoscout_processor.log"
property loggingAktiv : true

-- Scout-ID Filter (leer = alle, sonst Komma-Liste)
property scoutIds : ""

-- ========================================
-- NEU: Fehler-Handling
-- ========================================
property letzteFehlermeldung : ""
property fehlerDetails : {}

-- ========================================
-- AB HIER NICHTS ÄNDERN
-- ========================================

on run
	set letzteFehlermeldung to ""
	set fehlerDetails to {}
	
	my logLine("=== Run gestartet | Version " & scriptVersion & " ===")

	-- NEU: AUTO-UPDATE
	try
		set updateURL to "https://raw.githubusercontent.com/andreasdiehl/ImmoScout-Email-Automation/main/version.txt"
		set latestVersion to (do shell script "curl -s " & updateURL)
		
		if my trim(latestVersion) > scriptVersion then
			-- Prüfen ob wir als App laufen (Updater verfügbar?)
			set updaterVerfuegbar to false
			try
				set updaterScriptPfad to (POSIX path of (path to resource "updater.sh"))
				set updaterVerfuegbar to true
			on error
				set updaterVerfuegbar to false
			end try
			
			if updaterVerfuegbar then
				-- APP MODUS: Auto-Update
				set antwort to display dialog "🚀 Neue Version verfügbar: " & latestVersion & return & "Installiert: " & scriptVersion & return & return & "Die App wird neu gestartet." buttons {"Später", "Jetzt Updaten"} default button "Jetzt Updaten"
				
				if button returned of result is "Jetzt Updaten" then
					my logLine("UPDATE | Starte Auto-Update auf v" & latestVersion)
					
					-- 1. Pfade definieren
					set zipDownloadUrl to "https://github.com/andreasdiehl/ImmoScout-Email-Automation/releases/latest/download/ImmoScoutAutomation.zip"
					set zipPfad to "/tmp/ImmoScoutUpdate.zip"
					set meineAppPfad to (POSIX path of (path to me))
					
					-- 2. Download
					do shell script "curl -L -o " & quoted form of zipPfad & " " & zipDownloadUrl
					
					-- 3. Updater starten
					set myPID to (do shell script "ps -p $$ -o ppid=")
					do shell script "sh " & quoted form of updaterScriptPfad & " " & quoted form of zipPfad & " " & quoted form of meineAppPfad & " " & myPID & " > /dev/null 2>&1 &"
					
					quit
					return
				end if
			else
				-- SCRIPT MODUS: Manuell
				display dialog "🚀 Neue Version verfügbar: " & latestVersion & return & "Installiert: " & scriptVersion & return & return & "(Auto-Update nur in App verfügbar)" buttons {"Später", "Zum Download"} default button "Zum Download"
				if button returned of result is "Zum Download" then
					open location "https://github.com/andreasdiehl/ImmoScout-Email-Automation"
					return
				end if
			end if
		end if
	on error errMsg
		my logLine("WARNUNG | Update-Check fehlgeschlagen | " & errMsg)
	end try
	
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
		set geseheneBetreffe to {}
		
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
			on error errMsg
				set end of fehlerDetails to "❌ Fehler beim Durchsuchen eines Accounts: " & errMsg
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
			
			-- Erfolgsmeldung
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
			
			display dialog meldung buttons {"OK"}
			
			-- Fehler-Details anzeigen (falls vorhanden)
			if (count of fehlerDetails) > 0 then
				set AppleScript's text item delimiters to return & return
				set detailText to fehlerDetails as string
				set AppleScript's text item delimiters to ""
				
				-- Hinweis: Dialog ist begrenzt, aber für “sprechende Fehler” reicht das i.d.R.
				display dialog "Details zu Problemen:" & return & return & detailText buttons {"OK"}
			end if
		end if
		
	end tell
end run

-- ========================================
-- CONFIG LADEN
-- ========================================

on ladeConfig()
	try
		set configPfad to ""
		set nutzeLokaleConfig to false
		
		-- 1. Check: Sind wir im Script-Modus (Development)?
		tell application "Finder"
			set extensionName to ""
			try
				set extensionName to name extension of (path to me)
			end try
			
			if extensionName is not "app" then
				-- Wir laufen als Script -> Suche config.txt im Projekt-Root (../config.txt)
				try
					set srcOrdner to container of (path to me)
					set projektOrdner to container of srcOrdner
					set lokaleConfigDatei to file "config.txt" of projektOrdner
					
					if exists lokaleConfigDatei then
						set configPfad to (lokaleConfigDatei as text)
						set nutzeLokaleConfig to true
						my logLine("INFO | Nutze lokale Dev-Config: " & configPfad)
					end if
				on error
					-- Ordnerstruktur passt nicht (z.B. Script kopiert), fallback auf Standard
				end try
			end if
		end tell
		
		-- 2. Fallback: Standard Application Support (für App & wenn lokal fehlt)
		if not nutzeLokaleConfig then
			set appSupportOrdner to (path to application support from user domain as text)
			set meinOrdnerName to "ImmoScout-Automation"
			set configDateiname to "config.txt"
			
			set configOrdnerPfad to appSupportOrdner & meinOrdnerName & ":"
			set configPfad to configOrdnerPfad & configDateiname
			
			-- Prüfung für App Support Pfad
			tell application "Finder"
				if not (exists file configPfad) then
					set dText to "❌ Konfigurationsdatei fehlt!" & return & return & "Ich habe versucht den Ordner zu öffnen." & return & "Bitte kopiere 'config.txt' dort hinein."
					
					set antwort to display dialog dText buttons {"Pfad kopieren", "OK", "Gehe zu Ordner..."} default button "Gehe zu Ordner..." with icon stop
					
					if button returned of antwort is "Pfad kopieren" then
						set the clipboard to (POSIX path of configOrdnerPfad)
						display dialog "Pfad kopiert! Du kannst ihn im Finder mit ⇧⌘G (Gehe zu Ordner) nutzen." buttons {"OK"}
					else if button returned of antwort is "Gehe zu Ordner..." then
						if (exists folder configOrdnerPfad) then
							open folder configOrdnerPfad
						else
							open folder appSupportOrdner
						end if
					end if
					return false
				end if
			end tell
		end if
		
		-- 3. Config lesen
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
		
		-- Parse Config
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
						else if schluessel is "scoutIds" then
							set scoutIds to wert
						end if
					end if
					set AppleScript's text item delimiters to {return, linefeed}
				end if
			end if
		end repeat
		set AppleScript's text item delimiters to ""
		return true
	on error errMsg
		display dialog "❌ Unerwarteter Fehler im Config-Loader." & return & return & "Details: " & errMsg buttons {"OK"}
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

on logPfad()
	set appSupportOrdner to (path to application support from user domain as text)
	set meinOrdnerName to "ImmoScout-Automation"
	return (appSupportOrdner & meinOrdnerName & ":" & logDateiName)
end logPfad

on logLine(msg)
	if not loggingAktiv then return
	
	try
		set ts to (do shell script "date '+%Y-%m-%d %H:%M:%S'")
		set logString to ts & " | " & msg & linefeed
		
		set p to my logPfad()
		set f to open for access file p with write permission
		-- ans Ende springen und anhängen
		set eof f to (get eof f)
		write logString to f starting at eof
		close access f
	on error errMsg
		-- notfalls still schlucken, damit das Script nicht crasht
		try
			close access file (my logPfad())
		end try
	end try
end logLine
