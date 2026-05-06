extends Node3D
class_name WorleyNoise

## Worley (cellular) noise — floor display showing Voronoi/cellular noise.
## Scatters random seed points, then for each pixel computes distance to the
## nearest (F1) and second-nearest (F2) seeds. Renders F2-F1 for the classic
## cell boundary look, complementing Perlin/Simplex noise artifacts.

# @identity
# essence: for each pixel: F1=nearest seed distance, F2=second nearest; render (F2-F1) → bright thin edges on dark cell interiors; Voronoi tessellation as texture
# desire: to make cellular structure visible — the same distance function that divides a map into postal zones also generates skin texture, stone, and cell membranes
# critical_parameter: num_seeds — few seeds create large cells (stone slab); many seeds create tight cells (skin, scales); the count IS the cell density
# triggers: _ready → scatter num_seeds at random positions → per pixel: compute distances to all seeds → sort → F1=first, F2=second → color = clamp(F2-F1)
# emerges: cells with razor-thin bright edges — the Voronoi tessellation drawn not by geometry but by the distance census every pixel takes of its neighbors
# needs: VR seed count slider [missing], animated seed movement [missing], F-value selector [missing]
# relationships: inverse of noise_mixer (Worley uses distance, Perlin uses gradient); complement to lyapunov_fractal (both show structure in 2D parameter fields)
# truth: Worley noise is a democracy — every pixel votes for its nearest neighbor, and the visible borders are where two candidates tie.

# --- Configuration ---

@export var quad_size: Vector2 = Vector2(0.8, 0.8)
@export var num_seeds: int = 30
@export var seed_value: int = 42

const IMAGE_SIZE: int = 128
const BG_COLOR: Color = Color(0.02, 0.02, 0.05)
const CELL_COLOR: Color = Color(0.15, 0.55, 0.85)
const EDGE_COLOR: Color = Color(0.9, 0.95, 1.0)

var _mesh_inst: MeshInstance3D
var _material: StandardMaterial3D
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	_build_floor_quad()
	_generate_texture()


func _build_floor_quad() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "WorleyMesh"
	var quad := QuadMesh.new()
	quad.size = quad_size
	_mesh_inst.mesh = quad
	_mesh_inst.rotation_degrees.x = -90
	_mesh_inst.position.y = 0.005

	_material = StandardMaterial3D.new()
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.roughness = 0.85
	_material.metallic = 0.0
	_mesh_inst.material_override = _material
	add_child(_mesh_inst)


func _generate_texture() -> void:
	# Scatter seed points in [0, IMAGE_SIZE) space
	var seeds := PackedVector2Array()
	for i in range(num_seeds):
		seeds.append(Vector2(
			_rng.randf() * IMAGE_SIZE,
			_rng.randf() * IMAGE_SIZE
		))

	var image := Image.create(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(BG_COLOR)

	# Precompute F1 and F2 distances for every pixel
	var f1_buf := PackedFloat32Array()
	var f2_buf := PackedFloat32Array()
	f1_buf.resize(IMAGE_SIZE * IMAGE_SIZE)
	f2_buf.resize(IMAGE_SIZE * IMAGE_SIZE)

	var max_f2f1 := 0.0

	for py in range(IMAGE_SIZE):
		for px in range(IMAGE_SIZE):
			var pos := Vector2(float(px) + 0.5, float(py) + 0.5)
			var d1 := 1e10  # nearest
			var d2 := 1e10  # second nearest

			for s in seeds:
				var d := pos.distance_to(s)
				if d < d1:
					d2 = d1
					d1 = d
				elif d < d2:
					d2 = d

			var idx := py * IMAGE_SIZE + px
			f1_buf[idx] = d1
			f2_buf[idx] = d2

			var diff := d2 - d1
			if diff > max_f2f1:
				max_f2f1 = diff

	# Render F2-F1 to image — bright at cell edges, dark at cell centers
	if max_f2f1 < 0.001:
		max_f2f1 = 1.0

	for py in range(IMAGE_SIZE):
		for px in range(IMAGE_SIZE):
			var idx := py * IMAGE_SIZE + px
			var t := clampf((f2_buf[idx] - f1_buf[idx]) / max_f2f1, 0.0, 1.0)
			# Sqrt gamma for better visibility of cell structure
			t = sqrt(t)
			var color := CELL_COLOR.lerp(EDGE_COLOR, t)
			image.set_pixel(px, py, color)

	var texture := ImageTexture.create_from_image(image)
	_material.albedo_texture = texture


## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("num_seeds"):
		num_seeds = int(config_data["num_seeds"])
	if config_data.has("seed"):
		seed_value = int(config_data["seed"])
		_rng.seed = seed_value
		_generate_texture()
