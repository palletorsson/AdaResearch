**Noise**
Structured Randomness, Entropy Tamed

**White noise** is pure entropy - every sample independent, completely random, maximum disorder.

**Perlin/Simplex noise** is **structured randomness** - smooth, continuous, correlated. It looks organic, natural, like terrain, clouds, marble.

Noise is **entropy with continuity constraints** - randomness that flows smoothly from point to point, creating patterns without repetition.

**This is randomness tamed into usefulness** - still unpredictable, but coherent enough to generate terrain, textures, procedural content.

---

## White Noise vs Smooth Noise

**White noise** - every sample independent:

**Code: Maximum Disorder**

```
# White noise: each value random, no correlation
func white_noise(x: float) -> float:
    return randf()  # Completely random

# Values at nearby positions totally different:
# white_noise(5.0) = 0.7234
# white_noise(5.1) = 0.2156  # No relationship
```

**Perlin noise** - smooth interpolation between random values:

**Code: Structured Disorder**

```
# Perlin noise: smooth gradients between random grid points
var noise = FastNoiseLite.new()
noise.noise_type = FastNoiseLite.TYPE_PERLIN

func smooth_noise(x: float) -> float:
    return noise.get_noise_1d(x)

# Values at nearby positions smoothly related:
# smooth_noise(5.0) = 0.4521
# smooth_noise(5.1) = 0.4683  # Gradual change, continuous
```

**White noise = chaotic static**
**Smooth noise = organic undulation**

---

## Perlin Noise: Grid + Gradient + Interpolation

Perlin noise (Ken Perlin, 1983) works by:
1. **Grid** - Divide space into grid cells
2. **Random gradients** - Assign random direction vector to each grid corner
3. **Interpolation** - Smoothly blend between gradients

**The Mechanism:**

```
# 1D Perlin concept (simplified)
func perlin_1d(x: float) -> float:
    # Find grid cell (integer part)
    var cell = int(floor(x))

    # Position within cell (fractional part)
    var local_x = x - cell

    # Random gradients at cell corners
    var gradient_0 = random_gradient(cell)
    var gradient_1 = random_gradient(cell + 1)

    # Dot products (distance × gradient)
    var dot_0 = local_x * gradient_0
    var dot_1 = (local_x - 1.0) * gradient_1

    # Smooth interpolation (ease curve)
    var t = smoothstep(0.0, 1.0, local_x)

    # Blend values
    return lerp(dot_0, dot_1, t)

# Result: smooth, continuous, no sudden jumps
# Yet unpredictable (depends on random gradients)
```

**Perlin is hybrid:**
- **Random** (gradients at grid points)
- **Deterministic** (interpolation between them)
- **Continuous** (no discontinuities)

**Entropy structured by smoothness constraint.**

---

## Octaves: Layering Frequencies

To create rich, detailed noise, **layer multiple frequencies** (octaves):

**Code: Fractal Noise**

```
var noise = FastNoiseLite.new()

# Base frequency
noise.frequency = 0.01

func fractal_noise(x: float, y: float) -> float:
    var total = 0.0
    var amplitude = 1.0
    var frequency = 1.0

    # Add multiple octaves
    for i in range(4):  # 4 octaves
        total += noise.get_noise_2d(x * frequency, y * frequency) * amplitude

        # Each octave: double frequency, half amplitude
        frequency *= 2.0  # Lacunarity (frequency multiplier)
        amplitude *= 0.5  # Persistence (amplitude multiplier)

    return total

# Result: coarse features (low freq) + fine details (high freq)
# Like terrain: mountains (large scale) + boulders (small scale)
```

**Octaves create fractal-like detail** - self-similar patterns at multiple scales.

One octave = smooth rolling hills
Four octaves = mountains with ridges and valleys
Eight octaves = detailed rocky terrain

**Each octave adds one