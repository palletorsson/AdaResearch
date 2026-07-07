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

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

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

# Integrated 2D-in-3D readout — the estimate panel (π + darts + hits + error),
# consolidated onto ONE baked-text block that rebuilds only when its text changes.
var _readout_root: Node3D          # anchor holding the readout block (fixed position)
var _readout_block: Node3D         # the current make_text_block child (swapped on change)
var _readout_cache: String = ""    # last-rendered joined text — the rebuild cache guard
var _readout_color: Color = Color(0.85, 0.87, 0.95)
var _circle_mesh: MeshInstance3D

const _READOUT_LINE_H: float = 0.045
const _READOUT_WIDTH: float = 0.40
const _READOUT_GAP: float = 0.014



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

	# Corner axis tags: (0,0) → (1,1) coordinate display, as small integrated boards.
	var corner_z := board_thickness / 2.0 + 0.012
	var corner_positions := [
		[Vector3(-board_size / 2.0 - 0.045, board_height - board_size / 2.0, corner_z), "(0,0)"],
		[Vector3(board_size / 2.0 + 0.045, board_height + board_size / 2.0, corner_z), "(1,1)"],
	]
	for cp in corner_positions:
		var tag := BakedText.make_tag(
			cp[1], Color(0.6, 0.6, 0.68), 0.032,
			Color(0.08, 0.09, 0.11), true, Color(0.4, 0.6, 1.0))
		if tag:
			tag.position = cp[0]
			add_child(tag)


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
	var label_z := board_thickness / 2.0 + 0.012

	# ── TITLE — one integrated board above the dartboard (title + subtitle lines).
	var title_block := BakedText.make_text_block(
		["MONTE CARLO", "Estimating π with random darts"],
		Color(0.9, 0.9, 0.95), 0.05, board_size + 0.1, 0.012, true)
	if title_block:
		title_block.position = Vector3(0, board_height + board_size / 2.0 + 0.09, label_z)
		add_child(title_block)

	# ── READOUT — the converging estimate, consolidated onto ONE panel to the right.
	# An opaque plate behind the block gives it a clean "instrument screen" read; the
	# text block itself is swapped in _update_display() only when its lines change.
	_readout_root = Node3D.new()
	_readout_root.name = "ReadoutPanel"
	_readout_root.position = Vector3(board_size / 2.0 + 0.34, board_height, label_z)
	add_child(_readout_root)

	var plate := BakedText.make_panel_mesh(
		"", Color(0.06, 0.07, 0.10), Color.WHITE,
		Vector2(_READOUT_WIDTH + 0.06, 0.44), 1400, false)
	if plate:
		plate.position = Vector3(0, 0, -0.006)
		_readout_root.add_child(plate)

	_rebuild_readout(["π ≈ ?", "", "darts: 0", "inside: 0", "outside: 0"])

	# ── FORMULA — one integrated board below the dartboard.
	var formula_block := BakedText.make_text_block(
		["π/4 = area(circle) / area(square)",
		 "π ≈ 4 × (inside / total)"],
		Color(0.6, 0.6, 0.68), 0.04, board_size + 0.14, 0.012, true)
	if formula_block:
		formula_block.position = Vector3(0, board_height - board_size / 2.0 - 0.1, label_z)
		add_child(formula_block)


# Swap the readout text block for a fresh one holding `lines`. Called only when the
# joined text differs from the cache (guarded by the caller), so no per-frame churn.
func _rebuild_readout(lines: Array) -> void:
	if _readout_block and is_instance_valid(_readout_block):
		_readout_block.queue_free()
	_readout_block = BakedText.make_text_block(
		lines, _readout_color, _READOUT_LINE_H, _READOUT_WIDTH, _READOUT_GAP, true)
	if _readout_block:
		_readout_block.position = Vector3(0, 0, 0.002)
		_readout_root.add_child(_readout_block)


func _update_display() -> void:
	if _total_count == 0:
		return

	var pi_estimate: float = 4.0 * float(_inside_count) / float(_total_count)
	var error: float = absf(pi_estimate - PI)
	var error_pct: float = error / PI * 100.0

	# Every readout string, consolidated onto one panel.
	var lines := [
		"π ≈ %.6f" % pi_estimate,
		"",
		"darts: %d" % _total_count,
		"inside: %d" % _inside_count,
		"outside: %d" % (_total_count - _inside_count),
		"ratio: %.4f" % (float(_inside_count) / float(_total_count)),
		"",
		"actual π: %.6f" % PI,
		"error: %.6f (%.2f%%)" % [error, error_pct],
	]

	# Color the whole readout by accuracy — green excellent, gold good, orange far.
	if error_pct < 1.0:
		_readout_color = Color(0.4, 1.0, 0.45)
	elif error_pct < 5.0:
		_readout_color = color_pi
	else:
		_readout_color = Color(1.0, 0.6, 0.35)

	# Cache guard: rebuild the baked block only when its text (or colour) changed.
	var joined := "%s|%s" % [_readout_color, "\n".join(PackedStringArray(lines))]
	if joined == _readout_cache:
		return
	_readout_cache = joined
	_rebuild_readout(lines)


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

	_readout_color = Color(0.85, 0.87, 0.95)
	_readout_cache = ""
	_rebuild_readout(["π ≈ ?", "", "darts: 0", "inside: 0", "outside: 0"])

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
