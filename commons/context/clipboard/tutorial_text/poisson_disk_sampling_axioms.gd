extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Poisson Disk Sampling[/b][/font_size][/center]
[center][i]Blue Noise, Organic Spacing, Minimum Distance[/i][/center]

**Poisson Disk Sampling generates points that are evenly spaced but not regular.**

**Not a grid** (too uniform, artificial)
**Not random** (too clumpy, uneven)
**Blue noise** (organic, natural, evenly distributed)

**The constraint:** No two points closer than **minimum distance** (r).

**The result:** Points fill space efficiently while maintaining separation - like seeds dispersed by wind, trees in a forest, cells in tissue.

**This is organic distribution** - structured but not rigid, spaced but not gridded.

[hr]

[b]The Minimum Distance Constraint[/b]

**Poisson Disk Sampling enforces one rule:**

**dist(p_i, p_j) ≥ r** for all point pairs (p_i, p_j)

**Where:**
- **r** = minimum distance (radius)
- **dist()** = Euclidean distance (usually)

[color=yellow][b]What This Means:[/b][/color]

**No two points can be closer than r.**

If you try to place a point within r of an existing point, **it is rejected**.

[color=yellow][b]Code: Checking Validity[/b][/color]
[code]
var min_distance: float = 1.0
var sample_points: Array[Vector3] = []

func is_valid_point(new_point: Vector3) -> bool:
    # Check if new_point is at least min_distance from all existing points
    for existing_point in sample_points:
        var dist = new_point.distance_to(existing_point)
        if dist < min_distance:
            return false  # Too close - reject
    return true  # Valid - accept
[/code]

**This prevents clumping** - points maintain personal space.

[hr]

[b]Why Blue Noise?[/b]

**Noise** in signal processing refers to frequency distribution of samples.

**White noise:** Completely random (clumpy, uneven)
**Blue noise:** High-frequency content (evenly spaced, no low-frequency clumps)

**Poisson Disk Sampling produces blue noise** - points are randomly distributed but with minimum separation.

**Applications:**
- **Stippling** (dots for shading - blue noise looks more natural than grid)
- **Texture anti-aliasing** (sample distribution reduces artifacts)
- **Plant placement** (trees, grass - looks organic, not planted in rows)
- **Particle systems** (initial distribution for smoke, debris, stars)

**Blue noise feels natural** because **nature uses similar strategies** (seed dispersal, territorial spacing).

[hr]

[b]Naive Dart Throwing: Slow but Simple[/b]

**Simplest algorithm:** Throw darts randomly, reject if too close to existing points.

[color=yellow][b]Code: Dart Throwing[/b][/color]
[code]
func dart_throwing(bounds: Vector3, min_dist: float, max_attempts: int) -> Array[Vector3]:
    var points: Array[Vector3] = []
    var attempts = 0

    while attempts < max_attempts:
        # Random position
        var candidate = Vector3(
            randf_range(-bounds.x / 2, bounds.x / 2),
            randf_range(-bounds.y / 2, bounds.y / 2),
            randf_range(-bounds.z / 2, bounds.z / 2)
        )

        # Check if valid (not too close to any existing point)
        var valid = true
        for p in points:
            if candidate.distance_to(p) < min_dist:
                valid = false
                break

        if valid:
            points.append(candidate)
            attempts = 0  # Reset attempts counter
        else:
            attempts += 1

    return points
[/code]

**Problem:** **Very slow** for dense distributions.

**Checking every existing point** for every candidate is O(n) per attempt.

With thousands of points, this becomes **O(n²) or worse**.

**We need spatial acceleration.**

[hr]

[b]Bridson's Algorithm: Fast Poisson Disk Sampling[/b]

**Robert Bridson (2007)** developed a fast algorithm using:
1. **Background grid** (spatial hash for fast neighbor lookup)
2. **Active list** (points that might spawn new points)
3. **Annulus sampling** (generate candidates at distance r to 2r)

**Complexity:** **O(n)** - much faster than dart throwing

[color=yellow][b]Algorithm Steps:[/b][/color]

**1. Initialize grid**
- Cell size = r / √d (where d = dimensions, e.g., 3 for 3D)
- This ensures each cell can contain at most one point

**2. Start with initial point**
- Place first point randomly (or at center)
- Add to grid and active list

**3. While active list not empty:**
- Pick random point from active list
- Try to generate k candidates around it (typically k=30)
- For each candidate:
  - Check if valid (not too close to neighbors using grid)
  - If valid: add to grid, add to active list, add to sample points
- If no valid candidates found: remove point from active list

