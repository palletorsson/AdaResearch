# cheng_entity_behaviors.gd
# Entity behavior update functions extracted from cheng_simulation.gd.
# Each function updates a specific entity type per simulation tick.
# The simulation passes itself as `sim` so behaviors can access shared state
# (resource_points, entities, max_entities, rng, helper methods).

extends RefCounted
class_name ChengEntityBehaviors


## Update a wanderer entity: wander, seek targets, explore.
static func update_wanderer(sim, entity, delta: float) -> void:
	# Wanderers explore and seek interesting things
	var wander_force = entity.wander(entity.attributes["wander_strength"])

	# Check if entity should seek a target
	if entity.target != Vector3.ZERO:
		if entity.position.distance_to(entity.target) < 1.0:
			entity.target = Vector3.ZERO
		else:
			var seek_force = entity.seek(entity.target)
			entity.apply_force(seek_force)
	else:
		if sim.rng.randf() < delta * entity.attributes["curiosity"]:
			var new_target = sim.find_interest_target(entity)
			if new_target:
				entity.target = new_target

	entity.apply_force(wander_force)

	# Update velocity and position
	entity.velocity += entity.acceleration * delta
	var max_speed = entity.attributes["max_speed"]
	entity.velocity = entity.velocity.limit_length(max_speed)
	entity.position += entity.velocity * delta
	entity.acceleration = Vector3.ZERO

	# Update node position and rotation
	if entity.node:
		entity.node.position = entity.position
		if entity.velocity.length() > 0.1:
			var look_dir = entity.velocity.normalized()
			entity.node.look_at_from_position(entity.node.position, entity.position + look_dir, Vector3.UP)

	# State changes
	if entity.energy < 30.0:
		entity.set_state("hungry")
	elif entity.energy > 70.0:
		entity.set_state("exploring")
	else:
		entity.set_state("searching")


## Update a grower entity: slow movement, resource absorption, growth, splitting.
static func update_grower(sim, entity, delta: float) -> void:
	var wander_force = entity.wander(0.5)
	entity.apply_force(wander_force)

	entity.velocity += entity.acceleration * delta
	entity.velocity = entity.velocity.limit_length(1.0)
	entity.position += entity.velocity * delta
	entity.acceleration = Vector3.ZERO

	# Handle growth
	var growth_rate = entity.attributes["growth_rate"]
	var max_size = entity.attributes["max_size"]
	var target_scale = min(1.0 + (entity.age * growth_rate * 0.05), max_size)

	# Consume nearby resources
	for resource in sim.resource_points:
		if entity.position.distance_to(resource.position) < 2.0 and resource.energy > 10.0:
			var consumption = min(delta * 10.0, resource.energy * 0.5)
			resource.energy -= consumption
			entity.energy += consumption * entity.attributes["resource_efficiency"]
			target_scale += delta * 0.1
			break

	if entity.node:
		entity.scale = Vector3.ONE * target_scale
		entity.node.scale = entity.scale

	# Check for reproduction
	if entity.scale.x >= entity.attributes["split_threshold"] * max_size and entity.energy > 80.0:
		if sim.entities.size() < sim.max_entities:
			sim.split_grower(entity)

	if entity.energy < 30.0:
		entity.set_state("absorbing")
	elif entity.scale.x >= entity.attributes["split_threshold"] * max_size:
		entity.set_state("splitting")
	else:
		entity.set_state("growing")


