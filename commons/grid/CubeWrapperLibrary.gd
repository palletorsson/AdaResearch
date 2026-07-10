# CubeWrapperLibrary.gd — the sim-cube wrapper: THE GRID CELL MADE VISIBLE.
# One chassis (the invariant hand-grammar: base plate, label plate, touch
# corner, accent line, centered mount point) + five FAMILY expressions so
# housed artifacts stay recognizable by nature (Palle: "room for more cube
# families so we do not collapse all objects"):
#   gridglass — glazed, steel-cool, grid-lined: discrete worlds (CA, arrays)
#   tank      — liquid tint, brass-warm, hover+shadow: continuous physics
#   cage      — mesh bars, dark: agents — things that could get out
#   shadowbox — one open face, dark, backlit: luminous curves
#   openframe — edges only, lab-white: growth — things that should breathe
# Declarations: commons/data/principal_artifacts.json (wrappers.cube_families).
# Consumers: sim_cube artifact (runtime), export_cube_gltf.gd (browser).
extends RefCounted

const S := 2.0            # the housing: 2m (artifacts overflowed 1m — Palle)
const PLINTH_H := 1.0     # every sim-cube stands on a 1m cube plinth by default
const EDGE := 0.035
const BASE_H := 0.06

var mat_steel: StandardMaterial3D
var mat_brass: StandardMaterial3D
var mat_dark: StandardMaterial3D
var mat_white: StandardMaterial3D
var mat_glass: StandardMaterial3D
var mat_tankglass: StandardMaterial3D
var mat_amber: StandardMaterial3D
var mat_plate: StandardMaterial3D
var mat_backlight: StandardMaterial3D

const FAMILIES := ["gridglass", "tank", "cage", "shadowbox", "openframe",
	"table_display_1m", "table_display_2m", "podium", "plinth", "frame"]


func _init() -> void:
	mat_steel = _m(Color(0.45, 0.48, 0.52), 0.4, 0.6)
	mat_brass = _m(Color(0.62, 0.5, 0.3), 0.35, 0.7)
	mat_dark = _m(Color(0.1, 0.11, 0.12), 0.55, 0.4)
	mat_white = _m(Color(0.9, 0.9, 0.88), 0.6, 0.0)
	mat_glass = _m(Color(0.75, 0.82, 0.86, 0.16), 0.05, 0.1)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_tankglass = _m(Color(0.45, 0.72, 0.7, 0.3), 0.05, 0.1)
	mat_tankglass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_amber = _m(Color(1.0, 0.62, 0.18), 0.5, 0.0)
	mat_amber.emission_enabled = true
	mat_amber.emission = Color(1.0, 0.55, 0.15)
	mat_amber.emission_energy_multiplier = 1.4
	mat_plate = _m(Color(0.85, 0.83, 0.78), 0.3, 0.2)
	mat_backlight = _m(Color(0.85, 0.9, 1.0), 0.8, 0.0)
	mat_backlight.emission_enabled = true
	mat_backlight.emission = Color(0.7, 0.8, 1.0)
	mat_backlight.emission_energy_multiplier = 0.9


