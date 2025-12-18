@tool
extends Node3D

# Rotating Laser System - FINAL STABILIZED VERSION
# Features: Fixed base pivot, Timed Colors, Grid Layout, Fail-safe Initialization

@export_category("Grid Configuration")
@export var grid_rows: int = 10:
	set(v): grid_rows = v; if is_inside_tree(): _setup_multimesh()
@export var grid_cols: int = 10:
	set(v): grid_cols = v; if is_inside_tree(): _setup_multimesh()
@export var grid_spacing: float = 1.0:
	set(v): grid_spacing = v; if is_inside_tree(): _setup_multimesh()

@export_category("Beam Settings")
@export var beam_length: float = 20.0:
	set(v): beam_length = v; if is_inside_tree(): _setup_mesh_resource()
@export var beam_thickness: float = 0.05:
	set(v): beam_thickness = v; if is_inside_tree(): _setup_mesh_resource()

@export_category("Animation Settings")
@export var pattern_speed: float = 1.0
@export var pattern_amplitude: float = 45.0
@export_enum("Wave", "Focus", "Spread", "Scanning", "Chaos", "SkyWalker") var pattern_type: int = 0

@export_category("Color Settings")
@export var color_change_interval: float = 10.0

var _multimesh_instance: MultiMeshInstance3D
var _time: float = 0.0
var _color_timer: float = 0.0
var _current_color_index: int = 0

const COLOR_SEQUENCE = [Color.GREEN, Color.WHITE, Color.HOT_PINK]

func _ready():
	_setup_multimesh()

func _process(delta):
	# FAIL-SAFE: If anything is Nil during @tool lifecycle, stop immediately
	if color_change_interval == null: return
	if _time == null: _time = 0.0
	if _color_timer == null: _color_timer = 0.0
	
	var interval = float(color_change_interval)
	
	_time += delta
	_color_timer += delta
	
	# Color Sequence Logic
	if _color_timer > interval:
		_color_timer = 0.0
		_current_color_index = (_current_color_index + 1) % COLOR_SEQUENCE.size()
		
	_update_lasers(delta)

func _setup_multimesh():
	if _multimesh_instance: _multimesh_instance.queue_free()
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "LaserGrid"
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = grid_rows * grid_cols
	_multimesh_instance.multimesh = mm
	
	add_child(_multimesh_instance)
	_setup_mesh_resource()

func _setup_mesh_resource():
	if not _multimesh_instance or not _multimesh_instance.multimesh: return
	var mesh = CylinderMesh.new()
	mesh.top_radius = beam_thickness
	mesh.bottom_radius = beam_thickness * 1.5
	mesh.radial_segments = 6
	mesh.rings = 1
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_multimesh_instance.multimesh.mesh = mesh
	_multimesh_instance.material_override = mat

func _update_lasers(_delta):
	if not _multimesh_instance or not _multimesh_instance.multimesh: return
	var mm = _multimesh_instance.multimesh
	var count = grid_rows * grid_cols
	if mm.instance_count != count: return
		
	var center_x = (grid_cols - 1) * grid_spacing / 2.0
	var center_z = (grid_rows - 1) * grid_spacing / 2.0
	var target_color = COLOR_SEQUENCE[_current_color_index]
	target_color.a = 0.6
	
	for row in range(grid_rows):
		for col in range(grid_cols):
			var index = row * grid_cols + col
			var base_pos = Vector3(col * grid_spacing - center_x, 0, row * grid_spacing - center_z)
			var gimbal_basis = Basis()
			
			match pattern_type:
				0: # Wave
					var tilt_x = sin(base_pos.z * 0.5 + _time * pattern_speed) * deg_to_rad(pattern_amplitude)
					var tilt_z = cos(base_pos.x * 0.5 + _time * pattern_speed) * deg_to_rad(pattern_amplitude)
					gimbal_basis = gimbal_basis.rotated(Vector3(1,0,0), tilt_x).rotated(Vector3(0,0,1), tilt_z)
				1: # Focus
					var target = Vector3(sin(_time)*50, 20, cos(_time)*50)
					var look_dir = target - base_pos
					gimbal_basis = Basis.looking_at(look_dir, Vector3.UP).rotated(Vector3.RIGHT, -PI/2.0)
				2: # Spread
					var spin = _time * pattern_speed * (1.0 if (index % 2 == 0) else -1.0)
					gimbal_basis = gimbal_basis.rotated(Vector3.UP, spin).rotated(Vector3.RIGHT, deg_to_rad(pattern_amplitude))
				3: # Scanning
					var scan = sin(_time * pattern_speed) * deg_to_rad(pattern_amplitude * 1.5)
					gimbal_basis = gimbal_basis.rotated(Vector3.RIGHT, scan + row * 0.05)
				4: # Chaos
					gimbal_basis = gimbal_basis.rotated(Vector3.RIGHT, sin(_time + index)*deg_to_rad(pattern_amplitude))
					gimbal_basis = gimbal_basis.rotated(Vector3.FORWARD, cos(_time + index)*deg_to_rad(pattern_amplitude))
				5: # SkyWalker
					gimbal_basis = gimbal_basis.rotated(Vector3.RIGHT, sin(_time + row)*0.05)
			
			var t_base = Transform3D(Basis(), base_pos)
			var t_gimbal = Transform3D(gimbal_basis, Vector3.ZERO)
			var t_laser = Transform3D().scaled(Vector3(1, beam_length, 1))
			t_laser.origin = Vector3(0, beam_length / 2.0, 0)
			
			mm.set_instance_transform(index, t_base * t_gimbal * t_laser)
			mm.set_instance_color(index, target_color)
