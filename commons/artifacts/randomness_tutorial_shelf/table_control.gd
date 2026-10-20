extends Node3D
## A single upward-facing NEXT button on an extension of the tabletop.
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")

func _ready() -> void:
	var shelf := get_parent()
	var extension := MeshInstance3D.new()
	extension.name = "TableExtension"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.56, 0.06, 0.46)
	extension.mesh = mesh
	extension.material_override = shelf.get_node("Shelf").material_override
	# Overlap the tabletop's front edge so the extension is visibly joined.
	extension.position = Vector3(0, 1.16, 0.53)
	add_child(extension)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	extension.add_child(body)
	var boundary := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	boundary.shape = shape
	body.add_child(boundary)

	var button := preload("res://commons/interactables/push_button.tscn").instantiate()
	button.name = "NEXT"
	Rack.make_button_rectangular(button)
	button.rotation = Vector3.ZERO
	button.position = Vector3(0, 1.19, 0.55)
	button.released_color = Color("24363b")
	button.pressed_color = Color("b58f46")
	button.get_node("ButtonBase/BaseMesh").mesh = button.get_node("ButtonBase/BaseMesh").mesh.duplicate()
	button.get_node("ButtonBase/CollisionShape3D").shape = button.get_node("ButtonBase/CollisionShape3D").shape.duplicate()
	button.get_node("ButtonBase/BaseMesh").mesh.size = Vector3(0.34, 0.01, 0.22)
	button.get_node("ButtonBase/CollisionShape3D").shape.size = Vector3(0.34, 0.02, 0.22)
	button.get_node("Button/ButtonMesh").mesh.size = Vector3(0.29, 0.024, 0.17)
	button.get_node("Button/CollisionShape3D").shape.size = Vector3(0.29, 0.028, 0.17)
	button.get_node("AccentRing").mesh.size = Vector3(0.32, 0.014, 0.20)
	button.get_node("InteractableAreaButton/CollisionShape3D").shape.size = Vector3(0.32, 0.06, 0.20)
	add_child(button)
	button.pressed.connect(shelf.next_sample)
	var label := Label3D.new()
	label.name = "Caption"
	label.text = "NEXT"
	label.font_size = 44
	label.pixel_size = 0.0016
	label.modulate = Color("eeeade")
	label.outline_size = 0
	label.position = Vector3(0, 0.016, 0)
	label.rotation.x = -PI/2
	button.get_node("Button").add_child(label)
