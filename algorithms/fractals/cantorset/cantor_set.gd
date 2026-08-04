extends Node3D

# Cantor Set Fractal with Physics
# Creates a vertical Cantor set where each iteration divides bars into thirds,
# removes the middle third, and stacks them using RigidBody3D physics
# Bars fall and stack on top of each other

# @identity
# essence: cantor(bar) = [bar.left_third, bar.right_third], remove middle third, repeat. Measure → 0.
# desire: To watch something disappear — each iteration removes a third, and the bars physically fall into place with RigidBody3D
# critical_parameter: max_iterations — at 5 iterations, each bar is 1/243 of the original, yet the set is still uncountably infinite
# triggers: iteration_interval tick → split all current bars → new bars fall with physics → hue shifts per generation
# emerges: The physical stacking of bars — gravity gives the abstract Cantor set a visceral presence as bars clatter into position
# needs: VR iteration trigger [missing], physics interaction [missing]
# relationships: Foundation for sierpinski_triangle (2D Cantor) and menger_sponge (3D Cantor); demonstrates measure-zero sets
# truth: The Cantor set removes everything and keeps everything — zero length, uncountable points, the paradox made physical.

# Cantor set settings
@export var iteration_interval: float = 2.0  # Time between iterations in seconds
@export var max_iterations: int = 5  # Maximum number of iterations (derived from `tick`)
@export var auto_start: bool = true  # Start generating automatically
@export var initial_bar_length: float = 9.0  # Length of the initial bar
@export var bar_thickness: float = 0.3  # Thickness (height and depth) of bars
@export var vertical_spacing: float = 1.5  # Vertical space between iteration levels

# ─────────────────────────────────────────────────────────────────────
#  STAGE-2 DNA — promoted 2026-08-03 (hand promotion; the runner refused
#  this token for NO TURNABLE KNOBS, which was true of its *categorical*
#  knobs: everything above is a duration or a size.)
#
#  tick     — how many removals the record carries. `max_iterations` was
#             already the @identity's declared critical_parameter and was
#             unreachable, because apply_grid_config's whole body was
#             `pass`. Every placement got five. The word is taken from
#             zeno_staircase character for character: the same ladder of
#             subdivision, named the same way.
#  removal  — what the drawing does with the middle third it deleted.
#             This is the part Zeno has no equivalent for: a staircase
#             SUBDIVIDES, Cantor REMOVES, and until now the removal was
#             invisible because the middle was simply never built.
#
#  build_mode is NOT an axis — it is the fixture. The shipped artifact
#  grows one row every `iteration_interval` seconds and drops each bar
#  with RigidBody3D physics, so at any capture instant there is one bar
#  in freefall and nothing to photograph. "instant" lays the completed
#  ladder out frozen, in one frame, using the identical thirds rule.
#  Default "grow" is the shipped behaviour, line for line.
# ─────────────────────────────────────────────────────────────────────

const TICK_LEVELS := {"once": 1, "coarse": 2, "fine": 3, "dense": 4, "limit": 5}
const REMOVALS := ["gone", "ghost", "scar"]
const BUILD_MODES := ["grow", "instant"]

@export_enum("once", "coarse", "fine", "dense", "limit") var tick: String = "limit"
@export_enum("gone", "ghost", "scar") var removal: String = "gone"
@export_enum("grow", "instant") var build_mode: String = "grow"

# Internal state
var current_iteration: int = 0
var iteration_timer: float = 0.0
var is_generating: bool = false
var current_bars: Array = []  # Track bars from current iteration
var _built: bool = false

func _ready() -> void:
	print("CantorSet: Ready")
	_rebuild()

# How many removals this record carries. Default "limit" = 5, the shipped value.
func _levels() -> int:
	return int(TICK_LEVELS.get(tick, 5))

# Tear down and rebuild. Only ever called from _ready(), reset(), and from
# apply_grid_config when a declared value ACTUALLY changed after the first
# build — an unguarded rebuild here would re-run the whole construction on
# every shipped placement that passes any config key at all.
func _rebuild() -> void:
	for child in get_children():
		if child is RigidBody3D or child is MeshInstance3D:
			child.queue_free()
	current_iteration = 0
	iteration_timer = 0.0
	is_generating = false
	current_bars.clear()
	max_iterations = _levels()
	print("CantorSet: Will create %d iterations" % max_iterations)

	if build_mode == "instant":
		_build_static()
	else:
		create_initial_bar()
		if auto_start:
			is_generating = true
			print("CantorSet: Auto-generation enabled")
	_built = true

func _process(delta: float) -> void:
	if not is_generating:
		return

	# Update timer
	iteration_timer += delta

	# Check if it's time for next iteration
	if iteration_timer >= iteration_interval:
		iteration_timer = 0.0
		perform_iteration()

# Create the initial bar at the top
func create_initial_bar() -> void:
	var bar = create_bar(Vector3(0, vertical_spacing * max_iterations, 0), initial_bar_length)
	current_bars = [bar]
	print("CantorSet: Created initial bar with length %.2f" % initial_bar_length)

# Create a single bar as a RigidBody3D.
# `level` and `frozen` default to the grow-mode behaviour: hue from the live
# iteration counter, body free to fall. The static build passes them explicitly.
func create_bar(position: Vector3, length: float, level: int = -1, frozen: bool = false) -> RigidBody3D:
	# Create RigidBody3D
	var rigid_body = RigidBody3D.new()
	rigid_body.position = position
	rigid_body.freeze = frozen

	# Prevent gravity gun from picking up these objects
	rigid_body.add_to_group("no_gravity_gun")

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(length, bar_thickness, bar_thickness)
	collision_shape.shape = box_shape

	# Create mesh for visualization
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(length, bar_thickness, bar_thickness)
	mesh_instance.mesh = box_mesh

	# Create material with color based on iteration
	var material = StandardMaterial3D.new()
	var hue_level: int = current_iteration if level < 0 else level
	var hue = hue_level / float(maxi(max_iterations, 1))
	material.albedo_color = Color.from_hsv(hue, 0.8, 0.9)
	material.metallic = 0.0
	material.roughness = 1.0
	mesh_instance.material_override = material

	# Assemble the bar
	rigid_body.add_child(collision_shape)
	rigid_body.add_child(mesh_instance)
	add_child(rigid_body)

	return rigid_body

