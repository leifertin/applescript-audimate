global appsup, chosenAlias

property homeRootURL : "http://audimate.me/"

(*START CUSTOM FUNCTIONS*)

(*Start Common Functions*)
on split(someText, delimiter)
	set AppleScript's text item delimiters to delimiter
	set someText to someText's text items
	set AppleScript's text item delimiters to {""}
	return someText
end split

(*End Common Functions*)

on getMyDetails()
	set myProfileURL to (homeRootURL & "getMyDetails.php") as string
	set myProfileData to (do shell script ("curl --data " & quoted form of ("alias=" & chosenAlias) & " -e 'audiMate.getMyDetails' " & quoted form of myProfileURL)) as string
	return myProfileData
end getMyDetails

on getMyLocation()
	set myProfileData to getMyDetails()
	set myLocation_cont to item 2 of (split(myProfileData, "<--userLocation-->")) as string
	set (contents of text view 1 of scroll view 1 of window "locationWindow") to myLocation_cont
end getMyLocation

on updateLocation()
	tell window "loginWindow"
		set myLoginEmail to (contents of text field "loginEmailInput")
		set myLoginPassword to (contents of text field "loginPasswordInput")
	end tell
	set myLocation_cont to (contents of text view 1 of scroll view 1 of window "locationWindow") as string
	set myLocationURL to (homeRootURL & "updateLocation.php") as string
	set myLocation to ("curl --form-string " & quoted form of ("strDesc=" & myLocation_cont) & " --form-string " & quoted form of ("email=" & myLoginEmail) & " --form-string " & quoted form of ("password=" & myLoginPassword) & " --form press=OK" & " -e 'audiMate.updateLocation' " & quoted form of (myLocationURL))
	--display dialog "" default answer myLocation
	set myLocation to (do shell script myLocation)
	return myLocation_cont
end updateLocation

(*END CUSTOM FUNCTIONS*)


on clicked theObject
	if the name of theObject is "locationHideButton" then
		set title of window "homeWindow" to "Home"
		close panel window "locationWindow"
	else if the name of theObject is "locationUpdateButton" then
		set myProfileData_location to updateLocation()
		set contents of text field "homeLocationText" of window "homeWindow" to (myProfileData_location)
		set title of window "homeWindow" to "Home"
		close panel window "locationWindow"
	end if
end clicked

on choose menu item theObject
	if the name of window 1 is "homeWindow" then
		if visible of progress indicator 1 of window "homeWindow" is false then
			if the name of theObject is "locationMenuItem" then
				set chosenAlias to (contents of text field "loggedInAsText" of window "homeWindow")
				set appsup to ((POSIX path of (path to me)) & ("Contents/Resources/")) as string
				set title of window "homeWindow" to "Edit Location"
				getMyLocation()
				display panel window "locationWindow" attached to window "homeWindow"
			end if
		end if
	end if
end choose menu item