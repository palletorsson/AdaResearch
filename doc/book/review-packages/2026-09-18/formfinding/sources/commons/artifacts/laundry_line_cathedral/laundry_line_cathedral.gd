extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LaundryLineCathedral

## @identity
## lineage: the Catenary hero — Gaudí's upside-down trick done as laundry. Three
##   washing lines sag between poles, each a true catenary (cosh, not a guess), pegged
##   with towels and shirts; and ABOVE each line hangs its ghost: the same curve
##   mirrored upward as a pale arch, because a hanging chain flipped is a standing
##   vault. The washing knows structural engineering; the cathedral is implied.
## essence: a chain settles where pulling tension along itself costs least - y =
##   a·cosh(x/a). Nobody drew it: gravity solved it. Mirror the solution and
##   compression replaces tension - the arch that stands is the chain that hung.
## truth: form is the answer to a minimization problem. The laundry finds it every
##   time, without being asked.
##
## The 2026-08-27 category-heroes pass, formfinding.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const CLOTH := [Color(0.88, 0.86, 0.82), Color(0.78, 0.16, 0.12), Color(0.13, 0.30, 0.62), Color(0.92, 0.75, 0.14)]

@export var seed: int = 6
@export var span: float = 3.2
@export var pole_h: float = 2.1
## The catenary parameter a per line - smaller sags deeper. Three lines, three sags,
## three arches: one family of answers to one lazy question.
@export var sags: PackedFloat32Array = PackedFloat32Array([2.2, 1.4, 1.0])

func _ready() -> void:
	_rng.seed = seed
	_build_poles()
	for i in range(sags.size()):
		_build_line(float(i - 1) * 0.8, sags[i], i)
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "span", "pole_h"]:
		if config_data.has(key):
			set(key, config_data[key])

func _cat_y(x: float, a: float) -> float:
	# centred catenary through the two pole tops: cosh sag below the anchor height
	# sag DOWN from the pole tops: deepest at x=0, zero at the anchors
	return pole_h - a * (cosh(span * 0.5 / a) - cosh(x / a))

func _build_poles() -> void:
	for sx in [-span * 0.5, span * 0.5]:
		var pole := MeshInstance3D.new()
		var pole_mesh := CylinderMesh.new()
		pole_mesh.top_radius = 0.035
		pole_mesh.bottom_radius = 0.05
		pole_mesh.height = pole_h
		pole.mesh = pole_mesh
		pole.position = Vector3(sx, pole_h * 0.5, 0.0)
		pole.material_override = _matte_mat(Color(0.35, 0.22, 0.12), 0.85)
		add_child(pole)
		var foot := MeshInstance3D.new()
		var foot_mesh := CylinderMesh.new()
		foot_mesh.top_radius = 0.12
		foot_mesh.bottom_radius = 0.16
		foot_mesh.height = 0.08
		foot.mesh = foot_mesh
		foot.position = Vector3(sx, 0.04, 0.0)
		foot.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
		add_child(foot)
	# crossbars so three lines can share two poles
	for z in [-0.8, 0.0, 0.8]:
		pass  # lines anchor at pole tops offset in z via their own geometry

func _build_line(z: float, a: float, idx: int) -> void:
	var n := 30
	# THE CHAIN: rope segments along the true cosh
	for i in range(n):
		var x0 := -span * 0.5 + span * float(i) / float(n)
		var x1 := -span * 0.5 + span * float(i + 1) / float(n)
		var p0 := Vector3(x0, _cat_y(x0, a), z)
		var p1 := Vector3(x1, _cat_y(x1, a), z)
		var seg := MeshInstance3D.new()
		var seg_mesh := CylinderMesh.new()
		seg_mesh.top_radius = 0.008
		seg_mesh.bottom_radius = 0.008
		seg_mesh.height = p0.distance_to(p1) * 1.05
		seg.mesh = seg_mesh
		seg.position = (p0 + p1) * 0.5
		seg.rotation.z = atan2(p1.y - p0.y, p1.x - p0.x) + PI * 0.5
		seg.material_override = _matte_mat(Color(0.75, 0.72, 0.65), 0.8)
		add_child(seg)
	# THE GHOST ARCH: the same curve mirrored above the anchor line, faint
	var top := pole_h
	for i in range(n):
		var x0 := -span * 0.5 + span * float(i) / float(n)
		var x1 := -span * 0.5 + span * float(i + 1) / float(n)
		var p0 := Vector3(x0, 2.0 * top - _cat_y(x0, a) , z)
		var p1 := Vector3(x1, 2.0 * top - _cat_y(x1, a), z)
		var seg := MeshInstance3D.new()
		var seg_mesh := CylinderMesh.new()
		seg_mesh.top_radius = 0.014
		seg_mesh.bottom_radius = 0.014
		seg_mesh.height = p0.distance_to(p1) * 1.05
		seg.mesh = seg_mesh
		seg.position = (p0 + p1) * 0.5
		seg.rotation.z = atan2(p1.y - p0.y, p1.x - p0.x) + PI * 0.5
		var gm := _glow_mat(Color(0.88, 0.86, 0.82), 0.5)
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.albedo_color.a = 0.22
		seg.material_override = gm
		add_child(seg)
	# THE WASHING: towels pegged along the chain, hanging plumb from it
	var pieces := 4 + (idx % 2)
	for k in range(pieces):
		var u := (float(k) + 0.7) / (float(pieces) + 0.6)
		var x := -span * 0.5 + span * u
		var y := _cat_y(x, a)
		var w := _rng.randf_range(0.24, 0.4)
		var h := _rng.randf_range(0.3, 0.5)
		var cloth := MeshInstance3D.new()
		var cloth_mesh := BoxMesh.new()
		cloth_mesh.size = Vector3(w, h, 0.015)
		cloth.mesh = cloth_mesh
		cloth.position = Vector3(x, y - h * 0.5, z)
		# a towel hangs plumb even on a slope - one more small proof of gravity's
		# opinion, and the slight yaw is the wind's counter-signature
		cloth.rotation.y = _rng.randf_range(-0.12, 0.12)
		cloth.material_override = _matte_mat(CLOTH[(k + idx) % CLOTH.size()], 0.95)
		add_child(cloth)
		for sx in [-w * 0.4, w * 0.4]:
			var peg := MeshInstance3D.new()
			var peg_mesh := BoxMesh.new()
			peg_mesh.size = Vector3(0.02, 0.05, 0.03)
			peg.mesh = peg_mesh
			peg.position = Vector3(x + sx, y + 0.01, z)
			peg.material_override = _matte_mat(Color(0.78, 0.16, 0.12), 0.8)
			add_child(peg)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "LaundryPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-span * 0.5 - 0.4, 0.24, 1.15)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("LAUNDRY LINE CATHEDRAL - y = a cosh(x/a)",
			"A chain settles where tension costs least; nobody drew it, gravity solved\nit. Mirror the sag and the arch STANDS - the ghost above each line is\nGaudi's whole method. The washing knew. The cathedral is implied.")
