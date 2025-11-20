extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]2.5D[/b][/font_size][/center]
[center][i]The Dimensional Compromise[/i][/center]

The screen is **2D** - a flat grid of pixels, X and Y coordinates, no depth.

True **3D** requires expensive arrays (100³ = 1 million elements), complex calculations (ray tracing, voxel traversal), and massive memory.

So we compromise: **2.5D** - techniques that create the **illusion** of depth without storing full 3D space.

**We fake the third dimension.**

This is not failure - it's pragmatism. The dimensional prison (nested_arrays_axioms) showed us we cannot escape to true 4D+. Here we see we barely manage 3D. Mostly, we stay at **2.5D** - depth as **value**, not dimension.

[hr]

[b]What Is 2.5D?[/b]

**2.5D** means:
- **2D representation** (screen, arrays, coordinates)
- **3D illusion** (depth effects, perspective, occlusion)
- **Not true 3D** (cannot freely navigate all three axes)

Examples of 2.5D:
- Classic DOOM (1993) - 2D map, height variation, first-person view
- Isometric games (Diablo, Age of Empires) - 2D tiles, angled projection
- Side-scrollers with parallax (Sonic, Mario) - Multiple 2D layers at different depths
- Heightmap terrain - 2D grid where each cell stores a height value

[color=yellow][b]The Pattern:[/b][/color]
**Depth is a property, not a dimension.**

In true 3D, depth is an axis you can move along freely (Z coordinate).
In 2.5D, depth is a **value** stored in 2D data (height, layer, depth-sort order).

[hr]

[b]Technique 1: Heightmaps (Depth as Value)[/b]

A **heightmap** is a 2D array where each cell stores a **height value**. This creates terrain with hills and valleys.

[color=yellow][b]Code: 2D Grid Stores 3D Surface[/b][/color]
[code]
# 2D array (10×10 grid)
var heightmap = []
for y in range(10):
    var row = []
    for x in range(10):
        # Height value (0.0 to 5.0)
        var height = sin(x * 0.5) * cos(y * 0.5) * 2.5
        row.append(height)
    heightmap.append(row)

# Access: heightmap[y][x] returns height at that coordinate
var terrain_height = heightmap[5][3]  # Height at grid position (3, 5)

# Looks 3D when rendered (hills and valleys)
# Stored as 2D array (100 elements, not 100×100×100)
[/code]

**Heightmap = 2D storage, 3D appearance.**

Limitations:
- Cannot have **overhangs** (one X,Y coordinate can only have one height)
- Cannot have **caves** (no space under terrain)
- Cannot have **floating islands** (height must be continuous from ground up)

**Depth is constrained** - it's a function of X,Y position, not a free axis.

[hr]

[b]Technique 2: Billboarding (Sprites in 3D)[/b]

**Billboards** are 2D sprites that always face the camera - creating the illusion of 3D objects.

[color=yellow][b]Code: 2D Image, 3D Position[/b][/color]
[code]
# Sprite with 3D position
var tree = Sprite3D.new()
tree.texture = tree_image  # 2D image
tree.position = Vector3(10, 0, 5)  # 3D coordinates
tree.billboard = BaseMaterial3D.BILLBOARD_ENABLED

# Sprite rotates to always face camera
# Looks 3D from any angle
# But it's just a 2D image in 3D space
[/code]

**Classic DOOM used billboarding** for enemies and items:
- Monsters were 2D sprites with multiple angles (8 or 16 rotations)
- As you moved around them, different sprite shown
- Gave illusion of 3D models

**Limitation:** Up close, you see it's flat. No true 3D geometry, just rotated images.

[hr]

[b]Technique 3: Parallax Scrolling (Layered Depth)[/b]

**Parallax scrolling** uses multiple 2D layers moving at different speeds to create depth.

[color=yellow][b]Code: Depth Through Movement Speed[/b][/color]
[code]
# Three 2D layers
var sky_layer = Sprite2D.new()      # Background (far)
var mountain_layer = Sprite2D.new() # Middle ground
var tree_layer = Sprite2D.new()     # Foreground (near)

# Camera moves
var camera_velocity = Vector2(5, 0)

