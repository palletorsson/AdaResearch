extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ImpossibleEndTable

## @identity
## lineage: a constructed end-table pose with two separated brackets, four cable meshes
##   and an unbothered teacup. It refers to tension-supported furniture without solving it.
## essence: positions and bars are drawn directly. No rigid bodies, joints, cable tensions,
##   contacts or load test hold this upper assembly up; the scene never lets gravity try it.
## truth: the teacup's stillness is authored geometry, not evidence that the pictured
##   pulls can support its weight. A physical comparison would be a separate experiment.
##
## The 2026-08-27 category-heroes pass, formfinding.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 14
@export var base_r: float = 0.42
@export var gap: float = 0.16          # the daylight between the two brackets

func _ready() -> void:
	_rng.seed = seed
	_build_base()
	_build_brackets()
	_build_cables()
	_build_top()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "base_r", "gap"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_base() -> void:
	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = base_r
	disc_mesh.bottom_radius = base_r + 0.04
	disc_mesh.height = 0.05
	disc.mesh = disc_mesh
	disc.position = Vector3(0.0, 0.025, 0.0)
	disc.material_override = _matte_mat(Color(0.30, 0.19, 0.10), 0.85)
	add_child(disc)

## The two Y-brackets: a vertical post with a horizontal overhang arm — the lower one
## rises from the base and reaches +x; the upper one hangs under the top and reaches
## -x; their arm tips OVERLAP in plan without touching in height. That overlap is
## where the centre cable lives.
func _build_brackets() -> void:
	var steel := _steel_mat(Color(0.16, 0.16, 0.18))
	# lower: post up from base at -x, arm toward +x at height 0.34
	_bar(Vector3(-0.18, 0.05, 0.0), Vector3(-0.18, 0.34, 0.0), 0.03, steel)
	_bar(Vector3(-0.18, 0.34, 0.0), Vector3(0.16, 0.34, 0.0), 0.03, steel)
	# upper: post down from top at +x, arm toward -x at height 0.34+gap
	var top_y := 0.34 + gap + 0.34
	_bar(Vector3(0.18, top_y, 0.0), Vector3(0.18, 0.34 + gap, 0.0), 0.03, steel)
	_bar(Vector3(0.18, 0.34 + gap, 0.0), Vector3(-0.16, 0.34 + gap, 0.0), 0.03, steel)

func _build_cables() -> void:
	var wire := _matte_mat(Color(0.75, 0.75, 0.78), 0.4, 0.8)
	# The drawn central cable joins the lower and upper arm tips. No tension is solved.
	_bar(Vector3(0.16, 0.34, 0.0), Vector3(-0.16, 0.34 + gap, 0.0), 0.006, wire)
	# Three drawn rim cables connect the base and top; they apply no forces.
	var top_y := 0.34 + gap + 0.34
	for k in range(3):
		var ang := TAU * float(k) / 3.0 + 0.5
		var b := Vector3(cos(ang) * base_r * 0.92, 0.05, sin(ang) * base_r * 0.92)
		var t := Vector3(cos(ang) * base_r * 0.92, top_y, sin(ang) * base_r * 0.92)
		_bar(b, t, 0.005, wire)

func _build_top() -> void:
	var top_y := 0.34 + gap + 0.34
	var top := MeshInstance3D.new()
	var top_mesh := CylinderMesh.new()
	top_mesh.top_radius = base_r
	top_mesh.bottom_radius = base_r
	top_mesh.height = 0.045
	top.mesh = top_mesh
	top.position = Vector3(0.0, top_y + 0.022, 0.0)
	top.material_override = _matte_mat(Color(0.30, 0.19, 0.10), 0.85)
	add_child(top)
	# the unbothered teacup: saucer, cup, one ear - service for the laws of statics
	var saucer := MeshInstance3D.new()
	var saucer_mesh := CylinderMesh.new()
	saucer_mesh.top_radius = 0.085
	saucer_mesh.bottom_radius = 0.06
	saucer_mesh.height = 0.015
	saucer.mesh = saucer_mesh
	saucer.position = Vector3(0.1, top_y + 0.052, 0.05)
	saucer.material_override = _matte_mat(Color(0.88, 0.86, 0.82), 0.6)
	add_child(saucer)
	var cup := MeshInstance3D.new()
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.05
	cup_mesh.bottom_radius = 0.035
	cup_mesh.height = 0.06
	cup.mesh = cup_mesh
	cup.position = Vector3(0.1, top_y + 0.09, 0.05)
	cup.material_override = _matte_mat(Color(0.88, 0.86, 0.82), 0.6)
	add_child(cup)
	var ear := MeshInstance3D.new()
	var ear_mesh := TorusMesh.new()
	ear_mesh.inner_radius = 0.012
	ear_mesh.outer_radius = 0.022
	ear.mesh = ear_mesh
	ear.rotation.x = PI * 0.5
	ear.position = Vector3(0.155, top_y + 0.09, 0.05)
	ear.material_override = _matte_mat(Color(0.88, 0.86, 0.82), 0.6)
	add_child(ear)

func _bar(from: Vector3, to: Vector3, r: float, mat: Material) -> void:
	var seg := MeshInstance3D.new()
	var seg_mesh := CylinderMesh.new()
	seg_mesh.top_radius = r
	seg_mesh.bottom_radius = r
	seg_mesh.height = from.distance_to(to)
	seg.mesh = seg_mesh
	seg.position = (from + to) * 0.5
	# aim the cylinder's Y axis along the segment
	var d := (to - from).normalized()
	if absf(d.y) < 0.999:
		var axis := Vector3.UP.cross(d).normalized()
		seg.rotate(axis, acos(Vector3.UP.dot(d)))
	seg.material_override = mat
	add_child(seg)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "TensegrityPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-base_r - 0.5, 0.24, 0.5)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("IMPOSSIBLE END TABLE - a constructed pose",
			"No forces are solved.\nThe teacup never meets gravity.")
