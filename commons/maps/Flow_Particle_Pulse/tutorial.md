# The Field, Obeyed

The arrows get bodies. A particle in a flow field integrates it — position accumulating velocity, the integral of the room.

```gdscript
var particles: Array[Vector3] = []

func _physics_process(delta: float) -> void:
    for i in particles.size():
        var p := particles[i]
        p += field(p) * delta        # Euler step: obey the local arrow
        particles[i] = p
```

That one line — `p += field(p) * delta` — is numerical integration. Each particle reads only the arrow where it stands, takes a small step, reads again. No particle knows the whole field; every trajectory is the field disclosed one step at a time.

Render a thousand of them cheaply with a MultiMesh:

```gdscript
func setup(count: int = 1000) -> void:
    mm.instance_count = count
    for i in count:
        particles.append(Vector3(randf_range(-4, 4), randf_range(0, 4), randf_range(-4, 4)))

func _process(_d: float) -> void:
    for i in particles.size():
        mm.set_instance_transform(i, Transform3D(Basis(), particles[i]))
```

Watch the swarm organize. Where arrows converge, particles bunch into streams; where they diverge, the crowd thins. Structure you never drew appears — it was latent in the field, and the particles are developing it like a photograph.

Respawn keeps the flow eternal:

```gdscript
func recycle(p: Vector3) -> Vector3:
    if p.length() > 8.0 or p.y > 6.0:
        return Vector3(randf_range(-4, 4), 0.0, randf_range(-4, 4))
    return p
```

Try: shrink `delta` artificially (quarter steps, four per frame). The streams tighten — smaller steps track the true curves better. You are watching integration error, the gap between the world and any finite sampling of it.
