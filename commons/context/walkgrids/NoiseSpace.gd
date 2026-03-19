# NoiseSpace.gd - Algorithmic disruption
# @identity
# essence: height(x,z) = FastNoiseLite.get_noise_2d(x × noise_scale, z × noise_scale) × height_scale — fractal noise as a walkable terrain substrate
# desire: to walk across a landscape that is simultaneously random and smooth — to feel that the ground underfoot is coherent without being designed
# critical_parameter: noise_scale — at low values the terrain is a gentle undulation; at high values it becomes violently jagged; the sweet spot is where walking feels organic
# triggers: changing octaves changes how many scales of detail are superimposed; the organic green material reinforces the disruption aesthetic of non-Euclidean space
# emerges: the TopologySpace base class provides the mesh infrastructure; the noise generates height variation that makes this space feel like resistance — harder to traverse than a flat grid
# needs: no VR controls [missing]; all parameters are export-only; the terrain is generated once at startup and does not update dynamically [has]
# relationships: extends TopologySpace alongside other walkgrid substrates (FractalSpace, ErosionSpace, WaveInterferenceSpace); contrasts with flat SineSpace; used as the noise_space map substrate
# truth: a noise landscape is the simplest possible proof that order and randomness are not opposites — every point in this terrain is deterministically computed yet no two regions feel the same
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
