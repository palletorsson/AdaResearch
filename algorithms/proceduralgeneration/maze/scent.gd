# scent.gd - Scent dispersion system for AI pathfinding
class_name Scent

var scent_a: Array
var scent_b: Array
var use_a := false
var cooldown := 0.0

func _init(maze: Maze):
	scent_a = []
	scent_b = []
	scent_a.resize(maze.cells.size())
	scent_b.resize(maze.cells.size())
	scent_a.fill(0.0)
	scent_b.fill(0.0)

func disperse(maze: Maze, player_position: Vector3, delta: float) -> Array:
	cooldown -= delta
	
	if cooldown <= 0.0:
		cooldown += 0.1
		
		var old_scent = scent_a if use_a else scent_b
		var new_scent = scent_b if use_a else scent_a
		
		for i in range(maze.cells.size()):
			var cell = maze.cells[i]
			var scent = old_scent[i]
			var from_neighbors = 0.0
			var dispersal_factor = 0.0
			
			if cell & Maze.PASSAGE_E:
				from_neighbors += old_scent[i + maze.get_step_e()]
				dispersal_factor += 1.0
			
			if cell & Maze.PASSAGE_W:
				from_neighbors += old_scent[i + maze.get_step_w()]
				dispersal_factor += 1.0
			
			if cell & Maze.PASSAGE_N:
				from_neighbors += old_scent[i + maze.get_step_n()]
				dispersal_factor += 1.0
			
			if cell & Maze.PASSAGE_S:
				from_neighbors += old_scent[i + maze.get_step_s()]
				dispersal_factor += 1.0
			
			scent += (from_neighbors - scent * dispersal_factor) * 0.2
			new_scent[i] = scent * 0.5
		
		use_a = not use_a
	
	var current = scent_a if use_a else scent_b
	var player_index = maze.world_position_to_index(player_position)
	if player_index >= 0 and player_index < current.size():
		current[player_index] = 1.0
	
	return current

func dispose():
	scent_a.clear()
	scent_b.clear()
