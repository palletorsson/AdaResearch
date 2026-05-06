extends Node

var text = '''[center][font_size=28][b]Delaunay Triangulation[/b][/font_size][/center]
[center][i]Optimal Triangulation, Circumcircle Property, Voronoi Dual[/i][/center]

**Delaunay triangulation connects points to form "nice" triangles.**

**Property:** No point inside any triangle's circumcircle (circle through 3 vertices).

**Result:** Maximizes minimum angle (avoids sliver triangles).

[hr]

[b]Algorithm[/b]

**Bowyer-Watson:**
1. Start with super-triangle (contains all points)
2. For each point:
   - Find triangles whose circumcircle contains point
   - Remove those triangles (creates polygonal hole)
   - Re-triangulate hole from new point
3. Remove super-triangle edges

[color=yellow][b]Properties:[/b][/color]
- **Dual of Voronoi** diagram
- **Unique** for non-degenerate point sets
- **Maximizes minimum angle** (quality mesh)

[hr]

[b]Applications[/b]

- **Mesh generation** (FEM, rendering)
- **Terrain interpolation** (height from sample points)
- **Path planning** (navmesh)
- **Proximity graphs** (nearest neighbors)

[hr]

[b]Queer Delaunay[/b]

**Delaunay optimizes for "niceness"** - avoids extreme angles, prefers regularity.

**Circumcircle property:** No intruders allowed inside the circle.

**This is spatial normative pressure:**
- **Triangles must be "well-formed"** (not too thin)
- **Boundaries enforce separation** (no points in circumcircle)

**Queer resistance:** What if we want sliver triangles? Extreme angles? Non-regular meshes?

**Delaunay enforces aesthetic norm** (nice triangles). **Queerness embraces irregularity.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Delaunay triangulation: optimal triangulation (no points in circumcircles), maxim izes minimum angle, dual of Voronoi. Applications: mesh generation, terrain, navmesh. Queer Delaunay: enforces regularity/"niceness", circumcircle exclusion as boundary norm. Queer irregularity resists optimization toward single aesthetic.

'''
