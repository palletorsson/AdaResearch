extends Node3D

# Affect Theory Visualization
# Emotional response to digital touch and affective transmission

var time := 0.0
var affect_timer := 0.0

# Affect theory concepts
var emotional_bodies := []
var affective_flows := []
var intensity_levels := {}
var touch_responses := []

# Emotional states based on affect theory
var affects = [
	{"name": "joy", "intensity": 0.5, "transmission": 0.8, "color": Color(1.0, 0.8, 0.2)},
	{"name": "fear", "intensity": 0.3, "transmission": 0.6, "color": Color(0.8, 0.2, 0.8)},
	{"name": "anger", "intensity": 0.7, "transmission": 0.9, "color": Color(1.0, 0.2, 0.2)},
	{"name": "sadness", "intensity": 0.4, "transmission": 0.3, "color": Color(0.2, 0.4, 0.8)},
	{"name": "surprise", "intensity": 0.9, "transmission": 0.7, "color": Color(0.9, 0.9, 0.2)},
	{"name": "disgust", "intensity": 0.6, "transmission": 0.4, "color": Color(0.4, 0.8, 0.2)}
]

class EmotionalBody:
	var position: Vector3
	var velocity: Vector3
	var current_affect: Dictionary
	var affect_history: Array
	var responsiveness: float
	var boundary_permeability: float
	var size: float

class AffectiveFlow:
	var source: Vector3
	var target: Vector3
	var intensity: float
	var affect_type: String
	var flow_speed: float
	var particles: Array

class TouchResponse:
	var position: Vector3
	var affect_type: String
	var intensity: float
	var ripple_radius: float
	var age: float

func _ready():
	initialize_emotional_bodies()
	initialize_affective_system()

func _process(delta):
	time += delta
	affect_timer += delta
	
	update_emotional_states()
	simulate_emotional_bodies()
	visualize_affective_transmission()
	demonstrate_intensity_flows()
	show_digital_touch_responses()

func initialize_emotional_bodies():
	# Create emotional bodies with different affective capacities
	for i in range(6):
		var body = EmotionalBody.new()
		body.position = Vector3(
			randf_range(-3, 3),
			randf_range(1, 5),
			randf_range(-3, 3)
		)
		body.velocity = Vector3.ZERO
		body.current_affect = affects[i % affects.size()].duplicate()
		body.affect_history = []
		body.responsiveness = randf_range(0.3, 1.0)
		body.boundary_permeability = randf_range(0.4, 0.9)
		body.size = randf_range(0.8, 1.5)
		
		emotional_bodies.append(body)

func initialize_affective_system():
	# Initialize intensity tracking for different affects
	for affect in affects:
		intensity_levels[affect.name] = {"current": affect.intensity, "target": affect.intensity}

func update_emotional_states():
	# Update affect intensities over time
	for affect_name in intensity_levels:
		var level = intensity_levels[affect_name]
		
		# Add some temporal variation
		level.target = clamp(
			level.target + sin(time * 0.5 + affects.find(func(a): return a.name == affect_name)) * 0.1,
			0.0, 1.0
		)
		
		# Smooth interpolation towards target
		level.current = lerp(level.current, level.target, 0.1)

func simulate_emotional_bodies():
	var container = $EmotionalBodies
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	for i in range(emotional_bodies.size()):
		var body = emotional_bodies[i]
		
		# Update emotional state based on proximity to other bodies
		update_affective_influence(body, i)
		
		# Apply soft body physics with emotional modulation
		apply_emotional_physics(body)
		
		# Visualize emotional body
		create_emotional_body_visualization(container, body, i)

func update_affective_influence(body: EmotionalBody, body_index: int):
	# Affect transmission between bodies
	for j in range(emotional_bodies.size()):
		if j == body_index:
			continue
		
		var other_body = emotional_bodies[j]
		var distance = body.position.distance_to(other_body.position)
		
		if distance < 4.0:
			# Calculate affective influence
			var influence_strength = (4.0 - distance) / 4.0
			influence_strength *= other_body.current_affect.transmission
			influence_strength *= body.boundary_permeability
			
			# Transmit affect
			var intensity_change = influence_strength * 0.1
			body.current_affect.intensity = lerp(
				body.current_affect.intensity,
				other_body.current_affect.intensity,
				intensity_change
			)
			
			# Create affective flow
			if randf() < 0.05:
				create_affective_flow(other_body.position, body.position, other_body.current_affect.name)

