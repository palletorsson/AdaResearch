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
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Housing finish — "rams" (light Braun default) or "terminal" (dark console).
## Every colour derives from HangarKit.finish_palette(), so one word re-skins
## the whole body instead of a dozen hand-typed constants.
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "MC-02"

## Pedestal height. These machines are authored at bench scale but ground
## base-to-floor, which left their keypads at knee height (G5-reach). The
## plinth hangs BELOW the origin, so every coordinate above stays as authored
## and auto-grounding lifts the whole assembly. Set 0.0 for a floor-standing
## build.
@export var plinth_height: float = 0.38


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
# live metrics (cabinet compacts these so the readout fits its column screen)
var _readout_line_h: float = _READOUT_LINE_H
var _readout_width: float = _READOUT_WIDTH



# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_create_board()
	_create_circle_overlay()
	_create_labels()
	_create_vr_controls()
	_create_cabinet()


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
	# no_depth_test was ON, so the ring composited OVER the frame above the
	# board — a teal seam at the aperture top (off-family). Depth-test it so it
	# stays on the board face.
	mat.no_depth_test = false
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
		title_block.name = "TitleBlock"
		title_block.position = Vector3(0, board_height + board_size / 2.0 + 0.09, label_z)
		add_child(title_block)

	# ── READOUT — the converging estimate, consolidated onto ONE panel to the right.
	# An opaque plate behind the block gives it a clean "instrument screen" read; the
	# text block itself is swapped in _update_display() only when its lines change.
	_readout_root = Node3D.new()
	_readout_root.name = "ReadoutPanel"
	_readout_root.position = Vector3(board_size / 2.0 + 0.34, board_height, label_z)
	add_child(_readout_root)

	# A MILLED POCKET behind the plate. Without it this readout is a plate taped to
	# the body — the one thing G6 exists to catch, and it was catching it here: the
	# family's only standing advisory was this panel, correctly flagged.
	var recess: MeshInstance3D = HangarKit.box(
		Vector3(0, 0, -0.014),
		Vector3(_READOUT_WIDTH + 0.088, 0.468, 0.014),
		HangarKit.painted_metal(Color(0.07, 0.075, 0.09), wear, 0.35, 0.55))
	if recess:
		recess.name = "ReadoutPocket"
		_readout_root.add_child(recess)

	var plate := BakedText.make_panel_mesh(
		"", Color(0.06, 0.07, 0.10), Color.WHITE,
		Vector2(_READOUT_WIDTH + 0.06, 0.44), 1400, false)
	if plate:
		plate.name = "ReadoutPlate"
		plate.position = Vector3(0, 0, -0.006)
		_readout_root.add_child(plate)

	_rebuild_readout(["π ≈ ?", "", "darts: 0", "inside: 0", "outside: 0"])

	# ── FORMULA — one integrated board below the dartboard.
	var formula_block := BakedText.make_text_block(
		["π/4 = area(circle) / area(square)",
		 "π ≈ 4 × (inside / total)"],
		Color(0.6, 0.6, 0.68), 0.04, board_size + 0.14, 0.012, true)
	if formula_block:
		formula_block.name = "FormulaBlock"
		formula_block.position = Vector3(0, board_height - board_size / 2.0 - 0.1, label_z)
		add_child(formula_block)


# Swap the readout text block for a fresh one holding `lines`. Called only when the
# joined text differs from the cache (guarded by the caller), so no per-frame churn.
func _rebuild_readout(lines: Array) -> void:
	if _readout_block and is_instance_valid(_readout_block):
		_readout_block.queue_free()
	_readout_block = BakedText.make_text_block(
		lines, _readout_color, _readout_line_h, _readout_width, _READOUT_GAP, true)
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

