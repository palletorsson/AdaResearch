# RandomProfile.gd
# Creates a random height profile using pure randomness
# Profile is 1 meter wide with n points, starts and ends at 0.5

extends Node3D

@export var point_count: int = 5
@export var profile_width: float = 1.0
@export var max_height_variation: float = 0.3

var rng = RandomNumberGenerator.new()
var profile_points: Array[Vector3] = []
var profile_mesh: MeshInstance3D

func _ready():
	# Initialize random generator
	rng.randomize()
	
	# Get reference to the existing RandomPlane from the scene
	profile_mesh = $RandomPlane
	if not profile_mesh:
		print("ERROR: RandomPlane node not found in scene!")
		return
	
	# Generate the random profile
	generate_random_profile()
	
	print("SimpleRandomProfile: Created profile with %d points using RandomPlane" % point_count)

func generate_random_profile():
	"""Generate a random height profile using pure randomness"""
	profile_points.clear()
	
	# Calculate spacing between points
	var spacing = profile_width / float(point_count - 1)
	
	# Generate points along the profile
	for i in range(point_count):
		var x_position = i * spacing - (profile_width / 2.0)  # Center the profile
		var height = _calculate_random_height_at_index(i)
		
		# Create point
		var point = Vector3(x_position, height, 0)
		profile_points.append(point)
		
		print("Point %d: x=%.3f, height=%.3f" % [i, x_position, height])
	
	# Create visual representation using the RandomPlane
	_create_profile_mesh()

func _calculate_random_height_at_index(index: int) -> float:
	"""Calculate random height ensuring start and end are at 1.0"""
	var base_height = 1.0
	
	# Force first and last points to 1.0
	if index == 0 or index == point_count - 1:
		return base_height
	
	# For middle points, add random variation
	var random_variation = rng.randf_range(-max_height_variation, max_height_variation)
	
	# Optional: reduce variation near edges for smoother transition
	var edge_factor = 1.0
	var normalized_position = float(index) / float(point_count - 1)
	
	if normalized_position < 0.3:  # Near start
		edge_factor = normalized_position / 0.3
	elif normalized_position > 0.7:  # Near end
		edge_factor = (1.0 - normalized_position) / 0.3
	
	return base_height + (random_variation * edge_factor)

func _create_profile_mesh():
	"""Create a visual mesh representation of the profile using vertices"""
	if profile_points.size() < 2:
		return
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create a plane that follows the profile shape
	var depth = 0.1  # Small depth for the profile plane
	var subdivisions = profile_points.size() - 1
	
	# Generate vertices for the profile surface
	for i in range(profile_points.size() - 1):
		var p1 = profile_points[i]
		var p2 = profile_points[i + 1]
		
		# Create two triangles for each segment
		# Bottom edge (y=0)
		var bottom_p1 = Vector3(p1.x, 0, -depth/2)
		var bottom_p2 = Vector3(p2.x, 0, -depth/2)
		var bottom_p1_back = Vector3(p1.x, 0, depth/2)
		var bottom_p2_back = Vector3(p2.x, 0, depth/2)
		
		# Top edge (following profile)
		var top_p1 = Vector3(p1.x, p1.y, -depth/2)
		var top_p2 = Vector3(p2.x, p2.y, -depth/2)
		var top_p1_back = Vector3(p1.x, p1.y, depth/2)
		var top_p2_back = Vector3(p2.x, p2.y, depth/2)
		
		# Front face triangles
		surface_tool.set_normal(Vector3(0, 0, 1))
		_add_quad(surface_tool, bottom_p1, bottom_p2, top_p2, top_p1)
		
		# Back face triangles
		surface_tool.set_normal(Vector3(0, 0, -1))
		_add_quad(surface_tool, bottom_p1_back, top_p1_back, top_p2_back, bottom_p2_back)
		
		# Top face (if there's height)
		if p1.y > 0.01 or p2.y > 0.01:
			surface_tool.set_normal(Vector3(0, 1, 0))
			_add_quad(surface_tool, top_p1, top_p2, top_p2_back, top_p1_back)
		
		# Bottom face
		surface_tool.set_normal(Vector3(0, -1, 0))
		_add_quad(surface_tool, bottom_p1, bottom_p1_back, bottom_p2_back, bottom_p2)
	
	# Add side caps (left and right ends)
	if profile_points.size() >= 2:
		var first_point = profile_points[0]
		var last_point = profile_points[-1]
		
		# Left side cap (first point)
		surface_tool.set_normal(Vector3(-1, 0, 0))
		var left_bottom_front = Vector3(first_point.x, 0, -depth/2)
		var left_bottom_back = Vector3(first_point.x, 0, depth/2)
		var left_top_front = Vector3(first_point.x, first_point.y, -depth/2)
		var left_top_back = Vector3(first_point.x, first_point.y, depth/2)
		_add_quad(surface_tool, left_bottom_front, left_top_front, left_top_back, left_bottom_back)
		
		# Right side cap (last point)
		surface_tool.set_normal(Vector3(1, 0, 0))
		var right_bottom_front = Vector3(last_point.x, 0, -depth/2)
		var right_bottom_back = Vector3(last_point.x, 0, depth/2)
		var right_top_front = Vector3(last_point.x, last_point.y, -depth/2)
		var right_top_back = Vector3(last_point.x, last_point.y, depth/2)
		_add_quad(surface_tool, right_bottom_front, right_bottom_back, right_top_back, right_top_front)
	
	# Create and assign the mesh
	var mesh = surface_tool.commit()
	profile_mesh.mesh = mesh
	
	print("Profile mesh created with %d points" % profile_points.size())

