extends Node3D
class_name ConstraintDemo

# @identity
# essence: a paired structural vignette — the same few members built once so they fail and once so they hold, so a constraint is learned by comparison rather than by being told
# desire: one artifact that stages all three of the bricolage sequence's constraints (gravity, balance, triangulation) in both states, so Bricolage_Constraints reads as three A/B experiments down a hall instead of six unrelated props
# critical_parameter: the (constraint, holds) pair derived from the lookup_name meta the grid stamps before _ready — gravity_fail_demo -> (gravity,false), triangulation_pass_demo -> (triangulation,true); it picks both the geometry and the colour
# triggers: _ready() reads get_meta("artifact_lookup_name"), lays a witness pad, builds the vignette in its failing or holding configuration, and names the constraint on a plaque
# emerges: a room you read across rather than along — left column collapsed and red, right column standing and cyan, the difference between them the single member that matters
# needs: BoxMesh members [Godot built-in]; Grid.gdshader [present]; TextScreen PAD plate [present]; the lookup_name meta [set by GridInteractablesComponent before add_child]
# relationships: sibling to specimen_plinth (same one-scene-many-names wrapper pattern, same witness/subject palette) in the bricolage sequence; the constraints it stages are what the chair, sculpture and dome rooms later have to satisfy — this is where the pushing-back is named
# truth: a constraint is not a rule someone imposed, it is what the world does when you build wrong. You cannot argue with the fallen beam. Bricolage is the craft of discovering which member you were missing, and the fastest way to teach that is to stand the missing member next to the gap it leaves.

## Paired constraint vignettes for the bricolage sequence. One script serves
## all six artifacts (gravity/balance/triangulation × fail/pass): the pair is
## read from the lookup_name the grid stamps as metadata before _ready().

@export var constraint: String = ""   # override; empty = derive from lookup_name
@export var holds: bool = true        # true = the passing configuration
@export var demo_label: String = ""
@export var demo_note: String = ""

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

const PAD_W := 0.92
const M := 0.05      # member thickness

# lookup_name -> [constraint, holds, LABEL, note]
const DEMOS := {
	"gravity_fail_demo":       ["gravity", false, "GRAVITY", "unsupported — the span falls"],
	"gravity_pass_demo":       ["gravity", true,  "GRAVITY", "supported — the span holds"],
	"balance_fail_demo":       ["balance", false, "BALANCE", "mass past the base — it topples"],
	"balance_pass_demo":       ["balance", true,  "BALANCE", "mass over the base — it stands"],
	"triangulation_fail_demo": ["triangulation", false, "TRIANGULATION", "a quad hinges — it racks"],
	"triangulation_pass_demo": ["triangulation", true,  "TRIANGULATION", "the diagonal locks it"],
}

var _built := false


func _ready() -> void:
	_resolve_identity()
	_build()


func _resolve_identity() -> void:
	var lookup := ""
	if has_meta("artifact_lookup_name"):
		lookup = str(get_meta("artifact_lookup_name"))
	if constraint == "" and DEMOS.has(lookup):
		var d: Array = DEMOS[lookup]
		constraint = str(d[0])
		holds = bool(d[1])
		if demo_label == "":
			demo_label = str(d[2])
		if demo_note == "":
			demo_note = str(d[3])
	if constraint == "":
		constraint = "gravity"
	if demo_label == "":
		demo_label = constraint.to_upper()


func _build() -> void:
	if _built:
		for c in get_children():
			c.queue_free()
	_built = true

	_add_pad()
	match constraint:
		"gravity":
			_build_gravity()
		"balance":
			_build_balance()
		"triangulation":
			_build_triangulation()
		_:
			_build_gravity()
	_add_label()


# --- staging -------------------------------------------------------------

func _add_pad() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Pad"
	var box := BoxMesh.new()
	box.size = Vector3(PAD_W, 0.04, PAD_W)
	mi.mesh = box
	mi.position = Vector3(0.0, 0.02, 0.0)
	mi.material_override = _witness_mat()
	add_child(mi)


func _add_label() -> void:
	# Configure BEFORE add_child — TextScreen's setters rebuild only when
	# already in-tree, so driving them post-add forces a queue_free/rebuild per
	# property and leaves the renderer holding freed materials. Set first, add last.
	var ts := TextScreenScript.new()
	ts.name = "ConstraintPlate"
	ts.mode = 2                       # Mode.PAD — reclined plaque
	ts.width_m = 0.36
	ts.position = Vector3(0.0, 0.045, PAD_W * 0.5 - 0.06)
	if ts.has_method("set_text"):
		ts.set_text(demo_label, demo_note)
	add_child(ts)


