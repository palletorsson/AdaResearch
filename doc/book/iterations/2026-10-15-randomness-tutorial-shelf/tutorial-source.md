# Give a number somewhere to go

We build a small tutorial shelf: a point on a line, a growing point, a turning cube and a sphere that changes colour. Each press of NEXT sends **the same number** to all four. We can see what we have directed randomness towards.

The abacus in the room makes a path felt through a hand. Here we isolate its first operation: assigning a value to a property. Position, scale, rotation and materials come from the earlier Primitives, Transformation and Colour lessons. The new part is the source of the value and the decision about where it goes.

## Build the shelf

The [editable shelf scene](../../../doc/book/studies/randomness-shelf/shelf.tscn) supplies geometry and the inherited rectangular buttons. The [desktop preview](../../../doc/book/studies/randomness-shelf/preview.tscn) includes a camera and clickable controls; open it in Godot and press F6. For a museum practice scene, instance `shelf.tscn` at floor level with unit scale and keep the existing player and lights. This is a learner build; its installation in the room is a later placement decision.

To assemble the study ourselves, start with a Node3D and the following children. Each group has its own origin; the script changes properties relative to that origin.

| Group | Object we build | What remains fixed |
| --- | --- | --- |
| `Move` | `Point`: sphere of radius 0.1 m; `Line`: box 0.8 m long on X | Y, Z and the line |
| `Scale` | `Point`: sphere of radius 0.1 m | Centre and shape |
| `Rotate` | `Cube`: box 0.22 m across, with a coloured face marker | Centre and size |
| `Colour` | `Point`: sphere with a StandardMaterial3D in Material Override | Geometry |

Place the groups beside one another, add a Label3D named `Readout`, and attach the following file to their parent. The supplied scene shows the complete arrangement. NEXT calls `next_sample()`; REPLAY calls `replay()`. The marked face makes the cube's turn visible.

## The small program — direct_randomness.gd

Read `show_sample()` first. `u` is one stored value between zero and one. **Mapping** means assigning that value a consequence. `lerpf(a, b, u)` places it proportionally between two limits. `TAU` is one full turn in radians. Hue travels around a colour circle while saturation and brightness stay fixed.

<!-- student-code:direct_randomness.gd -->

{{CORE_CODE}}

Run it. One value is already displayed. Press NEXT: the point jumps along its line while size, angle and colour change together. There is no smoothing or physics pushing it. The time of the press determines when the next value matters. After eight values, the retained sequence repeats.

`rng.seed = 435` starts a **pseudorandom generator**, a deterministic calculation whose internal state advances with each draw. We request eight values once. Reading them changes no generator state. REPLAY returns to the first stored value. Each object receives `u`; calling `randf()` separately for each object would answer a different question.

## Change one consequence

At `u = 0.25`, predict X = −0.2 m, scale = 0.75 and rotation = a quarter-turn. Colour gets that same fraction of its hue circle. These outputs are related by our assignments; they are not four independent random events. A full turn and no turn look alike, and hue also wraps: different values can have the same visible consequence.

Keep a baseline, then change only `x_extent` from 0.4 to 0.2 in the running shelf's Remote Inspector. Press REPLAY and compare the same sample numbers. The point's travel contracts; the other three assignments stay. Restore 0.4 afterward. Does the shortened range change what feels restless, constrained or barely moving? An uninteresting difference is evidence too.

The optional [notebook](../../../doc/book/studies/randomness-shelf/shelf_notebook.gd) supplies KEEP and LOAD. KEEP writes a new file and prints its location in Godot Output. It retains the actual eight values, current sample and X range. Add `observation` and `next_change` in that JSON; leave its record fields intact. Set Notebook's `load_path` to reopen it after restarting. LOAD restores that saved moment; REPLAY starts its stored sequence again. Preserve the scene and script with each experiment.

Have another person build from the small program, load the record and compare the four properties. Then let the observation propose one further change: another range, another destination, or a clock that advances NEXT. Keep the earlier record for comparison. Reproducibility of these stored values does not establish unpredictability or reproduce a feeling.

The **48-value seed bench remains the first research pilot**. This eight-value shelf introduces its question at a smaller scale. The [full abacus reconstruction and experiment loop](abacus-reconstruction.md) and [colour-window study](seed-picture-extension.md) remain extensions. Keep the local generator, stored array and distinction between value and assignment: [Random Entropy](../Random_Entropy/tutorial.md) next asks what a measurement retains from a record.
