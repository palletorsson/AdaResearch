class_name FormConstraint
extends RefCounted

## FormConstraint - Defines geometric relationships that must hold for a form
##
## Category Theory perspective: A form is an invariant - a pattern of relationships
## that remains constant regardless of position, rotation, or scale.
## These constraints define what makes a triangle a triangle, not where it is.

## Constraint types - the morphisms of line geometry
enum Type {
	PARALLEL,           # Lines have same direction
	PERPENDICULAR,      # Lines meet at 90 degrees
	CONNECTED,          # Lines share an endpoint
	EQUAL_LENGTH,       # Lines have same length
	CLOSED_LOOP,        # Lines form a closed polygon
	INTERSECT_CENTER,   # Lines cross at their midpoints (for + and X)
	INTERSECT,          # Lines cross anywhere (not at endpoints)
}

## The constraint type
var type: Type

## Which lines this constraint applies to (indices into snap_lines array)
var line_indices: Array[int]

## Tolerance for this constraint
var position_tolerance: float = 0.05   # For CONNECTED, INTERSECT_CENTER
var angle_tolerance: float = 0.26      # For PARALLEL, PERPENDICULAR (~15 degrees)

## Human-readable description for feedback
var description: String = ""


## Create a new constraint
func _init(constraint_type: Type, indices: Array[int], desc: String = "") -> void:
	type = constraint_type
	line_indices = indices
	description = desc if desc != "" else _default_description()


## Get default description based on type
func _default_description() -> String:
	match type:
		Type.PARALLEL:
			return "Lines must be parallel"
		Type.PERPENDICULAR:
			return "Lines must be perpendicular"
		Type.CONNECTED:
			return "Lines must share an endpoint"
		Type.EQUAL_LENGTH:
			return "Lines must have equal length"
		Type.CLOSED_LOOP:
			return "Lines must form a closed shape"
		Type.INTERSECT_CENTER:
			return "Lines must cross at their centers"
		Type.INTERSECT:
			return "Lines must cross"
	return "Constraint"


## Validate this constraint against actual line positions
## lines: Array of dictionaries with {start: Vector3, end: Vector3}
func validate(lines: Array) -> bool:
	match type:
		Type.PARALLEL:
			return _validate_parallel(lines)
		Type.PERPENDICULAR:
			return _validate_perpendicular(lines)
		Type.CONNECTED:
			return _validate_connected(lines)
		Type.EQUAL_LENGTH:
			return _validate_equal_length(lines)
		Type.CLOSED_LOOP:
			return _validate_closed_loop(lines)
		Type.INTERSECT_CENTER:
			return _validate_intersect_center(lines)
		Type.INTERSECT:
			return _validate_intersect(lines)
	return false


## Get the lines referenced by this constraint
func _get_constraint_lines(lines: Array) -> Array:
	var result = []
	for idx in line_indices:
		if idx >= 0 and idx < lines.size():
			result.append(lines[idx])
	return result


## Validate PARALLEL constraint
func _validate_parallel(lines: Array) -> bool:
	var constraint_lines = _get_constraint_lines(lines)
	if constraint_lines.size() < 2:
		return false

	# All lines must be parallel to each other
	var first = constraint_lines[0]
	for i in range(1, constraint_lines.size()):
		var other = constraint_lines[i]
		if not GeometryUtils.are_parallel(
			first.start, first.end,
			other.start, other.end,
			angle_tolerance
		):
			return false
	return true


## Validate PERPENDICULAR constraint
func _validate_perpendicular(lines: Array) -> bool:
	var constraint_lines = _get_constraint_lines(lines)
	if constraint_lines.size() != 2:
		return false

	var line_a = constraint_lines[0]
	var line_b = constraint_lines[1]

	return GeometryUtils.are_perpendicular(
		line_a.start, line_a.end,
		line_b.start, line_b.end,
		angle_tolerance
	)


## Validate CONNECTED constraint
func _validate_connected(lines: Array) -> bool:
	var constraint_lines = _get_constraint_lines(lines)
	if constraint_lines.size() != 2:
		return false

	var line_a = constraint_lines[0]
	var line_b = constraint_lines[1]

	return GeometryUtils.are_connected(
		line_a.start, line_a.end,
		line_b.start, line_b.end,
		position_tolerance
	)


