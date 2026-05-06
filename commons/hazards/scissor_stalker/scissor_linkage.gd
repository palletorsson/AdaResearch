extends RefCounted
class_name ScissorLinkage
## Scissor linkage chain geometry - extends/compresses dramatically.
## Each X unit pivots at center, creating telescoping behavior.

# Parameters
var unit_count: int = 3
var bar_length: float = 0.15
var bar_thickness: float = 0.012

# State
var pivot_angle: float = PI * 0.5  # Angle at X crossing (radians)

# Computed geometry - joints and bar endpoints
var joints: PackedVector3Array = []  # Pivot points
var bar_endpoints: Array[PackedVector3Array] = []  # Each bar's start/end


func build(p_units: int, p_bar_length: float, p_thickness: float) -> void:
	unit_count = max(1, p_units)
	bar_length = max(0.01, p_bar_length)
	bar_thickness = max(0.001, p_thickness)


func solve_extension(extension: float) -> void:
	## Compute geometry for given extension.
	## extension: 0 = fully compressed (short, wide)
	##           1 = fully extended (long, thin)
	
	extension = clamp(extension, 0.05, 0.95)
	
	# Pivot angle determines shape:
	# θ near π: compressed (bars nearly parallel)
	# θ near 0: extended (bars nearly colinear)
	
	pivot_angle = lerp(PI * 0.85, PI * 0.15, extension)
	
	joints.clear()
	bar_endpoints.clear()
	
	var half_angle: float = pivot_angle * 0.5
	
	# Unit dimensions
	var unit_length: float = 2.0 * bar_length * sin(half_angle)  # Along chain
	var unit_width: float = 2.0 * bar_length * cos(half_angle)   # Perpendicular
	
	# Generate joints and bars along the chain
	var current_pos: float = 0.0
	
	for i in range(unit_count):
		var center_x: float = current_pos + unit_length * 0.5
		
		# Four endpoints of the X
		var top_left: Vector3 = Vector3(center_x - unit_length * 0.5, unit_width * 0.5, 0.0)
		var top_right: Vector3 = Vector3(center_x + unit_length * 0.5, unit_width * 0.5, 0.0)
		var bottom_left: Vector3 = Vector3(center_x - unit_length * 0.5, -unit_width * 0.5, 0.0)
		var bottom_right: Vector3 = Vector3(center_x + unit_length * 0.5, -unit_width * 0.5, 0.0)
		
		# Center pivot
		joints.append(Vector3(center_x, 0.0, 0.0))
		
		# Bar 1: top_left to bottom_right
		var bar1: PackedVector3Array = [top_left, bottom_right]
		bar_endpoints.append(bar1)
		
		# Bar 2: bottom_left to top_right
		var bar2: PackedVector3Array = [bottom_left, top_right]
		bar_endpoints.append(bar2)
		
		current_pos += unit_length
	
	# Add end joints
	if unit_count > 0:
		joints.insert(0, Vector3(0.0, 0.0, 0.0))
		joints.append(Vector3(current_pos, 0.0, 0.0))


func get_total_length() -> float:
	## Return current total length of the chain.
	if joints.size() < 2:
		return 0.0
	return joints[joints.size() - 1].x - joints[0].x


func get_tip_position() -> Vector3:
	if joints.is_empty():
		return Vector3.ZERO
	return joints[joints.size() - 1]


func get_compressed_length() -> float:
	return unit_count * bar_length * 0.3


func get_extended_length() -> float:
	return unit_count * bar_length * 1.9
