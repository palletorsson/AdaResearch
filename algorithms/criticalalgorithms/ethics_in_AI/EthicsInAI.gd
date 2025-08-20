extends Node3D
class_name EthicsInAI

var time: float = 0.0
var trust_score: float = 1.0
var ethics_score: float = 1.0
var transparency_level: float = 0.0
var accountability_level: float = 0.0
var particle_count: int = 20

func _ready():
	# Initialize ethics in AI visualization
	print("Ethics in AI Visualization initialized")
	create_ethical_dilemmas()
	create_data_flow()
	setup_trust_metrics()

func _process(delta):
	time += delta
	
	# Simulate ethical dynamics
	transparency_level = min(1.0, time * 0.1)
	accountability_level = min(1.0, time * 0.12)
	
	# Trust and ethics scores based on transparency and accountability
	trust_score = max(0.1, 1.0 - (1.0 - transparency_level) * 0.6)
	ethics_score = max(0.1, 1.0 - (1.0 - accountability_level) * 0.7)
	
	animate_ai_system(delta)
	animate_ethical_framework(delta)
	animate_human_values(delta)
	animate_decision_process(delta)
	animate_ethical_dilemmas(delta)
	animate_data_flow(delta)
	update_trust_metrics(delta)

func create_ethical_dilemmas():
	# Create ethical dilemma spheres
	var dilemma_spheres = $EthicalDilemmas/DilemmaSpheres
	for i in range(6):
		var sphere = CSGSphere3D.new()
		sphere.radius = 0.15
		sphere.material_override = StandardMaterial3D.new()
		sphere.material_override.albedo_color = Color(0.8, 0.8, 0.2, 0.7)
		sphere.material_override.emission_enabled = true
		sphere.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position spheres in a circle around the decision process
		var angle = float(i) / 6 * PI * 2
		var radius = 6.0
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		sphere.position = Vector3(x, 0, z)
		
		dilemma_spheres.add_child(sphere)

func create_data_flow():
	# Create data flow particles
	var flow_particles = $DataFlow/FlowParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		# Position particles along the ethical decision flow
		var progress = float(i) / particle_count
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 2) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles.add_child(particle)

func setup_trust_metrics():
	# Initialize trust and ethics meters
	var trust_indicator = $TrustMetrics/TrustScore/TrustIndicator
	var ethics_indicator = $TrustMetrics/EthicsScore/EthicsIndicator
	if trust_indicator:
		trust_indicator.position.x = 0  # Start at middle
	if ethics_indicator:
		ethics_indicator.position.x = 0  # Start at middle

func animate_ai_system(delta):
	# Animate AI core
	var ai_core = $AISystem/AICore
	if ai_core:
		# Rotate AI system
		ai_core.rotation.y += delta * 0.3
		
		# Scale based on trust and ethics
		var target_scale = 2.0 + (trust_score + ethics_score) * 0.5
		ai_core.scale = Vector3.ONE * lerp(ai_core.scale.x, target_scale, delta * 2.0)
		
		# Change color based on ethical standing
		if ai_core.material_override:
			var green_component = 0.2 + (trust_score + ethics_score) * 0.4
			var blue_component = 0.2 + (trust_score + ethics_score) * 0.4
			ai_core.material_override.albedo_color = Color(0.2, green_component, blue_component, 1)

