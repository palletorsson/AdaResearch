# relationship_network.gd
class_name RelationshipNetwork
extends Node3D

signal connection_formed(entity1, entity2, type, strength)
signal connection_severed(entity1, entity2)
signal network_pattern_emerged(pattern_type, entities)
signal community_formed(community_entities, center, radius)

# Configuration
@export_category("Network Parameters")
@export var connection_visual_enabled: bool = true
@export var connection_decay_rate: float = 0.01
@export var pattern_detection_enabled: bool = true
@export var community_detection_interval: float = 5.0
@export var enable_network_visualization: bool = true
@export var max_connection_distance: float = 15.0
@export var queer_kinship_boost: float = 0.3

# Network state
var connections: Array = []
var entities: Dictionary = {}  # entity -> Array of connections
var communities: Array = []
var emergent_patterns: Array = []
var connection_visuals: Node3D
var community_detection_timer: float = 0.0

# Connection types with corresponding colors
var connection_types = {
	"kinship": Color(0.2, 0.8, 0.2),      # Green for family/kinship
	"alliance": Color(0.2, 0.2, 0.8),     # Blue for mutual aid/collaboration
	"romantic": Color(0.8, 0.2, 0.2),     # Red for romantic/intimate
	"mentorship": Color(0.8, 0.8, 0.2),   # Yellow for knowledge transfer
	"creative": Color(0.8, 0.2, 0.8),     # Purple for collaborative creation
	"fluid": Color(0.2, 0.8, 0.8),        # Cyan for constantly changing/evolving
	"nomadic": Color(0.5, 0.3, 0.1),      # Brown for temporary/traveling
	"queer": Color(1.0, 0.5, 0.8)         # Pink for challenging normative patterns
}

# Connection class
class Connection:
	var entity1: Object
	var entity2: Object
	var type: String
	var strength: float
	var formation_time: int
	var last_interaction_time: int
	var interactions: Array = []
	var is_reciprocal: bool
	var visual: Node3D
	var properties: Dictionary = {}
	
	func _init(e1, e2, t: String, s: float):
		entity1 = e1
		entity2 = e2
		type = t
		strength = s
		formation_time = Time.get_ticks_msec()
		last_interaction_time = formation_time
		is_reciprocal = true  # Default, can be changed
	
	func add_interaction(interaction_data: Dictionary):
		interactions.append({
			"time": Time.get_ticks_msec(),
			"data": interaction_data
		})
		last_interaction_time = Time.get_ticks_msec()
	
	func get_age() -> float:
		return (Time.get_ticks_msec() - formation_time) / 1000.0  # In seconds
	
	func get_dormancy() -> float:
		return (Time.get_ticks_msec() - last_interaction_time) / 1000.0  # In seconds
	
	func update(delta: float, decay_rate: float) -> bool:
		# Apply decay based on dormancy
		var dormancy_factor = get_dormancy() / 3600.0  # Convert to hours
		strength -= decay_rate * delta * (1.0 + dormancy_factor * 0.1)
		
		# Check if connection should be severed
		if strength <= 0:
			return false
		
		return true

# Community class
class Community:
	var entities: Array = []
	var center: Vector3
	var radius: float
	var primary_type: String
	var formation_time: int
	var stability: float = 0.5
	var diversity: float = 0.5
	var boundary_permeability: float = 0.5
	var visual: Node3D
	
	func _init(community_entities: Array, center_pos: Vector3, community_radius: float, main_type: String):
		entities = community_entities
		center = center_pos
		radius = community_radius
		primary_type = main_type
		formation_time = Time.get_ticks_msec()
	
	func calculate_metrics(all_connections: Array):
		# Calculate community metrics
		
		# Get all connections between community members
		var internal_connections = []
		for connection in all_connections:
			if entities.has(connection.entity1) and entities.has(connection.entity2):
				internal_connections.append(connection)
		
		# Calculate stability based on connection strengths and age
		var total_strength = 0.0
		var connection_count = max(1, internal_connections.size())
		
		for connection in internal_connections:
			total_strength += connection.strength
		
		stability = clamp(total_strength / connection_count, 0.0, 1.0)
		
		# Calculate diversity based on trait differences
		diversity = 0.0
		if entities.size() > 1:
			var trait_differences = 0.0
			var comparison_count = 0
			
			for i in range(entities.size()):
				for j in range(i + 1, entities.size()):
					var entity1 = entities[i]
					var entity2 = entities[j]
					
					if entity1.has_method("get_info") and entity2.has_method("get_info"):
						var info1 = entity1.get_info()
						var info2 = entity2.get_info()
						
						if info1.has("traits") and info2.has("traits"):
							# Calculate difference between traits
							for _trait in info1.traits:
								if info2.traits.has(_trait):
									trait_differences += abs(info1.traits[_trait] - info2.traits[_trait])
									comparison_count += 1
			
			if comparison_count > 0:
				diversity = clamp(trait_differences / comparison_count / 0.5, 0.0, 1.0)
			else:
				diversity = 0.5  # Default if no traits to compare
		
		# Calculate boundary permeability based on external connections
		var external_connections = 0
		for entity in entities:
			if entity.has_method("get_info"):
				var info = entity.get_info()
				if info.has("connections"):
					for connection in info.connections:
						if not entities.has(connection.entity1) or not entities.has(connection.entity2):
							external_connections += 1
		
		boundary_permeability = clamp(float(external_connections) / max(1, entities.size()), 0.0, 1.0)

