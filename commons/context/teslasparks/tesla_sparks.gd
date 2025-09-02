extends Node3D

@export var sphere_scene: PackedScene  # Packed scene for the sphere
@export var num_segments: int = 10  # Number of segments in the spark line
@export var randomness: float = 0.1  # Controls how much randomness in the spark path
@export var line_width: float = 0.005  # Width of the spark line
@export var sphere_scale: float = 0.05  # Scale for the sphere instances

@onready var mesh = ImmediateMesh.new()  # Create the mesh for the spark
@onready var mesh_instance = MeshInstance3D.new()  # MeshInstance to hold the ImmediateMesh
@onready var label: Label3D = $Label3D  # Label for displaying positions
@onready var start_sphere: Node3D
@onready var end_sphere: Node3D
@onready var start_node =  $teslasphereGrabMeLow/startNode # Node3D to act as the starting point
@onready var end_node =  $teslasphereGrabMeTop/endNode # Node3D to act as the ending point

# Custom material for double-sided white rendering
@onready var white_material = ShaderMaterial.new()

# Called when the node enters the scene tree for the first time
func _ready():
	# Assign the ImmediateMesh to the MeshInstance
	mesh_instance.mesh = mesh
	add_child(mesh_instance)  # Add the MeshInstance to the scene

	# Create the shader for double-sided white texture
	_create_white_material()

	# Apply the shader material to the mesh
	mesh_instance.material_override = white_material

	# Create spheres at the start_node and end_node positions
	# start_sphere = place_sphere(start_node.global_transform.origin - self.global_transform.origin)
	# end_sphere = place_sphere(end_node.global_transform.origin - self.global_transform.origin)

	# Start generating sparks in real-time
	_generate_spark_from_nodes()

# Function to generate the spark between the start_node and end_node positions
func _generate_spark(start: Vector3, end: Vector3):
	mesh.clear_surfaces()  # Clear any previous geometry
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)  # Start drawing triangles for the thicker line

	var last_position = start

	for i in range(1, num_segments + 1):
		# Interpolate between start and end
		var t = float(i) / num_segments
		var next_position = start.lerp(end, t)
		
		# Add randomness to the path to simulate an electric spark
		next_position.x += randf_range(-randomness, randomness)
		next_position.y += randf_range(-randomness, randomness)
		next_position.z += randf_range(-randomness, randomness)
		
		# Calculate direction between points and perpendicular vector for thickness
		var direction = (next_position - last_position).normalized()
		var perpendicular = direction.cross(Vector3.UP).normalized() * line_width

		# Create quads (two triangles) between each segment to simulate a wider line
		var p1 = last_position + perpendicular
		var p2 = last_position - perpendicular
		var p3 = next_position + perpendicular
		var p4 = next_position - perpendicular
		
		# Add the two triangles that form the quad
		mesh.surface_add_vertex(p1)
		mesh.surface_add_vertex(p3)
		mesh.surface_add_vertex(p2)

		mesh.surface_add_vertex(p2)
		mesh.surface_add_vertex(p3)
		mesh.surface_add_vertex(p4)
		
		last_position = next_position

	mesh.surface_end()  # Finish drawing the quads

# Function to create the double-sided white material
func _create_white_material():
	var shader_code = """
		shader_type spatial;
		render_mode cull_disabled; // Disable backface culling, so both sides are rendered

		void fragment() {
			ALBEDO = vec3(1.0, 1.0, 1.0);  // Set the color to white
		}
	"""
	var shader = Shader.new()
	shader.code = shader_code
	white_material.shader = shader

# Function to instance a sphere at a specific position (start or end)
func place_sphere(position: Vector3) -> Node3D:
	var sphere = create_sphere_instance()
	if sphere:
		sphere.global_transform.origin = position
		sphere.scale = Vector3(sphere_scale, sphere_scale, sphere_scale)  # Set sphere scale
		add_child(sphere)  # Add the sphere to the scene
	return sphere

# Utility function to instance the sphere from PackedScene and scale it down
func create_sphere_instance() -> Node3D:
	if not sphere_scene:
		print("Sphere scene not assigned")
		return null
	
	# Instance the sphere
	var sphere = sphere_scene.instantiate() as Node3D
	
	return sphere

# Function to generate sparks from the current positions of the start_node and end_node
func _generate_spark_from_nodes():
	var new_start = start_node.global_transform.origin - self.global_transform.origin
	var new_end = end_node.global_transform.origin - self.global_transform.origin
	_generate_spark(new_start, new_end)

	# Update the label with the current positions of the spheres
	label.text = "Start: " + str(new_start) + "\nEnd: " + str(new_end)

# Update spark position in real-time using _process
func _process(delta):
	_generate_spark_from_nodes()
