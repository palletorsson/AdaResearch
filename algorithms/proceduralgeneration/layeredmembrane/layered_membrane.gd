extends Node3D

# Layered Folded Membrane Generator
# Creates a 3D structure of undulating membrane-like layers with color gradients

@export_category("Membrane Structure")
@export var radius: float = 3.0
@export var height: float = 2.5
@export var num_layers: int = 50
@export var layer_thickness: float = 0.02
@export var undulation_amount: float = 0.8
@export var radial_segments: int = 60
@export var height_segments: int = 40

@export_category("Color Settings")
@export var inner_color: Color = Color(0.75, 0.3, 0.8)  # Purple
@export var outer_color: Color = Color(0.95, 0.5, 0.3)  # Orange
@export var surface_roughness: float = 0.5
@export var metallic: float = 0.1
@export var specular: float = 0.5
@export var noise_influence: float = 0.2

# Internal variables
var noise = FastNoiseLite.new()
var membrane_container

func _ready():
	# Set up noise generator
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.8
	
	# Create container for all membrane layers
	membrane_container = Node3D.new()
	membrane_container.name = "MembraneContainer"
	add_child(membrane_container)
	
	# Generate the layered membrane
	generate_layered_membrane()
	
	# Set up the environment with proper lighting
	setup_environment()
	


func generate_layered_membrane():
	# Create multiple layers of membranes
	for i in range(num_layers):
		var layer_progress = float(i) / num_layers
		var current_radius = radius * (1.0 - layer_progress * 0.5)
		
		# Create the membrane mesh
		var membrane = create_membrane_layer(current_radius, i)
		membrane_container.add_child(membrane)

func create_membrane_layer(current_radius, layer_index):
	# Create a new membrane layer
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MembraneLayer_" + str(layer_index)
	
	# Progress value from inner to outer (0 to 1)
	var layer_progress = float(layer_index) / num_layers
	
	# Create surface tool for building the mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create mesh data
	var circle_points = radial_segments
	var height_points = height_segments
	
	# Layer specific parameters
	var layer_undulation = undulation_amount * (1.0 - layer_progress * 0.3)
	var layer_height = height * (1.0 - layer_progress * 0.2)
	var layer_phase_offset = layer_index * 0.2
	
	# Generate vertices
	for h in range(height_points + 1):
		var h_ratio = float(h) / height_points
		var h_pos = h_ratio * layer_height
		
		for c in range(circle_points + 1):
			var c_ratio = float(c) / circle_points
			var angle = c_ratio * TAU
			
			# Base radius calculation with undulation
			var radius_variation = sin(angle * 3 + h_pos * 5 + layer_phase_offset) * layer_undulation * 0.3
			radius_variation += sin(angle * 5 + h_pos * 3 - layer_phase_offset) * layer_undulation * 0.2
			radius_variation += noise.get_noise_3d(cos(angle) * 2, sin(angle) * 2, h_pos + layer_index * 0.5) * layer_undulation * noise_influence
			
			var vertex_radius = current_radius + radius_variation
			
			# Calculate position
			var x = cos(angle) * vertex_radius
			var z = sin(angle) * vertex_radius
			var y = h_pos + sin(angle * 4 + layer_phase_offset) * layer_undulation * 0.15
			
			# Add some noise to y position
			y += noise.get_noise_3d(x * 0.5, z * 0.5, layer_index * 0.3) * layer_undulation * 0.3
			
			# Calculate normal (approximate)
			var normal = Vector3(
				cos(angle) + radius_variation * cos(angle),
				layer_undulation * 0.1,
				sin(angle) + radius_variation * sin(angle)
			).normalized()
			
			# Blend between inner and outer color based on layer index
			var vertex_color = inner_color.lerp(outer_color, layer_progress)
			
			# Add some color variation based on position
			var color_noise = noise.get_noise_3d(x, y, z + layer_index) * 0.1
			vertex_color = vertex_color.lightened(color_noise)
			
			# Add vertex with position, normal, color, and UV
			st.set_color(vertex_color)
			st.set_normal(normal)
			st.set_uv(Vector2(c_ratio, h_ratio))
			st.add_vertex(Vector3(x, y, z))
	
	# Generate indices for triangles
	for h in range(height_points):
		for c in range(circle_points):
			var current = h * (circle_points + 1) + c
			var next = current + 1
			var bottom_current = (h + 1) * (circle_points + 1) + c
			var bottom_next = bottom_current + 1
			
			# First triangle
			st.add_index(current)
			st.add_index(bottom_current)
			st.add_index(next)
			
			# Second triangle
			st.add_index(next)
			st.add_index(bottom_current)
			st.add_index(bottom_next)
	
	# Create mesh and assign material
	var mesh = st.commit()
	mesh_instance.mesh = mesh
	
	# Create and assign material
	var material = create_membrane_material(layer_progress)
	mesh_instance.material_override = material
	
	return mesh_instance

