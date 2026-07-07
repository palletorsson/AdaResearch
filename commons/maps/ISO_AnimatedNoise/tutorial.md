# The Surface Chases the Field

Noise evolves; the isosurface follows. Animation here is not motion — it is re-extraction.

The cheapest time axis is a scrolling offset through 3D noise:

```gdscript
var t := 0.0

func density(p: Vector3) -> float:
    return noise.get_noise_3d(p.x, p.y, p.z + t * 0.6)   # slide the field past

func _process(delta: float) -> void:
    t += delta
    remesh()
```

The honest time axis is a fourth dimension — sample 4D noise so the field *changes in place* instead of drifting past:

```gdscript
func density_4d(p: Vector3) -> float:
    # two 3D samples faked into 4D: blend between two noise spaces over time
    var a := noise_a.get_noise_3d(p.x, p.y, p.z)
    var b := noise_b.get_noise_3d(p.x, p.y, p.z)
    return lerp(a, b, 0.5 + 0.5 * sin(t * 0.4))
```

With a scroll, blobs migrate across the room. With in-place evolution, they breathe — swelling, splitting, merging where they stand. Watch a blob divide: there is no "split" event anywhere in the code. Two maxima in the field drifted apart, and the threshold stopped connecting them.

Re-extracting every frame is the cost, so budget it:

```gdscript
func remesh() -> void:
    frame_counter += 1
    if frame_counter % 2 == 0:            # every other frame is plenty
        mesh_instance.mesh = extract(density, 24)   # modest resolution
```

Halving resolution is an 8× saving in cells; the eye forgives coarse triangles on a moving surface far more than it forgives a stutter.

Try: freeze `t` with a button. The mysterious breathing thing becomes an ordinary static sculpture instantly — proof that all the life was in the field's evolution, none of it in the geometry. Motion here is the *derivative of the field*, rendered; the previous sequence's calculus is running under this room.
