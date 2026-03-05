# Signed Distance Fields

Every point in space knows how far it is from a shape. That's the entire trick. A signed distance function returns a single number: negative inside, zero on the boundary, positive outside. The circle is the simplest — `length(uv) - radius`. The rectangle requires `max()` and `abs()`. From two operations, hard geometry.

Boolean operations collapse to arithmetic. Union is `min()`. Intersection is `max()`. Subtraction is `max(a, -b)`. Combine any two shapes with a single line of code. No meshes, no vertices, no triangles — just inequalities evaluated per pixel.

Regular polygons emerge from angular repetition. Atan2 gives the angle; modular arithmetic tiles it. A pentagon is a circle seen through fivefold symmetry.

Distance is the oldest geometric concept. Before coordinates, before axes — proximity. How far am I from the edge? The fragment shader asks this question millions of times per frame. Each pixel answering independently, yet together they render a boundary that never exists in memory. The shape is not stored. It is perpetually computed.