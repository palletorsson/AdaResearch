# Iter 3 — sofa WALL + crystalcluster PROMOTED (composition with caveat)

**Two candidates this turn:**

## sofa → WALL
The sofa is a 16-vertex carved cube with asymmetric inset (vertices at x=-0.144, z=0.022). It's NOT a clean stack of axis-aligned BoxMesh — the cut creates a seat surface that needs precise non-axis-aligned geometry. A 2-3 box approximation would lose the seat detail.

**Filed as WALL.** Carved-cube shapes need either CSG (Boolean operations) or hand-coded vertex arrays. The genome's box-composition mode doesn't reach here.

## crystalcluster → PROMOTED (with documented limitation)
5 hexagonal prisms = 5× `CylinderMesh(radial_segments=6, top_radius<bottom_radius, height=...)`. Each tapers slightly at the top to form a crystalline tip.

**Spec:** `commons/primitives/promoted/_specs/crystalcluster_v2.compose.json`
**Capture:** clean cluster of 5 blue-tipped hex columns, varying sizes, spread positions.

**LIMITATION:** Original randomly rotates each crystal in 3D, giving a "natural cluster" feel. Current compose renderer only handles `position` (not `rotation_degrees`). Result is upright cluster — silhouette right, dynamic-tilted feel lost. Adding rotation support to compose mode is a small extension (~15 min) when needed.

## Net for this iteration

- 1 PROMOTED (crystalcluster_v2, with rotation limitation)
- 1 WALL (sofa — carved-cube needs CSG)

Both are useful data: the wall maps where box-composition fails, the limitation maps where compose mode needs to grow next.
