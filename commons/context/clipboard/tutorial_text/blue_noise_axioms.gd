extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Blue Noise[/b][/font_size][/center]
[center][i]Structured Randomness[/i][/center]

**Blue noise is random, but refuses to clump.** It's randomness with discipline - evenly spread, avoiding clusters, maximally dispersed.

**White noise is chaos. Blue noise is organized chaos.**

[hr]

[b]The Problem with Random Distribution[/b]

**Truly random placement creates clusters:**

[color=yellow][b]Code: Uniform Random (White Noise)[/b][/color]
[code]
# Place 100 points randomly
var points = []
for i in range(100):
    var x = randf() * 100
    var y = randf() * 100
    points.append(Vector2(x, y))

# Result: CLUMPY
# Some areas dense, others sparse
# Random ≠ evenly distributed
[/code]

**Why?** Each point is **independent** - doesn't know about others.
- Sometimes multiple points land near each other (cluster)
- Sometimes no points land in an area (void)

**Poisson clustering:** In truly random distribution, empty spaces and clusters are inevitable.

[hr]

[b]Blue Noise: Randomness with Constraints[/b]

**Blue noise:** Random distribution where points maintain minimum distance.

[color=yellow][b]Code: Simple Blue Noise (Dart Throwing)[/b][/color]
[code]
# Place points with minimum distance constraint
var points = []
var min_distance = 5.0
var max_attempts = 100

func add_blue_noise_point() -> bool:
    for attempt in range(max_attempts):
        var candidate = Vector2(randf() * 100, randf() * 100)

        # Check if too close to existing points
        var valid = true
        for existing in points:
            if candidate.distance_to(existing) < min_distance:
                valid = false
                break

        if valid:
            points.append(candidate)
            return true

    return false  # Failed to place point

# Place as many points as possible
while add_blue_noise_point():
    pass

# Result: Evenly spaced, no clusters, no large voids
# Still looks random (irregular), but organized
[/code]

**Properties:**
- **Random** (no grid pattern)
- **No clusters** (minimum distance enforced)
- **Efficient packing** (maximizes point count)
- **Organic appearance** (not obviously structured)

[hr]

[b]Frequency Domain: Why "Blue"?[/b]

**Color of noise = frequency spectrum:**

[color=yellow][b]Noise Types by Frequency:[/b][/color]
[code]
# White noise: All frequencies equally present (flat spectrum)
# - Looks: TV static, random scatter
# - Sound: Hiss, static

# Pink noise (1/f): Low frequencies stronger (1/f falloff)
# - Looks: Clouds, organic textures
# - Sound: Natural ambient (waterfall, rain)

# Blue noise: High frequencies stronger, low frequencies suppressed
# - Looks: Evenly spaced points, no large-scale clusters
# - Sound: Bright, airy (like sky/ocean - hence "blue")

# Red noise (Brownian): Very low frequencies (integrated white noise)
# - Looks: Smooth gradients, slow variation
# - Sound: Deep rumble
[/code]

**Blue noise suppresses low-frequency clumping** - no large-scale patterns, but allows high-frequency variation (point-to-point differences).

**Fourier transform of blue noise:** High-pass filtered - low frequencies removed.

[hr]

[b]Poisson Disk Sampling (Better Blue Noise)[/b]

**Dart throwing is slow.** **Poisson disk sampling** is faster:

[color=yellow][b]Code: Bridson's Algorithm (Fast Poisson Disk)[/b][/color]
[code]
# Fast Poisson disk sampling using spatial grid
var min_distance = 5.0
var grid_size = min_distance / sqrt(2)
var grid = {}  # Spatial hash grid
var active_list = []
var points = []

func poisson_disk_sample(width: float, height: float):
    # Add initial random point
    var initial = Vector2(randf() * width, randf() * height)
    points.append(initial)
    active_list.append(initial)
    add_to_grid(initial)

    while not active_list.is_empty():
        # Pick random active point
        var index = randi() % active_list.size()
        var center = active_list[index]
        var found = false

        # Try to place k candidates around it
        for i in range(30):
            var angle = randf() * TAU
            var radius = min_distance + randf() * min_distance
            var candidate = center + Vector2(cos(angle), sin(angle)) * radius

            # Check if candidate is valid
            if is_valid(candidate, width, height):
                points.append(candidate)
                active_list.append(candidate)
                add_to_grid(candidate)
                found = true
                break

        if not found:
            # No valid candidates, remove from active list
            active_list.remove_at(index)

    return points

