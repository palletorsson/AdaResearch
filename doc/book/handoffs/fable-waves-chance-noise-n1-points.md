# N1 — Random_Noise_Types: the sampling bench (Fable, 12 September 2026)

The first hall of Astra's noise arc, developed in the same pattern as the six randomness halls before it. Astra's card asked for matched-volume clouds from explicit seeds; requested, accepted and refused counts shown; no secret reduction of the spacing to reach the requested population; a player able to bring two accepted points closer together, so that a constraint at birth can be told from ongoing enforcement, with an easy restore; and the audio-noise galleries either separated or given a corrected context.

## What was there

`randompoints`: three distributions (uniform, gaussian, and dart-thrown minimum distance, which the code calls BLUE_NOISE), thirty points in a one-metre cube, `randomize()` and the global stream, `apply_grid_config` empty so no token could reach anything, and — the part that mattered — the dart thrower silently dropping every point it could not place. The packing limit was real and invisible.

## What it is now

An opt-in `stand:compare` bench in the room's open east half, at (10,3), turned to face the north door:

- **Two slabs, matched and drawn as frames.** 0.9 × 0.9 × 0.12 m each, side by side, twelve edges apiece so "the same volume" is visible rather than asserted; the probe measures both frames.
- **One seed, two rules.** Twenty-four points per slab from one named five-digit seed. Left: every candidate the uniform draw proposes. Right: the shipped dart thrower, keeping only what the minimum-distance rule admits.
- **The refusals stay.** Thirty-nine refusals for twenty-four places, in sixty-three draws, drawn as grey ghosts where they fell. There are more refusals than points, and that is the price of the even slab.
- **The excluded neighbourhood is drawn at half the distance,** which is the exact geometry: shells of radius d/2 around centres no closer than d can touch and never overlap. Overlapping shells on the left are what having no rule looks like.
- **The readout** names the seed, the population, the volume and the rule, then both columns: kept, refused, draws taken, closest surviving pair.
- **The rule's distance is derived from the density** — 0.8 × the mean spacing the requested count implies — because `#dist:0.13` is unusable (the grid reads `#key:number` as a rotation unless the key is in `CONFIG_PARAM_NAMES`; `radius` is, and overrides).
- **REDRAW · NEW SEED · RULE · RESTORE** at hand height on the bench's front.

## The two things Astra asked to be proved

**The shortfall is reported, not papered over.** The probe asks for four times the population: 45 of 96 placed, 51 unplaceable, 220 refused, and the closest pair still at the rule. The plate says `51 could not be placed at all: the volume ran out of room`. Nothing relaxes the distance to make the number.

**The rule is a condition of admission and not a force.** The points are the project's pickable spheres. In the live lane the desktop pointer's own grab ray finds one at 1.16 m, the right button carries it, and the carry alone brings the gap to 0.03 m against a 0.13 m rule. Both shells turn red, the readout says `moved 1 · under the distance 1 — the rule was applied at birth, not since`, and nothing pushes anything back. A second right-button press puts the point down (the pointer's right button is a toggle, not a hold), and RESTORE — pressed through the pointer — returns every point to its generated position.

## Evidence

| lane | result |
|---|---|
| bare (`run_wcn_probe.sh points`) | 44 checks, 0 failures |
| live (`run_wcn_probe.sh points live`) | 52 checks, 0 failures, exit 0 |

Captures: the standing view of the bench, both slabs together, each slab alone, the over-asked slab at its packing limit, the readout, a point pushed inside a neighbour's shell, the rig's own carry, and the hall in plan.

## Map changes

- `randompoints` from (2,4) to (10,3) as `randompoints:180#stand:compare#count:24#size:0.9`. It had stood on a platform in the gallery row; the bench needs its own space and the galleries need distance from it.
- `museum.artifact_placement: "map"` and `sculpture_clear_rects [[9,2,12,6]]`.
- Nothing else. `WhiteNoiseGallery`, `NoiseColors3D` and the single `randompoint` keep their cells, and the probe measures the four to six metres between them and the bench.

## Not done, said plainly

- No headset walk, and nobody has carried a point with their own hand rather than the desktop pointer's.
- The galleries' own internal claims are untouched. Only their relation to the bench is addressed, in the final's closing and by the distance between them.
- Astra's review of this room.
- Three faults cost a run each and are worth passing on: the bench's front faces the map's −z under the token's 180, so the first live run stood the rig behind it and every press found nothing; the button's own area is a 4 cm sphere after the rack's 0.55 and the panel's 1.4 scaling, so a press aimed from 1.2 m misses and the rig now walks to arm's length; and the pointer's right button is a toggle, so a mouse-up drops nothing and the point stayed in the rig's hand through the restore.

## Files

`algorithms/randomness/randompoints/randompoints.gd`, `commons/maps/Random_Noise_Types/map_data.json`, `commons/maps/Random_Noise_Types/{final,summary,technical,tutorial,blurb,field_notes}.md`, `commons/testing/probe_wcn_points.gd` and its live port, `tools/run_wcn_probe.sh` and `tools/port_wcn_probes_live.py` (the `points` case), `tools/build_wcn_captures_page.py` (N1's views), and the captures page rebuilt and published. Forum: 260912-qbcmy.
