extends Node3D

# Parameters for the cell
var center = Vector3(0, 0, 0)
var base_radius = 1.0
var sphere_resolution = 32  # Resolution for the sphere mesh
var noise_scale = 0.3
var pulse_speed = 1.0
var max_amplitude = 0.3

# Information and entropy variables
var inner_entropy = 0.5
var outer_entropy = 0.5
var information_hotspots = []
var max_hotspots = 8  # More hotspots for 3D
var hotspot_lifetime = 5.0
var current_time = 0.0

# Noise generator for organic movement
var noise = FastNoiseLite.new()
var time_passed = 0.0

# Colors
var inner_color = Color(0.2, 0.4, 0.8, 0.7)  # Blueish for inner world
var membrane_color = Color(0.9, 0.5, 0.2, 0.9)  # Orange for membrane
var outer_color = Color(0.1, 0.7, 0.3, 0.3)  # Greenish for outer world
var info_color = Color(1.0, 0.9, 0.1, 0.8)  # Yellow for information

# 3D visual elements
var membrane_mesh_instance
var inner_mesh_instance
var outer_mesh_instance
var hotspot_parent

# UI Elements
var inner_entropy_label
var outer_entropy_label

func _ready():
	randomize()
	
	# Configure noise with FastNoiseLite
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = 0.05
	noise.fractal_gain = 0.5
	
	# Create the scene structure
	_setup_scene()
	
	# Generate initial information hotspots
	for i in range(3):
		_generate_hotspot()

func _setup_scene():
	# Setup camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 5)
	camera.current = true
	add_child(camera)
	
	# Add environment
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.1)
	env.ambient_light_color = Color(0.2, 0.2, 0.3)
	env.fog_enabled = true
	#env.fog_color = Color(0.05, 0.05, 0.1)
	env.fog_depth_begin = 10.0
	env.fog_depth_end = 30.0
	environment.environment = env
	add_child(environment)
	
	# Add lighting
	var light = DirectionalLight3D.new()
	light.position = Vector3(10, 10, 10)
	light.look_at_from_position(light.position, Vector3.ZERO, Vector3.UP)
	add_child(light)
	
	# Create inner cell mesh
	inner_mesh_instance = MeshInstance3D.new()
	inner_mesh_instance.mesh = SphereMesh.new()
	inner_mesh_instance.mesh.radius = base_radius * 0.7
	inner_mesh_instance.mesh.height = base_radius * 1.4
	inner_mesh_instance.mesh.radial_segments = sphere_resolution
	inner_mesh_instance.mesh.rings = sphere_resolution / 2
	var inner_material = StandardMaterial3D.new()
	inner_material.albedo_color = inner_color
	inner_material.metallic = 0.2
	inner_material.roughness = 0.7
	inner_material.emission_enabled = true
	inner_material.emission = inner_color * 0.5
	inner_material.emission_energy = 0.5
	inner_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_mesh_instance.material_override = inner_material
	add_child(inner_mesh_instance)
	
	# Create membrane mesh
	membrane_mesh_instance = MeshInstance3D.new()
	membrane_mesh_instance.mesh = SphereMesh.new()
	membrane_mesh_instance.mesh.radius = base_radius
	membrane_mesh_instance.mesh.height = base_radius * 2
	membrane_mesh_instance.mesh.radial_segments = sphere_resolution
	membrane_mesh_instance.mesh.rings = sphere_resolution / 2
	var membrane_material = StandardMaterial3D.new()
	membrane_material.albedo_color = membrane_color
	membrane_material.metallic = 0.5
	membrane_material.roughness = 0.3
	membrane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	membrane_material.emission_enabled = true
	membrane_material.emission = membrane_color * 0.3
	membrane_material.emission_energy = 0.8
	membrane_mesh_instance.material_override = membrane_material
	add_child(membrane_mesh_instance)
	
	# Create outer environment mesh
	outer_mesh_instance = MeshInstance3D.new()
	outer_mesh_instance.mesh = SphereMesh.new()
	outer_mesh_instance.mesh.radius = base_radius * 4
	outer_mesh_instance.mesh.height = base_radius * 8
	outer_mesh_instance.mesh.radial_segments = sphere_resolution
	outer_mesh_instance.mesh.rings = sphere_resolution / 2
	var outer_material = StandardMaterial3D.new()
	outer_material.albedo_color = outer_color
	outer_material.metallic = 0.1
	outer_material.roughness = 0.9
	outer_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outer_material.cull_mode = BaseMaterial3D.CULL_FRONT  # Render inside instead of outside
	outer_mesh_instance.material_override = outer_material
	add_child(outer_mesh_instance)
	
	# Create parent for hotspots
	hotspot_parent = Node3D.new()
	hotspot_parent.name = "Hotspots"
	add_child(hotspot_parent)
	
	# Add UI for entropy values
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	inner_entropy_label = Label.new()
	inner_entropy_label.position = Vector2(20, 20)
	inner_entropy_label.text = "Inner Entropy: 0.5"
	canvas_layer.add_child(inner_entropy_label)
	
	outer_entropy_label = Label.new()
	outer_entropy_label.position = Vector2(20, 60)
	outer_entropy_label.text = "Outer Entropy: 0.5"
	canvas_layer.add_child(outer_entropy_label)

