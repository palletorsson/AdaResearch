# GridSystem.gd (Component-Based Version)
# Orchestrates grid components for modular map generation
# Replaces the monolithic 776-line version with clean component architecture

extends Node3D
class_name GridSystem

# Preload component scripts
const DataComponentScript = preload("res://commons/grid/GridDataComponent.gd")
const StructureComponentScript = preload("res://commons/grid/GridStructureComponent.gd")
const UtilitiesComponentScript = preload("res://commons/grid/GridUtilitiesComponent.gd")
const InteractablesComponentScript = preload("res://commons/grid/GridInteractablesComponent.gd")
const SpawnComponentScript = preload("res://commons/grid/GridSpawnComponent.gd")
const CeilingComponentScript = preload("res://commons/grid/GridCeilingComponent.gd")
const WallComponentScript = preload("res://commons/grid/GridWallComponent.gd")
const AudioComponentScript = preload("res://commons/grid/GridAudioComponent.gd")
const TimelineComponentScript = preload("res://commons/grid/GridTimelineComponent.gd")
const FloorPlanLoader = preload("res://commons/grid/FloorPlanLoader.gd")
# Biome paint layers build on the earlier maps in a sequence (render-time accrual).
# Preloaded by path (not the SequenceAccrual global) to dodge class-cache ordering.
const SequenceAccrualLib = preload("res://commons/biome_layers/sequence_accrual.gd")
# Modifier op-stack — non-destructive grid colorize/normalize pass applied at
# load (additive; see doc/BRACELET_GARDEN_MODIFIERS.md). Preloaded by path.
const ModifierStackLib = preload("res://commons/modifiers/modifier_stack.gd")

# Configuration
@export var cube_size: float = 1.0
## Runtime paint-layer override (set by a live brush via repaint_biome()).
## Empty → the map's own paint_layers / default behaviour. See doc/PAINT_LAYERS.md.
var _runtime_paint_layers: Array = []
@export var gutter: float = 0.0
@export var map_name: String = "Tutorial_Start"
# Spine-corridor mode: when set, prefer map_data.corridor.json over map_data.json
@export var prefer_corridor_variant: bool = false
@export var reload_map: bool = false : set = reload_map_setter
@export var auto_load_map_on_ready: bool = true
@export var cache_artifact_registry_between_maps: bool = true
@export var flatten_post_lab_structure_walls: bool = false
@export var post_lab_wall_height_threshold: int = 6

# Components
var data_component
var structure_component
var utilities_component
var interactables_component
var spawn_component
var ceiling_component
var wall_component
var audio_component
var timeline_component

# Scene references
@onready var base_cube = $CubeScene

# State
var is_initialized: bool = false
var generation_in_progress: bool = false
var _ecosystem_spawner: Node3D = null

# Signals
signal map_loaded(map_name: String, format: String)
signal map_generation_complete()
signal interactable_activated(object_id, position, data)
signal grid_animation_started()
signal grid_animation_complete()

func _ready():
	print("GridSystem: Initializing component-based grid system...")

	# Add to group so other systems can find us
	add_to_group("grid_system")

	if not base_cube:
		push_error("GridSystem: Base cube reference not found!")
		return

	# Initialize components first
	_initialize_components()

	# CRITICAL: Defer scene data check and map loading to next frame
	# This allows staging to set scene_user_data BEFORE we try to read it
	call_deferred("_deferred_initialization")

func _deferred_initialization():
	"""Deferred init to allow staging to set scene_user_data first"""
	print("GridSystem: Deferred initialization starting...")

	# Now check for scene data (metadata should be set by now)
	_check_for_scene_data()

	# Load map data
	if auto_load_map_on_ready:
		_load_map_data()
	else:
		print("GridSystem: auto_load_map_on_ready=false (awaiting explicit reload_map trigger)")

# Check for scene data and update map_name
func _check_for_scene_data():
	var scene_data = {}

	# Try multiple locations for scene data
	# 1. Check current scene's metadata
	if not is_inside_tree():
		return
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_data = scene_root.get_meta("scene_user_data", {})
		if scene_data.is_empty():
			scene_data = scene_root.get_meta("scene_data", {})

	# 2. Check staging node (AdaVRStaging) metadata
	if scene_data.is_empty():
		var staging = get_node_or_null("/root/AdaVRStaging")
		if staging:
			scene_data = staging.get_meta("scene_user_data", {})
			if scene_data.is_empty():
				scene_data = staging.get_meta("scene_data", {})

	# 3. Check parent scene's metadata (if GridSystem is child of loaded scene)
	if scene_data.is_empty():
		var parent = get_parent()
		while parent and scene_data.is_empty():
			scene_data = parent.get_meta("scene_user_data", {})
			if scene_data.is_empty():
				scene_data = parent.get_meta("scene_data", {})
			parent = parent.get_parent()

	if not scene_data.is_empty():
		print("GridSystem: Found scene data: %s" % scene_data)

		# Update map name from scene data
		if scene_data.has("map_name"):
			var new_map_name = scene_data["map_name"]
			print("GridSystem: Updating map_name from '%s' to '%s'" % [map_name, new_map_name])
			map_name = new_map_name

		if scene_data.has("initial_map"):
			var new_map_name = scene_data["initial_map"]
			print("GridSystem: Updating map_name from '%s' to '%s' (initial_map)" % [map_name, new_map_name])
			map_name = new_map_name

		# Store sequence data for reference
		if scene_data.has("sequence_data"):
			set_meta("current_sequence", scene_data["sequence_data"])
	else:
		print("GridSystem: No scene data found, using default map_name: %s" % map_name)

