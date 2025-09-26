# Vector Operations Essentials

- Use dot and cross products to analyse direction.
- Normalize vectors before using them for direction.
- Combine vectors to create offsets or movement.

```gdscript
# Demonstrate basic vector operations
var direction := Vector3(1, 2, 0)
var normalized := direction.normalized()
var dot := direction.dot(Vector3.FORWARD)
var cross := direction.cross(Vector3.UP)
print("Normalized", normalized, "dot", dot, "cross", cross)
```
