# Finite removal, volume and embodied access

## Hand model and complete learner construction — 8 October 2026

The existing Menger lesson now installs `commons/artifacts/menger_lesson/hand_cells.gd`. It stands beside the six-button desk, outside the flight volume. It copies the generator's live retained cubes and optional removed volumes at factor 0.09 into a transparent, noncolliding model. It does not run a second full-size generator. A familiar PointBody selects one of the 27 first-level addresses; small and large noncolliding frames mark the same cell. KEEP/REMOVE reads the original `keep_positions` table. After cut two, a kept first-level cell contains smaller holes; the selector deliberately does not imply that region is still filled.

The point's inherited action signal and nearby NEXT/BACK/RESET all route through the original desk's `act()` and its occupant guard. Reading a cell changes no solids. Release returns the point to the near edge. Rebuilds detach old miniature meshes immediately, preserve the reader/flight fixtures and stay bounded at 400 retained + 147 optional removed meshes. The original six controls and cinematic monitor remain.

`tutorial.md` now contains complete `menger.gd` and unchanged `point_body.gd`. The student's current/next array stores cube centres with one common edge length; a Boolean predicate retains offsets having fewer than two middle coordinates. It is equivalent to the production index table for this axis-aligned cube. The model's visual scale is separate from represented volume. The student renderer supplies no cube collision or flight. The independent corner-only variation changes the rule while preserving outer bounds. Exact printed fences are extracted and run by `tools/test_menger_hand_lesson.py`.

The primary is `menger_sponge`. Its book anchor, role, order and Necklace card refer to the existing nine-metre specimen with `#flight_box:true#lesson:true`. All six current placements remain. The film monitor moves from cell (10, 1) to (3, 1), clearing the standing approach to the desk and hand model. The 15×18 structure and basin stay. Entry `sp` moves to (7, 1); the two old `t` markers inside/beside the enclosure become one at (7, 17), with a flush floor cell. The previous markers failed portal clearance and put the fallback next-hall portal directly before the flight entrance. The new exit is beyond the rear ground door. This changes map addresses, not the shared portal or flight code.

## The desk

`commons/artifacts/menger_lesson/menger_lesson.gd` is an opt-in child of the existing generator. It has six full-sized touch buttons in a compact 3×2 arrangement and the small transparent tilted screen used in the preceding halls. The desk stands to the right of the front entrance, outside the flight volume, with its standing position clear of the museum wall and the glass envelope.

| Control | Effect |
|---|---|
| NEXT | Advance one finite cut, up to two. |
| BACK | Rebuild the preceding stage. |
| GHOST | Show/hide the seven removed cells from each subdivided parent. |
| FRAME | Show/hide a non-solid nine-metre outer frame. |
| RESET | Return to the uncut cube and initial view. |
| RULE | Explain the selection after the visitor has compared stages. |

NEXT/BACK/RESET check the `em_walker`, `player_body` and `player` groups against the flight volume. They refuse a solid rebuild while a visitor is inside. Refusal does not queue a later action: the visitor must press again after the enclosure is empty. View controls remain available because they change neither the retained cubes nor collision. This is a desk interlock, not a claim that every external editor or direct script call is prevented from rebuilding the scene.

## The actual construction

`algorithms/fractals/mengersponge/menger_sponge.gd` scans only its own cube scenes. `InitialCube` is a one-unit cube scaled to nine metres, with centre y=4.5. Each iteration partitions its retained cubes into a 3×3×3 grid, removes the central cell and six face-centred cells, and keeps twenty positions. Integer division maps the linear index to three coordinates. The central cross connects opposite faces along all three axes.

| Cut | Retained cubes | Cube edge | Summed retained volume | Smallest axial opening |
|---|---:|---:|---:|---:|
| 0 | 1 | 9 m | 729 m³ | None |
| 1 | 20 | 3 m | 540 m³ | 3×3 m |
| 2 | 400 | 1 m | 400 m³ | 1×1 m |

The outer AABB remains 9×9×9 m. Counts follow 20^n; volumes follow 729(20/27)^n. The lesson computes retained volume from the determinants of the actual unit-cube transforms. At the identity placement used here, this agrees with the formula. Object counts and volumes are not entropy measurements.

The complement is constructed once per stage: at cut two, seven removed cubes of edge 3 m plus 140 of edge 1 m, totalling 329 m³. These MeshInstances have no colliders. A `menger_removed` metadata tag identifies them independently of Godot's generated node names. GHOST changes their visibility; FRAME changes twelve thin edge meshes. Neither rebuilds the solids. Rebuild detaches old generated nodes and retains the desk and flight enclosure. The desk stops at two cuts and does not allocate another generation at its ceiling. Ordinary source scenes without `lesson:true` retain their existing automatic generation and DNA configuration.

## Flight and bodies

`commons/movement/museum_flight_box.gd` and `museum_flight_provider.gd` remain unchanged. The twelve-metre glass envelope has two three-metre-wide ground doors. Its floor provides support independently of the map basin. Movement is capped at 2.4 m/s; neutral input hovers. Exiting at ground level returns control to ordinary locomotion. Retained cubes and glass remain solid. The same enclosure instance persists across desk rebuilds.

The native museum walker has a 0.32 m-radius, 1.5 m-high capsule. Its camera is 1.65 m above the feet, so view position and collision shape are distinct. In the reviewed second-stage sponge, a ray along local x=−3,y=1.5 crosses the one-metre axial tunnel, but the standing capsule cannot enter it. The three-metre central passage admits that body during flight. XR body height follows the user's tracking/setup; the desktop capsule is not a measurement of every VR visitor.

The existing flight acceptance is rerun on the changed scene: ground entry, ascent, hover, central passage, travel around and above the sponge, roof/side collisions, descent, exit, resumed gravity, volume removal and synthetic XR controller input. Desk input uses the standalone DesktopPlayer's real pointer pipeline inside the museum; that rig has a different 1.8 m capsule. It does not establish native museum mouse-button interaction. Headset reach, comfort and Quest frame time remain pending. Recorded build durations are observations on this desktop, not a headset benchmark.

## Retained secondary works

`diffusion_limited_aggregation` retains its automatic two-dimensional random walks, ten-walker cap and attachment rule. It has no new desk controls or held-seed comparison in this pass. Its particles move once per rendered update; this is not a validated physical model of frost, rivers or all branching forms. Its progression may be slow within a brief visit. The catalyst prompter and vent retain their existing behavior. The dark sphere retains its placement. None is silently relabelled as part of the sponge algorithm.

Previous map, manuscript, supporting texts, source and flight fixture are archived in `doc/space/menger-encounter-2026-09-14/before/`. Earlier flight evidence remains available, and the new runtime receipt records the teaching scene now in use.
