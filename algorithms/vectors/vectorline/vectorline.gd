extends Node3D

@export var line_thickness: float = 0.01
@export var line_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var arrow_tip_length: float = 0.16
@export var arrow_tip_radius: float = 0.05
@export var vector_name: String = "Vector"

@onready var point_one: Node3D = $lineContainer/GrabSphere
@onready var point_two: Node3D = $lineContainer/GrabSphere2

var current_line: MeshInstance3D
var length_label: Label3D
var arrow_tip: MeshInstance3D
var line_material: StandardMaterial3D
var last_distance: float = 0.0

func _ready():
	_create_length_label()
	_refresh_geometry()
	if point_one and point_one.has_signal("dropped"):
		point_one.dropped.connect(_on_point_dropped)
	if point_two and point_two.has_signal("dropped"):
		point_two.dropped.connect(_on_point_dropped)

func _process(_delta):
	_refresh_geometry()

func _refresh_geometry():
	if not point_one or not point_two:
		return
	var start_global = point_one.global_transform.origin
	var end_global = point_two.global_transform.origin
	var start_local = to_local(start_global)
	var end_local = to_local(end_global)
	_update_line(start_local, end_local)
	_update_arrow_tip(start_local, end_local)
	_update_length_label(start_local, end_local)

func _update_line(start_local: Vector3, end_local: Vector3):
	if not current_line or not is_instance_valid(current_line):
		current_line = MeshInstance3D.new()
		current_line.name = "VectorBody"
		add_child(current_line)
		var cylinder = CylinderMesh.new()
		cylinder.radial_segments = 24
		current_line.mesh = cylinder
	if not line_material:
		line_material = _build_material(line_color)
	current_line.material_override = line_material
	var cylinder_mesh := current_line.mesh as CylinderMesh
	var direction = end_local - start_local
	var distance = direction.length()
	cylinder_mesh.height = max(distance, 0.001)
	cylinder_mesh.top_radius = line_thickness
	cylinder_mesh.bottom_radius = line_thickness
	current_line.position = (start_local + end_local) * 0.5
	if distance > 0.001:
		current_line.transform.basis = _compute_basis(direction)

func _update_arrow_tip(start_local: Vector3, end_local: Vector3):
	if not arrow_tip or not is_instance_valid(arrow_tip):
		arrow_tip = MeshInstance3D.new()
		arrow_tip.name = "VectorArrow"
		var cone := CylinderMesh.new()
		cone.radial_segments = 32
		arrow_tip.mesh = cone
		if not line_material:
			line_material = _build_material(line_color)
		arrow_tip.material_override = line_material
		add_child(arrow_tip)
	var direction = end_local - start_local
	var distance = direction.length()
	if distance <= 0.001:
		arrow_tip.visible = false
		return
	arrow_tip.visible = true
	var normalized = direction / distance
	var tip_length = min(arrow_tip_length, distance)
	var cone_mesh := arrow_tip.mesh as CylinderMesh
	cone_mesh.height = tip_length
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = arrow_tip_radius
	arrow_tip.transform.basis = _compute_basis(direction)
	arrow_tip.position = end_local - normalized * (tip_length * 0.5)

func _create_length_label():
	length_label = Label3D.new()
	length_label.name = "LengthLabel"
	length_label.text = "Vector |v| = 0.00m"
	length_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	length_label.font_size = 32
	length_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	length_label.outline_size = 4
	length_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	length_label.scale = Vector3.ONE * 0.12
	add_child(length_label)

func _update_length_label(start_local: Vector3, end_local: Vector3):
	if not length_label:
		return
	var distance = start_local.distance_to(end_local)
	last_distance = distance
	length_label.text = "%s |v| = %.2fm" % [vector_name, distance]
	var center_pos = (start_local + end_local) * 0.5
	center_pos.y += 0.08
	length_label.position = center_pos

func _on_point_dropped(_pickable):
	var context := {
		"length": "%.2f" % last_distance,
		"length_raw": last_distance
	}
	if typeof(TextManager) != TYPE_NIL and TextManager.has_method("trigger_event"):
		if TextManager.trigger_event("line_drop", context):
			return
	push_warning("Line: Missing line_drop text entry for current map")

func _build_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.9
	material.emission_energy_multiplier = 3.0
	material.metallic = 0.15
	material.roughness = 0.25
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
