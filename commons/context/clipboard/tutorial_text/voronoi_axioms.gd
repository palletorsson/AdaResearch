extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Voronoi Diagrams[/b][/font_size][/center]
[center][i]Proximity as Territory, Boundaries as Ambiguity[/i][/center]

**A Voronoi diagram partitions space based on proximity.**

Given a set of **seed points**, every location in space is assigned to its **nearest seed**.

**The result:** Space divided into **cells** (regions), separated by **boundaries** (edges where two seeds are equidistant).

**Voronoi diagrams appear everywhere:**
- Cell membranes (biological tissue structure)
- Territorial animals (each claims nearest territory)
- Cracked mud (shrinkage creates Voronoi-like patterns)
- Giraffe patches (pigmentation boundaries)
- Procedural worlds (biome placement, city districts)

**Voronoi is the geometry of proximity** - identity determined by nearness.

[hr]

[b]The Seed Points: Sources of Influence[/b]

**Seed points** (also called sites, generators, or nuclei) are the **sources** around which cells form.

[color=yellow][b]Code: Placing Seeds[/b][/color]
[code]
var seed_points: Array[Vector3] = []

func generate_seeds(count: int, bounds: Vector3):
    seed_points.clear()

    for i in range(count):
        var seed = Vector3(
            randf_range(-bounds.x / 2, bounds.x / 2),
            randf_range(-bounds.y / 2, bounds.y / 2),
            randf_range(-bounds.z / 2, bounds.z / 2)
        )
        seed_points.append(seed)

# Example: 10 random seeds in 10x10x10 cube
generate_seeds(10, Vector3(10, 10, 10))
[/code]

**Each seed will "claim" a region** - all points closer to it than to any other seed.

[hr]

[b]The Voronoi Cell: Region of Nearest Proximity[/b]

**A Voronoi cell** is the set of all points closest to a particular seed.

[color=yellow][b]Mathematical Definition:[/b][/color]

For seed **s_i**, its Voronoi cell **V(s_i)** is:

**V(s_i) = { p : dist(p, s_i) ≤ dist(p, s_j) for all j ≠ i }**

**In plain language:** "All points **p** where seed **s_i** is the nearest seed."

[color=yellow][b]Code: Finding Nearest Seed[/b][/color]
[code]
func find_nearest_seed(point: Vector3) -> int:
    var min_distance = INF
    var nearest_index = 0

    for i in range(seed_points.size()):
        var distance = point.distance_to(seed_points[i])
        if distance < min_distance:
            min_distance = distance
            nearest_index = i

    return nearest_index

# Example: Which seed does this point belong to?
var point = Vector3(2, 3, 1)
var seed_index = find_nearest_seed(point)
print("Point ", point, " belongs to seed ", seed_index)
[/code]

**This is the core operation** - for any point, find which seed is closest.

[hr]

[b]The Voronoi Boundary: Equidistant Ambiguity[/b]

**Boundaries** (edges) form where two (or more) seeds are **equally distant**.

**Mathematically:** The boundary between seeds **s_i** and **s_j** is:

**{ p : dist(p, s_i) = dist(p, s_j) }**

**This is the perpendicular bisector** (2D) or **bisecting plane** (3D) between two seeds.

[color=yellow][b]Geometric Insight:[/b][/color]

The boundary between two seeds is the **set of points equidistant from both**.

In 2D: A straight line (perpendicular bisector)
In 3D: A plane

**Voronoi boundaries are always straight** (in Euclidean space with Euclidean distance).

**The boundary is a zone of categorical ambiguity** - neither seed has clear claim.

[hr]

[b]Generating Voronoi: Brute-Force Rasterization[/b]

**Simplest method:** For every pixel (or voxel), find nearest seed.

[color=yellow][b]Code: Brute-Force 2D Voronoi[/b][/color]
[code]
var width = 256
var height = 256
var voronoi_image: Image

