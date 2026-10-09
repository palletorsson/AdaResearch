# WaveFunctions_Pendulum — W1 report (Fable 5.1, 2026-09-10)

Status: **implemented — awaiting review**. Source pass complete; runtime probe written and NOT RUN (Godot PID 2780 held the user:// lock); headset not walked.

## Question and experiment

Where does a movement put its past? One pendulum swings under a gallows frame; its position is sampled on a fixed-time policy and every sample is drawn behind the bob at a depth proportional to its age. The visitor counts marks between two same-side crossings, compares the count with the plate's period ÷ interval, switches the sampler (FINE 25 ms / COARSE 200 ms / STROBE once per measured period) and reads which of the record's two limits (300 marks, 10 s) is binding.

## Before / after

Before: `PendulumWave:90` at (1,7) against the west wall; its trail (frame-based sampling, 300 samples, 2 m/s) receded INTO the wall after 0.5 m and its length depended on frame rate (10 m at 60 fps, 6.7 m at 90). No readout, no control, no count.

After: `PendulumWave:180` at (6,11), the head of the open south half; the record recedes 4.5 m (FINE) or 6 m (COARSE) toward the exit along a lane the visitor walks beside; a cased readout 3 m down the trail; a four-button panel on the east post; the seismograph moved beside the trail (2,13); GlassRack moved out of the lane (10,12). Structure and utilities unchanged. `museum.artifact_placement: "map"` added.

## Design decision

Two limits on the record (count AND age), so the two sampling policies run into different rules and the readout shows which. The strobe as a third policy: sampled at its own measured period the record of a moving bob stands still.

## Departures from the card

None in question or comparison. The card offered "a bounded fixed-time sampler independent of render frequency" — taken. The card's "compare two sampling intervals" — taken, plus the strobe. The frame-based policy was not kept as an option (it would make the counts frame-rate dependent, which the readout could not print honestly).

## Primary tokens, configs, anchors

Primary: `PendulumWave:180` (no `#` keys; `sampler` is a word-valued config for other placements). Book anchor: `<!-- @PendulumWave -->`; hero moved WavePaintings → PendulumWave in `commons/data/book/wavefunctions.json`. Roles unchanged (PendulumWave primary).

## Code excerpts in final.md

- append/evict block (9 lines): `algorithms/wavefunctions/oscillation_driver/PendulumWave.gd`, `_physics_process`, verbatim.
- depth line: same file, `_draw_trail`, verbatim.
Source SHA256 (after, CRLF): see `_baseline_w1`-relative manifest in the batch report.

## Files changed

`algorithms/wavefunctions/oscillation_driver/PendulumWave.gd` (rewrite); `commons/maps/WaveFunctions_Pendulum/{map_data.json, final.md, intent.md, blurb.md, summary.md, tutorial.md, technical.md, critical.md, field_notes.md (new)}`; `commons/data/book/wavefunctions.json` (PendulumWave line + hero); `commons/testing/probe_wcn_pendulum.gd` (new). Before-copies: `doc/space/waves-chance-noise-w1-2026-09-10/before/`.

## Evidence (source only)

| check | result |
|---|---|
| gdparse PendulumWave.gd, probe | parses |
| pathfinder | OK 209/273 (unchanged) |
| check_map_tokens | OK |
| check_wave_platform_recovery (persistent) | passes, 12 maps / 193 platforms / 137 walls, route unchanged |
| final excerpts verbatim | 10/10 lines |
| tutorial/technical excerpts (PendulumWave) | all lines verbatim; the seismograph/Foucault/double-pendulum sketches are labelled as sketches |
| final length | 780 prose words + 2 excerpts |
| /api/compose-docs serves the new final | see batch report |
| runtime probe | written, not run |
| headset | no |

Control path planned in the probe: `button_pressed` emitted programmatically on the panel's push buttons; no tracked hand. Invariants the probe asserts: ~120 marks after 3 s; 300 marks / 7.5 s / 4.5 m at 9 s (count binds); ~50 marks / 10 s / 6 m under COARSE (age binds); period 2.7–3.2 s measured; marks-per-swing ≈ period/interval; strobe 3–4 marks with x-spread < 0.12 m; RESET zeroes clock and list and keeps the sampler; record recedes south; readout text; swing and lane clear of collision; three capsule routes.

## Unverified

Everything runtime: the readout's legibility at 1.45 m, the panel's reach, the bob at 0.9 m, the record's direction, the numbers above. The seismograph's facing after the move. Known unrelated red: `final_tags --check` reports four stale tags in other maps.