func _process(delta):
	time_passed += delta
	current_time += delta
	
	# Update membrane and other visual elements
	_update_visual_elements()
	
	# Process existing hotspots
	_process_hotspots(delta)
	
	# Occasionally generate new hotspots
	if randf() < 0.02:
		_generate_hotspot()
	
	# Adjust entropy based on hotspot interactions
	_adjust_entropy()
	
	# Rotate the cell slowly
	rotate_y(delta * 0.1)

func _update_visual_elements():
	var pulse_factor = sin(time_passed * pulse_speed) * 0.5 + 0.5
	
	# Update membrane mesh with noise and pulsation
	# Instead of complex mesh deformation, we'll use scaling and material effects
	var membrane_mesh = membrane_mesh_instance.mesh
	
	# Apply scale based on pulsation
	var scale_factor = 1.0 + pulse_factor * 0.2
	membrane_mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# Apply material effects to simulate noise
	var membrane_material = membrane_mesh_instance.material_override
	membrane_material.roughness = 0.3 + noise.get_noise_1d(time_passed) * 0.2
	membrane_material.emission_energy = 0.8 + pulse_factor * 0.4
	
	#membrane_mesh_instance.mesh = deformed_mesh
	
	# Update inner and outer meshes
	inner_mesh_instance.scale = Vector3.ONE * (0.7 + 0.1 * sin(time_passed * 0.7))
	
	# Update material properties based on entropy
	var inner_mat = inner_mesh_instance.material_override
	inner_mat.albedo_color = inner_color.lerp(Color(1,1,1,0.7), inner_entropy)
	inner_mat.emission = inner_color.lerp(Color(1,1,1,0.5), inner_entropy) * 0.5
	inner_mat.emission_energy = 0.3 + inner_entropy * 0.7
	
	var outer_mat = outer_mesh_instance.material_override
	outer_mat.albedo_color = outer_color.lerp(Color(0.4,0.8,0.5,0.4), outer_entropy)
	
	# Update UI
	inner_entropy_label.text = "Inner Entropy: " + str(snapped(inner_entropy, 0.01))
	outer_entropy_label.text = "Outer Entropy: " + str(snapped(outer_entropy, 0.01))

