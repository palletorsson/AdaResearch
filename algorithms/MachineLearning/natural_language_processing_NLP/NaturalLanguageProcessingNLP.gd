extends Node3D
class_name NaturalLanguageProcessingNLP

var time: float = 0.0
var processing_progress: float = 0.0
var accuracy_score: float = 0.0
var perplexity_score: float = 0.0
var particle_count: int = 30
var flow_particles: Array = []
var text_particles: Array = []
var result_particles: Array = []

func _ready():
	# Initialize NLP visualization
	print("Natural Language Processing Visualization initialized")
	create_text_particles()
	create_result_particles()
	create_flow_particles()
	setup_nlp_metrics()

func _process(delta):
	time += delta
	
	# Simulate processing progress
	processing_progress = min(1.0, time * 0.1)
	accuracy_score = processing_progress * 0.9
	perplexity_score = processing_progress * 0.8
	
	animate_input_text(delta)
	animate_processing_pipeline(delta)
	animate_output_results(delta)
	animate_language_model(delta)
	animate_data_flow(delta)
	update_nlp_metrics(delta)

func create_text_particles():
	# Create text input particles representing words/tokens
	var text_particles_node = $InputText/TextParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position particles in text-like arrangement
		var row = i / 6
		var col = i % 6
		var x = (col - 2.5) * 0.5
		var y = (row - 2.5) * 0.3
		var z = randf_range(-0.3, 0.3)
		particle.position = Vector3(x, y, z)
		
		text_particles_node.add_child(particle)
		text_particles.append(particle)

func create_result_particles():
	# Create result output particles
	var result_particles_node = $OutputResults/ResultParticles
	for i in range(20):
		var particle = CSGSphere3D.new()
		particle.radius = 0.1
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.4
		
		# Position particles in structured output format
		var row = i / 5
		var col = i % 5
		var x = (col - 2) * 0.6
		var y = (row - 1.5) * 0.4
		var z = randf_range(-0.2, 0.2)
		particle.position = Vector3(x, y, z)
		
		result_particles_node.add_child(particle)
		result_particles.append(particle)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(35):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the processing flow path
		var progress = float(i) / 35
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 5) * 2.5
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_nlp_metrics():
	# Initialize NLP metrics
	var accuracy_indicator = $NLPMetrics/AccuracyMeter/AccuracyIndicator
	var perplexity_indicator = $NLPMetrics/PerplexityMeter/PerplexityIndicator
	if accuracy_indicator:
		accuracy_indicator.position.x = 0  # Start at middle
	if perplexity_indicator:
		perplexity_indicator.position.x = 0  # Start at middle

func animate_input_text(delta):
	# Animate text particles
	for i in range(text_particles.size()):
		var particle = text_particles[i]
		if particle:
			# Move particles in a reading flow pattern
			var base_pos = particle.position
			var move_x = base_pos.x + sin(time * 0.8 + i * 0.2) * 0.1
			var move_y = base_pos.y + cos(time * 1.0 + i * 0.15) * 0.1
			var move_z = base_pos.z + sin(time * 1.2 + i * 0.1) * 0.05
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on processing progress
			var pulse = 1.0 + sin(time * 2.0 + i * 0.3) * 0.2 * processing_progress
			particle.scale = Vector3.ONE * pulse
			
			# Change color based on tokenization progress
			var token_progress = (time * 0.5 + float(i) * 0.1) % 1.0
			var red_component = 0.8 * (0.5 + token_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - token_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)