## Update a networker entity: form connections, share information.
static func update_networker(sim, entity, delta: float) -> void:
	var wander_force = entity.wander(0.7)
	entity.apply_force(wander_force)

	var nearby_entities = sim.get_entities_in_radius(entity.position, entity.attributes["connection_range"])
	var connected_count = 0

	for nearby in nearby_entities:
		if nearby.id != entity.id and nearby.type == "networker":
			if not entity.relationships.has(nearby.id) or entity.relationships[nearby.id] != "connected":
				entity.relationships[nearby.id] = "connected"
				nearby.relationships[entity.id] = "connected"
				sim.update_network_connections(entity)
				connected_count += 1

			var seek_force = entity.seek(nearby.position, 0.5)
			entity.apply_force(seek_force)

		if connected_count >= entity.attributes["max_connections"]:
			break

	entity.velocity += entity.acceleration * delta
	entity.velocity = entity.velocity.limit_length(1.5)
	entity.position += entity.velocity * delta
	entity.acceleration = Vector3.ZERO

	if entity.node:
		entity.node.position = entity.position
		var connector = entity.node.get_node_or_null("Connections")
		if connector:
			for child in connector.get_children():
				if child is MeshInstance3D:
					child.visible = false

	if connected_count > 0:
		entity.set_state("connected")
	else:
		entity.set_state("searching")


## Update a predator entity: hunt, attack prey.
static func update_predator(sim, entity, delta: float) -> void:
	var wander_force = entity.wander(0.8)
	entity.apply_force(wander_force)

	# Find prey
	var target_entity = null
	var nearest_distance = INF

	var nearby_entities = sim.get_entities_in_radius(entity.position, 6.0)
	for nearby in nearby_entities:
		if nearby.id != entity.id and (nearby.type == "wanderer" or nearby.type == "grower" or nearby.type == "networker"):
			var distance = entity.position.distance_to(nearby.position)
			if distance < nearest_distance:
				nearest_distance = distance
				target_entity = nearby

	if target_entity and entity.energy < 80.0:
		var hunt_strength = entity.attributes["hunting_efficiency"]
		var seek_force = entity.seek(target_entity.position, hunt_strength)
		entity.apply_force(seek_force)

		entity.target = target_entity.position
		entity.set_state("hunting")

		if nearest_distance < 1.0 and sim.rng.randf() < entity.attributes["attack_strength"] * 0.1:
			var damage = 10.0 * entity.attributes["attack_strength"]
			target_entity.energy = max(10.0, target_entity.energy - damage)
			entity.energy = min(100.0, entity.energy + damage * 0.7)
			sim.create_attack_effect(entity.position, target_entity.position)
	else:
		entity.set_state("stalking")

	entity.velocity += entity.acceleration * delta
	var max_speed = 2.0 + entity.attributes["hunting_efficiency"] * 0.5
	entity.velocity = entity.velocity.limit_length(max_speed)
	entity.position += entity.velocity * delta
	entity.acceleration = Vector3.ZERO

	if entity.node:
		entity.node.position = entity.position
		if entity.velocity.length() > 0.1:
			var look_dir = entity.velocity.normalized()
			entity.node.look_at_from_position(entity.node.position, entity.position + look_dir, Vector3.UP)


## Update a builder entity: construct structures, gather resources.
static func update_builder(sim, entity, delta: float) -> void:
	var movement_speed = 1.5
	var is_building = entity.attributes.get("construction_state", "") == "building"

	if is_building:
		movement_speed = 0.5

	var wander_force = entity.wander(0.6)
	entity.apply_force(wander_force)

	if is_building:
		entity.attributes["construction_progress"] = min(1.0, entity.attributes["construction_progress"] + delta * entity.attributes["construction_speed"])
		if entity.attributes["construction_progress"] >= 1.0:
			sim.complete_construction(entity)
			entity.attributes.erase("construction_state")
	else:
		if entity.energy > 50.0 and sim.rng.randf() < delta * entity.attributes["creativity"]:
			sim.start_construction(entity)

	entity.velocity += entity.acceleration * delta
	entity.velocity = entity.velocity.limit_length(movement_speed)
	entity.position += entity.velocity * delta
	entity.acceleration = Vector3.ZERO

	if entity.node:
		entity.node.position = entity.position
		if is_building:
			sim.update_construction_visualizer(entity)

	if is_building:
		entity.set_state("building")
	elif entity.energy < 30.0:
		entity.set_state("gathering")
	else:
		entity.set_state("planning")