func animate_ethical_framework(delta):
	# Animate transparency core
	var transparency_core = $EthicalFramework/TransparencyCore
	if transparency_core:
		transparency_core.rotation.y += delta * 0.8
		transparency_core.scale = Vector3.ONE * (1.0 + sin(time * 2.0) * 0.15)
		
		# Change emission based on transparency level
		if transparency_core.material_override:
			var intensity = 0.3 + transparency_level * 0.7
			transparency_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate accountability core
	var accountability_core = $EthicalFramework/AccountabilityCore
	if accountability_core:
		accountability_core.rotation.y += delta * 1.0
		accountability_core.scale = Vector3.ONE * (1.0 + sin(time * 2.5) * 0.15)
		
		# Change emission based on accountability level
		if accountability_core.material_override:
			var intensity = 0.3 + accountability_level * 0.7
			accountability_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_human_values(delta):
	# Animate values core
	var values_core = $HumanValues/ValuesCore
	if values_core:
		values_core.rotation.y += delta * 0.6
		values_core.scale = Vector3.ONE * (1.0 + sin(time * 1.8) * 0.15)
		
		# Change emission based on human values integration
		if values_core.material_override:
			var intensity = 0.3 + (trust_score + ethics_score) * 0.35
			values_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate human core
	var human_core = $HumanValues/HumanCore
	if human_core:
		human_core.rotation.y += delta * 0.7
		human_core.scale = Vector3.ONE * (1.0 + sin(time * 2.2) * 0.15)
		
		# Change emission based on human-centric approach
		if human_core.material_override:
			var intensity = 0.3 + (trust_score + ethics_score) * 0.35
			human_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_decision_process(delta):
	# Animate decision core
	var decision_core = $DecisionProcess/DecisionCore
	if decision_core:
		# Rotate decision process
		decision_core.rotation.y += delta * 0.4
		
		# Scale based on ethical decision quality
		var decision_quality = (transparency_level + accountability_level) / 2
		var target_scale = 1.0 + decision_quality * 0.5
		decision_core.scale = Vector3.ONE * lerp(decision_core.scale.x, target_scale, delta * 2.0)
		
		# Change color based on decision quality
		if decision_core.material_override:
			var green_component = 0.2 + decision_quality * 0.6
			var blue_component = 0.2 + decision_quality * 0.6
			decision_core.material_override.albedo_color = Color(0.2, green_component, blue_component, 1)

func animate_ethical_dilemmas(delta):
	# Animate dilemma spheres
	var dilemma_spheres = $EthicalDilemmas/DilemmaSpheres
	for i in range(dilemma_spheres.get_child_count()):
		var sphere = dilemma_spheres.get_child(i)
		if sphere:
			# Pulse based on ethical complexity
			var complexity = (transparency_level + accountability_level) / 2
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.3 * complexity
			sphere.scale = Vector3.ONE * pulse
			
			# Move spheres up and down
			var y_offset = sin(time * 1.5 + i * 0.4) * 0.2 * complexity
			sphere.position.y = y_offset
			
			# Change emission intensity
			if sphere.material_override:
				var intensity = 0.3 + complexity * 0.7
				sphere.material_override.emission = Color(0.8, 0.8, 0.2, 1) * intensity

func animate_data_flow(delta):
	# Animate data flow particles
	var flow_particles = $DataFlow/FlowParticles
	for i in range(flow_particles.get_child_count()):
		var particle = flow_particles.get_child(i)
		if particle:
			# Move particles through the ethical decision flow
			var progress = fmod(time * 0.3 + float(i) * 0.1, 1.0)
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 2) * 2
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and ethical standing
			var color_progress = fmod((progress + 0.5), 1.0)
			var green_component = 0.8 * (1.0 - color_progress * 0.5) * (trust_score + ethics_score) * 0.5
			var blue_component = 0.8 * (0.5 + color_progress * 0.5) * (transparency_level + accountability_level) * 0.5
			particle.material_override.albedo_color = Color(0.2, green_component, blue_component, 1)
			particle.material_override.emission = Color(0.2, green_component, blue_component, 1) * 0.3

func update_trust_metrics(delta):
	# Update trust score meter
	var trust_indicator = $TrustMetrics/TrustScore/TrustIndicator
	if trust_indicator:
		var target_x = lerp(-2, 2, trust_score)
		trust_indicator.position.x = lerp(trust_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on trust score
		var green_component = 0.8 * trust_score
		var red_component = 0.2 + 0.6 * (1.0 - trust_score)
		trust_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update ethics score meter
	var ethics_indicator = $TrustMetrics/EthicsScore/EthicsIndicator
	if ethics_indicator:
		var target_x = lerp(-2, 2, ethics_score)
		ethics_indicator.position.x = lerp(ethics_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on ethics score
		var green_component = 0.8 * ethics_score
		var red_component = 0.2 + 0.6 * (1.0 - ethics_score)
		ethics_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_transparency_level(level: float):
	transparency_level = clamp(level, 0.0, 1.0)

func set_accountability_level(level: float):
	accountability_level = clamp(level, 0.0, 1.0)

func get_trust_score() -> float:
	return trust_score

func get_ethics_score() -> float:
	return ethics_score

func reset_ethics():
	time = 0.0
	transparency_level = 0.0
	accountability_level = 0.0
	trust_score = 1.0
	ethics_score = 1.0
