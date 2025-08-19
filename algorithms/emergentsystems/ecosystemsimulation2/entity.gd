# entity.gd
class_name Entity
extends Node3D

signal transformation_requested(entity)
signal expired(entity)
signal boundary_challenge_requested(entity, boundary_type)
signal relationship_formed(entity, other_entity, strength)
signal resource_consumed(entity, resource, amount)

# Configuration parameters
@export_category("Entity Parameters")
@export var energy_consumption_rate: float = 0.1
@export var max_age: int = 100
@export var reproduction_energy_threshold: float = 0.8
@export var transformation_probability: float = 0.05
@export var movement_speed: float = 2.0

# State
var traits: QueerTraits
var age: int = 0
var energy: float = 1.0
var health: float = 1.0
var current_form: Dictionary = {}
var visual_representation: Node3D
var is_transforming: bool = false
var lifespan: int = 0  # Will be set based on traits and randomness
var relationships: Array = []
var current_behavior: String = "idle"
var target_position: Vector3 = Vector3.ZERO
var memory: Dictionary = {}  # Stores experiences and interactions

func _ready():
	# Generate initial lifespan based on traits
	lifespan = int(randf_range(max_age * 0.5, max_age * 1.5) * traits.get_trait("longevity"))
	
	# Initialize with random energy
	energy = randf_range(0.4, 1.0)
	
	# Create visual representation
	_setup_visual_representation()
	
	# Initialize behavior to idle
	_set_behavior("idle")

func _setup_visual_representation():
	# The visual representation will be set by the MorphologyGenerator
	# This is a placeholder for any additional setup needed
	visual_representation = Node3D.new()
	visual_representation.name = "VisualForm"
	add_child(visual_representation)

func _process(delta):
	# Age and energy updates happen in process_behavior
	pass

func process_behavior(delta):
	# Update age and energy
	age += delta / 86400.0  # Convert seconds to days (very rough approximation)
	energy -= energy_consumption_rate * delta * traits.get_trait("metabolism")
	
	# Check if entity should expire
	if age >= lifespan or energy <= 0 or health <= 0:
		emit_signal("expired", self)
		return
	
	# Process current behavior
	match current_behavior:
		"idle":
			_process_idle(delta)
		"seeking_resource":
			_process_seeking_resource(delta)
		"seeking_connection":
			_process_seeking_connection(delta)
		"transforming":
			_process_transforming(delta)
		"challenging_boundary":
			_process_challenging_boundary(delta)
		"celebrating":
			_process_celebrating(delta)

# Behavior processing methods
func _process_idle(delta):
	# Occasionally change to a different behavior
	if randf() < 0.01:
		_choose_new_behavior()
	
	# Gentle random movement
	if randf() < 0.05:
		var random_offset = Vector3(
			randf_range(-5, 5),
			randf_range(-2, 5),
			randf_range(-5, 5)
		)
		target_position = position + random_offset
	
	# Move toward target position
	if position.distance_to(target_position) > 0.1:
		var direction = (target_position - position).normalized()
		position += direction * movement_speed * delta * traits.get_trait("mobility")

func _process_seeking_resource(delta):
	# This would involve finding and moving toward the nearest resource
	# For this implementation, we'll just simulate finding a resource
	if randf() < 0.02:
		var found_resource = randf() < 0.3  # 30% chance to find a resource each check
		
		if found_resource:
			var resource_amount = randf_range(0.1, 0.3)
			energy += resource_amount
			emit_signal("resource_consumed", self, "energy", resource_amount)
			
			# Return to idle after consuming
			_set_behavior("idle")
	
	# Move toward target position (would be resource position in a full implementation)
	if position.distance_to(target_position) > 0.1:
		var direction = (target_position - position).normalized()
		position += direction * movement_speed * delta * traits.get_trait("mobility")
	else:
		# If we've reached the target but found nothing, set a new target
		var random_offset = Vector3(
			randf_range(-10, 10),
			randf_range(-5, 5),
			randf_range(-10, 10)
		)
		target_position = position + random_offset

func _process_seeking_connection(delta):
	# In a full implementation, this would involve finding and approaching another entity
	# For now, simulate finding a connection
	if randf() < 0.01:
		var found_connection = randf() < 0.2  # 20% chance to find a connection each check
		
		if found_connection:
			# Simulate forming a relationship with an unspecified entity
			emit_signal("relationship_formed", self, null, randf_range(0.1, 0.9))
			
			# Return to idle after forming connection
			_set_behavior("idle")
	
	# Move toward target position (would be other entity's position in a full implementation)
	if position.distance_to(target_position) > 0.1:
		var direction = (target_position - position).normalized()
		position += direction * movement_speed * delta * traits.get_trait("mobility")
	else:
		# If we've reached the target but found no one, set a new target
		var random_offset = Vector3(
			randf_range(-10, 10),
			randf_range(-5, 5),
			randf_range(-10, 10)
		)
		target_position = position + random_offset

func _process_transforming(delta):
	# Transformation is a process that takes time
	if !is_transforming:
		# Start transformation
		is_transforming = true
		
		# Reduce energy during transformation
		energy -= 0.2
		
		# Request a transformation from the ecosystem controller
		emit_signal("transformation_requested", self)
	else:
		# Transformation animation/progress would happen here
		# For now, just complete the transformation after a delay
		await get_tree().create_timer(2.0).timeout
		
		# Transformation complete
		is_transforming = false
		_set_behavior("celebrating")

