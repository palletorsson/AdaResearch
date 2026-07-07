# Union: Either

Every cell that belongs to either shape belongs to the result. OR, made solid.

On a voxel grid the operation is a word:

```gdscript
func union_grid(a: Dictionary, b: Dictionary) -> Dictionary:
    var out := a.duplicate()
    for cell in b:
        out[cell] = true      # membership in either is membership
    return out
```

Two overlapping boxes of cells go in; one connected mass comes out. Note what vanished: the boundary *between* them. Cells that used to be "A's edge facing B" are now interior — union does not glue two skins together, it deletes the skins where they met and re-derives one skin around the whole.

In signed-distance language the same idea is `min`:

```gdscript
func sd_union(a: float, b: float) -> float:
    return min(a, b)     # nearer surface wins; inside either = inside
```

And in the engine's scene tree it is a node arrangement:

```gdscript
func csg_union(shape_a: CSGShape3D, shape_b: CSGShape3D) -> CSGCombiner3D:
    var c := CSGCombiner3D.new()
    shape_a.operation = CSGShape3D.OPERATION_UNION
    shape_b.operation = CSGShape3D.OPERATION_UNION
    c.add_child(shape_a)
    c.add_child(shape_b)
    return c
```

Three notations — set, field, scene graph — one operation. Union is commutative and associative (`A∪B = B∪A`; grouping is free), which is why it is the safe operation: order never matters, nothing is ever lost, the result can only grow.

Watch the demo pull its two solids apart and together. At the moment of first contact the two skins open into each other — count the faces and there are suddenly fewer, not more. Joining *removed* surface.

Try: overlap the solids almost entirely. The union is barely bigger than one of them — `A∪A = A`. Union is idempotent: saying a thing twice adds nothing. The next room's operation is the jealous opposite.
