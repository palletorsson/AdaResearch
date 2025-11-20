extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Noise[/b][/font_size][/center]
[center][i]Structured Randomness, Entropy Tamed[/i][/center]

**White noise** is pure entropy - every sample independent, completely random, maximum disorder.

**Perlin/Simplex noise** is **structured randomness** - smooth, continuous, correlated. It looks organic, natural, like terrain, clouds, marble.

Noise is **entropy with continuity constraints** - randomness that flows smoothly from point to point, creating patterns without repetition.

**This is randomness tamed into usefulness** - still unpredictable, but coherent enough to generate terrain, textures, procedural content.

[hr]

[b]White Noise vs Smooth Noise[/b]

**White noise** - every sample independent:

[color=yellow][b]Code: Maximum Disorder[/b][/color]
[code]
# White noise: each value random, no correlation
func white_noise(x: float) -> float:
    return randf()  # Completely random

# Values at nearby positions totally different:
# white_noise(5.0) = 0.7234
# white_noise(5.1) = 0.2156  # No relationship
[/code]

**Perlin noise** - smooth interpolation between random values:

[color=yellow][b]Code: Structured Disorder[/b][/color]
[code]
# Perlin noise: smooth gradients between random grid points
var noise = FastNoiseLite.new()
noise.noise_type = FastNoiseLite.TYPE_PERLIN

func smooth_noise(x: float) -> float:
    return noise.get_noise_1d(x)

# Values at nearby positions smoothly related:
# smooth_noise(5.0) = 0.4521
# smooth_noise(5.1) = 0.4683  # Gradual change, continuous
[/code]

**White noise = chaotic static**
**Smooth noise = organic undulation**

[hr]

[b]Perlin Noise: Grid + Gradient + Interpolation[/b]

Perlin noise (Ken Perlin, 1983) works by:
1. **Grid** - Divide space into grid cells
2. **Random gradients** - Assign random direction vector to each grid corner
3. **Interpolation** - Smoothly blend between gradients

[color=yellow][b]The Mechanism:[/b][/color]
[code]
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
[/code]

**Perlin is hybrid:**
- **Random** (gradients at grid points)
- **Deterministic** (interpolation between them)
- **Continuous** (no discontinuities)

**Entropy structured by smoothness constraint.**

[hr]

[b]Octaves: Layering Frequencies[/b]

To create rich, detailed noise, **layer multiple frequencies** (octaves):

[color=yellow][b]Code: Fractal Noise[/b][/color]
[code]
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
[/code]

**Octaves create fractal-like detail** - self-similar patterns at multiple scales.

One octave = smooth rolling hills
Four octaves = mountains with ridges and valleys
Eight octaves = detailed rocky terrain

**Each octave adds one "dimension" of variation** - more frequencies = more complexity.

[hr]

[b]Terrain from Noise: Heightmap[/b]

The classic use: **2D noise as height values** creates terrain.

[color=yellow][b]Code: Landscape from Randomness[/b][/color]
[code]
var noise = FastNoiseLite.new()
noise.frequency = 0.01
noise.fractal_octaves = 4

# Generate terrain mesh
func create_terrain(width: int, depth: int) -> MeshInstance3D:
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

    # For each grid position
    for z in range(depth):
        for x in range(width):
            # Sample noise for height
            var height = noise.get_noise_2d(x, z) * 10.0

            # Create vertex
            var vertex = Vector3(x, height, z)
            surface_tool.add_vertex(vertex)

    # Connect vertices into triangles...
    return create_mesh_from_surface(surface_tool)

# Result: Mountains, valleys, plateaus
# Completely from structured randomness
[/code]

**Noise converts entropy to geometry** - random values become spatial forms.

[hr]

[b]Textures from Noise: Procedural Materials[/b]

**3D noise** (x, y, z inputs) creates volumetric textures:

[color=yellow][b]Code: Marble, Wood, Clouds[/b][/color]
[code]
# Marble: use noise to distort stripes
func marble_texture(x: float, y: float, z: float) -> Color:
    var noise_value = noise.get_noise_3d(x, y, z)

    # Sine wave distorted by noise
    var pattern = sin((x + noise_value * 5.0) * 0.1)

    # Map to color (dark to light marble)
    var brightness = (pattern + 1.0) / 2.0
    return Color(brightness, brightness, brightness * 0.9)

# Wood: cylindrical noise rings
# Clouds: multiple octaves at different densities
# Stone: high-frequency noise with sharp cutoffs
[/code]

**Noise as material generator** - organic textures from mathematical randomness.

No need to store huge texture images - generate on-demand from noise functions.

[hr]

[b]Simplex Noise: Perlin's Successor[/b]

**Simplex noise** (Ken Perlin, 2001) improves on Perlin:
- **Faster** (fewer gradient samples)
- **Higher dimensions** (scales better to 4D, 5D)
- **No directional artifacts** (Perlin has visible grid alignment)

[color=yellow][b]Code: Simplex vs Perlin[/b][/color]
[code]
# Perlin uses square/cube grid
var perlin = FastNoiseLite.new()
perlin.noise_type = FastNoiseLite.TYPE_PERLIN

# Simplex uses triangular/tetrahedral grid
var simplex = FastNoiseLite.new()
simplex.noise_type = FastNoiseLite.TYPE_SIMPLEX

