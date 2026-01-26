class_name GeometryUtils
extends RefCounted

## GeometryUtils - Static functions for geometric relationship validation
##
## Category Theory perspective: These functions define morphisms between lines.
## A form is characterized by the pattern of relationships between its elements.

## Tolerance constants (can be overridden per-call)
const DEFAULT_POSITION_TOLERANCE: float = 0.05  # 5cm for point matching
const DEFAULT_ANGLE_TOLERANCE: float = 0.26     # ~15 degrees (cos(15°) ≈ 0.966)


## Check if two lines are parallel (same or opposite direction)
## Returns true if direction vectors are nearly collinear
static func are_parallel(line_a_start: Vector3, line_a_end: Vector3,
						  line_b_start: Vector3, line_b_end: Vector3,
						  tolerance: float = DEFAULT_ANGLE_TOLERANCE) -> bool:
	var dir_a = (line_a_end - line_a_start).normalized()
	var dir_b = (line_b_end - line_b_start).normalized()

	# Parallel if dot product is close to 1 or -1
	var dot = abs(dir_a.dot(dir_b))
	return dot > 1.0 - tolerance


## Check if two lines are perpendicular (90 degree angle)
## Returns true if direction vectors are nearly orthogonal
static func are_perpendicular(line_a_start: Vector3, line_a_end: Vector3,
							   line_b_start: Vector3, line_b_end: Vector3,
							   tolerance: float = DEFAULT_ANGLE_TOLERANCE) -> bool:
	var dir_a = (line_a_end - line_a_start).normalized()
	var dir_b = (line_b_end - line_b_start).normalized()

	# Perpendicular if dot product is close to 0
	var dot = abs(dir_a.dot(dir_b))
	return dot < tolerance


## Check if two lines share an endpoint (are connected)
## Returns true if any endpoint of line_a is close to any endpoint of line_b
static func are_connected(line_a_start: Vector3, line_a_end: Vector3,
						   line_b_start: Vector3, line_b_end: Vector3,
						   tolerance: float = DEFAULT_POSITION_TOLERANCE) -> bool:
	var a_points = [line_a_start, line_a_end]
	var b_points = [line_b_start, line_b_end]

	for pa in a_points:
		for pb in b_points:
			if pa.distance_to(pb) < tolerance:
				return true
	return false


## Get the shared vertex between two connected lines
## Returns Vector3.INF if no shared vertex found
static func get_shared_vertex(line_a_start: Vector3, line_a_end: Vector3,
							   line_b_start: Vector3, line_b_end: Vector3,
							   tolerance: float = DEFAULT_POSITION_TOLERANCE) -> Vector3:
	var a_points = [line_a_start, line_a_end]
	var b_points = [line_b_start, line_b_end]

	for pa in a_points:
		for pb in b_points:
			if pa.distance_to(pb) < tolerance:
				return (pa + pb) / 2.0  # Return midpoint for precision
	return Vector3.INF


## Check if two lines have equal length
static func are_equal_length(line_a_start: Vector3, line_a_end: Vector3,
							  line_b_start: Vector3, line_b_end: Vector3,
							  tolerance: float = DEFAULT_POSITION_TOLERANCE) -> bool:
	var len_a = line_a_start.distance_to(line_a_end)
	var len_b = line_b_start.distance_to(line_b_end)
	return absf(len_a - len_b) < tolerance


## Get the angle between two lines in radians
static func get_angle_between(line_a_start: Vector3, line_a_end: Vector3,
							   line_b_start: Vector3, line_b_end: Vector3) -> float:
	var dir_a = (line_a_end - line_a_start).normalized()
	var dir_b = (line_b_end - line_b_start).normalized()
	return acos(clampf(dir_a.dot(dir_b), -1.0, 1.0))


## Check if lines form a closed loop (polygon)
## Each endpoint must connect to exactly one other line's endpoint
## Returns true if lines form a valid closed cycle
static func forms_closed_loop(line_endpoints: Array, tolerance: float = DEFAULT_POSITION_TOLERANCE) -> bool:
	# line_endpoints is Array of [start: Vector3, end: Vector3] pairs
	if line_endpoints.size() < 3:
		return false

	# Build vertex adjacency: count how many line endpoints touch each point
	var vertices: Array[Vector3] = []
	var vertex_counts: Array[int] = []

	for line in line_endpoints:
		var start: Vector3 = line[0]
		var end: Vector3 = line[1]

		_add_or_increment_vertex(vertices, vertex_counts, start, tolerance)
		_add_or_increment_vertex(vertices, vertex_counts, end, tolerance)

	# For a closed loop, each vertex should have exactly 2 connections
	# (one line coming in, one going out)
	for count in vertex_counts:
		if count != 2:
			return false

	# Also need exactly N vertices for N lines
	return vertices.size() == line_endpoints.size()


