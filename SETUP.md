# Pre-Show Announcements - Setup

## Companion Buttons

| Stream Deck Button | Action |
|---|---|
| **NEW SHOW** | Pick an hour, then a minute |
| **BUILD** | Creates a `Temp-PreShow 19:30` cue list: Audio cue announcements and a cleanup cue |
| **CANCEL** | Deletes the list and clears the stored time |

The announcements are triggered by wall clock times. At show time or otherwise configured, the cleanup cue deletes the list.

There is **no default show time**.

## Requirements

- A QLab 5 **licence** to be able to use scripts
- The QLab workspace you will use for the shows.
- Companion
- Admin login to set Login Items and the Terminal commands in Part 8.

---

## Part 1 - Prepare the audio

1. Collect announcement audio. Schedule has options for four files: Welcome, 10 minute call, 5 Minute Call and Final Call. If there is a call you don't use, don't provide a directory.
2. Put them somewhere permanent and local. **Not** a network share or folder that gets easily cleared. Something like `/Users/qlab/Show Audio/Announcements/`.
3. Make sure each files plays in qLab by making a standard audio cue to test and to check it routes to the right outputs. This script only supports a output through routing audio in channel 1 and 2. 

## Part 2 - Set up the script

1. Copy `PreShowAnnouncements.applescript` onto the QLab Mac, into `/Users/qlab/Scripts/`.
2. Open it in **Script Editor**.
3. Find the four file paths at the top. Replace each one with your own. Drag an audio file into the Script Editor window to get its exact path, then paste it between the quotes.
4. Under each path is a patch and a level. The patch is which QLab audio output the cue plays through, numbered as in *Workspace Settings > Audio*, so `1` is the first. Use `0` to leave a cue on the workspace default. The level is `{master, left, right}` in dB. Both can be set later if alterations need to be made.
5. Look at the schedule below the settings. It lists when each call plays, counted back from the show time. Feel free to change it to match your pre-show announcement timings.
6. Press **Command K** to compile.

It must compile with no errors before you go on. If it does not, the error will point at the line, and it is almost always a quote mark missing from a path.

## Part 3 - Test the script by hand

1. Open your QLab workspace. Make sure it is the main window.
2. Go back to Script Editor and press **Run**.
3. macOS will ask whether Script Editor may control QLab. Click **OK**. Miss this dialog and nothing works. See Part 9.
4. When it asks for a show time, enter one about **four minutes from now**.
5. You should get a summary dialog listing what it built.

Now check QLab. You should see a new cue list called `Temp-PreShow HH:MM` holding one audio cue per row of the schedule and a cleanup cue. Each is named with the time it fires.

6. Click one of the cues and open the **Triggers** tab. The **Wall Clock** box should be ticked, with the right time next to it.
7. Open the same cue's **Audio** tab. The output patch should be the one you set, and on the **Levels** tab the master, left and right faders should read what you set in the config. Anything that did not take is named in the summary dialog.
8. At show time or as configured, the list should delete itself.

If the wall clock boxes are not ticked, the summary dialog will have said so. Tick one by hand, then check the property name against QLab's dictionary, via *File > Open Dictionary* in Script Editor.

## Part 4 - Export the compiled script

QLab, the Login Item and Script Editor all load this one file. One copy means there is no second version to keep in step.

1. In Script Editor: **File > Export**
2. File Format: **Script**
3. Save as `/Users/qlab/Scripts/PreShow.scpt`

Edit the `.applescript` later and you must **export it again**, or QLab carries on running the old version.

## Part 5 - Add the control cues in QLab

These three cues stay in your show file. Companion drives the system through them.

Make a new cue list called `PRE-SHOW CONTROL`, then add three cues to it.

**1. Memo cue**
- Cue number: `PSTIME`
- Name: `SHOW TIME - not set`
- **Disarm it.** It is a label, not something to play.

**2. Script cue**
- Cue number: `PSBUILD`
- Name: `BUILD PRE-SHOW`
- Script:
  ```applescript
  set b to load script (POSIX file "/Users/qlab/Scripts/PreShow.scpt")
  tell b to buildFromQLabCue()
  ```

**3. Script cue**
- Cue number: `PSCLEAR`
- Name: `CANCEL PRE-SHOW`
- Script:
  ```applescript
  set b to load script (POSIX file "/Users/qlab/Scripts/PreShow.scpt")
  tell b to clearPreShow()
  ```

**4. Build succeeded cue**
- Cue number: `PSOK`
- Name: `BUILD OK`
- **Arm it.** Unlike `PSTIME`, this one plays.
- Any cue type you like: a short audio blip, a Light cue, or a Network cue back to Companion to turn a Stream Deck button green.

