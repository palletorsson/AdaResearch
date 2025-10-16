extends Node3D

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

var grid_width = 10
var grid_height = 16
var cell_size = 1.0

var current_gen = []
var rules = []

var rule_change_timer = 0.0
var rule_change_interval = 0.25
var turn_counter = 0
var current_row_to_change = 0

func _ready():
	# Initialize the grid
	current_gen.resize(grid_width)
	for i in range(grid_width):
		current_gen[i] = []
		current_gen[i].resize(grid_height)
		for j in range(grid_height):
			current_gen[i][j] = 0
	
	# Initialize rules
	initialize_rules()
	
	# Create cells (laid out in Z forward, X across)
	for i in range(grid_width):
		for j in range(grid_height):
			var cell = CUBE_SCENE.instantiate()
			cell.name = "cell_" + str(i) + "_" + str(j)
			cell.position = Vector3(i * cell_size, 0, j * cell_size)  # Z forward
			cell.visible = false
			add_child(cell)
	
	# Set initial state (random)
	for i in range(grid_width):
		current_gen[i][0] = randi() % 2

func _process(delta):
	rule_change_timer += delta
	if rule_change_timer >= rule_change_interval:
		rule_change_timer = 0.0
		update_bridge()
	animate_cells(delta)

func update_bridge():
	if current_row_to_change < grid_height:
		for i in range(grid_width):
			var neighbors = count_neighbors(i, current_row_to_change)
			var rule = rules[current_row_to_change]
			if (rule >> neighbors) & 1:
				current_gen[i][current_row_to_change] = 1
			else:
				current_gen[i][current_row_to_change] = 0
		current_row_to_change += 1
	else:
		current_row_to_change = 0
		turn_counter += 1
		if turn_counter >= 10:
			turn_counter = 0
			initialize_rules()

func animate_cells(delta):
	for i in range(grid_width):
		for j in range(grid_height):
			var cell = get_node("cell_" + str(i) + "_" + str(j))
			var static_body = cell.get_node("CubeBaseStaticBody3D")
			
			var collision_shape = static_body.get_node("CollisionShape3D")
			
			if current_gen[i][j] == 1:
				cell.visible = true
				static_body.set_collision_layer_value(1, true)  # Enable collision
				static_body.set_collision_mask_value(1, true)
				collision_shape.disabled = false  # Enable collision shape
			else:
				cell.visible = false
				static_body.set_collision_layer_value(1, false)  # Disable collision
				static_body.set_collision_mask_value(1, false)
				collision_shape.disabled = true  # Disable collision shape

func count_neighbors(x, y):
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and j == 0:
				continue
			var nx = (x + i + grid_width) % grid_width
			var ny = (y + j + grid_height) % grid_height
			if ny < 0:
				ny = grid_height - 1
			if current_gen[nx][ny] == 1:
				count += 1
	return count

func initialize_rules():
	"""Initialize or re-randomize the CA rules for each row"""
	rules.clear()
	rules.resize(grid_height)
	for i in range(grid_height):
		# Generate random rule (0-255)
		rules[i] = randi() % 256
	print("CrosswayCA: New rules initialized")