## THE CABINET — the 2026-07-20 interface ruling propagated (2nd artifact):
## the dartboard becomes ONE appliance, vending-machine grammar. The board
## is the poster window; the pi census lives on an inset column screen; the
## THROW/AUTO/RESET pad seats on a wedge; sign band in the cap; maroon
## flank; vent grille; plinth on feet. The free-floating title, formula and
## readout plates are retired — every interface element is a face of the
## same volume.
func _create_cabinet() -> void:
	var half: float = board_size / 2.0
	var bd: float = board_thickness
	var cw: float = 0.27
	var colx: float = half + cw / 2.0
	var face_z: float = 0.09
	var win_bot: float = board_height - half
	var win_top: float = board_height + half
	var total_w: float = board_size + cw + 0.10
	var cx: float = (half + cw) - (total_w / 2.0)
	var cap_h: float = 0.12
	var body_top: float = win_top + 0.06

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
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.04, 0.05, 0.08)
	glass_mat.roughness = 0.15
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(0.05, 0.08, 0.12)
	glass_mat.emission_energy_multiplier = 0.6
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# back slab — full height
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(total_w, body_top, 0.05)
	back.mesh = back_mesh
	back.material_override = shell
	back.position = Vector3(cx, body_top / 2.0, -bd / 2.0 - 0.035)
	cab.add_child(back)

	# maroon flank (left, full height)
	var flank := MeshInstance3D.new()
	var flank_mesh := BoxMesh.new()
	flank_mesh.size = Vector3(0.10, body_top, 0.16)
	flank.mesh = flank_mesh
	flank.material_override = maroon
	flank.position = Vector3(-half - 0.05, body_top / 2.0, -0.005)
	cab.add_child(flank)

	# front shell panels around the window (below + above, window width)
	var below := MeshInstance3D.new()
	var below_mesh := BoxMesh.new()
	below_mesh.size = Vector3(board_size, win_bot, 0.05)
	below.mesh = below_mesh
	below.material_override = shell
	below.position = Vector3(0.0, win_bot / 2.0, bd / 2.0 - 0.010)
	cab.add_child(below)
	var above := MeshInstance3D.new()
	var above_mesh := BoxMesh.new()
	above_mesh.size = Vector3(board_size, body_top - win_top, 0.05)
	above.mesh = above_mesh
	above.material_override = shell
	above.position = Vector3(0.0, (win_top + body_top) / 2.0, bd / 2.0 - 0.010)
	cab.add_child(above)

	# FORMULA — signage in the below-window panel (was a floating block)
	var f_band := MeshInstance3D.new()
	var f_band_mesh := BoxMesh.new()
	f_band_mesh.size = Vector3(board_size - 0.06, 0.11, 0.012)
	f_band.mesh = f_band_mesh
	f_band.material_override = dark
	f_band.position = Vector3(0.0, win_bot - 0.12, bd / 2.0 + 0.012)
	cab.add_child(f_band)
	var f1: Node3D = BakedText.make_tag(
		"PI/4 = AREA(CIRCLE) / AREA(SQUARE)", Color(0.62, 0.64, 0.72), 0.020,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if f1:
		f1.position = Vector3(0.0, win_bot - 0.095, bd / 2.0 + 0.020)
		cab.add_child(f1)
	var f2: Node3D = BakedText.make_tag(
		"PI ~ 4 x (INSIDE / TOTAL)", Color(0.85, 0.75, 0.35), 0.024,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if f2:
		f2.position = Vector3(0.0, win_bot - 0.140, bd / 2.0 + 0.020)
		cab.add_child(f2)

	# right service column
	var col := MeshInstance3D.new()
	var col_mesh := BoxMesh.new()
	col_mesh.size = Vector3(cw, body_top, 0.16)
	col.mesh = col_mesh
	col.material_override = shell
	col.position = Vector3(colx, body_top / 2.0, -0.005)
	cab.add_child(col)

	# inset PI screen (upper column) — the readout re-homes here
	var scr_w: float = cw - 0.05
	var scr_h: float = 0.46
	var scr_y: float = board_height + 0.10
	var pocket := MeshInstance3D.new()
	var pocket_mesh := BoxMesh.new()
	pocket_mesh.size = Vector3(scr_w + 0.02, scr_h + 0.05, 0.015)
	pocket.mesh = pocket_mesh
	pocket.material_override = dark
	pocket.position = Vector3(colx, scr_y, face_z + 0.002)
	cab.add_child(pocket)
	var glass := MeshInstance3D.new()
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(scr_w, scr_h, 0.006)
	glass.mesh = glass_mesh
	glass.material_override = glass_mat
	glass.position = Vector3(colx, scr_y - 0.008, face_z + 0.010)
	cab.add_child(glass)
	var head_tag: Node3D = BakedText.make_tag(
		"PI CENSUS", Color(0.92, 0.93, 0.97), 0.020,
		Color(0.055, 0.06, 0.075), true, Color(0.86, 0.30, 0.10))
	if head_tag:
		head_tag.position = Vector3(colx, scr_y + scr_h / 2.0 + 0.014, face_z + 0.014)
		cab.add_child(head_tag)
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(scr_w + 0.02, 0.005, 0.004)
	stripe.mesh = stripe_mesh
	stripe.material_override = accent
	stripe.position = Vector3(colx, scr_y + scr_h / 2.0 - 0.002, face_z + 0.012)
	cab.add_child(stripe)

	# retire the floats; re-home the live readout INTO the screen
	var tb: Node = get_node_or_null("TitleBlock")
	if tb != null:
		tb.queue_free()
	var fb: Node = get_node_or_null("FormulaBlock")
	if fb != null:
		fb.queue_free()
	if _readout_root != null and is_instance_valid(_readout_root):
		var old_plate: Node = _readout_root.get_node_or_null("ReadoutPlate")
		if old_plate != null:
			old_plate.queue_free()
		_readout_root.position = Vector3(colx, scr_y - 0.01, face_z + 0.014)
		_readout_line_h = 0.026
		_readout_width = scr_w - 0.02
		_readout_cache = ""
		_rebuild_readout(["PI ~ ?", "", "darts: 0", "inside: 0", "outside: 0"])

	# keypad wedge + (pad repositioned in _create_vr_controls)
	var wedge := _make_wedge(cw - 0.03, 0.16, 0.062, 0.018, dark)
	wedge.position = Vector3(colx, 0.62, face_z - 0.045)
	cab.add_child(wedge)

	# vent grille (lower column)
	for gi in range(7):
		var slat := MeshInstance3D.new()
		var slat_mesh := BoxMesh.new()
		slat_mesh.size = Vector3(cw - 0.06, 0.010, 0.012)
		slat.mesh = slat_mesh
		slat.material_override = dark
		slat.position = Vector3(colx, 0.18 + float(gi) * 0.024, face_z + 0.002)
		cab.add_child(slat)

	# header cap with the integrated sign band
	var cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(total_w, cap_h, 0.20)
	cap.mesh = cap_mesh
	cap.material_override = shell
	cap.position = Vector3(cx, body_top + cap_h / 2.0, -0.005)
	cab.add_child(cap)
	var cap_stripe := MeshInstance3D.new()
	var cap_stripe_mesh := BoxMesh.new()
	cap_stripe_mesh.size = Vector3(total_w, 0.006, 0.004)
	cap_stripe.mesh = cap_stripe_mesh
	cap_stripe.material_override = accent
	cap_stripe.position = Vector3(cx, body_top + 0.004, 0.093)
	cab.add_child(cap_stripe)
	var sign := MeshInstance3D.new()
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(total_w - 0.08, 0.078, 0.012)
	sign.mesh = sign_mesh
	sign.material_override = dark
	sign.position = Vector3(cx, body_top + cap_h / 2.0, 0.096)
	cab.add_child(sign)
	var sign_title: Node3D = BakedText.make_tag(
		"MONTE CARLO", Color(0.93, 0.94, 0.97), 0.032,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title:
		sign_title.position = Vector3(cx, body_top + cap_h / 2.0 + 0.014, 0.104)
		cab.add_child(sign_title)
	var sign_sub: Node3D = BakedText.make_tag(
		"ESTIMATING PI WITH RANDOM DARTS", Color(0.55, 0.58, 0.66), 0.015,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_sub:
		sign_sub.position = Vector3(cx, body_top + cap_h / 2.0 - 0.020, 0.104)
		cab.add_child(sign_sub)

	# plinth + feet
	var plinth := MeshInstance3D.new()
	var plinth_mesh := BoxMesh.new()
	plinth_mesh.size = Vector3(total_w, 0.10, 0.24)
	plinth.mesh = plinth_mesh
	plinth.material_override = dark
	plinth.position = Vector3(cx, 0.05, 0.0)
	cab.add_child(plinth)
	for fx in [-total_w / 2.0 + 0.08, total_w / 2.0 - 0.08]:
		var foot := MeshInstance3D.new()
		var foot_mesh := BoxMesh.new()
		foot_mesh.size = Vector3(0.10, 0.035, 0.20)
		foot.mesh = foot_mesh
		foot.material_override = dark
		foot.position = Vector3(cx + fx, 0.017, 0.0)
		cab.add_child(foot)


## Right-triangle prism shoulder (shared cabinet grammar — see galton_board).

	# ── Kit details: the manufactured read the station props carry ──────
	cab.add_child(HangarKit.bolts(
		Vector3(colx + cw / 2.0 - 0.02, 0.14, face_z - 0.004),
		Vector3(colx + cw / 2.0 - 0.02, body_top - 0.10, face_z - 0.004),
		7, 0.009, steel))
	var bar: Node3D = HangarKit.three_color_bar(cw - 0.06, 0.016)
	if bar:
		bar.position = Vector3(colx, win_bot + 0.10, face_z + 0.004)
		cab.add_child(bar)
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.12, 0.030),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-half + 0.10, 0.155, bd / 2.0 + 0.056)
		cab.add_child(code)
	var gb: MeshInstance3D = HangarKit.grime_band(total_w * 0.9, 0.055,
		bd / 2.0 + 0.058, col_body)
	if gb:
		gb.position.x = cx                  # keep the kit's baked z
		cab.add_child(gb)

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
	var bbl := Vector3(x0, y0, 0.0)
	var bbr := Vector3(x1, y0, 0.0)
	var btl := Vector3(x0, y1, 0.0)
	var btr := Vector3(x1, y1, 0.0)
	var fbl := Vector3(x0, y0, d_bottom)
	var fbr := Vector3(x1, y0, d_bottom)
	var ftl := Vector3(x0, y1, d_top)
	var ftr := Vector3(x1, y1, d_top)
	var faces := [
		[fbl, fbr, ftr, ftl],
		[bbr, bbl, btl, btr],
		[bbl, fbl, ftl, btl],
		[fbr, bbr, btr, ftr],
		[btl, ftl, ftr, btr],
		[bbl, bbr, fbr, fbl],
	]
	for f in faces:
		st.add_vertex(f[0]); st.add_vertex(f[1]); st.add_vertex(f[2])
		st.add_vertex(f[0]); st.add_vertex(f[2]); st.add_vertex(f[3])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("", [
		[
			{"type": "button", "label": "THROW"},
			{"type": "button", "label": "AUTO"},
			{"type": "button", "label": "RESET"},
		],
	])
	# seated on the service column's wedge (all-in-one cabinet)
	panel.position = Vector3(board_size / 2.0 + 0.135, 0.62, 0.105)
	panel.rotation_degrees = Vector3(-15, 0, 0)
	panel.scale = Vector3(0.72, 0.72, 0.72)
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
