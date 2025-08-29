extends Node3D
class_name BoidsAlgorithmSystem

var time: float = 0.0
var swarm_progress: float = 0.0
var cohesion_strength: float = 0.0
var efficiency_score: float = 0.0
var boid_count: int = 30
var ant_count: int = 15
var boids: Array = []
var ants: Array = []
var pheromone_trails: Array = []
var flocks: Array = []

# Boids parameters
var separation_radius: float = 1.0
var alignment_radius: float = 1.5
var cohesion_radius: float = 2.0
var max_speed: float = 2.0
var max_force: float = 0.1

func _ready():
	# Initialize Swarm Intelligence visualization
	print("Boids Algorithm Visualization initialized")
	create_boids()
	create_ants()
	create_pheromone_trails()
	create_flocks()
	setup_swarm_metrics()

func _process(delta):
	time += delta
	
	# Simulate swarm progress
	swarm_progress = min(1.0, time * 0.1)
	cohesion_strength = swarm_progress * 0.85
	efficiency_score = swarm_progress * 0.9
	
	update_boids(delta)
	animate_behavior_engine(delta)
	animate_ant_colony(delta)
	animate_flocks(delta)
	update_swarm_metrics(delta)

func create_boids():
	# Create boid agents
	var boids_node = $SwarmSpace/Boids
	for i in range(boid_count):
		var boid = CSGCylinder3D.new()
		boid.radius = 0.05
		
		boid.height = 0.3
		boid.material_override = StandardMaterial3D.new()
		
		# Different colors for different boid types
		var boid_type = i % 3
		match boid_type:
			0:  # Leaders
				boid.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
			1:  # Followers
				boid.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
			2:  # Scouts
				boid.material_override.albedo_color = Color(0.2, 0.2, 0.8, 1)
		
		boid.material_override.emission_enabled = true
		boid.material_override.emission = boid.material_override.albedo_color * 0.3
		
		# Random initial position and velocity
		var pos = Vector3(
			randf_range(-5, 5),
			randf_range(-3, 3),
			randf_range(-5, 5)
		)
		var vel = Vector3(
			randf_range(-1, 1),
			randf_range(-0.5, 0.5),
			randf_range(-1, 1)
		).normalized() * randf_range(0.5, 1.5)
		
		boid.position = pos
		
		boids_node.add_child(boid)
		boids.append({
			"boid": boid,
			"position": pos,
			"velocity": vel,
			"acceleration": Vector3.ZERO,
			"type": boid_type,
			"flock_id": i / 10  # Group into flocks
		})

func create_ants():
	# Create ant agents for ACO
	var ants_node = $AntColonyOptimization/Ants
	for i in range(ant_count):
		var ant = CSGSphere3D.new()
		ant.radius = 0.08
		ant.material_override = StandardMaterial3D.new()
		ant.material_override.albedo_color = Color(0.6, 0.3, 0.1, 1)
		ant.material_override.emission_enabled = true
		ant.material_override.emission = Color(0.6, 0.3, 0.1, 1) * 0.3
		
		# Position ants in colony area
		var angle = float(i) / ant_count * PI * 2
		var radius = 2.0 + randf() * 1.0
		var pos = Vector3(
			cos(angle) * radius,
			randf_range(-0.5, 0.5),
			sin(angle) * radius
		)
		ant.position = pos
		
		ants_node.add_child(ant)
		ants.append({
			"ant": ant,
			"position": pos,
			"velocity": Vector3.ZERO,
			"target": Vector3.ZERO,
			"pheromone_strength": 1.0
		})

func create_pheromone_trails():
	# Create pheromone trail indicators
	var trails_node = $AntColonyOptimization/PheromoneTrails
	for i in range(20):
		var trail = CSGSphere3D.new()
		trail.radius = 0.05
		trail.material_override = StandardMaterial3D.new()
		trail.material_override.albedo_color = Color(0.8, 0.8, 0.2, 0.6)
		trail.material_override.emission_enabled = true
		trail.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.2
		trail.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Random trail positions
		var pos = Vector3(
			randf_range(-3, 3),
			randf_range(-1, 1),
			randf_range(-3, 3)
		)
		trail.position = pos
		
		trails_node.add_child(trail)
		pheromone_trails.append({
			"trail": trail,
			"strength": randf(),
			"age": 0.0
		})

