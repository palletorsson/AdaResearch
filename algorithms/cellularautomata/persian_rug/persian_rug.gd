@tool
extends Node3D

@export_category("Rug Settings")
@export var width: int = 256
@export var height: int = 384
@export var border_size: int = 32
@export var iterations: int = 100
@export var auto_step: bool = true
@export var step_interval: float = 0.05

@export_category("Rules")
# Format: [Born_list, Survive_list, States]
# Example: Star Wars [2, [3,4,5], 4]
@export var rule_border_born: Array[int] = [2]
@export var rule_border_survive: Array[int] = [3, 4, 5]
@export var rule_border_states: int = 4

@export var rule_inner_born: Array[int] = [3]
@export var rule_inner_survive: Array[int] = [1, 2, 3, 4, 5] # Maze-like
@export var rule_inner_states: int = 5

@export_category("Colors (Pink Persian)")
@export var color_background: Color = Color("5e1026") # Dark Burgundy
@export var color_border_active: Color = Color("d6336c") # Vivid Pink
@export var color_inner_active: Color = Color("ffc966") # Gold
@export var color_decay: Gradient

var grid: Array = []
var next_grid: Array = []
var texture: ImageTexture
var image: Image
var timer: float = 0.0
var current_step: int = 0

@onready var mesh_instance: MeshInstance3D = $RugMesh

func _ready():
	if not color_decay:
		_setup_default_gradient()
	
	_initialize_grid()
	_setup_texture()
	_update_texture()

func _process(delta):
	if auto_step:
		timer += delta
		if timer >= step_interval:
			timer = 0.0
			step()

func _setup_default_gradient():
	color_decay = Gradient.new()
	color_decay.remove_point(0)
	color_decay.remove_point(0)
	color_decay.add_point(0.0, Color("2a1a4a")) # Deep Blue
	color_decay.add_point(0.5, Color("9c1c5a")) # Raspberry
	color_decay.add_point(1.0, Color("f8d7da")) # Pale Pink

func _initialize_grid():
	grid.resize(width)
	next_grid.resize(width)
	for x in range(width):
		grid[x] = []
		next_grid[x] = []
		grid[x].resize(height)
		next_grid[x].resize(height)
		for y in range(height):
			# Random start, but symmetric
			grid[x][y] = 0
	
	# Seed random noise in top-left quadrant
	seed(12345) # Consistent seed for rug pattern
	for x in range(width / 2):
		for y in range(height / 2):
			if randf() < 0.15:
				# Determine if border or inner to set max state
				var is_border = _is_border(x, y)
				var max_state = rule_border_states if is_border else rule_inner_states
				grid[x][y] = max_state - 1
	
	_enforce_symmetry()

func _is_border(x, y) -> bool:
	return x < border_size or x >= width - border_size or y < border_size or y >= height - border_size

func _enforce_symmetry():
	# Mirror Top-Left to Top-Right
	for x in range(width / 2):
		for y in range(height / 2):
			var val = grid[x][y]
			grid[width - 1 - x][y] = val
			grid[x][height - 1 - y] = val
			grid[width - 1 - x][height - 1 - y] = val

func step():
	for x in range(width):
		for y in range(height):
			var is_border = _is_border(x, y)
			var born = rule_border_born if is_border else rule_inner_born
			var survive = rule_border_survive if is_border else rule_inner_survive
			var states = rule_border_states if is_border else rule_inner_states
			
			var current = grid[x][y]
			
			if current == states - 1: # Active state
				var neighbors = _count_active_neighbors(x, y, states - 1)
				if neighbors in survive:
					next_grid[x][y] = states - 1 # Stay active
				else:
					next_grid[x][y] = current - 1 # Decay
			elif current > 0: # Decaying state
				next_grid[x][y] = current - 1
			else: # Dead state
				var neighbors = _count_active_neighbors(x, y, states - 1)
				if neighbors in born:
					next_grid[x][y] = states - 1 # Born
				else:
					next_grid[x][y] = 0
	
	# Swap grids
	var temp = grid
	grid = next_grid
	next_grid = temp
	
	_enforce_symmetry() # Keep it perfectly symmetric
	_update_texture()
	current_step += 1

func _count_active_neighbors(x, y, active_state) -> int:
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and j == 0: continue
			
			var nx = (x + i + width) % width
			var ny = (y + j + height) % height
			
			if grid[nx][ny] == active_state:
				count += 1
	return count

func _setup_texture():
	image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	if mesh_instance:
		mesh_instance.material_override = mat

func _update_texture():
	for x in range(width):
		for y in range(height):
			var state = grid[x][y]
			var is_border = _is_border(x, y)
			var max_states = rule_border_states if is_border else rule_inner_states
			var col = color_background
			
			if state == max_states - 1:
				col = color_border_active if is_border else color_inner_active
			elif state > 0:
				var t = float(state) / float(max_states - 1)
				col = color_decay.sample(t)
			
			image.set_pixel(x, y, col)
	
	texture.update(image)
