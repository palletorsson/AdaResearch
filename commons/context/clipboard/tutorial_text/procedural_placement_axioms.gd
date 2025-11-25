extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Procedural Placement[/b][/font_size][/center]
[center][i]Scattering Objects Intelligently[/i][/center]

**Hand-placing 10,000 trees is torture.** Algorithms place them better, faster, more naturally.

**Procedural placement = rules that create believable distribution.**

[hr]

[b]The Naive Approach: Uniform Random[/b]

**Just scatter randomly? Looks terrible.**

[color=yellow][b]Code: Bad Random Placement[/b][/color]
[code]
# Don't do this for natural-looking placement
func place_trees_random(count: int, bounds: Rect2):
    for i in range(count):
        var x = randf() * bounds.size.x + bounds.position.x
        var z = randf() * bounds.size.y + bounds.position.y

        var tree = tree_scene.instantiate()
        tree.position = Vector3(x, 0, z)
        add_child(tree)

# Problems:
# - Trees cluster (Poisson clumping)
# - Trees overlap (no collision checking)
# - Trees in water/on cliffs (no terrain awareness)
# - All same type (no variety)
[/code]

**Result:** Unnatural, overlapping, ignorant of environment.

[hr]

[b]Blue Noise Placement (Better)[/b]

**Use Poisson disk sampling** (from blue_noise_axioms.gd):

[color=yellow][b]Code: Evenly Distributed Trees[/b][/color]
[code]
# Use Poisson disk for minimum distance
func place_trees_blue_noise(min_distance: float, bounds: Rect2):
    var points = poisson_disk_sample(bounds.size.x, bounds.size.y, min_distance)

    for point in points:
        var world_pos = Vector3(
            point.x + bounds.position.x,
            0,
            point.y + bounds.position.y
        )

        var tree = tree_scene.instantiate()
        tree.position = world_pos
        add_child(tree)

# Result: No overlaps, evenly spread, natural-looking
[/code]

**Blue noise prevents clustering** - better baseline than uniform random.

[hr]

[b]Terrain-Aware Placement[/b]

**Check terrain properties before placing:**

[color=yellow][b]Code: Slope and Height Filtering[/b][/color]
[code]
# Only place on valid terrain
func place_with_terrain_check(points: Array):
    for point in points:
        var world_pos = Vector3(point.x, 0, point.y)

        # Raycast down to find ground height
        var space_state = get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(
            world_pos + Vector3.UP * 100,
            world_pos + Vector3.DOWN * 100
        )
        var result = space_state.intersect_ray(query)

        if result:
            var ground_pos = result.position
            var normal = result.normal

            # Calculate slope (angle from vertical)
            var slope_angle = rad_to_deg(acos(normal.dot(Vector3.UP)))

            # Check height (water level = 0)
            var height = ground_pos.y

            # Filter: only flat-ish ground above water
            if slope_angle < 30 and height > 2:
                var tree = tree_scene.instantiate()
                tree.position = ground_pos
                tree.rotation.y = randf() * TAU  # Random rotation
                add_child(tree)

# Result: Trees on flat ground, not in water or on cliffs
[/code]

**Terrain awareness makes placement believable.**

[hr]

[b]Biome-Based Placement[/b]

**Different objects in different areas:**

[color=yellow][b]Code: Biome Map Sampling[/b][/color]
[code]
# Use noise to define biomes
func get_biome(x: float, z: float) -> String:
    var value = perlin_noise(x * 0.01, z * 0.01)

    if value < 0.3:
        return "desert"
    elif value < 0.6:
        return "grassland"
    else:
        return "forest"

func place_biome_aware(points: Array):
    for point in points:
        var biome = get_biome(point.x, point.y)

        match biome:
            "desert":
                if randf() < 0.3:  # Sparse cacti
                    spawn_object(cactus_scene, point)
            "grassland":
                if randf() < 0.6:  # Some bushes
                    spawn_object(bush_scene, point)
            "forest":
                if randf() < 0.9:  # Dense trees
                    spawn_object(tree_scene, point)

# Result: Desert is sparse, forest is dense
# Each biome has characteristic appearance
[/code]

[hr]

[b]Density Variation (Importance Sampling)[/b]

**More objects near paths/player-visible areas:**

[color=yellow][b]Code: Weighted Density[/b][/color]
[code]
# Importance map (higher = more objects)
func get_importance(x: float, z: float) -> float:
    var distance_to_path = get_distance_to_nearest_path(Vector2(x, z))

    # More objects near path (player sees them)
    var importance = clamp(1.0 - distance_to_path / 50.0, 0.1, 1.0)
    return importance

func place_with_density_variation(base_points: Array):
    for point in base_points:
        var importance = get_importance(point.x, point.y)

        # Higher importance = higher probability of placement
        if randf() < importance:
            spawn_object(tree_scene, point)

# Result: Dense near paths, sparse far away
# Optimization: detail where player looks
[/code]