func create_flocks():
	# Create flock indicators
	var flocks_node = $SwarmSpace/Flocks
	for i in range(3):
		var flock = CSGSphere3D.new()
		flock.radius = 2.0
		flock.material_override = StandardMaterial3D.new()
		
		match i:
			0:
				flock.material_override.albedo_color = Color(0.8, 0.2, 0.2, 0.2)
			1:
				flock.material_override.albedo_color = Color(0.2, 0.8, 0.2, 0.2)
			2:
				flock.material_override.albedo_color = Color(0.2, 0.2, 0.8, 0.2)
		
		flock.material_override.emission_enabled = true
		flock.material_override.emission = flock.material_override.albedo_color * 0.5
		flock.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Position flocks in different areas
		var angle = float(i) / 3.0 * PI * 2
		var radius = 3.0
		var pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		flock.position = pos
		
		flocks_node.add_child(flock)
		flocks.append({
			"indicator": flock,
			"center": pos,
			"members": []
		})

func setup_swarm_metrics():
	# Initialize swarm metrics
	var cohesion_indicator = $SwarmMetrics/CohesionMeter/CohesionIndicator
	var efficiency_indicator = $SwarmMetrics/EfficiencyMeter/EfficiencyIndicator
	if cohesion_indicator:
		cohesion_indicator.position.x = 0  # Start at middle
	if efficiency_indicator:
		efficiency_indicator.position.x = 0  # Start at middle

func update_boids(delta):
	# Apply boids rules to each boid
	for i in range(boids.size()):
		var boid_data = boids[i]
		var boid = boid_data["boid"]
		
		if boid:
			# Calculate steering forces
			var separation = calculate_separation(i)
			var alignment = calculate_alignment(i)
			var cohesion = calculate_cohesion(i)
			
			# Weight the forces
			separation *= 1.5
			alignment *= 1.0
			cohesion *= 1.0
			
			# Apply forces
			boid_data["acceleration"] = separation + alignment + cohesion
			boid_data["velocity"] += boid_data["acceleration"] * delta
			
			# Limit speed
			if boid_data["velocity"].length() > max_speed:
				boid_data["velocity"] = boid_data["velocity"].normalized() * max_speed
			
			# Update position
			boid_data["position"] += boid_data["velocity"] * delta
			boid.position = boid_data["position"]
			
			# Orient boid in direction of movement
			if boid_data["velocity"].length() > 0.1:
				boid.look_at(boid_data["position"] + boid_data["velocity"], Vector3.UP)
			
			# Wrap around boundaries
			wrap_position(boid_data)
			
			# Pulse based on swarm activity
			var pulse = 1.0 + sin(time * 3.0 + i * 0.2) * 0.2 * swarm_progress
			boid.scale = Vector3.ONE * pulse
			
			# Reset acceleration
			boid_data["acceleration"] = Vector3.ZERO

func calculate_separation(boid_index: int) -> Vector3:
	var boid_data = boids[boid_index]
	var steer = Vector3.ZERO
	var count = 0
	
	for i in range(boids.size()):
		if i != boid_index:
			var other = boids[i]
			var distance = boid_data["position"].distance_to(other["position"])
			
			if distance > 0 and distance < separation_radius:
				var diff = boid_data["position"] - other["position"]
				diff = diff.normalized() / distance  # Weight by distance
				steer += diff
				count += 1
	
	if count > 0:
		steer = steer / count
		steer = steer.normalized() * max_speed
		steer -= boid_data["velocity"]
		if steer.length() > max_force:
			steer = steer.normalized() * max_force
	
	return steer

func calculate_alignment(boid_index: int) -> Vector3:
	var boid_data = boids[boid_index]
	var sum_velocity = Vector3.ZERO
	var count = 0
	
	for i in range(boids.size()):
		if i != boid_index:
			var other = boids[i]
			var distance = boid_data["position"].distance_to(other["position"])
			
			if distance > 0 and distance < alignment_radius:
				sum_velocity += other["velocity"]
				count += 1
	
	if count > 0:
		sum_velocity = sum_velocity / count
		sum_velocity = sum_velocity.normalized() * max_speed
		var steer = sum_velocity - boid_data["velocity"]
		if steer.length() > max_force:
			steer = steer.normalized() * max_force
		return steer
	
	return Vector3.ZERO

