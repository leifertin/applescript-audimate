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

on createMe()
	tell window "registerWindow"
		set contents of text field "registerErrorText" to ""
		set myReg_email to (contents of text field "registerEmailInput") as string
		if myReg_email is not "" then
			set myReg_alias to (contents of text field "registerAliasInput") as string
			if myReg_alias is not "" then
				set myReg_password to (contents of text field "registerPasswordInput") as string
				if myReg_password is not "" then
					set myReg_password_c to (contents of text field "registerPasswordConfirmInput") as string
					if myReg_password_c is not "" then
						if (myReg_password is not equal to myReg_password_c) then
							set contents of text field "registerErrorText" to "Your passwords do not match."
						end if
						set myReg_gender to (current row of matrix "registerGenderMatrix") as string
						if myReg_gender is "1" then
							set myReg_gender to "Male"
						else if myReg_gender is "2" then
							set myReg_gender to "Female"
						end if
					else
						set contents of text field "registerErrorText" to "You provided no confirmation password."
					end if
				else
					set contents of text field "registerErrorText" to "You provided no password."
				end if
			else
				set contents of text field "registerErrorText" to "You provided no alias."
			end if
		else
			set contents of text field "registerErrorText" to "You provided no email."
		end if
	end tell
	
	if (contents of text field "registerErrorText" of window "registerWindow") is "" then
		set myCreationURL to (homeRootURL & "createMe.php") as string
		set myCreation to ("curl --data-urlencode " & quoted form of ("myEmail=" & myReg_email) & " --data " & quoted form of ("myAlias=" & myReg_alias) & " --data " & quoted form of ("myPassword=" & myReg_password) & " --data " & quoted form of ("myGender=" & myReg_gender) & " -e 'audiMate.makeYourself' " & quoted form of (myCreationURL))
		--display dialog "myCreation" default answer myCreation
		set myCreation to (do shell script myCreation)
		set (contents of text field "registerErrorText" of window "registerWindow") to myCreation
		--return myCreation
	end if
end createMe

on deleteMe(myDelEmail, myDelPassword)
	set myDeleteURL to (homeRootURL & "deleteMe.php")
	set myDeletionResult to (do shell script ("curl --data " & quoted form of ("email=" & myDelEmail & "&password=" & myDelPassword) & " -e 'audiMate.deleteMe' " & quoted form of myDeleteURL)) as string
	return myDeletionResult
end deleteMe

(*END CUSTOM FUNCTIONS*)


on clicked theObject
	if the name of theObject is "registerCancelButton" then
		set title of window "loginWindow" to "Login"
		close panel window "registerWindow"
	else if the name of theObject is "registerCreateButton" then
		createMe()
	else if the name of theObject is "register18Check" then
		if (the state of theObject as string) is "0" then
			set enabled of button "registerCreateButton" of window "registerWindow" to false
		else
			set enabled of button "registerCreateButton" of window "registerWindow" to true
		end if
	end if
end clicked

on choose menu item theObject
	set windowOneName to (the name of window 1)
	if windowOneName is "homeWindow" then
		if visible of progress indicator 1 of window "homeWindow" is false then
			if the name of theObject is "locationMenuItem" then
				set chosenAlias to (contents of text field "loggedInAsText" of window "homeWindow")
				set appsup to ((POSIX path of (path to me)) & ("Contents/Resources/")) as string
				set title of window "homeWindow" to "Edit Location"
				getMyLocation()
				display panel window "locationWindow" attached to window "homeWindow"
			end if
		end if
		if the name of theObject is "deleteMeMI" then
			tell window "loginWindow"
				set myEmail to (contents of text field "loginEmailInput")
				set myPassword to (contents of text field "loginPasswordInput")
			end tell
			
			display dialog ("Are you sure you wish to delete yourself?") buttons {"No", "Yes"} default button 1
			if ((button returned of result) as string) is "Yes" then
				display dialog ("You must manually forget each conversation, or they will stay there. All other information about you will be deleted automatically.") buttons {"Cancel", "Continue"} default button 1
				if ((button returned of result) as string) is "Continue" then
					display dialog ("This cannot be reversed!
You can not change your mind about this!
Are you still sure?") buttons {"No...", "Yes!"} default button 1
					if ((button returned of result) as string) is "Yes!" then
						set delRes to (deleteMe(myEmail, myPassword)) as string
						if delRes is "You now cease to exist." then
							show window "loginWindow"
							hide window windowOneName
							display alert "You now cease to exist..." attached to window "loginWindow"
						else
							display alert "There was an error with the deletion process." attached to window windowOneName
						end if
					end if
				end if
			end if
		else if the name of theObject is "activateMeMI" then
			open location (homeRootURL & "activate")
		end if
	end if
end choose menu item