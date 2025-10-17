extends Node3D

class_name CelestialBody

@export var body_name: String = "Body"
@export var body_mass: float = 1000.0
@export var body_color: Color = Color.WHITE
@export var initial_position: Vector3 = Vector3.ZERO
@export var initial_velocity: Vector3 = Vector3.ZERO

var velocity: Vector3
var current_force: Vector3
var trail_points = []
var max_trail_points = 200
var trail_material: StandardMaterial3D

func _ready():
	_create_body_mesh()
	_create_trail_material()

func _create_body_mesh():
	# Create the celestial body sphere
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.5
	sphere.material = StandardMaterial3D.new()
	sphere.material.albedo_color = body_color
	sphere.material.emission_enabled = true
	sphere.material.emission = body_color * 0.3
	
	add_child(sphere)
	
	# Add a label showing the body name
	var label = Label3D.new()
	label.text = body_name
	label.font_size = 24
	label.pixel_size = 0.1
	label.position = Vector3(0, 1, 0)
	add_child(label)

func _create_trail_material():
	trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = body_color
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.albedo_color.a = 0.7

func initialize():
	position = initial_position
	velocity = initial_velocity
	current_force = Vector3.ZERO
	trail_points.clear()

func apply_force(force: Vector3):
	current_force += force

func update_physics(delta: float):
	# Apply force to velocity (F = ma, assuming mass = 1 for simplicity)
	velocity += current_force / body_mass * delta
	
	# Update position
	position += velocity * delta
	
	# Reset force for next frame
	current_force = Vector3.ZERO

func update_trail():
	# Add current position to trail
	trail_points.append(position)
	
	# Limit trail length
	if trail_points.size() > max_trail_points:
		trail_points.pop_front()
	
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
		
		# Add to trails parent
		get_parent().get_parent().get_node("Trails").add_child(trail_segment)

func reset_to_initial():
	position = initial_position
	velocity = initial_velocity
	current_force = Vector3.ZERO
	trail_points.clear()
	
	# Clear trail segments
	for child in get_children():
		if child.name.begins_with("TrailSegment"):
			child.queue_free()
