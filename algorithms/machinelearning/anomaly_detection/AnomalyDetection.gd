extends Node3D
  

var time: float = 0.0
var detection_progress: float = 0.0
var precision_score: float = 0.0
var recall_score: float = 0.0
var particle_count: int = 30
var flow_particles: Array = []
var normal_particles: Array = []
var anomaly_particles: Array = []

func _ready():
	# Initialize Anomaly Detection visualization
	print("Anomaly Detection Visualization initialized")
	create_normal_particles()
	create_anomaly_particles()
	create_flow_particles()
	setup_detection_metrics()

func _process(delta):
	time += delta
	
	# Simulate detection progress
	detection_progress = min(1.0, time * 0.1)
	precision_score = detection_progress * 0.9
	recall_score = detection_progress * 0.85
	
	animate_normal_data(delta)
	animate_detection_engine(delta)
	animate_anomaly_output(delta)
	animate_threshold_boundary(delta)
	animate_data_flow(delta)
	update_detection_metrics(delta)

func create_normal_particles():
	# Create normal data particles
	var normal_particles_node = $NormalData/NormalParticles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
		
		# Position particles in a normal distribution cluster
		var angle = randf() * PI * 2
		var radius = randf_range(0.5, 2.0)
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = randf_range(-0.5, 0.5)
		particle.position = Vector3(x, y, z)
		
		normal_particles_node.add_child(particle)
		normal_particles.append(particle)

func create_anomaly_particles():
	# Create anomaly output particles
	var anomaly_particles_node = $AnomalyOutput/AnomalyParticles
	for i in range(10):  # Fewer anomalies
		var particle = CSGSphere3D.new()
		particle.radius = 0.12
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.5
		
		# Position particles as outliers
		var angle = randf() * PI * 2
		var radius = randf_range(3.0, 5.0)
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = randf_range(-1.0, 1.0)
		particle.position = Vector3(x, y, z)
		
		anomaly_particles_node.add_child(particle)
		anomaly_particles.append(particle)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(25):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the detection flow path
		var progress = float(i) / 25
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 3) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_detection_metrics():
	# Initialize detection metrics
	var precision_indicator = $DetectionMetrics/PrecisionMeter/PrecisionIndicator
	var recall_indicator = $DetectionMetrics/RecallMeter/RecallIndicator
	if precision_indicator:
		precision_indicator.position.x = 0  # Start at middle
	if recall_indicator:
		recall_indicator.position.x = 0  # Start at middle

func animate_normal_data(delta):
	# Animate normal data particles
	for i in range(normal_particles.size()):
		var particle = normal_particles[i]
		if particle:
			# Move particles in a flowing pattern within normal bounds
			var base_pos = particle.position
			var move_x = base_pos.x + sin(time * 0.8 + i * 0.1) * 0.2
			var move_y = base_pos.y + cos(time * 1.2 + i * 0.15) * 0.2
			var move_z = base_pos.z + sin(time * 1.0 + i * 0.12) * 0.1
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 1.5)
			particle.position.y = lerp(particle.position.y, move_y, delta * 1.5)
			particle.position.z = lerp(particle.position.z, move_z, delta * 1.5)
			
			# Pulse particles based on detection progress
			var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.2 * detection_progress
			particle.scale = Vector3.ONE * pulse

