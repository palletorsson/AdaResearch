extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Worley Noise[/b][/font_size][/center]
[center][i]Cellular Patterns and Distance Fields[/i][/center]

**Worley noise** (also called **Voronoi noise** or **cellular noise**) divides space into cells around random points.

Not smooth gradients - sharp boundaries, organic cells, natural cracks.

[hr]

[b]The Core Concept: Distance to Nearest Point[/b]

**Algorithm:**
1. Scatter random points in space (feature points)
2. For any sample position, find distance to nearest feature point
3. Distance = noise value

[color=yellow][b]Code: Basic 2D Worley Noise[/b][/color]
[code]
# Scatter feature points in grid cells
func get_feature_point(cell_x: int, cell_y: int) -> Vector2:
    # Random offset within cell [0, 1] Ã— [0, 1]
    var hash_x = hash_2d(cell_x, cell_y)
    var hash_y = hash_2d(cell_x + 1, cell_y + 1)
    return Vector2(cell_x + hash_x, cell_y + hash_y)

func worley_noise_2d(x: float, y: float) -> float:
    var cell_x = int(floor(x))
    var cell_y = int(floor(y))

    var min_dist = INF

    # Check 3Ã—3 grid of cells (current + neighbors)
    for offset_y in range(-1, 2):
        for offset_x in range(-1, 2):
            var neighbor_x = cell_x + offset_x
            var neighbor_y = cell_y + offset_y

            var feature_point = get_feature_point(neighbor_x, neighbor_y)
            var diff = Vector2(x, y) - feature_point
            var dist = diff.length()

            if dist < min_dist:
                min_dist = dist

    return min_dist

# Result: Distance field - values increase away from feature points
# Creates cell boundaries where distances are equal
[/code]

**Key insight:** Where two cells meet, distances to their feature points are equal â†’ boundary.

[hr]

[b]F1, F2, F2-F1: Distance Metrics[/b]

**Different combinations create different patterns:**

[color=yellow][b]F1: Distance to Closest Point[/b][/color]
[code]
func worley_F1(_x: float, y: float) -> float:
    # Return distance to NEAREST feature point
    return min_dist  # As computed above

# Result: Smooth cells with sharp boundaries
# Dark at feature points, bright at boundaries
# Like: cells, bubbles, stone texture
[/code]

[color=yellow][b]F2: Distance to Second-Closest Point[/b][/color]
[code]
func worley_F2(_x: float, y: float) -> float:
    var distances = []

    # Collect all distances
    for neighbor in neighbors:
        var dist = (sample_pos - feature_point).length()
        distances.append(dist)

    distances.sort()
    return distances[1]  # Second smallest

# Result: Boundaries emphasized, cell centers de-emphasized
# Creates "ridges" at boundaries
[/code]

[color=yellow][b]F2 - F1: Difference (Edge Detection)[/b][/color]
[code]
func worley_F2_minus_F1(_x: float, y: float) -> float:
    var distances = []
    # ... collect distances ...
    distances.sort()
    return distances[1] - distances[0]

# Result: ONLY the boundaries visible
# Zero in cell centers, non-zero at edges
# Perfect for cracks, veins, cell walls
[/code]

**F2-F1 isolates boundaries** - removes cells, keeps only cracks.

[hr]

[b]Distance Functions[/b]

**Different distance metrics create different cell shapes:**

[color=yellow][b]1. Euclidean (Natural, Circular)[/b][/color]
[code]
func euclidean_distance(a: Vector2, b: Vector2) -> float:
    var diff = b - a
    return diff.length()  # sqrt(dxÂ² + dyÂ²)

# Result: Natural circular cells
# Most organic-looking
[/code]

[color=yellow][b]2. Manhattan (Grid-Aligned, Crystalline)[/b][/color]
[code]
func manhattan_distance(a: Vector2, b: Vector2) -> float:
    var diff = b - a
    return abs(diff.x) + abs(diff.y)

# Result: Square/diamond cells
# Crystalline, architectural
# Cheaper (no sqrt)
[/code]

[color=yellow][b]3. Chebyshev (Square Cells)[/b][/color]
[code]
func chebyshev_distance(a: Vector2, b: Vector2) -> float:
    var diff = b - a
    return max(abs(diff.x), abs(diff.y))

