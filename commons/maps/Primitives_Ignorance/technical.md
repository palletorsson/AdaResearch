# Sphere names, mesh counts and visible differences

Point_Animatedcube separated vertex positions from connectivity and presentation. This hall keeps those distinctions available while examining the sphere. Its route now passes an ordinary sphere and the five-solid courtyard, then the existing sphere pairs and a twelve-sphere atlas, the counting counter, the central five-segment capsule, and the additional engine mesh prefabs. Sixteen older placements remain in a side alcove.

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

The counter now stands at (9,26), facing back into the second room. The three pairs occupy columns 13 and 16 at rows 18, 21 and 24. Their requested support is 0.70 m with no extra vertical offset. The former 0.10 m support plus 0.60 m offset has been consolidated; the new plain block honors the requested height.

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

The installed `commons/primitives/capsule/capsule.tscn` authors a CapsuleMesh with radius 0.25, height 1.0, five radial segments and five rings. The root script defaults to `facture = "cast"`, which leaves this mesh unchanged. The reliquary instantiates this scene without a facture override, gives the visible mesh an off-black material, and scales it uniformly by 1.6. Its bottom sits at the 1.04 m top of eight 0.13 m cylinder tiers, with radial segments 4 through 11. The original rotation script remains inside the source scene. The capsule has no pickup or collider; the solid support prevents walking through its base. Its child uses `commons/primitives/prismes/rotation.gd`, with angular speed `(0,45,0)` degrees per second.

The straight middle has a regular pentagonal cross-section. Its equal angular intervals are 72 degrees. A 72-degree rotation preserves the cross-section's corners; a 180-degree rotation does not. Opposite a corner's radial direction is a side midpoint. The absent half-turn symmetry should not be described as total asymmetry or as an inability to infer the back from the full generative rule.

The capsule supplies a second limit: a familiar name or an assumed front/back correspondence does not specify the unseen side. The constraints generate an inspectable form between what "rounded pill" suggests and what these facets actually do. "Transcendental inside restrictions" is Palle's research formulation for exceeding an expectation within a generative system, not an additional property measured by the mesh API.

A direct Godot mesh measurement is archived at `doc/space/ignorance-focus-2026-09-16/capsule-return/`. It extracts a ring from the actual authored mesh, tests the 72-degree and 180-degree rotations, and compares a six-segment copy as a control. This verifies cross-section geometry, not visual legibility in the room.

## Sources and checks

- `commons/primitives/godotmeshes/sphere_low.gd`, `sphere_mid.gd`, `sphere_high.gd`
- `commons/primitives/shared/mesh_inspection.gd`
- `commons/artifacts/budget_of_smoothness/budget_of_smoothness.gd`
- `commons/maps/Primitives_Ignorance/map_data.json`
- `commons/testing/probe_ignorance_primary.gd`

The probe exercises pointer events, reads actual mesh arrays, compares paired vertex/index buffers and stamps the configured counter through the museum loader. Full-room distances, hand reach and headset legibility remain to be checked. Primitives_Godot, Primitives_Columns and Primitives_Profiles now follow this hall before Primitives_Portals develops the distinction between finite approximations and a mathematical limit.

## Shared sphere figure

The book comparison loads the actual `sphere_high`, `sphere_mid` and `sphere_low` scenes, applying the six inspection configurations read from this map. It retains their generated geometry, normals and inspection materials. The book layout changes only their arrangement, with equal scale, viewpoint and lighting across the pairs. These are the existing museum exhibits; there is no new museum plate or additional control.

`tools/capture_sphere_resolution.py` stages a private Godot project and checks the paired position, index and normal arrays, material colours, orientation and overlay visibility before rendering. The measured submitted / area-bearing counts are 544 / 512, 112 / 98 and 40 / 20, in finer-to-coarser order. These are the full-size exhibits, not the four smaller counter samples listed above.


## Courtyard, independent subdivisions and reusable mesh scenes — 27 September 2026

Relocation note, 4 October: the mesh library and seven-form choir now belong to Primitives_Godot. The source mechanisms below are retained; the earlier placement and verification evidence describes the prior arrangement.

`geometry_courtyard` uses meshes from the existing tetrahedron, cube, octahedron, dodecahedron and icosahedron source scenes. There is one of each, normalized to a maximum dimension of 0.88 m, with an unscaled RigidBody and a convex collider generated from the scaled source vertices. All use the production XRTools pickup path. The sixteen cylinder columns use eight radial resolutions twice: 4, 5, 6, 8, 12, 20, 32, 64. The inscription sits above the entrance with clear headroom.

`sphere_resolution_atlas` crosses radial segments [4, 8, 16, 32] with rings [1, 4, 12]. Each sphere has radius 0.39 m and height 0.78 m; the shared inspection helper draws its actual triangle edges. These twelve constructions supplement the six existing paired specimens.

`primitive_mesh_library` instantiates eight separate `.tscn` prefabs in `commons/artifacts/ignorance_gallery/prefabs/`. The resource classes are PrismMesh, TorusMesh, PlaneMesh, QuadMesh, PointMesh, TextMesh, RibbonTrailMesh and TubeTrailMesh. They extend the earlier box, cylinder, capsule and sphere selection. There is no ConeMesh class: CylinderMesh supplies that shape through unequal end radii. QuadMesh is a PlaneMesh subclass. The PointMesh uses a 22-pixel point material; its screen extent is not a metre measurement. Both trail examples display undeformed rest geometry, not particle animation. The additional prefabs are fixed viewing exhibits, now in Primitives_Godot. The five Platonic solids remain pickable in Ignorance.

After the choir relocation, the alcove keeps fifteen earlier secondary/decorative placements. `diamonds` uses a room-local scale of 0.12 and a 0.45 m support, retaining twelve units and their twist. Its original scene remains unchanged elsewhere.

## Shared museum support

StationPlinth, its wide variant and its micropod now default to `presentation = "museum"`: one matte off-white box with a matching collider, no ornamental trim or lights. Requested top height is honored down to 0.02 m. Captions and information lines remain as plain type. `presentation = "industrial"` retains the prior authored workshop variants. Automatic low broad supports now use the same plain family; automatic minimum lift remains 0.25 m, while explicit lower decks are honored. Architectural podium/plinth material roles use the same off-white finish. The capsule's resolution tiers are deliberately part of the exhibit, not generic furniture.

The room's new courtyard and two walk-through collections do not seal their entire bounding rectangles in the museum's path map. Their individual colliders govern passage. The capsule's compact footprint uses normal sealing. The main rooms remain 19 cells wide; the retained side alcove extends total width to 27, an intentional exception to the sequence template's 19-cell width preference.

Native evidence, photographs, code and scope notes: [courtyard review](/book-review/doc/book/iterations/2026-09-27-ignorance-courtyard/index.html). Desktop geometry and supplied pickup are tested; headset targeting, label legibility and Quest performance still need an in-headset visit.
