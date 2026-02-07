# LabelPlate.gd - 3D label plate for math objects
@tool
extends Node3D

@export var object_name: String = "Object":
	set(value):
		object_name = value
		_update_labels()

@export var formula: String = "":
	set(value):
		formula = value
		_update_labels()

@export var plate_color: Color = Color(0.1, 0.1, 0.15):
	set(value):
		plate_color = value
		_update_plate()

@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		_update_labels()

@export var plate_width: float = 0.18:
	set(value):
		plate_width = value
		_update_plate()

@export var plate_height: float = 0.06:
	set(value):
		plate_height = value
		_update_plate()

func _ready() -> void:
	_create_plate()
	_create_labels()
	_update_plate()
	_update_labels()

func _create_plate() -> void:
	var existing = get_node_or_null("Plate")
	if existing:
		return
	
	var plate = MeshInstance3D.new()
	plate.name = "Plate"
	var box = BoxMesh.new()
	box.size = Vector3(plate_width, 0.005, plate_height)
	plate.mesh = box
	add_child(plate)

func _create_labels() -> void:
	# Name label
	var name_label = get_node_or_null("NameLabel")
	if not name_label:
		name_label = Label3D.new()
		name_label.name = "NameLabel"
		name_label.position = Vector3(0, 0.004, 0.012)
		name_label.rotation_degrees = Vector3(-90, 0, 0)
		name_label.pixel_size = 0.0008
		name_label.font_size = 24
		name_label.outline_size = 2
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(name_label)
	
	# Formula label
	var formula_label = get_node_or_null("FormulaLabel")
	if not formula_label:
		formula_label = Label3D.new()
		formula_label.name = "FormulaLabel"
		formula_label.position = Vector3(0, 0.004, -0.012)
		formula_label.rotation_degrees = Vector3(-90, 0, 0)
		formula_label.pixel_size = 0.0006
		formula_label.font_size = 20
		formula_label.outline_size = 1
		formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		formula_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(formula_label)

func _update_plate() -> void:
	var plate = get_node_or_null("Plate") as MeshInstance3D
	if not plate:
		return
	
	var box = plate.mesh as BoxMesh
	if box:
		box.size = Vector3(plate_width, 0.005, plate_height)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = plate_color
	material.metallic = 0.3
	material.roughness = 0.7
	plate.material_override = material

func _update_labels() -> void:
	var name_label = get_node_or_null("NameLabel") as Label3D
	if name_label:
		name_label.text = object_name
		name_label.modulate = text_color
		name_label.outline_modulate = Color(0, 0, 0, 0.8)
	
	var formula_label = get_node_or_null("FormulaLabel") as Label3D
	if formula_label:
		formula_label.text = formula
		formula_label.modulate = text_color.lerp(Color.GRAY, 0.2)
		formula_label.outline_modulate = Color(0, 0, 0, 0.6)
