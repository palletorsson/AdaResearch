# SineSpace.gd - Perfect mathematical waves
extends TopologySpace
class_name SineSpace

@export var wave_frequency: float = 2.0
@export var wave_amplitude: float = 1.0
@export var phase_x: float = 0.0
@export var phase_z: float = 0.0

func generate_space():
	var heights = []
	
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var world_x = (x / float(resolution)) * space_size.x - space_size.x/2
			var world_z = (z / float(resolution)) * space_size.y - space_size.y/2
			
			# Perfect sine wave topology
			var height = wave_amplitude * sin(world_x * wave_frequency + phase_x) * cos(world_z * wave_frequency + phase_z)
			heights.append(height * height_scale)
	
	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	
	# Use Godot's built-in collision creation
	create_collision_from_mesh(mesh)
	
	# Smooth material for surveillance aesthetic
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.metallic = 0.8
	material.roughness = 0.1
	mesh_instance.material_override = material
