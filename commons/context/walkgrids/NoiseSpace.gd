# NoiseSpace.gd - Algorithmic disruption
extends TopologySpace
class_name NoiseSpace

@export var noise_scale: float = 5.0
@export var octaves: int = 4
@export var persistence: float = 0.5

var noise: FastNoiseLite

func _ready():
	noise = FastNoiseLite.new()
	noise.frequency = 0.1
	noise.fractal_octaves = octaves
	super._ready()

func generate_space():
	var heights = []
	
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var world_x = (x / float(resolution)) * space_size.x - space_size.x/2
			var world_z = (z / float(resolution)) * space_size.y - space_size.y/2
			
			# Fractal noise - spaces of resistance
			var height = noise.get_noise_2d(world_x * noise_scale, world_z * noise_scale)
			heights.append(height * height_scale)
	
	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	
	# Rough material for disruption aesthetic
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.7, 0.4) # Organic green
	material.roughness = 0.9
	material.metallic = 0.1
	mesh_instance.material_override = material
