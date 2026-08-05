extends Node3D

# Menger Sponge Fractal Generator
# Creates a Menger sponge by subdividing cubes into 27 parts (3x3x3)
# and removing the center cube and the 6 face-centered cubes
# Each iteration subdivides all existing cubes

# @identity
# essence: menger(cube) = 20 * menger(sub-cubes at kept positions), remove 7 cross-cubes per iteration. D = log(20)/log(3) ~ 2.727.
# desire: To be walked inside — at 9m initial size and 2 iterations, the sponge has human-scale corridors through its cross-holes
# critical_parameter: max_iterations — at 1 the cross-holes appear; at 2 the sub-holes within holes create a labyrinth; at 3 it would be 8000 cubes
# triggers: subdivision_interval tick → find all cube_scene instances UNDER THIS NODE → subdivide each into 20 kept positions → remove original
# emerges: Corridors from three orthogonal axes — the removed crosses create walkable passages that penetrate the entire structure
# needs: VR walkability [has at 9m scale], iteration control [has, via `tick`]
# relationships: The 3D culmination of the removal fractals: Cantor (1D) → Sierpinski (2D) → Menger (3D); D ~ 2.727, more than a plane
# truth: The Menger sponge has infinite surface area and zero volume — it is a solid made entirely of holes.

# Reference to the cube scene to instantiate
const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

# Menger sponge settings
@export var subdivision_interval: float = 1.0  # Time between subdivisions in seconds
@export var max_iterations: int = 2  # 2-stage Menger sponge (derived from `tick`)
@export var auto_start: bool = true  # Start subdividing automatically

# ─────────────────────────────────────────────────────────────────────
#  STAGE-2 DNA — promoted 2026-08-05 (hand promotion; the runner refused
#  this token for NO TURNABLE KNOBS, which was true of its *categorical*
#  knobs: an interval, a count and a flag, and apply_grid_config's whole
#  body was `pass`, so not one of the three was reachable from a map.)
#
#  tick     — how many removals the sponge carries. The word, and its
#             value names, are cantor_set's and sierpinski_pyramid's,
#             character for character. THE LADDER IS SHORT AND THAT IS
#             THIS ARTIFACT'S OWN ARGUMENT: each Menger tick multiplies
#             the cube count by 20, so once/coarse/fine are 20/400/8000
#             bodies and a fourth rung would be 160,000. Cantor reaches
#             five rungs at 32 bars because its rule multiplies by 2.
#             D = log(20)/log(3) is exactly why this ladder stops early,
#             so only the rungs that actually build are declared.
#  removal  — what the drawing does with the 7 cross-cubes it deleted.
#             cantor_set's word with cantor_set's three values and its
#             ghost colour, 0.16 alpha and 0.22 scar ratio lifted
#             unchanged. sierpinski_pyramid REFUSED this word because
#             its children's volumes interpenetrate and there was no
#             complement to draw; here the 27 sub-cubes partition the
#             parent exactly, so the complement is a real, drawable set.
#
#  build_mode is NOT an axis — it is the fixture, for cantor_set's
#  reason. The shipped artifact subdivides once per `subdivision_interval`
#  second, so a still taken at boot holds ONE 9 m cube and the whole of
#  `tick` is invisible to it. "instant" lays the finished sponge out in
#  _ready() through the identical subdivide call. Default "grow" is the
#  shipped clock, line for line.
#
#  TWO DEFECTS FOUND AND REPAIRED IN THIS PASS — see the registry's
#  `finding`. They change what the nine placements draw, and they are
#  repairs, not axis behaviour:
#    1. `var z = i / 9.0` was a FLOAT divide, so the 20 kept sub-cubes
#       were smeared along z at 1/9-offsets instead of landing on the
#       three lattice layers. The object was not a Menger sponge.
#    2. find_all_cube_scenes() walked get_tree().current_scene — the
#       WHOLE MAP — and matched by node name, so it found GridSystem's
#       $CubeScene template and every other artifact built from
#       cube_scene.tscn, subdivided them and freed the originals.
# ─────────────────────────────────────────────────────────────────────

