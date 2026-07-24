# matrix_4x4_viewer.gd
# Matrix 4x4 Viewer — interactive transformation matrix with live 3D preview
# Shows a wireframe cube being transformed by sliders (translate, rotate, scale).
# The 4x4 matrix values update in real time as a grid of Label3D nodes.
#
# HOUSING — the cabinet grammar (2026-07-21), VERTICAL dialect, a new body:
# the CORRESPONDENCE CONSOLE. This artifact carries two CO-EQUAL displays of one
# fact — 16 numbers and one cube — plus a control bank that drives both. No
# existing body carries two equal apertures (the kiosk/vending bodies are one
# window plus a service column; the twin-bay comparison compares two runs of the
# SAME phenomenon). Here the two bays are two LANGUAGES for one state, which is
# the artifact's truth statement, so the silhouette states equality: twin bays of
# identical size, symmetric about x=0, split by a mullion carrying the ember
# line, under one cap band spanning both. Left bay = the seated readout pocket
# (the 16 cells); right bay = the glazed vitrine (the cube).
#
# The case is sized from the phenomenon's real sweep, not a guess: a cube
# rotating about Y at max scale sweeps its XZ diagonal, so the bay is
# CUBE_SIZE*SCALE_MAX*sqrt(2) + 2*TRAVEL + clearance. Travel is clamped to
# CUBE_SIZE*0.5 so the cube can never leave its own box — the window IS the
# transform's declared domain.
#
# @identity
# essence: the matrix is the truth of the transform — numbers become geometry
# desire: slide translate/rotate/scale, watch the cube warp and the 16 numbers shift
# critical_parameter: rotation — the only transform that mixes matrix columns
# triggers: MOVE X/Y/Z sliders shift columns 3; ROTATE slider fills rotation submatrix; SCALE slider scales diagonal
# emerges: identity matrix = no change; rotation fills off-diagonal cells; translation only touches the last column
# needs: RackTemplates panel [has]; ImmediateMesh wireframe cube [has]; Label3D 4x4 grid [has]
# relationships: sibling to homogeneous_coordinates (theory); feeds into transform_composition (application)
# truth: Every spatial transformation hides inside 16 numbers — the matrix makes the invisible scaffolding visible.

extends Node3D

class_name Matrix4x4Viewer

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# ── Housing finish ────────────────────────────────────────────────────
## "rams" (light Braun default) or "terminal" (dark console). One word drives
## every colour through HangarKit.finish_palette().
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "MX-01"
## Pedestal height. The plinth hangs BELOW the origin, so every authored
## coordinate above stays put and the grid's auto-grounding lifts the assembly
## until the plinth foot meets the floor. Set 0.0 for a floor-standing build.
@export var plinth_height: float = 0.60

# ── Layout ────────────────────────────────────────────────────────────
# The hidden numbers of the transform, hoisted into constants so the BODY can
# be derived from the phenomenon instead of guessed at.
const CUBE_SIZE: float = 0.10                       # the vitrine sizes the specimen
const EDGE_RADIUS: float = 0.002
const AXIS_LEN: float = CUBE_SIZE * 0.55            # just proud of the cube face
const SCALE_MIN: float = 0.5
const SCALE_MAX: float = 2.0
const TRAVEL: float = CUBE_SIZE * 0.5               # translate range each way
const BAY_CLEAR: float = 0.02                       # air between sweep and glass
const MATRIX_CELL_SPACING: float = 0.075

# ── Derived body dimensions (set by _compute_layout) ──────────────────
var _win_w: float = 0.0
var _win_d: float = 0.0
var _win_h: float = 0.0
var _scr_w: float = 0.0
var _bay_w: float = 0.0
var _mull: float = 0.07
var _trim: float = 0.05
var _total_w: float = 0.0
var _bd: float = 0.0
var _win_bot: float = 0.44
var _win_top: float = 0.0
var _body_top: float = 0.0
var _cap_h: float = 0.11
var _bay_a_x: float = 0.0
var _bay_b_x: float = 0.0
var _cube_home: Vector3 = Vector3.ZERO
var _matrix_origin: Vector3 = Vector3.ZERO

