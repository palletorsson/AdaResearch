# Marching Cubes — Summary

## What You'll Learn

Marching Cubes extracts surfaces from scalar fields — turning implicit definitions into explicit geometry. Given a 3D grid of density values, it finds the isosurface where density equals a threshold.

## The Algorithm

1. **Sample the field** — Get density at each grid point
2. **March through cubes** — Process each 2×2×2 cell
3. **Classify corners** — Each corner is inside (density > threshold) or outside
4. **Lookup triangles** — 8 corners × 2 states = 256 cases, precomputed
5. **Interpolate edges** — Place vertices where surface crosses edges
6. **Output mesh** — Collect all triangles

## Key Concepts

### Implicit Surfaces
The surface isn't defined by vertices — it's defined by a function f(x,y,z). The surface exists wherever f(x,y,z) = threshold.

### The 256 Cases
Each cube corner is inside or outside: 2^8 = 256 combinations. By symmetry, these reduce to 15 unique cases. Each case specifies which edges contain surface vertices.

### Isovalue
The threshold that defines the surface. Changing it expands or contracts the extracted geometry.

### Ambiguous Cases
Some configurations have multiple valid triangulations. The original algorithm had cracks; later variants fixed these.

## Applications

- Terrain from noise fields
- Medical imaging (CT/MRI visualization)
- Metaballs and blob modeling
- Cave and organic structure generation
- Real-time sculpting

## QFEP Connection

Marching Cubes finds the **edge** — the threshold between inside and outside. This IS λ made geometric: the boundary where states transition, the surface of phase change.
