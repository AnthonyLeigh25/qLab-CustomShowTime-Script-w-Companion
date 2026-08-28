--------------------------------------------------------------------------------
-- pre-show announcements builder for qlab 5
--
-- makes a cue list called "Temp-PreShow HH:MM" holding one audio cue per
-- pre-show call. every cue gets a wall clock trigger, so it fires itself at a
-- real time of day and nobody has to press go.
--
-- if a "Temp-PreShow" list is already there you can reschedule it to a new
-- show time in place, rebuild it, or delete it.
--
-- to use it, open this in script editor with your qlab 5 workspace at the
-- front, edit the configuration block below, then run.
--
-- worth knowing before you lean on it:
--   - wall clock triggers only fire while the workspace is open in qlab, the
--     mac is awake, and the cue and its list are armed.
--   - qlab's days-of-week restriction is not scriptable, so these triggers are
--     live every day. that is why the list ends with a script cue that deletes
--     the whole thing at show time. if that cue is disabled or unlicensed,
--     delete the list by hand after the show, or re-run this and choose
--     delete it.
--------------------------------------------------------------------------------


-- ============================ configuration ==================================

-- audio files. full posix paths, and the easiest way to get one right is to
-- drag the file into the script editor window.
property kWelcomeFile : "/Users/you/Show Audio/Announcements/Welcome.wav"
property kTenMinFile : "/Users/you/Show Audio/Announcements/10 Minute Call.wav"
property kFiveMinFile : "/Users/you/Show Audio/Announcements/5 Minute Call.wav"
property kFinalCallFile : "/Users/you/Show Audio/Announcements/Final Call.wav"

-- there is deliberately no default show time. nothing is built unless a time
-- has been set on purpose, either typed into the dialog or pushed in from
-- companion. a missing or unreadable time aborts the build rather than quietly
-- assuming one, because a wrong time is worse than no announcements at all.

-- what the control cue's name goes back to when no show time is set. it must
-- not contain anything that could be read as a time.
property kNoTimeText : "SHOW TIME - not set"

-- companion / stream deck integration ------------------------------------------
-- the q number of a permanent control cue in your show file. a memo cue is
-- ideal. companion writes the chosen show time into that cue's name over osc:
--     /cue/PSTIME/name 19:30
-- and the headless entry points read it back out. set to "" to disable.
property kShowTimeCueNumber : "PSTIME"

-- the headless entry points set this true. while it is true the script shows no
-- dialogs at all, so a stream deck press can never leave a modal window sitting
-- on the booth mac waiting for somebody to click ok.
property kSilent : false

-- cue list naming. the show time gets appended, so "Temp-PreShow 19:30".
property kListPrefix : "Temp-PreShow"

-- cue number prefix. numbers come out as PS1, PS2 and so on. "" to skip them.
property kNumberPrefix : "PS"

-- colours by call type. valid qlab colour names, or "none".
property kWelcomeColour : "green"
property kCallColour : "blue"
property kFinalColour : "red"

-- put a memo cue at the top of the list restating the show time.
property kAddMemoCue : true

-- put a self-cleaning script cue at the end of the list. it triggers at show
-- time and removes the whole temporary list, so nothing is left armed to go off
-- again tomorrow. needs a qlab licence, since script cues do not run in the
-- free tier.
property kAddCleanupCue : true

-- minutes before the show for the cleanup cue. 0 means exactly at show time,
-- when there are no announcements left to make. go negative for after the show
-- has started, so -5 is five minutes into act one.
property kCleanupOffsetMinutes : 0

-- what the cleanup cue actually does:
--   "delete"  removes the cue list entirely. cleanest.
--   "disarm"  leaves the list in place but disarms it and marks it [DONE], so
--             you can see what ran. the safer option if you would rather not
--             have a cue deleting the list it lives in.
property kCleanupAction : "delete"

-- =========================== end configuration ===============================


-- the schedule: {minutes before show, cue name, audio file, colour}. add,
-- remove or reorder rows here and the rest of the script follows along.
on announcementSchedule()
	return {¬
		{60, "Welcome Message", kWelcomeFile, kWelcomeColour}, ¬
		{40, "Welcome Message", kWelcomeFile, kWelcomeColour}, ¬
		{20, "Welcome Message", kWelcomeFile, kWelcomeColour}, ¬
		{15, "10 Minute Call", kTenMinFile, kCallColour}, ¬
		{10, "5 Minute Call", kFiveMinFile, kCallColour}, ¬
		{5, "Final Call", kFinalCallFile, kFinalColour}, ¬
		{3, "Final Call", kFinalCallFile, kFinalColour}, ¬
		{2, "Final Call", kFinalCallFile, kFinalColour}}
