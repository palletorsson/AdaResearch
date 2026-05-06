# monte_carlo_dartboard.gd
# Monte Carlo Dart Board — throw darts to estimate π
# A square board with inscribed circle. Darts that land inside the circle
# vs total darts gives ratio ≈ π/4. Live counter shows π estimate improving.
#
# QFEP: Computation through accumulation — random sampling converges to truth.
#
# @identity
# essence: π ≈ 4 · (points inside circle / total points) — Monte Carlo integration
# desire: throw darts at a board and watch π emerge from chaos — green inside, red outside, gold answer
# critical_parameter: max_darts — more darts means tighter convergence; error scales as 1/sqrt(n)
# triggers: _throw_dart() samples uniform (rx, ry) in [0,1]², tests dx²+dy² <= 0.25
# emerges: the π estimate converges — randomness computes a transcendental number without algebra
# needs: VR push buttons for THROW/AUTO/RESET [has]; dart visual markers [has]
# relationships: contrasts with galton_board (integration vs distribution); feeds understanding of random sampling
# truth: Randomness is not the enemy of precision — given enough samples, it converges to any truth.

extends Node3D

class_name MonteCarloDartboard

# ── Board ────────────────────────────────────────────────────────────────────
@export var board_size: float = 0.6
@export var board_thickness: float = 0.03
@export var board_height: float = 1.3  # Height off ground (eye level)

# ── Darts ────────────────────────────────────────────────────────────────────
@export var dart_radius: float = 0.005
@export var dart_length: float = 0.08
@export var max_darts: int = 500
@export var auto_throw: bool = true
@export var darts_per_second: float = 3.0

# ── Colors ───────────────────────────────────────────────────────────────────
@export var color_board: Color = Color(0.15, 0.15, 0.18)
@export var color_circle: Color = Color(0.1, 0.15, 0.35)
@export var color_inside: Color = Color(0.2, 0.9, 0.3)   # Green — inside circle
@export var color_outside: Color = Color(0.9, 0.25, 0.2)  # Red — outside circle
@export var color_pi: Color = Color(1.0, 0.85, 0.2)       # Gold for π display

# ── Internal ─────────────────────────────────────────────────────────────────
var _inside_count: int = 0
var _total_count: int = 0
var _throw_timer: float = 0.0
var _dart_meshes: Array[MeshInstance3D] = []

var _pi_label: Label3D
var _stats_label: Label3D
var _accuracy_label: Label3D
var _circle_mesh: MeshInstance3D



# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_create_board()
	_create_circle_overlay()
	_create_labels()
	_create_vr_controls()


func _process(delta: float) -> void:
	if auto_throw and _total_count < max_darts:
		_throw_timer += delta
		var interval := 1.0 / darts_per_second
		while _throw_timer >= interval and _total_count < max_darts:
			_throw_timer -= interval
			_throw_dart()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				auto_throw = not auto_throw
			KEY_D:
				_throw_dart()
			KEY_R:
				_reset()


# ═════════════════════════════════════════════════════════════════════════════
# BOARD
# ═════════════════════════════════════════════════════════════════════════════

