# @identity
# essence: gaussian sampling that raises the HOST MAP's floor — each draw picks a cell in an 8x8 region and lifts that cube by raise_amount, so height is a visit count
# desire: stand in a room whose floor slowly grows a bell curve under you, made of the same cubes you were already walking on
# critical_parameter: sigma — the standard deviation, which decides whether the mound is a spike or a swell; gaussian_seed pins which mound you get
# triggers: a 0.1 s timer steps execute_step max_raises times; each step draws (x, z) by Box-Muller and raises one MultiMesh instance
# emerges: a diffusion profile in the structure layer — tallest at the region centre, thinning outward, built entirely out of the map's own geometry
# needs: a GridSystem in the scene with cubes already present in the region [required — this artifact places nothing itself]
# relationships: the SOURCE end of the gaussian tier — GaussianPaintSplatter is the same draws landing on a plate (`refusal`), GaussianBlurCircle is the curve used as a kernel instead of a sampler (`sitter`); this one is neither, just the stream
# truth: A distribution has no body. This artifact owns no mesh at all — it borrows the room's floor and writes the bell curve into somebody else's cubes.
#
# ─────────────────────────────────────────────────────────────────────────────
# DNA — DELIBERATELY NOT PROMOTED (2026-08-02). A truthful null.
#
# This artifact renders NOTHING OF ITS OWN. There is not one MeshInstance3D in
# gaussian_random.tscn and not one line here that creates geometry; every visible
# effect is a write into the HOST MAP's structure MultiMesh, via a GridSystem
# looked up from the scene tree. The registry has measured it and agrees:
# aabb_size [0, 0, 0].
#
# So an evidence sweep of this token photographs an empty frame five times,
# scores 0.00%, and reports whatever axis was declared as INERT. That verdict
# would be a fact about the capture harness — which stages one artifact with no
# map around it — and not a fact about the artifact. A fabricated axis here
# would run the whole DNA loop green and publish a number that looks like
# evidence and is not. It is the same class of failure the declaration gate was
# built to catch, arriving from the other direction.
#
# The precondition for ever measuring it is a MAP-level sweep, and the
# precondition for THAT is determinism, which is what gaussian_seed below is
# for. The seed ships now so the measurement is possible later.
#
# SECOND LOOK, 2026-08-03 — CONCURS, and records why, so this is not re-opened a
# third time from scratch.
#
# The brief for the re-examination put the live question well: a bell curve
# artifact that shows only the heights it produced never shows the bell, and the
# corpus already owns a word for that — `evidence`, on 18 artifacts, and in its
# distribution dialect (none | anecdote | sample | census) on the two nearest
# neighbours, galton_board and shannon_workbench. If the premise held, the axis
# would be sitting there ready-made.
#
# The premise does not hold HERE, and that is the whole answer. galton_board
# drops beads down a pegboard and the pile at the bottom is a by-product, so
# there is a real difference between showing the pile and showing the curve. This
# algorithm raises one cube per draw inside an 8x8 region: each cube IS a bin and
# its height IS that bin's count. The mound is not the output of a histogram, it
# is the histogram, at 1:1, and the visitor is standing in it. Adding a drawn
# curve on a plate above the floor would not disclose a hidden step; it would put
# a picture of the room next to the room, and it would spend the artifact's one
# stated truth — that a distribution has no body — to do it.
#
# The axis that IS right, when it can be measured, is `distribution`
# (gaussian | uniform | bimodal | heavy_tail): what SHAPE of chance the floor is
# a record of, defaulting to gaussian, which is the Box-Muller pair below
# unchanged. That axis changes the artifact's argument from "here is the normal
# distribution" to "the shape of chance was a choice somebody made", and it is
# plainly visible — as a spike, a plateau, two mounds or a spire with a long
# skirt — in any still OF A ROOM. In a still of this artifact ALONE it is
# invisible, because there is no room and therefore no floor and therefore no
# mound; every value photographs the same empty frame. So the blocker is not the
# design and never was. It is that the sweep stages one artifact with no map
# around it, and this artifact is only ever visible through a map.
#
# Declining is the cheap half. The standing request, written down here so it is
# not lost: a map-level variant sweep. gaussian_seed exists to make it honest.
# ─────────────────────────────────────────────────────────────────────────────

