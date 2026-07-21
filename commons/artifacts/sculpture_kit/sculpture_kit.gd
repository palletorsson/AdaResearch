extends Node3D
class_name SculptureKit

# @identity
# essence: balance treated as a practice rather than a test — the lever law and the tie shown as principles, then two different compositions that both satisfy them, so equilibrium reads as something you negotiate rather than something you pass
# desire: one artifact that stages the whole sculpture room of the bricolage sequence (counterweight, tension, builder, and two finished works), so the room argues that a balanced form has no single correct answer
# critical_parameter: the station read from the lookup_name meta the grid stamps before _ready — counterweight_demo / tension_demo / sculpture_builder / balanced_sculpture_1 / balanced_sculpture_2; it selects which move of the practice this instance embodies
# triggers: _ready() reads get_meta("artifact_lookup_name"), lays a witness pad, builds that station (masses sized and placed so the lever arithmetic actually holds), and names it on a plaque
# emerges: a room where the two finished sculptures visibly disagree about how to stand and are both right — the constraint is satisfied twice, differently, which is what makes it a craft and not a rule
# needs: Box/Cylinder/SphereMesh [Godot built-in, no SurfaceTool so no null-surface material]; Grid.gdshader [present]; TextScreen PAD plate configured BEFORE add_child [present]; the lookup_name meta [set by GridInteractablesComponent before add_child]
# relationships: the expressive answer to constraint_demo's pass/fail (same balance constraint, now a medium rather than a verdict); kin to the existing calder_mobile artifact, which hangs the same lever law in a mobile — this room keeps to grounded compositions so the two do not repeat each other
# truth: a sculpture that balances is an argument that held. Gravity does not care what it looks like, so everything above the fulcrum is free — which is why balance is the most generous constraint in the sequence: it fixes one number and leaves the rest of the form to you.

## The sculpture kit for the bricolage sequence. One script serves all five
## stations of Bricolage_Sculpture; the station is read from the lookup_name
## the grid stamps as metadata before _ready(), the same wrapper pattern as
## specimen_plinth, constraint_demo and dome_kit.

@export var station: String = ""     # override; empty = derive from lookup_name
@export var kit_label: String = ""
@export var kit_note: String = ""

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

const PAD_W := 0.98