# ── State ─────────────────────────────────────────────────────────────
var _translate := Vector3.ZERO
var _rotate_y: float = 0.0
var _scale_uniform: float = 1.0

var _cube_root: Node3D
var _edge_meshes: Array[MeshInstance3D] = []
var _matrix_labels: Array[Label3D] = []
var _panel: Node3D


func _ready() -> void:
	_compute_layout()
	_build_wireframe_cube()
	_build_matrix_display()
	_build_panel()
	_update_transform()
	_create_cabinet()


# ═════════════════════════════════════════════════════════════════════
# LAYOUT — the body follows the phenomenon's real sweep
# ═════════════════════════════════════════════════════════════════════

func _compute_layout() -> void:
	var cube_edge_max: float = CUBE_SIZE * SCALE_MAX
	# rotation about Y sweeps the cube's XZ diagonal — that is the widest the
	# phenomenon ever gets, and therefore what the vitrine has to clear.
	var cube_diag_max: float = cube_edge_max * sqrt(2.0)
	_win_w = cube_diag_max + 2.0 * TRAVEL + 2.0 * BAY_CLEAR
	_win_d = _win_w
	_win_h = cube_edge_max + 2.0 * TRAVEL + 2.0 * BAY_CLEAR
	_scr_w = 4.0 * MATRIX_CELL_SPACING + 0.04
	_bay_w = maxf(_win_w, _scr_w) + 0.02
	_total_w = 2.0 * _bay_w + _mull + 2.0 * _trim
	_bd = _win_d + 0.06
	_win_top = _win_bot + _win_h
	_body_top = _win_top + 0.05
	_bay_a_x = -(_mull + _bay_w) / 2.0
	_bay_b_x = (_mull + _bay_w) / 2.0
	_cube_home = Vector3(_bay_b_x, _win_bot + _win_h / 2.0, 0.0)
	_matrix_origin = Vector3(
		_bay_a_x - 1.5 * MATRIX_CELL_SPACING,
		_win_bot + _win_h / 2.0 - 0.02 + 1.5 * MATRIX_CELL_SPACING,
		_bd / 2.0 - 0.004
	)


# ═════════════════════════════════════════════════════════════════════
# WIREFRAME CUBE
# ═════════════════════════════════════════════════════════════════════

func _build_wireframe_cube() -> void:
	_cube_root = Node3D.new()
	_cube_root.name = "CubeRoot"
	_cube_root.position = _cube_home
	add_child(_cube_root)

	var half: float = CUBE_SIZE / 2.0
	# 8 corners of a unit cube
	var corners := [
		Vector3(-half, -half, -half), Vector3(half, -half, -half),
		Vector3(half, half, -half), Vector3(-half, half, -half),
		Vector3(-half, -half, half), Vector3(half, -half, half),
		Vector3(half, half, half), Vector3(-half, half, half),
	]
	# 12 edges as index pairs
	var edges := [
		[0,1],[1,2],[2,3],[3,0],  # back face
		[4,5],[5,6],[6,7],[7,4],  # front face
		[0,4],[1,5],[2,6],[3,7],  # connecting edges
	]

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.85, 0.95)
	mat.emission = Color(0.3, 0.85, 0.95)
	mat.emission_energy_multiplier = 0.6

	for edge in edges:
		var a: Vector3 = corners[edge[0]]
		var b: Vector3 = corners[edge[1]]
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = EDGE_RADIUS
		cyl.bottom_radius = EDGE_RADIUS
		cyl.height = a.distance_to(b)
		mi.mesh = cyl
		mi.material_override = mat

		# Position at midpoint, orient along the edge direction
		mi.position = (a + b) / 2.0
		var dir: Vector3 = (b - a).normalized()
		if dir.is_equal_approx(Vector3.UP):
			pass  # default cylinder orientation
		elif dir.is_equal_approx(Vector3.DOWN):
			mi.rotation.z = PI
		else:
			var axis: Vector3 = Vector3.UP.cross(dir).normalized()
			var angle: float = acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0))
			if axis.length() > 0.001:
				mi.transform.basis = Basis(axis, angle)
				mi.position = (a + b) / 2.0

		_cube_root.add_child(mi)
		_edge_meshes.append(mi)

	# Reference axes at cube center (small colored lines). Length is derived from
	# CUBE_SIZE so that at SCALE_MAX + full travel the indicators still clear the
	# vitrine walls — the cube and its axes never leave their own box.
	_add_axis_indicator(_cube_root, Vector3.RIGHT * AXIS_LEN, Color(1, 0.3, 0.3))
	_add_axis_indicator(_cube_root, Vector3.UP * AXIS_LEN, Color(0.3, 1, 0.3))
	_add_axis_indicator(_cube_root, Vector3.BACK * AXIS_LEN, Color(0.3, 0.3, 1))