class_name GaussianDistributionAlgorithm
extends Node3D

# Algorithm properties
var algorithm_name: String = ""
var algorithm_description: String = ""
var grid_reference = null
var max_steps: int = 200

# Gaussian properties
@export var raise_amount: float = 0.05
var total_raises: int = 0
@export var max_raises: int = 200
var center_x: float
var center_z: float
@export var sigma: float = 2.0  # Standard deviation

# 8x8 area bounds in the middle of 11x16 map
@export var region_min_x: int = 2
@export var region_max_x: int = 9
@export var region_min_z: int = 4
@export var region_max_z: int = 11
@export var target_y_level: int = 1

# Node3D properties
@export var auto_start: bool = true
@export var step_delay: float = 0.1
var timer: Timer
var is_running: bool = false

# ── Determinism ──────────────────────────────────────────────────────────────
# This algorithm is made of nothing but random draws, so two runs of the same
# map grow two different mounds and no before/after comparison of a room that
# contains one can mean anything. -1 = do not touch the stream, i.e. today
# exactly: maxf(randf(), 1e-10) off the global generator, a fresh landscape
# every launch, which is right in a room and useless to a measurement.
#
# Any value >= 0 builds a LOCAL generator instead and draws from that — never
# seed() on the global stream, because this artifact shares a map with others
# that draw too, and re-seeding the process to make one mound reproducible
# would silently move every one of them.
@export var gaussian_seed: int = -1
var _rng: RandomNumberGenerator = null

# Box-Muller spare value (persists across calls)
var _has_spare: bool = false
var _spare: float = 0.0

# Position lookup cache (avoids O(n) search per step)
var _position_cache: Dictionary = {}

# Signals
signal algorithm_step_complete()
signal algorithm_finished()

func _init() -> void:
	algorithm_name = "Gaussian Distribution (8x8 Region)"
	algorithm_description = "Bell curve distribution in middle 8x8 area"
	max_steps = max_raises

func _ready() -> void:
	# APPENDED FIRST and draws nothing: _setup_seeded_stream() only constructs
	# (or clears) a generator. The first sample is taken in execute_step, which
	# the deferred start_algorithm below cannot reach before the timer's first
	# 0.1 s tick, so nothing above or below this line shifts.
	_setup_seeded_stream()

	# Create timer for stepping
	timer = Timer.new()
	timer.wait_time = step_delay
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

	# Auto-connect to grid system
	call_deferred("_find_and_connect_grid")

	if auto_start:
		call_deferred("start_algorithm")

func _find_and_connect_grid() -> void:
	# Look for GridSystem in the scene
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		# Try finding by class name
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		set_grid_reference(grid_system)
		print("GaussianDistributionAlgorithm: Connected to grid system")
	else:
		print("GaussianDistributionAlgorithm: WARNING - Could not find GridSystem!")

func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	if node == null:
		return null
	if node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result
	
	return null

func start_algorithm() -> void:
	if not grid_reference:
		print("GaussianDistributionAlgorithm: Cannot start - grid not ready")
		return
	
	setup_initial_state()
	is_running = true
	timer.start()
	print("GaussianDistributionAlgorithm: Algorithm started")

func stop_algorithm() -> void:
	is_running = false
	timer.stop()
	print("GaussianDistributionAlgorithm: Algorithm stopped")

func step_once():
	if not grid_reference:
		return false
	
	var result = execute_step()
	algorithm_step_complete.emit()
	
	if not result:
		stop_algorithm()
		algorithm_finished.emit()
	
	return result

func _on_timer_timeout() -> void:
	if is_running:
		step_once()

func setup_initial_state() -> void:
	# Ensure there are base cubes in the 8x8 region
	if not grid_reference:
		return
		
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Add base cubes in the region at target Y level if they don't exist
	for x in range(region_min_x, region_max_x + 1):
		for z in range(region_min_z, region_max_z + 1):
			if not structure_component.has_cube_at(x, target_y_level, z):
				_place_cube_at(x, target_y_level, z)
	
	# Set center of distribution to middle of 8x8 region
	center_x = (region_min_x + region_max_x) / 2.0
	center_z = (region_min_z + region_max_z) / 2.0
	total_raises = 0
	
	print("GaussianDistribution: Initialized with center at (%f, %f)" % [center_x, center_z])

