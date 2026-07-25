# galton_board.gd
# Galton Board — balls fall through a triangular peg array, accumulate into bins
# Each peg deflects left or right with equal probability (p=0.5)
# After many rows the bin counts form a binomial distribution → Gaussian (CLT)
#
# QFEP: Central Limit Theorem as convergence — many independent binary
# choices accumulate into Gaussian structure. Order from repetition.
#
# @identity
# essence: Binomial(n, 0.5) → N(n/2, n/4) as n → ∞ — the Central Limit Theorem
# desire: watch balls cascade through pegs and see the bell curve assemble itself from binary choices
# critical_parameter: peg_rows — more rows means tighter Gaussian convergence; 8 rows gives 9 bins
# triggers: auto_drop spawns balls at balls_per_second rate; peg collisions create the L/R branching
# emerges: the bell curve overlay converges to match the histogram — theory becomes visible fact
# needs: VR push buttons for DROP/AUTO/RESET/SPEED [has]; ball pool recycling [has]
# relationships: contrasts with slot_machine (uniform vs Gaussian); feeds gaussian_random and random_bell_curve
# truth: The bell curve is not imposed — it is the inevitable shape of accumulated independence.

extends Node3D

class_name GaltonBoard

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Housing finish — "rams" (light Braun default) or "terminal" (dark console).
## The whole cabinet derives from HangarKit.finish_palette(), so one word
## re-skins every part consistently instead of 12 hand-typed colours.
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "GB-01"
## When false the board renders WITHOUT its own cabinet housing — for embedding
## the bare board inside another artifact's bay (e.g. galton_friction's harvest).
@export var show_cabinet: bool = true

## Pedestal height. These machines are authored at bench scale but ground
## base-to-floor, which left their keypads at knee height (G5-reach). The
## plinth hangs BELOW the origin, so every coordinate above stays as authored
## and auto-grounding lifts the whole assembly. Set 0.0 for a floor-standing
## build.
@export var plinth_height: float = 0.60

# ── Board Frame ──────────────────────────────────────────────────────────────
@export var board_width: float = 0.5
@export var board_height: float = 0.55
@export var board_depth: float = 0.06

# ── Pegs ─────────────────────────────────────────────────────────────────────
@export var peg_rows: int = 8
@export var peg_radius: float = 0.007
@export var peg_spacing: float = 0.048

# ── Balls ────────────────────────────────────────────────────────────────────
@export var ball_radius: float = 0.009
@export var ball_mass: float = 0.04
@export var ball_bounce: float = 0.3
@export var balls_per_second: float = 2.0
@export var max_active_balls: int = 50

# ── Bins ─────────────────────────────────────────────────────────────────────
@export var bin_height: float = 0.18
@export var num_bins: int = 9  # peg_rows + 1

# ── Colors ───────────────────────────────────────────────────────────────────
@export var color_peg: Color = Color(0.7, 0.75, 0.85)
@export var color_ball: Color = Color(1.0, 0.8, 0.2)
@export var color_bin_bar: Color = Color(0.3, 0.7, 1.0)
@export var color_frame: Color = Color(0.12, 0.12, 0.16)
@export var color_glass: Color = Color(0.7, 0.85, 1.0, 0.12)
@export var color_bell_curve: Color = Color(1.0, 0.4, 0.2, 0.8)

# ── Control ──────────────────────────────────────────────────────────────────
@export var auto_drop: bool = true

# ── Internal state ───────────────────────────────────────────────────────────
var _bin_counts: Array[int] = []
var _total_dropped: int = 0
var _drop_timer: float = 0.0

var _ball_pool: Array[RigidBody3D] = []
var _active_balls: Array[RigidBody3D] = []
var _available_balls: Array[RigidBody3D] = []

var _bin_bar_meshes: Array[MeshInstance3D] = []
var _bin_divider_positions: Array[float] = []
var _bin_sensor_areas: Array[Area3D] = []
var _ball_bin_assigned: Dictionary = {}  # ball instance_id → bin_index

var _stats_tag: Node3D
var _stats_tag_pos: Vector3 = Vector3.ZERO
var _stats_last_text: String = ""
# The info kiosk (2026-07-20 ruling): readout + buttons live in ONE housed
# interface body — no floating stat plates. When the kiosk exists, the stats
# lines mount on its screen; _stats_tag_pos is only the legacy fallback.
var _kiosk_screen: Node3D = null
var _screen_size: Vector2 = Vector2(0.185, 0.40)
var _title_tag: Node3D
var _bell_curve_mesh: MeshInstance3D
var _control_panel: Node3D

# Peg section vertical range (for detecting when ball exits pegs)
var _peg_area_bottom: float = 0.0
var _bin_floor_y: float = 0.0
var _funnel_top_y: float = 0.0



# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	num_bins = peg_rows + 1
	_bin_counts.resize(num_bins)
	_bin_counts.fill(0)

	_calculate_layout()
	_create_back_panel()
	_create_glass_front()
	_create_side_walls()
	_create_floor()
	_create_funnel()
	_create_pegs()
	_create_bin_dividers()
	_create_bin_bars()
	_create_bin_sensors()
	_create_labels()
	_create_vr_controls()
	_init_ball_pool()


func _process(delta: float) -> void:
	# Auto-drop balls
	if auto_drop:
		_drop_timer += delta
		var interval := 1.0 / balls_per_second
		while _drop_timer >= interval:
			_drop_timer -= interval
			_spawn_ball()

	# Check active balls for bin landing
	_check_ball_positions()

	# Update visuals
	_update_bin_bars()
	_update_bell_curve()
	_update_stats()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				auto_drop = not auto_drop
			KEY_R:
				_reset_board()
			KEY_D:
				_spawn_ball()


# ═════════════════════════════════════════════════════════════════════════════
# LAYOUT CALCULATION
# ═════════════════════════════════════════════════════════════════════════════

func _calculate_layout() -> void:
	# Vertical spacing between peg rows (equilateral triangle height)
	var row_height := peg_spacing * 0.866  # sqrt(3)/2

	# Funnel sits at the top
	_funnel_top_y = board_height

	# First peg row starts below funnel
	var first_peg_y := board_height - 0.06
	var last_peg_y := first_peg_y - (peg_rows - 1) * row_height
	_peg_area_bottom = last_peg_y - peg_spacing * 0.5

	# Bin floor is at y=0
	_bin_floor_y = 0.0

	# Calculate bin divider x positions
	_bin_divider_positions.clear()
	var total_bin_width := num_bins * peg_spacing
	var bin_start_x := -total_bin_width / 2.0
	for i in range(num_bins + 1):
		_bin_divider_positions.append(bin_start_x + i * peg_spacing)


# ═════════════════════════════════════════════════════════════════════════════
# FRAME CONSTRUCTION
# ═════════════════════════════════════════════════════════════════════════════

func _create_back_panel() -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "BackPanel"
	var box := BoxMesh.new()
	box.size = Vector3(board_width + 0.01, board_height + bin_height + 0.01, 0.004)
	mesh_inst.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_frame
	mat.metallic = 0.2
	mat.roughness = 0.8
	mesh_inst.material_override = mat

	mesh_inst.position = Vector3(0, (board_height + bin_height) / 2.0, -(board_depth / 2.0) - 0.002)
	add_child(mesh_inst)

	# Also add a StaticBody so balls don't fall through
	var body := StaticBody3D.new()
	body.name = "BackWall"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(board_width + 0.01, board_height + bin_height + 0.01, 0.004)
	col.shape = shape
	body.add_child(col)
	body.position = mesh_inst.position
	add_child(body)


func _create_glass_front() -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "GlassFront"
	var box := BoxMesh.new()
	box.size = Vector3(board_width + 0.01, board_height + bin_height + 0.01, 0.003)
	mesh_inst.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_glass
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.metallic = 0.1
	mat.roughness = 0.1
	mesh_inst.material_override = mat

	mesh_inst.position = Vector3(0, (board_height + bin_height) / 2.0, (board_depth / 2.0) + 0.002)
	add_child(mesh_inst)

	# Front collision wall
	var body := StaticBody3D.new()
	body.name = "FrontWall"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(board_width + 0.01, board_height + bin_height + 0.01, 0.003)
	col.shape = shape
	body.add_child(col)
	body.position = mesh_inst.position
	add_child(body)


func _create_side_walls() -> void:
	for x_sign in [-1, 1]:
		var body := StaticBody3D.new()
		body.name = "SideWall_" + ("L" if x_sign < 0 else "R")

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.006, board_height + bin_height + 0.01, board_depth + 0.01)
		col.shape = shape
		body.add_child(col)

		var mesh_inst := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = shape.size
		mesh_inst.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.15, 0.2)
		mat.metallic = 0.4
		mat.roughness = 0.5
		mesh_inst.material_override = mat
		body.add_child(mesh_inst)

		body.position = Vector3(
			x_sign * (board_width / 2.0 + 0.003),
			(board_height + bin_height) / 2.0,
			0.0
		)
		add_child(body)


func _create_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "Floor"

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(board_width + 0.02, 0.006, board_depth + 0.01)
	col.shape = shape
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_frame
	mat.metallic = 0.3
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	body.position = Vector3(0, -0.003, 0)
	add_child(body)


