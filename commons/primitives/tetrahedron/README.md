# Tetrahedron

Regular tetrahedron (4 triangular faces) with grid material.

## Files

- `tetrahedron.gd` / `tetrahedron.tscn`: procedural tetrahedron
- `tetrahedron_mesh.gd`: mesh-only variant
- `grab_tetrahedron.gd` / matching `.tscn`: grabbable VR variant

## Behavior

- Uses PrimitiveMeshBuilder and GridMaterialFactory.
- Grabbable variant extends XRToolsPickable.
