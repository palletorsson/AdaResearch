# boundary_system.gd
class_name BoundarySystem
extends Node3D

signal boundary_created(boundary_type, location, strength)
signal boundary_challenged(entity, boundary_type, success)
signal boundary_transformed(boundary_type, new_type, location)
signal boundary_dissolved(boundary_type, location, entities)

# Configuration
@export_category("Boundary Parameters")
@export var boundary_visibility: float = 0.5  # 0 = invisible, 1 = fully visible
@export var entropy_influence: float = 1.0
@export var challenge_difficulty_base: float = 0.5
@export var boundary_decay_rate: float = 0.01
@export var enable_dynamic_boundaries: bool = true
@export var boundary_visuals_enabled: bool = true

# Boundary types with properties
var boundary_types = {
	"physical": {
		"color": Color(0.2, 0.2, 0.8),
		"permeability": 0.3,
		"stability": 0.8,
		"trait_requirement": "mobility",
		"challenge_traits": ["fluidity", "boundary_pushing"]
	},
	"relational": {
		"color": Color(0.8, 0.2, 0.2),
		"permeability": 0.5,
		"stability": 0.6,
		"trait_requirement": "sociality",
		"challenge_traits": ["uniqueness", "sociality"]
	},
	"cognitive": {
		"color": Color(0.2, 0.8, 0.2),
		"permeability": 0.4,
		"stability": 0.7,
		"trait_requirement": "adaptability",
		"challenge_traits": ["adaptability", "fluidity"]
	},
	"expressive": {
		"color": Color(0.8, 0.8, 0.2),
		"permeability": 0.6,
		"stability": 0.5,
		"trait_requirement": "expressiveness",
		"challenge_traits": ["expressiveness", "uniqueness"]
	}
}

# State
var boundaries: Array = []
var current_entropy: float = 0.0
var boundary_visuals: Node3D
var challenge_results: Dictionary = {}

# Boundary class
class Boundary:
	var type: String
	var position: Vector3
	var radius: float
	var strength: float
	var permeability: float
	var stability: float
	var visual: Node3D
	var creation_time: int
	var last_challenge_time: int = 0
	var challenges: Array = []
	var entities_within: Array = []
	var properties: Dictionary = {}
	
	func _init(b_type: String, pos: Vector3, rad: float, str: float, perm: float, stab: float):
		type = b_type
		position = pos
		radius = rad
		strength = str
		permeability = perm
		stability = stab
		creation_time = Time.get_ticks_msec()
	
	func is_point_inside(point: Vector3) -> bool:
		return position.distance_to(point) <= radius
	
	func get_challenge_difficulty(entity: Object) -> float:
		# Calculate difficulty based on strength, stability and entity traits
		var base_difficulty = strength * (1.0 - permeability)
		
		# Consider time since last challenge
		var time_factor = 1.0
		if last_challenge_time > 0:
			var time_since_last = (Time.get_ticks_msec() - last_challenge_time) / 1000.0  # seconds
			time_factor = min(1.0, time_since_last / 300.0)  # Easier if recently challenged
		
		return base_difficulty * time_factor
	
	func register_challenge(entity: Object, success: bool, impact: float):
		last_challenge_time = Time.get_ticks_msec()
		
		challenges.append({
			"entity": entity,
			"time": last_challenge_time,
			"success": success,
			"impact": impact
		})
		
		# If challenge was successful, reduce strength
		if success:
			strength = max(0.1, strength - impact * 0.2)
			permeability = min(0.9, permeability + impact * 0.1)

	func update(delta: float, decay_rate: float):
		# Apply decay over time
		strength = max(0.1, strength - decay_rate * delta * (1.0 - stability))
		
		# If strength gets too low, boundary can dissolve
		return strength > 0.1

func _ready():
	# Create container for boundary visuals
	boundary_visuals = Node3D.new()
	boundary_visuals.name = "BoundaryVisuals"
	add_child(boundary_visuals)

