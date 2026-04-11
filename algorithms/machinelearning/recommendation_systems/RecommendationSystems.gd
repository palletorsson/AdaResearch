## ============================================================================
## RecommendationSystems.gd — Interactive Recommendation Systems Visualization
## Demonstrates collaborative filtering, content-based, and hybrid recommendation
## engines with animated user-item matching, data flow, and live metric tracking.
## ============================================================================
extends Node3D

# ── Runtime UI Controls ──────────────────────────────────────────────────────
@export_range(0.0, 1.0, 0.01) var recommendation_progress: float = 0.0:
	set(v):
		recommendation_progress = clamp(v, 0.0, 1.0)
		_on_progress_changed()

@export_range(0.0, 1.0, 0.01) var precision_score: float = 0.0:
	set(v):
		precision_score = clamp(v, 0.0, 1.0)

@export_range(0.0, 1.0, 0.01) var recall_score: float = 0.0:
	set(v):
		recall_score = clamp(v, 0.0, 1.0)

@export_range(5, 40, 1) var particle_count: int = 15
@export_range(0.1, 3.0, 0.1) var animation_speed: float = 1.0
@export var auto_progress: bool = true  ## Automatically advance progress over time

# ── Internal State ───────────────────────────────────────────────────────────
var time: float = 0.0
var flow_particles: Array = []
var user_particles: Array = []
var item_particles: Array = []
var _stats_label: Label3D = null
var _match_lines: Array = []  ## Lines connecting matched user-item pairs

func _ready() -> void:
	# Initialize Recommendation Systems visualization
	print("Recommendation Systems Visualization initialized")
	create_user_particles()
	create_item_particles()
	create_flow_particles()
	setup_recommendation_metrics()
	_create_stats_label()

func _process(delta: float) -> void:
	time += delta * animation_speed
	
	# ── Auto-advance progress if enabled ─────────────────────────────────
	if auto_progress:
		recommendation_progress = min(1.0, time * 0.1)
		precision_score = recommendation_progress * 0.9
		recall_score = recommendation_progress * 0.85
	
	animate_users(delta)
	animate_recommendation_engine(delta)
	animate_items(delta)
	animate_user_item_matrix(delta)
	animate_data_flow(delta)
	update_recommendation_metrics(delta)
	_update_stats_label()

func create_user_particles() -> void:
	## Create user profile particles — purple spheres representing individual users
	var user_profiles = $Users/UserProfiles
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.3, 0.5, 0.9, 1)  # Blue for data
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.3, 0.5, 0.9, 1) * 0.5
		particle.material_override.emission_energy_multiplier = 1.5
		particle.material_override.metallic = 0.4
		particle.material_override.roughness = 0.3
		
		# Position particles in a cluster around users
		var x = randf_range(-1.5, 1.5)
		var y = randf_range(-1.5, 1.5)
		var z = randf_range(-1.5, 1.5)
		particle.position = Vector3(x, y, z)
		
		user_profiles.add_child(particle)
		user_particles.append(particle)

func create_item_particles() -> void:
	## Create item catalog particles — cyan spheres representing available items
	var item_catalog = $Items/ItemCatalog
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.3, 0.85, 0.4, 1)  # Green for items
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.3, 0.85, 0.4, 1) * 0.5
		particle.material_override.emission_energy_multiplier = 1.5
		particle.material_override.metallic = 0.4
		particle.material_override.roughness = 0.3
		
		# Position particles in a cluster around items
		var x = randf_range(-1.5, 1.5)
		var y = randf_range(-1.5, 1.5)
		var z = randf_range(-1.5, 1.5)
		particle.position = Vector3(x, y, z)
		
		item_catalog.add_child(particle)
		item_particles.append(particle)

func create_flow_particles() -> void:
	## Create data flow particles — gold spheres flowing through the recommendation pipeline
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(30):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(1.0, 0.85, 0.2, 1)  # Gold for data flow
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(1.0, 0.85, 0.2, 1) * 0.6
		particle.material_override.emission_energy_multiplier = 2.0
		particle.material_override.metallic = 0.6
		particle.material_override.roughness = 0.2
		
		# Position particles along the recommendation flow path
		var progress = float(i) / 30
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 3) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_recommendation_metrics() -> void:
	# Initialize recommendation metrics
	var precision_indicator = $RecommendationMetrics/PrecisionMeter/PrecisionIndicator
	var recall_indicator = $RecommendationMetrics/RecallMeter/RecallIndicator
	if precision_indicator:
		precision_indicator.position.x = 0  # Start at middle
	if recall_indicator:
		recall_indicator.position.x = 0  # Start at middle