end announcementSchedule


--------------------------------------------------------------------------------
-- main
--------------------------------------------------------------------------------

-- interactive entry point. running the script normally lands here.
on run
	-- reset in case a headless run left this true, since properties persist
	-- between runs of a compiled script.
	set kSilent to false
	set theSchedule to announcementSchedule()

	-- deal with any list left over from a previous build before making another,
	-- otherwise you end up with two sets of triggers fighting each other.
	set existingList to findExistingList()
	if existingList is not missing value then
		set existingTime to timeFromListName(nameOfList(existingList))
		set whatNow to chooseExistingAction(existingTime)
		if whatNow is "DELETE" then
			deleteList(existingList)
			display dialog "Deleted the old pre-show cue list." buttons {"OK"} ¬
				default button 1 with title "Pre-Show Announcements"
			return "deleted"
		else if whatNow is "RESCHEDULE" then
			set newTime to askForShowTime(existingTime)
			return rescheduleList(existingList, newTime, theSchedule)
		else
			-- rebuild, so bin the old one and fall through to the build below
			deleteList(existingList)
		end if
	end if

	return buildPreShow(askForShowTime(""))
end run


--------------------------------------------------------------------------------
-- headless entry points, for driving from companion or a stream deck.
--
-- save this as a compiled script (file > export > script) somewhere permanent,
-- then have a qlab script cue load it and call one of these, along the lines of
--
--     set b to load script (POSIX file "/Users/you/Scripts/PreShow.scpt")
--     tell b to buildFromQLabCue()
--
-- the companion notes at the foot of this file spell that out properly. none of
-- these paths show a dialog, so a button press can never block mid-show.
--------------------------------------------------------------------------------

-- read the show time out of the control cue and build against it. any existing
-- temporary list is binned first, so one press always lands on a known state
-- rather than on whatever happened to be there.
on buildFromQLabCue()
	set kSilent to true
	-- no fallback here on purpose. an unset time raises, qlab shows the error
	-- against the script cue, and nothing gets built.
	set showTimeText to showTimeFromControlCue()
	repeat
		set existingList to findExistingList()
		if existingList is missing value then exit repeat
		deleteList(existingList)
	end repeat
	return buildPreShow(showTimeText)
end buildFromQLabCue

-- bin the temporary list and forget the stored show time. this is what a
-- "cancel pre-show" button should call.
on clearPreShow()
	set kSilent to true
	set n to 0
	repeat
		set existingList to findExistingList()
		if existingList is missing value then exit repeat
		deleteList(existingList)
		set n to n + 1
		-- belt and braces. if a delete ever silently fails this would otherwise
		-- spin forever with qlab wedged behind it.
		if n > 20 then exit repeat
	end repeat
	resetControlCue()
	return ("cleared " & n & " list(s)")
end clearPreShow


-- the morning purge. run this from a login item every day, a minute or so after
-- the mac comes up and qlab has opened the workspace.
--
-- this is not belt and braces, it is load bearing. qlab autosaves the workspace
-- on a timer, so a temporary list built yesterday is on disk. without this, a
-- cancelled show, or any evening where qlab was quit before the cleanup cue
-- ran, leaves yesterday's list armed and it announces again tonight at
-- yesterday's times, to whoever happens to be in the building.
on purgeOnLaunch()
	set kSilent to true
	-- login items can start before qlab has a workspace open, so wait rather
	-- than assume, and give up eventually instead of hanging about all day.
	set waited to 0
	repeat
		if workspaceIsOpen() then exit repeat
		delay 5
		set waited to waited + 5
		if waited ≥ 300 then return "gave up waiting for a QLab workspace"
	end repeat
	delay 5 -- let the workspace settle before touching anything in it
	return ("launch purge: " & clearPreShow())
end purgeOnLaunch

on workspaceIsOpen()
	try
		tell application id "com.figure53.QLab.5"
			if not running then return false
			return (count of workspaces) > 0
		end tell
	on error
		-- qlab mid-launch will happily refuse to answer, and that is a not yet
		-- rather than a no
		return false
	end try
end workspaceIsOpen


