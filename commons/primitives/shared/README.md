# Shared Primitive Helpers

This folder provides reusable helpers for Godot primitives that used to hand-roll `SurfaceTool` meshes and SimpleGrid materials. With these scripts in place, static shapes only need to describe their geometry and any optional tweaks.

## Scripts

- `grid_material_factory.gd` – returns a `ShaderMaterial` that targets `res://commons/resourses/shaders/SimpleGrid.gdshader`, applying defaults for the usual wireframe look and falling back to an equivalent `StandardMaterial3D` when the shader is unavailable.
- `primitive_mesh_builder.gd` – wraps the `SurfaceTool` boilerplate. Feed it vertices and triangular faces (array-of-arrays or dictionaries with `indices`/`normal`) to receive an `ArrayMesh` or ready `MeshInstance3D`.

The scripts are registered as global classes (`GridMaterialFactory`, `PrimitiveMeshBuilder`) via `project.godot`, so they can be referenced directly without local `preload()` calls.

## Typical Usage

```gdscript
var geometry := {
    "vertices": [Vector3(...), ...],
    "faces": [
        [0, 1, 2],
        { "indices": [0, 2, 3], "normal": Vector3.UP }
    ]
}
var material := GridMaterialFactory.make(base_color, {
    "edge_width": 1.2,
    "emission_strength": 0.8
})
var mesh := PrimitiveMeshBuilder.build_mesh_instance(
    geometry["vertices"],
    geometry["faces"],
    {
        "name": "MyPrimitive",
        "material": material,
        "double_sided": true
    }
)
add_child(mesh)
```

### Options

- `GridMaterialFactory.make(base_color, overrides)` accepts optional overrides for shader parameters. Keys such as `edge_color`, `edge_width`, `edge_sharpness`, `emission_strength`, and `double_sided` map directly to the shader uniforms. The helper auto-builds a double-sided fallback material when requested.
- `PrimitiveMeshBuilder.build_mesh(vertices, faces, options)` supports:
  - `double_sided` – append reversed triangles so both sides render without requiring `generate_normals`.
  - `generate_normals` – call `SurfaceTool.generate_normals()` after the faces are submitted.
  - `faces` may either be arrays of three vertex indices or dictionaries containing `indices` (Array[int]) and an optional `normal : Vector3`.

### Collision Helpers

The builder only targets rendering. For primitives that require collisions, create shapes separately (see `unitcube.gd` and `prismblock.gd` for examples).

## Migration Notes

1. Remove local `SurfaceTool` loops and per-file `apply_*_material` helpers.
2. Describe the vertex list and triangle indices in `_geometry()` style functions.
3. Build the `MeshInstance3D` via `PrimitiveMeshBuilder` and assign materials with `GridMaterialFactory`.
4. When adding a new helper script that needs to be globally accessible, append it to the `[global_script_classes]` section in `project.godot` to keep preload-free usage working.

Following this pattern keeps primitive scripts shorter, consistent, and easier to maintain across the library.
