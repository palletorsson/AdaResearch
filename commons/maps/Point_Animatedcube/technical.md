# A cube assembled, replayed and changed

Primitives_Polythedra distinguished a visible boundary from a collision boundary and tested how forms support or interrupt movement. Here, the primary order is an outline (`cube_lines`), a timed reveal with editable corners (`animatedcubebuilder`), the shared-diagonal reference (`cube_diagonal_plate`), a hinged surface (`polyhedron_nets_cube`), reusable copies (`prefab_box_library`), then a sorting rule (`cube_sorting_line`). The room has two builder placements; one can remain an unchanged reference.

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

The cube net keeps each square face rigid and rotates parent hinge nodes. Ordinary placements animate a fold-progress property:

```gdscript
tween.tween_property(self, "fold_progress", 1.0, fold_duration)
```

For the default net, that property maps to ±90-degree hinge rotations, with the back flap delayed relative to the others. The current room has one `latin_cross` net with `fall_cycle:true`. Its controller drives the same property over 2.6 seconds, holds the closed cube briefly, then shrinks it around its centre to 45% of its original size over 0.8 seconds. At release it copies the closed six-face hierarchy, including edges and numbers, into a new rigid body. Shared mesh and material resources keep copies inexpensive; their transforms and physics states are separate.

The resulting 0.315 m cube falls under gravity and settles on the museum floor. Contact and low speed start a 2.2-second pause, accompanied by one, two and three dots. The fallen cube stays. Above it, the working net becomes visible, grows back to full size and unfolds. A small alternating release velocity lets successive cubes land around the same spot; rotation is free, and the cubes collide with one another. “Thinking” names a possible reading of the timed pause.

`edge_length`, `fold_duration`, `drop_scale` and `think_hold` configure size, fold, reduction and pause. `max_dropped_cubes` defaults to 24; further releases retire the oldest body, keeping the collection bounded. Escaped bodies are also retired. Reconfiguration and unloading remove the temporary collection. `fall_cycle` defaults to false, preserving other placements. The student tutorial continues to concentrate on vertex positions and their connections.

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
- `commons/infoboards_3d/visualizations/cube_net_cycle.gd`
- `commons/testing/capture_cube_net_cycle.gd`
- `commons/scenes/endless_museum.gd` (`_box`, `_flush_boxes`, `_wall_at`, `_add_col`, floor stamping)
- `commons/artifacts/crate/crate.gd` (`_build`, `_build_plank_face`)
- `commons/maps/Point_Animatedcube/map_data.json`
- `commons/testing/probe_cube_primary.gd`

The probe exercises actual pointer-button events and supplied corner positions in a translated, rotated artifact. It checks pause, replay, restoration, connection preservation, surface updates, diagonals and readout bounds. A full-room headset walk remains necessary for reach, viewing distance and comparison between placements.

The October 4 production test assembles the actual endless museum and runs two complete cycles. It checks shrink dimensions, six-face copies, floor contact, two retained independent bodies, the working net's return, the collection limit and live reconfiguration. All four existing net layouts still close. The native clip and checks are in `doc/book/iterations/2026-10-04-cube-another-one/`. Physical headset behavior remains untested.

## Shared front-face illustration

`cube_diagonal_plate` renders the same four front-face positions and the same two triples as the builder. In the right specimen only v6 receives `(0,0,0.55)`. The common diagonal 5–7 and triangle 4–5–7 remain fixed. Both specimens use one oblique projection with equal depth compression; the reference is not metrically to scale on the wall.

`tools/capture_cube_diagonal_plate.py` extracts the builder's current vertices and faces, then checks the actual plate meshes against them in a private Godot project. It renders the production scene for the book. The plate is static; handle interaction, replay and restoration still belong to the existing builders.

## Reuse a scene, arrange its copies

