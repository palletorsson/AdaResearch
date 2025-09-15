extends Node3D

# Universal Sphere Modifier System
# This version uses a shader for procedural sphere deformation on the GPU

@export_enum("Ordered_Spikes", "Random_Spikes", "Random_Walk", "Hill_Seeking", "Gaussian_Bumps", "Noise_Deformation", "Cellular_Automata") var modifier_mode: int = 0
@export var sphere_subdivisions: int = 3
@export var iterations: int = 20
@export var auto_evolve: bool = false
@export var evolution_speed: float = 2.0

# Common parameters
@export_group("General")
@export var intensity: float = 0.3
@export var smoothing: float = 0.1

# Spike parameters
@export_group("Spike Modes")
@export var spike_count: int = 12
@export var spike_length: float = 0.5
@export var spike_taper: float = 0.8

# Random Walk parameters
@export_group("Random Walk")
@export var walk_step_size: float = 0.05
@export var walk_expansion_rate: float = 0.02
@export var walk_direction_chaos: float = 0.3

# Hill Seeking parameters
@export_group("Hill Seeking")
@export var hill_count: int = 5
@export var hill_attraction_strength: float = 0.08
@export var hill_influence_radius: float = 1.5

# Gaussian parameters
@export_group("Gaussian Bumps")
@export var gaussian_count: int = 8
@export var gaussian_amplitude: float = 0.4
@export var gaussian_width: float = 0.6

# Noise parameters
@export_group("Noise Deformation")
@export var noise_frequency: float = 2.0
@export var noise_octaves: int = 3
@export var noise_amplitude: float = 0.25

# CA parameters
@export_group("Cellular Automata")
@export var ca_neighbor_threshold: int = 3
@export var ca_growth_rate: float = 0.2

# Core components
var mesh_instance: MeshInstance3D
var shader_material: ShaderMaterial
var sphere_material: StandardMaterial3D
var vertices: PackedVector3Array
var original_positions: PackedVector3Array
var original_indices: PackedInt32Array
var current_iteration: int = 0

# UI components
var mode_label: Label3D
var change_label: Label3D

# Measurement variables
var original_volume: float = 0.0
var current_volume: float = 0.0
var total_displacement: float = 0.0

# Evolution system
var evolution_timer: Timer
var is_evolving: bool = false

# DEMO SYSTEM
var demo_timer: Timer
var demo_mode: int = 0
var is_demo_running: bool = false

func _ready():
	set_physics_process(true)#
	setup_mesh()
	setup_material()
	setup_mode_label()
	
	print("=== Universal Sphere Modifier (Shader Version) ===")
	print_current_mode()
	print_controls()
	
	setup_evolution_timer()
	#setup_demo_timer()  # Not needed for iteration-based demo

	# Auto-start demo after a short delay
	await get_tree().create_timer(2.0).timeout
	print("Auto-starting demo in 2 seconds...")
	await get_tree().create_timer(2.0).timeout
	start_demo()

func print_current_mode():
	var mode_names = ["Ordered Spikes", "Random Spikes", "Random Walk", "Hill Seeking", "Gaussian Bumps", "Noise Deformation", "Cellular Automata"]
	print("Current Mode: ", mode_names[modifier_mode])

func print_controls():
	print("Controls:")
	print("  Space - Single step")
	print("  Enter - Toggle auto-evolution")  
	print("  Escape - Reset sphere")
	print("  Up/Down - Change algorithm")
	print("  Left/Right - Adjust intensity")
	print("  Home - Start demo sequence (all modes, 5 sec each)")
	print("  End - Stop demo sequence")

func setup_mesh():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	generate_initial_sphere()

