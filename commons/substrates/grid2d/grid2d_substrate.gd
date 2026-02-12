@tool
extends Node3D
class_name Grid2DSubstrate

## Grid2D Substrate — the backbone artifact.
## A MultiMesh cell grid driven by swappable algorithm cartridges.
## Petri dish variant: dark glass base, rounded cubes, emission + bloom.
##
## Place in map: "grid2d_life", "grid2d#algorithm:rule30", etc.

## --- Configuration ---

@export var grid_width: int = 48
@export var grid_height: int = 48
@export var step_interval: float = 0.12  ## Seconds between generations
@export var auto_play: bool = true        ## Start stepping immediately (set false for touch-to-start)
@export var label_text: String = ""

## Algorithm selection
enum Algorithm {
	GAME_OF_LIFE, SEEDS, BRIANS_BRAIN,
	RULE30, RULE110, RULE90,
	BFS_FLOOD, DFS_MAZE,
	WIRE_WORLD,
	LANGTONS_ANT,
}

@export var algorithm: Algorithm = Algorithm.GAME_OF_LIFE:
	set(v):
		algorithm = v
		if is_inside_tree() and not Engine.is_editor_hint():
			_load_cartridge()

## --- Signals ---

signal generation_advanced(step_index: int)
signal cell_touched(x: int, y: int, state: int)
signal playback_changed(is_playing: bool)

## --- Internal ---

var _cartridge: Grid2DCartridge
var _grid: PackedInt32Array
var _prev_grid: PackedInt32Array
var _step_index: int = 0
var _is_playing: bool = false
var _time_accumulator: float = 0.0

@onready var _renderer: Grid2DRenderer = $Renderer
@onready var _base_plate: MeshInstance3D = $BasePlate
@onready var _rim: MeshInstance3D = $Rim
@onready var _label: Label3D = $Label3D
@onready var _touch_area: Area3D = $TouchArea


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_resolve_algorithm_from_lookup_name()
	_load_cartridge()

	if auto_play:
		_is_playing = true


func _load_cartridge() -> void:
	_cartridge = _create_cartridge(algorithm)

	# Let cartridge override grid size if it has a preference
	var pw = _cartridge.get_preferred_width()
	var ph = _cartridge.get_preferred_height()
	if pw > 0:
		grid_width = pw
	if ph > 0:
		grid_height = ph

	var pi = _cartridge.get_preferred_interval()
	if pi > 0.0:
		step_interval = pi

	# Initialize grid
	var total = grid_width * grid_height
	_grid = PackedInt32Array()
	_grid.resize(total)
	_grid.fill(0)
	_prev_grid = PackedInt32Array()
	_prev_grid.resize(total)
	_prev_grid.fill(0)
	_step_index = 0
	_time_accumulator = 0.0

	# Setup renderer
	if _renderer:
		_renderer.setup(grid_width, grid_height)

	# Let cartridge populate initial state
	_cartridge.initialize(_grid, grid_width, grid_height)

	# Warmup steps
	var warmup = _cartridge.get_warmup_steps()
	for i in range(warmup):
		_prev_grid = _grid.duplicate()
		_grid = _cartridge.step(_grid, grid_width, grid_height)
		_step_index += 1

	# Push initial state to renderer
	if _renderer:
		_renderer.update_grid(_grid, _cartridge, _prev_grid)

	# Update visuals
	_update_base_plate()
	_update_touch_area()
	_update_label()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Always interpolate visuals (smooth transitions even when paused)
	if _renderer:
		_renderer.interpolate(delta)

	if not _is_playing or not _cartridge:
		return

	_time_accumulator += delta
	if _time_accumulator >= step_interval:
		_time_accumulator -= step_interval
		_advance_step()


func _advance_step() -> void:
	_prev_grid = _grid.duplicate()
	_grid = _cartridge.step(_grid, grid_width, grid_height)
	_step_index += 1

	if _renderer:
		_renderer.update_grid(_grid, _cartridge, _prev_grid)

	generation_advanced.emit(_step_index)


## --- Public API ---

func play() -> void:
	_is_playing = true
	_time_accumulator = 0.0
	playback_changed.emit(true)

func pause() -> void:
	_is_playing = false
	playback_changed.emit(false)

func toggle_play() -> void:
	if _is_playing:
		pause()
	else:
		play()

func single_step() -> void:
	_advance_step()

func reset() -> void:
	_step_index = 0
	_time_accumulator = 0.0
	_grid.fill(0)
	_prev_grid.fill(0)
	_cartridge.initialize(_grid, grid_width, grid_height)
	if _renderer:
		_renderer.update_grid(_grid, _cartridge, _prev_grid)

func touch_cell(x: int, y: int) -> void:
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		return
	_prev_grid = _grid.duplicate()
	_grid = _cartridge.on_cell_touch(_grid, x, y, grid_width, grid_height)
	var state = _grid[y * grid_width + x]
	if _renderer:
		_renderer.update_grid(_grid, _cartridge, _prev_grid)
	cell_touched.emit(x, y, state)

func get_step_count() -> int:
	return _step_index

func is_playing() -> bool:
	return _is_playing


## --- Visuals ---

func _update_base_plate() -> void:
	if not _renderer or not _base_plate:
		return
	var world_size = _renderer.get_world_size()
	# Base plate slightly larger than grid
	var plate_margin = 0.04
	_base_plate.mesh.size = Vector3(
		world_size.x + plate_margin * 2,
		0.012,
		world_size.y + plate_margin * 2
	)
	_base_plate.position.y = -0.006  # Sink below cells

	# Rim
	if _rim:
		_rim.mesh.size = Vector3(
			world_size.x + plate_margin * 2 + 0.01,
			0.018,
			world_size.y + plate_margin * 2 + 0.01
		)
		_rim.position.y = -0.003


