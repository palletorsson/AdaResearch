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

## --- STAGE-2 DNA, promoted 2026-08-05 ---------------------------------------------------
## THE STATE THE ARRAY IS FOUND IN.
##
## A sort is time-domain and a still catches one arbitrary pass, so "how far through" is not
## an honest axis for a photograph. What IS still-visible, and what this artifact's own
## subject line is about, is the array BEFORE the first comparison — because bubble sort's
## whole claim is that the same code costs O(n) on one input and O(n^2) on another, and the
## input is a picture.
##
##   shuffled       the shipped Fisher-Yates draw. Average case, ~n^2/4 inversions.
##   reversed       descending. The WORST case: n(n-1)/2 inversions, every pass swaps.
##   nearly_sorted  ascending with a scatter of adjacent transpositions. The case where
##                  bubble sort is genuinely competitive and everyone forgets it.
##   sorted         ascending. The BEST case: one pass, no swap, done — the early-exit
##                  branch in cartridge_bubble_sort.step() that nothing had ever shown.
##
## WHY NOT found_state. entropy_jar and entropy_morphogenesis already declare
## found_state = sorted | stirred | mixed for the same-shaped question, and three of these
## four values map onto it cleanly. `reversed` does not, and cannot be added to it without
## breaking it: on an entropy ladder reversed sits at the SAME rung as sorted (it is
## perfectly ordered) while being the single most expensive input bubble sort can be handed.
## That gap is exactly this artifact's lesson — the cost model is inversion count, not
## disorder — so taking the word would have meant either corrupting a sibling's ladder or
## dropping the one value that carries the argument. Different question, different word.
##
## DEFAULT PRESERVES. At initial_order = "shuffled" AND order_seed = 0, _arrange returns the
## cartridge's own array untouched, so the shipped `super.initialize()` shuffle is the only
## thing that ran. The 4 existing placements are unaffected.
@export_enum("shuffled", "reversed", "nearly_sorted", "sorted") var initial_order: String = "shuffled"
const ORDERS: PackedStringArray = ["shuffled", "reversed", "nearly_sorted", "sorted"]
## Capture-bench pin, NOT an axis. The shipped shuffle is the global unseeded randi(), so a
## sweep photographs a different array every run and any bite number measures the RNG. 0
## keeps the shipped fresh-every-run behaviour and is what every placement gets.
@export var order_seed: int = 0

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

	# DNA: normalise before anything builds, so an unrecognised value falls back to the
	# shipped lineage rather than to whatever the match block's wildcard happens to draw.
	var _o: String = str(initial_order).strip_edges().to_lower()
	initial_order = _o if ORDERS.has(_o) else "shuffled"

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

	# Initialize array. The cartridge still runs first — it resets its own cursor and pass
	# state off array_size — and _arrange then decides what values those indices hold. At the
	# shipped default it hands the cartridge's array straight back.
	_array = _arrange(_cartridge.initialize(array_size))
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
	_array = _arrange(_cartridge.initialize(array_size))
	if _renderer:
		_renderer.update_bars(_array, _cartridge)


## --- initial_order ----------------------------------------------------------------------
## Rewrite the starting values. Returns the cartridge's own array UNCHANGED on the shipped
## default, so this is a short circuit and not a recomputation of the same shuffle — a map
## that overrides nothing gets the same code path it always got.
func _arrange(arr: PackedFloat32Array) -> PackedFloat32Array:
	if initial_order == "shuffled" and order_seed == 0:
		return arr

	# ONLY A SORT IS ASKED WHAT STATE ITS INPUT IS IN. This export lands on the substrate,
	# which all nine bar_array_* tokens share, but histogram, fibonacci and prime_sieve build
	# their own arrays in initialize() — an empty bin count, a Fibonacci series, a sieve —
	# and overwriting those with a ramp would not be a variation of anything, it would be
	# vandalism. Asked of the cartridge rather than hard-coded against a list of names, so a
	# tenth cartridge answers for itself. The six sorts inherit the base "sorting".
	if _cartridge == null or _cartridge.get_category() != "sorting":
		return arr

	var n: int = arr.size()
	if n <= 0:
		return arr

	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		out[i] = float(i + 1) / float(n)

	match initial_order:
		"sorted":
			# Ascending, untouched. Bubble sort's best case: one pass, no swap.
			pass
		"reversed":
			# The worst case — every adjacent pair is an inversion.
			out.reverse()
		"nearly_sorted":
			# Ascending with ~12% of positions disturbed by an adjacent transposition.
			var rng_near: RandomNumberGenerator = RandomNumberGenerator.new()
			rng_near.seed = order_seed if order_seed != 0 else 20260805
			var kicks: int = maxi(1, int(float(n) * 0.12))
			for k in range(kicks):
				var i_near: int = rng_near.randi_range(0, n - 2)
				var tmp_near: float = out[i_near]
				out[i_near] = out[i_near + 1]
				out[i_near + 1] = tmp_near
		_:
			# "shuffled" with a pinned seed — the same Fisher-Yates the cartridge does,
			# reproducible so a sweep photographs one array rather than one per run.
			var rng_all: RandomNumberGenerator = RandomNumberGenerator.new()
			rng_all.seed = order_seed if order_seed != 0 else 20260805
			for i in range(n - 1, 0, -1):
				var j: int = rng_all.randi_range(0, i)
				var tmp_all: float = out[i]
				out[i] = out[j]
				out[j] = tmp_all

	return out

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

	# DNA. Read BEFORE the algorithm key below, because the algorithm setter calls
	# _load_cartridge() and _load_cartridge is where _arrange runs — so if a token names both,
	# one rebuild serves both. An unknown value leaves the shipped state alone; a value that
	# did not change sets no flag and so costs nothing.
	var reload: bool = false
	if config.has("order_seed"):
		var s: int = int(config["order_seed"])
		if s != order_seed:
			order_seed = s
			reload = true
	if config.has("initial_order"):
		var want: String = str(config["initial_order"]).strip_edges().to_lower()
		if ORDERS.has(want) and want != initial_order:
			initial_order = want
			reload = true

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
			reload = false   # the setter already re-ran _load_cartridge with the new order
			print("BarArray: Config set algorithm to '%s'" % algo_name)
		else:
			push_warning("BarArray: Unknown algorithm '%s'" % algo_name)

	# Rebuild ONLY when a DNA value actually changed, only after _ready built the cartridge
	# once, and only if the algorithm setter above has not already done it.
	if reload and _cartridge != null:
		_load_cartridge()

	if auto_play and not _is_playing:
		play()
		print("BarArray: Auto-play started after config")
