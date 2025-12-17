@tool
extends Node3D

# Color Mixing Demo
# Demonstrates Subtractive (CMY) and Additive (RGB) color mixing using transparent planes.

@export var plane_size: float = 2.0
@export var plane_thickness: float = 0.15
@export var plane_opacity: float = 0.5
@export var separation: float = 0.5 # Distance between planes centers

func _ready():
	_create_subtractive_mix(Vector3(-4, 0, 0))
	_create_additive_mix(Vector3(4, 0, 0))
	_create_labels()

func _create_subtractive_mix(position: Vector3):
	# Subtractive Mixing (CMY) - Like Ink/Paint
	# Cyan + Magenta = Blue
	# Magenta + Yellow = Red
	# Yellow + Cyan = Green
	# All three = Black (dark grey)
	
	var root = Node3D.new()
	root.name = "SubtractiveMix"
	root.position = position
	add_child(root)
	
	# Create 3 overlapping planes in a triangle formation
	
	# Cyan
	_create_plane(root, "Cyan", Color(0, 1, 1, plane_opacity), Vector3(0, 1, 0), false)
	
	# Magenta
	_create_plane(root, "Magenta", Color(1, 0, 1, plane_opacity), Vector3(-0.8, -0.5, 0.01), false)
	
	# Yellow
	_create_plane(root, "Yellow", Color(1, 1, 0, plane_opacity), Vector3(0.8, -0.5, 0.02), false)

func _create_additive_mix(position: Vector3):
	# Additive Mixing (RGB) - Like Light/Screens
	# Red + Green = Yellow
	# Green + Blue = Cyan
	# Blue + Red = Magenta
	# All three = White
	
	var root = Node3D.new()
	root.name = "AdditiveMix"
	root.position = position
	add_child(root)
	
	# Red
	_create_plane(root, "Red", Color(1, 0, 0, 1.0), Vector3(0, 1, 0), true)
	
	# Green
	_create_plane(root, "Green", Color(0, 1, 0, 1.0), Vector3(-0.8, -0.5, 0.01), true)
	
	# Blue
	_create_plane(root, "Blue", Color(0, 0, 1, 1.0), Vector3(0.8, -0.5, 0.02), true)

func _create_plane(parent: Node, name: String, color: Color, pos: Vector3, additive: bool):
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = name
	
	var mesh = BoxMesh.new() # Use thin box for plane
	mesh.size = Vector3(plane_size, plane_size, plane_thickness)
	mesh_inst.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	if additive:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_color.a = 0.5 # Lower alpha for add to prevent instant white
	else:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	
	parent.add_child(mesh_inst)

func _create_labels():
	var sub_label = Label3D.new()
	sub_label.text = "Subtractive (CMY)\nMix"
	sub_label.font_size = 64
	sub_label.position = Vector3(-4, 2.5, 0)
	add_child(sub_label)
	
	var add_label = Label3D.new()
	add_label.text = "Additive (RGB)\nLight"
	add_label.font_size = 64
	add_label.position = Vector3(4, 2.5, 0)
	add_child(add_label)
