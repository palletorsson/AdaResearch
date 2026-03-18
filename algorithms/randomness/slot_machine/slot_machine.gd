# slot_machine.gd
# Slot Machine — VR lever pull spins 3 reels with symbols.
# Reels stop one by one, left to right. Tracks results histogram
# showing convergence toward uniform distribution across symbols.
#
# QFEP: Independence — each reel is an independent uniform trial.
# The combination space grows multiplicatively (6^3 = 216 outcomes).

extends Node3D

class_name SlotMachine

# ── Cabinet ─────────────────────────────────────────────────────────────────
@export var cabinet_width: float = 0.50
@export var cabinet_height: float = 0.55
@export var cabinet_depth: float = 0.30
@export var cabinet_color: Color = Color(0.6, 0.08, 0.12)
@export var trim_color: Color = Color(0.85, 0.75, 0.2)

# ── Reels ───────────────────────────────────────────────────────────────────
@export var reel_count: int = 3
@export var symbols_per_reel: int = 6
@export var reel_radius: float = 0.06
@export var reel_width: float = 0.10
@export var reel_spacing: float = 0.02
@export var spin_speed: float = 12.0  ## radians per second
@export var stop_delay: float = 0.7   ## seconds between each reel stopping

# ── Pedestal ────────────────────────────────────────────────────────────────
@export var pedestal_height: float = 0.85
@export var pedestal_color: Color = Color(0.1, 0.08, 0.07)

# ── Symbols (emoji-style text) ──────────────────────────────────────────────
const SYMBOLS: Array[String] = ["7", "*", "#", "+", "~", "?"]
const SYMBOL_COLORS: Array[Color] = [
	Color(1.0, 0.2, 0.2),   # 7  — red
	Color(1.0, 0.85, 0.1),  # *  — gold
	Color(0.2, 0.8, 0.3),   # #  — green
	Color(0.3, 0.5, 1.0),   # +  — blue
	Color(0.9, 0.4, 0.9),   # ~  — purple
	Color(1.0, 1.0, 1.0),   # ?  — white
]

# ── Internal ────────────────────────────────────────────────────────────────
var _reel_nodes: Array[Node3D] = []          # pivot nodes that rotate
var _reel_angles: Array[float] = []          # current angles
var _reel_target_indices: Array[int] = []    # which symbol index each lands on
var _reel_spinning: Array[bool] = []         # per-reel spin state
var _reel_stopping: Array[bool] = []         # per-reel deceleration phase
var _reel_stop_timers: Array[float] = []     # countdown to stop each reel
var _reel_decel: Array[float] = []           # deceleration rate per reel

var _is_spinning: bool = false
var _stop_sequence_timer: float = 0.0
var _next_reel_to_stop: int = 0

var _total_spins: int = 0
var _symbol_counts: Array[int] = []  # per-symbol histogram (first reel only for simplicity)
var _triple_count: int = 0           # how many times all 3 match

var _result_label: Label3D
var _stats_label: Label3D
var _window_frame: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_symbol_counts.resize(symbols_per_reel)
	_symbol_counts.fill(0)

	_create_pedestal()
	_create_cabinet()
	_create_reels()
	_create_window()
	_create_labels()
	_create_vr_controls()


func _process(delta: float) -> void:
	if not _is_spinning:
		return

	# Spin active reels
	for i in range(reel_count):
		if _reel_spinning[i]:
			if _reel_stopping[i]:
				# Decelerating toward target
				_reel_decel[i] += delta * 8.0
				var speed: float = max(spin_speed - _reel_decel[i] * spin_speed, 0.0)
				_reel_angles[i] += speed * delta
				if speed <= 0.1:
					# Snap to target
					_reel_angles[i] = _reel_target_indices[i] * (TAU / symbols_per_reel)
					_reel_spinning[i] = false
					_reel_stopping[i] = false
			else:
				_reel_angles[i] += spin_speed * delta

		# Apply rotation
		if _reel_nodes[i]:
			_reel_nodes[i].rotation.x = -_reel_angles[i]

	# Stop sequence timer
	_stop_sequence_timer -= delta
	if _stop_sequence_timer <= 0.0 and _next_reel_to_stop < reel_count:
		_begin_reel_stop(_next_reel_to_stop)
		_next_reel_to_stop += 1
		_stop_sequence_timer = stop_delay

	# Check if all stopped
	var all_stopped := true
	for i in range(reel_count):
		if _reel_spinning[i]:
			all_stopped = false
			break
	if all_stopped and _is_spinning:
		_is_spinning = false
		_on_all_reels_stopped()


