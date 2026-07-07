# Sculpting the Field, Not the Mesh

You never touch the surface. You edit the numbers behind it, and the surface follows.

Store the field explicitly this time — a 3D grid of floats you can wound and heal:

```gdscript
var field: PackedFloat32Array
var N := 48

func idx(x: int, y: int, z: int) -> int:
    return x + y * N + z * N * N

func init_field() -> void:
    field.resize(N * N * N)
    field.fill(-1.0)          # empty space everywhere
```

The brush is addition. Sculpting is arithmetic on a neighborhood:

```gdscript
func brush(center: Vector3, radius: float, strength: float) -> void:
    for x in range(max(0, center.x - radius), min(N, center.x + radius + 1)):
        for y in range(max(0, center.y - radius), min(N, center.y + radius + 1)):
            for z in range(max(0, center.z - radius), min(N, center.z + radius + 1)):
                var d := Vector3(x, y, z).distance_to(center)
                if d < radius:
                    var falloff := 1.0 - d / radius
                    field[idx(x, y, z)] += strength * falloff * falloff
```

Positive `strength` deposits matter (the fountain rising); negative carves it away. The falloff makes the brush soft — density blooms around the center instead of stamping a hard ball.

After each stroke, re-march only the cells the brush touched:

```gdscript
func _on_trigger(hand_pos: Vector3, grow: bool) -> void:
    var c := world_to_grid(hand_pos)
    brush(c, 4.0, 0.8 if grow else -0.8)
    remarch_region(c - Vector3.ONE * 5, c + Vector3.ONE * 5)
```

This is the whole live-sculpting trick: the field is cheap to edit and the extraction is local. Your hand writes density; marching cubes translates continuously.

Try: carve a tunnel straight through a mound you just raised. No mesh operation happened — no cutting, no stitching. You lowered some numbers below the threshold, and the surface reorganized around the fact. Matter here is an *opinion the field holds*, revisable by hand.
