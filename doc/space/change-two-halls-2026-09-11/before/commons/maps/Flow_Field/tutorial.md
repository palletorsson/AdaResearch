# A Vector at Every Point

The slope arrows leave the ground. A field is a function whose answer is a direction.

```gdscript
func field(p: Vector3) -> Vector3:
    # a gentle rotor around the y-axis plus a slow updraft
    return Vector3(-p.z, 0.4, p.x).normalized() * 1.5
```

Feed it any point in the room, get back which way and how hard. The function is total — it has an answer *everywhere* — but you can only ever draw finitely many of them.

Sample it on a lattice and plant arrows:

```gdscript
func build_field(extent: int = 4, spacing: float = 1.0) -> void:
    for x in range(-extent, extent + 1):
        for y in range(0, extent + 1):
            for z in range(-extent, extent + 1):
                var p := Vector3(x, y, z) * spacing
                add_arrow(p, field(p))

func add_arrow(p: Vector3, v: Vector3) -> void:
    var a := arrow_scene.instantiate()
    add_child(a)
    a.global_position = p
    a.look_at(p + v)
    a.scale = Vector3.ONE * clamp(v.length() * 0.4, 0.1, 1.0)
```

The grid of arrows is not the field — it is a census of it. Halve the spacing and the same function yields four times the arrows; the field was always there between them.

Fields come from somewhere. The gradient of any height function is one:

```gdscript
func gradient_field(p: Vector3) -> Vector3:
    var e := 0.01
    return Vector3(
        (h(p.x + e, p.z) - h(p.x - e, p.z)) / (2 * e),
        0.0,
        (h(p.x, p.z + e) - h(p.x, p.z - e)) / (2 * e))
```

Every terrain owns an invisible field of steepest-ascent arrows. This room just makes one visible and hangs it in the air.

Try: walk through the lattice and read the arrows around you like weather. Nothing moves yet — the field is all instruction and no obedience. The next map releases the particles.
