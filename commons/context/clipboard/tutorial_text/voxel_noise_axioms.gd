extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Voxel Noise[/b][/font_size][/center]
[center][i]3D Terrain Generation[/i][/center]

**2D heightmaps are limited.** Voxels create caves, overhangs, floating islands - true 3D worlds.

**Voxel noise = volumetric generation from 3D noise functions.**

[hr]

[b]What Are Voxels?[/b]

**Voxel = volumetric pixel** - 3D grid cells, each solid or empty.

**Properties:**
- **Discrete** - World divided into cubic cells
- **Binary** - Each voxel is air OR solid (or material type)
- **Volumetric** - Supports caves, overhangs, tunnels

**Famous voxel games:** Minecraft, Terraria (2D), Teardown, 7 Days to Die

[hr]

[b]Density Function (Core Concept)[/b]

**Sample 3D noise, threshold for solid/air:**

[color=yellow][b]Code: Basic Voxel Generation[/b][/color]
[code]
# Sample 3D noise at each position
func get_voxel_type(x: int, y: int, z: int) -> int:
    var density = perlin_noise_3d(x * 0.05, y * 0.05, z * 0.05)

    if density > 0.0:
        return SOLID  # 1 = solid block
    else:
        return AIR    # 0 = empty

# Result: Blob-like terrain, organic caves
# Where noise > 0 = solid, noise < 0 = air
[/code]

**Density function** = scalar field in 3D space. Threshold creates surface.

[hr]

[b]Heightmap vs Volumetric[/b]

**Comparison:**

[color=yellow][b]Heightmap (2D Noise → Height)[/b][/color]
[code]
# Traditional terrain: Y = noise(X, Z)
func generate_heightmap_terrain(x: int, z: int) -> int:
    var height = perlin_noise(x * 0.01, z * 0.01) * 50 + 100

    return int(height)  # Y coordinate of surface

# Result: Rolling hills, mountains
# BUT: No caves, no overhangs, single surface
[/code]

[color=yellow][b]Volumetric (3D Noise → Density)[/b][/color]
[code]
# Voxel terrain: Density = noise(X, Y, Z)
func generate_voxel_terrain(x: int, y: int, z: int) -> int:
    var density = perlin_noise_3d(x * 0.05, y * 0.05, z * 0.05)

    if density > 0.0:
        return STONE
    else:
        return AIR

# Result: Organic blobs, caves, floating islands
# Can have multiple surfaces above each other
[/code]

**Volumetric is more powerful** - represents any 3D shape.

[hr]

[b]Combining 2D and 3D Noise[/b]

**Use heightmap as baseline, 3D noise for caves:**

[color=yellow][b]Code: Hybrid Terrain[/b][/color]
[code]
func get_voxel_hybrid(x: int, y: int, z: int) -> int:
    # 2D noise for base terrain height
    var base_height = perlin_noise(x * 0.01, z * 0.01) * 50 + 100

    # Below surface = solid (with cave carving)
    if y < base_height:
        # 3D noise for cave system
        var cave_noise = perlin_noise_3d(x * 0.05, y * 0.05, z * 0.05)

        if cave_noise > 0.3:  # Threshold for cave
            return AIR  # Carved out by cave
        else:
            return STONE
    else:
        return AIR  # Above surface

# Result: Terrain with underground cave network
# Best of both: surface terrain + volumetric caves
[/code]

[hr]

[b]Density Gradient (Vertical Falloff)[/b]

**Make density decrease with height:**

[color=yellow][b]Code: Vertical Gradient[/b][/color]
[code]
func get_voxel_with_gradient(x: int, y: int, z: int) -> int:
    # 3D noise
    var noise = perlin_noise_3d(x * 0.05, y * 0.05, z * 0.05)

    # Vertical gradient (higher Y = less density)
    var gradient = 1.0 - (y / 200.0)  # Decrease from Y=0 to Y=200

    # Combine noise + gradient
    var density = noise + gradient

    if density > 0.5:
        return STONE
    else:
        return AIR

# Result: Terrain thins out at high altitude
# Floating islands at top, solid ground at bottom
[/code]

**Gradient creates vertical structure** - terrain anchored to ground.

[hr]

[b]Multiple Noise Layers[/b]

**Large-scale + small-scale detail:**