func _add_axis_indicator(parent: Node3D, direction: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.001
	cyl.bottom_radius = 0.003
	cyl.height = direction.length()
	mi.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mi.material_override = mat

	mi.position = direction / 2.0
	var dir: Vector3 = direction.normalized()
	if not dir.is_equal_approx(Vector3.UP) and not dir.is_equal_approx(Vector3.DOWN):
		var axis: Vector3 = Vector3.UP.cross(dir).normalized()
		var angle: float = acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0))
		if axis.length() > 0.001:
			mi.transform.basis = Basis(axis, angle)
			mi.position = direction / 2.0
	parent.add_child(mi)


# ═════════════════════════════════════════════════════════════════════
# MATRIX DISPLAY — the LEFT bay's face
# ═════════════════════════════════════════════════════════════════════
# The hand-rolled backing plate, the two bracket Label3Ds and the overhead
# "TRANSFORM MATRIX" tag are gone: the pocket in _create_cabinet() is the
# backing, the brackets are MILLED as worn-metal hardware, and the name is
# carried by the cap sign band plus a baked header inside the pocket.

func _build_matrix_display() -> void:
	# 4x4 grid of live cells, laid onto the left bay's lit face.
	for row in 4:
		for col in 4:
			var lbl := Label3D.new()
			lbl.name = "M_%d_%d" % [row, col]
			lbl.text = "0.00"
			lbl.pixel_size = 0.0016
			lbl.font_size = 16
			lbl.modulate = Color(0.9, 0.85, 0.5)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.position = _matrix_origin + Vector3(
				float(col) * MATRIX_CELL_SPACING,
				-float(row) * MATRIX_CELL_SPACING,
				0.0
			)
			add_child(lbl)
			_matrix_labels.append(lbl)


# ═════════════════════════════════════════════════════════════════════
# PANEL
# ═════════════════════════════════════════════════════════════════════

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	# Two rows, not five: a 0.172 x 0.409 column cannot sit on any shoulder.
	# 0.476 x 0.19 lies flat on the wedge. Title is empty — the cap sign band
	# owns the name now, so the pad carries no second title into the air.
	_panel = RackTpl.create_panel("", [
		[
			{"type": "slider_h", "label": "MOVE X", "default": 0.5},
			{"type": "slider_h", "label": "MOVE Y", "default": 0.5},
			{"type": "slider_h", "label": "MOVE Z", "default": 0.5},
		],
		[
			{"type": "slider_h", "label": "ROTATE", "default": 0.0},
			{"type": "slider_h", "label": "SCALE", "default": 0.33},
		],
	])
	# Seated ON the wedge shoulder built in _create_cabinet(): the wedge's
	# 0.07-over-0.20 profile is 19.3 degrees, which is the -20 the pad is
	# tilted by, so the faceplate lies on the slope instead of hanging in air.
	_panel.position = Vector3(0.0, 0.30, _bd / 2.0 + 0.077)
	_panel.rotation_degrees = Vector3(-20, 0, 0)
	add_child(_panel)

	# Connect all sliders
	for i in 5:
		var slider: Node = _panel.find_child("Param_%d" % i, true, false)
		if slider and slider.has_signal("slider_moved"):
			slider.slider_moved.connect(_on_slider_changed)