**5. Build failed cue**
- Cue number: `PSFAIL`
- Name: `BUILD FAILED`
- **Arm it.**
- Same idea, but for a failure. A red button or a different sound.

Leave **Run in separate process** ticked on both Script cues. That is QLab's default.

`PSTIME` holds the show time in its name. `PSBUILD` reads it and builds. `PSCLEAR` clears everything. `PSOK` and `PSFAIL` are started by the script to say how the build went.

A build counts as failed if nothing was built at all, if any cue's wall clock trigger would not enable, if any audio file was missing, or if the cleanup cue could not be made. All four leave a list that looks fine and does not work. If you do not want the feedback cues, set `kBuildOKCue` and `kBuildFailCue` to `""` in the script.

Both are stopped before either is started, when CANCEL is pressed, and by the cleanup cue at show time. So a cue that loops, or one that holds a light or a button colour on, will not run into the performance. That also means they are safe to build as looping cues if a steady indicator suits the control position better than a one-shot.

## Part 6 - Test the control cues

*Developer's note - Why am I still here, it's 4am on a Sunday night. Reading my own code and writing up how it works, this isn't fun. There may be a few mistakes...probably......you'll figure it out :-)*

1. Rename `PSTIME` to `SHOW TIME 19:30`, using a time a few minutes ahead.
2. GO `PSBUILD`. The temporary cue list should appear.
3. `PSOK` should have fired on its own straight after the build. If you built it as a looping or holding cue, GO `PSCLEAR` and check it stops.
4. GO `PSCLEAR`. The list should vanish, and `PSTIME` should go back to `SHOW TIME - not set`.
5. Rename `PSTIME` back to `SHOW TIME - not set` and GO `PSBUILD` again. Nothing should be built. `PSTIME`'s notes should read `BUILD REFUSED - no show time set`, QLab will flag an error on the Script cue, and `PSFAIL` should fire. **That is correct.**

If `PSBUILD` does nothing at all, check your QLab licence first, then Part 9.

## Part 7 - Set up the morning purge

**Do not skip this part.**

QLab autosaves, so a list built today is written to disk. If the show is cancelled, or QLab is quit before the cleanup cue runs, tomorrow's launch brings that list back **armed**, and it announces again at yesterday's times. The daily restart does not clear it. This does.

1. In Script Editor, open a new document and paste these two lines:
   ```applescript
   set b to load script (POSIX file "/Users/qlab/Scripts/PreShow.scpt")
   tell b to purgeOnLaunch()
   ```
2. **File > Export**, File Format: **Application**, saved as `/Users/qlab/Scripts/PreShow Purge.app`
3. **Run it once by hand now.** macOS will ask whether it may control QLab. Click OK. This approval cannot be given on an unattended restart, so it has to happen here.
4. **System Settings > General > Login Items**, then **+**, and add `PreShow Purge.app`.

It waits up to five minutes for QLab to open a workspace, so it does not matter whether it runs before or after QLab.

## Part 8 - Set up the Mac to run unattended

*Developer's Note - Lucky for me, our system already does all this with our existing qLab system...WOOOOOOOOOOOOOOOOOO*

Four things have to be true or the pre-show system will not survive a restart.

**1. The Mac logs in on its own.**
*System Settings > Users & Groups > Automatically log in as.*

**FileVault blocks this.** With FileVault on, the Mac stops at the unlock screen and nothing launches at all. Turn it off on a machine that has to start on its own, or accept that somebody unlocks it each morning.

**2. The workspace opens on its own.**
QLab has no reopen last workspace option, so add the workspace *file* to Login Items next to the purge app: *Login Items > + >* select your `.qlab5` file.

**3. The Mac never sleeps.**
Wall clock triggers do not fire while it is asleep. In Terminal:
```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 30
```

**4. The restart is scheduled.**
Skip this if an MDM already does it.
```bash
sudo pmset repeat restart MTWRFSU 04:00:00
```

Last, in QLab: *Workspace Settings > OSC* must have **OSC controls enabled**. Note the passcode if you set one. Companion needs both in Part 10.

## Part 9 - Check automation permissions

If things are skipped, might not work another time so check all of these. Ta.

- Script Editor controlling QLab (Part 3)
- QLab controlling QLab, meaning the Script cues (Part 6)
- PreShow Purge.app controlling QLab (Part 7)

Open *System Settings > Privacy & Security > Automation*. All three should be listed with QLab underneath, switched on.

**Renaming or moving `PreShow.scpt` or the purge app resets its permission.** Run them after any move.

## Part 10 - Set up Companion