# Initialization
func _ready():
	# Create container for connection visuals
	connection_visuals = Node3D.new()
	connection_visuals.name = "ConnectionVisuals"
	add_child(connection_visuals)
	
	# Schedule community detection
	_schedule_community_detection()

func _schedule_community_detection():
	community_detection_timer = community_detection_interval

func register_entity(entity: Object):
	if not entities.has(entity):
		entities[entity] = []

func unregister_entity(entity: Object):
	if entities.has(entity):
		# Remove all connections involving this entity
		var to_remove = []
		for connection in connections:
			if connection.entity1 == entity or connection.entity2 == entity:
				to_remove.append(connection)
		
		for connection in to_remove:
			sever_connection(connection)
		
		# Remove from entities dictionary
		entities.erase(entity)
		
		# Remove from communities
		for community in communities:
			if community.entities.has(entity):
				community.entities.erase(entity)

func create_connection(entity1: Object, entity2: Object, type: String, strength: float = 0.5) -> Connection:
	if entity1 == entity2:
		return null  # Can't connect to self
	
	# Check if connection already exists
	for connection in connections:
		if (connection.entity1 == entity1 and connection.entity2 == entity2) or \
		   (connection.entity1 == entity2 and connection.entity2 == entity1):
			# Update existing connection
			connection.strength = max(connection.strength, strength)
			connection.last_interaction_time = Time.get_ticks_msec()
			_update_connection_visual(connection)
			return connection
	
	# Create new connection
	var connection = Connection.new(entity1, entity2, type, strength)
	connections.append(connection)
	
	# Add connection to entity lists
	if entities.has(entity1):
		entities[entity1].append(connection)
	if entities.has(entity2):
		entities[entity2].append(connection)
	
	# Create visual representation
	if connection_visual_enabled:
		_create_connection_visual(connection)
	
	# Apply queer kinship boost if applicable
	if type == "queer" or type == "fluid":
		connection.strength += queer_kinship_boost
		connection.strength = min(connection.strength, 1.0)
	
	# Emit signal
	emit_signal("connection_formed", entity1, entity2, type, strength)
	
	return connection

func sever_connection(connection: Connection):
	# Remove from connections list
	connections.erase(connection)
	
	# Remove from entity lists
	if entities.has(connection.entity1):
		entities[connection.entity1].erase(connection)
	if entities.has(connection.entity2):
		entities[connection.entity2].erase(connection)
	
	# Remove visual
	if connection.visual:
		connection.visual.queue_free()
	
	# Emit signal
	emit_signal("connection_severed", connection.entity1, connection.entity2)

func _create_connection_visual(connection: Connection):
	var visual = Node3D.new()
	visual.name = "Connection_" + connection.entity1.name + "_" + connection.entity2.name
	
	# Create line between entities
	var line = MeshInstance3D.new()
	line.name = "ConnectionLine"
	
	# Calculate positions
	var start_pos = connection.entity1.global_position
	var end_pos = connection.entity2.global_position
	var center_pos = (start_pos + end_pos) / 2
	var length = start_pos.distance_to(end_pos)
	
	# Create mesh
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.05 * connection.strength
	mesh.bottom_radius = 0.05 * connection.strength
	mesh.height = length
	line.mesh = mesh
	
	# Position and orient line
	line.global_position = center_pos
	line.look_at_from_position(center_pos, end_pos, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI/2)
	
	# Create material
	var material = StandardMaterial3D.new()
	var connection_color = connection_types[connection.type] if connection_types.has(connection.type) else Color(0.7, 0.7, 0.7)
	material.albedo_color = connection_color
	material.albedo_color.a = 0.7 * connection.strength
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = connection_color
	material.emission_energy = 0.5 * connection.strength
	line.material_override = material
	
	visual.add_child(line)
	connection_visuals.add_child(visual)
	connection.visual = visual

