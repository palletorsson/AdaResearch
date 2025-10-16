# maze.gd - Maze generation and management
class_name Maze

# Passage flags
const PASSAGE_N = 0b0001
const PASSAGE_E = 0b0010
const PASSAGE_S = 0b0100
const PASSAGE_W = 0b1000
const PASSAGES_STRAIGHT = 0b1111
const PASSAGE_NE = 0b0001_0000
const PASSAGE_SE = 0b0010_0000
const PASSAGE_SW = 0b0100_0000
const PASSAGE_NW = 0b1000_0000
const PASSAGES_DIAGONAL = 0b1111_0000

var size: Vector2i
var cells: Array

func _init(maze_size: Vector2i):
	size = maze_size
	cells = []
	cells.resize(size.x * size.y)
	cells.fill(0)

func coordinates_to_index(coords: Vector2i) -> int:
	return coords.y * size.x + coords.x

func index_to_coordinates(index: int) -> Vector2i:
	var y = index / size.x
	var x = index - size.x * y
	return Vector2i(x, y)

func coordinates_to_world_position(coords: Vector2i, y: float = 0.0) -> Vector3:
	return Vector3(
		2.0 * coords.x + 1.0 - size.x,
		y,
		2.0 * coords.y + 1.0 - size.y
	)

func index_to_world_position(index: int, y: float = 0.0) -> Vector3:
	return coordinates_to_world_position(index_to_coordinates(index), y)

func world_position_to_coordinates(pos: Vector3) -> Vector2i:
	return Vector2i(
		int((pos.x + size.x) * 0.5),
		int((pos.z + size.y) * 0.5)
	)

func world_position_to_index(pos: Vector3) -> int:
	return coordinates_to_index(world_position_to_coordinates(pos))

func get_step_n() -> int:
	return size.x

func get_step_e() -> int:
	return 1

func get_step_s() -> int:
	return -size.x

func get_step_w() -> int:
	return -1

func set_flag(index: int, mask: int):
	cells[index] = cells[index] | mask

func unset_flag(index: int, mask: int):
	cells[index] = cells[index] & ~mask

func has_flag(index: int, mask: int) -> bool:
	return (cells[index] & mask) == mask

func has_any_flag(index: int, mask: int) -> bool:
	return (cells[index] & mask) != 0

func has_exactly_one(flags: int) -> bool:
	return flags != 0 and (flags & (flags - 1)) == 0

func generate(pick_last_prob: float, open_dead_end_prob: float, open_arbitrary_prob: float):
	# Growing tree algorithm
	var active_indices = []
	var first_active = 0
	var last_active = 0
	
	active_indices.resize(cells.size())
	active_indices[0] = randi() % cells.size()
	
	while first_active <= last_active:
		var pick_last = randf() < pick_last_prob
		var random_active_idx = 0
		var index = 0
		
		if pick_last:
			index = active_indices[last_active]
		else:
			random_active_idx = randi_range(first_active, last_active)
			index = active_indices[random_active_idx]
		
		var available = find_available_passages(index)
		
		if available.size() <= 1:
			if pick_last:
				last_active -= 1
			else:
				active_indices[random_active_idx] = active_indices[first_active]
				first_active += 1
		
		if available.size() > 0:
			var passage = available[randi() % available.size()]
			set_flag(index, passage[1])
			cells[passage[0]] = passage[2]
			last_active += 1
			active_indices[last_active] = passage[0]
	
	# Open dead ends
	if open_dead_end_prob > 0:
		for i in range(cells.size()):
			var cell = cells[i]
			var straight = cell & PASSAGES_STRAIGHT
			if has_exactly_one(straight) and randf() < open_dead_end_prob:
				var closed = find_closed_passages(i, straight)
				if closed.size() > 0:
					var passage = closed[randi() % closed.size()]
					cells[i] = cell | passage[1]
					set_flag(i + passage[0], passage[2])
	
	# Open arbitrary passages
	if open_arbitrary_prob > 0:
		for i in range(cells.size()):
			var coords = index_to_coordinates(i)
			if coords.x > 0 and randf() < open_arbitrary_prob:
				set_flag(i, PASSAGE_W)
				set_flag(i + get_step_w(), PASSAGE_E)
			if coords.y > 0 and randf() < open_arbitrary_prob:
				set_flag(i, PASSAGE_S)
				set_flag(i + get_step_s(), PASSAGE_N)

