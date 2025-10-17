# game.gd - Main game controller
# 
# PLAYER INTEGRATION NOTES:
# Your player needs to implement:
#   - start_new_game(position: Vector3) - Called when game starts
#   - global_position property - To get player position for scent tracking
# Or modify the update_game() function to work with your player's API
#
extends Node3D

@export var maze_size := Vector2i(20, 20)
@export var seed_value := 123
@export_range(0.0, 1.0) var pick_last_probability := 0.5
@export_range(0.0, 1.0) var open_dead_end_probability := 0.5
@export_range(0.0, 1.0) var open_arbitrary_probability := 0.25

var maze: Maze
var scent: Scent
var cell_objects := []
var agents := []
var is_playing := false

# MODIFY THESE TO POINT TO YOUR PLAYER AND UI
@export var player: Node3D  # Set this in the inspector to your player node
@export var display_label: Label  # Optional: for win/lose messages

@onready var agents_container = $Agents  # Or create dynamically

var agent_scene = preload("res://agent.tscn")

func _ready():
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	create_agents()
	
	if display_label:
		display_label.text = "PRESS SPACE TO START"

func create_agents():
	# Create agents container if it doesn't exist
	if not has_node("Agents"):
		agents_container = Node3D.new()
		agents_container.name = "Agents"
		add_child(agents_container)
	
	var red_agent = agent_scene.instantiate()
	if not red_agent:
		return
	red_agent.agent_color = Color.RED
	red_agent.speed = 2.5
	red_agent.scale = Vector3.ONE * 0.75
	red_agent.trigger_message = "RED CAUGHT YOU!"
	red_agent.is_goal = false
	agents_container.add_child(red_agent)
	agents.append(red_agent)
	
	var blue_agent = agent_scene.instantiate()
	blue_agent.agent_color = Color.BLUE
	blue_agent.speed = 1.5
	blue_agent.scale = Vector3.ONE * 0.75
	blue_agent.trigger_message = "BLUE CAUGHT YOU!"
	blue_agent.is_goal = false
	agents_container.add_child(blue_agent)
	agents.append(blue_agent)
	
	var yellow_agent = agent_scene.instantiate()
	yellow_agent.agent_color = Color.YELLOW
	yellow_agent.speed = 0.5
	yellow_agent.scale = Vector3.ONE * 0.5
	yellow_agent.trigger_message = "YOU CAUGHT YELLOW!"
	yellow_agent.is_goal = true
	agents_container.add_child(yellow_agent)
	agents.append(yellow_agent)

func start_new_game():
	is_playing = true
	
	if display_label:
		display_label.hide()
	
	if seed_value != 0:
		seed(seed_value)
	else:
		randomize()
	
	if maze:
		clear_maze()
	
	maze = Maze.new(maze_size)
	maze.generate(pick_last_probability, open_dead_end_probability, open_arbitrary_probability)
	maze.find_diagonal_passages()
	
	visualize_maze()
	
	scent = Scent.new(maze)
	
	# Place player in bottom-left quadrant
	var player_coords = Vector2i(
		randi() % (maze_size.x / 4),
		randi() % (maze_size.y / 4)
	)
	var player_pos = maze.coordinates_to_world_position(player_coords)
	
	# ADAPT THIS TO YOUR PLAYER'S API
	if player and player.has_method("start_new_game"):
		player.start_new_game(player_pos)
	elif player:
		player.position = player_pos
	
	# Place agents outside bottom-left quadrant
	var half_size = maze_size / 2
	for agent in agents:
		var coords = Vector2i(randi() % maze_size.x, randi() % maze_size.y)
		if coords.x < half_size.x and coords.y < half_size.y:
			if randf() < 0.5:
				coords.x += half_size.x
			else:
				coords.y += half_size.y
		agent.start_new_game(maze, coords)

func visualize_maze():
	cell_objects.clear()
	
	for i in range(maze.cells.size()):
		var cell_data = maze.cells[i]
		var cell_node = create_maze_cell(cell_data, i)
		add_child(cell_node)
		cell_objects.append(cell_node)

