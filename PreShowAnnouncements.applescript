--------------------------------------------------------------------------------
-- Custom pre-show announcements builder for QLab 5
--
-- Builds a cue list called "Temp-PreShow HH:MM", one audio cue per call.
-- Each cue has a wall clock trigger, so it fires itself at a set time.
--
-- If a "Temp-PreShow" list already exists you can reschedule it, rebuild
-- it or delete it.
--
-- To use: open in script editor with your QLab 5 workspace at the front,
-- edit the configuration below and then run.
--
-- Two things to know:
--   - Triggers only fire while the workspace is open, the mac is awake,
--     and the cue and its list are armed.
--   - QLab's days-of-week setting is not scriptable, so these triggers
--     are live every day and so the list ends with a script cue that deletes it
--     at show time. If that cue cannot run, delete the list by hand.
-- Note to self, don't do applescript ever again god I hate myself.
--------------------------------------------------------------------------------


-- ============================ CONFIGURATION ==================================

-- Audio file locations, the output patch each one uses, and the level it
-- plays at.
--
-- Levels are {master, left, right} in dB, range is -120(-INF) to +12.
--
-- Left and right are the crosspoints for a stereo file on default routing.
--
-- Patch is the number of a QLab audio output patch, so 1 is the first one in
-- Workspace Settings > Audio. Use 0 to leave a cue on the workspace default.
property kWelcomeFile : "/Users/lphproduction/Desktop/FOH ANNOUNCEMENTS 27.06.26/audio/Pre-concert FOH areas no mask .wav"
property kWelcomePatch : 1
property kWelcomeLevel : {0, 0, -10}

-- Spare. Not in the schedule at the moment, kept for when a 10 minute call
-- is wanted again. An unused property costs nothing.
property kTenMinFile : "/Users/you/Show Audio/Announcements/10 Minute Call.wav"
property kTenMinPatch : 1
property kTenMinLevel : {0, 0, 0}

property kFiveMinFile : "/Users/lphproduction/Desktop/FOH ANNOUNCEMENTS 27.06.26/audio/Pre-Event 5 Mins Photography Permitted.wav"
property kFiveMinPatch : 1
property kFiveMinLevel : {0, 0, -11}

property kFinalCallFile : "/Users/lphproduction/Desktop/FOH ANNOUNCEMENTS 27.06.26/audio/Pre-EVENT final call.wav"
property kFinalCallPatch : 1
property kFinalCallLevel : {0, 0, -17}

-- There is no default show time. The time is either typed into
-- the dialog or sent from Companion. A missing or unreadable one stops the
-- script from building.

-- What the control cue is renamed to when no show time is set. It must not
-- contain anything that reads as a time.
property kNoTimeText : "SHOW TIME - not set"

-- COMPANION / STREAM DECK INTEGRATION ----------------------------------------
-- The q number of a permanent control cue, ideally a memo cue. Companion
-- writes the show time into its name over OSC:
--     /cue/PSTIME/name 19:30
-- and the headless handlers read it back. Set to "" to disable.
property kShowTimeCueNumber : "PSTIME"

-- Feedback cues on the permanent control list, started after a build. Gives
-- the control position a sound or a light rather than making somebody read
-- the control cue's notes. Arm both, unlike the control cue itself. Set
-- either to "" to skip it.
property kBuildOKCue : "PSOK"
property kBuildFailCue : "PSFAIL"

-- Set true by the headless handlers. No dialogs appear while it is true, so
-- a Stream Deck press cannot leave a window waiting for a click.
property kSilent : false

-- Cue list name. The show time is added, so "Temp-PreShow 19:30".
property kListPrefix : "Temp-PreShow"

-- Cue number prefix. Numbers come out as PS1, PS2 and so on. "" to skip.
property kNumberPrefix : "PS"

-- Colours by call type. Valid QLab colour names, or "none".
property kWelcomeColour : "green"
property kCallColour : "blue"
property kFinalColour : "red"

-- Add a memo cue at the top showing the show time.
property kAddMemoCue : true

-- Add a script cue at the end that deletes the list at show time, so nothing
-- is left armed for tomorrow.
property kAddCleanupCue : true

