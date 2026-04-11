# EcosystemNatureSpawner.gd
# Bridges EcosystemManager flags to the Nature System's CritterSpawner.
# Placed in maps (or Lab) to populate flora/fauna based on progression state.
# Listens to ecosystem_stage_advanced and rebuilds vegetation accordingly.

extends Node3D
class_name EcosystemNatureSpawner

# ── Configuration ─────────────────────────────────────────────────────

## Spawn radius around the spawner origin.
@export var spawn_radius: float = 12.0

## Max population for this spawner instance.
@export var max_population: int = 40

## Spawn center offset from this node's position.
@export var center_offset: Vector3 = Vector3.ZERO

## Seed for deterministic placement (-1 = random).
@export var rng_seed: int = -1

## Use chunk-based LOD system (recommended for VR performance).
## When true, a ChunkManager handles spatial LOD and visibility ranges.
## When false, uses flat-circle spawning (legacy behavior).
@export var use_chunk_system: bool = true

## Override EcosystemManager density for testing (-1 = use progression).
@export var override_density: float = -1.0

## Override EcosystemManager kingdoms for testing (empty = use progression).
@export var override_kingdoms: Array[String] = []

# ── Runtime ───────────────────────────────────────────────────────────

var _spawner: CritterSpawner = null
var _nature_root: Node3D = null
var _has_populated: bool = false
var _chunk_manager: ChunkManager = null

# Kingdom IDs matching CritterDNA
const KINGDOM_FLOWER: int = 0
const KINGDOM_TREE: int = 1
const KINGDOM_FUNGUS: int = 2
const KINGDOM_CREATURE: int = 3

# Kingdom name to ID mapping
const KINGDOM_MAP: Dictionary = {
	"flower": KINGDOM_FLOWER,
	"tree": KINGDOM_TREE,
	"fungus": KINGDOM_FUNGUS,
	"creature": KINGDOM_CREATURE,
}


func _ready() -> void:
	if use_chunk_system:
		# Delegate to ChunkManager for spatial LOD
		_chunk_manager = ChunkManager.new()
		_chunk_manager.name = "ChunkManager"
		_chunk_manager.spawn_radius = spawn_radius
		_chunk_manager.max_population = max_population
		_chunk_manager.center_offset = center_offset
		_chunk_manager.rng_seed = rng_seed
		_chunk_manager.override_density = override_density
		_chunk_manager.override_kingdoms = override_kingdoms
		add_child(_chunk_manager)
		# ChunkManager handles its own signals and lifecycle
		print("EcosystemNatureSpawner: Using chunk-based LOD system")
		return

	# Legacy flat-circle spawning
	_nature_root = Node3D.new()
	_nature_root.name = "NaturePopulation"
	add_child(_nature_root)

	_spawner = CritterSpawner.new(_nature_root)
	_spawner.max_population = max_population
	_spawner.default_lod = _get_ecosystem_lod()

	# Connect to EcosystemManager
	call_deferred("_connect_signals")
	# Initial population after scene settles
	call_deferred("_initial_populate")


func _connect_signals() -> void:
	var eco = get_node_or_null("/root/EcosystemManager")
	if eco:
		if eco.has_signal("ecosystem_stage_advanced"):
			eco.ecosystem_stage_advanced.connect(_on_stage_advanced)
		if eco.has_signal("vegetation_config_changed"):
			eco.vegetation_config_changed.connect(_on_vegetation_changed)
		print("EcosystemNatureSpawner: Connected to EcosystemManager")


func _initial_populate() -> void:
	# Wait a frame for everything to be ready
	await get_tree().process_frame
	_rebuild_population()


func _on_stage_advanced(_sequence_name: String) -> void:
	_rebuild_population()


func _on_vegetation_changed(_config: Dictionary) -> void:
	_rebuild_population()


# ── Population Logic ──────────────────────────────────────────────────

func _rebuild_population() -> void:
	var eco = get_node_or_null("/root/EcosystemManager")
	if not eco:
		return

	var density: float = eco.get_vegetation_density()
	var kingdoms: Array = eco.get_allowed_kingdoms()
	var lod: int = eco.get_morphology_lod()

	# Nothing to spawn if density is zero or no kingdoms allowed
	if density <= 0.0 or kingdoms.is_empty():
		if _spawner.get_population_count() > 0:
			_spawner.despawn_all()
		return

	# Calculate target count based on density
	var target_count: int = int(max_population * density)
	var current_count: int = _spawner.get_population_count()

	# Update LOD
	_spawner.default_lod = lod

	# If we already have roughly the right population, skip
	if abs(current_count - target_count) < 3 and _has_populated:
		return

	# Clear and rebuild (simple approach — could be incremental later)
	_spawner.despawn_all()

	var center := global_position + center_offset
	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	# Distribute across allowed kingdoms
	var kingdom_ids: Array[int] = []
	for k_name in kingdoms:
		if KINGDOM_MAP.has(k_name):
			kingdom_ids.append(KINGDOM_MAP[k_name])

	if kingdom_ids.is_empty():
		return

	var per_kingdom: int = max(1, target_count / kingdom_ids.size())
	var spawned_total: int = 0

	for kid in kingdom_ids:
		var count: int = per_kingdom
		# Give flowers more weight early, creatures more weight late
		if kid == KINGDOM_FLOWER and density < 0.5:
			count = int(count * 1.5)
		elif kid == KINGDOM_CREATURE and density < 0.7:
			count = int(count * 0.5)

		var batch: Array = _spawner.seed_population(
			kid, count, center, spawn_radius,
			rng.randi() if rng_seed >= 0 else -1
		)
		spawned_total += batch.size()

	_has_populated = true
	print("EcosystemNatureSpawner: Populated %d critters (density=%.2f, kingdoms=%s, lod=%d)" % [
		spawned_total, density, str(kingdoms), lod
	])


func _get_ecosystem_lod() -> int:
	var eco = get_node_or_null("/root/EcosystemManager")
	if eco:
		return eco.get_morphology_lod()
	return 2
