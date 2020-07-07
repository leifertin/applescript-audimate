
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

on getInitialList(initialListType)
	if initialListType is "iTunes" then
		tell application "iTunes"
			set artistNames to artist of every track of library playlist 1
			--set theLibrary to view of browser window 1
			--set theList to (artist of every track in theLibrary)
		end tell
	else if initialListType is "MyVinyl" then
		tell application "MyVinyl"
			set myIMPTable to (table view 1 of scroll view 1 of view 1 of split view "topSplitView" of tab view item ("haveTab") of tab view 1 of view 1 of split view "mainSplitView" of window "mainList")
			set artistNames to (contents of data cell "artistColumn" of every data row of data source of myIMPTable)
		end tell
		--display dialog "myArtist" default answer myArtist
	end if
	return artistNames
end getInitialList

on returniTunesArtists(myImpApp)
	set visible of progress indicator 1 of window "homeWindow" to true
	
	set list1 to getInitialList(myImpApp)
	
	set list2 to {}
	repeat with x from 1 to count of items of list1
		set n to item x of list1
		if n is not in list2 then set end of list2 to n
	end repeat
	copy list2 to myAppArtistList
	set myAppArtistList to cleanMyList(myAppArtistList, {""})
	if myImpApp is "MyVinyl" then
		set myAppArtistList to alphabetize(myAppArtistList)
	end if
	set visible of progress indicator 1 of window "homeWindow" to false
	
	set content of table view 1 of scroll view 1 of tab view item "artistsTab" of tab view 1 of window "homeWindow" to myAppArtistList
	--CLEAN OUT BLANKS AND DUPES
end returniTunesArtists
(*END CUSTOM FUNCTIONS*)



on clicked theObject
	if the name of theObject is "homeGetiTunesList" then
		returniTunesArtists((title of theObject as string))
		set visible of button "artistsTabSyncButton" of tab view item "artistsTab" of tab view 1 of window "homeWindow" to true
	else if the name of theObject is "homeGetMyVinylList" then
		returniTunesArtists((title of theObject as string))
		set visible of button "artistsTabSyncButton" of tab view item "artistsTab" of tab view 1 of window "homeWindow" to true
	end if
end clicked