func apply_emotional_physics(body: EmotionalBody):
	# Emotional state affects physical behavior
	var emotional_force = Vector3.ZERO
	
	# Different affects create different movement patterns
	match body.current_affect.name:
		"joy":
			emotional_force += Vector3(0, sin(time * 3) * 2.0, 0)  # Bouncy movement
		"fear":
			emotional_force += Vector3(
				cos(time * 5) * 1.5,
				0,
				sin(time * 5) * 1.5
			)  # Erratic movement
		"anger":
			emotional_force += Vector3(
				sin(time * 2) * 3.0,
				0,
				cos(time * 2) * 3.0
			)  # Aggressive movement
		"sadness":
			emotional_force += Vector3(0, -1.0, 0)  # Downward tendency
		"surprise":
			if fmod(time, 3.0) < 0.1:
				emotional_force += Vector3(
					randf_range(-5, 5),
					randf_range(0, 5),
					randf_range(-5, 5)
				)  # Sudden bursts
		"disgust":
			# Avoidance behavior - move away from others
			for other_body in emotional_bodies:
				if other_body != body:
					var distance_vec = body.position - other_body.position
					var distance = distance_vec.length()
					if distance < 3.0:
						emotional_force += distance_vec.normalized() * (3.0 - distance)
	
	# Apply emotional modulation
	emotional_force *= body.current_affect.intensity * body.responsiveness
	
	# Update physics
	body.velocity += emotional_force * get_process_delta_time() * 0.1
	body.velocity *= 0.95  # Damping
	body.position += body.velocity * get_process_delta_time()
	
	# Boundary constraints
	body.position.x = clamp(body.position.x, -5, 5)
	body.position.y = clamp(body.position.y, 0.5, 8)
	body.position.z = clamp(body.position.z, -5, 5)

func create_affective_flow(source: Vector3, target: Vector3, affect_type: String):
	var flow = AffectiveFlow.new()
	flow.source = source
	flow.target = target
	flow.affect_type = affect_type
	flow.intensity = randf_range(0.3, 1.0)
	flow.flow_speed = randf_range(1.0, 3.0)
	flow.particles = []
	
	# Create flow particles
	for i in range(8):
		flow.particles.append({
			"position": source,
			"progress": float(i) / 8.0,
			"size": randf_range(0.1, 0.3)
		})
	
	affective_flows.append(flow)

func create_emotional_body_visualization(container: Node3D, body: EmotionalBody, index: int):
	# Create soft, deformable emotional body
	var body_sphere = CSGSphere3D.new()
	
	# Size affected by emotional intensity
	var size_modulation = 1.0 + body.current_affect.intensity * 0.5
	body_sphere.radius = body.size * size_modulation
	body_sphere.position = body.position
	
	# Apply emotional deformation
	var deformation = get_emotional_deformation(body.current_affect.name, index)
	body_sphere.scale = deformation
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(
		body.current_affect.color.r,
		body.current_affect.color.g,
		body.current_affect.color.b,
		0.7
	)
	material.flags_transparent = true
	material.emission_enabled = true
	material.emission = body.current_affect.color * body.current_affect.intensity * 0.6
	material.metallic = 0.1
	material.roughness = 0.8
	body_sphere.material_override = material
	
	container.add_child(body_sphere)
	
	# Add affect label (small indicator)
	var affect_indicator = CSGBox3D.new()
	affect_indicator.size = Vector3(0.2, 0.2, 0.2)
	affect_indicator.position = body.position + Vector3(0, body.size + 0.5, 0)
	
	var indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = body.current_affect.color
	indicator_material.emission_enabled = true
	indicator_material.emission = body.current_affect.color * 0.8
	affect_indicator.material_override = indicator_material
	
	container.add_child(affect_indicator)

func get_emotional_deformation(affect_name: String, index: int) -> Vector3:
	# Different affects create different body deformations
	var base_scale = Vector3.ONE
	
	match affect_name:
		"joy":
			return base_scale + Vector3(
				sin(time * 4 + index) * 0.2,
				cos(time * 3 + index) * 0.3,
				sin(time * 5 + index) * 0.2
			)
		"fear":
			return base_scale + Vector3(
				sin(time * 8 + index) * 0.4,
				sin(time * 10 + index) * 0.3,
				sin(time * 6 + index) * 0.4
			)
		"anger":
			return base_scale + Vector3(
				1.0 + sin(time * 2 + index) * 0.5,
				0.8,
				1.0 + cos(time * 2 + index) * 0.5
			)
		"sadness":
			return Vector3(1.2, 0.6 + sin(time * 1 + index) * 0.2, 1.2)
		"surprise":
			var burst_factor = 1.0
			if fmod(time + index, 2.0) < 0.2:
				burst_factor = 1.5
			return base_scale * burst_factor
		"disgust":
			return Vector3(
				0.8 + sin(time * 3 + index) * 0.1,
				1.0,
				0.8 + cos(time * 3 + index) * 0.1
			)
		_:
			return base_scale