[color=yellow][b]Code: Multi-Scale Voxel Noise[/b][/color]
[code]
func get_voxel_detailed(x: int, y: int, z: int) -> int:
    # Large-scale terrain shape (low frequency)
    var large_scale = perlin_noise_3d(x * 0.01, y * 0.01, z * 0.01)

    # Medium caves (medium frequency)
    var caves = perlin_noise_3d(x * 0.05, y * 0.05, z * 0.05)

    # Fine detail (high frequency)
    var detail = perlin_noise_3d(x * 0.2, y * 0.2, z * 0.2) * 0.1

    # Combine
    var density = large_scale + caves * 0.5 + detail

    # Vertical gradient
    density += 1.0 - (y / 100.0)

    if density > 0.5:
        return STONE
    else:
        return AIR

# Result: Large terrain features + cave systems + surface detail
[/code]

[hr]

[b]Biome-Based Materials[/b]

**Different voxel types by location:**

[color=yellow][b]Code: Material Selection[/b][/color]
[code]
const AIR = 0
const STONE = 1
const DIRT = 2
const SAND = 3
const SNOW = 4

func get_voxel_with_materials(x: int, y: int, z: int) -> int:
    var density = perlin_noise_3d(x * 0.05, y * 0.05, z * 0.05)
    density += 1.0 - (y / 100.0)

    if density < 0.5:
        return AIR

    # Determine material by biome
    var biome_noise = perlin_noise(x * 0.005, z * 0.005)

    if y > 120:
        return SNOW  # High altitude = snow
    elif biome_noise < 0.3:
        return SAND  # Desert biome
    elif y < 80:
        return STONE  # Deep underground
    else:
        return DIRT  # Default

# Result: Varied terrain materials by location and height
[/code]

[hr]

[b]Erosion and Secondary Processing[/b]

**Post-process generated voxels:**

[color=yellow][b]Code: Surface Dirt Layer[/b][/color]
[code]
func apply_surface_dirt(voxels: Array):
    for x in range(chunk_size):
        for z in range(chunk_size):
            # Find topmost solid voxel
            for y in range(chunk_size - 1, -1, -1):
                if voxels[x][y][z] == STONE:
                    # Replace top 3 layers with dirt
                    for depth in range(3):
                        if y - depth >= 0 and voxels[x][y - depth][z] == STONE:
                            voxels[x][y - depth][z] = DIRT

                    break  # Found surface, continue to next column

# Result: Stone terrain with dirt surface layer
# Like Minecraft grass/dirt on top of stone
[/code]

[hr]

[b]Marching Cubes (Smooth Voxels)[/b]

**Convert voxel density to smooth mesh:**

[color=yellow][b]Concept: Isosurface Extraction[/b][/color]
[code]
# Instead of cubic blocks, extract smooth surface from density field
# Marching cubes algorithm:
# 1. Sample density at 8 corners of each cube
# 2. Determine which edges are crossed by isosurface
# 3. Generate triangles at crossings
# 4. Result: Smooth terrain mesh

# Godot doesn't have built-in marching cubes,
# but libraries exist (e.g., Transvoxel, Dual Contouring)

# Result: Smooth organic terrain (like No Man's Sky)
# Not blocky like Minecraft
[/code]

[hr]

[b]Chunk System (Streaming)[/b]

**Load/unload voxel chunks as player moves:**

[color=yellow][b]Code: Chunk Generation[/b][/color]
[code]
const CHUNK_SIZE = 16
var loaded_chunks = {}

func get_chunk_coord(world_pos: Vector3i) -> Vector3i:
    return Vector3i(
        int(floor(world_pos.x / CHUNK_SIZE)),
        int(floor(world_pos.y / CHUNK_SIZE)),
        int(floor(world_pos.z / CHUNK_SIZE))
    )

func generate_chunk(chunk_coord: Vector3i):
    var voxels = []

    # Generate CHUNK_SIZE³ voxels
    for x in range(CHUNK_SIZE):
        var layer = []
        for y in range(CHUNK_SIZE):
            var column = []
            for z in range(CHUNK_SIZE):
                var world_x = chunk_coord.x * CHUNK_SIZE + x
                var world_y = chunk_coord.y * CHUNK_SIZE + y
                var world_z = chunk_coord.z * CHUNK_SIZE + z

                column.append(get_voxel(world_x, world_y, world_z))
            layer.append(column)
        voxels.append(layer)

    loaded_chunks[chunk_coord] = voxels
    generate_mesh_for_chunk(chunk_coord, voxels)

func update_chunks(player_pos: Vector3):
    var player_chunk = get_chunk_coord(Vector3i(player_pos))

    # Load chunks in radius
    for x in range(-view_distance, view_distance + 1):
        for y in range(-1, 2):  # Vertical range
            for z in range(-view_distance, view_distance + 1):
                var chunk_coord = player_chunk + Vector3i(x, y, z)
                if not loaded_chunks.has(chunk_coord):
                    generate_chunk(chunk_coord)

    # Unload distant chunks
    for coord in loaded_chunks.keys():
        if coord.distance_to(player_chunk) > view_distance + 2:
            unload_chunk(coord)