# lookup_name -> [station, LABEL, note]
const STATIONS := {
	"counterweight_demo":   ["counterweight", "COUNTERWEIGHT", "mass times distance, both sides"],
	"tension_demo":         ["tension",       "TENSION",       "a tie pulls where a strut pushes"],
	"sculpture_builder":    ["builder",       "SCULPTURE BENCH", "the fulcrum, and parts not yet placed"],
	"balanced_sculpture_1": ["work_one",      "WORK I",        "balanced by counterweight"],
	"balanced_sculpture_2": ["work_two",      "WORK II",       "balanced by mutual leaning"],
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
		station = "counterweight"
	if kit_label == "":
		kit_label = station.to_upper()


func _build() -> void:
	if _built:
		for c in get_children():
			c.queue_free()
	_built = true
	_add_pad()
	match station:
		"counterweight":
			_build_counterweight()
		"tension":
			_build_tension()
		"builder":
			_build_builder()
		"work_one":
			_build_work_one()
		"work_two":
			_build_work_two()
		_:
			_build_counterweight()
	_add_label()


# --- the five stations ----------------------------------------------------

# COUNTERWEIGHT — the lever law, and the arithmetic actually holds:
# the big block is ~4x the volume of the small one, so it sits ~1/4 the distance out.
func _build_counterweight() -> void:
	var y := 0.04
	_block(Vector3(0.07, 0.20, 0.10), Vector3(0.0, y + 0.10, 0.0), true)          # fulcrum
	_block(Vector3(0.78, 0.035, 0.09), Vector3(0.0, y + 0.218, 0.0), false)       # beam
	var big := 0.155
	var small := 0.098
	# volume ratio ~ (0.155/0.098)^3 ~ 3.96 -> distances inverse: 0.105 vs 0.415
	_block(Vector3(big, big, big), Vector3(-0.105, y + 0.236 + big * 0.5, 0.0), false)
	_block(Vector3(small, small, small), Vector3(0.415, y + 0.236 + small * 0.5, 0.0), false)


# TENSION — the same load held two ways: a thin tie pulling, a thick strut pushing.
func _build_tension() -> void:
	var y := 0.04
	_block(Vector3(0.07, 0.52, 0.07), Vector3(-0.30, y + 0.26, 0.0), true)        # mast
	_block(Vector3(0.56, 0.05, 0.07), Vector3(0.0, y + 0.50, 0.0), true)          # cantilever arm
	# the TIE: thin, from mast top out to the arm's end — in tension
	_rod(Vector3(-0.30, y + 0.52, 0.0), Vector3(0.26, y + 0.475, 0.0), 0.012, false)
	# the load it carries, hung from the arm's end
	_rod(Vector3(0.26, y + 0.475, 0.0), Vector3(0.26, y + 0.30, 0.0), 0.008, false)
	_block(Vector3(0.13, 0.13, 0.13), Vector3(0.26, y + 0.235, 0.0), false)
	# the STRUT doing the same job by pushing, set behind for contrast
	_rod(Vector3(-0.26, y, -0.22), Vector3(0.20, y + 0.46, -0.22), 0.030, true)


# BUILDER — the fulcrum and a part-made composition, the rest still loose.
func _build_builder() -> void:
	var y := 0.04
	_block(Vector3(0.09, 0.26, 0.11), Vector3(-0.10, y + 0.13, 0.0), true)        # the fulcrum
	_block(Vector3(0.52, 0.035, 0.09), Vector3(0.02, y + 0.278, 0.0), false)      # beam, resting askew
	_block(Vector3(0.13, 0.13, 0.13), Vector3(-0.20, y + 0.296 + 0.065, 0.0), false)
	# parts not yet placed, laid out on the pad
	var loose := [0.10, 0.13, 0.075]
	for i in 3:
		var s := float(loose[i])
		_block(Vector3(s, s, s), Vector3(0.14 + float(i) * 0.17, y + s * 0.5, 0.30), true)


# WORK I — a finished piece balanced the counterweight way: one tall mass near
# the fulcrum, a long arm reaching out to a small one.
func _build_work_one() -> void:
	var y := 0.04
	_block(Vector3(0.10, 0.34, 0.10), Vector3(-0.06, y + 0.17, 0.0), true)        # plinth-post
	_block(Vector3(0.62, 0.04, 0.08), Vector3(0.06, y + 0.358, 0.0), false)       # arm
	_block(Vector3(0.17, 0.24, 0.17), Vector3(-0.12, y + 0.378 + 0.12, 0.0), false)
	_block(Vector3(0.09, 0.09, 0.09), Vector3(0.33, y + 0.378 + 0.045, 0.0), false)
	_rod(Vector3(0.33, y + 0.378, 0.0), Vector3(0.33, y + 0.20, 0.0), 0.008, true)
	_block(Vector3(0.07, 0.07, 0.07), Vector3(0.33, y + 0.165, 0.0), false)       # a hung accent


# WORK II — the other solution: three members leaning into each other, no one
# of which stands alone. Balance by mutual support, not by counterweight.
func _build_work_two() -> void:
	var y := 0.04
	var top := Vector3(0.0, y + 0.50, 0.0)
	var feet := [Vector3(-0.24, y, -0.14), Vector3(0.24, y, -0.14), Vector3(0.0, y, 0.26)]
	for f in feet:
		_rod(f as Vector3, top, 0.026, false)
	_block(Vector3(0.12, 0.12, 0.12), Vector3(0.0, y + 0.55, 0.0), false)         # the shared cap
	# a slab resting across two of the legs — held only by the leaning
	_block(Vector3(0.34, 0.03, 0.13), Vector3(0.0, y + 0.24, -0.14), true)


# --- pieces ---------------------------------------------------------------

func _block(size: Vector3, pos: Vector3, witness: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = _witness_mat() if witness else _subject_mat()
	add_child(mi)
	return mi


# A rod between two points — the cylinder's Y axis laid along the span.
func _rod(p1: Vector3, p2: Vector3, radius: float, witness: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var d := p1.distance_to(p2)
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = max(0.001, d)
	cyl.radial_segments = 8
	cyl.rings = 1
	mi.mesh = cyl
	var dir := (p2 - p1).normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var xa := up.cross(dir).normalized()
	var za := dir.cross(xa).normalized()
	mi.transform = Transform3D(Basis(xa, dir, za), (p1 + p2) * 0.5)
	mi.material_override = _witness_mat() if witness else _subject_mat()
	add_child(mi)
	return mi


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
	# Configure BEFORE add_child — TextScreen's setters rebuild only when already
	# in-tree, so driving them post-add forces a queue_free/rebuild per property
	# and leaves the renderer holding freed materials. Set first, add last.
	var ts := TextScreenScript.new()
	ts.name = "WorkPlate"
	ts.mode = 2                       # Mode.PAD — reclined plaque
	ts.width_m = 0.36
	ts.position = Vector3(0.0, 0.045, PAD_W * 0.5 - 0.06)
	if ts.has_method("set_text"):
		ts.set_text(kit_label, kit_note)
	add_child(ts)


# --- material -------------------------------------------------------------

func _subject_mat() -> Material:
	return _grid_material(Color(0.55, 0.62, 0.72), Color(0.45, 0.85, 1.0), 2.0)


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
