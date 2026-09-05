-- Throwaway diagnostic, round three. Deleting a cue list.
--
-- The build now works. The cleanup empties the list but leaves the list
-- itself behind, and the delete sits inside a try so whatever QLab says
-- about it never reaches us. Each test below makes its own list, tries one
-- way of deleting it, and reports the error and whether the count actually
-- dropped. A form can fail quietly, so the count is what counts.
--
-- Run in Script Editor with the workspace open. Delete any leftover test
-- lists by hand afterwards.


on freshList(nm)
	tell application id "com.figure53.QLab.5"
		tell front workspace
			make type "Cue List"
			set q name of last cue list to nm
		end tell
	end tell
end freshList


on listCount()
	tell application id "com.figure53.QLab.5"
		tell front workspace
			return (count of (every cue list))
		end tell
	end tell
end listCount


-- J: delete the object itself, reached by position.
on testJ()
	freshList("DEL TEST J")
	set b to listCount()
	set msg to "no error"
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				delete last cue list
			on error e number n
				set msg to ("error " & n & " - " & e)
			end try
		end tell
	end tell
	return my verdict(msg, b)
end testJ


-- K: by name. This is what the cleanup cue does now.
on testK()
	freshList("DEL TEST K")
	set b to listCount()
	set msg to "no error"
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				delete cue list "DEL TEST K"
			on error e number n
				set msg to ("error " & n & " - " & e)
			end try
		end tell
	end tell
	return my verdict(msg, b)
end testK


-- L: by a whose clause on the name.
on testL()
	freshList("DEL TEST L")
	set b to listCount()
	set msg to "no error"
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				delete (first cue list whose q name is "DEL TEST L")
			on error e number n
				set msg to ("error " & n & " - " & e)
			end try
		end tell
	end tell
	return my verdict(msg, b)
end testL


-- M: by unique id, which the workspace lists as one of the ways in.
on testM()
	freshList("DEL TEST M")
	set b to listCount()
	set msg to "no error"
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				set u to uniqueID of last cue list
				delete cue list id u
			on error e number n
				set msg to ("error " & n & " - " & e)
			end try
		end tell
	end tell
	return my verdict(msg, b)
end testM


on verdict(msg, wasCount)
	set nowCount to listCount()
	if nowCount < wasCount then return "GONE. " & msg
	return "STILL THERE. " & msg
end verdict


on runTests()
	set out to {}
	set end of out to "J " & testJ()
	set end of out to "K " & testK()
	set end of out to "L " & testL()
	set end of out to "M " & testM()
	return out
end runTests

runTests()
