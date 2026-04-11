# Limb Growth -- Dynamic Topology Morphogenesis

A procedural growth system that demonstrates **dynamic topology (dyntopo) remeshing** applied to biological morphogenesis. Starting from an icosphere, the artifact selects random surface points and extrudes mesh faces outward, adaptively subdividing or collapsing edges to maintain appropriate detail levels.

## Concept Taught

**Dynamic topology** is a mesh editing technique from digital sculpting (popularized by tools like Blender's Dyntopo mode) where the mesh resolution adapts locally to match the level of detail needed. In growth zones, edges are subdivided to create finer geometry; in low-activity areas, short edges are collapsed to save resources. This mirrors how biological tissues allocate cellular density -- rapidly dividing cells appear at growth tips while dormant regions maintain minimal structure.

## How It Works

1. An **icosphere** is generated from an icosahedron base through recursive midpoint subdivision, projecting vertices onto a sphere surface.
2. At timed intervals, a random point on the sphere is selected as a new **growth zone**.
3. Faces within `growth_zone_radius` of the growth point are marked for processing.
4. In dyntopo mode:
   - Edges longer than `detail_size` in growth zones (or `max_edge_length` globally) are **subdivided** by inserting a midpoint vertex and splitting adjacent faces.
   - Edges shorter than `min_edge_length` are **collapsed** by merging vertices and removing degenerate faces.
5. Vertices in growth zones are **extruded** along their normals (blended with gravity) using a smooth quadratic falloff from the growth center.
6. The mesh is rebuilt each frame using `SurfaceTool` with generated normals.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `sphere_radius` | float | 1.0 | Initial icosphere radius |
| `initial_subdivisions` | int | 2 | Subdivision iterations for the base sphere |
| `growth_interval` | float | 1.0 | Seconds between new growth zone activations |
| `extrusion_amount` | float | 0.15 | How far vertices push outward per growth step |
| `gravity_influence` | float | 0.3 | Blend factor pulling growth downward |
| `growth_zone_radius` | float | 0.4 | Radius of each growth activation zone |
| `subdivision_iterations` | int | 2 | Growth/extrusion passes per zone activation |
| `dyntopo_enabled` | bool | true | Enable adaptive edge subdivision/collapse |
| `max_edge_length` | float | 0.15 | Subdivide edges longer than this globally |
| `min_edge_length` | float | 0.03 | Collapse edges shorter than this |
| `detail_size` | float | 0.1 | Target edge length in growth zones |

## Features

- Full icosphere generation from icosahedron with midpoint subdivision
- Dual remeshing modes: static subdivision and adaptive dyntopo
- Edge subdivision splits triangles at midpoints
- Edge collapse merges vertices and removes degenerate faces
- Quadratic falloff for smooth extrusion profiles
- Gravity blending creates natural drooping limb shapes
- Red sphere markers visualize growth zone locations
- Interactive controls: SPACE to start growth, R to reset

## Files

- `limbgrowth.gd` -- Main script with icosphere generation, dyntopo remeshing, and growth simulation
- `limbgrowth.tscn` -- Scene file