# ═════════════════════════════════════════════════════════════════════════════
# PEDESTAL
# ═════════════════════════════════════════════════════════════════════════════

func _create_pedestal() -> void:
	var body := StaticBody3D.new()
	body.name = "Pedestal"

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(cabinet_width * 0.8, pedestal_height, cabinet_depth * 0.7)
	col.shape = shape
	body.add_child(col)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(cabinet_width * 0.8, pedestal_height, cabinet_depth * 0.7)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pedestal_color
	mat.metallic = 0.2
	mat.roughness = 0.7
	mesh.material_override = mat
	body.add_child(mesh)

	body.position = Vector3(0, pedestal_height / 2.0, 0)
	add_child(body)


# ═════════════════════════════════════════════════════════════════════════════
# CABINET
# ═════════════════════════════════════════════════════════════════════════════

func _create_cabinet() -> void:
	var cabinet := Node3D.new()
	cabinet.name = "Cabinet"
	cabinet.position = Vector3(0, pedestal_height + cabinet_height / 2.0, 0)
	add_child(cabinet)

	# Main body
	var body_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(cabinet_width, cabinet_height, cabinet_depth)
	body_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cabinet_color
	mat.metallic = 0.3
	mat.roughness = 0.5
	body_mesh.material_override = mat
	cabinet.add_child(body_mesh)

	# Collision
	var static_body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(cabinet_width, cabinet_height, cabinet_depth)
	col.shape = shape
	static_body.add_child(col)
	cabinet.add_child(static_body)

	# Gold trim — top
	var trim_top := MeshInstance3D.new()
	var trim_box := BoxMesh.new()
	trim_box.size = Vector3(cabinet_width + 0.01, 0.015, cabinet_depth + 0.01)
	trim_top.mesh = trim_box
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = trim_color
	trim_mat.metallic = 0.7
	trim_mat.roughness = 0.3
	trim_top.material_override = trim_mat
	trim_top.position.y = cabinet_height / 2.0 + 0.007
	cabinet.add_child(trim_top)

	# Gold trim — bottom
	var trim_bot := trim_top.duplicate()
	trim_bot.position.y = -cabinet_height / 2.0 - 0.007
	cabinet.add_child(trim_bot)

	# Title plate on top
	var title_plate := MeshInstance3D.new()
	var plate_box := BoxMesh.new()
	plate_box.size = Vector3(cabinet_width * 0.7, 0.06, 0.02)
	title_plate.mesh = plate_box
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.15, 0.02, 0.02)
	plate_mat.metallic = 0.4
	plate_mat.roughness = 0.4
	title_plate.material_override = plate_mat
	title_plate.position = Vector3(0, cabinet_height / 2.0 - 0.05, -cabinet_depth / 2.0 - 0.011)
	cabinet.add_child(title_plate)

	var title_lbl := Label3D.new()
	title_lbl.text = "LUCKY 7s"
	title_lbl.pixel_size = 0.002
	title_lbl.font_size = 16
	title_lbl.modulate = trim_color
	title_lbl.outline_size = 4
	title_lbl.outline_modulate = Color(0.3, 0.1, 0)
	title_lbl.position = Vector3(0, cabinet_height / 2.0 - 0.05, -cabinet_depth / 2.0 - 0.023)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cabinet.add_child(title_lbl)


# ═════════════════════════════════════════════════════════════════════════════
# REELS
# ═════════════════════════════════════════════════════════════════════════════

