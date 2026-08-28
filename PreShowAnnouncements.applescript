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