# Initialize all components
func _initialize_components():
	print("GridSystem: Initializing components...")
	
	# Create and add components as children
	data_component = DataComponentScript.new()
	data_component.name = "GridDataComponent"
	data_component.prefer_corridor_variant = prefer_corridor_variant
	add_child(data_component)

	structure_component = StructureComponentScript.new()
	structure_component.name = "GridStructureComponent"
	add_child(structure_component)

	utilities_component = UtilitiesComponentScript.new()
	utilities_component.name = "GridUtilitiesComponent"
	add_child(utilities_component)

	interactables_component = InteractablesComponentScript.new()
	interactables_component.name = "GridInteractablesComponent"
	add_child(interactables_component)

	spawn_component = SpawnComponentScript.new()
	spawn_component.name = "GridSpawnComponent"
	add_child(spawn_component)

	ceiling_component = CeilingComponentScript.new()
	ceiling_component.name = "GridCeilingComponent"
	add_child(ceiling_component)

	wall_component = WallComponentScript.new()
	wall_component.name = "GridWallComponent"
	add_child(wall_component)

	audio_component = AudioComponentScript.new()
	audio_component.name = "GridAudioComponent"
	add_child(audio_component)

	timeline_component = TimelineComponentScript.new()
	timeline_component.name = "GridTimelineComponent"
	add_child(timeline_component)

	# Connect component signals
	_connect_component_signals()

	print("GridSystem: ✅ All components initialized")

# Connect signals from components
func _connect_component_signals():
	# Data component signals
	data_component.data_loaded.connect(_on_data_loaded)
	data_component.data_load_failed.connect(_on_data_load_failed)
	
	# Structure component signals
	structure_component.structure_generation_complete.connect(_on_structure_complete)
	structure_component.animation_started.connect(_on_grid_animation_started)
	structure_component.animation_complete.connect(_on_grid_animation_complete)
	
	# Utilities component signals
	utilities_component.utility_generation_complete.connect(_on_utilities_complete)
	utilities_component.utility_activated.connect(_on_utility_activated)
	
	# Interactables component signals
	interactables_component.interactables_generation_complete.connect(_on_interactables_complete)
	interactables_component.interactable_activated.connect(_on_interactable_activated)
	
	# Spawn component signals
	spawn_component.spawn_positioning_complete.connect(_on_spawn_complete)

	# Ceiling component signals
	ceiling_component.ceiling_generation_complete.connect(_on_ceiling_complete)

	# Wall component signals
	wall_component.wall_generation_complete.connect(_on_wall_complete)

	# Audio component signals
	audio_component.audio_initialized.connect(_on_audio_initialized)
	audio_component.ambient_started.connect(_on_ambient_started)
	audio_component.ambient_stopped.connect(_on_ambient_stopped)
	audio_component.audio_error.connect(_on_audio_error)

# Load map data using data component
func _load_map_data():
	print("GridSystem: Loading map data for '%s'" % map_name)
	
	# Check if map_name is actually a sequence name (should be handled by AdaSceneManager)
	if _is_sequence_name(map_name):
		push_warning("GridSystem: '%s' is a sequence name, not a map. Redirecting to AdaSceneManager..." % map_name)
		var scene_manager = _find_ada_scene_manager()
		if scene_manager:
			scene_manager.start_sequence(map_name)
			return
		else:
			push_error("GridSystem: Cannot redirect sequence '%s' - AdaSceneManager not found" % map_name)
			return
	
	if not data_component.load_map_data(map_name):
		push_error("GridSystem: Failed to load map data for '%s'" % map_name)

# Check if a name is a sequence name
## Cached sequence names — auto-discovered from res://commons/maps/sequences/*.json
var _known_sequences_cache: Array = []

func _is_sequence_name(name: String) -> bool:
	if _known_sequences_cache.is_empty():
		_known_sequences_cache = _discover_sequence_names()
	return name in _known_sequences_cache

## Scan the sequences directory for all .json files and extract their names.
## Runs once, cached for the session.
static func _discover_sequence_names() -> Array:
	var names: Array = []
	var dir := DirAccess.open("res://commons/maps/sequences")
	if not dir:
		push_warning("GridSystem: Could not open sequences directory for autodiscovery")
		return names
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and file_name != "sequence_index.json" and file_name != "templates.json":
			names.append(file_name.get_basename())
		file_name = dir.get_next()
	return names

# Find AdaSceneManager in the scene tree
func _find_ada_scene_manager():
	var potential_paths = [
		"/root/AdaSceneManager",
		"/root/SceneManager"
	]
	
	for path in potential_paths:
		var manager = get_node_or_null(path)
		if manager:
			return manager
	
	# Try to find by class name
	var tree = get_tree()
	if tree:
		var root = tree.current_scene
		if root:
			var manager = root.find_child("AdaSceneManager", true, false)
			if manager:
				return manager
	
	return null

# Handle successful data loading
func _on_data_loaded(loaded_map_name: String, format: String):
	print("GridSystem: Data loaded successfully - %s (%s)" % [loaded_map_name, format])

	_apply_post_lab_structure_override_if_needed()
	
	# Try to get base_cube if invalid (structure_component can use cached data if unavailable)
	if not is_instance_valid(base_cube):
		base_cube = get_node_or_null("CubeScene")
		if base_cube:
			print("GridSystem: Re-acquired base_cube reference in _on_data_loaded")
		else:
			print("GridSystem: base_cube unavailable, structure_component will use cached data")
	
	# Get settings from data and apply them
	var settings = data_component.get_settings()
	cube_size = settings.get("cube_size", cube_size)
	gutter = settings.get("gutter", gutter)
	
	# Initialize components with settings and references
	var component_settings = {
		"cube_size": cube_size,
		"gutter": gutter,
		"cache_artifact_registry": cache_artifact_registry_between_maps
	}
	
	# Pass animation settings if present
	if settings.has("grid_animation"):
		component_settings["grid_animation"] = settings["grid_animation"]
	
	structure_component.initialize(self, base_cube, component_settings)
	utilities_component.initialize(self, structure_component, component_settings)
	interactables_component.initialize(self, structure_component, utilities_component, data_component, component_settings)
	spawn_component.initialize(data_component, component_settings)
	ceiling_component.initialize(self, data_component, component_settings)
	wall_component.initialize(self, data_component, component_settings)
	audio_component.initialize(self, data_component)
	timeline_component.initialize(self, data_component, structure_component, component_settings)

	# Set sequence ID if available from scene data
	var current_sequence = get_meta("current_sequence", {})
	if not current_sequence.is_empty():
		var sequence_name = current_sequence.get("sequence_name", "")
		if not sequence_name.is_empty():
			audio_component.set_sequence_id(sequence_name)
	
	# Start grid generation
	_generate_grid()
	
	if typeof(GameManager) != TYPE_NIL and GameManager.has_method("set_current_map"):
		GameManager.set_current_map(loaded_map_name)
	
	emit_signal("map_loaded", loaded_map_name, format)

