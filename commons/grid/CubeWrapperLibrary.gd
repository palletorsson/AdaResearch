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

const FAMILIES := ["gridglass", "tank", "cage", "shadowbox", "openframe"]


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
	var hover := 0.05 if family in ["tank", "openframe"] else 0.0
	return Vector3(0, PLINTH_H + hover + BASE_H + 0.01, 0)


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
