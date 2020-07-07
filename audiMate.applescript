
global myLoginEmail, myLoginAlias, myLoginPassword, loggedIn, appsup, homeRootURL, myConversationID, conversationsTab_DataSource

property homeRootURL : "http://audimate.me/"

(*START CUSTOM FUNCTIONS*)

(*START Common Functions*)
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
(*END Common Functions*)

on toggleVisibleLoginItems(toggleAction)
	tell window "loginWindow"
		set myLoginEmail to (contents of text field "loginEmailInput")
		set myLoginPassword to (contents of text field "loginPasswordInput")
		if toggleAction is "idle" then
			set visible of text field "audiMateLoginTitle" to true
			set visible of text field "loginLoadingText" to false
			set visible of button "loginButton" to true
			set visible of button "registerButton" to true
			set visible of text field "loginEmailInput" to true
			set visible of text field "loginPasswordInput" to true
			--set visible of text field "loginPasswordLabelText" to true
			--set visible of text field "loginEmailLabelText" to true
		else if toggleAction is "active" then
			set visible of text field "audiMateLoginTitle" to false
			set visible of text field "loginLoadingText" to true
			set visible of button "loginButton" to false
			set visible of button "registerButton" to false
			set visible of text field "loginEmailInput" to false
			set visible of text field "loginPasswordInput" to false
			--set visible of text field "loginPasswordLabelText" to false
			--set visible of text field "loginEmailLabelText" to false
		end if
	end tell
end toggleVisibleLoginItems

on load_portrait(myAlias, outputWindow)
	if outputWindow is "profileWindow" then
		set myImageViewName to "portraitProfile"
	else if outputWindow is "homeWindow" then
		set myImageViewName to "portraitHome"
	else if outputWindow is "conversationWindow" then
		set myImageViewName to "portraitConversation"
	end if
	
	set myPortraitURL to (homeRootURL & "displayPortrait.php") as string
	set myPortrait_f to (appsup & "currentPortrait.jpeg") as string
	
	try
		do shell script ("rm  " & quoted form of myPortrait_f)
	end try
	
	set myPortraitData to ("curl --data " & quoted form of ("alias=" & myAlias) & " -e 'audiMate.displayPortrait' " & quoted form of myPortraitURL & " -o " & quoted form of myPortrait_f)
	set myPortraitData to (do shell script myPortraitData)
	
	try
		set image of image view myImageViewName of window outputWindow to load image (appsup & "currentPortrait.jpeg")
	on error
		set image of image view myImageViewName of window outputWindow to load image ("NSUser")
	end try
	
end load_portrait

on load_userTracks(myLoginAlias, outputWindow)
	if outputWindow is "homeWindow" then
		set trackTable to (table view 1 of scroll view 1 of tab view item "artistsTab" of tab view 1 of window "homeWindow")
		--DELETE OLD DATA SOURCE
		try
			delete data source artistsTab_DataSource
		end try
	else
		set trackTable to (table view 1 of scroll view 1 of window "profileWindow")
		set visible of scroll view 1 of window "profileWindow" to true
		--DELETE OLD DATA SOURCE
		try
			delete data source profileTracks_DataSource
		end try
	end if
	
	
	set myArtistsURL to (homeRootURL & "getMyArtists.php") as string
	set myArtists to (do shell script ("curl --data " & quoted form of ("alias=" & myLoginAlias) & " -e 'audiMate.getMyArtists' " & quoted form of myArtistsURL)) as string
	if myArtists is "0" then
		--HIDE TABLE
		if outputWindow is "profileWindow" then
			set visible of scroll view 1 of window outputWindow to false
			set contents of text field "profileNoInterests" of window outputWindow to (myLoginAlias & " has no interests.")
			--set visible of trackTable to false
		end if
	else
		set visible of trackTable to true
		set myArtists to every paragraph of myArtists
		set myArtists to cleanMyList(myArtists, {""})
		if outputWindow is "homeWindow" then
			--CREATE NEW ONE
			set artistsTab_DataSource to make new data source at end of data sources
			tell artistsTab_DataSource
				make new data column at end of data columns with properties {name:"artistName", sort order:ascending, sort type:alphabetical, sort case sensitivity:case sensitive}
			end tell
			
			set data source of trackTable to artistsTab_DataSource
			
			--POPULATE DATA SOURCE
			
			repeat with myRepeatVar from 1 to (count myArtists)
				tell artistsTab_DataSource
					make new data row at end of data rows
					set contents of data cell "artistName" of data row myRepeatVar to (item myRepeatVar of myArtists as string)
				end tell
			end repeat
		else
			--CREATE NEW ONE
			set profileTracks_DataSource to make new data source at end of data sources
			tell profileTracks_DataSource
				make new data column at end of data columns with properties {name:"artistName", sort order:ascending, sort type:alphabetical, sort case sensitivity:case sensitive}
			end tell
			
			set data source of trackTable to profileTracks_DataSource
			
			--POPULATE DATA SOURCE
			
			repeat with myRepeatVar from 1 to (count myArtists)
				tell profileTracks_DataSource
					make new data row at end of data rows
					set contents of data cell "artistName" of data row myRepeatVar to (item myRepeatVar of myArtists as string)
				end tell
			end repeat
		end if
	end if
