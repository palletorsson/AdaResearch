# Who connected the controls? — implementation

## Existing museum

The artifact is `algorithms/spacetopology/entropy_morphogenesis/entropy_morphogenesis_vr.gd`, using `GyroidFieldGenerator.gd` from the adjacent gyroid_cheese directory. The adapter `commons/artifacts/timing_machines/soft_workshop.gd` binds its six controls. This pass changes none of those algorithms or the adapter. The desk moves from (15,3) to (15,9), nearer the large surface at (15,14), offset four metres upward. Arrival is clear; the right-side museum route has floor and capsule clearance in 273 samples. Passage through the gyroid and portal transitions were not tested.

Opening runtime observations: `{"S": 0.3, "box": [5.0, 10.0, 5.0], "frequency": 1.11, "mesh_bounds": "[P: (-2.5, -5.0, -2.5), S: (5.0, 5.0, 5.0)]", "noise": 0.095, "resolution": "(40, 40, 40)", "seed": 1337, "threshold": -0.06}`.

The scene exports a non-cubic (5,10,5) box with a 40-cubed resolution. The generator uses box_size.x/resolution.x as one spacing for every axis, starting at -box_size/2. The measured generated bounds therefore span (5,5,5), offset from y=-5, rather than filling the declared ten-metre height. This existing limitation remains explicitly recorded. The prior reflection's metrics for an eight-unit cube are not evidence for this actual exhibit and have been removed from the reflective text. The original illustration and text remain in before/.

S=.3 maps to frequency1.11, noise amplitude.095, threshold-.06. S1 maps to1.6,.20,.15 when the threshold centre is0 and noise is enabled. LEVEL changes threshold centre; NOISE changes its two endpoint amplitudes; RESOLUTION cycles24/16/32. RESET restores S.3, centre0, noise.05/.20, resolution24; the existing button-cycle indices and level string are not reset. Tests assert the resulting parameters, not a clean reset of every UI cursor. The startup resolution is40, not24.

The normalized density is clamp((sine_field + noise_amp * sampled_noise - threshold)/6 + .5,0,1). Threshold changes this mapping while retaining underlying field parameters. The supplied noise implementation multiplies coordinates by noise_freq while FastNoiseLite also holds that frequency; this lesson carries the implementation as supplied and makes no independent claim about its wavelength. A gyroid-like trigonometric level set is not a proof of exact minimality, topology, entropy or physical growth.

## Learner

`doc/book/studies/soft-bodies-through-the-hands/Topology_Entropy_Morphogenesis/` supplies recipe.gd, unchanged point_body.gd and the minimal study.tscn. Both visible scripts are extracted from tutorial.md and executed. The lesson writes the recipe and its named recipients. Field generation, marching cubes and trimesh collision remain explicit project dependencies; future Isosurfaces work can open the extractor. No new backend and no implicit scene-child reference is introduced.

Two separate generators have equal seed1337, box(8,8,8), resolution24 cubed, and initial recipe at.3. Separate quarter-scale holders display two-metre specimens. The cubic volume avoids the supplied rectangular-spacing issue. A stays fixed; B uses ALL/FREQUENCY/NOISE/CUT modes relative to the original. Held PointBody height in the root's local frame previews0..1 over y.8..1.6; held trigger commits. Release parks at preview height without rebuilding. Keyboard1 cycles mode, arrows preview, Space builds, R resets. Mode selection is keyboard-driven in the student host; installed controls are pointer/VR buttons. The temporary native host sits at map(15,0,27),yaw180; it is not a permanent third artifact.

The independent CUT_SPAN .15->.30 edit changes the starting cut from-.06 to-.12 and the endpoint from.15 to.30, preserving frequency/noise. Source references separate the new analytic spatial field from the previous dynamic two-dimensional reaction field. Their lineage is the method of matched comparison and carried PointBody, not automatic transfer of concentration arrays.

## Evidence

32 executable code checks passed on native Godot4.6/OpenGL: full host, parameter predictions, recipient isolation, equal seeds/meshes/collision, preview/commit/echo, reset, density difference, transformed-host XRTools, independent edit. Four executing faults were rejected: an uncentred cut, accidentally coupled noise, different seeds and writing to the reference object.

44 native museum checks passed: actual pointer operations for six controls, current mesh/collider after rebuild, deterministic reconstruction, unchanged geometry at idle, complete learner at four modes, synthetic XRTools preview/trigger/release, independent edit, arrival and outer route. Real above/eye captures inspected. Display type was enlarged after the first capture; final code and museum runs were repeated for that change. Existing UID/Jolt/material warnings remain; no script or parse errors in the final runs. Physical headset comfort, Quest performance and an independent human learner remain untested.

Reproduce: `python tools/test_morphogenesis_lesson.py`; `python tools/run_encounter_probe.py Topology_Entropy_Morphogenesis --sequence softbodies --render --no-bridges --output-tag morphogenesis-final --probe tools/probes/morphogenesis_room.gd`.
