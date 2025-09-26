# Build a Custom ArrayMesh

- Prepare vertex arrays for SURFACE array format.
- Call ArrayMesh.add_surface_from_arrays with PRIMITIVE_TRIANGLES.
- Assign the mesh to a MeshInstance3D for display.

```gdscript
# Create a simple quad from two triangles
var vertices := PackedVector3Array([
	Vector3(-1, 0, -1),
	Vector3(1, 0, -1),
	Vector3(1, 0, 1),
	Vector3(-1, 0, 1),
])
var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
var arrays := []
arrays.resize(Mesh.ARRAY_MAX)
arrays[Mesh.ARRAY_VERTEX] = vertices
arrays[Mesh.ARRAY_INDEX] = indices
var mesh := ArrayMesh.new()
mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
var mesh_instance := MeshInstance3D.new()
mesh_instance.mesh = mesh
add_child(mesh_instance)
```