end load_userTracks

on load_userMates(myLoginAlias)
	
	set myArtistsURL to (homeRootURL & "getMyMates.php") as string
	set myMates to (do shell script ("curl --data " & quoted form of ("alias=" & myLoginAlias) & " -e 'audiMate.getMyMates' " & quoted form of myArtistsURL)) as string
	set myMates to every paragraph of myMates
	set myMates to alphabetize(myMates)
	set myMates to cleanMyList(myMates, {""})
	set content of (table view 1 of scroll view 1 of tab view item "matesTab" of tab view 1 of window "homeWindow") to myMates
	
end load_userMates

on updateMates(myMateAction, myMate_alias)
	
	set myMates to (contents of data cell 1 of every data row of data source of table view 1 of scroll view 1 of tab view item "matesTab" of tab view 1 of window "homeWindow")
	
	if myMateAction is "Forget" then
		set myMates to cleanMyList(myMates, {myMate_alias})
	else
		set myMates to myMates & myMate_alias
	end if
	set myMatesCount to (count myMates)
	--ECHO TO TEXT FILE
	
	set myMates_f to (appsup & "myMates_temp.txt") as string
	
	do shell script ("echo  > " & quoted form of myMates_f)
	repeat with matesLoopV from 1 to (myMatesCount)
		set myCurrentMate to (item matesLoopV of myMates) as string
		do shell script ("echo " & quoted form of myCurrentMate & " >> " & quoted form of myMates_f)
	end repeat
	
	set myPostMatesURL to (homeRootURL & "updateMates.php") as string
	set myPostMates to ("curl --form-string " & quoted form of ("strDesc=" & myLoginAlias) & " --form-string " & quoted form of ("email=" & myLoginEmail) & " --form-string " & quoted form of ("password=" & myLoginPassword) & " --form " & quoted form of ("fileUpload=@" & myMates_f) & " --form press=OK" & " -e 'audiMate.updateMates' " & quoted form of (myPostMatesURL))
	
	do shell script myPostMates
	
	try
		do shell script ("rm  " & quoted form of myMates_f)
	end try
	
	load_userMates(myLoginAlias)
end updateMates

