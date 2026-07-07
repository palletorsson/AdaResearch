# Difference: Except

Subtract the second volume from the first. Where they met, a cavity opens. The first operation in the chapter where *order matters*.

```gdscript
func subtract_grid(a: Dictionary, b: Dictionary) -> Dictionary:
    var out := {}
    for cell in a:
        if not b.has(cell):
            out[cell] = true
    return out
```

Keep A's cells except the ones B claims. `A − B` and `B − A` are different objects — a mug minus a cylinder is a mug with a bore; a cylinder minus a mug is a plug shaped like the mug's absence. Non-commutativity arrives in this room and never leaves the curriculum.

In distance fields, subtraction is intersection with the *complement* — flip B inside-out, then demand both:

```gdscript
func sd_subtract(a: float, b: float) -> float:
    return max(a, -b)    # inside A, AND outside B
```

That `-b` is the whole idea: negation turns a solid into its outside, and cutting is just insisting on someone else's outside.

```gdscript
shape_b.operation = CSGShape3D.OPERATION_SUBTRACTION   # order = child order
```

The demo's moment worth standing close to: as B pushes into A, *new surface appears* — the cavity wall. That wall belongs to neither input; it is B's shape, inverted, wearing A's material. Every hole ever drilled has this property: the drill leaves, its geometry stays, as absence.

```gdscript
# useful identities to test against the demo
# A − B == A            when they never touch
# A − B == {}           when B swallows A
# A − (A − B)           == A ∩ B      (subtracting the remainder leaves the overlap)
```

Try: subtract a small sphere from the middle of a large box — a hidden void, invisible from outside, real to the physics. Then subtract a second sphere overlapping the first from *outside* the box. The void becomes a mouth. Two subtractions and you have made a cave, which is to say: the isosurfaces chapter, the architecture map next door, and every room you have ever stood in.