func _generate_hotspot():
	if information_hotspots.size() >= max_hotspots:
		return
	
	# Generate a random position on a sphere larger than the membrane
	var phi = randf() * PI * 2
	var theta = acos(2 * randf() - 1)
	var distance = base_radius * (1.5 + randf() * 1.0)
	
	var pos = Vector3(
		sin(theta) * cos(phi),
		sin(theta) * sin(phi),
		cos(theta)
	) * distance
	
	# Create visual representation for the hotspot
	var hotspot_mesh = MeshInstance3D.new()
	hotspot_mesh.mesh = SphereMesh.new()
	var size = 0.05 + randf() * 0.15
	hotspot_mesh.mesh.radius = size
	hotspot_mesh.mesh.height = size * 2
	
	var hotspot_material = StandardMaterial3D.new()
	hotspot_material.albedo_color = info_color
	hotspot_material.emission_enabled = true
	hotspot_material.emission = info_color
	hotspot_material.emission_energy = 1.0
	hotspot_mesh.material_override = hotspot_material
	
	hotspot_mesh.position = pos
	hotspot_parent.add_child(hotspot_mesh)
	
	# Store hotspot data
	information_hotspots.append({
		"position": pos,
		"lifetime": 0,
		"intensity": 0.1 + randf() * 0.9,
		"processed": false,
		"size": size,
		"mesh_instance": hotspot_mesh
	})

func _process_hotspots(delta):
	var i = 0
	while i < information_hotspots.size():
		var hotspot = information_hotspots[i]
		hotspot.lifetime += delta
		
		# Move hotspots toward the membrane if not processed
		if not hotspot.processed:
			var dir = (center - hotspot.position).normalized()
			hotspot.position += dir * delta * 0.3
			hotspot.mesh_instance.position = hotspot.position
			
			# Create trail effect
			if randf() < 0.2:
				var trail = MeshInstance3D.new()
				trail.mesh = SphereMesh.new()
				trail.mesh.radius = hotspot.size * 0.3
				trail.mesh.height = hotspot.size * 0.6
				
				var trail_material = StandardMaterial3D.new()
				trail_material.albedo_color = info_color
				trail_material.albedo_color.a = 0.3
				trail_material.emission_enabled = true
				trail_material.emission = info_color * 0.5
				trail_material.emission_energy = 0.5
				trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				trail.material_override = trail_material
				
				trail.position = hotspot.position
				hotspot_parent.add_child(trail)
				
				# Create a timer to remove the trail
				get_tree().create_timer(1.0).timeout.connect(func(): 
					if trail and is_instance_valid(trail):
						trail.queue_free()
				)
			
			# Check if hotspot has reached the membrane
			var dist_to_center = hotspot.position.length()
			if dist_to_center < base_radius * 1.1 and dist_to_center > base_radius * 0.9:
				hotspot.processed = true
				# Membrane absorbs information - cause a pulse
				time_passed = 0  # Reset pulse phase
				
				# Visual effect for absorption
				var absorption = GPUParticles3D.new()
				var particles_material = ParticleProcessMaterial.new()
				particles_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
				particles_material.emission_sphere_radius = 0.1
				particles_material.direction = Vector3(0, 1, 0)
				particles_material.spread = 180.0
				particles_material.gravity = Vector3.ZERO
				particles_material.initial_velocity_min = 0.2
				particles_material.initial_velocity_max = 0.5
				particles_material.scale_min = 0.02
				particles_material.scale_max = 0.06
				particles_material.color = info_color
				absorption.process_material = particles_material
				
				var particle_mesh = SphereMesh.new()
				particle_mesh.radius = 0.05
				particle_mesh.height = 0.1
				absorption.draw_pass_1 = particle_mesh
				
				absorption.amount = 20
				absorption.one_shot = true
				absorption.explosiveness = 0.8
				absorption.position = hotspot.position
				hotspot_parent.add_child(absorption)
				absorption.emitting = true
				
				# Remove absorption effect after it's done
				get_tree().create_timer(2.0).timeout.connect(func(): 
					if absorption and is_instance_valid(absorption):
						absorption.queue_free()
				)
		else:
			# Once processed, move inside
			var dir = (center - hotspot.position).normalized()
			hotspot.position += dir * delta * 0.15
			hotspot.mesh_instance.position = hotspot.position
			
			# Gradually fade the hotspot as it moves inside
			var hotspot_material = hotspot.mesh_instance.material_override
			hotspot_material.albedo_color.a = clamp(1.0 - hotspot.lifetime / hotspot_lifetime, 0.1, 1.0)
			hotspot_material.emission_energy = clamp(1.0 - hotspot.lifetime / hotspot_lifetime, 0.1, 1.0)
		
		# Remove old hotspots
		if hotspot.lifetime > hotspot_lifetime or hotspot.position.length() < base_radius * 0.5:
			if hotspot.mesh_instance and is_instance_valid(hotspot.mesh_instance):
				hotspot.mesh_instance.queue_free()
			information_hotspots.remove_at(i)
		else:
			i += 1

