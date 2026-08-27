extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PaperRegatta

## @identity
## lineage: the Flow hero — a winding gutter-river crossing the room, and a regatta of
##   paper boats forever shipping along it. No boat has an engine: each one just reads
##   the field where it floats and goes where the water says, which is the entire
##   theory of vector fields told as street play after rain.
## essence: a flow field is a rate EVERYWHERE - a velocity assigned to every point.
##   The boats integrate it live (their headings are the field's arrows, worn as
##   hulls), and the river's bends are visible before any boat arrives, because the
##   field is the geography, not the traffic.
## truth: what if the rate is everywhere at once? Then everything that floats is
##   already navigating. Fold paper, launch it, and read the room's mathematics.
##
## The 2026-08-27 category-heroes pass, change.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const HULLS := [Color(0.88, 0.86, 0.82), Color(0.78, 0.16, 0.12), Color(0.92, 0.75, 0.14), Color(0.13, 0.30, 0.62)]
const FLEET := 7
const LAPS := 24.0                     # seconds for a full course

@export var seed: int = 13
@export var course_r: float = 1.6      # the serpentine's reach, m

var _boats: Array = []                 # {node, u}

func _ready() -> void:
	_rng.seed = seed
	_build_river()
	_build_fleet()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "course_r"]:
		if config_data.has(key):
			set(key, config_data[key])

## The course, u in 0..1: a closed serpentine (a figure-flow) in the plot.
func _course(u: float) -> Vector3:
	var a := u * TAU
	return Vector3(cos(a) * course_r + 0.35 * cos(a * 3.0), 0.0, sin(a) * course_r * 0.62 + 0.3 * sin(a * 2.0))

func _process(delta: float) -> void:
	for b in _boats:
		b["u"] = fmod(b["u"] + delta / LAPS, 1.0)
		var u: float = b["u"]
		var p := _course(u)
		var ahead := _course(fmod(u + 0.01, 1.0))
		var node: Node3D = b["node"]
		node.position = Vector3(p.x, 0.14, p.z)
		node.look_at(node.global_position + (ahead - p).normalized(), Vector3.UP)
		# a paper boat bobs: tiny roll and pitch on its own phase
		node.rotation.z += sin(Time.get_ticks_msec() / 1000.0 * 2.2 + b["u"] * 20.0) * 0.05

func _build_river() -> void:
	# the gutter: flat dark water ribbon laid in segments along the course, with
	# brass banks - a street river, curated
	var n := 64
	for i in range(n):
		var p0 := _course(float(i) / float(n))
		var p1 := _course(float(i + 1) / float(n))
		var seg := MeshInstance3D.new()
		var seg_mesh := BoxMesh.new()
		seg_mesh.size = Vector3(p0.distance_to(p1) * 1.15, 0.035, 0.5)
		seg.mesh = seg_mesh
		seg.position = (p0 + p1) * 0.5 + Vector3(0.0, 0.1, 0.0)
		seg.rotation.y = -atan2(p1.z - p0.z, p1.x - p0.x)
		var wm := _glow_mat(Color(0.13, 0.20, 0.26), 0.3)
		wm.metallic = 0.6
		wm.roughness = 0.08
		seg.material_override = wm
		add_child(seg)
	# field arrows on the water, sparse: the geography before the traffic
	for k in range(10):
		var u := float(k) / 10.0
		var p := _course(u)
		var ahead := _course(u + 0.012)
		var dirv := (ahead - p).normalized()
		var arrow := MeshInstance3D.new()
		var arrow_mesh := CylinderMesh.new()
		arrow_mesh.top_radius = 0.0
		arrow_mesh.bottom_radius = 0.035
		arrow_mesh.height = 0.11
		arrow.mesh = arrow_mesh
		arrow.position = Vector3(p.x, 0.125, p.z)
		arrow.rotation.z = -PI * 0.5
		arrow.rotation.y = -atan2(dirv.z, dirv.x)
		var am := _glow_mat(Color(0.75, 0.85, 0.95), 0.5)
		am.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		am.albedo_color.a = 0.35
		arrow.material_override = am
		add_child(arrow)

func _build_fleet() -> void:
	for i in range(FLEET):
		var boat := _paper_boat(HULLS[i % HULLS.size()])
		add_child(boat)
		_boats.append({"node": boat, "u": float(i) / float(FLEET)})

## A folded paper boat: two hull planes, a keel line and a sail-peak - origami by boxes.
func _paper_boat(col: Color) -> Node3D:
	var root := Node3D.new()
	for sz in [-1.0, 1.0]:
		var hull := MeshInstance3D.new()
		var hull_mesh := BoxMesh.new()
		hull_mesh.size = Vector3(0.26, 0.09, 0.012)
		hull.mesh = hull_mesh
		hull.position = Vector3(0.0, 0.045, sz * 0.045)
		hull.rotation.x = sz * 0.5
		hull.material_override = _matte_mat(col, 0.85)
		root.add_child(hull)
	var peak := MeshInstance3D.new()
	var peak_mesh := BoxMesh.new()
	peak_mesh.size = Vector3(0.1, 0.1, 0.012)
	peak.mesh = peak_mesh
	peak.position = Vector3(0.0, 0.1, 0.0)
	peak.rotation.z = PI * 0.25
	peak.material_override = _matte_mat(col.lerp(Color.WHITE, 0.3), 0.9)
	root.add_child(peak)
	return root

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "RegattaPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-course_r - 0.5, 0.24, course_r * 0.62 + 0.5)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("PAPER REGATTA - the field",
			"A flow field is a rate everywhere: a velocity assigned to every point.\nNo boat has an engine - each reads the water where it floats and goes\nwhere the field says. The bends were there before any boat arrived.")