func create_membrane_material(layer_progress):
	var material = StandardMaterial3D.new()
	
	# Blend between inner and outer color
	material.albedo_color = inner_color.lerp(outer_color, layer_progress)
	
	# Material properties
	material.roughness = surface_roughness
	material.metallic = metallic
	material.metallic_specular = specular
	
	# Enable vertex colors
	material.vertex_color_use_as_albedo = true
	
	# Subsurface scattering for translucent look
	material.subsurf_scatter_enabled = true
	material.subsurf_scatter_strength = 0.5
	
	# Some transparency for the membrane layers
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.alpha_scissor_threshold = 0.1
	material.albedo_color.a = 0.9
	
	return material

func setup_environment():
	# Create camera
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, height/2, radius * 2)
	camera.look_at_from_position(camera.position, Vector3(0, height/2, 0), Vector3.UP)
	add_child(camera)
	
	# Add lighting
	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.position = Vector3(radius * 2, height * 2, radius * 2)
	main_light.look_at_from_position(main_light.position, Vector3(0, 0, 0), Vector3.UP)
	main_light.light_energy = 1.0
	add_child(main_light)
	
	# Add a fill light from another direction
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.position = Vector3(-radius * 1.5, height, -radius * 1.5)
	fill_light.look_at_from_position(fill_light.position, Vector3(0, 0, 0), Vector3.UP)
	fill_light.light_energy = 0.5
	fill_light.light_color = Color(0.9, 0.8, 1.0)  # Slightly bluish light
	add_child(fill_light)
	
	# Create ambient lighting
	var environment = Environment.new()
	environment.ambient_light_color = Color(0.1, 0.1, 0.2)
	environment.ambient_light_energy = 0.3
	
	var world_environment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

func create_rotation_animation():
	# Create animation player
	var animation_player = AnimationPlayer.new()
	add_child(animation_player)
	
	# Create animation
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	
	# Set track to animate rotation
	animation.track_set_path(track_index, "MembraneContainer:rotation")
	
	# Create keyframes
	animation.track_insert_key(track_index, 0, Vector3(0, 0, 0))
	animation.track_insert_key(track_index, 10, Vector3(0, TAU, 0))  # Full rotation over 10 seconds
	
	# Set animation to loop
	animation.loop_mode = Animation.LOOP_LINEAR
	
	# Add animation to player
	animation_player.add_animation("rotate", animation)
	animation_player.play("rotate")

# Regenerate the membrane with a new random seed
func regenerate():
	# Remove existing membrane
	if membrane_container:
		membrane_container.queue_free()
	
	# Create new container
	membrane_container = Node3D.new()
	membrane_container.name = "MembraneContainer"
	add_child(membrane_container)
	
	# Set new seed for noise
	noise.seed = randi()
	
	# Generate new membrane
	generate_layered_membrane()
	
	# Create rotation animation
	create_rotation_animation()

# Handle input for regeneration
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			regenerate()