func _adjust_entropy():
	# Count how many hotspots are being processed at the membrane
	var membrane_activity = 0
	for hotspot in information_hotspots:
		var dist_to_center = hotspot.position.length()
		if hotspot.processed and dist_to_center < base_radius * 1.2:
			membrane_activity += hotspot.intensity
	
	# Adjust inner entropy based on information processing
	inner_entropy = clamp(inner_entropy + membrane_activity * 0.01, 0.1, 0.9)
	
	# Outer entropy fluctuates more chaotically
	outer_entropy = clamp(outer_entropy + (randf() * 0.04 - 0.02), 0.2, 0.8)
	
	# Create Ernst Haeckel-inspired decorative elements in 3D
	if randf() < 0.01:  # Occasionally spawn decorative elements
		_create_decorative_element()

func _create_decorative_element():
	# Create a decorative element inspired by Ernst Haeckel's illustrations
	var decorative = Node3D.new()
	
	# Generate a random position on a sphere around the cell
	var phi = randf() * PI * 2
	var theta = acos(2 * randf() - 1)
	var distance = base_radius * 2.5
	
	var pos = Vector3(
		sin(theta) * cos(phi),
		sin(theta) * sin(phi),
		cos(theta)
	) * distance
	
	decorative.position = pos
	
	# Create central element
	var center_mesh = MeshInstance3D.new()
	center_mesh.mesh = SphereMesh.new()
	var size = 0.1 + 0.05 * sin(time_passed)
	center_mesh.mesh.radius = size
	center_mesh.mesh.height = size * 2
	
	var central_material = StandardMaterial3D.new()
	central_material.albedo_color = Color(0.8, 0.5, 0.9, 0.6)
	central_material.emission_enabled = true
	central_material.emission = Color(0.8, 0.5, 0.9, 0.6) * 0.3
	central_material.emission_energy = 0.5
	central_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	center_mesh.material_override = central_material
	
	decorative.add_child(center_mesh)
	
	# Add small orbiting elements
	var small_element_count = 5
	for i in range(small_element_count):
		var small_phi = 2 * PI * i / small_element_count
		var small_theta = PI * 0.5  # Orbit around equator
		
		var small_pos = Vector3(
			sin(small_theta) * cos(small_phi),
			sin(small_theta) * sin(small_phi),
			cos(small_theta)
		) * (size * 1.5)
		
		var small_mesh = MeshInstance3D.new()
		small_mesh.mesh = SphereMesh.new()
		small_mesh.mesh.radius = size * 0.2
		small_mesh.mesh.height = size * 0.4
		small_mesh.position = small_pos
		
		var small_material = StandardMaterial3D.new()
		small_material.albedo_color = membrane_color.lerp(info_color, 0.5)
		small_material.emission_enabled = true
		small_material.emission = membrane_color.lerp(info_color, 0.5) * 0.5
		small_material.emission_energy = 0.8
		small_mesh.material_override = small_material
		
		decorative.add_child(small_mesh)
	
	hotspot_parent.add_child(decorative)
	