on updateConversation(myConvoAction)
	set chosenAlias to (title of window "homeWindow") as string
	
	if myConvoAction is "Create" then
		set chosenAlias to (split(chosenAlias, "'s profile")) as string
		set myPostConvoURL to (homeRootURL & "createConversation.php") as string
		set myPostConvo to ("curl --form-string " & quoted form of ("theirAlias=" & chosenAlias) & " --form-string " & quoted form of ("email=" & myLoginEmail) & " --form-string " & quoted form of ("password=" & myLoginPassword) & " --form press=OK" & " -e 'audiMate.createConversation' " & quoted form of (myPostConvoURL))
		do shell script myPostConvo
		close panel window "profileWindow"
	else if myConvoAction is "Forget" then
		set chosenAlias to (split(chosenAlias, "Conversation with ")) as string
		set myPostConvoURL to (homeRootURL & "forgetConversation.php") as string
		set myPostConvo to ("curl --form-string " & quoted form of ("strDesc=" & myConversationID) & " --form-string " & quoted form of ("email=" & myLoginEmail) & " --form-string " & quoted form of ("password=" & myLoginPassword) & " --form press=OK" & " -e 'audiMate.forgetConversation' " & quoted form of (myPostConvoURL))
		do shell script myPostConvo
		close panel window "conversationWindow"
	else if myConvoAction is "Reply" then
		set chosenAlias to (split(chosenAlias, "Conversation with ")) as string
		set myConversationData to display_conversation_head(chosenAlias)
		set myAddedConversationData to (the contents of text view 1 of scroll view 1 of view 2 of split view 1 of window "conversationWindow") as string
		set (the contents of text view 1 of scroll view 1 of view 2 of split view 1 of window "conversationWindow") to ""
		set myAddedConversationData to (myLoginAlias & ": " & myAddedConversationData & (ASCII character 10) & (ASCII character 10)) as string
		--ECHO TO TEXT FILE
		set myConvo_f to (appsup & "myConvo_temp.txt") as string
		do shell script ("echo " & quoted form of myConversationData & " > " & quoted form of myConvo_f)
		do shell script ("echo " & quoted form of myAddedConversationData & " >> " & quoted form of myConvo_f)
		
		set myPostConvoURL to (homeRootURL & "updateConversation.php") as string
		set myPostConvo to ("curl --form-string " & quoted form of ("strDesc=" & myConversationID) & " --form-string " & quoted form of ("email=" & myLoginEmail) & " --form-string " & quoted form of ("password=" & myLoginPassword) & " --form " & quoted form of ("fileUpload=@" & myConvo_f) & " --form press=OK" & " -e 'audiMate.updateConversation' " & quoted form of (myPostConvoURL))
		
		do shell script myPostConvo
		
		try
			do shell script ("rm  " & quoted form of myConvo_f)
		end try
		set the contents of text view 1 of scroll view 1 of view 1 of split view 1 of window "conversationWindow" to (myConversationData & (ASCII character 10) & myAddedConversationData)
	end if
	if myConvoAction is not "Reply" then
		set the title of window "homeWindow" to "Home"
	end if
	load_userConversations(myLoginAlias)
end updateConversation

on updatePortrait(myPortraitPath, outputWindow)
	set myPortraitSize to (size of (info for myPortraitPath))
	if myPortraitSize is less than 151000 then
		if getFileType(myPortraitPath) is "JPEG image" then
			set myPortraitURL to (homeRootURL & "updatePortrait.php") as string
			set myPortrait to ("curl --form-string " & quoted form of ("email=" & myLoginEmail) & " --form-string " & quoted form of ("password=" & myLoginPassword) & " --form " & quoted form of ("fileUpload=@" & myPortraitPath) & " --form press=OK" & " -e 'audiMate.updatePortrait' " & quoted form of (myPortraitURL))
			
			set myPortrait to (do shell script myPortrait)
			if myPortrait is "0" then
				display alert "Error: something went wrong with the upload." attached to window "homeWindow"
				
			else if myPortrait ends with "is a user but does not exist in portraits." then
				display alert myPortrait attached to window "homeWindow"
			end if
			load_portrait(myLoginAlias, outputWindow)
		else
			display alert "Error: only JPEGs are supported." attached to window "homeWindow"
		end if
	else
		display alert "Error: your portrait must be less than 150KB." attached to window "homeWindow"
	end if
end updatePortrait

