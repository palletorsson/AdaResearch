# visualization.gd
class_name Visualization
extends Node3D

signal visualization_mode_changed(mode)
signal entity_highlighted(entity)
signal visual_effect_created(effect_type, location, duration)

# Configuration
@export_category("Visualization Parameters")
@export var enable_entity_highlighting: bool = true
@export var enable_connection_visualization: bool = true
@export var enable_trajectory_visualization: bool = true
@export var enable_resource_visualization: bool = true
@export var enable_boundary_visualization: bool = true
@export var enable_event_visualization: bool = true
@export var detail_level: int = 2  # 1=low, 2=medium, 3=high
@export var color_scheme: String = "default"  # default, vibrant, pastel, monochrome
@export var apply_post_processing: bool = true
@export var visualization_scale: float = 1.0

# Visualization containers
var entity_visuals: Node3D
var connection_visuals: Node3D
var resource_visuals: Node3D
var boundary_visuals: Node3D
var event_visuals: Node3D
var trajectory_visuals: Node3D
var current_effects: Node3D
var ui_elements: Node3D

# Visualization state
var current_mode: String = "default"
var highlighted_entities: Array = []
var entity_visual_cache: Dictionary = {}
var resource_visual_cache: Dictionary = {}
var active_effects: Array = []
var time_scale: float = 1.0
var entity_history: Dictionary = {}  # entity -> array of historical positions
var history_length: int = 50  # Number of positions to keep in history

# Color palettes for different schemes
var color_palettes = {
	"default": {
		"entity": {
			"default": Color(0.3, 0.5, 0.8),
			"highlighted": Color(0.9, 0.7, 0.2),
			"selected": Color(0.9, 0.2, 0.2)
		},
		"resource": {
			"energy": Color(0.9, 0.8, 0.2),
			"material": Color(0.2, 0.6, 0.9),
			"information": Color(0.9, 0.2, 0.9),
			"essence": Color(0.5, 0.9, 0.5)
		},
		"connection": {
			"kinship": Color(0.2, 0.8, 0.2),
			"alliance": Color(0.2, 0.2, 0.8),
			"romantic": Color(0.8, 0.2, 0.2),
			"creative": Color(0.8, 0.2, 0.8),
			"default": Color(0.7, 0.7, 0.7)
		},
		"boundary": {
			"physical": Color(0.2, 0.2, 0.8),
			"relational": Color(0.8, 0.2, 0.2),
			"cognitive": Color(0.2, 0.8, 0.2),
			"expressive": Color(0.8, 0.8, 0.2),
			"default": Color(0.5, 0.5, 0.5)
		},
		"event": {
			"celebration": Color(0.9, 0.7, 0.2),
			"challenge": Color(0.9, 0.2, 0.2),
			"transformation": Color(0.2, 0.2, 0.9),
			"default": Color(0.7, 0.7, 0.7)
		},
		"background": Color(0.05, 0.05, 0.1)
	},
	"vibrant": {
		# More saturated colors
		"entity": {
			"default": Color(0.2, 0.6, 1.0),
			"highlighted": Color(1.0, 0.8, 0.0),
			"selected": Color(1.0, 0.0, 0.0)
		},
		"resource": {
			"energy": Color(1.0, 0.9, 0.0),
			"material": Color(0.0, 0.8, 1.0),
			"information": Color(1.0, 0.0, 1.0),
			"essence": Color(0.3, 1.0, 0.3)
		},
		# Additional colors for other categories...
		"background": Color(0.0, 0.0, 0.2)
	},
	"pastel": {
		# Softer, desaturated colors
		"entity": {
			"default": Color(0.6, 0.8, 0.9),
			"highlighted": Color(0.9, 0.8, 0.6),
			"selected": Color(0.9, 0.6, 0.6)
		},
		# Additional colors...
		"background": Color(0.9, 0.9, 0.95)
	},
	"monochrome": {
		# Various shades of a single hue
		"entity": {
			"default": Color(0.5, 0.5, 0.5),
			"highlighted": Color(0.8, 0.8, 0.8),
			"selected": Color(0.2, 0.2, 0.2)
		},
		# Additional shades...
		"background": Color(0.1, 0.1, 0.1)
	}
}

