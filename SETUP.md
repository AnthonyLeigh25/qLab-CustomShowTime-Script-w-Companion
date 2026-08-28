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