func _update_connection_visual(connection: Connection):
	if not connection.visual:
		_create_connection_visual(connection)
		return
	
	# Update the visual based on current connection properties
	var line = connection.visual.get_node("ConnectionLine")
	if line:
		# Update positions
		var start_pos = connection.entity1.global_position
		var end_pos = connection.entity2.global_position
		var center_pos = (start_pos + end_pos) / 2
		var length = start_pos.distance_to(end_pos)
		
		# Update mesh
		var mesh = line.mesh
		mesh.top_radius = 0.05 * connection.strength
		mesh.bottom_radius = 0.05 * connection.strength
		mesh.height = length
		
		# Update position and orientation
		line.global_position = center_pos
		line.look_at_from_position(center_pos, end_pos, Vector3.UP)
		line.rotate_object_local(Vector3.RIGHT, PI/2)
		
		# Update material
		var material = line.material_override
		var connection_color = connection_types[connection.type] if connection_types.has(connection.type) else Color(0.7, 0.7, 0.7)
		material.albedo_color = connection_color
		material.albedo_color.a = 0.7 * connection.strength
		material.emission = connection_color
		material.emission_energy = 0.5 * connection.strength

func update(delta: float):
	# Update connections
	for connection in connections.duplicate():  # Duplicate to safely modify during iteration
		var still_active = connection.update(delta, connection_decay_rate)
		
		if not still_active:
			sever_connection(connection)
		elif connection_visual_enabled and connection.visual:
			_update_connection_visual(connection)
	
	# Update community detection timer
	community_detection_timer -= delta
	if community_detection_timer <= 0:
		_detect_communities()
		_detect_emergent_patterns()
		_schedule_community_detection()
	
	# Update community visuals
	for community in communities:
		_update_community_visual(community)

func _detect_communities():
	# Simple community detection algorithm
	# In a full implementation, this would use a more sophisticated algorithm like Louvain method
	
	# Clear old communities
	for community in communities:
		if community.visual:
			community.visual.queue_free()
	communities.clear()
	
	# Find densely connected groups
	var processed_entities = {}
	
	for entity in entities.keys():
		if processed_entities.has(entity):
			continue
		
		var community_entities = []
		var connection_counts = {}
		
		# Find all entities connected to this one
		var entity_connections = entities[entity]
		for connection in entity_connections:
			var other_entity = connection.entity1 if connection.entity1 != entity else connection.entity2
			
			if not connection_counts.has(other_entity):
				connection_counts[other_entity] = 0
			connection_counts[other_entity] += 1
		
		# Add entities with strong connections to the community
		for other_entity in connection_counts.keys():
			if connection_counts[other_entity] >= 2:  # At least 2 connections
				community_entities.append(other_entity)
				processed_entities[other_entity] = true
		
		# Only create community if there are at least 3 entities
		if community_entities.size() >= 3:
			# Calculate center and radius
			var center = Vector3.ZERO
			for member in community_entities:
				center += member.global_position
			center /= community_entities.size()
			
			var radius = 0.0
			for member in community_entities:
				var distance = member.global_position.distance_to(center)
				radius = max(radius, distance)
			
			# Determine primary connection type
			var type_counts = {}
			for member in community_entities:
				for connection in entities[member]:
					if not type_counts.has(connection.type):
						type_counts[connection.type] = 0
					type_counts[connection.type] += 1
			
			var primary_type = "mixed"
			var max_count = 0
			for type in type_counts:
				if type_counts[type] > max_count:
					max_count = type_counts[type]
					primary_type = type
			
			# Create the community
			var community = Community.new(community_entities, center, radius, primary_type)
			communities.append(community)
			
			# Create visual representation
			_create_community_visual(community)
			
			# Calculate community metrics
			community.calculate_metrics(connections)
			
			# Emit signal
			emit_signal("community_formed", community_entities, center, radius)