# Visualization modes
var visualization_modes = [
	"default",
	"trait_heatmap",
	"relationship_network",
	"resource_flow",
	"boundary_field",
	"entropy_visualization",
	"historical_trajectories"
]

func _ready():
	# Create containers for different visual elements
	entity_visuals = Node3D.new()
	entity_visuals.name = "EntityVisuals"
	add_child(entity_visuals)
	
	connection_visuals = Node3D.new()
	connection_visuals.name = "ConnectionVisuals"
	add_child(connection_visuals)
	
	resource_visuals = Node3D.new()
	resource_visuals.name = "ResourceVisuals"
	add_child(resource_visuals)
	
	boundary_visuals = Node3D.new()
	boundary_visuals.name = "BoundaryVisuals"
	add_child(boundary_visuals)
	
	event_visuals = Node3D.new()
	event_visuals.name = "EventVisuals"
	add_child(event_visuals)
	
	trajectory_visuals = Node3D.new()
	trajectory_visuals.name = "TrajectoryVisuals"
	add_child(trajectory_visuals)
	
	current_effects = Node3D.new()
	current_effects.name = "CurrentEffects"
	add_child(current_effects)
	
	ui_elements = Node3D.new()
	ui_elements.name = "UIElements"
	add_child(ui_elements)
	
	# Initialize visualization
	_setup_post_processing()

func _process(delta):
	# Update visualizations
	_update_entity_visuals(delta)
	_update_connection_visuals(delta)
	_update_trajectory_visuals(delta)
	_update_active_effects(delta)
	
	# Update entity history for trajectory visualization
	if enable_trajectory_visualization:
		_update_entity_histories(delta)

func add_entity_visualization(entity: Object):
	# Check if we're already tracking this entity
	if entity_visual_cache.has(entity):
		return entity_visual_cache[entity]
	
	# Create visual representation based on entity form
	var visual = Node3D.new()
	visual.name = "EntityVisual_" + entity.name
	
	# Try to get entity form data
	var form_data = {}
	if entity.has_method("get_info"):
		var info = entity.get_info()
		if info.has("form"):
			form_data = info.form
	
	# If no form data, create simple representation
	if form_data.is_empty():
		_create_default_entity_visual(visual, entity)
	else:
		# This would use form data to create a more complex visual
		# For this simplified version, still use default
		_create_default_entity_visual(visual, entity)
	
	# Add to visuals container
	entity_visuals.add_child(visual)
	
	# Cache the visual
	entity_visual_cache[entity] = visual
	
	# Start tracking history
	entity_history[entity] = []
	
	return visual

func _create_default_entity_visual(visual: Node3D, entity: Object):
	# Create a simple sphere to represent the entity
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "DefaultMesh"
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh_instance.mesh = sphere
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = get_color_for_entity(entity)
	material.metallic = 0.3
	material.roughness = 0.6
	
	mesh_instance.material_override = material
	
	visual.add_child(mesh_instance)
	
	# Add label with entity name
	var label = Label3D.new()
	label.name = "EntityLabel"
	label.text = entity.name
	label.font_size = 12
	label.pixel_size = 0.01
	label.billboard = true
	label.position = Vector3(0, 1.0, 0)
	
	visual.add_child(label)

func update_entity_visualization(entity: Object):
	# Get the existing visual
	if not entity_visual_cache.has(entity):
		return add_entity_visualization(entity)
	
	var visual = entity_visual_cache[entity]
	
	# Update position
	visual.global_position = entity.global_position
	
	# Check if entity has form data and update visual accordingly
	if entity.has_method("get_info"):
		var info = entity.get_info()
		
		if info.has("form") and not info.form.is_empty():
			# This would update the visual based on form
			# For this simplified version, just update material
			var mesh_instance = visual.get_node("DefaultMesh")
			if mesh_instance:
				var material = mesh_instance.material_override
				
				# Check if entity is highlighted
				if highlighted_entities.has(entity):
					material.albedo_color = get_color_from_palette("entity", "highlighted")
				else:
					material.albedo_color = get_color_for_entity(entity)
	
	return visual