func _create_reels() -> void:
	var total_reel_span: float = reel_count * reel_width + (reel_count - 1) * reel_spacing
	var start_x: float = -total_reel_span / 2.0 + reel_width / 2.0
	var reel_y: float = pedestal_height + cabinet_height * 0.45

	for i in range(reel_count):
		var pivot := Node3D.new()
		pivot.name = "ReelPivot_%d" % i
		pivot.position = Vector3(
			start_x + i * (reel_width + reel_spacing),
			reel_y,
			-cabinet_depth / 2.0 + 0.03
		)
		add_child(pivot)

		# Create symbol labels around the reel circumference
		for s in range(symbols_per_reel):
			var angle: float = s * (TAU / symbols_per_reel)
			var lbl := Label3D.new()
			lbl.text = SYMBOLS[s]
			lbl.pixel_size = 0.003
			lbl.font_size = 28
			lbl.modulate = SYMBOL_COLORS[s]
			lbl.outline_size = 5
			lbl.outline_modulate = Color(0, 0, 0)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

			# Position on reel circumference
			var y_pos := cos(angle) * reel_radius
			var z_pos := -sin(angle) * reel_radius
			lbl.position = Vector3(0, y_pos, z_pos)
			lbl.rotation.x = angle
			pivot.add_child(lbl)

		# Reel drum mesh (decorative)
		var drum := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = reel_radius * 0.85
		cyl.bottom_radius = reel_radius * 0.85
		cyl.height = reel_width * 0.8
		cyl.radial_segments = 16
		drum.mesh = cyl
		drum.rotation.z = PI / 2.0  # orient horizontally
		var drum_mat := StandardMaterial3D.new()
		drum_mat.albedo_color = Color(0.95, 0.95, 0.92)
		drum_mat.roughness = 0.8
		drum.material_override = drum_mat
		pivot.add_child(drum)

		_reel_nodes.append(pivot)
		_reel_angles.append(0.0)
		_reel_target_indices.append(0)
		_reel_spinning.append(false)
		_reel_stopping.append(false)
		_reel_stop_timers.append(0.0)
		_reel_decel.append(0.0)


# ═════════════════════════════════════════════════════════════════════════════
# WINDOW (viewing slot in front of cabinet)
# ═════════════════════════════════════════════════════════════════════════════

func _create_window() -> void:
	_window_frame = Node3D.new()
	_window_frame.name = "Window"
	var win_y: float = pedestal_height + cabinet_height * 0.45
	var win_z: float = -cabinet_depth / 2.0 - 0.005
	_window_frame.position = Vector3(0, win_y, win_z)
	add_child(_window_frame)

	var total_span: float = reel_count * reel_width + (reel_count - 1) * reel_spacing
	var frame_w: float = total_span + 0.04
	var frame_h: float = reel_radius * 2.0 + 0.03

	# Dark backing
	var backing := MeshInstance3D.new()
	var back_box := BoxMesh.new()
	back_box.size = Vector3(frame_w, frame_h, 0.005)
	backing.mesh = back_box
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.02, 0.02, 0.04)
	backing.material_override = back_mat
	backing.position.z = 0.01
	_window_frame.add_child(backing)

	# Glass overlay
	var glass := MeshInstance3D.new()
	var glass_box := BoxMesh.new()
	glass_box.size = Vector3(frame_w - 0.01, frame_h - 0.01, 0.002)
	glass.mesh = glass_box
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.8, 0.9, 1.0, 0.08)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.metallic = 0.1
	glass_mat.roughness = 0.05
	glass.material_override = glass_mat
	glass.position.z = -0.003
	_window_frame.add_child(glass)

	# Gold frame border (4 sides)
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = trim_color
	frame_mat.metallic = 0.6
	frame_mat.roughness = 0.3

	# Window frame border bars using MultiMesh
	# Two horizontal bars (same size) and two vertical bars (same size)
	var bar_thick := 0.012

	# Horizontal bars
	var hbar_mesh := BoxMesh.new()
	hbar_mesh.size = Vector3(frame_w + bar_thick, bar_thick, bar_thick)
	hbar_mesh.material = frame_mat

	var hbar_mm := MultiMesh.new()
	hbar_mm.transform_format = MultiMesh.TRANSFORM_3D
	hbar_mm.instance_count = 2
	hbar_mm.mesh = hbar_mesh
	hbar_mm.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(0, frame_h / 2.0, 0)))
	hbar_mm.set_instance_transform(1, Transform3D(Basis.IDENTITY, Vector3(0, -frame_h / 2.0, 0)))
	var hbar_mmi := MultiMeshInstance3D.new()
	hbar_mmi.name = "HBars_MM"
	hbar_mmi.multimesh = hbar_mm
	_window_frame.add_child(hbar_mmi)

	# Vertical bars
	var vbar_mesh := BoxMesh.new()
	vbar_mesh.size = Vector3(bar_thick, frame_h, bar_thick)
	vbar_mesh.material = frame_mat

	var vbar_mm := MultiMesh.new()
	vbar_mm.transform_format = MultiMesh.TRANSFORM_3D
	vbar_mm.instance_count = 2
	vbar_mm.mesh = vbar_mesh
	vbar_mm.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(frame_w / 2.0, 0, 0)))
	vbar_mm.set_instance_transform(1, Transform3D(Basis.IDENTITY, Vector3(-frame_w / 2.0, 0, 0)))
	var vbar_mmi := MultiMeshInstance3D.new()
	vbar_mmi.name = "VBars_MM"
	vbar_mmi.multimesh = vbar_mm
	_window_frame.add_child(vbar_mmi)

	# Payline indicator — horizontal line across reels
	var payline := MeshInstance3D.new()
	var line_box := BoxMesh.new()
	line_box.size = Vector3(frame_w - 0.02, 0.003, 0.001)
	payline.mesh = line_box
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(1.0, 0.3, 0.1, 0.7)
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mat.emission_enabled = true
	line_mat.emission = Color(1.0, 0.3, 0.1)
	line_mat.emission_energy_multiplier = 0.5
	payline.material_override = line_mat
	payline.position.z = -0.005
	_window_frame.add_child(payline)


