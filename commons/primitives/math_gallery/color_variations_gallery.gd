# ColorVariationsGallery.gd - Shows all 3 color variations of each math object
@tool
extends Node3D

@export var row_spacing: float = 0.35
@export var col_spacing: float = 0.25
@export var show_labels: bool = true

# Mathematical object definitions with 3 color variations
const MATH_OBJECTS := [
	{"name": "Tetrahedron", "script": "grab_tetrahedron.gd", "formula": "F=4, V=4, E=6",
	 "colors": [Color(1.0, 0.0, 1.0), Color(0.8, 0.2, 0.8), Color(0.6, 0.0, 0.6)]},
	{"name": "Cube", "script": "grab_cube.gd", "formula": "F=6, V=8, E=12",
	 "colors": [Color(0.0, 1.0, 1.0), Color(0.2, 0.8, 0.8), Color(0.0, 0.6, 0.6)]},
	{"name": "Octahedron", "script": "grab_octahedron.gd", "formula": "F=8, V=6, E=12",
	 "colors": [Color(1.0, 0.5, 0.0), Color(0.8, 0.4, 0.0), Color(0.6, 0.3, 0.0)]},
	{"name": "Dodecahedron", "script": "grab_dodecahedron.gd", "formula": "F=12, V=20, E=30",
	 "colors": [Color(1.0, 0.8, 0.2), Color(0.8, 0.6, 0.1), Color(0.9, 0.7, 0.0)]},
	{"name": "Icosahedron", "script": "grab_icosahedron.gd", "formula": "F=20, V=12, E=30",
	 "colors": [Color(0.2, 0.6, 1.0), Color(0.1, 0.4, 0.8), Color(0.0, 0.3, 0.6)]},
	{"name": "Bipyramid", "script": "grab_bipyramid.gd", "formula": "F=8, V=6, E=12",
	 "colors": [Color(0.6, 0.0, 0.8), Color(0.5, 0.0, 0.6), Color(0.4, 0.0, 0.5)]},
	{"name": "Pyramid", "script": "grab_pyramid.gd", "formula": "F=5, V=5, E=8",
	 "colors": [Color(1.0, 0.9, 0.3), Color(0.9, 0.8, 0.2), Color(0.8, 0.7, 0.1)]},
	{"name": "Prism", "script": "grab_prism.gd", "formula": "F=5, V=6, E=9",
	 "colors": [Color(0.4, 0.8, 0.4), Color(0.3, 0.6, 0.3), Color(0.2, 0.5, 0.2)]},
	{"name": "Truncated Tetra", "script": "grab_truncated_tetrahedron.gd", "formula": "F=8, V=12, E=18",
	 "colors": [Color(1.0, 0.5, 0.0), Color(0.9, 0.4, 0.0), Color(0.7, 0.3, 0.0)]},
	{"name": "Sphere", "script": "grab_sphere.gd", "formula": "A=4πr²",
	 "colors": [Color(0.8, 0.2, 0.2), Color(0.6, 0.1, 0.1), Color(0.9, 0.3, 0.3)]},
	{"name": "Torus", "script": "grab_torus.gd", "formula": "χ=0, genus=1",
	 "colors": [Color(0.2, 0.8, 0.4), Color(0.1, 0.6, 0.3), Color(0.3, 0.9, 0.5)]},
	{"name": "Menger Sponge", "script": "grab_menger_sponge.gd", "formula": "D≈2.727",
	 "colors": [Color(0.4, 0.4, 0.8), Color(0.3, 0.3, 0.6), Color(0.5, 0.5, 0.9)]}
]

const LabelPlateScene = preload("res://commons/primitives/math_gallery/LabelPlate.tscn")
const PedestalScene = preload("res://commons/primitives/math_gallery/Pedestal.tscn")

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_build_gallery()

func _build_gallery() -> void:
	for child in get_children():
		child.queue_free()
	
	var row := 0
	for obj_def in MATH_OBJECTS:
		# Create 3 color variations in a row
		for color_idx in range(3):
			_create_display_item(obj_def, row, color_idx, color_idx)
		row += 1

func _create_display_item(obj_def: Dictionary, row: int, col: int, color_idx: int) -> void:
	var x := col * col_spacing
	var z := row * row_spacing
	
	var container = Node3D.new()
	container.name = obj_def["name"].replace(" ", "") + "_v" + str(color_idx)
	container.position = Vector3(x, 0, z)
	add_child(container)
	
	# Pedestal
	var pedestal = PedestalScene.instantiate()
	pedestal.pedestal_radius = 0.06
	container.add_child(pedestal)
	
	# Math object
	var script_path = "res://commons/primitives/math_gallery/" + obj_def["script"]
	var script = load(script_path)
	if script:
		var pickable_scene = load("res://addons/godot-xr-tools/objects/pickable.tscn")
		var obj = pickable_scene.instantiate()
		obj.name = "MathObject"
		obj.set_script(script)
		obj.base_color = obj_def["colors"][color_idx]
		obj.object_scale = 0.06
		obj.position.y = 0.06
		container.add_child(obj)
	
	# Label only on first variation
	if show_labels and color_idx == 0:
		var label = LabelPlateScene.instantiate()
		label.object_name = obj_def["name"]
		label.formula = obj_def["formula"]
		label.plate_width = 0.22
		label.position = Vector3(col_spacing, -0.01, 0.1)
		container.add_child(label)