func _create_funnel() -> void:
	# Two angled walls that guide balls to center drop point
	var funnel_width := board_width * 0.4
	var funnel_height := 0.04
	var funnel_y := board_height - 0.02

	for x_sign in [-1, 1]:
		var body := StaticBody3D.new()
		body.name = "Funnel_" + ("L" if x_sign < 0 else "R")

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(funnel_width, 0.004, board_depth)
		col.shape = shape
		body.add_child(col)

		var mesh_inst := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = shape.size
		mesh_inst.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.2, 0.25)
		mat.metallic = 0.5
		mesh_inst.material_override = mat
		body.add_child(mesh_inst)

		body.position = Vector3(
			x_sign * (funnel_width / 2.0 + 0.01),
			funnel_y,
			0.0
		)
		# Angle the funnel inward
		body.rotation_degrees.z = x_sign * -25.0
		add_child(body)


# ═════════════════════════════════════════════════════════════════════════════
# PEGS
# ═════════════════════════════════════════════════════════════════════════════

func _create_pegs() -> void:
	var row_height := peg_spacing * 0.866
	var first_peg_y := board_height - 0.06

	# Count total pegs for MultiMesh visual
	var total_pegs := 0
	for row in range(peg_rows):
		total_pegs += row + 1

	# Create MultiMesh for peg visuals
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = peg_radius
	cyl_mesh.bottom_radius = peg_radius
	cyl_mesh.height = board_depth * 0.9
	cyl_mesh.radial_segments = 12

	var peg_mat := StandardMaterial3D.new()
	peg_mat.albedo_color = color_peg
	peg_mat.metallic = 0.6
	peg_mat.roughness = 0.3
	peg_mat.emission_enabled = true
	peg_mat.emission = color_peg * 0.3
	peg_mat.emission_energy_multiplier = 0.2
	cyl_mesh.material = peg_mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = total_pegs
	mm.mesh = cyl_mesh

	var peg_idx := 0
	for row in range(peg_rows):
		var pegs_in_row := row + 1
		var row_width := (pegs_in_row - 1) * peg_spacing
		var y := first_peg_y - row * row_height

		for col in range(pegs_in_row):
			var x := -row_width / 2.0 + col * peg_spacing
			var pos := Vector3(x, y, 0)

			# MultiMesh visual transform (rotated 90 on X to align along Z)
			var t := Transform3D()
			t.basis = Basis(Vector3(1, 0, 0), deg_to_rad(90))
			t.origin = pos
			mm.set_instance_transform(peg_idx, t)
			peg_idx += 1

			# Still need individual StaticBody3D for collision
			_create_single_peg_collision(pos)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Pegs_MM"
	mmi.multimesh = mm
	add_child(mmi)


func _create_single_peg_collision(pos: Vector3) -> void:
	# Collision-only StaticBody3D (visuals handled by MultiMesh)
	var body := StaticBody3D.new()

	var col := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = peg_radius
	cyl_shape.height = board_depth * 0.9
	col.shape = cyl_shape
	col.rotation_degrees.x = 90
	body.add_child(col)

	body.position = pos
	add_child(body)


# ═════════════════════════════════════════════════════════════════════════════
# BINS
# ═════════════════════════════════════════════════════════════════════════════

func _create_bin_dividers() -> void:
	var divider_height := bin_height
	for i in range(num_bins + 1):
		var x := _bin_divider_positions[i]

		var body := StaticBody3D.new()
		body.name = "BinDivider_%d" % i

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.003, divider_height, board_depth)
		col.shape = shape
		body.add_child(col)

		var mesh_inst := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = shape.size
		mesh_inst.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.25, 0.3)
		mat.metallic = 0.4
		mesh_inst.material_override = mat
		body.add_child(mesh_inst)

		body.position = Vector3(x, divider_height / 2.0, 0)
		add_child(body)


func _create_bin_bars() -> void:
	_bin_bar_meshes.clear()
	for i in range(num_bins):
		var x := (_bin_divider_positions[i] + _bin_divider_positions[i + 1]) / 2.0

		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "BinBar_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(peg_spacing * 0.85, 0.001, board_depth * 0.6)  # Start tiny
		mesh_inst.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_bin_bar
		mat.emission_enabled = true
		mat.emission = color_bin_bar
		mat.emission_energy_multiplier = 0.4
		mesh_inst.material_override = mat

		mesh_inst.position = Vector3(x, 0.001, 0)
		add_child(mesh_inst)
		_bin_bar_meshes.append(mesh_inst)


func _create_bin_sensors() -> void:
	# Area3D sensors at the bottom of each bin to detect when balls land
	_bin_sensor_areas.clear()
	for i in range(num_bins):
		var x := (_bin_divider_positions[i] + _bin_divider_positions[i + 1]) / 2.0

		var area := Area3D.new()
		area.name = "BinSensor_%d" % i

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		# Sensor spans the full bin width and a decent height above floor
		shape.size = Vector3(peg_spacing * 0.9, bin_height * 0.8, board_depth)
		col.shape = shape
		area.add_child(col)

		area.position = Vector3(x, bin_height * 0.4, 0)
		area.monitoring = true
		area.monitorable = false
		area.collision_layer = 0
		area.collision_mask = 2  # Balls on layer 2

		area.body_entered.connect(_on_bin_body_entered.bind(i))
		add_child(area)
		_bin_sensor_areas.append(area)