# ═════════════════════════════════════════════════════════════════════════════
# SPIN LOGIC
# ═════════════════════════════════════════════════════════════════════════════

func _pull_lever() -> void:
	if _is_spinning:
		return

	_is_spinning = true
	_next_reel_to_stop = 0
	_stop_sequence_timer = 1.2  # initial spin time before first stop

	# Pick random results for each reel
	for i in range(reel_count):
		_reel_target_indices[i] = randi() % symbols_per_reel
		_reel_spinning[i] = true
		_reel_stopping[i] = false
		_reel_decel[i] = 0.0
		# Add some offset so reels aren't synchronized
		_reel_angles[i] += randf_range(0.5, 2.0)


func _begin_reel_stop(reel_idx: int) -> void:
	if reel_idx < reel_count:
		_reel_stopping[reel_idx] = true
		_reel_decel[reel_idx] = 0.0
		# Adjust angle so deceleration ends near the target
		var target_angle: float = _reel_target_indices[reel_idx] * (TAU / symbols_per_reel)
		# Round up current angle to next multiple of TAU, then add target offset
		var full_rots: float = ceil(_reel_angles[reel_idx] / TAU) + 1.0
		_reel_angles[reel_idx] = full_rots * TAU + target_angle - TAU * 0.25


func _on_all_reels_stopped() -> void:
	_total_spins += 1

	# Record result
	var result_symbols: Array[String] = []
	for i in range(reel_count):
		var idx := _reel_target_indices[i]
		result_symbols.append(SYMBOLS[idx])

	# Track first reel histogram
	_symbol_counts[_reel_target_indices[0]] += 1

	# Check for triple match
	if _reel_target_indices[0] == _reel_target_indices[1] and _reel_target_indices[1] == _reel_target_indices[2]:
		_triple_count += 1
		_flash_win()

	# Update display
	_result_label.text = " ".join(result_symbols)
	_update_stats()


func _flash_win() -> void:
	# Brief color flash on result label
	_result_label.modulate = Color(1.0, 1.0, 0.2)
	var tw := create_tween()
	tw.tween_property(_result_label, "modulate", Color(1.0, 0.9, 0.8), 1.5)


# ═════════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	var front_z: float = -cabinet_depth / 2.0 - 0.03

	# Result display — below window
	_result_label = Label3D.new()
	_result_label.name = "ResultLabel"
	_result_label.text = "? ? ?"
	_result_label.pixel_size = 0.003
	_result_label.font_size = 22
	_result_label.modulate = Color(1.0, 0.9, 0.8)
	_result_label.outline_size = 4
	_result_label.outline_modulate = Color(0.2, 0.05, 0)
	_result_label.position = Vector3(0, pedestal_height + cabinet_height * 0.22, front_z)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_result_label)

	# Stats panel — side of cabinet
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.text = "Pulls: 0\n\nPull the lever!"
	_stats_label.pixel_size = 0.0012
	_stats_label.font_size = 10
	_stats_label.modulate = Color(0.8, 0.8, 0.85)
	_stats_label.position = Vector3(cabinet_width / 2.0 + 0.08, pedestal_height + cabinet_height * 0.55, 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stats_label)


