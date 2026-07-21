extends Node3D
class_name ChairKit

# @identity
# essence: the chair argument in three stations — the parts laid out as honest stock, the half-joined frame where affordance becomes commitment, and the finished chair that is nothing but a plane agreeing to be sat on
# desire: one artifact that stages Bricolage_Chair as a single derivation (stock -> joint -> seat) rather than three unrelated props, closing the loop the affordance plinths opened
# critical_parameter: the station read from the lookup_name meta the grid stamps before _ready — chair_parts_inventory / chair_builder / chair_assembled; it selects which step of the assembly this instance embodies
# triggers: _ready() reads get_meta("artifact_lookup_name"), lays a witness pad, builds that station's geometry from the same four primitives the affordance sequence taught (cylinder as leg, plane as seat, plane as back), and names it on a plaque
# emerges: a room you can assemble in your head — the same four cylinders visible as stock, as standing legs, and as the chair's stance, so the chair stops being furniture and becomes a consequence
# needs: CylinderMesh legs + BoxMesh planes [Godot built-ins]; Grid.gdshader [present]; TextScreen PAD plate [present]; the lookup_name meta [set by GridInteractablesComponent before add_child]
# relationships: the payoff of the affordance stations — plane_as_seat and cylinder_as_column stop being claims and start bearing weight; sibling of dome_kit and sculpture_kit in the bricolage kit family
# truth: a chair is a treaty between a plane and four columns. Nobody invents sitting; someone notices that a surface at knee height affords it, and the assembly is just that noticing made rigid enough to hand to someone else.

## The chair kit for the bricolage sequence. One script serves all three
## stations of Bricolage_Chair; the station is read from the lookup_name the
## grid stamps as metadata before _ready(), the same wrapper pattern as
## specimen_plinth, dome_kit and sculpture_kit.

@export var station: String = ""      # override; empty = derive from lookup_name
@export var kit_label: String = ""
@export var kit_note: String = ""

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

const LEG_R := 0.022
const LEG_H := 0.34
const SEAT := Vector3(0.42, 0.035, 0.40)
const BACK := Vector3(0.42, 0.44, 0.035)

# lookup_name -> [station, LABEL, note]
const STATIONS := {
	"chair_parts_inventory": ["parts",     "PARTS",     "four columns, two planes — honest stock"],
	"chair_builder":         ["builder",   "BUILDER",   "legs stand; the seat is a decision"],
	"chair_assembled":       ["assembled", "CHAIR",     "a plane agreeing to be sat on"],
}

var _built := false


func _ready() -> void:
	_resolve_identity()
	_build()


func _resolve_identity() -> void:
	var lookup := ""
	if has_meta("artifact_lookup_name"):
		lookup = str(get_meta("artifact_lookup_name"))
	if station == "" and STATIONS.has(lookup):
		var s: Array = STATIONS[lookup]
		station = str(s[0])
		if kit_label == "":
			kit_label = str(s[1])
		if kit_note == "":
			kit_note = str(s[2])
	if station == "":
		station = "parts"
	if kit_label == "":
		kit_label = station.to_upper()


func _build() -> void:
	if _built:
		for c in get_children():
			c.queue_free()
	_built = true

	var pad_w := 1.1
	_add_pad(pad_w)
	match station:
		"parts":
			_build_parts()
		"builder":
			_build_builder()
		"assembled":
			_build_assembled()
		_:
			_build_parts()
	_add_label(pad_w)


# --- stations -------------------------------------------------------------

# The stock, laid out flat: four legs in a rack row, seat and back leaning.
func _build_parts() -> void:
	for i in 4:
		var z := -0.24 + float(i) * 0.16
		add_child(_leg(Vector3(-0.30, 0.04 + LEG_R, z), Vector3(-0.30 + LEG_H, 0.04 + LEG_R, z)))
	# seat plane lying flat on the pad
	add_child(_plane(SEAT, Vector3(0.16, 0.04 + SEAT.y * 0.5, -0.12), 0.0))
	# back plane propped at a lean, resting against nothing yet
	add_child(_plane(BACK, Vector3(0.18, 0.04 + BACK.y * 0.42, 0.24), deg_to_rad(-64.0)))


