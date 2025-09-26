# Build a Triangle Surface

- Use SurfaceTool in PRIMITIVE_TRIANGLES mode to add three vertices.
- Supply a normal so lighting renders correctly.
- Commit the geometry and return the mesh instance.

```gdscript
# Create a filled triangle with a surface normal
func create_triangle(p0: Vector3, p1: Vector3, p2: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.add_normal((p1 - p0).cross(p2 - p0).normalized())
	builder.add_vertex(p0)
	builder.add_vertex(p1)
	builder.add_vertex(p2)
	mesh_instance.mesh = builder.commit()
	return mesh_instance
```
