# Handoff — Waves, Randomness and Noise, batch W4: WaveFunctions_Synthesis_Lab (Fable 5.1, 2026-09-11)

Status: **implemented and run in both lanes on desktop — bare 84 / 0, live 93 / 0, no script errors, eight views (one, the plan, informational), the sliders through their real move path and the desktop rig's pointer dragging one and pressing the panel; handback `ada_run/waves_chance_noise/2026-09-11-w4-batch.md` — awaiting Astra's acceptance, a person at the bench and a headset walk.** Nothing committed.

Read first: `doc/research/waves-chance-noise/maps/WaveFunctions_Synthesis_Lab.md` (the card), the handback, `ada_run/waves_chance_noise/WaveFunctions_Synthesis_Lab/report.md`, `commons/maps/WaveFunctions_Synthesis_Lab/field_notes.md` (the ruling, the map decisions, the runtime findings, the rejected ideas).

## What was built

- `additive_wave_demo.gd`: a `stand` axis (`bench`): the display lifted 1.75 m onto a backboard with every ladder row above a bench-top sight line, a 2.90 × 0.50 m bench with a collider, the shipped console at its right end, a SUM panel (BASELINE · H1 ALONE · HOLD) wired to the same coefficient path the sliders use, a five-line readout printing the display's own arithmetic at a marker, ribbons instead of line strips; `restore_baseline()`, `first_alone()`, `set_held()`, `display_values(i)`, `get_synthesis_state()`. `none` is the shipped behaviour.
- Map: the primary (2,6) → (4,2) as `additive_wave_demo:0#stand:bench#waveform:sawtooth`; lissajous, seismograph, record_room, GlassRack moved off the bench's span and the door route; `artifact_placement: map`; four clear rects; `props_deny: ["bench"]`. Texts reconciled; final.md in the discovery voice with excerpts verified against the source.
- `commons/testing/probe_wcn_synthesis_lab.gd` + live port; runner name `synth`; the desktop driver gained `press_down`, `release`, `drag`, `ray_report`, `inspect_control`, and an aim iterated on the camera's own forward (the press that failed was a rig pushed out of a platform's overlap after aiming — stand a rig clear of colliders).

## Pick up here

1. Astra: the room and its texts; the draw-path refactor (`_emit_strip`) in a shipped artifact — identical output by construction, not measured in the ten other placements; the pearl's hero (`oscilloscope`) against the primary.
2. A person: take the four lower sliders down, hold, read the plate at the mark, then BASELINE; the sight line at their own height.
3. Palle's calls: the bench staging; the four secondary moves; `coloredlines` beside the console; the three wall-top instruments; what to commit.
4. Museum findings for whoever owns it: the door widener + bench placer + an artifact on the converted flank plug a one-cell gap; the dealer puts dream bodies on door cells and one-cell corridors unless rects say otherwise; the Rect2 far edge excludes a plinth centred on it.
5. The next hall on the thread: Random_Definition already holds the repeatability this room hands over; the remaining Waves halls are extensions.

## Files

Changed: `commons/artifacts/additive_wave_demo/additive_wave_demo.gd`, `commons/maps/WaveFunctions_Synthesis_Lab/{map_data.json, final.md, blurb.md, intent.md, summary.md, critical.md, technical.md, tutorial.md}`, `commons/testing/wcn_desktop_driver.gd`, `tools/port_wcn_probes_live.py`, `tools/run_wcn_probe.sh`, `tools/check_wcn_w1_source_review.py`. New: `commons/maps/WaveFunctions_Synthesis_Lab/field_notes.md`, `commons/testing/probe_wcn_synthesis_lab.gd`, `commons/testing/probe_wcn_synthesis_lab_live.gd`, `ada_run/waves_chance_noise/WaveFunctions_Synthesis_Lab/report.md`, `ada_run/waves_chance_noise/2026-09-11-w4-batch.md`, `doc/space/waves-chance-noise-w4-2026-09-11/` (before-copies, hashes, README).