-- read the show time out of the control cue's name, the cue whose q number is
-- kShowTimeCueNumber. companion writes it there over osc with
--     /cue/PSTIME/name 19:30
-- raises if nothing readable is sitting there. no default, deliberately.
on showTimeFromControlCue()
	if kShowTimeCueNumber is "" then ¬
		error "kShowTimeCueNumber is empty, so there is no show time to read."

	set ctrlCue to findCueByNumber(kShowTimeCueNumber)
	if ctrlCue is missing value then ¬
		error ("No cue numbered " & kShowTimeCueNumber & " was found. The " & ¬
			"pre-show control cue is missing from this workspace.")

	tell application id "com.figure53.QLab.5"
		set rawName to q name of ctrlCue
	end tell

	set s to firstTimeTokenSeconds(rawName)
	if s is missing value then
		-- leave the reason where the booth will actually see it, since a stream
		-- deck press gives no other feedback
		my noteOnControlCue("BUILD REFUSED - no show time set. Choose a time " & ¬
			"on the Stream Deck first.")
		error ("No show time has been set. Cue " & kShowTimeCueNumber & ¬
			" reads \"" & rawName & "\", which contains no time. Nothing built.")
	end if
	return hhmmFromSeconds(s)
end showTimeFromControlCue


--------------------------------------------------------------------------------
-- the build itself
--------------------------------------------------------------------------------

