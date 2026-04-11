# EcosystemViewport.gd — The living world where released specimens coexist
#
# Manages the shared ecosystem: terrain, population, evolution cycles,
# ecology interactions, and the HUD. This is the culmination of the
# Pokemon Studio — where all kingdoms meet, mate, and evolve.
#
# Usage:
#   var ecosystem := EcosystemViewport.new()
#   add_child(ecosystem)
#   ecosystem.start()

class_name EcosystemViewport
extends Node3D

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## Size of the ecosystem terrain (meters, square).
@export var terrain_size: float = 50.0

## How often evolution cycles run (seconds).
@export var evolution_interval: float = 30.0

## Maximum population in the ecosystem.
@export var max_population: int = 120

## Target population for evolution (try to maintain this many).
@export var target_population: int = 60

## Enable automatic evolution cycles.
@export var auto_evolve: bool = true

## LOD update interval (seconds).
@export var lod_update_interval: float = 0.5


# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

## Fired after each evolution cycle with stats.
signal evolution_tick(generation: int, stats: Dictionary)

## Fired when a notable ecology event occurs.
signal ecology_event(event_type: String, data: Dictionary)

## Fired when population changes significantly.
signal population_changed(summary: Dictionary)


# ─────────────────────────────────────────────────────────────
#  Subsystems (exposed for external wiring)
# ─────────────────────────────────────────────────────────────

## The spawner managing all ecosystem entities.
var spawner: CritterSpawner = null

## The evolution system running generational cycles.
var evolution: EvolutionSystem = null

## The ecology system running real-time interactions.
var ecology: EcologyInteractionSystem = null

## The transmutation manager for player bonds.
var transmutation: TransmutationManager = null

## The lineage tracker.
var lineage: LineageTracker = null

## The presence grid (living ground memory).
var presence: PresenceGrid = null

## The ground spawner (procedural ecosystem from ground presence).
var ground_spawner: GroundSpawner = null


# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

var _terrain_mesh: MeshInstance3D = null
var _lod_timer: float = 0.0
var _stats_history: Array[Dictionary] = []
var _running: bool = false


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	# Initialize subsystems
	spawner = CritterSpawner.new()
	spawner.max_population = max_population
	spawner.world_root = self

	evolution = EvolutionSystem.new()
	evolution.spawner = spawner
	evolution.target_population = target_population
	evolution.max_population = max_population

	ecology = EcologyInteractionSystem.new()

	transmutation = TransmutationManager.new()
	evolution.transmutation_manager = transmutation

	lineage = LineageTracker.new()
	lineage.load_data()

	# Presence grid — living ground memory
	presence = PresenceGrid.new(128, Vector2(terrain_size, terrain_size))

	# Ground spawner — procedural ecosystem from ground presence
	ground_spawner = GroundSpawner.new()
	ground_spawner.spawner = spawner
	ground_spawner.presence = presence
	ground_spawner.terrain_size = terrain_size

	# Wire signals
	evolution.generation_complete.connect(_on_generation_complete)
	evolution.critter_born.connect(_on_critter_born)
	evolution.critter_died.connect(_on_critter_died)
	ecology.ecology_event.connect(_on_ecology_event)

	# Build the terrain
	_build_terrain()


func _process(delta: float) -> void:
	if not _running:
		return

	# Evolution auto-cycling
	if auto_evolve:
		evolution.process(delta)

	# Ecology real-time interactions
	ecology.process(spawner, delta)

	# Ground spawner — new organisms grow from fertile ground
	if ground_spawner:
		ground_spawner.process(delta)

	# Presence grid — organisms mark the ground
	if presence:
		_deposit_presence()
		presence.process(delta)
		# Update ground shader texture
		if _terrain_mesh and _terrain_mesh.material_override is ShaderMaterial:
			(_terrain_mesh.material_override as ShaderMaterial).set_shader_parameter(
				"presence_map", presence.get_texture()
			)

	# LOD updates
	_lod_timer += delta
	if _lod_timer >= lod_update_interval:
		_lod_timer = 0.0
		spawner.update_lod_levels()


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

## Start the ecosystem (begins evolution cycles and ecology interactions).
func start() -> void:
	_running = true
	if auto_evolve:
		evolution.start(evolution_interval)


## Stop the ecosystem.
func stop() -> void:
	_running = false
	evolution.stop()


## Whether the ecosystem is running.
func is_running() -> bool:
	return _running


## Set the VR camera position for LOD reference.
func set_camera_position(pos: Vector3) -> void:
	spawner.update_lod_reference(pos)


