extends Node3D
class_name ReinforcementLearning

var time: float = 0.0
var learning_progress: float = 0.0
var reward_score: float = 0.0
var episode_count: float = 0.0
var particle_count: int = 25
var flow_particles: Array = []
var environment_particles: Array = []
var agent_particles: Array = []

func _ready():
	# Initialize Reinforcement Learning visualization
	print("Reinforcement Learning Visualization initialized")
	create_environment_particles()
	create_agent_particles()
	create_flow_particles()
	setup_learning_metrics()

func _process(delta):
	time += delta
	
	# Simulate learning progress
	learning_progress = min(1.0, time * 0.1)
	reward_score = learning_progress * 0.9
	episode_count = learning_progress * 0.8
	
	animate_environment(delta)
	animate_agent(delta)
	animate_learning_algorithm(delta)
	animate_reward_system(delta)
	animate_data_flow(delta)
	update_learning_metrics(delta)

func create_environment_particles():
	# Create environment grid particles
	var environment_grid = $Environment/EnvironmentGrid
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		# Position particles in a grid pattern
		var grid_size = 5
		var x = (i % grid_size - grid_size/2) * 0.8
		var z = (i / grid_size - grid_size/2) * 0.8
		var y = randf_range(-0.5, 0.5)
		particle.position = Vector3(x, y, z)
		
		environment_grid.add_child(particle)
		environment_particles.append(particle)

func create_agent_particles():
	# Create agent particles
	var agent_core = $Agent/AgentCore
	for i in range(15):
		var particle = CSGSphere3D.new()
		particle.radius = 0.06
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position particles around agent
		var angle = randf() * PI * 2
		var radius = randf_range(0.8, 1.5)
		var x = cos(angle) * radius
		var y = randf_range(-0.8, 0.8)
		var z = sin(angle) * radius
		particle.position = Vector3(x, y, z)
		
		agent_core.add_child(particle)
		agent_particles.append(particle)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(30):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the learning flow path
		var progress = float(i) / 30
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 4) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_learning_metrics():
	# Initialize learning metrics
	var reward_indicator = $LearningMetrics/RewardMeter/RewardIndicator
	var episode_indicator = $LearningMetrics/EpisodeMeter/EpisodeIndicator
	if reward_indicator:
		reward_indicator.position.x = 0  # Start at middle
	if episode_indicator:
		episode_indicator.position.x = 0  # Start at middle

func animate_environment(delta):
	# Animate environment particles
	for i in range(environment_particles.size()):
		var particle = environment_particles[i]
		if particle:
			# Move particles in a flowing grid pattern
			var base_pos = particle.position
			var move_x = base_pos.x + sin(time * 0.6 + i * 0.1) * 0.1
			var move_y = base_pos.y + cos(time * 0.8 + i * 0.15) * 0.1
			var move_z = base_pos.z + sin(time * 1.0 + i * 0.12) * 0.1
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on learning progress
			var pulse = 1.0 + sin(time * 1.8 + i * 0.2) * 0.2 * learning_progress
			particle.scale = Vector3.ONE * pulse

func animate_agent(delta):
	# Animate agent core
	var agent_core = $Agent/AgentCore
	if agent_core:
		# Rotate agent
		agent_core.rotation.y += delta * 0.6
		
		# Pulse based on learning progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * learning_progress
		agent_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on learning
		if agent_core.material_override:
			var intensity = 0.3 + learning_progress * 0.7
			agent_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate agent particles
	for i in range(agent_particles.size()):
		var particle = agent_particles[i]
		if particle:
			# Move particles in an exploration pattern
			var base_pos = particle.position
			var move_x = base_pos.x + sin(time * 1.2 + i * 0.2) * 0.3
			var move_y = base_pos.y + cos(time * 1.5 + i * 0.25) * 0.3
			var move_z = base_pos.z + sin(time * 1.8 + i * 0.3) * 0.3
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.5)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.5)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.5)
			
			# Pulse particles based on learning progress
			var pulse = 1.0 + sin(time * 2.2 + i * 0.3) * 0.3 * learning_progress
			particle.scale = Vector3.ONE * pulse