`prefab_box_library` is restored at grid (11,8), facing east, with all 24 original pickable copies. The placement's `offset:-0.2,0,0` puts its root at world X = 11.3 m. Its `column_pitch:1.2` brings the rack width to 7.44 m without changing the copies' sizes; the default 1.48 m pitch retains the original 9.12 m rack in other placements. The `worktable_x:-2.45` and `worktable_z:2.0` settings move the original-size table to the south end. The six catalog columns each supply four copies: four repeated families followed by crate and printed-carton variations. The library caches a display scene per source/configuration, sharing mesh resources while each pickable keeps its own transform and physics state. Taking copies to the table changes their arrangement. This experiment remains available beside the sorting game's prescribed matching rule.

## Fold, print, sort

`cube_sorting_line` stands in the widened east gallery at grid (16,7), facing west toward the restored shelf across a shared aisle. Its 5.2 m conveyor has a 0.48 m wide, 0.95 m high work surface. Both baskets are on the far side, close to the belt, leaving the visitor's side clear. Their raised labels face the visitor; the pause/reset stand remains alongside. The feeder uses the existing `polyhedron_nets_cube` scene at a 0.42 m edge length, with the scene's automatic folding disabled so the game controls the fold, shrink and release cycle. Each finished delivery is a separate 0.32 m cube.

The conveyor is a `StaticBody3D` whose `constant_linear_velocity` follows the artifact's rotated local X axis. A free cube passing beneath the printer receives one of two randomly selected shared materials. `carton_skins.gd` generates a six-face texture atlas carrying AGAIN on cream with red stripes, or YET on mint with teal stripes. These editions adapt the original printed carton's visual vocabulary; the basket samples instantiate the existing `edition_carton` scene. The moving cubes share their box geometry and edition textures while retaining separate transforms and physics state.

`sorting_cube.gd` extends the production XR Tools pickable and tracks both XR and desktop holding. Layer 6/mask 7 allows contact with the conveyor, museum, baskets and other deliveries. A held cube cannot be printed or sorted. Sorting requires a released, printed cube inside the matching basket; a wrong edition remains a physical cube. An accepted cube shrinks to 0.065 m while moving into the basket, then joins that basket's `MultiMesh` display and count. The basket floors and four low walls remain physical geometry.

Missed deliveries fall from the open conveyor end onto the actual museum floor. When they settle, two material batches retain their exact positions and rotations; individual box shapes on a shared static body preserve the same collision geometry. There is no automatic alignment or separation by edition. Nearby exposed cubes become individual pickables in those same poses. Taking a supporting cube wakes nearby boxes above it, within the active-body budget, so they can fall again. This keeps unsorted stock without simulating every settled cube continuously. The floor scan estimates a bounded room capacity without assigning storage positions. A natural jam can also pause production when the moving-body budget is full. **PAUSE** stops the feeder and belt; **RESET** clears the round's stock and counts. State remains local to the current scene.

The Godot 4.6 gameplay and capture run passes 80 checks covering physical belt transport and stamping, correct and wrong basket handling, visible mesh and collider shrinking, actual XR Tools pickup/release with a supplied grabber, retained-stock recovery, reset while holding a cube, and a compact fixture's room-full loss state. It also verifies that the rendered miniatures stay inside the relocated baskets.

The restored hall passes 30 native museum checks with no script errors. They verify both artifact placements and facing, all 24 original XR Tools pickables, the worktable's local centre `(-2.45,0,2.0)`, collider clearance for the complete library and table, generated deliveries, room-fill configuration and basket clearance. The rack clears the door leaf and trim by 0.1625 m. A 0.24 m radius, 1.68 m high capsule follows three unobstructed, floor-supported routes: 14.25 m from the south entry along all six columns, 7.57 m between the table, sorting baskets and controls, and 3.15 m back into the hall. These desktop checks do not establish headset reach, real controller targeting or Quest performance.

Sources: `commons/artifacts/cube_sorting_line/`; `commons/artifacts/prefab_box_library/`. Stage and museum capture helpers: `ada_run/cube-sorter-stage/`. Gameplay and museum reports and native interior captures: sibling repository `ada_encyclopedia/captures/ada-run/cube-sorter-2026-10-05/`. The restored `prefab_box_library` retains the component checks recorded in `doc/book/iterations/2026-09-26-cube-prefab-library/`.