on buildPreShow(showTimeText)
	set theSchedule to announcementSchedule()
	-- round trip through seconds so whatever the operator typed comes out in
	-- one shape, and the list name and the cue names cannot disagree
	set showSecs to secondsOfDayFromText(showTimeText)
	set showTimeText to hhmmFromSeconds(showSecs)
	set listName to kListPrefix & " " & showTimeText
	set builtCount to 0
	set cueIndex to 0

	-- everything that went sideways is collected rather than raised, so one
	-- missing file or one taken cue number cannot lose the other seven cues.
	-- stage 10 turns these into the summary the operator reads.
	set numberClashes to {}
	set triggerFailures to {}
	set crossesMidnight to {}
	set reportLines to {}
	set cleanupMade to false
	set cleanupError to ""

	warnAboutMissingFiles(theSchedule)

	tell application id "com.figure53.QLab.5"
		if (count of workspaces) is 0 then ¬
			error "No QLab workspace is open. Open your workspace and try again."

		tell front workspace

			-- make the list and check we really have it. everything below writes
			-- into this one list, so carrying on without it would scatter cues
			-- through the operator's show file.
			make type "Cue List"
			set theList to last cue list
			set q name of theList to listName
			if (q name of theList) is not listName then ¬
				error "Could not create or name the new cue list."
			try
				set armed of theList to true
			end try

			-- a memo at the top, so the show time is legible from across the
			-- booth without reading trigger times off individual cues
			if kAddMemoCue then
				make type "Memo"
				set memoCue to last item of (selected as list)
				set q name of memoCue to ("SHOW AT " & showTimeText & ¬
					"  -  delete this cue list after the show")
				set q color of memoCue to kFinalColour
				try
					move memoCue to end of theList
				end try
			end if

			repeat with theRow in theSchedule
				set minsBefore to item 1 of theRow
				set baseName to item 2 of theRow
				set thePath to item 3 of theRow
				set theColour to item 4 of theRow

				-- an early call for a lunchtime show lands yesterday evening.
				-- the trigger is fine with that, it is a time of day and not a
				-- date, but the operator should be told.
				set fireSecs to my wrapSeconds(showSecs - (minsBefore * 60))
				if fireSecs > showSecs then ¬
					set end of crossesMidnight to ("T-" & minsBefore)
				set fireText to my hhmmssFromSeconds(fireSecs)
				set cueIndex to cueIndex + 1

				make type "Audio"
				set theCue to last item of (selected as list)

				-- lead with the fire time so the list reads as a running order
				set q name of theCue to (fireText & "  -  " & baseName & ¬
					"  (T-" & minsBefore & ")")
				set q color of theCue to theColour
				set notes of theCue to ("Wall clock trigger at " & fireText & ¬
					" - " & minsBefore & " minutes before a " & showTimeText & ¬
					" show." & return & "File: " & thePath & return & ¬
					"Fires every day while this workspace is open. Delete " & ¬
					"this cue list after the show.")
				set armed of theCue to true

				-- a missing file leaves an empty audio cue rather than killing
				-- the build. the path is in the notes above either way, and the
				-- summary says which ones are hollow.
				if my fileExists(thePath) then
					set file target of theCue to POSIX file thePath
				end if

				set wall clock hours of theCue to (fireSecs div 3600)
				set wall clock minutes of theCue to ((fireSecs mod 3600) div 60)
				set wall clock seconds of theCue to (fireSecs mod 60)
				if not my enableWallClock(theCue) then ¬
					set end of triggerFailures to fireText

				-- numbers are a convenience for osc, not load bearing, so a
				-- clash with the operator's own numbering is noted and skipped
				if kNumberPrefix is not "" then
					set wantedNumber to kNumberPrefix & cueIndex
					try
						set q number of theCue to wantedNumber
					on error
						set end of numberClashes to wantedNumber
					end try
				end if

				move theCue to end of theList

				set builtCount to builtCount + 1
				set end of reportLines to ("  " & fireText & "   T-" & ¬
					minsBefore & tab & baseName)
			end repeat

			-- the cue that tidies up after itself, last in the list. wrapped in
			-- a try because script cues need a licence, and a free tier qlab
			-- should still get its announcements, just with a list to delete by
			-- hand afterwards.
			if kAddCleanupCue then
				try
					set cleanupSecs to my wrapSeconds(showSecs - ¬
						(kCleanupOffsetMinutes * 60))
					set cleanupText to my hhmmssFromSeconds(cleanupSecs)

					make type "Script"
					set cleanupCue to last item of (selected as list)

					set script source of cleanupCue to ¬
						my cleanupScriptSource(listName)
					set q name of cleanupCue to (cleanupText & ¬
						"  -  CLEAN UP: " & kCleanupAction & " this cue list")
					set q color of cleanupCue to kFinalColour
					set notes of cleanupCue to ("Runs at " & cleanupText & ¬
						" and " & kCleanupAction & "s the cue list \"" & ¬
						listName & "\", so these wall clock triggers don't " & ¬
						"fire again tomorrow." & return & ¬
						"Reschedule via the builder script to keep this in step.")
					set armed of cleanupCue to true

					set wall clock hours of cleanupCue to (cleanupSecs div 3600)
					set wall clock minutes of cleanupCue to ¬
						((cleanupSecs mod 3600) div 60)
					set wall clock seconds of cleanupCue to (cleanupSecs mod 60)
					if not my enableWallClock(cleanupCue) then ¬
						set end of triggerFailures to cleanupText

					if kNumberPrefix is not "" then
						try
							set q number of cleanupCue to ¬
								(kNumberPrefix & "-END")
						on error
							set end of numberClashes to (kNumberPrefix & "-END")
						end try
					end if

					move cleanupCue to end of theList
					set cleanupMade to true
					set end of reportLines to ("  " & cleanupText & ¬
						"   T-" & kCleanupOffsetMinutes & tab & ¬
						"CLEAN UP (" & kCleanupAction & " cue list)")
				on error errMsg
					-- hang on to why, the summary makes a point of it
					set cleanupError to errMsg
				end try
			end if
		end tell
	end tell

	-- report ------------------------------------------------------------------
	set summary to "Created cue list \"" & listName & "\" with " & builtCount & ¬
		" self-triggering announcement cues." & return & return
	repeat with L in reportLines
		set summary to summary & L & return
	end repeat
	set summary to summary & return & ¬
		"No GO required - each cue fires itself at the time shown." & return & ¬
		"Leave the workspace open and stop the Mac from sleeping." & return

	if kAddCleanupCue then
		if cleanupMade then
			set summary to summary & return & "The list " & kCleanupAction & ¬
				"s itself at show time, so nothing is left armed for " & ¬
				"tomorrow." & return
		else
			set summary to summary & return & "WARNING: the cleanup cue could " & ¬
				"NOT be created"
			if cleanupError is not "" then ¬
				set summary to summary & " (" & cleanupError & ")"
			set summary to summary & "." & return & "Script cues need a QLab " & ¬
				"licence. Delete this cue list by hand after the show, or " & ¬
				"these triggers will fire again tomorrow." & return
		end if
	end if

	if (count of crossesMidnight) > 0 then
		set summary to summary & return & "NOTE: these calls fall before " & ¬
			"midnight of the previous day: " & my joinList(crossesMidnight, " ") & ¬
			return
	end if
	if (count of triggerFailures) > 0 then
		set summary to summary & return & "WARNING: could not tick the wall " & ¬
			"clock checkbox on: " & my joinList(triggerFailures, " ") & ¬
			return & "Enable it by hand in the Triggers tab." & return
	end if
	if (count of numberClashes) > 0 then
		set summary to summary & return & "Cue numbers already in use, left " & ¬
			"blank: " & my joinList(numberClashes, " ") & return
	end if
	set summary to summary & return & ¬
		"Re-run this script to reschedule or delete the list."

	-- write the outcome into the control cue whether or not anyone is looking
	-- at a dialog, since on a stream deck build this is the only feedback there
	-- is, and it can be read back over osc
	reportToControlCue(showTimeText, builtCount)

	if not kSilent then
		display dialog summary buttons {"OK"} default button 1 with title ¬
			"Pre-Show Announcements"
	end if
	return summary
end buildPreShow


--------------------------------------------------------------------------------
-- rescheduling an existing list in place
--------------------------------------------------------------------------------

