# Noise Inside Noise

Domain warping. Noise drives the coordinates of other noise.

Simple warp.

```gdscript
func warped_noise(p: Vector2, warp_amount: float) -> float:
    var offset := Vector2(
        noise.get_noise_2d(p.x, p.y),
        noise.get_noise_2d(p.x + 100, p.y + 100)
    ) * warp_amount
    return noise.get_noise_2d(p.x + offset.x, p.y + offset.y)
```

First noise gives displacement; second noise is sampled at the displaced position. Produces turbulent flow patterns.

Recursive warp.

```gdscript
func recursive_warp(p: Vector2, depth: int) -> float:
    if depth == 0:
        return noise.get_noise_2d(p.x, p.y)
    var offset := Vector2(
        recursive_warp(p, depth - 1),
        recursive_warp(p + Vector2(100, 100), depth - 1)
    ) * 0.5
    return noise.get_noise_2d(p.x + offset.x, p.y + offset.y)
```

Each level warps the next. Produces increasingly chaotic patterns at each depth.

Render a warped field.

```gdscript
func render_warp_to_texture(resolution: Vector2i, warp_amount: float) -> ImageTexture:
    var image := Image.create(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
    for y in resolution.y:
        for x in resolution.x:
            var p := Vector2(x * 0.05, y * 0.05)
            var value: float = warped_noise(p, warp_amount)
            var color := Color(value * 0.5 + 0.5, value * 0.7 + 0.3, 1.0 - value * 0.3, 1.0)
            image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)
```

Each pixel sampled and coloured. Higher warp amounts produce more marbled, fluid-like textures.

Animate the warp.

```gdscript
var warp_strength: float = 0.0

func _process(delta: float) -> void:
    warp_strength = fmod(warp_strength + delta * 0.5, 2.0)
    update_material(warp_strength)
```

Oscillating warp strength. The texture pulses between ordered and turbulent.

Use curl noise.

```gdscript
func curl_noise(p: Vector2) -> Vector2:
    var h: float = 0.01
    var dx_dy: float = (noise.get_noise_2d(p.x, p.y + h) - noise.get_noise_2d(p.x, p.y - h)) / (2 * h)
    var dy_dx: float = (noise.get_noise_2d(p.x + h, p.y) - noise.get_noise_2d(p.x - h, p.y)) / (2 * h)
    return Vector2(dx_dy, -dy_dx)
```

Divergence-free velocity field. Perfect for flow simulation; particles move without compressing.

Advect particles.

```gdscript
func advect_particles(particles: Array, delta: float) -> void:
    for i in particles.size():
        var flow: Vector2 = curl_noise(particles[i]) * 2.0
        particles[i] += flow * delta
```

Each particle samples the flow at its position and moves accordingly. Paths swirl without compression.

You can now warp noise with noise, apply recursive warping, animate warp strength, compute curl noise, and advect particles through the resulting flow. Noise_Space_10 extends into the 10D parameter space.

Clamp to valid range.

```gdscript
func clamp_noise(value: float, low: float = -1.0, high: float = 1.0) -> float:
    return clamp(value, low, high)
```

Guarantees output stays in the expected range. Useful before writing to textures.