func _on_bin_body_entered(body: Node3D, bin_index: int) -> void:
	# A ball's RigidBody entered a bin sensor
	var ball_id := body.get_instance_id()
	if ball_id in _ball_bin_assigned:
		return  # Already counted

	_ball_bin_assigned[ball_id] = bin_index
	_bin_counts[bin_index] += 1
	_total_dropped += 1

	# Recycle ball after a short delay
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(_recycle_ball.bind(body))


# ═════════════════════════════════════════════════════════════════════════════
# BALL POOL
# ═════════════════════════════════════════════════════════════════════════════

func _init_ball_pool() -> void:
	for i in range(max_active_balls):
		var rb := _create_ball_body()
		rb.visible = false
		rb.freeze = true
		add_child(rb)
		_ball_pool.append(rb)
		_available_balls.append(rb)


func _create_ball_body() -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.mass = ball_mass
	rb.gravity_scale = 1.0
	rb.linear_damp = 0.3
	rb.angular_damp = 0.5
	rb.continuous_cd = true  # Important for small fast balls
	rb.collision_layer = 2   # Layer 2 for balls
	rb.collision_mask = 1    # Collide with layer 1 (static geometry)

	var phys_mat := PhysicsMaterial.new()
	phys_mat.bounce = ball_bounce
	phys_mat.friction = 0.15
	rb.physics_material_override = phys_mat

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = ball_radius
	col.shape = shape
	rb.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_inst.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_ball
	mat.emission_enabled = true
	mat.emission = color_ball
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.15
	mat.roughness = 0.4
	mesh_inst.material_override = mat
	rb.add_child(mesh_inst)

	return rb


func _spawn_ball() -> void:
	if _available_balls.is_empty():
		return

	var rb: RigidBody3D = _available_balls.pop_back()
	_active_balls.append(rb)

	# Freeze, reset, position at funnel top with slight random offset
	rb.freeze = true
	rb.linear_velocity = Vector3.ZERO
	rb.angular_velocity = Vector3.ZERO
	rb.global_position = global_position + Vector3(
		randf_range(-0.005, 0.005),  # Tiny horizontal jitter
		_funnel_top_y + 0.02,
		randf_range(-board_depth * 0.2, board_depth * 0.2)
	)
	rb.visible = true

	# Unfreeze deferred so position takes effect
	rb.set_deferred("freeze", false)


func _recycle_ball(rb: RigidBody3D) -> void:
	if not is_instance_valid(rb):
		return

	var ball_id := rb.get_instance_id()
	_ball_bin_assigned.erase(ball_id)

	rb.freeze = true
	rb.visible = false
	rb.linear_velocity = Vector3.ZERO
	rb.angular_velocity = Vector3.ZERO

	if rb in _active_balls:
		_active_balls.erase(rb)
	if rb not in _available_balls:
		_available_balls.append(rb)


func _check_ball_positions() -> void:
	# Safety: recycle any ball that falls too far below
	for rb in _active_balls.duplicate():
		if rb.global_position.y < global_position.y - 0.5:
			_recycle_ball(rb)


# ═════════════════════════════════════════════════════════════════════════════
# VISUAL UPDATES
# ═════════════════════════════════════════════════════════════════════════════

func _update_bin_bars() -> void:
	if _total_dropped == 0:
		return

	var max_count: int = int(_bin_counts.max())
	if max_count == 0:
		return

	for i in range(num_bins):
		var mesh_inst := _bin_bar_meshes[i]
		var fraction := float(_bin_counts[i]) / float(max_count)
		var bar_h := fraction * bin_height * 0.85
		bar_h = max(bar_h, 0.001)

		# Update mesh size
		var box: BoxMesh = mesh_inst.mesh
		box.size = Vector3(peg_spacing * 0.85, bar_h, board_depth * 0.6)

		# Position bar so bottom sits on floor
		var x := (_bin_divider_positions[i] + _bin_divider_positions[i + 1]) / 2.0
		mesh_inst.position = Vector3(x, bar_h / 2.0, 0)

		# Color intensity by count
		var mat: StandardMaterial3D = mesh_inst.material_override
		var intensity := 0.3 + 0.7 * fraction
		mat.emission_energy_multiplier = 0.2 + 0.6 * fraction
		mat.albedo_color = color_bin_bar * intensity


