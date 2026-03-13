# galton_board.gd
# Galton Board — balls fall through a triangular peg array, accumulate into bins
# Each peg deflects left or right with equal probability (p=0.5)
# After many rows the bin counts form a binomial distribution → Gaussian (CLT)
#
# QFEP: Central Limit Theorem as convergence — many independent binary
# choices accumulate into Gaussian structure. Order from repetition.

extends Node3D

class_name GaltonBoard

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

var _stats_label: Label3D
var _title_label: Label3D
var _bell_curve_mesh: MeshInstance3D
var _control_panel: Node3D

# Peg section vertical range (for detecting when ball exits pegs)
var _peg_area_bottom: float = 0.0
var _bin_floor_y: float = 0.0
var _funnel_top_y: float = 0.0

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")


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

	for row in range(peg_rows):
		var pegs_in_row := row + 1
		var row_width := (pegs_in_row - 1) * peg_spacing
		var y := first_peg_y - row * row_height

		for col in range(pegs_in_row):
			var x := -row_width / 2.0 + col * peg_spacing
			_create_single_peg(Vector3(x, y, 0))


func _create_single_peg(pos: Vector3) -> void:
	var body := StaticBody3D.new()

	# Collision — cylinder spanning board depth
	var col := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = peg_radius
	cyl_shape.height = board_depth * 0.9
	col.shape = cyl_shape
	col.rotation_degrees.x = 90  # Align along Z axis
	body.add_child(col)

	# Mesh
	var mesh_inst := MeshInstance3D.new()
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = peg_radius
	cyl_mesh.bottom_radius = peg_radius
	cyl_mesh.height = board_depth * 0.9
	cyl_mesh.radial_segments = 12
	mesh_inst.mesh = cyl_mesh
	mesh_inst.rotation_degrees.x = 90

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_peg
	mat.metallic = 0.6
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = color_peg * 0.3
	mat.emission_energy_multiplier = 0.2
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

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
	if not _stats_label:
		return

	if _total_dropped == 0:
		_stats_label.text = "n = 0\nDrop balls!"
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

	_stats_label.text = "n = %d\n\nmean = %.2f\nstd = %.2f\n\ntheory:\nmean = %.1f\nstd = %.2f" % [
		_total_dropped, mean, sqrt(variance), theo_mean, theo_std
	]


# ═════════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	# Title
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "GALTON BOARD"
	_title_label.pixel_size = 0.002
	_title_label.font_size = 18
	_title_label.modulate = Color(0.9, 0.9, 0.95)
	_title_label.position = Vector3(0, board_height + bin_height + 0.06, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title_label)

	# Subtitle
	var sub_label := Label3D.new()
	sub_label.name = "SubtitleLabel"
	sub_label.text = "Central Limit Theorem"
	sub_label.pixel_size = 0.0015
	sub_label.font_size = 12
	sub_label.modulate = Color(0.6, 0.6, 0.7)
	sub_label.position = Vector3(0, board_height + bin_height + 0.035, 0)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub_label)

	# Stats panel — right side
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.text = "n = 0\nDrop balls!"
	_stats_label.pixel_size = 0.0012
	_stats_label.font_size = 11
	_stats_label.modulate = Color(0.8, 0.85, 0.9)
	_stats_label.position = Vector3(board_width / 2.0 + 0.08, board_height * 0.5, 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stats_label)

	# Bin number labels
	for i in range(num_bins):
		var x := (_bin_divider_positions[i] + _bin_divider_positions[i + 1]) / 2.0
		var lbl := Label3D.new()
		lbl.text = str(i)
		lbl.pixel_size = 0.001
		lbl.font_size = 8
		lbl.modulate = Color(0.5, 0.5, 0.6)
		lbl.position = Vector3(x, -0.015, board_depth * 0.35)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(lbl)


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.06, board_depth / 2.0 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	# Panel backing
	var panel_back := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.38, 0.08, 0.008)
	panel_back.mesh = panel_mesh
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.06, 0.06, 0.08)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.008
	_control_panel.add_child(panel_back)

	# DROP button
	var drop_btn := PUSH_BUTTON.instantiate()
	drop_btn.name = "DropBtn"
	drop_btn.position = Vector3(-0.12, 0.0, 0)
	drop_btn.scale = Vector3(0.7, 0.7, 0.7)
	_control_panel.add_child(drop_btn)
	_add_button_label(drop_btn, "DROP")

	var drop_area := drop_btn.get_node_or_null("InteractableAreaButton")
	if drop_area:
		drop_area.button_pressed.connect(func(_b): _spawn_ball())

	# AUTO toggle
	var auto_btn := PUSH_BUTTON.instantiate()
	auto_btn.name = "AutoBtn"
	auto_btn.position = Vector3(-0.04, 0.0, 0)
	auto_btn.scale = Vector3(0.7, 0.7, 0.7)
	_control_panel.add_child(auto_btn)
	_add_button_label(auto_btn, "AUTO")

	var auto_area := auto_btn.get_node_or_null("InteractableAreaButton")
	if auto_area:
		auto_area.button_pressed.connect(func(_b): auto_drop = not auto_drop)

	# RESET button
	var reset_btn := PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetBtn"
	reset_btn.position = Vector3(0.04, 0.0, 0)
	reset_btn.scale = Vector3(0.7, 0.7, 0.7)
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")

	var reset_area := reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(func(_b): _reset_board())

	# SPEED button (cycle speed)
	var speed_btn := PUSH_BUTTON.instantiate()
	speed_btn.name = "SpeedBtn"
	speed_btn.position = Vector3(0.12, 0.0, 0)
	speed_btn.scale = Vector3(0.7, 0.7, 0.7)
	_control_panel.add_child(speed_btn)
	_add_button_label(speed_btn, "SPEED")

	var speed_area := speed_btn.get_node_or_null("InteractableAreaButton")
	if speed_area:
		speed_area.button_pressed.connect(func(_b): _cycle_speed())


func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.position = Vector3(0, -0.022, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(lbl)


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

