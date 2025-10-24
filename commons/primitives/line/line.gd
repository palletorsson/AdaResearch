extends Node3D

# Line connection system for grab spheres with queer CGI education
@export var line_thickness: float = 0.005
@export var line_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var update_frequency: float = 0.1  # Update every 0.1 seconds

@onready var point_one = $GrabSphere
@onready var point_two = $GrabSphere2

var connection_lines: Array[MeshInstance3D] = []
var current_line: MeshInstance3D
var length_label: Label3D
var last_distance: float = 0.0

func _ready():
	create_length_label()
	update_connections()
	
	# Connect to point drop events to send educational messages
	if point_one and point_one.has_signal("dropped"):
		point_one.dropped.connect(_on_point_dropped)
	if point_two and point_two.has_signal("dropped"):
		point_two.dropped.connect(_on_point_dropped)

func create_length_label():
	length_label = Label3D.new()
	length_label.name = "LengthLabel"
	length_label.text = "Length: 0.00m"
	length_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	length_label.font_size = 32
	length_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	length_label.outline_size = 4
	length_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	length_label.scale = Vector3.ONE * 0.1
	add_child(length_label)

func update_connections():
	clear_connections()
	if point_one and point_two and is_instance_valid(point_one) and is_instance_valid(point_two):
		current_line = create_connection_line(point_one.position, point_two.position)
		update_length_label(point_one.position, point_two.position)

func _process(delta):
	if point_one and point_two and is_instance_valid(point_one) and is_instance_valid(point_two):
		update_line_transform(point_one.position, point_two.position)
		update_length_label(point_one.position, point_two.position)

func create_connection_line(start_pos: Vector3, end_pos: Vector3) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	
	# Create cylinder mesh for the line
	var cylinder = CylinderMesh.new()
	var distance = start_pos.distance_to(end_pos)
	cylinder.height = distance
	cylinder.top_radius = line_thickness
	cylinder.bottom_radius = line_thickness
	cylinder.radial_segments = 4
	cylinder.rings = 0
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
	
	# Create material - glossy and emissive with queer pride colors influence
	var material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.metallic = 0.8  # High metallic for glossy look
	material.roughness = 0.1  # Low roughness for glossy finish
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED  # Hard, not transparent
	material.emission_enabled = true
	material.emission = line_color
	line.material_override = material
	
	connection_lines.append(line)
	add_child(line)
	
	return line

func update_line_transform(start_pos: Vector3, end_pos: Vector3):
	if current_line == null or not is_instance_valid(current_line):
		return
		
	var cylinder = current_line.mesh as CylinderMesh
	if cylinder == null:
		return
		
	var distance = start_pos.distance_to(end_pos)
	cylinder.height = distance
	
	var center_pos = (start_pos + end_pos) / 2.0
	current_line.position = center_pos
	
	var direction = (end_pos - start_pos).normalized()
	if direction.length() > 0.001:
		var up = Vector3.UP
		var right = direction.cross(up).normalized()
		if right.length() < 0.001:
			right = Vector3.RIGHT
			up = right.cross(direction).normalized()
		else:
			up = right.cross(direction).normalized()
		current_line.transform.basis = Basis(right, direction, up)

func update_length_label(start_pos: Vector3, end_pos: Vector3):
	if not length_label:
		return
		
	var distance = start_pos.distance_to(end_pos)
	last_distance = distance
	
	# Update label text with distance in meters (2 decimal places)
	length_label.text = "Length: %.2fm" % distance
	
	# Position label at the midpoint of the line, slightly offset upward
	var center_pos = (start_pos + end_pos) / 2.0
	center_pos.y += 0.05  # Offset up by 5cm
	length_label.position = center_pos

func clear_connections():
	if current_line and is_instance_valid(current_line):
		current_line.queue_free()
	current_line = null
	connection_lines.clear()

# Public method to manually refresh connections
func refresh_connections():
	update_connections()


# Called when either point is dropped
func _on_point_dropped(_pickable):
	# Send map-aware educational message via TextManager
	var context := {
		"length": "%.2f" % last_distance,
		"length_raw": last_distance
	}
	var handled := false
	if typeof(TextManager) != TYPE_NIL and TextManager.has_method("trigger_event"):
		handled = TextManager.trigger_event("line_drop", context)
	if handled:
		return
	push_warning("Line: Missing line_drop text entry for current map")
