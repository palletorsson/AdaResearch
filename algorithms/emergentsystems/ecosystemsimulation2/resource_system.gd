# resource_system.gd
class_name ResourceSystem
extends Node3D

signal resource_spawned(resource)
signal resource_consumed(resource, entity, amount)
signal resource_depleted(resource_type, location)
signal resource_transformed(resource, new_type)

# Configuration
@export_category("Resource Parameters")
@export var energy_resource_color: Color = Color(0.9, 0.8, 0.2)
@export var material_resource_color: Color = Color(0.2, 0.6, 0.9)
@export var information_resource_color: Color = Color(0.9, 0.2, 0.9)
@export var essence_resource_color: Color = Color(0.5, 0.9, 0.5)
@export var resource_decay_rate: float = 0.01
@export var transformation_probability: float = 0.02
@export var resource_scale_range: Vector2 = Vector2(0.3, 1.2)
@export var spawn_radius: float = 25.0

# Resource tracking
var resources: Array = []
var resource_quadrants = {}  # Spatial partitioning for faster lookup
var quadrant_size: float = 10.0
var resource_flow_connections: Array = []
var resource_node: Node3D

# Season influences
var season_modifiers = {
	0: {"energy": 1.2, "material": 1.0, "information": 0.8, "essence": 1.1}, # Spring
	1: {"energy": 1.5, "material": 0.7, "information": 1.0, "essence": 0.8}, # Summer
	2: {"energy": 0.8, "material": 1.3, "information": 1.2, "essence": 1.0}, # Autumn
	3: {"energy": 0.5, "material": 0.9, "information": 1.4, "essence": 0.7}  # Winter
}

# Resource classes
class EcosystemResource extends Node3D:
	var type: String
	var subtype: String
	var value: float
	var decay_rate: float
	var is_flowing: bool
	var flow_path: Array
	var flow_speed: float
	var flow_progress: float
	var origin_position: Vector3
	var destination_position: Vector3
	var max_lifetime: float
	var current_lifetime: float
	var visual: MeshInstance3D
	var is_renewable: bool
	var can_transform: bool
	var affinity_spectrum: Dictionary
	var consumption_effect: Dictionary
	
	func _init():
		name = "EcosystemResource"
	
	func update(delta: float) -> bool:
		# Update lifetime
		current_lifetime -= delta
		if current_lifetime <= 0:
			return false  # Resource depleted
		
		# Handle resource flow if applicable
		if is_flowing and flow_path.size() > 1:
			flow_progress += flow_speed * delta
			if flow_progress >= 1.0:
				# Reached destination
				is_flowing = false
				position = destination_position
			else:
				# Interpolate position along flow path
				var current_segment = int(flow_progress * (flow_path.size() - 1))
				var segment_progress = fmod(flow_progress * (flow_path.size() - 1), 1.0)
				var start_pos = flow_path[current_segment]
				var end_pos = flow_path[current_segment + 1]
				position = start_pos.lerp(end_pos, segment_progress)
		
		# Apply decay
		value -= decay_rate * delta
		if value <= 0:
			return false  # Resource depleted
		
		# Visual update
		if visual:
			var scale_factor = value / max_value
			visual.scale = Vector3.ONE * scale_factor
		
		return true  # Resource still active
	
	# Variables for state
	var max_value: float
	var accumulated_transformations: int = 0
	var interaction_memory: Array = []
	var relationship_to_environment: float = 0.5  # 0 = parasitic, 1 = symbiotic

# Initialization
func _ready():
	# Create resource parent node
	resource_node = Node3D.new()
	resource_node.name = "Resources"
	add_child(resource_node)
	
	# Initialize quadrants
	_initialize_quadrants()

func _initialize_quadrants():
	# Create a spatial partitioning system for faster resource lookup
	# Divide the space into quadrants
	var bounds = 50.0  # Assuming environment is 100x100 centered at origin
	
	for x in range(-int(bounds/quadrant_size), int(bounds/quadrant_size) + 1):
		for z in range(-int(bounds/quadrant_size), int(bounds/quadrant_size) + 1):
			var key = _get_quadrant_key(Vector3(x * quadrant_size, 0, z * quadrant_size))
			resource_quadrants[key] = []

func _get_quadrant_key(position: Vector3) -> String:
	var qx = floor(position.x / quadrant_size)
	var qz = floor(position.z / quadrant_size)
	return str(qx) + "," + str(qz)

func register_resource(resource: EcosystemResource):
	resources.append(resource)
	
	# Add to quadrant
	var quadrant_key = _get_quadrant_key(resource.position)
	if resource_quadrants.has(quadrant_key):
		resource_quadrants[quadrant_key].append(resource)
	
	# Parent to resources node
	resource_node.add_child(resource)
	
	emit_signal("resource_spawned", resource)

