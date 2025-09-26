# Create a Point

- Instantiate a Node3D to represent the point.
- Give the node a clear name so it is easy to reference.
- Set its position to the exact Vector3 location you need.
- Add it to the scene tree with add_child so it becomes visible in the world.

```gdscript
# Create a point at the origin
var point := Node3D.new()
point.name = "MyPoint"
point.position = Vector3.ZERO
add_child(point)
```
