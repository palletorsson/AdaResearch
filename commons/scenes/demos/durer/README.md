# Durer's Melencolia I

Procedural recreations of two mathematical objects from Albrecht Durer's 1514 engraving "Melencolia I": the truncated rhombohedron and the 4x4 magic square.

## How It Works

The polyhedron is built at runtime using SurfaceTool, constructing the 8-face solid (6 pentagons + 2 triangles) from calculated vertex positions based on golden ratio proportions. The magic square generates a 4x4 grid of Label3D cells with background plates, highlighting the year "1514" in gold and corner cells in blue. Both scripts support `@tool` mode for in-editor preview.

## Files

- `DurerPolyhedron.gd` -- Generates the truncated rhombohedron mesh procedurally with optional slow rotation
- `MagicSquare.gd` -- Builds the 4x4 magic square grid (all rows/columns/diagonals sum to 34) with highlighted cells
- `DurerScene.tscn` -- Combined scene placing both objects together
