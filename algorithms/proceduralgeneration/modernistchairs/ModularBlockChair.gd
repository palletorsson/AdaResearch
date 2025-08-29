# ModularBlockChair.gd
# Procedural generation of De Stijl modular block chairs
# Inspired by Gerrit Rietveld's Red and Blue Chair
extends Node3D
class_name ModularBlockChair

@export var block_thickness: float = 0.03
@export var seat_width: float = 0.4
@export var seat_depth: float = 0.35
@export var back_height: float = 0.7
@export var generate_on_ready: bool = true

var materials: ModernistMaterials

func _ready():
	materials = ModernistMaterials.new()
	add_child(materials)
	if generate_on_ready:
		generate_chair()

func generate_chair():
	var primary_colors = materials.get_primary_color_set()
	
	# Horizontal seat plank
	var seat = MeshInstance3D.new()
	seat.mesh = BoxMesh.new()
	seat.mesh.size = Vector3(seat_width, block_thickness, seat_depth)
	seat.position = Vector3(0, 0.4, 0)
	seat.material_override = primary_colors[0]  # Red
	add_child(seat)
	
	# Vertical back plank
	var back = MeshInstance3D.new()
	back.mesh = BoxMesh.new()
	back.mesh.size = Vector3(seat_width, back_height - 0.4, block_thickness)
	back.position = Vector3(0, (back_height + 0.4) / 2, -seat_depth/2)
	back.material_override = primary_colors[1]  # Blue
	add_child(back)
	
	# Vertical supports
	var support_positions = [
		Vector3(-seat_width/2 + block_thickness/2, 0.2, seat_depth/2 - block_thickness/2),
		Vector3(seat_width/2 - block_thickness/2, 0.2, seat_depth/2 - block_thickness/2),
		Vector3(-seat_width/2 + block_thickness/2, 0.2, -seat_depth/2 + block_thickness/2),
		Vector3(seat_width/2 - block_thickness/2, 0.2, -seat_depth/2 + block_thickness/2)
	]
	
	for i in range(4):
		var support = MeshInstance3D.new()
		support.mesh = BoxMesh.new()
		support.mesh.size = Vector3(block_thickness, 0.4, block_thickness)
		support.position = support_positions[i]
		support.material_override = primary_colors[4] if i % 2 == 0 else primary_colors[3]  # Black/White
		add_child(support)

func regenerate_with_parameters(params: Dictionary):
	for child in get_children():
		if child != materials:
			child.queue_free()
	generate_chair()
