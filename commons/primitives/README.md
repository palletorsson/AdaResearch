# Primitives Library

Reusable geometric primitives for the Ada Research VR environment. Each subfolder provides a procedurally generated shape with scene, script, and optional grab/interaction variants.

## Organization

- **Polyhedra**: cube, tetrahedron, octahedron, icosahedron, dodecahedron, bipyramid, truncatedtetrahedron, johnsonsolids
- **Basic shapes**: sphere, cylinder, capsule, torus, plane, quad, prism, pyramid, diamond, star, plus, rectcube
- **Triangles**: triangle, righttriangle, lefttriangle, triangularblock, triangularprism, triangleprofiles, interactivetriangle
- **Cubes**: cube, cubes, unitcube, roundedcube, walledcube, halocube, slantedcube, animatedcubebuilder
- **Rocks**: rock, roughrock, hollowrock, proceduralrock, rockfactory, crystal, crystalcluster
- **Furniture**: chair, modernchair, sofa, furniture
- **Interactive**: curves, foldedpaper, folded_strip, zigzagprofile, pythagorean_proof, puzzles, snappoint
- **Tools**: laser_measure, positionlabel, constraint, mesh_draw, trails
- **Structures**: arch, boxbeam, pillar, portal, frame, entrances, cave, pipes
- **Collections**: arrays, combines, math_gallery, parametric, design_classics, godotmeshes
- **Shared**: shared/ (GridMaterialFactory, PrimitiveMeshBuilder utilities)

## Patterns

Most primitives extend `Node3D` and build meshes procedurally in `_ready()` using `SurfaceTool`, `PrimitiveMeshBuilder`, or Godot built-in meshes. Materials come from `GridMaterialFactory` or direct `StandardMaterial3D`. Grab variants (`grab_*.tscn`) extend `XRToolsPickable` for VR interaction.
