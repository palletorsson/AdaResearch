# Influence, Summed

A metaball is a point that radiates. The surface is where the combined influence of all of them crosses the threshold.

```gdscript
var balls: Array[Vector4] = []    # xyz = center, w = radius

func density(p: Vector3) -> float:
    var total := 0.0
    for b in balls:
        var d2 := p.distance_squared_to(Vector3(b.x, b.y, b.z))
        total += (b.w * b.w) / max(d2, 0.0001)     # classic r²/d² falloff
    return total - 1.0                              # threshold at 1
```

One ball alone renders as a sphere — influence 1.0 exactly at distance `r`. The interesting physics is in the `+=`: influence *sums*. Two balls near each other lift the field between them above the threshold before either surface would touch, and a bridge of matter appears — the merge that gives metaballs their liquid look.

Move them and the surface negotiates continuously:

```gdscript
func _process(delta: float) -> void:
    for i in balls.size():
        var b := balls[i]
        b.x += sin(time * speeds[i]) * delta * 1.5
        balls[i] = b
    remesh()
```

Watch two balls approach: first a waist forms between them, then a smooth neck, then one body. Pull them apart and the neck thins, pinches, snaps into two. Merging and splitting cost nothing — no topology surgery, no seams — because there is no topology in the model, only a sum that marching cubes reads.

Negative influence is a repeller — a ball that pushes matter away:

```gdscript
total += sign * (b.w * b.w) / max(d2, 0.0001)   # sign = −1 carves a dent
```

Press a negative ball into a positive blob and it dimples, cups, tunnels through.

Try: grab one ball and orbit another slowly at just past merge distance. The bridge forms and breaks, forms and breaks — a relationship rendered as geometry, closeness made literal. This is the softest object in the sequence, and it is nothing but addition and a threshold.
