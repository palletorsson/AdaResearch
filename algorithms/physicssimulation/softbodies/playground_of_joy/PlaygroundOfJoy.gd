extends Node3D

# Playground of Joy - Tactile Interaction Experiences
# Demonstrates soft body physics as joyful, playful interactions

var time := 0.0
var interaction_timer := 0.0
var joy_level := 0.5

# Soft body simulation
var soft_objects := []
var interaction_points := []
var joy_particles := []

# Joy parameters
var bounce_factor := 1.5
var squish_responsiveness := 2.0
var color_vibrancy := 1.0
var playful_gravity := -5.0

class SoftObject:
	var position: Vector3
	var velocity: Vector3
	var vertices: Array
	var springs: Array
	var rest_length: float
	var stiffness: float
	var damping: float
	var joy_factor: float
	var color_hue: float

class JoyParticle:
	var position: Vector3
	var velocity: Vector3
	var life: float
	var color: Color
	var size: float

func _ready():
	create_joyful_soft_bodies()
	initialize_interaction_system()

func _process(delta):
	time += delta
	interaction_timer += delta
	
	update_joy_level()
	simulate_tactile_interactions()
	animate_joyful_responses()
	create_playful_physics()
	visualize_emotional_resonance()

func create_joyful_soft_bodies():
	# Create various playful soft body objects
	for i in range(6):
		var soft_obj = SoftObject.new()
		soft_obj.position = Vector3(
			randf_range(-3, 3),
			randf_range(2, 6),
			randf_range(-3, 3)
		)
		soft_obj.velocity = Vector3.ZERO
		soft_obj.joy_factor = randf_range(0.5, 1.5)
		soft_obj.color_hue = float(i) / 6.0
		soft_obj.stiffness = randf_range(0.8, 1.5)
		soft_obj.damping = 0.95
		
		# Create vertices for soft body
		soft_obj.vertices = []
		for j in range(8):
			var vertex_pos = Vector3(
				cos(float(j) / 8.0 * TAU) * 0.5,
				sin(float(j) / 8.0 * TAU) * 0.5,
				sin(float(j) / 4.0 * TAU) * 0.3
			)
			soft_obj.vertices.append(vertex_pos)
		
		soft_objects.append(soft_obj)

func initialize_interaction_system():
	# Create virtual interaction points that move around
	for i in range(3):
		interaction_points.append({
			"position": Vector3(randf_range(-5, 5), randf_range(1, 8), randf_range(-5, 5)),
			"velocity": Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-2, 2)),
			"strength": randf_range(0.5, 1.5)
		})

func update_joy_level():
	# Joy level influenced by interaction frequency and responsiveness
	var interaction_activity = 0.0
	
	for point in interaction_points:
		for soft_obj in soft_objects:
			var distance = point.position.distance_to(soft_obj.position)
			if distance < 2.0:
				interaction_activity += (2.0 - distance) * 0.1
	
	joy_level = lerp(joy_level, clamp(interaction_activity, 0.2, 1.0), 0.1)

func simulate_tactile_interactions():
	var container = $TactileInteractions
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update interaction points
	for point in interaction_points:
		# Move interaction points in playful patterns
		point.velocity += Vector3(
			sin(time * 2 + point.position.x) * 0.5,
			cos(time * 1.5 + point.position.y) * 0.3,
			sin(time * 2.5 + point.position.z) * 0.5
		) * 0.1
		
		point.velocity *= 0.98  # Damping
		point.position += point.velocity * get_process_delta_time()
		
		# Keep points in bounds
		point.position.x = clamp(point.position.x, -6, 6)
		point.position.y = clamp(point.position.y, 0, 10)
		point.position.z = clamp(point.position.z, -6, 6)
		
		# Visualize interaction point
		var interaction_sphere = CSGSphere3D.new()
		interaction_sphere.radius = 0.3 * point.strength
		interaction_sphere.position = point.position
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.5, 1.0, 0.7)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(1.0, 0.5, 1.0) * point.strength
		interaction_sphere.material_override = material
		
		container.add_child(interaction_sphere)
	
	# Update soft bodies based on interactions
	for soft_obj in soft_objects:
		var total_force = Vector3(0, playful_gravity, 0)
		
		# Check interactions with points
		for point in interaction_points:
			var distance = point.position.distance_to(soft_obj.position)
			if distance < 3.0:
				var interaction_force = (soft_obj.position - point.position).normalized()
				interaction_force *= (3.0 - distance) * point.strength * soft_obj.joy_factor
				total_force += interaction_force
				
				# Create joy particles on interaction
				if distance < 1.5 and randf() < 0.1:
					create_joy_particle(soft_obj.position, soft_obj.color_hue)
		
		# Update soft body physics
		soft_obj.velocity += total_force * get_process_delta_time()
		soft_obj.velocity *= soft_obj.damping
		soft_obj.position += soft_obj.velocity * get_process_delta_time()
		
		# Bounce off ground with joy
		if soft_obj.position.y < 0.5:
			soft_obj.position.y = 0.5
			soft_obj.velocity.y = abs(soft_obj.velocity.y) * bounce_factor * joy_level
			
			# Extra joy on bounce
			for i in range(3):
				create_joy_particle(soft_obj.position, soft_obj.color_hue)
		
		# Visualize soft body
		create_soft_body_visualization(container, soft_obj)

