extends Node3D

# Reaction-Diffusion (Gray-Scott Model) — 3D VR Version
# Simulation runs on a grid, rendered as texture on a QuadMesh panel.

var width: int = 128
var height: int = 128
var grid_a: Array = []
var grid_b: Array = []
var next_a: Array = []
var next_b: Array = []

var diffusion_a: float = 1.0
var diffusion_b: float = 0.5
var feed_rate: float = 0.055
var kill_rate: float = 0.062
var reaction_rate: float = 1.0
var time_scale: float = 1.0

var image: Image
var texture: ImageTexture
var frame_counter: int = 0

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _label: Label3D

var current_preset: int = 0
var presets: Array = [
	{"name": "Coral", "dA": 1.0, "dB": 0.5, "f": 0.055, "k": 0.062},
	{"name": "Mitosis", "dA": 1.0, "dB": 0.5, "f": 0.0367, "k": 0.0649},
	{"name": "Fingers", "dA": 1.0, "dB": 0.5, "f": 0.037, "k": 0.06},
	{"name": "Spots", "dA": 1.0, "dB": 0.5, "f": 0.025, "k": 0.05},
	{"name": "Waves", "dA": 1.0, "dB": 0.5, "f": 0.018, "k": 0.051},
	{"name": "Maze", "dA": 1.0, "dB": 0.5, "f": 0.029, "k": 0.057}
]

var _preset_timer: float = 0.0
var _preset_cycle_interval: float = 30.0

func _ready() -> void:
	_initialize_grids()
	image = Image.create_empty(width, height, false, Image.FORMAT_RGB8)

	# Create QuadMesh display panel
	_mesh_instance = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.6, 0.6)
	_mesh_instance.mesh = quad
	_mesh_instance.position = Vector3(0, 0.3, 0)

	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh_instance.material_override = _material
	add_child(_mesh_instance)

	_label = Label3D.new()
	_label.text = "Reaction-Diffusion — Coral"
	_label.font_size = 28
	_label.position = Vector3(0, -0.05, 0)
	_label.modulate = Color(1, 1, 1, 0.8)
	add_child(_label)

	_add_random_seeds()
	_update_texture()

func _process(delta: float) -> void:
	var steps := int(time_scale * 3.0 * delta)
	for i in range(maxi(1, steps)):
		_simulate_step(delta)

	frame_counter += 1
	if frame_counter % 3 == 0:
		_update_texture()

	# Auto-cycle presets
	_preset_timer += delta
	if _preset_timer >= _preset_cycle_interval:
		_preset_timer = 0.0
		_load_next_preset()

func _update_texture() -> void:
	if image == null or image.get_width() == 0:
		image = Image.create_empty(width, height, false, Image.FORMAT_RGB8)
		return

	for y in range(height):
		for x in range(width):
			var a := grid_a[y][x]
			var b := grid_b[y][x]
			var color := Color(
				clampf(a, 0.0, 1.0),
				clampf(a - b, 0.0, 1.0),
				clampf(a - b, 0.0, 1.0)
			)
			image.set_pixel(x, y, color)

	texture = ImageTexture.create_from_image(image)
	_material.albedo_texture = texture

func _initialize_grids() -> void:
	grid_a = []
	grid_b = []
	next_a = []
	next_b = []
	for y in range(height):
		var row_a := []
		var row_b := []
		var nr_a := []
		var nr_b := []
		for x in range(width):
			row_a.append(1.0)
			row_b.append(0.0)
			nr_a.append(0.0)
			nr_b.append(0.0)
		grid_a.append(row_a)
		grid_b.append(row_b)
		next_a.append(nr_a)
		next_b.append(nr_b)

func _add_random_seeds() -> void:
	for i in range(5):
		var cx := randi() % width
		var cy := randi() % height
		var sz := randi() % 10 + 5
		for dx in range(-sz, sz):
			for dy in range(-sz, sz):
				var px := (cx + dx) % width
				var py := (cy + dy) % height
				if dx * dx + dy * dy < sz * sz:
					grid_b[py][px] = 1.0
					grid_a[py][px] = 0.0

func _load_next_preset() -> void:
	current_preset = (current_preset + 1) % presets.size()
	var preset: Dictionary = presets[current_preset]
	diffusion_a = preset.dA
	diffusion_b = preset.dB
	feed_rate = preset.f
	kill_rate = preset.k
	_label.text = "Reaction-Diffusion — %s" % preset.name
	_add_random_seeds()

func _simulate_step(delta: float) -> void:
	for y in range(height):
		for x in range(width):
			var laplacian_a := _calculate_laplacian(grid_a, x, y)
			var laplacian_b := _calculate_laplacian(grid_b, x, y)
			var a := grid_a[y][x]
			var b := grid_b[y][x]
			var reaction := a * b * b * reaction_rate
			next_a[y][x] = clampf(a + (diffusion_a * laplacian_a - reaction + feed_rate * (1.0 - a)) * delta, 0.0, 1.0)
			next_b[y][x] = clampf(b + (diffusion_b * laplacian_b + reaction - (kill_rate + feed_rate) * b) * delta, 0.0, 1.0)

	var temp_a := grid_a
	var temp_b := grid_b
	grid_a = next_a
	grid_b = next_b
	next_a = temp_a
	next_b = temp_b

func _calculate_laplacian(grid: Array, x: int, y: int) -> float:
	var center: float = grid[y][x]
	var result := 0.0
	result += grid[(y - 1 + height) % height][x] - center
	result += grid[y][(x + 1) % width] - center
	result += grid[(y + 1) % height][x] - center
	result += grid[y][(x - 1 + width) % width] - center
	result += 0.05 * (grid[(y - 1 + height) % height][(x - 1 + width) % width] - center)
	result += 0.05 * (grid[(y - 1 + height) % height][(x + 1) % width] - center)
	result += 0.05 * (grid[(y + 1) % height][(x - 1 + width) % width] - center)
	result += 0.05 * (grid[(y + 1) % height][(x + 1) % width] - center)
	return result

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
