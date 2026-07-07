# Two Terrains, One Difference

Both landscapes run the same extractor. The flat one thinks in 2D; the overhung one thinks in 3D. The difference is one term.

Heightmap-style density — the classic terrain:

```gdscript
var noise2d := FastNoiseLite.new()

func density_flat(p: Vector3) -> float:
    var ground := noise2d.get_noise_2d(p.x, p.z) * 4.0    # height from 2D noise
    return ground - p.y     # positive below ground, negative above
```

`ground − y` means: the field decreases as you rise, crossing zero exactly at the height the 2D noise dictates. Because height is a *function of (x, z)* — one answer per column — no column can fold over itself. Gentle hills, guaranteed. Also guaranteed: no caves, no arches, no roofs. The function's type signature forbids them.

Add a 3D term and the prohibition lifts:

```gdscript
var noise3d := FastNoiseLite.new()

func density_overhang(p: Vector3) -> float:
    var ground := noise2d.get_noise_2d(p.x, p.z) * 4.0
    var carve := noise3d.get_noise_3d(p.x * 0.7, p.y * 0.7, p.z * 0.7) * 3.0
    return ground - p.y + carve
```

Now density at a point depends on *y itself*, not just the column. Where the 3D noise runs positive high up, matter appears above emptiness — an overhang. Where it runs negative underground, a pocket opens — a cave. One added term and the world acquires an interior.

```gdscript
func compare() -> void:
    extract(density_flat).position.x = -8.0
    extract(density_overhang).position.x = 8.0
```

Stand between them. Left: a world that is only ever a floor. Right: a world with an inside.

Try: scale the `carve` weight from 0 to 3 with a slider. Watch overhangs bud off the hillsides at around 1.0 — the moment the terrain stops being a heightmap in disguise. That budding point is a phase transition in what kind of space the function can describe.
