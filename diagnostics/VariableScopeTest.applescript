-- Throwaway diagnostic for the -2753 error on theList.
--
-- Four ways of holding a newly made cue list in a variable. One of them is
-- what the main script does now. Run this in Script Editor with the
-- workspace open and read the Result pane. Whichever ones come back FAILED
-- tell us which construct QLab will not accept, so the fix stops being a
-- guess.
--
-- It leaves up to four empty cue lists behind. Delete them by hand after.


-- A: sentinel set outside the tell, list made inside, read inside.
-- This is what buildPreShow does today.
on testA()
	set L to missing value
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				set L to make type "Cue List"
			end try
			try
				if L is missing value then return "made nothing"
				return "ok, named " & (q name of L)
			on error e number n
				return "FAILED " & n & " - " & e
			end try
		end tell
	end tell
end testA


-- B: sentinel set inside the tell instead. This is what it did before.
on testB()
	tell application id "com.figure53.QLab.5"
		tell front workspace
			set L to missing value
			try
				set L to make type "Cue List"
			end try
			try
				if L is missing value then return "made nothing"
				return "ok, named " & (q name of L)
			on error e number n
				return "FAILED " & n & " - " & e
			end try
		end tell
	end tell
end testB


-- C: no sentinel at all. The variable only ever holds a real cue list.
on testC()
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				set L to (make type "Cue List")
				return "ok, named " & (q name of L)
			on error e number n
				return "FAILED " & n & " - " & e
			end try
		end tell
	end tell
end testC


-- D: made inside the tell, read outside it.
on testD()
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				set L to (make type "Cue List")
			on error e number n
				return "FAILED at make " & n & " - " & e
			end try
		end tell
	end tell
	try
		tell application id "com.figure53.QLab.5"
			return "ok, named " & (q name of L)
		end tell
	on error e number n
		return "FAILED on read " & n & " - " & e
	end try
end testD


on runTests()
	set out to {}
	set end of out to "A " & testA()
	set end of out to "B " & testB()
	set end of out to "C " & testC()
	set end of out to "D " & testD()
	return out
end runTests

runTests()
