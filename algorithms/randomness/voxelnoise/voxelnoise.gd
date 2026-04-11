# VoxelWorld.gd
# @identity
# essence: voxel[x,y,z] = 1 if FastNoiseLite.get_noise_3d(x,y,z) > iso_level else 0 — continuous noise field discretized into a binary 3D grid
# desire: to touch the threshold — to slide iso_level and watch a landscape of solid cubes dissolve or materialize, understanding that the voxel world is just a snapshot of a continuous noise field
# critical_parameter: iso_level — the decision boundary between solid and void; small changes cause avalanches of appearing/disappearing cubes
# triggers: iso_level crosses a noise peak → a cave collapses; noise_scale changes → the spatial frequency of the underlying field reshapes what's solid
# emerges: the iso-surface concept — that topology of solid matter is defined by a threshold value, not by explicit geometry; also the glass/pink shader makes solid cubes feel crystalline
# needs: links to perlin_terrain_sculptor via apply_perlin_terrain_controls signal bus [has]; no standalone VR sliders [missing]; responds to group "voxelnoise_receivers" [has]
# relationships: depends on perlin_terrain_sculptor for interactive control; discretizes what noiselayers shows continuously; connects to marching cubes (smoother iso-surface)
# truth: matter is a threshold — the voxel world reveals that solid and void are not intrinsic qualities but the result of where you draw the line through a continuous field
extends Node3D

# Local debug flag to gate prints (default off)
@export var debug: bool = false

@export var chunk_size: int = 32
@export var world_height: int = 64
@export var voxel_scale: float = 1.0
@export var iso_level: float = 0.0
@export var generation_offset: Vector3i = Vector3i(3, 0, 3)

@export var noise_seed: int = 1337
@export var noise_scale: float = 0.05
@export var noise_octaves: int = 4
@export var noise_persistence: float = 0.5
@export var noise_lacunarity: float = 2.0

@export_group("Perlin Sculptor Link")
@export var link_to_perlin_sculptor: bool = true
@export var linked_frequency_min: float = 0.005
@export var linked_frequency_max: float = 0.18
@export var linked_iso_bias: float = 0.0

var noise: FastNoiseLite
var _generated_root: Node3D
var _rebuild_queued: bool = false

func _ready() -> void:
	add_to_group("voxelnoise_receivers")
	_ensure_generated_root()
	_queue_rebuild()


func _generate_chunk(chunk_pos: Vector3i) -> void:
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(chunk_size):
		for y in range(1, world_height + 1):  # Start at Y=1, go up to world_height
			for z in range(chunk_size):
				var world_x = chunk_pos.x * chunk_size + x + generation_offset.x
				var world_y = y + generation_offset.y
				var world_z = chunk_pos.z * chunk_size + z + generation_offset.z

				var p = Vector3(world_x, world_y, world_z)
				var val = noise.get_noise_3d(p.x, p.y, p.z)

				if val > iso_level:
					_add_cube(st, p * voxel_scale)

	st.generate_normals()
	mesh = st.commit()

	# MeshInstance for rendering
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	_generated_root.add_child(mi)

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
		_generated_root.add_child(col)

func apply_perlin_terrain_controls(payload: Dictionary) -> void:
	if not link_to_perlin_sculptor:
		return

	var threshold_value: float = float(payload.get("threshold", iso_level))
	var scale_norm: float = clampf(float(payload.get("noise_scale_norm", 0.0)), 0.0, 1.0)
	var mapped_frequency: float = lerpf(linked_frequency_min, linked_frequency_max, scale_norm)

	iso_level = clampf(threshold_value + linked_iso_bias, -1.0, 1.0)
	noise_scale = mapped_frequency
	if payload.has("noise_octaves"):
		noise_octaves = clampi(int(payload.get("noise_octaves", noise_octaves)), 1, 8)
	if payload.has("seed"):
		noise_seed = int(payload.get("seed", noise_seed))

	if debug:
		print("Voxelnoise: linked update -> iso=%.3f freq=%.4f oct=%d seed=%d" % [iso_level, noise_scale, noise_octaves, noise_seed])

	_queue_rebuild()

func _ensure_generated_root() -> void:
	if _generated_root != null:
		return

	_generated_root = get_node_or_null("Generated") as Node3D
	if _generated_root == null:
		_generated_root = Node3D.new()
		_generated_root.name = "Generated"
		add_child(_generated_root)

func _configure_noise() -> void:
	if noise == null:
		noise = FastNoiseLite.new()

	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = noise_seed
	noise.frequency = noise_scale
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = noise_octaves
	noise.fractal_lacunarity = noise_lacunarity
	noise.fractal_gain = noise_persistence

func _clear_generated() -> void:
	if _generated_root == null:
		return

	for child in _generated_root.get_children():
		child.queue_free()

func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_now")

func _rebuild_now() -> void:
	_rebuild_queued = false
	_ensure_generated_root()
	_configure_noise()
	_clear_generated()
	_generate_chunk(Vector3i.ZERO)


func _add_cube(st: SurfaceTool, pos: Vector3) -> void:
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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
