# constructive_proof.gd
# Demonstrates constructive vs classical proof
# Constructive: must exhibit the thing. Classical: can prove existence by contradiction.

extends Node3D
class_name ConstructiveProof

var _label: Label3D
var _example_box: MeshInstance3D

func _ready():
	_create_visual()
	_create_label()

func _create_visual():
	_example_box = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	_example_box.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 0.9)
	_example_box.material_override = mat
	add_child(_example_box)
	
	var arrow = Label3D.new()
	arrow.text = "← Must BUILD it"
	arrow.pixel_size = 0.001
	arrow.font_size = 12
	arrow.position = Vector3(0.25, 0, 0)
	add_child(arrow)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 11
	_label.text = "CONSTRUCTIVE PROOF\n\nClassical: \"∃x such that P(x)\"\n(existence by contradiction)\n\nConstructive: \"Here is x\"\n(must exhibit the witness)"
	_label.position = Vector3(0, -0.35, 0)
	add_child(_label)

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("color") and _example_box:
		var c = config_data["color"]
		if c is Color:
			_example_box.material_override.albedo_color = c
		elif c is String:
			_example_box.material_override.albedo_color = Color(c)
	if config_data.has("size") and _example_box:
		var s = float(config_data["size"])
		(_example_box.mesh as BoxMesh).size = Vector3(s, s, s)
