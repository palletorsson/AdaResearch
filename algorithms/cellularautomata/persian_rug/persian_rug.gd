@tool
extends Node3D

@export_category("Rug Settings")
@export var width: int = 256
@export var height: int = 384
@export var border_size: int = 32
@export var iterations: int = 100
@export var auto_step: bool = true
@export var step_interval: float = 0.05
@export var random_seed: bool = false

@export_category("Performance")
@export var performance_mode: bool = false
@export var play_duration: float = 10.0
@export var pause_duration: float = 10.0

@export_category("Rules")
# Format: [Born_list, Survive_list, States]
@export var rule_border_born: Array[int] = [2]
@export var rule_border_survive: Array[int] = [3, 4, 5]
@export var rule_border_states: int = 4

@export var rule_inner_born: Array[int] = [3]
@export var rule_inner_survive: Array[int] = [1, 2, 3, 4, 5]
@export var rule_inner_states: int = 5

@export_category("Colors (Pink Persian)")
@export var color_background: Color = Color("5e1026")
@export var color_border_active: Color = Color("d6336c")
@export var color_inner_active: Color = Color("ffc966")
@export var color_decay: Gradient
@export var rows_per_frame: int = 40

# Optimization: Use PackedByteArray for 1D grid and pixel buffer
var grid: PackedByteArray
var next_grid: PackedByteArray
var pixel_buffer: PackedByteArray

var texture: ImageTexture
var image: Image
var timer: float = 0.0
var current_step: int = 0
var current_row: int = 0

var cycle_timer = 0.0
var is_playing = true

@onready var mesh_instance: MeshInstance3D = $RugMesh

func _ready():
	if not color_decay:
		_setup_default_gradient()
	
	_initialize_grid()
	_setup_texture()
	# Initial full update
	_update_texture_slice(height)

func _process(delta):
	# Ensure variables are initialized for @tool hot-reloading
	if cycle_timer == null: cycle_timer = 0.0
	if is_playing == null: is_playing = true
	if rows_per_frame == null: rows_per_frame = 40
	
	# Hot-reload safety: Ensure grid is correct type
	if not grid is PackedByteArray or grid.size() != width * height:
		_initialize_grid()
		_setup_texture()
		current_row = 0

	if performance_mode:
		cycle_timer += delta
		if is_playing:
			if cycle_timer >= play_duration:
				is_playing = false
				cycle_timer = 0.0
		else:
			if cycle_timer >= pause_duration:
				is_playing = true
				cycle_timer = 0.0
				if random_seed:
					_initialize_grid() 
	
	# Update a slice of the texture every frame
	if current_row < height:
		var rows: int = 40
		if rows_per_frame != null:
			rows = int(rows_per_frame)
		if rows <= 0: rows = 40
		_update_texture_slice(rows)
	
	# Only step if we are done updating the view
	if auto_step and is_playing and current_row >= height:
		timer += delta
		if timer >= step_interval:
			timer = 0.0
			step()
			current_row = 0

func _setup_default_gradient():
	color_decay = Gradient.new()
	color_decay.remove_point(0)
	color_decay.remove_point(0)
	color_decay.add_point(0.0, Color("2a1a4a"))
	color_decay.add_point(0.5, Color("9c1c5a"))
	color_decay.add_point(1.0, Color("f8d7da"))

func _initialize_grid():
	var size = width * height
	# Force type reset in case of hot-reload artifact
	grid = PackedByteArray()
	next_grid = PackedByteArray()
	grid.resize(size)
	next_grid.resize(size)
	grid.fill(0)
	next_grid.fill(0)
	
	if random_seed:
		randomize()
	else:
		seed(12345)
		
	for x in range(width / 2):
		for y in range(height / 2):
			if randf() < 0.15:
				var is_border = _is_border(x, y)
				var max_state = rule_border_states if is_border else rule_inner_states
				var idx = y * width + x
				grid[idx] = max_state - 1
	
	_enforce_symmetry()

func _is_border(x, y) -> bool:
	return x < border_size or x >= width - border_size or y < border_size or y >= height - border_size

func _enforce_symmetry():
	# Mirror Top-Left to Top-Right, Bottom-Left, Bottom-Right
	for y in range(height / 2):
		var row_offset = y * width
		var mirror_row_offset = (height - 1 - y) * width
		
		for x in range(width / 2):
			var val = grid[row_offset + x]
			
			# Top-Right
			grid[row_offset + (width - 1 - x)] = val
			# Bottom-Left
			grid[mirror_row_offset + x] = val
			# Bottom-Right
			grid[mirror_row_offset + (width - 1 - x)] = val