# Result: Infinite world, only nearby chunks loaded
[/code]

[hr]

[b]Meshing (Greedy Meshing)[/b]

**Convert voxels to renderable mesh efficiently:**

[color=yellow][b]Concept: Greedy Meshing[/b][/color]
[code]
# Naive: One quad per voxel face = many triangles
# Greedy: Merge adjacent same-type faces into larger quads

# Algorithm:
# 1. For each axis (X, Y, Z)
# 2. Scan along that axis
# 3. Merge runs of identical exposed faces
# 4. Create single large quad instead of many small ones

# Result: 10x-100x fewer triangles
# Essential for performance in voxel games
[/code]

[hr]

[b]3D Noise Types for Voxels[/b]

[color=yellow][b]1. Perlin 3D (Smooth Blobs)[/b][/color]
[code]
var density = perlin_noise_3d(x * 0.05, y * 0.05, z * 0.05)
# Result: Rounded caves, organic shapes
[/code]

[color=yellow][b]2. Worley 3D (Cellular Caves)[/b][/color]
[code]
var density = worley_noise_3d(x * 0.1, y * 0.1, z * 0.1)
# Result: Cell-like cave structure, chambers connected by tunnels
[/code]

[color=yellow][b]3. Ridged Multifractal (Mountain Ranges)[/b][/color]
[code]
var density = ridged_fbm_3d(x * 0.05, y * 0.05, z * 0.05, 6)
# Result: Sharp ridges, mountain peaks
[/code]

[color=yellow][b]4. Domain Warping (Swirling Formations)[/b][/color]
[code]
var warp = Vector3(
    perlin_noise_3d(x * 0.02, y * 0.02, z * 0.02),
    perlin_noise_3d(x * 0.02 + 5, y * 0.02, z * 0.02),
    perlin_noise_3d(x * 0.02, y * 0.02 + 5, z * 0.02)
) * 10.0

var density = perlin_noise_3d(x + warp.x, y + warp.y, z + warp.z)
# Result: Twisted, flowing cave systems
[/code]

[hr]

[b]Floating Islands[/b]

**Use vertical mask to create sky islands:**

[color=yellow][b]Code: Floating Island Generation[/b][/color]
[code]
func floating_island_density(x: int, y: int, z: int) -> float:
    var noise = perlin_noise_3d(x * 0.05, y * 0.05, z * 0.05)

    # Vertical mask: sphere-like falloff from Y=100
    var center_y = 100
    var vertical_dist = abs(y - center_y) / 30.0
    var vertical_mask = 1.0 - vertical_dist

    vertical_mask = clamp(vertical_mask, 0, 1)

    return noise + vertical_mask - 0.5

# Result: Island-like structures floating at Y=100
# Density peaks near center_y, drops above/below
[/code]

[hr]

[b]What Voxel Noise Reveals[/b]

Voxel noise shows us:

1. **3D freedom** - Caves, overhangs, floating islands impossible with heightmaps
2. **Density fields** - Scalar function in 3D space, threshold creates surface
3. **Hybrid approaches work** - 2D heightmap + 3D caves = best of both
4. **Vertical gradients structure** - Anchor terrain to ground, thin at top
5. **Multi-scale layering** - Large features + caves + detail
6. **Chunking essential** - Infinite worlds require streaming
7. **Meshing matters** - Greedy meshing dramatically reduces triangles
8. **Noise type = terrain character** - Perlin (smooth), Worley (cellular), ridged (mountains)

**Voxels are computational geology** - sculpting 3D space with mathematical functions.

**The world is a density field** - everything derived from noise.

[hr]

[color=cyan][b]Summary:[/b][/color]
Voxel noise generates 3D terrain using density functions (sample 3D noise, threshold for solid/air). Supports caves, overhangs, floating islands. Hybrid: 2D heightmap + 3D cave carving. Vertical gradients anchor terrain. Multi-scale layering (large + medium + detail). Biome-based materials. Chunk system for streaming infinite worlds. Greedy meshing for efficient rendering. Noise types: Perlin (smooth), Worley (cellular), ridged (mountains), domain warping (twisted). Marching cubes for smooth surfaces. Post-processing for erosion, surface layers.

[hr]

[color=orange][b]Conclusion:[/b] Randomness as Tool and Philosophy[/color]
We've explored randomness from bell curves to voxel worlds. Each type reveals computational truth - normalization as control, noise as texture, glitches as beauty, pheromones as coordination. Randomness is not chaos - it's structured unpredictability, the mathematics of variation, the resistance to uniformity.

'''