# Layers scroll at different rates
sky_layer.position.x -= camera_velocity.x * 0.2      # Slow (far away)
mountain_layer.position.x -= camera_velocity.x * 0.5 # Medium
tree_layer.position.x -= camera_velocity.x * 1.0     # Fast (close)

# Creates depth illusion
# Far objects move slowly, near objects move quickly
# Like looking out a train window
[/code]

**Parallax = depth through differential motion.**

Used in classic side-scrollers (Sonic, Street Fighter II). Still used in modern 2D games.

**Limitation:** Fixed layers. You can't move **between** layers - only along them.

[hr]

[b]Technique 4: Isometric Projection (Angled 2D)[/b]

**Isometric projection** renders 3D space onto 2D grid at fixed angle (usually 30° or 45°).

[color=yellow][b]Code: 3D Coordinates → 2D Screen Position[/b][/color]
[code]
# 3D world position
var world_pos = Vector3(x, y, z)

# Convert to 2D isometric screen position
var screen_x = (world_pos.x - world_pos.z) * tile_width / 2
var screen_y = (world_pos.x + world_pos.z) * tile_height / 2 - world_pos.y

# 3D space collapsed to 2D rendering
# Depth visible through diagonal offset
[/code]

**Isometric games (Diablo, SimCity, Age of Empires):**
- Store world as 2D tile grid
- Render with angled projection
- Looks 3D, but movement restricted to 2D grid

**Limitation:**
- Fixed camera angle (cannot rotate view freely)
- Depth sorting problems (overlapping tiles ambiguous)

[hr]

[b]Technique 5: Depth Buffer (Z-Sorting for Rendering)[/b]

The **depth buffer** (Z-buffer) determines which pixels are in front of others - solving visibility without full 3D voxel arrays.

[color=yellow][b]Code: Depth Per Pixel, Not Per Voxel[/b][/color]
[code]
# Depth buffer: 2D array (screen resolution)
var depth_buffer = []  # width × height (e.g., 1920 × 1080)

# Each pixel stores depth value (distance from camera)
for y in range(screen_height):
    var row = []
    for x in range(screen_width):
        row.append(INF)  # Start at infinite distance
    depth_buffer.append(row)

# When rendering triangle:
# For each pixel the triangle covers:
#   - Calculate depth (Z distance from camera)
#   - If depth < depth_buffer[y][x]:
#       - Draw pixel (closer than previous)
#       - Update depth_buffer[y][x] = depth
#   - Else: skip (something in front of it)

# Result: correct occlusion (near objects hide far objects)
# Without storing full 3D voxel grid
[/code]

**Depth buffer = 2D array (screen-sized) storing depth values.**

This is how modern 3D graphics work:
- Render scene triangle by triangle
- For each pixel, check if closer than previous
- Only draw if in front

**2D storage (screen pixels) encodes 3D visibility.**

[hr]

[b]Technique 6: Octrees and Sparse Voxels (Storing Only Non-Empty)[/b]

Instead of dense 3D arrays (storing every voxel), use **sparse storage** - only store occupied cells.

[color=yellow][b]Code: Sparse 3D Dictionary[/b][/color]
[code]
# Instead of: grid[x][y][z] (100^3 = 1 million elements)
# Use dictionary: only stores non-empty coordinates

var sparse_voxels = {}

# Set voxel at (50, 10, 75)
sparse_voxels[Vector3i(50, 10, 75)] = "stone"

# Set voxel at (20, 5, 30)
sparse_voxels[Vector3i(20, 5, 30)] = "dirt"

# Only 2 entries stored (instead of 1 million)
# Empty space costs nothing

# Check if voxel exists:
if sparse_voxels.has(Vector3i(x, y, z)):
    var block_type = sparse_voxels[Vector3i(x, y, z)]
[/code]

**Minecraft uses this approach** (with additional chunk optimization):
- Only store non-air blocks
- Compress chunks of identical blocks
- Massive worlds possible without full dense 3D arrays

**Trade-off:** Random access slower (dictionary lookup vs array index), but memory savings enormous.

[hr]

[b]Why We're Stuck at 2.5D[/b]