## Validate EQUAL_LENGTH constraint
func _validate_equal_length(lines: Array) -> bool:
	var constraint_lines = _get_constraint_lines(lines)
	if constraint_lines.size() < 2:
		return false

	var first = constraint_lines[0]
	var first_len = first.start.distance_to(first.end)

	for i in range(1, constraint_lines.size()):
		var other = constraint_lines[i]
		var other_len = other.start.distance_to(other.end)
		if absf(first_len - other_len) > position_tolerance:
			return false
	return true


## Validate CLOSED_LOOP constraint
func _validate_closed_loop(lines: Array) -> bool:
	var constraint_lines = _get_constraint_lines(lines)
	if constraint_lines.size() < 3:
		return false

	# Convert to array of [start, end] pairs for GeometryUtils
	var endpoints_array: Array = []
	for line in constraint_lines:
		endpoints_array.append([line.start, line.end])

	return GeometryUtils.forms_closed_loop(endpoints_array, position_tolerance)


## Validate INTERSECT_CENTER constraint
func _validate_intersect_center(lines: Array) -> bool:
	var constraint_lines = _get_constraint_lines(lines)
	if constraint_lines.size() != 2:
		return false

	var line_a = constraint_lines[0]
	var line_b = constraint_lines[1]

	return GeometryUtils.intersect_at_centers(
		line_a.start, line_a.end,
		line_b.start, line_b.end,
		position_tolerance
	)


## Validate INTERSECT constraint
func _validate_intersect(lines: Array) -> bool:
	var constraint_lines = _get_constraint_lines(lines)
	if constraint_lines.size() != 2:
		return false

	var line_a = constraint_lines[0]
	var line_b = constraint_lines[1]

	return GeometryUtils.do_intersect(
		line_a.start, line_a.end,
		line_b.start, line_b.end,
		position_tolerance
	)


## Static helper: Create common constraint patterns

## Triangle: 3 lines forming a closed loop with all pairs connected
static func triangle_constraints() -> Array[FormConstraint]:
	var constraints: Array[FormConstraint] = []

	# Each pair of adjacent lines must be connected
	constraints.append(FormConstraint.new(Type.CONNECTED, [0, 1], "Side 1-2 connected"))
	constraints.append(FormConstraint.new(Type.CONNECTED, [1, 2], "Side 2-3 connected"))
	constraints.append(FormConstraint.new(Type.CONNECTED, [2, 0], "Side 3-1 connected"))

	# Must form closed loop
	constraints.append(FormConstraint.new(Type.CLOSED_LOOP, [0, 1, 2], "Forms closed triangle"))

	return constraints


## Parallel pair: 2 lines that are parallel
static func parallel_constraints() -> Array[FormConstraint]:
	var constraints: Array[FormConstraint] = []
	constraints.append(FormConstraint.new(Type.PARALLEL, [0, 1], "Lines are parallel"))
	return constraints


## Cross (X shape): 2 perpendicular lines intersecting at centers
static func cross_constraints() -> Array[FormConstraint]:
	var constraints: Array[FormConstraint] = []
	constraints.append(FormConstraint.new(Type.PERPENDICULAR, [0, 1], "Lines are perpendicular"))
	constraints.append(FormConstraint.new(Type.INTERSECT_CENTER, [0, 1], "Lines cross at center"))
	return constraints


## Plus (+) shape: Same as cross
static func plus_constraints() -> Array[FormConstraint]:
	return cross_constraints()


## Rectangle/Quad: 4 lines forming a closed loop
## Flexible: only requires closed loop, not specific connection order
static func quad_constraints() -> Array[FormConstraint]:
	var constraints: Array[FormConstraint] = []

	# Only require closed loop - lines can be placed in any order
	# The CLOSED_LOOP check validates that each vertex has exactly 2 connections
	# and there are exactly 4 vertices for 4 lines
	constraints.append(FormConstraint.new(Type.CLOSED_LOOP, [0, 1, 2, 3], "Forms closed quad"))

	return constraints
