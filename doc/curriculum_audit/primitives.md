# Primitives — Curriculum Audit

**Sequence ID:** `primitives`
**Spine order:** 1
**Maps:** 13
**Evolutions written:** 3 (Point_One, Point_Line, Point_Lines)

## 1. Core Concept

The atomic units of geometry — the vocabulary a body needs before it can reason about space. Position, relation, direction, area, closure, coordinate system. Each map introduces one new structural element and shows both what it can encode and what it cannot.

## 2. The Red Thread

1. **Position** (Point_Zero → Point_One)
   - A location in space, three floats, discrete address
   - Captures: where
   - Leaks: duration, relation, size, identity, continuity

2. **Relation** (Point_Line)
   - Distance and direction between two positions
   - Captures: measurement, between-ness
   - Leaks: curvature, thickness, meaning, multiplicity

3. **Trace** (Point_Trace)
   - Position accumulated over time
   - Captures: history, path, memory
   - Leaks: why the path, not just that it happened

4. **Multiplicity** (Point_Lines)
   - Many lines in dialogue — crossings, parallels, constraints
   - Captures: perpendicularity (dot product = 0), parallelism, construction from atoms
   - Leaks: Euclidean assumption, exact orthogonality, static rigidity

5. **Grid** (Point_Line_Grid)
   - Regular multiplicity — indexable space
   - Captures: addressability, uniform division
   - Leaks: the politics of choosing a grid, what gets erased

6. **Closure** (Point_Triangle)
   - Three points make a bounded region
   - Captures: area, polygon, interior/exterior
   - Leaks: curved boundaries, fractal boundaries, what's inside really

7. **Polygon** (Point_Polygon) — MAP MISSING
   - N-sided closed shape
   - Captures: regular/irregular, convex/concave, vertex-edge duality
   - Leaks: smooth curves require limit-taking

8. **Circle** (Point_Circle) — MAP MISSING
   - Infinite-vertex polygon, constant radius locus
   - Captures: continuity, 2π, radian
   - Leaks: circles are idealizations; real circles have thickness

9. **Coordinate System** (Point_Coordinate_System) — MAP MISSING
   - Named axes with orientation
   - Captures: origin, orthogonal basis, handedness
   - Leaks: coordinate systems are chosen, not given; non-Cartesian systems exist

10. **Pattern & Gallery** (MANN_Gallery_Museum, Grand_Pattern_Museum, Pattern_Showcase)
    - Primitives arranged into decorative / mosaic / wallpaper patterns
    - Captures: symmetry groups, repetition, tiling
    - Leaks: patterns teach symmetry but not why symmetry matters (graph theory, group theory)

11. **Chamber** (Chamber_Primitives)
    - The catalyst chamber — where all primitives concepts integrate
    - Captures: synthesis, QFEP connection, narrative closure
    - Leaks: transitions to the next sequence (transformation)

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | Point_One | Position | interactive_point_origin | Evolution ✓ |
| 2 | Point_Line | Relation | line | Evolution ✓ |
| 3 | Point_Lines | Multiplicity | plus_line_puzzle | Evolution ✓ |
| 4 | Point_Trace | Trace | draw_dot | Needs evolution |
| 5 | Point_Line_Grid | Grid | grid_lines | Needs evolution |
| 6 | Point_Triangle | Closure | triangle | Needs evolution |
| 7 | Point_Polygon | Polygon | — | MAP MISSING |
| 8 | Point_Circle | Circle | — | MAP MISSING |
| 9 | Point_Coordinate_System | Coordinate System | — | MAP MISSING |
| 10 | MANN_Gallery_Museum | Pattern (museum 1) | floor_plan_space | Needs evolution |
| 11 | Grand_Pattern_Museum | Pattern (museum 2) | library_rack | Needs evolution |
| 12 | Pattern_Showcase | Pattern (showcase) | floor_plan_space | Needs evolution |
| 13 | Chamber_Primitives | Chamber | becoming_catalyst | Needs evolution |