# Visually similar, but simplex:
# - Runs faster
# - Better for animation (4D: x, y, z, time)
# - Less directional bias
[/code]

**Simplex is optimization** - same organic smoothness, better computational efficiency.

[hr]

[b]Cellular Noise (Worley Noise): Distance Fields[/b]

**Cellular noise** (Steven Worley, 1996) based on distance to random points:

[color=yellow][b]Code: Voronoi Cells[/b][/color]
[code]
# Place random seed points
var seed_points = []
for i in range(20):
    seed_points.append(Vector2(randf() * 100, randf() * 100))

# For any position, find distance to nearest seed
func cellular_noise(pos: Vector2) -> float:
    var min_dist = INF

    for seed in seed_points:
        var dist = pos.distance_to(seed)
        if dist < min_dist:
            min_dist = dist

    return min_dist

# Result: Voronoi diagram
# Cell structure (like biological cells, stone cracks)
[/code]

**Cellular noise creates organic cell patterns** - different from smooth gradients of Perlin.

Used for: rock textures, water caustics, biological patterns, cracked earth.

[hr]

[b]What Noise Cannot Generate[/b]

Noise is **statistically random** but **spatially continuous**.

It cannot create:
- **Sharp edges** (always smooth gradients)
- **Discrete patterns** (always continuous fields)
- **Intentional structure** (no symmetry, no planned shapes)
- **Text or symbols** (too ordered for noise alone)

**Noise generates organic, not geometric.**

It creates **natural-looking** forms (terrain, clouds, wood grain) but not **designed** forms (buildings, circuits, written language).

[hr]

[b]Noise as Controlled Entropy[/b]

**White noise** = maximum entropy (every sample independent)
**Perlin noise** = controlled entropy (smoothness constraint)

[color=yellow][b]The Trade-Off:[/b][/color]
[code]
# White noise: high entropy, no structure
var entropy_white = measure_entropy(white_noise_samples)  # HIGH

# Perlin noise: reduced entropy, but structured
var entropy_perlin = measure_entropy(perlin_noise_samples)  # MEDIUM

# Pattern: zero entropy, full structure
var entropy_pattern = measure_entropy(checkerboard_pattern)  # LOW

# Noise occupies middle ground:
# - More ordered than white noise
# - Less ordered than intentional pattern
# - Just right for organic appearance
[/code]

**Noise is the Goldilocks zone** between chaos and order.

Too random → incoherent (white noise)
Too ordered → artificial (patterns)
**Just right → organic** (smooth noise)

[hr]

[b]Turing Morphogenesis Revisited[/b]

Turing showed patterns emerge from **reaction-diffusion + random initial conditions**.

**Noise provides those initial conditions:**

[color=yellow][b]Code: Pattern from Randomness[/b][/color]
[code]
# Start with noise as initial state
var initial_state = []
for i in range(1000):
    initial_state.append(noise.get_noise_1d(i))

# Apply reaction-diffusion rules iteratively
for iteration in range(100):
    apply_reaction_diffusion(initial_state)

# After many iterations:
# → Spots, stripes, spirals emerge
# → Noise (randomness) → Pattern (structure)
# → Entropy → Order (with energy input)
[/code]

**Noise is the seed of morphogenesis** - structured randomness that enables pattern emergence.

[hr]

[b]What Noise Reveals[/b]

Noise shows us:

1. **Entropy can be structured** - Randomness with continuity constraint
2. **Smooth chaos is organic** - Perlin/Simplex feel natural
3. **Octaves add detail** - Fractal layering creates complexity
4. **Geometry from randomness** - Terrain, textures, clouds from noise functions
5. **Computation replaces storage** - Generate infinite variation from algorithm
6. **Middle ground between order and chaos** - Not white noise, not pattern
7. **Initial conditions for emergence** - Noise enables Turing morphogenesis

**Noise is entropy made useful** - random enough to avoid repetition, smooth enough to appear natural, structured enough to generate coherent forms.

**It is the algorithm's way of creating organic appearance** - simulating nature's irregularity through controlled randomness.

[hr]

[color=cyan][b]Summary:[/b][/color]
Noise is structured randomness - smooth, continuous, unlike white noise (independent samples). Perlin noise uses grid of random gradients with smooth interpolation. Octaves (multiple frequencies layered) create fractal detail. Used for terrain (heightmaps), textures (marble, wood, clouds), procedural content. Simplex noise improves Perlin (faster, higher dimensions). Cellular noise creates Voronoi patterns. Noise occupies middle ground between chaos (white noise) and order (patterns) - organic appearance from controlled entropy.

[hr]

[color=orange][b]Conclusion:[/b] Randomness Spectrum[/color]

**Entropy** → High-dimensional freedom, disorder as vital
**PRNG** → Deterministic chaos, seed as control
**Noise** → Structured randomness, smooth entropy

From maximum disorder to controlled variation to intentional pattern.
From white noise to Perlin to geometric order.

Randomness is not binary (random vs not). It is a **spectrum**:
- Material entropy (TRNG)
- Algorithmic simulation (PRNG)
- Smooth variation (noise)
- Fractal detail (octaves)
- Emergent pattern (morphogenesis)
- Intentional design

**We navigate this spectrum** - choosing how much chaos, how much control, how much freedom the algorithm permits.

'''