# A rectangular member. Subject material unless witness is true.
func _member(size: Vector3, pos: Vector3, rot_deg: Vector3, witness: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = _witness_mat() if witness else _state_mat()
	add_child(mi)
	return mi


# --- the three constraints ------------------------------------------------

# GRAVITY — a span needs something under it.
#   pass: two posts carry a level beam.
#   fail: one post; the far end has dropped, and the block it carried lies on the pad.
func _build_gravity() -> void:
	var post_h := 0.42
	_member(Vector3(M * 1.6, post_h, M * 1.6), Vector3(-0.28, 0.04 + post_h * 0.5, 0.0), Vector3.ZERO)
	if holds:
		_member(Vector3(M * 1.6, post_h, M * 1.6), Vector3(0.28, 0.04 + post_h * 0.5, 0.0), Vector3.ZERO)
		_member(Vector3(0.72, M * 1.4, M * 1.6), Vector3(0.0, 0.04 + post_h + M * 0.7, 0.0), Vector3.ZERO)
		# the load it can now carry
		_member(Vector3(0.14, 0.14, 0.14), Vector3(0.0, 0.04 + post_h + M * 1.4 + 0.07, 0.0), Vector3.ZERO)
	else:
		# the span, hinged down off the single post
		_member(Vector3(0.72, M * 1.4, M * 1.6), Vector3(0.06, 0.04 + post_h - 0.10, 0.0), Vector3(0.0, 0.0, -28.0))
		# the load, fallen
		_member(Vector3(0.14, 0.14, 0.14), Vector3(0.30, 0.04 + 0.07, 0.10), Vector3(0.0, 22.0, 14.0))


# BALANCE — the centre of mass must sit over the base.
#   pass: a centred stack, upright.
#   fail: each course creeps outward until the mass leaves the base; the stack leans.
func _build_balance() -> void:
	var b := Vector3(0.26, 0.11, 0.20)
	if holds:
		_member(Vector3(0.34, 0.05, 0.26), Vector3(0.0, 0.065, 0.0), Vector3.ZERO, true)   # footing
		for i in 3:
			_member(b, Vector3(0.0, 0.115 + float(i) * 0.12, 0.0), Vector3.ZERO)
	else:
		_member(Vector3(0.34, 0.05, 0.26), Vector3(0.0, 0.065, 0.0), Vector3.ZERO, true)
		var creep := [0.0, 0.10, 0.22]
		for i in 3:
			_member(b, Vector3(float(creep[i]), 0.115 + float(i) * 0.12, 0.0),
				Vector3(0.0, 0.0, -6.0 * float(i)))


# TRIANGULATION — a quadrilateral hinges; a triangle cannot.
#   pass: a square frame with one diagonal — rigid.
#   fail: the same four members racked into a parallelogram.
func _build_triangulation() -> void:
	var w := 0.56
	var h := 0.46
	var y0 := 0.04
	if holds:
		_member(Vector3(w, M, M), Vector3(0.0, y0 + M * 0.5, 0.0), Vector3.ZERO)            # bottom
		_member(Vector3(w, M, M), Vector3(0.0, y0 + h - M * 0.5, 0.0), Vector3.ZERO)        # top
		_member(Vector3(M, h, M), Vector3(-w * 0.5 + M * 0.5, y0 + h * 0.5, 0.0), Vector3.ZERO)
		_member(Vector3(M, h, M), Vector3(w * 0.5 - M * 0.5, y0 + h * 0.5, 0.0), Vector3.ZERO)
		# the member that makes it rigid
		var diag := sqrt(w * w + h * h)
		var ang := rad_to_deg(atan2(h, w))
		_member(Vector3(diag, M * 0.9, M * 0.9), Vector3(0.0, y0 + h * 0.5, 0.0),
			Vector3(0.0, 0.0, ang))
	else:
		var lean := 22.0
		var dx := h * tan(deg_to_rad(lean))
		_member(Vector3(w, M, M), Vector3(0.0, y0 + M * 0.5, 0.0), Vector3.ZERO)            # bottom
		_member(Vector3(w, M, M), Vector3(dx, y0 + h - M * 0.5, 0.0), Vector3.ZERO)         # top, slid over
		_member(Vector3(M, h, M), Vector3(-w * 0.5 + M * 0.5 + dx * 0.5, y0 + h * 0.5, 0.0),
			Vector3(0.0, 0.0, -lean))
		_member(Vector3(M, h, M), Vector3(w * 0.5 - M * 0.5 + dx * 0.5, y0 + h * 0.5, 0.0),
			Vector3(0.0, 0.0, -lean))


# --- material -------------------------------------------------------------

# Subject colour carries the verdict: cyan holds, red-orange fails.
func _state_mat() -> Material:
	if holds:
		return _grid_material(Color(0.55, 0.62, 0.72), Color(0.45, 0.85, 1.0), 2.0)
	return _grid_material(Color(0.62, 0.42, 0.40), Color(1.0, 0.35, 0.30), 2.0)


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


## Grid config. Keys: "constraint", "holds" (bool), "label", "note".
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("constraint"):
		constraint = str(config_data["constraint"])
	if config_data.has("holds"):
		holds = bool(config_data["holds"])
	if config_data.has("label"):
		demo_label = str(config_data["label"])
	if config_data.has("note"):
		demo_note = str(config_data["note"])
	if _built:
		_build()
