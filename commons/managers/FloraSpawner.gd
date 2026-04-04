# @identity
# essence: reads EcosystemManager and scatters existing flora artifacts procedurally on the grid
# desire: the lab gradually becomes a garden — flowers at the edges, trees at intersections, mushrooms in shadows
# critical_parameter: vegetation_density — 0.0 is sterile lab, 1.0 is full ecosystem
# triggers: stage changes update kingdoms and density; spawner places flora accordingly
# emerges: the world grows around the learning — each sequence's principle shapes how nature appears
# truth: the flora already exists. the spawner just decides where and when.

class_name FloraSpawner
extends Node
## Procedurally places flora on the grid based on EcosystemManager state.
## Uses existing artifacts: evolving flowers, L-system trees, mushrooms, DNA creatures.
## VR-safe: spawns in batches, respects LOD, caps total instance count.

# ── Scene references (preloaded for fast spawning) ────────────────────────
const FLOWER_SCENES: Array[String] = [
	"res://algorithms/machinelearning/evolvingflowers/evolvingflowers.tscn",
	"res://algorithms/computationalbiology/bucketoftulips/ten_tulip_buckets.tscn",
]
const TREE_SCENES: Array[String] = [
	"res://algorithms/proceduralgeneration/lsystem/tree_l_system.tscn",
]
const FUNGUS_SCENES: Array[String] = [
	"res://algorithms/proceduralgeneration/mushrooms/mushrooms.tscn",
]
const CREATURE_SCENES: Array[String] = [
	"res://algorithms/nature_system/nature_system_demo.tscn",
]

# ── Limits (VR performance budget) ────────────────────────────────────────
const MAX_FLORA_INSTANCES: int = 30      ## Hard cap on total spawned flora
const MAX_FLOWERS: int = 12
const MAX_TREES: int = 6
const MAX_FUNGUS: int = 6
const MAX_CREATURES: int = 4
const SPAWN_SCALE: float = 0.3           ## Scale down flora to fit grid
const MIN_SPAWN_DISTANCE: float = 1.5    ## Minimum distance between spawns

# ── State ─────────────────────────────────────────────────────────────────
var _spawned: Array[Node3D] = []
var _spawn_root: Node3D = null
var _cached_density: float = -1.0
var _cached_kingdoms: Array = []
var _rng := RandomNumberGenerator.new()
var _grid_bounds: AABB = AABB()
var _poll_timer: float = 0.0

# ── Ecosystem reference ───────────────────────────────────────────────────
var _ecosystem: Node = null


func _ready() -> void:
	_spawn_root = Node3D.new()
	_spawn_root.name = "FloraRoot"
	add_child(_spawn_root)
	call_deferred("_find_ecosystem")


func _find_ecosystem() -> void:
	_ecosystem = get_node_or_null("/root/EcosystemManager")
	if not _ecosystem:
		# Try again later
		get_tree().create_timer(2.0).timeout.connect(_find_ecosystem)
		return
	# Find grid bounds from GridSystem
	var grid := _find_grid_system()
	if grid:
		_compute_grid_bounds(grid)
	_rng.seed = get_instance_id()
	print("FloraSpawner: ready (ecosystem found, bounds=%s)" % _grid_bounds)


func _process(delta: float) -> void:
	if not _ecosystem:
		return
	_poll_timer += delta
	if _poll_timer < 2.0:  # Check every 2 seconds
		return
	_poll_timer = 0.0

	var density: float = _ecosystem.get("vegetation_density") if _ecosystem.get("vegetation_density") != null else 0.0
	var kingdoms: Array = _ecosystem.get("nature_kingdoms") if _ecosystem.get("nature_kingdoms") != null else []

	if abs(density - _cached_density) < 0.01 and kingdoms == _cached_kingdoms:
		return

	_cached_density = density
	_cached_kingdoms = kingdoms.duplicate()
	_rebuild_flora()


# ═════════════════════════════════════════════════════════════════════════
# FLORA PLACEMENT — the core logic
# ═════════════════════════════════════════════════════════════════════════

