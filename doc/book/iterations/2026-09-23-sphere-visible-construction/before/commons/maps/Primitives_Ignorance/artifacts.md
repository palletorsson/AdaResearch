# Primitives Ignorance — current artifacts

Reviewed against map_data.json and artifact_roles.json on 2026-09-16. Twenty-six placements remain, with six primary artifact types. Coordinates are (column,row) grid indices, not world metres.

## Primary order

`sphere` → `sphere_high` → `sphere_mid` → `sphere_low` → `budget_of_smoothness` → `capsule`.

The ordinary sphere begins near the entrance. The three resolution pairs follow their existing order at rows 11, 13 and 15. The text then explicitly returns to the counter at (5,9). Then the capsule at (0,16) makes the missing half-turn symmetry a main encounter before the exit. Nine physical placements carry these six primary types. The Academy motto remains a text utility at (4,9), not an invented extra artifact.

## Every placement

| Cell | Artifact | Role | Full placement string |
| --- | --- | --- | --- |
| (1,1) | `dark_sphere` | decoration | `dark_sphere:0:-0.5` |
| (2,1) | `cube_scene` | secondary | `cube_scene:0:-0.5#offset:0.00,0.45,0.00#plinth:0.10` |
| (3,1) | `sphere` | primary | `sphere:0:-0.5` |
| (11,3) | `dark_sphere` | decoration | `dark_sphere#body:cairn` |
| (6,4) | `platonic_grabbables` | secondary | `platonic_grabbables:0:0` |
| (5,9) | `budget_of_smoothness` | primary | `budget_of_smoothness:180:0#discovery:1#plinth:0` |
| (10,9) | `primitive_pillar` | secondary | `primitive_pillar` |
| (10,10) | `science_screen` | secondary | `science_screen#surface:tiles` |
| (3,11) | `sphere_high` | primary | `sphere_high:0:0#plinth:0.10#offset:0.00,0.60,0.00#inspection:1#inspection_edges:1` |
| (5,11) | `sphere_high` | primary | `sphere_high:0:0#plinth:0.10#offset:0.00,0.60,0.00#inspection:1#inspection_edges:0` |
| (1,12) | `star_primitive` | secondary | `star_primitive:90:0#plinth:0.90` |
| (10,12) | `cube_scene` | secondary | `cube_scene#grain:quartered` |
| (3,13) | `sphere_mid` | primary | `sphere_mid:0:0#plinth:0.10#offset:0.00,0.60,0.00#inspection:1#inspection_edges:1` |
| (5,13) | `sphere_mid` | primary | `sphere_mid:0:0#plinth:0.10#offset:0.00,0.60,0.00#inspection:1#inspection_edges:0` |
| (8,13) | `hole_with_cones` | secondary | `hole_with_cones:0:-0.5` |
| (10,13) | `seven_words_choir` | secondary | `seven_words_choir` |
| (0,14) | `truncatedtetrahedron` | secondary | `truncatedtetrahedron:0:0#plinth:0.90` |
| (10,14) | `cylinder_radials_rings` | secondary | `cylinder_radials_rings` |
| (3,15) | `sphere_low` | primary | `sphere_low:0:0#plinth:0.10#offset:0.00,0.60,0.00#inspection:1#inspection_edges:1` |
| (5,15) | `sphere_low` | primary | `sphere_low:0:0#plinth:0.10#offset:0.00,0.60,0.00#inspection:1#inspection_edges:0` |
| (0,16) | `capsule` | primary | `capsule:0:0#plinth:0.90` |
| (3,17) | `grab_octahedron` | secondary | `grab_octahedron:0:0#plinth:0.90` |
| (5,17) | `snap_octahedron_puzzle` | secondary | `snap_octahedron_puzzle:0:0.5#fillhole:remove` |
| (7,18) | `diamonds` | secondary | `diamonds` |
| (3,19) | `roughrock` | secondary | `roughrock:0:0#plinth:0.90` |
| (4,19) | `righttriangle` | secondary | `righttriangle:0:0#plinth:0.90` |

## Reading the configurations

The sphere-pair defaults are high: 16 rings/16 radial segments; middle: 7/7; low: 1/10. Each pair has identical sphere geometry with opposite edge-overlay visibility in inspection mode. The counter's two buttons reveal counts and edges independently; they do not resize or release its samples.

The former inventory listed floating_sphere_field, lshape, prism_block, library_rack, torus_radials_rings, capsule_radials_rings and plus. Those tokens are not current interactable placements in this room. Unplaced historical role rulings and rack configuration files have been preserved; they are not counted as current exhibits.

The capsule retains its authored five radial segments, five rings and 45-degree-per-second rotation. No geometry or control changes accompany its promotion.

The regular solids, octahedron, truncated tetrahedron, star, rock and other supporting works remain secondary. Their useful comparisons are retained in tutorial.md. The two dark-sphere placements remain decoration.