func create_boundary(type: String, position: Vector3, radius: float, strength: float = 0.8):
	# Make sure type is valid
	if not boundary_types.has(type):
		print("Warning: Invalid boundary type: " + type)
		return null
	
	# Get boundary properties
	var properties = boundary_types[type]
	
	# Create boundary
	var boundary = Boundary.new(
		type,
		position,
		radius,
		strength,
		properties.permeability,
		properties.stability
	)
	
	# Create visual representation if enabled
	if boundary_visuals_enabled:
		_create_boundary_visual(boundary)
	
	# Add to tracking
	boundaries.append(boundary)
	
	# Emit signal
	emit_signal("boundary_created", type, position, strength)
	
	return boundary

func _create_boundary_visual(boundary: Boundary):
	var visual = Node3D.new()
	visual.name = "Boundary_" + boundary.type
	visual.position = boundary.position
	
	# Create sphere to represent boundary
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "BoundaryMesh"
	
	var sphere = SphereMesh.new()
	sphere.radius = boundary.radius
	sphere.height = boundary.radius * 2
	mesh_instance.mesh = sphere
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = boundary_types[boundary.type].color
	material.albedo_color.a = boundary_visibility * boundary.strength
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = boundary_types[boundary.type].color
	material.emission_energy = 0.5 * boundary.strength
	
	mesh_instance.material_override = material
	
	visual.add_child(mesh_instance)
	boundary_visuals.add_child(visual)
	
	boundary.visual = visual

func update_boundary_visuals(boundary: Boundary):
	if not boundary_visuals_enabled or not boundary.visual:
		return
	
	# Update visual properties based on boundary state
	var mesh_instance = boundary.visual.get_node("BoundaryMesh")
	if not mesh_instance:
		return
	
	var material = mesh_instance.material_override
	
	# Update color alpha based on strength
	var color = boundary_types[boundary.type].color
	material.albedo_color = Color(color.r, color.g, color.b, boundary_visibility * boundary.strength)
	
	# Update emission based on strength
	material.emission_energy = 0.5 * boundary.strength
	
	# Adjust sphere size
	var mesh = mesh_instance.mesh
	mesh.radius = boundary.radius
	mesh.height = boundary.radius * 2

func update(delta: float):
	# Update all boundaries
	for boundary in boundaries.duplicate():  # Duplicate to safely modify during iteration
		if not boundary.update(delta, boundary_decay_rate):
			# Boundary has dissolved
			_dissolve_boundary(boundary)
			continue
		
		# Update visuals
		if boundary_visuals_enabled:
			update_boundary_visuals(boundary)
	
	# If dynamic boundaries are enabled, potentially create new ones
	if enable_dynamic_boundaries:
		_consider_creating_dynamic_boundary(delta)

func _dissolve_boundary(boundary: Boundary):
	# Remove boundary
	boundaries.erase(boundary)
	
	# Remove visual
	if boundary.visual:
		boundary.visual.queue_free()
	
	# Emit signal
	emit_signal("boundary_dissolved", boundary.type, boundary.position, boundary.entities_within)

func _consider_creating_dynamic_boundary(delta: float):
	# Random chance to create a new boundary
	# More likely with higher entropy
	var creation_chance = 0.0001 * delta * (1.0 + current_entropy * 3.0)
	
	if randf() < creation_chance:
		# Choose random type
		var types = boundary_types.keys()
		var type = types[randi() % types.size()]
		
		# Choose random position
		var bounds = 40.0  # Assume environment is roughly this size
		var position = Vector3(
			randf_range(-bounds/2, bounds/2),
			randf_range(0.5, 5),
			randf_range(-bounds/2, bounds/2)
		)
		
		# Random radius and strength
		var radius = randf_range(3, 10)
		var strength = randf_range(0.4, 0.8)
		
		# Create the boundary
		create_boundary(type, position, radius, strength)