func is_valid(point: Vector2, width: float, height: float) -> bool:
    # Check bounds
    if point.x < 0 or point.x >= width or point.y < 0 or point.y >= height:
        return false

    # Check nearby grid cells for conflicts
    var cell_x = int(point.x / grid_size)
    var cell_y = int(point.y / grid_size)

    for dx in range(-2, 3):
        for dy in range(-2, 3):
            var key = Vector2i(cell_x + dx, cell_y + dy)
            if grid.has(key):
                var neighbor = grid[key]
                if point.distance_to(neighbor) < min_distance:
                    return false

    return true

# Result: Fast, evenly distributed, no clusters
# O(n) time complexity (not O(n²) like dart throwing)
[/code]

**Bridson's algorithm:** Industry standard for blue noise generation (sampling, stippling, dithering).

[hr]

[b]Applications of Blue Noise[/b]

**1. Object Placement (Trees, Rocks, NPCs)**

[color=yellow][b]Code: Natural Forest[/b][/color]
[code]
# Place trees with blue noise
var tree_positions = poisson_disk_sample(1000, 1000)
for pos in tree_positions:
    var tree = tree_scene.instantiate()
    tree.position = Vector3(pos.x, 0, pos.y)
    add_child(tree)

# Result: Forest looks natural
# - No obvious grid pattern
# - No clustered clumps
# - No large empty clearings
# Much better than uniform random OR regular grid
[/code]

**2. Dithering (Image Processing)**

[color=yellow][b]Blue noise dithering:[/b][/color]
- Reduce color depth without banding
- Use blue noise threshold map instead of ordered Bayer matrix
- Result: Organic grain, no visible patterns

**3. Sampling (Ray Tracing, Monte Carlo)**

[color=yellow][b]Rendering:[/b][/color]
- Blue noise sample positions for anti-aliasing
- Better convergence than uniform random
- Fewer samples needed for smooth result

**4. Stippling (Artistic Pointillism)**

[color=yellow][b]Weighted blue noise:[/b][/color]
- Vary point density based on image brightness
- Dark areas: dense points
- Light areas: sparse points
- Creates shading through point distribution

[hr]

[b]Blue Noise vs Grid vs Random[/b]

[color=yellow][b]Comparison:[/b][/color]
[code]
# 1. Regular grid
# Pros: Perfectly even, predictable
# Cons: Obvious pattern, artificial looking
# Use: Architecture, UI layouts

# 2. Uniform random (white noise)
# Pros: Truly random, unpredictable
# Cons: Clusters and voids, uneven coverage
# Use: Particle systems, texture noise

# 3. Blue noise (Poisson disk)
# Pros: Even coverage, looks random, no clusters
# Cons: More expensive to generate
# Use: Object placement, sampling, dithering

# Metaphor:
# Grid = totalitarian order (every point in assigned place)
# Random = pure chaos (no structure)
# Blue noise = distributed autonomy (freedom with boundaries)
[/code]

**Blue noise is anarchist randomness** - no central authority, but mutual respect for space.

[hr]

[b]Generating Blue Noise Textures[/b]

**Create blue noise texture for dithering/sampling:**

[color=yellow][b]Code: Blue Noise Texture[/b][/color]
[code]
# Generate 256x256 blue noise texture
var texture_size = 256
var min_distance = 2.0

func generate_blue_noise_texture() -> Image:
    var img = Image.create(texture_size, texture_size, false, Image.FORMAT_L8)

    # Generate blue noise points
    var points = poisson_disk_sample(texture_size, texture_size)

    # Assign intensity values (0-255) sequentially
    points.sort_custom(func(a, b): return randf() < 0.5)  # Shuffle

    for i in range(points.size()):
        var pos = points[i]
        var intensity = int((i / float(points.size())) * 255)
        img.set_pixel(int(pos.x), int(pos.y), Color(intensity/255.0, 0, 0))

    return img

# Use in shader for dithering:
# if (color_value < texture(blue_noise, uv).r) {
#     output = dark_color
# } else {
#     output = light_color
# }
[/code]

**Result:** Organic dithering, no visible patterns, smooth gradients.

[hr]