func create_maze_cell(flags: int, index: int) -> Node3D:
	var cell = Node3D.new()
	var pos = maze.index_to_world_position(index)
	cell.position = pos
	
	var straight = flags & Maze.PASSAGES_STRAIGHT
	var diagonal = flags & Maze.PASSAGES_DIAGONAL
	
	var rotation_y = 0.0
	match straight:
		Maze.PASSAGE_N:
			create_dead_end(cell)
		Maze.PASSAGE_E:
			create_dead_end(cell)
			rotation_y = 90
		Maze.PASSAGE_S:
			create_dead_end(cell)
			rotation_y = 180
		Maze.PASSAGE_W:
			create_dead_end(cell)
			rotation_y = 270
		Maze.PASSAGE_N | Maze.PASSAGE_S:
			create_straight(cell)
		Maze.PASSAGE_E | Maze.PASSAGE_W:
			create_straight(cell)
			rotation_y = 90
		Maze.PASSAGE_N | Maze.PASSAGE_E:
			create_corner(cell, diagonal)
		Maze.PASSAGE_E | Maze.PASSAGE_S:
			create_corner(cell, diagonal)
			rotation_y = 90
		Maze.PASSAGE_S | Maze.PASSAGE_W:
			create_corner(cell, diagonal)
			rotation_y = 180
		Maze.PASSAGE_W | Maze.PASSAGE_N:
			create_corner(cell, diagonal)
			rotation_y = 270
		_:
			if straight == (Maze.PASSAGES_STRAIGHT & ~Maze.PASSAGE_W):
				create_t_junction(cell, diagonal)
			elif straight == (Maze.PASSAGES_STRAIGHT & ~Maze.PASSAGE_N):
				create_t_junction(cell, diagonal)
				rotation_y = 90
			elif straight == (Maze.PASSAGES_STRAIGHT & ~Maze.PASSAGE_E):
				create_t_junction(cell, diagonal)
				rotation_y = 180
			elif straight == (Maze.PASSAGES_STRAIGHT & ~Maze.PASSAGE_S):
				create_t_junction(cell, diagonal)
				rotation_y = 270
			else:
				create_x_junction(cell, diagonal)
	
	cell.rotation_degrees.y = rotation_y
	return cell

func create_dead_end(parent: Node3D):
	create_quad(parent, Vector3(-1, 1, 1), Vector2(2, 2), Vector3.RIGHT, Vector3.DOWN)
	create_quad(parent, Vector3(1, 1, 1), Vector2(2, 2), Vector3.BACK, Vector3.DOWN)
	create_quad(parent, Vector3(-1, 1, -1), Vector2(2, 2), Vector3.RIGHT, Vector3.DOWN)
	create_quad(parent, Vector3(-1, 0, -1), Vector2(2, 2), Vector3.RIGHT, Vector3.FORWARD)
	create_quad(parent, Vector3(-1, 2, 1), Vector2(2, 2), Vector3.RIGHT, Vector3.BACK)

func create_straight(parent: Node3D):
	create_quad(parent, Vector3(-1, 1, 1), Vector2(2, 2), Vector3.BACK, Vector3.DOWN)
	create_quad(parent, Vector3(1, 1, -1), Vector2(2, 2), Vector3.FORWARD, Vector3.DOWN)
	create_quad(parent, Vector3(-1, 0, -1), Vector2(2, 2), Vector3.RIGHT, Vector3.FORWARD)
	create_quad(parent, Vector3(-1, 2, 1), Vector2(2, 2), Vector3.RIGHT, Vector3.BACK)