## Helper: Add vertex to list or increment count if it exists
static func _add_or_increment_vertex(vertices: Array[Vector3], counts: Array[int],
									  point: Vector3, tolerance: float) -> void:
	for i in range(vertices.size()):
		if vertices[i].distance_to(point) < tolerance:
			counts[i] += 1
			return
	vertices.append(point)
	counts.append(1)


## Check if two lines intersect (not just at endpoints)
## Returns true if the lines cross each other
static func do_intersect(line_a_start: Vector3, line_a_end: Vector3,
						  line_b_start: Vector3, line_b_end: Vector3,
						  tolerance: float = DEFAULT_POSITION_TOLERANCE) -> bool:
	# Project to 2D (using Y=0 plane for XZ intersection, or the plane of the lines)
	# For 3D lines, we check closest approach distance
	var intersection = get_intersection_point(line_a_start, line_a_end, line_b_start, line_b_end)
	if intersection == Vector3.INF:
		return false

	# Check if intersection is within both segments (not at endpoints)
	var t_a = _get_parameter_on_segment(line_a_start, line_a_end, intersection)
	var t_b = _get_parameter_on_segment(line_b_start, line_b_end, intersection)

	# Interior intersection: t in (tolerance, 1-tolerance) for both
	var margin = 0.05
	return t_a > margin and t_a < (1.0 - margin) and t_b > margin and t_b < (1.0 - margin)


## Get intersection point of two lines (may be outside segments)
## Returns Vector3.INF if lines are parallel or don't intersect in 3D
static func get_intersection_point(line_a_start: Vector3, line_a_end: Vector3,
									line_b_start: Vector3, line_b_end: Vector3) -> Vector3:
	var d1 = line_a_end - line_a_start
	var d2 = line_b_end - line_b_start
	var d3 = line_b_start - line_a_start

	var cross_d1_d2 = d1.cross(d2)
	var cross_d3_d2 = d3.cross(d2)

	var denom = cross_d1_d2.length_squared()
	if denom < 0.0001:  # Lines are parallel
		return Vector3.INF

	var t = cross_d3_d2.dot(cross_d1_d2) / denom
	return line_a_start + d1 * t


## Get parameter t for where point lies on segment (0 = start, 1 = end)
static func _get_parameter_on_segment(seg_start: Vector3, seg_end: Vector3, point: Vector3) -> float:
	var seg = seg_end - seg_start
	var seg_len_sq = seg.length_squared()
	if seg_len_sq < 0.0001:
		return 0.0
	return (point - seg_start).dot(seg) / seg_len_sq


## Check if lines intersect at their centers (for cross/plus patterns)
static func intersect_at_centers(line_a_start: Vector3, line_a_end: Vector3,
								  line_b_start: Vector3, line_b_end: Vector3,
								  tolerance: float = DEFAULT_POSITION_TOLERANCE) -> bool:
	var center_a = (line_a_start + line_a_end) / 2.0
	var center_b = (line_b_start + line_b_end) / 2.0
	return center_a.distance_to(center_b) < tolerance


## Check if a point lies on a line segment
static func point_on_segment(seg_start: Vector3, seg_end: Vector3, point: Vector3,
							  tolerance: float = DEFAULT_POSITION_TOLERANCE) -> bool:
	var seg_len = seg_start.distance_to(seg_end)
	var dist_to_start = point.distance_to(seg_start)
	var dist_to_end = point.distance_to(seg_end)

	# Point is on segment if distances to endpoints sum to segment length (within tolerance)
	return absf((dist_to_start + dist_to_end) - seg_len) < tolerance


## Get all unique vertices from a set of lines
static func get_unique_vertices(line_endpoints: Array, tolerance: float = DEFAULT_POSITION_TOLERANCE) -> Array[Vector3]:
	var vertices: Array[Vector3] = []

	for line in line_endpoints:
		var start: Vector3 = line[0]
		var end: Vector3 = line[1]

		_add_unique_vertex(vertices, start, tolerance)
		_add_unique_vertex(vertices, end, tolerance)

	return vertices


## Helper: Add vertex if not already in list
static func _add_unique_vertex(vertices: Array[Vector3], point: Vector3, tolerance: float) -> void:
	for v in vertices:
		if v.distance_to(point) < tolerance:
			return
	vertices.append(point)