-- Minutes before the show for the cleanup cue. 0 is show time itself. Use a
-- negative number for after the show starts, so -5 is five minutes in.
property kCleanupOffsetMinutes : -2

-- What the cleanup cue does:
--   "delete"  removes the cue list. Cleanest.
--   "disarm"  keeps the list but disarms it and marks it [DONE], so you can
--             see what ran.
property kCleanupAction : "delete"

-- The schedule: {minutes before show, cue name, audio file, colour, level,
-- patch}.
-- Add, remove or reorder rows and the rest of the script follows.
on announcementSchedule()
	return {¬
		{60, "Welcome Message", kWelcomeFile, kWelcomeColour, kWelcomeLevel, kWelcomePatch}, ¬
		{50, "Welcome Message", kWelcomeFile, kWelcomeColour, kWelcomeLevel, kWelcomePatch}, ¬
		{40, "Welcome Message", kWelcomeFile, kWelcomeColour, kWelcomeLevel, kWelcomePatch}, ¬
		{30, "Welcome Message", kWelcomeFile, kWelcomeColour, kWelcomeLevel, kWelcomePatch}, ¬
		{20, "Welcome Message", kWelcomeFile, kWelcomeColour, kWelcomeLevel, kWelcomePatch}, ¬
		{10, "5 Minute Call", kFiveMinFile, kCallColour, kFiveMinLevel, kFiveMinPatch}, ¬
		{8, "5 Minute Call", kFiveMinFile, kCallColour, kFiveMinLevel, kFiveMinPatch}, ¬
		{5, "Final Call", kFinalCallFile, kFinalColour, kFinalCallLevel, kFinalCallPatch}, ¬
		{3, "Final Call", kFinalCallFile, kFinalColour, kFinalCallLevel, kFinalCallPatch}, ¬
		{1, "Final Call", kFinalCallFile, kFinalColour, kFinalCallLevel, kFinalCallPatch}}
end announcementSchedule

-- =========================== END CONFIGURATION ===============================

--------------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------------

-- Running the script normally starts here.
on run
	-- Properties keep their value between runs of a compiled script, so a
	-- Companion press could leave this true. Reset it.
	set kSilent to false

	-- Clear any leftover list first. Two lists means two sets of triggers, and both of them fire. No bueno.
	set existingList to findExistingList()
	if existingList is not missing value then
		set existingTime to timeFromListName(nameOfList(existingList))
		set whatNow to chooseExistingAction(existingTime)
		if whatNow is "DELETE" then
			deleteList(existingList)
			display dialog "Deleted the old pre-show cue list." buttons {"OK"} ¬
				default button 1 with title "Pre-Show Announcements"
			return "deleted"
		else
			-- Rebuild: delete the old one and carry on to the build below
			deleteList(existingList)
		end if
	end if

	return buildPreShow(askForShowTime(""))
end run


--------------------------------------------------------------------------------
-- HEADLESS ENTRY POINTS, FOR COMPANION AND THE STREAM DECK
--
-- Export this as a compiled script (file > export > script), then have a
-- QLab script cue load it and call one of these:
--
--     tell (load script (POSIX file "/Users/you/Scripts/PreShow.scpt")) to buildFromQLabCue()
--
-- None of these show a dialog, so a button press cannot block mid-show.
-- The full wiring is at the foot of this file.
--------------------------------------------------------------------------------

-- Read the show time from the control cue and build. Any old list is deleted first.
on buildFromQLabCue()
	set kSilent to true
	try
		-- No fallback. An unset time raises an error, QLab shows it on the script cue, and nothing is built.
		set showTimeText to showTimeFromControlCue()
		repeat
			set existingList to findExistingList()
			if existingList is missing value then exit repeat
			deleteList(existingList)
		end repeat
		return buildPreShow(showTimeText)
	on error errMsg
		-- Nothing was built at all. Fire the fail cue, then re-raise so QLab
		-- still flags the error against this Script cue.
		fireCue(kBuildFailCue)
		error errMsg
	end try
end buildFromQLabCue

-- Delete the list and clear the stored show time. Wire this to a cancel button.
on clearPreShow()
	set kSilent to true
	set n to 0
	repeat
		set existingList to findExistingList()
		if existingList is missing value then exit repeat
		deleteList(existingList)
		set n to n + 1
		if n > 20 then exit repeat
	end repeat
	stopFeedbackCues()
	resetControlCue()
	return ("cleared " & n & " list(s)")
