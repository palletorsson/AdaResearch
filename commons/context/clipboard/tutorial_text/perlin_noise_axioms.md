**Perlin Noise**
Smooth Randomness, Natural Texture

**Perlin noise creates smooth, natural-looking randomness.**

**Ken Perlin (1983)** - invented for Tron movie. **Won Academy Award.**

**Unlike random noise (harsh, discontinuous), Perlin is smooth and organic.**

---

## How It Works

1. **Grid of gradients** - random vectors at integer coordinates
2. **Interpolate** - smoothly blend between gradients
3. **Octaves** - layer multiple frequencies for detail

**Code:**

```
func perlin_noise_2d(x: float, y: float) -> float:
    # Get integer coordinates
    var x0 = int(floor(x))
    var x1 = x0 + 1
    var y0 = int(floor(y))
    var y1 = y0 + 1

    # Get fractional part
    var sx = x - x0
    var sy = y - y0

    # Get gradient vectors at corners
    var g00 = get_gradient(x0, y0)
    var g10 = get_gradient(x1, y0)
    var g01 = get_gradient(x0, y1)
    var g11 = get_gradient(x1, y1)

    # Calculate dot products
    var n00 = dot(g00, Vector2(sx, sy))
    var n10 = dot(g10, Vector2(sx - 1, sy))
    var n01 = dot(g01, Vector2(sx, sy - 1))
    var n11 = dot(g11, Vector2(sx - 1, sy - 1))

    # Interpolate
    var u = fade(sx)  # Smooth curve: 6t^5 - 15t^4 + 10t^3
    var v = fade(sy)

    var nx0 = lerp(n00, n10, u)
    var nx1 = lerp(n01, n11, u)

    return lerp(nx0, nx1, v)

func fade(t: float) -> float:
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
```

**Result:** Smooth hills and valleys. **Continuous but not predictable.**

---

## Applications

- **Terrain generation** (heightmaps)
- **Textures** (clouds, marble, wood grain)
- **Procedural animation** (organic movement)
- **Fire/smoke** (particle displacement)

---

## Queer Noise

**Perlin noise is smooth but non-uniform** - organic variation without grid.

**This is queer texture:**
- **Not white noise** (chaos)
- **Not grid** (order)
- **Organic middle** (structured variation)

**Queerness as noise** - smooth deviation from norm, continuous but unpredictable, natural-looking difference.

**Perlin generates landscapes without blueprints** - emergent terrain from layered randomness.

---

**Summary:**
Perlin noise: smooth randomness via gradient interpolation. Grid of gradients, fade curves, octaves for detail. Applications: terrain, textures, animation. Queer noise: organic middle between chaos and grid, smooth deviation, natural difference without blueprint.