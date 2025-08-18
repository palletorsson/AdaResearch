extends Node3D
class_name AttentionMechanisms

var time: float = 0.0
var attention_score: float = 0.0
var focus_intensity: float = 0.0
var token_count: int = 6
var attention_weights: Array = []

func _ready():
	# Initialize attention mechanisms visualization
	print("Attention Mechanisms Visualization initialized")
	create_input_tokens()
	create_attention_matrix()
	create_weight_visualization()
	create_focus_indicators()
	setup_training_metrics()

func _process(delta):
	time += delta
	
	# Simulate attention dynamics
	attention_score = min(1.0, time * 0.15)
	focus_intensity = attention_score * 0.8
	
	animate_input_tokens(delta)
	animate_query_key_value(delta)
	animate_attention_weights(delta)
	animate_focus_indicators(delta)
	update_training_metrics(delta)

func create_input_tokens():
	# Create input sequence tokens
	var input_tokens = $InputSequence/InputTokens
	for i in range(token_count):
		var token = CSGSphere3D.new()
		token.radius = 0.2
		token.material_override = StandardMaterial3D.new()
		token.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		token.material_override.emission_enabled = true
		token.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		var x = (i - token_count/2) * 0.8
		token.position = Vector3(x, 0, 0)
		input_tokens.add_child(token)
	
	# Create output sequence tokens
	var output_tokens = $OutputSequence/OutputTokens
	for i in range(token_count):
		var token = CSGSphere3D.new()
		token.radius = 0.2
		token.material_override = StandardMaterial3D.new()
		token.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		token.material_override.emission_enabled = true
		token.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		var x = (i - token_count/2) * 0.8
		token.position = Vector3(x, 0, 0)
		output_tokens.add_child(token)

func create_attention_matrix():
	# Create attention weights matrix
	var attention_matrix = $AttentionWeights/AttentionMatrix
	for i in range(token_count):
		for j in range(token_count):
			var weight = CSGSphere3D.new()
			weight.radius = 0.05
			weight.material_override = StandardMaterial3D.new()
			weight.material_override.albedo_color = Color(0.6, 0.6, 0.6, 0.8)
			weight.material_override.emission_enabled = true
			weight.material_override.emission = Color(0.6, 0.6, 0.6, 1) * 0.2
			
			var x = (i - token_count/2) * 0.4
			var z = (j - token_count/2) * 0.4
			weight.position = Vector3(x, 0, z)
			attention_matrix.add_child(weight)
			attention_weights.append(weight)

func create_weight_visualization():
	# Create weight connection lines
	var weight_lines = $WeightVisualization/WeightLines
	for i in range(token_count):
		for j in range(token_count):
			var line = CSGCylinder3D.new()
			line.radius = 0.01
			line.height = 0.8
			line.material_override = StandardMaterial3D.new()
			line.material_override.albedo_color = Color(0.4, 0.4, 0.8, 0.6)
			
			var start_x = (i - token_count/2) * 0.8
			var end_x = (j - token_count/2) * 0.4
			var mid_x = (start_x + end_x) / 2
			var mid_z = (0 + (j - token_count/2) * 0.4) / 2
			
			line.position = Vector3(mid_x, 0, mid_z)
			line.rotation.z = atan2((j - token_count/2) * 0.4, end_x - start_x)
			
			weight_lines.add_child(line)

func create_focus_indicators():
	# Create focus indicator spheres
	var focus_spheres = $FocusIndicators/FocusSpheres
	for i in range(token_count):
		var sphere = CSGSphere3D.new()
		sphere.radius = 0.15
		sphere.material_override = StandardMaterial3D.new()
		sphere.material_override.albedo_color = Color(0.8, 0.2, 0.8, 0.7)
		sphere.material_override.emission_enabled = true
		sphere.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		var x = (i - token_count/2) * 0.8
		sphere.position = Vector3(x, 1.5, 0)
		focus_spheres.add_child(sphere)

func setup_training_metrics():
	# Initialize attention score meter
	var score_indicator = $TrainingMetrics/AttentionScore/ScoreIndicator
	if score_indicator:
		score_indicator.position.x = -4  # Start at low score

