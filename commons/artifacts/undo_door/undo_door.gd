extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name UndoDoor

## @identity
## lineage: the Reconciliation hero — the registry has promised an ftc_bridge since
##   June and never built it, so the fundamental theorem gets a DOOR instead. One
##   brass frame; on its west face a curve in ribbon-steel, on its east face that
##   curve's derivative. Walk through eastward and you are differentiated; walk back
##   and you are integrated — and hanging from the west lintel, a little brass tag
##   reading "+C", the constant the return trip cannot remember for you.
## essence: differentiation and integration are one operation read in opposite
##   directions - the door's two faces are the same wall. The only asymmetry is the
##   tag: integrate and every vertical shift of the original is equally true, so the
##   door hands you a +C and lets you choose.
## truth: change and accumulation undo each other. The theorem is a doorway, not a
##   bridge - you were always allowed to walk it both ways.
##
## The 2026-08-27 category-heroes pass, change.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 27
@export var door_w: float = 1.9
@export var door_h: float = 2.3

func _f(u: float) -> float:
	# the west face: a gentle two-hump curve on 0..1
	return 0.5 + 0.32 * sin(u * TAU) + 0.12 * sin(u * TAU * 2.0)

func _df(u: float) -> float:
	# its honest derivative (chain rule over the 0..1 parameter)
	return 0.32 * TAU * cos(u * TAU) + 0.12 * TAU * 2.0 * cos(u * TAU * 2.0)

func _ready() -> void:
	_rng.seed = seed
	_build_frame()
	_build_face(-0.06, true)
	_build_face(0.06, false)
	_build_tag()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "door_w", "door_h"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_frame() -> void:
	var brass := _steel_mat(Color(0.55, 0.48, 0.30))
	for sx in [-1.0, 1.0]:
		var jamb := MeshInstance3D.new()
		var jamb_mesh := BoxMesh.new()
		jamb_mesh.size = Vector3(0.14, door_h + 0.2, 0.24)
		jamb.mesh = jamb_mesh
		jamb.position = Vector3(sx * (door_w * 0.5 + 0.1), (door_h + 0.2) * 0.5, 0.0)
		jamb.material_override = brass
		add_child(jamb)
	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(door_w + 0.48, 0.16, 0.28)
	lintel.mesh = lintel_mesh
	lintel.position = Vector3(0.0, door_h + 0.18, 0.0)
	lintel.material_override = brass
	add_child(lintel)
	var sill := MeshInstance3D.new()
	var sill_mesh := BoxMesh.new()
	sill_mesh.size = Vector3(door_w + 0.48, 0.05, 0.5)
	sill.mesh = sill_mesh
	sill.position = Vector3(0.0, 0.025, 0.0)
	sill.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
	add_child(sill)
	# direction plates on the lintel, one per face
	var west := TextScreenScript.new()
	west.mode = 2
	west.width_m = 0.34
	west.position = Vector3(0.0, door_h + 0.3, -0.2)
	west.rotation.y = PI
	add_child(west)
	if west.has_method("set_text"):
		west.set_text("d/dx  ->", "walk through: be differentiated")
	var east := TextScreenScript.new()
	east.mode = 2
	east.width_m = 0.34
	east.position = Vector3(0.0, door_h + 0.3, 0.2)
	add_child(east)
	if east.has_method("set_text"):
		east.set_text("<-  S dx", "walk back: be integrated (collect your constant)")

func _build_face(z: float, is_f: bool) -> void:
	# the curve as ribbon-steel: segments across the doorway, f on one face, f' on
	# the other, both normalised into the same opening
	var n := 34
	var lo := 999.0
	var hi := -999.0
	for i in range(n + 1):
		var v := _f(float(i) / float(n)) if is_f else _df(float(i) / float(n))
		lo = minf(lo, v)
		hi = maxf(hi, v)
	var col := Color(0.78, 0.16, 0.12) if is_f else Color(0.13, 0.30, 0.62)
	for i in range(n):
		var u0 := float(i) / float(n)
		var u1 := float(i + 1) / float(n)
		var y0 := 0.3 + (door_h - 0.7) * (((_f(u0) if is_f else _df(u0)) - lo) / (hi - lo))
		var y1 := 0.3 + (door_h - 0.7) * (((_f(u1) if is_f else _df(u1)) - lo) / (hi - lo))
		var p0 := Vector3(-door_w * 0.5 + u0 * door_w, y0, z)
		var p1 := Vector3(-door_w * 0.5 + u1 * door_w, y1, z)
		var seg := MeshInstance3D.new()
		var seg_mesh := BoxMesh.new()
		seg_mesh.size = Vector3(p0.distance_to(p1) * 1.1, 0.055, 0.02)
		seg.mesh = seg_mesh
		seg.position = (p0 + p1) * 0.5
		seg.rotation.z = atan2(y1 - y0, p1.x - p0.x)
		seg.material_override = _glow_mat(col, 0.7)
		add_child(seg)
	# the zero line for the derivative face - where f was flat, f' crosses home
	if not is_f:
		var zero_y := 0.3 + (door_h - 0.7) * ((0.0 - lo) / (hi - lo))
		var zline := MeshInstance3D.new()
		var zline_mesh := BoxMesh.new()
		zline_mesh.size = Vector3(door_w, 0.012, 0.014)
		zline.mesh = zline_mesh
		zline.position = Vector3(0.0, zero_y, z + 0.015)
		zline.material_override = _matte_mat(Color(0.75, 0.75, 0.78), 0.6)
		add_child(zline)

func _build_tag() -> void:
	# the +C, hung from the west lintel on a chain: integration's homework
	var chain := MeshInstance3D.new()
	var chain_mesh := CylinderMesh.new()
	chain_mesh.top_radius = 0.006
	chain_mesh.bottom_radius = 0.006
	chain_mesh.height = 0.34
	chain.mesh = chain_mesh
	chain.position = Vector3(door_w * 0.5 - 0.2, door_h - 0.07, -0.16)
	chain.material_override = _matte_mat(Color(0.35, 0.35, 0.37), 0.5, 0.8)
	add_child(chain)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.16
	tag.position = Vector3(door_w * 0.5 - 0.2, door_h - 0.3, -0.16)
	tag.rotation.y = PI
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("+C", "yours to choose")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "UndoPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-(door_w * 0.5 + 0.55), 0.24, 0.6)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("UNDO DOOR - the fundamental theorem",
			"One wall, two faces: the curve on the west, its derivative on the east.\nWalk east to differentiate; walk back to integrate - and take the +C tag,\nbecause the return trip cannot remember your height for you.")