func _create_board() -> void:
	# Board backing — a square
	var body := StaticBody3D.new()
	body.name = "Board"

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(board_size, board_size, board_thickness)
	col.shape = shape
	body.add_child(col)

	# Board face mesh
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(board_size, board_size, board_thickness)
	mesh.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_board
	mat.metallic = 0.1
	mat.roughness = 0.8
	mesh.material_override = mat
	body.add_child(mesh)

	# Position: vertical, at board_height
	body.position = Vector3(0, board_height, 0)
	add_child(body)

	# Frame around the board
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.3, 0.25, 0.18)
	frame_mat.metallic = 0.3

	var frame_width := 0.015
	var sides := [
		[Vector3(0, board_size / 2.0 + frame_width / 2.0, 0), Vector3(board_size + frame_width * 2, frame_width, board_thickness + 0.005)],
		[Vector3(0, -(board_size / 2.0 + frame_width / 2.0), 0), Vector3(board_size + frame_width * 2, frame_width, board_thickness + 0.005)],
		[Vector3(board_size / 2.0 + frame_width / 2.0, 0, 0), Vector3(frame_width, board_size, board_thickness + 0.005)],
		[Vector3(-(board_size / 2.0 + frame_width / 2.0), 0, 0), Vector3(frame_width, board_size, board_thickness + 0.005)],
	]

	for s in sides:
		var frame := MeshInstance3D.new()
		var frame_box := BoxMesh.new()
		frame_box.size = s[1]
		frame.mesh = frame_box
		frame.material_override = frame_mat
		frame.position = s[0] + Vector3(0, board_height, 0)
		add_child(frame)

	# Corner labels: (0,0) → (1,1) coordinate display
	var corner_positions := [
		[Vector3(-board_size / 2.0 - 0.03, board_height - board_size / 2.0, board_thickness / 2.0 + 0.01), "(0,0)"],
		[Vector3(board_size / 2.0 + 0.03, board_height + board_size / 2.0, board_thickness / 2.0 + 0.01), "(1,1)"],
	]
	for cp in corner_positions:
		var lbl := Label3D.new()
		lbl.text = cp[1]
		lbl.pixel_size = 0.0008
		lbl.font_size = 8
		lbl.modulate = Color(0.5, 0.5, 0.55)
		lbl.position = cp[0]
		add_child(lbl)


func _create_circle_overlay() -> void:
	# Draw the inscribed circle using ImmediateMesh (line loop)
	_circle_mesh = MeshInstance3D.new()
	_circle_mesh.name = "CircleOverlay"

	var imesh := ImmediateMesh.new()
	var segments := 64
	var radius := board_size / 2.0

	imesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(segments + 1):
		var angle := float(i) / float(segments) * TAU
		var x := cos(angle) * radius
		var y := sin(angle) * radius
		imesh.surface_add_vertex(Vector3(x, y, 0))
	imesh.surface_end()

	_circle_mesh.mesh = imesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.6, 1.0, 0.6)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	_circle_mesh.material_override = mat

	_circle_mesh.position = Vector3(0, board_height, board_thickness / 2.0 + 0.002)
	add_child(_circle_mesh)

	# Also draw a faint filled circle for reference
	var fill := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.001
	disc.radial_segments = 48
	fill.mesh = disc
	fill.rotation_degrees.x = 90

	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = Color(color_circle.r, color_circle.g, color_circle.b, 0.15)
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fill.material_override = fill_mat

	fill.position = Vector3(0, board_height, board_thickness / 2.0 + 0.001)
	add_child(fill)


# ═════════════════════════════════════════════════════════════════════════════
# DART THROWING
# ═════════════════════════════════════════════════════════════════════════════

func _throw_dart() -> void:
	if _total_count >= max_darts:
		return

	# Random point in unit square [0,1] × [0,1], mapped to board
	var rx := randf()
	var ry := randf()

	# Check if inside inscribed circle (center 0.5, 0.5, radius 0.5)
	var dx := rx - 0.5
	var dy := ry - 0.5
	var inside := (dx * dx + dy * dy) <= 0.25  # radius^2 = 0.25

	_total_count += 1
	if inside:
		_inside_count += 1

	# Map to board coordinates
	var board_x := (rx - 0.5) * board_size
	var board_y := (ry - 0.5) * board_size
	var dart_z := board_thickness / 2.0 + 0.003

	# Create dart marker (small sphere)
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = dart_radius
	sphere.height = dart_radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	marker.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_inside if inside else color_outside
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = mat

	marker.position = Vector3(board_x, board_height + board_y, dart_z)
	add_child(marker)
	_dart_meshes.append(marker)

	# Recycle oldest darts if over visual limit
	if _dart_meshes.size() > 300:
		var old: MeshInstance3D = _dart_meshes.pop_front() as MeshInstance3D
		if old:
			old.queue_free()

	_update_display()


