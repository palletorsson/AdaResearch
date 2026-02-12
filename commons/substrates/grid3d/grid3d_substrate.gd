@tool
extends Node3D
class_name Grid3DSubstrate

## Grid3D Substrate — volumetric MultiMesh with connection layer.
## Nodes (spheres) + Edges (cylinders) driven by swappable algorithm cartridges.
## Walk through the data. Watch graphs evolve. Touch nodes.
##
## Place in map: "grid3d_bfs", "grid3d#algorithm:force_directed#nodes:30", etc.

## --- Configuration ---

@export var node_count: int = 20
@export var bounds: Vector3 = Vector3(2.0, 1.5, 2.0)  ## World-space bounds for node placement
@export var step_interval: float = 0.3
@export var auto_play: bool = true
@export var label_text: String = ""

## Algorithm selection
enum Algorithm {
	BFS, DFS, DIJKSTRA,
	KRUSKAL_MST, PRIM_MST,
	FORCE_DIRECTED,
	RANDOM_GRAPH,
	ENTROPY_FIELD,
}

@export var algorithm: Algorithm = Algorithm.BFS:
	set(v):
		algorithm = v
		if is_inside_tree() and not Engine.is_editor_hint():
			_load_cartridge()

## --- Signals ---

signal step_advanced(step_index: int)
signal node_touched(index: int, state: int)
signal playback_changed(is_playing: bool)
signal algorithm_complete()

## --- Internal ---

var _cartridge: Grid3DCartridge
var _positions: PackedVector3Array
var _states: PackedInt32Array
var _edges: Array = []
var _edge_states: PackedInt32Array
var _edge_weights: PackedFloat32Array
var _step_index: int = 0
var _is_playing: bool = false
var _is_done: bool = false
var _time_accumulator: float = 0.0

@onready var _renderer: Grid3DRenderer = $Renderer
@onready var _label: Label3D = $Label3D


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_resolve_algorithm_from_lookup_name()
	_load_cartridge()

	if auto_play:
		_is_playing = true


func _load_cartridge() -> void:
	_cartridge = _create_cartridge(algorithm)

	# Let cartridge override settings
	var pn = _cartridge.get_preferred_node_count()
	if pn > 0:
		node_count = pn
	var pb = _cartridge.get_preferred_bounds()
	if pb != Vector3.ZERO:
		bounds = pb
	var pi = _cartridge.get_preferred_interval()
	if pi > 0.0:
		step_interval = pi

	# Initialize graph data from cartridge
	var data = _cartridge.initialize(node_count, bounds)
	_positions = data["positions"]
	_states = data["states"]
	_edges = data.get("edges", [])
	_edge_states = data.get("edge_states", PackedInt32Array())
	_edge_weights = data.get("edge_weights", PackedFloat32Array())
	_step_index = 0
	_time_accumulator = 0.0
	_is_done = false

	# Setup renderer
	if _renderer:
		_renderer.setup_nodes(_positions.size())
		_renderer.setup_edges(_edges)
		_renderer.update_nodes(_positions, _cartridge, _states)
		_renderer.update_edges(_cartridge, _edge_states)

	# Warmup steps
	var warmup = _cartridge.get_warmup_steps()
	for i in range(warmup):
		_do_step()

	# Update label
	_update_label()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Always interpolate (smooth even when paused)
	if _renderer:
		_renderer.interpolate(delta)

	if not _is_playing or not _cartridge or _is_done:
		return

	_time_accumulator += delta
	if _time_accumulator >= step_interval:
		_time_accumulator -= step_interval
		_do_step()


func _do_step() -> void:
	var result = _cartridge.step(_positions, _states, _edges, _edge_states, _edge_weights)

	# Update positions if cartridge provides new ones
	if result.get("positions") != null:
		_positions = result["positions"]
	if result.get("states") != null:
		_states = result["states"]
	if result.get("edges") != null:
		_edges = result["edges"]
		# Re-setup edge MultiMesh if edge list changed
		if _renderer:
			_renderer.setup_edges(_edges)
	if result.get("edge_states") != null:
		_edge_states = result["edge_states"]

	_step_index += 1

	if _renderer:
		_renderer.update_nodes(_positions, _cartridge, _states, result)
		_renderer.update_edges(_cartridge, _edge_states, result)

	step_advanced.emit(_step_index)

	if result.get("done", false):
		_is_done = true
		algorithm_complete.emit()


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
	_do_step()