const TICK_LEVELS := {"once": 1, "coarse": 2, "fine": 3}
const REMOVALS := ["gone", "ghost", "scar"]
const BUILD_MODES := ["grow", "instant"]

@export_enum("once", "coarse", "fine") var tick: String = "coarse"
@export_enum("gone", "ghost", "scar") var removal: String = "gone"
@export_enum("grow", "instant") var build_mode: String = "grow"

# Internal state
var current_iteration: int = 0
var subdivision_timer: float = 0.0
var is_subdividing: bool = false
var _built: bool = false
var _shipped_iterations: int = 2  # max_iterations as authored, read once in _ready
var _seed_cubes: Array = []  # [local_position, scale] of the cubes authored in the .tscn

# Menger sponge pattern: which of the 27 positions to KEEP (not remove)
# We remove 7 cubes: center (1) + 6 face centers
# Positions are indexed 0-26 in a 3x3x3 grid (x + y*3 + z*9)
var keep_positions = [
	# Bottom layer (y=0)
	0, 1, 2,      # Front row
	3, 5,         # Middle row (skip 4 - face center)
	6, 7, 8,      # Back row

	# Middle layer (y=1)
	9, 11,        # Front row (skip 10 - face center)
	15, 17,       # Back row (skip 16 - face center)
	# Skip 12, 13, 14 (middle row contains center 13 and two face centers 12, 14)

	# Top layer (y=2)
	18, 19, 20,   # Front row
	21, 23,       # Middle row (skip 22 - face center)
	24, 25, 26    # Back row
]

func _ready() -> void:
	# Remember the authored cubes so a config-driven rebuild can start over.
	for c in find_all_cube_scenes():
		_seed_cubes.append([c.position, c.scale])
	# Read once, BEFORE any rebuild writes to max_iterations. Reading it inside
	# _levels() would latch: a config setting tick=fine leaves max_iterations at 3,
	# and a later coarse would then short-circuit to 3 instead of the shipped 2.
	_shipped_iterations = max_iterations
	_rebuild()

# How many removals this sponge carries. Default "coarse" SHORT-CIRCUITS to the
# shipped max_iterations rather than to the table's 2, so a scene that overrides
# max_iterations in the inspector is not silently retuned by this promotion.
func _levels() -> int:
	if tick == "coarse":
		return _shipped_iterations
	return int(TICK_LEVELS.get(tick, _shipped_iterations))

# Tear down and build. Only ever reached from _ready(), reset(), and from
# apply_grid_config when a declared value ACTUALLY changed after the first
# build — an unguarded rebuild here would re-run the whole construction on
# every shipped placement that passes any config key at all.
func _rebuild() -> void:
	if _built:
		_clear_built()
		_restore_seed_cubes()
	current_iteration = 0
	subdivision_timer = 0.0
	is_subdividing = false
	max_iterations = _levels()
	print("MengerSponge: Will create %d iterations" % max_iterations)

	if build_mode == "instant":
		_build_instant()
	elif auto_start:
		is_subdividing = true
		print("MengerSponge: Auto-subdivision enabled")
	_built = true

# Free everything this script generated, leaving the .tscn's camera and lights.
func _clear_built() -> void:
	for child in get_children():
		if child is Camera3D or child is Light3D:
			continue
		remove_child(child)
		child.queue_free()

func _restore_seed_cubes() -> void:
	for seed_data in _seed_cubes:
		var c: Node3D = CUBE_SCENE.instantiate()
		add_child(c)
		c.position = seed_data[0]
		c.scale = seed_data[1]

func _process(delta: float) -> void:
	if not is_subdividing:
		return

	# Update timer
	subdivision_timer += delta

	# Check if it's time to subdivide
	if subdivision_timer >= subdivision_interval:
		subdivision_timer = 0.0
		perform_iteration()

