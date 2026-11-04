# Truncated Tetrahedron

Tetrahedron with corners cut off, leaving 4 triangular and 4 hexagonal faces.

## Files

- `truncatedtetrahedron.gd`: the solid, built by cutting each corner of a seed tetrahedron
- `truncatedtetrahedron.tscn`: scene wrapper
- `commons/testing/probe_truncatedtetrahedron.gd`: counts what it builds (exit = failures)

## Behavior

- Seed tetrahedron: corners at (±0.2, ±0.2, ±0.2) with an even number of minus signs.
- `truncation` (0.02 to 0.5, default 1/3): how far along each edge the corner is cut.
  - 1/3: the Archimedean truncated tetrahedron, with 12 vertices, 18 equal edges, and 4 triangles + 4 hexagons.
  - Other values below 1/2: the same counts with two edge lengths.
  - 1/2: the cuts meet at the edge midpoints and the solid is the octahedron (6 V, 12 E, 8 triangles).
- `origin_solid`: `hidden` shows the result alone; `ghost` shows the seed tetrahedron as a translucent shell.
- Until 2026-11-04 the mesh was an 8-vertex stand-in (two interleaved tetrahedra with crossing faces) and not a truncated tetrahedron.
