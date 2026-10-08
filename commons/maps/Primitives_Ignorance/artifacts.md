# Primitives Ignorance — current artifacts

Updated 6 October 2026. The original footprint and side alcove remain; 28 placements, including the resolution monitor and final moon-court installation. Coordinates are (column,row) grid indices. The installation tokens below contain multiple constituent meshes.

## Primary route

`sphere` → `geometry_courtyard` → `sphere_high` → `sphere_mid` → `sphere_low` → `sphere_resolution_atlas` → `budget_of_smoothness` → `capsule_reliquary`.

One ordinary sphere precedes the five-solid courtyard. The second room holds six existing sphere specimens, twelve new independent subdivision examples, the counter, and the enlarged original capsule. The eight-prefab library now occupies Primitives_Godot with the choir. Fifteen older secondary/decorative placements remain in the side alcove. The final court holds the moon torus and a hanging point catalyst, with its instructions beside it near the approach.

## Every placement

| Cell | Artifact | Role | Full placement string |
| --- | --- | --- | --- |
| (6,2) | `sphere` | primary | `sphere:0:0#plinth:0.75` |
| (9,6) | `geometry_courtyard` | primary | `geometry_courtyard:0:0#plinth:0` |
| (1,16) | `resolution_reveal_monitor` | primary | `resolution_reveal_monitor:90:0#plinth:0#pin:1` |
| (13,18) | `sphere_high` | primary | `sphere_high:0:0#plinth:0.70#offset:0.00,0.00,0.00#inspection:1#inspection_edges:1` |
| (16,18) | `sphere_high` | primary | `sphere_high:0:0#plinth:0.70#offset:0.00,0.00,0.00#inspection:1#inspection_edges:0` |
| (3,21) | `sphere_resolution_atlas` | primary | `sphere_resolution_atlas:0:0#plinth:0` |
| (13,21) | `sphere_mid` | primary | `sphere_mid:0:0#plinth:0.70#offset:0.00,0.00,0.00#inspection:1#inspection_edges:1` |
| (16,21) | `sphere_mid` | primary | `sphere_mid:0:0#plinth:0.70#offset:0.00,0.00,0.00#inspection:1#inspection_edges:0` |
| (9,22) | `capsule_reliquary` | primary | `capsule_reliquary:0:0#plinth:0` |
| (13,24) | `sphere_low` | primary | `sphere_low:0:0#plinth:0.70#offset:0.00,0.00,0.00#inspection:1#inspection_edges:1` |
| (16,24) | `sphere_low` | primary | `sphere_low:0:0#plinth:0.70#offset:0.00,0.00,0.00#inspection:1#inspection_edges:0` |
| (9,26) | `budget_of_smoothness` | primary | `budget_of_smoothness:180:0#discovery:1#plinth:0` |
| (19,30) | `dark_sphere` | decoration | `dark_sphere:0:-0.5` |
| (21,30) | `cube_scene` | secondary | `cube_scene:0:-0.5#offset:0.00,0.45,0.00#plinth:0.10` |
| (23,30) | `dark_sphere` | decoration | `dark_sphere#body:cairn` |
| (25,30) | `primitive_pillar` | secondary | `primitive_pillar` |
| (19,33) | `science_screen` | secondary | `science_screen#surface:tiles` |
| (21,33) | `star_primitive` | secondary | `star_primitive:90:0#plinth:0.90` |
| (23,33) | `cube_scene` | secondary | `cube_scene#grain:quartered` |
| (25,33) | `hole_with_cones` | secondary | `hole_with_cones:0:-0.5` |
| (9,35) | `form_in_hand` | primary | `form_in_hand:0:0#plinth:0` |
| (21,36) | `truncatedtetrahedron` | secondary | `truncatedtetrahedron:0:0#plinth:0.90` |
| (23,36) | `cylinder_radials_rings` | secondary | `cylinder_radials_rings` |
| (25,36) | `grab_octahedron` | secondary | `grab_octahedron:0:0#plinth:0.90` |
| (19,39) | `snap_octahedron_puzzle` | secondary | `snap_octahedron_puzzle:0:0.5#fillhole:remove` |
| (21,39) | `diamonds` | secondary | `diamonds#scale:0.12#plinth:0.45` |
| (23,39) | `roughrock` | secondary | `roughrock:0:0#plinth:0.90` |
| (25,39) | `righttriangle` | secondary | `righttriangle:0:0#plinth:0.90` |

## What the installation tokens contain

- `form_in_hand`: a torus five metres above the floor, two rings/segments comparison spheres, and the black point catalyst at 1.45 m. Hold the point to reduce its SphereMesh rings/segments from 16/32 to the valid minimum 1/4. Trigger sends an independent copy of the current form; release returns and resets the point after two seconds. Its small guide and live counts share the display stand. Placement and interactions were checked in the actual museum; headset comfort remains a playtest.
- `geometry_courtyard`: one tetrahedron, cube, octahedron, dodecahedron and icosahedron, all pickable. Sixteen columns use 4, 5, 6, 8, 12, 20, 32 and 64 radial segments. The motto belongs to its entrance plaque.
- `sphere_resolution_atlas`: twelve fixed spheres, crossing radial segments [4,8,16,32] and rings [1,4,12]. Actual triangle-edge overlays remain visible.
- `capsule_reliquary`: the original five-segment/five-ring CapsuleMesh at 1.6 times size, turning at 45 degrees per second. Eight solid tiers, radial resolutions 4 through 11.

The old 75-body `platonic_grabbables` scene remains in the project but is replaced in this map by five individual source meshes. The old capsule placement is replaced by its enlarged installation; the source scene remains unchanged. The side alcove preserves the rock, star, extra cubes, puzzle, cylinder display, pillar, science screen, truncated tetrahedron and other studies. The choir joins the mesh library in [Primitives_Godot](../Primitives_Godot/artifacts.md). Its diamond tower alone receives a room-local 0.12 scale and 0.45 m support.

Existing high/middle/low sphere pairs keep their mesh, inspection, edge-overlay and material settings. The counter retains independent count/edge controls and fixed samples. The earlier 28-placement loading check predates this relocation. `budget_of_smoothness` stays here; `seven_words_choir` moves to Godot. Their registry support remains; the new placement context belongs to the separate route integration check.

Unplaced historical role entries remain available as history; they are not counted above. See technical.md for geometry and test limits.
