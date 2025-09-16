extends Node3D

# Line connection system for grab spheres
@export var line_thickness: float = 0.01
@export var line_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var update_frequency: float = 0.1  # Update every 0.1 seconds

@onready var point_one = $GrabSphere
@onready var point_two = $GrabSphere2

var connection_lines: Array[MeshInstance3D] = []
var update_timer: Timer

func _ready():
	setup_update_timer()
	update_connections()

func setup_update_timer():
	update_timer = Timer.new()
	update_timer.wait_time = update_frequency
	update_timer.timeout.connect(update_connections)
	update_timer.autostart = true
	add_child(update_timer)

func update_connections():
	# Clear existing connection lines
	clear_connections()
	
	# Create connection between the two specific grab spheres
	if point_one and point_two and is_instance_valid(point_one) and is_instance_valid(point_two):
		# Get the local positions of the grab spheres relative to this container
		var pos_one = point_one.position
		var pos_two = point_two.position
		create_connection_line(pos_one, pos_two)

func create_connection_line(start_pos: Vector3, end_pos: Vector3) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	
	# Create cylinder mesh for the line
	var cylinder = CylinderMesh.new()
	var distance = start_pos.distance_to(end_pos)
	cylinder.height = distance
	cylinder.top_radius = line_thickness
	cylinder.bottom_radius = line_thickness
	cylinder.radial_segments = 8
	
	line.mesh = cylinder
	
	# Position at center between start and end
	var center_pos = (start_pos + end_pos) / 2.0
	line.position = center_pos
	
	# Orient the line to point from start to end
	var direction = (end_pos - start_pos).normalized()
	if direction.length() > 0.001:  # Avoid division by zero
		# Create proper transform for cylinder orientation
		var up = Vector3.UP
		var right = direction.cross(up).normalized()
		if right.length() < 0.001:  # If direction is parallel to UP
			right = Vector3.RIGHT
			up = right.cross(direction).normalized()
		else:
			up = right.cross(direction).normalized()
		
		# Set the transform with proper orientation
		line.transform.basis = Basis(right, direction, up)
	
	# Create material - hard, glossy, black
	var material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.metallic = 0.8  # High metallic for glossy look
	material.roughness = 0.1  # Low roughness for glossy finish
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED  # Hard, not transparent
	material.emission_enabled = false  # No emission for hard look
	line.material_override = material
	
	connection_lines.append(line)
	add_child(line)
	
	return line

func clear_connections():
	for line in connection_lines:
		if is_instance_valid(line):
			line.queue_free()
	connection_lines.clear()

# Public method to manually refresh connections
func refresh_connections():
	update_connections()
