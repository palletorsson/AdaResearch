# fluid_form.gd
# QFEP φ > 0 Visualization - Fluid Form
# Queer signature: embraces change, welcomes becoming
# Constantly morphing, flowing, transforming

extends Node3D

class_name QFEPFluidForm

# @identity
# essence: vertex_shader(noise_along_normal * noise_gain + global_wave * sway_gain) + fresnel_iridescence -> morphing sphere
# desire: watch a form that never holds still — always becoming, never arriving
# critical_parameter: flux — WHERE the becoming happens. flow_intensity is how much; flux is whether the skin churns or the whole body moves
# triggers: _process updates shader time continuously; pulse() temporarily triples flow intensity; apply_grid_config re-sets the gains
# emerges: iridescent color shifts at glancing angles — the form appears to have an inner light
# needs: VR flow intensity control [missing], pulse trigger [missing]
# relationships: contrasts rigid_sculpture (phi<0 frozen vs phi>0 flowing); paired with transforming_pattern; depends on phi concept
# truth: positive phi means embracing transformation — the fluid form is not broken, it is becoming

# --- STAGE-2 DNA (promoted 2026-08-04) ---------------------------------------
# flux: where the becoming happens. Same displacement budget, spent differently.
#   mixed (shipped) noise along the normal at full strength PLUS the global wave at
#                   0.3 — the two constants the shader had hard-coded
#   skin            noise along the normal only: the surface boils, the body keeps its
#                   shape. Becoming as presentation
#   sway            the global wave only, at full strength: a smooth body whose whole
#                   silhouette bends. Becoming as morphology
#   still           neither: a perfect sphere with the iridescence still running. The
#                   control — this is what the same form looks like at phi = 0
#
# WHY NOT AN AMOUNT. flow_intensity is this file's declared critical parameter and it is
# the wrong axis: five intensities photograph as five degrees of lumpiness, which is size
# wearing a name. mixed, skin and sway all spend the SAME flow_intensity; they differ only
# in which of the two registers gets it. That is an argument the still can carry.
#
# NOT `becoming`, although queer_morphology_specimen owns that word for phi and sits in
# this artifact's own cluster_with list. Its values — jarred, cracked, escaped, clouded —
# are about the JAR: the specimen's relation to the vitrine that classifies it. This form
# has no jar. Same theme, different question, so a different word.
const FLUXES: PackedStringArray = ["mixed", "skin", "sway", "still"]

## Where the becoming happens. `mixed` is the shipped pair of shader constants.
@export_enum("mixed", "skin", "sway", "still") var flux: String = "mixed"

## Form size
@export var size: float = 0.4

## Morph speed
@export var morph_speed: float = 0.5

## Flow intensity
@export var flow_intensity: float = 0.3

## Embrace color (gold/yellow)
@export var fluid_color: Color = Color(1.0, 0.8, 0.2, 1.0)

## Capture fixture, NOT an axis. Negative (the default) means live time: the form
## morphs and drifts exactly as shipped. Zero or above pins the shader clock and stops
## the idle rotation, so a sweep photographs every flux value at the same phase instead
## of measuring which frame the camera happened to catch. Left untyped on purpose — a
## typed float rejects the string a fixture passes before _ready.
@export var freeze_time = -1.0

# Internal
var _mesh: MeshInstance3D
var _material: ShaderMaterial
var _time: float = 0.0
var _built: bool = false

# Morphing shader
#
# THIS SHADER DID NOT COMPILE. Two errors, both fatal, both present since the file was
# written: `fmod` is not a function in Godot's shading language (that is GDScript's and
# HLSL's name for it — the shader language has `mod`, and `fract` is what this code
# wanted), and `vec3(127.1, 311.7, 74.7, 1.0)` passes four components to a three-component
# constructor. So the material never built and the one shipped placement has been
# rendering an unshaded sphere, not the morphing iridescent form the registry, the name
# and the @identity block all describe. The hash line below is now the same one that
# works in marble_column.gdshader and random_animated.gdshader in this repo.
#
# noise_gain and sway_gain default to 1.0 and 0.3 — the exact constants the vertex
# function had inline — so a shader that is never told about flux reproduces the code
# as written. frag_time defaults negative and falls through to TIME, so the iridescence
# is untouched unless the capture fixture pins it.
const FLUID_SHADER = """
shader_type spatial;

uniform float time = 0.0;
uniform float morph_speed = 0.5;
uniform float flow_intensity = 0.3;
uniform float noise_gain = 1.0;
uniform float sway_gain = 0.3;
uniform float frag_time = -1.0;
uniform vec3 fluid_color : source_color = vec3(1.0, 0.8, 0.2);

// Noise for morphing
float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(mix(hash(i), hash(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(hash(i + vec3(0.0, 1.0, 0.0)), hash(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(hash(i + vec3(0.0, 0.0, 1.0)), hash(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(hash(i + vec3(0.0, 1.0, 1.0)), hash(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

void vertex() {
	// Morph the vertices
	float t = time * morph_speed;
	vec3 pos = VERTEX;

	// Multiple layers of deformation
	float n1 = noise(pos * 3.0 + t);
	float n2 = noise(pos * 5.0 - t * 1.3);

	// The skin register: displacement along the normal.
	vec3 offset = NORMAL * (n1 * n2 - 0.25) * flow_intensity * noise_gain;
	// The sway register: one smooth wave through the whole body.
	offset += vec3(sin(t + pos.y * 4.0), cos(t * 1.2 + pos.x * 3.0), sin(t * 0.8 + pos.z * 5.0)) * flow_intensity * sway_gain;

	VERTEX += offset;
}

void fragment() {
	// Iridescent effect
	float ft = frag_time < 0.0 ? TIME : frag_time;
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 2.0);
	vec3 iridescence = vec3(
		sin(ft + UV.x * 6.28) * 0.5 + 0.5,
		sin(ft * 1.3 + UV.y * 6.28) * 0.5 + 0.5,
		sin(ft * 0.7 + (UV.x + UV.y) * 3.14) * 0.5 + 0.5
	);

	vec3 color = mix(fluid_color, iridescence, fresnel * 0.5);

	ALBEDO = color;
	EMISSION = color * fresnel * 0.5;
	METALLIC = 0.3;
	ROUGHNESS = 0.4;
}
"""