func generate_initial_sphere():
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.height = 2.0
	sphere_mesh.radial_segments = pow(2, sphere_subdivisions) * 8
	sphere_mesh.rings = pow(2, sphere_subdivisions) * 4
	
	var arrays = sphere_mesh.surface_get_arrays(0)
	vertices = arrays[Mesh.ARRAY_VERTEX]
	original_positions = vertices.duplicate()
	
	# Store the original indices. This is crucial for maintaining the mesh structure.
	original_indices = arrays[Mesh.ARRAY_INDEX]
	
	# Create the mesh with proper arrays
	var array_mesh = ArrayMesh.new()
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = calculate_normals()
	mesh_arrays[Mesh.ARRAY_INDEX] = original_indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	mesh_instance.mesh = array_mesh
	
	# Apply the shader material to the mesh
	if shader_material != null:
		mesh_instance.material_override = shader_material
		print("Applied shader material to mesh")
		print("Mesh instance material: %s" % mesh_instance.material_override)
		print("Shader material shader: %s" % shader_material.shader)
	else:
		print("ERROR: Shader material is null!")
	
	# Calculate original volume for change measurement
	original_volume = calculate_sphere_volume()
	
	print("Generated sphere with %d vertices" % vertices.size())
	print("Original volume: %.3f" % original_volume)

func calculate_normals() -> PackedVector3Array:
	var normals = PackedVector3Array()
	normals.resize(vertices.size())
	
	# Simple radial normal calculation for now.
	for i in range(vertices.size()):
		normals[i] = (vertices[i] - Vector3.ZERO).normalized()
	
	return normals

func setup_material():
	# Create fallback material first
	sphere_material = StandardMaterial3D.new()
	sphere_material.albedo_color = Color(0.3, 0.7, 0.9, 1.0)
	sphere_material.metallic = 0.2
	sphere_material.roughness = 0.6
	sphere_material.emission_enabled = true
	sphere_material.emission = Color(0.1, 0.3, 0.4) * 0.2
	sphere_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Try to load shader
	var shader = load("res://algorithms/randomness/walkingsphere/shperemod.gdshader")
	if shader == null:
		print("Warning: Could not load sphere modification shader, using fallback material")
		mesh_instance.material_override = sphere_material
		return
	
	# Create ShaderMaterial with sphere modification shader
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	mesh_instance.material_override = shader_material
	
	# Set initial shader parameters
	update_shader_parameters()
	
	print("Walking Sphere: Using sphere modification shader for material")
	print("Shader material created: %s" % shader_material)
	print("Shader resource: %s" % shader)

func setup_mode_label():
	"""Create 3D labels to display the current mode and measurements"""
	# Mode label
	mode_label = Label3D.new()
	mode_label.text = "Mode: " + get_mode_name()
	mode_label.font_size = 24
	mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mode_label.position = Vector3(0, 2.5, 0)  # Above the sphere
	mode_label.modulate = Color.WHITE
	mode_label.outline_size = 4
	mode_label.outline_modulate = Color.BLACK
	add_child(mode_label)
	
	# Change measurement label
	change_label = Label3D.new()
	change_label.text = "Change: 0.0%"
	change_label.font_size = 18
	change_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	change_label.position = Vector3(0, 2.0, 0)  # Below mode label
	change_label.modulate = Color.YELLOW
	change_label.outline_size = 3
	change_label.outline_modulate = Color.BLACK
	add_child(change_label)

func get_mode_name() -> String:
	var mode_names = ["Ordered Spikes", "Random Spikes", "Random Walk", "Hill Seeking", "Gaussian Bumps", "Noise Deformation", "Cellular Automata"]
	return mode_names[modifier_mode]

func update_mode_label():
	"""Update the label with current mode and iteration"""
	if mode_label != null:
		mode_label.text = "%s\nStep: %d/%d" % [get_mode_name(), current_iteration, iterations]

func calculate_sphere_volume() -> float:
	"""Calculate approximate volume of the deformed sphere"""
	if vertices.size() == 0:
		return 0.0
	
	# Calculate average radius from center
	var total_radius = 0.0
	for vertex in vertices:
		total_radius += vertex.length()
	
	var average_radius = total_radius / vertices.size()
	return (4.0 / 3.0) * PI * pow(average_radius, 3)

func calculate_total_displacement() -> float:
	"""Calculate total displacement from original positions"""
	if vertices.size() != original_positions.size():
		return 0.0
	
	var total_displacement = 0.0
	for i in range(vertices.size()):
		var displacement = vertices[i].distance_to(original_positions[i])
		total_displacement += displacement
	
	return total_displacement / vertices.size()  # Average displacement