on display_userProfile(chosenAlias)
	if chosenAlias is not "" then
		--Fetch Profile
		set myProfileData to getMyDetails(chosenAlias)
		if myProfileData is "0" then
			display alert "This user does not exist." attached to window "homeWindow"
		else
			set myProfileData_location to item 2 of (split(myProfileData, "<--userLocation-->")) as string
			set myProfileData_gender to item 2 of (split(myProfileData, "<--userGender-->")) as string
			
			copy chosenAlias to myProfileData_alias
			
			set title of window "homeWindow" to (myProfileData_alias & "'s profile") as string
			
			tell window "profileWindow"
				set contents of text field "profileLocationText" to ((myProfileData_location) as string)
				set contents of text field "profileGenderText" to ((myProfileData_gender) as string)
			end tell
			
			load_portrait(chosenAlias, "profileWindow")
			load_userTracks(chosenAlias, "profileWindow")
			
			
			--SET BUTTON TO REMEMBER/FORGET
			copy myProfileData_alias to myMate_alias
			--GOT MATE NAME
			set myMates to (contents of data cell 1 of every data row of data source of table view 1 of scroll view 1 of tab view item "matesTab" of tab view 1 of window "homeWindow")
			set myMatesCount to (count myMates)
			set myMates to cleanMyList(myMates, {myMate_alias})
			if (count myMates) is equal to myMatesCount then
				set the title of button "profileRememberForgetButton" of window "profileWindow" to "Remember"
			else
				set the title of button "profileRememberForgetButton" of window "profileWindow" to "Forget"
			end if
			
			--GET SOUNDBITE
			display panel window "profileWindow" attached to window "homeWindow"
			
		end if
	end if
end display_userProfile


on load_userConversations(theGivenAlias)
	set myConversationsURL to (homeRootURL & "getMyConversations.php") as string
	set visible of progress indicator 1 of window "homeWindow" to true
	
	set myConversationsCURL to ("curl --data-urlencode " & quoted form of ("alias=" & theGivenAlias) & " -e 'audiMate.getMyConversations' " & quoted form of (myConversationsURL)) as string
	set myConversationsCURLed to (do shell script (myConversationsCURL)) as string
	
	if myConversationsCURLed is "0" then
		set myConversations_dbTemp to {}
	else
		set myConversations_dbTemp to every paragraph of myConversationsCURLed
	end if
	
	set myConversations_time to {}
	set myConversations_alias to {}
	set myConversations_deleted to {}
	
	repeat until myConversations_dbTemp is {}
		set myConversations_time to myConversations_time & (item 1 of myConversations_dbTemp)
		set myConversations_dbTemp to rest of myConversations_dbTemp
		set myConversations_alias to myConversations_alias & (item 1 of myConversations_dbTemp)
		set myConversations_dbTemp to rest of myConversations_dbTemp
		set myConversations_deleted to myConversations_deleted & (item 1 of myConversations_dbTemp)
		set myConversations_dbTemp to rest of myConversations_dbTemp
	end repeat
	
	--FINISHED SPLITTING INTO COLUMNS
	
	--DELETE OLD DATA SOURCE
	try
		delete data source conversationsTab_DataSource
	end try
	--CREATE NEW ONE
	set conversationsTab_DataSource to make new data source at end of data sources
	tell conversationsTab_DataSource
		make new data column at end of data columns with properties {name:"lastActivity", sort order:ascending, sort type:alphabetical, sort case sensitivity:case sensitive}
		make new data column at end of data columns with properties {name:"alias", sort order:ascending, sort type:alphabetical, sort case sensitivity:case sensitive}
	end tell
	
	set data source of (table view 1 of scroll view 1 of tab view item "conversationsTab" of tab view 1 of window "homeWindow") to conversationsTab_DataSource
	
	--POPULATE DATA SOURCE
	set myDataRowser to 0
	repeat with myRepeatVar from 1 to (count myConversations_time)
		set myDataRowser to (myDataRowser + 1)
		tell conversationsTab_DataSource
			if (item myRepeatVar of myConversations_deleted as string) is not myLoginAlias then
				make new data row at end of data rows
				set contents of data cell "lastActivity" of data row myDataRowser to (item myRepeatVar of myConversations_time as string)
				set contents of data cell "alias" of data row myDataRowser to (item myRepeatVar of myConversations_alias as string)
			else
				set myDataRowser to (myDataRowser - 1)
			end if
		end tell
	end repeat
	set visible of progress indicator 1 of window "homeWindow" to false
end load_userConversations