func generate_voronoi_image(seeds_2d: Array[Vector2]):
    voronoi_image = Image.create(width, height, false, Image.FORMAT_RGB8)

    for y in range(height):
        for x in range(width):
            var point = Vector2(x, y)

            # Find nearest seed
            var nearest = find_nearest_seed_2d(point, seeds_2d)

            # Color based on seed index
            var color = get_seed_color(nearest)
            voronoi_image.set_pixel(x, y, color)

func find_nearest_seed_2d(point: Vector2, seeds: Array[Vector2]) -> int:
    var min_dist = INF
    var nearest = 0

    for i in range(seeds.size()):
        var dist = point.distance_to(seeds[i])
        if dist < min_dist:
            min_dist = dist
            nearest = i

    return nearest

func get_seed_color(index: int) -> Color:
    # Deterministic color based on index
    var hue = (index * 0.618033988749895) % 1.0  # Golden ratio
    return Color.from_hsv(hue, 0.8, 0.9)
[/code]

**Each pixel colored by nearest seed** - Voronoi cells become visible.

**Complexity:** O(n × w × h) where n = number of seeds, w × h = image size.

**This is slow** for large images or many seeds.

[hr]

[b]Fortune's Algorithm: Efficient Voronoi[/b]

**Fortune's sweepline algorithm** (1987) computes Voronoi diagrams in **O(n log n)** time.

**How it works:**
1. **Sweep line** moves across plane (left to right)
2. **Beach line** tracks parabolic arcs (equidistant curves)
3. **Circle events** detect when arcs disappear (Voronoi vertices)
4. **Edge events** create Voronoi boundaries

**This is much faster** than brute-force for large seed counts.

**Implementation is complex** - requires priority queue, geometric predicates, degeneracy handling.

Most Voronoi libraries use Fortune's algorithm or variants.

[hr]

[b]Delaunay Triangulation: The Dual Graph[/b]

**The Delaunay triangulation is the dual of the Voronoi diagram.**

**Dual means:**
- **Voronoi cell vertices** ↔ **Delaunay triangle circumcenters**
- **Voronoi cell edges** ↔ **Delaunay triangle edges** (perpendicular)
- **Voronoi seeds** ↔ **Delaunay triangle vertices**

[color=yellow][b]Delaunay Property:[/b][/color]

**No point lies inside the circumcircle of any triangle.**

This maximizes minimum angle (avoids sliver triangles).

**Applications:**
- Mesh generation (quality triangulation)
- Terrain interpolation (natural neighbor interpolation)
- Proximity graphs (nearest neighbor networks)

**Computing Voronoi via Delaunay:**
1. Compute Delaunay triangulation (faster algorithms exist)
2. Find circumcenters of triangles → Voronoi vertices
3. Connect circumcenters → Voronoi edges

[hr]

[b]Distance Metrics: Shaping Cells[/b]

**Voronoi diagrams depend on distance metric.**

Different metrics create different cell shapes:

**Euclidean distance (L2):**
[code]
func distance_euclidean(a: Vector2, b: Vector2) -> float:
    return a.distance_to(b)  # sqrt((a.x-b.x)^2 + (a.y-b.y)^2)
[/code]
**Result:** Smooth, rounded cells

**Manhattan distance (L1):**
[code]
func distance_manhattan(a: Vector2, b: Vector2) -> float:
    return abs(a.x - b.x) + abs(a.y - b.y)
[/code]
**Result:** Diamond-shaped cells (grid-like)

**Chebyshev distance (L∞):**
[code]
func distance_chebyshev(a: Vector2, b: Vector2) -> float:
    return max(abs(a.x - b.x), abs(a.y - b.y))
