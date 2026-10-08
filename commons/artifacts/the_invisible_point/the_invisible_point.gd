extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheInvisiblePoint

## @identity
## lineage: the primitives taxonomy's rung 1 — a museum vitrine exhibiting NOTHING.
##   Four brass arrows converge on empty air; two hair-thin laser lines cross exactly
##   there. The point is never given a visible body. Its position can be located
##   through the surrounding geometry and read in the source.
## essence: a point is position without extension. The engine cannot draw one — Vector3
##   holds a where with no body, and everything you have ever seen called "a point"
##   was a sphere hired to stand in for it. This vitrine displays the difference.
## truth: a point is a decision: here, not there — but only inside a system. The
##   exhibit is the address, not the occupant.
##
## The 2026-08-27 primitives taxonomy refinement (doc/PRIMITIVES_TAXONOMY.md), rung 1.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

## No marker is created at this position, including at startup or in wireframe.
const FOCUS := Vector3(0.0, 1.25, 0.0)

func _ready() -> void:
	_build_vitrine()
	_build_arrows()
	_build_lasers()
	_build_plaque()

func _build_vitrine() -> void:
	var plinth := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.7, 0.9, 0.7)
	plinth.mesh = pm
	plinth.position = Vector3(0.0, 0.45, 0.0)
	plinth.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
	add_child(plinth)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.6, 0.78, 0.82, 0.10)
	glass.roughness = 0.05
	var case := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.66, 0.7, 0.66)
	case.mesh = cm
	case.position = Vector3(0.0, 1.25, 0.0)
	case.material_override = glass
	add_child(case)
	var lid := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.7, 0.04, 0.7)
	lid.mesh = lm
	lid.position = Vector3(0.0, 1.62, 0.0)
	lid.material_override = _steel_mat(Color(0.5, 0.42, 0.26))
	add_child(lid)

func _build_arrows() -> void:
	# four brass arrows outside the case, all aimed at the focus — the address spoken
	# from four directions
	for i in range(4):
		var ang := TAU * float(i) / 4.0 + PI / 4.0
		var from := FOCUS + Vector3(cos(ang) * 0.85, 0.28 * sin(float(i) * 2.3), sin(ang) * 0.85)
		var dir := (FOCUS - from).normalized()
		var shaft := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.014
		sm.bottom_radius = 0.014
		sm.height = 0.34
		shaft.mesh = sm
		shaft.position = from + dir * 0.17
		var axis := Vector3.UP.cross(dir)
		if axis.length() > 0.001:
			shaft.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
		shaft.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
		add_child(shaft)
		var head := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.0
		hm.bottom_radius = 0.045
		hm.height = 0.11
		head.mesh = hm
		head.position = from + dir * 0.4
		if axis.length() > 0.001:
			head.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
		head.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
		add_child(head)

func _build_lasers() -> void:
	# two hair-thin crossing lines THROUGH the case, meeting at the focus
	for horizontal in [true, false]:
		var beam := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.0035
		bm.bottom_radius = 0.0035
		bm.height = 1.5
		beam.mesh = bm
		beam.position = FOCUS
		if horizontal:
			beam.rotation.z = PI * 0.5
		else:
			beam.rotation.x = PI * 0.5
		beam.material_override = _glow_mat(Color(0.9, 0.25, 0.2), 1.6)
		add_child(beam)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "PointPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-0.75, 0.24, 0.75)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE INVISIBLE POINT",
			"A point is position without extension.\nFollow the arrows and the crossing lines.\nThey locate a position that is never given a visible body.")
	var readout := TextScreenScript.new()
	readout.name = "PositionReadout"
	readout.mode = 2
	readout.width_m = 0.3
	readout.position = Vector3(0.75, 0.24, 0.75)
	readout.rotation.y = deg_to_rad(-38.0)
	add_child(readout)
	if readout.has_method("set_text"):
		readout.set_text("Vector3(0, 1.25, 0)",
			"A position in this case's local frame.\nNo sphere will appear here.")
