@tool
extends Node3D

# Vertical Wave Lines System
# Visualizes a wave function using a grid of vertical lines (MultiMesh).
# "Many lines, one body."

class_name VerticalWaveLines

@export_group("Grid")
@export var grid_size: Vector2i = Vector2i(32, 32): set = set_grid_size
@export var spacing: float = 0.5: set = set_spacing

@export_group("Visuals")
@export var line_thickness: float = 0.05: set = set_line_thickness
@export var line_height: float = 3.0: set = set_line_height
@export var base_color: Color = Color(0.1, 0.1, 0.8): set = set_base_color
@export var wave_color: Color = Color(0.4, 0.8, 1.0): set = set_wave_color

func set_line_height(val: float) -> void:
	line_height = val
	if is_inside_tree():
		if multimesh_instance and multimesh_instance.multimesh and multimesh_instance.multimesh.mesh:
			var m = multimesh_instance.multimesh.mesh as BoxMesh
			if m:
				m.size = Vector3(line_thickness, val, line_thickness)
		_update_grid() # Since translation depends on height

@export_group("Wave Parameters")
@export var speed: float = 2.0: set = set_speed
@export var frequency: float = 0.5: set = set_frequency
@export var amplitude: float = 3.0: set = set_amplitude

@onready var multimesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D

func _ready() -> void:
	if not multimesh_instance:
		_setup_system()
	_update_grid()

func _process(_delta: float) -> void:
	# Shader handles animation via TIME, but we can pass other uniforms if needed manually
	# Currently the shader does it all.
	pass

func _setup_system() -> void:
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.name = "MultiMeshInstance3D"
	add_child(multimesh_instance)
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false 
	multimesh_instance.multimesh = mm
	
	# Create Line Geometry
	# A PrismMesh or BoxMesh works well.
	var mesh = BoxMesh.new()
	mesh.size = Vector3(line_thickness, 1.0, line_thickness) # Base height 1.0
	multimesh_instance.multimesh.mesh = mesh
	
	# Shader Material
	var shader = load("res://algorithms/wavefunctions/vertical_wave_lines/wave_lines.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	multimesh_instance.material_override = mat
	
	_update_uniforms()

func _update_grid() -> void:
	if not multimesh_instance or not multimesh_instance.multimesh:
		return
		
	var mm = multimesh_instance.multimesh
	var total_instances = grid_size.x * grid_size.y
	mm.instance_count = total_instances
	
	var offset_x = (grid_size.x * spacing) * 0.5
	var offset_z = (grid_size.y * spacing) * 0.5
	
	var idx = 0
	for x in range(grid_size.x):
		for z in range(grid_size.y):
			var pos = Vector3(x * spacing - offset_x, 0, z * spacing - offset_z)
			var t = Transform3D(Basis(), pos)
			
			# We don't scale Y here, the shader does it.
			# But we might want to offset Y up by 0.5 if the box pivot is center.
			# BoxMesh pivot is center.
			# So Y=0 means it goes from -0.5 to 0.5.
			# We want it to grow FROM the floor.
			# So translate up by 0.5 * BaseHeight (1.0) = 0.5.
			t = t.translated(Vector3(0, 0.5, 0))
			
			mm.set_instance_transform(idx, t)
			idx += 1

func _update_uniforms() -> void:
	if multimesh_instance and multimesh_instance.material_override:
		var mat = multimesh_instance.material_override as ShaderMaterial
		mat.set_shader_parameter("base_color", base_color)
		mat.set_shader_parameter("wave_color", wave_color)
		mat.set_shader_parameter("time_speed", speed)
		mat.set_shader_parameter("wave_frequency", frequency)
		mat.set_shader_parameter("wave_amplitude", amplitude)

# Setters
func set_grid_size(val: Vector2i) -> void:
	grid_size = val
	if is_inside_tree(): _update_grid()

func set_spacing(val: float) -> void:
	spacing = val
	if is_inside_tree(): _update_grid()

func set_line_thickness(val: float) -> void:
	line_thickness = val
	if multimesh_instance and multimesh_instance.multimesh and multimesh_instance.multimesh.mesh:
		var m = multimesh_instance.multimesh.mesh as BoxMesh
		if m:
			m.size = Vector3(val, 1.0, val)

func set_base_color(val: Color) -> void:
	base_color = val
	_update_uniforms()

func set_wave_color(val: Color) -> void:
	wave_color = val
	_update_uniforms()

func set_speed(val: float) -> void:
	speed = val
	_update_uniforms()

func set_frequency(val: float) -> void:
	frequency = val
	_update_uniforms()

func set_amplitude(val: float) -> void:
	amplitude = val
	_update_uniforms()
