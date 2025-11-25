extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Value Noise[/b][/font_size][/center]
[center][i]Grid-Based Random Interpolation[/i][/center]

**Value noise** is the simplest coherent noise: random values at grid points, smoothly interpolated between.

Cheaper than Perlin, but with visible artifacts. The tradeoff between cost and quality.

[hr]

[b]The Grid of Random Values[/b]

**Core concept:** Place random values at integer coordinates, interpolate smoothly.

[color=yellow][b]Code: 1D Value Noise[/b][/color]
[code]
# Hash function: integer → deterministic "random" value
func hash(n: int) -> float:
    var x = sin(n * 12.9898 + 78.233) * 43758.5453
    return fmod(x, 1.0)  # Return fractional part (0.0-1.0)

# Get value at integer grid point
func grid_value(x: int) -> float:
    return hash(x)

# 1D value noise with linear interpolation
func value_noise_1d(x: float) -> float:
    var x0 = int(floor(x))  # Left grid point
    var x1 = x0 + 1          # Right grid point

    var v0 = grid_value(x0)
    var v1 = grid_value(x1)

    var t = x - x0  # Fractional part (0.0-1.0)
    return lerp(v0, v1, t)

# Sample: value_noise_1d(2.7) interpolates between grid_value(2) and grid_value(3)
[/code]

**Properties:**
- Grid points have fixed random values (deterministic from seed)
- Between points: smooth interpolation
- Continuous, but derivative not continuous (visible creases)

[hr]

[b]2D Value Noise[/b]

**Extend to 2D:** Random values at (x, y) grid points, bilinear interpolation.

[color=yellow][b]Code: 2D Value Noise[/b][/color]
[code]
# 2D hash function
func hash_2d(x: int, y: int) -> float:
    var n = x + y * 57
    return hash(n)

# 2D value noise with bilinear interpolation
func value_noise_2d(x: float, y: float) -> float:
    var x0 = int(floor(x))
    var x1 = x0 + 1
    var y0 = int(floor(y))
    var y1 = y0 + 1

    # Four corner values
    var v00 = hash_2d(x0, y0)
    var v10 = hash_2d(x1, y0)
    var v01 = hash_2d(x0, y1)
    var v11 = hash_2d(x1, y1)

    # Interpolate in X direction
    var tx = x - x0
    var v0 = lerp(v00, v10, tx)
    var v1 = lerp(v01, v11, tx)

    # Interpolate in Y direction
    var ty = y - y0
    return lerp(v0, v1, ty)

# Result: Smooth gradient between grid points
# But linear interpolation creates visible diagonal artifacts
[/code]

**Bilinear interpolation:** Interpolate twice (X, then Y).

[hr]

[b]Interpolation Methods[/b]

**The interpolation function determines smoothness:**

[color=yellow][b]1. Linear (Cheapest, Worst Quality)[/b][/color]
[code]
func linear_interp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t

# Result: Continuous, but derivative has sharp corners
# Visible grid alignment, directional bias
[/code]

[color=yellow][b]2. Smoothstep (Better)[/b][/color]
[code]
func smoothstep(t: float) -> float:
    return t * t * (3.0 - 2.0 * t)

func smoothstep_interp(a: float, b: float, t: float) -> float:
    var smooth_t = smoothstep(t)
    return a + (b - a) * smooth_t

# Result: Smoother, first derivative continuous
# Less grid-aligned artifacts
[/code]

[color=yellow][b]3. Smootherstep (Best for Value Noise)[/b][/color]
[code]
func smootherstep(t: float) -> float:
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)

func smootherstep_interp(a: float, b: float, t: float) -> float:
    var smooth_t = smootherstep(t)
    return a + (b - a) * smooth_t

# Result: Very smooth, second derivative continuous
# Minimal artifacts, but more expensive
[/code]

**Trade-off:** Linear is fast but ugly, smootherstep is beautiful but costly.

[hr]

