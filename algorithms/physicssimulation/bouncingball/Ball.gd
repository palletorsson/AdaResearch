extends Node3D
class_name Ball

@export var ball_color: Color = Color.WHITE
@export var initial_position: Vector3 = Vector3.ZERO
@export var initial_velocity: Vector3 = Vector3.ZERO

var velocity: Vector3
var trail_points = []
var max_trail_points = 50  # Reduced from 100 for better performance
var ball_radius = 0.5

# Pre-created objects for performance
var ball_mesh: CSGSphere3D
var trail_mesh: MeshInstance3D
var trail_array_mesh: ArrayMesh

# Trail optimization
var trail_vertices = PackedVector3Array()
var trail_indices = PackedInt32Array()
var trail_colors = PackedColorArray()
var trail_needs_update = false
var trail_update_counter = 0

func _ready():
	_create_ball_mesh()
	_create_trail_system()

func _create_ball_mesh():
	# Create the ball sphere once
	ball_mesh = CSGSphere3D.new()
	ball_mesh.radius = ball_radius
	ball_mesh.material = StandardMaterial3D.new()
	ball_mesh.material.albedo_color = ball_color
	ball_mesh.material.emission_enabled = true
	ball_mesh.material.emission = ball_color * 0.2
	ball_mesh.material.metallic = 0.2
	ball_mesh.material.roughness = 0.3
	
	add_child(ball_mesh)

func _create_trail_system():
	# Use efficient MeshInstance3D instead of multiple CSG nodes
	trail_mesh = MeshInstance3D.new()
	trail_array_mesh = ArrayMesh.new()
	trail_mesh.mesh = trail_array_mesh
	
	# Create trail material once
	var trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = ball_color
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.albedo_color.a = 0.6
	trail_material.emission_enabled = true
	trail_material.emission = ball_color * 0.3
	trail_material.vertex_color_use_as_albedo = true
	trail_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	trail_material.no_depth_test = false
	trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	trail_mesh.material_override = trail_material
	add_child(trail_mesh)

func initialize():
	position = initial_position
	velocity = initial_velocity
	trail_points.clear()
	trail_needs_update = true

func update_physics(delta: float, gravity: Vector3):
	# Apply gravity
	velocity += gravity * delta
	
	# Apply air resistance (slightly more efficient)
	velocity *= 0.99
	
	# Update position
	position += velocity * delta
	
	# Only add trail point every few frames for performance
	trail_update_counter += 1
	if trail_update_counter >= 2:  # Update every 2 frames
		trail_update_counter = 0
		_add_trail_point(position)

func _add_trail_point(point: Vector3):
	trail_points.append(point)
	
	# Limit trail length
	if trail_points.size() > max_trail_points:
		trail_points.pop_front()
	
	trail_needs_update = true

func _update_trail_mesh():
	if not trail_needs_update or trail_points.size() < 2:
		return
	
	trail_needs_update = false
	
	# Clear arrays
	trail_vertices.clear()
	trail_indices.clear()
	trail_colors.clear()
	
	var trail_width = 0.05
	var point_count = trail_points.size()
	
	# Generate trail geometry using quad strips
	for i in range(point_count - 1):
		var start_pos = trail_points[i]
		var end_pos = trail_points[i + 1]
		var direction = (end_pos - start_pos).normalized()
		var perpendicular = direction.cross(Vector3.UP).normalized() * trail_width
		
		# Create quad vertices
		var v1 = start_pos + perpendicular
		var v2 = start_pos - perpendicular
		var v3 = end_pos + perpendicular
		var v4 = end_pos - perpendicular
		
		# Add vertices
		var base_index = trail_vertices.size()
		trail_vertices.append_array([v1, v2, v3, v4])
		
		# Add indices for two triangles
		trail_indices.append_array([
			base_index, base_index + 1, base_index + 2,
			base_index + 1, base_index + 3, base_index + 2
		])
		
		# Add colors with alpha fade
		var alpha = float(i) / float(point_count - 1)
		var color = Color(ball_color.r, ball_color.g, ball_color.b, alpha * 0.6)
		trail_colors.append_array([color, color, color, color])
	
	# Update mesh
	trail_array_mesh.clear_surfaces()
	if trail_vertices.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = trail_vertices
		arrays[Mesh.ARRAY_INDEX] = trail_indices
		arrays[Mesh.ARRAY_COLOR] = trail_colors
		trail_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

# Call this from the main game loop at a controlled frequency
func update_trail_visualization():
	_update_trail_mesh()

func reset_to_initial():
	position = initial_position
	velocity = initial_velocity
	trail_points.clear()
	trail_needs_update = true
	_update_trail_mesh()

# Getter for ball radius (used by collision detection)
func get_radius() -> float:
	return ball_radius

# Optional: Reduce trail quality for performance
func set_trail_quality(quality: int):
	match quality:
		0: # Low
			max_trail_points = 20
		1: # Medium
			max_trail_points = 50
		2: # High
			max_trail_points = 100

# Optional: Enable/disable trail
func set_trail_enabled(enabled: bool):
	trail_mesh.visible = enabled