func _create_community_visual(community: Community):
	if not enable_network_visualization:
		return
	
	var visual = Node3D.new()
	visual.name = "Community_" + str(communities.size())
	
	# Create a translucent sphere to represent the community boundary
	var boundary = MeshInstance3D.new()
	boundary.name = "CommunityBoundary"
	
	var mesh = SphereMesh.new()
	mesh.radius = community.radius
	mesh.height = community.radius * 2
	boundary.mesh = mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	var community_color = connection_types[community.primary_type] if connection_types.has(community.primary_type) else Color(0.7, 0.7, 0.7)
	material.albedo_color = community_color
	material.albedo_color.a = 0.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	boundary.material_override = material
	
	visual.add_child(boundary)
	visual.global_position = community.center
	
	connection_visuals.add_child(visual)
	community.visual = visual

func _update_community_visual(community: Community):
	if not community.visual or not enable_network_visualization:
		return
	
	# Update center position based on current entity positions
	var center = Vector3.ZERO
	for entity in community.entities:
		center += entity.global_position
	
	if community.entities.size() > 0:
		center /= community.entities.size()
		community.center = center
		community.visual.global_position = center
	
	# Update radius based on current entity positions
	var radius = 0.0
	for entity in community.entities:
		var distance = entity.global_position.distance_to(center)
		radius = max(radius, distance)
	
	community.radius = radius
	
	# Update boundary mesh
	var boundary = community.visual.get_node("CommunityBoundary")
	if boundary:
		var mesh = boundary.mesh
		mesh.radius = community.radius
		mesh.height = community.radius * 2

func _detect_emergent_patterns():
	if not pattern_detection_enabled:
		return
	
	# Clear old patterns
	emergent_patterns.clear()
	
	# Look for different network patterns
	_detect_stars()
	_detect_chains()
	_detect_cycles()
	_detect_clusters()

func _detect_stars():
	# Look for star patterns (one central entity connected to many others)
	var star_centers = []
	
	for entity in entities.keys():
		var entity_connections = entities[entity]
		if entity_connections.size() >= 4:  # At least 4 connections to be a star center
			var connected_entities = []
			for connection in entity_connections:
				var other_entity = connection.entity1 if connection.entity1 != entity else connection.entity2
				connected_entities.append(other_entity)
			
			# Check if connected entities have few other connections
			var is_star = true
			for other_entity in connected_entities:
				if entities[other_entity].size() > 2:  # More than 2 connections means not a leaf
					is_star = false
					break
			
			if is_star:
				star_centers.append(entity)
				
				# Create a star pattern
				var pattern = {
					"type": "star",
					"center": entity,
					"leaves": connected_entities,
					"position": entity.global_position
				}
				
				emergent_patterns.append(pattern)
				
				# Emit signal
				emit_signal("network_pattern_emerged", "star", [entity] + connected_entities)

func _detect_chains():
	# Look for chain patterns (linear sequences of connections)
	var processed_entities = {}
	
	for entity in entities.keys():
		if processed_entities.has(entity):
			continue
		
		# Start a chain if entity has exactly 1 or 2 connections
		if entities[entity].size() <= 2:
			var chain = [entity]
			processed_entities[entity] = true
			
			# Try to extend the chain in both directions
			var current = entity
			var found_next = true
			
			while found_next:
				found_next = false
				
				for connection in entities[current]:
					var next_entity = connection.entity1 if connection.entity1 != current else connection.entity2
					
					if not processed_entities.has(next_entity) and entities[next_entity].size() <= 2:
						chain.append(next_entity)
						processed_entities[next_entity] = true
						current = next_entity
						found_next = true
						break
			
			# Only consider chains of at least 4 entities
			if chain.size() >= 4:
				var pattern = {
					"type": "chain",
					"entities": chain.duplicate(),
					"position": chain[0].global_position
				}
				
				emergent_patterns.append(pattern)
				
				# Emit signal
				emit_signal("network_pattern_emerged", "chain", chain)

func _detect_cycles():
	# Look for cycle patterns (loops of connections)
	# This is a simplified cycle detection
	var processed_connections = {}
	
	for start_entity in entities.keys():
		# Try to find cycles starting from this entity
		var visited = {}
		var path = [start_entity]
		
		_find_cycles_dfs(start_entity, start_entity, visited, path, processed_connections)

