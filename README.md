# Pre-Show Announcements for QLab 5

Front of house calls that fire themselves.

Pick a show time on a Stream Deck, press BUILD, and QLab gets a temporary cue list of pre-show announcements. Each one is triggered by the clock, so nobody presses GO. At show time the list deletes itself.

Built for a booth Mac that restarts overnight and runs unattended.

## The three buttons

| Press | What happens |
|---|---|
| **NEW SHOW** | Pick an hour, then a minute. The button shows the time chosen |
| **BUILD** | Builds `Temp-PreShow 19:30`: eight announcement cues and a cleanup cue, all clock triggered |
| **CANCEL** | Deletes the list and clears the stored time |

There is no default show time. Until someone picks one, BUILD refuses and nothing is built. Announcements at the wrong time are worse than none.

## How the pieces fit

Companion sends the chosen time over OSC into the name of a permanent QLab cue, then starts a Script cue. That cue loads the compiled AppleScript, reads the time back out and builds the list.

A login item runs the same script's purge handler each morning. QLab autosaves the workspace, so without it a list built for a cancelled show would come back armed the next day.

## What is in here

- `PreShowAnnouncements.applescript` - the whole thing. Settings at the top, Companion wiring at the foot.
- `SETUP.md` - installation, ten parts, about an hour on a day with no show.
- `CONTRIBUTING.md` - conventions for commits and writing style.

Start with `SETUP.md`.

## Worth knowing

**None of this has been run against a real QLab 5 yet.** It was written from QLab's published AppleScript and OSC dictionaries. Work through the interactive test and the dress test in `SETUP.md` on a non-show day before trusting it with an audience in the building.