func _update_bell_curve() -> void:
	if _total_dropped < 5:
		return

	if not _bell_curve_mesh:
		_bell_curve_mesh = MeshInstance3D.new()
		_bell_curve_mesh.name = "BellCurveOverlay"
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_bell_curve
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.no_depth_test = true
		_bell_curve_mesh.material_override = mat
		add_child(_bell_curve_mesh)

	# Calculate mean and std from bin counts
	var mean := 0.0
	var variance := 0.0
	for i in range(num_bins):
		mean += float(i) * float(_bin_counts[i])
	mean /= float(_total_dropped)

	for i in range(num_bins):
		var diff := float(i) - mean
		variance += diff * diff * float(_bin_counts[i])
	variance /= float(_total_dropped)
	var std_dev := sqrt(max(variance, 0.01))

	# Draw theoretical Gaussian as line strip over the bins
	var imesh := ImmediateMesh.new()
	imesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var max_count: int = int(_bin_counts.max())
	if max_count == 0:
		imesh.surface_end()
		_bell_curve_mesh.mesh = imesh
		return

	var segments := 60
	var x_start := _bin_divider_positions[0]
	var x_end := _bin_divider_positions[num_bins]
	var x_range := x_end - x_start

	for s in range(segments + 1):
		var t := float(s) / float(segments)
		var x := x_start + t * x_range

		# Map x to bin index space
		var bin_t := t * float(num_bins)
		var z_norm := (bin_t - mean) / std_dev
		var gauss := exp(-0.5 * z_norm * z_norm)

		# Scale to match actual histogram height
		var peak_height := float(max_count) / float(_total_dropped)
		var y := gauss * peak_height * bin_height * 0.85

		imesh.surface_add_vertex(Vector3(x, y, board_depth * 0.35))

	imesh.surface_end()
	_bell_curve_mesh.mesh = imesh


func _update_stats() -> void:
	if _total_dropped == 0:
		_refresh_stats_tag("n = 0\nDrop balls!")
		return

	# Calculate mean and std
	var mean := 0.0
	for i in range(num_bins):
		mean += float(i) * float(_bin_counts[i])
	mean /= float(_total_dropped)

	var variance := 0.0
	for i in range(num_bins):
		var diff := float(i) - mean
		variance += diff * diff * float(_bin_counts[i])
	variance /= float(_total_dropped)

	# Theoretical values for binomial(peg_rows, 0.5)
	var theo_mean := float(peg_rows) / 2.0
	var theo_std := sqrt(float(peg_rows) * 0.25)

	_refresh_stats_tag("n = %d\n\nmean = %.2f\nstd = %.2f\n\ntheory:\nmean = %.1f\nstd = %.2f" % [
		_total_dropped, mean, sqrt(variance), theo_mean, theo_std
	])


# ═════════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	# Title/subtitle only in BARE mode — with the cabinet, its sign-band cap
	# owns the name and these tags would be buried duplicates inside the shell.
	if not show_cabinet:
		_title_tag = BakedText.make_tag(
			"GALTON BOARD", Color(0.9, 0.9, 0.95), 0.045,
			Color(0.08, 0.09, 0.11), true, Color(0.86, 0.40, 0.16))
		if _title_tag:
			_title_tag.name = "TitleTag"
			_title_tag.position = Vector3(0, board_height + bin_height + 0.06, 0)
			add_child(_title_tag)
		var sub_tag: Node3D = BakedText.make_tag(
			"Central Limit Theorem", Color(0.6, 0.6, 0.7), 0.028,
			Color(0.08, 0.09, 0.11), true, Color(0, 0, 0, 0))
		if sub_tag:
			sub_tag.name = "SubtitleTag"
			sub_tag.position = Vector3(0, board_height + bin_height + 0.03, 0)
			add_child(sub_tag)

	# Stats panel — right side. Rebuilt on change via _refresh_stats_tag().
	_stats_tag_pos = Vector3(board_width / 2.0 + 0.12, board_height * 0.5, 0)
	_refresh_stats_tag("n = 0\nDrop balls!")

	# Bin number labels — integrated board tags
	for i in range(num_bins):
		var x := (_bin_divider_positions[i] + _bin_divider_positions[i + 1]) / 2.0
		var bin_tag: Node3D = BakedText.make_tag(
			str(i), Color(0.5, 0.5, 0.6), 0.02,
			Color(0.08, 0.09, 0.11), true, Color(0, 0, 0, 0))
		if bin_tag:
			bin_tag.name = "BinTag_%d" % i
			bin_tag.position = Vector3(x, -0.02, board_depth * 0.35)
			add_child(bin_tag)