[b]Value Noise vs Perlin Noise[/b]

[color=yellow][b]Value Noise:[/b][/color]
- **Interpolates random VALUES** at grid points
- Simpler, cheaper computation
- Visible grid artifacts (especially with linear interp)
- Values clustered near 0.5 (average of random [0,1])
- Good enough for rough textures

[color=yellow][b]Perlin Noise:[/b][/color]
- **Interpolates random GRADIENTS** at grid points
- More expensive (dot products, gradient vectors)
- Smoother, fewer artifacts
- Better frequency distribution
- Industry standard for quality

**When to use value noise:** Performance-critical, rough textures, multiple octaves will hide artifacts.

[hr]

[b]Artifacts and Failures[/b]

**Value noise has characteristic problems:**

[color=yellow][b]1. Grid Alignment[/b][/color]
- With linear interpolation, you can SEE the grid
- Diagonals appear in texture
- Solution: Use smoothstep or better

[color=yellow][b]2. Value Clustering[/b][/color]
- Random values uniformly distributed [0, 1]
- Interpolated values cluster near 0.5 (average)
- Less contrast than Perlin
- Solution: Remap output range

[color=yellow][b]3. Directional Bias[/b][/color]
- Bilinear interpolation has slight directional preference
- Not isotropic (not rotationally invariant)
- Solution: Use Perlin or Simplex for isotropy

[hr]

[b]Octaves (Fractal Value Noise)[/b]

**Layer multiple frequencies to hide artifacts:**

[color=yellow][b]Code: Fractal Value Noise (fBm)[/b][/color]
[code]
func fractal_value_noise(x: float, y: float, octaves: int = 4) -> float:
    var value = 0.0
    var amplitude = 1.0
    var frequency = 1.0
    var max_value = 0.0  # For normalization

    for i in range(octaves):
        value += value_noise_2d(x * frequency, y * frequency) * amplitude
        max_value += amplitude

        amplitude *= 0.5  # Each octave half as strong (persistence)
        frequency *= 2.0  # Each octave double frequency (lacunarity)

    return value / max_value  # Normalize to [0, 1]

# Result: Multiple layers of detail
# Higher octaves add fine detail, masking grid artifacts
[/code]

**Octaves save value noise** - single-octave value noise looks bad, but 4-6 octaves look acceptable.

[hr]

[b]Hash Functions Matter[/b]

**The hash function determines randomness quality:**

[color=yellow][b]Bad Hash (Periodic, Visible Patterns)[/b][/color]
[code]
func bad_hash(x: int, y: int) -> float:
    return fmod(float(x * y), 1.0)
# Result: Terrible! Obvious patterns, not random-looking
[/code]

[color=yellow][b]Good Hash (Pseudorandom, Looks Random)[/b][/color]
[code]
func good_hash(x: int, y: int) -> float:
    var n = x * 374761393 + y * 668265263
    n = (n ^ (n >> 13)) * 1274126177
    return float(n & 0x7fffffff) / 2147483647.0
# Result: Good distribution, looks random
# Fast bit operations
[/code]

**A bad hash ruins everything** - no amount of interpolation fixes bad randomness.

[hr]

[b]3D Value Noise[/b]

**Extend to volumetric:**

[color=yellow][b]Code: 3D Value Noise[/b][/color]
[code]
func value_noise_3d(x: float, y: float, z: float) -> float:
    var x0 = int(floor(x))
    var x1 = x0 + 1
    var y0 = int(floor(y))
    var y1 = y0 + 1
    var z0 = int(floor(z))
    var z1 = z0 + 1

    # Eight corner values
    var v000 = hash_3d(x0, y0, z0)
    var v100 = hash_3d(x1, y0, z0)
    var v010 = hash_3d(x0, y1, z0)
    var v110 = hash_3d(x1, y1, z0)
    var v001 = hash_3d(x0, y0, z1)
    var v101 = hash_3d(x1, y0, z1)
    var v011 = hash_3d(x0, y1, z1)
    var v111 = hash_3d(x1, y1, z1)

    # Trilinear interpolation
    var tx = smoothstep(x - x0)
    var ty = smoothstep(y - y0)
    var tz = smoothstep(z - z0)

    # Interpolate along X
    var v00 = lerp(v000, v100, tx)
    var v10 = lerp(v010, v110, tx)
    var v01 = lerp(v001, v101, tx)
    var v11 = lerp(v011, v111, tx)

    # Interpolate along Y
    var v0 = lerp(v00, v10, ty)
    var v1 = lerp(v01, v11, ty)

    # Interpolate along Z
    return lerp(v0, v1, tz)

