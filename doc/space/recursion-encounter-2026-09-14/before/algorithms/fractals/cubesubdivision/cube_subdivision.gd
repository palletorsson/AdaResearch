extends Node3D

# Cube Subdivision Fractal - Single Path Recursive
# Starts with one cube, subdivides it into 8, picks ONE of those 8 to subdivide next,
# creating a fractal zoom path through scale. Like diving into one corner repeatedly.

# @identity
# essence: cube -> 8 sub-cubes -> pick one -> repeat. Scale reduction 0.5 per level.
# desire: To be watched as it eats itself — one cube chosen, split open, its children exposed, then one of them chosen next
# critical_parameter: random_corner — when true, every subdivision picks a different child, creating unpredictable growth; when false, it always drills the same corner
# triggers: Each subdivision_interval tick selects and detonates a cube; color shifts per depth generation
# emerges: Multi-scale color clouds from depth-indexed palette — no cube knows its neighbors but the ensemble reads as a fractal
# needs: VR grab-to-subdivide [missing], depth slider [missing]
# relationships: Foundation for menger_sponge (structured removal) and recursive_boolean_cube (Sierpinski pattern)
# truth: To subdivide is to choose — and the fractal is the history of every choice made at every scale.

# ─── STAGE-2 DNA (promoted 2026-08-05) ────────────────────────────────────────
#
#  tick  — how far the record goes. The word and its five rungs are cantor_set's,
#          zeno_staircase's and sierpinski_pyramid's, character for character. The
#          INTEGERS behind them are not, and cannot be: one tick there is a whole
#          generation of a uniform rule, and one tick HERE is a single cube being
#          split, so the ladder is scaled to this rule's own unit — 1, 3, 6, 12,
#          24 steps, giving 8, 22, 43, 85 and 169 cubes.
#  walk  — WHICH cube gets split, which is the same question as "is this fractal a
#          path or a population". This file's header says "Single Path Recursive
#          ... like diving into one corner repeatedly" and its @identity declares
#          critical_parameter: random_corner — and neither random_corner nor
#          fixed_corner_index was ever read: perform_single_subdivision picked
#          randi() % all_cubes.size() unconditionally. Both the header and the
#          identity described `drill`, and the code has only ever run
#          `population`. The knob is now real; the shipped behaviour is the
#          default, so nothing moves.
#
#  MEASURED, NOT ASSUMED (the ladder re-run in Python, all three walks):
#    population  8 / 22 / 43 / 85 / 169 cubes, max depth 1 / 2 / 3 / 4 / 6 — clean
#    spread      same counts, max depth 1 / 2 / 2 / 3 / 3 — a generation front
#    drill       SATURATES ABOVE `fine`. Scale falls 0.45x per level, so 0.45^7 is
#                under 1 cm of the metre cube, and from step 6 onward every new
#                cube is sub-visible: 35 visible cubes at fine, dense AND limit,
#                summed face area 1.777 at all three. The top two rungs of tick
#                exist in code under drill and cannot be photographed. Named here
#                so the next reader does not measure it as an inert axis.
#
#  build_mode and seed_value are NOT axes — they are the capture fixture.
#  build_mode is cantor_set's word for cantor_set's problem: the shipped artifact
#  grows one cube every subdivision_interval seconds, so a still taken at boot
#  holds ONE cube and the whole of `tick` is invisible to it. "instant" lays the
#  finished record out in one frame by the identical rule. seed_value 0 leaves the
#  shipped global randi() call exactly where it was, in the same order; any other
#  value routes the same modulo through a seeded RNG, so five variants of `walk`
#  are five walks over one cloud rather than five different clouds.
# ──────────────────────────────────────────────────────────────────────────────

# Reference to the cube scene to instantiate
const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

const TICK_LEVELS := {"once": 1, "coarse": 3, "fine": 6, "dense": 12, "limit": 24}
const WALKS := ["population", "drill", "spread"]
const BUILD_MODES := ["grow", "instant"]

@export_enum("once", "coarse", "fine", "dense", "limit") var tick: String = "dense"
@export_enum("population", "drill", "spread") var walk: String = "population"
@export_enum("grow", "instant") var build_mode: String = "grow"
@export var seed_value: int = 0

# Subdivision settings
@export var subdivision_interval: float = 0.8  # Time between subdivisions in seconds
@export var max_subdivisions: int = 10  # Maximum number of subdivision iterations
@export var auto_start: bool = true  # Start subdividing automatically
@export var random_corner: bool = true  # Pick a random cube each iteration
@export var fixed_corner_index: int = 7  # Which corner if not random (0-7)
# Corner indices: 0=front-bottom-left, 1=front-bottom-right, 2=front-top-left, 3=front-top-right
#                 4=back-bottom-left,  5=back-bottom-right,  6=back-top-left,  7=back-top-right

