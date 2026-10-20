# Polyhedra: construction, support and passage

This reference follows the current tetrahedron/wedge hall. The mathematical calculations below are reference calculations, not live readouts.

## Alignment creates a physical solid

[`align_solid.gd`](../../artifacts/primitive_encounters/align_solid.gd) provides both opening constructions. Releasing the displaced vertex within 0.12 m of the target completes the authored form, creates its pickable rigid body and enables gravity. A farther release leaves the construction unfinished. The tetrahedron already has tetrahedral connectivity; the target accepts the particular regular proportions. The wedge target restores a triangular prism. A target test is not a general proof that a mesh is a valid solid.

[`geometry.gd`](../../artifacts/primitive_encounters/geometry.gd) supplies the visible surfaces and convex collision geometry. These have separate jobs: a face list draws the boundary; the physics representation controls contact.

## A corner, an opening, a movable apex

The placed [`corner_tetrahedron.gd`](../../artifacts/primitive_encounters/corner_tetrahedron.gd) occupies cell (2, 17), offset towards the meeting walls. It adds a solid to the corner; it does not subtract the room. This replaces the earlier map-wide simplex-corner configuration.

[`grab_trihedron.gd`](../../primitives/trihedron/grab_trihedron.gd) renders three triangular faces sharing a vertex. Its convex-hull collider closes the undrawn rim. The boundary plate exposes that difference; the editable pyramid keeps a vertex available for continuing alteration. A visible opening does not guarantee physical passage.

## A central bank follows the grid

Five existing `prism_block` objects, with `grain:solid` and uniform scale 2, form the stopper collection. Anchors are (5, 24), (7, 24), (9, 24), (11, 24), (13, 24); each has `offset:0.5,0,0.5`. Their two-metre footprints therefore occupy pairs of whole grid cells. The bank covers columns 5–14, rows 24–25, and is two metres tall. The original static concave collider scales with each visible prism.

The main floor runs from columns 2 to 17. Columns 2–4 and 15–17 remain clear beside the bank: three metres each. This is the current interpretation of the requested spacing, following the clarification that the blockers should be central and the climbing wedges should come afterwards at the sides. It replaces the earlier interpretation of a three-metre landing between opposing ramps.

## Forward side ramps onto a shared platform

The platform spans columns 2–17 and rows 30–32: 48 structure-`2` cells form a 16 × 3 m landing. `map_info.museum.wall_height: 3` makes its walking surface one metre above structure `1`. Walls use explicit `w`; the rock enclosure remains walled.

Ten stock [`walkableprism.tscn`](../../scenes/mapobjects/walkableprism.tscn) units make the approaches and descent. Each is one metre wide, one metre high and two metres long after its baked rotation, with a static concave collider. The museum's `_stamp_wedge` reads the neighbouring floor height.

| Purpose | Cells (x, z) | Utility | Direction |
| --- | --- | --- | --- |
| Left side approach | (2, 29), (3, 29), (4, 29) | `wp:0` | Climb +Z |
| Right side approach | (15, 29), (16, 29), (17, 29) | `wp:0` | Climb +Z |
| Far descent | (8, 33), (9, 33), (10, 33), (11, 33) | `wp:180` | Climb −Z; walking +Z descends |

Three adjacent units form each three-metre-wide side approach. The centred descent uses four. The `wedge_palace#layout:map` anchor moves to (9, 31); it builds no duplicate meshes. The separate standalone artifact remains available elsewhere.

Short inner walls at columns 5 and 14, rows 27–29, hold the ramps beside the existing outer walls. The central baffle and the old transverse ramp arrangement are removed. The broad platform reaches both outer walls, so an ordinary grounded walk cannot bypass it on flat floor. The central bank and side ramps remain successive encounters. Jumping, teleporting and flying are outside this route claim.

## Sculpture and plinth model on the landing

`wedge_column:0:0#offset:0.5,0,0#plinth:0#pin:1` at (6,32) places the sculpture centre at (6.5,32). Six instances of `prism_block.tscn` retain their source mesh, material and static concave collider. Each is uniformly scaled to 0.65. Pairs rotate ±90° about Z and meet at their bases; three paired modules produce a 1.30 m wide × 0.65 m deep × 1.95 m high column. Point-contact stacking is authored and fixed, not a rigid-body equilibrium test.

`wedge_mouse_model:0:0#plinth:0#pin:1` at (13,32) builds a 2.8 × 1.0 × 0.82 m plinth. The displayed model extends upward from the actual structure-2 surface. The front edge at z=31.5 leaves the existing z=31 crossing clear.

Seven `Piece` bodies reuse one right-triangular vertex set (width 0.22, rise 0.24, run 0.48 m). Two stand as blockers, one exposes a climbing face, two form the platform and two form the far landing. The 0.22 m gap lies between the platform's right end x=0.56 and the far landing's left end x=0.78 in model coordinates. The mouse and cheese share the triangular vocabulary at other dimensions. Grabbable pieces freeze on release, as the earlier triangle table does.

