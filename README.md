# Pre-Show Announcements for QLab 5

Self-building and firing Front of house calls using applescript. This is primarily for a FOH QLab System that I already use with Companion so hopefully it works :-)

On a stream deck with companion, press New Show, pick the time and press build. Simples! Then QLab builds a temporary cue list of pre-show announcements. Each is triggered by the world clock. At show time or system restart, the list deletes itself.

## Three Streamdeck buttons

| Press | What happens |
|---|---|
| **NEW SHOW** | Pick an hour, then a minute. The button shows the time chosen |
| **BUILD** | Builds `Temp-PreShow 19:30`: one cue per call in the schedule, ten as shipped, plus a cleanup cue, all clock triggered |
| **CANCEL** | Deletes the list and clears the stored time |

There is no default show time. This is for creating those weird show times that you don't have presets for or just y'know use this instead of building presets I guess.

## The technical shizzle

Companion sends the chosen time over OSC into the name of a permanent QLab cue, then starts a Script cue. That cue loads the compiled AppleScript, reads the time back out and builds the list.

A login item runs the same script's purge handler each morning. QLab autosaves the workspace, so without it a list built for a cancelled show would come back armed the next day.

## Did it work though

Two more cues sit on the permanent list and the script starts one of them once the build settles. `PSOK` if it went cleanly, `PSFAIL` if it did not. Make them whatever suits your control position: a blip, a light, or a Network cue back to Companion to turn a button green or red. Beats squinting at QLab from across the room.

Failed means any of these, because all four leave you with a list that looks perfectly healthy and does nothing:

- Nothing was built at all, usually no show time set
- A cue's wall clock box would not tick, so it never fires
- An audio file was missing, so a cue plays silence
- The cleanup cue could not be made, so the list is there again tomorrow

Both cues get stopped before either one fires, when you press CANCEL, and by the cleanup cue at show time. So nothing is left blinking away during act one, and you can safely build them as looping cues if you would rather have a steady light than a one-shot.

Start with `SETUP.md`. Hopefully my instructions work, to be confirmed......
