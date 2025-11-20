extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Marching Cubes[/b][/font_size][/center]
[center][i]Extracting Surfaces from the Invisible, Thresholds Made Visible[/i][/center]

**Marching cubes is an algorithm that converts invisible scalar fields into visible surfaces.**

It finds the boundary - the exact location where a 3D field crosses a threshold value - and materializes it as a mesh.

**The algorithm reveals what was always there but could not be seen:**
- Terrain hidden in noise functions
- Liquids defined by density gradients
- Organic forms implicit in mathematical equations
- Metaballs emerging from points of influence

**Marching cubes is the transformation of the implicit into the explicit.**

[hr]

[b]The Scalar Field: Invisible Density[/b]

A **scalar field** is a 3D grid where every point has a single numeric value - density, temperature, distance, noise.

[color=yellow][b]Code: Creating a Scalar Field[/b][/color]
[code]
# 3D grid of density values
var field = []
var grid_size = Vector3(32, 32, 32)

func generate_scalar_field() -> Array:
    field = []

    for x in range(grid_size.x):
        field.append([])
        for y in range(grid_size.y):
            field[x].append([])
            for z in range(grid_size.z):
                var value = calculate_density(x, y, z)
                field[x][y][z] = value

    return field

func calculate_density(x: int, y: int, z: int) -> float:
    # Example: sphere at center
    var center = grid_size * 0.5
    var pos = Vector3(x, y, z)
    var dist = pos.distance_to(center)
    var radius = 10.0

    # Negative inside sphere, positive outside
    return dist - radius
[/code]

**The field is invisible** - just numbers in memory. Marching cubes **makes it visible** by finding where it crosses zero.

[hr]

[b]The Iso-Value: The Threshold of Becoming[/b]

The **iso-value** (or iso-surface value) is the threshold - the exact density where "inside" becomes "outside."

Common choices:
- **0.0** - zero-crossing (negative to positive)
- **0.5** - halfway point
- **Any value** - defines what counts as "surface"

[color=yellow][b]The Threshold is Political:[/b][/color]

**Who decides where the boundary is?**

At iso-value = 0.0, everything negative is "inside," everything positive is "outside."

Change the threshold to -0.5, and suddenly more space becomes "inside" - the surface expands.

**The algorithm treats the threshold as objective truth** - but it is chosen, arbitrary, a line drawn by the programmer.

**Thresholds are never neutral** - they determine inclusion/exclusion, visibility/invisibility, matter/void.

[hr]

[b]The Marching Cubes Algorithm: Finding the Surface[/b]

The algorithm "marches" through every cube in the 3D grid, checking each cube's 8 corners:

**For each cube:**
1. **Sample** - Read density values at 8 corners
2. **Classify** - Determine which corners are above/below iso-value
3. **Index** - Create 8-bit number (each corner is 0 or 1)
4. **Lookup** - Use index to find triangle configuration (256 possible cases)
5. **Interpolate** - Calculate exact vertex positions on edges
6. **Generate** - Add triangles to mesh

[color=yellow][b]Code: Marching Cubes Core Loop[/b][/color]
[code]
func marching_cubes(field: Array, iso_value: float) -> ArrayMesh:
    var vertices = []
    var indices = []

    # March through every cube in the grid
    for x in range(grid_size.x - 1):
        for y in range(grid_size.y - 1):
            for z in range(grid_size.z - 1):
                # Process this cube
                process_cube(x, y, z, field, iso_value, vertices, indices)

    # Build mesh from vertices and indices
    return create_mesh(vertices, indices)

func process_cube(x: int, y: int, z: int, field: Array, iso_value: float,
                  vertices: Array, indices: Array):
    # Get 8 corner values
    var corners = get_corner_values(x, y, z, field)

    # Calculate case index (0-255)
    var case_index = 0
    for i in range(8):
        if corners[i] > iso_value:
            case_index |= (1 << i)  # Set bit i

    # Lookup triangle configuration for this case
    var triangle_config = MARCHING_CUBES_TABLE[case_index]

    # Interpolate vertices on edges and add triangles
    for triangle in triangle_config:
        for edge_index in triangle:
            var vertex = interpolate_vertex(x, y, z, edge_index, corners, iso_value)
            vertices.append(vertex)
            indices.append(indices.size())
