extends Node
class_name Turtle

# The Axiom Garden - Iteration 2: The Sprout
# Interprets L-System strings into 3D vector paths.

# State
var position: Vector3 = Vector3.ZERO
var heading: Vector3 = Vector3.UP
var stack: Array = [] # Stores [position, heading]

# Configuration
var step_length: float = 1.0
var angle_degrees: float = 25.0

# Output
# Returns an array of line segments (each segment is a PackedVector3Array of 2 points)
func process_string(instruction_string: String, start_pos: Vector3 = Vector3.ZERO, start_heading: Vector3 = Vector3.UP) -> Array:
	var lines: Array = []
	
	# Reset state
	position = start_pos
	heading = start_heading.normalized()
	stack.clear()
	
	# Pre-calculate rotation basis
	# For simplicity in this iteration, we'll rotate around Z and X axes
	
	for character in instruction_string:
		match character:
			"F": # Move forward and draw
				var new_pos = position + (heading * step_length)
				var segment = PackedVector3Array([position, new_pos])
				lines.append(segment)
				position = new_pos
				
			"f": # Move forward without drawing
				position += (heading * step_length)
				
			"+": # Turn right (Yaw +)
				heading = heading.rotated(Vector3.BACK, deg_to_rad(angle_degrees))
				
			"-": # Turn left (Yaw -)
				heading = heading.rotated(Vector3.BACK, deg_to_rad(-angle_degrees))
				
			"&": # Pitch down
				heading = heading.rotated(Vector3.RIGHT, deg_to_rad(angle_degrees))
				
			"^": # Pitch up
				heading = heading.rotated(Vector3.RIGHT, deg_to_rad(-angle_degrees))
				
			"\\": # Roll left
				heading = heading.rotated(Vector3.UP, deg_to_rad(angle_degrees))
				
			"/": # Roll right
				heading = heading.rotated(Vector3.UP, deg_to_rad(-angle_degrees))
				
			"|": # Turn around
				heading = heading.rotated(Vector3.UP, deg_to_rad(180))
				
			"[": # Push state
				stack.push_back([position, heading])
				
			"]": # Pop state
				if not stack.is_empty():
					var state = stack.pop_back()
					position = state[0]
					heading = state[1]
					
	return lines