func step():
	# Pre-calculate constants to avoid lookups in loop
	var w = width
	var h = height
	
	# We can't easily optimize the border check out of the loop without splitting loops,
	# but 1D array access is fast enough.
	
	for y in range(h):
		var y_offset = y * w
		var ym1_offset = ((y - 1 + h) % h) * w
		var yp1_offset = ((y + 1) % h) * w
		
		for x in range(w):
			var idx = y_offset + x
			var is_border = _is_border(x, y)
			
			# Select rules
			var born: Array[int]
			var survive: Array[int]
			var states: int
			
			if is_border:
				born = rule_border_born
				survive = rule_border_survive
				states = rule_border_states
			else:
				born = rule_inner_born
				survive = rule_inner_survive
				states = rule_inner_states
			
			var current = grid[idx]
			
			if current == states - 1: # Active
				# Count neighbors inline
				var xm1 = (x - 1 + w) % w
				var xp1 = (x + 1) % w
				var active_state = states - 1
				var count = 0
				
				if grid[ym1_offset + xm1] == active_state: count += 1
				if grid[ym1_offset + x] == active_state: count += 1
				if grid[ym1_offset + xp1] == active_state: count += 1
				if grid[y_offset + xm1] == active_state: count += 1
				if grid[y_offset + xp1] == active_state: count += 1
				if grid[yp1_offset + xm1] == active_state: count += 1
				if grid[yp1_offset + x] == active_state: count += 1
				if grid[yp1_offset + xp1] == active_state: count += 1
				
				if count in survive:
					next_grid[idx] = active_state
				else:
					next_grid[idx] = current - 1
					
			elif current > 0: # Decaying
				next_grid[idx] = current - 1
				
			else: # Dead
				# Count neighbors inline
				var xm1 = (x - 1 + w) % w
				var xp1 = (x + 1) % w
				var active_state = states - 1
				var count = 0
				
				if grid[ym1_offset + xm1] == active_state: count += 1
				if grid[ym1_offset + x] == active_state: count += 1
				if grid[ym1_offset + xp1] == active_state: count += 1
				if grid[y_offset + xm1] == active_state: count += 1
				if grid[y_offset + xp1] == active_state: count += 1
				if grid[yp1_offset + xm1] == active_state: count += 1
				if grid[yp1_offset + x] == active_state: count += 1
				if grid[yp1_offset + xp1] == active_state: count += 1
				
				if count in born:
					next_grid[idx] = active_state
				else:
					next_grid[idx] = 0
	
	# Swap buffers
	var temp = grid
	grid = next_grid
	next_grid = temp
	
	_enforce_symmetry()
	current_step += 1

func _setup_texture():
	image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)
	
	# Initialize pixel buffer
	pixel_buffer = PackedByteArray()
	pixel_buffer.resize(width * height * 4)
	pixel_buffer.fill(0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	if mesh_instance:
		mesh_instance.material_override = mat

func _update_texture_slice(rows: int):
	var end_row = min(current_row + rows, height)
	var w = width
	
	for y in range(current_row, end_row):
		var row_offset = y * w
		var pixel_idx = row_offset * 4
		
		for x in range(w):
			var state = grid[row_offset + x]
			var is_border = _is_border(x, y)
			var max_states = rule_border_states if is_border else rule_inner_states
			var col = color_background
			
			if state == max_states - 1:
				col = color_border_active if is_border else color_inner_active
			elif state > 0:
				var t = float(state) / float(max_states - 1)
				col = color_decay.sample(t)
			
			# Direct byte access is much faster than set_pixel
			pixel_buffer[pixel_idx] = int(col.r * 255)
			pixel_buffer[pixel_idx + 1] = int(col.g * 255)
			pixel_buffer[pixel_idx + 2] = int(col.b * 255)
			pixel_buffer[pixel_idx + 3] = 255
			pixel_idx += 4
	
	# Update the image from the buffer
	# We update the whole image data because set_data is fast
	image.set_data(width, height, false, Image.FORMAT_RGBA8, pixel_buffer)
	texture.update(image)
	
	current_row = end_row
