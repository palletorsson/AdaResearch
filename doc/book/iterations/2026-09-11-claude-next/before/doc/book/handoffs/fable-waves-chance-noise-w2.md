# Handoff — Waves, Randomness and Noise, batch W2: WaveFunctions_Effect_Sound (Fable 5.1, 2026-09-10)

Status: **implemented and source-checked — runtime probe written, ported and parsed, NOT run (a Godot editor, PID 40320, and its play instance of `endless_museum.tscn` held the project); awaiting Godot, Astra's review, a headset walk and a listener.** Nothing committed.

Read first: `doc/book/handoffs/fable-wcn-runtime-followup.md` (item 5, the brief), `doc/research/waves-chance-noise/maps/WaveFunctions_Effect_Sound.md` (the card), `ada_run/waves_chance_noise/2026-09-10-w2-batch.md` (the handback), `ada_run/waves_chance_noise/WaveFunctions_Effect_Sound/report.md`, `commons/maps/WaveFunctions_Effect_Sound/field_notes.md` (the ruling and the rejected ideas).

## What was built

- `DualBallFMController.gd`: `stand` axis (`desks`), AUDITION panel (BASELINE / HOLD / PLAY / COMPARE), cased readout with a `differs:` line and the synthesis milliseconds, change-gated refresh, `drag_note_cap` (ships at 0), player reach 18 m under the staging, `render_samples()` / `get_audition_state()`.
- Map: the primary to (8,11) as `DualBallFMController:180#stand:desks#evidence:longhand`; rects [[6,9,11,13]]; `artifact_placement: map`; description rewritten. Structure, utilities and every other placement untouched.
- Init order: `MelodyChaser3D` and `UniversalVRAudioController` keep a config that arrives before `_ready` and apply it once ready.
- Texts: final (the four points of the brief), blurb, intent, summary, critical, technical, tutorial reconciled to the real hall; field_notes.md.
- `commons/testing/probe_wcn_effect_sound.gd` + live port; runner name `effect`.

## Pick up here

1. When Godot is free: `bash tools/run_wcn_probe.sh effect`, then `bash tools/run_wcn_probe.sh effect live`; read the JSON (`checks`, `failures`, `measurements.synth_ms_index4`, `drag_test`, `players_playing_within_5m`, `audio_controllers`, `melody_chaser`, `streaming`, `desktop_input`) and the five captures; fix observed problems locally; fold the numbers into the report, the field notes and the W2 handback; decide `drag_note_cap` from the synthesis time.
2. Also queued: `for n in pendulum sine noise random intro; do bash tools/run_wcn_probe.sh $n live; done` (the pendulum's corrected captures; the four refreshed under the current probe sources).
3. Astra: review the second runtime pass (`2026-09-10-w1-batch.md`, second runtime pass section) and W2.
4. Palle's calls: the primary's move to the quiet quarter; the desks' colliders (three sealed cells); the reconciled supporting texts; the pearl's blank DualBallFMController line and its hero (timbre_sculptor); what to commit.
5. Headset: the desks at 0.92 m, the balls at 1.0–1.4 m, the panel at 1.02 m, the readout at 1.46 m, the scope above; the racks' loudness on the audition floor by ear.

## Files

Changed: `algorithms/wavefunctions/mariocontrol/DualBallFMController.gd`, `algorithms/wavefunctions/mariocontrol/MelodyChaser3D.gd`, `commons/audio/UniversalVRAudioController.gd`, `commons/maps/WaveFunctions_Effect_Sound/{map_data.json, final.md, blurb.md, intent.md, summary.md, critical.md, technical.md, tutorial.md}`, `tools/port_wcn_probes_live.py`, `tools/run_wcn_probe.sh`. New: `commons/maps/WaveFunctions_Effect_Sound/field_notes.md`, `commons/testing/probe_wcn_effect_sound.gd`, `commons/testing/probe_wcn_effect_sound_live.gd`, `ada_run/waves_chance_noise/WaveFunctions_Effect_Sound/report.md`, `ada_run/waves_chance_noise/2026-09-10-w2-batch.md`, `doc/space/waves-chance-noise-w2-2026-09-10/` (before-copies, hashes, README).
