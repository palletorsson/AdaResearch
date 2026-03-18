# nature_system_demo.gd — Visual test scene for the Nature System
#
# Spawns critters from all 4 kingdoms in a grid so you can see what
# the morphology generators produce. Press keys to interact:
#
#   1-4     Spawn a random critter (1=tree, 2=creature, 3=flower, 4=fungus)
#   R       Randomize all critters (new DNA, same positions)
#   E       Run one evolution step
#   SPACE   Spawn a mixed population (clears existing)
#   C       Clear all critters
#   L       Cycle LOD (0-3) and rebuild all
#   +/-     Zoom camera in/out
#   H       Toggle hybrid mode (spawn body_type between kingdoms)

extends Node3D

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────
@export var grid_rows: int = 4          ## Rows per kingdom
@export var grid_cols: int = 4          ## Columns per kingdom
@export var grid_spacing: float = 3.0   ## Distance between critters
@export var initial_lod: int = 1        ## Starting LOD (0=highest, 3=lowest)
@export var auto_populate: bool = true  ## Spawn on ready?
@export var auto_evolve: bool = false   ## Run evolution automatically?
@export var evolve_interval: float = 15.0  ## Seconds between evolution steps

# ─────────────────────────────────────────────────────────────
#  Runtime
# ─────────────────────────────────────────────────────────────
var _spawner: CritterSpawner = null
var _evolution: EvolutionSystem = null
var _transmutation: TransmutationManager = null
var _current_lod: int = 1
var _hybrid_mode: bool = false

# Scene nodes
@onready var _critter_root: Node3D = $CritterRoot
@onready var _camera: Camera3D = $Camera3D
@onready var _label: Label = $UI/InfoLabel


func _ready() -> void:
	_current_lod = initial_lod

	# Create systems
	_spawner = CritterSpawner.new(_critter_root)
	_spawner.max_population = 200
	_spawner.default_lod = _current_lod
	_spawner.debug = true

	_transmutation = TransmutationManager.new()
	_transmutation.debug = true

	_evolution = EvolutionSystem.new()
	_evolution.spawner = _spawner
	_evolution.transmutation_manager = _transmutation
	_evolution.target_population = grid_rows * grid_cols * 4
	_evolution.debug = true

	# Connect signals
	_evolution.generation_complete.connect(_on_generation_complete)
	_evolution.cross_kingdom_breed.connect(_on_cross_kingdom)
	_transmutation.ability_granted.connect(_on_ability_granted)

	if auto_evolve:
		_evolution.start(evolve_interval)

	if auto_populate:
		_spawn_kingdom_grid()

	_update_label()


