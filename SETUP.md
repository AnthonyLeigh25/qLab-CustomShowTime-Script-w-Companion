# Pre-Show Announcements - Setup

Building the Stream Deck to Companion to QLab 5 pre-show system.

Allow about an hour. Do it on a day with no show.

---

## What you end up with

| Stream Deck press | What happens |
|---|---|
| **NEW SHOW** | Pick an hour, then a minute |
| **BUILD** | Creates a `Temp-PreShow 19:30` cue list: 8 announcements and a cleanup cue |
| **CANCEL** | Deletes the list and clears the stored time |

The announcements fire themselves at wall clock times. Nobody presses GO. At show time the cleanup cue deletes the list.

There is **no default show time**. Until someone picks one, BUILD refuses.

---

## Part 1 - Prepare the audio

1. Record or gather four files: Welcome, 10 Minute Call, 5 Minute Call, Final Call.
2. Put them somewhere permanent and local. **Not** a network share, not a folder that gets cleared. Something like `/Users/booth/Show Audio/Announcements/`.
3. Play each one in QLab by hand, to check it routes to the right outputs.

## Part 2 - Configure the script

1. Copy `PreShowAnnouncements.applescript` onto the QLab Mac, say into `/Users/booth/Scripts/`.
2. Open it in **Script Editor**.
3. Edit the four file paths at the top. Drag each audio file into the Script Editor window to get its POSIX path, then paste it between the quotes.
4. Check the schedule. Note that T-15 announces the *10 minute* call and T-10 the *5 minute* call, as specified. Fix those two rows now if that is wrong.
5. Press **Command K** to compile. It must compile cleanly before you go further.

## Part 3 - First test, interactive

Do this before any Companion work, so you test one thing at a time.

1. Open your QLab workspace. Make sure it is the frontmost one.
2. In Script Editor, press **Run**.
3. macOS will ask whether Script Editor may control QLab. Click **OK**. Miss this dialog and nothing works, see Part 8.
4. Enter a time about **four minutes from now**.
5. You should get a summary dialog and a new cue list, `Temp-PreShow HH:MM`, holding 8 audio cues and a cleanup cue, each showing its trigger time.
6. Click a cue and open the **Triggers** tab. Check the **Wall Clock** box is ticked and the time is right.
7. Wait. The T-2 cue should fire on its own. At show time the list should delete itself.

If the wall clock boxes are not ticked, the summary will have said so. Tick one by hand and check the property name in QLab's dictionary, via *File > Open Dictionary* in Script Editor.

## Part 4 - Export the compiled script

Everything else loads this one file, so there is no second copy to keep in step.

1. In Script Editor: **File > Export**
2. File Format: **Script**
3. Save as `/Users/booth/Scripts/PreShow.scpt`

Edit the `.applescript` later and you must **re-export it**, or QLab keeps running the old version.

## Part 5 - Build the control cues in QLab

Make a cue list called `PRE-SHOW CONTROL`. It stays in the show file.

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

Leave **Run in separate process** ticked on both Script cues. That is QLab's default.

Now test by hand. Rename `PSTIME` to `SHOW TIME 19:30`, then GO `PSBUILD`. You should get the temporary list. GO `PSCLEAR` and it should vanish, with `PSTIME` back to `SHOW TIME - not set`.

> **Script cues need a QLab licence.** They do not run in the free tier. If `PSBUILD` does nothing, check your licence first.

## Part 6 - The launch purge (required)

**Do not skip this.** QLab autosaves, so a list built today is written to disk. If the show is cancelled, or QLab is quit before the cleanup cue runs, tomorrow's launch brings that list back **armed**, and it announces again at yesterday's times. The daily restart does not clear it. This does.

1. In Script Editor, open a new document and paste:
   ```applescript
   set b to load script (POSIX file "/Users/booth/Scripts/PreShow.scpt")
   tell b to purgeOnLaunch()
   ```
2. **File > Export**, File Format: **Application**, saved as `/Users/booth/Scripts/PreShow Purge.app`
3. **Run it once by hand now.** macOS will ask whether it may control QLab. Click OK. This approval cannot be given on an unattended restart, so it has to happen here.
4. **System Settings > General > Login Items**, then **+**, and add `PreShow Purge.app`.

`purgeOnLaunch()` waits up to five minutes for QLab to open a workspace, so it does not matter whether it runs before or after QLab.

## Part 7 - Make the daily restart actually work

Your Mac restarts and relaunches QLab daily. Four things have to be true for that to work:

1. **The Mac logs in automatically.** *System Settings > Users & Groups > Automatically log in as.*
   **FileVault blocks this.** With FileVault on, the Mac sits at the unlock screen and nothing launches. Turn it off on a booth machine, or accept that someone unlocks it each morning.