# Internal state
var subdivision_count: int = 0
var subdivision_timer: float = 0.0
var is_subdividing: bool = false
var current_target_cube: Node3D = null  # The cube we'll subdivide next
var all_cubes: Array[Node3D] = []  # Track all cubes for visualization
var cube_depths: Dictionary = {}  # Track each cube's generation depth
var _litter: Array[Node3D] = []  # The eight children of the LAST split — what `drill` walks
var _rng := RandomNumberGenerator.new()
var _initial_xform: Transform3D = Transform3D.IDENTITY
var _built: bool = false

# Color palette for iteration levels (10 colors for 10 iterations)
var iteration_colors: Array[Color] = [
	Color(0.9, 0.2, 0.3, 1.0),   # Iteration 0 - Red (initial)
	Color(0.95, 0.5, 0.1, 1.0),  # Iteration 1 - Orange
	Color(0.95, 0.85, 0.2, 1.0), # Iteration 2 - Yellow
	Color(0.3, 0.85, 0.4, 1.0),  # Iteration 3 - Green
	Color(0.2, 0.5, 0.95, 1.0),  # Iteration 4 - Blue
	Color(0.7, 0.3, 0.9, 1.0),   # Iteration 5 - Purple
	Color(0.1, 0.8, 0.8, 1.0),   # Iteration 6 - Cyan
	Color(0.95, 0.4, 0.6, 1.0),  # Iteration 7 - Pink
	Color(0.6, 0.8, 0.2, 1.0),   # Iteration 8 - Lime
	Color(0.4, 0.3, 0.8, 1.0),   # Iteration 9 - Indigo
]


func _ready() -> void:
	print("CubeSubdivision: Ready - Single path recursive mode")

	# random_corner was the @identity's declared critical_parameter and NOTHING read
	# it. It is now the legacy spelling of `walk`, so set_random(false) and a .tscn
	# that flips the flag both reach the corner drill they always meant. The shipped
	# default is true, which leaves `walk` on its own default and changes nothing.
	if not random_corner and walk == "population":
		walk = "drill"
	if seed_value != 0:
		_rng.seed = seed_value

	# Find and color the initial cube
	var initial_cube = _find_initial_cube()
	if initial_cube:
		_initial_xform = initial_cube.transform
		_start_from(initial_cube)
	else:
		push_error("CubeSubdivision: No initial cube found!")
		return
	_built = true


# How many splits this record carries. "dense" SHORT-CIRCUITS to the shipped
# max_subdivisions rather than the table's 12, so a scene or a map that sets its
# own ceiling keeps it — cube_subdivision.tscn sets 12 while the @export default
# is 10, and deriving the rung from the table would silently retune the .tscn.
func _levels() -> int:
	if tick == "dense":
		return max_subdivisions
	return int(TICK_LEVELS.get(tick, max_subdivisions))


func _start_from(cube: Node3D) -> void:
	current_target_cube = cube
	_apply_color_to_cube(cube, iteration_colors[0])
	all_cubes.append(cube)
	cube_depths[cube] = 0  # Initial cube is depth 0
	_litter.clear()
	_litter.append(cube)
	print("CubeSubdivision: Found initial cube, colored red (depth 0)")

	if build_mode == "instant":
		# The fixture. Runs the identical rule the identical number of times, all in
		# this frame, so a still can hold the whole record instead of one cube.
		is_subdividing = false
		for _i in range(_levels()):
			perform_single_subdivision()
	elif auto_start:
		# Start automatic subdivision if enabled
		is_subdividing = true
		print("CubeSubdivision: Auto-subdivision enabled, will run %d iterations" % _levels())


func _process(delta: float) -> void:
	if not is_subdividing:
		return

	# Update timer
	subdivision_timer += delta

	# Check if it's time to subdivide
	if subdivision_timer >= subdivision_interval:
		subdivision_timer = 0.0
		perform_single_subdivision()


func _find_initial_cube() -> Node3D:
	# Look for the InitialCube node or any cube_scene instance
	for child in get_children():
		if child.name == "InitialCube" or child.name == "CubeScene":
			return child
		if child is Node3D and child.has_node("CubeBaseStaticBody3D"):
			return child
	return null


