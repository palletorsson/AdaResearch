# Procedural Rock

Procedural rock generator using icosphere base with noise displacement.

## Files

- `proceduralrock.gd`: icosphere + FastNoise rock generation
- `proceduralrock.tscn`: scene wrapper

## Behavior

- Extends MeshInstance3D.
- Exports: scale, skew, deformation parameters per axis.
- Uses noise-based vertex displacement for organic variation.