**Importance sampling** = allocate detail budget wisely.

[hr]

[b]Layered Placement (Multiple Passes)[/b]

**Place different object types in sequence:**

[color=yellow][b]Code: Multi-Layer Spawning[/b][/color]
[code]
func populate_world(bounds: Rect2):
    # Layer 1: Large trees (sparse, 10m spacing)
    var tree_points = poisson_disk_sample(bounds.size.x, bounds.size.y, 10.0)
    for point in tree_points:
        if terrain_valid(point):
            spawn_object(large_tree_scene, point)

    # Layer 2: Bushes (medium density, 5m spacing)
    var bush_points = poisson_disk_sample(bounds.size.x, bounds.size.y, 5.0)
    for point in bush_points:
        if terrain_valid(point) and not near_tree(point):
            spawn_object(bush_scene, point)

    # Layer 3: Rocks (dense, 2m spacing)
    var rock_points = poisson_disk_sample(bounds.size.x, bounds.size.y, 2.0)
    for point in rock_points:
        if terrain_valid(point):
            spawn_object(rock_scene, point)

# Result: Hierarchical detail - large sparse, small dense
[/code]

[hr]

[b]Clustering (Groups of Objects)[/b]

**Natural objects group together:**

[color=yellow][b]Code: Cluster Spawning[/b][/color]
[code]
# Place cluster centers with blue noise
var cluster_centers = poisson_disk_sample(1000, 1000, 50.0)

for center in cluster_centers:
    # Spawn 3-7 trees around each center
    var tree_count = randi_range(3, 7)

    for i in range(tree_count):
        # Offset from center (Gaussian distribution)
        var offset = Vector2(
            gaussian_random(0, 5),
            gaussian_random(0, 5)
        )
        var tree_pos = center + offset

        if terrain_valid(tree_pos):
            var tree = tree_scene.instantiate()
            tree.position = Vector3(tree_pos.x, 0, tree_pos.y)
            add_child(tree)

# Result: Trees in natural-looking clumps
# Like real forests (trees seed near parent)
[/code]

**Clustering mimics natural growth patterns.**

[hr]

[b]Exclusion Zones (Negative Space)[/b]

**Keep areas clear:**

[color=yellow][b]Code: Exclusion Filtering[/b][/color]
[code]
var exclusion_zones = [
    {"center": Vector2(100, 100), "radius": 20},  # Town
    {"center": Vector2(300, 200), "radius": 10},  # Campsite
]

func is_in_exclusion_zone(point: Vector2) -> bool:
    for zone in exclusion_zones:
        if point.distance_to(zone.center) < zone.radius:
            return true
    return false

func place_with_exclusions(points: Array):
    for point in points:
        if not is_in_exclusion_zone(point) and terrain_valid(point):
            spawn_object(tree_scene, point)

# Result: Clear areas for towns, paths, buildings
[/code]

[hr]

[b]Variety (Random Object Selection)[/b]

**Don't spawn same object everywhere:**

[color=yellow][b]Code: Weighted Random Selection[/b][/color]
[code]
var tree_types = [
    {"scene": oak_tree_scene, "weight": 50},
    {"scene": pine_tree_scene, "weight": 30},
    {"scene": birch_tree_scene, "weight": 15},
    {"scene": dead_tree_scene, "weight": 5},
]

func select_random_tree() -> PackedScene:
    var total_weight = 0
    for tree_type in tree_types:
        total_weight += tree_type.weight

    var random_value = randf() * total_weight
    var cumulative = 0.0

    for tree_type in tree_types:
        cumulative += tree_type.weight
        if random_value < cumulative:
            return tree_type.scene

    return tree_types[0].scene  # Fallback

# Result: 50% oak, 30% pine, 15% birch, 5% dead
# Varied forest, not monoculture
[/code]

[hr]

[b]Scale Variation[/b]

**Randomize size for naturalism:**

[color=yellow][b]Code: Random Scale[/b][/color]
[code]
func spawn_object(scene: PackedScene, point: Vector2):
    var obj = scene.instantiate()
    obj.position = Vector3(point.x, 0, point.y)

    # Random rotation
    obj.rotation.y = randf() * TAU

    # Random scale (log-normal distribution)
    var scale_factor = log_normal_random(0, 0.3)
    scale_factor = clamp(scale_factor, 0.7, 1.5)
    obj.scale = Vector3.ONE * scale_factor

    add_child(obj)

# Result: Trees of varying sizes
# More natural than uniform scale
[/code]

[hr]

[b]Grid-Based Chunking (Streaming)[/b]

**Place objects in chunks for open-world streaming:**

[color=yellow][b]Code: Chunk System[/b][/color]
[code]
var chunk_size = 100
var loaded_chunks = {}

func get_chunk_coord(world_pos: Vector2) -> Vector2i:
    return Vector2i(
        int(floor(world_pos.x / chunk_size)),
        int(floor(world_pos.y / chunk_size))
    )