func measure_sphere_change():
	"""Measure and update the overall change in the sphere"""
	if vertices.size() == 0:
		return
	
	# Calculate current measurements
	current_volume = calculate_sphere_volume()
	total_displacement = calculate_total_displacement()
	
	# Calculate percentage change
	var volume_change = 0.0
	if original_volume > 0.0:
		volume_change = ((current_volume - original_volume) / original_volume) * 100.0
	
	# Update change label
	if change_label != null:
		change_label.text = "Vol: %.1f%% | Disp: %.3f" % [volume_change, total_displacement]
	
	# Print detailed measurements
	print("Sphere Change - Volume: %.1f%% | Avg Displacement: %.3f" % [volume_change, total_displacement])

func update_shader_parameters():
	"""Update shader parameters with current values"""
	if shader_material == null or not shader_material is ShaderMaterial:
		print("Warning: Shader material not available for parameter update")
		return
	
	# Basic parameters
	shader_material.set_shader_parameter("mode", float(modifier_mode))
	shader_material.set_shader_parameter("intensity", intensity)
	shader_material.set_shader_parameter("smoothing", smoothing)
	shader_material.set_shader_parameter("iteration", float(current_iteration))
	shader_material.set_shader_parameter("iterations", float(iterations))
	
	# Debug: Print key parameters every 5 steps
	if current_iteration % 5 == 0:
		print("Shader params - Mode: %d, Iteration: %d/%d, Intensity: %.2f" % [modifier_mode, current_iteration, iterations, intensity])
		print("Shader material valid: %s" % (shader_material != null))
		if shader_material != null:
			print("Shader mode param: %s" % shader_material.get_shader_parameter("mode"))
			print("Shader intensity param: %s" % shader_material.get_shader_parameter("intensity"))
	
	# Spike parameters
	shader_material.set_shader_parameter("spike_count", float(spike_count))
	shader_material.set_shader_parameter("spike_length", spike_length)
	shader_material.set_shader_parameter("spike_taper", spike_taper)
	
	# Random Walk parameters
	shader_material.set_shader_parameter("walk_step_size", walk_step_size)
	shader_material.set_shader_parameter("walk_expansion_rate", walk_expansion_rate)
	shader_material.set_shader_parameter("walk_direction_chaos", walk_direction_chaos)
	
	# Hill Seeking parameters
	shader_material.set_shader_parameter("hill_count", float(hill_count))
	shader_material.set_shader_parameter("hill_attraction_strength", hill_attraction_strength)
	shader_material.set_shader_parameter("hill_influence_radius", hill_influence_radius)
	
	# Gaussian parameters
	shader_material.set_shader_parameter("gaussian_count", float(gaussian_count))
	shader_material.set_shader_parameter("gaussian_amplitude", gaussian_amplitude)
	shader_material.set_shader_parameter("gaussian_width", gaussian_width)
	
	# Noise parameters
	shader_material.set_shader_parameter("noise_frequency", noise_frequency)
	shader_material.set_shader_parameter("noise_octaves", float(noise_octaves))
	shader_material.set_shader_parameter("noise_amplitude", noise_amplitude)
	
	# CA parameters
	shader_material.set_shader_parameter("ca_neighbor_threshold", float(ca_neighbor_threshold))
	shader_material.set_shader_parameter("ca_growth_rate", ca_growth_rate)

func setup_evolution_timer():
	evolution_timer = Timer.new()
	evolution_timer.wait_time = 1.0 / evolution_speed
	evolution_timer.timeout.connect(_on_evolution_step)
	add_child(evolution_timer)
	
	if auto_evolve:
		start_evolution()
	
	# Initial uniform setup
	update_shader_parameters()

func update_material_color():
	var progress = float(current_iteration) / iterations
	var colors = [
		Color.RED,    # Ordered spikes
		Color.ORANGE, # Random spikes  
		Color.GREEN,  # Random walk
		Color.BLUE,   # Hill seeking
		Color.PURPLE, # Gaussian
		Color.YELLOW, # Noise
		Color.CYAN    # Cellular Automata
	]
	
	var target_color = colors[modifier_mode]
	var current_color = Color.WHITE.lerp(target_color, progress)
	
	# Update material color based on material type
	if shader_material != null and shader_material is ShaderMaterial:
		# For shader material, we can add color as a uniform
		shader_material.set_shader_parameter("albedo_color", current_color)
	elif sphere_material != null and sphere_material is StandardMaterial3D:
		sphere_material.albedo_color = current_color
	