func spawn_resource(type: String, position: Vector3, value: float = 1.0):
	var resource = EcosystemResource.new()
	resource.type = type
	resource.position = position
	resource.value = value
	resource.max_value = value
	resource.decay_rate = resource_decay_rate
	resource.is_flowing = false
	resource.current_lifetime = randf_range(60, 180)  # 1-3 minutes lifetime
	resource.max_lifetime = resource.current_lifetime
	resource.is_renewable = randf() < 0.3  # 30% chance of being renewable
	resource.can_transform = randf() < 0.2  # 20% chance of being able to transform
	
	# Create specific properties based on resource type
	match type:
		"energy":
			resource.name = "EnergyResource"
			resource.subtype = _random_energy_subtype()
			resource.consumption_effect = {"energy": 0.2, "health": 0.1}
			_create_energy_visual(resource)
		"material":
			resource.name = "MaterialResource"
			resource.subtype = _random_material_subtype()
			resource.consumption_effect = {"health": 0.15, "energy": 0.05}
			_create_material_visual(resource)
		"information":
			resource.name = "InformationResource"
			resource.subtype = _random_information_subtype()
			resource.consumption_effect = {"adaptation": 0.2, "creativity": 0.1}
			_create_information_visual(resource)
		"essence":
			resource.name = "EssenceResource"
			resource.subtype = _random_essence_subtype()
			resource.consumption_effect = {"transformation": 0.2, "lifespan": 0.1}
			_create_essence_visual(resource)
	
	# Add to tracking
	register_resource(resource)
	
	return resource

func _random_energy_subtype() -> String:
	var subtypes = ["solar", "thermal", "kinetic", "potential", "vibrational"]
	return subtypes[randi() % subtypes.size()]

func _random_material_subtype() -> String:
	var subtypes = ["organic", "crystalline", "fluid", "composite", "metamaterial"]
	return subtypes[randi() % subtypes.size()]

func _random_information_subtype() -> String:
	var subtypes = ["pattern", "memory", "knowledge", "algorithm", "dream"]
	return subtypes[randi() % subtypes.size()]

func _random_essence_subtype() -> String:
	var subtypes = ["creative", "transformative", "connective", "transcendent", "liminal"]
	return subtypes[randi() % subtypes.size()]

func _create_energy_visual(resource: EcosystemResource):
	var visual = MeshInstance3D.new()
	visual.name = "ResourceVisual"
	
	# Create appropriate mesh
	var mesh = SphereMesh.new()
	mesh.radius = 0.3 * resource_scale_range.x + resource.value * (resource_scale_range.y - resource_scale_range.x)
	mesh.height = mesh.radius * 2
	visual.mesh = mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = energy_resource_color
	material.emission_enabled = true
	material.emission = energy_resource_color
	material.emission_energy = 1.5
	visual.material_override = material
	
	# Add visual to resource
	resource.add_child(visual)
	resource.visual = visual
	
	# Add particle effects for energy
	var particles = GPUParticles3D.new()
	particles.name = "EnergyParticles"
	
	# The actual particle setup would go here, but it's simplified for this example
	# In a full implementation, you'd create a particle material and emission shape
	
	resource.add_child(particles)

func _create_material_visual(resource: EcosystemResource):
	var visual = MeshInstance3D.new()
	visual.name = "ResourceVisual"
	
	# Create appropriate mesh based on subtype
	var mesh
	match resource.subtype:
		"organic":
			mesh = SphereMesh.new()
			mesh.radius = 0.4 * resource_scale_range.x + resource.value * (resource_scale_range.y - resource_scale_range.x)
			mesh.height = mesh.radius * 2
		"crystalline":
			mesh = PrismMesh.new()
			var size = 0.4 * resource_scale_range.x + resource.value * (resource_scale_range.y - resource_scale_range.x)
			mesh.size = Vector3(size, size * 1.5, size)
		"fluid":
			mesh = SphereMesh.new()
			mesh.radius = 0.4 * resource_scale_range.x + resource.value * (resource_scale_range.y - resource_scale_range.x)
			mesh.height = mesh.radius * 2
		"composite", "metamaterial":
			mesh = BoxMesh.new()
			var size = 0.4 * resource_scale_range.x + resource.value * (resource_scale_range.y - resource_scale_range.x)
			mesh.size = Vector3(size, size, size)
	
	visual.mesh = mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = material_resource_color
	material.roughness = 0.2
	material.metallic = 0.8
	visual.material_override = material
	
	# Add visual to resource
	resource.add_child(visual)
	resource.visual = visual

