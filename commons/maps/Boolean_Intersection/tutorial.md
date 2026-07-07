# Intersection: Both

A cell belongs to the result only if it belongs to BOTH inputs. AND, made solid — and suddenly order still doesn't matter, but *existence* does.

```gdscript
func intersect_grid(a: Dictionary, b: Dictionary) -> Dictionary:
    var out := {}
    for cell in a:
        if b.has(cell):
            out[cell] = true
    return out
```

Everything outside the shared region vanishes. Union could only grow; intersection can only shrink — down to nothing, if the shapes never meet. The empty result is not an error. It is the honest answer to "where are you both?"

In distance-field language, the farther surface wins:

```gdscript
func sd_intersect(a: float, b: float) -> float:
    return max(a, b)     # inside only where inside BOTH
```

And as scene-tree CSG:

```gdscript
shape_b.operation = CSGShape3D.OPERATION_INTERSECTION
```

Intersection is the sculptor's operation in reverse: instead of adding clay, you keep only agreement. Two crude shapes can intersect into one precise one — a cylinder through a box yields a perfect cropped disc; a sphere through a slab yields a lens. Every profile that machinists call "turned and milled" is intersections wearing overalls.

The demo slides two volumes through each other. Watch the result at the extremes:

```gdscript
# A == B          -> A            (intersection is idempotent too)
# A, B disjoint   -> {}           (the empty solid)
# B contains A    -> A            (the smaller shape survives whole)
```

That last line is the useful surprise: intersecting with something *bigger* changes nothing. Intersection only bites where the boundary of one crosses the interior of the other.

Try: make one input a thin plate and sweep it through the other solid. The intersection becomes a live cross-section — a CT scanner built from one `max`. Slice by slice you are seeing what the interior always looked like; the boundary was just the only part that ever got rendered.
