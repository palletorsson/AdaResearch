# turing_pattern_generator.gd
# Gray-Scott reaction-diffusion simulation
# Turing's leopard spots problem - morphogenesis from mathematics

extends Node3D

class_name TuringPatternGenerator

## Display size
@export var display_size: float = 1.0

## Simulation resolution (lower = faster)
@export var resolution: int = 64

## Pattern presets (feed, kill rates)
@export_enum("Spots", "Stripes", "Maze", "Mitosis", "Coral", "Waves") var pattern_type: int = 0:
	set(value):
		pattern_type = value
		_apply_preset()

## Simulation speed
@export var steps_per_frame: int = 4
@export var auto_run: bool = true

## Color gradient
@export var color_gradient: Gradient

## Diffusion rates
@export var Du: float = 0.16
@export var Dv: float = 0.08

## Feed and kill rates (define pattern type)
@export var feed: float = 0.055
@export var kill: float = 0.062

# Pattern presets: [feed, kill, description]
const PRESETS = {
	0: [0.055, 0.062, "Spots"],      # Spots (like leopard)
	1: [0.042, 0.059, "Stripes"],    # Stripes (like zebra)
	2: [0.029, 0.057, "Maze"],       # Labyrinthine
	3: [0.028, 0.062, "Mitosis"],    # Cell division
	4: [0.058, 0.065, "Coral"],      # Coral-like growth
	5: [0.014, 0.047, "Waves"],      # Pulsing waves
}

# Simulation grids
var _U: Array[Array] = []  # Chemical U concentration
var _V: Array[Array] = []  # Chemical V concentration
var _U_next: Array[Array] = []
var _V_next: Array[Array] = []

# Display
var _display_mesh: MeshInstance3D
var _image: Image
var _texture: ImageTexture
var _material: StandardMaterial3D
var _info_label: Label3D

func _ready():
	_init_default_gradient()
	_create_display()
	_create_base()
	_create_labels()
	_init_simulation()
	_apply_preset()

func _init_default_gradient():
	if color_gradient == null:
		color_gradient = Gradient.new()
		# Leopard-like gradient: cream → tan → brown → black
		color_gradient.colors = PackedColorArray([
			Color(0.95, 0.9, 0.8),   # Cream
			Color(0.85, 0.7, 0.4),   # Tan
			Color(0.4, 0.25, 0.1),   # Brown
			Color(0.05, 0.02, 0.0)   # Near black
		])
		color_gradient.offsets = PackedFloat32Array([0.0, 0.4, 0.7, 1.0])

func _create_display():
	_display_mesh = MeshInstance3D.new()
	_display_mesh.name = "PatternDisplay"
	
	var quad = QuadMesh.new()
	quad.size = Vector2(display_size, display_size)
	_display_mesh.mesh = quad
	
	# Horizontal orientation
	_display_mesh.rotation_degrees = Vector3(-90, 0, 0)
	_display_mesh.position = Vector3(0, 0.02, 0)
	
	# Create texture
	_image = Image.create(resolution, resolution, false, Image.FORMAT_RGB8)
	_texture = ImageTexture.create_from_image(_image)
	
	_material = StandardMaterial3D.new()
	_material.albedo_texture = _texture
	_material.emission_enabled = true
	_material.emission_texture = _texture
	_material.emission_energy_multiplier = 0.2
	
	_display_mesh.material_override = _material
	add_child(_display_mesh)

func _create_base():
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var box = BoxMesh.new()
	box.size = Vector3(display_size + 0.04, 0.03, display_size + 0.04)
	base.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.15)
	mat.metallic = 0.6
	mat.roughness = 0.4
	base.material_override = mat
	
	base.position = Vector3(0, -0.015, 0)
	add_child(base)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 28
	_info_label.position = Vector3(0, 0.05, -display_size/2 - 0.08)
	add_child(_info_label)
	
	var hint = Label3D.new()
	hint.name = "ControlsHint"
	hint.pixel_size = 0.001
	hint.font_size = 20
	hint.text = "1-6 Presets | R Reset | Space Pause"
	hint.position = Vector3(0, 0.03, display_size/2 + 0.06)
	hint.modulate = Color(0.6, 0.6, 0.6)
	add_child(hint)

