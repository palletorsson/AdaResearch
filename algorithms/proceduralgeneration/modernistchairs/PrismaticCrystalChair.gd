# PrismaticCrystalChair.gd
# Procedural generation of crystalline faceted chairs
extends Node3D
class_name PrismaticCrystalChair

@export var base_width: float = 0.6
@export var base_height: float = 0.8
@export var facet_count: int = 20
@export var crystal_complexity: float = 0.3
@export var generate_on_ready: bool = true

var materials: ModernistMaterials

func _ready():
	materials = ModernistMaterials.new()
	add_child(materials)
	if generate_on_ready:
		generate_chair()

func generate_chair():
	var crystal_instance = MeshInstance3D.new()
	add_child(crystal_instance)
	
	# Create crystalline geometry using CSG operations
	var base_box = CSGBox3D.new()
	base_box.size = Vector3(base_width, base_height, base_width)
	
	# Add random faceted cuts
	for i in range(facet_count):
		var cut_box = CSGBox3D.new()
		cut_box.operation = CSGShape3D.OPERATION_SUBTRACTION
		cut_box.size = Vector3(randf_range(0.1, 0.3), randf_range(0.1, 0.4), randf_range(0.1, 0.3))
		cut_box.position = Vector3(
			randf_range(-base_width/3, base_width/3),
			randf_range(-base_height/3, base_height/3),
			randf_range(-base_width/3, base_width/3)
		)
		cut_box.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		base_box.add_child(cut_box)
	
	crystal_instance.add_child(base_box)
	crystal_instance.material_override = materials.get_material("clear_acrylic")

func regenerate_with_parameters(params: Dictionary):
	for child in get_children():
		if child != materials:
			child.queue_free()
	generate_chair()