[/code]

**The 256 cases** - every possible combination of corners being inside/outside the surface.

These cases are **pre-computed** and stored in a lookup table (the marching cubes table).

[hr]

[b]Edge Interpolation: Smoothness from Discreteness[/b]

Each cube has **12 edges**. When the surface crosses an edge (one corner inside, one outside), we must find the exact crossing point.

**Linear interpolation** - weighted average based on corner densities:

[color=yellow][b]Code: Vertex Interpolation[/b][/color]
[code]
func interpolate_vertex(x: int, y: int, z: int, edge_index: int,
                        corners: Array, iso_value: float) -> Vector3:
    # Get edge endpoints (2 corners)
    var edge_corners = EDGE_TABLE[edge_index]  # e.g., [0, 1]
    var corner_a = edge_corners[0]
    var corner_b = edge_corners[1]

    # Get corner positions
    var pos_a = get_corner_position(x, y, z, corner_a)
    var pos_b = get_corner_position(x, y, z, corner_b)

    # Get corner densities
    var val_a = corners[corner_a]
    var val_b = corners[corner_b]

    # Linear interpolation factor
    # If val_a = -0.5 and val_b = 0.5 and iso_value = 0.0:
    # t = (0.0 - (-0.5)) / (0.5 - (-0.5)) = 0.5 / 1.0 = 0.5 (midpoint)
    var t = (iso_value - val_a) / (val_b - val_a)

    # Interpolate position
    return pos_a.lerp(pos_b, t)
[/code]

**The surface vertex is not on the grid** - it's **between** grid points, calculated precisely.

**This is why marching cubes produces smooth surfaces** - not blocky voxels, but continuous geometry.

The **discrete grid** (voxels) generates **continuous surface** (mesh).

[hr]

[b]The Marching Cubes Table: 256 Cases[/b]

The heart of the algorithm is a **pre-computed lookup table** mapping each of the 256 possible corner configurations to a list of triangles.

**Case 0:** All corners inside (or outside) → no surface, no triangles
**Case 255:** Inverse of case 0 → no surface, no triangles
**Cases 1-254:** Various triangle configurations (0 to 5 triangles per cube)

[color=yellow][b]Example Cases:[/b][/color]
[code]
# MARCHING_CUBES_TABLE (simplified examples)

# Case 0: All corners below iso-value → no triangles
MARCHING_CUBES_TABLE[0] = []

# Case 1: Only corner 0 above iso-value → 1 triangle on edges 0,3,8
MARCHING_CUBES_TABLE[1] = [[0, 3, 8]]

# Case 15: 4 corners above → 4 triangles
MARCHING_CUBES_TABLE[15] = [
    [0, 1, 4],
    [1, 5, 4],
    [2, 3, 6],
    [3, 7, 6]
]

# Case 127: Complex configuration → multiple triangles
# ... (256 total cases)
[/code]

**The table is the compressed knowledge of all possible surface configurations.**

It was computed once (by Lorensen and Cline, 1987) and now every marching cubes implementation uses it.

**The algorithm is a lookup, not a calculation** - the hard work was done decades ago.

[hr]

[b]Applications: What Marching Cubes Reveals[/b]

Marching cubes extracts surfaces from:

**1. Terrain (Noise Functions)**
[code]
func generate_terrain_field(x, y, z):
    var noise = FastNoiseLite.new()
    return noise.get_noise_3d(x * 0.1, y * 0.1, z * 0.1)

# Marching cubes converts noise → 3D landscape
[/code]

**2. Metaballs (Organic Blobs)**
[code]
func generate_metaball_field(x, y, z, spheres: Array):
    var sum = 0.0
    for sphere in spheres:
        var dist = Vector3(x, y, z).distance_to(sphere.position)
        sum += sphere.radius / (dist * dist)  # Inverse square falloff
    return sum