func _apply_post_lab_structure_override_if_needed() -> void:
	if not flatten_post_lab_structure_walls:
		return
	if not _is_post_lab_map_name(map_name):
		return
	if data_component == null:
		return

	var structure_data = data_component.get_structure_data()
	if structure_data == null:
		return
	if not ("layout_data" in structure_data):
		return

	var layout_data_variant: Variant = structure_data.layout_data
	if not (layout_data_variant is Array):
		return

	var layout_data: Array = layout_data_variant
	var changed_cells: int = 0

	for z in range(layout_data.size()):
		var row_variant: Variant = layout_data[z]
		if not (row_variant is Array):
			continue
		var row: Array = row_variant
		for x in range(row.size()):
			var cell_height: int = _parse_structure_height(row[x])
			if cell_height >= post_lab_wall_height_threshold:
				row[x] = "1"
				changed_cells += 1
		layout_data[z] = row

	structure_data.layout_data = layout_data

	if changed_cells > 0:
		print("GridSystem: Flattened %d tall post-lab wall cells (threshold=%d)" % [changed_cells, post_lab_wall_height_threshold])

func _is_post_lab_map_name(target_map_name: String) -> bool:
	return target_map_name.begins_with("Lab/map_data_post_")

func _parse_structure_height(cell_value: Variant) -> int:
	match typeof(cell_value):
		TYPE_INT:
			return int(cell_value)
		TYPE_FLOAT:
			return int(round(float(cell_value)))
		TYPE_STRING:
			var raw_text: String = str(cell_value).strip_edges()
			if raw_text.is_empty():
				return 0
			if raw_text == " " or raw_text == "." or raw_text == "-" or raw_text == "_":
				return 0
			var value_text: String = raw_text.get_slice(":", 0).strip_edges()
			if value_text.is_valid_int():
				return value_text.to_int()
	return 0

# Handle data loading failure
func _on_data_load_failed(failed_map_name: String, error: String):
	push_error("GridSystem: CRITICAL FAILURE - Failed to load map '%s': %s" % [failed_map_name, error])
	
	# Stop here - no fallbacks, let it fail clearly
	generation_in_progress = false
	
	# Show error state for debugging
	_show_error_state(failed_map_name, error)
	
	# Emit failure signal for external systems to handle
	emit_signal("map_generation_complete")  # With error state

# Generate the complete grid using components
func _generate_grid():
	if generation_in_progress:
		print("GridSystem: Generation already in progress, skipping")
		return
	
	generation_in_progress = true
	print("GridSystem: Starting component-based grid generation...")
	
	# Hide base_cube if it exists (it's just a template, not needed visually)
	if is_instance_valid(base_cube):
		base_cube.visible = false
	
	# Get grid dimensions from data
	var dimensions = data_component.get_grid_dimensions()
	print("GridSystem: Grid dimensions: %dx%dx%d" % [dimensions.x, dimensions.y, dimensions.z])
	
	# Generate structure first
	var structure_data = data_component.get_structure_data()
	structure_component.generate_structure(structure_data, dimensions)

	# Update PlayerBoundsCheck if found
	_update_player_bounds(dimensions)

func _update_player_bounds(dimensions: Vector3i):
	var bounds_check = get_tree().current_scene.find_child("PlayerBoundsCheck", true, false)
	if bounds_check:
		# Calculate bounds based on grid size
		# Assuming grid is roughly centered or we want to allow movement within the grid area
		# Adding a generous buffer (e.g., 20 units + grid size)
		
		var bounds_x = (dimensions.x * cube_size) + 2.0
		var bounds_y = (dimensions.y * cube_size) + 2.0 
		var bounds_z = (dimensions.z * cube_size) + 2.0
		
		# If height is small (flat map), give minimum vertical headroom
		if bounds_y < 5.0: bounds_y = 5.0
		
		bounds_check.box_bounds = Vector3(bounds_x, bounds_y, bounds_z)
		print("GridSystem: Updated PlayerBoundsCheck limits to %s" % bounds_check.box_bounds)
	else:
		print("GridSystem: PlayerBoundsCheck node not found")

# Handle structure generation completion
func _on_structure_complete(cube_count: int):
	print("GridSystem: Structure generation complete (%d cubes)" % cube_count)

	# Apply the (optional) modifier op-stack on top of the freshly-built grid.
	# Additive + non-destructive: no map without a `modifiers` key is affected.
	_apply_modifier_stack()

	# Generate utilities
	var utility_data = data_component.get_utility_data()
	var utility_definitions = data_component.get_utility_definitions()
	utilities_component.generate_utilities(utility_data, utility_definitions)

# Apply the map's modifier op-stack to the generated structure (additive).
# Reads map_data.json's top-level `modifiers` array, builds a base cell model
# from the structure heights, runs ModifierStack.apply non-destructively, then
# tints each cell whose resulting colour differs from the default. Guards on an
# absent/empty stack so existing maps see no behaviour change.
func _apply_modifier_stack() -> void:
	if not data_component or not data_component.has_method("get_modifiers"):
		return
	var mods: Array = data_component.get_modifiers()
	if mods.is_empty():
		return
	if not structure_component:
		return
	# Build the base cell model: Vector2i(row, col) = (z, x) -> {height, color}.
	var base: Dictionary = {}
	var dims: Vector3i = structure_component.get_grid_dimensions()
	for z in range(dims.z):
		for x in range(dims.x):
			var h: int = structure_component.find_highest_y_at(x, z)
			if h <= 0:
				continue  # empty column — nothing visible to tint
			base[Vector2i(z, x)] = {"height": h, "color": ModifierStackLib.DEFAULT_COLOR}
	if base.is_empty():
		return
	var result: Dictionary = ModifierStackLib.apply(base, mods)
	var tinted: int = 0
	for k in result.keys():
		var cell: Dictionary = result[k]
		var col: Color = cell.get("color", ModifierStackLib.DEFAULT_COLOR)
		if col == ModifierStackLib.DEFAULT_COLOR:
			continue  # unchanged — leave the cube on its native material colour
		structure_component.set_cell_color(k, col)
		tinted += 1
	print("GridSystem: Modifier stack applied (%d ops, %d cells tinted)" % [mods.size(), tinted])

