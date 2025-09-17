# BerniniColumns.gd
# A 3D procedural generation system that creates spiral columns inspired by
# Gian Lorenzo Bernini's baroque architectural style.
extends Node3D

# -- Configuration --

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

# -- Scene State --
var columns = []

# Column positions (Baldacchino has 4 columns)
var column_positions = [
	Vector3(-2, 0, -2),
	Vector3(2, 0, -2),
	Vector3(-2, 0, 2),
	Vector3(2, 0, 2)
]

# -- Godot Lifecycle Functions --

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
	# Animate the columns if enabled
	if rotate_columns:
		time += delta
		for column in columns:
			# Slow continuous rotation
			column.rotation.y = time * rotation_speed

# --- Procedural Generation Functions ---

func create_spiral_column() -> Node3D:
	# Creates a single, complete column with a base, shaft, and capital.
	var column_node = Node3D.new()
	
	# Create the main spiral shaft
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = generate_spiral_column_mesh()
	
	# Create and apply the material
	var material = StandardMaterial3D.new()
	material.albedo_color = material_color
	material.metallic = 0.8
	material.roughness = 0.2
	mesh_instance.set_surface_override_material(0, material)
	
	column_node.add_child(mesh_instance)
	
	# Add the decorative top and bottom parts
	add_column_base(column_node)
	add_column_capital(column_node)
	
	return column_node

func generate_spiral_column_mesh() -> Mesh:
	# This is the core function that builds the column's geometry vertex by vertex.
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate vertices in rings, moving up the column
	for i in range(vertical_segments + 1):
		var v = float(i) / vertical_segments # Vertical progress (0.0 to 1.0)
		var height = v * column_height
		
		# Calculate the spiral center offset using sine and cosine
		var spiral_angle = v * spiral_density * 2.0 * PI
		var center_offset_x = sin(spiral_angle) * sine_amplitude
		var center_offset_z = cos(spiral_angle) * cosine_amplitude
		
		# Add a secondary wave for more complex Bernini-style shaping
		var secondary_wave = sin(v * PI * 4) * 0.05
		center_offset_x += secondary_wave
		center_offset_z += secondary_wave
		
		# Vary the radius along the height for a more organic feel
		var radius_variation = 1.0 + sin(v * PI * 8) * 0.1
		
		# Create a ring of vertices at the current height
		for j in range(radial_segments + 1): # FIX: Loop to +1 to create a seam vertex
			var u = float(j) / radial_segments # Radial progress (0.0 to 1.0)
			var angle = u * 2.0 * PI + v * twist_factor * 2.0 * PI
			
			# Calculate vertex position with spiral displacement and twist
			var x = cos(angle) * column_radius * radius_variation + center_offset_x
			var z = sin(angle) * column_radius * radius_variation + center_offset_z
			var vertex = Vector3(x, height, z)
			
			# Calculate an approximate normal for lighting
			var normal = Vector3(x - center_offset_x, 0, z - center_offset_z).normalized()
			
			# Add the vertex data to the surface tool
			st.set_normal(normal)
			st.set_uv(Vector2(u, v))
			st.add_vertex(vertex)
	
	# Create the triangle faces that connect the vertices
	for i in range(vertical_segments):
		for j in range(radial_segments): # FIX: Loop only to radial_segments
			# Get indices for the four corners of a quad
			var a = i * (radial_segments + 1) + j
			var b = i * (radial_segments + 1) + j + 1
			var c = (i + 1) * (radial_segments + 1) + j
			var d = (i + 1) * (radial_segments + 1) + j + 1
			
			# Create the first triangle of the quad
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			
			# Create the second triangle of the quad
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	
	# Finalize the mesh generation
	st.generate_normals()
	st.generate_tangents()
	
	return st.commit()

func add_column_base(column_node: Node3D):
	# Adds a tube trail mesh base to the bottom of a column.
	var base = MeshInstance3D.new()
	base.mesh = create_tube_trail_base_mesh()
	base.position.y = -0.25
	
	var material = StandardMaterial3D.new()
	material.albedo_color = material_color
	material.metallic = 0.8
	material.roughness = 0.2
	base.set_surface_override_material(0, material)
	
	column_node.add_child(base)

func add_column_capital(column_node: Node3D):
	# Adds a cylindrical capital to the top of a column.
	var capital = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.bottom_radius = column_radius * 1.2
	cylinder_mesh.top_radius = column_radius * 1.8
	cylinder_mesh.height = 0.6
	cylinder_mesh.radial_segments = radial_segments
	capital.mesh = cylinder_mesh
	capital.position.y = column_height + 0.3
	
	var material = StandardMaterial3D.new()
	material.albedo_color = material_color
	material.metallic = 0.8
	material.roughness = 0.2
	capital.set_surface_override_material(0, material)
	
	column_node.add_child(capital)

# --- Scene Setup Functions ---

func create_platform():
	# Creates a simple box mesh to act as a floor or base.
	var platform = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(6.0, 0.3, 6.0)
	platform.mesh = box_mesh
	platform.position.y = -0.5
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.6, 0.6, 1.0) # Gray marble-like color
	platform.set_surface_override_material(0, material)
	
	add_child(platform)

func create_lighting():
	# Sets up basic lighting for the scene to make the columns visible.
	var dir_light = DirectionalLight3D.new()
	dir_light.light_energy = 1.2
	dir_light.shadow_enabled = true
	dir_light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(dir_light)
	
	var ambient_light = DirectionalLight3D.new()
	ambient_light.light_energy = 0.3
	ambient_light.rotation_degrees = Vector3(45, -135, 0)
	add_child(ambient_light)
	
	# Add a spotlight for each column to create dramatic highlights
	for pos in column_positions:
		var spotlight = SpotLight3D.new()
		spotlight.position = pos + Vector3(0, column_height * 1.5, 0)
		spotlight.look_at(pos)
		spotlight.light_energy = 2.0
		spotlight.light_color = Color(1.0, 0.9, 0.7) # Warm golden light
		spotlight.spot_range = column_height * 2.0
		spotlight.spot_angle = 30.0
		add_child(spotlight)
