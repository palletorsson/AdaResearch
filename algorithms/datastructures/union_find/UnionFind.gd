extends Node3D

var time = 0.0
var operation_timer = 0.0
var operation_interval = 2.0
var element_count = 12
var components_count = 0

# Union-Find operations
enum UFOperation {
	MAKE_SET,
	UNION,
	FIND,
	PATH_COMPRESSION,
	RANK_OPTIMIZATION
}

var current_operation = UFOperation.MAKE_SET

# Union-Find element
class UFElement:
	var id: int
	var parent: UFElement
	var rank: int = 0
	var visual_object: CSGSphere3D
	var position_2d: Vector2
	
	func _init(element_id: int):
		id = element_id
		parent = self  # Initially, each element is its own parent
		rank = 0

var elements = []
var connections = []
var recent_union_pairs = []

func _ready():
	setup_materials()
	initialize_union_find()

func setup_materials():
	# Component indicator material
	var component_material = StandardMaterial3D.new()
	component_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	component_material.emission_enabled = true
	component_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$ComponentIndicator.material_override = component_material
	
	# Union operation indicator material
	var union_material = StandardMaterial3D.new()
	union_material.albedo_color = Color(1.0, 0.6, 0.2, 1.0)
	union_material.emission_enabled = true
	union_material.emission = Color(0.3, 0.15, 0.05, 1.0)
	$UnionOperationIndicator.material_override = union_material

func initialize_union_find():
	# Create elements arranged in a circle
	for i in range(element_count):
		var element = UFElement.new(i)
		
		# Position in circle
		var angle = i * (2.0 * PI / element_count)
		var radius = 4.0
		element.position_2d = Vector2(cos(angle) * radius, sin(angle) * radius)
		
		create_visual_element(element)
		elements.append(element)
	
	update_components_count()

func create_visual_element(element: UFElement):
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.3
	sphere.position = Vector3(element.position_2d.x, element.position_2d.y, 0)
	
	# Material with unique color per component
	var element_material = StandardMaterial3D.new()
	update_element_material(element, element_material)
	sphere.material_override = element_material
	
	$Elements.add_child(sphere)
	element.visual_object = sphere

func update_element_material(element: UFElement, material: StandardMaterial3D):
	var root_id = find_root(element).id
	var color_intensity = (root_id % element_count) / float(element_count)
	
	material.albedo_color = Color(
		0.3 + color_intensity * 0.7,
		0.3 + (1.0 - color_intensity) * 0.5,
		0.8,
		1.0
	)
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.4

func _process(delta):
	time += delta
	operation_timer += delta
	
	if operation_timer >= operation_interval:
		operation_timer = 0.0
		perform_union_find_operation()
	
	animate_union_find()
	animate_indicators()

func perform_union_find_operation():
	current_operation = (current_operation + 1) % UFOperation.size()
	
	match current_operation:
		UFOperation.MAKE_SET:
			reset_all_sets()
		
		UFOperation.UNION:
			perform_random_union()
		
		UFOperation.FIND:
			demonstrate_find_operation()
		
		UFOperation.PATH_COMPRESSION:
			demonstrate_path_compression()
		
		UFOperation.RANK_OPTIMIZATION:
			demonstrate_rank_optimization()

func reset_all_sets():
	# Reset each element to be its own set
	for element in elements:
		element.parent = element
		element.rank = 0
	
	# Clear connections
	clear_connections()
	update_all_materials()
	update_components_count()

func perform_random_union():
	# Union two random elements from different sets
	var available_pairs = []
	
	for i in range(elements.size()):
		for j in range(i + 1, elements.size()):
			if find_root(elements[i]) != find_root(elements[j]):
				available_pairs.append([i, j])
	
	if available_pairs.size() > 0:
		var random_pair = available_pairs[randi() % available_pairs.size()]
		union_elements(elements[random_pair[0]], elements[random_pair[1]])
		recent_union_pairs = [random_pair[0], random_pair[1]]

func union_elements(element1: UFElement, element2: UFElement):
	var root1 = find_root(element1)
	var root2 = find_root(element2)
	
	if root1 == root2:
		return  # Already in same set
	
	# Union by rank
	if root1.rank < root2.rank:
		root1.parent = root2
	elif root1.rank > root2.rank:
		root2.parent = root1
	else:
		root2.parent = root1
		root1.rank += 1
	
	create_connection(element1, element2)
	update_all_materials()
	update_components_count()

func find_root(element: UFElement) -> UFElement:
	# Find with path compression
	if element.parent != element:
		element.parent = find_root(element.parent)
	return element.parent

func find_root_with_path(element: UFElement) -> Array:
	# Returns path to root for visualization
	var path = [element]
	var current = element
	
	while current.parent != current:
		current = current.parent
		path.append(current)
	
	return path

func demonstrate_find_operation():
	# Show find operation on a random element
	if elements.size() > 0:
		var random_element = elements[randi() % elements.size()]
		var path = find_root_with_path(random_element)
		# Path will be highlighted in animation