on display_conversation(chosenAlias)
	if chosenAlias is not "" then
		set myConversationData to display_conversation_head(chosenAlias)
		set the contents of text view 1 of scroll view 1 of view 1 of split view 1 of window "conversationWindow" to myConversationData
		set myProfileData to getMyDetails(chosenAlias)
		copy chosenAlias to myProfileData_alias
		if myProfileData is "0" then
			set myProfileData_location to ""
			set myProfileData_gender to ""
		else
			set myProfileData_location to item 2 of (split(myProfileData, "<--userLocation-->")) as string
			set myProfileData_gender to item 2 of (split(myProfileData, "<--userGender-->")) as string
		end if
		tell window "conversationWindow"
			set contents of text field "conversationLocationText" to ((myProfileData_location) as string)
			set contents of text field "conversationGenderText" to ((myProfileData_gender) as string)
		end tell
		load_portrait(chosenAlias, "conversationWindow")
		
		set title of window "homeWindow" to ("Conversation with " & chosenAlias) as string
		try
			display panel window "conversationWindow" attached to window "homeWindow"
		end try
	end if
end display_conversation

on getMySoundbite(myAlias)
	set mySoundbiteURL to (homeRootURL & "displaySoundbite.php") as string
	set mySoundbite_f to (appsup & "mySoundbite_temp.mp3") as string
	set mySoundbiteData to ("curl --data " & quoted form of ("alias=" & myAlias) & " -e 'audiMate.displaySoundbite' " & quoted form of mySoundbiteURL & " -o " & quoted form of mySoundbite_f)
	set mySoundbiteData to (do shell script mySoundbiteData)
	set mySoundbiteURL to ("file://" & mySoundbite_f) as string
	
	set visible of view "soundbitePreview" of window "profileWindow" to true
	loadPage from mySoundbiteURL
	set visible of view "soundbitePreview" of window "profileWindow" to false
	set content of text field "soundbiteErrorText" of window "profileWindow" to "Playing"
	delay 3
	set content of text field "soundbiteErrorText" of window "profileWindow" to ""
end getMySoundbite

on loadPage from theURL
	set URLWithString to call method "URLWithString:" of class "NSURL" with parameter theURL
	set requestWithURL to call method "requestWithURL:" of class "NSURLRequest" with parameter URLWithString
	tell window "profileWindow"
		set mainFrame to call method "mainFrame" of object (view "soundbitePreview")
	end tell
	call method "loadRequest:" of mainFrame with parameter requestWithURL
end loadPage

on display_conversation_head(chosenAlias)
	set myConversationURL to (homeRootURL & "displayConversation.php") as string
	set myConversationData to (do shell script ("curl --data " & quoted form of ("alias=" & myLoginAlias) & " --data " & quoted form of ("otherAlias=" & chosenAlias) & " -e 'audiMate.displayConversation' " & quoted form of myConversationURL)) as string
	
	set myConversationData_l to split(myConversationData, "<--StrtMssg_{" & myLoginAlias & "}:{" & chosenAlias & "}.[")
	set myConversationData_l_count to (count myConversationData_l)
	set myConversationData_l to split(((item 2 of myConversationData_l) as string), "]-->")
	
	if (myConversationData_l_count) is greater than 2 then
		set enabled of button "conversationReplyButton" of window "conversationWindow" to false
	else
		set enabled of button "conversationReplyButton" of window "conversationWindow" to true
	end if
	
	set myConversationID to item 1 of myConversationData_l as string
	set myConversationData to item 2 of myConversationData_l as string
	
	return myConversationData
end display_conversation_head

on getMyDetails(chosenAlias)
	set myProfileURL to (homeRootURL & "getMyDetails.php") as string
	set myProfileData to (do shell script ("curl --data " & quoted form of ("alias=" & chosenAlias) & " -e 'audiMate.getMyDetails' " & quoted form of myProfileURL)) as string
	return myProfileData
end getMyDetails

on updateMePlusLaunch()
	set otherScript to useOtherScript("updateApp")
	tell otherScript to updateMePlus(true)
end updateMePlusLaunch

on useOtherScript(scriptNameID)
	tell me
		set otherScript to POSIX file ((appsup & "Scripts/" & scriptNameID & ".scpt") as string)
		--set otherScript to ((path for script scriptNameID) as string)
	end tell
	set otherScript to load script (otherScript)
	return otherScript
end useOtherScript
(*
END CUSTOM FUNCTIONS
*)