# Perform one Cantor set iteration
func perform_iteration() -> void:
	# Check if we've reached the maximum
	if current_iteration >= max_iterations:
		print("CantorSet: Reached maximum iterations (%d)" % max_iterations)
		is_generating = false
		return

	current_iteration += 1
	print("CantorSet: Starting iteration %d" % current_iteration)

	var new_bars = []
	var removed_middles: Array[Vector2] = []

	# For each bar in the current iteration, create two bars (left and right thirds)
	for bar in current_bars:
		if not is_instance_valid(bar):
			continue

		var bar_position = bar.position
		var bar_length = get_bar_length(bar)

		# Calculate new length (1/3 of original)
		var new_length = bar_length / 3.0

		# Calculate y position for new iteration (stacked below)
		var new_y = vertical_spacing * (max_iterations - current_iteration)

		# Calculate x offsets for left and right thirds
		var offset = bar_length / 3.0

		# Create left third bar
		var left_bar = create_bar(
			Vector3(bar_position.x - offset, new_y, bar_position.z),
			new_length
		)
		new_bars.append(left_bar)

		# Create right third bar
		var right_bar = create_bar(
			Vector3(bar_position.x + offset, new_y, bar_position.z),
			new_length
		)
		new_bars.append(right_bar)

		# The middle third — the thing the rule DELETES. Drawn only when the
		# `removal` axis asks for it; at the default "gone" this list is never used.
		removed_middles.append(Vector2(bar_position.x, new_length))

	_spawn_removed(removed_middles, current_iteration)

	print("CantorSet: Created %d bars for iteration %d" % [new_bars.size(), current_iteration])

	# Update current bars for next iteration
	current_bars = new_bars

# ── The completed ladder, laid out in one frame ──────────────────────
# Same rule as perform_iteration(): a segment of length L becomes two of L/3
# offset by ±L/3, and the L/3 in the middle is deleted. The only differences
# are that every row is placed at once and every body is frozen, so the record
# stands still instead of falling.
func _build_static() -> void:
	var segs: Array[Vector2] = [Vector2(0.0, initial_bar_length)]  # (center_x, length)
	_spawn_row(segs, 0)

	for level in range(1, max_iterations + 1):
		var survivors: Array[Vector2] = []
		var removed: Array[Vector2] = []
		for seg in segs:
			var third: float = seg.y / 3.0
			survivors.append(Vector2(seg.x - third, third))
			survivors.append(Vector2(seg.x + third, third))
			removed.append(Vector2(seg.x, third))
		_spawn_row(survivors, level)
		_spawn_removed(removed, level)
		segs = survivors

	current_iteration = max_iterations
	current_bars = []


# One row of surviving segments at the y of iteration `level`.
func _spawn_row(segs: Array[Vector2], level: int) -> void:
	var y: float = vertical_spacing * float(max_iterations - level)
	for seg in segs:
		create_bar(Vector3(seg.x, y, 0.0), seg.y, level, true)


# The middles the rule threw away. `gone` draws nothing at all, which is what
# this artifact has always done; `ghost` restores them as pale full-thickness
# volumes so each row reads as the whole interval with its holes marked; `scar`
# leaves a thin dark rod where the bar used to be, so the row reads as a comb.
func _spawn_removed(removed: Array[Vector2], level: int) -> void:
	if removal == "gone" or removed.is_empty():
		return
	var y: float = vertical_spacing * float(max_iterations - level)
	for seg in removed:
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		var thin: float = bar_thickness if removal == "ghost" else bar_thickness * 0.22
		box.size = Vector3(seg.y, thin, thin)
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

		mesh_instance.position = Vector3(seg.x, y, 0.0)
		add_child(mesh_instance)


# Get the length of a bar by examining its collision shape
func get_bar_length(bar: RigidBody3D) -> float:
	for child in bar.get_children():
		if child is CollisionShape3D:
			var shape = child.shape
			if shape is BoxShape3D:
				return shape.size.x
	return 0.0

# Manual control functions
func start_generation() -> void:
	is_generating = true
	iteration_timer = 0.0
	print("CantorSet: Started manually")

func stop_generation() -> void:
	is_generating = false
	print("CantorSet: Stopped manually")

func reset() -> void:
	_rebuild()
	# _rebuild honours auto_start; reset() has always left the set stopped.
	is_generating = false

	print("CantorSet: Reset")

# Perform a single iteration step
func step() -> void:
	perform_iteration()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Reads the two declared axes plus the build_mode fixture flag.
##
## GUARDED ON PURPOSE. A value is only taken when it validates AND differs, and
## the rebuild only fires once the first build has happened. A placement that
## passes none of these keys — which is all five of them today — never reaches
## _rebuild() and is byte-identical to before this promotion.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return

	var changed: bool = false

	if config_data.has("tick"):
		var v: String = str(config_data["tick"]).to_lower()
		if TICK_LEVELS.has(v) and v != tick:
			tick = v
			changed = true

	if config_data.has("removal"):
		var r: String = str(config_data["removal"]).to_lower()
		if REMOVALS.has(r) and r != removal:
			removal = r
			changed = true

	if config_data.has("build_mode"):
		var b: String = str(config_data["build_mode"]).to_lower()
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
