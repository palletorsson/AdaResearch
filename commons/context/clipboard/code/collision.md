# Set Up Collision Detection

- Pair a PhysicsBody3D with a matching CollisionShape3D.
- Configure the shape (BoxShape3D, SphereShape3D, etc.) to match geometry.
- Listen to body_entered/area_entered signals to react to overlaps.

```gdscript
# Create a static box collider
var body := StaticBody3D.new()
var shape := CollisionShape3D.new()
shape.shape = BoxShape3D.new()
shape.shape.size = Vector3(1, 1, 1)
body.add_child(shape)
add_child(body)
```
