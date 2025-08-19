extends Node3D

# Parameters for column generation
@export var column_height: float = 8.0
@export var column_radius: float = 0.5
@export var spiral_density: float = 3.0  # Number of complete rotations
@export var sine_amplitude: float = 0.15
@export var cosine_amplitude: float = 0.15
@export var vertical_segments: int = 40
@export var radial_segments: int = 16
@export var twist_factor: float = 0.8  # How much the column twists as it rises
@export var material_color: Color = Color(0.8, 0.7, 0.5, 1.0)  # Gold-like color

# For animated rotation
@export var rotate_columns: bool = true
@export var rotation_speed: float = 0.2
var time: float = 0.0

# Nodes for each column
var columns = []

# Column positions (Baldacchino has 4 columns)
var column_positions = [
	Vector3(-2, 0, -2),
	Vector3(2, 0, -2),
	Vector3(-2, 0, 2),
	Vector3(2, 0, 2)
]

func _ready():
	# Create the Baldacchino columns
	for pos in column_positions:
		var column = create_spiral_column()
		column.position = pos
		add_child(column)
		columns.append(column)
	
	# Create a simple platform/base
	create_platform()
	
	# Add a light to highlight the columns
	create_lighting()

func _process(delta):
	if rotate_columns:
		time += delta
		for column in columns:
			column.rotation.y = sin(time * rotation_speed) * 0.1

func create_spiral_column():
	var column_node = Node3D.new()
	
	# Create the mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = generate_spiral_column_mesh()
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = material_color
	material.metallic = 0.8
	material.roughness = 0.2
	mesh_instance.set_surface_override_material(0, material)
	
	# Add mesh to column node
	column_node.add_child(mesh_instance)
	
	# Add a base and capital to the column
	add_column_base(column_node)
	add_column_capital(column_node)
	
	return column_node

func generate_spiral_column_mesh():
	# Create a surface tool for mesh construction
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create spiral column vertices
	for i in range(vertical_segments + 1):
		var v = float(i) / vertical_segments
		var height = v * column_height
		
		# Calculate the center of the column at this height
		# Use sine and cosine to create a spiral effect
		var spiral_angle = v * spiral_density * 2.0 * PI
		var center_offset_x = sin(spiral_angle) * sine_amplitude
		var center_offset_z = cos(spiral_angle) * cosine_amplitude
		
		# Additional sine wave for more complex shaping (Bernini-style)
		var secondary_wave = sin(v * PI * 4) * 0.05
		center_offset_x += secondary_wave
		center_offset_z += secondary_wave
		
		# Calculate radius variation
		var radius_variation = 1.0 + sin(v * PI * 8) * 0.1
		
		for j in range(radial_segments):
			var u = float(j) / radial_segments
			var angle = u * 2.0 * PI + v * twist_factor * 2.0 * PI
			
			# Calculate vertex position with spiral displacement
			var x = cos(angle) * column_radius * radius_variation + center_offset_x
			var z = sin(angle) * column_radius * radius_variation + center_offset_z
			var vertex = Vector3(x, height, z)
			
			# Calculate normal (approximate)
			var normal = Vector3(x - center_offset_x, 0, z - center_offset_z).normalized()
			
			# Add vertex data
			st.set_normal(normal)
			st.set_uv(Vector2(u, v))
			st.add_vertex(vertex)
	
	# Create triangles
	for i in range(vertical_segments):
		for j in range(radial_segments):
			var a = i * (radial_segments + 1) + j
			var b = i * (radial_segments + 1) + j + 1
			var c = (i + 1) * (radial_segments + 1) + j
			var d = (i + 1) * (radial_segments + 1) + j + 1
			
			# Triangle 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			
			# Triangle 2
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	
	# Commit and create the mesh
	st.index()
	st.generate_normals()
	st.generate_tangents()
	
	return st.commit()

func add_column_base(column_node):
	var base = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = column_radius * 1.5
	cylinder_mesh.bottom_radius = column_radius * 2.0
	cylinder_mesh.height = 0.5
	cylinder_mesh.radial_segments = radial_segments
	
	base.mesh = cylinder_mesh
	
	# Position the base
	base.position.y = -0.25
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = material_color
	material.metallic = 0.8
	material.roughness = 0.2
	base.set_surface_override_material(0, material)
	
	column_node.add_child(base)

func add_column_capital(column_node):
	var capital = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.bottom_radius = column_radius * 1.2
	cylinder_mesh.top_radius = column_radius * 1.8
	cylinder_mesh.height = 0.6
	cylinder_mesh.radial_segments = radial_segments
	
	capital.mesh = cylinder_mesh
	
	# Position the capital at the top of the column
	capital.position.y = column_height + 0.3
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = material_color
	material.metallic = 0.8
	material.roughness = 0.2
	capital.set_surface_override_material(0, material)
	
	column_node.add_child(capital)

func create_platform():
	var platform = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(6.0, 0.3, 6.0)
	platform.mesh = box_mesh
	
	# Position the platform below the columns
	platform.position.y = -0.5
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.6, 0.6, 1.0)  # Gray marble-like color
	platform.set_surface_override_material(0, material)
	
	add_child(platform)

func create_lighting():
	# Main directional light (like sunlight)
	var dir_light = DirectionalLight3D.new()
	dir_light.light_energy = 1.2
	dir_light.shadow_enabled = true
	dir_light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(dir_light)
	
	# Ambient light from the opposite direction
	var ambient_light = DirectionalLight3D.new()
	ambient_light.light_energy = 0.3
	ambient_light.rotation_degrees = Vector3(45, -135, 0)
	add_child(ambient_light)
	
	# Spotlights to highlight columns
	for i in range(column_positions.size()):
		var spotlight = SpotLight3D.new()
		spotlight.position = column_positions[i] + Vector3(0, column_height * 1.5, 0)
		spotlight.look_at(column_positions[i])
		spotlight.light_energy = 2.0
		spotlight.light_color = Color(1.0, 0.9, 0.7)  # Warm golden light
		spotlight.spot_range = column_height * 2.0
		spotlight.spot_angle = 30.0
		add_child(spotlight)