func remove_entity_visualization(entity: Object):
	if entity_visual_cache.has(entity):
		var visual = entity_visual_cache[entity]
		
		# Remove from scene
		visual.queue_free()
		
		# Remove from cache
		entity_visual_cache.erase(entity)
	
	# Remove from history tracking
	if entity_history.has(entity):
		entity_history.erase(entity)

func add_resource_visualization(resource: Object):
	# Check if we're already tracking this resource
	if resource_visual_cache.has(resource):
		return resource_visual_cache[resource]
	
	# Create visual representation
	var visual = Node3D.new()
	visual.name = "ResourceVisual_" + resource.name
	
	# Create mesh based on resource type
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ResourceMesh"
	
	var mesh: Mesh
	var resource_type = "energy"  # Default
	
	if resource.has("type"):
		resource_type = resource.type
	
	match resource_type:
		"energy":
			mesh = SphereMesh.new()
			mesh.radius = 0.3
			mesh.height = 0.6
		"material":
			mesh = BoxMesh.new()
			mesh.size = Vector3(0.5, 0.5, 0.5)
		"information":
			mesh = TorusMesh.new()
			mesh.inner_radius = 0.2
			mesh.outer_radius = 0.4
		"essence":
			mesh = PrismMesh.new()
			mesh.size = Vector3(0.4, 0.6, 0.4)
	
	mesh_instance.mesh = mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = get_color_from_palette("resource", resource_type)
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy = 0.5
	
	mesh_instance.material_override = material
	
	visual.add_child(mesh_instance)
	
	# Add to visuals container
	resource_visuals.add_child(visual)
	
	# Cache the visual
	resource_visual_cache[resource] = visual
	
	return visual

func update_resource_visualization(resource: Object):
	# Get the existing visual
	if not resource_visual_cache.has(resource):
		return add_resource_visualization(resource)
	
	var visual = resource_visual_cache[resource]
	
	# Update position
	visual.global_position = resource.global_position
	
	# Update scale based on value if available
	if resource.has("value") and resource.has("max_value"):
		var scale_factor = resource.value / resource.max_value
		visual.scale = Vector3.ONE * scale_factor
	
	return visual

func remove_resource_visualization(resource: Object):
	if resource_visual_cache.has(resource):
		var visual = resource_visual_cache[resource]
		
		# Remove from scene
		visual.queue_free()
		
		# Remove from cache
		resource_visual_cache.erase(resource)

func create_connection_visualization(entity1: Object, entity2: Object, type: String, strength: float):
	# Don't create if connection visualization is disabled
	if not enable_connection_visualization:
		return null
	
	# Calculate connection key to avoid duplicates
	var key = _get_connection_key(entity1, entity2)
	
	# Remove existing connection if any
	for child in connection_visuals.get_children():
		if child.name == "Connection_" + key:
			child.queue_free()
			break
	
	# Create new connection visual
	var visual = Node3D.new()
	visual.name = "Connection_" + key
	
	# Create line between entities
	var line = MeshInstance3D.new()
	line.name = "ConnectionLine"
	
	# Calculate positions
	var start_pos = entity1.global_position
	var end_pos = entity2.global_position
	var center_pos = (start_pos + end_pos) / 2
	var length = start_pos.distance_to(end_pos)
	
	# Create mesh
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.05 * strength
	mesh.bottom_radius = 0.05 * strength
	mesh.height = length
	line.mesh = mesh
	
	# Position and orient line
	line.global_position = center_pos
	line.look_at_from_position(center_pos, end_pos, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI/2)
	
	# Create material
	var material = StandardMaterial3D.new()
	var connection_color = get_color_from_palette("connection", type)
	material.albedo_color = connection_color
	material.albedo_color.a = 0.7 * strength
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = connection_color
	material.emission_energy = 0.5 * strength
	line.material_override = material
	
	visual.add_child(line)
	connection_visuals.add_child(visual)
	
	return visual