end clearPreShow


-- The morning purge. Run this from a login item every day.
on purgeOnLaunch()
	set kSilent to true
	-- A login item can start before QLab is ready, so wait for the workspace.
	-- Give up after five minutes.
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
		-- QLab refuses to answer while it is starting up. That is a not yet,
		-- not a no.
		return false
	end try
end workspaceIsOpen


-- Read the show time from the control cue's name. Companion puts it there
-- over OSC:
--     /cue/PSTIME/name 19:30
-- Raises an error if there is no readable time. No default, on purpose.
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
		-- A Stream Deck press gives no other feedback, so put the reason where it visible.
		my noteOnControlCue("BUILD REFUSED - no show time set. Choose a time " & ¬
			"on the Stream Deck first.")
		error ("No show time has been set. Cue " & kShowTimeCueNumber & ¬
			" reads \"" & rawName & "\", which contains no time. Nothing built.")
	end if
	return hhmmFromSeconds(s)
end showTimeFromControlCue


--------------------------------------------------------------------------------
-- THE BUILD ITSELF (I hate my life)
--------------------------------------------------------------------------------

on buildPreShow(showTimeText)
	set theSchedule to announcementSchedule()
	-- Convert to seconds and back, so any input format comes out the same way
	-- and the list name always matches the cue names
	set showSecs to secondsOfDayFromText(showTimeText)
	set showTimeText to hhmmFromSeconds(showSecs)
	set listName to kListPrefix & " " & showTimeText
	set builtCount to 0
	set cueIndex to 0

	-- Problems are collected so one missing file won't affect the
	-- other seven cues. The summary at the end reports all of them.
	set numberClashes to {}
	set triggerFailures to {}
	set levelFailures to {}
	set patchFailures to {}
	set missingFiles to {}
	set crossesMidnight to {}
	set reportLines to {}
	set cleanupMade to false
	set cleanupError to ""

	-- The schedule is edited by hand, so check its shape before building
	-- anything. A short row would otherwise fail deep in the loop with a
	-- "can't get item 6" and half a cue list already made.
	repeat with i from 1 to count of theSchedule
		if (count of (item i of theSchedule)) < 6 then error ("Row " & i & ¬
			" of the schedule has " & (count of (item i of theSchedule)) & ¬
			" items. Each row needs 6: minutes, name, file, colour, level, " & ¬
			"patch.")
	end repeat

	warnAboutMissingFiles(theSchedule)

	tell application id "com.figure53.QLab.5"
		if (count of workspaces) is 0 then ¬
			error "No QLab workspace is open. Open your workspace and try again."

		tell front workspace

			-- Check the list was made. Every cue below is moved into it.
			--
			-- theList is given a value before the make, not by it. A command
			-- that returns nothing leaves the variable undefined rather than
			-- empty, and the next line to touch it raises -2753 instead of
			-- anything that explains itself.
			set theList to missing value
			try
				set theList to make type "Cue List"
			end try
			if theList is missing value then
				try
					set theList to last cue list
				end try
			end if
			if theList is missing value then ¬
				error "QLab would not make a new cue list. Nothing was built."
			set q name of theList to listName
			if (q name of theList) is not listName then ¬
				error "Could not create or name the new cue list."
			try
				set armed of theList to true
			end try

			-- A memo at the top, so the show time is readable
			if kAddMemoCue then
				set memoCue to my newCue("Memo")
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
				set theLevel to item 5 of theRow
				set thePatch to item 6 of theRow

				-- An early call for a lunchtime show falls the night before. The
				-- trigger is happy, it is a time of day and not a date, but say so.
				-- I hate code but gotta specify this, otherwise I'll forget what this does.
				set fireSecs to my wrapSeconds(showSecs - (minsBefore * 60))
				if fireSecs > showSecs then ¬
					set end of crossesMidnight to ("T-" & minsBefore)
				set fireText to my hhmmssFromSeconds(fireSecs)
				set cueIndex to cueIndex + 1

				set theCue to my newCue("Audio")

				-- Leads with the fire time so the list reads as a running order, hopefully.
				set q name of theCue to (fireText & "  -  " & baseName & ¬
					"  (T-" & minsBefore & ")")
				set q color of theCue to theColour
				set notes of theCue to ("Wall clock trigger at " & fireText & ¬
					" - " & minsBefore & " minutes before a " & showTimeText & ¬
					" show." & return & "File: " & thePath & return & ¬
					"Fires every day while this workspace is open. Delete " & ¬
					"this cue list after the show.")
				set armed of theCue to true

				-- A missing file leaves an empty cue rather than stopping the
				-- build. The path is in the notes and the summary lists them.
				if my fileExists(thePath) then
					set file target of theCue to POSIX file thePath
					-- Patch first, then levels. Both a new file target and a
					-- new patch rebuild the level matrix, so anything set
					-- before them is thrown away.
					if not my applyPatch(theCue, thePatch) then ¬
						set end of patchFailures to fireText
					if not my applyLevels(theCue, theLevel) then ¬
						set end of levelFailures to fireText
				else
					-- Recorded because a Stream Deck build shows no dialog, so
					-- this is the only way an empty cue gets reported.
					set end of missingFiles to fireText
				end if

				set wall clock hours of theCue to (fireSecs div 3600)
				set wall clock minutes of theCue to ((fireSecs mod 3600) div 60)
				set wall clock seconds of theCue to (fireSecs mod 60)
				if not my enableWallClock(theCue) then ¬
					set end of triggerFailures to fireText

				-- Cue numbers are a convenience for OSC, so a clash with the
				-- operator's own numbering is noted and skipped
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

			-- The cleanup cue.
			if kAddCleanupCue then
				try
					set cleanupSecs to my wrapSeconds(showSecs - ¬
						(kCleanupOffsetMinutes * 60))
					set cleanupText to my hhmmssFromSeconds(cleanupSecs)

					set cleanupCue to my newCue("Script")

					set script source of cleanupCue to ¬
						my cleanupScriptSource(listName)
					set q name of cleanupCue to (cleanupText & ¬
						"  -  CLEAN UP: " & kCleanupAction & " this cue list")
					set q color of cleanupCue to kFinalColour
					set notes of cleanupCue to ("Runs at " & cleanupText & ¬
						" and " & kCleanupAction & "s the cue list \"" & ¬
						listName & "\", so these wall clock triggers don't " & ¬
						"fire again tomorrow." & return & ¬
						"Re-run the builder to change the show time.")
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
					-- Keep the reason, the summary reports it
					set cleanupError to errMsg
				end try
			end if
		end tell
	end tell

	-- =========================== SUMMARY REPORTING ===============================
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
	if (count of missingFiles) > 0 then
		set summary to summary & return & "WARNING: audio file not found " & ¬
			"for: " & my joinList(missingFiles, " ") & return & ¬
			"Those cues were built empty and will play nothing." & return
	end if
	if (count of triggerFailures) > 0 then
		set summary to summary & return & "WARNING: could not tick the wall " & ¬
			"clock checkbox on: " & my joinList(triggerFailures, " ") & ¬
			return & "Enable it by hand in the Triggers tab." & return
	end if
	if (count of patchFailures) > 0 then
		set summary to summary & return & "WARNING: could not set the output " & ¬
			"patch on: " & my joinList(patchFailures, " ") & return & ¬
			"Those cues are on the workspace default patch." & return
	end if
	if (count of levelFailures) > 0 then
		set summary to summary & return & "WARNING: could not set every " & ¬
			"level on: " & my joinList(levelFailures, " ") & return & ¬
			"A mono file has no right channel, so that one is expected. " & ¬
			"Anything else wants checking in the cue's Levels tab." & return
	end if
	if (count of numberClashes) > 0 then
		set summary to summary & return & "Cue numbers already in use, left " & ¬
			"blank: " & my joinList(numberClashes, " ") & return
	end if
	set summary to summary & return & ¬
		"Re-run this script to reschedule or delete the list."

	-- Always write the result to the control cue. A Stream Deck build shows no
	-- dialog, so this is the only feedback and OSC should be able to read it back.
	reportToControlCue(showTimeText, builtCount)

	-- A cue whose wall clock box would not tick never fires, and a cue with
	-- no file plays nothing. Both look fine in the list, so both count as a
	-- failed build even though the list exists. Level failures are left out
	-- on purpose: a wrong level is audible, and a mono file always reports
	-- its right channel as failed.
	set buildIsClean to (builtCount > 0) and ¬
		((count of triggerFailures) is 0) and ¬
		((count of missingFiles) is 0) and ¬
		((not kAddCleanupCue) or cleanupMade)
	-- Clear the last result first, so a rebuild after a failure is not left
	-- showing both states at once.
	stopFeedbackCues()
	if buildIsClean then
		fireCue(kBuildOKCue)
	else
		fireCue(kBuildFailCue)
	end if

	if not kSilent then
		display dialog summary buttons {"OK"} default button 1 with title ¬
			"Pre-Show Announcements"
	end if
	return summary