func _update_touch_area() -> void:
	if not _renderer or not _touch_area:
		return
	var world_size = _renderer.get_world_size()
	var shape = _touch_area.get_node_or_null("CollisionShape3D")
	if shape and shape.shape is BoxShape3D:
		shape.shape.size = Vector3(world_size.x, 0.05, world_size.y)


func _update_label() -> void:
	if not _label or not _cartridge:
		return
	var display = label_text if label_text != "" else _cartridge.get_name()
	_label.text = display
	# Position label below the base plate
	if _renderer:
		var world_size = _renderer.get_world_size()
		_label.position = Vector3(0, -0.02, world_size.y * 0.5 + 0.05)


## --- Touch detection ---

func _on_touch_area_body_entered(body: Node3D) -> void:
	# VR hand / pointer entered the grid area
	pass

func _on_touch_input(event: InputEvent, local_pos: Vector3) -> void:
	if not _renderer:
		return
	var grid_pos = _renderer.world_to_grid(local_pos)
	if grid_pos.x >= 0:
		touch_cell(grid_pos.x, grid_pos.y)


## --- Cartridge factory ---

func _create_cartridge(algo: Algorithm) -> Grid2DCartridge:
	match algo:
		Algorithm.GAME_OF_LIFE:
			return preload("res://commons/substrates/grid2d/cartridges/cartridge_game_of_life.gd").new()
		Algorithm.SEEDS:
			return preload("res://commons/substrates/grid2d/cartridges/cartridge_seeds.gd").new()
		Algorithm.BRIANS_BRAIN:
			return preload("res://commons/substrates/grid2d/cartridges/cartridge_brians_brain.gd").new()
		Algorithm.RULE30:
			return preload("res://commons/substrates/grid2d/cartridges/cartridge_rule_1d.gd").new(30)
		Algorithm.RULE110:
			return preload("res://commons/substrates/grid2d/cartridges/cartridge_rule_1d.gd").new(110)
		Algorithm.RULE90:
			return preload("res://commons/substrates/grid2d/cartridges/cartridge_rule_1d.gd").new(90)
		Algorithm.BFS_FLOOD:
			return preload("res://commons/substrates/grid2d/cartridges/cartridge_bfs.gd").new()
		Algorithm.DFS_MAZE:
			return preload("res://commons/substrates/grid2d/cartridges/cartridge_dfs_maze.gd").new()
		Algorithm.WIRE_WORLD:
			return preload("res://commons/substrates/grid2d/cartridges/cartridge_wireworld.gd").new()
		Algorithm.LANGTONS_ANT:
			return preload("res://commons/substrates/grid2d/cartridges/cartridge_langtons_ant.gd").new()

	# Fallback
	return preload("res://commons/substrates/grid2d/cartridges/cartridge_game_of_life.gd").new()


## --- Lookup name auto-resolve (same pattern as LivingPaper) ---

func _resolve_algorithm_from_lookup_name() -> void:
	var lookup = get_meta("artifact_lookup_name", "")
	if lookup == "" or lookup == "grid2d":
		return
	var key = lookup.replace("grid2d_", "")
	var algo_map = {
		"life": Algorithm.GAME_OF_LIFE,
		"game_of_life": Algorithm.GAME_OF_LIFE,
		"seeds": Algorithm.SEEDS,
		"brians_brain": Algorithm.BRIANS_BRAIN,
		"rule30": Algorithm.RULE30,
		"rule110": Algorithm.RULE110,
		"rule90": Algorithm.RULE90,
		"bfs": Algorithm.BFS_FLOOD,
		"dfs_maze": Algorithm.DFS_MAZE,
		"wireworld": Algorithm.WIRE_WORLD,
		"langtons_ant": Algorithm.LANGTONS_ANT,
	}
	if key in algo_map:
		algorithm = algo_map[key]
		print("Grid2D: Auto-selected '%s' from lookup_name '%s'" % [key, lookup])


## --- Grid config from map system ---

func apply_grid_config(config: Dictionary) -> void:
	print("Grid2D: apply_grid_config called with: %s" % str(config))

	# Collect size changes first (before algorithm setter triggers _load_cartridge)
	if config.has("width"):
		grid_width = int(config["width"])
	if config.has("height"):
		grid_height = int(config["height"])
	if config.has("interval"):
		step_interval = float(config["interval"])
	if config.has("auto_play"):
		auto_play = str(config["auto_play"]).to_lower() == "true"

	# Set algorithm last — the setter calls _load_cartridge() which re-initializes everything
	if config.has("algorithm"):
		var algo_name = str(config["algorithm"]).to_lower()
		var algo_map = {
			"life": Algorithm.GAME_OF_LIFE,
			"game_of_life": Algorithm.GAME_OF_LIFE,
			"seeds": Algorithm.SEEDS,
			"brians_brain": Algorithm.BRIANS_BRAIN,
			"rule30": Algorithm.RULE30,
			"rule110": Algorithm.RULE110,
			"rule90": Algorithm.RULE90,
			"bfs": Algorithm.BFS_FLOOD,
			"dfs_maze": Algorithm.DFS_MAZE,
			"wireworld": Algorithm.WIRE_WORLD,
			"langtons_ant": Algorithm.LANGTONS_ANT,
		}
		if algo_name in algo_map:
			algorithm = algo_map[algo_name]
			print("Grid2D: Config set algorithm to '%s'" % algo_name)
		else:
			push_warning("Grid2D: Unknown algorithm '%s'" % algo_name)

	# Ensure playback is running
	if auto_play and not _is_playing:
		play()
		print("Grid2D: Auto-play started after config")
