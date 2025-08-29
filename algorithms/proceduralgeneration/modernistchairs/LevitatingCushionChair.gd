# LevitatingCushionChair.gd
# Procedural generation of levitating cushion chairs
extends Node3D
class_name LevitatingCushionChair

@export var cushion_size: float = 0.5
@export var levitation_height: float = 0.45
@export var field_strength: float = 0.1
@export var generate_on_ready: bool = true

var materials: ModernistMaterials

func _ready():
	materials = ModernistMaterials.new()
	add_child(materials)
	if generate_on_ready:
		generate_chair()

func generate_chair():
	# Main floating cushion
	var seat_cushion = MeshInstance3D.new()
	seat_cushion.mesh = BoxMesh.new()
	seat_cushion.mesh.size = Vector3(cushion_size, 0.08, cushion_size)
	seat_cushion.position = Vector3(0, levitation_height, 0)
	seat_cushion.material_override = materials.get_material("memory_foam")
	add_child(seat_cushion)
	
	# Back cushion
	var back_cushion = MeshInstance3D.new()
	back_cushion.mesh = BoxMesh.new()
	back_cushion.mesh.size = Vector3(cushion_size, 0.4, 0.06)
	back_cushion.position = Vector3(0, levitation_height + 0.25, -cushion_size/2)
	back_cushion.material_override = materials.get_material("memory_foam")
	add_child(back_cushion)
	
	# Invisible field generators (small metallic cubes)
	var generator_positions = [
		Vector3(-0.3, 0, -0.3),
		Vector3(0.3, 0, -0.3),
		Vector3(-0.3, 0, 0.3),
		Vector3(0.3, 0, 0.3)
	]
	
	for pos in generator_positions:
		var generator = MeshInstance3D.new()
		generator.mesh = BoxMesh.new()
		generator.mesh.size = Vector3(0.05, 0.05, 0.05)
		generator.position = pos
		generator.material_override = materials.get_material("holographic")
		add_child(generator)
		
		# Add field effect particles (simplified as small spheres)
		for i in range(5):
			var field_particle = MeshInstance3D.new()
			field_particle.mesh = SphereMesh.new()
			field_particle.mesh.radius = 0.002
			var random_offset = Vector3(randf_range(-0.1, 0.1), randf_range(0, levitation_height), randf_range(-0.1, 0.1))
			field_particle.position = pos + random_offset
			field_particle.material_override = materials.get_material("holographic")
			add_child(field_particle)

func regenerate_with_parameters(params: Dictionary):
	for child in get_children():
		if child != materials:
			child.queue_free()
	generate_chair()