# Mid-assembly: legs standing at their corners, seat hovering just above,
# back still lying on the pad as stock.
func _build_builder() -> void:
	var dx := SEAT.x * 0.5 - 0.05
	var dz := SEAT.z * 0.5 - 0.05
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var x := float(sx) * dx
			var z := float(sz) * dz
			add_child(_leg(Vector3(x, 0.04, z), Vector3(x, 0.04 + LEG_H, z)))
	# the seat, lowered halfway — the decision in progress
	add_child(_plane(SEAT, Vector3(0.0, 0.04 + LEG_H + 0.10, 0.0), 0.0))
	# the back, still stock on the pad
	add_child(_plane(BACK, Vector3(0.34, 0.04 + BACK.z * 0.5, 0.0), deg_to_rad(-90.0)))


# The finished chair: legs, seat seated, back risen.
func _build_assembled() -> void:
	var dx := SEAT.x * 0.5 - 0.05
	var dz := SEAT.z * 0.5 - 0.05
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var x := float(sx) * dx
			var z := float(sz) * dz
			add_child(_leg(Vector3(x, 0.04, z), Vector3(x, 0.04 + LEG_H, z)))
	var seat_y := 0.04 + LEG_H + SEAT.y * 0.5
	add_child(_plane(SEAT, Vector3(0.0, seat_y, 0.0), 0.0))
	add_child(_plane(BACK, Vector3(0.0, seat_y + BACK.y * 0.5 + 0.01, -SEAT.z * 0.5 + BACK.z * 0.5), 0.0))


# --- pieces ---------------------------------------------------------------

# A leg between two points: one cylinder, oriented so its Y axis runs the edge.
func _leg(p1: Vector3, p2: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var d := p1.distance_to(p2)
	cyl.top_radius = LEG_R
	cyl.bottom_radius = LEG_R
	cyl.height = max(0.001, d)
	cyl.radial_segments = 10
	cyl.rings = 1
	mi.mesh = cyl
	var dir := (p2 - p1).normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var xa := up.cross(dir).normalized()
	var za := dir.cross(xa).normalized()
	mi.transform = Transform3D(Basis(xa, dir, za), (p1 + p2) * 0.5)
	mi.material_override = _subject_mat()
	return mi


# A plane (seat or back) as a thin box, tilted around X by `lean`.
func _plane(size: Vector3, pos: Vector3, lean: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.rotation = Vector3(lean, 0.0, 0.0)
	mi.material_override = _subject_mat()
	return mi


func _add_pad(w: float) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Pad"
	var box := BoxMesh.new()
	box.size = Vector3(w, 0.04, w)
	mi.mesh = box
	mi.position = Vector3(0.0, 0.02, 0.0)
	mi.material_override = _witness_mat()
	add_child(mi)


func _add_label(pad_w: float) -> void:
	# Configure BEFORE add_child — TextScreen's setters rebuild only when
	# already in-tree; set first, add last (same note as dome_kit).
	var ts := TextScreenScript.new()
	ts.name = "KitPlate"
	ts.mode = 2                       # Mode.PAD — reclined plaque
	ts.width_m = 0.36
	ts.position = Vector3(0.0, 0.045, pad_w * 0.5 - 0.06)
	if ts.has_method("set_text"):
		ts.set_text(kit_label, kit_note)
	add_child(ts)


# --- material -------------------------------------------------------------

func _subject_mat() -> Material:
	return _grid_material(Color(0.62, 0.55, 0.44), Color(1.0, 0.78, 0.45), 2.0)


func _witness_mat() -> Material:
	return _grid_material(Color(0.30, 0.32, 0.38), Color(0.45, 0.50, 0.60), 0.5)


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


## Grid config. Keys: "station", "label", "note".
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("station"):
		station = str(config_data["station"])
	if config_data.has("label"):
		kit_label = str(config_data["label"])
	if config_data.has("note"):
		kit_note = str(config_data["note"])
	if _built:
		_build()