func update_connection_visualization(entity1: Object, entity2: Object, type: String, strength: float):
	# Don't update if connection visualization is disabled
	if not enable_connection_visualization:
		return null
	
	# Get connection key
	var key = _get_connection_key(entity1, entity2)
	var visual: Node3D = null
	
	# Find existing connection
	for child in connection_visuals.get_children():
		if child.name == "Connection_" + key:
			visual = child
			break
	
	# If not found, create new
	if visual == null:
		return create_connection_visualization(entity1, entity2, type, strength)
	
	# Update existing connection
	var line = visual.get_node("ConnectionLine")
	if not line:
		return null
	
	# Calculate positions
	var start_pos = entity1.global_position
	var end_pos = entity2.global_position
	var center_pos = (start_pos + end_pos) / 2
	var length = start_pos.distance_to(end_pos)
	
	# Update mesh
	var mesh = line.mesh
	mesh.top_radius = 0.05 * strength
	mesh.bottom_radius = 0.05 * strength
	mesh.height = length
	
	# Update position and orientation
	line.global_position = center_pos
	line.look_at_from_position(center_pos, end_pos, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI/2)
	
	# Update material
	var material = line.material_override
	var connection_color = get_color_from_palette("connection", type)
	material.albedo_color = connection_color
	material.albedo_color.a = 0.7 * strength
	material.emission = connection_color
	material.emission_energy = 0.5 * strength
	
	return visual

func remove_connection_visualization(entity1: Object, entity2: Object):
	if not enable_connection_visualization:
		return
	
	# Get connection key
	var key = _get_connection_key(entity1, entity2)
	
	# Find and remove connection
	for child in connection_visuals.get_children():
		if child.name == "Connection_" + key:
			child.queue_free()
			break

func create_boundary_visualization(boundary: Object):
	# Don't create if boundary visualization is disabled
	if not enable_boundary_visualization:
		return null
	
	# Create boundary visual
	var visual = Node3D.new()
	visual.name = "BoundaryVisual_" + boundary.name
	
	# Create sphere to represent boundary
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "BoundaryMesh"
	
	var sphere = SphereMesh.new()
	sphere.radius = boundary.radius if boundary.has("radius") else 5.0
	sphere.height = sphere.radius * 2
	mesh_instance.mesh = sphere
	
	# Create material
	var material = StandardMaterial3D.new()
	
	# Get boundary type
	var boundary_type = "default"
	if boundary.has("type"):
		boundary_type = boundary.type
	
	var boundary_color = get_color_from_palette("boundary", boundary_type)
	var boundary_strength = boundary.strength if boundary.has("strength") else 0.7
	
	material.albedo_color = Color(boundary_color.r, boundary_color.g, boundary_color.b, 0.3 * boundary_strength)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = boundary_color
	material.emission_energy = 0.3 * boundary_strength
	
	mesh_instance.material_override = material
	
	visual.add_child(mesh_instance)
	visual.global_position = boundary.position if boundary.has("position") else Vector3.ZERO
	
	boundary_visuals.add_child(visual)
	
	return visual

func update_boundary_visualization(boundary: Object, visual: Node3D = null):
	# Don't update if boundary visualization is disabled
	if not enable_boundary_visualization:
		return null
	
	# Find visual if not provided
	if visual == null:
		for child in boundary_visuals.get_children():
			if child.name == "BoundaryVisual_" + boundary.name:
				visual = child
				break
	
	# If still not found, create new
	if visual == null:
		return create_boundary_visualization(boundary)
	
	# Update existing boundary visual
	var mesh_instance = visual.get_node("BoundaryMesh")
	if not mesh_instance:
		return null
	
	# Update position
	visual.global_position = boundary.position if boundary.has("position") else Vector3.ZERO
	
	# Update mesh
	var mesh = mesh_instance.mesh
	mesh.radius = boundary.radius if boundary.has("radius") else 5.0
	mesh.height = mesh.radius * 2
	
	# Update material
	var material = mesh_instance.material_override
	
	# Get boundary type
	var boundary_type = "default"
	if boundary.has("type"):
		boundary_type = boundary.type
	
	var boundary_color = get_color_from_palette("boundary", boundary_type)
	var boundary_strength = boundary.strength if boundary.has("strength") else 0.7
	
	material.albedo_color = Color(boundary_color.r, boundary_color.g, boundary_color.b, 0.3 * boundary_strength)
	material.emission = boundary_color
	material.emission_energy = 0.3 * boundary_strength
	
	return visual

