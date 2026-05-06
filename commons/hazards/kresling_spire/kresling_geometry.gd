extends RefCounted
class_name KreslingGeometry
## Kresling origami cylinder geometry solver.
## A twisting cylinder that compresses from tall tower to flat disc.

# Pattern parameters
var radial_segments: int = 6
var layers: int = 4
var radius: float = 0.3
var edge_length: float = 0.25  # Length of diagonal edges

# Computed geometry
var vertices: PackedVector3Array = []
var faces: Array[PackedInt32Array] = []  # Triangular faces
var creases: Array[Vector2i] = []

# Ring vertices storage [layer][segment]
var _rings: Array = []


func build_pattern(p_segments: int, p_layers: int, p_radius: float, p_edge: float) -> void:
	radial_segments = max(4, p_segments)
	layers = max(1, p_layers)
	radius = max(0.05, p_radius)
	edge_length = max(0.05, p_edge)
	
	vertices.clear()
	faces.clear()
	creases.clear()
	_rings.clear()


func solve_twist(twist_amount: float) -> void:
	## Apply twist transformation.
	## twist_amount: 0 = fully extended (tall), 1 = fully compressed (flat disc)
	
	twist_amount = clamp(twist_amount, 0.0, 0.98)
	
	vertices.clear()
	faces.clear()
	creases.clear()
	_rings.clear()
	
	var n: int = radial_segments
	var m: int = layers
	
	# Kresling kinematics:
	# The twist angle per layer determines height
	# Max twist = 2π/n (fully collapsed)
	# Zero twist = fully extended
	
	var max_twist: float = TAU / float(n) * 0.95
	var twist_per_layer: float = twist_amount * max_twist
	
	# Calculate layer height from twist angle
	# Using the Kresling kinematic relationship:
	# h = sqrt(L² - 2R²(1 - cos(2π/n - φ)))
	# where L = edge length, R = radius, φ = twist angle
	
	var angle_step: float = TAU / float(n)
	var chord_angle: float = angle_step - twist_per_layer
	var height_sq: float = edge_length * edge_length - 2.0 * radius * radius * (1.0 - cos(chord_angle))
	var layer_height: float = sqrt(max(0.001, height_sq))
	
	# Generate vertices ring by ring
	_rings.resize(m + 1)
	
	for layer in range(m + 1):
		var ring: PackedInt32Array = []
		var layer_twist: float = layer * twist_per_layer
		var layer_y: float = layer * layer_height
		
		for seg in range(n):
			var angle: float = angle_step * float(seg) + layer_twist
			var x: float = cos(angle) * radius
			var z: float = sin(angle) * radius
			
			var idx: int = vertices.size()
			vertices.append(Vector3(x, layer_y, z))
			ring.append(idx)
		
		_rings[layer] = ring
	
	# Generate triangular faces
	for layer in range(m):
		var lower: PackedInt32Array = _rings[layer]
		var upper: PackedInt32Array = _rings[layer + 1]
		
		for seg in range(n):
			var next_seg: int = (seg + 1) % n
			
			# Lower-pointing triangle
			var v0: int = lower[seg]
			var v1: int = lower[next_seg]
			var v2: int = upper[seg]
			faces.append(PackedInt32Array([v0, v1, v2]))
			
			# Upper-pointing triangle
			var v3: int = upper[seg]
			var v4: int = lower[next_seg]
			var v5: int = upper[next_seg]
			faces.append(PackedInt32Array([v3, v4, v5]))
			
			# Creases
			_add_crease(v0, v1)  # Bottom horizontal
			_add_crease(v0, v2)  # Left diagonal
			_add_crease(v1, v2)  # Right diagonal (shared)
			_add_crease(v2, v5)  # Top horizontal
	
	# Center vertically
	_center_vertices()


func _add_crease(v0: int, v1: int) -> void:
	var edge: Vector2i = Vector2i(min(v0, v1), max(v0, v1))
	if edge not in creases:
		creases.append(edge)


func _center_vertices() -> void:
	if vertices.is_empty():
		return
	
	# Center horizontally and put base at y=0
	var min_y: float = INF
	var center_xz: Vector2 = Vector2.ZERO
	
	for v in vertices:
		min_y = min(min_y, v.y)
		center_xz += Vector2(v.x, v.z)
	center_xz /= float(vertices.size())
	
	for i in range(vertices.size()):
		vertices[i].x -= center_xz.x
		vertices[i].z -= center_xz.y
		vertices[i].y -= min_y


func get_height() -> float:
	if vertices.is_empty():
		return 0.0
	
	var max_y: float = 0.0
	for v in vertices:
		max_y = max(max_y, v.y)
	return max_y


func get_top_center() -> Vector3:
	## Get the center of the top ring.
	if _rings.is_empty() or vertices.is_empty():
		return Vector3.ZERO
	
	var top_ring: PackedInt32Array = _rings[_rings.size() - 1]
	var center: Vector3 = Vector3.ZERO
	
	for idx in top_ring:
		center += vertices[idx]
	
	return center / float(top_ring.size())