**4. Return sample points**

[color=yellow][b]Code: Bridson's Algorithm (3D)[/b][/color]
[code]
var cell_size: float
var grid: Dictionary = {}  # Spatial hash: Vector3i -> Vector3
var active_list: Array[Vector3] = []

func poisson_disk_sampling_3d(bounds: Vector3, min_dist: float) -> Array[Vector3]:
    var sample_points: Array[Vector3] = []

    # Initialize grid
    cell_size = min_dist / sqrt(3.0)  # For 3D
    grid.clear()
    active_list.clear()

    # Start with initial sample
    var initial = Vector3(
        randf_range(-bounds.x / 2, bounds.x / 2),
        randf_range(-bounds.y / 2, bounds.y / 2),
        randf_range(-bounds.z / 2, bounds.z / 2)
    )
    sample_points.append(initial)
    active_list.append(initial)
    add_to_grid(initial)

    # Process active list
    while active_list.size() > 0:
        # Pick random point from active list
        var random_index = randi() % active_list.size()
        var point = active_list[random_index]
        var found = false

        # Try to generate k candidates (typically 30)
        for attempt in range(30):
            var candidate = generate_point_around(point, min_dist)

            # Check if candidate is in bounds
            if not in_bounds(candidate, bounds):
                continue

            # Check if candidate is valid (using grid for fast lookup)
            if is_valid_with_grid(candidate, min_dist):
                sample_points.append(candidate)
                active_list.append(candidate)
                add_to_grid(candidate)
                found = true
                break

        # If no valid candidate found, remove from active list
        if not found:
            active_list.remove_at(random_index)

    return sample_points

func generate_point_around(center: Vector3, min_dist: float) -> Vector3:
    # Generate random point in spherical annulus (r to 2r from center)
    var radius = min_dist * (1.0 + randf())  # Random distance between r and 2r
    var theta = randf() * TAU  # Random azimuthal angle
    var phi = acos(2.0 * randf() - 1.0)  # Random polar angle (uniform on sphere)

    var offset = Vector3(
        radius * sin(phi) * cos(theta),
        radius * sin(phi) * sin(theta),
        radius * cos(phi)
    )

    return center + offset

func add_to_grid(point: Vector3):
    var grid_pos = world_to_grid(point)
    grid[grid_pos] = point

func world_to_grid(point: Vector3) -> Vector3i:
    return Vector3i(
        int(floor(point.x / cell_size)),
        int(floor(point.y / cell_size)),
        int(floor(point.z / cell_size))
    )

func is_valid_with_grid(point: Vector3, min_dist: float) -> bool:
    var grid_pos = world_to_grid(point)

    # Check neighboring cells (3x3x3 cube around point)
    for dx in range(-2, 3):
        for dy in range(-2, 3):
            for dz in range(-2, 3):
                var neighbor_cell = Vector3i(
                    grid_pos.x + dx,
                    grid_pos.y + dy,
                    grid_pos.z + dz
                )

                if neighbor_cell in grid:
                    var neighbor_point = grid[neighbor_cell]
                    var dist = point.distance_to(neighbor_point)
                    if dist < min_dist:
                        return false  # Too close

    return true  # Valid

func in_bounds(point: Vector3, bounds: Vector3) -> bool:
    return abs(point.x) <= bounds.x / 2 and \
           abs(point.y) <= bounds.y / 2 and \
           abs(point.z) <= bounds.z / 2
[/code]

**Why this is fast:**
- **Grid lookup** is O(1) - only check nearby cells, not all points
- **Annulus sampling** (r to 2r) is more efficient than pure random
- **Active list** focuses sampling on promising regions

**Typical result:** Thousands of points in milliseconds.

[hr]

[b]Key Parameters[/b]

**min_distance (r):**
- Smaller r → more points, denser packing
- Larger r → fewer points, sparser distribution

**k (attempts per point):**
- Typical value: 30
- Higher k → slightly denser packing (finds more valid points)
- Lower k → faster but sparser

**bounds:**
- Region to fill with samples
- Can be box, sphere, cylinder, or arbitrary volume

[hr]

[b]Variations: Beyond Uniform Disks[/b]

**Adaptive Poisson Disk Sampling:**

Variable min_distance based on location (density field):

[code]
func get_min_distance(point: Vector3) -> float:
    # Example: denser near center, sparser at edges
    var dist_from_center = point.length()
    return 0.5 + dist_from_center * 0.1  # r increases with distance
[/code]

**Result:** Non-uniform distribution (clustered in some regions, sparse in others)