func calculate_cohesion(boid_index: int) -> Vector3:
	var boid_data = boids[boid_index]
	var sum_position = Vector3.ZERO
	var count = 0
	
	for i in range(boids.size()):
		if i != boid_index:
			var other = boids[i]
			var distance = boid_data["position"].distance_to(other["position"])
			
			if distance > 0 and distance < cohesion_radius:
				sum_position += other["position"]
				count += 1
	
	if count > 0:
		sum_position = sum_position / count
		var desired = sum_position - boid_data["position"]
		desired = desired.normalized() * max_speed
		var steer = desired - boid_data["velocity"]
		if steer.length() > max_force:
			steer = steer.normalized() * max_force
		return steer
	
	return Vector3.ZERO

func wrap_position(boid_data: Dictionary):
	var boundary = 8.0
	if boid_data["position"].x > boundary:
		boid_data["position"].x = -boundary
	elif boid_data["position"].x < -boundary:
		boid_data["position"].x = boundary
	
	if boid_data["position"].z > boundary:
		boid_data["position"].z = -boundary
	elif boid_data["position"].z < -boundary:
		boid_data["position"].z = boundary
	
	if boid_data["position"].y > 5:
		boid_data["position"].y = -5
	elif boid_data["position"].y < -5:
		boid_data["position"].y = 5

func animate_behavior_engine(delta):
	# Animate behavior engine core
	var engine_core = $BehaviorEngine/EngineCore
	if engine_core:
		# Rotate engine
		engine_core.rotation.y += delta * 0.5
		
		# Pulse based on swarm progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * swarm_progress
		engine_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on swarm activity
		if engine_core.material_override:
			var intensity = 0.3 + swarm_progress * 0.7
			engine_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate behavior rule cores
	var separation_core = $BehaviorEngine/BehaviorRules/SeparationCore
	if separation_core:
		separation_core.rotation.y += delta * 0.8
		var separation_activation = sin(time * 1.5) * 0.5 + 0.5
		separation_activation *= swarm_progress
		
		var pulse = 1.0 + separation_activation * 0.3
		separation_core.scale = Vector3.ONE * pulse
		
		if separation_core.material_override:
			var intensity = 0.3 + separation_activation * 0.7
			separation_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var alignment_core = $BehaviorEngine/BehaviorRules/AlignmentCore
	if alignment_core:
		alignment_core.rotation.y += delta * 1.0
		var alignment_activation = cos(time * 1.8) * 0.5 + 0.5
		alignment_activation *= swarm_progress
		
		var pulse = 1.0 + alignment_activation * 0.3
		alignment_core.scale = Vector3.ONE * pulse
		
		if alignment_core.material_override:
			var intensity = 0.3 + alignment_activation * 0.7
			alignment_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var cohesion_core = $BehaviorEngine/BehaviorRules/CohesionCore
	if cohesion_core:
		cohesion_core.rotation.y += delta * 1.2
		var cohesion_activation = sin(time * 2.0) * 0.5 + 0.5
		cohesion_activation *= swarm_progress
		
		var pulse = 1.0 + cohesion_activation * 0.3
		cohesion_core.scale = Vector3.ONE * pulse
		
		if cohesion_core.material_override:
			var intensity = 0.3 + cohesion_activation * 0.7
			cohesion_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_ant_colony(delta):
	# Animate ant colony core
	var colony_core = $AntColonyOptimization/ColonyCore
	if colony_core:
		# Rotate colony
		colony_core.rotation.y += delta * 0.3
		
		# Pulse based on swarm progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * swarm_progress
		colony_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity
		if colony_core.material_override:
			var intensity = 0.3 + swarm_progress * 0.7
			colony_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate ants
	for i in range(ants.size()):
		var ant_data = ants[i]
		var ant = ant_data["ant"]
		
		if ant:
			# Move ants in foraging patterns
			var foraging_angle = time * 0.5 + i * 0.4
			var foraging_radius = 1.5 + sin(time * 0.8 + i * 0.3) * 0.5
			var target_x = cos(foraging_angle) * foraging_radius
			var target_z = sin(foraging_angle) * foraging_radius
			var target_pos = Vector3(target_x, 0, target_z)
			
			ant_data["position"] = lerp(ant_data["position"], target_pos, delta * 1.0)
			ant.position = ant_data["position"]
			
			# Pulse ants based on activity
			var pulse = 1.0 + sin(time * 2.5 + i * 0.4) * 0.3 * swarm_progress
			ant.scale = Vector3.ONE * pulse
	
	# Animate pheromone trails
	for i in range(pheromone_trails.size()):
		var trail_data = pheromone_trails[i]
		var trail = trail_data["trail"]
		
		if trail:
			# Age and fade pheromone trails
			trail_data["age"] += delta
			var fade = max(0.0, 1.0 - trail_data["age"] * 0.2)
			trail_data["strength"] = fade
			
			# Reset trail if completely faded
			if fade <= 0.0:
				trail_data["age"] = 0.0
				trail_data["strength"] = randf()
			
			# Update trail appearance
			var alpha = 0.3 + trail_data["strength"] * 0.5
			trail.material_override.albedo_color = Color(0.8, 0.8, 0.2, alpha)
			
			var pulse = 1.0 + trail_data["strength"] * 0.5
			trail.scale = Vector3.ONE * pulse

