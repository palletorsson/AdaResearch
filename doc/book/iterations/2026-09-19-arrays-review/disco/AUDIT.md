# Tutorial_Disco: name the sound that actually occupies the track

The chapter already makes a strong return to the earlier array lesson: an address remains when a cube disappears or a note is switched off. It then separates the stored pattern, the clock reading it, the floor's own animation, and the visitor's movement. Keep this progression and the sixteen-step/twelve-column comparison. No edit to `final.md` is needed for the confirmed label defect.

## Confirmed defect and repair

The map configures `90s_house`. Its second track resolves to `KORG_M1_PIANO`, but the UI called it **Snare** in every preset. This is a misleading artifact label, rather than a missing explanation in the manuscript.

| Row | Before | After, with the same 90s_house preset |
| --- | --- | --- |
| 1 | Kick | TR-909 Kick |
| 2 | Snare | Korg M1 Piano |
| 3 | HiHat | Acid 606 Hi-Hat |
| 4 | Bass | TB-303 Acid Bass |

`StepSequencer._sync_sound_ui()` now passes readable names from the existing audio catalog for the actual resolved sound types. It runs after startup connection and after preset changes. Sounds without a catalog display name receive **Track N**; they do not inherit an instrument identity from another preset. Unknown presets retain the existing audio fallback kit and display the names of that kit. Neither the presets nor their synthesis has changed.

The label column is wider, using spare space inside the same 800 × 300 screen. Grid buttons retain their dimensions, number and stored state. The playhead indicators remain aligned with the columns. The physical screen, room, placement and book text are unchanged.

## Paired captures

Both are direct captures of the real packed sequencer scene's screen in Godot 4.6, with the same preset and cell selected. They are **artifact screen captures**, not museum views or headset photographs.

Before:

![Before: fixed Snare label under the house preset](before-house-panel.png)

After:

![After: Korg M1 Piano labels the second track](verified-house-panel.png)

## Verification

- `verified-checks.json`: **10/10 checks**. Covers all seventeen model presets, the actual selector signal updating the model and labels, known-name and neutral fallbacks, no sound preview caused by preset changes, preserved cell/address, and generation of the labelled piano's audio stream.
- `encounter-checks.json`: **17/17 existing encounter checks**. The note and highlighted address agree; inactive cells remain silent; last-step wrapping works; two halls bind to their own sequencers; floor animation can continue independently; steps zero and twelve map to the same floor column.
- `before-checks.json` reproduces five label failures. Its sixth failure was a probe setup mistake: selecting the initial cell intentionally auditions it. The first post-fix run (`after-checks.json`) leaves only that setup failure. The verified probe explicitly clears that initial preview before testing later preset changes. All three reports are retained.
- Before snapshots, SHA-256 manifests, exact source diff and per-run command/log records are adjacent. `final.md`, `map_data.json` and the existing encounter probe are byte-for-byte unchanged.

The runs use real scenes, UI signals, resolved sound types and generated streams, with a dummy audio driver. They do not establish listening quality, pointer reach, headset readability or learner understanding. Logs retain the project's known missing UID/certificate warnings, viewport initialization messages and exit object-leak warning. The screen images rendered successfully; this is not a claim that the entire application log is clean.

## Files changed

- `commons/audio/sequencer/step_sequencer.gd`: model-to-label synchronization.
- `commons/audio/sequencer/sequencer_ui.gd`: dynamic names, neutral fallback and space for readable labels.
- `tools/probes/disco_track_labels.gd`: focused runtime regression and repeatable same-screen capture.

No new manuscript prose, artifact quota, sequence reorder, room geometry or musical preset was introduced. Further chapter editing should respond to a reader or visitor difficulty, rather than to this repaired UI mismatch.