func create_joy_particle(pos: Vector3, hue: float):
	var particle = JoyParticle.new()
	particle.position = pos + Vector3(
		randf_range(-0.5, 0.5),
		randf_range(-0.5, 0.5),
		randf_range(-0.5, 0.5)
	)
	particle.velocity = Vector3(
		randf_range(-2, 2),
		randf_range(1, 4),
		randf_range(-2, 2)
	)
	particle.life = randf_range(1.0, 3.0)
	particle.color = Color.from_hsv(hue, 0.8, 1.0)
	particle.size = randf_range(0.1, 0.3)
	
	joy_particles.append(particle)

func create_soft_body_visualization(container: Node3D, soft_obj: SoftObject):
	# Create deformable soft body visualization
	var squish_factor = 1.0 + sin(time * 5 + soft_obj.position.x) * 0.2 * joy_level
	
	var soft_sphere = CSGSphere3D.new()
	soft_sphere.radius = 0.6 * squish_factor
	soft_sphere.position = soft_obj.position
	
	# Add playful deformation
	soft_sphere.scale = Vector3(
		1.0 + sin(time * 3 + soft_obj.position.x) * 0.1,
		squish_factor,
		1.0 + cos(time * 4 + soft_obj.position.z) * 0.1
	)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.from_hsv(soft_obj.color_hue, 0.7, 1.0, 0.8)
	material.flags_transparent = true
	material.emission_enabled = true
	material.emission = Color.from_hsv(soft_obj.color_hue, 0.7, 1.0) * joy_level * 0.5
	material.metallic = 0.1
	material.roughness = 0.3
	soft_sphere.material_override = material
	
	container.add_child(soft_sphere)

func animate_joyful_responses():
	var container = $JoyfulResponses
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update and visualize joy particles
	var i = 0
	while i < joy_particles.size():
		var particle = joy_particles[i]
		particle.life -= get_process_delta_time()
		
		if particle.life <= 0:
			joy_particles.remove_at(i)
			continue
		
		# Update particle physics
		particle.velocity.y -= 3.0 * get_process_delta_time()  # Gravity
		particle.position += particle.velocity * get_process_delta_time()
		
		# Visualize particle
		var particle_sphere = CSGSphere3D.new()
		particle_sphere.radius = particle.size * (particle.life / 3.0)
		particle_sphere.position = particle.position
		
		var material = StandardMaterial3D.new()
		var alpha = particle.life / 3.0
		material.albedo_color = Color(particle.color.r, particle.color.g, particle.color.b, alpha)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = particle.color * alpha * 0.8
		particle_sphere.material_override = material
		
		container.add_child(particle_sphere)
		
		i += 1
	
	# Create joy waves
	for wave_idx in range(3):
		var wave_radius = fmod(time * 2 + wave_idx * 1.0, 6.0)
		
		var joy_wave = CSGCylinder3D.new()
		joy_wave.top_radius = wave_radius + 0.3
		joy_wave.bottom_radius = wave_radius
		joy_wave.height = 0.1
		joy_wave.position = Vector3(0, 1 + wave_idx * 2, 0)
		
		var material = StandardMaterial3D.new()
		var alpha = (1.0 - wave_radius / 6.0) * joy_level
		material.albedo_color = Color(1.0, 0.8, 0.2, alpha * 0.4)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = Color(1.0, 0.8, 0.2) * alpha * 0.6
		joy_wave.material_override = material
		
		container.add_child(joy_wave)

func create_playful_physics():
	var container = $PlayfulPhysics
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create bouncing playground elements
	var playground_elements = ["Trampoline", "Slide", "Swing", "Seesaw"]
	
	for i in range(playground_elements.size()):
		var element_name = playground_elements[i]
		var base_pos = Vector3(i * 3.0 - 4.5, 0, -4)
		
		create_playground_element(container, element_name, base_pos, i)