func execute_step() -> bool:
	if total_raises >= max_raises:
		return false
	
	# Generate Gaussian distributed coordinates
	var rand_x = _gaussian_random(center_x, sigma)
	var rand_z = _gaussian_random(center_z, sigma)
	
	# Clamp to 8x8 region bounds
	var x = int(clamp(rand_x, region_min_x, region_max_x))
	var z = int(clamp(rand_z, region_min_z, region_max_z))
	
	# Raise the cube at this position
	_raise_cube(x, z)
	total_raises += 1
	
	return total_raises < max_raises

# Set grid reference for the algorithm to work with
func set_grid_reference(grid_ref) -> void:
	grid_reference = grid_ref

func _gaussian_random(mean: float, std_dev: float) -> float:
	# Box-Muller transform to generate Gaussian random numbers
	if _has_spare:
		_has_spare = false
		return _spare * std_dev + mean

	_has_spare = true
	# _unit_draw() IS randf() whenever gaussian_seed is -1, which is every room.
	# Same two calls, same order, same count.
	var u := maxf(_unit_draw(), 1e-10)  # Avoid log(0)
	var v := _unit_draw()
	var mag := std_dev * sqrt(-2.0 * log(u))
	_spare = mag * cos(2.0 * PI * v)
	return mag * sin(2.0 * PI * v) + mean

func _raise_cube(x: int, z: int) -> void:
	if not grid_reference:
		return

	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return

	# Find the MultiMesh instance for this cube position
	var multimesh = structure_component.multimesh
	if not multimesh:
		return

	# Find the instance index for this position
	var instance_idx = _find_instance_index(structure_component, x, target_y_level, z)
	if instance_idx >= 0:
		# Get current transform and raise it
		var transform = multimesh.get_instance_transform(instance_idx)
		transform.origin.y += raise_amount
		multimesh.set_instance_transform(instance_idx, transform)

# Place a cube at specific 3D coordinates
func _place_cube_at(_x: int, y: int, z: int) -> void:
	# With MultiMesh, cubes should be pre-generated by the structure
	# This function is kept for compatibility but does nothing
	# Cubes need to exist in the initial structure layout
	pass

# Find the instance index for a given grid position (cached)
func _find_instance_index(structure_component, x: int, y: int, z: int) -> int:
	var target_pos := Vector3i(x, y, z)

	if _position_cache.has(target_pos):
		return _position_cache[target_pos]

	# Build cache on first miss
	if _position_cache.is_empty():
		var cube_positions = structure_component.cube_positions
		for i in range(cube_positions.size()):
			_position_cache[cube_positions[i]] = i

	return _position_cache.get(target_pos, -1)

# Get current region bounds for external access
func get_region_bounds() -> Dictionary:
	return {
		"min_x": region_min_x,
		"max_x": region_max_x,
		"min_z": region_min_z,
		"max_z": region_max_z,
		"center_x": (region_min_x + region_max_x) / 2,
		"center_z": (region_min_z + region_max_z) / 2
	}

# Get algorithm info
func get_algorithm_info() -> Dictionary:
	return {
		"name": algorithm_name,
		"description": algorithm_description,
		"max_steps": max_steps,
		"max_raises": max_raises,
		"current_raises": total_raises,
		"raise_amount": raise_amount,
		"sigma": sigma,
		"center": {"x": center_x, "z": center_z},
		"region_bounds": get_region_bounds()
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("gaussian_seed"):
		gaussian_seed = int(str(config["gaussian_seed"]))
		_setup_seeded_stream()
		# A seed that arrives after the algorithm has already stepped would
		# otherwise pin only the tail of the mound. Start the draw sequence over
		# so a pinned run is pinned from its first sample.
		_has_spare = false
		_spare = 0.0


## Builds the local generator, or leaves it null. Null is the default and the
## room behaviour: _unit_draw() falls straight through to the global randf() this
## file has always used.
func _setup_seeded_stream() -> void:
	if gaussian_seed < 0:
		_rng = null
		return
	_rng = RandomNumberGenerator.new()
	_rng.seed = gaussian_seed


## One uniform draw. Identical to randf() unless seeded.
func _unit_draw() -> float:
	if _rng != null:
		return _rng.randf()
	return randf()
