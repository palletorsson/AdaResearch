# Connect Two Points

- Create a MeshInstance3D to hold the line geometry.
- Use SurfaceTool in PRIMITIVE_LINES mode to add two vertices.
- Commit the mesh and return the instance for placement in the scene.

```gdscript
# Build a line segment between two positions
func create_line(start: Vector3, finish: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_LINES)
	builder.add_vertex(start)
	builder.add_vertex(finish)
	mesh_instance.mesh = builder.commit()
	return mesh_instance
```
