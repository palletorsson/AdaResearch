extends Node3D
class_name ArrayProbe

# @identity
# essence: the same seven cubes arranged four ways — an array is not repetition but a systematic exhaustion of possibility, and the arrangement IS the artifact
# desire: one probe scene serving the four array demos (linear/radial/grid/stack) so Bricolage_Arrays_as_Probes resolves without four near-identical scenes
# critical_parameter: mode — derived from the lookup_name meta (linear_array_demo -> linear, ...); it decides the arrangement rule the cubes obey
# triggers: _ready() reads get_meta("artifact_lookup_name"), lays out seven grid-shaded cubes by the mode's rule, and stands a PAD name plate at the front
# emerges: four probes that are visibly THE SAME PARTS under different laws — walking between them you compare arrangements, not objects, which is the map's whole lesson
# needs: BoxMesh [built-in]; Grid.gdshader [present]; TextScreen PAD plate [commons/ui/text_screen.gd]; lookup_name meta [set pre-_ready by GridInteractablesComponent, proven by specimen_plinth]
# relationships: sibling of specimen_plinth (same one-scene-many-names pattern, transfer_ledger row); kin of bar_array (1D values) and the pattern_tile family (2D repeats); the probe family Bricolage_Arrays_as_Probes stands on
# truth: an array is a law applied to a count. Change the law and the same seven parts become a queue, a council, a field, or a tower — possibility exhausted one arrangement at a time.

## The array-probe wrapper for Bricolage_Arrays_as_Probes. One script serves
## linear_array_demo / radial_array_demo / grid_array_demo / stack_array_demo:
## the mode is read from the lookup_name the grid stamps before _ready().

@export var mode: String = ""            # override; empty = derive from lookup_name
@export var count: int = 7
@export var element_size: float = 0.16
@export var spacing: float = 0.26
@export var primitive_color: Color = Color(0.55, 0.62, 0.72)

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# lookup_name -> [mode, LABEL, note]
const MODES := {
	"linear_array_demo": ["linear", "LINEAR", "a law of nexts — the queue"],
	"radial_array_demo": ["radial", "RADIAL", "a law of angles — the council"],
	"grid_array_demo":   ["grid",   "GRID",   "a law of rows and columns — the field"],
	"stack_array_demo":  ["stack",  "STACK",  "a law of aboves — the tower"],
}

var _built := false


func _ready() -> void:
	if mode == "" and has_meta("artifact_lookup_name"):
		var lk := str(get_meta("artifact_lookup_name"))
		if MODES.has(lk):
			mode = str(MODES[lk][0])
	if mode == "":
		mode = "linear"
	_build()


func _build() -> void:
	if _built:
		for c in get_children():
			c.queue_free()
	_built = true

	var mat := _grid_material(primitive_color, Color(0.45, 0.85, 1.0), 1.8)
	for i in range(count):
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(element_size, element_size, element_size)
		mi.mesh = box
		mi.material_override = mat
		mi.position = _position_for(i)
		add_child(mi)

	_add_label()


func _position_for(i: int) -> Vector3:
	var h := element_size * 0.5 + 0.001
	match mode:
		"radial":
			var ang := TAU * float(i) / float(count)
			var r := spacing * 1.35
			return Vector3(cos(ang) * r, h, sin(ang) * r)
		"grid":
			var side := int(ceil(sqrt(float(count))))
			var col := i % side
			var row := i / side
			var off := float(side - 1) * spacing * 0.5
			return Vector3(float(col) * spacing - off, h, float(row) * spacing - off)
		"stack":
			return Vector3(0.0, h + float(i) * (element_size + 0.015), 0.0)
		_:
			# linear: a row along X, centred
			var off_x := float(count - 1) * spacing * 0.5
			return Vector3(float(i) * spacing - off_x, h, 0.0)


func _add_label() -> void:
	var lk := str(get_meta("artifact_lookup_name")) if has_meta("artifact_lookup_name") else ""
	var label := mode.to_upper()
	var note := ""
	if MODES.has(lk):
		label = str(MODES[lk][1])
		note = str(MODES[lk][2])
	var ts := TextScreenScript.new()
	ts.name = "NamePlate"
	add_child(ts)
	ts.mode = 2                       # PAD — reclined plaque (the label ruling)
	ts.width_m = 0.34
	ts.position = Vector3(0.0, 0.0, spacing * 2.1)
	if ts.has_method("set_text"):
		ts.set_text(label, note)


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


## Grid config: "mode", "count", "spacing", "color".
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("mode"):
		mode = str(config_data["mode"])
	if config_data.has("count"):
		count = clampi(int(config_data["count"]), 1, 64)
	if config_data.has("spacing"):
		spacing = maxf(0.05, float(config_data["spacing"]))
	if config_data.has("color"):
		var c = config_data["color"]
		if c is Color:
			primitive_color = c
		elif c is Array and c.size() >= 3:
			primitive_color = Color(float(c[0]), float(c[1]), float(c[2]))
	if _built:
		_build()