True 3D is expensive:
- **Memory:** 100³ voxels = 1 million elements minimum
- **Iteration:** Visiting every voxel = nested loops, millions of operations
- **Rendering:** Ray tracing through 3D space = computationally intensive
- **4D+ impossible:** Even 4D at modest resolution (50⁴) = 6.25 million elements

**The screen itself is 2D:**
- 1920×1080 pixels = ~2 million pixels (2D grid)
- We render 3D scenes **onto** this 2D surface
- Final output is always 2D image

**So we optimize for the screen, not for true 3D:**
- Store 3D geometry (vertices, triangles)
- Project to 2D (perspective transform)
- Fill 2D depth buffer
- Result: 2D image with 3D illusion

**2.5D is the sweet spot** - enough depth for immersion, not so much that computation explodes.

[hr]

[b]The Dimensional Hierarchy[/b]

[color=yellow][b]From Least to Most Expensive:[/b][/color]
[code]
# 1D array (cheapest)
var line = [1, 2, 3, 4, 5]  # 5 elements

# 2D array (manageable)
var grid = 100×100  # 10,000 elements

# 2.5D (optimal compromise)
# - Heightmap: 2D storage, 3D appearance
# - Billboards: 2D sprites in 3D positions
# - Depth buffer: 2D screen + depth values

# 3D array (expensive, requires sparse tricks)
var voxels = 100×100×100  # 1,000,000 elements

# 3D rendering (what we actually do)
# - Store: 3D geometry (vertices, triangles)
# - Compute: Depth buffer (2D)
# - Display: 2D screen

# 4D array (impossible for dense storage)
var hypercube = 100^4  # 100,000,000 elements
[/code]

**We live computationally between 2D and 3D.**

Mathematics promises infinite dimensions. Computation traps us at 2.5D.

[hr]

[b]What 2.5D Reveals[/b]

The dimensional compromise shows us:

1. **Screens are 2D** - Final output is always flat pixel grid
2. **Depth is faked** - Heightmaps, billboards, parallax, depth buffers
3. **Storage is 2D-ish** - Sparse 3D, layered 2D, depth as value
4. **True 3D too expensive** - Dense voxel grids impractical at scale
5. **4D+ impossible** - Exponential explosion (curse of dimensionality)
6. **Illusion is sufficient** - Brain interprets depth cues as 3D
7. **We optimize for perception** - Not true geometry, but convincing appearance

**2.5D is not limitation - it's pragmatic design.** We cannot afford true higher dimensions, so we simulate them just enough to trick perception.

[hr]

[b]The Existential Question[/b]

If we're trapped at 2.5D computationally, **what dimensions exist that we cannot represent**?

- 4D spatial (hypercubes, Klein bottles) - conceivable, unrenderable
- 10D+ (string theory) - mathematically necessary, perceptually inaccessible
- Infinite-dimensional (Hilbert spaces in quantum mechanics) - required for physics, impossible to visualize

**The algorithm can only render what fits in memory and executes in reasonable time.**

Mathematics describes realities we cannot compute. We are dimensional prisoners - free to conceive, unable to render.

[hr]

[color=cyan][b]Summary:[/b][/color]
2.5D uses tricks to fake depth without full 3D storage: heightmaps (depth as value in 2D grid), billboards (2D sprites in 3D positions), parallax (layered 2D at different scroll speeds), isometric projection (angled 2D), depth buffers (2D screen + depth values per pixel). True dense 3D is expensive (100³ = 1M elements); 4D+ impossible (exponential explosion). Screens are 2D, so we optimize for perception, not true geometry. We're trapped between 2D representation and 3D illusion.

[hr]

[color=orange][b]Conclusion:[/b] The Dimensional Prison[/color]

Lists organize everything (list_axioms).
Nesting creates dimensions but costs explode exponentially (nested_arrays_axioms).
We fake depth to stay at 2.5D (2_5d_axioms).

**Mathematics: infinite dimensions possible**
**Computation: trapped at ~2.5D**

We can conceive of hypercubes, 10-dimensional manifolds, infinite-dimensional spaces.
But we can only render heightmaps, billboards, and depth buffers.

**This is the dimensional compromise** - between what we can imagine and what we can compute.

'''