func demonstrate_path_compression():
	# Create a long chain and then compress it
	if elements.size() >= 4:
		# Create a chain
		for i in range(1, min(5, elements.size())):
			elements[i].parent = elements[i-1]
		
		# Now find the root to trigger path compression
		find_root(elements[min(4, elements.size()-1)])
		update_all_materials()

func demonstrate_rank_optimization():
	# Show how rank affects union operations
	perform_random_union()

func create_connection(element1: UFElement, element2: UFElement):
	var connection = CSGCylinder3D.new()
	var pos1 = element1.visual_object.position
	var pos2 = element2.visual_object.position
	var distance = pos1.distance_to(pos2)
	
	connection.height = distance
	connection.top_radius = 0.05
	connection.bottom_radius = 0.05
	
	# Position and orient
	var mid_point = (pos1 + pos2) * 0.5
	connection.position = mid_point
	
	# Orient connection
	var direction = (pos2 - pos1).normalized()
	if direction != Vector3.UP:
		var axis = Vector3.UP.cross(direction).normalized()
		var angle = acos(Vector3.UP.dot(direction))
		connection.transform.basis = Basis(axis, angle)
	
	# Connection material
	var connection_material = StandardMaterial3D.new()
	connection_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
	connection_material.emission_enabled = true
	connection_material.emission = Color(0.2, 0.2, 0.05, 1.0)
	connection.material_override = connection_material
	
	$Connections.add_child(connection)
	connections.append(connection)

func clear_connections():
	for connection in connections:
		connection.queue_free()
	connections.clear()

func update_all_materials():
	for element in elements:
		var material = element.visual_object.material_override as StandardMaterial3D
		update_element_material(element, material)

func update_components_count():
	var roots = {}
	for element in elements:
		var root = find_root(element)
		roots[root.id] = true
	
	components_count = roots.size()

func animate_union_find():
	match current_operation:
		UFOperation.MAKE_SET:
			animate_make_set()
		
		UFOperation.UNION:
			animate_union_operation()
		
		UFOperation.FIND:
			animate_find_operation()
		
		UFOperation.PATH_COMPRESSION:
			animate_path_compression()
		
		UFOperation.RANK_OPTIMIZATION:
			animate_rank_optimization()

func animate_make_set():
	# Pulse all elements as they become individual sets
	for element in elements:
		var pulse = 1.0 + sin(time * 6.0 + element.id * 0.5) * 0.3
		element.visual_object.scale = Vector3.ONE * pulse

func animate_union_operation():
	# Highlight recently unioned elements
	for i in recent_union_pairs:
		if i < elements.size():
			var pulse = 1.0 + sin(time * 8.0) * 0.5
			elements[i].visual_object.scale = Vector3.ONE * pulse

func animate_find_operation():
	# Create a wave effect showing path traversal
	for i in range(elements.size()):
		var element = elements[i]
		var path_length = get_path_to_root_length(element)
		var wave_phase = time * 4.0 - path_length * 0.3
		var intensity = max(0.0, sin(wave_phase)) * 0.4
		element.visual_object.scale = Vector3.ONE * (1.0 + intensity)

func animate_path_compression():
	# Show compression effect with shrinking paths
	for element in elements:
		var path_length = get_path_to_root_length(element)
		var compression_effect = 1.0 + (1.0 / max(1.0, path_length)) * sin(time * 6.0) * 0.3
		element.visual_object.scale = Vector3.ONE * compression_effect

func animate_rank_optimization():
	# Highlight elements based on their rank
	for element in elements:
		if element == find_root(element):  # Root elements
			var rank_pulse = 1.0 + element.rank * 0.1 + sin(time * 5.0 + element.id) * 0.2
			element.visual_object.scale = Vector3.ONE * rank_pulse
		else:
			element.visual_object.scale = Vector3.ONE

func get_path_to_root_length(element: UFElement) -> int:
	var length = 0
	var current = element
	
	while current.parent != current:
		current = current.parent
		length += 1
	
	return length

func animate_indicators():
	# Component count indicator
	var component_height = components_count * 0.3 + 0.5
	$ComponentIndicator.size.y = component_height
	$ComponentIndicator.position.y = -4 + component_height/2
	
	# Union operation indicator
	var union_height = (current_operation + 1) * 0.2 + 0.3
	$UnionOperationIndicator.size.y = union_height
	$UnionOperationIndicator.position.y = -4 + union_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 3.0) * 0.1
	$ComponentIndicator.scale.x = pulse
	$UnionOperationIndicator.scale.x = pulse
	
	# Animate connections
	for connection in connections:
		var connection_pulse = 1.0 + sin(time * 4.0 + connection.position.x) * 0.2
		connection.scale = Vector3(connection_pulse, 1.0, connection_pulse)

func get_operation_name() -> String:
	match current_operation:
		UFOperation.MAKE_SET:
			return "Make Set"
		UFOperation.UNION:
			return "Union"
		UFOperation.FIND:
			return "Find"
		UFOperation.PATH_COMPRESSION:
			return "Path Compression"
		UFOperation.RANK_OPTIMIZATION:
			return "Rank Optimization"
		_:
			return "Unknown"