func _on_slider_changed(_value: float) -> void:
	# The panel is held as a member: with an empty title RackTemplates leaves
	# the node unnamed, so the old get_node_or_null("MATRIX_VIEWER") lookup
	# would silently find nothing.
	if not _panel or not is_instance_valid(_panel):
		return

	# Read all 5 sliders
	for i in 5:
		var slider: Node = _panel.find_child("Param_%d" % i, true, false)
		if slider and slider.has_method("get_normalized_value"):
			var norm: float = slider.get_normalized_value()
			match i:
				0: _translate.x = (norm - 0.5) * 2.0 * TRAVEL
				1: _translate.y = (norm - 0.5) * 2.0 * TRAVEL
				2: _translate.z = (norm - 0.5) * 2.0 * TRAVEL
				3: _rotate_y = norm * 360.0  # 0 to 360
				4: _scale_uniform = SCALE_MIN + norm * (SCALE_MAX - SCALE_MIN)

	_update_transform()


# ═════════════════════════════════════════════════════════════════════
# UPDATE
# ═════════════════════════════════════════════════════════════════════

func _update_transform() -> void:
	# Build Transform3D from slider values
	var xform := Transform3D.IDENTITY
	xform = xform.scaled(Vector3.ONE * _scale_uniform)
	xform = xform.rotated(Vector3.UP, deg_to_rad(_rotate_y))
	xform.origin = _translate

	# Apply to cube — one home coordinate, shared with _build_wireframe_cube()
	if _cube_root:
		var local_xform := xform
		local_xform.origin += _cube_home
		_cube_root.transform = local_xform

	# Update matrix labels
	var basis := xform.basis
	var origin := xform.origin
	# Godot uses column-major: basis[col][row]
	# Display as row-major 4x4 for standard math notation
	var values := [
		basis[0].x, basis[1].x, basis[2].x, origin.x,
		basis[0].y, basis[1].y, basis[2].y, origin.y,
		basis[0].z, basis[1].z, basis[2].z, origin.z,
		0.0, 0.0, 0.0, 1.0,
	]

	# Color coding: rotation/scale = cyan, translation = green, bottom row = gray
	var color_rotation := Color(0.3, 0.85, 0.95)
	var color_translation := Color(0.3, 0.95, 0.4)
	var color_bottom := Color(0.5, 0.5, 0.5)

	for i in 16:
		if i < _matrix_labels.size():
			# "%6.2f" padded each cell to ~0.063 m inside a 0.045 m slot — the
			# cells overlapped. Centred text needs no pad.
			_matrix_labels[i].text = "%.2f" % values[i]
			var row: int = i / 4
			var col: int = i % 4
			if row == 3:
				_matrix_labels[i].modulate = color_bottom
			elif col == 3:
				_matrix_labels[i].modulate = color_translation
			else:
				_matrix_labels[i].modulate = color_rotation


# ═════════════════════════════════════════════════════════════════════
# THE CABINET — correspondence console (vertical dialect)
# ═════════════════════════════════════════════════════════════════════
## Twin equal bays across a mullion: numbers left, geometry right, one cap over
## both. Back slab, maroon flanks on both outer edges (a symmetric body states
## its flank twice), a glazed vitrine over the cube, a seated anthracite pocket
## under the 16 cells, the keypad on a wedge shoulder spanning the mullion, a
## sign-band cap over a full-width ember line, vent slats in the apron, and a
## plinth as the sole base.

