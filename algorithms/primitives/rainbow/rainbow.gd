extends Node3D

# Rainbow parameters
const RAINBOW_RADIUS = 15.0
const RAINBOW_HEIGHT = 8.0
const RAINBOW_SEGMENTS = 64
const RAINBOW_THICKNESS = 0.8

# Double rainbow parameters
const SECONDARY_OFFSET = 3.0
const SECONDARY_FADE = 0.4

# Rainbow colors (ROYGBIV)
var rainbow_colors = [
	Color(1.0, 0.0, 0.0, 1.0),    # Red
	Color(1.0, 0.5, 0.0, 1.0),    # Orange  
	Color(1.0, 1.0, 0.0, 1.0),    # Yellow
	Color(0.0, 1.0, 0.0, 1.0),    # Green
	Color(0.0, 0.0, 1.0, 1.0),    # Blue
	Color(0.3, 0.0, 0.5, 1.0),    # Indigo
	Color(0.5, 0.0, 1.0, 1.0)     # Violet
]

func _ready():
	# Create the primary rainbow
	create_rainbow(Vector3.ZERO, 1.0, false)
	
	# Create the secondary rainbow (larger, fainter, reversed colors)
	create_rainbow(Vector3(0, 1, 0), SECONDARY_FADE, true)
	
	# Add some atmospheric effects
	create_atmosphere()
	


func create_rainbow(offset: Vector3, alpha_multiplier: float, reverse_colors: bool):
	var rainbow_node = Node3D.new()
	rainbow_node.name = "Rainbow_" + str(randf())
	add_child(rainbow_node)
	
	# Create each color band of the rainbow
	for color_index in range(rainbow_colors.size()):
		var color_band = create_color_band(color_index, alpha_multiplier, reverse_colors, offset)
		rainbow_node.add_child(color_band)

func create_color_band(color_index: int, alpha_multiplier: float, reverse_colors: bool, offset: Vector3) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ColorBand_" + str(color_index)
	
	# Create the arc geometry
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	# Calculate radius for this color band
	var inner_radius = RAINBOW_RADIUS + (color_index * RAINBOW_THICKNESS) + (offset.length() * SECONDARY_OFFSET)
	var outer_radius = inner_radius + RAINBOW_THICKNESS
	
	# Get the color for this band
	var actual_color_index = color_index if not reverse_colors else (rainbow_colors.size() - 1 - color_index)
	var band_color = rainbow_colors[actual_color_index]
	band_color.a *= alpha_multiplier * 0.7  # Make more transparent
	
	# Create arc vertices
	for i in range(RAINBOW_SEGMENTS + 1):
		var angle = PI * (float(i) / float(RAINBOW_SEGMENTS))  # Half circle
		var cos_a = cos(angle)
		var sin_a = sin(angle)
		
		# Inner vertex
		var inner_pos = Vector3(inner_radius * cos_a, inner_radius * sin_a, 0) + offset
		vertices.append(inner_pos)
		normals.append(Vector3(0, 0, 1))
		colors.append(band_color)
		
		# Outer vertex  
		var outer_pos = Vector3(outer_radius * cos_a, outer_radius * sin_a, 0) + offset
		vertices.append(outer_pos)
		normals.append(Vector3(0, 0, 1))
		colors.append(band_color)
	
	# Create triangles
	for i in range(RAINBOW_SEGMENTS):
		var base_index = i * 2
		
		# First triangle
		indices.append(base_index)
		indices.append(base_index + 1)
		indices.append(base_index + 2)
		
		# Second triangle
		indices.append(base_index + 1)
		indices.append(base_index + 3)
		indices.append(base_index + 2)
	
	# Assign arrays to mesh
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh
	
	# Create material with transparency
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	material.flags_unshaded = true
	
	mesh_instance.material_override = material
	
	return mesh_instance

func create_atmosphere():
	# Add some atmospheric particles/effects
	var particles = GPUParticles3D.new()
	particles.name = "AtmosphereParticles"
	add_child(particles)
	
	# Create particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.initial_velocity_min = 0.5
	particle_material.initial_velocity_max = 2.0
	particle_material.gravity = Vector3(0, -0.5, 0)
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	particle_material.color = Color(0.8, 0.9, 1.0, 0.3)
	
	particles.process_material = particle_material
	particles.emitting = true
	particles.amount = 100
	particles.position = Vector3(0, -5, 0)
	
	# Create a simple quad mesh for particles
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.2, 0.2)
	particles.draw_pass_1 = quad_mesh
	
	# Particle material
	var draw_material = StandardMaterial3D.new()
	draw_material.albedo_color = Color(1, 1, 1, 0.5)
	draw_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particles.material_override = draw_material



func _process(delta):
	# Add some color cycling for extra effect
	var time = Time.get_time_dict_from_system()
	var time_factor = (time.second + time.minute * 60) * 0.01
	
	# Animate the atmosphere particles
	var particles = get_node_or_null("AtmosphereParticles")
	if particles:
		particles.position.x = sin(time_factor) * 2.0