# WHICH cube gets split. "population" returns the shipped line verbatim — the same
# global randi() modulo over the same array in the same order — so the default is
# the walk this file has always taken.
func _pick_target() -> Node3D:
	match walk:
		"drill":
			# Always the same corner of the newest litter: the fractal zoom path the
			# file's own header describes and its code never took.
			if _litter.size() > 0:
				var idx: int = clampi(fixed_corner_index, 0, _litter.size() - 1)
				if is_instance_valid(_litter[idx]) and all_cubes.has(_litter[idx]):
					return _litter[idx]
			return all_cubes[0]
		"spread":
			# The shallowest cube standing: a generation front rather than a path.
			var best: Node3D = all_cubes[0]
			var best_d: int = int(cube_depths.get(best, 0))
			for cube in all_cubes:
				var d: int = int(cube_depths.get(cube, 0))
				if d < best_d:
					best_d = d
					best = cube
			return best
	return all_cubes[_pick_index(all_cubes.size())]


# seed_value 0 is the shipped call, untouched. Anything else routes the same
# modulo through a seeded stream so a sweep photographs one cloud, not five.
func _pick_index(n: int) -> int:
	if seed_value == 0:
		return randi() % n
	return _rng.randi() % n


func perform_single_subdivision() -> void:
	# Check if we've reached the maximum
	if subdivision_count >= _levels():
		print("CubeSubdivision: Reached maximum subdivisions (%d)" % _levels())
		is_subdividing = false
		return

	# Pick a random cube from ALL existing cubes
	if all_cubes.is_empty():
		print("CubeSubdivision: No cubes available")
		is_subdividing = false
		return

	# Clean up invalid cubes first
	all_cubes = all_cubes.filter(func(c): return is_instance_valid(c))

	if all_cubes.is_empty():
		print("CubeSubdivision: No valid cubes")
		is_subdividing = false
		return

	# Pick the next cube the way `walk` says to
	current_target_cube = _pick_target()
	if current_target_cube == null:
		is_subdividing = false
		return
	var picked_depth = cube_depths.get(current_target_cube, -1)

	subdivision_count += 1
	print("CubeSubdivision: Iteration %d - picked a cube of %d by %s (depth %d)" % [subdivision_count, all_cubes.size(), walk, picked_depth])

	# Subdivide the chosen cube
	var new_cubes = subdivide_cube_return_children(current_target_cube)

	if new_cubes.is_empty():
		print("CubeSubdivision: Failed to create sub-cubes")
		is_subdividing = false
		return

	# Count cubes by depth for debug
	var depth_counts = {}
	for cube in all_cubes:
		var d = cube_depths.get(cube, -1)
		depth_counts[d] = depth_counts.get(d, 0) + 1
	print("CubeSubdivision: Iteration %d complete, now have %d cubes. Depths: %s" % [subdivision_count, all_cubes.size(), depth_counts])


func subdivide_cube_return_children(cube: Node3D) -> Array[Node3D]:
	"""Subdivide a cube into 8 smaller cubes, return the array of new cubes"""
	var new_cubes: Array[Node3D] = []

	if not is_instance_valid(cube):
		return new_cubes

	# Use LOCAL position (relative to this node) for consistent behavior
	# whether running standalone or inside a map
	var cube_position = cube.position
	var cube_scale = cube.scale

	# Calculate the new scale (half size, then shrink by 0.9 for visibility gaps)
	var new_scale = cube_scale * 0.5 * 0.9

	# Calculate offset for positioning the 8 new cubes
	var offset = cube_scale.x * 0.25

	# Create 8 new cubes in a 2x2x2 grid pattern
	var positions = [
		Vector3(-offset, -offset, -offset),  # 0: Bottom-left-front
		Vector3(offset, -offset, -offset),   # 1: Bottom-right-front
		Vector3(-offset, offset, -offset),   # 2: Top-left-front
		Vector3(offset, offset, -offset),    # 3: Top-right-front
		Vector3(-offset, -offset, offset),   # 4: Bottom-left-back
		Vector3(offset, -offset, offset),    # 5: Bottom-right-back
		Vector3(-offset, offset, offset),    # 6: Top-left-back
		Vector3(offset, offset, offset)      # 7: Top-right-back
	]

	# Get parent cube's depth and calculate child depth
	var parent_depth = cube_depths.get(cube, 0)
	var child_depth = parent_depth + 1

	# Get color based on child's depth (generation)
	var color_index = child_depth % iteration_colors.size()
	var color = iteration_colors[color_index]

	# Create the 8 new cubes
	_litter.clear()
	for i in range(8):
		var new_cube = CUBE_SCENE.instantiate()

		# Set LOCAL position (relative to parent node)
		new_cube.position = cube_position + positions[i]
		new_cube.scale = new_scale

		# Apply color based on depth
		_apply_color_to_cube(new_cube, color)

		# Add to the scene
		add_child(new_cube)
		all_cubes.append(new_cube)
		new_cubes.append(new_cube)
		_litter.append(new_cube)  # what `drill` reaches into next
		cube_depths[new_cube] = child_depth  # Track this cube's depth

	# Remove the original cube from tracking and scene
	all_cubes.erase(cube)
	cube_depths.erase(cube)
	cube.queue_free()

	return new_cubes


