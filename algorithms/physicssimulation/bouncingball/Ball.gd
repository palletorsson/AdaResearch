extends Node3D

class_name Ball

@export var ball_color: Color = Color.WHITE
@export var initial_position: Vector3 = Vector3.ZERO
@export var initial_velocity: Vector3 = Vector3.ZERO

var velocity: Vector3
var trail_points = []
var max_trail_points = 100
var trail_material: StandardMaterial3D

func _ready():
	_create_ball_mesh()
	_create_trail_material()

func _create_ball_mesh():
	# Create the ball sphere
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.5
	sphere.material = StandardMaterial3D.new()
	sphere.material.albedo_color = ball_color
	sphere.material.emission_enabled = true
	sphere.material.emission = ball_color * 0.2
	
	add_child(sphere)

func _create_trail_material():
	trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = ball_color
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.albedo_color.a = 0.5

func initialize():
	position = initial_position
	velocity = initial_velocity
	trail_points.clear()

func update_physics(delta: float, gravity: Vector3):
	# Apply gravity
	velocity += gravity * delta
	
	# Apply air resistance
	velocity *= 0.99
	
	# Update position
	position += velocity * delta
	
	# Add current position to trail
	trail_points.append(position)
	
	# Limit trail length
	if trail_points.size() > max_trail_points:
		trail_points.pop_front()
	
	# Update trail visualization
	_update_trail()

func _update_trail():
	# Clear existing trail segments
	for child in get_children():
		if child.name.begins_with("TrailSegment"):
			child.queue_free()
	
	# Draw trail
	for i in range(1, trail_points.size()):
		var start = trail_points[i-1]
		var end = trail_points[i]
		
		var trail_segment = CSGBox3D.new()
		trail_segment.name = "TrailSegment" + str(i)
		trail_segment.size = Vector3(0.02, 0.02, start.distance_to(end))
		trail_segment.position = (start + end) / 2
		trail_segment.look_at(end, Vector3.UP)
		trail_segment.material = trail_material
		
		add_child(trail_segment)

func reset_to_initial():
	position = initial_position
	velocity = initial_velocity
	trail_points.clear()
	
	# Clear trail segments
	for child in get_children():
		if child.name.begins_with("TrailSegment"):
			child.queue_free()