func challenge_boundary(entity: Object, boundary_type: String, entropy_level: float = 0.0) -> Dictionary:
	# Find a relevant boundary to challenge
	var target_boundary = null
	var entity_pos = entity.global_position
	
	# First try to find a boundary of the specified type that the entity is inside
	for boundary in boundaries:
		if boundary.type == boundary_type and boundary.is_point_inside(entity_pos):
			target_boundary = boundary
			break
	
	# If not found, try any boundary of the specified type
	if target_boundary == null:
		for boundary in boundaries:
			if boundary.type == boundary_type:
				target_boundary = boundary
				break
	
	# If still not found, return failure
	if target_boundary == null:
		return {
			"success": false,
			"message": "No such boundary found",
			"impact": 0.0
		}
	
	# Calculate challenge difficulty
	var difficulty = target_boundary.get_challenge_difficulty(entity)
	difficulty = difficulty * challenge_difficulty_base
	
	# Calculate entity's capability to challenge based on traits
	var capability = 0.0
	
	# In a full implementation, you would access entity traits here
	if entity.has_method("get_info"):
		var info = entity.get_info()
		
		if info.has("traits"):
			var traits = info.traits
			
			# Get relevant traits for this boundary type
			var challenge_traits = boundary_types[boundary_type].challenge_traits
			
			# Calculate average of relevant traits
			var trait_sum = 0.0
			var trait_count = 0
			
			for trait_name in challenge_traits:
				if traits.has(trait_name):
					trait_sum += traits[trait_name]
					trait_count += 1
			
			if trait_count > 0:
				capability = trait_sum / trait_count
	
	# Entropy boost
	var entropy_boost = entropy_level * entropy_influence * 0.2
	capability += entropy_boost
	
	# Random factor
	var random_factor = randf_range(-0.1, 0.2)
	
	# Final success calculation
	var success_value = capability - difficulty + random_factor
	var success = success_value > 0
	
	# Impact is based on how significant the success/failure was
	var impact = abs(success_value) * 0.5 + 0.3
	
	# Register the challenge with the boundary
	target_boundary.register_challenge(entity, success, impact)
	
	# Store challenge result
	var result = {
		"success": success,
		"boundary": target_boundary,
		"difficulty": difficulty,
		"capability": capability,
		"impact": impact,
		"message": "Challenge " + ("succeeded" if success else "failed")
	}
	
	# Store in challenge history
	if not challenge_results.has(entity):
		challenge_results[entity] = []
	challenge_results[entity].append(result)
	
	# Emit signal
	emit_signal("boundary_challenged", entity, boundary_type, success)
	
	return result

func transform_boundary(boundary: Boundary, new_type: String) -> bool:
	# Transform a boundary to a new type
	if not boundary_types.has(new_type):
		return false
	
	var old_type = boundary.type
	boundary.type = new_type
	
	# Update properties based on new type
	var properties = boundary_types[new_type]
	boundary.permeability = properties.permeability
	boundary.stability = properties.stability
	
	# Update visual
	if boundary_visuals_enabled and boundary.visual:
		var mesh_instance = boundary.visual.get_node("BoundaryMesh")
		if mesh_instance:
			var material = mesh_instance.material_override
			material.albedo_color = properties.color
			material.albedo_color.a = boundary_visibility * boundary.strength
			material.emission = properties.color
	
	# Emit signal
	emit_signal("boundary_transformed", old_type, new_type, boundary.position)
	
	return true

func get_boundaries_of_type(type: String) -> Array:
	var result = []
	for boundary in boundaries:
		if boundary.type == type:
			result.append(boundary)
	return result

func get_boundaries_in_radius(position: Vector3, radius: float) -> Array:
	var result = []
	for boundary in boundaries:
		if position.distance_to(boundary.position) <= radius:
			result.append(boundary)
	return result

func get_boundary_at_position(position: Vector3) -> Boundary:
	for boundary in boundaries:
		if boundary.is_point_inside(position):
			return boundary
	return null

func set_entropy(value: float):
	current_entropy = clamp(value, 0.0, 1.0)

func get_boundary_types() -> Array:
	return boundary_types.keys()

func get_entity_challenge_history(entity: Object) -> Array:
	if challenge_results.has(entity):
		return challenge_results[entity].duplicate()
	return []

func set_boundary_visibility(value: float):
	boundary_visibility = clamp(value, 0.0, 1.0)
	
	# Update all boundary visuals
	for boundary in boundaries:
		update_boundary_visuals(boundary)
