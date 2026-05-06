extends Node3D

# Static line that doesn't use grab spheres
@export var start_pos: Vector3 = Vector3(-0.4, 0, 0)
@export var end_pos: Vector3 = Vector3(0.4, 0, 0)
@export var line_thickness: float = 0.01
@export var line_color: Color = Color(0.788235, 0.462745, 0.996078, 1)

var current_line: MeshInstance3D
var length_label: Label3D

func _ready():
	create_length_label()
	update_line()

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

func update_line():
	# Clear existing line
	if current_line and is_instance_valid(current_line):
		current_line.queue_free()

	# Create new line
	current_line = create_connection_line(start_pos, end_pos)
	update_length_label(start_pos, end_pos)

func create_connection_line(start: Vector3, end: Vector3) -> MeshInstance3D:
	var line = MeshInstance3D.new()

	# Create cylinder mesh for the line
	var cylinder = CylinderMesh.new()
	var distance = start.distance_to(end)
	cylinder.height = distance
	cylinder.top_radius = line_thickness
	cylinder.bottom_radius = line_thickness
	cylinder.radial_segments = 4
	cylinder.rings = 0
	line.mesh = cylinder

	# Position at center between start and end
	var center_pos = (start + end) / 2.0
	line.position = center_pos

	# Orient the line to point from start to end
	var direction = (end - start).normalized()
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

	# Create material - glossy and emissive
	var material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.metallic = 0.8  # High metallic for glossy look
	material.roughness = 0.1  # Low roughness for glossy finish
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.emission_enabled = true
	material.emission = line_color
	line.material_override = material

	add_child(line)
	return line

func update_length_label(start: Vector3, end: Vector3):
	if not length_label:
		return

	var distance = start.distance_to(end)

	# Update label text with distance in meters (2 decimal places)
	length_label.text = "Length: %.2fm" % distance

	# Position label at the midpoint of the line, slightly offset upward
	var center_pos = (start + end) / 2.0
	center_pos.y += 0.05  # Offset up by 5cm
	length_label.position = center_pos

# Public method to set positions and update
func set_positions(start: Vector3, end: Vector3):
	start_pos = start
	end_pos = end
	if is_inside_tree():
		update_line()

# Public method to set line properties
func set_line_properties(thickness: float, color: Color):
	line_thickness = thickness
	line_color = color
	if is_inside_tree():
		update_line()