-- the show time has moved and the list is already built. re-stamp what is there
-- rather than tearing it down, so anything the operator has tweaked by hand
-- since the build, levels, routing, a swapped file, survives the change.
on rescheduleList(theList, newTimeText, theSchedule)
	set showSecs to secondsOfDayFromText(newTimeText)
	set newTimeText to hhmmFromSeconds(showSecs)
	set listName to kListPrefix & " " & newTimeText
	set movedCount to 0
	set reportLines to {}

	tell application id "com.figure53.QLab.5"
		tell front workspace
			set q name of theList to listName
			set theCues to every cue of theList

			-- audio cues are matched to schedule rows by their order in the
			-- list, which is the order the build put them in. that holds as long
			-- as nobody has reordered or deleted cues by hand; if they have,
			-- rebuild instead of rescheduling.
			set scheduleIndex to 0
			repeat with theCue in theCues
				if (q type of theCue) is "Audio" then
					set scheduleIndex to scheduleIndex + 1
					if scheduleIndex ≤ (count of theSchedule) then
						set theRow to item scheduleIndex of theSchedule
						set minsBefore to item 1 of theRow
						set baseName to item 2 of theRow

						set fireSecs to my wrapSeconds(showSecs - (minsBefore * 60))
						set fireText to my hhmmssFromSeconds(fireSecs)

						set wall clock hours of theCue to (fireSecs div 3600)
						set wall clock minutes of theCue to ((fireSecs mod 3600) div 60)
						set wall clock seconds of theCue to (fireSecs mod 60)
						my enableWallClock(theCue)
						set armed of theCue to true
						set q name of theCue to (fireText & "  -  " & baseName & ¬
							"  (T-" & minsBefore & ")")
						set movedCount to movedCount + 1
						set end of reportLines to ("  " & fireText & "   T-" & ¬
							minsBefore & tab & baseName)
					end if
				else if (q type of theCue) is "Script" then
					-- the cleanup cue needs its script rewritten as well as its
					-- time moved, because it finds the list by name and the list
					-- has just been renamed to the new show time
					set cleanupSecs to my wrapSeconds(showSecs - ¬
						(kCleanupOffsetMinutes * 60))
					set cleanupText to my hhmmssFromSeconds(cleanupSecs)
					set wall clock hours of theCue to (cleanupSecs div 3600)
					set wall clock minutes of theCue to ¬
						((cleanupSecs mod 3600) div 60)
					set wall clock seconds of theCue to (cleanupSecs mod 60)
					my enableWallClock(theCue)
					set armed of theCue to true
					try
						set script source of theCue to ¬
							my cleanupScriptSource(listName)
					end try
					set q name of theCue to (cleanupText & "  -  CLEAN UP: " & ¬
						kCleanupAction & " this cue list")
					set end of reportLines to ("  " & cleanupText & "   T-" & ¬
						kCleanupOffsetMinutes & tab & "CLEAN UP (" & ¬
						kCleanupAction & " cue list)")
				else if kAddMemoCue and (q type of theCue) is "Memo" then
					set q name of theCue to ("SHOW AT " & newTimeText & ¬
						"  -  delete this cue list after the show")
				end if
			end repeat
		end tell
	end tell

	set summary to "Rescheduled " & movedCount & " cues to a " & newTimeText & ¬
		" show." & return & return
	repeat with L in reportLines
		set summary to summary & L & return
	end repeat
	reportToControlCue(newTimeText, movedCount)
	if not kSilent then
		display dialog summary buttons {"OK"} default button 1 with title ¬
			"Pre-Show Announcements"
	end if
	return summary
end rescheduleList


--------------------------------------------------------------------------------
-- qlab helpers
--------------------------------------------------------------------------------

-- the first cue list whose name starts with kListPrefix, or missing value.
-- matching on the prefix rather than the full name means a list built for any
-- show time is found, which is the point: callers want to know whether one is
-- there at all, not which one.
on findExistingList()
	tell application id "com.figure53.QLab.5"
		if (count of workspaces) is 0 then return missing value
		tell front workspace
			repeat with L in (every cue list)
				try
					if (q name of L) starts with kListPrefix then return L
				end try
			end repeat
		end tell
	end tell
	return missing value
end findExistingList

-- find a cue anywhere in the workspace by its q number. searches every cue list
-- and one level into group cues, which covers a control cue tucked inside a
-- group without recursing through an entire show file on every call. the cues
-- this looks for are ones the setup instructions put at the top level of their
-- own list anyway.
on findCueByNumber(theNumber)
	if theNumber is "" then return missing value
	tell application id "com.figure53.QLab.5"
		if (count of workspaces) is 0 then return missing value
		tell front workspace
			repeat with L in (every cue list)
				try
					repeat with C in (every cue of L)
						try
							if (q number of C) is theNumber then return C
						end try
						try
							if (q type of C) is "Group" then
								repeat with C2 in (every cue of C)
									try
										if (q number of C2) is theNumber then ¬
											return C2
									end try
								end repeat
							end if
						end try
					end repeat
				end try
			end repeat
		end tell
	end tell
	return missing value
