# Random Noise Types

White noise. Blue noise. Each has a spectral signature.

Generate white noise.

```gdscript
func white_noise_grid(size: Vector2i) -> Array:
    var grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            row.append(randf())
        grid.append(row)
    return grid
```

Each cell independent. No structure.

Generate blue noise via dart throwing.

```gdscript
func blue_noise_points(count: int, bounds: Rect2, min_distance: float) -> Array:
    var points: Array = []
    var attempts: int = 0
    while points.size() < count and attempts < count * 30:
        var candidate := Vector2(randf() * bounds.size.x, randf() * bounds.size.y) + bounds.position
        var valid: bool = true
        for p in points:
            if candidate.distance_to(p) < min_distance:
                valid = false
                break
        if valid:
            points.append(candidate)
        attempts += 1
    return points
```

Dart throwing with minimum-distance constraint. Rejects candidates that are too close to existing points.

Render noise as texture.

```gdscript
func noise_to_texture(grid: Array) -> ImageTexture:
    var height: int = grid.size()
    var width: int = grid[0].size()
    var image := Image.create(width, height, false, Image.FORMAT_L8)
    for y in height:
        for x in width:
            image.set_pixel(x, y, Color(grid[y][x], grid[y][x], grid[y][x]))
    return ImageTexture.create_from_image(image)
```

Grayscale intensity maps to noise value. Noisy textures for use in shaders.

Build an FFT to see the spectrum.

```gdscript
func spectral_power(grid: Array) -> Array:
    var fft_result := compute_2d_fft(grid)
    var power: Array = []
    for row in fft_result:
        var power_row: Array = []
        for c in row:
            power_row.append(c.real * c.real + c.imag * c.imag)
        power.append(power_row)
    return power
```

Fourier transform followed by magnitude. White noise has flat power; blue noise concentrates power at high frequencies.

Radial power spectrum.

```gdscript
func radial_spectrum(power: Array) -> Array:
    var centre_x: int = power[0].size() / 2
    var centre_y: int = power.size() / 2
    var bins: Array = []
    for _i in 30: bins.append(0.0)
    var counts: Array = []
    for _i in 30: counts.append(0)
    for y in power.size():
        for x in power[0].size():
            var r: float = Vector2(x - centre_x, y - centre_y).length()
            var bin: int = int(r / 2)
            if bin < bins.size():
                bins[bin] += power[y][x]
                counts[bin] += 1
    for i in bins.size():
        if counts[i] > 0: bins[i] /= counts[i]
    return bins
```

Average power at each radial frequency. The shape of this curve distinguishes noise types.

Classify by spectrum.

```gdscript
func classify_noise(radial_spec: Array) -> String:
    var low_power: float = 0.0
    var high_power: float = 0.0
    for i in radial_spec.size() / 2:
        low_power += radial_spec[i]
    for i in range(radial_spec.size() / 2, radial_spec.size()):
        high_power += radial_spec[i]
    if low_power > high_power * 1.5: return "red (low-frequency)"
    elif high_power > low_power * 1.5: return "blue (high-frequency)"
    return "white (flat)"
```

Heuristic from low-vs-high frequency content. Red noise has smooth ramps; blue noise has point-like structure.

You can now generate white and blue noise, render as textures, compute their power spectra, and classify them. Noise_Columns extends into 3D noise for terrain.
