# EcosystemTerrainGenerator.gd
# Generates terrain meshes based on EcosystemManager's terrain_mode.
# Modes: flat, noise, growth, self_generating.
# Place in a map scene — it creates/replaces the ground plane dynamically.

extends Node3D
class_name EcosystemTerrainGenerator

# ── Configuration ─────────────────────────────────────────────────────

## Size of the terrain grid in world units.
@export var terrain_size: float = 20.0

## Resolution: number of subdivisions per axis.
@export var resolution: int = 64

## Maximum height displacement for non-flat modes.
@export var max_height: float = 1.5

## Noise seed (-1 = random).
@export var noise_seed: int = -1

## Material color (base).
@export var base_color: Color = Color(0.12, 0.14, 0.18)

# ── Runtime ───────────────────────────────────────────────────────────

var _mesh_instance: MeshInstance3D = null
var _current_mode: String = "flat"
var _noise: FastNoiseLite = null
var _rng: RandomNumberGenerator = null
var _material: StandardMaterial3D = null


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	if noise_seed >= 0:
		_rng.seed = noise_seed
	else:
		_rng.randomize()

	_noise = FastNoiseLite.new()
	_noise.seed = _rng.randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.05
	_noise.fractal_octaves = 4

	_material = StandardMaterial3D.new()
	_material.albedo_color = Color.WHITE  # Let vertex colors drive the color
	_material.roughness = 0.85
	_material.vertex_color_use_as_albedo = true

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TerrainMesh"
	_mesh_instance.material_override = _material
	add_child(_mesh_instance)

	call_deferred("_connect_signals")
	call_deferred("_build_initial")


func _connect_signals() -> void:
	var eco = get_node_or_null("/root/EcosystemManager")
	if eco:
		if eco.has_signal("terrain_mode_changed"):
			eco.terrain_mode_changed.connect(_on_terrain_mode_changed)
		_current_mode = eco.get_terrain_mode()
		print("EcosystemTerrainGenerator: Connected (mode='%s')" % _current_mode)


func _build_initial() -> void:
	await get_tree().process_frame
	_generate_terrain()


func _on_terrain_mode_changed(new_mode: String) -> void:
	if new_mode == _current_mode:
		return
	_current_mode = new_mode
	_generate_terrain()
	print("EcosystemTerrainGenerator: Rebuilt terrain (mode='%s')" % _current_mode)


# ── Terrain Generation ────────────────────────────────────────────────

func _generate_terrain() -> void:
	match _current_mode:
		"flat":
			_build_flat()
		"noise":
			_build_noise()
		"growth":
			_build_growth()
		"self_generating":
			_build_self_generating()
		_:
			_build_flat()


func _build_flat() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(terrain_size, terrain_size)
	plane.subdivide_width = 1
	plane.subdivide_depth = 1
	_mesh_instance.mesh = plane
	# Flat mode has no vertex colors, so use base_color directly
	_material.albedo_color = base_color
	_material.vertex_color_use_as_albedo = false


func _build_noise() -> void:
	_noise.frequency = 0.04
	_noise.fractal_octaves = 3
	_build_heightmap(func(x: float, z: float) -> float:
		return _noise.get_noise_2d(x * 100.0, z * 100.0) * max_height * 0.6
	)


func _build_growth() -> void:
	# Cellular automata-style terrain: noise + discrete plateaus
	_noise.frequency = 0.06
	_noise.fractal_octaves = 4
	_build_heightmap(func(x: float, z: float) -> float:
		var n: float = _noise.get_noise_2d(x * 100.0, z * 100.0)
		# Quantize to create stepped / cellular look
		var steps: float = 5.0
		var stepped: float = round(n * steps) / steps
		return stepped * max_height * 0.8
	)


func _build_self_generating() -> void:
	# Rich layered terrain with multiple noise octaves
	_noise.frequency = 0.03
	_noise.fractal_octaves = 6

	var noise2 := FastNoiseLite.new()
	noise2.seed = _noise.seed + 42
	noise2.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise2.frequency = 0.08

	_build_heightmap(func(x: float, z: float) -> float:
		var base_n: float = _noise.get_noise_2d(x * 100.0, z * 100.0)
		var cell_n: float = noise2.get_noise_2d(x * 100.0, z * 100.0)
		# Blend Simplex with Cellular for organic-yet-structured terrain
		var blended: float = base_n * 0.7 + cell_n * 0.3
		# Add ridges near zero crossings
		var ridge: float = 1.0 - abs(base_n) * 2.0
		ridge = max(0.0, ridge)
		return (blended + ridge * 0.3) * max_height
	)


func _build_heightmap(height_fn: Callable) -> void:
	# Re-enable vertex colors for heightmap modes
	_material.albedo_color = Color.WHITE
	_material.vertex_color_use_as_albedo = true

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half := terrain_size * 0.5
	var step := terrain_size / float(resolution)

	# Generate vertices with heights
	var heights: Array = []  # [resolution+1][resolution+1]
	for zi in range(resolution + 1):
		var row: Array = []
		for xi in range(resolution + 1):
			var x: float = -half + xi * step
			var z: float = -half + zi * step
			var h: float = height_fn.call(x / terrain_size, z / terrain_size)
			row.append(h)
		heights.append(row)

	# Build triangles with normals and vertex colors
	for zi in range(resolution):
		for xi in range(resolution):
			var x0: float = -half + xi * step
			var x1: float = x0 + step
			var z0: float = -half + zi * step
			var z1: float = z0 + step

			var h00: float = heights[zi][xi]
			var h10: float = heights[zi][xi + 1]
			var h01: float = heights[zi + 1][xi]
			var h11: float = heights[zi + 1][xi + 1]

			var v00 := Vector3(x0, h00, z0)
			var v10 := Vector3(x1, h10, z0)
			var v01 := Vector3(x0, h01, z1)
			var v11 := Vector3(x1, h11, z1)

			# Vertex colors: height-based
			var c00 := _height_color(h00)
			var c10 := _height_color(h10)
			var c01 := _height_color(h01)
			var c11 := _height_color(h11)

			# Triangle 1: v00, v10, v01
			var n1 := (v10 - v00).cross(v01 - v00).normalized()
			st.set_normal(n1)
			st.set_color(c00); st.add_vertex(v00)
			st.set_color(c10); st.add_vertex(v10)
			st.set_color(c01); st.add_vertex(v01)

			# Triangle 2: v10, v11, v01
			var n2 := (v11 - v10).cross(v01 - v10).normalized()
			st.set_normal(n2)
			st.set_color(c10); st.add_vertex(v10)
			st.set_color(c11); st.add_vertex(v11)
			st.set_color(c01); st.add_vertex(v01)

	_mesh_instance.mesh = st.commit()


func _height_color(h: float) -> Color:
	# Map height to visible color gradient
	var t: float = clamp((h / max_height + 1.0) * 0.5, 0.0, 1.0)
	# Low = deep indigo, mid = forest green, high = sandy ochre
	var low := Color(0.08, 0.10, 0.22)
	var mid := Color(0.14, 0.38, 0.16)
	var high := Color(0.52, 0.38, 0.18)
	if t < 0.5:
		return low.lerp(mid, t * 2.0)
	else:
		return mid.lerp(high, (t - 0.5) * 2.0)
