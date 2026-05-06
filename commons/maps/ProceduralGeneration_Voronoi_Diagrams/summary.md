# Voronoi Diagrams — Summary

## What You'll Learn

A Voronoi diagram partitions space based on proximity. Given a set of seed points, each region contains all points closest to one seed. The boundaries are the loci of equidistance.

## Key Concepts

### Voronoi Cell
The region belonging to a single seed — all points closer to that seed than any other.

### Voronoi Edge
The boundary between two cells — points equidistant from exactly two seeds.

### Voronoi Vertex
Where three or more edges meet — points equidistant from three or more seeds.

### Delaunay Triangulation
The dual of Voronoi. Connect seeds whose cells share an edge. This creates optimal triangulations (maximizes minimum angle).

## Properties

- Every point belongs to exactly one cell
- Cells are convex polygons
- Edges are perpendicular bisectors of seed pairs
- Adding a seed only affects nearby cells (locality)

## Algorithms

1. **Fortune's Algorithm** — O(n log n) sweep line
2. **Bowyer-Watson** — Incremental Delaunay, then dualize
3. **Jump Flooding** — GPU-friendly, approximate

## Applications

- Organic textures and cell patterns
- City district generation
- Pathfinding mesh generation
- Nearest neighbor queries
- Procedural cracks and fractures

## QFEP Connection

Voronoi is **spatial negotiation** — each seed's influence extends until meeting resistance. The edges are compromise, the cells are territory. This is self-organization from simple rules: λ tuned for natural partitioning.
