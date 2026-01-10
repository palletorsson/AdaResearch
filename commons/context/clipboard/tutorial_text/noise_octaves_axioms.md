**Noise Octaves**
Fractal Layering and fBm

**Single-octave noise is simple.** Multiple octaves create complexity.

**Fractal Brownian Motion (fBm)** - the technique of layering noise at different frequencies to build detailed, natural-looking textures.

---

## The Octave Concept

**Octave** = a layer of noise at a specific frequency and amplitude.

**Core Idea:**

```
# Base noise (single octave)
var noise1 = perlin_noise(x, y)  # Frequency 1, amplitude 1

# Add second octave (double frequency, half amplitude)
var noise2 = perlin_noise(x * 2, y * 2) * 0.5

# Combine
var result = noise1 + noise2

# Result: Large features (noise1) + fine detail (noise2)
```

**Musical analogy:** Like adding harmonics to a fundamental frequency - enriches the sound.

---

## Fractal Brownian Motion (fBm)

**fBm formula:** Sum multiple octaves with exponentially increasing frequency and decreasing amplitude.

**Code: Standard fBm**

```
func fbm(x: float, y: float, octaves: int = 6) -> float:
    var value = 0.0
    var amplitude = 1.0
    var frequency = 1.0
    var max_value = 0.0  # For normalization

    for i in range(octaves):
        value += perlin_noise(x * frequency, y * frequency) * amplitude

        max_value += amplitude
        amplitude *= 0.5  # Persistence (how much each octave contributes)
        frequency *= 2.0  # Lacunarity (frequency multiplier)

    return value / max_value  # Normalize to [0, 1]

# Result: Natural-looking terrain with multiple scales of detail
```

**Parameters:**
- **Octaves:** Number of layers (more = more detail, more expensive)
- **Persistence:** Amplitude multiplier per octave (default 0.5)
- **Lacunarity:** Frequency multiplier per octave (default 2.0)

---

## Persistence: Roughness Control

**Persistence** determines how