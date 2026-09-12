# N2 — Noise_Columns: the trio (Fable, 12 September 2026)

Astra's card asked for a recognisable baseline column, one periodic deformation and one deliberately implemented coherent-noise deformation, sharing mesh, material, displacement range and viewing frame, with the driver revealed only after observation; local freeze; whole-column rotation separated from deformation; the marble shading inspectable on its own; bounded resolution and rebuild frequency with the frame cost measured; no load-bearing claim; and the erosion/entropy claims in the supporting docs corrected.

## What was there

`MeltingBerniniColumns.gd` built a ring of nine columns and rebuilt every one of them, in full, every frame. The melt was `sin(time * melt_speed + i)`. There was no field anywhere in the file, while the hall's own description promised 3D Perlin erosion and reversible entropy. `apply_grid_config` was empty.

Two faults in the placed scene made the rest impossible and are worth naming on their own:

- **The root was scriptless.** `MeltingBerniniScene.tscn` had a bare `Node3D` root with the script on a `BerniniColumns` child. The grid sets `config_*` metadata and calls `apply_grid_config` on the ROOT, so no map token could ever have configured this artifact. The probe's first run reported the body with `script: -`.
- **The scene carried a camera marked `current = true`.** Twelve maps place this scene, and each of them was putting a camera into the hall that takes the view.

The script now sits on the root with the child's exports carried over verbatim (the child was at identity, so those twelve placements build exactly what they built), and the camera is gone.

## What it is now

`#stand:trio` builds three columns on one bench, at (9,7), turned to face the hall's north door:

- **Identical in everything but the driver.** Same height, radius, mesh resolution (40 × 16, 697 vertices each), same material, same mapped displacement range, same frame.
- **The three drivers.** A fixed phase (the recognisable column), the shipped sine, and a real `FastNoiseLite` field seeded by the room — the first coherent field this file has contained. Both live drivers hand a phase in [0,1] to the same function, so the drop is 0.00–0.70 m for either.
- **Unnamed until asked.** The drivers are dealt to the three places from the room's seed and the plates read `?` until REVEAL.
- **FREEZE, SPIN, MARBLE.** Time stops; the columns turn without a vertex moving; the veining comes off and the same geometry is underneath.
- **Bounded and measured.** Twelve rebuilds a second, only for the two that move, none while frozen; about 3.5 ms a mesh, printed on the plate.

## Evidence

| lane | result |
|---|---|
| bare (`run_wcn_probe.sh columns`) | 37 checks, 0 failures |
| live (`run_wcn_probe.sh columns live`) | 42 checks, 0 failures, exit 0 |

The probe rebuilds a column at a named time twice and gets the same mesh to the vertex, and a different mesh at another time; turns the columns and gets the same checksum; takes the marble off and gets the same checksum. Over forty-eight seconds of the artifact's own driver function, the periodic column's returns are spaced within 0.05 s of each other and the field column's vary by 1.9 s — which is the room's actual answer: a shape carries no mark of what produced it, and only the history separates a clock from a field. In the live lane all four controls are pressed through the desktop pointer from arm's length and each changes what it claims to change.

## The hall is severed by the museum's passage, and was before this

`[em-walk] Noise_Columns: SEVERED and nothing reopens it`. Measured both ways: 193 free cells with the trio staged, 213 with the staging switched off, same verdict. The museum's tile for the hall is open end to end (rows 1–14 all floor, doors at x5–7 north and south); the passage rows the museum adds afterwards bend east and end at x9–x10 while the door lane is x5–x7. The probe checks the hall's own tile door to door, which passes, and records the museum's verdict as a measurement. Raised as its own thread, 260912-fca2z, because a seam is not this room's to fix.

## Map changes

- `MeltingBerniniScene` from (6,7) to (9,7) as `MeltingBerniniScene:180#stand:trio#speed:0.9`. Any collider in the staging seals the body's whole footprint, and a 4.4 m row across the hall's middle sat in its narrow lane.
- `museum.artifact_placement: "map"` and `sculpture_clear_rects [[7,4,12,11]]`.
- The description rewritten: it claimed an erosion process and an undoing of disorder that the melt never implemented. It now says what is there, including that the columns carry no collider. The probe checks the description in both directions.

## Not done, said plainly

- No headset walk, and nobody has watched long enough to catch a return with their own eyes.
- The marble shader's own parameters are untouched; this pass only takes it off and puts it back.
- The two other scenes that use this script (`proceduralgeneration/berninicolumns` and `wavefunctions/berninicolumns`) are untouched: they have their own roots and their own cameras, and they are not this room's.
- Astra's review, and the passage severance on the forum.

## Files

`algorithms/proceduralgeneration/hybrid_complex/berninicolumns/MeltingBerniniColumns.gd` and `MeltingBerniniScene.tscn`, `commons/maps/Noise_Columns/map_data.json`, `commons/maps/Noise_Columns/{final,summary,technical,tutorial,field_notes}.md`, `commons/testing/probe_wcn_columns.gd` and its live port, `tools/run_wcn_probe.sh` and `tools/port_wcn_probes_live.py` (the `columns` case), `tools/build_wcn_captures_page.py` (N2's views), and the captures page rebuilt and published. Forum: 260912-2jx9v (the claim), 260912-fca2z (the passage).
