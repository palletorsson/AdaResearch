# A Value at Every Point, a Surface at One of Them

A scalar field fills space with numbers. The isosurface is where the field crosses a chosen value — the threshold made geometry.

```gdscript
var noise := FastNoiseLite.new()

func density(p: Vector3) -> float:
    return noise.get_noise_3d(p.x, p.y, p.z)   # −1 .. 1, everywhere
```

The field is invisible and total: every point in the room has a density, whether or not anything marks it. Choose an isovalue — say 0.0 — and space splits in two: inside (density above) and outside (below). The surface is the frontier between them.

Marching cubes finds that frontier one cell at a time:

```gdscript
func march(size: int, iso: float = 0.0) -> void:
    for x in size:
        for y in size:
            for z in size:
                var corners: Array[float] = []
                for c in CORNER_OFFSETS:          # the cube's 8 corners
                    corners.append(density(Vector3(x, y, z) + c))
                var mask := 0
                for i in 8:
                    if corners[i] > iso:
                        mask |= 1 << i            # 8 bits: 256 cases
                emit_triangles_for_case(mask, corners)
```

Eight corners, each inside or outside: an 8-bit mask, 256 possible configurations, and a lookup table that says which triangles to draw for each. The whole algorithm is a walk (march every cell) plus a dictionary (the table). The next map opens the dictionary.

Slide the isovalue and the world remakes itself:

```gdscript
func _on_iso_slider(value: float) -> void:
    clear_mesh()
    march(32, value)
```

Lower it and matter grows; raise it and matter recedes. Nothing in the field changed — only the threshold. The shape was never *in* the data. It is a decision about the data.

Try: set `iso` to −0.4, then +0.4. Same noise, two different worlds. Ask which one was really there.
