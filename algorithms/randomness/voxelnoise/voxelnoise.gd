# VoxelWorld.gd
extends Node3D

@export var chunk_size: int = 32
@export var world_height: int = 64
@export var voxel_scale: float = 1.0
@export var iso_level: float = 0.0

@export var noise_seed: int = 1337
@export var noise_scale: float = 0.05
@export var noise_octaves: int = 4
@export var noise_persistence: float = 0.5
@export var noise_lacunarity: float = 2.0

var noise: FastNoiseLite

func _ready():
	# Setup noise
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = noise_seed
	noise.frequency = noise_scale
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = noise_octaves
	noise.fractal_lacunarity = noise_lacunarity
	noise.fractal_gain = noise_persistence

	# Generate one chunk for demo
	_generate_chunk(Vector3i.ZERO)


func _generate_chunk(chunk_pos: Vector3i):
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(chunk_size):
		for y in range(world_height):
			for z in range(chunk_size):
				var world_x = chunk_pos.x * chunk_size + x
				var world_y = y
				var world_z = chunk_pos.z * chunk_size + z

				var p = Vector3(world_x, world_y, world_z)
				var val = noise.get_noise_3d(p.x, p.y, p.z)

				if val > iso_level:
					_add_cube(st, p * voxel_scale)

	st.generate_normals()
	mesh = st.commit()

	# MeshInstance for rendering
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)

	# Apply shader material
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode cull_disabled;

	uniform vec4 glass_color : source_color = vec4(0.2, 0.4, 1.0, 1.0); // solid blue glass
	uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.5, 1.0); // pink outline
	uniform float outline_width : hint_range(0.5, 5.0) = 1.5;

	varying vec3 barycentric;

	void vertex() {
		// Assign barycentric coords based on vertex ID (for edge detection)
		int vid = VERTEX_ID % 3;
		if (vid == 0) barycentric = vec3(1.0, 0.0, 0.0);
		else if (vid == 1) barycentric = vec3(0.0, 1.0, 0.0);
		else barycentric = vec3(0.0, 0.0, 1.0);
	}

	void fragment() {
		// Edge factor from barycentrics
		vec3 d = fwidth(barycentric);
		vec3 a3 = smoothstep(vec3(0.0), d * outline_width, barycentric);
		float edge = 1.0 - min(min(a3.x, a3.y), a3.z);

		// Mix between blue glassy fill and pink outline
		vec3 color = mix(glass_color.rgb, outline_color.rgb, edge);

		ALBEDO = color;

		// Give "glassiness" with smooth specular highlights
		METALLIC = 0.1;
		ROUGHNESS = 0.1;

		// Pink edge glow
		EMISSION = outline_color.rgb * edge * 1.2;
	}


	"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mi.set_surface_override_material(0, mat)

	# Collider for physics
	if mesh != null and mesh.get_surface_count() > 0:
		var col = StaticBody3D.new()
		var shape = CollisionShape3D.new()
		var concave = ConcavePolygonShape3D.new()
		concave.data = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		shape.shape = concave
		col.add_child(shape)
		add_child(col)


func _add_cube(st: SurfaceTool, pos: Vector3):
	var s = voxel_scale * 0.5
	var verts = [
		Vector3(-s, -s, -s), Vector3(s, -s, -s),
		Vector3(s,  s, -s), Vector3(-s,  s, -s),
		Vector3(-s, -s,  s), Vector3(s, -s,  s),
		Vector3(s,  s,  s), Vector3(-s,  s,  s)
	]
	var idx = [
		0,1,2, 2,3,0,
		1,5,6, 6,2,1,
		5,4,7, 7,6,5,
		4,0,3, 3,7,4,
		3,2,6, 6,7,3,
		4,5,1, 1,0,4
	]
	for i in idx:
		st.add_vertex(pos + verts[i])