func remove_boundary_visualization(boundary: Object):
	if not enable_boundary_visualization:
		return
	
	# Find and remove boundary visual
	for child in boundary_visuals.get_children():
		if child.name == "BoundaryVisual_" + boundary.name:
			child.queue_free()
			break

func create_event_visualization(event_type: String, location: Vector3, parameters: Dictionary = {}):
	# Don't create if event visualization is disabled
	if not enable_event_visualization:
		return null
	
	# Create unique ID for this event
	var event_id = str(Time.get_ticks_msec()) + "_" + event_type
	
	# Create event visual
	var visual = Node3D.new()
	visual.name = "EventVisual_" + event_id
	
	# Set position
	visual.global_position = location
	
	# Get event properties
	var event_color = get_color_from_palette("event", event_type)
	var intensity = parameters.intensity if parameters.has("intensity") else 1.0
	var duration = parameters.duration if parameters.has("duration") else 5.0
	var radius = parameters.radius if parameters.has("radius") else 3.0
	
	# Create visual effect based on event type
	match event_type:
		"celebration", "convergence", "resonance":
			_create_celebration_effect(visual, event_color, intensity, radius)
		"challenge", "boundary_test", "resource_scarcity":
			_create_challenge_effect(visual, event_color, intensity, radius)
		"transformation", "morphic_resonance", "phase_transition":
			_create_transformation_effect(visual, event_color, intensity, radius)
		_:
			# Default effect
			_create_default_event_effect(visual, event_color, intensity, radius)
	
	# Add to event visuals
	event_visuals.add_child(visual)
	
	# Schedule removal after duration
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.autostart = true
	timer.connect("timeout", func(): visual.queue_free())
	visual.add_child(timer)
	
	# Add to active effects
	active_effects.append({
		"visual": visual,
		"type": event_type,
		"start_time": Time.get_ticks_msec(),
		"duration": duration,
		"intensity": intensity,
		"parameters": parameters
	})
	
	# Emit signal
	emit_signal("visual_effect_created", event_type, location, duration)
	
	return visual

func _create_celebration_effect(visual: Node3D, color: Color, intensity: float, radius: float):
	# Create particles for celebration
	var particles = GPUParticles3D.new()
	particles.name = "CelebrationParticles"
	
	# Simplified particle setup
	# In a full implementation, this would set up a proper particle material
	
	# Create pulsing sphere
	var sphere = MeshInstance3D.new()
	sphere.name = "PulsingSphere"
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	sphere.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 0.5 * intensity
	
	sphere.material_override = material
	
	# Create animation to pulse the sphere
	var animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	
	var animation = Animation.new()
	animation.length = 2.0
	animation.loop_mode = Animation.LOOP_LINEAR
	
	# Add track for emission energy
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, NodePath(str(sphere.get_path()) + ":material_override:emission_energy"))
	
	# Add keyframes for pulsing
	animation.track_insert_key(track_idx, 0.0, 0.2 * intensity)
	animation.track_insert_key(track_idx, 1.0, 1.0 * intensity)
	animation.track_insert_key(track_idx, 2.0, 0.2 * intensity)
	
	animation_player.add_animation("pulse", animation)
	animation_player.play("pulse")
	
	visual.add_child(sphere)
	visual.add_child(particles)
	visual.add_child(animation_player)