Everything Companion talks to now works. Now we get to make the buttons! Yay!

### Step 1 - The connection

Add the **qlabfb** connection, pointed at the QLab Mac. Use `127.0.0.1` if Companion runs on the same machine. Add the OSC passcode if you set one in Part 8.

### Step 2 - The variables

*Variables tab > Custom Variables*. Create two:

- `showHour`
- `showMinute`

Set both to **not persist**. A Companion restart then leaves them blank, so nobody can build yesterday's time by accident.

### Step 3 - Page 10, PRE-SHOW

| Button | Actions |
|---|---|
| **NEW SHOW** | `internal: Set surface page` to 11 |
| **BUILD** | 1. qlabfb custom OSC to `/cue/PSTIME/name`, string arg `$(custom:showHour):$(custom:showMinute)`<br>2. `wait 250 ms`<br>3. qlabfb custom OSC to `/cue/PSBUILD/start` |
| **CANCEL** | qlabfb custom OSC to `/cue/PSCLEAR/start` |

The two OSC messages on BUILD must arrive in order: the name is set and then the build cue reads it. That is why there is a 250 ms wait.

Set NEW SHOW's button text to:
```
NEW SHOW
$(custom:showHour):$(custom:showMinute)
```
so the Stream Deck shows what time you have selected.

### Step 4 - Page 11, SELECT HOUR

Make 24 buttons, each is an hour so set the "showHour` = `"18"" to the hour number. Or however many buttons with the range you want. Idk, probably like 11 to 21?
Each does two things:
1. `internal: Custom Variable Set Value` to `showHour` = `"18"`
2. `internal: Set surface page` to 12

### Step 5 - Page 12, SELECT MINUTE

12 buttons, at five minute steps. Same as above. Each does two things:
1. `internal: Custom Variable Set Value` to `showMinute` = `"30"`
2. `internal: Set surface page` to 10

> **Pad the values.** Enter `"07"` and `"05"`, not `7` and `5`. Companion *can* pad with expressions but typing two characters rules out `19:5` faults, which are annoying af.

## Part 11 - Full dress test

It's just like a dress rehearsal! We love those....right? I'm getting delierious.

1. Restart the Mac. Do not touch anything. Check it logs in, QLab opens the workspace, and `PSTIME` reads `SHOW TIME - not set`.
2. Press **BUILD** without picking a time. Nothing should be built, `PSTIME`'s notes should read `BUILD REFUSED - no show time set`, and `PSFAIL` should fire.
3. Press **NEW SHOW**, pick an hour and minute about five minutes ahead, then press **BUILD**.
4. Check the new cue list. Check the trigger times, and that `PSTIME`'s notes read `Last build: 10 cues...`. `PSOK` should have fired, not `PSFAIL`.
5. Let the T-1 cue fire on its own. Listen to it in the house.
6. Press **CANCEL**. The list should disappear and `PSTIME` should reset.
7. If `PSOK` or `PSFAIL` holds rather than plays once, build again and let the cleanup cue run at show time. It should stop both before it deletes the list.
8. Build once more, then **quit QLab before the cleanup cue runs**, and restart the Mac. After login the purge should have removed the stale list.

Step 8 is the one that proves you are safe on a cancelled show. Do not skip it, or I'll steal your gaffa tape.

---

## Daily use

1. **NEW SHOW**, then hour, then minute
2. **BUILD**
3. Check the times on screen
4. Leave it. The announcements and the cleanup run themselves.

If the show time moves, pick the new time and press BUILD again. It deletes and rebuilds. That holds whether or not you have already built. BUILD is always safe to press twice.

---

## Troubleshooting

Hopefully these things help.

| Symptom | Likely cause |
|---|---|
| BUILD does nothing at all | Script cues need a QLab licence, or Automation permission is missing (Part 9) |
| `No cue numbered PSTIME was found` | Control cues missing, or the open workspace is not the one you set up |
| `BUILD REFUSED - no show time set` | No time picked on the Stream Deck. Working as intended |
| Cues built at the wrong time | Companion variables not padded. Check for `19:5` |
| Cues built but silent | File paths wrong. The summary lists missing files. Check a cue's Audio tab |
| Wall clock boxes not ticked | Reported in the summary. Tick by hand, and check the property name in QLab's dictionary |
| Nothing fires overnight | The Mac slept (Part 8.3), or the workspace was not open |
| Yesterday's list still present | Purge app not installed, or its permission was reset by moving it |
| Announcements fired on a dark day | Same as above. The purge is the only thing preventing this |
| `PSFAIL` fires but the list looks right | A missing audio file, a wall clock box that would not tick, or no cleanup cue. The summary and `PSTIME`'s notes say which |
| Neither `PSOK` nor `PSFAIL` fires | The cues are missing, disarmed, or their numbers do not match `kBuildOKCue` and `kBuildFailCue` |
| A feedback cue is still running during the show | The cleanup cue did not run, so nothing stopped it. Same cause as a list left behind |

