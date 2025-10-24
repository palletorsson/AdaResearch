# InfoBoards TODO - Next Session

## ✅ Completed This Session

### Content
- ✅ Rewrote Triangle slides (5) - made concise and axiomatic
- ✅ Added Quad board (3 slides) - four points, triangulation, topology
- ✅ Added Cube board (3 slides) - six faces, wireframe, collision
- ✅ Added Sphere board (3 slides) - equidistant points, tessellation, normals
- ✅ Added Cylinder board (3 slides) - two circles, caps/sides, segments
- ✅ Rewrote Torus board (4 slides) - two radii, ring segments, radial segments, tessellation
- ✅ Updated progression array in JSON to include new boards

### Visualizations Created
- ✅ QuadVisualizationControl.gd/.tscn (basic_quad, quad_triangulation, quad_topology)
- ✅ CubeVisualizationControl.gd/.tscn (basic_cube, cube_wireframe, cube_collision)
- ✅ SphereVisualizationControl.gd/.tscn (basic_sphere, sphere_tessellation, sphere_normals)
- ✅ CylinderVisualizationControl.gd/.tscn (basic_cylinder, cylinder_parts, cylinder_segments)
- ✅ TorusVisualizationControl.gd/.tscn (basic_torus, torus_ring_segments, torus_radial_segments, torus_tessellation)
- ✅ CoordinateSystemVisualizationControl.gd/.tscn (origin, axes, handedness, positions)

### Scale Configuration
- ✅ All visualizations scale at 1.3x (configured in UniversalInfoBoard.gd:311)

## ⚠️ CRITICAL ISSUE TO ADDRESS

### Vectors Board Visualization Mismatch
**Location:** `commons/infoboards_3d/boards/Vectors/VectorsVisualizationControl.gd`

**Problem:**
- The JSON content for "vectors" board has 5 slides about basic vector concepts:
  - vectors_1: Vector duality (position vs direction)
  - vectors_2: Vector subtraction (B - A)
  - vectors_3: Magnitude/length (.length())
  - vectors_4: Normalization (.normalized())
  - vectors_5: Line definition (point + direction)

- BUT the existing VectorsVisualizationControl.gd file contains:
  - Physics simulation with particles, forces, velocity_trails, field_vectors
  - Appears to be for a "forces" board, not basic vector concepts

**Resolution Needed:**
1. Check if existing Vectors visualizations are actually for the "forces" board
2. Either:
   - Create NEW visualizations for basic vector concepts (duality, subtraction, magnitude, normalization, line_definition)
   - OR move existing Vectors visualizations to Forces board and create new ones for Vectors

**Note:** The JSON already has good pedagogical content for Vectors - it just needs matching visualizations.

## 🧪 Testing Required

### 1. Test All New Boards Load
Run `test_universal_infoboard_2d.tscn` and verify:
- ✓ Can navigate through all slides (not just up to triangle)
- ✓ Coordinate System slides display correctly
- ✓ Point slides display correctly
- ✓ Vectors slides display (but may have wrong visualizations - see issue above)
- ✓ Line slides display correctly
- ✓ Triangle slides display with new concise text
- ✓ Quad slides display with visualizations
- ✓ Cube slides display with visualizations
- ✓ Sphere slides display with visualizations
- ✓ Cylinder slides display with visualizations
- ✓ Torus slides display with visualizations

### 2. Test Map JSON Invocation
Test that boards can be spawned via map JSON:
```
ib:coordinate_system
ib:point
ib:vectors
ib:line
ib:triangle
ib:quad
ib:cube
ib:sphere
ib:cylinder
ib:torus
```

### 3. Verify HandheldInfoBoard Integration
Test that boards display correctly in VR with:
- Screen glow working
- Screen lid hides when player approaches
- Text is readable (font size 18, outline size 8)
- Visualizations scale properly (1.3x)

## 📋 Current Progression Order

From `_meta.progression` in infoboard_content.json:
1. coordinate_system (order 0)
2. point (order 1)
3. vectors (order 2) ⚠️ NEEDS VISUALIZATION FIX
4. line (order 3)
5. triangle (order 3)
6. quad (order 4)
7. cube (order 5)
8. sphere (order 6)
9. cylinder (order 7)
10. torus (order 8)
11. primitives
12. transformation
13. color
14. arrays
15. vectors (duplicate?)
16. forces
17. unitcircle
18. randomwalk
19. procedural_generation

## 📁 File Locations

### JSON Content
`commons/infoboards_3d/content/infoboard_content.json`

### Visualization Directories
```
commons/infoboards_3d/boards/
├── CoordinateSystem/
│   ├── CoordinateSystemVisualizationControl.gd
│   └── CoordinateSystemVisualizationControl.tscn
├── Point/
│   ├── PointVisualizationControl.gd
│   └── PointVisualizationControl.tscn
├── Vectors/  ⚠️ CONTAINS PHYSICS STUFF, NOT BASIC VECTOR CONCEPTS
│   ├── VectorsVisualizationControl.gd (WRONG CONTENT)
│   └── VectorsVisualizationControl.tscn
├── Line/
│   ├── LineVisualizationControl.gd
│   └── LineVisualizationControl.tscn
├── Triangle/
│   ├── TriangleVisualizationControl.gd
│   └── TriangleVisualizationControl.tscn
├── Quad/
│   ├── QuadVisualizationControl.gd (NEW)
│   └── QuadVisualizationControl.tscn (NEW)
├── Cube/
│   ├── CubeVisualizationControl.gd (NEW)
│   └── CubeVisualizationControl.tscn (NEW)
├── Sphere/
│   ├── SphereVisualizationControl.gd (NEW)
│   └── SphereVisualizationControl.tscn (NEW)
├── Cylinder/
│   ├── CylinderVisualizationControl.gd (NEW)
│   └── CylinderVisualizationControl.tscn (NEW)
└── Torus/
    ├── TorusVisualizationControl.gd (NEW)
    └── TorusVisualizationControl.tscn (NEW)
```

## 🎯 Priority Tasks for Tomorrow

1. **HIGH PRIORITY:** Fix Vectors board visualization mismatch
2. **HIGH PRIORITY:** Test all boards load in test scene
3. **MEDIUM:** Test map JSON invocation
4. **LOW:** Consider if other boards (Arrays, Forces, Wave, UnitCircle) need JSON migration

## 💡 Notes

- All new visualizations follow the same pattern as Point/Line/Triangle
- All use 2D drawing with animations
- All include grid backgrounds, labels, and info text
- Text rendering: font_size=18, outline_size=8, cyan glow
- Visualization scale: 1.3x (set in UniversalInfoBoard.gd:311)
- UniversalInfoBoard system working well - single template loads all boards from JSON
