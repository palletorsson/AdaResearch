**Random Transformations**
Variation Through Geometry

**100 identical trees look fake.** Randomize rotation, scale, color - suddenly unique.

**Transformations break uniformity** - same model, infinite variations.

---

## Random Rotation

**Simplest transformation - just spin it:**

**Code: Y-Axis Rotation (Most Common)**

```
# Rotate around Y (up) axis - different facing direction
var tree = tree_scene.instantiate()
tree.position = spawn_position
tree.rotation.y = randf() * TAU  # Random 0-360 degrees

add_child(tree)

# Result: Tree faces random direction
# Breaks grid alignment, looks natural
```

**Why Y-axis?** Objects usually upright - rotating X or Z would tip them over.

**Full 3D Rotation (Chaotic Objects)**

# Random rotation in all axes (debris, asteroids, floating items)
var debris = debris_scene.instantiate()
debris.position = spawn_position
debris.rotation = Vector3(
    randf() * TAU,
    randf() * TAU,
    randf() * TAU
)

add_child(debris)

# Result: Tumbling, no