func load_chunk(chunk_coord: Vector2i):
    if loaded_chunks.has(chunk_coord):
        return  # Already loaded

    # Seed random generator with chunk coords
    seed(hash_2d(chunk_coord.x, chunk_coord.y))

    var bounds = Rect2(
        chunk_coord.x * chunk_size,
        chunk_coord.y * chunk_size,
        chunk_size,
        chunk_size
    )

    var points = poisson_disk_sample(chunk_size, chunk_size, 10.0)
    var chunk_objects = []

    for point in points:
        var world_pos = point + bounds.position
        var obj = tree_scene.instantiate()
        obj.position = Vector3(world_pos.x, 0, world_pos.y)
        add_child(obj)
        chunk_objects.append(obj)

    loaded_chunks[chunk_coord] = chunk_objects

func unload_chunk(chunk_coord: Vector2i):
    if not loaded_chunks.has(chunk_coord):
        return

    for obj in loaded_chunks[chunk_coord]:
        obj.queue_free()

    loaded_chunks.erase(chunk_coord)

# Call load_chunk/unload_chunk based on player position
[/code]

**Result:** Infinite world, only nearby chunks loaded.

[hr]

[b]Painter's Algorithm (Paint Density)[/b]

**User paints where objects should be:**

[color=yellow][b]Code: Density Map Painting[/b][/color]
[code]
# Use image as density map (painted in editor)
var density_map: Image

func place_from_density_map():
    var points = []

    # Sample many candidate points
    for i in range(10000):
        var x = randf() * 1000
        var y = randf() * 1000

        # Sample density map (grayscale 0-1)
        var density = density_map.get_pixel(int(x), int(y)).r

        # Accept point with probability = density
        if randf() < density:
            points.append(Vector2(x, y))

    # Now place objects at accepted points
    for point in points:
        spawn_object(tree_scene, point)

# Result: Dense where painted white, sparse where black
# Artist control + procedural placement
[/code]

[hr]

[b]Noise-Driven Placement[/b]

**Use noise functions to control density:**

[color=yellow][b]Code: Perlin-Based Density[/b][/color]
[code]
func place_noise_driven(count: int):
    for i in range(count):
        var x = randf() * 1000
        var z = randf() * 1000

        # Sample noise (0-1)
        var noise_value = perlin_noise(x * 0.01, z * 0.01)

        # Accept point if noise above threshold
        if noise_value > 0.5:
            var tree = tree_scene.instantiate()
            tree.position = Vector3(x, 0, z)
            add_child(tree)

# Result: Organic patches of trees
# Smooth density variation from noise
[/code]

[hr]

[b]Avoiding Overlaps (Physics Check)[/b]

**Don't place where existing objects:**

[color=yellow][b]Code: Sphere Cast Validation[/b][/color]
[code]
func is_space_clear(position: Vector3, radius: float) -> bool:
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsShapeQueryParameters3D.new()

    var sphere = SphereShape3D.new()
    sphere.radius = radius
    query.shape = sphere
    query.transform.origin = position

    var result = space_state.intersect_shape(query, 1)
    return result.is_empty()

func place_with_collision_check(points: Array, radius: float):
    for point in points:
        var world_pos = Vector3(point.x, 0, point.y)

        if is_space_clear(world_pos, radius):
            var tree = tree_scene.instantiate()
            tree.position = world_pos
            add_child(tree)

# Result: No overlapping trees
[/code]

[hr]

[b]What Procedural Placement Reveals[/b]

Procedural placement shows us:

1. **Uniform random looks bad** - Clusters and overlaps
2. **Blue noise is baseline** - Minimum distance prevents clumping
3. **Terrain awareness essential** - Check slope, height, biome
4. **Layering creates hierarchy** - Large sparse, small dense
5. **Clustering mimics nature** - Objects group around seeds
6. **Variety prevents monotony** - Random types, scales, rotations
7. **Chunking enables streaming** - Load/unload as player moves
8. **Noise controls density** - Organic variation from Perlin/Worley
9. **Artist control hybrid** - Paint density, algorithm places

**Procedural placement is algorithmic gardening** - rules that create natural-looking distribution without hand-placement tedium.

**The algorithm knows what looks good** - better than random scatter, faster than manual work.

[hr]

[color=cyan][b]Summary:[/b][/color]
Procedural placement scatters objects using algorithms. Uniform random creates clusters/overlaps (bad). Blue noise (Poisson disk) prevents clumping (better baseline). Terrain-aware placement checks slope/height/biome. Density variation via importance sampling or noise functions. Layered placement (multiple passes for different object types). Clustering for natural grouping. Exclusion zones keep areas clear. Variety through weighted random selection and scale variation. Grid-based chunking for streaming large worlds. Artist-controlled density maps. Physics checks prevent overlaps.

[hr]

[color=orange][b]Next:[/b] Random Transformations[/color]
If placement scatters positions, transformations randomize geometry - rotation, scale, color, deformation. Making identical models look unique through procedural variation.

'''
