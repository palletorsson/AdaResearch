@tool
extends Node3D

# Rotating Laser System — Stage Array Layout
# Lasers mounted on overhead rig bars, shooting downward like concert lighting

@export_category("Array Configuration")
@export var array_rows: int = 3:
	set(v): array_rows = v; if is_inside_tree(): _setup_multimesh()
@export var array_cols: int = 12:
	set(v): array_cols = v; if is_inside_tree(): _setup_multimesh()
@export var array_spacing_x: float = 1.2:
	set(v): array_spacing_x = v; if is_inside_tree(): _setup_multimesh()
@export var array_spacing_z: float = 3.0:
	set(v): array_spacing_z = v; if is_inside_tree(): _setup_multimesh()
@export var rig_height: float = 8.0:
	set(v): rig_height = v

@export_category("Beam Settings")
@export var beam_length: float = 15.0:
	set(v): beam_length = v; if is_inside_tree(): _setup_mesh_resource()
@export var beam_thickness: float = 0.04:
	set(v): beam_thickness = v; if is_inside_tree(): _setup_mesh_resource()

@export_category("Animation Settings")
@export var pattern_speed: float = 1.0
@export var pattern_amplitude: float = 55.0
@export_enum("Wave", "Focus", "Spread", "Scanning", "Chaos", "SkyWalker") var pattern_type: int = 0

@export_category("Color Settings")
@export var color_change_interval: float = 10.0

var _multimesh_instance: MultiMeshInstance3D
var _rig_mesh_instance: MeshInstance3D
var _time: float = 0.0
var _color_timer: float = 0.0
var _current_color_index: int = 0

const COLOR_SEQUENCE = [Color.GREEN, Color.WHITE, Color.HOT_PINK]

func _ready() -> void:
	_setup_rig()
	_setup_multimesh()

func _process(delta: float) -> void:
	if color_change_interval == null: return
	if _time == null: _time = 0.0
	if _color_timer == null: _color_timer = 0.0

	var interval = float(color_change_interval)
	_time += delta
	_color_timer += delta

	if _color_timer > interval:
		_color_timer = 0.0
		_current_color_index = (_current_color_index + 1) % COLOR_SEQUENCE.size()

	_update_lasers(delta)

func _setup_rig() -> void:
	# Build visible rig bars (dark metal truss look)
	if _rig_mesh_instance: _rig_mesh_instance.queue_free()

	var rig_node = Node3D.new()
	rig_node.name = "RigBars"
	add_child(rig_node)

	var bar_mat = StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.15, 0.15, 0.18)
	bar_mat.metallic = 0.8
	bar_mat.roughness = 0.4

	var total_width = (array_cols - 1) * array_spacing_x
	for row in range(array_rows):
		var bar = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(total_width + 1.0, 0.15, 0.15)
		box.material = bar_mat
		bar.mesh = box
		var z_off = row * array_spacing_z - (array_rows - 1) * array_spacing_z / 2.0
		bar.position = Vector3(0, rig_height, z_off)
		rig_node.add_child(bar)

func _setup_multimesh() -> void:
	if _multimesh_instance: _multimesh_instance.queue_free()
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "LaserArray"

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = array_rows * array_cols
	_multimesh_instance.multimesh = mm

	add_child(_multimesh_instance)
	_setup_mesh_resource()

func _setup_mesh_resource() -> void:
	if not _multimesh_instance or not _multimesh_instance.multimesh: return
	var mesh = CylinderMesh.new()
	mesh.top_radius = beam_thickness * 0.5
	mesh.bottom_radius = beam_thickness
	mesh.radial_segments = 6
	mesh.rings = 1

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 5.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_multimesh_instance.multimesh.mesh = mesh
	_multimesh_instance.material_override = mat

func _update_lasers(_delta) -> void:
	if not _multimesh_instance or not _multimesh_instance.multimesh: return
	var mm = _multimesh_instance.multimesh
	var count = array_rows * array_cols
	if mm.instance_count != count: return

	var center_x = (array_cols - 1) * array_spacing_x / 2.0
	var center_z = (array_rows - 1) * array_spacing_z / 2.0
	var target_color = COLOR_SEQUENCE[_current_color_index]
	target_color.a = 0.7

	for row in range(array_rows):
		for col in range(array_cols):
			var index = row * array_cols + col
			# Lasers mount on the overhead rig bars
			var mount_pos = Vector3(
				col * array_spacing_x - center_x,
				rig_height,
				row * array_spacing_z - center_z
			)

			# Start pointing straight down (PI rotation around X)
			var gimbal_basis = Basis().rotated(Vector3(1, 0, 0), PI)

			# Normalized position for pattern calculations
			var nx = float(col) / max(array_cols - 1, 1)
			var nz = float(row) / max(array_rows - 1, 1)

			match pattern_type:
				0: # Wave — sweeping sine wave across the array
					var tilt_x = sin(nx * TAU + _time * pattern_speed) * deg_to_rad(pattern_amplitude)
					var tilt_z = cos(nz * TAU + _time * pattern_speed * 0.7) * deg_to_rad(pattern_amplitude * 0.5)
					gimbal_basis = gimbal_basis.rotated(Vector3(1,0,0), tilt_x).rotated(Vector3(0,0,1), tilt_z)
				1: # Focus — all beams converge on a moving floor point
					var floor_target = Vector3(sin(_time * 0.5) * 4.0, 0, cos(_time * 0.5) * 3.0)
					var look_dir = (floor_target - mount_pos).normalized()
					gimbal_basis = Basis.looking_at(look_dir, Vector3.UP)
				2: # Spread — fan outward from center
					var fan_angle = (nx - 0.5) * deg_to_rad(pattern_amplitude * 2.0)
					var fan_tilt = (nz - 0.5) * deg_to_rad(pattern_amplitude)
					var spin = _time * pattern_speed * 0.3
					gimbal_basis = gimbal_basis.rotated(Vector3(0,0,1), fan_angle + sin(spin) * 0.2)
					gimbal_basis = gimbal_basis.rotated(Vector3(1,0,0), fan_tilt)
				3: # Scanning — synchronized sweep
					var scan = sin(_time * pattern_speed) * deg_to_rad(pattern_amplitude)
					var phase = col * 0.15
					gimbal_basis = gimbal_basis.rotated(Vector3(0,0,1), scan + phase)
				4: # Chaos — each laser independent
					gimbal_basis = gimbal_basis.rotated(Vector3(1,0,0), sin(_time * 1.3 + index * 0.7) * deg_to_rad(pattern_amplitude))
					gimbal_basis = gimbal_basis.rotated(Vector3(0,0,1), cos(_time * 0.9 + index * 1.1) * deg_to_rad(pattern_amplitude))
				5: # SkyWalker — gentle sway
					gimbal_basis = gimbal_basis.rotated(Vector3(0,0,1), sin(_time * 0.5 + col * 0.3) * deg_to_rad(15))
					gimbal_basis = gimbal_basis.rotated(Vector3(1,0,0), cos(_time * 0.4 + row * 0.5) * deg_to_rad(10))

			var t_base = Transform3D(Basis(), mount_pos)
			var t_gimbal = Transform3D(gimbal_basis, Vector3.ZERO)
			var t_laser = Transform3D().scaled(Vector3(1, beam_length, 1))
			t_laser.origin = Vector3(0, beam_length / 2.0, 0)

			mm.set_instance_transform(index, t_base * t_gimbal * t_laser)
			mm.set_instance_color(index, target_color)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

