# Walkthrough Plan: Primitives Sequence

Autonomous evaluation of the first learning sequence — "Primitives: Points Build Worlds".

## The Loop

For each map:
1. Read `map_data.json` — know what's placed
2. Tell user to enter map → screenshot → see it
3. Compare: what IS here vs what SHOULD be here
4. Fix / build / skip — then move on

## Sequence Truth

> "A point is position without extension. Everything is built from nothing."

QFEP: F — stable foundations before entropy. Pure order.

Arc: point → line → triangle → polyhedra → motion → limits → portals

## Map-by-Map Plan

### 1. Point_One (7x10, 8 interactables)
**Teaching**: The origin. A single point. Position without extension.
**Has**: origin, static_point, interactive_point_origin, dark_sphere, CoordinateSystem3M, script_runner, folding_past, frame_counter_display
**Evaluate**: Does the student understand that a point is just (x,y,z)? Is the coordinate system visible and clear? Does the origin feel like "ground zero"?
**Likely**: Fine — mature map with good content density.

### 2. Point_Lines (7x27, 25 interactables)
**Teaching**: Two points make a line. Connection topology.
**Has**: line_demo, modulor_man_demo, line_builder_3d, parallel_line_puzzle, plus_line_puzzle, 25 total pieces
**Evaluate**: Rich map. Does the progression from single line → puzzles → Modulor Man make sense spatially? Is it too long (27 deep)?
**Likely**: Fine — very dense. Maybe check if puzzles are reachable.

### 3. Point_Trace (7x14, 5 interactables)
**Teaching**: Points in motion leave paths.
**Has**: dark_sphere, draw_dot, 3x cube_scene (fill holes)
**Evaluate**: Only 5 interactables — thin. Does "trace" come across? Is there a trail visualization? Should there be a player_trace artifact here?
**Risk**: May need content — player_trace exists in Point_Line_Grid but not here.

### 4. Point_Line_Grid (8x14, 4 interactables)
**Teaching**: Structured repetition. Grid as foundation.
**Has**: player_trace, grid_lines, dark_sphere, grab_sphere_point_snap
**Evaluate**: Very minimal (4 items). The grid concept is crucial — is grid_lines enough? Should there be more interactive elements?
**Risk**: May need a grid construction artifact or more visual density.

### 5. Point_Triangle (7x9, 5 interactables)
**Teaching**: Three points define a plane. The GPU's atom.
**Has**: triangle_line_puzzle, dark_sphere, cube_scene, triangle, triangleprofiles
**Evaluate**: Key transition moment — from 1D (lines) to 2D (triangles). Is the "aha" clear? Does the puzzle work?
**Likely**: Fine — focused map with clear purpose.

### 6. Point_Triangle_Context (7x12, 8 interactables)
**Teaching**: Triangles in context. Meshes begin.
**Has**: folded_strip, draw_triangle_faces, interactivetriangle, pythagorean_triangle_angles, quad_line_puzzle, quad
**Evaluate**: Nice breadth. Folded strip → drawn faces → interactive → Pythagorean → quad. Does the flow make spatial sense?
**Likely**: Good. Check if the Pythagorean triangle is positioned well.

### 7. Primitives_Polythedra (7x9, 7 interactables)
**Teaching**: 3D from triangles. Platonic solids emerge.
**Has**: grab_trihedron, snap_tetrahedron_puzzle, pyramid_edit, cube_scenes
**Evaluate**: The leap from triangle to tetrahedron to polyhedra. Is the snap puzzle working? Should there be more Platonic solids visible? The name "polythedra" (typo — should be "polyhedra"?).
**Risk**: Check if all 5 Platonic solids are represented.

### 8. Point_Animatedcube (7x14, 6 interactables)
**Teaching**: Primitives in motion. Animation from geometry.
**Has**: 4x animatedcubebuilder, polyhedron_nets_cube (folding)
**Evaluate**: Four animated cube builders — is that repetitive or does each show something different? The net-folding is great.
**Likely**: Fine — animated content is always engaging.

### 9. Primitives_Ignorance (9x27, 38 interactables)
**Teaching**: "Let no one ignorant of geometry enter here" — the full primitive catalog.
**Has**: platonic_grabbables, star, sphere variants, truncatedtetrahedron, plus 28 more
**Evaluate**: Museum/zoo map with 38 items. Is it overwhelming or well-organized? Are items labeled? Is there a guided path?
**Risk**: Large — may feel like a dumping ground. Check spatial organization.

### 10. Primitives_Portals (7x35, 3 interactables)
**Teaching**: Primitives as boundaries between spaces.
**Has**: capsule, combine_portals, dark_sphere
**Evaluate**: Very long (35 deep) but only 3 interactables. That's intentional — the journey IS the content. But is it too sparse?
**Risk**: The concept of "primitives as portals" is abstract. Does it land visually?

### 11. Primitives_Melencolia (7x14, 17 interactables)
**Teaching**: Dürer's Melencolia I — historical context of geometry.
**Has**: pyramids, cubes, prisms, snap_pyramid_puzzle, plus more
**Evaluate**: Art history meets geometry. Does it reference Dürer's engraving? Are the polyhedra arranged like in the artwork?
**Likely**: Capstone map — should feel conclusive.

## Evaluation Criteria

For each map, score:

| Criterion | Question |
|-----------|----------|
| **Ontological** | Does this teach what the sequence promises? |
| **Spatial** | Is the layout walkable and readable in VR? |
| **Density** | Too sparse? Too cluttered? |
| **Flow** | Does it lead naturally to the next map? |
| **Interactivity** | Can the student DO something, not just look? |
| **Labels** | Are things named/explained? Clipboards? |

## When to Skip vs Fix vs Build

- **Skip**: Map scores well on all criteria → screenshot, note "looks good", move on
- **Fix**: Layout issue, missing utility, bad spacing → edit map_data.json
- **Build**: Missing concept that should exist → create artifact, test desktop, deploy

## Blogging

After each map, write a short entry to `doc/WALKTHROUGH_LOG.md`:

```markdown
## Point_One — ✅ Good
Screenshot shows clear origin with coordinate axes. Student can grab the
point and see coordinates update. The dark_sphere anchors the space.
No changes needed.

## Point_Trace — ⚠️ Needs work
Only 5 interactables, feels sparse. Added player_trace artifact to show
motion trails. Screenshot before/after attached.
```

## Deployment

1. Edit map_data.json → save
2. If new artifact needed: create .gd + .tscn + registry entry → test with Godot CLI capture
3. Build APK: `C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe --export-release Android`
4. Upload: `adb install -r build.apk`
5. User enters map → screenshot → verify