func _find_cycles_dfs(start_entity, current_entity, visited, path, processed_connections):
	visited[current_entity] = true
	
	for connection in entities[current_entity]:
		# Skip already processed connections
		var connection_key = str(connection.entity1.get_instance_id()) + "_" + str(connection.entity2.get_instance_id())
		if processed_connections.has(connection_key):
			continue
		
		var next_entity = connection.entity1 if connection.entity1 != current_entity else connection.entity2
		
		if next_entity == start_entity and path.size() >= 3:
			# Found a cycle
			var cycle = path.duplicate()
			
			# Mark all connections in the cycle as processed
			for i in range(cycle.size()):
				var e1 = cycle[i]
				var e2 = cycle[(i + 1) % cycle.size()]
				processed_connections[str(e1.get_instance_id()) + "_" + str(e2.get_instance_id())] = true
				processed_connections[str(e2.get_instance_id()) + "_" + str(e1.get_instance_id())] = true
			
			# Create cycle pattern
			var center = Vector3.ZERO
			for entity in cycle:
				center += entity.global_position
			center /= cycle.size()
			
			var pattern = {
				"type": "cycle",
				"entities": cycle,
				"position": center
			}
			
			emergent_patterns.append(pattern)
			
			# Emit signal
			emit_signal("network_pattern_emerged", "cycle", cycle)
			
			return
		elif not visited.has(next_entity):
			path.append(next_entity)
			_find_cycles_dfs(start_entity, next_entity, visited.duplicate(), path, processed_connections)
			path.pop_back()

func _detect_clusters():
	# Look for densely connected clusters
	# We'll use the communities as clusters
	for community in communities:
		if community.entities.size() >= 5 and community.stability >= 0.7:
			var pattern = {
				"type": "cluster",
				"entities": community.entities.duplicate(),
				"position": community.center
			}
			
			emergent_patterns.append(pattern)
			
			# Emit signal
			emit_signal("network_pattern_emerged", "cluster", community.entities)

func get_entity_connections(entity: Object) -> Array:
	if entities.has(entity):
		return entities[entity].duplicate()
	return []

func get_connection_between(entity1: Object, entity2: Object) -> Connection:
	for connection in connections:
		if (connection.entity1 == entity1 and connection.entity2 == entity2) or \
		   (connection.entity1 == entity2 and connection.entity2 == entity1):
			return connection
	return null

func boost_connections(entity_group: Array, boost_amount: float):
	# Boost connections among a group of entities
	for i in range(entity_group.size()):
		for j in range(i + 1, entity_group.size()):
			var entity1 = entity_group[i]
			var entity2 = entity_group[j]
			
			var connection = get_connection_between(entity1, entity2)
			if connection:
				connection.strength += boost_amount
				connection.strength = min(connection.strength, 1.0)
				connection.last_interaction_time = Time.get_ticks_msec()
				
				if connection_visual_enabled and connection.visual:
					_update_connection_visual(connection)

func create_random_connections(entity: Object, count: int):
	# Create random connections from this entity to others
	if not entities.has(entity) or entities.keys().size() <= 1:
		return
	
	var other_entities = entities.keys().duplicate()
	other_entities.erase(entity)
	
	for i in range(min(count, other_entities.size())):
		if other_entities.size() == 0:
			break
		
		# Pick a random entity
		var random_index = randi() % other_entities.size()
		var other_entity = other_entities[random_index]
		other_entities.remove_at(random_index)
		
		# Pick a random connection type
		var types = connection_types.keys()
		var random_type = types[randi() % types.size()]
		
		# Create connection with random strength
		var strength = randf_range(0.3, 0.7)
		create_connection(entity, other_entity, random_type, strength)

func get_all_communities() -> Array:
	return communities.duplicate()

func get_entity_community(entity: Object) -> Community:
	for community in communities:
		if community.entities.has(entity):
			return community
	return null

func get_strongest_connections(entity: Object, count: int = 3) -> Array:
	if not entities.has(entity):
		return []
	
	var entity_connections = entities[entity].duplicate()
	entity_connections.sort_custom(func(a, b): return a.strength > b.strength)
	
	return entity_connections.slice(0, min(count, entity_connections.size()) - 1)

func get_network_centrality(entity: Object) -> float:
	# Calculate a simple measure of how central this entity is in the network
	if not entities.has(entity):
		return 0.0
	
	var direct_connections = entities[entity].size()
	var total_strength = 0.0
	
	for connection in entities[entity]:
		total_strength += connection.strength
	
	var centrality = (direct_connections * 0.7 + total_strength * 0.3) / max(1, entities.size() - 1)
	return centrality
