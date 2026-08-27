extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CookiePress

## @identity
## lineage: the Prism/extrusion hero for primitives — its category held three bare
##   solids and no applied body, so: a bakery extruder. A brass die with a star-shaped
##   hole, and pushed through it, one long star-profile column of dough lying on the
##   counter in three cut lengths — the same 2D profile all the way through, which is
##   the entire definition.
## essence: a prism is a 2D profile pushed through the third dimension. The die is
##   the profile; the push is the extrusion; every slice anywhere along the bar is
##   the same star, and the cut ends prove it in cross-section.
## truth: extrusion is commitment: choose a section once, then travel. Every bakery
##   knows more about prisms than most geometry lessons.
##
## The 2026-08-27 category-heroes pass, primitives.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const DOUGH := Color(0.91, 0.78, 0.55)

@export var seed: int = 31
@export_range(5, 8) var points: int = 5
@export var star_r: float = 0.16

func _ready() -> void:
	_rng.seed = seed
	_build_counter()
	_build_die()
	_build_extrusions()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "points", "star_r"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_counter() -> void:
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(2.6, 0.07, 1.0)
	top.mesh = top_mesh
	top.position = Vector3(0.0, 0.86, 0.0)
	top.material_override = _matte_mat(Color(0.88, 0.86, 0.82), 0.5)
	add_child(top)
	var skirt := MeshInstance3D.new()
	var skirt_mesh := BoxMesh.new()
	skirt_mesh.size = Vector3(2.5, 0.82, 0.9)
	skirt.mesh = skirt_mesh
	skirt.position = Vector3(0.0, 0.42, 0.0)
	skirt.material_override = _matte_mat(Color(0.30, 0.19, 0.10), 0.85)
	add_child(skirt)

func _build_die() -> void:
	# the die: a standing brass plate with the star hole implied by a recessed dark
	# star inlay, plus the barrel and plunger of the press behind it
	var plate := MeshInstance3D.new()
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(0.06, 0.5, 0.5)
	plate.mesh = plate_mesh
	plate.position = Vector3(-0.85, 1.14, 0.0)
	plate.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(plate)
	_star(Vector3(-0.815, 1.14, 0.0), star_r * 1.05, 0.015, Color(0.10, 0.10, 0.11), 0.0, true)
	var barrel := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.19
	barrel_mesh.bottom_radius = 0.19
	barrel_mesh.height = 0.55
	barrel.mesh = barrel_mesh
	barrel.rotation.z = PI * 0.5
	barrel.position = Vector3(-1.2, 1.14, 0.0)
	barrel.material_override = _steel_mat(Color(0.7, 0.7, 0.72))
	add_child(barrel)
	var plunger := MeshInstance3D.new()
	var plunger_mesh := CylinderMesh.new()
	plunger_mesh.top_radius = 0.05
	plunger_mesh.bottom_radius = 0.05
	plunger_mesh.height = 0.3
	plunger.mesh = plunger_mesh
	plunger.rotation.z = PI * 0.5
	plunger.position = Vector3(-1.6, 1.14, 0.0)
	plunger.material_override = _steel_mat(Color(0.35, 0.35, 0.38))
	add_child(plunger)
	var knob := MeshInstance3D.new()
	var knob_mesh := SphereMesh.new()
	knob_mesh.radius = 0.07
	knob_mesh.height = 0.14
	knob.mesh = knob_mesh
	knob.position = Vector3(-1.78, 1.14, 0.0)
	knob.material_override = _matte_mat(Color(0.78, 0.16, 0.12), 0.7)
	add_child(knob)

func _build_extrusions() -> void:
	# the bar, mid-extrusion out of the die, plus two cut lengths on the counter -
	# each built as a stack of thin star slices, so the section is LITERALLY repeated
	_star_bar(Vector3(-0.78, 1.14, 0.0), 1.05, 0.0)
	_star_bar(Vector3(0.55, 0.93 + star_r * 0.35, 0.22), 0.7, deg_to_rad(18.0))
	_star_bar(Vector3(0.35, 0.93 + star_r * 0.35, -0.25), 0.45, deg_to_rad(-31.0))

func _star_bar(from: Vector3, length: float, yaw: float) -> void:
	var slices := int(length / 0.035)
	var dirv := Vector3(cos(yaw), 0.0, sin(yaw))
	for i in range(slices):
		var star_scale := 1.0
		_star(from + dirv * (0.035 * float(i)), star_r * star_scale, 0.03, DOUGH, yaw, false)

## One star slice: `points` kite-quads around a hub - cheap, and the silhouette reads.
func _star(at: Vector3, r: float, thick: float, col: Color, yaw: float, emissive_face: bool) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = yaw
	add_child(root)
	var hub := MeshInstance3D.new()
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = r * 0.42
	hub_mesh.bottom_radius = r * 0.42
	hub_mesh.height = thick
	hub.mesh = hub_mesh
	hub.rotation.z = PI * 0.5
	hub.material_override = _matte_mat(col, 0.85) if not emissive_face else _glow_mat(col, 0.4)
	root.add_child(hub)
	for k in range(points):
		var ang := TAU * float(k) / float(points)
		var spike := MeshInstance3D.new()
		var spike_mesh := BoxMesh.new()
		spike_mesh.size = Vector3(thick, r * 0.95, r * 0.34)
		spike.mesh = spike_mesh
		spike.position = Vector3(0.0, cos(ang) * r * 0.5, sin(ang) * r * 0.5)
		spike.rotation.x = -ang
		spike.material_override = _matte_mat(col, 0.85) if not emissive_face else _glow_mat(col, 0.4)
		root.add_child(spike)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "PressPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(0.4, 0.24, 0.75)
	ts.rotation.y = deg_to_rad(12.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("COOKIE PRESS - the prism",
			"A prism is a 2D profile pushed through the third dimension: the die is the\nprofile, the push is the extrusion, and every slice along the bar is the\nsame star. Extrusion is commitment - choose a section once, then travel.")
