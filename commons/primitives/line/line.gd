extends Node3D

@export var line_thickness: float = 0.005
@export var line_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var arrow_tip_length: float = 0.12
@export var arrow_tip_radius: float = 0.03
@export var update_frequency: float = 0.1
@export var vector_name: String = "Vector"

@onready var point_one = $lineContainer/GrabSphere
@onready var point_two = $lineContainer/GrabSphere2

var connection_lines: Array[MeshInstance3D] = []
var current_line: MeshInstance3D
var length_label: Label3D
var arrow_tip: MeshInstance3D
var line_material: StandardMaterial3D
var last_distance: float = 0.0

func _ready():
	create_length_label()
	update_connections()
	
	if point_one and point_one.has_signal("dropped"):
		point_one.dropped.connect(_on_point_dropped)
	if point_two and point_two.has_signal("dropped"):
		point_two.dropped.connect(_on_point_dropped)

func create_length_label():
	length_label = Label3D.new()
	length_label.name = "LengthLabel"
	length_label.text = "Vector |v| = 0.00m"
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
		update_arrow_tip(point_one.position, point_two.position)
		update_length_label(point_one.position, point_two.position)

func _process(_delta):
	if point_one and point_two and is_instance_valid(point_one) and is_instance_valid(point_two):
		update_line_transform(point_one.position, point_two.position)
		update_arrow_tip(point_one.position, point_two.position)
		update_length_label(point_one.position, point_two.position)

func create_connection_line(start_pos: Vector3, end_pos: Vector3) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	var distance = start_pos.distance_to(end_pos)
	cylinder.height = max(distance, 0.001)
	cylinder.top_radius = line_thickness
	cylinder.bottom_radius = line_thickness
	cylinder.radial_segments = 8
	line.mesh = cylinder
	
	var center_pos = (start_pos + end_pos) / 2.0
	line.position = center_pos
	
	var direction = end_pos - start_pos
	if direction.length() > 0.001:
		line.transform.basis = _compute_basis(direction)
	else:
		line.transform = Transform3D.IDENTITY
	
	if not line_material:
		line_material = _build_material(line_color)
	line.material_override = line_material
	
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
	cylinder.height = max(distance, 0.001)
	current_line.position = (start_pos + end_pos) / 2.0
	var direction = end_pos - start_pos
	if direction.length() > 0.001:
		current_line.transform.basis = _compute_basis(direction)

func update_arrow_tip(start_pos: Vector3, end_pos: Vector3):
	if not point_one or not point_two:
		return
	if arrow_tip == null or not is_instance_valid(arrow_tip):
		_ensure_arrow_tip()
	var direction = end_pos - start_pos
	var distance = direction.length()
	if distance <= 0.001:
		arrow_tip.visible = false
		return
	arrow_tip.visible = true
	var normalized = direction / distance
	var tip_length = min(arrow_tip_length, distance)
	var cone = arrow_tip.mesh as CylinderMesh
	if cone:
		cone.height = tip_length
		cone.top_radius = 0.0
		cone.bottom_radius = arrow_tip_radius
	arrow_tip.transform.basis = _compute_basis(direction)
	arrow_tip.position = end_pos - normalized * (tip_length * 0.5)

func update_length_label(start_pos: Vector3, end_pos: Vector3):
	if not length_label:
		return
	var distance = start_pos.distance_to(end_pos)
	last_distance = distance
	var label_name = vector_name if vector_name.length() > 0 else "Vector"
	length_label.text = "%s |v| = %.2fm" % [label_name, distance]
	var center_pos = (start_pos + end_pos) / 2.0
	center_pos.y += 0.05
	length_label.position = center_pos

func clear_connections():
	if current_line and is_instance_valid(current_line):
		current_line.queue_free()
	current_line = null
	connection_lines.clear()
	if arrow_tip and is_instance_valid(arrow_tip):
		arrow_tip.visible = false

func refresh_connections():
	update_connections()

func get_start_position() -> Vector3:
	if point_one and is_instance_valid(point_one):
		return point_one.global_position
	return global_position

func get_end_position() -> Vector3:
	if point_two and is_instance_valid(point_two):
		return point_two.global_position
	return global_position

func get_vector() -> Vector3:
	return get_end_position() - get_start_position()

func set_start_local_position(position: Vector3):
	var node = point_one if point_one and is_instance_valid(point_one) else get_node_or_null("lineContainer/GrabSphere")
	if node:
		node.position = position

func set_end_local_position(position: Vector3):
	var node = point_two if point_two and is_instance_valid(point_two) else get_node_or_null("lineContainer/GrabSphere2")
	if node:
		node.position = position

func _on_point_dropped(_pickable):
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

func _ensure_arrow_tip():
	arrow_tip = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.height = arrow_tip_length
	cone.top_radius = 0.0
	cone.bottom_radius = arrow_tip_radius
	cone.radial_segments = 16
	arrow_tip.mesh = cone
	if not line_material:
		line_material = _build_material(line_color)
	arrow_tip.material_override = line_material
	add_child(arrow_tip)
	arrow_tip.visible = false

func _build_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.8
	material.roughness = 0.1
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.emission_enabled = true
	material.emission = color
	return material

func _compute_basis(direction: Vector3) -> Basis:
	var dir = direction.normalized()
	var up = Vector3.UP
	if abs(dir.dot(up)) > 0.999:
		up = Vector3.FORWARD
	var right = dir.cross(up).normalized()
	if right.length() <= 0.001:
		right = Vector3.RIGHT
		up = right.cross(dir).normalized()
	else:
		up = right.cross(dir).normalized()
	return Basis(right, dir, up)