func animate_input_tokens(delta):
	# Animate input sequence tokens
	var input_tokens = $InputSequence/InputTokens
	for i in range(input_tokens.get_child_count()):
		var token = input_tokens.get_child(i)
		if token:
			# Pulse tokens based on attention
			var pulse = 1.0 + sin(time * 2.0 + i * 0.5) * 0.2 * attention_score
			token.scale = Vector3.ONE * pulse
			
			# Rotate tokens
			token.rotation.y += delta * (0.5 + i * 0.2)
			
			# Change emission intensity based on attention
			if token.material_override:
				var intensity = 0.3 + attention_score * 0.7
				token.material_override.emission = Color(0.8, 0.8, 0.2, 1) * intensity

func animate_query_key_value(delta):
	# Animate query core
	var query_core = $QueryKeyValue/QueryCore
	if query_core:
		query_core.rotation.y += delta * 1.0
		query_core.scale = Vector3.ONE * (1.0 + sin(time * 2.5) * 0.15)
		
		# Change emission based on attention
		if query_core.material_override:
			var intensity = 0.3 + attention_score * 0.7
			query_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate key core
	var key_core = $QueryKeyValue/KeyCore
	if key_core:
		key_core.rotation.y += delta * 0.8
		key_core.scale = Vector3.ONE * (1.0 + sin(time * 2.0) * 0.15)
		
		# Change emission based on attention
		if key_core.material_override:
			var intensity = 0.3 + attention_score * 0.7
			key_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate value core
	var value_core = $QueryKeyValue/ValueCore
	if value_core:
		value_core.rotation.y += delta * 1.2
		value_core.scale = Vector3.ONE * (1.0 + sin(time * 3.0) * 0.15)
		
		# Change emission based on attention
		if value_core.material_override:
			var intensity = 0.3 + attention_score * 0.7
			value_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_attention_weights(delta):
	# Animate attention weights matrix
	for i in range(attention_weights.size()):
		var weight = attention_weights[i]
		if weight:
			# Calculate attention weight based on position and time
			var row = i / token_count
			var col = i % token_count
			var attention_value = sin(time * 1.5 + row * 0.5) * 0.5 + 0.5
			attention_value *= cos(time * 1.2 + col * 0.3) * 0.5 + 0.5
			attention_value *= attention_score
			
			# Scale weight based on attention value
			var target_scale = 0.5 + attention_value * 0.5
			weight.scale = Vector3.ONE * lerp(weight.scale.x, target_scale, delta * 3.0)
			
			# Change color based on attention value
			if weight.material_override:
				var green_component = 0.6 + attention_value * 0.4
				var blue_component = 0.6 + attention_value * 0.4
				weight.material_override.albedo_color = Color(0.6, green_component, blue_component, 0.8)
				weight.material_override.emission = Color(0.6, green_component, blue_component, 1) * (0.2 + attention_value * 0.3)

func animate_focus_indicators(delta):
	# Animate focus indicator spheres
	var focus_spheres = $FocusIndicators/FocusSpheres
	for i in range(focus_spheres.get_child_count()):
		var sphere = focus_spheres.get_child(i)
		if sphere:
			# Pulse based on focus intensity
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.3 * focus_intensity
			sphere.scale = Vector3.ONE * pulse
			
			# Move up and down slightly
			var y_offset = sin(time * 1.8 + i * 0.4) * 0.2 * focus_intensity
			sphere.position.y = 1.5 + y_offset
			
			# Change emission intensity
			if sphere.material_override:
				var intensity = 0.3 + focus_intensity * 0.7
				sphere.material_override.emission = Color(0.8, 0.2, 0.8, 1) * intensity

func update_training_metrics(delta):
	# Update attention score meter
	var score_indicator = $TrainingMetrics/AttentionScore/ScoreIndicator
	if score_indicator:
		var target_x = lerp(-4, 4, attention_score)
		score_indicator.position.x = lerp(score_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on score
		var green_component = 0.8 * attention_score
		var red_component = 0.2 + 0.6 * (1.0 - attention_score)
		score_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_attention_score(score: float):
	attention_score = clamp(score, 0.0, 1.0)

func set_focus_intensity(intensity: float):
	focus_intensity = clamp(intensity, 0.0, 1.0)

func get_attention_score() -> float:
	return attention_score

func get_focus_intensity() -> float:
	return focus_intensity

func reset_attention():
	time = 0.0
	attention_score = 0.0
	focus_intensity = 0.0