end buildPreShow
-- =========================== END OF SUMMARY REPORTING ===============================

--------------------------------------------------------------------------------
-- QLAB HELPERS
--------------------------------------------------------------------------------

-- The first cue list whose name starts with kListPrefix, or missing value.
-- Matching the prefix finds a list built for any show time, which is what
-- callers want to know: whether one is there at all.
on findExistingList()
	tell application id "com.figure53.QLab.5"
		if (count of workspaces) is 0 then return missing value
		tell front workspace
			repeat with L in (every cue list)
				try
					-- contents of, not the loop variable itself. A repeat
					-- variable is a reference into the list being walked, and
					-- commands sent to it later can fail or hit the wrong cue.
					if (q name of L) starts with kListPrefix then ¬
						return contents of L
				end try
			end repeat
		end tell
	end tell
	return missing value
end findExistingList

-- Find a cue by its q number. Searches every cue list and one level into
-- groups. That catches a control cue tidied into a group without walking a
-- whole show file on every call.
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


-- Put the result of a build in the control cue's notes
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
			set notes of ctrlCue to theText
		end try
	end tell
end noteOnControlCue

-- Start one of the feedback cues. A missing or unarmed cue is ignored,
-- because feedback failing is never a reason to fail a build.
on fireCue(theNumber)
	if theNumber is "" then return
	set theCue to findCueByNumber(theNumber)
	if theCue is missing value then return
	tell application id "com.figure53.QLab.5"
		try
			start theCue
		end try
	end tell