end findCueByNumber


-- write the outcome of a build into the control cue's notes, so the booth can
-- see what the last stream deck press actually did
on reportToControlCue(showTimeText, builtCount)
	noteOnControlCue("Last build: " & builtCount & " cues for a " & ¬
		showTimeText & " show." & return & "Cue list: " & kListPrefix & " " & ¬
		showTimeText)
end reportToControlCue

on noteOnControlCue(theText)
	set ctrlCue to findCueByNumber(kShowTimeCueNumber)
	if ctrlCue is missing value then return
	tell application id "com.figure53.QLab.5"
		try
			-- a note that will not write is not worth failing a build over
			set notes of ctrlCue to theText
		end try
	end tell
end noteOnControlCue

-- wipe the stored show time. this is the whole point of cancel: leaving a time
-- behind would let tomorrow's operator press build and get tonight's schedule
-- without ever choosing anything.
on resetControlCue()
	set ctrlCue to findCueByNumber(kShowTimeCueNumber)
	if ctrlCue is missing value then return
	tell application id "com.figure53.QLab.5"
		try
			set q name of ctrlCue to kNoTimeText
			set notes of ctrlCue to ("No show time set. Choose one on the " & ¬
				"Stream Deck, then press BUILD.")
		end try
	end tell
end resetControlCue

on nameOfList(theList)
	tell application id "com.figure53.QLab.5"
		try
			return q name of theList
		on error
			return ""
		end try
	end tell
end nameOfList

on deleteList(theList)
	tell application id "com.figure53.QLab.5"
		try
			delete theList
		end try
	end tell
end deleteList


-- build the applescript that goes inside the cleanup script cue.
--
-- the generated script finds the cue list by name rather than holding a
-- reference to it, because the workspace will have been saved, closed and
-- reopened between this being written and it running, and a reference does not
-- survive that.
--
-- the delay lets the cue finish starting before it removes the list it is
-- sitting in. leave "run in separate process" ticked on this cue, which is
-- qlab's default, so the script is not killed along with the list.
on cleanupScriptSource(listName)
	set LF to linefeed
	set qt to "\""

	if kCleanupAction is "disarm" then
		set theAction to ¬
			"                    set armed of L to false" & LF & ¬
			"                    set q name of L to ((q name of L) & " & qt & ¬
			" [DONE]" & qt & ")"
	else
		set theAction to "                    delete L"
	end if

	return "-- auto-generated by PreShowAnnouncements.applescript." & LF & ¬
		"-- removes the temporary pre-show cue list so its wall clock" & LF & ¬
		"-- triggers do not fire again tomorrow." & LF & ¬
		"delay 2" & LF & ¬
		"tell application id " & qt & "com.figure53.QLab.5" & qt & LF & ¬
		"    tell front workspace" & LF & ¬
		"        repeat with L in (every cue list)" & LF & ¬
		"            try" & LF & ¬
		"                if (q name of L) is " & qt & listName & qt & " then" & LF & ¬
		theAction & LF & ¬
		"                    exit repeat" & LF & ¬
		"                end if" & LF & ¬
		"            end try" & LF & ¬
		"        end repeat" & LF & ¬
		"    end tell" & LF & ¬
		"end tell"
end cleanupScriptSource


-- tick the wall clock trigger checkbox. returns true if it took.
--
-- tries the enumerated constant first and the string second because the
-- accepted form has moved around between qlab versions, and the whole system
-- is worthless if this one property does not get set. reports failure rather
-- than raising, so a build finishes and the summary can name the cues that need
-- the box ticking by hand.
on enableWallClock(theCue)
	tell application id "com.figure53.QLab.5"
		try
			set wall clock trigger of theCue to enabled
			return true
		end try
		try
			set wall clock trigger of theCue to "enabled"
			return true
		end try
	end tell
	return false
end enableWallClock


--------------------------------------------------------------------------------
-- dialogs
--------------------------------------------------------------------------------

on chooseExistingAction(existingTime)
	set msg to "A pre-show cue list already exists"
	if existingTime is not "" then set msg to msg & ", set for " & existingTime
	set msg to msg & "." & return & return & "Reschedule keeps the cues and " & ¬
		"just changes their trigger times. Rebuild deletes and recreates them."
	display dialog msg buttons {"Delete It", "Rebuild", "Reschedule"} ¬
		default button "Reschedule" with title "Pre-Show Announcements"
	set b to button returned of the result
	if b is "Delete It" then return "DELETE"
	if b is "Rebuild" then return "REBUILD"
	return "RESCHEDULE"
