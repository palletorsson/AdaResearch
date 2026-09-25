extends Node3D
class_name BasinWater

# @identity
# essence: a lid of water over a museum basin — one plane, displaced in the vertex shader by three directional sines and a value noise, coloured by the angle it is seen from; computed for every vertex and pixel on every frame, storing nothing between frames
# desire: to stand on the glass lid over the pool and watch water move under your feet without the pool ever taking you in
# critical_parameter: amplitude — the height the sines and the noise may add; at zero the pool is a still mirror, at 0.2 it reads as open water
# triggers: TIME inside the shader; after _ready nothing on the CPU moves, and no state carries from one frame to the next; TIME wraps every 30 s in this project and the waves are rounded to whole cycles per wrap, so the wrap is invisible here (the first hall's sine panel leaps at it)
# emerges: the surface looks continuous and remembered while being neither — every frame is recomputed from the clock alone, which is the sequence's first lesson made wet
# needs: [missing] slider_horizontal; [missing] push_button — the desk of the hall carries the controls
# relationships: lies in the basin of Shader_09_FBM (the sequence's basin hall), 35 cm under the glass lid, in front of the four FBM displays; the sines are WaveFunctions' and the noise term is sequence eleven's; the pool is the museum's own basin, whose glass lid is what carries the body
# truth: a surface can answer light, position and time without a memory or a body; whatever carries you is something else

## The plane's extent in metres (the museum basin's rect, usually).
@export var width: float = 5.0
@export var depth: float = 5.0
## Metres the surface may rise and fall.
@export var amplitude: float = 0.05
## Wavelength in metres of the longest sine.
@export var wavelength: float = 1.6
## Metres per second along the longest sine.
@export var speed: float = 0.8
## Share of the amplitude given to the noise term.
@export var noise_amount: float = 0.35
## calm = true stills the surface (amplitude 0): a mirror instead of a sea.
@export var calm: bool = false
## Metres above the artifact's origin (the glass lid) at which the mean surface sits.
## Negative is under the lid: -0.35 puts the water 35 cm down, and its crests (10.8 cm
## at amplitude 0.05) never reach the glass.
@export var lift: float = -0.35
## Subdivisions per side of the plane.
@export var subdivisions: int = 48

const SHADER_PATH := "res://commons/artifacts/basin_water/basin_water.gdshader"

var _mesh: MeshInstance3D = null
var _built: bool = false


func _ready() -> void:
	_build()
	_built = true


func _build() -> void:
	if _mesh != null and is_instance_valid(_mesh):
		_mesh.queue_free()
	var plane := PlaneMesh.new()
	plane.size = Vector2(maxf(width, 0.5), maxf(depth, 0.5))
	plane.subdivide_width = clampi(subdivisions, 4, 128)
	plane.subdivide_depth = clampi(subdivisions, 4, 128)
	var mat := ShaderMaterial.new()
	var sh := load(SHADER_PATH)
	if sh != null:
		mat.shader = sh
	mat.set_shader_parameter("amplitude", 0.0 if calm else amplitude)
	mat.set_shader_parameter("wavelength", wavelength)
	mat.set_shader_parameter("speed", speed)
	mat.set_shader_parameter("noise_amount", noise_amount)
	# the clock wraps at this many seconds (project.godot, 30 here); the shader rounds
	# every wave to whole cycles per wrap so the surface never leaps
	mat.set_shader_parameter("rollover", float(ProjectSettings.get_setting("rendering/limits/time/time_rollover_secs", 3600.0)))
	_mesh = MeshInstance3D.new()
	_mesh.name = "Surface"
	_mesh.mesh = plane
	_mesh.material_override = mat
	_mesh.position = Vector3(0.0, lift, 0.0)
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)


## Map tokens reach the surface here, e.g. basin_water:0:0#width:5#depth:5#amplitude:0.08#calm:on
func apply_grid_config(config: Dictionary) -> void:
	var changed := false
	for key in ["width", "depth", "amplitude", "wavelength", "speed", "noise_amount", "lift"]:
		if config.has(key):
			var v: float = float(config[key])
			if v != get(key):
				set(key, v)
				changed = true
	if config.has("calm"):
		var c: bool = str(config["calm"]).to_lower() in ["on", "true", "1", "yes"]
		if c != calm:
			calm = c
			changed = true
	if changed and _built:
		_build()
