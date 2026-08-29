# Pre-Show Announcements - Setup

Building the Stream Deck to Companion to QLab 5 pre-show announcement system.

Allow about an hour, and do it on a day with no show.

---

## What you end up with

| Stream Deck press | What happens |
|---|---|
| **NEW SHOW** | Drills through *Select Hour* then *Select Minute* |
| **BUILD** | Creates a `Temp-PreShow 19:30` cue list with 8 self-triggering announcements and a cleanup cue |
| **CANCEL** | Deletes that list and clears the stored time |

Announcements then fire themselves at wall clock times. Nobody presses GO. At show time the cleanup cue deletes the whole temporary list.

There is **no default show time**. Until someone picks one, BUILD refuses and nothing is created.

---

## Part 1 - Prepare the audio

1. Record or gather four files: Welcome, 10 Minute Call, 5 Minute Call, Final Call.
2. Put them somewhere permanent and local, **not** a network share, not a folder that gets cleared. Something like `/Users/booth/Show Audio/Announcements/`.
3. Play each one in QLab manually to confirm it routes to the right outputs.

## Part 2 - Configure the script

1. Copy `PreShowAnnouncements.applescript` onto the QLab Mac, for example into `/Users/booth/Scripts/`.
2. Open it in **Script Editor**.
3. Edit the four file paths at the top. Drag each audio file into the Script Editor window to get its exact POSIX path, then paste it between the quotes.
4. Check the schedule block reads how you want it. Note that T-15 announces the *10 minute* call and T-10 the *5 minute* call, as specified. If that is wrong, fix those two rows now.
5. Press **Command K** to compile. It must compile with no errors before going further.

## Part 3 - First test, interactive

Do this before any Companion work, so you are testing one thing at a time.

1. Open your QLab workspace. Make sure it is the frontmost workspace.
2. In Script Editor, press **Run**.
3. macOS will ask whether Script Editor may control QLab. Click **OK**. If you miss this dialog, nothing will work, see Part 8.
4. Enter a time about **four minutes from now**.
5. You should get a summary dialog, and a new cue list in QLab named `Temp-PreShow HH:MM` containing 8 audio cues and a cleanup cue, each showing its trigger time.
6. Click a cue and open the **Triggers** tab. Confirm the **Wall Clock** checkbox is ticked and the time is right.
7. Wait. The T-2 cue should fire on its own. Then at show time the list should delete itself.

If the wall clock boxes are not ticked, the summary dialog will have told you so. Tick one by hand and check the property name against QLab's dictionary, via *File > Open Dictionary* in Script Editor.

## Part 4 - Export the compiled script

Everything else loads this one file, so there is never a second copy to keep in step.

1. In Script Editor: **File > Export**
2. File Format: **Script**
3. Save as `/Users/booth/Scripts/PreShow.scpt`

Whenever you edit the `.applescript` later, **re-export it**, or QLab keeps running the old version.

## Part 5 - Build the control cues in QLab

Make a new cue list called `PRE-SHOW CONTROL`. This lives in the show file permanently.

**1. Memo cue**
- Cue number: `PSTIME`
- Name: `SHOW TIME - not set`
- **Disarm it.** It is a label, not something to play.

**2. Script cue**
- Cue number: `PSBUILD`
- Name: `BUILD PRE-SHOW`
- Script:
  ```applescript
  set b to load script (POSIX file "/Users/booth/Scripts/PreShow.scpt")
  tell b to buildFromQLabCue()
  ```

**3. Script cue**
- Cue number: `PSCLEAR`
- Name: `CANCEL PRE-SHOW`
- Script:
  ```applescript
  set b to load script (POSIX file "/Users/booth/Scripts/PreShow.scpt")
  tell b to clearPreShow()
  ```

Leave **Run in separate process** ticked on both Script cues, which is QLab's default.

Now test by hand: select `PSTIME`, rename it to `SHOW TIME 19:30`, then GO `PSBUILD`. You should get the temporary list. GO `PSCLEAR` and it should vanish, with `PSTIME` reset to `SHOW TIME - not set`.

> **Script cues need a QLab licence.** They do not run in the free tier. If `PSBUILD` does nothing, check your licence first.

## Part 6 - The launch purge (required)

**Do not skip this.** QLab autosaves the workspace on a timer, so a temporary list built today is written to disk. If a show is cancelled, or QLab is quit before the cleanup cue runs, tomorrow's fresh launch will have yesterday's list, **armed**, and it will announce again at yesterday's times. The daily restart does not clean it up. This does.

1. In Script Editor, open a new document and paste:
   ```applescript
   set b to load script (POSIX file "/Users/booth/Scripts/PreShow.scpt")
   tell b to purgeOnLaunch()
   ```
2. **File > Export** then File Format: **Application**, saved as `/Users/booth/Scripts/PreShow Purge.app`
3. **Run it once manually now.** macOS will ask whether it may control QLab, click OK. This one time approval cannot be granted on a headless restart, so it has to be done by hand here.
4. **System Settings > General > Login Items** then **+** and add `PreShow Purge.app`.

`purgeOnLaunch()` waits up to five minutes for QLab to finish opening a workspace, so it does not matter whether it runs before or after QLab.

## Part 7 - Make the daily restart actually work

Your Mac restarts and relaunches QLab daily. Four things must be true for that to be reliable:

1. **The Mac logs in automatically.** *System Settings > Users & Groups > Automatically log in as.*
   **FileVault blocks this.** If FileVault is on, the Mac sits at the disk unlock screen and nothing launches. Turn FileVault off on a booth machine, or accept that someone unlocks it each morning.
