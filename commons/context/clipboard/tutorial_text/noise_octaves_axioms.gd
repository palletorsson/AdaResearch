extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Noise Octaves[/b][/font_size][/center]
[center][i]Fractal Layering and fBm[/i][/center]

**Single-octave noise is simple.** Multiple octaves create complexity.

**Fractal Brownian Motion (fBm)** - the technique of layering noise at different frequencies to build detailed, natural-looking textures.

[hr]

[b]The Octave Concept[/b]

**Octave** = a layer of noise at a specific frequency and amplitude.

[color=yellow][b]Core Idea:[/b][/color]
[code]
# Base noise (single octave)
var noise1 = perlin_noise(x, y)  # Frequency 1, amplitude 1

# Add second octave (double frequency, half amplitude)
var noise2 = perlin_noise(x * 2, y * 2) * 0.5

# Combine
var result = noise1 + noise2

# Result: Large features (noise1) + fine detail (noise2)
[/code]

**Musical analogy:** Like adding harmonics to a fundamental frequency - enriches the sound.

[hr]

[b]Fractal Brownian Motion (fBm)[/b]

**fBm formula:** Sum multiple octaves with exponentially increasing frequency and decreasing amplitude.

[color=yellow][b]Code: Standard fBm[/b][/color]
[code]
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
[/code]

**Parameters:**
- **Octaves:** Number of layers (more = more detail, more expensive)
- **Persistence:** Amplitude multiplier per octave (default 0.5)
- **Lacunarity:** Frequency multiplier per octave (default 2.0)

[hr]

[b]Persistence: Roughness Control[/b]

**Persistence** determines how "rough" vs "smooth" the result is.

[color=yellow][b]Low Persistence (0.3):[/b][/color]
[code]
amplitude *= 0.3  # Each octave contributes less

# Result: SMOOTH
# - Large features dominate
# - Fine detail barely visible
# - Like: rolling hills, gentle waves
[/code]

[color=yellow][b]High Persistence (0.7):[/b][/color]
[code]
amplitude *= 0.7  # Each octave contributes more

# Result: ROUGH
# - Fine detail prominent
# - Jagged, chaotic appearance
# - Like: rocky mountains, turbulent water
[/code]

**Persistence = roughness slider** - 0.5 is balanced, < 0.5 is smooth, > 0.5 is rough.

[hr]

[b]Lacunarity: Frequency Gaps[/b]

**Lacunarity** controls frequency increase between octaves.

[color=yellow][b]Low Lacunarity (1.5):[/b][/color]
[code]
frequency *= 1.5  # Gradual frequency increase

# Result: Dense detail, all scales visible
# Smooth transition between octaves
# Like: clouds, organic textures
[/code]

[color=yellow][b]High Lacunarity (3.0):[/b][/color]
[code]
frequency *= 3.0  # Rapid frequency increase

# Result: Distinct scales, visible "steps"
# Large gaps between octave frequencies
# Like: fractal art, abstract patterns
[/code]

**Lacunarity = 2.0 is standard** - each octave doubles frequency (one "octave" in musical terms).

[hr]

[b]Octave Count: Detail vs Performance[/b]

**More octaves = more detail, but expensive:**

[color=yellow][b]Comparison:[/b][/color]
[code]
# 1 octave: Smooth blobs, no detail
var oct1 = fbm(x, y, 1)

# 3 octaves: Basic terrain features
var oct3 = fbm(x, y, 3)

# 6 octaves: Rich detail, natural-looking
var oct6 = fbm(x, y, 6)

# 12 octaves: Extreme detail, very expensive
var oct12 = fbm(x, y, 12)
[/code]

**Diminishing returns:** Beyond 6-8 octaves, added detail barely visible.

**Rule of thumb:**
- **Terrain:** 4-6 octaves
- **Clouds:** 3-4 octaves
- **Textures:** 6-8 octaves
- **Extreme detail:** 10+ octaves (rarely needed)

[hr]

[b]Turbulence: Absolute Value[/b]

**Turbulence** = take absolute value of noise before summing.