func reset() -> void:
	_load_cartridge()

func touch_node(index: int) -> void:
	if index < 0 or index >= _positions.size():
		return
	_states = _cartridge.on_node_touch(index, _positions, _states)
	if _renderer:
		_renderer.update_nodes(_positions, _cartridge, _states)
	node_touched.emit(index, _states[index])

func get_step_count() -> int:
	return _step_index

func is_playing() -> bool:
	return _is_playing


## --- Visuals ---

func _update_label() -> void:
	if not _label or not _cartridge:
		return
	_label.text = label_text if label_text != "" else _cartridge.get_name()


## --- Cartridge factory ---

func _create_cartridge(algo: Algorithm) -> Grid3DCartridge:
	match algo:
		Algorithm.BFS:
			return preload("res://commons/substrates/grid3d/cartridges/cartridge_bfs_graph.gd").new()
		Algorithm.DFS:
			return preload("res://commons/substrates/grid3d/cartridges/cartridge_dfs_graph.gd").new()
		Algorithm.DIJKSTRA:
			return preload("res://commons/substrates/grid3d/cartridges/cartridge_dijkstra.gd").new()
		Algorithm.KRUSKAL_MST:
			return preload("res://commons/substrates/grid3d/cartridges/cartridge_kruskal_mst.gd").new()
		Algorithm.PRIM_MST:
			return preload("res://commons/substrates/grid3d/cartridges/cartridge_prim_mst.gd").new()
		Algorithm.FORCE_DIRECTED:
			return preload("res://commons/substrates/grid3d/cartridges/cartridge_force_directed.gd").new()
		Algorithm.RANDOM_GRAPH:
			return preload("res://commons/substrates/grid3d/cartridges/cartridge_random_graph.gd").new()
		Algorithm.ENTROPY_FIELD:
			return preload("res://commons/substrates/grid3d/cartridges/cartridge_entropy_field.gd").new()

	return preload("res://commons/substrates/grid3d/cartridges/cartridge_bfs_graph.gd").new()


## --- Lookup name auto-resolve ---

func _resolve_algorithm_from_lookup_name() -> void:
	var lookup = get_meta("artifact_lookup_name", "")
	if lookup == "" or lookup == "grid3d":
		return
	var key = lookup.replace("grid3d_", "")
	var algo_map = {
		"bfs": Algorithm.BFS,
		"dfs": Algorithm.DFS,
		"dijkstra": Algorithm.DIJKSTRA,
		"kruskal": Algorithm.KRUSKAL_MST,
		"kruskal_mst": Algorithm.KRUSKAL_MST,
		"prim": Algorithm.PRIM_MST,
		"prim_mst": Algorithm.PRIM_MST,
		"force_directed": Algorithm.FORCE_DIRECTED,
		"force": Algorithm.FORCE_DIRECTED,
		"random_graph": Algorithm.RANDOM_GRAPH,
		"random": Algorithm.RANDOM_GRAPH,
		"entropy": Algorithm.ENTROPY_FIELD,
		"entropy_field": Algorithm.ENTROPY_FIELD,
	}
	if key in algo_map:
		algorithm = algo_map[key]
		print("Grid3D: Auto-selected '%s' from lookup_name '%s'" % [key, lookup])


## --- Grid config from map system ---

func apply_grid_config(config: Dictionary) -> void:
	print("Grid3D: apply_grid_config called with: %s" % str(config))

	if config.has("nodes"):
		node_count = int(config["nodes"])
	if config.has("size"):
		node_count = int(config["size"])
	if config.has("interval"):
		step_interval = float(config["interval"])
	if config.has("auto_play"):
		auto_play = str(config["auto_play"]).to_lower() == "true"

	if config.has("algorithm"):
		var algo_name = str(config["algorithm"]).to_lower()
		var algo_map = {
			"bfs": Algorithm.BFS,
			"dfs": Algorithm.DFS,
			"dijkstra": Algorithm.DIJKSTRA,
			"kruskal": Algorithm.KRUSKAL_MST,
			"prim": Algorithm.PRIM_MST,
			"force_directed": Algorithm.FORCE_DIRECTED,
			"random_graph": Algorithm.RANDOM_GRAPH,
			"entropy": Algorithm.ENTROPY_FIELD,
		}
		if algo_name in algo_map:
			algorithm = algo_map[algo_name]
			print("Grid3D: Config set algorithm to '%s'" % algo_name)

	if auto_play and not _is_playing:
		play()
