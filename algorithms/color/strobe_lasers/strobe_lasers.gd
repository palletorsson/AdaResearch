@tool
extends Node3D

# Strobe Laser System
# Simulates a nightclub laser scanner effect using high-performance MultiMesh lines.
# Features:
# - Rapid strobing (On/Off)
# - Rotation/Scanning
# - Configurable beam count and spread
# - Rainbow mode

class_name StrobeLaserSystem

@export_group("Lasers")
@export var beam_count: int = 16: set = set_beam_count
@export var beam_length: float = 20.0: set = set_beam_length
@export var beam_thickness: float = 0.05: set = set_beam_thickness
@export var spread_angle_deg: float = 120.0: set = set_spread_angle

@export_group("Animation")
@export var rotation_speed: float = 2.0 # Rads/sec
@export var strobe_frequency: float = 12.0 # Hz
@export var pulse_speed: float = 0.0 # If > 0, length pulses

@export_group("Colors")
@export var laser_color: Color = Color(0.0, 1.0, 0.0, 1.0): set = set_laser_color
@export var rainbow_mode: bool = false
@export var rainbow_speed: float = 0.5

@onready var multimesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D

var _time_accum: float = 0.0
var _strobe_accum: float = 0.0
var _is_on: bool = true

func _ready() -> void:
	if not multimesh_instance:
		_setup_multimesh()
	_update_beams()

func _process(delta: float) -> void:
	_time_accum += delta
	
	# Rotation
	rotate_y(rotation_speed * delta)
	
	# Strobe Logic
	if strobe_frequency > 0:
		_strobe_accum += delta
		var interval = 1.0 / strobe_frequency
		if _strobe_accum >= interval:
			_strobe_accum -= interval
			_is_on = not _is_on
			if multimesh_instance:
				multimesh_instance.visible = _is_on
	else:
		if multimesh_instance:
			multimesh_instance.visible = true
		
	# Rainbow / Color Animation
	if rainbow_mode:
		var hue = wrapf(_time_accum * rainbow_speed, 0.0, 1.0)
		var col = Color.from_hsv(hue, 1.0, 1.0)
		_set_material_color(col)
	
	# Pulse Length
	if pulse_speed > 0:
		var pulse = 1.0 + sin(_time_accum * pulse_speed) * 0.5
		scale.z = pulse # Scale along beam axis

func _setup_multimesh() -> void:
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.name = "MultiMeshInstance3D"
	add_child(multimesh_instance)
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false
	mm.instance_count = beam_count
	multimesh_instance.multimesh = mm
	
	var mesh = CylinderMesh.new()
	mesh.top_radius = beam_thickness
	mesh.bottom_radius = beam_thickness
	mesh.height = 1.0 # Scaled by beam_length later
	mesh.radial_segments = 8
	mesh.rings = 4 
	
	multimesh_instance.multimesh.mesh = mesh
	
	# Load Custom Shader Material
	var shader = load("res://algorithms/color/strobe_lasers/laser_smoke.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("laser_color", laser_color)
	
	# Create a simple noise texture on the fly
	var noise = FastNoiseLite.new()
	noise.frequency = 0.02
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.seamless = true
	mat.set_shader_parameter("noise_texture", noise_tex)
	
	multimesh_instance.material_override = mat

func _update_beams() -> void:
	if not multimesh_instance or not multimesh_instance.multimesh:
		return
		
	var mm = multimesh_instance.multimesh
	mm.instance_count = beam_count
	
	var start_angle = -deg_to_rad(spread_angle_deg) / 2.0
	var angle_step = deg_to_rad(spread_angle_deg) / max(1, beam_count - 1)
	if spread_angle_deg >= 360:
		angle_step = TAU / beam_count
	
	for i in range(beam_count):
		var t = Transform3D()
		# Fan rotation around Y
		var angle = start_angle + (i * angle_step)
		t = t.rotated(Vector3.UP, angle)
		
		# Rotate -90 on X so the cylinder (Y-up) points forward (-Z)
		t = t.rotated(Vector3.RIGHT, -PI/2.0)
		
		# Translate forward (which is now local Y of the rotated cylinder)
		t = t.translated(Vector3(0, beam_length / 2.0, 0))
		
		# Scale length (Y)
		t = t.scaled(Vector3(1, beam_length, 1))
		
		mm.set_instance_transform(i, t)

func set_beam_count(val: int) -> void:
	beam_count = val
	if is_inside_tree(): _update_beams()

func set_beam_length(val: float) -> void:
	beam_length = val
	if is_inside_tree(): _update_beams()

func set_beam_thickness(val: float) -> void:
	beam_thickness = val
	if is_inside_tree(): 
		_setup_geometry_size()
		_update_beams()

func _setup_geometry_size() -> void:
	if multimesh_instance and multimesh_instance.multimesh and multimesh_instance.multimesh.mesh:
		var m = multimesh_instance.multimesh.mesh as CylinderMesh
		if m:
			m.top_radius = beam_thickness
			m.bottom_radius = beam_thickness

func set_spread_angle(val: float) -> void:
	spread_angle_deg = val
	if is_inside_tree(): _update_beams()

func set_laser_color(val: Color) -> void:
	laser_color = val
	_set_material_color(val)

func _set_material_color(col: Color) -> void:
	if multimesh_instance and multimesh_instance.material_override:
		var mat = multimesh_instance.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("laser_color", col)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	if config.has("beam_count"):
		beam_count = int(config["beam_count"])
	if config.has("beam_length"):
		beam_length = float(config["beam_length"])
	if config.has("beam_thickness"):
		beam_thickness = float(config["beam_thickness"])
	if config.has("spread_angle"):
		spread_angle_deg = float(config["spread_angle"])
	if config.has("rotation_speed"):
		rotation_speed = float(config["rotation_speed"])
	if config.has("strobe_frequency"):
		strobe_frequency = float(config["strobe_frequency"])
	if config.has("pulse_speed"):
		pulse_speed = float(config["pulse_speed"])
	if config.has("color"):
		laser_color = Color.from_string(str(config["color"]), laser_color)
	if config.has("rainbow_mode"):
		rainbow_mode = config["rainbow_mode"] == true or str(config["rainbow_mode"]) == "true"
	if config.has("rainbow_speed"):
		rainbow_speed = float(config["rainbow_speed"])
	_setup_multimesh()
	_update_beams()
