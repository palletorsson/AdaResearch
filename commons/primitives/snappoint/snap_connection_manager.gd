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
var _wedges: Dictionary = {}  # String key -> Array of 6 points
var _octahedrons: Dictionary = {}  # String key -> Array of 6 points
var _square_pyramids: Dictionary = {}  # String key -> Array of 5 points

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
signal wedge_formed(points: Array)
signal octahedron_formed(points: Array)
signal square_pyramid_formed(points: Array)

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
	
	# Detect octahedrons (6 points: 4 equatorial + 2 polar)
	_detect_octahedrons()
	
	# Detect square pyramids (5 points: 4 base + 1 apex)
	_detect_square_pyramids()
	
	# Detect wedges (6 points: rectangle base + top edge)
	_detect_wedges()
	
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

func _detect_wedges() -> void:
	var found_wedges: Dictionary = {}
	
	# A wedge/prism needs 6 points:
	# - 4 points forming a rectangle (base)
	# - 2 points forming the top edge (creating the sloped faces)
	# The wedge has 2 triangular ends + 3 rectangular faces (base + 2 slopes)
	
	# Strategy: Find all sets of 4 points forming rectangles, then check for 2 more points
	# that form the top edge to create the wedge shape
	
	for point_a in _adjacency.keys():
		if not is_instance_valid(point_a):
			continue
		
		var neighbors_a = _adjacency[point_a]
		if neighbors_a.size() < 2:
			continue
		
		# Try all combinations of 4 points that might form a rectangle
		for i in range(neighbors_a.size()):
			var point_b = neighbors_a[i]
			if not is_instance_valid(point_b):
				continue
			
			for j in range(i + 1, neighbors_a.size()):
				var point_c = neighbors_a[j]
				if not is_instance_valid(point_c):
					continue
				
				# Now we have A, B, C - check if there's a D that completes a rectangle
				# Rectangle pattern: A connects to B and C, and B connects to D, C connects to D
				var neighbors_b = _adjacency[point_b]
				var neighbors_c = _adjacency[point_c]
				
				for point_d in neighbors_b:
					if not is_instance_valid(point_d):
						continue
					if point_d == point_a or point_d == point_c:
						continue
					
					# Check if D is also connected to C (forming rectangle A-B-D-C)
					if are_points_connected(point_c, point_d):
						# We have a potential rectangle: A-B-D-C (base of wedge)
						# Now look for 2 more points (E and F) that form the top edge
						
						var rect_points = [point_a, point_b, point_d, point_c]
						
						# Check all pairs of remaining points for the top edge
						for point_e in _adjacency.keys():
							if not is_instance_valid(point_e):
								continue
							if point_e in rect_points:
								continue
							
							for point_f in _adjacency.keys():
								if not is_instance_valid(point_f):
									continue
								if point_f in rect_points or point_f == point_e:
									continue
								
								# Check if E and F are connected to each other (top edge)
								if not are_points_connected(point_e, point_f):
									continue
								
								# Check if E and F each connect to 2 corners of the rectangle
								# This forms the proper wedge/prism shape
								var e_connections = 0
								var f_connections = 0
								for rect_point in rect_points:
									if are_points_connected(point_e, rect_point):
										e_connections += 1
									if are_points_connected(point_f, rect_point):
										f_connections += 1
								
								# For a valid wedge: each top point connects to 2 base corners
								if e_connections >= 2 and f_connections >= 2:
									var wedge_points = rect_points + [point_e, point_f]
									var key = _make_shape_key(wedge_points)
									
									if not found_wedges.has(key):
										found_wedges[key] = wedge_points

	# Emit signals for new wedges
	for key in found_wedges.keys():
		if not _wedges.has(key):
			_wedges[key] = found_wedges[key]
			wedge_formed.emit(found_wedges[key])
			print("SnapConnectionManager: Detected wedge with 6 points")

	# Remove wedges that no longer exist
	var keys_to_remove: Array[String] = []
	for key in _wedges.keys():
		if not found_wedges.has(key):
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		_wedges.erase(key)
		print("SnapConnectionManager: Removed wedge")