func _apply_color_to_cube(cube: Node3D, color: Color) -> void:
	# Find the mesh instance inside the cube
	var mesh_instance: MeshInstance3D = null
	if cube.has_node("CubeBaseStaticBody3D/CubeBaseMesh"):
		mesh_instance = cube.get_node("CubeBaseStaticBody3D/CubeBaseMesh")

	if mesh_instance:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.4
		material.emission_energy_multiplier = 0.6
		mesh_instance.material_override = material


func _highlight_target_cube(cube: Node3D) -> void:
	# Make the target cube glow brighter to show it's next
	var mesh_instance: MeshInstance3D = null
	if cube.has_node("CubeBaseStaticBody3D/CubeBaseMesh"):
		mesh_instance = cube.get_node("CubeBaseStaticBody3D/CubeBaseMesh")

	if mesh_instance and mesh_instance.material_override:
		var mat = mesh_instance.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 1.5


# Manual control functions
func start_subdivision() -> void:
	is_subdividing = true
	subdivision_timer = 0.0
	print("CubeSubdivision: Started manually")


func stop_subdivision() -> void:
	is_subdividing = false
	print("CubeSubdivision: Stopped manually")


func reset() -> void:
	# Remove all cubes except initial
	for cube in all_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	all_cubes.clear()
	cube_depths.clear()

	subdivision_count = 0
	subdivision_timer = 0.0
	is_subdividing = false
	current_target_cube = null
	print("CubeSubdivision: Reset")


func step() -> void:
	"""Perform a single subdivision step"""
	perform_single_subdivision()


func set_corner(index: int) -> void:
	"""Change which corner gets subdivided (0-7), disables random"""
	random_corner = false
	walk = "drill"
	fixed_corner_index = clamp(index, 0, 7)
	print("CubeSubdivision: Now subdividing corner %d (random disabled)" % fixed_corner_index)


func set_random(enabled: bool) -> void:
	"""Enable or disable random corner selection"""
	random_corner = enabled
	walk = "population" if enabled else "drill"
	print("CubeSubdivision: Random corner selection %s" % ("enabled" if enabled else "disabled"))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# Tear down every cube and start the record again from a fresh InitialCube at the
# transform the scene shipped it at. reset() cannot be reused: it frees the initial
# cube along with the rest and leaves nothing for _find_initial_cube to find.
func _rebuild() -> void:
	for cube in all_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	all_cubes.clear()
	cube_depths.clear()
	_litter.clear()
	subdivision_count = 0
	subdivision_timer = 0.0
	is_subdividing = false
	current_target_cube = null
	if seed_value != 0:
		_rng.seed = seed_value
	var fresh: Node3D = CUBE_SCENE.instantiate() as Node3D
	fresh.name = "InitialCube"
	fresh.transform = _initial_xform
	add_child(fresh)
	_start_from(fresh)


# Guarded twice: a word is taken only when it validates against the code's own list
# AND differs, and _rebuild() fires only after _ready has built once. The body of
# this function was a bare `pass` before this pass, so the 10 existing placements —
# which name no keys — reach no assignment and never rebuild.
func apply_grid_config(config: Dictionary) -> void:
	var dirty: bool = false
	if config.has("tick"):
		var t: String = str(config["tick"]).to_lower()
		if TICK_LEVELS.has(t) and t != tick:
			tick = t
			dirty = true
	if config.has("walk"):
		var w: String = str(config["walk"]).to_lower()
		if WALKS.has(w) and w != walk:
			walk = w
			dirty = true
	if config.has("build_mode"):
		var b: String = str(config["build_mode"]).to_lower()
		if BUILD_MODES.has(b) and b != build_mode:
			build_mode = b
			dirty = true
	if config.has("seed_value"):
		var s: int = int(config["seed_value"])
		if s != seed_value:
			seed_value = s
			dirty = true
	if not _built or not dirty:
		return
	_rebuild()