func animate_flocks(delta):
	# Update flock centers and animate indicators
	for i in range(flocks.size()):
		var flock = flocks[i]
		var flock_indicator = flock["indicator"]
		
		if flock_indicator:
			# Calculate flock center based on nearby boids
			var flock_center = Vector3.ZERO
			var member_count = 0
			
			for boid_data in boids:
				if boid_data["flock_id"] == i:
					flock_center += boid_data["position"]
					member_count += 1
			
			if member_count > 0:
				flock_center = flock_center / member_count
				flock["center"] = lerp(flock["center"], flock_center, delta * 1.0)
				flock_indicator.position = flock["center"]
			
			# Pulse flock indicator based on cohesion
			var cohesion_level = sin(time * 1.0 + i * 0.7) * 0.5 + 0.5
			cohesion_level *= swarm_progress
			
			var pulse = 1.0 + cohesion_level * 0.3
			flock_indicator.scale = Vector3.ONE * pulse
			
			# Update transparency based on flock strength
			var alpha = 0.2 + cohesion_level * 0.3
			var color = flock_indicator.material_override.albedo_color
			color.a = alpha
			flock_indicator.material_override.albedo_color = color

func update_swarm_metrics(delta):
	# Update cohesion strength meter
	var cohesion_indicator = $SwarmMetrics/CohesionMeter/CohesionIndicator
	if cohesion_indicator:
		var target_x = lerp(-2, 2, cohesion_strength)
		cohesion_indicator.position.x = lerp(cohesion_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on cohesion
		var green_component = 0.8 * cohesion_strength
		var red_component = 0.2 + 0.6 * (1.0 - cohesion_strength)
		cohesion_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update efficiency score meter
	var efficiency_indicator = $SwarmMetrics/EfficiencyMeter/EfficiencyIndicator
	if efficiency_indicator:
		var target_x = lerp(-2, 2, efficiency_score)
		efficiency_indicator.position.x = lerp(efficiency_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on efficiency
		var green_component = 0.8 * efficiency_score
		var red_component = 0.2 + 0.6 * (1.0 - efficiency_score)
		efficiency_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_swarm_progress(progress: float):
	swarm_progress = clamp(progress, 0.0, 1.0)

func set_cohesion_strength(cohesion: float):
	cohesion_strength = clamp(cohesion, 0.0, 1.0)

func set_efficiency_score(efficiency: float):
	efficiency_score = clamp(efficiency, 0.0, 1.0)

func get_swarm_progress() -> float:
	return swarm_progress

func get_cohesion_strength() -> float:
	return cohesion_strength

func get_efficiency_score() -> float:
	return efficiency_score

func reset_swarm():
	time = 0.0
	swarm_progress = 0.0
	cohesion_strength = 0.0
	efficiency_score = 0.0
