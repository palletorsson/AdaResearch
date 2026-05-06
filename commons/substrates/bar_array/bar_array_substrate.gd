@tool
extends Node3D
class_name BarArraySubstrate

## BarArray Substrate — the 1D algorithm visualization workhorse.
## A MultiMesh bar array driven by swappable algorithm cartridges.
## Sorting, spectra, histograms, sequences — one object, many algorithms.
##
## Place in map: "bar_array_bubble_sort", "bar_array#algorithm:quicksort#size:24", etc.

## --- Configuration ---

@export var array_size: int = 32
@export var step_interval: float = 0.08  ## Seconds between steps
@export var auto_play: bool = true        ## Start stepping immediately
@export var label_text: String = ""

## Algorithm selection
enum Algorithm {
	BUBBLE_SORT, INSERTION_SORT, SELECTION_SORT,
	MERGE_SORT, QUICKSORT, HEAP_SORT,
	HISTOGRAM, FIBONACCI, PRIME_SIEVE,
}

@export var algorithm: Algorithm = Algorithm.BUBBLE_SORT:
	set(v):
		algorithm = v
		if is_inside_tree() and not Engine.is_editor_hint():
			_load_cartridge()

## --- Signals ---

signal step_advanced(step_index: int)
signal bar_touched(index: int, value: float)
signal playback_changed(is_playing: bool)
signal sort_complete()

## --- Internal ---

var _cartridge: BarArrayCartridge
var _array: PackedFloat32Array
var _step_index: int = 0
var _is_playing: bool = false
var _is_done: bool = false
var _time_accumulator: float = 0.0

@onready var _renderer: BarArrayRenderer = $Renderer
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

	# Let cartridge override size/interval if it has a preference
	var ps = _cartridge.get_preferred_size()
	if ps > 0:
		array_size = ps

	var pi = _cartridge.get_preferred_interval()
	if pi > 0.0:
		step_interval = pi

	# Initialize array
	_array = _cartridge.initialize(array_size)
	_step_index = 0
	_time_accumulator = 0.0
	_is_done = false

	# Setup renderer
	if _renderer:
		_renderer.setup(array_size)

	# Warmup steps
	var warmup = _cartridge.get_warmup_steps()
	for i in range(warmup):
		var result = _cartridge.step(_array)
		_array = result["array"]
		_step_index += 1

	# Push initial state to renderer
	if _renderer:
		_renderer.update_bars(_array, _cartridge)

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

	if not _is_playing or not _cartridge or _is_done:
		return

	_time_accumulator += delta
	if _time_accumulator >= step_interval:
		_time_accumulator -= step_interval
		_advance_step()


func _advance_step() -> void:
	var result = _cartridge.step(_array)
	_array = result["array"]
	_step_index += 1

	if _renderer:
		_renderer.update_bars(_array, _cartridge, result)

	step_advanced.emit(_step_index)

	# Check if done
	if result.get("done", false):
		_is_done = true
		sort_complete.emit()


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
	_is_done = false
	_array = _cartridge.initialize(array_size)
	if _renderer:
		_renderer.update_bars(_array, _cartridge)

func touch_bar(index: int) -> void:
	if index < 0 or index >= array_size:
		return
	_array = _cartridge.on_bar_touch(_array, index)
	var value = _array[index]
	if _renderer:
		_renderer.update_bars(_array, _cartridge)
	bar_touched.emit(index, value)

func get_step_count() -> int:
	return _step_index

func is_playing() -> bool:
	return _is_playing

func is_done() -> bool:
	return _is_done


## --- Visuals ---

func _update_base_plate() -> void:
	if not _renderer or not _base_plate:
		return
	var world_size = _renderer.get_world_size()
	var plate_margin = 0.04
	_base_plate.mesh.size = Vector3(
		world_size.x + plate_margin * 2,
		0.012,
		world_size.y * 0.3 + plate_margin * 2
	)
	_base_plate.position.y = -0.006

	if _rim:
		_rim.mesh.size = Vector3(
			world_size.x + plate_margin * 2 + 0.01,
			0.018,
			world_size.y * 0.3 + plate_margin * 2 + 0.01
		)
		_rim.position.y = -0.003


func _update_touch_area() -> void:
	if not _renderer or not _touch_area:
		return
	var world_size = _renderer.get_world_size()
	var shape = _touch_area.get_node_or_null("CollisionShape3D")
	if shape and shape.shape is BoxShape3D:
		shape.shape.size = Vector3(world_size.x, world_size.y + 0.05, 0.1)
		shape.position.y = world_size.y * 0.5


func _update_label() -> void:
	if not _label or not _cartridge:
		return
	var display = label_text if label_text != "" else _cartridge.get_name()
	_label.text = display
	if _renderer:
		var world_size = _renderer.get_world_size()
		_label.position = Vector3(0, -0.02, world_size.y * 0.15 + 0.05)


## --- Cartridge factory ---

