# TrailTextEffect.gd - Standalone trailing text system for 3D objects
extends Node3D

# Trailing text system
var trailing_labels: Array[Label3D] = []
var trail_positions: Array[Vector3] = []
var max_trail_length: int = 8
var trail_update_distance: float = 0.2  # Minimum distance to move before adding new trail point
var last_trail_position: Vector3
var trail_fade_speed: float = 4.0

# Trail text options
var show_coordinates: bool = true
var show_vertex_index: bool = false
var vertex_index: int = 0

# Target node to track (optional - can also use this node's position directly)
var target_node: Node3D = null

# Control flags
var is_enabled: bool = true

func _ready():
	last_trail_position = get_tracked_position()

func _process(delta):
	if is_enabled:
		update_trail_system(delta)

func get_tracked_position() -> Vector3:
	if target_node and is_instance_valid(target_node):
		return target_node.global_position
	return global_position

func update_trail_system(delta: float):
	var current_pos = get_tracked_position()

	# Check if we've moved far enough to add a new trail point
	var distance_moved = current_pos.distance_to(last_trail_position)
	if distance_moved >= trail_update_distance:
		add_trail_point(last_trail_position)
		last_trail_position = current_pos

	# Update existing trail labels
	update_trail_labels(delta)

# Set a target node to track (optional - otherwise tracks own position)
func set_target(node: Node3D):
	target_node = node
	last_trail_position = get_tracked_position()

func add_trail_point(position: Vector3):
	# Create new trailing label
	var trail_label = Label3D.new()
	trail_label.name = "TrailLabel_" + str(trailing_labels.size())

	# Force the label to be on the floor (Y = 0)
	var floor_position = Vector3(position.x, 1, position.z)
	trail_label.global_position = floor_position

	trail_label.font_size = 10
	trail_label.modulate = Color(1.0, 1.0, 0.5, 0.8)  # Semi-transparent yellow
	trail_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	trail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Set trail text content
	if show_coordinates:
		trail_label.text = "%.1f,%.1f,%.1f" % [position.x, position.y, position.z]
	elif show_vertex_index:
		trail_label.text = "V%d" % vertex_index
	else:
		trail_label.text = "•"  # Simple dot if no text specified

	# Add outline for readability
	trail_label.outline_size = 1
	trail_label.outline_modulate = Color.BLACK

	# Add to scene and tracking arrays
	add_child(trail_label)
	trailing_labels.append(trail_label)
	trail_positions.append(position)

	# Remove oldest trail point if we exceed max length
	if trailing_labels.size() > max_trail_length:
		var oldest_label = trailing_labels.pop_front()
		trail_positions.pop_front()
		if oldest_label and is_instance_valid(oldest_label):
			oldest_label.queue_free()

func update_trail_labels(delta: float):
	# Fade out trail labels over time
	for i in range(trailing_labels.size()):
		var label = trailing_labels[i]
		if label and is_instance_valid(label):
			# Calculate fade based on position in trail (newer = more opaque)
			var trail_age = float(trailing_labels.size() - i) / float(max_trail_length)
			var target_alpha = 1.0 - trail_age

			# Animate alpha towards target
			var current_alpha = label.modulate.a
			var new_alpha = lerp(current_alpha, target_alpha, trail_fade_speed * delta)
			label.modulate.a = new_alpha

			# Also scale down older labels slightly
			var scale_factor = 1.0 - (trail_age * 0.3)
			label.scale = Vector3.ONE * scale_factor

func clear_trail():
	# Remove all trail labels
	for label in trailing_labels:
		if label and is_instance_valid(label):
			label.queue_free()
	trailing_labels.clear()
	trail_positions.clear()

# Configure what text to show in the trail
func set_trail_text_mode(coordinates: bool = true, vertex_idx: bool = false):
	show_coordinates = coordinates
	show_vertex_index = vertex_idx

# Set the vertex index for this point (useful for triangle vertices)
func set_vertex_index(idx: int):
	vertex_index = idx

# Configure trail appearance
func configure_trail(max_length: int = 8, update_distance: float = 0.2, fade_speed: float = 2.0):
	max_trail_length = max_length
	trail_update_distance = update_distance
	trail_fade_speed = fade_speed

# Set trail color
func set_trail_color(color: Color):
	for label in trailing_labels:
		if label and is_instance_valid(label):
			var current_alpha = label.modulate.a
			label.modulate = Color(color.r, color.g, color.b, current_alpha)

# Enable/disable the trail system
func set_trail_enabled(enabled: bool):
	is_enabled = enabled
	if not enabled:
		clear_trail()
	# Trail will automatically start again when movement is detected

# Get trail information
func get_trail_info() -> Dictionary:
	return {
		"trail_length": trailing_labels.size(),
		"max_length": max_trail_length,
		"update_distance": trail_update_distance,
		"fade_speed": trail_fade_speed,
		"show_coordinates": show_coordinates,
		"show_vertex_index": show_vertex_index
	}

# === FLOOR PROXIMITY METHODS ===

# Get trail points that are close to the floor (within a threshold)
func get_trail_points_near_floor(floor_y: float = 0.0, threshold: float = 0.5) -> Array[Vector3]:
	var floor_points = []
	for i in range(trail_positions.size()):
		var pos = trail_positions[i]
		if abs(pos.y - floor_y) <= threshold:
			floor_points.append(pos)
	return floor_points

# Get the closest trail point to the floor
func get_closest_trail_point_to_floor(floor_y: float = 0.0) -> Vector3:
	if trail_positions.is_empty():
		return Vector3.ZERO

	var closest_point = trail_positions[0]
	var closest_distance = abs(closest_point.y - floor_y)

	for pos in trail_positions:
		var distance = abs(pos.y - floor_y)
		if distance < closest_distance:
			closest_distance = distance
			closest_point = pos

	return closest_point

# Get statistics about floor proximity
func get_floor_proximity_stats(floor_y: float = 0.0) -> Dictionary:
	var stats = {
		"total_trail_points": trail_positions.size(),
		"points_near_floor": 0,
		"closest_distance": INF,
		"average_distance": 0.0
	}

	if trail_positions.is_empty():
		return stats

	var total_distance = 0.0
	for pos in trail_positions:
		var distance = abs(pos.y - floor_y)
		total_distance += distance

		if distance < stats.closest_distance:
			stats.closest_distance = distance

		if distance <= 0.5:  # Default threshold
			stats.points_near_floor += 1

	stats.average_distance = total_distance / trail_positions.size()
	return stats

# Highlight trail points that are close to the floor
func highlight_floor_trail_points(floor_y: float = 0.0, threshold: float = 0.5, highlight_color: Color = Color.GREEN):
	for i in range(trailing_labels.size()):
		var label = trailing_labels[i]
		var pos = trail_positions[i]

		if abs(pos.y - floor_y) <= threshold:
			# Make floor points more visible
			label.modulate = highlight_color
			label.font_size = 12  # Slightly larger
		else:
			# Reset to normal appearance
			label.modulate = Color(1.0, 1.0, 0.5, 0.8)
			label.font_size = 10
