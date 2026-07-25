# slot_machine.gd
# Slot Machine — VR lever pull spins 3 reels with symbols.
# Reels stop one by one, left to right. Tracks results histogram
# showing convergence toward uniform distribution across symbols.
#
# QFEP: Independence — each reel is an independent uniform trial.
# The combination space grows multiplicatively (6^3 = 216 outcomes).
#
# @identity
# essence: P(A∩B∩C) = P(A)·P(B)·P(C) — independent joint probability
# desire: pull the lever, feel anticipation as reels decelerate one by one
# critical_parameter: symbols_per_reel — determines outcome space (6^3 = 216)
# triggers: _pull_lever() → sequential reel-stop cascade via _stop_sequence_timer
# emerges: histogram convergence to uniform — the longer you play, the flatter the bars
# needs: VR push button [has], lever pull gesture [has]
# relationships: contrasts with galton_board (binomial, not uniform); unlocks coin_toss
# truth: Independence is not absence of connection — it is the impossibility of prediction from correlation.

extends Node3D

class_name SlotMachine

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Housing — cabinet grammar, VERTICAL dialect (body = "reel cabinet").
## This artifact was already A CABINET, which makes it the family's odd case: the
## body was right and the MANUFACTURER was wrong. Casino red with gold trim reads
## as a different maker entirely (G4), and it composed none of the kit (G8). Its
## keypad also sat on the BACK face at 1.45 m — the machine faces -Z, so the
## controls were behind it and above the reach band.
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "SL-06"

# ── Cabinet ─────────────────────────────────────────────────────────────────
@export var cabinet_width: float = 0.50
@export var cabinet_height: float = 0.55
@export var cabinet_depth: float = 0.30
## Derived from finish_palette() in _ready() so one word re-skins the machine with
## the family. Kept as fields (not exports) because the palette is now the source.
var cabinet_color: Color = Color(0.14, 0.14, 0.155)
var trim_color: Color = Color(0.85, 0.30, 0.12)

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
var pedestal_color: Color = Color(0.09, 0.09, 0.10)

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
var _cab: Node3D            # the Cabinet subtree the rules are scoped to



# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_symbol_counts.resize(symbols_per_reel)
	_symbol_counts.fill(0)

	_resolve_palette()
	_create_pedestal()
	_create_cabinet()
	_create_reels()
	_create_window()
	_create_labels()
	_create_vr_controls()
	_face_forward()


## This machine was authored facing -Z while every other member of the family faces
## +Z. 13 of its 14 map placements use rotation 0, so all of them were showing its
## BACK: a blank box, with the window, reels, sign, readouts and keypad behind it.
## Rather than mirror every authored coordinate, re-seat the finished assembly in
## one container turned 180 degrees — the geometry is untouched and the machine now
## reads front-forward like its kin, with no map edits needed.
func _face_forward() -> void:
	var kids: Array = get_children()
	var body := Node3D.new()
	body.name = "Assembly"
	add_child(body)
	for k in kids:
		remove_child(k)
		body.add_child(k)
	body.rotation_degrees.y = 180.0


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

## One palette word drives every part (kit finish system).
func _resolve_palette() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	cabinet_color = pal["body"]
	trim_color = pal["accent"]
	pedestal_color = pal["panel"]