# The finished sponge, laid out inside _ready() instead of over max_iterations
# seconds. Identical rule: every call goes through subdivide_cube_menger(), so
# the axis can never be a fact about which builder ran. The list of live cubes is
# carried forward explicitly rather than re-scanned, because queue_free() does not
# take effect until the end of the frame and a re-scan inside one _ready() would
# find the already-subdivided originals again.
func _build_instant() -> void:
	var cubes: Array = find_all_cube_scenes()
	for level in range(max_iterations):
		var next_cubes: Array = []
		for cube in cubes:
			next_cubes.append_array(subdivide_cube_menger(cube))
		cubes = next_cubes
		current_iteration = level + 1
		print("MengerSponge: Iteration %d complete (%d cubes)" % [current_iteration, cubes.size()])
		if cubes.is_empty():
			break

# Perform one Menger sponge iteration
func perform_iteration() -> void:
	# Check if we've reached the maximum
	if current_iteration >= max_iterations:
		print("MengerSponge: Reached maximum iterations (%d)" % max_iterations)
		is_subdividing = false
		return

	current_iteration += 1
	print("MengerSponge: Starting iteration %d" % current_iteration)

	# Find all cube_scene instances belonging to this sponge
	var cubes = find_all_cube_scenes()

	if cubes.is_empty():
		print("MengerSponge: No cubes found to subdivide")
		is_subdividing = false
		return

	print("MengerSponge: Found %d cubes to subdivide" % cubes.size())

	# Subdivide each cube into a Menger pattern
	for cube in cubes:
		subdivide_cube_menger(cube)

	print("MengerSponge: Iteration %d complete" % current_iteration)

# Find all cube_scene instances belonging to THIS sponge.
#
# This used to start at get_tree().current_scene and match on node NAME, which in
# a map meant every cube_scene in the level: GridSystem's own $CubeScene template
# (it is duplicated to build the floor and re-acquired on reload) and every other
# artifact built from the same primitive — cube_subdivision, sierpinski_pyramid,
# static_reference_cube and a dozen more. All of them were subdivided into 20
# pieces and the originals freed. Scoping the walk to `self` is the repair.
func find_all_cube_scenes() -> Array:
	var cubes = []
	_find_cubes_recursive(self, cubes)
	return cubes

# Recursive function to find cube scenes
func _find_cubes_recursive(node: Node, cubes: Array) -> void:
	# Check if this node is a cube_scene (including "InitialCube")
	if node.name == "CubeScene" or node.name.begins_with("CubeScene") or node.name == "InitialCube" or node.scene_file_path == "res://commons/primitives/cubes/cube_scene.tscn":
		cubes.append(node)

	# Recurse into children
	for child in node.get_children():
		_find_cubes_recursive(child, cubes)

# Subdivide a single cube into the Menger pattern. Returns the sub-cubes it made,
# so the instant build can carry the frontier forward without re-scanning.
func subdivide_cube_menger(cube: Node3D) -> Array:
	var created: Array = []
	if not is_instance_valid(cube):
		return created

	# Check if cube is in the tree before accessing global_position
	if not cube.is_inside_tree():
		print("MengerSponge: Cube not in tree, skipping")
		return created

	# Get the cube's current transform
	var cube_position = cube.global_position
	var cube_scale = cube.scale

	# Calculate the new scale (1/3 of original)
	var new_scale = cube_scale / 3.0

	# Calculate offset for positioning (1/3 of original size)
	var offset = cube_scale.x / 3.0

	# Get the parent of the cube
	var parent = cube.get_parent()
	if not parent:
		parent = self

	# Create cubes in a 3x3x3 grid, but only at the positions we want to keep
	for i in range(27):
		# Calculate 3D position from 1D index. z WAS `i / 9.0` — a float divide,
		# which handed back 0, 1/9, 2/9 … 26/9 instead of the three lattice layers
		# 0, 1, 2 and smeared the sponge along z. Integer division is the rule the
		# keep_positions table was written against.
		var x: int = i % 3
		var y: int = (i / 3) % 3
		var z: int = i / 9

		# Calculate offset from center (-1, 0, or 1 in each dimension)
		var pos_offset = Vector3(
			(x - 1) * offset,
			(y - 1) * offset,
			(z - 1) * offset
		)

		if i not in keep_positions:
			# The cross-cube the rule DELETES. Drawn only when `removal` asks for
			# it; at the shipped "gone" this branch returns immediately.
			_spawn_removed(parent, cube_position + pos_offset, offset)
			continue

		# Create new cube
		var new_cube = CUBE_SCENE.instantiate()
		new_cube.scale = new_scale

		# Add to the scene first
		parent.add_child(new_cube)

		# Then set position after it's in the tree
		new_cube.global_position = cube_position + pos_offset

		created.append(new_cube)

	# Remove the original cube. remove_child() first so it cannot be found again
	# by a scan inside the same frame; queue_free() alone leaves it in the tree
	# until the end of the frame.
	parent.remove_child(cube)
	cube.queue_free()
	return created

