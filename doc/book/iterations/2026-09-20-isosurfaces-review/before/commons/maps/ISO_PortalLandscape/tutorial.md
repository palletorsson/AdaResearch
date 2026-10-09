# Portal Landscape

Build a landscape by summing signed terms. Before it, the density must already be allowed to read `y` — a heightfield alone can hold no doorway.

Start from the heightfield.

```gdscript
func surface_height(p: Vector3) -> float:
    return noise.get_noise_2d(p.x * 0.01, p.z * 0.01) * 15.0 \
         + noise.get_noise_2d(p.x * 0.03, p.z * 0.03) * 5.0

func base_terrain(p: Vector3) -> float:
    return (surface_height(p) - p.y) / 30.0
```

Positive below the ground, negative above. One height per column. Nothing here can fold over your head.

Subtract an overhang.

```gdscript
func overhang(p: Vector3, w: float) -> float:
    var n := fbm(p, 4)
    var elevation := smoothstep(-10.0, 20.0, surface_height(p))
    var height_mod := sin(p.y * 0.1) * 0.5 + 0.5
    return n * elevation * w * lerp(0.3, 1.0, height_mod)
```

The term reads `p.y`, so density stops being a function of the column. `elevation` zones it: overhangs on the hills, none in the valleys.

Subtract a cave.

```gdscript
func cave(p: Vector3, w: float) -> float:
    return ridged(p, 3) * smoothstep(40.0, -10.0, p.y) * w
```

Below y = 40 the mask opens. This is the rung at which the landscape acquires an interior.

Subtract an arch.

```gdscript
func arch(p: Vector3, w: float) -> float:
    var pillars := absf(noise.get_noise_2d(p.x * 0.05, p.z * 0.05))
    var bands := sin(p.y * 0.15) * 0.5 + 0.5
    var mask := smoothstep(0.3, 0.7, noise.get_noise_2d(p.x * 0.02, p.z * 0.02))
    mask *= smoothstep(30.0, 5.0, absf(p.y - surface_height(p)))
    return pillars * bands * mask * w
```

Vertical pillars times horizontal bands. Solid columns with air between them — a passage, made by multiplying two periodic things.

Add an outcrop.

```gdscript
func outcrop(p: Vector3, w: float) -> float:
    var n := maxf(0.0, noise.get_noise_3d(p.x * 1.5, p.y * 1.5, p.z * 1.5))
    return n * n * smoothstep(surface_height(p) - 5.0,
                              surface_height(p) + 15.0, p.y) * w
```

The only added term. Clamped positive, then squared: it can put rock above the ground, never take any away.

Sum the five.

```gdscript
func density(p: Vector3, w: Array) -> float:
    return base_terrain(p) \
         - overhang(p, w[0]) - cave(p, w[1]) - arch(p, w[2]) \
         + outcrop(p, w[3])
```

No term draws a portal. A portal is where two subtractions overlap enough to drag the sum across the threshold.

Name the rungs.

```gdscript
const LANDFORM_WEIGHTS: Dictionary = {
    "hillside": [0.0, 0.0, 0.0, 0.0],
    "overhung": [0.8, 0.0, 0.0, 0.0],
    "quarried": [0.8, 0.6, 0.0, 0.0],
    "arched":   [0.8, 0.6, 0.4, 0.0],
    "compound": [0.8, 0.6, 0.4, 0.3],
}
@export_enum("hillside", "overhung", "quarried", "arched", "compound") var landform: String = "compound"
```

A ladder, not four knobs. Each rung adds exactly one claim to the one before it, so any change in the picture is attributable to a single term.

Threshold the sum.

```gdscript
func corner_bits(corners: PackedFloat32Array, iso: float) -> int:
    var bits := 0
    for i in 8:
        if corners[i] < iso:
            bits |= 1 << i
    return bits
```

Ground, cliff and doorway leave the field the same way: a sign change on one edge of one cell. The terrain does not contain the passage. The passage was already in the sum.