## The machine's front is -Z (window, reels and readouts all face that way), so
## every housing detail added here mirrors the family's +Z idiom to that side.
func _front_z() -> float:
	return -cabinet_depth / 2.0


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
	mesh.material_override = HangarKit.finish_body(finish, pedestal_color, wear)
	body.add_child(mesh)

	body.position = Vector3(0, pedestal_height / 2.0, 0)
	add_child(body)

	# Kit footing detail on the pedestal: recessed toe kick, grime at the floor,
	# and the asset code stencilled on the front — station furniture, not a plinth
	# improvised per artifact.
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.09, 0.09, 0.105), wear, 0.4, 0.5)
	var ped_front: float = -cabinet_depth * 0.35
	add_child(HangarKit.box(
		Vector3(0, 0.032, 0),
		Vector3(cabinet_width * 0.66, 0.064, cabinet_depth * 0.56), dark))
	var gb: MeshInstance3D = HangarKit.grime_band(
		cabinet_width * 0.7, 0.05, 0.0, pedestal_color)
	if gb:
		gb.position = Vector3(0, 0.078, ped_front - 0.003)
		gb.rotation_degrees.y = 180.0
		add_child(gb)
	var code: MeshInstance3D = HangarKit.stencil(
		unit_code, Vector2(0.10, 0.024), trim_color.lightened(0.22))
	if code:
		code.position = Vector3(-cabinet_width * 0.22, pedestal_height - 0.10, ped_front - 0.004)
		code.rotation_degrees.y = 180.0
		add_child(code)


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
	body_mesh.material_override = HangarKit.finish_body(finish, cabinet_color, wear)
	cabinet.add_child(body_mesh)
	cabinet.set_meta("housing", true)
	_cab = cabinet

	# Collision
	var static_body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(cabinet_width, cabinet_height, cabinet_depth)
	col.shape = shape
	static_body.add_child(col)
	cabinet.add_child(static_body)

	# Cap and skirt in worn steel — the gold trim's family equivalent. Gold on red
	# is a casino; the family says a steel cap over an ember line.
	var steel: StandardMaterial3D = HangarKit.worn_metal(cabinet_color.lightened(0.10))
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(trim_color, 2.2)
	var front_z: float = -cabinet_depth / 2.0

	cabinet.add_child(HangarKit.box(
		Vector3(0, cabinet_height / 2.0 + 0.014, 0),
		Vector3(cabinet_width + 0.045, 0.030, cabinet_depth + 0.045), steel))
	cabinet.add_child(HangarKit.box(
		Vector3(0, -cabinet_height / 2.0 - 0.012, 0),
		Vector3(cabinet_width + 0.03, 0.024, cabinet_depth + 0.03), steel))
	# side flanks, full height
	for sx in [-1.0, 1.0]:
		cabinet.add_child(HangarKit.box(
			Vector3(sx * (cabinet_width * 0.5 + 0.015), 0.0, 0.0),
			Vector3(0.030, cabinet_height, cabinet_depth + 0.016), steel))
	# ember stripe under the cap lip, on the front face (G7)
	cabinet.add_child(HangarKit.box(
		Vector3(0, cabinet_height / 2.0 - 0.010, front_z - 0.005),
		Vector3(cabinet_width * 0.98, 0.007, 0.006), accent))
	# bolted flank lines down the front
	cabinet.add_child(HangarKit.bolts(
		Vector3(-cabinet_width * 0.5 + 0.022, -cabinet_height * 0.36, front_z - 0.004),
		Vector3(-cabinet_width * 0.5 + 0.022, cabinet_height * 0.36, front_z - 0.004),
		4, 0.0055, steel))
	cabinet.add_child(HangarKit.bolts(
		Vector3(cabinet_width * 0.5 - 0.022, -cabinet_height * 0.36, front_z - 0.004),
		Vector3(cabinet_width * 0.5 - 0.022, cabinet_height * 0.36, front_z - 0.004),
		4, 0.0055, steel))
	# the family's three-colour bar, low on the front fascia
	var bar: Node3D = HangarKit.three_color_bar(cabinet_width * 0.38, 0.013)
	if bar:
		bar.position = Vector3(0.0, -cabinet_height * 0.40, front_z - 0.005)
		bar.rotation_degrees.y = 180.0
		cabinet.add_child(bar)

	# Sign band in the cap: the plate stays as the recess, but the name is a baked
	# stencil in the family accent instead of a gold outlined Label3D.
	cabinet.add_child(HangarKit.box(
		Vector3(0, cabinet_height / 2.0 - 0.052, front_z - 0.010),
		Vector3(cabinet_width * 0.74, 0.058, 0.018), dark))
	var sign: MeshInstance3D = HangarKit.stencil(
		"LUCKY 7s", Vector2(cabinet_width * 0.62, 0.032), trim_color.lightened(0.35))
	if sign:
		sign.position = Vector3(0, cabinet_height / 2.0 - 0.052, front_z - 0.021)
		sign.rotation_degrees.y = 180.0
		cabinet.add_child(sign)


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
	glass_mat.albedo_color = Color(0.62, 0.72, 0.85, 0.08)  # canon window_glass
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
	tw.tween_property(_result_label, "modulate", HangarKit.finish_palette(finish)["text"], 1.5)


# ═════════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════════