# Result: Perfect square cells
# Grid-like, regular
# Very cheap
[/code]

[color=yellow][b]4. Minkowski (Interpolate Between)[/b][/color]
[code]
func minkowski_distance(a: Vector2, b: Vector2, p: float) -> float:
    var diff = b - a
    return pow(pow(abs(diff.x), p) + pow(abs(diff.y), p), 1.0 / p)

# p=1: Manhattan
# p=2: Euclidean
# p=âˆž: Chebyshev
# p=0.5: Star-shaped cells (interesting!)
[/code]

**Distance function = cell shape** - fundamental control over appearance.

[hr]

[b]Applications[/b]

**Worley noise creates organic patterns:**

[color=yellow][b]1. Stone/Rock Texture[/b][/color]
[code]
# F1 with slight noise modulation
var base = worley_F1(x, y)
var detail = perlin_noise(x * 10, y * 10) * 0.1
var stone_texture = base + detail

# Result: Rocky surface with natural variation
[/code]

[color=yellow][b]2. Cell Membranes/Biological[/b][/color]
[code]
# F2 - F1 for cell boundaries
var cell_walls = worley_F2_minus_F1(x, y)
var thickness = 0.05
var cell_pattern = smoothstep(0, thickness, cell_walls)

# Result: Biological cell structure
# Like: onion cells, foam, coral
[/code]

[color=yellow][b]3. Cracks/Veins[/b][/color]
[code]
# F2 - F1, inverted
var cracks = 1.0 - worley_F2_minus_F1(x, y)
cracks = pow(cracks, 4.0)  # Make cracks thinner

# Result: Thin cracks, thick solid areas
# Like: dried mud, marble veins, lightning
[/code]

[color=yellow][b]4. Water Caustics[/b][/color]
[code]
# Animated Worley noise
var time_offset = time * 0.1
var caustic1 = worley_F2_minus_F1(x + time_offset, y)
var caustic2 = worley_F2_minus_F1(x, y + time_offset)
var caustics = min(caustic1, caustic2)

# Result: Shifting, overlapping light patterns
# Like: sunlight through water surface
[/code]

[hr]

[b]3D Worley Noise[/b]

**Extend to volumetric:**

[color=yellow][b]Code: 3D Worley[/b][/color]
[code]
func worley_noise_3d(x: float, y: float, z: float) -> float:
    var cell_x = int(floor(x))
    var cell_y = int(floor(y))
    var cell_z = int(floor(z))

    var min_dist = INF

    # Check 3Ã—3Ã—3 grid of cells
    for oz in range(-1, 2):
        for oy in range(-1, 2):
            for ox in range(-1, 2):
                var feature_point = get_feature_point_3d(
                    cell_x + ox,
                    cell_y + oy,
                    cell_z + oz
                )
                var diff = Vector3(x, y, z) - feature_point
                var dist = diff.length()

                if dist < min_dist:
                    min_dist = dist

    return min_dist

# Result: 3D cellular structure
# Like: foam, bubbles, organic tissue
[/code]

**Use case:** Volumetric clouds, organic meshes, 3D textures.

[hr]

[b]Combining with Other Noise[/b]

**Worley + Perlin = powerful:**

[color=yellow][b]1. Domain Warping[/b][/color]
[code]
# Use Perlin to distort Worley coordinates
var warp_x = perlin_noise(x * 0.5, y * 0.5) * 2.0
var warp_y = perlin_noise(x * 0.5 + 100, y * 0.5) * 2.0

var warped_worley = worley_F1(x + warp_x, y + warp_y)

# Result: Organic, flowing cells
# No longer perfect Voronoi, more natural
[/code]

[color=yellow][b]2. Layered Detail[/b][/color]
[code]
# Large Worley cells + small Perlin detail
var cells = worley_F1(x * 2, y * 2)
var detail = perlin_noise(x * 10, y * 10) * 0.2
var result = cells + detail

# Result: Cell structure with fine texture
# Like: weathered stone, aged material
[/code]

[color=yellow][b]3. Selective Masking[/b][/color]
[code]
# Use Worley to mask other effects
var cells = worley_F1(x, y)
var base_color = Color.GRAY
var cell_color = Color.WHITE

