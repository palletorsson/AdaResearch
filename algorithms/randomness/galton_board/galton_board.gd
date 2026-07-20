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
	# Title — integrated board tag
	_title_tag = BakedText.make_tag(
		"GALTON BOARD", Color(0.9, 0.9, 0.95), 0.045,
		Color(0.08, 0.09, 0.11), true, Color(0.86, 0.40, 0.16))
	if _title_tag:
		_title_tag.name = "TitleTag"
		_title_tag.position = Vector3(0, board_height + bin_height + 0.06, 0)
		add_child(_title_tag)

	# Subtitle — integrated board tag
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
	var lines := text.split("\n")
	var line_h: float = 0.021 if on_kiosk else 0.03
	var pitch: float = line_h * 1.15
	var count: int = lines.size()
	var top: float = (float(count) - 1.0) * 0.5 * pitch

	_stats_tag = Node3D.new()
	_stats_tag.name = "StatsTag"
	for i in range(count):
		var line := str(lines[i]).strip_edges()
		if line == "":
			continue
		# Each non-empty line becomes an integrated board tag (make_tag). On
		# the kiosk the lines sit INSIDE the recessed screen (no per-line
		# backing — the glass is the backing); floating fallback keeps the
		# old framed look for scenes built before the kiosk exists.
		var line_tag: Node3D = BakedText.make_tag(
			line, Color(0.80, 0.88, 0.95), line_h,
			Color(0.04, 0.05, 0.08) if on_kiosk else Color(0.08, 0.09, 0.11),
			not on_kiosk, Color(0, 0, 0, 0))
		if line_tag:
			line_tag.position = Vector3(0, top - float(i) * pitch, 0)
			_stats_tag.add_child(line_tag)
	if on_kiosk:
		_kiosk_screen.add_child(_stats_tag)
	else:
		_stats_tag.position = _stats_tag_pos
		add_child(_stats_tag)


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("GALTON BOARD", [
		[
			{"type": "button", "label": "DROP"},
			{"type": "button", "label": "AUTO"},
		],
		[
			{"type": "button", "label": "RESET"},
			{"type": "button", "label": "SPEED"},
		],
	])
	_control_panel.position = Vector3(0, -0.06, board_depth / 2.0 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	_create_kiosk()


## The info kiosk — the 2026-07-20 interface ruling made body: the running
## census (n / mean / std / theory) and the button pad become ONE housed
## terminal at the board's front, sci-fi street-kiosk grammar (dark metal
## housing, recessed bezel screen, stencil header, ember accent stripe —
## the station family's terminal finish). The button pad keeps its exact
## VR position; the kiosk builds the body AROUND it and raises the screen
## above, so nothing floats.
func _create_kiosk() -> void:
	var kiosk := Node3D.new()
	kiosk.name = "InfoKiosk"
	var panel_z: float = board_depth / 2.0 + 0.15
	kiosk.position = Vector3(0.0, 0.0, panel_z)
	add_child(kiosk)

	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.10, 0.11, 0.14)
	metal.roughness = 0.55
	metal.metallic = 0.35
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = Color(0.055, 0.06, 0.075)
	bezel_mat.roughness = 0.4
	bezel_mat.metallic = 0.5
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.04, 0.05, 0.08)
	glass_mat.roughness = 0.15
	glass_mat.metallic = 0.1
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.08, 0.12)
	glass_mat.emission_energy_multiplier = 0.6
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.86, 0.30, 0.10)
	accent_mat.emission_enabled = true
	accent_mat.emission = Color(0.86, 0.30, 0.10)
	accent_mat.emission_energy_multiplier = 2.2

	# Slim head: the census must never upstage the bins — the board's payoff
	# stays visible past the kiosk's shoulders, and the full 2x2 button pad
	# clears the screen's lower housing edge.
	var kw: float = 0.30            # kiosk width
	var pedestal_h: float = 0.14    # column under the button pad
	var screen_w: float = kw - 0.05
	var screen_h: float = 0.22
	var screen_base_y: float = 0.15 # bottom of screen housing (above the pad)
	var tilt := deg_to_rad(-12.0)

	# ── pedestal: the column the button pad rests on ──
	var pedestal := MeshInstance3D.new()
	var ped_mesh := BoxMesh.new()
	ped_mesh.size = Vector3(kw, pedestal_h, 0.16)
	pedestal.mesh = ped_mesh
	pedestal.material_override = metal
	pedestal.position = Vector3(0.0, -0.06 - pedestal_h * 0.5 - 0.02, 0.0)
	kiosk.add_child(pedestal)

	# ── spine: connects pedestal to the screen head, hides the gap ──
	var spine := MeshInstance3D.new()
	var spine_mesh := BoxMesh.new()
	spine_mesh.size = Vector3(kw * 0.55, screen_base_y + 0.20, 0.05)
	spine.mesh = spine_mesh
	spine.material_override = metal
	spine.position = Vector3(0.0, -0.02 + (screen_base_y + 0.20) * 0.5 - 0.10, -0.055)
	kiosk.add_child(spine)

	# ── screen head: housing + bezel + glass, tilted like the pad ──
	var head := Node3D.new()
	head.name = "ScreenHead"
	head.position = Vector3(0.0, screen_base_y + screen_h * 0.5, -0.03)
	head.rotation.x = tilt
	kiosk.add_child(head)

	var housing := MeshInstance3D.new()
	var housing_mesh := BoxMesh.new()
	housing_mesh.size = Vector3(kw, screen_h + 0.07, 0.045)
	housing.mesh = housing_mesh
	housing.material_override = metal
	housing.position = Vector3(0.0, 0.0, -0.012)
	head.add_child(housing)

	var bezel := MeshInstance3D.new()
	var bezel_mesh := BoxMesh.new()
	bezel_mesh.size = Vector3(screen_w + 0.02, screen_h + 0.02, 0.018)
	bezel.mesh = bezel_mesh
	bezel.material_override = bezel_mat
	bezel.position = Vector3(0.0, -0.008, 0.008)
	head.add_child(bezel)

	var glass := MeshInstance3D.new()
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(screen_w, screen_h, 0.006)
	glass.mesh = glass_mesh
	glass.material_override = glass_mat
	glass.position = Vector3(0.0, -0.008, 0.016)
	head.add_child(glass)

	# ── header: stencil title + ember accent stripe (terminal finish) ──
	var header_tag: Node3D = BakedText.make_tag(
		"CENSUS", Color(0.92, 0.93, 0.97), 0.028,
		Color(0.055, 0.06, 0.075), true, Color(0.86, 0.30, 0.10))
	if header_tag:
		header_tag.name = "KioskHeader"
		header_tag.position = Vector3(0.0, screen_h * 0.5 + 0.018, 0.024)
		head.add_child(header_tag)
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(screen_w + 0.02, 0.006, 0.004)
	stripe.mesh = stripe_mesh
	stripe.material_override = accent_mat
	stripe.position = Vector3(0.0, screen_h * 0.5 - 0.002, 0.022)
	head.add_child(stripe)

	# ── the stats mount point, just in front of the glass ──
	var screen_anchor := Node3D.new()
	screen_anchor.name = "StatsScreen"
	screen_anchor.position = Vector3(0.0, -0.02, 0.022)
	head.add_child(screen_anchor)
	_kiosk_screen = screen_anchor
	# re-home an already-built stats stack onto the screen
	if _stats_tag != null and is_instance_valid(_stats_tag):
		var txt := _stats_last_text
		_stats_last_text = ""
		_refresh_stats_tag(txt)

	var drop_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if drop_btn:
		var area: Node = drop_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _spawn_ball())

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
