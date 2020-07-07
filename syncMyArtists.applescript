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
(*End Common Functions*)

on sync_myArtists()
	set myHomeDate to (get (month of (current date)) as integer) as string
	set myLoginAlias to (contents of text field "loggedInAsText" of window "homeWindow")
	set appsup to ((POSIX path of (path to me)) & ("Contents/Resources/")) as string
	
	(*LOAD myARTISTS Locally*)
	set myArtists to (contents of data cell 1 of every data row of data source of table view 1 of scroll view 1 of tab view item "artistsTab" of tab view 1 of window "homeWindow")
	(*DONE LOADING myARTISTS Locally*)
	set myARTISTScount to (count myArtists)
	set myArtistsURL to (homeRootURL & "syncArtists.php") as string
	set visible of progress indicator 1 of window "homeWindow" to true
	
	set myArtists_f to (appsup & "myArtists_temp.txt") as string
	do shell script ("echo  > " & quoted form of myArtists_f)
	repeat with artistsLoopV from 1 to (myARTISTScount)
		set myCurrentArtist to (item artistsLoopV of myArtists) as string
		do shell script ("echo " & quoted form of myCurrentArtist & " >> " & quoted form of myArtists_f)
	end repeat
	set myCommonArtistsCURL to ("curl --data " & quoted form of ("month=" & myHomeDate & "&alias=" & myLoginAlias) & " --data-urlencode " & quoted form of ("artistList@" & myArtists_f) & " -e 'audiMate.syncArtists' " & quoted form of myArtistsURL) as string
	if ((do shell script myCommonArtistsCURL) as string) is "1" then
		try
			say "success"
		end try
	else
		try
			say "failure"
		end try
	end if
	set visible of progress indicator 1 of window "homeWindow" to false
end sync_myArtists

on update_progress(iteration, total_count, pbarName, windowVar)
	tell window windowVar
		set currentTab to name of current tab view item of tab view 1
		tell tab view item (currentTab) of tab view 1
			if iteration = 0 then
				set visible of progress indicator pbarName to false
			else
				set visible of progress indicator pbarName to true
			end if
			if iteration = 1 then
				tell progress indicator pbarName to start
				set indeterminate of progress indicator pbarName to true
			else
				tell progress indicator pbarName to stop
				set indeterminate of progress indicator pbarName to false
			end if
			set maximum value of progress indicator pbarName to total_count
			set content of progress indicator pbarName to iteration
		end tell
		update
	end tell
end update_progress
(*END CUSTOM FUNCTIONS*)


on clicked theObject
	if the name of theObject is "artistsTabSyncButton" then
		set visible of theObject to false
		sync_myArtists()
	end if
end clicked

