# Array Tutorial — assessment of received feedback

Received 2026-09-18 in [01-review.md](01-review.md). The user saved the response directly; its bytes were preserved. This file records targeted checks and editorial judgment, not acceptance of every proposal. No manuscript, map, artifact or package was changed in this pass.

## What the review adds

The useful reading is slot/value persistence across changed media: a disappeared cube, a reachable empty address, a rule evaluated across positions, and an inactive step still visited by a clock. Floor and Walls deliberately hold the rules constant while changing their bodily use. Preserve those returns.

The reader-experience section improves on earlier reviews by locating specific moments when prediction and perception can precede explanation. Treat that as a flexible rhythm. Clear names and controls can support beginner discovery; they need not always be hidden.

## Checked findings and proposed actions

| Finding | Evidence / qualification | Decision or next action |
|---|---|---|
| 3D enclosure says FLY INTO THE THIRD INDEX | Confirmed in array_flight_lab.gd. Whether this prematurely answers the discovery question is a teaching hypothesis. The displayed address is [x,y,z], with Y second, while storage is values[y][z][x]. An added dimension is not intrinsically a particular ordinal slot. | Consider FLY TO AN ADDRESS for clarity and invitation. Preserve explicit flight controls. Do not describe naming as inherently bad or add a reveal control by default. |
| Museum skin competes with monochrome studies | Inspected packaged Tutorial_Tiling_Floor-inside.png: prominent pink wireframes and striped interference overlap the studies. This also matches the existing RESUME.md work record. | Prioritize local neutral material/visual hierarchy and investigate floor overlap before rewriting prose. Capture again afterward. This is known unfinished staging, not a new verified root cause. |
| Activating a cell previews its sound | Confirmed in step_sequencer.gd::_on_cell_toggled: active invokes _play_sound(track). Current final.md explains the preview immediately. | The proposed listen-first passage is a useful small editorial candidate: hear activation, then playback, then distinguish writing state from clocked reading. Not applied. |
| Snare label can accompany an M1 piano | Confirmed: 90s_house loads KORG_M1_PIANO in the second track; sequencer_ui.gd hard-codes Kick/Snare/HiHat/Bass, and set_sound_preset changes only the preset selection. | Prefer preset-aware readable instrument names where known, with neutral fallback for unknown sounds. Musical identity can enrich this encounter; generic numbering is not automatically preferable. Source discrepancy confirmed; no audio run performed. |
| Pickup, binary table and XR flight provider omitted | All three implementation filenames are absent from the ZIP. Pickup/table references and two-hop export limit prevent a full interaction audit. | Extend future packages with critical interaction dependencies. Missing evidence does not itself contradict the manuscript. |
| Tiling names visible from entry | The question can direct looking before reading even when labels are available. | Do not add a NAMES button without evidence that it improves the encounter. Clear operation remains a priority. |

The checked array_flight_lab.gd, step_sequencer.gd and sequencer_ui.gd files match their frozen snapshots and the current working copy. These are targeted checks, not a comprehensive re-audit. The review's other detailed claims remain external findings until separately checked.

## Runtime and evidence limits

Existing tests and captures are in the original package's evidence folder and `doc/space/regularity-split-2026-09-17`. The Array report includes an earlier gridagent-recognition failure; RESUME.md records that the probe was corrected but needed rerunning. Preserve that distinction. No Godot or headset test was run while filing this feedback.

Still test visual separation of the six fields, pickup/table update, flight entry/exit, audio preview versus playback, independent clocks, and 16-step/12-column flashes. The last flash can be obscured by a later floor update, so a successful signal connection alone does not prove a readable experiment.

## Preservation

Keep row versus grid address persistence, Floor versus Walls, ONE EXCEPTION's open meaning, the return from absence to silence, and the two-clock distinction. The central question is what the representation records, and what other existence its values leave uncounted.

## Local follow-up — 19 September

The author's instruction to continue led to three parallel local audits and targeted repairs. See [findings and decisions](../../../iterations/2026-09-19-arrays-review/SUMMARY.md) and [paired images and text changes](../../../iterations/2026-09-19-review-comparison/index.html#arrays).

- **Preserve all five final chapters.** The current writing already supports contact collection, the distinction between addressing and flight, floor/wall returns, inactive steps and independent clocks.
- **Flight invitation clarified:** REACH AN ADDRESS and SELECT AN ADDRESS replace the two ordinal/dimensional headlines. Controls remain explicit. Rendered inspection also exposed addresses drawn through the opaque instruction board; lab-local depth and label-height corrections remove that obstruction without changing the shared grid or flight provider.
- **Floor interference repaired:** automatic grounding had cancelled the intended picture-plane lift. Explicit zero-height map placement preserves 2.5 cm separation from the unchanged collision floor. Floor and Walls use their existing local material override mechanism to quiet magenta edges and emission. Capture-mode height tint remains active and documented.
- **Disco labels repaired:** the house preset now names its Korg M1 Piano instead of Snare; other rows follow actual resolved sounds across seventeen presets. Unknown names get Track N. The chapter, sound presets, stored grid and physical screen remain intact.
- **Fresh bounded evidence:** 24/24 opening checks, 15/15 each surface hall, 20 surface evidence assertions, 10/10 label checks and 17/17 existing Disco encounter checks. Same-view captures are supplied with their scope. No headset, human listening or complete route claim follows.
- **Package gaps remain evidence tasks:** pickup, binary-table and flight-provider source files exist and were inspected locally. Include them when recapturing Arrays. Do not cut supported prose because the earlier ZIP omitted those files.

The next spine review is Color, followed by the later Tiling return. Remaining Arrays tasks are human reach/flight/readability checks and investigation of the existing secondary copy agent, not a uniform rewrite. Original reviewer wording and the frozen review package remain unchanged.
