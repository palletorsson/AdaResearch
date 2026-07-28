extends Node3D
class_name BridgetRileyOpArt

# @identity
# essence: a two-metre plate of parallel black-and-white lines, sinusoidally displaced by a soft horizontal band, standing at eye height with nothing else in the frame — the lines never move and the band never moves and the surface will not hold still
# desire: one object in the artmathematics room that argues from the retina rather than from a rule; LeWitt gives you the sentence and Molnár gives you the knob, and this gives you a headache you can walk away from
# critical_parameter: g_wobble — displacement amplitude through the band; at 0 the plate is an inert barcode, and every step upward buys shimmer at the cost of the flat reading, until the band stops being a distortion of the lines and becomes an object floating in front of them
# triggers: _build() puts one QuadMesh under a ShaderMaterial running the existing atlas_riley.gdshader; the illusion is fragment-side and needs no _process, so a still capture carries it exactly as VR does
# needs: res://commons/artifacts/pattern_atlas_gallery/shaders/atlas_riley.gdshader [present, already used by the pattern atlas]; QuadMesh [Godot built-in]; Grid.gdshader [present] for frame and plinth; no script of its own for the optics — the shader that works is the shader that ships
# emerges: motion in a static object, produced by nothing in the object — the clearest available demonstration that perception is a construction and not a readout
# relationships: the third wall of the artmathematics trio; it shares the atlas_riley shader with pattern_atlas_gallery, so a viewer who met Riley in the atlas as a thumbnail meets the same surface here at body scale
# truth: op art is not an illusion of movement. It is the visual system caught doing its ordinary job of predicting edges, on a stimulus built so that the prediction never settles — which means the shimmer is not in the painting and not a mistake.

## Bridget Riley op art plate. Parallel lines sinusoidally displaced by a soft
## band, running the atlas_riley shader that already ships with the pattern
## atlas gallery — same fragment code, one artifact instead of a thumbnail.

const RILEY_SHADER := "res://commons/artifacts/pattern_atlas_gallery/shaders/atlas_riley.gdshader"
const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

## Line frequency. 1.0 is 24 stripes across the plate — the shader's own default.
@export_range(0.3, 3.0) var g_scale: float = 1.0
## Line weight bias. Carried through to the shader for parity with the atlas.
@export_range(0.4, 2.2) var g_weight: float = 1.0
## Displacement amplitude through the band — the critical parameter.
@export_range(0.0, 2.5) var g_wobble: float = 1.0
## Overall tint. Riley worked in black and white; leave it white.
@export var g_tint: Color = Color(1.0, 1.0, 1.0)

const PLATE: float = 2.0        # the plate is square, two metres on a side
## Centre at 1.12 m sets the frame's bottom edge on the plinth top and puts the
## shader's band (uv.y 0.55, measured down from the top) at about 1.02 m — chest
## height, where a standing viewer's gaze crosses it without being aimed at it.
const PLATE_Y: float = 1.12

var _built := false
var _created: Array[Node] = []
var _plate_mat: ShaderMaterial = null


func _ready() -> void:
	_build()
	_built = true


func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _build() -> void:
	var plinth := MeshInstance3D.new()
	plinth.name = "Plinth"
	var pbox := BoxMesh.new()
	pbox.size = Vector3(PLATE + 0.14, 0.08, 0.30)
	plinth.mesh = pbox
	plinth.position = Vector3(0.0, 0.04, 0.0)
	plinth.material_override = _grid_material(Color(0.26, 0.28, 0.33), Color(0.45, 0.50, 0.60), 0.5)
	_own(plinth)

	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var fbox := BoxMesh.new()
	fbox.size = Vector3(PLATE + 0.07, PLATE + 0.07, 0.05)
	frame.mesh = fbox
	frame.position = Vector3(0.0, PLATE_Y, -0.03)
	frame.material_override = _grid_material(Color(0.20, 0.22, 0.27), Color(0.45, 0.50, 0.60), 0.4)
	_own(frame)

	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var quad := QuadMesh.new()
	quad.size = Vector2(PLATE, PLATE)
	plate.mesh = quad
	plate.position = Vector3(0.0, PLATE_Y, 0.0)
	plate.material_override = _make_material()
	_own(plate)

	var ts := TextScreenScript.new()
	ts.name = "Plate_Label"
	# PAD, not SCREEN — a reclined plaque on the plinth keeps the two-metre field
	# unbroken. A label standing in front of an op-art plate is a hole in the work.
	ts.mode = 2                     # Mode.PAD
	ts.width_m = 0.34
	ts.position = Vector3(0.0, 0.08, 0.11)
	if ts.has_method("set_text"):
		ts.set_text("OP ART", "the lines are still.\nthe eye is not.")
	_own(ts)


## The shader that already works, with the knobs bound. If it is missing the
## plate falls back to flat white rather than to an invisible surface — a
## missing shader must not make the artifact stop being an object.
func _make_material() -> Material:
	var shader: Shader = load(RILEY_SHADER)
	if shader == null:
		var flat := StandardMaterial3D.new()
		flat.albedo_color = Color(0.94, 0.93, 0.89)
		flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flat.cull_mode = BaseMaterial3D.CULL_DISABLED
		return flat
	_plate_mat = ShaderMaterial.new()
	_plate_mat.shader = shader
	_push_params()
	return _plate_mat


func _push_params() -> void:
	if _plate_mat == null:
		return
	_plate_mat.set_shader_parameter("g_scale", g_scale)
	_plate_mat.set_shader_parameter("g_weight", g_weight)
	_plate_mat.set_shader_parameter("g_wobble", g_wobble)
	_plate_mat.set_shader_parameter("g_tint", Vector3(g_tint.r, g_tint.g, g_tint.b))


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


## Grid config. Keys: "scale", "weight", "wobble", "tint".
## The optics live entirely in shader uniforms, so a config change pushes new
## values into the existing material — there is nothing to tear down and rebuild.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("scale"):
		g_scale = clampf(float(config_data["scale"]), 0.3, 3.0)
	if config_data.has("weight"):
		g_weight = clampf(float(config_data["weight"]), 0.4, 2.2)
	if config_data.has("wobble"):
		g_wobble = clampf(float(config_data["wobble"]), 0.0, 2.5)
	if config_data.has("tint"):
		g_tint = Color(str(config_data["tint"]))

	if not _built:
		return
	_push_params()