[color=yellow][b]Code: Turbulent fBm[/b][/color]
[code]
func turbulence(x: float, y: float, octaves: int = 6) -> float:
    var value = 0.0
    var amplitude = 1.0
    var frequency = 1.0
    var max_value = 0.0

    for i in range(octaves):
        var noise_value = perlin_noise(x * frequency, y * frequency)
        value += abs(noise_value) * amplitude  # Absolute value!

        max_value += amplitude
        amplitude *= 0.5
        frequency *= 2.0

    return value / max_value

# Result: Sharp ridges, turbulent appearance
# Like: marble veins, wood grain, turbulent flow
[/code]

**Effect:** Negatives become positives → sharp "V" shapes instead of smooth curves.

**Applications:** Wood grain, marble, fire, turbulent fluids.

[hr]

[b]Ridged Multifractal[/b]

**Ridged noise** creates sharp mountain ridges:

[color=yellow][b]Code: Ridged fBm[/b][/color]
[code]
func ridged_fbm(x: float, y: float, octaves: int = 6) -> float:
    var value = 0.0
    var amplitude = 1.0
    var frequency = 1.0
    var weight = 1.0

    for i in range(octaves):
        var noise_value = perlin_noise(x * frequency, y * frequency)

        # Invert and sharpen
        noise_value = 1.0 - abs(noise_value)
        noise_value = noise_value * noise_value  # Square to sharpen peaks

        # Weight by previous octave
        noise_value *= weight
        weight = clamp(noise_value * 2.0, 0.0, 1.0)

        value += noise_value * amplitude
        amplitude *= 0.5
        frequency *= 2.0

    return value

# Result: Sharp peaks, flat valleys
# Like: mountain ranges, erosion patterns
[/code]

**Key:** Inverted abs + weighting creates sharp ridges.

[hr]

[b]Domain Warping with fBm[/b]

**Use fBm to distort fBm coordinates:**

[color=yellow][b]Code: Domain Warping[/b][/color]
[code]
func domain_warped_fbm(x: float, y: float) -> float:
    # First layer of fBm for warping
    var warp_x = fbm(x + 0, y + 0, 4) * 2.0
    var warp_y = fbm(x + 5.2, y + 1.3, 4) * 2.0

    # Second layer using warped coordinates
    var warped = fbm(x + warp_x, y + warp_y, 6)

    return warped

# Result: Swirling, organic patterns
# Like: clouds, smoke, flowing lava
# Much more natural than straight fBm
[/code]

**Domain warping = using noise to distort noise** - creates complex, flowing patterns.

[hr]

[b]Selective Octaves: Frequency Bands[/b]

**Don't always need all octaves:**

[color=yellow][b]Code: Octave Filtering[/b][/color]
[code]
# Skip low frequencies (only detail, no large features)
func high_frequency_noise(x: float, y: float) -> float:
    var value = 0.0
    var amplitude = 0.25  # Start at 4th octave
    var frequency = 8.0

    for i in range(3):  # 3 high-frequency octaves
        value += perlin_noise(x * frequency, y * frequency) * amplitude
        amplitude *= 0.5
        frequency *= 2.0

    return value

# Result: Fine detail only, no large blobs
# Use case: Add detail to existing terrain without changing large shapes
[/code]

**Octave selection** = frequency band filtering - control which scales of detail to include.

[hr]

[b]Combining Different Noise Types[/b]

**Mix Perlin, Worley, Value, Simplex in octaves:**

[color=yellow][b]Code: Hybrid Octaves[/b][/color]
[code]
func hybrid_fbm(x: float, y: float) -> float:
    var value = 0.0

    # Large features: Perlin (smooth)
    value += perlin_noise(x * 1, y * 1) * 1.0

    # Medium features: Simplex (less regular)
    value += simplex_noise(x * 2, y * 2) * 0.5

    # Fine detail: Worley (cellular texture)
    value += worley_F1(x * 8, y * 8) * 0.1

    return value / 1.6  # Normalize

# Result: Smooth large shapes + cellular fine detail
# Best of multiple noise types
[/code]

**No rule says all octaves must use same noise function!**

[hr]

[b]3D Octaves for Volumetric Effects[/b]

**fBm works in 3D for clouds, fog, volumetric terrain:**