## ── User & Item Animation ────────────────────────────────────────────────────

func animate_users(delta) -> void:
	## Animate user particles in flowing cluster patterns with progress-based pulsing
	for i in range(user_particles.size()):
		var particle = user_particles[i]
		if particle:
			# Move particles in a flowing pattern
			var move_x = sin(time * 0.8 + i * 0.1) * 0.3
			var move_y = cos(time * 1.2 + i * 0.15) * 0.3
			var move_z = sin(time * 1.0 + i * 0.12) * 0.3
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 1.5)
			particle.position.y = lerp(particle.position.y, move_y, delta * 1.5)
			particle.position.z = lerp(particle.position.z, move_z, delta * 1.5)
			
			# Pulse particles based on recommendation progress
			var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.2 * recommendation_progress
			particle.scale = Vector3.ONE * pulse

## ── Recommendation Engine Animation ──────────────────────────────────────────

func animate_recommendation_engine(delta) -> void:
	## Animate the central engine and its sub-method cores (collaborative, content-based, hybrid)
	var engine_core = $RecommendationEngine/EngineCore
	if engine_core:
		# Rotate engine
		engine_core.rotation.y += delta * 0.5
		
		# Pulse based on recommendation progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * recommendation_progress
		engine_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on recommendation
		if engine_core.material_override:
			var intensity = 0.3 + recommendation_progress * 0.7
			engine_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate recommendation method cores
	var collaborative_core = $RecommendationEngine/RecommendationMethods/CollaborativeCore
	if collaborative_core:
		collaborative_core.rotation.y += delta * 0.8
		var collaborative_activation = sin(time * 1.5) * 0.5 + 0.5
		collaborative_activation *= recommendation_progress
		
		var pulse = 1.0 + collaborative_activation * 0.3
		collaborative_core.scale = Vector3.ONE * pulse
		
		if collaborative_core.material_override:
			var intensity = 0.3 + collaborative_activation * 0.7
			collaborative_core.material_override.emission = Color(0.9, 0.3, 0.3, 1) * intensity
	
	var content_based_core = $RecommendationEngine/RecommendationMethods/ContentBasedCore
	if content_based_core:
		content_based_core.rotation.y += delta * 1.0
		var content_activation = cos(time * 1.8) * 0.5 + 0.5
		content_activation *= recommendation_progress
		
		var pulse = 1.0 + content_activation * 0.3
		content_based_core.scale = Vector3.ONE * pulse
		
		if content_based_core.material_override:
			var intensity = 0.3 + content_activation * 0.7
			content_based_core.material_override.emission = Color(0.3, 0.5, 0.9, 1) * intensity
	
	var hybrid_core = $RecommendationEngine/RecommendationMethods/HybridCore
	if hybrid_core:
		hybrid_core.rotation.y += delta * 1.2
		var hybrid_activation = sin(time * 2.0) * 0.5 + 0.5
		hybrid_activation *= recommendation_progress
		
		var pulse = 1.0 + hybrid_activation * 0.3
		hybrid_core.scale = Vector3.ONE * pulse
		
		if hybrid_core.material_override:
			var intensity = 0.3 + hybrid_activation * 0.7
			hybrid_core.material_override.emission = Color(1.0, 0.85, 0.2, 1) * intensity  # Gold for hybrid

func animate_items(delta) -> void:
	# Animate item particles
	for i in range(item_particles.size()):
		var particle = item_particles[i]
		if particle:
			# Move particles in a flowing pattern
			var move_x = sin(time * 0.6 + i * 0.08) * 0.3
			var move_y = cos(time * 0.8 + i * 0.1) * 0.3
			var move_z = sin(time * 1.0 + i * 0.12) * 0.3
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 1.5)
			particle.position.y = lerp(particle.position.y, move_y, delta * 1.5)
			particle.position.z = lerp(particle.position.z, move_z, delta * 1.5)
			
			# Pulse particles based on recommendation progress
			var pulse = 1.0 + sin(time * 2.2 + i * 0.15) * 0.2 * recommendation_progress
			particle.scale = Vector3.ONE * pulse