end fireCue

-- Stop both feedback cues. Called before firing one, on cancel, and by the
-- cleanup cue at show time, so a cue that loops or holds a light on does not
-- run into the performance.
on stopFeedbackCues()
	stopCue(kBuildOKCue)
	stopCue(kBuildFailCue)
end stopFeedbackCues

on stopCue(theNumber)
	if theNumber is "" then return
	set theCue to findCueByNumber(theNumber)
	if theCue is missing value then return
	tell application id "com.figure53.QLab.5"
		try
			stop theCue
		end try
	end tell
end stopCue

-- Clear the stored show time for cancellation.
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

-- Delete a cue list. Returns true if the list itself went.
--
-- Only cues respond to delete, not cue lists.
on deleteList(theList)
	tell application id "com.figure53.QLab.5"
		tell front workspace
			try
				delete (every cue of theList)
			end try
			try
				delete theList
				return true
			end try
			-- The list will not go. Disarm it, and put the marker on the
			-- front of the name so it no longer starts with the prefix and
			-- findExistingList stops handing it back.
			try
				set armed of theList to false
				set q name of theList to ("[DONE] " & (q name of theList))
			end try
		end tell
	end tell
	return false
end deleteList


-- Build the AppleScript that goes inside the cleanup script cue.
-- It finds the cue list by name.
--
-- The delay lets the cue finish starting before it deletes the list it is
-- in. Leave "run in separate process" ticked, which is QLab's default, or
-- the script is killed along with the list.
on cleanupScriptSource(listName)
	set LF to linefeed
	set qt to "\""

	-- The feedback cues are stopped before the list goes, so nothing is left
	-- lit or looping once the show starts. Their numbers are written into the
	-- generated script, since it runs long after this handler has finished.
	set feedbackNumbers to {}
	if kBuildOKCue is not "" then set end of feedbackNumbers to kBuildOKCue
	if kBuildFailCue is not "" then set end of feedbackNumbers to kBuildFailCue

	set stopBlock to ""
	if (count of feedbackNumbers) > 0 then
		set numberList to "{"
		repeat with i from 1 to count of feedbackNumbers
			set numberList to numberList & qt & (item i of feedbackNumbers) & qt
			if i < (count of feedbackNumbers) then ¬
				set numberList to numberList & ", "
		end repeat
		set numberList to numberList & "}"

		set stopBlock to ¬
			"        -- stop the build feedback cues" & LF & ¬
			"        repeat with L in (every cue list)" & LF & ¬
			"            try" & LF & ¬
			"                repeat with C in (every cue of L)" & LF & ¬
			"                    try" & LF & ¬
			"                        if (q number of C) is in " & numberList & ¬
			" then stop C" & LF & ¬
			"                    end try" & LF & ¬
			"                end repeat" & LF & ¬
			"            end try" & LF & ¬
			"        end repeat" & LF
	end if

	if kCleanupAction is "disarm" then
		set theAction to ¬
			"                        set armed of TL to false" & LF & ¬
			"                        set q name of TL to ((q name of TL) & " & ¬
			qt & " [DONE]" & qt & ")"
	else
		set theAction to "                        delete (every cue of TL)" & LF
		set theAction to theAction & "                        try" & LF
		set theAction to theAction & "                            delete TL" & LF
		set theAction to theAction & "                        end try"
	end if

	-- Where to leave a note if this does not work. Running unattended, an
	-- error goes nowhere, so it is written onto the control cue instead.
	set noteBlock to ""
	if kShowTimeCueNumber is not "" then
		set noteBlock to ¬
			"        if not done then" & LF & ¬
			"            repeat with NL in (every cue list)" & LF & ¬
			"                try" & LF & ¬
			"                    repeat with NC in (every cue of NL)" & LF & ¬
			"                        try" & LF & ¬
			"                            if (q number of NC) is " & qt & ¬
			kShowTimeCueNumber & qt & " then set notes of NC to " & ¬
			"(" & qt & "Cleanup could not remove the cue list. " & qt & ¬
			" & why)" & LF & ¬
			"                        end try" & LF & ¬
			"                    end repeat" & LF & ¬
			"                end try" & LF & ¬
			"            end repeat" & LF & ¬
			"        end if" & LF
	end if

	return "-- auto-generated by PreShowAnnouncements.applescript." & LF & ¬
		"-- removes the temporary pre-show cue list so its wall clock" & LF & ¬
		"-- triggers do not fire again tomorrow." & LF & ¬
		"delay 2" & LF & ¬
		"tell application id " & qt & "com.figure53.QLab.5" & qt & LF & ¬
		"    tell front workspace" & LF & ¬
		stopBlock & ¬
		"        set done to false" & LF & ¬
		"        set why to " & qt & "list not found" & qt & LF & ¬
		"        repeat with L in (every cue list)" & LF & ¬
		"            try" & LF & ¬
		"                if (q name of L) is " & qt & listName & qt & " then" & LF & ¬
		"                    set TL to contents of L" & LF & ¬
		"                    try" & LF & ¬
		theAction & LF & ¬
		"                        set done to true" & LF & ¬
		"                    on error errMsg" & LF & ¬
		"                        set why to errMsg" & LF & ¬
		"                        try" & LF & ¬
		"                            set armed of TL to false" & LF & ¬
				"                            set q name of TL to (" & qt & �
				"                            set q name of TL to (" & qt & "[DONE] " & qt & " & (q name of TL))" & LF & 
		"                    end try" & LF & ¬
		"                    exit repeat" & LF & ¬
		"                end if" & LF & ¬
		"            end try" & LF & ¬
		"        end repeat" & LF & ¬
		noteBlock & ¬
		"    end tell" & LF & ¬
		"end tell"