# Handle grid animation started
func _on_grid_animation_started():
	print("GridSystem: 🎬 Grid animation started")
	grid_animation_started.emit()

# Handle grid animation complete
func _on_grid_animation_complete():
	print("GridSystem: 🎬 Grid animation complete")
	grid_animation_complete.emit()

# Handle utilities generation completion
func _on_utilities_complete(utility_count: int):
	print("GridSystem: Utilities generation complete (%d utilities)" % utility_count)
	
	# Generate interactables
	var interactable_data = data_component.get_interactable_data()
	interactables_component.generate_interactables(interactable_data)

# Handle interactables generation completion
func _on_interactables_complete(interactable_count: int):
	print("GridSystem: Interactables generation complete (%d interactables)" % interactable_count)

	# Generate ceiling if configured
	_handle_ceiling_generation()

# Handle ceiling generation
func _handle_ceiling_generation():
	var settings = data_component.get_settings()
	var ceiling_config = settings.get("ceiling", {})

	if not ceiling_config.is_empty() or settings.has("enable_ceiling"):
		print("GridSystem: Generating ceiling...")
		ceiling_component.generate_ceiling(ceiling_config)
	else:
		# Skip ceiling, try walls
		_handle_wall_generation()

# Handle ceiling generation completion
func _on_ceiling_complete(tile_count: int, light_count: int):
	print("GridSystem: Ceiling generation complete (%d tiles, %d lights)" % [tile_count, light_count])

	# Generate walls after ceiling
	_handle_wall_generation()

# Handle wall generation
func _handle_wall_generation():
	if flatten_post_lab_structure_walls and _is_post_lab_map_name(map_name):
		print("GridSystem: Skipping explicit wall generation for post-lab desktop preview")
		call_deferred("_handle_player_spawn")
		return

	var settings = data_component.get_settings()
	var wall_config = settings.get("walls", {})

	if not wall_config.is_empty():
		print("GridSystem: Generating walls...")
		wall_component.generate_walls(wall_config)
	else:
		# No walls config — still try floor plan overlay
		_try_load_floor_plan()
		# Go directly to spawn
		call_deferred("_handle_player_spawn")

# Handle wall generation completion
func _on_wall_complete(wall_count: int):
	print("GridSystem: Wall generation complete (%d walls)" % wall_count)
	_try_load_floor_plan()
	call_deferred("_handle_player_spawn")

## Try to load and apply a floor_plan.json from the current map directory.
## DISABLED: use floor_plan_space artifact in interactables instead.
var _floor_plan_loaded: bool = false
func _try_load_floor_plan() -> void:
	return  # Disabled — floor_plan_space artifact handles this
	if _floor_plan_loaded:
		return
	if not data_component:
		return
	var current_map: String = data_component.get_current_map_name()
	if current_map == "":
		return
	var map_dir: String = "res://commons/maps/" + current_map
	print("GridSystem: Checking for floor plan at %s" % map_dir)
	var loader := FloorPlanLoader.new()
	loader.name = "FloorPlanLoader"
	add_child(loader)
	if loader.load_floor_plan(map_dir):
		loader.apply_floor_plan(self, cube_size)
		_floor_plan_loaded = true
		print("GridSystem: Floor plan applied")
	else:
		print("GridSystem: No floor plan found")

# Handle player spawn positioning
func _handle_player_spawn():
	print("GridSystem: Handling player spawn positioning...")
	spawn_component.handle_player_spawn()

# Handle spawn positioning completion
func _on_spawn_complete(spawn_position: Vector3):
	print("GridSystem: Spawn positioning complete at %s" % spawn_position)

	# Spawn ecosystem organisms if configured (after terrain is built)
	call_deferred("_handle_ecosystem_spawn")

	# Start ambient audio after everything is set up
	call_deferred("_handle_audio_start")

	# Generate biome ring around grid (natural landscape surrounding the map)
	call_deferred("_handle_biome_ring")

	# Notify NatureRenderer of per-map environment overrides
	call_deferred("_notify_nature_renderer")

	generation_in_progress = false
	print("GridSystem: ✅ Grid generation completed successfully")
	emit_signal("map_generation_complete")

# Handle ecosystem spawner creation from map settings
func _handle_ecosystem_spawn():
	var settings = data_component.get_settings()
	var eco_config = settings.get("ecosystem", {})

	if not eco_config.get("enabled", false):
		return

	# Clean up previous spawner if reloading
	if _ecosystem_spawner and is_instance_valid(_ecosystem_spawner):
		_ecosystem_spawner.queue_free()
		_ecosystem_spawner = null

	var spawner = EcosystemNatureSpawner.new()
	spawner.name = "EcosystemNatureSpawner"

	# Forward config from map_data.json → spawner exports
	spawner.spawn_radius = eco_config.get("spawn_radius", 9.0)
	spawner.max_population = eco_config.get("max_population", 50)
	spawner.rng_seed = eco_config.get("rng_seed", -1)

	# Center offset from config (array [x, y, z] → Vector3)
	var offset = eco_config.get("center_offset", [0.0, 0.0, 0.0])
	if offset is Array and offset.size() >= 3:
		spawner.center_offset = Vector3(offset[0], offset[1], offset[2])

	# Always use the chunk-based LOD system
	spawner.use_chunk_system = eco_config.get("use_chunk_system", true)

	# Test overrides — bypass progression-gated EcosystemManager values
	spawner.override_density = eco_config.get("override_density", -1.0)
	var kingdoms_override = eco_config.get("override_kingdoms", [])
	if kingdoms_override is Array:
		var typed_kingdoms: Array[String] = []
		for k in kingdoms_override:
			typed_kingdoms.append(str(k))
		spawner.override_kingdoms = typed_kingdoms

	add_child(spawner)
	_ecosystem_spawner = spawner
	print("GridSystem: Ecosystem spawner created (radius=%.1f, pop=%d, chunks=%s)" % [
		spawner.spawn_radius, spawner.max_population, spawner.use_chunk_system
	])

# Handle audio start
func _handle_audio_start():
	print("GridSystem: Starting ambient audio...")
	audio_component.start_ambient()


# ═══════════════════════════════════════════════════════════════
# BIO SYSTEMS — Biome ring + NatureRenderer wiring
# ═══════════════════════════════════════════════════════════════

