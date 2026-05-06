# MathGallery.gd - Gallery display of mathematical objects
@tool
extends Node3D

@export var grid_spacing: float = 0.35
@export var objects_per_row: int = 4
@export var show_labels: bool = true
@export var show_pedestals: bool = true

# Mathematical object definitions with formulas
const MATH_OBJECTS := [
	{
		"name": "Tetrahedron",
		"script": "grab_tetrahedron.gd",
		"formula": "F=4, V=4, E=6",
		"colors": [Color(1.0, 0.0, 1.0), Color(0.8, 0.2, 0.8), Color(0.6, 0.0, 0.6)]
	},
	{
		"name": "Cube",
		"script": "grab_cube.gd",
		"formula": "F=6, V=8, E=12",
		"colors": [Color(0.0, 1.0, 1.0), Color(0.2, 0.8, 0.8), Color(0.0, 0.6, 0.6)]
	},
	{
		"name": "Octahedron",
		"script": "grab_octahedron.gd",
		"formula": "F=8, V=6, E=12",
		"colors": [Color(1.0, 0.5, 0.0), Color(0.8, 0.4, 0.0), Color(0.6, 0.3, 0.0)]
	},
	{
		"name": "Dodecahedron",
		"script": "grab_dodecahedron.gd",
		"formula": "F=12, V=20, E=30",
		"colors": [Color(1.0, 0.8, 0.2), Color(0.8, 0.6, 0.1), Color(0.9, 0.7, 0.0)]
	},
	{
		"name": "Icosahedron",
		"script": "grab_icosahedron.gd",
		"formula": "F=20, V=12, E=30",
		"colors": [Color(0.2, 0.6, 1.0), Color(0.1, 0.4, 0.8), Color(0.0, 0.3, 0.6)]
	},
	{
		"name": "Bipyramid",
		"script": "grab_bipyramid.gd",
		"formula": "F=8, V=6, E=12",
		"colors": [Color(0.6, 0.0, 0.8), Color(0.5, 0.0, 0.6), Color(0.4, 0.0, 0.5)]
	},
	{
		"name": "Pyramid",
		"script": "grab_pyramid.gd",
		"formula": "F=5, V=5, E=8",
		"colors": [Color(1.0, 0.9, 0.3), Color(0.9, 0.8, 0.2), Color(0.8, 0.7, 0.1)]
	},
	{
		"name": "Prism",
		"script": "grab_prism.gd",
		"formula": "F=5, V=6, E=9",
		"colors": [Color(0.4, 0.8, 0.4), Color(0.3, 0.6, 0.3), Color(0.2, 0.5, 0.2)]
	},
	{
		"name": "Truncated Tetra",
		"script": "grab_truncated_tetrahedron.gd",
		"formula": "F=8, V=12, E=18",
		"colors": [Color(1.0, 0.5, 0.0), Color(0.9, 0.4, 0.0), Color(0.7, 0.3, 0.0)]
	},
	{
		"name": "Sphere",
		"script": "grab_sphere.gd",
		"formula": "A=4πr², V=4/3πr³",
		"colors": [Color(0.8, 0.2, 0.2), Color(0.6, 0.1, 0.1), Color(0.9, 0.3, 0.3)]
	},
	{
		"name": "Torus",
		"script": "grab_torus.gd",
		"formula": "χ=0, genus=1",
		"colors": [Color(0.2, 0.8, 0.4), Color(0.1, 0.6, 0.3), Color(0.3, 0.9, 0.5)]
	},
	{
		"name": "Menger Sponge",
		"script": "grab_menger_sponge.gd",
		"formula": "D≈2.727 (fractal)",
		"colors": [Color(0.4, 0.4, 0.8), Color(0.3, 0.3, 0.6), Color(0.5, 0.5, 0.9)]
	}
]

const LabelPlateScene = preload("res://commons/primitives/math_gallery/LabelPlate.tscn")
const PedestalScene = preload("res://commons/primitives/math_gallery/Pedestal.tscn")

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_build_gallery()

func _build_gallery() -> void:
	# Clear existing children (except non-generated ones)
	for child in get_children():
		child.queue_free()
	
	var row := 0
	var col := 0
	
	for obj_def in MATH_OBJECTS:
		# Create just the first color variation for the main display
		_create_display_item(obj_def, row, col, 0)
		
		col += 1
		if col >= objects_per_row:
			col = 0
			row += 1

func _create_display_item(obj_def: Dictionary, row: int, col: int, color_idx: int) -> void:
	var x := col * grid_spacing
	var z := row * grid_spacing
	
	# Create container
	var container = Node3D.new()
	container.name = obj_def["name"].replace(" ", "") + "_" + str(color_idx)
	container.position = Vector3(x, 0, z)
	add_child(container)
	
	# Create pedestal
	if show_pedestals:
		var pedestal = PedestalScene.instantiate()
		container.add_child(pedestal)
	
	# Create math object
	var script_path = "res://commons/primitives/math_gallery/" + obj_def["script"]
	var script = load(script_path)
	if script:
		var pickable_scene = load("res://addons/godot-xr-tools/objects/pickable.tscn")
		var math_object = pickable_scene.instantiate()
		math_object.name = "MathObject"
		math_object.set_script(script)
		
		# Set color
		var colors: Array = obj_def["colors"]
		if color_idx < colors.size():
			math_object.base_color = colors[color_idx]
		
		math_object.object_scale = 0.08
		math_object.position.y = 0.07
		container.add_child(math_object)
	
	# Create label
	if show_labels:
		var label = LabelPlateScene.instantiate()
		label.object_name = obj_def["name"]
		label.formula = obj_def["formula"]
		label.position.y = -0.01
		label.position.z = 0.12
		container.add_child(label)

func regenerate() -> void:
	_build_gallery()