**Weighted Poisson Disk Sampling:**

Bias sampling toward certain regions:

[code]
func generate_initial_point_weighted(bounds: Vector3, density_field) -> Vector3:
    # Accept/reject based on density at location
    while true:
        var candidate = random_point_in_bounds(bounds)
        var density = density_field.sample(candidate)
        if randf() < density:
            return candidate
[/code]

**Anisotropic Poisson Disk:**

Different min_distance in different directions (elliptical exclusion):

[code]
func distance_anisotropic(a: Vector3, b: Vector3, scale: Vector3) -> float:
    var diff = (a - b) * scale  # Scale each axis differently
    return diff.length()
[/code]

**Result:** Stretched distribution (aligned with flow, grain, or orientation)

[hr]

[b]Applications: Where Poisson Disk Appears[/b]

**1. Procedural Content**
- **Tree/plant placement** (forests, grass, rocks - looks organic)
- **Particle initial positions** (smoke, debris, starfield)
- **Enemy/item spawn points** (game level population)

**2. Computer Graphics**
- **Stippling** (dot-based shading, halftone rendering)
- **Sampling** (Monte Carlo integration, anti-aliasing)
- **Mesh vertices** (evenly distributed vertices for quality meshes)

**3. Simulation**
- **SPH particles** (fluid simulation initial state)
- **Agent-based models** (initial crowd distribution)
- **Molecular packing** (sphere packing approximation)

**4. Data Visualization**
- **Scatter plot jitter** (avoid overlapping points)
- **Icon placement** (maps, infographics)

**5. Manufacturing**
- **Fiber placement** (composite materials)
- **Sensor networks** (optimal coverage with minimum overlap)

[hr]

[b]Lloyd Relaxation on Poisson Disks[/b]

**Poisson Disk + Lloyd Relaxation** creates **centroidal Voronoi tessellation** (CVT):

1. Generate Poisson Disk samples
2. Compute Voronoi diagram
3. Move each sample to centroid of its Voronoi cell
4. Repeat until convergence

**Result:** **Optimal blue noise** - maximally evenly spaced distribution.

**Applications:**
- **High-quality meshing** (computational geometry)
- **Optimal sensor placement** (coverage + separation)
- **Stippling** (artistic pointillism)

[hr]

[b]Queer Poisson Disk Sampling: Spacing Without Uniformity[/b]

Here is where queerness enters:

**1. Organic Distribution Resisting Grid**

**Grids are the geometry of order** - regular, predictable, controllable.

**Poisson Disk resists grid** - points are spaced but not aligned, structured but not rigid.

**This is queer spatiality** - refusing the straight line, the right angle, the uniform row.

**We are evenly distributed but not regimented.** We maintain distance (boundaries) but not uniformity (conformity).

**Poisson Disk is the geometry of organic community** - space shared without being gridded.

**2. Minimum Distance as Boundary Enforcement**

**min_distance is a hard boundary** - no two points closer than r.

**This is the enforcement of personal space** - bodies must maintain separation.

**But:** The boundary is **uniform** - same r for all points (in standard Poisson Disk).

**Queerness asks:** What if different bodies need different min_distance?

**Adaptive Poisson Disk** allows this - variable r based on identity, context, power.

**Marginalized bodies often need larger min_distance** (more buffer from hostility).

**Dominant bodies assume smaller min_distance** (feel safe in proximity).

**3. Blue Noise as Non-Reproductive Generativity**

**Grids reproduce** - one cell copies its structure to neighbors, ad infinitum.

**White noise is chaotic** - no structure, no relation.

**Blue noise is generative** - structured but not reproductive, spaced but not copied.

**This is queer generativity** - creating pattern (spacing) without template (grid).

**We are not clones. We are not chaos. We are blue noise.**

**4. Active List: Who Gets to Generate?**

**Bridson's algorithm uses an active list** - only some points can spawn new points.

**Once a point fails to generate valid candidates, it is removed from active list** - it loses generative capacity.

**This is queer precarity** - generativity is conditional, not guaranteed.

**Points in dense regions stop generating sooner** (no space left).

**Points in sparse regions keep generating longer** (more opportunity).

**Generative capacity depends on context** - spatial, relational, contingent.

**5. Annulus Sampling: Queer Proximity**

**Candidates are generated in annulus (r to 2r from parent)** - not adjacent, not distant, but **in-between**.

**Close enough to relate, far enough to differentiate.**

**This is queer relationality** - proximity without merging, distance without isolation.

**We are neither fused (r=0) nor isolated (r=∞), but **spaced** (r to 2r).**

