extends Node3D
class_name ExplainableAIXAI

var time: float = 0.0
var explanation_progress: float = 0.0
var transparency_score: float = 0.0
var interpretability_score: float = 0.0
var particle_count: int = 20
var flow_particles: Array = []
var explanation_particles: Array = []

func _ready():
	# Initialize Explainable AI visualization
	print("Explainable AI Visualization initialized")
	create_input_particles()
	create_explanation_particles()
	create_flow_particles()
	setup_explanation_metrics()

func _process(delta):
	time += delta
	
	# Simulate explanation progress
	explanation_progress = min(1.0, time * 0.1)
	transparency_score = explanation_progress * 0.9
	interpretability_score = explanation_progress * 0.85
	
	animate_input_data(delta)
	animate_ai_model(delta)
	animate_explanation_engine(delta)
	animate_transparency_metrics(delta)
	animate_data_flow(delta)
	update_explanation_metrics(delta)

func create_input_particles():
	# Create input data particles
	var input_particles = $InputData/InputParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles in a cluster around input
		var x = randf_range(-1.5, 1.5)
		var y = randf_range(-1.5, 1.5)
		var z = randf_range(-1.5, 1.5)
		particle.position = Vector3(x, y, z)
		
		input_particles.add_child(particle)

func create_explanation_particles():
	# Create explanation output particles
	var explanation_particles_node = $OutputExplanation/ExplanationParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		# Position particles in a cluster around output
		var x = randf_range(-1.5, 1.5)
		var y = randf_range(-1.5, 1.5)
		var z = randf_range(-1.5, 1.5)
		particle.position = Vector3(x, y, z)
		
		explanation_particles_node.add_child(particle)
		explanation_particles.append(particle)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(25):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position particles along the explanation flow path
		var progress = float(i) / 25
		var x = lerp(-8, 4, progress)
		var y = sin(progress * PI * 2) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_explanation_metrics():
	# Initialize explanation metrics
	var transparency_indicator = $ExplanationMetrics/TransparencyMeter/TransparencyIndicator
	var interpretability_indicator = $ExplanationMetrics/InterpretabilityMeter/InterpretabilityIndicator
	if transparency_indicator:
		transparency_indicator.position.x = 0  # Start at middle
	if interpretability_indicator:
		interpretability_indicator.position.x = 0  # Start at middle

func animate_input_data(delta):
	# Animate input particles
	var input_particles = $InputData/InputParticles
	for i in range(input_particles.get_child_count()):
		var particle = input_particles.get_child(i)
		if particle:
			# Move particles in a flowing pattern
			var move_x = sin(time * 0.8 + i * 0.1) * 0.3
			var move_y = cos(time * 1.2 + i * 0.15) * 0.3
			var move_z = sin(time * 1.0 + i * 0.12) * 0.3
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 1.5)
			particle.position.y = lerp(particle.position.y, move_y, delta * 1.5)
			particle.position.z = lerp(particle.position.z, move_z, delta * 1.5)
			
			# Pulse particles based on explanation progress
			var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.2 * explanation_progress
			particle.scale = Vector3.ONE * pulse

