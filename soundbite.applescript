global appsup, chosenAlias

property homeRootURL : "http://audimate.me/"

(*START CUSTOM FUNCTIONS*)

(*Start Common Functions*)
on alphabetize(the_list)
	set ascii_10 to ASCII character 10
	tell (a reference to my text item delimiters)
		set {old_atid, contents} to {contents, ascii_10}
		set {the_list, contents} to {the_list as Unicode text, old_atid}
	end tell
	set the_list to (do shell script "echo " & quoted form of the_list & " | sort")'s paragraphs
end alphabetize

on snr(the_string, search_string, replace_string)
	tell (a reference to my text item delimiters)
		set {old_tid, contents} to {contents, search_string}
		set {the_string, contents} to {the_string's text items, replace_string}
		set {the_string, contents} to {"" & the_string, old_tid}
	end tell
	return the_string
end snr

on split(someText, delimiter)
	set AppleScript's text item delimiters to delimiter
	set someText to someText's text items
	set AppleScript's text item delimiters to {""}
	return someText
end split

on cleanMyList(theList, itemsToDelete)
	set cleanList to {}
	repeat with i from 1 to count theList
		if {theList's item i} is not in itemsToDelete then set cleanList's end to theList's item i
	end repeat
	return cleanList
end cleanMyList

on getFileType(theGivenFile)
	tell application "System Events"
		set dropKind to (kind of (POSIX file (theGivenFile) as alias))
	end tell
	return (dropKind as string)
end getFileType

(*End Common Functions*)

on loadPage from theURL
	set URLWithString to call method "URLWithString:" of class "NSURL" with parameter theURL
	set requestWithURL to call method "requestWithURL:" of class "NSURLRequest" with parameter URLWithString
	tell window "soundbiteWindow"
		set mainFrame to call method "mainFrame" of object (view "soundbitePreview")
	end tell
	call method "loadRequest:" of mainFrame with parameter requestWithURL
end loadPage

on getMySoundbite(myAlias)
	set mySoundbiteURL to (homeRootURL & "displaySoundbite.php") as string
	set mySoundbite_f to (appsup & "mySoundbite_temp.mp3") as string
	set mySoundbiteData to ("curl --data " & quoted form of ("alias=" & myAlias) & " -e 'audiMate.displaySoundbite' " & quoted form of mySoundbiteURL & " -o " & quoted form of mySoundbite_f)
	set mySoundbiteData to (do shell script mySoundbiteData)
	set mySoundbiteURL to ("file://" & mySoundbite_f) as string
	
	set visible of view "soundbitePreview" of window "soundbiteWindow" to true
	loadPage from mySoundbiteURL
	set visible of view "soundbitePreview" of window "soundbiteWindow" to false
	set content of text field "soundbiteErrorText" of window "soundbiteWindow" to "Playing"
	--delay 3
	--set content of text field "soundbiteErrorText" of window "soundbiteWindow" to ""
end getMySoundbite

on updateSoundbite(mySoundbitePath)
	set mySoundbiteSize to (size of (info for mySoundbitePath))
	tell window "loginWindow"
		set myLoginEmail to (contents of text field "loginEmailInput")
		set myLoginPassword to (contents of text field "loginPasswordInput")
	end tell
	set mySoundType to getFileType(mySoundbitePath)
	if mySoundbiteSize is less than 1610000 then
		if mySoundType is "MP3 audio" then
			set mySoundbiteURL to (homeRootURL & "updateSoundbite.php") as string
			set mySoundbite to ("curl --form-string " & quoted form of ("email=" & myLoginEmail) & " --form-string " & quoted form of ("password=" & myLoginPassword) & " --form-string " & quoted form of ("mime=" & mySoundType) & " --form " & quoted form of ("fileUpload=@" & mySoundbitePath) & " --form press=OK" & " -e 'audiMate.updateSoundbite' " & quoted form of (mySoundbiteURL))
			
			set mySoundbite to (do shell script mySoundbite)
			
			if mySoundbite is "0" then
				set content of text field "soundbiteErrorText" of window "soundbiteWindow" to "Error: something went wrong with the upload."
			else
				copy mySoundbite to myGivenAlias
				set content of text field "soundbiteErrorText" of window "soundbiteWindow" to "Soundbite updated."
			end if
		else if mySoundType is "Ogg Vorbis Document" then
			set mySoundbiteURL to (homeRootURL & "updateSoundbite.php") as string
			set mySoundbite to ("curl --form-string " & quoted form of ("email=" & myLoginEmail) & " --form-string " & quoted form of ("password=" & myLoginPassword) & " --form-string " & quoted form of ("mime=" & mySoundType) & " --form " & quoted form of ("fileUpload=@" & mySoundbitePath) & " --form press=OK" & " -e 'audiMate.updateSoundbite' " & quoted form of (mySoundbiteURL))
			
			set mySoundbite to (do shell script mySoundbite)
			display dialog "" default answer mySoundbite
			
			
			if mySoundbite is "0" then
				set content of text field "soundbiteErrorText" of window "soundbiteWindow" to "Error: something went wrong with the upload."
			else
				copy mySoundbite to myGivenAlias
				set content of text field "soundbiteErrorText" of window "soundbiteWindow" to "Soundbite updated."
			end if
		else
			set content of text field "soundbiteErrorText" of window "soundbiteWindow" to "Error: only MP3s are supported."
		end if
	else
		set content of text field "soundbiteErrorText" of window "soundbiteWindow" to "Error: your soundbite must be less than 1.6MB."
	end if
	--delay 3
	--set content of text field "soundbiteErrorText" of window "soundbiteWindow" to ""
end updateSoundbite

(*END CUSTOM FUNCTIONS*)


on clicked theObject
	if the name of theObject is "soundbiteHideButton" then
		set title of window "homeWindow" to "Home"
		close panel window "soundbiteWindow"
		set mySoundbite_f to (appsup & "mySoundbite_temp.mp3") as string
		set visible of view "soundbitePreview" of window "soundbiteWindow" to false
		try
			do shell script ("rm  " & quoted form of mySoundbite_f)
		end try
	else if the name of theObject is "soundbiteHearButton" then
		getMySoundbite(chosenAlias)
	end if
end clicked

on conclude drop theObject drag info dragInfo
	return true
end conclude drop

on choose menu item theObject
	if the name of window 1 is "homeWindow" then
		if visible of progress indicator 1 of window "homeWindow" is false then
			if the name of theObject is "soundbiteMenuItem" then
				set appsup to ((POSIX path of (path to me)) & ("Contents/Resources/")) as string
				set title of window "homeWindow" to "Edit Soundbite"
				set content of text field "soundbiteErrorText" of window "soundbiteWindow" to ""
				display panel window "soundbiteWindow" attached to window "homeWindow"
				set chosenAlias to (contents of text field "loggedInAsText" of window "homeWindow")
			end if
		end if
	end if
end choose menu item

on drop theObject drag info dragInfo
	if the name of theObject is "soundbiteDrop" then
		--UPDATE MY SOUNDBITE
		set preferred type of pasteboard of dragInfo to "file names"
		set mySoundbitePath to (contents of pasteboard of dragInfo)
		
		updateSoundbite(mySoundbitePath)
	end if
end drop