func _create_information_visual(resource: EcosystemResource):
	var visual = MeshInstance3D.new()
	visual.name = "ResourceVisual"
	
	# Create torus mesh for information
	var mesh = TorusMesh.new()
	mesh.inner_radius = 0.2 * resource_scale_range.x + resource.value * 0.3 * (resource_scale_range.y - resource_scale_range.x)
	mesh.outer_radius = 0.4 * resource_scale_range.x + resource.value * (resource_scale_range.y - resource_scale_range.x)
	visual.mesh = mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = information_resource_color
	material.emission_enabled = true
	material.emission = information_resource_color * 0.5
	material.emission_energy = 0.8
	material.metallic = 0.2
	material.roughness = 0.4
	visual.material_override = material
	
	# Add visual to resource
	resource.add_child(visual)
	resource.visual = visual

func _create_essence_visual(resource: EcosystemResource):
	var visual = MeshInstance3D.new()
	visual.name = "ResourceVisual"
	
	# Create icosphere for essence
	var mesh = SphereMesh.new()
	mesh.radius = 0.3 * resource_scale_range.x + resource.value * (resource_scale_range.y - resource_scale_range.x)
	mesh.height = mesh.radius * 2
	visual.mesh = mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = essence_resource_color
	material.emission_enabled = true
	material.emission = essence_resource_color
	material.emission_energy = 1.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	visual.material_override = material
	
	# Add visual to resource
	resource.add_child(visual)
	resource.visual = visual
	
	# Add particle effects for essence
	var particles = GPUParticles3D.new()
	particles.name = "EssenceParticles"
	# Simplified particle setup
	resource.add_child(particles)

func update(delta: float, current_day: int):
	# Update all resources
	for resource in resources.duplicate():  # Duplicate array to safely modify during iteration
		var still_active = resource.update(delta)
		
		if !still_active:
			_deplete_resource(resource)
			continue
		
		# Check for resource transformation
		if resource.can_transform and randf() < transformation_probability * delta:
			_transform_resource(resource)
		
		# Check for resource renewal
		if resource.is_renewable and resource.value < resource.max_value * 0.5:
			resource.value += resource.max_value * 0.01 * delta
	
	# Occasionally spawn new resources based on day cycle
	if randf() < 0.02 * delta:  # 2% chance per second
		_spawn_random_resource(current_day)
	
	# Update resource flows
	_update_resource_flows(delta)

func _deplete_resource(resource: EcosystemResource):
	# Remove from tracking
	resources.erase(resource)
	
	# Remove from quadrant
	var quadrant_key = _get_quadrant_key(resource.position)
	if resource_quadrants.has(quadrant_key):
		resource_quadrants[quadrant_key].erase(resource)
	
	# Emit signal
	emit_signal("resource_depleted", resource.type, resource.position)
	
	# Remove from scene
	resource.queue_free()

func _transform_resource(resource: EcosystemResource):
	# Resources can transform to different types over time
	var current_type = resource.type
	var possible_types = ["energy", "material", "information", "essence"]
	possible_types.erase(current_type)
	var new_type = possible_types[randi() % possible_types.size()]
	
	# Record the transformation
	resource.accumulated_transformations += 1
	
	# Transform the resource
	resource.type = new_type
	
	# Update visual representation based on new type
	if resource.visual:
		resource.visual.queue_free()
	
	match new_type:
		"energy":
			resource.subtype = _random_energy_subtype()
			resource.consumption_effect = {"energy": 0.2, "health": 0.1}
			_create_energy_visual(resource)
		"material":
			resource.subtype = _random_material_subtype()
			resource.consumption_effect = {"health": 0.15, "energy": 0.05}
			_create_material_visual(resource)
		"information":
			resource.subtype = _random_information_subtype()
			resource.consumption_effect = {"adaptation": 0.2, "creativity": 0.1}
			_create_information_visual(resource)
		"essence":
			resource.subtype = _random_essence_subtype()
			resource.consumption_effect = {"transformation": 0.2, "lifespan": 0.1}
			_create_essence_visual(resource)
	
	# Emit signal
	emit_signal("resource_transformed", resource, new_type)

func _spawn_random_resource(current_day: int):
	# Calculate probabilities based on day cycle, season, etc.
	var resource_probs = {
		"energy": 0.4,
		"material": 0.3,
		"information": 0.2,
		"essence": 0.1
	}
	
	# Adjust based on day cycle
	# Example: More energy resources during day, more essence at night
	var time_of_day = fmod(current_day, 1.0)  # 0.0 to 1.0
	if time_of_day < 0.5:  # "Day time"
		resource_probs["energy"] *= 1.5
		resource_probs["essence"] *= 0.7
	else:  # "Night time"
		resource_probs["energy"] *= 0.7
		resource_probs["essence"] *= 1.5
	
	# Choose resource type
	var roll = randf()
	var cumulative_prob = 0.0
	var chosen_type = "energy"  # Default
	
	for type in resource_probs:
		cumulative_prob += resource_probs[type]
		if roll <= cumulative_prob:
			chosen_type = type
			break
	
	# Choose spawn position
	var spawn_angle = randf() * TAU
	var spawn_distance = sqrt(randf()) * spawn_radius
	var position = Vector3(
		cos(spawn_angle) * spawn_distance,
		randf_range(0.5, 3.0),
		sin(spawn_angle) * spawn_distance
	)
	
	# Determine value based on spawn distance
	var value = randf_range(0.5, 2.0) * (1.0 - spawn_distance / spawn_radius * 0.5)
	
	# Spawn the resource
	spawn_resource(chosen_type, position, value)