func _create_cartridge(algo: Algorithm) -> BarArrayCartridge:
	match algo:
		Algorithm.BUBBLE_SORT:
			return preload("res://commons/substrates/bar_array/cartridges/cartridge_bubble_sort.gd").new()
		Algorithm.INSERTION_SORT:
			return preload("res://commons/substrates/bar_array/cartridges/cartridge_insertion_sort.gd").new()
		Algorithm.SELECTION_SORT:
			return preload("res://commons/substrates/bar_array/cartridges/cartridge_selection_sort.gd").new()
		Algorithm.MERGE_SORT:
			return preload("res://commons/substrates/bar_array/cartridges/cartridge_merge_sort.gd").new()
		Algorithm.QUICKSORT:
			return preload("res://commons/substrates/bar_array/cartridges/cartridge_quicksort.gd").new()
		Algorithm.HEAP_SORT:
			return preload("res://commons/substrates/bar_array/cartridges/cartridge_heap_sort.gd").new()
		Algorithm.HISTOGRAM:
			return preload("res://commons/substrates/bar_array/cartridges/cartridge_histogram.gd").new()
		Algorithm.FIBONACCI:
			return preload("res://commons/substrates/bar_array/cartridges/cartridge_fibonacci.gd").new()
		Algorithm.PRIME_SIEVE:
			return preload("res://commons/substrates/bar_array/cartridges/cartridge_prime_sieve.gd").new()

	# Fallback
	return preload("res://commons/substrates/bar_array/cartridges/cartridge_bubble_sort.gd").new()


## --- Lookup name auto-resolve ---

func _resolve_algorithm_from_lookup_name() -> void:
	var lookup = get_meta("artifact_lookup_name", "")
	if lookup == "" or lookup == "bar_array":
		return
	var key = lookup.replace("bar_array_", "")
	var algo_map = {
		"bubble_sort": Algorithm.BUBBLE_SORT,
		"bubble": Algorithm.BUBBLE_SORT,
		"insertion_sort": Algorithm.INSERTION_SORT,
		"insertion": Algorithm.INSERTION_SORT,
		"selection_sort": Algorithm.SELECTION_SORT,
		"selection": Algorithm.SELECTION_SORT,
		"merge_sort": Algorithm.MERGE_SORT,
		"merge": Algorithm.MERGE_SORT,
		"quicksort": Algorithm.QUICKSORT,
		"quick_sort": Algorithm.QUICKSORT,
		"quick": Algorithm.QUICKSORT,
		"heap_sort": Algorithm.HEAP_SORT,
		"heap": Algorithm.HEAP_SORT,
		"histogram": Algorithm.HISTOGRAM,
		"fibonacci": Algorithm.FIBONACCI,
		"fib": Algorithm.FIBONACCI,
		"prime_sieve": Algorithm.PRIME_SIEVE,
		"primes": Algorithm.PRIME_SIEVE,
		"sieve": Algorithm.PRIME_SIEVE,
	}
	if key in algo_map:
		algorithm = algo_map[key]
		print("BarArray: Auto-selected '%s' from lookup_name '%s'" % [key, lookup])


## --- Grid config from map system ---

func apply_grid_config(config: Dictionary) -> void:
	print("BarArray: apply_grid_config called with: %s" % str(config))

	if config.has("size"):
		array_size = int(config["size"])
	if config.has("width"):
		array_size = int(config["width"])
	if config.has("interval"):
		step_interval = float(config["interval"])
	if config.has("auto_play"):
		auto_play = str(config["auto_play"]).to_lower() == "true"

	# Set algorithm last — the setter calls _load_cartridge()
	if config.has("algorithm"):
		var algo_name = str(config["algorithm"]).to_lower()
		var algo_map = {
			"bubble_sort": Algorithm.BUBBLE_SORT,
			"bubble": Algorithm.BUBBLE_SORT,
			"insertion_sort": Algorithm.INSERTION_SORT,
			"insertion": Algorithm.INSERTION_SORT,
			"selection_sort": Algorithm.SELECTION_SORT,
			"selection": Algorithm.SELECTION_SORT,
			"merge_sort": Algorithm.MERGE_SORT,
			"merge": Algorithm.MERGE_SORT,
			"quicksort": Algorithm.QUICKSORT,
			"quick_sort": Algorithm.QUICKSORT,
			"heap_sort": Algorithm.HEAP_SORT,
			"heap": Algorithm.HEAP_SORT,
			"histogram": Algorithm.HISTOGRAM,
			"fibonacci": Algorithm.FIBONACCI,
			"prime_sieve": Algorithm.PRIME_SIEVE,
			"primes": Algorithm.PRIME_SIEVE,
		}
		if algo_name in algo_map:
			algorithm = algo_map[algo_name]
			print("BarArray: Config set algorithm to '%s'" % algo_name)
		else:
			push_warning("BarArray: Unknown algorithm '%s'" % algo_name)

	if auto_play and not _is_playing:
		play()
		print("BarArray: Auto-play started after config")