func _create_challenge_effect(visual: Node3D, color: Color, intensity: float, radius: float):
	# Create spiky sphere for challenge
	var sphere = MeshInstance3D.new()
	sphere.name = "ChallengeSphere"
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	sphere.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 0.5 * intensity
	
	sphere.material_override = material
	
	# Create spikes
	var spike_count = int(10 * intensity)
	for i in range(spike_count):
		var spike = MeshInstance3D.new()
		spike.name = "Spike_" + str(i)
		
		var spike_mesh = CylinderMesh.new()
		spike_mesh.top_radius = 0.0
		spike_mesh.bottom_radius = 0.1
		spike_mesh.height = radius * 0.7
		spike.mesh = spike_mesh
		
		var spike_material = StandardMaterial3D.new()
		spike_material.albedo_color = color
		spike_material.emission_enabled = true
		spike_material.emission = color
		spike_material.emission_energy = 0.7 * intensity
		
		spike.material_override = spike_material
		
		# Position around sphere
		var angle = i * TAU / spike_count
		var spike_dir = Vector3(cos(angle), 0, sin(angle)).normalized()
		spike.position = spike_dir * radius
		
		# Orient spike outward
		spike.look_at_from_position(spike.position, Vector3.ZERO, Vector3.UP)
		spike.rotate_object_local(Vector3.RIGHT, -PI/2)
		
		visual.add_child(spike)
	
	visual.add_child(sphere)
	
	# Create animation for rotating spikes
	var animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	
	var animation = Animation.new()
	animation.length = 4.0
	animation.loop_mode = Animation.LOOP_LINEAR
	
	# Add track for rotation
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, NodePath(str(visual.get_path()) + ":rotation"))
	
	# Add keyframes for rotation
	animation.track_insert_key(track_idx, 0.0, Vector3(0, 0, 0))
	animation.track_insert_key(track_idx, 4.0, Vector3(0, TAU, 0))
	
	animation_player.add_animation("rotate", animation)
	animation_player.play("rotate")
	
	visual.add_child(animation_player)

func _create_transformation_effect(visual: Node3D, color: Color, intensity: float, radius: float):
	# Create morphing effect for transformation
	var torus = MeshInstance3D.new()
	torus.name = "TransformationTorus"
	
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = radius * 0.5
	torus_mesh.outer_radius = radius
	torus.mesh = torus_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 0.5 * intensity
	
	torus.material_override = material
	
	visual.add_child(torus)
	
	# Create particles
	var particles = GPUParticles3D.new()
	particles.name = "TransformationParticles"
	
	# Simplified particle setup
	
	visual.add_child(particles)
	
	# Create animation for morphing torus
	var animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	
	var animation = Animation.new()
	animation.length = 3.0
	animation.loop_mode = Animation.LOOP_LINEAR
	
	# Add track for inner radius
	var track_idx1 = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx1, NodePath(str(torus.get_path()) + ":mesh:inner_radius"))
	
	# Add track for outer radius
	var track_idx2 = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx2, NodePath(str(torus.get_path()) + ":mesh:outer_radius"))
	
	# Add track for rotation
	var track_idx3 = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx3, NodePath(str(torus.get_path()) + ":rotation"))
	
	# Add keyframes for morphing
	animation.track_insert_key(track_idx1, 0.0, radius * 0.5)
	animation.track_insert_key(track_idx1, 1.5, radius * 0.1)
	animation.track_insert_key(track_idx1, 3.0, radius * 0.5)
	
	animation.track_insert_key(track_idx2, 0.0, radius)
	animation.track_insert_key(track_idx2, 1.5, radius * 1.2)
	animation.track_insert_key(track_idx2, 3.0, radius)
	
	animation.track_insert_key(track_idx3, 0.0, Vector3(0, 0, 0))
	animation.track_insert_key(track_idx3, 3.0, Vector3(PI, PI, 0))
	
	animation_player.add_animation("morph", animation)
	animation_player.play("morph")
	
	visual.add_child(animation_player)

func _create_default_event_effect(visual: Node3D, color: Color, intensity: float, radius: float):
	# Create simple pulsing sphere
	var sphere = MeshInstance3D.new()
	sphere.name = "EventSphere"
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	sphere.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 0.5 * intensity
	
	sphere.material_override = material
	
	visual.add_child(sphere)

