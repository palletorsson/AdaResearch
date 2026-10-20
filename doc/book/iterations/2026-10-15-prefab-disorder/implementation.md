# Prefab disorder — what stays together?

One slider compares two arrangements of the same four gallery objects. On the left, each prefab moves as one assembly. On the right, its authored mesh parts move independently. Zero reconstructs both arrangements exactly.

Installed in **Random_Entropy**, grid **(13, 3)**, facing the entrance. It is an optional tutorial encounter. For a standalone desktop view, open `preview.tscn` in this directory and run it with F6; its screen controls mirror the physical console.

## Sources

| Prefab | Visible mesh parts on each side |
| --- | ---: |
| `cardboard_box` | 9 |
| `computer_monitor` | 13 |
| `lab_stool` | 14 |
| `microscope` | 14 |

These are the existing scenes under `commons/artifacts/<id>/<id>.tscn`, also represented in the artifact and props DNA galleries. Each is scaled uniformly to a longest dimension of 0.44 m. Both sides contain 50 meshes, with the original geometry and materials. The copies do not run the source scripts or inherit their physics. A mesh part is an authored modelling boundary, not a claim about atoms or mechanically separable components.

## Experiment

1. Begin at zero with seed 435. Compare the identical inventories and assemblies.
2. Move DISORDER to 0.5, then 1. The same retained draws set the direction of each translation and rotation; the slider changes their strength.
3. Compare recognition on the two sides. Does a rotated whole object remain identifiable when its separated counterpart does not? Which features preserve its identity?
4. Press KEEP at an interesting setting. Press ZERO, change the seed, then REPLAY. The saved slider and raw draws reconstruct the kept arrangement.
5. Reopen the preview and press REPLAY to check that the record survives a new scene instance.
6. Propose one further change: move only supports, keep surfaces together, or group parts by function. Such a change revises what counts as one movable unit.

ZERO changes only the slider. SEED +1 changes the deterministic offsets while retaining the slider setting. It does not acquire physical randomness. KEEP writes a timestamped JSON file under Godot's `user://` folder; REPLAY reads the latest saved pointer. The Output panel prints the full saved path.

## Small model

`disorder_sample.gd` retains six uint32 draws for each movable unit: three for translation, three for Euler rotation. Translation ranges at full disorder are x ±0.23 m, y 0–0.36 m, z ±0.20 m; each angular component ranges ±0.8π. Rotation occurs about the transformed bounding-box centre. A final vertical correction keeps each displayed unit's bounding box above its tray.

`prefab_disorder.gd` collects the source meshes and home transforms, then applies the model either to the complete assembly or separately to each mesh. Returning to zero uses the exact home transform. There is no accumulation of transform errors or new random sampling on slider movement.

This is geometric disorder: a reversible control over displacement and rotation. It is not a Shannon or Boltzmann entropy measurement, a thermal simulation, or a collision-driven pile. Parts can intersect. To add an entropy reading, first declare a random variable and distribution or a macrostate and the configurations being counted; visual irregularity alone supplies neither.

## Records and evidence

Records include schema, seed, slider, source list, source signature, raw draws and engine version. Changed source signatures and malformed records are rejected before changing the display. The seed alone is not the saved evidence: replay uses the retained draws.

The [review and verification receipt](../../../doc/book/iterations/2026-10-15-prefab-disorder/README.md) links 36 native apparatus checks and 17 actual-hall checks, with captures at zero, half and full disorder. Native checks include replay in a freshly instantiated scene and comparison of every resulting mesh transform. Headset comfort, Quest performance and human interpretations remain untested.
