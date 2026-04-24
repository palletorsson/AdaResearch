# Noise Perlin / Simplex

Two algorithms, same family. Different grids.

Sample Perlin noise.

```gdscript
func perlin_noise(p: Vector2) -> float:
    var perlin := FastNoiseLite.new()
    perlin.noise_type = FastNoiseLite.TYPE_PERLIN
    return perlin.get_noise_2d(p.x, p.y)
```

Uses a hypercubic grid. Axis-aligned artifacts visible at the right angles.

Sample Simplex noise.

```gdscript
func simplex_noise(p: Vector2) -> float:
    var simplex := FastNoiseLite.new()
    simplex.noise_type = FastNoiseLite.TYPE_SIMPLEX
    return simplex.get_noise_2d(p.x, p.y)
```

Uses a simplicial grid (triangles in 2D). No axis-aligned artifacts.

Compare outputs side by side.

```gdscript
func render_comparison() -> void:
    var perlin_texture := render_noise_function(perlin_noise, Rect2(0, 0, 10, 10), Vector2i(256, 256))
    var simplex_texture := render_noise_function(simplex_noise, Rect2(0, 0, 10, 10), Vector2i(256, 256))
    spawn_texture_at(perlin_texture, Vector3(-2, 0, 0))
    spawn_texture_at(simplex_texture, Vector3(2, 0, 0))
```

Same seed, same frequency. Any visible difference is algorithmic.

Rotate to expose artifacts.

```gdscript
func render_rotated(rotation_deg: float) -> ImageTexture:
    var r: float = deg_to_rad(rotation_deg)
    var image := Image.create(256, 256, false, Image.FORMAT_L8)
    for py in 256:
        for px in 256:
            var p := Vector2(px - 128, py - 128)
            var rotated := p.rotated(r)
            var value: float = perlin_noise(rotated / 16.0)
            image.set_pixel(px, py, Color(value, value, value))
    return ImageTexture.create_from_image(image)
```

Rotate the sample coordinates before evaluation. Perlin's axis-aligned artifacts travel with the rotation; Simplex's don't.

Measure isotropy.

```gdscript
func measure_isotropy(noise_func: Callable, samples: int = 1000) -> float:
    var angle_bins: Array = []
    for _i in 16: angle_bins.append(0.0)
    for _i in samples:
        var p := Vector2(randf() * 100, randf() * 100)
        var h: float = 0.01
        var grad := Vector2(
            (noise_func.call(p + Vector2(h, 0)) - noise_func.call(p - Vector2(h, 0))) / (2 * h),
            (noise_func.call(p + Vector2(0, h)) - noise_func.call(p - Vector2(0, h))) / (2 * h)
        )
        var bin: int = int(grad.angle() / (TAU / 16) + 16) % 16
        angle_bins[bin] += 1
    # Compute variance across bins; lower is more isotropic
    var mean: float = float(samples) / 16
    var variance: float = 0.0
    for b in angle_bins: variance += (b - mean) * (b - mean)
    return variance / 16
```

Sample many gradient directions; bin by angle. Uniform bins mean isotropic; skewed bins mean axis bias.

Benchmark performance.

```gdscript
func benchmark(noise_func: Callable, samples: int) -> float:
    var start: int = Time.get_ticks_usec()
    for _i in samples:
        noise_func.call(Vector2(randf(), randf()))
    var elapsed: int = Time.get_ticks_usec() - start
    return float(elapsed) / samples
```

Microseconds per sample. Perlin is slightly faster in 2D; Simplex is faster in higher dimensions.

You can now sample Perlin and Simplex noise, compare them visually side by side, rotate to expose artifacts, measure isotropy, and benchmark performance. Lab_Path closes the sequence with the corridor template.