func _update_entity_visuals(delta: float):
	# Update all entity visuals to match current positions
	for entity in entity_visual_cache.keys():
		update_entity_visualization(entity)

func _update_connection_visuals(delta: float):
	# Connection visuals are updated on demand
	# This function would be used for automatic updates
	pass

func _update_trajectory_visuals(delta: float):
	# Only update if trajectory visualization is enabled
	if not enable_trajectory_visualization:
		return
	
	# Make sure we're in the scene tree before proceeding
	if not is_inside_tree() or not trajectory_visuals or not trajectory_visuals.is_inside_tree():
		return
	
	# Clear existing trajectory lines
	for child in trajectory_visuals.get_children():
		child.queue_free()
	
	# Draw trajectories for each entity
	for entity in entity_history.keys():
		if not entity or not is_instance_valid(entity):
			continue
			
		var history = entity_history[entity]
		
		# Need at least 2 points for a line
		if history.size() < 2:
			continue
		
		# Create line segments
		for i in range(history.size() - 1):
			var start_pos = history[i]
			var end_pos = history[i + 1]
			
			# Skip if positions are too close
			if start_pos.distance_to(end_pos) < 0.1:
				continue
			
			# Create line segment
			var line = MeshInstance3D.new()
			if not is_instance_valid(entity):
				line.name = "TrajectoryLine_Unknown_" + str(i)
			else:
				line.name = "TrajectoryLine_" + entity.name + "_" + str(i)
			
			var mesh = CylinderMesh.new()
			mesh.top_radius = 0.02
			mesh.bottom_radius = 0.02
			mesh.height = start_pos.distance_to(end_pos)
			line.mesh = mesh
			
			# Add the line to the tree first, then position it
			trajectory_visuals.add_child(line)
			
			# Now it's safe to set global properties
			if line.is_inside_tree():
				# Position and orient line
				var center_pos = (start_pos + end_pos) / 2
				line.global_position = center_pos
				line.look_at_from_position(center_pos, end_pos, Vector3.UP)
				line.rotate_object_local(Vector3.RIGHT, PI/2)
				
				# Create material
				var material = StandardMaterial3D.new()
				
				# Fade color based on age
				var age_factor = float(i) / history.size()
				var alpha = (1.0 - age_factor) * 0.5
				
				material.albedo_color = get_color_for_entity(entity)
				material.albedo_color.a = alpha
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				
				line.material_override = material
			else:
				# If the line didn't get added to the tree properly, clean it up
				line.queue_free()

func _update_active_effects(delta: float):
	# Update active visual effects
	for effect in active_effects.duplicate():
		var visual = effect.visual
		
		# If visual was deleted, remove effect
		if not is_instance_valid(visual):
			active_effects.erase(effect)
			continue
		
		# Check if effect has expired
		var elapsed = (Time.get_ticks_msec() - effect.start_time) / 1000.0
		if elapsed >= effect.duration:
			# Effect has expired, will be removed by its own timer
			active_effects.erase(effect)
			continue
		
		# Update effect based on type
		match effect.type:
			"celebration", "convergence", "resonance":
				# Celebration effects might attract nearby entities
				pass
			"challenge", "boundary_test":
				# Challenge effects might repel entities
				pass
			"transformation", "morphic_resonance":
				# Transformation effects might distort space
				pass

func _update_entity_histories(delta: float):
	# Add current positions to history for trajectory visualization
	for entity in entity_visual_cache.keys():
		if not entity_history.has(entity):
			entity_history[entity] = []
		
		# Add current position to history
		entity_history[entity].append(entity.global_position)
		
		# Limit history length
		while entity_history[entity].size() > history_length:
			entity_history[entity].pop_front()