## Generate a biome ring around the grid if vegetation density > 0.
## Live-repaint hook for the VR/desktop biome brush. Sets a runtime paint-layer
## override and rebuilds the biome with it. Pass [] to clear (revert to the
## map's own paint_layers). Additive — does not change default map loading.
func repaint_biome(layers: Array) -> void:
	_runtime_paint_layers = layers if layers is Array else []
	_handle_biome_ring(true)   # live brush: skip the ecosystem re-sync (same map)


## Live mesh-only preview of the ground while the biome brush paints "ground".
## Far cheaper than repaint_biome — rebuilds just the ground mesh (no collider,
## no other layers), so the terrain rises under the brush in real time. The full
## rebuild (collider included) lands on stroke-release via repaint_biome.
func preview_ground(field: PackedFloat32Array, fw: int, fd: int, max_h: float) -> void:
	var sub := _find_descendant_named(self, "BiomeGroundSubstrate")
	if sub and sub.has_method("apply_height_preview"):
		# Lift the (backdrop-positioned) substrate to the grid floor surface so the live
		# preview hills rise VISIBLY above the floor — matching the committed terrain the
		# accrual rebuilds on stroke-release. Without this the live preview stays buried a
		# metre under the opaque floor cubes (the historic backdrop base).
		if max_h > 0.0 and sub.has_method("set_base_offset"):
			sub.set_base_offset(cube_size * 0.5 + 0.02)
		sub.apply_height_preview(field, fw, fd, max_h)


func _find_descendant_named(root: Node, nm: String) -> Node:
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			if c.name == nm:
				return c
			stack.append(c)
	return null


## `live_repaint` = called by the biome brush on a stroke (repaint_biome), where
## the map hasn't changed — so skip the ecosystem re-sync, which otherwise advances
## the monotonic progression AND writes the ecosystem save to disk on EVERY stroke.
func _handle_biome_ring(live_repaint: bool = false):
	# Runtime flag — let the encyclopedia /shortcuts surface flip this
	# off for clean map captures and architecture debugging.
	if not _runtime_flag_enabled("biome_enabled", true):
		print("GridSystem: biome_enabled=false in ada_run/runtime_flags.json — skipping biome")
		return
	# Per-map opt-out — set `"disable_biome": true` in the map's
	# settings block to keep abstract biome layers (floating_primitives
	# etc.) from spawning. Used for maps that ARE the lab (no need for
	# decorative spheres around it).
	if data_component:
		var map_settings: Dictionary = data_component.get_settings()
		if bool(map_settings.get("disable_biome", false)):
			print("GridSystem: map %s has disable_biome=true in settings — skipping biome" % map_name)
			return

	var eco = get_node_or_null("/root/EcosystemManager")
	if not eco:
		print("GridSystem: No EcosystemManager — no biome ring")
		return
	if not eco.has_method("get_vegetation_density"):
		print("GridSystem: EcosystemManager missing get_vegetation_density")
		return

	# Auto-advance ecosystem to the current map's sequence so biome matches context.
	# Skipped on a live brush repaint — the map (hence its sequence/stage) is
	# unchanged, and the sync writes the ecosystem save to disk each call.
	var density_before: float = eco.get_vegetation_density()
	if not live_repaint:
		_sync_ecosystem_to_current_map(eco)
	var density: float = eco.get_vegetation_density()
	var kingdoms = eco.get_allowed_kingdoms() if eco.has_method("get_allowed_kingdoms") else []
	print("GridSystem: Biome check — map='%s' density_before=%.2f density_after=%.2f kingdoms=%s" % [map_name, density_before, density, str(kingdoms)])
	# Accrual stack runs regardless of density — the old density gate is
	# a property of BiomeRingComponent, not the curriculum. Abstract layers
	# (floating_primitives) must render even at density 0.
	# Read biome paint once at function scope so the ground-paint
	# block below can use it as a fallback signal even when the
	# accrual-early branch didn't fire.
	var painted_layer: Array = []
	if data_component.has_method("get_biome_paint_layer"):
		painted_layer = data_component.get_biome_paint_layer()

	# (Gated by the runtime flag above — early return already handled.)
	var accrual_early = get_node_or_null("/root/BiomeAccrualManager")
	if accrual_early and accrual_early.has_method("apply"):
		var dims_early: Vector3i = data_component.get_grid_dimensions()
		# Thread biome_paint + stage_order into the layer context. The
		# biome_paint_dispatcher layer reads both: the painted layer for
		# the deposit list, the stage_order for kingdom-unlock guard.
		# Other layers (floating_primitives, lsystem_trees, …) ignore
		# them — they only consume their own params.
		var stage_order: int = 0
		if eco and eco.has_method("get_current_stage_order"):
			stage_order = int(eco.get_current_stage_order())
		# Per-map biome overrides (settings.biome_overrides): lets a map
		# add / remove / change biome layers on top of its sequence default.
		var biome_overrides: Dictionary = {}
		if data_component:
			biome_overrides = data_component.get_settings().get("biome_overrides", {})
		# Paint layers (top-level paint_layers[]): per-map authored distribution
		# for the population layers (tree/critter/flower/…). Opt-in — absent =
		# the spawn layers keep their default ring. See doc/PAINT_LAYERS.md.
		# A live VR/desktop brush can override via repaint_biome() (runtime wins).
		var paint_layers: Array = _runtime_paint_layers if not _runtime_paint_layers.is_empty() \
			else (data_component.get_paint_layers() if data_component else [])
		paint_layers = SequenceAccrualLib.accrued_layers(eco, map_name, paint_layers)
		accrual_early.apply(self, {
			"grid_dims": dims_early,
			"grid_center": Vector3(float(dims_early.x) * cube_size * 0.5, 0.0, float(dims_early.z) * cube_size * 0.5),
			"cube_size": cube_size,
			"rng_seed": hash(map_name),
			"map_name": map_name,
			"biome_paint": painted_layer,
			"stage_order": stage_order,
			"biome_overrides": biome_overrides,
			"paint_layers": paint_layers,
			# Phase 4b: the ground_ring accrual layer (wraps BiomeRingComponent)
			# needs density / terrain_mode / kingdoms. GridSystem no longer
			# special-cases the ring — it is just another accrual layer now.
			"density": density,
			"terrain_mode": eco.get_terrain_mode() if eco.has_method("get_terrain_mode") else "flat",
			"kingdoms": kingdoms,
			# ground_only (settings.ground_only): keep just the walkable ground —
			# for clean maps (e.g. primitives) that want terrain, not the abstract biome.
			"only_ground": bool(data_component.get_settings().get("ground_only", false)) if data_component else false,
		})

	# ── Ground paint layer (G3.7 + smart fallback) ────────────────────
	# Reads commons/maps/<map>/map_data.json's optional `ground_paint`
	# layer and renders one MultiMeshInstance3D per used type via
	# GroundLayerComponent. Smart fallback chain:
	#   explicit ground_paint  →  kingdom-inferred from biome_paint
	#                          →  stage's terrain_mode default
	# So authors usually paint only biome_paint and the ground
	# "just works"; ground_paint is the override for orthogonal cases
	# (stone path through grass, fungus on a fallen log, etc.).
	# Runs BEFORE the density gate so ground tiles even on barren maps.
	var ground_paint: Array = []
	if data_component.has_method("get_ground_paint_layer"):
		ground_paint = data_component.get_ground_paint_layer()
	# Determine if there's anything to render — explicit ground_paint
	# OR a non-empty biome_paint OR a non-default terrain_mode.
	var terrain_mode_str: String = ""
	if eco and eco.has_method("get_terrain_mode"):
		terrain_mode_str = String(eco.get_terrain_mode())
	if not ground_paint.is_empty() or not painted_layer.is_empty() or not terrain_mode_str.is_empty():
		var dims_ground: Vector3i = data_component.get_grid_dimensions()
		var GroundLayerScript = preload("res://commons/biome_layers/ground_layer_component.gd")
		# Drop any prior ground layer (idempotent reload).
		var old_ground = get_node_or_null("GroundLayer")
		if old_ground:
			old_ground.queue_free()
		var ground_layer = GroundLayerScript.new()
		ground_layer.name = "GroundLayer"
		add_child(ground_layer)
		var ground_stats: Dictionary = ground_layer.apply(ground_paint, {
			"grid_center": Vector3(
				float(dims_ground.x) * cube_size * 0.5,
				0.0,
				float(dims_ground.z) * cube_size * 0.5
			),
			"grid_dims": dims_ground,
			"cube_size": cube_size,
			"biome_paint": painted_layer,
			"terrain_mode": terrain_mode_str,
		})
		# If no tiles ended up rendered (all sources empty), drop the node.
		if int(ground_stats.get("tiles", 0)) == 0:
			ground_layer.queue_free()
		else:
			var src: Dictionary = ground_stats.get("by_source", {})
			print("GridSystem: 🟫 Ground paint applied — %d tiles in %d draw calls (explicit=%d, kingdom=%d, terrain=%d)"
				% [ground_stats.get("tiles", 0),
				   ground_stats.get("draw_calls", 0),
				   src.get("explicit", 0), src.get("kingdom", 0), src.get("terrain", 0)])

	# CONSOLIDATION Phase 4b (2026-06-04): the biome ring is no longer a
	# GridSystem special-case. It is now the `ground_ring` accrual layer
	# (order 1, always) — wrapping BiomeRingComponent — applied by
	# BiomeAccrualManager above, along with every other biome layer. The
	# density gate + barren-map skip now live inside the layer. This makes
	# the accrual stack the single biome populator and gives the ring per-map
	# biome_overrides support for free. See commons/biome_layers/ground_ring.gd.