[color=yellow][b]Code: 3D fBm[/b][/color]
[code]
func fbm_3d(x: float, y: float, z: float, octaves: int = 4) -> float:
    var value = 0.0
    var amplitude = 1.0
    var frequency = 1.0
    var max_value = 0.0

    for i in range(octaves):
        value += perlin_noise_3d(x * frequency, y * frequency, z * frequency) * amplitude

        max_value += amplitude
        amplitude *= 0.5
        frequency *= 2.0

    return value / max_value

# Use case: Volumetric clouds
func cloud_density(pos: Vector3) -> float:
    var density = fbm_3d(pos.x * 0.5, pos.y * 0.5, pos.z * 0.5, 4)
    return max(0, density - 0.3)  # Threshold for clouds

# Result: Puffy, detailed 3D clouds
[/code]

**3D fBm is expensive** - use fewer octaves (3-4 max) for real-time.

[hr]

[b]Time-Animated fBm[/b]

**Add time dimension for flowing, evolving noise:**

[color=yellow][b]Code: Animated Noise[/b][/color]
[code]
func animated_fbm(x: float, y: float, time: float) -> float:
    # Sample 3D noise using (x, y, time) as coordinates
    return fbm_3d(x, y, time * 0.1, 6)

# OR: Offset coordinates by time
func animated_fbm_2d(x: float, y: float, time: float) -> float:
    var offset_x = time * 0.05
    var offset_y = time * 0.03  # Different speeds for more natural flow
    return fbm(x + offset_x, y + offset_y, 6)

# Result: Smoothly evolving noise over time
# Like: flowing lava, drifting clouds, waving grass
[/code]

**Animating noise** = treating time as a spatial dimension.

[hr]

[b]Performance Optimizations[/b]

**fBm is expensive (multiple noise samples per pixel):**

[color=yellow][b]1. Bake to Texture[/b][/color]
- Precompute fBm, store in texture
- Sample texture at runtime
- Trade memory for speed

[color=yellow][b]2. Level of Detail (LOD)[/b][/color]
[code]
# Use fewer octaves when distant
var distance_to_camera = (pos - camera_pos).length()
var octave_count = int(lerp(6, 2, distance_to_camera / 100.0))
var noise = fbm(x, y, octave_count)

# Result: 6 octaves nearby, 2 octaves distant
# Significant performance save
[/code]

[color=yellow][b]3. Spatial Coherence[/b][/color]
- Reuse noise calculations for nearby pixels
- Cache intermediate octaves
- Use mipmaps for texture-based noise

[hr]

[b]What Noise Octaves Reveal[/b]

Noise octaves show us:

1. **Detail is layering** - Complexity from stacking simple patterns
2. **Persistence controls roughness** - < 0.5 smooth, > 0.5 rough
3. **Lacunarity sets scale gaps** - 2.0 is standard (musical octave)
4. **Diminishing returns** - Beyond 6-8 octaves, barely noticeable
5. **Turbulence creates ridges** - Absolute value sharpens features
6. **Domain warping adds naturalism** - Noise distorting noise = organic flow
7. **Mix noise types** - Each octave can use different function

**fBm is fractal** - self-similar at different scales, like nature (coastlines, mountains, trees).

**Single octave is boring, many octaves is expensive** - sweet spot is 4-6 for real-time.

[hr]

[color=cyan][b]Summary:[/b][/color]
Fractal Brownian Motion (fBm) layers multiple noise octaves at increasing frequency and decreasing amplitude. Persistence (amplitude multiplier) controls roughness. Lacunarity (frequency multiplier) controls scale gaps. Standard: persistence 0.5, lacunarity 2.0, 4-6 octaves. Turbulence uses abs() for sharp ridges. Ridged multifractal creates mountain peaks. Domain warping (noise distorting noise) creates organic flow. Can mix different noise types per octave. 3D fBm for volumetric effects. Time animation via extra dimension or coordinate offset.

[hr]

[color=orange][b]Next:[/b] Shader Noise - GPU Randomness[/color]
CPU noise is expensive. GPU noise is parallel - thousands of pixels simultaneously. Hash functions, procedural generation, real-time material shaders.

'''