func highlight_entity(entity: Object, is_highlighted: bool = true):
	if not enable_entity_highlighting:
		return
	
	if is_highlighted:
		# Add to highlighted entities if not already there
		if not highlighted_entities.has(entity):
			highlighted_entities.append(entity)
	else:
		# Remove from highlighted entities
		highlighted_entities.erase(entity)
	
	# Update visualization
	update_entity_visualization(entity)
	
	# Emit signal
	if is_highlighted:
		emit_signal("entity_highlighted", entity)

func set_visualization_mode(mode: String):
	if visualization_modes.has(mode):
		current_mode = mode
		
		# Update visualizations based on mode
		_apply_visualization_mode()
		
		# Emit signal
		emit_signal("visualization_mode_changed", mode)

func _apply_visualization_mode():
	# Apply different visualization styles based on current mode
	match current_mode:
		"trait_heatmap":
			# Visualization based on entity traits
			for entity in entity_visual_cache.keys():
				var visual = entity_visual_cache[entity]
				
				# In a full implementation, this would change visual properties
				# based on entity traits
				pass
		
		"relationship_network":
			# Highlight connections
			connection_visuals.visible = true
			
			# In a full implementation, this would modify connection
			# visuals to emphasize network structure
			pass
		
		"resource_flow":
			# Highlight resources and their movement
			resource_visuals.visible = true
			
			# In a full implementation, this would add flow
			# visualization between resources and entities
			pass
		
		"boundary_field":
			# Emphasize boundaries
			boundary_visuals.visible = true
			
			# In a full implementation, this would modify boundary
			# visuals to show field strength
			pass
		
		"entropy_visualization":
			# Show entropy effects
			
			# In a full implementation, this would add visual
			# distortions based on local entropy
			pass
		
		"historical_trajectories":
			# Show entity movement history
			trajectory_visuals.visible = true
			
			# This is handled by _update_trajectory_visuals
			pass
		
		_:  # default
			# Reset to standard visualization
			entity_visuals.visible = true
			connection_visuals.visible = enable_connection_visualization
			resource_visuals.visible = enable_resource_visualization
			boundary_visuals.visible = enable_boundary_visualization
			event_visuals.visible = enable_event_visualization
			trajectory_visuals.visible = enable_trajectory_visualization

func get_color_for_entity(entity: Object) -> Color:
	# Get color based on entity traits
	var color = get_color_from_palette("entity", "default")
	
	# In a full implementation, this would adjust color based
	# on entity traits, form, etc.
	
	return color

func get_color_from_palette(category: String, key: String) -> Color:
	var palette = color_palettes[color_scheme]
	
	if palette.has(category):
		var category_colors = palette[category]
		
		if category_colors.has(key):
			return category_colors[key]
		elif category_colors.has("default"):
			return category_colors["default"]
	
	# Fallback color
	return Color(0.7, 0.7, 0.7)

func _get_connection_key(entity1: Object, entity2: Object) -> String:
	# Create a consistent key for a connection between two entities
	var id1 = entity1.get_instance_id()
	var id2 = entity2.get_instance_id()
	
	# Order IDs to ensure consistency
	if id1 < id2:
		return str(id1) + "_" + str(id2)
	else:
		return str(id2) + "_" + str(id1)

func _setup_post_processing():
	# Set up post-processing effects
	if not apply_post_processing:
		return
	
	# In a full implementation, this would setup screen-space
	# effects like bloom, color correction, etc.
	
	pass

func set_color_scheme(scheme: String):
	if color_palettes.has(scheme):
		color_scheme = scheme
		
		# Update all visuals to use new color scheme
		# In a full implementation, this would iterate through
		# all visual elements and update their colors
		
		# For now, just set background color
		var environment = get_viewport().world_3d.environment
		if environment:
			environment.background_color = color_palettes[scheme].background

func set_detail_level(level: int):
	detail_level = clamp(level, 1, 3)
	
	# Adjust detail level of all visualizations
	# In a full implementation, this would modify mesh complexity,
	# particle counts, etc.

func set_visualization_scale(scale: float):
	visualization_scale = clamp(scale, 0.1, 2.0)
	
	# Scale all visualization elements
	# In a full implementation, this would adjust the size of
	# visual elements without affecting the actual entities