2. **The workspace opens automatically.** QLab has no reopen last workspace option, so add the workspace *document* to Login Items alongside the purge app: *Login Items > + > select your `.qlab5` file.*
3. **The Mac never sleeps.** Wall clock triggers do not fire while asleep. In Terminal:
   ```bash
   sudo pmset -a sleep 0 disksleep 0 displaysleep 30
   ```
4. **The restart is scheduled.** If an MDM is not already doing it:
   ```bash
   sudo pmset repeat restart MTWRFSU 04:00:00
   ```

Also check *Workspace Settings > OSC* in QLab has **OSC controls enabled**. Note the passcode if you have set one.

## Part 8 - Automation permissions

The commonest cause of "it worked yesterday and not today". Each of these needs a one time approval, given by clicking a dialog:

- Script Editor controlling QLab (Part 3)
- QLab controlling QLab, meaning the Script cues (Part 5)
- PreShow Purge.app controlling QLab (Part 6)

Check them in *System Settings > Privacy & Security > Automation*. All three should list QLab underneath, switched on. **Renaming or moving `PreShow.scpt` or the purge app resets its permission**, so run it by hand again after any move.

## Part 9 - Companion

Two custom variables, three pages.

### Custom variables

*Variables tab > Custom Variables*, create `showHour` and `showMinute`.
Set both to **not persist**. A Companion restart then leaves them blank, so nobody can build yesterday's time by accident.

### Connection

The **qlabfb** connection, pointed at the QLab Mac. Use `127.0.0.1` if Companion runs on the same machine. Add the OSC passcode if you set one.

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
so the Stream Deck always shows the time selected.

### Page 11 - SELECT HOUR

24 buttons. Each one:
1. `internal: Custom Variable Set Value` to `showHour` = `"18"`
2. `internal: Set surface page` to 12

### Page 12 - SELECT MINUTE

12 buttons at five minute steps. Each one:
1. `internal: Custom Variable Set Value` to `showMinute` = `"30"`
2. `internal: Set surface page` to 10

> **Pad the values.** Enter `"07"` and `"05"`, not `7` and `5`. Companion *can* pad with expressions, but typing two character strings rules out `19:5` faults for no effort.

The two OSC messages on BUILD must arrive in order: the name is set, then the build cue reads it. That is what the 250 ms wait is for.

## Part 10 - Full dress test

1. Restart the Mac. Do not touch anything. Check it logs in, QLab opens the workspace, and `PSTIME` reads `SHOW TIME - not set`.
2. Press **BUILD** without picking a time. Nothing should be built, and `PSTIME`'s notes should read `BUILD REFUSED - no show time set`. QLab will flag an error on the Script cue. **That is correct.**
3. Press **NEW SHOW**, pick an hour and minute about five minutes ahead, press **BUILD**.
4. Check the new cue list. Check the trigger times, and that `PSTIME`'s notes read `Last build: 8 cues...`.
5. Let the T-2 cue fire on its own. Listen to it in the house.
6. Press **CANCEL**. The list should disappear and `PSTIME` should reset.
7. Build once more, then **quit QLab before the cleanup cue runs**, and restart the Mac. After login the purge should have removed the stale list. This step is what proves you are safe on a cancelled show.

---

## Daily use

1. **NEW SHOW**, then hour, then minute
2. **BUILD**
3. Confirm the times on screen
4. Leave it. The announcements and the cleanup run themselves.

If the show time moves, pick the new time and press BUILD again. It deletes and rebuilds. That holds whether or not you have already built. BUILD is always safe to press twice.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| BUILD does nothing at all | Script cues need a QLab licence, or Automation permission is missing (Part 8) |
| `No cue numbered PSTIME was found` | Control cues missing, or the open workspace is not the one you set up |
| `BUILD REFUSED - no show time set` | No time picked on the Stream Deck. Working as intended |
| Cues built at the wrong time | Companion variables not padded. Check for `19:5` |
| Cues built but silent | File paths wrong. The summary lists missing files. Check a cue's Audio tab |
| Wall clock boxes not ticked | Reported in the summary. Tick by hand, and check the property name in QLab's dictionary |
| Nothing fires overnight | The Mac slept (Part 7.3), or the workspace was not open |
| Yesterday's list still present | Purge app not installed, or its permission was reset by moving it |
| Announcements fired on a dark day | Same as above. The purge is the only thing preventing this |

**None of this has been tested on a live QLab 5 system.** The script was written from QLab's published AppleScript and OSC dictionaries, but has never been run. Work through Parts 3, 5 and 10 properly on a non-show day before trusting it with an audience in the building.
