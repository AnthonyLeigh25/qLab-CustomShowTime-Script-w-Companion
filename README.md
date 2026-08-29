# Pre-Show Announcements for QLab 5

Front of house calls that fire themselves. Pick a show time on a Stream Deck, press BUILD, and QLab gets a temporary cue list of pre-show announcements, each one triggered by the clock rather than by anyone pressing GO. At show time the list deletes itself.

Built for a booth Mac that restarts overnight and runs unattended.

## The three buttons

| Press | What happens |
|---|---|
| **NEW SHOW** | Drills through Select Hour and Select Minute, and shows the chosen time on the button |
| **BUILD** | Writes the time into a control cue, then builds `Temp-PreShow 19:30`: eight announcement cues plus a cleanup cue, all wall clock triggered |
| **CANCEL** | Deletes the temporary list and clears the stored time |

There is no default show time anywhere. Until someone picks one, BUILD refuses and nothing is created, because announcements at the wrong time are worse than no announcements.

## How the pieces fit

Companion writes the chosen time into the name of a permanent QLab cue over OSC, then starts a Script cue. That cue loads the compiled AppleScript and calls one handler, which reads the time back out and builds the list. A login item runs the same script's purge handler each morning, which matters because QLab autosaves the workspace, so a list built for a show that was cancelled would otherwise come back armed the next day.

## What is in here

- `PreShowAnnouncements.applescript` - the whole thing. Configuration at the top, the Companion and Stream Deck wiring documented at the foot.
- `SETUP.md` - installation, ten parts, roughly an hour on a day with no show.
- `CONTRIBUTING.md` - conventions for commits and for the writing style.

Start with `SETUP.md`.

## Worth knowing

**None of this has been run against a real QLab 5 yet.** It was written against QLab's published AppleScript and OSC dictionaries. Work through the interactive test and the full dress test in `SETUP.md` on a non-show day before trusting it with an audience in the building.