end chooseExistingAction

on askForShowTime(defaultText)
	repeat
		set theReply to text returned of (display dialog ¬
			"Show time? (24-hour, e.g. 19:30)" default answer defaultText ¬
			with title "Pre-Show Announcements")
		try
			set s to secondsOfDayFromText(theReply)
			return hhmmFromSeconds(s)
		on error
			-- hand the rejected text back as the default so a fat fingered
			-- 199:30 is corrected rather than typed out again from scratch
			display dialog "Couldn't read \"" & theReply & ¬
				"\". Please use HH:MM, e.g. 19:30." buttons {"Try Again"} ¬
				default button 1 with icon caution
			set defaultText to theReply
		end try
	end repeat
end askForShowTime


-- say up front which audio files are not where the configuration claims. this
-- is the last chance to stop before a list of silent cues gets built, and it is
-- the sort of thing that only shows up in the house otherwise.
on warnAboutMissingFiles(theSchedule)
	if kSilent then return -- never block a stream deck press with a dialog
	set missingFiles to {}
	repeat with theRow in theSchedule
		set thePath to item 3 of theRow
		if not fileExists(thePath) then
			-- the same file appears on several rows, so only mention it once
			if missingFiles does not contain thePath then ¬
				set end of missingFiles to thePath
		end if
	end repeat
	if (count of missingFiles) is 0 then return
	set msg to "These audio files were not found:" & return & return
	repeat with p in missingFiles
		set msg to msg & "  - " & p & return
	end repeat
	set msg to msg & return & "The cues will still be built, but those file " & ¬
		"targets will be left empty for you to fill in."
	display dialog msg buttons {"Cancel", "Build Anyway"} ¬
		default button "Build Anyway" with icon caution
end warnAboutMissingFiles


--------------------------------------------------------------------------------
-- time and text helpers
--------------------------------------------------------------------------------

-- "19:30", "7:30 pm", "1930" all come out as seconds since midnight.
--
-- forgiving on the way in because the time arrives from three different places,
-- a dialog, an osc message and a cue name somebody may have typed by hand, and
-- being fussy about the format would just mean refusing to build over a stray
-- space. strict on the way out: the range check is what stops "25:70" becoming
-- a cue that never fires.
on secondsOfDayFromText(theText)
	set theText to trimText(theText as text)
	set isPM to (theText contains "pm" or theText contains "PM")
	set isAM to (theText contains "am" or theText contains "AM")

	-- strip to digits and separators first, so any decoration around the time
	-- falls away rather than having to be anticipated
	set cleaned to ""
	repeat with c in (characters of theText)
		if c is in "0123456789:." then set cleaned to cleaned & c
	end repeat
	if cleaned is "" then error "no digits"

	if cleaned contains ":" or cleaned contains "." then
		set AppleScript's text item delimiters to {":", "."}
		set parts to text items of cleaned
		set AppleScript's text item delimiters to {""}
		set hh to (item 1 of parts) as integer
		set mm to 0
		if (count of parts) > 1 then set mm to (item 2 of parts) as integer
	else if (length of cleaned) ≤ 2 then
		set hh to cleaned as integer
		set mm to 0
	else
		-- bare "1930"
		set hh to (text 1 thru -3 of cleaned) as integer
		set mm to (text -2 thru -1 of cleaned) as integer
	end if

	if isPM and hh < 12 then set hh to hh + 12
	if isAM and hh is 12 then set hh to 0
	if hh > 23 or hh < 0 or mm > 59 or mm < 0 then error "time out of range"
	return hh * 3600 + mm * 60
end secondsOfDayFromText

-- find the first thing that looks like a time in a longer string, or missing
-- value. this is what lets the show time sit inside a cue name such as
-- "SHOW TIME 19:30 (matinee)" rather than having to be the whole name.
--
-- requires a colon, so a stray "1930" in some other part of the name cannot be
-- mistaken for the time. resets the text item delimiters on the way out of the
-- error path as well, since they are global and leaving them changed would
-- quietly break the next handler that splits a string.
on firstTimeTokenSeconds(theText)
	try
		set AppleScript's text item delimiters to {" ", tab, return, linefeed}
		set parts to text items of (theText as text)
		set AppleScript's text item delimiters to {""}
		repeat with p in parts
			if (p as text) contains ":" then
				try
					return secondsOfDayFromText(p as text)
				end try
			end if
		end repeat
	on error
		set AppleScript's text item delimiters to {""}
	end try
	return missing value
end firstTimeTokenSeconds

-- pull "19:30" back out of a cue list name like "Temp-PreShow 19:30"
on timeFromListName(theName)
	set s to firstTimeTokenSeconds(theName)
	if s is missing value then return ""
	return hhmmFromSeconds(s)