2. **The workspace opens automatically.** QLab's launch preference has no reopen last workspace option, so add the workspace *document* to Login Items alongside the purge app: *Login Items > + > select your `.qlab5` file.*
3. **The Mac never sleeps.** Wall clock triggers do not fire while asleep. In Terminal:
   ```bash
   sudo pmset -a sleep 0 disksleep 0 displaysleep 30
   ```
4. **The restart itself is scheduled.** If you are not already doing this via an MDM, then:
   ```bash
   sudo pmset repeat restart MTWRFSU 04:00:00
   ```

Also confirm in QLab: *Workspace Settings > OSC* has **OSC controls enabled**, and note the passcode if you have set one.

## Part 8 - Automation permissions

The commonest cause of "it worked yesterday and not today". Each of these needs a one time approval, granted by clicking a dialog:

- Script Editor controlling QLab (Part 3)
- QLab controlling QLab, meaning the Script cues (Part 5)
- PreShow Purge.app controlling QLab (Part 6)

Check them in *System Settings > Privacy & Security > Automation*. All three should list QLab underneath and be switched on. **Renaming or moving `PreShow.scpt` or the purge app resets its permission**, so re-run it by hand after any move.

## Part 9 - Companion

Two custom variables, three pages.

### Custom variables

*Variables tab > Custom Variables*, create `showHour` and `showMinute`.
Set both to **not persist** across restarts. That way a Companion restart leaves them blank and nobody can accidentally build yesterday's time.

### Connection

The **qlabfb** connection, pointed at the QLab Mac, `127.0.0.1` if Companion runs on the same machine, with the OSC passcode if you set one.

### Page 10 - PRE-SHOW

| Button | Actions |
|---|---|
| **NEW SHOW** | `internal: Set surface page` to 11 |
| **BUILD** | 1. qlabfb custom OSC to `/cue/PSTIME/name`, string arg `$(custom:showHour):$(custom:showMinute)`<br>2. `wait 250 ms`<br>3. qlabfb custom OSC to `/cue/PSBUILD/start` |
| **CANCEL** | qlabfb custom OSC to `/cue/PSCLEAR/start` |

Set NEW SHOW's button text to:
```
NEW SHOW
$(custom:showHour):$(custom:showMinute)
```
so the Stream Deck always shows the time currently selected.

### Page 11 - SELECT HOUR

24 buttons. Each one:
1. `internal: Custom Variable Set Value` to `showHour` = `"18"`
2. `internal: Set surface page` to 12

### Page 12 - SELECT MINUTE

12 buttons at five minute steps. Each one:
1. `internal: Custom Variable Set Value` to `showMinute` = `"30"`
2. `internal: Set surface page` to 10

> **Pad the values.** Enter `"07"` and `"05"`, not `7` and `5`. Companion *can* pad with expressions, but hardcoding two character strings removes a whole class of `19:5` faults for no effort.

The two OSC messages on BUILD have to arrive in order, since the name is set and then the build cue reads it. That is what the 250 ms wait is for.

## Part 10 - Full dress test

1. Restart the Mac. Do not touch anything. Confirm it logs in, QLab opens the workspace, and `PSTIME` reads `SHOW TIME - not set`.
2. Press **BUILD** without selecting a time. Nothing should be built, and `PSTIME`'s notes should read `BUILD REFUSED - no show time set`. QLab will flag an error on the Script cue. **This is the correct behaviour.**
3. Press **NEW SHOW**, pick an hour and minute about five minutes ahead, press **BUILD**.
4. Check the new cue list. Confirm the trigger times, and that `PSTIME`'s notes read `Last build: 8 cues...`.
5. Let the T-2 cue fire on its own. Listen to it in the house.
6. Press **CANCEL**. Confirm the list disappears and `PSTIME` resets.
7. Build once more, then **quit QLab without letting the cleanup cue run**, and restart the Mac. After login the purge should have removed the stale list. This is the step that proves you are safe on a cancelled show.

---

## Daily use

1. **NEW SHOW**, then hour, then minute
2. **BUILD**
3. Confirm the times on screen
4. Leave it. The announcements and the cleanup run themselves.

If the show time moves before you have built, just pick the new time and press BUILD again. It deletes and rebuilds. If it moves *after* you have built, same thing. BUILD is always safe to press twice.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| BUILD does nothing at all | Script cues need a QLab licence, or Automation permission was not granted (Part 8) |
| `No cue numbered PSTIME was found` | Control cues missing, or the workspace open is not the one you set up |
| `BUILD REFUSED - no show time set` | No time selected on the Stream Deck. Working as intended |
| Cues built at the wrong time | Companion variables not padded, check for `19:5` |
| Cues built but silent | File paths wrong. The summary lists any missing files, check the Audio tab of a cue |
| Wall clock boxes not ticked | Reported in the summary. Tick by hand and check the property name in QLab's dictionary |
| Nothing fires overnight | Mac slept (Part 7.3), or the workspace was not open |
| Yesterday's list still present | Purge app not installed, or its Automation permission was reset by moving it |
| Announcements fired on a dark day | Same as above. The purge is the only thing preventing this |

**Every element of this is unverified against a live QLab 5 system.** The script was written against QLab's published AppleScript and OSC dictionaries but has never been run. Work through Parts 3, 5 and 10 properly on a non-show day before trusting it with an audience in the building.
