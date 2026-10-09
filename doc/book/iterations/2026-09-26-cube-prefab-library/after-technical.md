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

The default `closure:strata` leaves all layers visible. It does not automatically replace them with a final solid mesh. Existing configuration alternatives remain: `closure:scaffold` retains corners and edges; `closure:solid` shows a combined surface with corner handles. `order:descend` reveals triangles, edges and vertices in that order; `order:together` reveals all layers at once. These are configuration choices, not new controls on the front panel.

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

This source connection is enough for the current recognition: the museum's floor and walls belong to the same box vocabulary as the exhibits. The new prefab library begins composition with existing objects; later Transformation encounters examine the operations used to place and alter them.

## Source and verification

- `commons/primitives/animatedcubebuilder/animatedcubebuilder.gd`
- `commons/ui/cube_experiment_panel.gd`
- `commons/infoboards_3d/visualizations/polyhedron_nets.gd`
- `commons/scenes/endless_museum.gd` (`_box`, `_flush_boxes`, `_wall_at`, `_add_col`, floor stamping)
- `commons/artifacts/crate/crate.gd` (`_build`, `_build_plank_face`)
- `commons/maps/Point_Animatedcube/map_data.json`
- `commons/testing/probe_cube_primary.gd`

The probe exercises actual pointer-button events and supplied corner positions in a translated, rotated artifact. It checks pause, replay, restoration, connection preservation, surface updates, diagonals and readout bounds. A full-room headset walk remains necessary for reach, viewing distance and comparison between placements.

## Shared front-face illustration

`cube_diagonal_plate` renders the same four front-face positions and the same two triples as the builder. In the right specimen only v6 receives `(0,0,0.55)`. The common diagonal 5–7 and triangle 4–5–7 remain fixed. Both specimens use one oblique projection with equal depth compression; the reference is not metrically to scale on the wall.

`tools/capture_cube_diagonal_plate.py` extracts the builder's current vertices and faces, then checks the actual plate meshes against them in a private Godot project. It renders the production scene for the book. The plate is static; handle interaction, replay and restoration still belong to the existing builders.

## A library of box prefabs

`prefab_box_library` occupies the widened east gallery at grid (16,7), facing west. Its 9.12 m shelf contains 24 pickable copies: six columns and four tiers. The first four columns repeat cardboard, wooden crate, cargo crate and the original AGAIN carton respectively. The last two vary the wooden crate and carton through exported colour, construction and lettering properties. Twelve distinct source/configuration editions produce the 24 copies.

The editable `commons/artifacts/prefab_box_library/catalog.json` names the four real scene sources and their settings. The original cardboard, crate and cargo scenes are unchanged. At construction, each edition loads its source once, applies exported settings before `_ready`, and collects the resulting meshes and static labels. Meshes are batched by material into a cached `PackedScene`; copies share its mesh resources but have independent pickable bodies, transforms and physics state. This is a static display-and-pickup adapter for the listed sources, not a general copier of arbitrary prefab scripts or behaviours.

Each copy has one enclosing box collider, fitted to the source bounds. The cardboard opening is visible but does not have a hollow collision interior. Copies begin frozen on the shelf; pickup uses the production XRToolsPickable and release enables rigid-body physics. Layer 6/mask 7 allows contact with the table, the museum and other pickable copies. Mesh batching produces 24 geometry nodes and 105 geometry surfaces, plus lettering; this is not a claim of 24 draw calls or tested Quest performance.

The worktop is 0.775 m above the gallery floor. It is initially empty. The bottom and second tiers provide direct-reach copies; the higher tiers use the existing ranged pickup. Dropped objects below -2 m or more than 25 m from the library return to their shelf positions on the next periodic check, unless held. Arrangements are temporary in-session state, not a new save system.

The native museum probe checks actual production pickup/release with a supplied grabber, separate instance state, shared geometry, gravity settling on the worktop, box-on-box stacking and a visitor-width walk along the shelf. All 19 checks pass. The four screenshots are native views from within the hall. Headset reach, real controller targeting and Quest performance have not been verified.

Sources and evidence: `commons/artifacts/prefab_box_library/`; `doc/book/iterations/2026-09-26-cube-prefab-library/probe.gd`; the adjacent review page and native report.