on clicked theObject
	if the name of theObject is "loginButton" then
		set myLoginURL to (homeRootURL & "login.php") as string
		toggleVisibleLoginItems("idle")
		try
			set myLoginAlias to (do shell script ("curl --data " & quoted form of ("email=" & myLoginEmail & "&password=" & myLoginPassword) & " -e 'audiMate.login' " & quoted form of myLoginURL)) as string
			
			if myLoginAlias is not "0" then
				set loggedIn to "1"
			else
				set loggedIn to "0"
			end if
		on error number 6
			display dialog "Please connect your computer to the internet." attached to window "loginWindow" buttons {"OK"} default button 1
			set loggedIn to "0"
		end try
		
		if loggedIn is "0" then
			set loggedIn to false
			beep
		else if loggedIn is "1" then
			set loggedIn to true
			
			toggleVisibleLoginItems("active")
			update window "loginWindow"
			
			
			set enabled of menu item "activateMeMI" of last menu of main menu to true
			set enabled of menu item "deleteMeMI" of last menu of main menu to true
			set enabled of menu item "forgotPWMI" of last menu of main menu to false
			
			--Fetch Profile
			set myProfileData to getMyDetails(myLoginAlias)
			--display dialog "myProfileData" default answer myProfileData
			set myProfileData_location to item 2 of (split(myProfileData, "<--userLocation-->")) as string
			set myActivationStatus to item 2 of (split(myProfileData, "<--userStatus-->")) as string
			--display dialog "status" default answer myActivationStatus
			
			--Get Activation Status from getMyDetails()
			if myActivationStatus is "cc.309" then
				set contents of text field "varsWindowStatus" of window "varsWindow" to "0"
				set enabled of menu item "activateMeMI" of last menu of main menu to true
			else if myActivationStatus is "b0i9" then
				set contents of text field "varsWindowStatus" of window "varsWindow" to "1"
				tell menu item "activateMeMI" of last menu of main menu
					set enabled to false
					set title to "Activated - Thank you!"
				end tell
			end if
			
			
			
			set myActivationStatus to (contents of text field "varsWindowStatus" of window "varsWindow") as string
			
			tell progress indicator 1 of window "homeWindow" to start
			tell window "homeWindow"
				set contents of text field "loggedInAsText" to (myLoginAlias)
				set contents of text field "homeLocationText" to (myProfileData_location)
			end tell
			load_portrait(myLoginAlias, "homeWindow")
			
			set visible of progress indicator 1 of window "homeWindow" to true
			show window "homeWindow"
			hide window "loginWindow"
			toggleVisibleLoginItems("idle")
			load_userTracks(myLoginAlias, "homeWindow")
			load_userMates(myLoginAlias)
			load_userConversations(myLoginAlias)
			
			set visible of progress indicator 1 of window "homeWindow" to false
			
			set visible of tab view 1 of window "homeWindow" to true
			
			updateMePlusLaunch()
		end if
	else if the name of theObject is "locateTabViewButton" then
		tell tab view item "locateTab" of tab view 1 of window "homeWindow"
			try
				set chosenAlias to (contents of data cell "alias" of selected data row of table view 1 of scroll view 1) as string
			on error number (-1700)
				set chosenAlias to ""
			end try
		end tell
		display_userProfile(chosenAlias)
	else if the name of theObject is "profileHideButton" then
		set title of window "homeWindow" to "Home" as string
		close panel window "profileWindow"
	else if the name of theObject is "conversationHideButton" then
		set title of window "homeWindow" to "Home" as string
		close panel window "conversationWindow"
	else if the name of theObject is "registerButton" then
		set title of window "loginWindow" to "Make Yourself"
		set contents of text field "registerErrorText" of window "registerWindow" to ""
		display panel window "registerWindow" attached to window "loginWindow"
	else if the name of theObject is "profileRememberForgetButton" then
		--GET MATE NAME FROM WINDOW 1 (Profile)
		set myMate_alias to (title of window "homeWindow") as string
		set myMate_alias to (split(myMate_alias, "'s profile")) as string
		--GOT MATE NAME
		updateMates(((title of theObject) as string), myMate_alias)
		if the title of theObject is "Remember" then
			set the title of theObject to "Forget"
		else if the title of theObject is "Forget" then
			set the title of theObject to "Remember"
		end if
	else if the name of theObject is "matesTabViewButton" then
		tell tab view item "matesTab" of tab view 1 of window "homeWindow"
			try
				set chosenAlias to (contents of data cell 1 of selected data row of table view 1 of scroll view 1) as string
			on error number (-1700)
				set chosenAlias to ""
			end try
		end tell
		display_userProfile(chosenAlias)
	else if the name of theObject is "conversationsTabViewButton" then
		tell tab view item "conversationsTab" of tab view 1 of window "homeWindow"
			try
				set chosenAlias to (contents of data cell "alias" of selected data row of table view 1 of scroll view 1) as string
			on error number (-1700)
				set chosenAlias to ""
			end try
		end tell
		display_conversation(chosenAlias)
	else if the name of theObject is "conversationReplyButton" then
		updateConversation("Reply")
	else if the name of theObject is "conversationForgetButton" then
		updateConversation("Forget")
	else if the name of theObject is "profileConverseButton" then
		--GET LIST OF CONVO ALIASes
		set chosenAlias to (title of window "homeWindow") as string
		set chosenAlias to (split(chosenAlias, "'s profile")) as string
		
		set updateConvo to true
		set myConvoAliases to (contents of data cell "alias" of every data row of data source of table view 1 of scroll view 1 of tab view item "conversationsTab" of tab view 1 of window "homeWindow")
		repeat with myCNVOLoop from 1 to (count myConvoAliases)
			if (item myCNVOLoop of myConvoAliases as string) is chosenAlias then
				display alert ("You already have a conversation going with " & chosenAlias)
				set updateConvo to false
				exit repeat
			end if
		end repeat
		if updateConvo is true then
			updateConversation("Create")
		end if
	else if the name of theObject is "profileHearButton" then
		set chosenAlias to (title of window "homeWindow")
		set chosenAlias to (split(chosenAlias, "'s profile")) as string
		
		getMySoundbite(chosenAlias)
	else if the name of theObject is "matesTabForgetButton" then
		--GET MATE NAME FROM WINDOW 1 (Profile)
		tell tab view item "matesTab" of tab view 1 of window "homeWindow"
			try
				set chosenAlias to (contents of data cell 1 of selected data row of table view 1 of scroll view 1) as string
			on error number (-1700)
				set chosenAlias to ""
			end try
		end tell
		if chosenAlias is not "" then
			set myButton_t to (display dialog ("Are you sure you wish to forget " & chosenAlias & "?") buttons {"No", "Yes"} default button 1 with icon 0)
			set myButton_c to (button returned of myButton_t)
			
			if myButton_c is "Yes" then
				updateMates("Forget", chosenAlias)
			end if
		end if
	end if