end cleanupScriptSource


-- Make a cue and hand back a reference to it.
--
-- QLab's make returns the new cue, which is the reliable way to get hold of
-- it. Reading it back out of the selection instead fails whenever QLab does
-- not select what it just made, and "last item of {}" raises -1728 rather
-- than anything that explains itself. The selection is kept only as a
-- fallback for a QLab version that returns nothing.
on newCue(theType)
	tell application id "com.figure53.QLab.5"
		tell front workspace
			-- Same reason as the cue list above: assign first, so a make that
			-- hands nothing back leaves an empty variable and not a missing
			-- one.
			set theCue to missing value
			try
				set theCue to make type theType
			end try
			if theCue is missing value then
				set sel to (selected as list)
				if (count of sel) is 0 then error ¬
					("QLab made no " & theType & " cue, or would not say " & ¬
						"which one. Nothing was built.")
				set theCue to last item of sel
			end if
			return theCue
		end tell
	end tell
end newCue

-- Send a cue to an output patch. Returns true if it took, and true without
-- doing anything for a patch of 0, which means leave the workspace default
-- alone.
on applyPatch(theCue, thePatch)
	if thePatch is 0 then return true
	tell application id "com.figure53.QLab.5"
		try
			set patch of theCue to thePatch
			return true
		end try
	end tell
	return false