func single_evolution_step():
	print("DEBUG: single_evolution_step - current_iteration: %d, iterations: %d" % [current_iteration, iterations])
	if current_iteration < iterations:
		current_iteration += 1
		update_shader_parameters()
		update_material_color()
		update_mode_label()
		measure_sphere_change()
		
		print("Step %d/%d" % [current_iteration, iterations])
	else:
		print("DEBUG: single_evolution_step - iteration limit reached, not incrementing")

func start_evolution():
	if not is_evolving:
		is_evolving = true
		evolution_timer.start()
		print("Starting evolution...")

func stop_evolution():
	if is_evolving:
		is_evolving = false
		evolution_timer.stop()

func reset_sphere():
	current_iteration = 0
	update_shader_parameters()
	
	# Reset measurements
	original_volume = calculate_sphere_volume()
	current_volume = original_volume
	total_displacement = 0.0
	
	# Update labels
	update_mode_label()
	if change_label != null:
		change_label.text = "Vol: 0.0% | Disp: 0.000"
	
	print("Sphere reset")

func change_mode(new_mode: int):
	modifier_mode = new_mode
	reset_sphere()
	update_mode_label()
	print_current_mode()

func _on_evolution_step():
	print("DEBUG: _on_evolution_step called - current_iteration: %d, iterations: %d" % [current_iteration, iterations])
	single_evolution_step()
	print("DEBUG: After single_evolution_step - current_iteration: %d, iterations: %d" % [current_iteration, iterations])
	if current_iteration >= iterations:
		stop_evolution()
		print("Evolution complete!")
		# If in demo mode, advance to next mode
		if is_demo_running:
			call_deferred("next_demo_mode")

# Demo timer not needed - using iteration-based progression

func start_demo():
	if is_demo_running:
		return
		
	is_demo_running = true
	demo_mode = 0
	modifier_mode = 0
	reset_sphere()
	update_mode_label()
	
	print("=== STARTING DEMO SEQUENCE ===")
	print("Running through all 7 simulation modes...")
	print("Each mode will run for %d iterations" % iterations)
	print("Current Mode: " + get_mode_name())
	print("Starting evolution...")
	
	start_evolution()

func next_demo_mode():
	demo_mode += 1
	
	if demo_mode >= 7:
		print("=== DEMO COMPLETE ===")
		print("All 7 simulation modes have been demonstrated")
		is_demo_running = false
		return
	
	modifier_mode = demo_mode
	reset_sphere()
	update_mode_label()
	print("Current Mode: " + get_mode_name())
	print("Starting evolution...")
	start_evolution()
	

func stop_demo():
	if is_demo_running:
		is_demo_running = false
		stop_evolution()
		print("Demo stopped")

# INPUT HANDLING
func _input(event):
	if event.is_action_pressed("ui_accept"):
		single_evolution_step()
	elif event.is_action_pressed("ui_cancel"):
		reset_sphere()
	elif event.is_action_pressed("ui_select"):
		if is_evolving:
			stop_evolution()
		else:
			start_evolution()
	elif event.is_action_pressed("ui_up"):
		var next_mode = (modifier_mode + 1) % 7
		change_mode(next_mode)
	elif event.is_action_pressed("ui_down"):
		var prev_mode = (modifier_mode - 1 + 7) % 7
		change_mode(prev_mode)
	elif event.is_action_pressed("ui_right"):
		intensity = min(intensity + 0.1, 2.0)
		update_shader_parameters()
		print("Intensity: ", intensity)
	elif event.is_action_pressed("ui_left"):
		intensity = max(intensity - 0.1, 0.1)
		update_shader_parameters()
		print("Intensity: ", intensity)
	elif event.is_action_pressed("ui_home"):
		start_demo()
	elif event.is_action_pressed("ui_end"):
		stop_demo()