## Rebuild the stats readout with fresh text (baked text is fixed at build time,
## so the running readout must be regenerated whenever its content changes — the
## bin counts change as beads fall). Multi-line, so each line is a stacked baked
## tag: one integrated board per line, framed to match the make_tag aesthetic.
func _refresh_stats_tag(text: String) -> void:
	if text == _stats_last_text and _stats_tag != null:
		return
	_stats_last_text = text
	if _stats_tag != null and is_instance_valid(_stats_tag):
		_stats_tag.queue_free()
		_stats_tag = null

	var on_kiosk: bool = _kiosk_screen != null and is_instance_valid(_kiosk_screen)
	var raw := text.split("\n")
	var lines: Array = []
	for l in raw:
		var t := str(l).strip_edges()
		if t != "":
			lines.append(t)

	if on_kiosk:
		# The kit's framed screen: matte bezel, softly-lit face, amber header
		# and green CRT body. A powered instrument, not a printed plate.
		var pal: Dictionary = HangarKit.finish_palette(finish)
		_stats_tag = HangarKit.readout("CENSUS", lines, _screen_size,
			pal["screen"], pal["text"], pal["header"], finish)
		_kiosk_screen.add_child(_stats_tag)
		return

	# Fallback for scenes built before the cabinet exists: keep the old
	# framed board stack so nothing regresses.
	var line_h: float = 0.03
	var pitch: float = line_h * 1.15
	var top: float = (float(lines.size()) - 1.0) * 0.5 * pitch
	_stats_tag = Node3D.new()
	_stats_tag.name = "StatsTag"
	for i in range(lines.size()):
		var line_tag: Node3D = BakedText.make_tag(
			str(lines[i]), Color(0.80, 0.88, 0.95), line_h,
			Color(0.08, 0.09, 0.11), true, Color(0, 0, 0, 0))
		if line_tag:
			line_tag.position = Vector3(0, top - float(i) * pitch, 0)
			_stats_tag.add_child(line_tag)
	_stats_tag.position = _stats_tag_pos
	add_child(_stats_tag)


func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("", [
		[
			{"type": "button", "label": "DROP"},
			{"type": "button", "label": "AUTO"},
		],
		[
			{"type": "button", "label": "RESET"},
			{"type": "button", "label": "SPEED"},
		],
	])
	# ALL-IN-ONE BODY (Palle 2026-07-20, Cyber District refs): the pad mounts
	# INTO the cabinet's service column — a recessed pocket on the appliance
	# face, not a floating stand in front.
	# seated ON the wedge, not cantilevered forward over the bin ledge
	_control_panel.position = Vector3(board_width / 2.0 + 0.18, 0.275, board_depth / 2.0 + 0.052)
	_control_panel.rotation_degrees = Vector3(-15, 0, 0)
	_control_panel.scale = Vector3(0.86, 0.86, 0.86)  # fit within the wedge footprint
	add_child(_control_panel)
	if show_cabinet:
		_create_cabinet()

	var drop_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if drop_btn:
		var area1: Node = drop_btn.get_node_or_null("InteractableAreaButton")
		if area1:
			area1.button_pressed.connect(func(_b): _spawn_ball())
	var auto_btn: Node = _control_panel.find_child("Btn_1", true, false)
	if auto_btn:
		var area2: Node = auto_btn.get_node_or_null("InteractableAreaButton")
		if area2:
			area2.button_pressed.connect(func(_b): auto_drop = not auto_drop)
	var reset_btn: Node = _control_panel.find_child("Btn_2", true, false)
	if reset_btn:
		var area3: Node = reset_btn.get_node_or_null("InteractableAreaButton")
		if area3:
			area3.button_pressed.connect(func(_b): _reset_board())
	var speed_btn: Node = _control_panel.find_child("Btn_3", true, false)
	if speed_btn:
		var area4: Node = speed_btn.get_node_or_null("InteractableAreaButton")
		if area4:
			area4.button_pressed.connect(func(_b): _cycle_speed())


## THE CABINET — the artifact as ONE appliance (the 2026-07-20 interface
## ruling, KitBash3D Cyber District grammar): the pin field is the poster
## window of a vending-machine body. Light two-tone steel shell, a maroon
## service flank, a right-hand service column carrying the inset CENSUS
## screen + the recessed keypad pocket + a ribbed vent grille, a header cap
## wearing the board's name, a base plinth on feet, ember accent stripes.
## Nothing floats; every interface element is a face of the same volume.