[b]Weighted Blue Noise (Variable Density)[/b]

**Adapt point density based on importance map:**

[color=yellow][b]Code: Density-Varying Blue Noise[/b][/color]
[code]
# Place more points in "important" areas
var importance_map = load_importance_texture()

func weighted_poisson_disk_sample():
    # Similar to regular Poisson, but:
    # - min_distance varies by importance
    # - High importance → smaller min_distance → more points

    var points = []
    # ... (implementation similar to above, but min_distance = base_distance / importance)

    return points

# Example: Place more trees near path (player sees them more)
# - Path importance = 1.0 → dense trees
# - Far from path importance = 0.3 → sparse trees
# Still blue noise (no clusters), but variable density
[/code]

**Applications:**
- **Level of detail** (detail where player looks)
- **Crowd simulation** (density varies by location)
- **Stippling** (point density = shading)

[hr]

[b]3D Blue Noise (Spherical Poisson)[/b]

**Extend to 3D space:**

[color=yellow][b]Code: 3D Poisson Disk[/b][/color]
[code]
# Same algorithm, but Vector3 instead of Vector2
func poisson_disk_sample_3d(width: float, height: float, depth: float):
    # Use 3D spatial grid
    # Check spherical distance (not planar)
    # Result: Evenly distributed points in 3D volume
    pass  # (Implementation similar to 2D version)

# Use cases:
# - Particle system spawn positions
# - Star field generation
# - Volumetric sampling (fog, clouds)
[/code]

[hr]

[b]Blue Noise and Perception[/b]

**Why does blue noise look "better"?**

**Human vision is sensitive to patterns:**
- We notice regular grids immediately (artificial)
- We notice clusters (uneven, problematic)
- Blue noise appears "random" but feels "even"

**Blue noise matches natural distribution:**
- Trees in forest (compete for space)
- Stars in sky (minimum gravitational distance)
- Cells in tissue (packed but not overlapping)

**Goldilocks randomness:** Not too ordered, not too chaotic, just right.

[hr]

[b]Blue Noise as Social Space[/b]

**Metaphor:** Personal space boundaries in public.

[color=yellow][b]Social Poisson Disk:[/b][/color]
[code]
# People in park maintain minimum distance
# - Not grid (no assigned spots)
# - Not clustered (uncomfortable proximity)
# - Blue noise (random placement, but respectful spacing)

# min_distance = personal space bubble
# Each person "claims" circular area
# New arrivals find unclaimed space
[/code]

**Blue noise is spatial justice:**
- Everyone gets space
- No one forced into grid
- Freedom within constraints
- Anarchist distribution (no central planner, but mutual respect)

[hr]

[b]What Blue Noise Reveals[/b]

Blue noise shows us:

1. **Random ≠ evenly distributed** - Clusters appear in uniform random
2. **Constraints create quality** - Minimum distance improves appearance
3. **Organized chaos is possible** - Random yet structured
4. **Fast algorithms exist** - Bridson's Poisson disk is O(n)
5. **Perceptually better** - Humans prefer even randomness
6. **Natural distributions are blue** - Trees, stars, cells avoid clustering
7. **Anarchist space model** - Freedom with mutual respect, no central authority

**White noise:** Pure chaos, no structure, clumping.
**Grid:** Pure order, rigid structure, artificial.
**Blue noise:** Organized autonomy, even randomness, natural.

**Blue noise is queer randomness** - refuses binary (order/chaos), occupies liminal space between structure and freedom, looks natural because it respects boundaries without imposing grids.

[hr]

[color=cyan][b]Summary:[/b][/color]
Blue noise is random distribution with minimum distance constraint between points. Avoids clusters and voids, appearing evenly spread. "Blue" refers to high-pass frequency spectrum (suppresses low-frequency clumping). Poisson disk sampling (Bridson's algorithm) generates blue noise efficiently O(n). Used for object placement, dithering, ray tracing sampling, and stippling. Better perceptual quality than uniform random or grid. Natural distributions (trees, stars) are approximately blue noise. Metaphor: distributed autonomy - freedom with boundaries, no central authority.

[hr]

[color=orange][b]Next:[/b] Random Walks[/color]
If blue noise enforces spatial structure, random walks embrace temporal randomness - paths that wander without destination, accumulating entropy step by step. Brownian motion as computational drift.

'''