# ═════════════════════════════════════════════════════════════════════════════
# DISPLAY
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	var label_z := board_thickness / 2.0 + 0.01

	# Title
	var title := Label3D.new()
	title.text = "MONTE CARLO"
	title.pixel_size = 0.002
	title.font_size = 18
	title.modulate = Color(0.9, 0.9, 0.95)
	title.position = Vector3(0, board_height + board_size / 2.0 + 0.08, label_z)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var sub := Label3D.new()
	sub.text = "Estimating π with random darts"
	sub.pixel_size = 0.0013
	sub.font_size = 11
	sub.modulate = Color(0.6, 0.6, 0.7)
	sub.position = Vector3(0, board_height + board_size / 2.0 + 0.05, label_z)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# Big π estimate
	_pi_label = Label3D.new()
	_pi_label.name = "PiLabel"
	_pi_label.text = "π ≈ ?"
	_pi_label.pixel_size = 0.003
	_pi_label.font_size = 32
	_pi_label.modulate = color_pi
	_pi_label.position = Vector3(board_size / 2.0 + 0.15, board_height + 0.1, label_z)
	_pi_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_pi_label)

	# Stats
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.text = "darts: 0\ninside: 0\noutside: 0"
	_stats_label.pixel_size = 0.001
	_stats_label.font_size = 10
	_stats_label.modulate = Color(0.75, 0.75, 0.8)
	_stats_label.position = Vector3(board_size / 2.0 + 0.15, board_height - 0.05, label_z)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stats_label)

	# Accuracy
	_accuracy_label = Label3D.new()
	_accuracy_label.name = "AccuracyLabel"
	_accuracy_label.text = ""
	_accuracy_label.pixel_size = 0.001
	_accuracy_label.font_size = 10
	_accuracy_label.modulate = Color(0.6, 0.8, 0.6)
	_accuracy_label.position = Vector3(board_size / 2.0 + 0.15, board_height - 0.15, label_z)
	_accuracy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_accuracy_label)

	# Formula explanation below board
	var formula := Label3D.new()
	formula.text = "π/4 = area(circle) / area(square)\nπ ≈ 4 × (darts inside circle / total darts)"
	formula.pixel_size = 0.001
	formula.font_size = 10
	formula.modulate = Color(0.55, 0.55, 0.6)
	formula.position = Vector3(0, board_height - board_size / 2.0 - 0.06, label_z)
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(formula)


func _update_display() -> void:
	if _total_count == 0:
		return

	var pi_estimate: float = 4.0 * float(_inside_count) / float(_total_count)
	var error: float = absf(pi_estimate - PI)
	var error_pct: float = error / PI * 100.0

	_pi_label.text = "π ≈ %.6f" % pi_estimate

	_stats_label.text = "darts: %d\ninside: %d\noutside: %d\nratio: %.4f" % [
		_total_count, _inside_count, _total_count - _inside_count,
		float(_inside_count) / float(_total_count)
	]

	_accuracy_label.text = "actual π: %.6f\nerror: %.6f (%.2f%%)" % [PI, error, error_pct]

	# Color the π label by accuracy
	if error_pct < 1.0:
		_pi_label.modulate = Color(0.3, 1.0, 0.3)  # Green — excellent
	elif error_pct < 5.0:
		_pi_label.modulate = color_pi  # Gold — good
	else:
		_pi_label.modulate = Color(1.0, 0.5, 0.3)  # Orange — getting there


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("DARTBOARD", [
		[
			{"type": "button", "label": "THROW"},
			{"type": "button", "label": "AUTO"},
			{"type": "button", "label": "RESET"},
		],
	])
	panel.position = Vector3(0, board_height - board_size / 2.0 - 0.18, 0.12)
	panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(panel)

	# THROW button (Btn_0)
	var throw_btn: Node = panel.find_child("Btn_0", true, false)
	if throw_btn:
		var area = throw_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _throw_dart())

	# AUTO button (Btn_1)
	var auto_btn: Node = panel.find_child("Btn_1", true, false)
	if auto_btn:
		var area = auto_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): auto_throw = not auto_throw)

	# RESET button (Btn_2)
	var reset_btn: Node = panel.find_child("Btn_2", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset())


func _reset() -> void:
	_inside_count = 0
	_total_count = 0
	_throw_timer = 0.0

	for m in _dart_meshes:
		if is_instance_valid(m):
			m.queue_free()
	_dart_meshes.clear()

	_pi_label.text = "π ≈ ?"
	_pi_label.modulate = color_pi
	_stats_label.text = "darts: 0\ninside: 0\noutside: 0"
	_accuracy_label.text = ""

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