# Multiple spheres "merge" where fields add up
# Iso-value determines merging threshold
[/code]

**3. Liquids (Particle-Based Simulation)**
[code]
# Particle positions → density field → surface mesh
func particle_density(x, y, z, particles: Array):
    var density = 0.0
    for particle in particles:
        var dist = Vector3(x, y, z).distance_to(particle.position)
        if dist < kernel_radius:
            density += kernel_function(dist)  # Smooth kernel
    return density

# Marching cubes creates dynamic liquid surface
[/code]

**4. Medical Imaging (CT/MRI Scans)**
- Scalar field = X-ray density or MRI signal
- Iso-value = tissue boundary (bone, muscle, etc.)
- Marching cubes reconstructs 3D anatomy from 2D slices

**5. Distance Fields (SDF)**
[code]
func signed_distance_sphere(x, y, z, center, radius):
    return Vector3(x, y, z).distance_to(center) - radius

# Negative inside, positive outside
# Marching cubes at iso-value = 0.0 extracts exact sphere surface
[/code]

[hr]

[b]Ambiguity Cases: When the Algorithm Fails[/b]

Marching cubes has **ambiguous cases** - cube configurations that could be triangulated multiple ways.

**Case 6** (2 opposite corners above iso-value):
- Could connect with 2 triangles one way
- Or 2 triangles a different way
- Creates **holes** if neighboring cubes make different choices

**Solutions:**
- **Asymptotic Decider** - use additional tests to resolve ambiguity
- **Marching Tetrahedra** - subdivide cubes into tetrahedra (no ambiguous cases)
- **Dual Contouring** - different algorithm that avoids ambiguity

**The algorithm's categorical certainty has edge cases where it breaks down.**

[hr]

[b]Performance: The Cost of Visibility[/b]

Marching cubes is **computationally expensive**:

- **O(n³)** - must check every cube in 3D grid
- **64³ grid** = 262,144 cubes to process
- **128³ grid** = 2,097,152 cubes

**Optimizations:**
1. **Skip empty space** - don't process cubes where all corners are far from iso-value
2. **Octree subdivision** - adaptively refine only near surface
3. **Compute shaders** - parallelize on GPU (1000x+ speedup)
4. **Caching** - only recompute changed regions

**Visibility is expensive** - extracting the surface requires scanning the entire volume.

[hr]

[b]Queer Marching Cubes: Threshold Politics[/b]

Here is where queerness enters:

**1. The Threshold Determines Existence**

The iso-value is the **categorical boundary** - below threshold = invisible, above threshold = visible (or vice versa).

**Change the threshold, and entities appear or disappear.**

This is the violence of categorization - a continuous field (infinite gradations) reduced to binary (in/out, visible/invisible).

**The surface is not "discovered" - it is imposed** by choosing where to draw the line.

**2. Smoothness from Discreteness**

The grid is **discrete** (voxels), but the surface is **continuous** (smooth mesh).

**Interpolation** creates in-between states - vertex positions that do not exist in the source data.

This is queer emergence: the smooth surface is not "in" the voxel grid, but generated by the algorithm's interpretation.

**The mesh exceeds its source** - it is more than the sum of discrete points.

**3. Implicit to Explicit**

The scalar field is **implicit** - the surface exists as a mathematical relation (f(x,y,z) = iso_value), not as geometry.

Marching cubes makes it **explicit** - converts relation into triangles, vertices, coordinates.

**This is the transition from potential to actual** - from "could be drawn" to "is drawn."

The field contains infinite possible surfaces (one for each iso-value). Marching cubes **collapses** this potential by choosing one threshold.

**Queerness:** The field holds all thresholds simultaneously until we observe (extract) one.

**4. Ambiguity Cases: Categorical Breakdown**

The 256 cases are the algorithm's attempt at **total categorical coverage** - every possible configuration accounted for.

But **ambiguous cases** (like case 6) break this - same configuration, multiple valid interpretations.

**The algorithm fails when the boundary is truly uncertain.**

This is where discrete categorization (256 cases) encounters the **irreducible continuity** of the field.