func create_playground_element(container: Node3D, element_name: String, base_pos: Vector3, index: int):
	match element_name:
		"Trampoline":
			var trampoline = CSGCylinder3D.new()
			trampoline.top_radius = 1.0
			trampoline.bottom_radius = 1.0
			trampoline.height = 0.2
			trampoline.position = base_pos
			
			# Add bounce animation
			var bounce_height = sin(time * 4 + index) * 0.3 * joy_level
			trampoline.position.y += bounce_height
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.2, 0.8, 1.0)
			material.emission_enabled = true
			material.emission = Color(0.2, 0.8, 1.0) * abs(bounce_height)
			trampoline.material_override = material
			
			container.add_child(trampoline)
		
		"Slide":
			var slide = CSGBox3D.new()
			slide.size = Vector3(0.5, 2.0, 3.0)
			slide.position = base_pos + Vector3(0, 1, 0)
			slide.rotation_degrees = Vector3(20, 0, 0)
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(1.0, 0.3, 0.3)
			material.metallic = 0.8
			material.roughness = 0.1
			slide.material_override = material
			
			container.add_child(slide)
		
		"Swing":
			# Swing seat
			var swing_seat = CSGBox3D.new()
			swing_seat.size = Vector3(0.8, 0.1, 0.3)
			
			var swing_angle = sin(time * 2 + index) * 0.5
			var chain_length = 2.0
			swing_seat.position = base_pos + Vector3(
				sin(swing_angle) * chain_length,
				2.0 - cos(swing_angle) * chain_length,
				0
			)
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.8, 0.5, 0.2)
			swing_seat.material_override = material
			
			container.add_child(swing_seat)
			
			# Swing chains
			for chain_side in range(2):
				var chain = CSGCylinder3D.new()
				chain.top_radius = 0.02
				chain.bottom_radius = 0.02
				chain.height = chain_length
				chain.position = base_pos + Vector3(
					sin(swing_angle) * chain_length * 0.5 + (chain_side - 0.5) * 0.4,
					3.0 - cos(swing_angle) * chain_length * 0.5,
					0
				)
				chain.rotation_degrees = Vector3(0, 0, swing_angle * 57.3)
				
				var chain_material = StandardMaterial3D.new()
				chain_material.albedo_color = Color(0.5, 0.5, 0.5)
				chain.material_override = chain_material
				
				container.add_child(chain)
		
		"Seesaw":
			# Seesaw board
			var seesaw = CSGBox3D.new()
			seesaw.size = Vector3(3.0, 0.2, 0.5)
			seesaw.position = base_pos + Vector3(0, 1, 0)
			
			var seesaw_angle = sin(time * 1.5 + index) * 15
			seesaw.rotation_degrees = Vector3(0, 0, seesaw_angle)
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.6, 0.9, 0.3)
			seesaw.material_override = material
			
			container.add_child(seesaw)
			
			# Seesaw fulcrum
			var fulcrum = CSGCone3D.new()
			fulcrum.radius_top = 0.0
			fulcrum.radius_bottom = 0.3
			fulcrum.height = 0.8
			fulcrum.position = base_pos + Vector3(0, 0.4, 0)
			
			var fulcrum_material = StandardMaterial3D.new()
			fulcrum_material.albedo_color = Color(0.7, 0.4, 0.2)
			fulcrum.material_override = fulcrum_material
			
			container.add_child(fulcrum)

func visualize_emotional_resonance():
	var container = $EmotionalResonance
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create emotional resonance field
	var grid_size = 8
	for i in range(grid_size):
		for j in range(grid_size):
			var pos = Vector3(
				i - grid_size * 0.5,
				0,
				j - grid_size * 0.5
			)
			
			# Calculate emotional intensity based on distance from joy sources
			var emotional_intensity = 0.0
			for soft_obj in soft_objects:
				var distance = pos.distance_to(Vector3(soft_obj.position.x, 0, soft_obj.position.z))
				emotional_intensity += soft_obj.joy_factor / (distance + 1.0)
			
			emotional_intensity *= joy_level
			emotional_intensity = clamp(emotional_intensity, 0.0, 1.0)
			
			if emotional_intensity > 0.1:
				var resonance_pillar = CSGBox3D.new()
				resonance_pillar.size = Vector3(0.3, emotional_intensity * 3.0, 0.3)
				resonance_pillar.position = pos + Vector3(0, resonance_pillar.size.y * 0.5, 0)
				
				var material = StandardMaterial3D.new()
				material.albedo_color = Color.from_hsv(
					0.8 + emotional_intensity * 0.2,  # Purple to pink
					0.8,
					1.0,
					0.6
				)
				material.flags_transparent = true
				material.emission_enabled = true
				material.emission = Color.from_hsv(
					0.8 + emotional_intensity * 0.2,
					0.8,
					1.0
				) * emotional_intensity * 0.5
				resonance_pillar.material_override = material
				
				container.add_child(resonance_pillar)
	
	# Central joy core
	var joy_core = CSGSphere3D.new()
	joy_core.radius = 1.0 + joy_level * 0.5
	joy_core.position = Vector3(0, 3, 0)
	
	var core_material = StandardMaterial3D.new()
	core_material.albedo_color = Color(1.0, 0.8, 0.2, 0.4)
	core_material.flags_transparent = true
	core_material.emission_enabled = true
	core_material.emission = Color(1.0, 0.8, 0.2) * joy_level
	joy_core.material_override = core_material
	
	container.add_child(joy_core)