func _update_stats() -> void:
	if _total_spins == 0:
		return

	var lines := "Pulls: %d\nTriples: %d (%.1f%%)\n\n" % [
		_total_spins,
		_triple_count,
		float(_triple_count) / float(_total_spins) * 100.0
	]

	# Expected triple rate: 6/216 = 2.78%
	lines += "Theory: 2.8%%\n\n"

	# Histogram of first reel
	lines += "Reel 1 histogram:\n"
	for i in range(symbols_per_reel):
		var pct := float(_symbol_counts[i]) / float(_total_spins) * 100.0
		var bar := ""
		var bar_len := int(pct / 5.0)
		for j in range(bar_len):
			bar += "|"
		lines += "%s: %s %.0f%%\n" % [SYMBOLS[i], bar, pct]

	_stats_label.text = lines


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var panel := Node3D.new()
	panel.name = "ControlPanel"
	panel.position = Vector3(cabinet_width / 2.0 + 0.04, pedestal_height + cabinet_height * 0.3, -cabinet_depth / 4.0)
	panel.rotation_degrees = Vector3(-10, -90, 0)
	add_child(panel)

	# PULL lever button
	var pull_btn := PUSH_BUTTON.instantiate()
	pull_btn.name = "PullBtn"
	pull_btn.position = Vector3(0, 0, 0)
	pull_btn.scale = Vector3(0.8, 0.8, 0.8)
	panel.add_child(pull_btn)
	_add_button_label(pull_btn, "PULL")

	var pull_area := pull_btn.get_node_or_null("InteractableAreaButton")
	if pull_area:
		pull_area.button_pressed.connect(func(_b): _pull_lever())

	# Lever arm visual (decorative stick above button)
	var lever := MeshInstance3D.new()
	var lever_cyl := CylinderMesh.new()
	lever_cyl.top_radius = 0.012
	lever_cyl.bottom_radius = 0.015
	lever_cyl.height = 0.15
	lever.mesh = lever_cyl
	var lever_mat := StandardMaterial3D.new()
	lever_mat.albedo_color = Color(0.7, 0.7, 0.75)
	lever_mat.metallic = 0.8
	lever_mat.roughness = 0.3
	lever.material_override = lever_mat
	lever.position = Vector3(0, 0.09, 0)
	panel.add_child(lever)

	# Lever knob (ball on top)
	var knob := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	knob.mesh = sphere
	var knob_mat := StandardMaterial3D.new()
	knob_mat.albedo_color = Color(0.85, 0.2, 0.15)
	knob_mat.metallic = 0.5
	knob_mat.roughness = 0.3
	knob.material_override = knob_mat
	knob.position = Vector3(0, 0.17, 0)
	panel.add_child(knob)

	# AUTO toggle
	var auto_btn := PUSH_BUTTON.instantiate()
	auto_btn.name = "AutoBtn"
	auto_btn.position = Vector3(0, -0.07, 0)
	auto_btn.scale = Vector3(0.55, 0.55, 0.55)
	panel.add_child(auto_btn)
	_add_button_label(auto_btn, "AUTO")

	var auto_area := auto_btn.get_node_or_null("InteractableAreaButton")
	if auto_area:
		auto_area.button_pressed.connect(func(_b): _toggle_auto())

	# RESET button
	var reset_btn := PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetBtn"
	reset_btn.position = Vector3(0, -0.13, 0)
	reset_btn.scale = Vector3(0.55, 0.55, 0.55)
	panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")

	var reset_area := reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(func(_b): _reset_stats())


func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.position = Vector3(0, -0.02, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_child(lbl)


# ── Auto-spin ───────────────────────────────────────────────────────────────
var _auto_spin: bool = false
var _auto_timer: float = 0.0
const AUTO_INTERVAL: float = 3.5

func _toggle_auto() -> void:
	_auto_spin = not _auto_spin
	_auto_timer = 0.0


func _physics_process(delta: float) -> void:
	if _auto_spin and not _is_spinning:
		_auto_timer += delta
		if _auto_timer >= AUTO_INTERVAL:
			_auto_timer = 0.0
			_pull_lever()


func _reset_stats() -> void:
	_total_spins = 0
	_triple_count = 0
	_symbol_counts.fill(0)
	_result_label.text = "? ? ?"
	_result_label.modulate = Color(1.0, 0.9, 0.8)
	_stats_label.text = "Pulls: 0\n\nPull the lever!"
	_auto_spin = false
	_auto_timer = 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