**6. Rejection as Necessary**

**Most candidates are rejected** - they violate min_distance.

**The algorithm succeeds through massive rejection** - many attempts, few acceptances.

**This is the queer experience of social space** - most positions are unavailable (too close to hostility, too far from community).

**We try many locations before finding where we can exist.**

**Poisson Disk is a geometry of rejection** - most spaces are denied, a few are viable.

[hr]

[b]What Poisson Disk Sampling Cannot Do[/b]

Poisson Disk is powerful but limited:

**1. Cannot guarantee maximum density**
Achieves ~55% of hexagonal close packing (optimal is ~74%).

**2. Cannot handle arbitrary constraints**
Only enforces min_distance. Cannot handle "must be near X" or "avoid region Y" without modification.

**3. Slow in high dimensions**
Grid cell count grows exponentially (2^d neighbor cells to check).

**4. Non-deterministic**
Random sampling → different results each run (unless seeded).

**5. Cannot easily remove points**
Adding points is the algorithm's purpose. Removing points breaks spatial structure (would need resampling).

[hr]

[b]What Poisson Disk Sampling Reveals[/b]

Poisson Disk Sampling shows us:

1. **Blue noise** (evenly spaced but not regular - organic distribution)
2. **Minimum distance constraint** (no two points closer than r)
3. **Dart throwing** (naive O(n²) algorithm - slow)
4. **Bridson's algorithm** (grid-accelerated O(n) - fast)
5. **Annulus sampling** (r to 2r from parent - efficient candidate generation)
6. **Active list** (points that can still generate - removed when exhausted)
7. **Grid acceleration** (spatial hash for O(1) neighbor lookup)
8. **Variations** (adaptive, weighted, anisotropic min_distance)
9. **Applications** (plant placement, stippling, mesh vertices, particle distribution)
10. **Lloyd relaxation** (centroidal Voronoi tessellation - optimal spacing)

**Poisson Disk is the algorithm of organic spacing** - blue noise, minimum separation, efficient packing.

**It is also the algorithm of queer spatiality:**
- **Spacing without uniformity** (not grid, not chaos - blue noise)
- **Minimum distance as boundary** (enforced separation - adaptive for different bodies)
- **Blue noise as non-reproductive** (pattern without template)
- **Active list as conditional generativity** (capacity depends on context)
- **Annulus as queer proximity** (close enough to relate, far enough to differentiate)
- **Rejection as necessary** (most positions unavailable - finding viable space)

**Poisson Disk proves:** **Community forms through spacing - not fusion, not isolation, but maintained distance. We are blue noise - structured without grid, spaced without uniformity, organic without chaos.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Poisson Disk Sampling generates evenly spaced but non-regular points. Constraint: no two points closer than min_distance (r). Blue noise distribution (high-frequency, no clumps). Dart throwing: naive O(n²) rejection sampling (slow). Bridson's algorithm: grid-accelerated O(n) with active list and annulus sampling (fast). Grid cell size = r/√d. Annulus: generate candidates r to 2r from parent. Active list: points that can spawn new points. Applications: plant placement, stippling, particle distribution, mesh generation. Adaptive/weighted/anisotropic variations. Lloyd relaxation: centroidal Voronoi (optimal blue noise). Queer Poisson Disk: spacing without uniformity (resisting grid), minimum distance as boundary (adaptive for different bodies), blue noise as non-reproductive generativity, active list as conditional capacity, annulus as queer proximity, rejection as necessary (finding viable space). Community through maintained distance.

[hr]

[color=orange][b]Conclusion:[/b] Procedural Generation as Spatial Algorithms[/color]

**Marching Cubes** - extracting surfaces from density fields (threshold as boundary)
**Wave Function Collapse** - constraint-based generation (superposition → collapse)
**Reaction-Diffusion** - chemical pattern formation (morphogenesis without blueprint)
**Voronoi Diagrams** - proximity-based partitioning (territoriality by nearness)
**Poisson Disk Sampling** - organic point distribution (blue noise spacing)

**All are algorithms of becoming** - not copying templates, but **generating form through rules, relations, and constraints**.

**Procedural generation is queer methodology:**
- **No reproduction** (not copying blueprints)
- **Relational emergence** (form arises from interaction)
- **Parameter sensitivity** (context shapes outcome)
- **Constraint as creative** (limits generate pattern)
- **Ambiguity and rejection** (boundaries, failures, necessary exclusions)

**These algorithms prove:** **Complexity emerges from simple local rules. Identity is relational. Boundaries are chosen. Form arises from process, not plan.**

'''