func _create_cabinet() -> void:
	var bw: float = board_width
	var hh: float = board_height + bin_height          # window top
	var bd: float = board_depth
	var cw: float = 0.36                               # service column width (sized to host a kit readout)
	var colx: float = bw / 2.0 + cw / 2.0              # column centre x
	var face_z: float = bd / 2.0 + 0.055               # column face plane

	var cab := Node3D.new()
	cab.name = "Cabinet"
	add_child(cab)

	# ── One palette word drives every part (kit finish system) ──────────
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear

	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.62, 0.72, 0.85, 0.055)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.1

	# ── Body: back slab, flank, window frame, service column ───────────
	var body_top: float = hh + 0.10
	var cap_h: float = 0.12
	var total_w: float = bw + cw + 0.12
	var cx: float = (bw / 2.0 + cw) - total_w / 2.0

	cab.add_child(HangarKit.box(Vector3(cx, body_top / 2.0, -bd / 2.0 - 0.03),
		Vector3(total_w, body_top, 0.05), shell))
	cab.add_child(HangarKit.box(Vector3(-bw / 2.0 - 0.06, body_top / 2.0, 0.0),
		Vector3(0.12, body_top, bd + 0.10), maroon))
	cab.add_child(HangarKit.box(Vector3(colx, body_top / 2.0, 0.0),
		Vector3(cw, body_top, bd + 0.10), shell))
	# window glass over the phenomenon (balls must read THROUGH it)
	cab.add_child(HangarKit.box(Vector3(0.0, hh / 2.0, bd / 2.0 + 0.052),
		Vector3(bw, hh, 0.004), glass_mat))
	# frame band above the window
	cab.add_child(HangarKit.box(Vector3(0.0, (hh + body_top) / 2.0, 0.0),
		Vector3(bw, body_top - hh, bd + 0.06), shell))

	# bolt rows down the flank and the column edge — the kit's fastener read
	cab.add_child(HangarKit.bolts(
		Vector3(-bw / 2.0 - 0.06, 0.16, bd / 2.0 + 0.052),
		Vector3(-bw / 2.0 - 0.06, body_top - 0.10, bd / 2.0 + 0.052),
		7, 0.009, steel))
	cab.add_child(HangarKit.bolts(
		Vector3(colx + cw / 2.0 - 0.02, 0.16, face_z - 0.004),
		Vector3(colx + cw / 2.0 - 0.02, body_top - 0.10, face_z - 0.004),
		7, 0.009, steel))

	# ── The READOUT is the kit's, not a hand-built pocket ──────────────
	# Green-on-dark, lit face, matte bezel: it reads as a powered instrument
	# instead of a printed plate. Rebuilt on change by _refresh_stats_tag.
	var scr_w: float = cw - 0.06
	var scr_h: float = 0.30
	var scr_y: float = hh - 0.26
	# A MILLED POCKET behind it. HangarKit.readout() supplies the bezel and the lit
	# face but not the recess, so this screen sat proud of the column — the exact
	# "poster taped on" the seating rule is about. It went unnoticed because the rule
	# only looked for canonical glass and this readout has none.
	cab.add_child(HangarKit.box(
		Vector3(colx, scr_y, face_z + 0.002),
		Vector3(scr_w + 0.030, scr_h + 0.034, 0.014),
		HangarKit.painted_metal(Color(0.07, 0.075, 0.09), ew, 0.35, 0.55)))

	var anchor := Node3D.new()
	anchor.name = "StatsScreen"
	anchor.position = Vector3(colx, scr_y, face_z + 0.012)
	cab.add_child(anchor)
	_kiosk_screen = anchor
	_screen_size = Vector2(scr_w, scr_h)
	var txt := _stats_last_text
	_stats_last_text = ""
	_refresh_stats_tag(txt if txt != "" else "n = 0")

	# ── Controls: wedge shoulder + the Rams three-colour bar ───────────
	var wedge := _make_wedge(cw - 0.03, 0.19, 0.070, 0.020, dark)
	wedge.position = Vector3(colx, 0.26, bd / 2.0 + 0.045)
	cab.add_child(wedge)

	var bar: Node3D = HangarKit.three_color_bar(cw - 0.06, 0.018)
	if bar:
		bar.position = Vector3(colx, scr_y + scr_h / 2.0 + 0.028, face_z + 0.004)  # above the screen, clear of the keypad
		cab.add_child(bar)

	# vent grille (lower column)
	for gi in range(6):
		cab.add_child(HangarKit.box(
			Vector3(colx, 0.07 + float(gi) * 0.024, face_z + 0.002),
			Vector3(cw - 0.06, 0.010, 0.012), dark))

	# ── Cap: sign band over a full-width ember line ────────────────────
	cab.add_child(HangarKit.box(Vector3(cx, body_top + cap_h / 2.0, 0.0),
		Vector3(total_w, cap_h, bd + 0.14), shell))
	cab.add_child(HangarKit.box(Vector3(cx, body_top + 0.005, bd / 2.0 + 0.072),
		Vector3(total_w, 0.007, 0.004), accent))
	cab.add_child(HangarKit.box(Vector3(cx, body_top + cap_h / 2.0, bd / 2.0 + 0.070),
		Vector3(total_w - 0.10, 0.078, 0.012), dark))
	var sign_title: Node3D = BakedText.make_tag(
		"GALTON BOARD", Color(0.93, 0.94, 0.97), 0.030,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title:
		sign_title.position = Vector3(cx, body_top + cap_h / 2.0 + 0.014, bd / 2.0 + 0.078)
		cab.add_child(sign_title)
	var sign_sub: Node3D = BakedText.make_tag(
		"CENTRAL LIMIT THEOREM", Color(0.55, 0.58, 0.66), 0.014,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_sub:
		sign_sub.position = Vector3(cx, body_top + cap_h / 2.0 - 0.020, bd / 2.0 + 0.078)
		cab.add_child(sign_sub)

	# ── Unit number: a machine carries an asset code, not just a title ──
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.13, 0.032),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-bw / 2.0 + 0.10, 0.115, bd / 2.0 + 0.056)
		cab.add_child(code)

	# ── Age: the station props are used objects, not showroom stock ────
	# grime_band is an opaque DIRT SHADOW, not a decorative panel — it
	# belongs at the base, where dirt actually collects (see station_cabinet).
	var gb: MeshInstance3D = HangarKit.grime_band(total_w * 0.9, 0.055,
		bd / 2.0 + 0.058, col_body)
	if gb:
		gb.position.x = cx                   # keep the kit's baked z and y
		cab.add_child(gb)
	# (dust_streaks omitted here: over a WINDOW they read as smears on the
	#  phenomenon. Age belongs on solid faces — grime_band above.)

	# ── Plinth + feet — floor-standing build only (the pedestal below is the
	#    sole base otherwise; two bases stranded a dark slab mid-body). ──
	if plinth_height <= 0.0:
		cab.add_child(HangarKit.box(Vector3(cx, 0.045, 0.0),
			Vector3(total_w, 0.09, bd + 0.16), dark))
		for fx in [-total_w / 2.0 + 0.09, total_w / 2.0 - 0.09]:
			cab.add_child(HangarKit.box(Vector3(cx + fx, 0.012, 0.0),
				Vector3(0.11, 0.024, bd + 0.12), dark))

	# ── Pedestal: raise the controls into the VR reach band ─────────────
	var ped: Node3D = HangarKit.plinth(total_w, bd + 0.18, plinth_height, finish, ew,
		col_accent, unit_code)
	if ped:
		cab.add_child(ped)

