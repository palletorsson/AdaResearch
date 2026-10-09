# WaveFunctions_Sine_Space — W1 report (Fable 5.1, 2026-09-10)

Status: **implemented — awaiting review**. Source pass complete; runtime probe written and NOT RUN (Godot PID 2780 held the user:// lock); headset not walked.

## Question and experiment

What kinds of passage can a repeating rule make? Two facing sine walls along the antechamber; one slider for their shared amplitude, one for the phase offset between them; FREEZE to separate "the crest came to me" (phase) from "I went to the crest" (position); RESET to the declared values. Exact readings at the slider's ends: offset 0 → the walls agree, the gap breathes ~1.45–2.55 m; offset π → every sine flips sign, the gap is 2.00 m everywhere (a snake). The walls do not collide; a hand through a crest proves it.

## Before / after

Before: `sine_wall_corridor:90` at (7,3), across rows 2–4 including the doorway's cell: a visitor entering at (7,1) met the north wall face-on and walked through it; walls of unequal frequency and amplitude (1.6×, 0.5×), animation 0.05 rad/s (a crest every 126 s, invisible), no control, no readout; the final ended at a unit-circle room not on the route.

After: `sine_wall_corridor:90` at (6,4): an 8 m passage from x 2.5 to 10.5 across rows 3–5, entered at the west mouth from the door's row and leaving at the east mouth onto the bridge head; the direct route untouched; equal walls; 0.35 rad/s; entrance panel (AMP, PHASE, FREEZE, RESET) and readout with the gap range; the two explanation cases moved to the antechamber's corners; the basin bodies untouched. `museum.artifact_placement: "map"` added.

## Design decision

"Animated visible surfaces around a stable walk": the walls stay collision-free (as the placed scene already had them) and the final says so; the museum treats a wide body with no collider as a venue and seals nothing. Equal walls so PHASE is one variable with two exact readings.

## Departures from the card

The card's third option, static collidable states, was designed (a two-row trimesh per wall) and set aside: any collider seals the corridor's whole footprint in the museum's walk map, which severs the antechamber; on the bridge it would seal the bridge. Recorded in field_notes.md. `cut: ribs` was not used for the placement (skin is the bodily encounter; ribs remains a config option).

## Primary tokens, configs, anchors

Primary: `sine_wall_corridor:90` (the panel is enabled by the scene's `panel = "entrance"`; `#panel:none` would remove it). Secondary: `sine_wall_explanation:90:-.4` (1,2), `sine_space_explanation:-90:-0.2` (11,2), `sine_space`, `colorballs` ×3, `dark_sphere` in the basin. Book anchor `<!-- @sine_wall_corridor -->`; hero moved sine_space_explanation → sine_wall_corridor. Roles unchanged.

## Code excerpts in final.md

- the layer line of `_wave_displacement`: `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd`, verbatim.
- the placement line of `_create_wall_mesh` (`x_pos = base_x - side * displacement`), verbatim.

## Files changed

`algorithms/wavefunctions/sine_wall/SineWallCorridor.gd` (additive: panel, readout, controls, accessors, chrome strip, floor lift), `algorithms/wavefunctions/sine_wall/sine_wall_corridor.tscn` (rows 8, equal walls, 0.35 rad/s, panel entrance); `commons/maps/WaveFunctions_Sine_Space/{map_data.json, final.md, intent.md, blurb.md, summary.md, tutorial.md, technical.md, critical.md, field_notes.md (new)}`; `commons/data/book/wavefunctions.json` (sine_wall_corridor line + hero); `commons/testing/probe_wcn_sine_space.gd` (new). Before-copies: `doc/space/waves-chance-noise-w1-2026-09-10/before/`.

## Evidence (source only)

| check | result |
|---|---|
| gdparse SineWallCorridor.gd, probe | parses |
| check_dna_declarations (sine_wall_corridor.cut) | ok |
| pathfinder | OK 116/258 (unchanged) |
| check_map_tokens | OK |
| check_wave_platform_recovery (persistent) | passes; route unchanged |
| final excerpts verbatim | 2/2 lines |
| tutorial excerpts | 8 blocks, all verbatim |
| gap arithmetic (Python model of the three layers) | offset 0: 1.43–1.46 / 2.54–2.57 m over a phase cycle; offset π: 2.000 everywhere; AMP max: 0.72–0.78 m |
| final length | 678 prose words + 2 excerpts |
| runtime probe | written, not run |
| headset | no |

Control path planned in the probe: `slider_moved` and `button_pressed` emitted programmatically on the panel's own controls; no tracked hand. Invariants asserted: placement at (6,4) and the cases' corners; the passage runs along world +x with mouths at x 2.5/10.5 inside rows 3–5; no collision shape; panel at hand height beside the west mouth; PHASE = π gives gap 2.00 everywhere and d_right = −d_left at three z; PHASE = 0 breathes with lo < 1.5, hi > 2.5, lo + hi ≈ 4; AMP max leaves > 0.55 m; FREEZE holds the phase, RESET restores values and handles; five capsule routes and a walk through both walls; two captures.

## Unverified

Everything runtime: the plush walls' legibility with 8 rows, the panel's reach and facing, the readout, the explanation cases' facing (rotation guessed), the museum's treatment of the corridor as a venue (nothing sealed). Known unrelated red: `final_tags --check` reports four stale tags in other maps.