# Result: 3D coherent noise for volumetric effects
[/code]

**Trilinear interpolation:** 8 corner lookups, 7 lerps.

[hr]

[b]Applications[/b]

**Value noise is useful when:**

[color=yellow][b]1. Performance Critical[/b][/color]
- Mobile/VR platforms
- Real-time large-scale terrain
- Many parallel samples needed

[color=yellow][b]2. Rough Textures[/b][/color]
- Rock surfaces
- Dirt, gravel
- Weathering, rust
- Artifacts less noticeable in high-frequency detail

[color=yellow][b]3. Multiple Octaves[/b][/color]
- Layering hides single-octave artifacts
- 4+ octaves makes value noise acceptable
- Cheaper than Perlin with same octave count

[color=yellow][b]4. GPU Shaders[/b][/color]
- Simpler math = fewer instructions
- Good for real-time material shaders
- Hash function fits well in fragment shader

[hr]

[b]Optimizations[/b]

**Make value noise faster:**

[color=yellow][b]1. Precomputed Hash Table[/b][/color]
[code]
# Instead of computing hash every time, use lookup table
var hash_table = []

func init_hash_table(size: int = 256):
    hash_table.resize(size)
    for i in range(size):
        hash_table[i] = randf()

func table_hash(x: int, y: int) -> float:
    var index = (x + y * 57) & 255  # Modulo 256
    return hash_table[index]

# Much faster: memory lookup instead of computation
[/code]

[color=yellow][b]2. Integer-Only Hash[/b][/color]
[code]
# Avoid floating-point in hash (faster on some hardware)
func int_hash(x: int, y: int) -> int:
    var n = x * 374761393 + y * 668265263
    n = (n ^ (n >> 13)) * 1274126177
    return n & 0x7fffffff

# Convert to float only at end
[/code]

[hr]

[b]What Value Noise Reveals[/b]

Value noise shows us:

1. **Simplicity has costs** - Easier algorithm, visible artifacts
2. **Interpolation matters** - Linear vs smoothstep dramatically affects quality
3. **Layering hides flaws** - Multiple octaves mask single-octave problems
4. **Hash quality is critical** - Bad randomness ruins everything
5. **Performance vs quality** - Always a tradeoff in real-time graphics
6. **Grid artifacts inevitable** - Interpolating grid values shows the grid
7. **Good enough is often enough** - Not every texture needs perfect noise

**Value noise is the cheap noise** - not the best, but fast and sufficient for many uses. The workhorse of procedural generation.

**Perlin is premium, value is budget** - same idea (grid interpolation), different execution (gradients vs values).

[hr]

[color=cyan][b]Summary:[/b][/color]
Value noise places random values at grid points, smoothly interpolates between. Simpler and cheaper than Perlin noise, but with visible grid artifacts (especially linear interpolation). Smoothstep/smootherstep improve quality. Hash function quality critical for good randomness. Multiple octaves (fBm) mask artifacts. Best for performance-critical applications, rough textures, or when layered. Trilinear interpolation extends to 3D. Trade-off between computational cost and visual quality.

[hr]

[color=orange][b]Next:[/b] Worley Noise - Cellular Patterns[/color]
If value noise interpolates random values, Worley noise measures distance to random points - creating organic cellular structures, cracks, bubbles.

'''
