# Handoff — Waves, Randomness and Noise, batch W2: WaveFunctions_Effect_Sound (Fable 5.1, 2026-09-10)

**Next assignment from Astra, 11 September:** [W2 completion](fable-wcn-w2-completion.md). Read that brief with the [revised book voice](fable-final-discovery-voice.md). The dated incoming handoff below is preserved; completed book hero/line changes and earlier sequencing instructions are superseded.

Status (2026-09-11): **complete on desktop — bare 89 / 0, live 94 / 0, no script errors, five views, three rendered notes; completion report `ada_run/waves_chance_noise/2026-09-11-w2-completion.md` — awaiting Astra's acceptance, a listener and a headset walk.** Nothing committed.

Read first: `doc/book/handoffs/fable-wcn-runtime-followup.md` (item 5, the brief), `doc/research/waves-chance-noise/maps/WaveFunctions_Effect_Sound.md` (the card), `ada_run/waves_chance_noise/2026-09-10-w2-batch.md` (the handback), `ada_run/waves_chance_noise/WaveFunctions_Effect_Sound/report.md`, `commons/maps/WaveFunctions_Effect_Sound/field_notes.md` (the ruling and the rejected ideas).

## What was built

- `DualBallFMController.gd`: `stand` axis (`desks`), AUDITION panel (BASELINE / HOLD / PLAY / COMPARE), cased readout with a `differs:` line and the synthesis milliseconds, change-gated refresh, `drag_note_cap` (ships at 0), player reach 18 m under the staging, `render_samples()` / `get_audition_state()`.
- Map: the primary to (8,11) as `DualBallFMController:180#stand:desks#evidence:longhand`; rects [[6,9,11,13]]; `artifact_placement: map`; description rewritten. Structure, utilities and every other placement untouched.
- Init order: `MelodyChaser3D` and `UniversalVRAudioController` keep a config that arrives before `_ready` and apply it once ready.
- Texts: final (the four points of the brief), blurb, intent, summary, critical, technical, tutorial reconciled to the real hall; field_notes.md.
- `commons/testing/probe_wcn_effect_sound.gd` + live port; runner name `effect`.

## Pick up here

1. Done 2026-09-11 07:35–07:52: both Effect Sound lanes, the pendulum's corrected view, the four refreshes — see the completion report. `drag_note_cap` stays 0.
2. A listener: `ada_run/waves_chance_noise/WaveFunctions_Effect_Sound/audio_{A_baseline_unmodulated,B_index4_moddecay0.5,B_index4_moddecay1.5}.wav`.
3. Astra: review the second runtime pass (`2026-09-10-w1-batch.md`, second runtime pass section) and W2.
4. Palle's calls: the primary's move to the quiet quarter; the desks' colliders (three sealed cells); the reconciled supporting texts; the pearl's blank DualBallFMController line and its hero (timbre_sculptor); what to commit.
5. Headset: the desks at 0.92 m, the balls at 1.0–1.4 m, the panel at 1.02 m, the readout at 1.46 m, the scope above; the racks' loudness on the audition floor by ear.

## Files

Changed: `algorithms/wavefunctions/mariocontrol/DualBallFMController.gd`, `algorithms/wavefunctions/mariocontrol/MelodyChaser3D.gd`, `commons/audio/UniversalVRAudioController.gd`, `commons/maps/WaveFunctions_Effect_Sound/{map_data.json, final.md, blurb.md, intent.md, summary.md, critical.md, technical.md, tutorial.md}`, `tools/port_wcn_probes_live.py`, `tools/run_wcn_probe.sh`. New: `commons/maps/WaveFunctions_Effect_Sound/field_notes.md`, `commons/testing/probe_wcn_effect_sound.gd`, `commons/testing/probe_wcn_effect_sound_live.gd`, `ada_run/waves_chance_noise/WaveFunctions_Effect_Sound/report.md`, `ada_run/waves_chance_noise/2026-09-10-w2-batch.md`, `doc/space/waves-chance-noise-w2-2026-09-10/` (before-copies, hashes, README).