---

## Configurable items

Everything you can change is at the top of `PreShowAnnouncements.applescript`. Edit it in Script Editor, compile with Command K, then export again as in Part 4.

| Code line | Section | What it is | Options |
|---|---|---|---|
| `kWelcomeFile` | Configuration | Audio file for the welcome message | Any full POSIX path in quotes |
| `kWelcomePatch` | Configuration | Audio output patch for the welcome cues | A patch number as listed in Workspace Settings > Audio. `0` leaves the workspace default |
| `kWelcomeLevel` | Configuration | Output level of the welcome cues | `{master, left, right}` in dB. `0` is unity, `+12` the maximum, `-120` silence |
| `kTenMinFile` | Configuration | Audio file for a 10 minute call. Spare, not in the schedule as shipped | Any full POSIX path in quotes |
| `kTenMinPatch` | Configuration | Audio output patch for the 10 minute call. Spare, as above | A patch number, or `0` for the workspace default |
| `kTenMinLevel` | Configuration | Output level of the 10 minute call. Spare, as above | `{master, left, right}` in dB, as above |
| `kFiveMinFile` | Configuration | Audio file for the 5 minute call | Any full POSIX path in quotes |
| `kFiveMinPatch` | Configuration | Audio output patch for the 5 minute call | A patch number, or `0` for the workspace default |
| `kFiveMinLevel` | Configuration | Output level of the 5 minute call | `{master, left, right}` in dB, as above |
| `kFinalCallFile` | Configuration | Audio file for the final call | Any full POSIX path in quotes |
| `kFinalCallPatch` | Configuration | Audio output patch for the final call cues | A patch number, or `0` for the workspace default |
| `kFinalCallLevel` | Configuration | Output level of the final call cues | `{master, left, right}` in dB, as above |
| `kNoTimeText` | Configuration | Name the control cue resets to when no time is set | Any text, as long as it contains nothing that reads as a time |
| `kShowTimeCueNumber` | Companion integration | Cue number of the control cue Companion writes the time into | Any cue number, or `""` to turn Companion control off |
| `kBuildOKCue` | Companion integration | Cue started when a build finishes clean | Any cue number, or `""` to skip the feedback |
| `kBuildFailCue` | Companion integration | Cue started when a build fails or is degraded | Any cue number, or `""` to skip the feedback |
| `kSilent` | Companion integration | Hides all dialogs. Set by the headless handlers, not by you | `true` or `false`. Leave at `false` |
| `kListPrefix` | Configuration | Name of the temporary cue list, before the show time | Any text |
| `kNumberPrefix` | Configuration | Prefix for the announcement cue numbers | Any text, or `""` to leave the cues unnumbered |
| `kWelcomeColour` | Configuration | Colour of the welcome cues | A QLab colour name, or `"none"` |
| `kCallColour` | Configuration | Colour of the 10 and 5 minute call cues | A QLab colour name, or `"none"` |
| `kFinalColour` | Configuration | Colour of the final call cues | A QLab colour name, or `"none"` |
| `kAddMemoCue` | Configuration | Puts a memo at the top of the list showing the show time | `true` or `false` |
| `kAddCleanupCue` | Configuration | Adds the cue that clears the list at show time | `true` or `false`. Only turn off if you will delete the list by hand |
| `kCleanupOffsetMinutes` | Configuration | When the cleanup runs, in minutes before the show | Any whole number. `0` is show time, `-5` is five minutes after it |
| `kCleanupAction` | Configuration | What the cleanup does to the list | `"delete"` removes it, `"disarm"` keeps it and marks it `[DONE]` |
| `announcementSchedule()` | Schedule | The calls themselves, one row each | Rows of `{minutes before show, cue name, audio file, colour, level, patch}`. Add, remove or reorder freely |

Colour names must match the ones QLab offers in the cue inspector. `"none"` leaves a cue uncoloured. Options: red, orange, green, blue, purple and none

The patch and the levels are written to the cue on every build, so the config always wins. Levels go on after the patch, because changing either the file or the patch rebuilds a cue's level matrix.

Left and right are the crosspoints for a stereo file on default routing. A mono file has no right channel, so the summary will report that one as failed and you can ignore it. A patch that will not set leaves the cue on the workspace default, which is audible somewhere rather than silent, so that one is reported but does not fail the build.