end clicked

on should quit after last window closed theObject
	return true
end should quit after last window closed

on action theObject
	(**)
end action

on selection changed theObject
	(**)
end selection changed

on should quit theObject
	set myPortrait_f to (appsup & "currentPortrait.jpeg") as string
	set mySoundbite_f to (appsup & "mySoundbite_temp.mp3") as string
	try
		do shell script ("rm  " & quoted form of myPortrait_f)
	end try
	try
		do shell script ("rm  " & quoted form of mySoundbite_f)
	end try
	return true
end should quit


on launched theObject
	set visible of text field "loginLoadingText" of window "loginWindow" to false
	show window "loginWindow"
	
	set appsup to ((POSIX path of (path to me)) & ("Contents/Resources/")) as string
	
end launched

on should close theObject
	hide theObject
	return false
end should close

on drop theObject drag info dragInfo
	if the name of theObject is "portraitHome" then
		--UPDATE MY PORTRAIT
		set preferred type of pasteboard of dragInfo to "file names"
		set myPortraitPath to (contents of pasteboard of dragInfo)
		updatePortrait(myPortraitPath, "homeWindow")
	end if
end drop

on should select tab view item theObject tab view item tabViewItem
	if the name of theObject is "homeTabView" then
		if visible of progress indicator 1 of window "homeWindow" is true then
			return false
		else
			return true
		end if
	end if
end should select tab view item
