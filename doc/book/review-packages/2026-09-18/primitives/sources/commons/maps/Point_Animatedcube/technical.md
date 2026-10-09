# A cube assembled, replayed and changed

Primitives_Polythedra distinguished a visible boundary from a collision boundary and tested how forms support or interrupt movement. Here, the primary order is an outline (`cube_lines`), a timed reveal with editable corners (`animatedcubebuilder`), then a hinged surface (`polyhedron_nets_cube`). The room has two builder placements; one can remain an unchanged reference.

## Read a position and a connection separately

Before moving a handle, predict which parts will follow. The builder starts with eight local positions at the combinations of ±0.5 on X, Y and Z. It also stores twelve cube edges and twelve triangle patches in separate lists. The positions alone do not specify which vertices should connect.

For example, the front surface uses these source triples:

```gdscript
[4, 5, 7]
[5, 6, 7]
```

Their common edge is `[5, 7]`. Move vertex 6 out of the original face plane. The second triangle can tilt while the first remains unchanged. This pair no longer forms a planar square.

The initial cube's geometric face count gives `8 - 12 + 6 = 2`. Counting the triangulated boundary gives `8 - 18 + 12 = 2`, because triangulating the six squares adds six diagonals as well as six faces. The visible edge cylinders initially show only the twelve cube edges. The DIAGONALS control exposes the other six, derived from the triangle list rather than a separate hand-authored diagram.

Each triangle patch is submitted with a reversed copy for visibility from both sides. The panel counts twelve patches, not the twenty-four submitted triangles in this particular implementation. Counts must identify their representation.

## What the builder animates

At setup, the builder prepares hidden handle, edge and surface nodes. Its default timed presentation reveals eight vertices at 0.5-second steps, twelve edges at 0.2-second steps, then twelve patches at 0.15-second steps. Frame timing can extend those intervals: the state machine reveals at most one item per process call and resets its step timer after each item.

The default `closure:strata` leaves all layers visible. It does not automatically replace them with a final solid mesh. Existing configuration alternatives remain: `closure:scaffold` retains corners and edges; `closure:solid` shows a combined surface with corner handles. `order:descend` reveals triangles, edges and vertices in that order; `order:together` reveals all layers at once. These are configuration choices, not new controls on the side panel.

The `#discovery:1` option adds the room's instrument and source-index labels `v0` through `v7`. During assembly, handles are disabled for pickup; completion enables them. This lets a visitor pause a readable layer without accidentally editing a hidden corner.

## Four controls, four operations

- **REPLAY** hides and reveals the layers again using the current positions. It resumes a paused assembly and preserves deformation.
- **PAUSE / RESUME** stops or resumes only the builder's timed reveal. It does not pause the game clock, the folding net or the room. At completion, it asks the visitor to replay before pausing steps.
- **RESTORE CUBE** returns all eight handles to their initial local positions and displays the completed result, without replaying the animation.
- **DIAGONALS** shows or hides the six additional triangulation edges after assembly completes. It does not change the faces.

Replay and restore ask for a held corner to be released first. The panel reports visible points, visible cube edges, surface patches and the largest corner displacement from its initial local position. Local metres do not include additional scale applied to the artifact by a parent.

## Deformation reads handles back into geometry

After a completed build, changed handles update the stored positions:

```gdscript
vertices[i] = handle_nodes[i].position / cube_size
```

The existing edge and triangle lists are then used to rebuild geometry. Hidden surface patches update too, so replaying or changing the configured closure cannot bring back stale geometry. The yellow diagonal cylinders follow their corresponding vertex pairs.

This preserves connectivity, not cube validity. It does not enforce equal lengths, right angles, planarity or a non-intersecting enclosure. The mesh surfaces have no enclosing collision body; the corner handles have their own pickup colliders. A deformed shape is therefore a visual construction, not a newly tested walkable shelter.

## Folding changes another set of data

The cube net keeps each square face rigid and rotates parent hinge nodes. Its animation targets a fold-progress property:

```gdscript
tween.tween_property(self, "fold_progress", 1.0, fold_duration)
```

For the default net, that property maps to ±90-degree hinge rotations, with the back flap delayed relative to the others. The current room has one net placement, using the default `latin_cross` configuration with `loop_fold:true`. Other net configurations exist in the source but are not additional placements in this room. This is a different operation from the builder's visibility sequence and from independently moving its corners.

Primitives_Ignorance follows by examining what an engine's primitive names leave unspecified. Here, the word cube has already required a distinction between positions, connections, presentation and permitted edits.

## The box becomes museum structure

The endless museum's `_box()` records a position, size and material for each architectural box. `_flush_boxes()` renders batches using a shared `BoxMesh` with `size = Vector3.ONE`. Each instance receives its own scale and position:

```gdscript
mm.set_instance_transform(i, Transform3D(Basis.from_scale(s), p))
```

Here `s` is the box's size and `p` its centre. An ordinary floor tile is specified as `Vector3(1, 0.2, 1)`; `_wall_at()` specifies a wall cell as `Vector3(1, hh, 1)`, with `hh` carrying wall height. The repeated unit box becomes slabs and wall blocks. These are box-based constructions, rather than literal equal-sided cubes at every scale. Alternative wall-run batching can merge neighbouring cells into longer boxes.

The paired `_add_col()` constructs a separate `BoxShape3D` with the requested size. This is how the visible architecture gains collision for the walking body. The corner-editable builder does not use this architectural collision setup for its surface patches. A connection between the two constructions does not imply identical meshes, controls or physical behavior.

The placed `crate` provides another example. Its `_build()` calls `_build_plank_face()` for six sides, adds reinforcement strips and optionally builds a diagonal brace. Those components use additional box meshes. Six sides in a geometric description need not mean six rendered polygons or twelve total triangles in a furnished object.

This source connection is enough for the current recognition: the museum's floor and walls belong to the same box vocabulary as the exhibits. How to choose, transform and combine those parts into another spatial arrangement remains work for subsequent encounters.

## Source and verification

- `commons/primitives/animatedcubebuilder/animatedcubebuilder.gd`
- `commons/ui/cube_experiment_panel.gd`
- `commons/infoboards_3d/visualizations/polyhedron_nets.gd`
- `commons/scenes/endless_museum.gd` (`_box`, `_flush_boxes`, `_wall_at`, `_add_col`, floor stamping)
- `commons/artifacts/crate/crate.gd` (`_build`, `_build_plank_face`)
- `commons/maps/Point_Animatedcube/map_data.json`
- `commons/testing/probe_cube_primary.gd`

The probe exercises actual pointer-button events and supplied corner positions in a translated, rotated artifact. It checks pause, replay, restoration, connection preservation, surface updates, diagonals and readout bounds. A full-room headset walk remains necessary for reach, viewing distance and comparison between placements.