func _rebuild_flora() -> void:
	_clear_flora()

	if _cached_density < 0.05:
		return  # Lab is sterile

	print("FloraSpawner: rebuilding — density=%.2f kingdoms=%s" % [_cached_density, _cached_kingdoms])

	# Compute how many of each type based on density and kingdoms
	var flower_count: int = 0
	var tree_count: int = 0
	var fungus_count: int = 0
	var creature_count: int = 0

	if "flower" in _cached_kingdoms:
		flower_count = clampi(int(_cached_density * MAX_FLOWERS), 1, MAX_FLOWERS)
	if "tree" in _cached_kingdoms:
		tree_count = clampi(int(_cached_density * MAX_TREES), 1, MAX_TREES)
	if "fungus" in _cached_kingdoms:
		fungus_count = clampi(int(_cached_density * MAX_FUNGUS), 1, MAX_FUNGUS)
	if "creature" in _cached_kingdoms:
		creature_count = clampi(int(_cached_density * MAX_CREATURES), 1, MAX_CREATURES)

	# Respect total cap
	var total: int = flower_count + tree_count + fungus_count + creature_count
	if total > MAX_FLORA_INSTANCES:
		var scale_factor: float = float(MAX_FLORA_INSTANCES) / float(total)
		flower_count = int(flower_count * scale_factor)
		tree_count = int(tree_count * scale_factor)
		fungus_count = int(fungus_count * scale_factor)
		creature_count = int(creature_count * scale_factor)

	# Spawn in order: flowers first (cheapest), then trees, fungus, creatures
	var occupied: Array[Vector3] = []

	for i in flower_count:
		_spawn_flora_at_random(FLOWER_SCENES, occupied, SPAWN_SCALE * 0.5)

	for i in tree_count:
		_spawn_flora_at_random(TREE_SCENES, occupied, SPAWN_SCALE)

	for i in fungus_count:
		_spawn_flora_at_random(FUNGUS_SCENES, occupied, SPAWN_SCALE * 0.4)

	for i in creature_count:
		_spawn_flora_at_random(CREATURE_SCENES, occupied, SPAWN_SCALE * 0.6)

	print("FloraSpawner: placed %d flora (%d flowers, %d trees, %d fungus, %d creatures)" % [
		_spawned.size(), flower_count, tree_count, fungus_count, creature_count])


func _spawn_flora_at_random(scene_paths: Array[String], occupied: Array[Vector3], scale: float) -> void:
	if scene_paths.is_empty():
		return
	if _spawned.size() >= MAX_FLORA_INSTANCES:
		return

	# Pick a random scene from available options
	var scene_path: String = scene_paths[_rng.randi() % scene_paths.size()]
	var scene: PackedScene = load(scene_path) as PackedScene
	if not scene:
		push_warning("FloraSpawner: could not load %s" % scene_path)
		return

	# Find a position that doesn't overlap existing spawns
	var pos := _find_spawn_position(occupied)
	if pos == Vector3.INF:
		return  # No valid position found

	var instance: Node3D = scene.instantiate() as Node3D
	if not instance:
		return

	instance.position = pos
	instance.scale = Vector3.ONE * scale

	# Random Y rotation for variety
	instance.rotation.y = _rng.randf() * TAU

	# Apply grid config if available
	if instance.has_method("apply_grid_config"):
		instance.apply_grid_config({})

	_spawn_root.add_child(instance)
	_spawned.append(instance)
	occupied.append(pos)


func _find_spawn_position(occupied: Array[Vector3]) -> Vector3:
	## Find a random position within grid bounds that's not too close to existing spawns.
	## Tries 20 times then gives up.
	for _attempt in 20:
		var x: float = _rng.randf_range(_grid_bounds.position.x, _grid_bounds.end.x)
		var z: float = _rng.randf_range(_grid_bounds.position.z, _grid_bounds.end.z)
		var pos := Vector3(x, 0.5, z)  # Slightly above ground

		# Check minimum distance from all existing spawns
		var too_close := false
		for existing in occupied:
			if pos.distance_to(existing) < MIN_SPAWN_DISTANCE:
				too_close = true
				break

		if not too_close:
			return pos

	return Vector3.INF  # Failed to find valid position


func _clear_flora() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()


# ═════════════════════════════════════════════════════════════════════════
# GRID BOUNDS — figure out where we can place flora
# ═════════════════════════════════════════════════════════════════════════

func _find_grid_system() -> Node:
	var grid := get_tree().root.find_child("GridSystem", true, false)
	if grid:
		return grid
	return get_tree().root.find_child("LabGridSystem", true, false)


func _compute_grid_bounds(grid: Node) -> void:
	# Try to read dimensions from grid
	var width: float = 10.0
	var depth: float = 10.0

	if grid.has_method("get") and "map_width" in grid:
		width = float(grid.get("map_width"))
	if grid.has_method("get") and "map_depth" in grid:
		depth = float(grid.get("map_depth"))

	# Also try data component
	var data_comp := grid.find_child("GridDataComponent", true, false)
	if data_comp and data_comp.has_method("get"):
		if "layout_width" in data_comp:
			width = float(data_comp.get("layout_width"))
		if "layout_depth" in data_comp:
			depth = float(data_comp.get("layout_depth"))

	# Fallback to reasonable defaults
	_grid_bounds = AABB(
		Vector3(-width * 0.3, 0, -depth * 0.3),  # Inset from edges
		Vector3(width * 0.6, 2.0, depth * 0.6)
	)


# ═════════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════════

func apply_grid_config(_config: Dictionary) -> void:
	# Force re-evaluation on map change
	_cached_density = -1.0
	_cached_kingdoms = []