The player steers a CharacterBody3D using `joystick_zero.tscn`. There are no authored route targets in production. Its floor_max_angle is 50°, floor snapping is 0.025 m, gravity is 3 m/s², walking speed is 0.32 m/s, and jump launch speed is 1.10 m/s upward and 0.72 m/s horizontally. JUMP requires grounded contact and retains the last steering direction during flight. It can be attempted anywhere on the course. The miniature uses slowed physics for legibility, not dynamically scaled real-mouse mechanics. Construction convex margins are 1 mm: the default 4 cm rounding distorted the low ramp contact at this scale. The cheese is a gravity-enabled pickable body, so removing its support also changes its position.

HOME restores only the mouse and centres the stick. RESTORE restores all seven construction transforms, the mouse and the cheese. Neither writes a saved layout to disk. Holding a construction piece centres the stick and prevents jumping. The joystick returns to neutral on release and keeps avatar movement controls separate. Buttons use the existing poke/ray paths.

All four controls are collected on a 0.94 × 0.40 m panel at the starting end (model x=-1.42), facing -X behind the waiting mouse. The panel basis converts joystick directions into model coordinates: up goes +X towards the cheese; right goes +Z. Button caps face out from the panel. This keeps the long side of the plinth clear and the course ahead of its controls.

The mouse retains only its brown PrismMesh; the cheese is one upright yellow right-triangular wedge, 0.18 m wide, 0.24 m tall and 0.18 m deep. Neither has decorative facial parts or spots. Four flush, non-colliding BoxMeshes mark an initial detour around the stoppers to the ramp. This strip is a visual cue, not an automatic path or a physical rail; only the current surfaces determine support.

## Signs and retaining profiles

Four existing [`street_sign.gd`](../../artifacts/street_sign/street_sign.gd) instances mark the route. STOP at (9, 23) and a blue double arrow at (10, 23) precede the central bank. Blue ahead arrows at (3, 26) and (16, 26) indicate the later ramps. All face the entering body through a 180-degree rotation. They have no collision: the forms constrain or support movement; the signs supply instructions.

Eighteen [`concrete_barrier.gd`](../../artifacts/concrete_barrier/concrete_barrier.gd) sections surround the basin. Each requests a 1 m length, 0.85 m height, 0.60 m base width and `blocking:1`; the basin retains a floor and its small diamond chain. The rock box remains at (22, 31), with the scanner at (22, 35). The scanner's moving cyan plane does not currently produce the separate cross-section display.

## Count a closed surface

The following counts refer to geometric polygon faces, not GPU vertex submissions:

| Convex regular polyhedron | V | E | F | V − E + F |
| --- | ---: | ---: | ---: | ---: |
| Tetrahedron | 4 | 6 | 4 | 2 |
| Cube | 8 | 12 | 6 | 2 |
| Octahedron | 6 | 12 | 8 | 2 |
| Dodecahedron | 20 | 30 | 12 | 2 |
| Icosahedron | 12 | 30 | 20 | 2 |

The tetrahedron and cube are current comparison objects. This table is not a claim that all five are placed. For these sphere-topology boundaries the Euler characteristic is 2. A toroidal boundary has a different value. Triangulating a square by inserting a diagonal raises both E and F by one, preserving the characteristic.

The condition on a convex regular vertex is that its incident face angles sum to less than 360 degrees. Three, four or five equilateral triangles; three squares; or three regular pentagons give the five possible local patterns. These statements concern convex regular polyhedra, not every folded arrangement of faces.

## Angular defect does not measure volume

For an ordinary polyhedral vertex, subtract the incident face angles from 360 degrees. A cube corner gives `360 - 3*90 = 90`; a regular tetrahedron corner gives `360 - 3*60 = 180`. Summing the defects over a closed convex polyhedron gives 720 degrees. Scaling a cube changes its volume while leaving those angles unchanged. The earlier tutorial's claim that this is where a solid “keeps its volume” was incorrect.

In a convex setting, zero defect marks a locally flat intrinsic neighborhood. It does not guarantee that an arbitrary folded embedding lies in one plane. Likewise, dragging unconstrained handles can produce crossing faces for which the original solid interpretation needs reconsideration.

## Measure a tetrahedron's volume separately

These reference calculations use lengths and positions:

```gdscript
func regular_tetrahedron_volume(edge_length: float) -> float:
    return pow(edge_length, 3) / (6.0 * sqrt(2.0))

func tetrahedron_volume(v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3) -> float:
    var a := v1 - v0
    var b := v2 - v0
    var c := v3 - v0
    return absf(a.dot(b.cross(c))) / 6.0
```

The first assumes a regular tetrahedron and a nonnegative edge length. The second handles four arbitrary positions and gives zero when they are coplanar. Neither is installed as a readout in this hall.

## Scope of verification

The [wedge-grid-route trial](../../../doc/book/iterations/2026-10-17-wedge-grid-route/index.html) uses the real museum, floor rays and the native CharacterBody walker to measure the three-metre side passages and check both detours around the bank, side-ramp ascents, the landing, descent, blocked flat bypasses and continued access to the rock room and exit. Rendered captures record the signs and corridors. Earlier alignment and desktop/XRTools pickup checks remain in the primitive-encounters trial. Headset comfort, Quest performance and unprompted recognition of the route remain wearer checks.