func animate_detection_engine(delta):
	# Animate detection engine core
	var engine_core = $DetectionEngine/EngineCore
	if engine_core:
		# Rotate engine
		engine_core.rotation.y += delta * 0.5
		
		# Pulse based on detection progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * detection_progress
		engine_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on detection
		if engine_core.material_override:
			var intensity = 0.3 + detection_progress * 0.7
			engine_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate detection method cores
	var statistical_core = $DetectionEngine/DetectionMethods/StatisticalCore
	if statistical_core:
		statistical_core.rotation.y += delta * 0.8
		var statistical_activation = sin(time * 1.5) * 0.5 + 0.5
		statistical_activation *= detection_progress
		
		var pulse = 1.0 + statistical_activation * 0.3
		statistical_core.scale = Vector3.ONE * pulse
		
		if statistical_core.material_override:
			var intensity = 0.3 + statistical_activation * 0.7
			statistical_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var isolation_core = $DetectionEngine/DetectionMethods/IsolationForestCore
	if isolation_core:
		isolation_core.rotation.y += delta * 1.0
		var isolation_activation = cos(time * 1.8) * 0.5 + 0.5
		isolation_activation *= detection_progress
		
		var pulse = 1.0 + isolation_activation * 0.3
		isolation_core.scale = Vector3.ONE * pulse
		
		if isolation_core.material_override:
			var intensity = 0.3 + isolation_activation * 0.7
			isolation_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var autoencoder_core = $DetectionEngine/DetectionMethods/AutoencoderCore
	if autoencoder_core:
		autoencoder_core.rotation.y += delta * 1.2
		var autoencoder_activation = sin(time * 2.0) * 0.5 + 0.5
		autoencoder_activation *= detection_progress
		
		var pulse = 1.0 + autoencoder_activation * 0.3
		autoencoder_core.scale = Vector3.ONE * pulse
		
		if autoencoder_core.material_override:
			var intensity = 0.3 + autoencoder_activation * 0.7
			autoencoder_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_anomaly_output(delta):
	# Animate anomaly particles
	for i in range(anomaly_particles.size()):
		var particle = anomaly_particles[i]
		if particle:
			# Move particles in an erratic pattern
			var base_pos = particle.position
			var move_x = base_pos.x + sin(time * 1.5 + i * 0.3) * 0.5
			var move_y = base_pos.y + cos(time * 2.0 + i * 0.4) * 0.5
			var move_z = base_pos.z + sin(time * 1.8 + i * 0.25) * 0.3
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on detection progress
			var pulse = 1.0 + sin(time * 2.5 + i * 0.5) * 0.3 * detection_progress
			particle.scale = Vector3.ONE * pulse
			
			# Flash red when detection is active
			if detection_progress > 0.5:
				var flash = sin(time * 5.0 + i * 0.5) * 0.5 + 0.5
				particle.material_override.emission = Color(0.8, 0.2, 0.2, 1) * flash * 0.8

func animate_threshold_boundary(delta):
	# Animate threshold boundary core
	var boundary_core = $ThresholdBoundary/BoundaryCore
	if boundary_core:
		# Rotate boundary
		boundary_core.rotation.y += delta * 0.3
		
		# Pulse based on detection progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * detection_progress
		boundary_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on detection
		if boundary_core.material_override:
			var intensity = 0.3 + detection_progress * 0.7
			boundary_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the detection flow
			var progress = fmod(time * 0.25 + i * 0.1, 1.0)
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 3) * 2
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and detection progress
			var color_progress = fmod((progress + 0.5), 1.0)
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on detection
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * detection_progress
			particle.scale = Vector3.ONE * pulse

func update_detection_metrics(delta):
	# Update precision meter
	var precision_indicator = $DetectionMetrics/PrecisionMeter/PrecisionIndicator
	if precision_indicator:
		var target_x = lerp(-2, 2, precision_score)
		precision_indicator.position.x = lerp(precision_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on precision
		var green_component = 0.8 * precision_score
		var red_component = 0.2 + 0.6 * (1.0 - precision_score)
		precision_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update recall meter
	var recall_indicator = $DetectionMetrics/RecallMeter/RecallIndicator
	if recall_indicator:
		var target_x = lerp(-2, 2, recall_score)
		recall_indicator.position.x = lerp(recall_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on recall
		var green_component = 0.8 * recall_score
		var red_component = 0.2 + 0.6 * (1.0 - recall_score)
		recall_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_detection_progress(progress: float):
	detection_progress = clamp(progress, 0.0, 1.0)

func set_precision_score(precision: float):
	precision_score = clamp(precision, 0.0, 1.0)

func set_recall_score(recall: float):
	recall_score = clamp(recall, 0.0, 1.0)

func get_detection_progress() -> float:
	return detection_progress

func get_precision_score() -> float:
	return precision_score

func get_recall_score() -> float:
	return recall_score

func reset_detection():
	time = 0.0
	detection_progress = 0.0
	precision_score = 0.0
	recall_score = 0.0
