# Pre-Show Announcements for QLab 5

Self-building and firing Front of house calls using applescript. This is primarily for a FOH QLab System that I already use with Companion for those weird and pesky times we don't already have made. So hopefully this works :-)

On a stream deck with companion, press New Show, pick the time and press build. Simples! Then QLab builds a temporary cue list of pre-show announcements. Each is triggered by the world clock. At show time or system restart, the list empties itself. Whatever is configurated, if I remember what I set.

## Three Streamdeck buttons

| Press | What happens |
|---|---|
| **NEW SHOW** | Pick an hour, then a minute. The button shows the time chosen |
| **BUILD** | Builds `Temp-PreShow 19:30`: one cue per call in the schedule, ten as shipped, plus a cleanup cue, all clock triggered |
| **CANCEL** | Deletes the list and clears the stored time |

There is no default show time. This is for creating those weird show times that you don't have presets for or just y'know use this instead of building presets I guess.

## The technical shizzle

Companion sends the chosen time over OSC into the name of a permanent QLab cue, then starts a Script cue. That cue loads the compiled AppleScript, reads the time and builds the list. Voila!

A login item runs the same script's purge handler each morning. QLab autosaves the workspace, so without it a list built for a cancelled show would come back the next day, which isn't really ideal. I don't want Duty Managers calling me for random show calls being triggered at the wrong times. I already have enough to deal with.

## Did it work though

Two more cues sit on the permanent list and the script starts one of them once the build settles. Cue ID is set with `PSOK` if it went cleanly, `PSFAIL` if it did not. Personally, gonna make it trigger a graphic to display on a wee screen.

Failed means any of these, because all four leave you with a list that looks perfectly healthy and does nothing:

- Nothing was built at all, usually no show time set
- A cue's wall clock box wouldn't enable
- An audio file was missing
- The cleanup cue could not be made

Both cues are stopped before either one fires, when you press CANCEL, and by the cleanup cue at show time. So nothing is left showing.

Start with `SETUP.md`. Hopefully my instructions work, to be confirmed......maybe.....I can only guess my own work here.