func visualize_affective_transmission():
	var container = $AffectiveTransmission
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update and visualize affective flows
	var i = 0
	while i < affective_flows.size():
		var flow = affective_flows[i]
		
		# Update flow particles
		var all_particles_reached = true
		for particle in flow.particles:
			particle.progress += flow.flow_speed * get_process_delta_time() * 0.5
			if particle.progress < 1.0:
				all_particles_reached = false
			
			particle.position = flow.source.lerp(flow.target, particle.progress)
			
			# Visualize particle
			if particle.progress < 1.0:
				var particle_sphere = CSGSphere3D.new()
				particle_sphere.radius = particle.size
				particle_sphere.position = particle.position
				
				var affect_data = affects.filter(func(a): return a.name == flow.affect_type)[0]
				var material = StandardMaterial3D.new()
				material.albedo_color = affect_data.color
				material.emission_enabled = true
				material.emission = affect_data.color * flow.intensity
				particle_sphere.material_override = material
				
				container.add_child(particle_sphere)
		
		# Remove completed flows
		if all_particles_reached:
			affective_flows.remove_at(i)
		else:
			i += 1

func demonstrate_intensity_flows():
	var container = $IntensityFlows
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create intensity field visualization
	var grid_size = 10
	for i in range(grid_size):
		for j in range(grid_size):
			var pos = Vector3(
				i - grid_size * 0.5,
				0,
				j - grid_size * 0.5
			)
			
			# Calculate combined intensity at this position
			var total_intensity = 0.0
			var dominant_affect = affects[0]
			
			for body in emotional_bodies:
				var distance = pos.distance_to(Vector3(body.position.x, 0, body.position.z))
				var influence = body.current_affect.intensity / (distance + 1.0)
				
				if influence > total_intensity:
					total_intensity = influence
					dominant_affect = body.current_affect
			
			total_intensity = clamp(total_intensity, 0.0, 1.0)
			
			if total_intensity > 0.1:
				var intensity_pillar = CSGBox3D.new()
				intensity_pillar.size = Vector3(0.4, total_intensity * 4.0, 0.4)
				intensity_pillar.position = pos + Vector3(0, intensity_pillar.size.y * 0.5, 0)
				
				var material = StandardMaterial3D.new()
				material.albedo_color = Color(
					dominant_affect.color.r,
					dominant_affect.color.g,
					dominant_affect.color.b,
					0.6
				)
				material.flags_transparent = true
				material.emission_enabled = true
				material.emission = dominant_affect.color * total_intensity * 0.4
				intensity_pillar.material_override = material
				
				container.add_child(intensity_pillar)

func show_digital_touch_responses():
	var container = $DigitalTouch
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Generate touch events
	if affect_timer > 0.5:
		affect_timer = 0.0
		create_touch_response()
	
	# Update and visualize touch responses
	var i = 0
	while i < touch_responses.size():
		var response = touch_responses[i]
		response.age += get_process_delta_time()
		response.ripple_radius += 2.0 * get_process_delta_time()
		
		if response.age > 3.0:
			touch_responses.remove_at(i)
			continue
		
		# Create ripple effect
		var ripple = CSGCylinder3D.new()
		ripple.top_radius = response.ripple_radius + 0.3
		ripple.bottom_radius = response.ripple_radius
		ripple.height = 0.1
		ripple.position = response.position
		
		var affect_data = affects.filter(func(a): return a.name == response.affect_type)[0]
		var material = StandardMaterial3D.new()
		var alpha = (1.0 - response.age / 3.0) * response.intensity
		material.albedo_color = Color(
			affect_data.color.r,
			affect_data.color.g,
			affect_data.color.b,
			alpha * 0.4
		)
		material.flags_transparent = true
		material.emission_enabled = true
		material.emission = affect_data.color * alpha * 0.6
		ripple.material_override = material
		
		container.add_child(ripple)
		
		# Create haptic feedback visualization
		var haptic_sphere = CSGSphere3D.new()
		haptic_sphere.radius = 0.3 * response.intensity * (1.0 - response.age / 3.0)
		haptic_sphere.position = response.position + Vector3(0, sin(response.age * 5) * 0.5, 0)
		
		var haptic_material = StandardMaterial3D.new()
		haptic_material.albedo_color = affect_data.color
		haptic_material.emission_enabled = true
		haptic_material.emission = affect_data.color * alpha
		haptic_sphere.material_override = haptic_material
		
		container.add_child(haptic_sphere)
		
		i += 1

func create_touch_response():
	var response = TouchResponse.new()
	response.position = Vector3(
		randf_range(-4, 4),
		1,
		randf_range(-4, 4)
	)
	response.affect_type = affects[randi() % affects.size()].name
	response.intensity = randf_range(0.3, 1.0)
	response.ripple_radius = 0.1
	response.age = 0.0
	
	touch_responses.append(response)
	
	# Influence nearby emotional bodies
	for body in emotional_bodies:
		var distance = response.position.distance_to(body.position)
		if distance < 2.0:
			var influence = (2.0 - distance) / 2.0 * response.intensity
			body.current_affect.intensity = clamp(
				body.current_affect.intensity + influence * 0.2,
				0.0, 1.0
			)