end timeFromListName

-- keep a time of day inside the day. a call earlier than the show time by more
-- than the show time itself belongs to yesterday evening, which is exactly what
-- a wall clock trigger wants.
on wrapSeconds(s)
	set s to s as integer
	repeat while s < 0
		set s to s + 86400
	end repeat
	return s mod 86400
end wrapSeconds

on hhmmFromSeconds(s)
	set s to wrapSeconds(s)
	return pad2(s div 3600) & ":" & pad2((s mod 3600) div 60)
end hhmmFromSeconds

on hhmmssFromSeconds(s)
	set s to wrapSeconds(s)
	return pad2(s div 3600) & ":" & pad2((s mod 3600) div 60) & ":" & ¬
		pad2(s mod 60)
end hhmmssFromSeconds

on pad2(n)
	set n to n as integer
	if n < 10 then return "0" & (n as text)
	return n as text
end pad2


-- coercing to an alias is the cheap way to ask whether a file is really there,
-- since it fails for a path that does not resolve
on fileExists(posixPath)
	try
		set f to (POSIX file posixPath) as alias
		return true
	on error
		return false
	end try
end fileExists

on joinList(theList, sep)
	set out to ""
	repeat with i from 1 to count of theList
		set out to out & (item i of theList)
		if i < (count of theList) then set out to out & sep
	end repeat
	return out
end joinList

-- trims spaces only, which is all the show time inputs ever pick up
on trimText(t)
	set t to t as text
	repeat while t begins with " "
		set t to text 2 thru -1 of t
	end repeat
	repeat while t ends with " "
		set t to text 1 thru -2 of t
	end repeat
	return t
end trimText


--------------------------------------------------------------------------------
-- companion and stream deck setup
--
-- IN QLAB, a permanent cue list called "PRE-SHOW CONTROL" holding three cues.
-- these live in the show file for good. they are not part of the temporary list
-- and they are the only pre-show cues present at the start of a day.
--
--   PSTIME   memo cue.   name: "SHOW TIME - not set"
--                        companion overwrites this name with the chosen time.
--                        disarm it, it is a label rather than something to play.
--   PSBUILD  script cue: set b to load script (POSIX file "/Users/you/Scripts/PreShow.scpt")
--                        tell b to buildFromQLabCue()
--   PSCLEAR  script cue: set b to load script (POSIX file "/Users/you/Scripts/PreShow.scpt")
--                        tell b to clearPreShow()
--
-- export this file via file > export > file format: script to that .scpt path,
-- so qlab, the login item and script editor all share one copy and there is no
-- second version to keep in step.
--
-- ON THE MAC, a login item that runs purgeOnLaunch() every morning. save this
-- as an applet (file > export > file format: application) holding just these
-- two lines, then add it to login items:
--
--   set b to load script (POSIX file "/Users/you/Scripts/PreShow.scpt")
--   tell b to purgeOnLaunch()
--
-- this is required rather than belt and braces. qlab autosaves the workspace on
-- a timer, so a list built yesterday is on disk and would come back armed today.
--
-- IN COMPANION, three pages using the qlabfb connection plus two custom
-- variables, showHour and showMinute. turn off persist value on both, so a
-- companion restart leaves them blank and nobody can build yesterday's time.
--
--   page 10  PRE-SHOW
--     "NEW SHOW"      -> internal: set surface page = 11
--                       button text: NEW SHOW\n$(custom:showHour):$(custom:showMinute)
--     "BUILD"         -> qlabfb: custom osc /cue/PSTIME/name
--                          string argument: $(custom:showHour):$(custom:showMinute)
--                    -> wait 250 ms
--                    -> qlabfb: custom osc /cue/PSBUILD/start
--     "CANCEL"        -> qlabfb: custom osc /cue/PSCLEAR/start
--
--   page 11  SELECT HOUR    24 buttons, each:
--                       internal: custom variable set value, showHour = "18"
--                       internal: set surface page = 12
--
--   page 12  SELECT MINUTE  12 buttons at 5 minute steps, each:
--                       internal: custom variable set value, showMinute = "30"
--                       internal: set surface page = 10
--
-- store the hour and minute already padded to two characters ("07", "05") in
-- the button actions. that keeps "19:30" well formed without any expression
-- maths, and secondsOfDayFromText above will take it happily.
--
-- the two osc messages on BUILD have to arrive in order, since the name is set
-- and then the build cue reads it back. that is what the 250 ms wait is for.
--
-- nothing is built until BUILD is pressed, and BUILD refuses unless a readable
-- time is sitting in PSTIME's name. there is no default show time anywhere.
--------------------------------------------------------------------------------
