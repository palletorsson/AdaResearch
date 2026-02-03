# excluded_middle_demo.gd
# Law of excluded middle: P ∨ ¬P
# Brouwer rejected this for non-constructive proofs

extends Node3D

@export var show_rejection: bool = true

var _true_sphere: MeshInstance3D
var _false_sphere: MeshInstance3D
var _label: Label3D

func _ready():
	_create_spheres()
	_create_label()

func _create_spheres():
	# True state
	_true_sphere = MeshInstance3D.new()
	var s1 = SphereMesh.new()
	s1.radius = 0.1
	s1.height = 0.2
	_true_sphere.mesh = s1
	_true_sphere.position = Vector3(-0.2, 0, 0)
	var mat1 = StandardMaterial3D.new()
	mat1.albedo_color = Color(0.2, 0.8, 0.3)
	mat1.emission_enabled = true
	mat1.emission = Color(0.1, 0.5, 0.2)
	_true_sphere.material_override = mat1
	add_child(_true_sphere)
	
	var lbl1 = Label3D.new()
	lbl1.text = "P"
	lbl1.pixel_size = 0.001
	lbl1.font_size = 16
	lbl1.position = Vector3(-0.2, 0.15, 0)
	add_child(lbl1)
	
	# False state
	_false_sphere = MeshInstance3D.new()
	var s2 = SphereMesh.new()
	s2.radius = 0.1
	s2.height = 0.2
	_false_sphere.mesh = s2
	_false_sphere.position = Vector3(0.2, 0, 0)
	var mat2 = StandardMaterial3D.new()
	mat2.albedo_color = Color(0.8, 0.2, 0.2)
	mat2.emission_enabled = true
	mat2.emission = Color(0.5, 0.1, 0.1)
	_false_sphere.material_override = mat2
	add_child(_false_sphere)
	
	var lbl2 = Label3D.new()
	lbl2.text = "¬P"
	lbl2.pixel_size = 0.001
	lbl2.font_size = 16
	lbl2.position = Vector3(0.2, 0.15, 0)
	add_child(lbl2)
	
	# OR symbol
	var or_lbl = Label3D.new()
	or_lbl.text = "∨"
	or_lbl.pixel_size = 0.002
	or_lbl.font_size = 24
	or_lbl.position = Vector3(0, 0, 0)
	add_child(or_lbl)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	if show_rejection:
		_label.text = "LAW OF EXCLUDED MIDDLE\nP ∨ ¬P\n\nBrouwer: \"Not always!\"\nSome P cannot be decided."
	else:
		_label.text = "LAW OF EXCLUDED MIDDLE\nP ∨ ¬P\n\"Either true or false\""
	_label.position = Vector3(0, -0.25, 0)
	add_child(_label)