func _detect_octahedrons() -> void:
	var found_octahedrons: Dictionary = {}
	
	# An octahedron has 6 vertices: 4 forming an equatorial plane, 2 polar vertices (top/bottom)
	# Each polar vertex connects to all 4 equatorial vertices
	# Equatorial vertices each have exactly 4 connections: 2 to other equatorial points, 2 to polar points
	# Polar vertices each have exactly 4 connections: all to equatorial points
	
	# Debug: count all points and their connections
	var total_points = 0
	var points_with_4_connections = 0
	for point in _adjacency.keys():
		if is_instance_valid(point):
			total_points += 1
			if _adjacency[point].size() == 4:
				points_with_4_connections += 1
	
	if total_points == 6:
		print("SnapConnectionManager: Checking octahedron - %d total points, %d with 4 connections" % [total_points, points_with_4_connections])
	
	# Find all points with exactly 4 connections (potential octahedron vertices)
	var candidates = []
	for point in _adjacency.keys():
		if is_instance_valid(point) and _adjacency[point].size() == 4:
			candidates.append(point)
	
	# Need at least 6 points for an octahedron
	if candidates.size() < 6:
		if total_points == 6 and candidates.size() > 0:
			print("SnapConnectionManager: Not enough candidates with 4 connections (%d/6)" % candidates.size())
		return
	
	# Try all combinations of 6 points
	for i in range(candidates.size()):
		var p1 = candidates[i]
		for j in range(i + 1, candidates.size()):
			var p2 = candidates[j]
			for k in range(j + 1, candidates.size()):
				var p3 = candidates[k]
				for l in range(k + 1, candidates.size()):
					var p4 = candidates[l]
					for m in range(l + 1, candidates.size()):
						var p5 = candidates[m]
						for n in range(m + 1, candidates.size()):
							var p6 = candidates[n]
							
							var test_points = [p1, p2, p3, p4, p5, p6]
							
							# Debug: Check connection count for these 6 points
							var all_connected_properly = true
							for pt in test_points:
								var connections_in_set = 0
								for other_pt in test_points:
									if other_pt != pt and are_points_connected(pt, other_pt):
										connections_in_set += 1
								if connections_in_set != 4:
									all_connected_properly = false
									break
							
							if not all_connected_properly:
								continue  # Skip this combination
							
							# All 6 points have exactly 4 connections to each other - potential octahedron!
							print("SnapConnectionManager: Testing 6-point set where all have 4 connections")
							
							# Find the two polar vertices: they are the only pair NOT connected to each other
							var polar_points = []
							var found_polar_pair = false
							
							for p_i in range(test_points.size()):
								for p_j in range(p_i + 1, test_points.size()):
									if not are_points_connected(test_points[p_i], test_points[p_j]):
										# Found the two points that aren't connected - these are the polar vertices!
										polar_points = [test_points[p_i], test_points[p_j]]
										found_polar_pair = true
										print("SnapConnectionManager: Found polar pair (not connected to each other)")
										break
								if found_polar_pair:
									break
							
							if polar_points.size() != 2:
								print("SnapConnectionManager: ✗ No polar pair found (all points connected)")
								continue
							
							# The remaining 4 points are the equatorial square
							var equatorial_points = []
							for point in test_points:
								if point not in polar_points:
									equatorial_points.append(point)
							
							# Validate: Each polar connects to all 4 equatorial
							var valid_octahedron = true
							for polar in polar_points:
								for eq in equatorial_points:
									if not are_points_connected(polar, eq):
										valid_octahedron = false
										print("SnapConnectionManager: ✗ Polar not connected to equatorial")
										break
								if not valid_octahedron:
									break
							
							# Validate: Equatorial points form a square (4-cycle)
							if valid_octahedron:
								for eq in equatorial_points:
									var eq_to_eq_connections = 0
									for other_eq in equatorial_points:
										if other_eq != eq and are_points_connected(eq, other_eq):
											eq_to_eq_connections += 1
									if eq_to_eq_connections != 2:
										valid_octahedron = false
										print("SnapConnectionManager: ✗ Equatorial square invalid")
										break
							
							if valid_octahedron:
								print("SnapConnectionManager: ✓✓✓ FOUND VALID OCTAHEDRON! 2 polar + 4 equatorial")
								var key = _make_shape_key(test_points)
								if not found_octahedrons.has(key):
									found_octahedrons[key] = test_points
	
	# Emit signals for new octahedrons
	for key in found_octahedrons.keys():
		if not _octahedrons.has(key):
			_octahedrons[key] = found_octahedrons[key]
			octahedron_formed.emit(found_octahedrons[key])
			print("SnapConnectionManager: Detected octahedron with 6 points")
	
	# Remove octahedrons that no longer exist
	var keys_to_remove: Array[String] = []
	for key in _octahedrons.keys():
		if not found_octahedrons.has(key):
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		_octahedrons.erase(key)
		print("SnapConnectionManager: Removed octahedron")

func _detect_square_pyramids() -> void:
	var found_pyramids: Dictionary = {}
	
	# A square pyramid has 5 vertices: 4 forming the base square, 1 apex above/below
	# The apex connects to all 4 base vertices
	# Base vertices form a square (4-cycle)
	
	for point_a in _adjacency.keys():
		if not is_instance_valid(point_a):
			continue
		
		var neighbors_a = _adjacency[point_a]
		if neighbors_a.size() < 2:
			continue
		
		# Try to find a square base starting with A
		for i in range(neighbors_a.size()):
			var point_b = neighbors_a[i]
			if not is_instance_valid(point_b):
				continue
			
			# Try to find point C that forms angle at B
			var neighbors_b = _adjacency[point_b]
			for point_c in neighbors_b:
				if not is_instance_valid(point_c):
					continue
				if point_c == point_a:
					continue
				
				# Try to find point D that completes the square A-B-C-D
				var neighbors_c = _adjacency[point_c]
				for point_d in neighbors_c:
					if not is_instance_valid(point_d):
						continue
					if point_d == point_a or point_d == point_b:
						continue
					
					# Check if D connects back to A (completing the square base)
					if not are_points_connected(point_d, point_a):
						continue
					
					# We have a potential square base: A-B-C-D
					var base_points = [point_a, point_b, point_c, point_d]
					
					# Now find an apex that connects to all 4 base points
					for point_apex in _adjacency.keys():
						if not is_instance_valid(point_apex):
							continue
						if point_apex in base_points:
							continue
						
						# Check if apex connects to all 4 base points
						var connects_to_all = true
						for base_point in base_points:
							if not are_points_connected(point_apex, base_point):
								connects_to_all = false
								break
						
						if connects_to_all:
							var pyramid_points = base_points + [point_apex]
							var key = _make_shape_key(pyramid_points)
							
							if not found_pyramids.has(key):
								found_pyramids[key] = pyramid_points
	
	# Emit signals for new square pyramids
	for key in found_pyramids.keys():
		if not _square_pyramids.has(key):
			_square_pyramids[key] = found_pyramids[key]
			square_pyramid_formed.emit(found_pyramids[key])
			print("SnapConnectionManager: Detected square pyramid with 5 points")
	
	# Remove square pyramids that no longer exist
	var keys_to_remove: Array[String] = []
	for key in _square_pyramids.keys():
		if not found_pyramids.has(key):
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		_square_pyramids.erase(key)
		print("SnapConnectionManager: Removed square pyramid")

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