var final_color = lerp(base_color, cell_color, smoothstep(0.3, 0.5, cells))

# Result: Different materials per cell
# Like: tiles, scales, segmented armor
[/code]

[hr]

[b]Optimizations[/b]

**Worley noise is expensive (many distance calculations):**

[color=yellow][b]1. Spatial Hashing[/b][/color]
- Only check nearby cells (3Ã—3 in 2D, 3Ã—3Ã—3 in 3D)
- Don't check entire space
- Feature points stored in grid structure

[color=yellow][b]2. Early Exit[/b][/color]
[code]
# If current min_dist is very small, stop checking
if min_dist < 0.01:
    break  # Close enough to feature point

# Saves checking distant cells
[/code]

[color=yellow][b]3. Texture Baking[/b][/color]
- Precompute Worley noise to texture
- Sample texture at runtime (very fast)
- Trade memory for speed

[color=yellow][b]4. Lower Resolution[/b][/color]
- Compute Worley at half resolution
- Upscale with filtering
- Add high-frequency detail with cheap noise

[hr]

[b]Jittered Grid vs Pure Random[/b]

**Feature point placement strategy:**

[color=yellow][b]Jittered Grid (Standard Worley)[/b][/color]
[code]
# One point per grid cell, randomly placed within cell
func get_feature_point(cell_x: int, cell_y: int) -> Vector2:
    var rand_x = hash_2d(cell_x, cell_y)
    var rand_y = hash_2d(cell_x + 1, cell_y + 1)
    return Vector2(cell_x + rand_x, cell_y + rand_y)

# Pros: Predictable cell count, consistent sizing
# Cons: Grid structure slightly visible
[/code]

[color=yellow][b]Poisson Disk (Better, More Expensive)[/b][/color]
- Use Poisson disk sampling for feature points
- More uniform distribution
- No grid artifacts
- Much more expensive to compute

**Trade-off:** Jittered grid is standard - good enough, fast.

[hr]

[b]Cellular Noise in Nature[/b]

**Why does Worley look organic?**

**Nature creates Voronoi patterns:**
- **Giraffe spots:** Turing patterns converge to Voronoi
- **Dragonfly wings:** Cell growth creates natural tessellation
- **Cracked mud:** Shrinkage cracks follow minimum energy paths (Voronoi)
- **Soap bubbles:** Surface tension minimizes area â†’ Voronoi structure
- **Plant cells:** Growth pressure creates polygonal packing

**Worley noise mimics natural cell formation** - not just aesthetic, but physically grounded.

[hr]

[b]What Worley Noise Reveals[/b]

Worley noise shows us:

1. **Distance fields are textures** - Not just gradient interpolation
2. **Boundaries emerge from equality** - Cell walls where distances match
3. **Metric changes everything** - Euclidean vs Manhattan = organic vs crystalline
4. **F1 vs F2 vs F2-F1** - Different combinations, wildly different results
5. **Nature is Voronoi** - Biological patterns follow minimum-distance logic
6. **Expensive but worth it** - Many distance checks, but unique aesthetic
7. **Combines well** - Worley + Perlin = powerful hybrid

**Worley noise is spatial competition** - each feature point claims territory, boundaries form where claims meet.

**Perlin is smooth gradients, Worley is sharp territories** - complementary, not competitive.

[hr]

[color=cyan][b]Summary:[/b][/color]
Worley/Voronoi/cellular noise based on distance to nearest random feature point. F1 (nearest), F2 (second-nearest), F2-F1 (boundary detection) create different patterns. Distance metric (Euclidean, Manhattan, Chebyshev) determines cell shape. Applications: stone texture, cell membranes, cracks, caustics. Extends to 3D for volumetric effects. Combines well with Perlin via domain warping or layering. Computationally expensive (many distance checks), but produces unique organic patterns. Mimics natural Voronoi structures (soap bubbles, cracked mud, biological cells).

[hr]

[color=orange][b]Next:[/b] Noise Octaves - Fractal Layering[/color]
Single-octave noise is simple. Multiple octaves create complexity - fractal Brownian motion (fBm), turbulence, ridges. Layering frequencies to build detail.

'''
