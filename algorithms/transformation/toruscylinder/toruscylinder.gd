extends Node3D
class_name TorusCylinder

## Torus Cylinder — Animated 3D transformation demonstration.
##
## Pairs a continuously rotating torus with a sinusoidally oscillating cylinder
## to teach the two most fundamental animated transformations: rotation and
## periodic translation. An ImmediateMesh motion trail traces the cylinder's
## path, making the sine wave visible in 3D space.

# --- Configuration ---

@export var torus_rotation_speed: float = 0.5  ## rad/s
@export var torus_scale_pulse: float = 0.0  ## amplitude of scale breathing (0 = off)
@export var torus_scale_pulse_speed: float = 1.0
@export var torus_color: Color = Color(1.0, 0.227, 1.0)
@export var torus_radius: float = 1.0

@export var cylinder_osc_speed: float = 1.5  ## frequency multiplier
@export var cylinder_osc_range: float = 1.5  ## peak amplitude
@export var cylinder_color: Color = Color(0.608, 0.282, 1.0)
@export var cylinder_radius: float = 0.3
@export var cylinder_height: float = 1.2

@export var show_trail: bool = true
@export var trail_length: int = 120  ## number of trail points
@export var trail_color: Color = Color(0.4, 0.8, 1.0, 0.7)

# --- Internal ---

var _torus: MeshInstance3D
var _cylinder: MeshInstance3D
var _trail_mesh_inst: MeshInstance3D
var _trail_im: ImmediateMesh
var _trail_points: PackedVector3Array
var _time: float = 0.0


func _ready() -> void:
	_build_torus()
	_build_cylinder()
	if show_trail:
		_build_trail()


func _build_torus() -> void:
	_torus = MeshInstance3D.new()
	_torus.name = "TorusMesh"
	var mesh := TorusMesh.new()
	mesh.inner_radius = torus_radius * 0.6
	mesh.outer_radius = torus_radius * 1.4
	_torus.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = torus_color
	mat.roughness = 0.3
	mat.metallic = 0.4
	_torus.material_override = mat

	add_child(_torus)


func _build_cylinder() -> void:
	_cylinder = MeshInstance3D.new()
	_cylinder.name = "CylinderMesh"
	var mesh := CylinderMesh.new()
	mesh.top_radius = cylinder_radius
	mesh.bottom_radius = cylinder_radius * 0.8
	mesh.height = cylinder_height
	_cylinder.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = cylinder_color
	mat.roughness = 0.4
	mat.metallic = 0.3
	_cylinder.material_override = mat

	# Position cylinder offset from torus center
	_cylinder.position.x = torus_radius * 2.0
	add_child(_cylinder)


func _build_trail() -> void:
	_trail_mesh_inst = MeshInstance3D.new()
	_trail_mesh_inst.name = "TrailMesh"
	_trail_im = ImmediateMesh.new()
	_trail_mesh_inst.mesh = _trail_im

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	_trail_mesh_inst.material_override = mat

	_trail_points = PackedVector3Array()
	add_child(_trail_mesh_inst)


func _process(delta: float) -> void:
	_time += delta

	# Torus: continuous Y-axis rotation
	if _torus:
		_torus.rotation.y += delta * torus_rotation_speed

		# Optional scale pulse (breathing)
		if torus_scale_pulse > 0.0:
			var s := 1.0 + sin(_time * torus_scale_pulse_speed) * torus_scale_pulse
			_torus.scale = Vector3(s, s, s)

	# Cylinder: sinusoidal Y oscillation
	if _cylinder:
		_cylinder.position.y = sin(_time * cylinder_osc_speed) * cylinder_osc_range

		# Record trail
		if show_trail and _trail_im:
			_trail_points.append(_cylinder.position)
			if _trail_points.size() > trail_length:
				_trail_points = _trail_points.slice(_trail_points.size() - trail_length)
			_draw_trail()


func _draw_trail() -> void:
	_trail_im.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var count := _trail_points.size()
	for i in range(count):
		var t := float(i) / float(count - 1)
		var col := trail_color
		col.a = t * trail_color.a  # fade in from old to new
		_trail_im.surface_set_color(col)
		_trail_im.surface_add_vertex(_trail_points[i])
	_trail_im.surface_end()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("torus_rotation_speed"):
		torus_rotation_speed = float(config["torus_rotation_speed"])
	if config.has("torus_scale_pulse"):
		torus_scale_pulse = float(config["torus_scale_pulse"])
	if config.has("torus_scale_pulse_speed"):
		torus_scale_pulse_speed = float(config["torus_scale_pulse_speed"])
	if config.has("torus_color"):
		torus_color = Color(config["torus_color"])
	if config.has("torus_radius"):
		torus_radius = float(config["torus_radius"])
	if config.has("cylinder_osc_speed"):
		cylinder_osc_speed = float(config["cylinder_osc_speed"])
	if config.has("cylinder_osc_range"):
		cylinder_osc_range = float(config["cylinder_osc_range"])
	if config.has("cylinder_color"):
		cylinder_color = Color(config["cylinder_color"])
	if config.has("cylinder_radius"):
		cylinder_radius = float(config["cylinder_radius"])
	if config.has("cylinder_height"):
		cylinder_height = float(config["cylinder_height"])
	if config.has("show_trail"):
		show_trail = bool(config["show_trail"])
	if config.has("trail_length"):
		trail_length = int(config["trail_length"])
	if config.has("trail_color"):
		trail_color = Color(config["trail_color"])

	# Rebuild geometry with new parameters
	for child in get_children():
		child.queue_free()
	_trail_points = PackedVector3Array()
	_time = 0.0
	call_deferred("_ready")
