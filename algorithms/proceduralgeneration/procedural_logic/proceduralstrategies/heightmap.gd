# heightmap.gd - Generate terrain from heightmap/noise
extends Node3D

@export var resolution: int = 64
@export var size: float = 50.0
@export var height_scale: float = 10.0
@export var noise_frequency: float = 0.05
@export var octaves: int = 4

var mesh_instance: MeshInstance3D
var noise: FastNoiseLite

func _ready():
	setup_noise()
	generate_mesh()

func setup_noise():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_frequency
	noise.fractal_octaves = octaves
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM

func generate_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var cell_size = size / float(resolution - 1)
	
	# Generate heightmap vertices
	for z in range(resolution - 1):
		for x in range(resolution - 1):
			# Get four corners of quad
			var v00 = get_vertex(x, z, cell_size)
			var v10 = get_vertex(x + 1, z, cell_size)
			var v01 = get_vertex(x, z + 1, cell_size)
			var v11 = get_vertex(x + 1, z + 1, cell_size)
			
			# First triangle
			st.add_vertex(v00)
			st.add_vertex(v11)
			st.add_vertex(v10)
			
			# Second triangle
			st.add_vertex(v00)
			st.add_vertex(v01)
			st.add_vertex(v11)
	
	st.generate_normals()
	
	if mesh_instance:
		mesh_instance.queue_free()
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.7, 0.3)
	material.roughness = 0.9
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

func get_vertex(x: int, z: int, cell_size: float) -> Vector3:
	var world_x = (x - resolution * 0.5) * cell_size
	var world_z = (z - resolution * 0.5) * cell_size
	var height = noise.get_noise_2d(x, z) * height_scale
	return Vector3(world_x, height, world_z)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			setup_noise()
			generate_mesh()