func _add_quad(surface_tool: SurfaceTool, p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3):
	"""Helper function to add a quad as two triangles"""
	# Calculate UVs based on position
	surface_tool.set_uv(Vector2(0, 0))
	surface_tool.add_vertex(p1)
	
	surface_tool.set_uv(Vector2(1, 0))
	surface_tool.add_vertex(p2)
	
	surface_tool.set_uv(Vector2(1, 1))
	surface_tool.add_vertex(p3)
	
	# Second triangle
	surface_tool.set_uv(Vector2(0, 0))
	surface_tool.add_vertex(p1)
	
	surface_tool.set_uv(Vector2(1, 1))
	surface_tool.add_vertex(p3)
	
	surface_tool.set_uv(Vector2(0, 1))
	surface_tool.add_vertex(p4)

func regenerate_profile():
	"""Generate a new random profile"""
	generate_random_profile()

func set_point_count(new_count: int):
	"""Change the number of points in the profile"""
	point_count = max(3, new_count)  # Minimum 3 points
	generate_random_profile()

func set_height_variation(variation: float):
	"""Change the maximum height variation"""
	max_height_variation = max(0.0, variation)
	generate_random_profile()

func get_height_at_distance(distance: float) -> float:
	"""Get interpolated height at any distance along the profile"""
	if profile_points.size() < 2:
		return 1.0
	
	# Clamp distance to profile bounds
	distance = clamp(distance, 0.0, profile_width)
	
	# Find the two points to interpolate between
	for i in range(profile_points.size() - 1):
		var p1 = profile_points[i]
		var p2 = profile_points[i + 1]
		
		if distance >= p1.x and distance <= p2.x:
			# Linear interpolation between p1 and p2
			var t = (distance - p1.x) / (p2.x - p1.x)
			return lerp(p1.y, p2.y, t)
	
	# Fallback
	return 1.0

func get_random_heights_array() -> Array[float]:
	"""Return just the height values as an array"""
	var heights: Array[float] = []
	for point in profile_points:
		heights.append(point.y)
	return heights

func get_profile_as_string() -> String:
	"""Return profile as formatted string"""
	var result = "Random Profile: "
	for i in range(profile_points.size()):
		var point = profile_points[i]
		result += "%.2f" % point.y
		if i < profile_points.size() - 1:
			result += ", "
	return result
