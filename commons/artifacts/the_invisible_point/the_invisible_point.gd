extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheInvisiblePoint

## @identity
## lineage: the primitives taxonomy's rung 1 — a museum vitrine exhibiting NOTHING.
##   Four brass arrows converge on empty air; two hair-thin laser lines cross exactly
##   there; a small stand-in sphere appears at the crossing for a few seconds at a
##   time, then blinks out — and the arrows keep pointing, because the POINT never
##   left. Only its stand-in did.
## essence: a point is position without extension. The engine cannot draw one — Vector3
##   holds a where with no body, and everything you have ever seen called "a point"
##   was a sphere hired to stand in for it. This vitrine displays the difference.
## truth: a point is a decision: here, not there — but only inside a system. The
##   exhibit is the address, not the occupant.
##
## The 2026-08-27 primitives taxonomy refinement (doc/PRIMITIVES_TAXONOMY.md), rung 1.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 51
## Seconds the stand-in exists, and the gap it leaves. The gap is the exhibit.
@export var present: float = 3.0
@export var absent: float = 2.2

var _standin: MeshInstance3D
var _clock := 0.0
var _readout: Node3D
const FOCUS := Vector3(0.0, 1.25, 0.0)

func _ready() -> void:
	_rng.seed = seed
	_clock = _rng.randf_range(0.0, present)
	_build_vitrine()
	_build_arrows()
	_build_lasers()
	_build_standin()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "present", "absent"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	_clock += delta
	var cycle := present + absent
	var t := fmod(_clock, cycle)
	var here := t < present
	if _standin.visible != here:
		_standin.visible = here
		if _readout and _readout.has_method("set_text"):
			_readout.set_text("Vector3(0, 1.25, 0)",
				"stand-in on duty" if here else "the point remains; its body has stepped out")

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

func _build_standin() -> void:
	_standin = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.035
	sm.height = 0.07
	_standin.mesh = sm
	_standin.position = FOCUS
	_standin.material_override = _glow_mat(Color(0.95, 0.9, 0.8), 2.2)
	add_child(_standin)

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
			"A point is position without extension - the engine cannot draw one.\nEvery 'point' you have seen was a sphere hired to stand in for it.\nThe arrows keep pointing while the stand-in steps out: the address remains.")
	_readout = TextScreenScript.new()
	_readout.mode = 2
	_readout.width_m = 0.3
	_readout.position = Vector3(0.75, 0.24, 0.75)
	_readout.rotation.y = deg_to_rad(-38.0)
	add_child(_readout)