# The seven cross-cubes the rule threw away. `gone` draws nothing at all, which is
# what this artifact has always done — the removed positions were simply never
# built; `ghost` restores each as a pale full-size volume, so the sponge reads as
# the whole cube with its holes marked and the eye can watch the volume leave;
# `scar` leaves a small dark core at 22 percent of the cell where the sub-cube used
# to be, so the holes read as a lattice of markers rather than as empty air. The
# colour, the 0.16 alpha, the unshaded flag and the 0.22 ratio are cantor_set's,
# unchanged, so the 1D and 3D removal fractals photograph alike.
func _spawn_removed(parent: Node, world_position: Vector3, cell: float) -> void:
	if removal == "gone":
		return
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "RemovedCube"
	var box: BoxMesh = BoxMesh.new()
	var thin: float = cell if removal == "ghost" else cell * 0.22
	box.size = Vector3(thin, thin, thin)
	mesh_instance.mesh = box

	var material: StandardMaterial3D = StandardMaterial3D.new()
	if removal == "ghost":
		material.albedo_color = Color(0.86, 0.88, 0.96, 0.16)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		material.albedo_color = Color(0.09, 0.09, 0.11)
		material.metallic = 0.0
		material.roughness = 1.0
	mesh_instance.material_override = material

	parent.add_child(mesh_instance)
	mesh_instance.global_position = world_position

# Manual control functions
func start_subdivision() -> void:
	is_subdividing = true
	subdivision_timer = 0.0
	print("MengerSponge: Started manually")

func stop_subdivision() -> void:
	is_subdividing = false
	print("MengerSponge: Stopped manually")

func reset() -> void:
	_rebuild()
	# _rebuild honours auto_start; reset() has always left the sponge stopped.
	is_subdividing = false
	print("MengerSponge: Reset")

# Perform a single iteration step
func step() -> void:
	perform_iteration()


## Reads the two declared axes plus the build_mode fixture flag.
##
## GUARDED ON PURPOSE. A value is only taken when it validates AND differs, and
## the rebuild only fires once the first build has happened. All nine placements
## carry the bare token with no config keys, so none of them reaches a rebuild.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	var changed: bool = false

	if config.has("tick"):
		var v: String = str(config["tick"]).to_lower()
		if TICK_LEVELS.has(v) and v != tick:
			tick = v
			changed = true

	if config.has("removal"):
		var r: String = str(config["removal"]).to_lower()
		if REMOVALS.has(r) and r != removal:
			removal = r
			changed = true

	if config.has("build_mode"):
		var b: String = str(config["build_mode"]).to_lower()
		if BUILD_MODES.has(b) and b != build_mode:
			build_mode = b
			changed = true

	if not changed:
		return
	# Before the first build there is nothing to tear down — _ready() will pick
	# the new values up when it runs.
	if not _built:
		return
	_rebuild()