## Advance EcosystemManager to the sequence that owns the current map.
## Uses EcosystemManager's cached map→sequence index (built once at boot).
func _sync_ecosystem_to_current_map(eco) -> void:
	if eco.has_method("sync_to_map"):
		if eco.sync_to_map(map_name):
			print("GridSystem: Ecosystem synced to '%s' for map '%s'" % [eco.get_sequence_for_map(map_name), map_name])
		return
	# Fallback for older EcosystemManager without cached index
	if not eco.has_method("force_advance_to"):
		return


## Notify NatureRenderer of per-map environment overrides + trigger living ground.
func _notify_nature_renderer():
	var nr = get_node_or_null("/root/NatureRenderer")
	if not nr:
		return

	# Load per-map overrides from map_data.json "environment" block
	if nr.has_method("load_map_overrides"):
		var overrides: Dictionary = data_component.get_environment_overrides()
		nr.load_map_overrides(overrides)
		if not overrides.is_empty():
			print("GridSystem: 🌍 Loaded %d environment overrides" % overrides.size())

	# Trigger living ground activation check
	if nr.has_method("apply_grid_config"):
		nr.apply_grid_config({})


# Audio component signal handlers
func _on_audio_initialized():
	print("GridSystem: Audio component initialized")

func _on_ambient_started(preset_name: String):
	print("GridSystem: 🎵 Ambient audio started - %s" % preset_name)

func _on_ambient_stopped():
	print("GridSystem: 🎵 Ambient audio stopped")

func _on_audio_error(error_message: String):
	print("GridSystem: ⚠️ Audio error: %s" % error_message)

# Handle utility activation
func _on_utility_activated(utility_type: String, position: Vector3, data: Dictionary):
	print("GridSystem: 🎯 Utility activated - %s at %s" % [utility_type, position])
	
	# For teleporters, also try to find and notify SceneManager directly
	if utility_type == "t":
		print("GridSystem: 🚀 Teleporter activation detected - notifying SceneManager")
		_handle_teleporter_activation(position, data)
	
	# Forward to external systems if needed (for other integrations)
	# This maintains the existing signal for anything else that might be listening

