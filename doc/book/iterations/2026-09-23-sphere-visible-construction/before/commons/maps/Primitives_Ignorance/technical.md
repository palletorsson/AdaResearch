# Sphere names, mesh counts and visible differences

Point_Animatedcube separated vertex positions from connectivity and presentation. This hall keeps those distinctions available while examining the sphere. Its primary encounters now follow the ordinary sphere near the entrance, the high, middle and low sphere pairs in their placed order, then a deliberate return to `budget_of_smoothness` at (5,9), followed by the five-segment capsule at (0,16). The other solids remain available as further comparisons.

## What the polygonal representation cannot retain

An analytic sphere is defined by a fixed distance from its centre. The finite surface mesh connects sampled positions with planar triangles. That triangle surface cannot coincide everywhere with the exact curved boundary. This is a limitation of the chosen representation; it is not a claim that code or mathematics cannot specify a sphere analytically.

Keep geometry, presentation and use distinct. Changing rings or radial segments changes the generated mesh. The inspection overlay changes how a fixed mesh is shown. Viewing distance and the observer's purpose change which of its features matter. The room's reference to Plato directs attention to those distinctions; its historical and interpretive sources are footnoted in final.md.

## Two directions of subdivision

First compare silhouettes from the same distance. The current default configurations are:

| Artifact | Rings | Radial segments |
|---|---:|---:|
| sphere_low | 1 | 10 |
| sphere_mid | 7 | 7 |
| sphere_high | 16 | 16 |

All three use radius 0.5 and height 1.0. Their scripts expose other configuration choices, but this room retains the defaults above. Rings and radial segments divide different directions of the surface. Their distribution matters as well as their quantity.

Each resolution is placed twice. The room adds `inspection:1` to both members and `inspection_edges:1` or `inspection_edges:0` to distinguish them. Their generated vertex and index arrays agree. The inspection mode supplies the same plain material to each pair and adds actual triangle-edge lines to one member.

The room-specific overlay is built from the mesh's index triples. It does not assume that `VERTEX_ID % 3` produces distinct barycentric coordinates for every indexed triangle; shared indices can violate that assumption. The shared inspection helper reads the indices explicitly. Existing non-inspection appearances remain available in other maps.

## Read the counter after choosing a use

The counter generates four smaller spheres with radius 0.26 and height 0.52. Their radial segment settings are 4, 8, 16 and 64; rings are `maxi(seg / 2, 2)`. They share material and spin rate. Counts and overlays start hidden under `#discovery:1`.

The two pointer/press buttons independently show or hide counts and edges. Revealing either leaves the original surface mesh resource unchanged. The spheres are fixed exhibits, not grabbable samples. Their stands raise them above the tilted labels.

The counter has moved from column 1 to the clear central cell at column 5, row 9, retaining one placement. Its three-metre-wide counter previously extended toward the room's side boundary. The new placement faces the earlier rows. Actual museum stamping is checked; full-room approach still needs a headset walk.

## Two triangle counts

Read the buffers of each generated sphere:

```gdscript
var arrays = mesh.surface_get_arrays(0)
var triangle_entries = arrays[Mesh.ARRAY_INDEX].size() / 3
```

This counts triangle entries, including collapsed entries at the poles. The helper also examines their positions:

```gdscript
if (b-a).cross(c-a).length_squared() < 1e-16:
    continue
```

The cross product is twice the triangle's oriented area vector. This squared-length tolerance excludes zero and tiny-area triangles in local coordinates. The label **with area** means triangles retained by that test, not a proof of exact nonzero area at arbitrary scale.

| Segments | Rings | Triangle entries | Retained by area test |
|---:|---:|---:|---:|
| 4 | 2 | 24 | 16 |
| 8 | 4 | 80 | 64 |
| 16 | 8 | 288 | 256 |
| 64 | 32 | 4,224 | 4,096 |

These values were measured from meshes produced by the project's Godot 4.6 runtime. The previous formula `2 * segments * rings` matched the area-bearing count in these examples. It did not include the collapsed pole entries in the index buffer. The updated counter exposes both descriptions.

An overlay is built from the three edges of each retained triangle. Shared edges may be drawn twice. It is slightly enlarged by a factor of 1.002 to reduce coplanar flicker. Overlay geometry, stands, screens and the counter itself are excluded from the sphere counts.

## A count does not measure the whole frame

The display inventories mesh geometry. It does not time the GPU, estimate headset frame rate or measure attention. Materials, screen coverage, lighting, shadows, batching and other running work affect performance too. Use the numbers to specify a design choice, then test its perceptual and runtime consequences separately.

The low-resolution form may preserve the distinctive outline a visitor wants to recognise. The high-resolution form may be useful for a closer inspection. Neither judgment follows automatically from an integer or from the name sphere.

## Five segments: a particular symmetry fails

The installed `commons/primitives/capsule/capsule.tscn` authors a CapsuleMesh with radius 0.25, height 1.0, five radial segments and five rings. The root script defaults to `facture = "cast"`, which leaves this mesh unchanged. The map has no facture override. Its child uses `commons/primitives/prismes/rotation.gd`, with angular speed `(0,45,0)` degrees per second.

The straight middle has a regular pentagonal cross-section. Its equal angular intervals are 72 degrees. A 72-degree rotation preserves the cross-section's corners; a 180-degree rotation does not. Opposite a corner's radial direction is a side midpoint. The absent half-turn symmetry should not be described as total asymmetry or as an inability to infer the back from the full generative rule.

The capsule supplies a second limit: a familiar name or an assumed front/back correspondence does not specify the unseen side. The constraints generate an inspectable form between what "rounded pill" suggests and what these facets actually do. "Transcendental inside restrictions" is Palle's research formulation for exceeding an expectation within a generative system, not an additional property measured by the mesh API.

A direct Godot mesh measurement is archived at `doc/space/ignorance-focus-2026-09-16/capsule-return/`. It extracts a ring from the actual authored mesh, tests the 72-degree and 180-degree rotations, and compares a six-segment copy as a control. This verifies cross-section geometry, not visual legibility in the room.

## Sources and checks

- `commons/primitives/godotmeshes/sphere_low.gd`, `sphere_mid.gd`, `sphere_high.gd`
- `commons/primitives/shared/mesh_inspection.gd`
- `commons/artifacts/budget_of_smoothness/budget_of_smoothness.gd`
- `commons/maps/Primitives_Ignorance/map_data.json`
- `commons/testing/probe_ignorance_primary.gd`

The probe exercises pointer events, reads actual mesh arrays, compares paired vertex/index buffers and stamps the configured counter through the museum loader. Full-room distances, hand reach and headset legibility remain to be checked. Primitives_Portals next develops the distinction between finite approximations and a mathematical limit.