func _create_cabinet() -> void:
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)      # so the grammar probe scopes its rules here
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
	glass_mat.albedo_color = Color(0.62, 0.72, 0.85, 0.055)   # PALE window glass:
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA  # the cube reads THROUGH it
	glass_mat.roughness = 0.1

	var half_w: float = _total_w / 2.0
	var face_z: float = _bd / 2.0
	var bays_w: float = 2.0 * _bay_w + _mull
	var win_cy: float = _win_bot + _win_h / 2.0

	# ── Ground: the back slab spanning the whole body ───────────────────
	cab.add_child(HangarKit.box(Vector3(0.0, _body_top / 2.0, -face_z - 0.03),
		Vector3(_total_w, _body_top, 0.05), shell))

	# ── Flank: maroon side trims, full height, on BOTH outer edges ──────
	for fx in [-(half_w - _trim / 2.0), half_w - _trim / 2.0]:
		var fxv: float = fx
		cab.add_child(HangarKit.box(Vector3(fxv, _body_top / 2.0, 0.0),
			Vector3(_trim, _body_top, _bd + 0.06), maroon))

	# ── The mullion: the body's statement that the two bays are equal ───
	cab.add_child(HangarKit.box(Vector3(0.0, _body_top / 2.0, 0.0),
		Vector3(_mull, _body_top, _bd + 0.04), shell))
	# the ember signature runs up its face (the mullion front sits 0.020 proud
	# of the frame bands, so the strip is seated in it, not hovering off it)
	cab.add_child(HangarKit.box(Vector3(0.0, win_cy, face_z + 0.022),
		Vector3(0.008, _win_h, 0.006), accent))
	# bolt rows down both mullion edges, above the shoulder so nothing buries them
	for bx in [-(_mull / 2.0 - 0.008), _mull / 2.0 - 0.008]:
		var bxv: float = bx
		cab.add_child(HangarKit.bolts(
			Vector3(bxv, _win_bot + 0.02, face_z + 0.022),
			Vector3(bxv, _win_top, face_z + 0.022),
			7, 0.009, steel))

	# ── Frame bands, so the bays read as apertures cut in ONE face ──────
	cab.add_child(HangarKit.box(Vector3(0.0, (_win_top + _body_top) / 2.0, 0.0),
		Vector3(bays_w, _body_top - _win_top, _bd + 0.02), shell))
	cab.add_child(HangarKit.box(Vector3(0.0, _win_bot / 2.0, 0.0),
		Vector3(bays_w, _win_bot, _bd + 0.02), shell))

	# ── RIGHT BAY: the vitrine over the cube ────────────────────────────
	cab.add_child(HangarKit.box(Vector3(_bay_b_x, win_cy, -_win_d / 2.0 + 0.006),
		Vector3(_bay_w, _win_h, 0.012), dark))                       # dark backdrop
	cab.add_child(HangarKit.box(Vector3(_bay_b_x, _win_bot - 0.008, 0.0),
		Vector3(_bay_w, 0.016, _win_d), dark))                       # bay floor
	cab.add_child(HangarKit.box(Vector3(_bay_b_x, _win_top + 0.008, 0.0),
		Vector3(_bay_w, 0.016, _win_d), dark))                       # bay ceiling
	cab.add_child(HangarKit.box(Vector3(_bay_b_x, win_cy, face_z + 0.004),
		Vector3(_bay_w - 0.02, _win_h, 0.004), glass_mat))           # pale glass
	cab.add_child(HangarKit.box(Vector3(_bay_b_x, _win_bot - 0.010, face_z + 0.014),
		Vector3(_bay_w - 0.02, 0.006, 0.006), accent))               # ember lip

	# ── LEFT BAY: the seated readout pocket under the 16 cells ──────────
	cab.add_child(HangarKit.box(Vector3(_bay_a_x, win_cy, face_z - 0.030),
		Vector3(_scr_w + 0.05, _win_h, 0.05), dark))                 # the pocket
	cab.add_child(HangarKit.box(Vector3(_bay_a_x, win_cy, face_z - 0.012),
		Vector3(_scr_w, _win_h - 0.02, 0.012),
		HangarKit.emissive(HangarKit.DISPLAY_DARK, 0.32)))           # lit face, inset
	cab.add_child(HangarKit.box(Vector3(_bay_a_x, _win_top - 0.012, face_z - 0.004),
		Vector3(_scr_w, 0.005, 0.006), accent))                      # ember lip

	# Brackets MILLED as hardware, not typed as text: a spine plus two returns
	# flanking the cell grid, so the notation is part of the faceplate.
	var cells_cy: float = _matrix_origin.y - 1.5 * MATRIX_CELL_SPACING
	var br_off: float = 1.5 * MATRIX_CELL_SPACING + 0.055
	var br_z: float = face_z - 0.004
	for s in [-1.0, 1.0]:
		var sv: float = s
		var bx2: float = _bay_a_x + sv * br_off
		var din: float = -sv
		cab.add_child(HangarKit.box(Vector3(bx2, cells_cy, br_z),
			Vector3(0.004, 0.26, 0.006), steel))
		for yy in [cells_cy - 0.128, cells_cy + 0.128]:
			var yv: float = yy
			cab.add_child(HangarKit.box(Vector3(bx2 + din * 0.017, yv, br_z),
				Vector3(0.030, 0.004, 0.006), steel))

	# The pocket's own baked header — the retired floating title, printed on.
	var hdr: MeshInstance3D = HangarKit.stencil("TRANSFORM MATRIX",
		Vector2(_scr_w * 0.72, 0.024), col_accent.lightened(0.25))
	if hdr:
		hdr.position = Vector3(_bay_a_x, _win_top - 0.045, face_z - 0.003)
		cab.add_child(hdr)

	# ── Controls: the wedge shoulder the pad rests on (spans the mullion) ─
	var shoulder: MeshInstance3D = HangarKit.wedge(0.52, 0.20, 0.10, 0.03, dark)
	shoulder.position = Vector3(0.0, 0.30, face_z + 0.005)
	cab.add_child(shoulder)

	# ── Service, signage and age ────────────────────────────────────────
	# Vent slats sit PROUD of the apron face (a slot milled into a solid box
	# would simply be invisible) — the same read as the kiosk's grille.
	for gi in range(5):
		cab.add_child(HangarKit.box(
			Vector3(0.38, 0.14 + float(gi) * 0.024, face_z + 0.011),
			Vector3(0.18, 0.010, 0.012), dark))
	var bar: Node3D = HangarKit.three_color_bar(0.18, 0.016)
	if bar:
		bar.position = Vector3(-0.38, 0.24, face_z + 0.012)
		cab.add_child(bar)

	# Cap: sign band over a full-width ember line
	cab.add_child(HangarKit.box(Vector3(0.0, _body_top + _cap_h / 2.0, 0.0),
		Vector3(_total_w, _cap_h, _bd + 0.10), shell))
	cab.add_child(HangarKit.box(Vector3(0.0, _body_top + 0.005, face_z + 0.052),
		Vector3(_total_w, 0.007, 0.004), accent))
	cab.add_child(HangarKit.box(Vector3(0.0, _body_top + _cap_h / 2.0, face_z + 0.050),
		Vector3(_total_w - 0.10, 0.072, 0.012), dark))
	var sign_title: Node3D = BakedText.make_tag(
		"MATRIX 4x4", Color(0.93, 0.94, 0.97), 0.030,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title:
		sign_title.position = Vector3(0.0, _body_top + _cap_h / 2.0 + 0.014, face_z + 0.058)
		cab.add_child(sign_title)
	var sign_sub: Node3D = BakedText.make_tag(
		"SIXTEEN NUMBERS, ONE TRANSFORM", Color(0.55, 0.58, 0.66), 0.014,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_sub:
		sign_sub.position = Vector3(0.0, _body_top + _cap_h / 2.0 - 0.020, face_z + 0.058)
		cab.add_child(sign_sub)

	# A machine carries an asset code, not only a title.
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.13, 0.032),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-half_w + 0.16, 0.10, face_z + 0.014)
		cab.add_child(code)

	# Age at the base only: grime_band is an opaque dirt shadow, and dust
	# streaks over a vitrine read as smears on the phenomenon.
	var gb: MeshInstance3D = HangarKit.grime_band(_total_w * 0.9, 0.055,
		face_z + 0.014, col_body)
	if gb:
		gb.position.x = 0.0                # keep the kit's baked y and z
		cab.add_child(gb)

	# ── Footing ─────────────────────────────────────────────────────────
	if plinth_height <= 0.0:
		cab.add_child(HangarKit.box(Vector3(0.0, 0.045, 0.0),
			Vector3(_total_w, 0.09, _bd + 0.12), dark))
		for fx2 in [-(half_w - 0.09), half_w - 0.09]:
			var fx2v: float = fx2
			cab.add_child(HangarKit.box(Vector3(fx2v, 0.012, 0.0),
				Vector3(0.11, 0.024, _bd + 0.08), dark))
	else:
		# The plinth is the SOLE base — two bases strand a dark slab mid-body.
		var ped: Node3D = HangarKit.plinth(_total_w, _bd + 0.14, plinth_height,
			finish, ew, col_accent, unit_code)
		if ped:
			cab.add_child(ped)


func apply_grid_config(config: Dictionary) -> void:
	pass