func _init_simulation():
	# Initialize grids
	_U.clear()
	_V.clear()
	_U_next.clear()
	_V_next.clear()
	
	for y in range(resolution):
		var row_u: Array[float] = []
		var row_v: Array[float] = []
		var row_u2: Array[float] = []
		var row_v2: Array[float] = []
		row_u.resize(resolution)
		row_v.resize(resolution)
		row_u2.resize(resolution)
		row_v2.resize(resolution)
		
		for x in range(resolution):
			row_u[x] = 1.0  # U starts at 1
			row_v[x] = 0.0  # V starts at 0
			row_u2[x] = 0.0
			row_v2[x] = 0.0
		
		_U.append(row_u)
		_V.append(row_v)
		_U_next.append(row_u2)
		_V_next.append(row_v2)
	
	# Seed with random perturbations
	_seed_random()

func _seed_random():
	var center = resolution / 2
	var seed_size = resolution / 8
	
	# Add several random seed points
	for _i in range(5):
		var cx = randi_range(seed_size, resolution - seed_size)
		var cy = randi_range(seed_size, resolution - seed_size)
		var size = randi_range(2, seed_size)
		
		for dy in range(-size, size + 1):
			for dx in range(-size, size + 1):
				var x = cx + dx
				var y = cy + dy
				if x >= 0 and x < resolution and y >= 0 and y < resolution:
					if dx*dx + dy*dy <= size*size:
						_U[y][x] = 0.5
						_V[y][x] = 0.25

func _apply_preset():
	var preset = PRESETS.get(pattern_type, PRESETS[0])
	feed = preset[0]
	kill = preset[1]
	_update_info_label()

func _update_info_label():
	var preset = PRESETS.get(pattern_type, PRESETS[0])
	_info_label.text = "TURING: %s\nf=%.3f k=%.3f" % [preset[2], feed, kill]

func _process(_delta):
	if auto_run:
		for _i in range(steps_per_frame):
			_simulation_step()
	_update_texture()

func _simulation_step():
	# Gray-Scott reaction-diffusion
	for y in range(resolution):
		for x in range(resolution):
			var u = _U[y][x]
			var v = _V[y][x]
			
			# Laplacian (9-point stencil)
			var lap_u = _laplacian(_U, x, y)
			var lap_v = _laplacian(_V, x, y)
			
			# Reaction-diffusion equations
			var uvv = u * v * v
			var du = Du * lap_u - uvv + feed * (1.0 - u)
			var dv = Dv * lap_v + uvv - (kill + feed) * v
			
			_U_next[y][x] = clampf(u + du, 0.0, 1.0)
			_V_next[y][x] = clampf(v + dv, 0.0, 1.0)
	
	# Swap buffers
	var temp = _U
	_U = _U_next
	_U_next = temp
	
	temp = _V
	_V = _V_next
	_V_next = temp

func _laplacian(grid: Array[Array], x: int, y: int) -> float:
	# 9-point Laplacian stencil
	var sum = 0.0
	var center = grid[y][x]
	
	# Neighbors with wrap-around
	var xm = (x - 1 + resolution) % resolution
	var xp = (x + 1) % resolution
	var ym = (y - 1 + resolution) % resolution
	var yp = (y + 1) % resolution
	
	# Cardinal neighbors (weight 0.2)
	sum += grid[y][xm] * 0.2
	sum += grid[y][xp] * 0.2
	sum += grid[ym][x] * 0.2
	sum += grid[yp][x] * 0.2
	
	# Diagonal neighbors (weight 0.05)
	sum += grid[ym][xm] * 0.05
	sum += grid[ym][xp] * 0.05
	sum += grid[yp][xm] * 0.05
	sum += grid[yp][xp] * 0.05
	
	# Center (weight -1.0)
	sum -= center
	
	return sum

func _update_texture():
	for y in range(resolution):
		for x in range(resolution):
			var v = _V[y][x]
			var color = color_gradient.sample(v)
			_image.set_pixel(x, y, color)
	
	_texture.update(_image)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				pattern_type = 0
			KEY_2:
				pattern_type = 1
			KEY_3:
				pattern_type = 2
			KEY_4:
				pattern_type = 3
			KEY_5:
				pattern_type = 4
			KEY_6:
				pattern_type = 5
			KEY_R:
				_init_simulation()
			KEY_SPACE:
				auto_run = not auto_run

## Set color palette
func set_gradient(gradient: Gradient):
	color_gradient = gradient

## Reset with new pattern
func reset():
	_init_simulation()