**Holes appear** when the algorithm cannot decide - visibility gaps created by categorical insufficiency.

**5. Field as Ambient Potential**

The scalar field is **everywhere present but nowhere visible** until extracted.

It is ambient, continuous, infinite - like affect, like atmosphere.

Marching cubes is the operation that says **"this counts as surface"** - a cut through ambient potential.

**The surface is a political act** - choosing what to make visible from what was always there.

[hr]

[b]What Marching Cubes Cannot Do[/b]

Marching cubes is powerful but limited:

**1. Cannot preserve sharp edges**
Interpolation smooths everything - no perfect cubes, no hard corners.

**Solution:** Dual Contouring (preserves features)

**2. Cannot handle thin features**
If detail is smaller than voxel size, it disappears (aliasing).

**Solution:** Higher resolution grid (but exponentially expensive)

**3. Cannot dynamically adjust resolution**
Fixed grid resolution throughout volume.

**Solution:** Octree adaptive refinement

**4. Cannot avoid ambiguous cases**
Some configurations have multiple valid triangulations.

**Solution:** Marching Tetrahedra, Asymptotic Decider

**5. Cannot extract surface without scanning volume**
Must check every cube (or most cubes) to find surface.

**Visibility requires exhaustive search.**

[hr]

[b]What Marching Cubes Reveals[/b]

Marching cubes shows us:

1. **Thresholds are chosen** - iso-value determines inclusion/exclusion
2. **Invisible fields surround us** - density, temperature, distance, noise
3. **Surfaces are interpretations** - not discovered, but extracted via threshold
4. **Smoothness from discreteness** - interpolation creates continuous from voxels
5. **Implicit to explicit** - mathematical relation → geometric mesh
6. **256 cases** - attempt at total categorical coverage (but ambiguity persists)
7. **Ambiguous cases** - categorical breakdown, holes in visibility
8. **Computational cost** - O(n³), visibility is expensive
9. **Applications** - terrain, liquids, metaballs, medical imaging, SDFs
10. **Field as potential** - infinite surfaces until threshold chosen

**Marching cubes is the algorithm of making invisible forces visible.**

**It is also the algorithm of threshold politics:**
- **Binary categorical boundaries** (above/below iso-value)
- **Chosen thresholds** (iso-value is arbitrary)
- **Smoothness imposed** (interpolation creates continuity not in source)
- **Potential collapsed** (infinite surfaces → one extracted)
- **Ambiguity producing holes** (when categories fail, gaps appear)

**The surface is not "the truth" - it is the threshold's consequence.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Marching cubes extracts surfaces from scalar fields (3D grids of density values). Iso-value is threshold (boundary between inside/outside). Algorithm marches through cubes, classifying 8 corners as above/below threshold, creating case index (0-255), looking up triangle configuration, interpolating vertices on edges. Edge interpolation creates smooth surfaces from discrete voxels. 256 cases pre-computed (Lorensen & Cline 1987). Applications: terrain (noise), metaballs (organic blobs), liquids (particle density), medical imaging (CT/MRI), distance fields. Ambiguous cases (multiple valid triangulations) create holes. O(n³) performance (expensive). Queer marching cubes: threshold as categorical violence (chosen, not discovered), smoothness from discreteness (interpolation creates in-between), implicit to explicit (potential → actual), ambiguity as categorical breakdown, field as ambient potential (infinite surfaces until one chosen). Surface is interpretation, not truth.

[hr]

[color=orange][b]Next:[/b] Wave Function Collapse - Constraint-Based Becoming[/color]
If marching cubes extracts surfaces by **thresholding density**, Wave Function Collapse generates patterns by **collapsing superposition**.

**WFC treats possibility as quantum state** - each cell is all options simultaneously until observed (collapsed).

**Entropy measures freedom** - high entropy = many possibilities, low entropy = few possibilities.

**Constraint propagation** - collapsing one cell limits neighbors' options (relational determination).

**Adjacency rules** - only compatible tiles can be neighbors (enforced boundary conditions).

**WFC is the algorithm of relational ontology** - identity determined by proximity and constraint.

'''