## Seats one screen into a face: milled pocket, lit face, the family's canonical
## glass, ember lip. `face_dir` is -Z for the machine's front or +X for its side.
func _seat_screen(size: Vector2, centre: Vector3, face_dir: Vector3) -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(trim_color, 2.0)
	var w: float = size.x
	var h: float = size.y
	var n: Vector3 = face_dir.normalized()
	var flat := Vector3(w + 0.026, h + 0.030, 0.014)
	var face := Vector3(w, h, 0.005)
	var glassv := Vector3(w, h, 0.004)
	if absf(n.x) > 0.5:
		flat = Vector3(0.014, h + 0.030, w + 0.026)
		face = Vector3(0.005, h, w)
		glassv = Vector3(0.004, h, w)

	var host: Node3D = _cab if _cab != null else self
	host.add_child(HangarKit.box(centre + n * 0.002, flat, dark))
	host.add_child(HangarKit.box(
		centre + n * 0.008, face, HangarKit.emissive(pal["screen"], 0.45)))
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.04, 0.05, 0.08)
	glass_mat.roughness = 0.15
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.08, 0.12)
	glass_mat.emission_energy_multiplier = 0.5
	host.add_child(HangarKit.box(centre + n * 0.0125, glassv, glass_mat))
	# ember lip along the pocket's top edge
	var lip_s := Vector3(w + 0.026, 0.005, 0.005)
	if absf(n.x) > 0.5:
		lip_s = Vector3(0.005, 0.005, w + 0.026)
	host.add_child(HangarKit.box(
		centre + n * 0.010 + Vector3(0, h * 0.5 + 0.010, 0), lip_s, accent))


func _create_labels() -> void:
	var front_z: float = -cabinet_depth / 2.0 - 0.03
	var pal: Dictionary = HangarKit.finish_palette(finish)
	# The two readouts are SEATED in the body now, not hovering off it: the result
	# in the front fascia below the window, the stats flush in the side face where
	# they used to float 8 cm clear of the cabinet.
	# Centres are CABINET-LOCAL: the Cabinet node sits at its own mid-height, so a
	# world height of pedestal + cabinet_height * f is local cabinet_height * (f - 0.5).
	_seat_screen(Vector2(cabinet_width * 0.62, 0.080),
		Vector3(0, cabinet_height * -0.28, -cabinet_depth / 2.0),
		Vector3(0, 0, -1))
	_seat_screen(Vector2(cabinet_depth * 0.62, 0.150),
		Vector3(cabinet_width / 2.0, cabinet_height * 0.05, 0),
		Vector3(1, 0, 0))

	# Result display — below window
	_result_label = Label3D.new()
	_result_label.name = "ResultLabel"
	_result_label.text = "? ? ?"
	_result_label.pixel_size = 0.003
	_result_label.font_size = 22
	_result_label.modulate = pal["text"]
	_result_label.outline_size = 0
	_result_label.position = Vector3(0, pedestal_height + cabinet_height * 0.22, -cabinet_depth / 2.0 - 0.020)
	_result_label.rotation_degrees.y = 180.0
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_result_label)

	# Stats panel — side of cabinet
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.text = "Pulls: 0\n\nPull the lever!"
	_stats_label.pixel_size = 0.0012
	_stats_label.font_size = 10
	_stats_label.modulate = pal["text"]
	_stats_label.position = Vector3(cabinet_width / 2.0 + 0.020, pedestal_height + cabinet_height * 0.55, 0)
	_stats_label.rotation_degrees.y = 90.0
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
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	# Frameless: the wedge shoulder is the faceplate; RackTemplates' cream plate and
	# copper strip would be a second manufacturer on this body (G4).
	var panel: Node3D = RackTpl.create_panel("", [
		[
			{"type": "button", "label": "PULL"},
			{"type": "button", "label": "AUTO"},
			{"type": "button", "label": "RESET"},
		],
	], true)
	# The keypad belongs on the face you READ, and this machine reads at -Z. It used
	# to hang off the BACK at 1.45 m — behind the machine and above the reach band.
	# Now it rests on a wedge shoulder cantilevered off the front, under the window.
	var front_z: float = -cabinet_depth / 2.0
	var shoulder_y: float = pedestal_height + cabinet_height * 0.06
	var steel: StandardMaterial3D = HangarKit.worn_metal(cabinet_color.lightened(0.10))
	var shoulder: MeshInstance3D = HangarKit.wedge(
		cabinet_width * 0.66, 0.11, 0.15, 0.05, steel)
	if shoulder:
		shoulder.position = Vector3(0.0, shoulder_y, front_z + 0.002)
		shoulder.rotation_degrees.y = 180.0
		add_child(shoulder)
	panel.position = Vector3(0.0, shoulder_y + 0.055, front_z - 0.076)
	panel.rotation_degrees = Vector3(-32, 180, 0)
	HangarKit.harmonize(panel, finish)
	add_child(panel)

	# PULL button (Btn_0)
	var pull_btn: Node = panel.find_child("Btn_0", true, false)
	if pull_btn:
		var area = pull_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _pull_lever())

	# AUTO button (Btn_1)
	var auto_btn: Node = panel.find_child("Btn_1", true, false)
	if auto_btn:
		var area = auto_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _toggle_auto())

	# RESET button (Btn_2)
	var reset_btn: Node = panel.find_child("Btn_2", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset_stats())


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