func _make_wedge(w: float, h: float, d_bottom: float, d_top: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0: float = -w / 2.0
	var x1: float = w / 2.0
	var y0: float = -h / 2.0
	var y1: float = h / 2.0
	# back face corners (z=0), front bottom (z=d_bottom), front top (z=d_top)
	var bbl := Vector3(x0, y0, 0.0)
	var bbr := Vector3(x1, y0, 0.0)
	var btl := Vector3(x0, y1, 0.0)
	var btr := Vector3(x1, y1, 0.0)
	var fbl := Vector3(x0, y0, d_bottom)
	var fbr := Vector3(x1, y0, d_bottom)
	var ftl := Vector3(x0, y1, d_top)
	var ftr := Vector3(x1, y1, d_top)
	var faces := [
		[fbl, fbr, ftr, ftl],    # slope (front)
		[bbr, bbl, btl, btr],    # back
		[bbl, fbl, ftl, btl],    # left
		[fbr, bbr, btr, ftr],    # right
		[btl, ftl, ftr, btr],    # top
		[bbl, bbr, fbr, fbl],    # bottom
	]
	for f in faces:
		st.add_vertex(f[0]); st.add_vertex(f[1]); st.add_vertex(f[2])
		st.add_vertex(f[0]); st.add_vertex(f[2]); st.add_vertex(f[3])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


func _cycle_speed() -> void:
	if balls_per_second <= 2.0:
		balls_per_second = 5.0
	elif balls_per_second <= 5.0:
		balls_per_second = 10.0
	elif balls_per_second <= 10.0:
		balls_per_second = 20.0
	else:
		balls_per_second = 2.0


# ═════════════════════════════════════════════════════════════════════════════
# RESET
# ═════════════════════════════════════════════════════════════════════════════

func _reset_board() -> void:
	# Recycle all active balls
	for rb in _active_balls.duplicate():
		_recycle_ball(rb)

	# Reset counts
	_bin_counts.fill(0)
	_total_dropped = 0
	_ball_bin_assigned.clear()
	_drop_timer = 0.0

	# Reset bar visuals
	for mesh_inst in _bin_bar_meshes:
		var box: BoxMesh = mesh_inst.mesh
		box.size = Vector3(peg_spacing * 0.85, 0.001, board_depth * 0.6)
		mesh_inst.position.y = 0.001

	# Clear bell curve
	if _bell_curve_mesh:
		_bell_curve_mesh.mesh = null

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