# Handle teleporter activation by finding and notifying SceneManager
func _handle_teleporter_activation(position: Vector3, data: Dictionary):
	# Find SceneManager in the tree
	var scene_manager = _find_scene_manager()
	if scene_manager:
		print("GridSystem: ✅ Found SceneManager - requesting transition")
		
		# Check if we're in a sequence context
		var current_sequence = get_meta("current_sequence", {})
		var action = data.get("action", "load_map")  # Use teleporter's action property
		var destination = data.get("destination", "")
		var sequence = ""
		
		print("GridSystem: 🔍 DEBUG - Current sequence metadata: %s" % current_sequence)
		print("GridSystem: 🔍 DEBUG - Teleporter action: '%s'" % action)
		print("GridSystem: 🔍 DEBUG - Destination from teleporter: '%s'" % destination)
		print("GridSystem: 🔍 DEBUG - All metadata: %s" % get_meta_list())
		
		# RESPECT the teleporter's action property instead of overriding it
		if action == "next_in_sequence":
			print("GridSystem: ✅ Using teleporter's 'next_in_sequence' action")
			# If no active sequence and destination is a sequence name, convert to start_sequence
			if current_sequence.is_empty() and destination in ["primitives", "array_tutorial", "randomness", "noise", "wavefunctions", "qfeplaboratory"]:
				print("GridSystem: 🔄 No active sequence, converting next_in_sequence to start_sequence for: %s" % destination)
				action = "start_sequence"
				sequence = destination
				destination = ""
		elif action == "next":
			print("GridSystem: ✅ Using teleporter's 'next' action")
		elif destination.is_empty():
			action = "next"
			print("GridSystem: ⚠️ No action specified, using 'next' action as fallback")
		# Check if destination is a sequence name — dynamically via
		# MapProgressionManager so new sequences (atlas, etc.) work without
		# editing this list. Falls back to hardcoded list if MPM unavailable.
		elif _is_known_sequence(destination):
			action = "start_sequence"
			sequence = destination
			destination = ""
		# Otherwise it's a direct map load
		else:
			action = "load_map"
		
		print("GridSystem: Action: %s, Destination: %s, Sequence: %s" % [action, destination, sequence])
		print("GridSystem: Current sequence context: %s" % current_sequence.get("sequence_name", "none"))
		
		# Request transition with appropriate action
		var transition_request = {
			"type": 1, # TransitionType.TELEPORTER
			"action": action,
			"sequence": sequence,
			"destination": destination,
			"current_map_name": map_name,  # Pass current map name
			"source": "grid_teleporter",
			"position": position,
			"utility_data": data
		}
		
		# If we're in a sequence context, provide the sequence data to SceneManager
		if not current_sequence.is_empty():
			transition_request["current_sequence_context"] = current_sequence
			# Ensure SceneManager knows about the sequence
			if scene_manager.has_method("_restore_sequence_context"):
				scene_manager._restore_sequence_context(current_sequence)
			else:
				# Fallback: set the sequence data directly
				scene_manager.current_sequence_data = current_sequence
		
		scene_manager.request_transition(transition_request)
	else:
		print("GridSystem: ❌ WARNING - No SceneManager found for teleporter transition")
		print("GridSystem: 🔍 Available autoloads:")
		_debug_print_autoloads()

## Is `name` a registered sequence? Asks MapProgressionManager first (which
## auto-loads every sequences/*.json at boot, so new sequences like atlas
## just work). Falls back to a static list for safety when MPM isn't ready.
func _is_known_sequence(name: String) -> bool:
	var mpm = get_node_or_null("/root/MapProgressionManager")
	if mpm and mpm.has_method("has_sequence"):
		return mpm.has_sequence(name)
	if mpm and "sequences" in mpm:
		var seqs = mpm.get("sequences")
		if seqs is Dictionary:
			return seqs.has(name)
	# Fallback — the pre-existing hardcoded list plus new sequences
	return name in [
		"primitives", "tests", "array_tutorial", "meshestextures", "randomness",
		"wavefunctions", "noise", "forces", "proceduralaudio", "physicssimulation",
		"softbodies", "recursiveemergence", "lsystems", "swarmintelligence",
		"patterngeneration", "mosaicanalysis", "proceduralgeneration",
		"searchpathfinding", "graphtheory", "computationalgeometry",
		"machinelearning", "criticalalgorithms", "speculativecomputation",
		"resourcemanagement", "advancedlaboratory", "qfeplaboratory",
		"grammar_systems", "spatial_partitioning", "constraint_solvers",
		"isosurfaces", "higher_dimensions", "morphogenesis",
		# Newer cross-cutting sequences — keep in sync with sequences/*.json
		"atlas",
	]


# Find SceneManager (check autoloads first, then scene tree)
func _find_scene_manager():
	# Check autoloads first (most common location)
	var autoload_managers = [
		get_node_or_null("/root/SceneManager"),
		get_node_or_null("/root/AdaSceneManager")
	]
	
	for manager in autoload_managers:
		if manager:
			print("GridSystem: Found SceneManager autoload: %s" % manager.name)
			return manager
	
	# Check scene tree
	var scene_managers = [
		get_tree().current_scene.find_child("SceneManager", true, false),
		get_tree().current_scene.find_child("AdaSceneManager", true, false)
	]
	
	for manager in scene_managers:
		if manager:
			print("GridSystem: Found SceneManager in scene: %s" % manager.get_path())
			return manager
	
	return null

# Debug: Print autoloads to help find SceneManager
func _debug_print_autoloads():
	print("GridSystem: Autoloads in /root/:")
	for child in get_tree().root.get_children():
		print("  → %s (%s)" % [child.name, child.get_class()])

# Handle interactable activation
func _on_interactable_activated(object_id: String, position: Vector3, data: Dictionary):
	print("GridSystem: Interactable activated - %s at %s" % [object_id, position])
	emit_signal("interactable_activated", object_id, position, data)

# Reload map setter
func reload_map_setter(value: bool):
	if value:
		reload_map = false
		call_deferred("_reload_current_map")

# Reload current map
func _reload_current_map():
	print("GridSystem: Reloading map '%s'" % map_name)
	
	# Clear all components
	_clear_all_components()
	
	# Wait one frame for queue_free() to complete
	await get_tree().process_frame
	
	# Try to re-validate base_cube reference (it might have become invalid)
	# But don't fail - structure_component caches mesh data from first init
	if not is_instance_valid(base_cube):
		base_cube = get_node_or_null("CubeScene")
		if base_cube:
			print("GridSystem: Re-acquired base_cube reference")
		else:
			print("GridSystem: base_cube unavailable, will use cached mesh data")
	
	# Reload map data
	_load_map_data()