func create_corner(parent: Node3D, diagonal: int):
	var has_diagonal = (diagonal & Maze.PASSAGES_DIAGONAL) != 0
	
	create_quad(parent, Vector3(-1, 1, -1), Vector2(2, 2), Vector3.RIGHT, Vector3.DOWN)
	create_quad(parent, Vector3(-1, 1, 1), Vector2(2, 2), Vector3.BACK, Vector3.DOWN)
	
	if not has_diagonal:
		create_pillar(parent, Vector3(0.75, 1, 0.75))
	
	create_quad(parent, Vector3(-1, 0, -1), Vector2(2, 2), Vector3.RIGHT, Vector3.FORWARD)
	create_quad(parent, Vector3(-1, 2, 1), Vector2(2, 2), Vector3.RIGHT, Vector3.BACK)

func create_t_junction(parent: Node3D, diagonal: int):
	create_quad(parent, Vector3(-1, 1, 1), Vector2(2, 2), Vector3.BACK, Vector3.DOWN)
	create_quad(parent, Vector3(-1, 0, -1), Vector2(2, 2), Vector3.RIGHT, Vector3.FORWARD)
	create_quad(parent, Vector3(-1, 2, 1), Vector2(2, 2), Vector3.RIGHT, Vector3.BACK)
	
	if not (diagonal & Maze.PASSAGE_NE):
		create_pillar(parent, Vector3(0.75, 1, -0.75))
	if not (diagonal & Maze.PASSAGE_SE):
		create_pillar(parent, Vector3(0.75, 1, 0.75))

func create_x_junction(parent: Node3D, diagonal: int):
	create_quad(parent, Vector3(-1, 0, -1), Vector2(2, 2), Vector3.RIGHT, Vector3.FORWARD)
	create_quad(parent, Vector3(-1, 2, 1), Vector2(2, 2), Vector3.RIGHT, Vector3.BACK)
	
	if not (diagonal & Maze.PASSAGE_NE):
		create_pillar(parent, Vector3(0.75, 1, -0.75))
	if not (diagonal & Maze.PASSAGE_SE):
		create_pillar(parent, Vector3(0.75, 1, 0.75))
	if not (diagonal & Maze.PASSAGE_SW):
		create_pillar(parent, Vector3(-0.75, 1, 0.75))
	if not (diagonal & Maze.PASSAGE_NW):
		create_pillar(parent, Vector3(-0.75, 1, -0.75))

func create_quad(parent: Node3D, pos: Vector3, size: Vector2, right: Vector3, down: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = size
	mesh_instance.mesh = quad_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.8)
	material.roughness = 1.0
	material.metallic = 0.0
	mesh_instance.material_override = material
	
	mesh_instance.position = pos
	var basis = Basis()
	basis.x = right.normalized()
	basis.y = -down.normalized()
	basis.z = right.cross(-down).normalized()
	mesh_instance.basis = basis
	
	parent.add_child(mesh_instance)
	
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(size.x, size.y, 0.1)
	collision.shape = shape
	static_body.add_child(collision)
	mesh_instance.add_child(static_body)

func create_pillar(parent: Node3D, pos: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.5, 2.0, 0.5)
	mesh_instance.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.8)
	material.roughness = 1.0
	mesh_instance.material_override = material
	
	mesh_instance.position = pos
	parent.add_child(mesh_instance)
	
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.5, 2.0, 0.5)
	collision.shape = shape
	static_body.add_child(collision)
	mesh_instance.add_child(static_body)

func clear_maze():
	for obj in cell_objects:
		obj.queue_free()
	cell_objects.clear()

func _process(delta):
	if is_playing:
		update_game(delta)
	elif Input.is_action_just_pressed("ui_accept"):
		start_new_game()

func update_game(delta: float):
	var player_pos = player.move(delta)
	var current_scent = scent.disperse(maze, player_pos, delta)
	
	for agent in agents:
		var agent_pos = agent.move(current_scent, delta)
		var dist_sq = Vector2(agent_pos.x - player_pos.x, agent_pos.z - player_pos.z).length_squared()
		if dist_sq < 1.0:
			end_game(agent.trigger_message)
			return

func end_game(message: String):
	is_playing = false
	display_label.text = message
	display_label.show()
	
	for agent in agents:
		agent.end_game()
	
	clear_maze()
	if maze:
		maze.dispose()
	if scent:
		scent.dispose()