## 4. Artifact Inventory

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Position | interactive_point_origin | commons/primitives/point/interactive_point_origin.gd | ✓ works |
| Position (slider variant) | xyz_slider_plate | commons/primitives/point/xyz_slider_plate.gd | ✓ new |
| Relation | line | commons/primitives/line/line.gd | ✓ works |
| Relation (grabbable) | grabbable_line | commons/primitives/line/grabbable_line.gd | ✓ new |
| Relation (demo) | line_demo | commons/primitives/line/line_demo.gd | ✓ minimal (29 lines) — could be richer |
| Relation (vector) | vectorline | commons/primitives/line/vectorline.gd | ✓ |
| Trace | draw_dot | commons/primitives/point/draw_dot.gd | ✓ (454 lines) |
| Trace (player) | player_trace | found | ✓ |
| Grid | grid_lines | found | ✓ |
| Grid (snap) | grab_sphere_point_snap | found | ✓ |
| Multiplicity (puzzle +) | plus_line_puzzle | commons/primitives/line/puzzles/plus_line_puzzle.gd | ✓ |
| Multiplicity (puzzle ∥) | parallel_line_puzzle | commons/primitives/line/puzzles/ | ✓ |
| Multiplicity (perspective) | perspective_lines | commons/primitives/line/perspective_lines.gd | ✓ |
| Multiplicity (scale) | scale_lines | commons/primitives/line/ | ✓ |
| Multiplicity (laser) | lightrod, laser_sword | commons/primitives/line/ | ✓ new laser_sword |
| Closure | triangle | found | ✓ (252 lines) |
| Closure (puzzle) | triangle_line_puzzle | found | ✓ |
| Closure (profile) | triangleprofiles | found | ✓ |
| Closure (decorative) | parasol_triangle | found | ✓ |
| Polygon | — | — | **MISSING** |
| Circle | — | — | **MISSING** |
| Coordinate System | CoordinateSystem3M | (in Point_One) | ✓ but map missing |

## 5. Gap Analysis

### Missing Maps (High Priority)
- **Point_Polygon** — no map_data.json. Polygon is the natural next step after triangle.
- **Point_Circle** — no map_data.json. Circle is the limit of polygon as n→∞.
- **Point_Coordinate_System** — no map_data.json. The framework that makes all preceding concepts addressable.

### Missing Artifacts (Medium Priority)
- **Polygon primitive** — needs a configurable n-gon artifact with vertex/edge count slider
- **Circle primitive** — needs a circle artifact showing radius, circumference, 2πr
- **Coordinate system artifact** — CoordinateSystem3M exists but needs a richer demo

### Ordering Issues
Current order is mostly correct, but:
- The three Pattern museums (MANN, Grand, Showcase) feel like they belong in a later sequence (transformation? color?). Patterns introduce symmetry groups which are group theory, not primitives. Consider moving to a dedicated "patterns" sequence or into transformation.
- Chamber_Primitives is in the right place (end).

### Missing Transitions
- Point_Line_Grid → Point_Triangle: no bridge explaining why triangles are special (they're the simplest closed shape, the atom of meshes)
- Point_Triangle → Polygon/Circle: a bridge map showing triangle as "closure" and polygon as "generalized closure"

## 6. Forward Leaks

Concepts this sequence raises but cannot answer:
- **Curvature** → Wavefunctions (sine bends the line)
- **Thickness** → later primitives or soft bodies (mesh extrusion)
- **Meaning of edges** → Graph theory
- **Non-Euclidean space** → Foundations crisis
- **Transform** → Transformation sequence (next)
- **Identity persistence** → QFEP laboratory
- **Continuity** → Noise, cellular automata
- **Why symmetry matters** → Graph theory, wallpaper groups
- **Self-similarity** → Fractals
- **Time-varying position** → Forces, wave functions

## 7. Proposed Ordering

```
1. Point_One           — position, coordinate, embodiment
2. Point_Line          — relation, distance, direction
3. Point_Trace         — position over time (trace)
4. Point_Lines         — multiplicity, perpendicularity, parallels
5. Point_Line_Grid     — regular multiplicity, addressable grid
6. Point_Triangle      — closure, bounded region, area
7. Point_Polygon*      — generalized closure (MAP MISSING)
8. Point_Circle*       — limit of polygon (MAP MISSING)
9. Point_Coordinate_System* — the framework made explicit (MAP MISSING)
10. Chamber_Primitives — synthesis, catalyst

Move pattern museums out of this sequence:
- → transformation (they teach wallpaper groups = symmetry = transformation)
- OR create new sequence "patterns" between primitives and transformation
```

The current order puts pattern museums before Chamber, which is correct narratively (museum before resolution). But the three museum maps feel bolted on — they teach something different from the rest.

## Summary

Primitives is the strongest, most developed sequence. The concept flow is clean from Point_One through Point_Triangle. Three evolutions are written. The main gaps are:
1. Three missing maps (Polygon, Circle, Coordinate_System) that would complete the geometric vocabulary
2. Pattern museums feel misplaced — they belong elsewhere
3. Evolutions needed for: Point_Trace, Point_Line_Grid, Point_Triangle, Chamber_Primitives

This sequence is the template. It shows what a completed sequence looks like.