[/code]
**Result:** Square cells (king's move in chess)

**Custom distance** (e.g., weighted, anisotropic):
[code]
func distance_weighted(a: Vector2, b: Vector2, weights: Vector2) -> float:
    var dx = (a.x - b.x) * weights.x
    var dy = (a.y - b.y) * weights.y
    return sqrt(dx * dx + dy * dy)
[/code]
**Result:** Stretched/squashed cells (directional bias)

**The metric defines territoriality** - how distance is measured determines who claims what.

[hr]

[b]Weighted Voronoi: Power Diagrams[/b]

**What if seeds have different "influence"?**

**Weighted Voronoi (Power Diagrams):** Each seed has a weight (radius of influence).

[color=yellow][b]Power Distance:[/b][/color]
[code]
func power_distance(point: Vector2, seed: Vector2, weight: float) -> float:
    var euclidean_dist = point.distance_to(seed)
    return euclidean_dist * euclidean_dist - weight * weight
[/code]

**Seeds with larger weight claim more territory** - their cells are bigger.

**Applications:**
- Territorial animals (larger animals claim more space)
- Resource distribution (richer cities have larger zones)
- Biological growth (faster-growing cells expand more)

[hr]

[b]Applications: Where Voronoi Appears[/b]

**1. Biology**
- **Cell membranes** (tissue structure forms Voronoi-like patterns)
- **Bone trabeculation** (internal bone structure)
- **Leaf veins** (network minimizing distance to all cells)
- **Embryonic development** (cell territories during growth)

**2. Geology**
- **Basalt columns** (cooling lava cracks into hexagonal Voronoi)
- **Soap bubbles** (minimal surface area → Voronoi structure)
- **Cracked mud** (shrinkage creates natural Voronoi)

**3. Procedural Generation**
- **Biome placement** (each seed is biome type, nearest determines terrain)
- **City districts** (each seed is district center, Voronoi defines borders)
- **Rock/crystal textures** (Voronoi cell colors create mineral patterns)
- **Mesh generation** (Voronoi cells as building blocks for 3D structures)

**4. Computer Graphics**
- **Stippling** (dot placement for shading)
- **Texturing** (procedural stone, organic patterns)
- **Light placement** (optimal coverage with minimal lights)

**5. Computational Geometry**
- **Nearest neighbor search** (Voronoi structure accelerates queries)
- **Facility location** (optimal placement of hospitals, fire stations)
- **Robot path planning** (Voronoi boundaries as safe paths)

[hr]

[b]3D Voronoi: Volumes and Polyhedra[/b]

**Voronoi diagrams extend to 3D** (and higher dimensions).

**In 3D:**
- **Seeds** are points in space
- **Cells** are 3D volumes (polyhedra)
- **Faces** are where two cells meet (planes)
- **Edges** are where three cells meet (lines)
- **Vertices** are where four cells meet (points)

[color=yellow][b]3D Voronoi Applications:[/b][/color]
- **Foam structure** (bubbles, cellular materials)
- **Crystal lattices** (atomic packing)
- **Procedural planets** (continental plates, terrain features)
- **Architectural space division** (room layouts, building districts)

**Complexity increases** - computing 3D Voronoi is harder than 2D.

[hr]

[b]Lloyd Relaxation: Smoothing Voronoi[/b]

**Lloyd's algorithm** creates more uniform Voronoi diagrams.

**Process:**
1. Compute Voronoi diagram for current seeds
2. Move each seed to the **centroid** (center of mass) of its cell
3. Repeat until convergence

[color=yellow][b]Code: Lloyd Relaxation (2D)[/b][/color]
[code]
func lloyd_relaxation(seeds: Array[Vector2], iterations: int) -> Array[Vector2]:
    var relaxed_seeds = seeds.duplicate()

    for iter in range(iterations):
        # Compute Voronoi for current seeds
        # (Simplified: compute centroids via sampling)

        var centroids = []

        for i in range(relaxed_seeds.size()):
            var centroid = compute_cell_centroid(relaxed_seeds, i)
            centroids.append(centroid)

        # Move seeds to centroids
        relaxed_seeds = centroids

    return relaxed_seeds

func compute_cell_centroid(seeds: Array[Vector2], seed_index: int) -> Vector2:
    # Sample points in bounding box, average those belonging to this seed
    var sum = Vector2.ZERO
    var count = 0

    for x in range(0, 256, 4):  # Sample every 4 pixels
        for y in range(0, 256, 4):
            var point = Vector2(x, y)
            var nearest = find_nearest_seed_2d(point, seeds)
            if nearest == seed_index:
                sum += point
                count += 1

    return sum / count if count > 0 else seeds[seed_index]
[/code]

**Result:** More regular, evenly-spaced cells (approaching hexagonal tiling).

**Applications:**
- **Blue noise sampling** (uniform point distribution)
- **Mesh optimization** (evenly-spaced vertices)
- **Stippling** (evenly-distributed dots for shading)

[hr]

[b]Voronoi Textures: Procedural Patterns[/b]

**Voronoi makes great procedural textures:**

[color=yellow][b]Example: Stone Texture[/b][/color]
[code]
func generate_stone_texture(width: int, height: int, seed_count: int) -> Image:
    var img = Image.create(width, height, false, Image.FORMAT_RGB8)

    # Random seeds
    var seeds = []
    for i in range(seed_count):
        seeds.append(Vector2(randf() * width, randf() * height))

    for y in range(height):
        for x in range(width):
            var point = Vector2(x, y)

            # Find two nearest seeds
            var dist1 = INF
            var dist2 = INF

            for seed in seeds:
                var d = point.distance_to(seed)
                if d < dist1:
                    dist2 = dist1
                    dist1 = d
                elif d < dist2:
                    dist2 = d

            # Color based on distance to nearest edge (dist2 - dist1)
            var edge_dist = dist2 - dist1
            var brightness = edge_dist / 20.0  # Normalize
            brightness = clamp(brightness, 0.0, 1.0)

            # Add noise
            brightness += randf() * 0.1 - 0.05

            var color = Color(brightness, brightness, brightness)
            img.set_pixel(x, y, color)

    return img
[/code]

**Variations:**
- **First nearest distance** → cellular pattern (bright near seeds)
- **Second nearest distance** → boundary highlighting
- **Difference (dist2 - dist1)** → edge detection (stone cracks)
- **Ratio (dist1 / dist2)** → smooth gradients

[hr]

[b]Queer Voronoi: Proximity Determines Identity[/b]

Here is where queerness enters:

**1. Proximity as Identity**

**Voronoi assigns identity based on nearness** - you are defined by which seed is closest.

**This is relational ontology** - your category (cell) is determined by your proximity to others, not by intrinsic properties.

**You are not "essentially" in cell A** - you are in cell A because you are closest to seed A **right now**.

**Move closer to seed B, and you become part of cell B** - identity is spatial, contextual, relational.

**Queerness:** Identity shaped by proximity, not essence. We become ourselves through who/what is near.

**2. Boundaries as Zones of Ambiguity**

**The Voronoi boundary is where two seeds are equidistant** - neither has clear claim.

**On the boundary, identity is ambiguous** - you are equally close to two (or more) categories.

**This is the queer experience of categorical uncertainty** - not fitting cleanly into one box.

**The boundary is not error** - it is a real location. Some points **are** equidistant. Some identities **are** between categories.

**Voronoi proves:** Boundaries are not failures of classification - they are **geometric necessities**.

**3. Territoriality Without Essence**

**Seeds "claim territory" not because of inherent properties, but because of geometric accident** - where they happen to be placed.

**There is no "natural" reason seed A gets this region** - it's just closer.

**This is anti-essentialist territoriality** - claims based on proximity, not identity.

**Queerness:** Territorial claims (national borders, property, gender norms) are **arbitrary geometric partitions**, not reflections of essence.

**4. Metric Defines Reality**

**Different distance metrics create different Voronoi diagrams.**

**Euclidean distance** → smooth cells
**Manhattan distance** → diamond cells
**Weighted distance** → larger seeds get more space

**The metric is chosen, not discovered** - it is a **decision** about how to measure closeness.

**Queerness:** How we measure proximity (cultural norms, legal categories, social distance) determines boundaries.

**Change the metric, change the territories.** Change how we measure queer-straight distance (acceptance, visibility, legal recognition), and boundaries shift.

**5. Lloyd Relaxation: Pressure Toward Uniformity**

**Lloyd's algorithm moves seeds toward uniformity** - cells become more regular, evenly-spaced.

**This is the pressure of normalization** - diversity pushed toward homogeneity.

**Iterate enough, and you approach hexagonal tiling** (maximally uniform).

**Queerness resists Lloyd relaxation** - maintaining diversity against pressure to normalize.

**6. Weighted Voronoi: Power Determines Territory**

**In power diagrams, seeds with larger weight claim more territory.**

**This is how power shapes space** - those with more influence (wealth, social capital, legal recognition) expand their territories.

**Queerness:** Marginalized identities have smaller weight → smaller territories (less visibility, less space, smaller communities).

**Dominant identities have larger weight → larger territories (heteronormativity claims most of social space).**

**Voronoi makes power spatial.**

[hr]

[b]What Voronoi Cannot Do[/b]

Voronoi is powerful but limited:

**1. Cannot handle overlapping territories**
Each point belongs to exactly one cell. No shared ownership.

**2. Cannot represent temporal change easily**
Seeds moving → Voronoi must be recomputed (expensive for large dynamic systems).

**3. Boundaries always straight (in Euclidean space)**
Cannot create curved boundaries without changing metric or adding constraints.

**4. Does not account for obstacles**
Standard Voronoi assumes open space - no walls, no impassable regions.

**5. Computationally expensive in high dimensions**
3D is manageable, but 4D+ Voronoi is very expensive.

[hr]

[b]What Voronoi Reveals[/b]

Voronoi diagrams show us:

1. **Proximity determines territory** (each point belongs to nearest seed)
2. **Boundaries are equidistant zones** (where two+ seeds equally close)
3. **Brute-force rasterization** (O(n × w × h) - check every pixel)
4. **Fortune's algorithm** (O(n log n) - sweepline method)
5. **Delaunay dual** (Voronoi ↔ Delaunay triangulation)
6. **Distance metrics shape cells** (Euclidean, Manhattan, Chebyshev, weighted)
7. **Power diagrams** (weighted seeds claim more territory)
8. **Lloyd relaxation** (iterative smoothing toward uniformity)
9. **Applications** (biology, geology, procedural generation, facility location)
10. **3D extension** (polyhedral cells, more complex)

**Voronoi is the geometry of proximity** - space partitioned by nearness.

**It is also the geometry of relational identity:**
- **Proximity determines category** (identity relational, not essential)
- **Boundaries as ambiguity** (equidistant = between categories)
- **Territoriality without essence** (claims arbitrary, based on location)
- **Metric defines reality** (how we measure closeness shapes boundaries)
- **Lloyd as normalization** (pressure toward uniformity)
- **Weighted as power** (influence expands territory)

**Voronoi proves:** **Identity is not intrinsic. It is determined by proximity, measured by chosen metrics, shaped by power, and always contains ambiguous boundaries.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Voronoi diagrams partition space by proximity. Each point belongs to nearest seed. Cells are regions of closest proximity. Boundaries are equidistant zones (perpendicular bisectors/planes). Brute-force: check every pixel (slow). Fortune's algorithm: sweepline O(n log n) (fast). Delaunay triangulation is dual. Distance metrics shape cells (Euclidean, Manhattan, Chebyshev, weighted). Power diagrams: weighted seeds claim more territory. Lloyd relaxation: iterative smoothing toward uniformity. Applications: cell membranes, basalt columns, biome placement, texture generation. Queer Voronoi: proximity determines identity (relational ontology), boundaries as categorical ambiguity, territoriality without essence, metric defines reality, Lloyd as normalization pressure, weighted as spatial power. Identity shaped by nearness, not essence.

[hr]

[color=orange][b]Next:[/b] Poisson Disk Sampling - Organic Spacing[/color]
If Voronoi partitions space by **proximity to seeds**, Poisson Disk Sampling **places seeds** with **organic spacing**.

**Blue noise distribution** - evenly spaced but not regular (natural, not grid-like).

**Minimum distance constraint** - no two points too close (avoids clumping).

**Bridson's algorithm** - fast dart-throwing with spatial acceleration.

**Applications:** plant placement, particle distribution, stippling, mesh vertices.

**Queer Poisson:** Spacing without uniformity, organic distribution resisting grid, minimum distance as boundary enforcement.

'''