## Manually trigger one evolution cycle.
func evolve_step() -> void:
	evolution.evolve_step()


## Get the current population summary.
func get_population_summary() -> Dictionary:
	return spawner.get_population_summary()


## Get the ecosystem's diversity score.
func get_diversity() -> float:
	return evolution.get_diversity()


## Get stats from the last evolution cycle.
func get_last_evolution_stats() -> Dictionary:
	return evolution.get_last_stats()


## Get ecology stats from the last tick.
func get_last_ecology_stats() -> Dictionary:
	return ecology.get_last_stats()


## Get the full stats history (all recorded generations).
func get_stats_history() -> Array[Dictionary]:
	return _stats_history


## Seed the ecosystem with a starting population.
func seed_initial_population(
	count_per_kingdom: int = 5,
	kingdoms: Array[int] = [0, 1, 2, 3]
) -> void:
	var center := Vector3(terrain_size / 4.0, 0, terrain_size / 4.0)
	var radius: float = terrain_size * 0.3

	for kingdom in kingdoms:
		spawner.seed_population(kingdom, count_per_kingdom, center, radius)

	population_changed.emit(spawner.get_population_summary())


## Export ecosystem state as a JSON dictionary (for web editor dashboard).
func export_state() -> Dictionary:
	return {
		"running": _running,
		"generation": evolution.current_generation,
		"population": spawner.get_population_summary(),
		"diversity": get_diversity(),
		"last_evolution": evolution.get_last_stats(),
		"last_ecology": ecology.get_last_stats(),
		"stats_history_count": _stats_history.size(),
	}


## Write ecosystem state to a JSON file (for web editor polling).
func save_stats_snapshot() -> void:
	var data: Dictionary = export_state()
	DirAccess.make_dir_recursive_absolute("user://pokemon_studio/")
	var path: String = "user://pokemon_studio/ecosystem_stats.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


# ═══════════════════════════════════════════════════════════════
# SIGNAL HANDLERS
# ═══════════════════════════════════════════════════════════════

func _on_generation_complete(gen_number: int, stats: Dictionary) -> void:
	_stats_history.append(stats)
	# Cap history to prevent unbounded growth
	if _stats_history.size() > 500:
		_stats_history = _stats_history.slice(-250)

	evolution_tick.emit(gen_number, stats)
	population_changed.emit(spawner.get_population_summary())

	# Periodically save stats for web editor
	if gen_number % 5 == 0:
		save_stats_snapshot()


func _on_critter_born(entity: CritterEntity, parent_a: CritterEntity, parent_b: CritterEntity) -> void:
	if lineage:
		lineage.record_entity_birth(entity, parent_a, parent_b)


func _on_critter_died(entity: CritterEntity, cause: String) -> void:
	ecology_event.emit("death", {"entity_name": entity.name, "cause": cause})


func _on_ecology_event(event_type: String, data: Dictionary) -> void:
	ecology_event.emit(event_type, data)


# ═══════════════════════════════════════════════════════════════
# TERRAIN
# ═══════════════════════════════════════════════════════════════

## Build the terrain with living ground shader.
func _build_terrain() -> void:
	_terrain_mesh = MeshInstance3D.new()
	_terrain_mesh.name = "Terrain"

	var plane := PlaneMesh.new()
	plane.size = Vector2(terrain_size, terrain_size)
	plane.subdivide_depth = 32  # More subdivisions for vertex displacement
	plane.subdivide_width = 32
	_terrain_mesh.mesh = plane

	# Use living ground shader if available, fallback to standard material
	var shader_path: String = "res://algorithms/nature_system/shaders/living_ground.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader: Shader = load(shader_path)
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("world_size", Vector2(terrain_size, terrain_size))
		mat.set_shader_parameter("world_offset", Vector2.ZERO)
		if presence:
			mat.set_shader_parameter("presence_map", presence.get_texture())
		_terrain_mesh.material_override = mat
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.22, 0.12)
		mat.roughness = 0.9
		_terrain_mesh.material_override = mat

	add_child(_terrain_mesh)


## Deposit presence from all active organisms.
func _deposit_presence() -> void:
	if not presence or not spawner:
		return
	for entity in spawner.get_active_critters():
		if not is_instance_valid(entity) or not entity.dna:
			continue
		presence.deposit_from_entity(
			entity.global_position,
			entity.get_kingdom(),
			entity.dna.scent_strength,
			entity.dna.scale
		)
