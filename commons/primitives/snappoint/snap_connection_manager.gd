extends Node
class_name SnapConnectionManager

## Manages the graph topology of all snap point connections
## Detects triangles, quads, and tetrahedrons automatically

# Graph structure: adjacency list
var _adjacency: Dictionary = {}  # Node3D -> Array[Node3D]

# Connection objects
var _connections: Dictionary = {}  # String key -> SnapLine instance

# Detected shapes
var _triangles: Dictionary = {}  # String key -> SnapTriangle
var _quads: Dictionary = {}  # String key -> SnapQuad
var _tetrahedrons: Dictionary = {}  # String key -> SnapTetrahedron

# Scene references for instantiation
var _snap_line_scene: PackedScene
var _snap_triangle_scene: PackedScene
var _snap_quad_scene: PackedScene
var _snap_tetrahedron_scene: PackedScene

# Signals
signal connection_created(point_a: Node3D, point_b: Node3D, line: Node3D)
signal connection_broken(point_a: Node3D, point_b: Node3D)
signal triangle_formed(points: Array)
signal quad_formed(points: Array)
signal tetrahedron_formed(points: Array)

func _ready() -> void:
	# Preload scenes
	_snap_line_scene = preload("res://commons/primitives/snappoint/snap_line.tscn")
	_snap_triangle_scene = preload("res://commons/primitives/snappoint/snap_triangle.tscn")
	_snap_tetrahedron_scene = preload("res://commons/primitives/snappoint/snap_tetrahedron.tscn")

func register_snap_point(point: Node3D) -> void:
	if not point in _adjacency:
		_adjacency[point] = []
		print("SnapConnectionManager: Registered point ", point.name)

func unregister_snap_point(point: Node3D) -> void:
	if point in _adjacency:
		# Break all connections to this point
		var connected = _adjacency[point].duplicate()
		for other_point in connected:
			break_connection(point, other_point)
		_adjacency.erase(point)

func create_connection(point_a: Node3D, point_b: Node3D) -> Node3D:
	if not is_instance_valid(point_a) or not is_instance_valid(point_b):
		return null
	
	if point_a == point_b:
		return null
	
	# Check if connection already exists
	var key = _make_connection_key(point_a, point_b)
	if _connections.has(key):
		return _connections[key]
	
	# Register points if not already registered
	if not point_a in _adjacency:
		register_snap_point(point_a)
	if not point_b in _adjacency:
		register_snap_point(point_b)
	
	# Add to adjacency list (undirected edge)
	if point_b not in _adjacency[point_a]:
		_adjacency[point_a].append(point_b)
	if point_a not in _adjacency[point_b]:
		_adjacency[point_b].append(point_a)
	
	# Create the visual line
	var line = _create_snap_line(point_a, point_b)
	_connections[key] = line
	
	print("SnapConnectionManager: Created connection ", key)
	connection_created.emit(point_a, point_b, line)
	
	# Check for new shapes
	_detect_and_create_shapes()
	
	return line

func break_connection(point_a: Node3D, point_b: Node3D) -> void:
	var key = _make_connection_key(point_a, point_b)
	
	if not _connections.has(key):
		return
	
	# Remove from adjacency list
	if point_a in _adjacency and point_b in _adjacency[point_a]:
		_adjacency[point_a].erase(point_b)
	if point_b in _adjacency and point_a in _adjacency[point_b]:
		_adjacency[point_b].erase(point_a)
	
	# Destroy the line
	var line = _connections[key]
	if is_instance_valid(line):
		line.queue_free()
	_connections.erase(key)
	
	connection_broken.emit(point_a, point_b)
	
	# Redetect shapes (some may have been destroyed)
	_detect_and_create_shapes()

func _create_snap_line(point_a: Node3D, point_b: Node3D) -> Node3D:
	if not _snap_line_scene:
		push_error("SnapConnectionManager: snap_line.tscn not loaded")
		return null
	
	var line = _snap_line_scene.instantiate()
	
	# Add to scene tree
	var root = get_tree().current_scene
	if not root:
		root = get_tree().root
	root.add_child(line)
	
	# Set the endpoints
	if line.has_method("set_endpoints"):
		line.set_endpoints(point_a, point_b)
	
	return line

func _make_connection_key(point_a: Node3D, point_b: Node3D) -> String:
	# Create a sorted key so order doesn't matter
	var id_a = point_a.get_instance_id()
	var id_b = point_b.get_instance_id()
	if id_a < id_b:
		return str(id_a) + "|" + str(id_b)
	else:
		return str(id_b) + "|" + str(id_a)

func _make_shape_key(points: Array) -> String:
	# Create sorted key from multiple points
	var ids: Array[int] = []
	for point in points:
		if is_instance_valid(point):
			ids.append(point.get_instance_id())
	ids.sort()
	var key = ""
	for id in ids:
		if key != "":
			key += "|"
		key += str(id)
	return key

func _detect_and_create_shapes() -> void:
	# Clear existing shape tracking (we'll rebuild)
	_clear_invalid_shapes()
	
	# Detect triangles (3-cycles)
	_detect_triangles()
	
	# Detect tetrahedrons (complete graph K4)
	_detect_tetrahedrons()
	
	# Note: Quads are detected from triangles sharing edges