func animate_user_item_matrix(delta) -> void:
	# Animate user-item matrix core
	var matrix_core = $UserItemMatrix/MatrixCore
	if matrix_core:
		# Rotate matrix
		matrix_core.rotation.y += delta * 0.4
		
		# Pulse based on recommendation progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * recommendation_progress
		matrix_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on recommendation
		if matrix_core.material_override:
			var intensity = 0.3 + recommendation_progress * 0.7
			matrix_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

## ── Data Flow Animation ──────────────────────────────────────────────────────

func animate_data_flow(delta) -> void:
	## Animate gold flow particles traveling through the recommendation pipeline
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the recommendation flow
			var progress = fmod(time * 0.25 + float(i) * 0.1, 1.0)
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 3) * 2
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and recommendation progress
			var color_progress = fmod((progress + 0.5), 1.0)
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on recommendation
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * recommendation_progress
			particle.scale = Vector3.ONE * pulse

## ── Metrics Animation ────────────────────────────────────────────────────────

func update_recommendation_metrics(delta) -> void:
	## Update precision and recall meter indicators with color-coded feedback
	var precision_indicator = $RecommendationMetrics/PrecisionMeter/PrecisionIndicator
	if precision_indicator:
		var target_x = lerp(-2, 2, precision_score)
		precision_indicator.position.x = lerp(precision_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on precision
		var green_component = 0.8 * precision_score
		var red_component = 0.2 + 0.6 * (1.0 - precision_score)
		precision_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update recall meter
	var recall_indicator = $RecommendationMetrics/RecallMeter/RecallIndicator
	if recall_indicator:
		var target_x = lerp(-2, 2, recall_score)
		recall_indicator.position.x = lerp(recall_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on recall
		var green_component = 0.8 * recall_score
		var red_component = 0.2 + 0.6 * (1.0 - recall_score)
		recall_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

# ── Public API ───────────────────────────────────────────────────────────────

func set_recommendation_progress(progress: float) -> void:
	recommendation_progress = clamp(progress, 0.0, 1.0)

func set_precision_score(precision: float) -> void:
	precision_score = clamp(precision, 0.0, 1.0)

func set_recall_score(recall: float) -> void:
	recall_score = clamp(recall, 0.0, 1.0)

func get_recommendation_progress() -> float:
	return recommendation_progress

func get_precision_score() -> float:
	return precision_score

func get_recall_score() -> float:
	return recall_score

func reset_recommendation() -> void:
	time = 0.0
	recommendation_progress = 0.0
	precision_score = 0.0
	recall_score = 0.0
	# Animate reset with a tween pulse on the engine
	var engine_core = $RecommendationEngine/EngineCore
	if engine_core:
		var tween = create_tween()
		tween.tween_property(engine_core, "scale", Vector3.ONE * 1.5, 0.15)
		tween.tween_property(engine_core, "scale", Vector3.ONE, 0.3)

# ── Stats Label & Visual Feedback ────────────────────────────────────────────

func _create_stats_label() -> void:
	## Creates a floating 3D label that shows live recommendation stats
	_stats_label = Label3D.new()
	_stats_label.text = "Initializing..."
	_stats_label.font_size = 48
	_stats_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	_stats_label.outline_modulate = Color(0, 0, 0, 0.8)
	_stats_label.outline_size = 8
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.position = Vector3(0, 4.5, 0)
	_stats_label.no_depth_test = true
	add_child(_stats_label)

func _update_stats_label() -> void:
	if _stats_label:
		_stats_label.text = "Recommendation Systems\nProgress: %d%%  |  Precision: %.0f%%  |  Recall: %.0f%%" % [
			recommendation_progress * 100,
			precision_score * 100,
			recall_score * 100
		]

func _on_progress_changed() -> void:
	## Visual feedback when progress changes — pulse the engine core with gold glow
	var engine_core = $RecommendationEngine/EngineCore
	if engine_core and engine_core.material_override:
		var tween = create_tween()
		tween.tween_property(engine_core.material_override, "emission",
			Color(1.0, 0.85, 0.2) * 1.5, 0.15)
		tween.tween_property(engine_core.material_override, "emission",
			Color(0.3, 0.85, 0.4) * (0.3 + recommendation_progress * 0.7), 0.3)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