func _process(delta: float) -> void:
	if auto_evolve:
		_evolution.process(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key: InputEventKey = event as InputEventKey
		match key.keycode:
			KEY_1:
				_spawn_single_kingdom(0)  # Tree
			KEY_2:
				_spawn_single_kingdom(1)  # Creature
			KEY_3:
				_spawn_single_kingdom(2)  # Flower
			KEY_4:
				_spawn_single_kingdom(3)  # Fungus
			KEY_R:
				_randomize_all()
			KEY_E:
				_evolution.evolve_step()
				_update_label()
			KEY_SPACE:
				_spawner.despawn_all()
				_spawn_kingdom_grid()
			KEY_C:
				_spawner.despawn_all()
				_update_label()
			KEY_L:
				_cycle_lod()
			KEY_EQUAL:  # +
				_zoom_camera(-2.0)
			KEY_MINUS:
				_zoom_camera(2.0)
			KEY_H:
				_hybrid_mode = not _hybrid_mode
				_update_label()


# ═══════════════════════════════════════════════════════════════
# SPAWNING
# ═══════════════════════════════════════════════════════════════

## Spawn a grid of critters: 4 kingdoms, each in their own row block.
func _spawn_kingdom_grid() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for kingdom in range(4):
		var kingdom_offset_x: float = 0.0
		var kingdom_offset_z: float = float(kingdom) * float(grid_rows) * grid_spacing + float(kingdom) * 4.0

		for row in grid_rows:
			for col in grid_cols:
				var dna: CritterDNA
				if _hybrid_mode:
					# Create hybrids: body_type between kingdoms
					dna = CritterDNA.random(rng.randi())
					dna.body_type = rng.randf_range(0.0, 4.0)
				else:
					dna = CritterDNA.random_kingdom(kingdom, rng.randi())

				var pos := Vector3(
					kingdom_offset_x + float(col) * grid_spacing,
					0.0,
					kingdom_offset_z + float(row) * grid_spacing
				)

				_spawner.spawn(dna, pos, _current_lod)

	_update_label()


## Spawn one random critter of a specific kingdom at center.
func _spawn_single_kingdom(kingdom: int) -> void:
	var dna: CritterDNA = CritterDNA.random_kingdom(kingdom)
	var pos := Vector3(
		randf_range(-5.0, 5.0),
		0.0,
		randf_range(-5.0, 5.0)
	)
	var entity: CritterEntity = _spawner.spawn(dna, pos, _current_lod)
	if entity:
		print("Spawned %s at %s" % [entity.name, str(pos)])
	_update_label()


## Randomize all existing critters (new DNA, keep positions).
func _randomize_all() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for entity in _spawner.get_active_critters():
		if not is_instance_valid(entity):
			continue
		var kingdom: int = entity.get_kingdom()
		var new_dna: CritterDNA
		if _hybrid_mode:
			new_dna = CritterDNA.random(rng.randi())
			new_dna.body_type = rng.randf_range(0.0, 4.0)
		else:
			new_dna = CritterDNA.random_kingdom(kingdom, rng.randi())

		# Rebuild mesh
		MorphologyRouter.rebuild(entity, new_dna, _spawner.trait_mapper, _current_lod)
		entity.init_from_dna(new_dna)

	_update_label()


## Cycle through LOD levels and rebuild all critters.
func _cycle_lod() -> void:
	_current_lod = (_current_lod + 1) % 4
	_spawner.default_lod = _current_lod

	for entity in _spawner.get_active_critters():
		if not is_instance_valid(entity) or not entity.dna:
			continue
		MorphologyRouter.rebuild(entity, entity.dna, _spawner.trait_mapper, _current_lod)
		entity.set_meta("lod", _current_lod)

	_update_label()


# ═══════════════════════════════════════════════════════════════
# CAMERA
# ═══════════════════════════════════════════════════════════════

func _zoom_camera(amount: float) -> void:
	if _camera:
		_camera.position.y += amount
		_camera.position.z += amount * 0.7
		_camera.position.y = maxf(_camera.position.y, 3.0)


# ═══════════════════════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════════════════════

func _update_label() -> void:
	if not _label:
		return

	var summary: Dictionary = _spawner.get_population_summary()
	var text := "=== Nature System Demo ===\n"
	text += "Population: %d / %d\n" % [summary.get("total", 0), _spawner.max_population]
	text += "  Tree: %d  Creature: %d  Flower: %d  Fungus: %d  Hybrid: %d\n" % [
		summary.get("tree", 0), summary.get("creature", 0),
		summary.get("flower", 0), summary.get("fungus", 0),
		summary.get("hybrid", 0)
	]
	text += "LOD: %d  |  Gen: %d\n" % [_current_lod, _evolution.current_generation]
	text += "Hybrid mode: %s\n" % ("ON" if _hybrid_mode else "OFF")
	text += "\n--- Controls ---\n"
	text += "1-4: Spawn (tree/creature/flower/fungus)\n"
	text += "SPACE: Reset grid  |  R: Randomize DNA\n"
	text += "E: Evolve step  |  L: Cycle LOD\n"
	text += "H: Toggle hybrids  |  C: Clear\n"
	text += "+/-: Zoom"

	_label.text = text


# ═══════════════════════════════════════════════════════════════
# SIGNAL HANDLERS
# ═══════════════════════════════════════════════════════════════

func _on_generation_complete(gen: int, stats: Dictionary) -> void:
	print("[Demo] Generation %d complete — pop: %d, fitness: %.3f" % [
		gen, stats.get("population", 0), stats.get("avg_fitness", 0.0)
	])
	_update_label()


func _on_cross_kingdom(_parent_a: CritterEntity, _parent_b: CritterEntity, child_kingdom: String) -> void:
	print("[Demo] Cross-kingdom breed! Child is: %s" % child_kingdom)


func _on_ability_granted(ability_name: String, _data: Dictionary) -> void:
	print("[Demo] Ability granted: %s" % ability_name)

func apply_grid_config(config: Dictionary) -> void:
	pass
