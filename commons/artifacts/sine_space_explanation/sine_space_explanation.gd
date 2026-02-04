# sine_space_explanation.gd
# Explains the TOPOLOGY of sine space - the wave surface mesh
# Shows: y = A·sin(f·x)·cos(f·z) creating the wave terrain

extends Node3D

class_name SineSpaceExplanation

@export var display_size: float = 1.0
@export var grid_resolution: int = 24
@export var amplitude: float = 0.12
@export var frequency: float = 1.5
@export var wave_speed: float = 0.3
@export var surface_color: Color = Color(0.2, 0.5, 0.8)
@export var wireframe_color: Color = Color(0.4, 0.8, 1.0)

var _surface_mesh: MeshInstance3D
var _wireframe_mesh: MeshInstance3D
var _base_plate: MeshInstance3D
var _formula_label: Label3D
var _title_label: Label3D
var _time: float = 0.0


func _ready():
	_create_base_plate()
	_create_surface()
	_create_wireframe()
	_create_labels()
	_create_axis_markers()


func _create_base_plate():
	_base_plate = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(display_size * 1.1, 0.02, display_size * 1.1)
	_base_plate.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.07)
	mat.metallic = 0.2
	mat.roughness = 0.9
	_base_plate.material_override = mat
	_base_plate.position.y = -amplitude - 0.02
	add_child(_base_plate)


func _create_surface():
	_surface_mesh = MeshInstance3D.new()
	_surface_mesh.name = "SineSurface"
	add_child(_surface_mesh)
	
	_update_surface_mesh(0.0)


func _create_wireframe():
	_wireframe_mesh = MeshInstance3D.new()
	_wireframe_mesh.name = "Wireframe"
	add_child(_wireframe_mesh)
	
	_update_wireframe_mesh(0.0)