func animate_ai_model(delta):
	# Animate AI model core
	var model_core = $AIModel/ModelCore
	if model_core:
		# Rotate model
		model_core.rotation.y += delta * 0.6
		
		# Pulse based on explanation progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * explanation_progress
		model_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on explanation
		if model_core.material_override:
			var intensity = 0.3 + explanation_progress * 0.7
			model_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_explanation_engine(delta):
	# Animate explanation engine core
	var explanation_core = $ExplanationEngine/ExplanationCore
	if explanation_core:
		# Rotate explanation engine
		explanation_core.rotation.y += delta * 0.5
		
		# Pulse based on explanation progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * explanation_progress
		explanation_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on explanation
		if explanation_core.material_override:
			var intensity = 0.3 + explanation_progress * 0.7
			explanation_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate explanation method cores
	var shap_core = $ExplanationEngine/ExplanationMethods/SHAPCore
	if shap_core:
		shap_core.rotation.y += delta * 0.8
		var shap_activation = sin(time * 1.5) * 0.5 + 0.5
		shap_activation *= explanation_progress
		
		var pulse = 1.0 + shap_activation * 0.3
		shap_core.scale = Vector3.ONE * pulse
		
		if shap_core.material_override:
			var intensity = 0.3 + shap_activation * 0.7
			shap_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var lime_core = $ExplanationEngine/ExplanationMethods/LIMECore
	if lime_core:
		lime_core.rotation.y += delta * 1.0
		var lime_activation = cos(time * 1.8) * 0.5 + 0.5
		lime_activation *= explanation_progress
		
		var pulse = 1.0 + lime_activation * 0.3
		lime_core.scale = Vector3.ONE * pulse
		
		if lime_core.material_override:
			var intensity = 0.3 + lime_activation * 0.7
			lime_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var gradcam_core = $ExplanationEngine/ExplanationMethods/GradCAMCore
	if gradcam_core:
		gradcam_core.rotation.y += delta * 1.2
		var gradcam_activation = sin(time * 2.0) * 0.5 + 0.5
		gradcam_activation *= explanation_progress
		
		var pulse = 1.0 + gradcam_activation * 0.3
		gradcam_core.scale = Vector3.ONE * pulse
		
		if gradcam_core.material_override:
			var intensity = 0.3 + gradcam_activation * 0.7
			gradcam_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_transparency_metrics(delta):
	# Animate transparency metrics core
	var transparency_core = $TransparencyMetrics/TransparencyCore
	if transparency_core:
		# Rotate transparency core
		transparency_core.rotation.y += delta * 0.7
		
		# Pulse based on transparency score
		var pulse = 1.0 + sin(time * 2.5) * 0.15 * transparency_score
		transparency_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on transparency
		if transparency_core.material_override:
			var intensity = 0.3 + transparency_score * 0.7
			transparency_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the explanation flow
			var progress = (time * 0.25 + float(i) * 0.1) % 1.0
			var x = lerp(-8, 4, progress)
			var y = sin(progress * PI * 2) * 2
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and explanation progress
			var color_progress = (progress + 0.5) % 1.0
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on explanation
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * explanation_progress
			particle.scale = Vector3.ONE * pulse

func update_explanation_metrics(delta):
	# Update transparency meter
	var transparency_indicator = $ExplanationMetrics/TransparencyMeter/TransparencyIndicator
	if transparency_indicator:
		var target_x = lerp(-2, 2, transparency_score)
		transparency_indicator.position.x = lerp(transparency_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on transparency
		var green_component = 0.8 * transparency_score
		var red_component = 0.2 + 0.6 * (1.0 - transparency_score)
		transparency_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update interpretability meter
	var interpretability_indicator = $ExplanationMetrics/InterpretabilityMeter/InterpretabilityIndicator
	if interpretability_indicator:
		var target_x = lerp(-2, 2, interpretability_score)
		interpretability_indicator.position.x = lerp(interpretability_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on interpretability
		var green_component = 0.8 * interpretability_score
		var red_component = 0.2 + 0.6 * (1.0 - interpretability_score)
		interpretability_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_explanation_progress(progress: float):
	explanation_progress = clamp(progress, 0.0, 1.0)

func set_transparency_score(transparency: float):
	transparency_score = clamp(transparency, 0.0, 1.0)

func set_interpretability_score(interpretability: float):
	interpretability_score = clamp(interpretability, 0.0, 1.0)

func get_explanation_progress() -> float:
	return explanation_progress

func get_transparency_score() -> float:
	return transparency_score

func get_interpretability_score() -> float:
	return interpretability_score

func reset_explanation():
	time = 0.0
	explanation_progress = 0.0
	transparency_score = 0.0
	interpretability_score = 0.0
