# Pre-Show Announcements for QLab 5

Front of house calls that fire themselves.

Pick a show time on a Stream Deck using Companion, press BUILD, and QLab gets a temporary cue list of pre-show announcements. Each one is triggered by the world clock. At show time or system restart, the list deletes itself.

## The three buttons

| Press | What happens |
|---|---|
| **NEW SHOW** | Pick an hour, then a minute. The button shows the time chosen |
| **BUILD** | Builds `Temp-PreShow 19:30`: eight announcement cues and a cleanup cue, all clock triggered |
| **CANCEL** | Deletes the list and clears the stored time |

There is no default show time. Until someone picks one, BUILD refuses and nothing is built.

## How the pieces fit

Companion sends the chosen time over OSC into the name of a permanent QLab cue, then starts a Script cue. That cue loads the compiled AppleScript, reads the time back out and builds the list.

A login item runs the same script's purge handler each morning. QLab autosaves the workspace, so without it a list built for a cancelled show would come back armed the next day.

Start with `SETUP.md`.