func animate_learning_algorithm(delta):
	# Animate learning algorithm core
	var algorithm_core = $LearningAlgorithm/AlgorithmCore
	if algorithm_core:
		# Rotate algorithm
		algorithm_core.rotation.y += delta * 0.5
		
		# Pulse based on learning progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * learning_progress
		algorithm_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on learning
		if algorithm_core.material_override:
			var intensity = 0.3 + learning_progress * 0.7
			algorithm_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate policy network cores
	var policy_core = $LearningAlgorithm/PolicyNetwork/PolicyCore
	if policy_core:
		policy_core.rotation.y += delta * 0.8
		var policy_activation = sin(time * 1.5) * 0.5 + 0.5
		policy_activation *= learning_progress
		
		var pulse = 1.0 + policy_activation * 0.3
		policy_core.scale = Vector3.ONE * pulse
		
		if policy_core.material_override:
			var intensity = 0.3 + policy_activation * 0.7
			policy_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var value_core = $LearningAlgorithm/PolicyNetwork/ValueCore
	if value_core:
		value_core.rotation.y += delta * 1.0
		var value_activation = cos(time * 1.8) * 0.5 + 0.5
		value_activation *= learning_progress
		
		var pulse = 1.0 + value_activation * 0.3
		value_core.scale = Vector3.ONE * pulse
		
		if value_core.material_override:
			var intensity = 0.3 + value_activation * 0.7
			value_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var qnetwork_core = $LearningAlgorithm/PolicyNetwork/QNetworkCore
	if qnetwork_core:
		qnetwork_core.rotation.y += delta * 1.2
		var qnetwork_activation = sin(time * 2.0) * 0.5 + 0.5
		qnetwork_activation *= learning_progress
		
		var pulse = 1.0 + qnetwork_activation * 0.3
		qnetwork_core.scale = Vector3.ONE * pulse
		
		if qnetwork_core.material_override:
			var intensity = 0.3 + qnetwork_activation * 0.7
			qnetwork_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_reward_system(delta):
	# Animate reward system core
	var reward_core = $RewardSystem/RewardCore
	if reward_core:
		# Rotate reward system
		reward_core.rotation.y += delta * 0.4
		
		# Pulse based on learning progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * learning_progress
		reward_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on learning
		if reward_core.material_override:
			var intensity = 0.3 + learning_progress * 0.7
			reward_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the learning flow
			var progress = (time * 0.25 + float(i) * 0.1) % 1.0
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 4) * 2
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and learning progress
			var color_progress = (progress + 0.5) % 1.0
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on learning
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * learning_progress
			particle.scale = Vector3.ONE * pulse

func update_learning_metrics(delta):
	# Update reward meter
	var reward_indicator = $LearningMetrics/RewardMeter/RewardIndicator
	if reward_indicator:
		var target_x = lerp(-2, 2, reward_score)
		reward_indicator.position.x = lerp(reward_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on reward
		var green_component = 0.8 * reward_score
		var red_component = 0.2 + 0.6 * (1.0 - reward_score)
		reward_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update episode meter
	var episode_indicator = $LearningMetrics/EpisodeMeter/EpisodeIndicator
	if episode_indicator:
		var target_x = lerp(-2, 2, episode_count)
		episode_indicator.position.x = lerp(episode_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on episode count
		var green_component = 0.8 * episode_count
		var red_component = 0.2 + 0.6 * (1.0 - episode_count)
		episode_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_learning_progress(progress: float):
	learning_progress = clamp(progress, 0.0, 1.0)

func set_reward_score(reward: float):
	reward_score = clamp(reward, 0.0, 1.0)

func set_episode_count(episodes: float):
	episode_count = clamp(episodes, 0.0, 1.0)

func get_learning_progress() -> float:
	return learning_progress

func get_reward_score() -> float:
	return reward_score

func get_episode_count() -> float:
	return episode_count

func reset_learning():
	time = 0.0
	learning_progress = 0.0
	reward_score = 0.0
	episode_count = 0.0
