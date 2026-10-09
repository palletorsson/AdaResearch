# Handoff — Waves, Randomness and Noise, batch W3: WaveFunctions_AirMusic (Fable 5.1, 2026-09-11)

Status: **implemented and run in both lanes on desktop — bare 52 / 0, live 55 / 0, no script errors, five views, the strike through the striker's own collision path; handback `ada_run/waves_chance_noise/2026-09-11-w3-batch.md` — awaiting Astra's acceptance, a person striking and listening, and a headset walk.** Nothing committed.

Read first: `doc/book/handoffs/fable-wcn-w2-completion.md` ("What comes next"), `doc/research/waves-chance-noise/maps/WaveFunctions_AirMusic.md` (the card), the handback, `ada_run/waves_chance_noise/WaveFunctions_AirMusic/report.md`, `commons/maps/WaveFunctions_AirMusic/field_notes.md` (the ruling, the six runtime findings, the rejected ideas).

## What was built

- `ResonatingMetallophone.gd`: `stand` axis (`table`: the deck at the origin, a cradle the striker returns to, labels on the front, locked bars 0.16 m apart, the readout housed and the sum backed, the striker's decorations hidden), the striker's speed handed to the bar, `get_active_voices()`, `strike_bar()`, `get_stick()`.
- `ResonatingBar.gd`: the striker by ancestry, a strike zone, one count per strike, the pick-up layer heard, the note 2.5 decays long and ending with the glow, a returning striker ignored. `CombinedWaveVisualizer.gd`: bars found recursively, a ribbon, a voices readout. `FMPianoSynth.gd`: worker tasks joined at exit.
- Map: `resonating_metallophone:0#stand:table` at (5,9); rects [[3,8,8,10]]; `artifact_placement: map`. Texts reconciled; final.md in the discovery voice.
- `commons/testing/probe_wcn_air_music.gd` + live port; runner name `air`.

## Pick up here

1. Astra: the four shipped-artifact repairs (the strike path, the note's end, the visualiser's bars, the synth's tasks) change every placement of those scripts — accept or narrow.
2. A person: strike, listen through the tail, then the pair; the plate and the ribbon are the readable part.
3. Palle's calls: the table staging, the wider spacing, the hidden striker decorations, the pearl's hero (`RackAmbientDrone`) against the primary, what to commit.
4. The next hall on the thread: the Synthesis Lab's additive sum, where the ribbon's sum becomes the subject.

## Files

Changed: `algorithms/wavefunctions/resonance/{ResonatingMetallophone.gd, ResonatingBar.gd, CombinedWaveVisualizer.gd}`, `commons/audio/systems/air_points/FMPianoSynth.gd`, `commons/maps/WaveFunctions_AirMusic/{map_data.json, final.md, blurb.md, intent.md, summary.md, critical.md, technical.md, tutorial.md}`, `tools/port_wcn_probes_live.py`, `tools/run_wcn_probe.sh`. New: `commons/maps/WaveFunctions_AirMusic/field_notes.md`, `commons/testing/probe_wcn_air_music.gd`, `commons/testing/probe_wcn_air_music_live.gd`, `ada_run/waves_chance_noise/WaveFunctions_AirMusic/report.md`, `ada_run/waves_chance_noise/2026-09-11-w3-batch.md`, `doc/space/waves-chance-noise-w3-2026-09-11/` (before-copies, hashes, README).