func _m(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


func build(family: String, accent: StandardMaterial3D = null) -> Node3D:
	"""origin at bottom-centre (plinth base); interior clear for the mount."""
	var n := Node3D.new()
	var acc := accent if accent != null else mat_amber
	# stand families: no plinth, no housing — table displays and the podium
	if family == "table_display_1m":
		_table_display(n, acc, 1.0)
		return n
	if family == "table_display_2m":
		_table_display(n, acc, 2.0)
		return n
	if family == "podium":
		_podium(n, acc)
		return n
	if family == "plinth":
		_plinth(n, acc)
		return n
	if family == "frame":
		_frame(n, acc)
		return n
	# the default 1m cube plinth under every housing
	_box(n, Vector3(1.0, PLINTH_H, 1.0), Vector3(0, PLINTH_H * 0.5, 0), mat_dark)
	_box(n, Vector3(1.06, 0.05, 1.06), Vector3(0, PLINTH_H - 0.025, 0), mat_steel)
	var housing := Node3D.new()
	housing.name = "Housing"
	housing.position.y = PLINTH_H
	n.add_child(housing)
	var hover := 0.0
	if family in ["tank", "openframe"]:
		hover = 0.05                        # the momo shadow gap
	_chassis(housing, acc, hover)
	match family:
		"gridglass": _f_gridglass(housing, hover)
		"tank": _f_tank(housing, hover)
		"cage": _f_cage(housing, hover)
		"shadowbox": _f_shadowbox(housing, hover)
		"openframe": _f_openframe(housing, hover, mat_white)
		_: _f_openframe(housing, hover, mat_steel)
	return n


func mount_point(family: String) -> Vector3:
	"""where the housed artifact's origin should sit (local)."""
	if family in ["table_display_1m", "table_display_2m"]:
		return Vector3(0, 0.82, -0.28)     # on the table, against the panel
	if family == "podium":
		return Vector3(0, 1.14, 0)          # the operating surface
	if family == "plinth":
		return Vector3(0, 1.0, 0)           # on the top plate
	if family == "frame":
		return Vector3(0, 0.85, 0.06)       # in front of the backing, low anchor
	var hover := 0.05 if family in ["tank", "openframe"] else 0.0
	return Vector3(0, PLINTH_H + hover + BASE_H + 0.01, 0)


# ── stand families ───────────────────────────────────────────────────────────
func _table_display(n: Node3D, acc: StandardMaterial3D, w: float) -> void:
	"""a table with a FRAMELESS vertical panel — 2D content edge to edge."""
	var top_y := 0.78
	# slim steel legs + dark top slab
	for sx in [-w * 0.5 + 0.06, w * 0.5 - 0.06]:
		for sz in [-0.32, 0.32]:
			_box(n, Vector3(0.05, top_y, 0.05), Vector3(sx, top_y * 0.5, sz), mat_steel)
	_box(n, Vector3(w, 0.05, 0.8), Vector3(0, top_y + 0.025, 0), mat_dark)
	# the frameless panel: one thin bright surface, no border, full width
	var panel_h := 1.25
	_box(n, Vector3(w, panel_h, 0.022),
		Vector3(0, top_y + 0.05 + panel_h * 0.5, -0.34), mat_white)
	# two small stand tabs behind (invisible from the front)
	for sx in [-w * 0.25, w * 0.25]:
		_box(n, Vector3(0.05, 0.3, 0.05), Vector3(sx, top_y + 0.2, -0.395), mat_dark)
	# the hand-grammar on the table's front edge
	_box(n, Vector3(0.34, 0.08, 0.012), Vector3(-w * 0.5 + 0.24, top_y - 0.06, 0.4), mat_plate)
	_box(n, Vector3(0.08, 0.08, 0.02), Vector3(w * 0.5 - 0.12, top_y - 0.06, 0.4), acc)
	_box(n, Vector3(w, 0.018, 0.014), Vector3(0, top_y + 0.055, 0.4), acc)


func _podium(n: Node3D, acc: StandardMaterial3D) -> void:
	"""the operating stand — a small interactive at hand height (coin_toss)."""
	_box(n, Vector3(0.5, 0.08, 0.5), Vector3(0, 0.04, 0), mat_dark)      # foot
	_box(n, Vector3(0.4, 0.96, 0.4), Vector3(0, 0.08 + 0.48, 0), mat_dark)
	_box(n, Vector3(0.62, 0.06, 0.62), Vector3(0, 1.1, 0), mat_steel)    # top
	_box(n, Vector3(0.62, 0.03, 0.08), Vector3(0, 1.085, 0.31), mat_dark)  # lip
	# hand-grammar on the column front
	_box(n, Vector3(0.3, 0.08, 0.012), Vector3(-0.04, 0.9, 0.21), mat_plate)
	_box(n, Vector3(0.07, 0.07, 0.018), Vector3(0.14, 0.78, 0.21), acc)
	_box(n, Vector3(0.4, 0.016, 0.014), Vector3(0, 1.07, 0.21), acc)


func _plinth(n: Node3D, acc: StandardMaterial3D) -> void:
	"""the display column — a small thing held to the eye on a top plate."""
	_box(n, Vector3(0.66, 0.05, 0.66), Vector3(0, 0.025, 0), mat_dark)     # foot plate
	_box(n, Vector3(0.5, 0.95, 0.5), Vector3(0, 0.05 + 0.475, 0), mat_dark)  # column
	_box(n, Vector3(0.6, 0.04, 0.6), Vector3(0, 0.98, 0), mat_steel)       # top plate
	# hand-grammar on the column front (+Z)
	_box(n, Vector3(0.3, 0.08, 0.012), Vector3(-0.04, 0.78, 0.251), mat_plate)
	_box(n, Vector3(0.07, 0.07, 0.018), Vector3(0.15, 0.66, 0.251), acc)
	_box(n, Vector3(0.4, 0.016, 0.014), Vector3(0, 0.92, 0.251), acc)


func _frame(n: Node3D, acc: StandardMaterial3D) -> void:
	"""a freestanding framed display for flat work — the panel HOVERS above the base."""
	_box(n, Vector3(1.2, 0.08, 0.3), Vector3(0, 0.04, 0), mat_dark)        # base bar
	# two slim posts rising from the ends
	for px in [-0.56, 0.56]:
		_box(n, Vector3(0.05, 2.2, 0.05), Vector3(px, 0.08 + 1.1, 0), mat_dark)
	# the framed panel — dark border around an inset white backing, centred ~1.45m
	var pw := 1.1
	var ph := 1.4
	var cy := 1.45
	_box(n, Vector3(pw, ph, 0.05), Vector3(0, cy, 0), mat_dark)            # frame border
	_box(n, Vector3(pw - 0.1, ph - 0.1, 0.03), Vector3(0, cy, 0.011), mat_white)  # inset backing
	# hand-grammar on the base bar front (+Z)
	_box(n, Vector3(0.3, 0.05, 0.012), Vector3(-0.4, 0.05, 0.151), mat_plate)
	_box(n, Vector3(0.06, 0.06, 0.018), Vector3(0.48, 0.05, 0.151), acc)
	_box(n, Vector3(1.2, 0.014, 0.014), Vector3(0, 0.075, 0.151), acc)


# ── the chassis: the one hand-grammar ────────────────────────────────────────
func _chassis(n: Node3D, acc: StandardMaterial3D, hover: float) -> void:
	var y0 := hover
	_box(n, Vector3(S, BASE_H, S), Vector3(0, y0 + BASE_H * 0.5, 0), mat_dark)
	# label plate — lower front left
	_box(n, Vector3(0.34, 0.1, 0.012), Vector3(-0.28, y0 + BASE_H + 0.07, S * 0.5), mat_plate)
	# touch corner — lower front right, emissive
	_box(n, Vector3(0.09, 0.09, 0.02), Vector3(0.4, y0 + BASE_H + 0.065, S * 0.5), acc)
	# accent line along the base front edge
	_box(n, Vector3(S, 0.02, 0.015), Vector3(0, y0 + BASE_H + 0.005, S * 0.5), acc)


func _edges(n: Node3D, mat: StandardMaterial3D, y0: float, h: float) -> void:
	var hs := S * 0.5
	for sx in [-hs, hs]:
		for sz in [-hs, hs]:
			_box(n, Vector3(EDGE, h, EDGE), Vector3(sx, y0 + h * 0.5, sz), mat)
	for sy in [y0, y0 + h]:
		for sz in [-hs, hs]:
			_box(n, Vector3(S, EDGE, EDGE), Vector3(0, sy, sz), mat)
		for sx in [-hs, hs]:
			_box(n, Vector3(EDGE, EDGE, S), Vector3(sx, sy, 0), mat)


# ── the families ─────────────────────────────────────────────────────────────
func _f_gridglass(n: Node3D, hover: float) -> void:
	var y0 := hover + BASE_H
	var h := S - BASE_H
	_edges(n, mat_steel, y0, h)
	for sz in [-S * 0.5, S * 0.5]:
		_box(n, Vector3(S - 0.08, h - 0.08, 0.012), Vector3(0, y0 + h * 0.5, sz), mat_glass)
	for sx in [-S * 0.5, S * 0.5]:
		_box(n, Vector3(0.012, h - 0.08, S - 0.08), Vector3(sx, y0 + h * 0.5, 0), mat_glass)
	_box(n, Vector3(S - 0.08, 0.012, S - 0.08), Vector3(0, y0 + h, 0), mat_glass)
	# the grid lines — back pane carries the substrate look
	for i in 3:
		var t := -S * 0.5 + (i + 1) * S * 0.25
		_box(n, Vector3(0.008, h - 0.1, 0.014), Vector3(t, y0 + h * 0.5, -S * 0.5 + 0.002), mat_steel)
		_box(n, Vector3(S - 0.1, 0.008, 0.014), Vector3(0, y0 + BASE_H + (i + 1) * (h - 0.1) * 0.25, -S * 0.5 + 0.002), mat_steel)


func _f_tank(n: Node3D, hover: float) -> void:
	var y0 := hover + BASE_H
	var h := S - BASE_H
	_edges(n, mat_brass, y0, h)
	for sz in [-S * 0.5, S * 0.5]:
		_box(n, Vector3(S - 0.06, h - 0.06, 0.014), Vector3(0, y0 + h * 0.5, sz), mat_tankglass)
	for sx in [-S * 0.5, S * 0.5]:
		_box(n, Vector3(0.014, h - 0.06, S - 0.06), Vector3(sx, y0 + h * 0.5, 0), mat_tankglass)
	_box(n, Vector3(S - 0.06, 0.014, S - 0.06), Vector3(0, y0 + h, 0), mat_tankglass)
	# low backlight panel inside the back wall
	_box(n, Vector3(S - 0.12, h - 0.2, 0.008), Vector3(0, y0 + h * 0.5, -S * 0.5 + 0.03), mat_backlight)


func _f_cage(n: Node3D, hover: float) -> void:
	var y0 := hover + BASE_H
	var h := S - BASE_H
	_edges(n, mat_dark, y0, h)
	for i in 5:
		var t := -S * 0.5 + (i + 1) * S / 6.0
		for sz in [-S * 0.5, S * 0.5]:
			_box(n, Vector3(0.018, h, 0.018), Vector3(t, y0 + h * 0.5, sz), mat_dark)
		for sx in [-S * 0.5, S * 0.5]:
			_box(n, Vector3(0.018, h, 0.018), Vector3(sx, y0 + h * 0.5, t), mat_dark)
	_box(n, Vector3(S, 0.03, S), Vector3(0, y0 + h, 0), mat_dark)


func _f_shadowbox(n: Node3D, hover: float) -> void:
	var y0 := hover + BASE_H
	var h := S - BASE_H
	_box(n, Vector3(S, h, 0.03), Vector3(0, y0 + h * 0.5, -S * 0.5), mat_dark)
	for sx in [-S * 0.5, S * 0.5]:
		_box(n, Vector3(0.03, h, S), Vector3(sx, y0 + h * 0.5, 0), mat_dark)
	_box(n, Vector3(S, 0.03, S), Vector3(0, y0 + h, 0), mat_dark)
	# the backlight the subject glows against
	_box(n, Vector3(S - 0.1, h - 0.1, 0.01), Vector3(0, y0 + h * 0.5, -S * 0.5 + 0.03), mat_backlight)


func _f_openframe(n: Node3D, hover: float, mat: StandardMaterial3D) -> void:
	_edges(n, mat, hover + BASE_H, S - BASE_H)
