# The Donut and the Infinite Labyrinth

Two fields, close up. One encloses a volume; the other divides all of space forever.

The torus is distance measured twice:

```gdscript
func torus(p: Vector3, R: float = 2.0, r: float = 0.7) -> float:
    var ring := Vector2(p.x, p.z).length() - R    # distance to the ring's circle
    var q := Vector2(ring, p.y)
    return r - q.length()                          # inside the tube: positive
```

First: how far is the point from the great circle of radius `R` lying in the floor plane? Second: is that distance under the tube radius `r`? Two nested distance checks make a donut. Widen `r` until it swallows `R` and the hole closes — a topology change from a slider.

The gyroid is three sines shaking hands:

```gdscript
func gyroid(p: Vector3, scale: float = 2.0, thickness: float = 0.0) -> float:
    p *= scale
    var g := sin(p.x) * cos(p.y) + sin(p.y) * cos(p.z) + sin(p.z) * cos(p.x)
    return thickness - abs(g) if thickness > 0.0 else g
```

At isovalue zero the gyroid is a *triply periodic minimal surface* — it repeats in all three directions, has no edge, and splits space into two interlocked labyrinths, neither of which encloses the other. Walk either side forever without crossing. Butterfly wings and heat exchangers both compute this surface, for the same reason: maximum area, minimum material, two worlds kept apart while touching everywhere.

The `thickness` variant (`t - abs(g)`) turns the infinite membrane into a walkable slab — the version a printer or a game engine can hold.

```gdscript
func _on_morph(t: float) -> void:      # 0 = torus, 1 = gyroid
    extract(func(p): return lerp(torus(p), gyroid(p), t))
```

Try: morph halfway. The in-between object belongs to neither family — hole count in flux, the lookup table calmly triangulating a shape that has no name. That namelessness is the point: fields do not care about our taxonomy of solids.