func _update_surface_mesh(phase: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half = display_size * 0.45
	var step = (half * 2) / grid_resolution
	
	for zi in range(grid_resolution):
		for xi in range(grid_resolution):
			var x0 = -half + xi * step
			var z0 = -half + zi * step
			var x1 = x0 + step
			var z1 = z0 + step
			
			# Calculate heights at corners using sin(x)*cos(z)
			var y00 = _get_height(x0, z0, phase)
			var y10 = _get_height(x1, z0, phase)
			var y01 = _get_height(x0, z1, phase)
			var y11 = _get_height(x1, z1, phase)
			
			var v00 = Vector3(x0, y00, z0)
			var v10 = Vector3(x1, y10, z0)
			var v01 = Vector3(x0, y01, z1)
			var v11 = Vector3(x1, y11, z1)
			
			# Color based on height
			var c00 = _height_to_color(y00)
			var c10 = _height_to_color(y10)
			var c01 = _height_to_color(y01)
			var c11 = _height_to_color(y11)
			
			# Quad as two triangles
			st.set_color(c00); st.add_vertex(v00)
			st.set_color(c10); st.add_vertex(v10)
			st.set_color(c11); st.add_vertex(v11)
			
			st.set_color(c00); st.add_vertex(v00)
			st.set_color(c11); st.add_vertex(v11)
			st.set_color(c01); st.add_vertex(v01)
	
	st.generate_normals()
	_surface_mesh.mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.3
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = surface_color * 0.2
	mat.emission_energy_multiplier = 0.3
	_surface_mesh.material_override = mat


func _update_wireframe_mesh(phase: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	var half = display_size * 0.45
	var step = (half * 2) / grid_resolution
	
	# Draw grid lines in X direction
	for zi in range(grid_resolution + 1):
		var z = -half + zi * step
		for xi in range(grid_resolution):
			var x0 = -half + xi * step
			var x1 = x0 + step
			var y0 = _get_height(x0, z, phase)
			var y1 = _get_height(x1, z, phase)
			
			st.set_color(wireframe_color)
			st.add_vertex(Vector3(x0, y0 + 0.002, z))
			st.add_vertex(Vector3(x1, y1 + 0.002, z))
	
	# Draw grid lines in Z direction
	for xi in range(grid_resolution + 1):
		var x = -half + xi * step
		for zi in range(grid_resolution):
			var z0 = -half + zi * step
			var z1 = z0 + step
			var y0 = _get_height(x, z0, phase)
			var y1 = _get_height(x, z1, phase)
			
			st.set_color(wireframe_color)
			st.add_vertex(Vector3(x, y0 + 0.002, z0))
			st.add_vertex(Vector3(x, y1 + 0.002, z1))
	
	_wireframe_mesh.mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_wireframe_mesh.material_override = mat


func _get_height(x: float, z: float, phase: float) -> float:
	# The sine space formula: y = A * sin(f*x + φ) * cos(f*z + φ)
	return amplitude * sin(frequency * x * TAU / display_size + phase) * cos(frequency * z * TAU / display_size + phase * 0.7)


func _height_to_color(y: float) -> Color:
	var t = (y / amplitude + 1.0) * 0.5  # 0 to 1
	var low_color = Color(0.1, 0.2, 0.4)
	var mid_color = surface_color
	var high_color = Color(0.8, 0.9, 1.0)
	
	if t < 0.5:
		return low_color.lerp(mid_color, t * 2)
	else:
		return mid_color.lerp(high_color, (t - 0.5) * 2)


func _create_labels():
	# Title
	_title_label = Label3D.new()
	_title_label.pixel_size = 0.001
	_title_label.font_size = 52
	_title_label.outline_size = 6
	_title_label.text = "Sine Space Topology"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.position = Vector3(0, amplitude + 0.28, 0)
	_title_label.modulate = wireframe_color
	add_child(_title_label)
	
	# Formula
	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 48
	_formula_label.outline_size = 6
	_formula_label.text = "y = sin(x)·cos(z)"
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(0, amplitude + 0.18, 0)
	_formula_label.modulate = Color(0.9, 0.95, 1.0)
	add_child(_formula_label)
	
	# Explanation - topology description
	var topo_label = Label3D.new()
	topo_label.pixel_size = 0.001
	topo_label.font_size = 32
	topo_label.outline_size = 4
	topo_label.text = "Wave surface: peaks & valleys\nfrom perpendicular sine waves"
	topo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topo_label.position = Vector3(0, -amplitude - 0.12, display_size/2 + 0.08)
	topo_label.rotation.x = -PI/4
	topo_label.modulate = Color(0.7, 0.8, 0.9)
	add_child(topo_label)


func _create_axis_markers():
	# X-axis
	var x_label = Label3D.new()
	x_label.pixel_size = 0.001
	x_label.font_size = 40
	x_label.text = "x →"
	x_label.position = Vector3(display_size * 0.5, -amplitude, 0)
	x_label.modulate = Color(1.0, 0.5, 0.3)
	add_child(x_label)
	
	# Z-axis
	var z_label = Label3D.new()
	z_label.pixel_size = 0.001
	z_label.font_size = 40
	z_label.text = "z →"
	z_label.position = Vector3(0, -amplitude, display_size * 0.5)
	z_label.modulate = Color(0.3, 0.5, 1.0)
	add_child(z_label)
	
	# Y-axis (height)
	var y_label = Label3D.new()
	y_label.pixel_size = 0.001
	y_label.font_size = 36
	y_label.text = "↑ height"
	y_label.position = Vector3(-display_size * 0.52, amplitude * 0.5, 0)
	y_label.rotation.y = PI/2
	y_label.modulate = Color(0.3, 0.9, 0.4)
	add_child(y_label)


func _process(delta):
	_time += delta * wave_speed
	_update_surface_mesh(_time)
	_update_wireframe_mesh(_time)


# Public API
func set_amplitude(a: float) -> void:
	amplitude = a

func set_frequency(f: float) -> void:
	frequency = f

func set_wave_speed(s: float) -> void:
	wave_speed = s
