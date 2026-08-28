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
		end tell
	end tell

	return listName
end buildPreShow