func _process_challenging_boundary(delta):
	# Challenging a boundary is a significant action that costs energy
	energy -= 0.05 * delta
	
	# Choose a random boundary type to challenge
	var boundary_types = ["physical", "relational", "cognitive", "expressive"]
	var boundary_type = boundary_types[randi() % boundary_types.size()]
	
	# Signal that this entity wants to challenge a boundary
	emit_signal("boundary_challenge_requested", self, boundary_type)
	
	# Move back to idle after the challenge
	_set_behavior("idle")

func _process_celebrating(delta):
	# Celebration after a transformation or other significant event
	# This might involve special visual effects or interactions
	
	# Move in a more lively way
	var celebration_offset = Vector3(
		sin(Time.get_ticks_msec() * 0.001 * 2) * 3,
		cos(Time.get_ticks_msec() * 0.001 * 3) * 1,
		sin(Time.get_ticks_msec() * 0.001 * 2.5) * 3
	)
	
	position = target_position + celebration_offset * traits.get_trait("expressiveness")
	
	# Celebration lasts for a limited time
	if randf() < 0.01:
		_set_behavior("idle")

func _choose_new_behavior():
	# Choose a new behavior based on current state and traits
	var behaviors = []
	
	# Always possible behaviors
	behaviors.append("idle")
	
	# Behaviors based on needs
	if energy < 0.5:
		behaviors.append("seeking_resource")
		behaviors.append("seeking_resource")  # Add twice to increase probability
	
	# Behaviors based on traits
	if traits.get_trait("sociality") > 0.5:
		behaviors.append("seeking_connection")
	
	if traits.get_trait("fluidity") > 0.7 and randf() < transformation_probability:
		behaviors.append("transforming")
	
	if traits.get_trait("boundary_pushing") > 0.6 and randf() < 0.1:
		behaviors.append("challenging_boundary")
	
	# Choose a random behavior from the possibilities
	var new_behavior = behaviors[randi() % behaviors.size()]
	_set_behavior(new_behavior)

func _set_behavior(behavior: String):
	current_behavior = behavior
	
	# Set a new target position based on the behavior
	match behavior:
		"idle":
			# Stay relatively close to current position
			target_position = position + Vector3(
				randf_range(-3, 3),
				randf_range(-1, 3),
				randf_range(-3, 3)
			)
		"seeking_resource", "seeking_connection":
			# Look farther afield
			target_position = position + Vector3(
				randf_range(-15, 15),
				randf_range(-5, 10),
				randf_range(-15, 15)
			)
		"transforming", "challenging_boundary", "celebrating":
			# Stay in place for these behaviors
			target_position = position

func end_of_day_update(day: int):
	# Check for reproduction
	if energy > reproduction_energy_threshold and traits.get_trait("fertility") > randf():
		_attempt_reproduction()
	
	# Check for transformation
	if traits.get_trait("fluidity") > randf() and randf() < transformation_probability:
		_set_behavior("transforming")
	
	# Record the day in memory
	memory["last_day_update"] = day
	
	# Adjust traits slightly over time (gradual evolution)
	traits.slight_random_drift()

func _attempt_reproduction():
	# In a full implementation, this would involve finding a compatible entity
	# For now, just signal that reproduction was attempted
	# The ecosystem controller would handle the actual creation of a new entity
	
	# Reduce energy from reproduction
	energy -= 0.3
	
	# This would be handled by the ecosystem controller via signals
	print(name + " attempted reproduction")

func apply_transformation(new_form: Dictionary):
	current_form = new_form
	
	# Update visual representation
	# This would be handled by the ecosystem controller in the full implementation
	# For now, just log the transformation
	print(name + " transformed to a new form")
	
	# Adjust traits based on the new form
	traits.adjust_after_transformation(new_form)

func get_current_form() -> Dictionary:
	return current_form

func interact_with(other_entity: Entity) -> Dictionary:
	# Calculate compatibility and interaction result
	var compatibility = traits.calculate_compatibility(other_entity.traits)
	var interaction_strength = randf() * compatibility
	
	# Store the interaction in memory
	if !memory.has("interactions"):
		memory["interactions"] = []
	
	memory["interactions"].append({
		"entity": other_entity.name,
		"compatibility": compatibility,
		"strength": interaction_strength,
		"time": Time.get_ticks_msec()
	})
	
	# Return interaction details
	return {
		"compatibility": compatibility,
		"strength": interaction_strength,
		"initiator": self,
		"receiver": other_entity
	}

func consume_resource(resource_type: String, amount: float):
	match resource_type:
		"energy":
			energy += amount
			if energy > 1.0:
				energy = 1.0
		"health":
			health += amount
			if health > 1.0:
				health = 1.0
	
	emit_signal("resource_consumed", self, resource_type, amount)

func take_damage(amount: float):
	health -= amount
	if health < 0:
		health = 0
		emit_signal("expired", self)

func get_info() -> Dictionary:
	return {
		"name": name,
		"age": age,
		"energy": energy,
		"health": health,
		"traits": traits.get_all_traits(),
		"behavior": current_behavior,
		"form": current_form
	}