func _ready() -> void:
	_read_dna_meta()
	_build_form()
	_built = true

# GridInteractablesComponent sets `config_*` metadata BEFORE add_child, so this runs
# ahead of the build. An unknown word keeps the default.
func _read_dna_meta() -> void:
	if has_meta("config_flux"):
		var f_in: String = str(get_meta("config_flux")).strip_edges().to_lower()
		flux = f_in if FLUXES.has(f_in) else flux
	if has_meta("config_freeze_time"):
		freeze_time = float(str(get_meta("config_freeze_time")))
	if has_meta("config_size"):
		size = float(str(get_meta("config_size")))

## The flux axis, as (noise_gain, sway_gain).
## `mixed` returns (1.0, 0.3) — the two constants the shader carried inline.
func _flux_gains() -> Vector2:
	match flux:
		"skin":
			return Vector2(1.0, 0.0)
		"sway":
			return Vector2(0.0, 1.0)
		"still":
			return Vector2(0.0, 0.0)
		_:
			return Vector2(1.0, 0.3)

func _build_form() -> void:
	_mesh = MeshInstance3D.new()

	# Start with a sphere that will morph
	var sphere = SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2
	sphere.radial_segments = 32
	sphere.rings = 16
	_mesh.mesh = sphere

	# Apply morphing shader
	_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = FLUID_SHADER
	_material.shader = shader
	_material.set_shader_parameter("fluid_color", Vector3(fluid_color.r, fluid_color.g, fluid_color.b))
	_material.set_shader_parameter("time", 0.0)
	_sync_material()

	_mesh.material_override = _material
	add_child(_mesh)

## Push every non-mesh parameter. Cheap enough that flux never needs a rebuild.
func _sync_material() -> void:
	if not _material:
		return
	var gains: Vector2 = _flux_gains()
	_material.set_shader_parameter("morph_speed", morph_speed)
	_material.set_shader_parameter("flow_intensity", flow_intensity)
	_material.set_shader_parameter("noise_gain", gains.x)
	_material.set_shader_parameter("sway_gain", gains.y)
	_material.set_shader_parameter("frag_time", _frag_time())

func _frag_time() -> float:
	var frozen: float = float(freeze_time)
	return frozen if frozen >= 0.0 else -1.0

func _process(delta: float) -> void:
	var frozen: float = float(freeze_time)
	if frozen >= 0.0:
		# Fixture path: hold the clock, hold the pose. Nothing reaches this unless a
		# capture asked for it — freeze_time ships negative.
		if not is_equal_approx(_time, frozen):
			_time = frozen
			if _material:
				_material.set_shader_parameter("time", _time)
		return

	_time += delta
	if _material:
		_material.set_shader_parameter("time", _time)

	# Also rotate gently
	rotation.y += delta * 0.2
	rotation.x = sin(_time * 0.3) * 0.1

## Set flow intensity
func set_flow(intensity: float) -> void:
	flow_intensity = intensity
	if _material:
		_material.set_shader_parameter("flow_intensity", intensity)

## Pulse the form
func pulse() -> void:
	var original = flow_intensity
	var tween = create_tween()
	tween.tween_method(set_flow, flow_intensity, flow_intensity * 3, 0.2)
	tween.tween_method(set_flow, flow_intensity * 3, original, 0.5)

# --- Grid config -------------------------------------------------------------

## Grid hook. There was none before, so nothing here was reachable from a map token.
##
## GATED BY DATA. A config carrying none of these keys returns before touching anything.
## `flux` needs no rebuild at all — it is two shader uniforms — so only a change of size
## re-makes the mesh, and only after _ready has built once.
func apply_grid_config(config_data: Dictionary) -> void:
	var touched: bool = false
	var before_size: float = size

	if config_data.has("flux"):
		var f_in: String = str(config_data["flux"]).strip_edges().to_lower()
		if FLUXES.has(f_in):
			flux = f_in
			touched = true
	if config_data.has("flow_intensity"):
		flow_intensity = float(str(config_data["flow_intensity"]))
		touched = true
	if config_data.has("morph_speed"):
		morph_speed = float(str(config_data["morph_speed"]))
		touched = true
	if config_data.has("freeze_time"):
		freeze_time = float(str(config_data["freeze_time"]))
		touched = true
	if config_data.has("size"):
		size = float(str(config_data["size"]))
		touched = true

	if not touched or not _built:
		return
	if not is_equal_approx(size, before_size):
		_rebuild_now()
		return
	_sync_material()

func _rebuild_now() -> void:
	if is_instance_valid(_mesh):
		remove_child(_mesh)
		_mesh.queue_free()
	_mesh = null
	_build_form()
