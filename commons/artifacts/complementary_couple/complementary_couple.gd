extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ComplementaryCouple

## @identity
## lineage: the color taxonomy's rung 9 — two armchairs facing each other over a rug,
##   locked in complement: whatever hue one chair drifts to, the other answers from
##   exactly across the wheel. A hue ring inlaid in the rug carries two markers
##   orbiting in permanent opposition, so the arithmetic of the marriage is visible
##   at their feet.
## essence: the engine has no word for harmony — no Color property relates two colours.
##   Complement is CULTURE: h and h+0.5, a promise two objects keep to each other.
##   These chairs keep it forever, drifting through every pairing the wheel owns.
## truth: a chord is a relation BETWEEN triples. No triple is harmonious alone.
##
## The 2026-08-27 color taxonomy (doc/COLOR_TAXONOMY.md), rung 9 of 12.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 29
## Hue drift in wheel-turns per minute. 0.5 crosses every complementary pair in 2 min.
@export var drift: float = 0.5

var _h0 := 0.0
var _mat_a: StandardMaterial3D
var _mat_b: StandardMaterial3D
var _marker_a: Node3D
var _marker_b: Node3D

func _ready() -> void:
	_rng.seed = seed
	_h0 = _rng.randf()
	_build_rug()
	_mat_a = _matte_mat(Color.from_hsv(_h0, 0.8, 0.85), 0.7)
	_mat_b = _matte_mat(Color.from_hsv(fmod(_h0 + 0.5, 1.0), 0.8, 0.85), 0.7)
	_build_chair(Vector3(-0.85, 0.0, 0.0), 0.0, _mat_a)
	_build_chair(Vector3(0.85, 0.0, 0.0), PI, _mat_b)
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "drift"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(_delta: float) -> void:
	var t := float(Time.get_ticks_msec()) / 1000.0
	var h := fmod(_h0 + drift * t / 60.0, 1.0)
	var hb := fmod(h + 0.5, 1.0)
	_mat_a.albedo_color = Color.from_hsv(h, 0.8, 0.85)
	_mat_b.albedo_color = Color.from_hsv(hb, 0.8, 0.85)
	if _marker_a:
		_marker_a.position = Vector3(cos(TAU * h) * 0.62, 0.055, sin(TAU * h) * 0.62)
		_marker_b.position = Vector3(cos(TAU * hb) * 0.62, 0.055, sin(TAU * hb) * 0.62)

# --- the rug and its wheel ----------------------------------------------------------

func _build_rug() -> void:
	var rug := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.95
	rm.bottom_radius = 0.95
	rm.height = 0.03
	rug.mesh = rm
	rug.position = Vector3(0.0, 0.015, 0.0)
	rug.material_override = _matte_mat(Color(0.13, 0.11, 0.10), 0.95)
	add_child(rug)
	# the hue ring: twelve inlaid segments, the wheel the couple is married on
	for i in range(12):
		var h := float(i) / 12.0
		var seg := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.3, 0.012, 0.09)
		seg.mesh = sm
		var ang := TAU * h
		seg.position = Vector3(cos(ang) * 0.62, 0.035, sin(ang) * 0.62)
		seg.rotation.y = -ang + PI * 0.5
		seg.material_override = _matte_mat(Color.from_hsv(h, 0.85, 0.8), 0.6)
		add_child(seg)
	_marker_a = _marker()
	_marker_b = _marker()

func _marker() -> Node3D:
	var m := MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 0.045
	mm.height = 0.09
	m.mesh = mm
	m.material_override = _glow_mat(Color(0.95, 0.95, 0.95), 1.2)
	add_child(m)
	return m

# --- a chair ------------------------------------------------------------------------

func _build_chair(at: Vector3, facing: float, mat: StandardMaterial3D) -> void:
	var chair := Node3D.new()
	chair.position = at
	chair.rotation.y = facing
	add_child(chair)
	var dark := _matte_mat(Color(0.1, 0.09, 0.09), 0.85)
	var seat := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.62, 0.16, 0.6)
	seat.mesh = sm
	seat.position = Vector3(0.0, 0.36, 0.0)
	seat.material_override = mat
	chair.add_child(seat)
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.62, 0.62, 0.14)
	back.mesh = bm
	back.position = Vector3(0.0, 0.72, 0.26)
	back.rotation.x = deg_to_rad(-8.0)
	back.material_override = mat
	chair.add_child(back)
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(0.12, 0.3, 0.6)
		arm.mesh = am
		arm.position = Vector3(side * 0.37, 0.51, 0.0)
		arm.material_override = mat
		chair.add_child(arm)
		for fz in [-1.0, 1.0]:
			var leg := MeshInstance3D.new()
			var lm := CylinderMesh.new()
			lm.top_radius = 0.025
			lm.bottom_radius = 0.03
			lm.height = 0.28
			leg.mesh = lm
			leg.position = Vector3(side * 0.26, 0.14, fz * 0.24)
			leg.material_override = dark
			chair.add_child(leg)

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CouplePlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(0.0, 0.24, 1.25)
	ts.rotation.y = deg_to_rad(0.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("COMPLEMENTARY COUPLE",
			"The engine has no word for harmony - no property relates two colours.\nComplement is a promise: h and h + 180, kept here forever. The markers\nin the rug are the couple's positions on the wheel, always across.")