func _detect_triangles() -> void:
	var found_triangles: Dictionary = {}
	
	# For each point, try to find triangles containing it
	for point_a in _adjacency.keys():
		if not is_instance_valid(point_a):
			continue
		
		var neighbors_a = _adjacency[point_a]
		
		# Check all pairs of neighbors
		for i in range(neighbors_a.size()):
			var point_b = neighbors_a[i]
			if not is_instance_valid(point_b):
				continue
			
			for j in range(i + 1, neighbors_a.size()):
				var point_c = neighbors_a[j]
				if not is_instance_valid(point_c):
					continue
				
				# Check if B and C are connected (forming triangle A-B-C)
				if are_points_connected(point_b, point_c):
					var triangle_points = [point_a, point_b, point_c]
					var key = _make_shape_key(triangle_points)
					
					if not found_triangles.has(key):
						found_triangles[key] = triangle_points

	# Create or update triangles
	for key in found_triangles.keys():
		if not _triangles.has(key):
			_create_triangle(found_triangles[key])

	# Remove triangles that no longer exist
	var keys_to_remove: Array[String] = []
	for key in _triangles.keys():
		if not found_triangles.has(key):
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		_destroy_triangle(key)

func _detect_tetrahedrons() -> void:
	var found_tetrahedrons: Dictionary = {}
	
	# A tetrahedron needs 4 points all connected to each other (6 edges total)
	for point_a in _adjacency.keys():
		if not is_instance_valid(point_a):
			continue
		
		var neighbors_a = _adjacency[point_a]
		if neighbors_a.size() < 3:
			continue
		
		# Check all triples of neighbors
		for i in range(neighbors_a.size()):
			var point_b = neighbors_a[i]
			if not is_instance_valid(point_b):
				continue
			
			for j in range(i + 1, neighbors_a.size()):
				var point_c = neighbors_a[j]
				if not is_instance_valid(point_c):
					continue
				
				for k in range(j + 1, neighbors_a.size()):
					var point_d = neighbors_a[k]
					if not is_instance_valid(point_d):
						continue
					
					# Check if all pairs are connected (complete graph K4)
					if are_points_connected(point_b, point_c) and \
					   are_points_connected(point_b, point_d) and \
					   are_points_connected(point_c, point_d):
						var tetra_points = [point_a, point_b, point_c, point_d]
						var key = _make_shape_key(tetra_points)
						
						if not found_tetrahedrons.has(key):
							found_tetrahedrons[key] = tetra_points

	# Create or update tetrahedrons
	for key in found_tetrahedrons.keys():
		if not _tetrahedrons.has(key):
			_create_tetrahedron(found_tetrahedrons[key])

	# Remove tetrahedrons that no longer exist
	var keys_to_remove: Array[String] = []
	for key in _tetrahedrons.keys():
		if not found_tetrahedrons.has(key):
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		_destroy_tetrahedron(key)

func _create_triangle(points: Array) -> void:
	var key = _make_shape_key(points)
	
	if not _snap_triangle_scene:
		push_error("SnapConnectionManager: snap_triangle.tscn not loaded")
		return
	
	var triangle_node = _snap_triangle_scene.instantiate()
	triangle_node.name = "Triangle_" + key.substr(0, 8)
	
	var root = get_tree().current_scene
	if not root:
		root = get_tree().root
	root.add_child(triangle_node)
	
	# Setup the triangle with the 3 points
	if triangle_node.has_method("setup"):
		triangle_node.setup(points[0], points[1], points[2])
	
	_triangles[key] = triangle_node
	triangle_formed.emit(points)
	
	print("SnapConnectionManager: Created triangle with points: ", points[0].name, ", ", points[1].name, ", ", points[2].name)

func _destroy_triangle(key: String) -> void:
	if _triangles.has(key):
		var triangle = _triangles[key]
		if is_instance_valid(triangle):
			triangle.queue_free()
		_triangles.erase(key)

func _create_tetrahedron(points: Array) -> void:
	var key = _make_shape_key(points)
	
	if not _snap_tetrahedron_scene:
		push_error("SnapConnectionManager: snap_tetrahedron.tscn not loaded")
		return
	
	var tetra_node = _snap_tetrahedron_scene.instantiate()
	tetra_node.name = "Tetrahedron_" + key.substr(0, 8)
	
	var root = get_tree().current_scene
	if not root:
		root = get_tree().root
	root.add_child(tetra_node)
	
	# Setup the tetrahedron with the 4 points
	if tetra_node.has_method("setup"):
		tetra_node.setup(points[0], points[1], points[2], points[3])
	
	_tetrahedrons[key] = tetra_node
	tetrahedron_formed.emit(points)
	
	print("SnapConnectionManager: Created tetrahedron with 4 points")

func _destroy_tetrahedron(key: String) -> void:
	if _tetrahedrons.has(key):
		var tetra = _tetrahedrons[key]
		if is_instance_valid(tetra):
			tetra.queue_free()
		_tetrahedrons.erase(key)

func _clear_invalid_shapes() -> void:
	# Remove shapes with invalid point references
	var invalid_triangles: Array[String] = []
	for key in _triangles.keys():
		var triangle = _triangles[key]
		if not is_instance_valid(triangle):
			invalid_triangles.append(key)
	
	for key in invalid_triangles:
		_triangles.erase(key)

func are_points_connected(point_a: Node3D, point_b: Node3D) -> bool:
	if not point_a in _adjacency:
		return false
	return point_b in _adjacency[point_a]

func get_connections_for_point(point: Node3D) -> Array[Node3D]:
	if point in _adjacency:
		return _adjacency[point].duplicate()
	return []

func get_all_triangles() -> Array:
	return _triangles.values()

func get_all_tetrahedrons() -> Array:
	return _tetrahedrons.values()
