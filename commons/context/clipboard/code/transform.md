# Apply 3D Transformations

- Build a Transform3D from basis (rotation & scale) plus origin.
- Use translated/rotated versions to adjust objects in world space.
- Combine transforms to move between coordinate frames.

```gdscript
# Construct and apply a custom transform
var basis := Basis()
basis = basis.rotated(Vector3.UP, deg_to_rad(45))
basis = basis.scaled(Vector3(1.5, 1, 1.5))
var xform := Transform3D(basis, Vector3(2, 0, -3))
$YourNode.transform = xform
```
