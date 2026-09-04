-- Throwaway diagnostic for the -2753 error on theList.
--
-- Round one showed all four ways of holding a new cue list in a variable
-- fail the same way, so the sentinel and the placing of the declaration are
-- both innocent. Round two asks the two questions that are left. Does a
-- plain variable survive being read inside a tell block at all, and does
-- make actually hand anything back.
--
-- Run this in Script Editor with the workspace open and read the Result
-- pane. It leaves a couple of empty cue lists behind. Delete them after.

global gText


-- E: a plain string set outside the tell, read inside it. Nothing to do
-- with QLab or with make. If this fails, no variable can cross into a tell
-- block here and the whole script needs rethinking.
on testE()
	set L to "hello"
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				return "ok, got " & L
			on error e number n
				return "FAILED " & n & " - " & e
			end try
		end tell
	end tell
end testE


-- F: the same, but declared local first.
on testF()
	local L
	set L to "hello"
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				return "ok, got " & L
			on error e number n
				return "FAILED " & n & " - " & e
			end try
		end tell
	end tell
end testF


-- G: the same again, but through a global.
on testG()
	set gText to "hello"
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				return "ok, got " & gText
			on error e number n
				return "FAILED " & n & " - " & e
			end try
		end tell
	end tell
end testG


-- H: what make hands back, asked without any variable in the way. If make
-- returns nothing then every set in round one had nothing to store, which
-- would explain all four failures on its own.
on testH()
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				return "class is " & ((class of (make type "Cue List")) as text)
			on error e number n
				return "FAILED " & n & " - " & e
			end try
		end tell
	end tell
end testH


-- I: the candidate fix. No variable at all. Make the list, then reach it
-- back through the workspace by position and by name.
on testI()
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				make type "Cue List"
				set q name of last cue list to "SCOPE TEST I"
				return "ok, named " & (q name of cue list "SCOPE TEST I")
			on error e number n
				return "FAILED " & n & " - " & e
			end try
		end tell
	end tell
end testI


on runTests()
	set out to {}
	set end of out to "E " & testE()
	set end of out to "F " & testF()
	set end of out to "G " & testG()
	set end of out to "H " & testH()
	set end of out to "I " & testI()
	return out
end runTests

runTests()