func _update_resource_flows(delta: float):
	# Update all resource flows
	for flow in resource_flow_connections.duplicate():
		flow.time_remaining -= delta
		if flow.time_remaining <= 0:
			resource_flow_connections.erase(flow)

func find_resources_in_radius(position: Vector3, radius: float, type: String = "") -> Array:
	var found_resources = []
	
	# Get all potentially relevant quadrants
	var quadrant_radius = ceil(radius / quadrant_size)
	var center_qx = floor(position.x / quadrant_size)
	var center_qz = floor(position.z / quadrant_size)
	
	for qx in range(center_qx - quadrant_radius, center_qx + quadrant_radius + 1):
		for qz in range(center_qz - quadrant_radius, center_qz + quadrant_radius + 1):
			var key = str(qx) + "," + str(qz)
			if resource_quadrants.has(key):
				for resource in resource_quadrants[key]:
					if position.distance_to(resource.position) <= radius:
						if type == "" or resource.type == type:
							found_resources.append(resource)
	
	return found_resources

func consume_resource(resource: EcosystemResource, entity, amount: float = 0.0) -> float:
	if not resources.has(resource):
		return 0.0
	
	var consumed_amount = min(resource.value, amount if amount > 0 else resource.value)
	resource.value -= consumed_amount
	
	emit_signal("resource_consumed", resource, entity, consumed_amount)
	
	# Check if resource is depleted
	if resource.value <= 0:
		_deplete_resource(resource)
	
	return consumed_amount

func create_resource_flow(start_position: Vector3, end_position: Vector3, resource_type: String, value: float, duration: float = 5.0):
	# Create a flow of resources from one point to another
	var flow = {
		"start": start_position,
		"end": end_position,
		"type": resource_type,
		"value": value,
		"time_remaining": duration,
		"path": [start_position, end_position]  # Simple direct path
	}
	
	resource_flow_connections.append(flow)
	
	# Create a flowing resource
	var resource = spawn_resource(resource_type, start_position, value)
	resource.is_flowing = true
	resource.flow_path = flow.path
	resource.flow_speed = 1.0 / duration
	resource.flow_progress = 0.0
	resource.origin_position = start_position
	resource.destination_position = end_position

func adjust_for_season(season: int):
	# Adjust resource generation based on season
	if season < 0 or season >= season_modifiers.size():
		return
	
	var modifiers = season_modifiers[season]
	
	# Apply seasonal effects to existing resources
	for resource in resources:
		if modifiers.has(resource.type):
			var modifier = modifiers[resource.type]
			
			# Adjust decay rate inversely to availability
			resource.decay_rate = resource_decay_rate / modifier
			
			# For scarce resources in this season, occasionally transform some
			if modifier < 0.8 and randf() < 0.1:
				_transform_resource(resource)

func recycle_entity_resources(position: Vector3, value: float):
	# When an entity expires, it returns resources to the environment
	if value <= 0:
		return
	
	# Distribute the value among different resource types
	var energy_value = value * 0.3
	var material_value = value * 0.4
	var information_value = value * 0.2
	var essence_value = value * 0.1
	
	# Add slight randomization to positions
	var radius = 1.0
	
	if energy_value > 0.1:
		var energy_pos = position + Vector3(
			randf_range(-radius, radius),
			randf_range(0, radius),
			randf_range(-radius, radius)
		)
		spawn_resource("energy", energy_pos, energy_value)
	
	if material_value > 0.1:
		var material_pos = position + Vector3(
			randf_range(-radius, radius),
			randf_range(0, radius),
			randf_range(-radius, radius)
		)
		spawn_resource("material", material_pos, material_value)
	
	if information_value > 0.1:
		var info_pos = position + Vector3(
			randf_range(-radius, radius),
			randf_range(0, radius),
			randf_range(-radius, radius)
		)
		spawn_resource("information", info_pos, information_value)
	
	if essence_value > 0.1:
		var essence_pos = position + Vector3(
			randf_range(-radius, radius),
			randf_range(0, radius),
			randf_range(-radius, radius)
		)
		spawn_resource("essence", essence_pos, essence_value)