# Clear all components
func _clear_all_components():
	print("GridSystem: Clearing all components...")
	
	if structure_component:
		structure_component.clear_structure()
	
	if utilities_component:
		utilities_component.clear_utilities()
	
	if interactables_component:
		interactables_component.clear_interactables()

	if ceiling_component:
		ceiling_component.clear_ceiling()

	if wall_component:
		wall_component.clear_walls()

	if audio_component:
		audio_component.cleanup()

	if _ecosystem_spawner and is_instance_valid(_ecosystem_spawner):
		_ecosystem_spawner.queue_free()
		_ecosystem_spawner = null

	generation_in_progress = false

# Public API methods

# Get current map information
func get_current_map_info() -> Dictionary:
	var info = {
		"name": map_name,
		"format": data_component.get_current_format() if data_component else "unknown",
		"dimensions": data_component.get_grid_dimensions() if data_component else Vector3i.ZERO,
		"objects": {
			"cubes": structure_component.get_cube_count() if structure_component else 0,
			"utilities": utilities_component.get_utility_count() if utilities_component else 0,
			"interactables": interactables_component.get_interactable_count() if interactables_component else 0,
			"ceiling_tiles": ceiling_component.ceiling_tiles.size() if ceiling_component else 0,
			"ceiling_lights": ceiling_component.ceiling_lights.size() if ceiling_component else 0,
			"walls": wall_component.get_wall_count() if wall_component else 0
		},
		"generation_complete": not generation_in_progress
	}
	
	if data_component:
		info.merge(data_component.get_map_metadata())
	
	return info

# Get component references (for external access)
func get_data_component() -> GridDataComponent:
	return data_component

func get_structure_component() -> GridStructureComponent:
	return structure_component

func get_utilities_component() -> GridUtilitiesComponent:
	return utilities_component

func get_interactables_component() -> GridInteractablesComponent:
	return interactables_component

func get_spawn_component() -> GridSpawnComponent:
	return spawn_component

func get_ceiling_component() -> GridCeilingComponent:
	return ceiling_component

func get_wall_component() -> GridWallComponent:
	return wall_component

func get_audio_component() -> GridAudioComponent:
	return audio_component

# Check if map is fully loaded and generated
func is_map_ready() -> bool:
	return data_component and data_component.is_data_loaded() and not generation_in_progress

# Get grid dimensions
func get_grid_dimensions() -> Vector3i:
	if data_component:
		return data_component.get_grid_dimensions()
	return Vector3i.ZERO

# Find highest Y position at X,Z coordinate (delegated to structure component)
func find_highest_y_at(x: int, z: int) -> int:
	if structure_component:
		return structure_component.find_highest_y_at(x, z)
	return 0

# Check if position has a cube (delegated to structure component)
func has_cube_at(x: int, y: int, z: int) -> bool:
	if structure_component:
		return structure_component.has_cube_at(x, y, z)
	return false

# Get utility at position (delegated to utilities component)
func get_utility_at(x: int, y: int, z: int) -> Node3D:
	if utilities_component:
		return utilities_component.get_utility_at(x, y, z)
	return null

# Get interactable at position (delegated to interactables component)
func get_interactable_at(x: int, y: int, z: int) -> Node3D:
	if interactables_component:
		return interactables_component.get_interactable_at(x, y, z)
	return null

# Debug: Print component status
func print_component_status():
	print("=== GridSystem Component Status ===")
	print("Map: %s" % map_name)
	print("Generation in progress: %s" % generation_in_progress)
	print("Data component: %s (loaded: %s)" % [
		"✓" if data_component else "✗",
		data_component.is_data_loaded() if data_component else false
	])
	print("Structure component: %s (cubes: %d)" % [
		"✓" if structure_component else "✗",
		structure_component.get_cube_count() if structure_component else 0
	])
	print("Utilities component: %s (utilities: %d)" % [
		"✓" if utilities_component else "✗",
		utilities_component.get_utility_count() if utilities_component else 0
	])
	print("Interactables component: %s (interactables: %d)" % [
		"✓" if interactables_component else "✗",
		interactables_component.get_interactable_count() if interactables_component else 0
	])
	print("Spawn component: %s" % ("✓" if spawn_component else "✗"))
	
	if data_component:
		print("Spawn info: %s" % spawn_component.get_spawn_info())
	
	print("==================================")

# Show error state when map loading fails completely
func _show_error_state(failed_map_name: String, error: String):
	print("GridSystem: 🔴 SHOWING ERROR STATE - MAP LOAD FAILED")
	print("GridSystem: Map: '%s'" % failed_map_name)
	print("GridSystem: Error: %s" % error)
	
	# Create a simple error display cube
	if is_instance_valid(base_cube):
		var error_cube = base_cube.duplicate()
		error_cube.position = Vector3.ZERO
		error_cube.visible = true
		add_child(error_cube)
		
		# Add error label
		var label = Label3D.new()
		label.text = "❌ MAP LOAD FAILED ❌\nMap: %s\nError: %s\n\nCHECK CONSOLE FOR DETAILS" % [failed_map_name, error]
		label.position = Vector3(0, 2, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color.RED
		add_child(label)
		
		print("GridSystem: 🔴 Error state displayed - check scene for red error message")
		print("GridSystem: 🔍 Run print_component_status() for detailed debugging info")

# Add explicit failure checking
func has_load_error() -> bool:
	return not is_map_ready() and not generation_in_progress

# Get error details for debugging
func get_error_info() -> Dictionary:
	return {
		"has_error": has_load_error(),
		"map_name": map_name,
		"data_loaded": data_component.is_data_loaded() if data_component else false,
		"generation_in_progress": generation_in_progress,
		"components_initialized": _are_components_initialized()
	}

# Check if all components are properly initialized
func _are_components_initialized() -> bool:
	return (data_component != null and
			structure_component != null and
			utilities_component != null and
			interactables_component != null and
			spawn_component != null and
			ceiling_component != null)


# ─── Runtime flags ───────────────────────────────────────────────
# Read from ada_run/runtime_flags.json — flipped by the encyclopedia
# /shortcuts page. Used for capture/debug scenarios where the live
# behaviour (biome, etc.) interferes with what the user is doing.

func _runtime_flag_enabled(flag_name: String, default_value: bool) -> bool:
	var path := "res://ada_run/runtime_flags.json"
	var fa := FileAccess.open(path, FileAccess.READ)
	if not fa:
		return default_value
	var raw := fa.get_as_text()
	fa.close()
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		return default_value
	if not data.has(flag_name):
		return default_value
	return bool(data[flag_name])