func find_available_passages(index: int) -> Array:
	var coords = index_to_coordinates(index)
	var available = []
	
	if coords.x + 1 < size.x:
		var i = index + get_step_e()
		if cells[i] == 0:
			available.append([i, PASSAGE_E, PASSAGE_W])
	
	if coords.x > 0:
		var i = index + get_step_w()
		if cells[i] == 0:
			available.append([i, PASSAGE_W, PASSAGE_E])
	
	if coords.y + 1 < size.y:
		var i = index + get_step_n()
		if cells[i] == 0:
			available.append([i, PASSAGE_N, PASSAGE_S])
	
	if coords.y > 0:
		var i = index + get_step_s()
		if cells[i] == 0:
			available.append([i, PASSAGE_S, PASSAGE_N])
	
	return available

func find_closed_passages(index: int, exclude: int) -> Array:
	var coords = index_to_coordinates(index)
	var closed = []
	
	if exclude != PASSAGE_E and coords.x + 1 < size.x:
		closed.append([get_step_e(), PASSAGE_E, PASSAGE_W])
	
	if exclude != PASSAGE_W and coords.x > 0:
		closed.append([get_step_w(), PASSAGE_W, PASSAGE_E])
	
	if exclude != PASSAGE_N and coords.y + 1 < size.y:
		closed.append([get_step_n(), PASSAGE_N, PASSAGE_S])
	
	if exclude != PASSAGE_S and coords.y > 0:
		closed.append([get_step_s(), PASSAGE_S, PASSAGE_N])
	
	return closed

func find_diagonal_passages():
	for i in range(cells.size()):
		var cell = cells[i]
		
		# Check NE
		if (cell & (PASSAGE_N | PASSAGE_E)) == (PASSAGE_N | PASSAGE_E):
			var ne_idx = i + get_step_n() + get_step_e()
			if ne_idx >= 0 and ne_idx < cells.size():
				if (cells[ne_idx] & (PASSAGE_S | PASSAGE_W)) == (PASSAGE_S | PASSAGE_W):
					cell = cell | PASSAGE_NE
		
		# Check NW
		if (cell & (PASSAGE_N | PASSAGE_W)) == (PASSAGE_N | PASSAGE_W):
			var nw_idx = i + get_step_n() + get_step_w()
			if nw_idx >= 0 and nw_idx < cells.size():
				if (cells[nw_idx] & (PASSAGE_S | PASSAGE_E)) == (PASSAGE_S | PASSAGE_E):
					cell = cell | PASSAGE_NW
		
		# Check SE
		if (cell & (PASSAGE_S | PASSAGE_E)) == (PASSAGE_S | PASSAGE_E):
			var se_idx = i + get_step_s() + get_step_e()
			if se_idx >= 0 and se_idx < cells.size():
				if (cells[se_idx] & (PASSAGE_N | PASSAGE_W)) == (PASSAGE_N | PASSAGE_W):
					cell = cell | PASSAGE_SE
		
		# Check SW
		if (cell & (PASSAGE_S | PASSAGE_W)) == (PASSAGE_S | PASSAGE_W):
			var sw_idx = i + get_step_s() + get_step_w()
			if sw_idx >= 0 and sw_idx < cells.size():
				if (cells[sw_idx] & (PASSAGE_N | PASSAGE_E)) == (PASSAGE_N | PASSAGE_E):
					cell = cell | PASSAGE_SW
		
		cells[i] = cell

func dispose():
	cells.clear()