func animate_processing_pipeline(delta):
	# Animate processing pipeline core
	var pipeline_core = $ProcessingPipeline/PipelineCore
	if pipeline_core:
		# Rotate pipeline
		pipeline_core.rotation.y += delta * 0.5
		
		# Pulse based on processing progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * processing_progress
		pipeline_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on processing
		if pipeline_core.material_override:
			var intensity = 0.3 + processing_progress * 0.7
			pipeline_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate processing stage cores
	var tokenization_core = $ProcessingPipeline/ProcessingStages/TokenizationCore
	if tokenization_core:
		tokenization_core.rotation.y += delta * 0.8
		var tokenization_activation = sin(time * 1.5) * 0.5 + 0.5
		tokenization_activation *= processing_progress
		
		var pulse = 1.0 + tokenization_activation * 0.3
		tokenization_core.scale = Vector3.ONE * pulse
		
		if tokenization_core.material_override:
			var intensity = 0.3 + tokenization_activation * 0.7
			tokenization_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var embedding_core = $ProcessingPipeline/ProcessingStages/EmbeddingCore
	if embedding_core:
		embedding_core.rotation.y += delta * 1.0
		var embedding_activation = cos(time * 1.8) * 0.5 + 0.5
		embedding_activation *= processing_progress
		
		var pulse = 1.0 + embedding_activation * 0.3
		embedding_core.scale = Vector3.ONE * pulse
		
		if embedding_core.material_override:
			var intensity = 0.3 + embedding_activation * 0.7
			embedding_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var attention_core = $ProcessingPipeline/ProcessingStages/AttentionCore
	if attention_core:
		attention_core.rotation.y += delta * 1.2
		var attention_activation = sin(time * 2.0) * 0.5 + 0.5
		attention_activation *= processing_progress
		
		var pulse = 1.0 + attention_activation * 0.3
		attention_core.scale = Vector3.ONE * pulse
		
		if attention_core.material_override:
			var intensity = 0.3 + attention_activation * 0.7
			attention_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var sentiment_core = $ProcessingPipeline/ProcessingStages/SentimentCore
	if sentiment_core:
		sentiment_core.rotation.y += delta * 0.9
		var sentiment_activation = cos(time * 1.6) * 0.5 + 0.5
		sentiment_activation *= processing_progress
		
		var pulse = 1.0 + sentiment_activation * 0.3
		sentiment_core.scale = Vector3.ONE * pulse
		
		if sentiment_core.material_override:
			var intensity = 0.3 + sentiment_activation * 0.7
			sentiment_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var ner_core = $ProcessingPipeline/ProcessingStages/NERCore
	if ner_core:
		ner_core.rotation.y += delta * 1.1
		var ner_activation = sin(time * 1.7) * 0.5 + 0.5
		ner_activation *= processing_progress
		
		var pulse = 1.0 + ner_activation * 0.3
		ner_core.scale = Vector3.ONE * pulse
		
		if ner_core.material_override:
			var intensity = 0.3 + ner_activation * 0.7
			ner_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_output_results(delta):
	# Animate result particles
	for i in range(result_particles.size()):
		var particle = result_particles[i]
		if particle:
			# Move particles in a structured output pattern
			var base_pos = particle.position
			var move_x = base_pos.x + sin(time * 0.6 + i * 0.15) * 0.1
			var move_y = base_pos.y + cos(time * 0.8 + i * 0.2) * 0.1
			var move_z = base_pos.z + sin(time * 1.0 + i * 0.1) * 0.05
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on processing progress
			var pulse = 1.0 + sin(time * 2.2 + i * 0.25) * 0.2 * processing_progress
			particle.scale = Vector3.ONE * pulse
			
			# Change color based on result confidence
			var confidence = (processing_progress + sin(time * 1.5 + i * 0.2) * 0.2) % 1.0
			var green_component = 0.8 * confidence
			var red_component = 0.2 + 0.6 * (1.0 - confidence)
			particle.material_override.albedo_color = Color(red_component, green_component, 0.8, 1)

func animate_language_model(delta):
	# Animate language model core
	var model_core = $LanguageModel/ModelCore
	if model_core:
		# Rotate model
		model_core.rotation.y += delta * 0.3
		
		# Pulse based on processing progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * processing_progress
		model_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on processing
		if model_core.material_override:
			var intensity = 0.3 + processing_progress * 0.7
			model_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the processing flow
			var progress = (time * 0.25 + float(i) * 0.08) % 1.0
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 5) * 2.5
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and processing progress
			var color_progress = (progress + 0.5) % 1.0
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on processing
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * processing_progress
			particle.scale = Vector3.ONE * pulse

func update_nlp_metrics(delta):
	# Update accuracy meter
	var accuracy_indicator = $NLPMetrics/AccuracyMeter/AccuracyIndicator
	if accuracy_indicator:
		var target_x = lerp(-2, 2, accuracy_score)
		accuracy_indicator.position.x = lerp(accuracy_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on accuracy
		var green_component = 0.8 * accuracy_score
		var red_component = 0.2 + 0.6 * (1.0 - accuracy_score)
		accuracy_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update perplexity meter (lower is better, so invert)
	var perplexity_indicator = $NLPMetrics/PerplexityMeter/PerplexityIndicator
	if perplexity_indicator:
		var target_x = lerp(-2, 2, 1.0 - perplexity_score)  # Invert because lower perplexity is better
		perplexity_indicator.position.x = lerp(perplexity_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on perplexity (inverted)
		var green_component = 0.8 * (1.0 - perplexity_score)
		var red_component = 0.2 + 0.6 * perplexity_score
		perplexity_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_processing_progress(progress: float):
	processing_progress = clamp(progress, 0.0, 1.0)

func set_accuracy_score(accuracy: float):
	accuracy_score = clamp(accuracy, 0.0, 1.0)

func set_perplexity_score(perplexity: float):
	perplexity_score = clamp(perplexity, 0.0, 1.0)

func get_processing_progress() -> float:
	return processing_progress

func get_accuracy_score() -> float:
	return accuracy_score

func get_perplexity_score() -> float:
	return perplexity_score

func reset_processing():
	time = 0.0
	processing_progress = 0.0
	accuracy_score = 0.0
	perplexity_score = 0.0