end applyPatch

-- Set a cue's master, left and right levels. Returns true if all three took.
--
-- Row 0 column 0 is the cue's master. Rows and columns from 1 are the
-- crosspoints, so a stereo file on default routing is left at 1/1 and right
-- at 2/2. Each is tried on its own, so a mono file still gets its master and
-- left set rather than failing outright.
on applyLevels(theCue, theLevel)
	-- A level edited down to two numbers would fail on item 3 rather than
	-- say so, and the summary would blame the cue instead of the config.
	if (count of theLevel) < 3 then return false
	set allSet to true
	tell application id "com.figure53.QLab.5"
		try
			setLevel theCue row 0 column 0 db (item 1 of theLevel)
		on error
			set allSet to false
		end try
		try
			setLevel theCue row 0 column 1 db (item 2 of theLevel)
		on error
			set allSet to false
		end try
		try
			setLevel theCue row 0 column 2 db (item 3 of theLevel)
		on error
			set allSet to false
		end try
	end tell
	return allSet
end applyLevels

-- Tick the wall clock trigger checkbox. Returns true if it worked.
--
-- Tries the constant, then the string, because which one QLab accepts has
-- changed between versions. A cue that does not trigger makes the whole
-- thing pointless. Returns a result instead of raising, so the build
-- finishes and the summary can name any cue needing the box ticked by hand.
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
-- DIALOGS
--------------------------------------------------------------------------------

on chooseExistingAction(existingTime)
	set msg to "A pre-show cue list already exists"
	if existingTime is not "" then set msg to msg & ", set for " & existingTime
	set msg to msg & "." & return & return & "Rebuild deletes it and makes " & ¬
		"it again against the current schedule and a new show time."
	display dialog msg buttons {"Delete It", "Rebuild"} ¬
		default button "Rebuild" with title "Pre-Show Announcements"
	set b to button returned of the result
	if b is "Delete It" then return "DELETE"
	return "REBUILD"
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
			-- Hand the bad text back as the default, so a mistyped 199:30
			-- is corrected rather than retyped
			display dialog "Couldn't read \"" & theReply & ¬
				"\". Please use HH:MM, e.g. 19:30." buttons {"Try Again"} ¬
				default button 1 with icon caution
			set defaultText to theReply
		end try
	end repeat
end askForShowTime


-- List any audio files that are missing. A cue with no file looks fine in
-- QLab and is silent in the house, so it is worth checking before building.
on warnAboutMissingFiles(theSchedule)
	if kSilent then return -- never block a stream deck press with a dialog
	set missingFiles to {}
	repeat with theRow in theSchedule
		set thePath to item 3 of theRow
		if not fileExists(thePath) then
			-- The same file appears on several rows, so only mention it once
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
-- TIME AND TEXT HELPERS
--------------------------------------------------------------------------------

-- "19:30", "7:30 pm" and "1930" all come out as seconds since midnight.
--
-- The time comes from a dialog, an OSC message or a cue name typed by hand, so refusing over a stray space
-- would be unhelpful. The range check stops "25:70" becoming a cue that never fires.
on secondsOfDayFromText(theText)
	set theText to trimText(theText as text)
	set isPM to (theText contains "pm" or theText contains "PM")
	set isAM to (theText contains "am" or theText contains "AM")

	-- Strip to digits and separators, so anything around the time falls away
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
		-- Bare "1930"
		set hh to (text 1 thru -3 of cleaned) as integer
		set mm to (text -2 thru -1 of cleaned) as integer
	end if

	if isPM and hh < 12 then set hh to hh + 12
	if isAM and hh is 12 then set hh to 0
	if hh > 23 or hh < 0 or mm > 59 or mm < 0 then error "time out of range"
	return hh * 3600 + mm * 60
