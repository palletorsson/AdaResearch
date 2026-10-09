extends Node2D

# @identity
# essence: dA/dt = D_a*nabla^2(A) - A*B^2 + f*(1-A); dB/dt = D_b*nabla^2(B) + A*B^2 - (k+f)*B
# desire: watch two chemicals chase each other into coral, mitosis, mazes — Turing's morphogenesis alive
# critical_parameter: feed_rate / kill_rate ratio — tiny changes cross phase boundaries between spots, stripes, and chaos
# triggers: preset auto-cycle switches Gray-Scott parameters every 30s; random seeds nucleate new pattern islands
# emerges: self-organizing spatial patterns from uniform initial conditions — structure from nothing but diffusion and reaction
# needs: VR parameter controls [missing], preset selection buttons [missing], touch-to-seed interaction [missing]
# relationships: unlocks edge_core understanding; depends on diffusion/laplacian concepts; contrasts ordered_grid (imposed order vs emergent order)
# truth: pattern does not require a planner — two diffusing chemicals and a nonlinear reaction are sufficient for morphogenesis

# Reaction-Diffusion (Gray-Scott Model) — 3D VR Version
# Simulation runs on a grid, rendered as texture on a QuadMesh panel.

var width: int = 128
var height: int = 128

# ── DNA ───────────────────────────────────────────────────────────────────────
# THE AXIS lives on the WRAPPER SCENE, 2d_in_3d_turing_pattern_reaction_diffusion.gd, which
# is what the registry points at and therefore the only script the declaration can be read
# from. This is its mechanism. Both spell the six words identically, and the wrapper is the
# one vocabulary.
@export_enum("blot", "lattice", "point", "rim", "seam", "dust") var inoculation: String = "blot"

## Seed for the inoculation draws. -1 keeps the legacy behaviour (Godot randomises the global
## stream at startup, so every placement nucleates somewhere new); any value >= 0 pins it.
## `lattice`, `point`, `rim` and `seam` draw nothing at all and are reproducible regardless.
@export var field_seed: int = -1
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
			var a: float = grid_a[y][x]
			var b: float = grid_b[y][x]
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

## WHERE THE DIFFERENCE COMES FROM. The field starts perfectly uniform — a = 1 everywhere,
## b = 0 everywhere — and the Gray-Scott rule is identical in every cell. A uniform field
## under a uniform rule stays uniform forever. Everything this artifact is famous for
## depends on this one function breaking that symmetry, and it has always broken it in
## exactly one way (five random blots) without ever calling that a choice.
##
## The match is APPENDED and `blot` falls through to the untouched legacy body, so the
## default consumes the same three randi() draws per blob, in the same order, as before.
func _add_random_seeds() -> void:
	if field_seed >= 0:
		seed(field_seed)
	match inoculation:
		"lattice":
			_inoculate_lattice()
		"point":
			_inoculate_point()
		"rim":
			_inoculate_rim()
		"seam":
			_inoculate_seam()
		"dust":
			_inoculate_dust()
		_:
			_inoculate_blot()

## One cell of the field handed over to B. Every inoculation below writes through here, so
## they cannot drift in what "seeded" means.
func _sow(px: int, py: int) -> void:
	grid_b[py][px] = 1.0
	grid_a[py][px] = 0.0

## blot — the legacy lineage, byte for byte: five discs, random centres, random radii.
func _inoculate_blot() -> void:
	for i in range(5):
		var cx := randi() % width
		var cy := randi() % height
		var sz := randi() % 10 + 5
		for dx in range(-sz, sz):
			for dy in range(-sz, sz):
				var px := (cx + dx) % width
				var py := (cy + dy) % height
				if dx * dx + dy * dy < sz * sz:
					_sow(px, py)

## lattice — sixteen identical discs on a regular 4 x 4 grid. Order imposed on the initial
## condition; the pattern still diverges, which is the point.
func _inoculate_lattice() -> void:
	var sz: int = 6
	for i in range(4):
		for j in range(4):
			var cx: int = int(float(width) * (0.125 + 0.25 * float(i)))
			var cy: int = int(float(height) * (0.125 + 0.25 * float(j)))
			_disc(cx, cy, sz)

## point — one disc at the centre. Every difference in the finished field descends from a
## single origin.
func _inoculate_point() -> void:
	_disc(int(width / 2), int(height / 2), int(mini(width, height) / 6))

## rim — a band along the left edge. Difference arrives from the boundary and invades.
func _inoculate_rim() -> void:
	var band: int = maxi(1, int(width / 10))
	for y in range(height):
		for x in range(band):
			_sow(x, y)

## seam — a straight diagonal crack across the field. One line, no centre.
func _inoculate_seam() -> void:
	var halfw: int = maxi(1, int(mini(width, height) / 26))
	for y in range(height):
		for x in range(width):
			if absi(x - y) <= halfw:
				_sow(x, y)

## dust — every cell perturbed on its own account, 2% of the time. Difference is everywhere
## and has no origin at all: the limit case, and the hardest one for "a pattern needs a
## seed" to survive.
func _inoculate_dust() -> void:
	for y in range(height):
		for x in range(width):
			if randf() < 0.02:
				_sow(x, y)

## A filled disc, wrapped at the edges exactly as the legacy blot loop wraps.
func _disc(cx: int, cy: int, sz: int) -> void:
	for dx in range(-sz, sz):
		for dy in range(-sz, sz):
			if dx * dx + dy * dy < sz * sz:
				_sow((cx + dx + width) % width, (cy + dy + height) % height)

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
			var a: float = grid_a[y][x]
			var b: float = grid_b[y][x]
			var reaction: float = a * b * b * reaction_rate
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