end secondsOfDayFromText

-- Find the first thing that looks like a time in a longer string, or missing
-- value. This lets the show time sit inside a cue name such as
-- "SHOW TIME 19:30 (matinee)".
--
-- A colon is required, so another number in the name cannot be taken for the
-- time. The delimiters are reset on the error path too. They are global, and
-- leaving them set breaks the next handler that splits a string.
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

-- Pull "19:30" back out of a cue list name like "Temp-PreShow 19:30"
on timeFromListName(theName)
	set s to firstTimeTokenSeconds(theName)
	if s is missing value then return ""
	return hhmmFromSeconds(s)
end timeFromListName

-- Keep a time of day inside the day. A call earlier than midnight wraps back
-- to the evening before, which is what a wall clock trigger wants.
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


-- Coercing to an alias fails if the path does not resolve, which is the cheap
-- way to test for a file
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

-- Spaces only, which is all a typed or OSC show time picks up
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
-- COMPANION AND STREAM DECK SETUP
--
-- IN QLAB, a permanent cue list called "PRE-SHOW CONTROL" with three cues.
-- These stay in the show file. They are not part of the temporary list, and
-- they are the only pre-show cues there at the start of a day.
--
--   PSTIME   memo cue.   Name: "SHOW TIME - not set"
--                        Companion overwrites this name with the chosen time.
--                        disarm it. it is a label, not something to play.
--   PSBUILD  script cue:
--     tell (load script (POSIX file "/Users/you/Scripts/PreShow.scpt")) to buildFromQLabCue()
--   PSCLEAR  script cue:
--     tell (load script (POSIX file "/Users/you/Scripts/PreShow.scpt")) to clearPreShow()
--
-- Export this file via file > export > file format: script to that .scpt
-- path. QLab, the login item and script editor then share one copy, so there
-- is no second version to keep in step.
--
-- ON THE MAC, a login item that runs purgeOnLaunch() every morning. Save it
-- as an applet (file > export > file format: application) holding these two
-- lines, then add it to login items:
--
--   tell (load script (POSIX file "/Users/you/Scripts/PreShow.scpt")) to purgeOnLaunch()
--
-- This is required, not optional. QLab autosaves, so a list built yesterday
-- is on disk and would come back armed today.
--
-- IN COMPANION, three pages on the qlabfb connection, plus two custom
-- variables, showHour and showMinute. Turn off persist value on both, so a
-- Companion restart leaves them blank and nobody can build yesterday's time.
--
--   Page 10  PRE-SHOW
--     "NEW SHOW"      -> internal: set surface page = 11
--                       button text: NEW SHOW\n$(custom:showHour):$(custom:showMinute)
--     "BUILD"         -> qlabfb: custom OSC /cue/PSTIME/name
--                          string argument: $(custom:showHour):$(custom:showMinute)
--                    -> wait 250 ms
--                    -> qlabfb: custom OSC /cue/PSBUILD/start
--     "CANCEL"        -> qlabfb: custom OSC /cue/PSCLEAR/start
--
--   Page 11  SELECT HOUR    24 buttons, each:
--                       internal: custom variable set value, showHour = "18"
--                       internal: set surface page = 12
--
--   Page 12  SELECT MINUTE  12 buttons at 5 minute steps, each:
--                       internal: custom variable set value, showMinute = "30"
--                       internal: set surface page = 10
--
-- Store the hour and minute padded to two characters ("07", "05") in the
-- button actions. That keeps "19:30" well formed without any expression
-- maths.
--
-- The two OSC messages on BUILD must arrive in order: the name is set, then
-- the build cue reads it back. That is what the 250 ms wait is for.
--
-- Nothing is built until BUILD is pressed, and BUILD refuses unless there is
-- a readable time in PSTIME's name. There is no default show time anywhere.
--------------------------------------------------------------------------------
