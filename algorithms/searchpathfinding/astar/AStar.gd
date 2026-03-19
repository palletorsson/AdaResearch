extends Node3D

# AStar — Jump Point Search, Theta*, and algorithm comparison
# 3 modes: JPS (pruned A* with jump points), THETA (any-angle paths),
# COMPARE (side-by-side A* vs JPS vs Theta*)

enum Mode { JPS, THETA, COMPARE }
enum AlgStep { IDLE, RUNNING, DONE }

const SLIDER_SCENE = preload("res://commons/interactables/slider_horizontal.tscn")
const BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")

@export var grid_size: int = 20
@export var obstacle_density: float = 0.25
@export var step_speed: float = 3.0
@export var cell_size: float = 0.3

var _mode: int = Mode.JPS
var _grid: Array = []  # 0 = walkable, 1 = obstacle
var _start: Vector2i = Vector2i(1, 1)
var _goal: Vector2i

# Algorithm state — each algorithm has its own state for comparison mode
var _alg_states: Array = []  # Array of dictionaries

# ImmediateMesh layers
var _grid_im: ImmediateMesh
var _grid_mi: MeshInstance3D
var _cells_im: ImmediateMesh
var _cells_mi: MeshInstance3D
var _path_im: ImmediateMesh
var _path_mi: MeshInstance3D
var _overlay_im: ImmediateMesh
var _overlay_mi: MeshInstance3D

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# Labels
var _title_label: Label3D
var _info_label: Label3D
var _mode_label: Label3D
var _stats_label: Label3D

# VR controls
var _mode_button: Node3D
var _density_slider: Node3D
var _speed_slider: Node3D
var _size_slider: Node3D
var _reset_button: Node3D

# Timing
var _step_timer: float = 0.0
var _auto_restart_timer: float = 0.0
var _running: bool = false
var _finished: bool = false

# Colors
const COL_FLOOR := Color(0.15, 0.18, 0.25)
const COL_WALL := Color(0.35, 0.15, 0.12)
const COL_START := Color(0.2, 0.85, 0.3)
const COL_GOAL := Color(0.9, 0.2, 0.15)
const COL_OPEN := Color(0.3, 0.7, 0.85, 0.7)
const COL_CLOSED := Color(0.45, 0.5, 0.6, 0.5)
const COL_PATH_ASTAR := Color(1.0, 0.85, 0.1)
const COL_PATH_JPS := Color(0.2, 0.9, 1.0)
const COL_PATH_THETA := Color(1.0, 0.4, 0.8)
const COL_JUMP := Color(0.0, 1.0, 0.6)
const COL_GRID := Color(0.3, 0.35, 0.4, 0.4)
const COL_LOS := Color(1.0, 0.6, 0.2, 0.6)

# Compare mode offsets
var _compare_offsets: Array = []


func _ready() -> void:
	_goal = Vector2i(grid_size - 2, grid_size - 2)
	_create_materials()
	_create_mesh_instances()
	_create_labels()
	_create_vr_controls()
	_generate_grid()
	_start_algorithms()


func _process(delta: float) -> void:
	_step_timer += delta

	if _running and _step_timer >= (1.0 / maxf(step_speed, 0.01)):
		_step_timer = 0.0
		_advance_all()

	if _finished:
		_auto_restart_timer += delta
		if _auto_restart_timer > 6.0:
			_restart()

	_draw_all()
	_update_labels()


# --- Setup ---

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alpha = StandardMaterial3D.new()
	_mat_alpha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_alpha.vertex_color_use_as_albedo = true
	_mat_alpha.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _create_mesh_instances() -> void:
	_grid_im = ImmediateMesh.new()
	_grid_mi = MeshInstance3D.new()
	_grid_mi.mesh = _grid_im
	_grid_mi.material_override = _mat_alpha
	add_child(_grid_mi)

	_cells_im = ImmediateMesh.new()
	_cells_mi = MeshInstance3D.new()
	_cells_mi.mesh = _cells_im
	_cells_mi.material_override = _mat_unshaded
	add_child(_cells_mi)

	_path_im = ImmediateMesh.new()
	_path_mi = MeshInstance3D.new()
	_path_mi.mesh = _path_im
	_path_mi.material_override = _mat_unshaded
	add_child(_path_mi)

	_overlay_im = ImmediateMesh.new()
	_overlay_mi = MeshInstance3D.new()
	_overlay_mi.mesh = _overlay_im
	_overlay_mi.material_override = _mat_alpha
	add_child(_overlay_mi)


func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 72
	_title_label.outline_size = 8
	_title_label.modulate = Color.WHITE
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.font_size = 40
	_info_label.outline_size = 6
	_info_label.modulate = Color(0.85, 0.85, 0.9)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_info_label)

	_mode_label = Label3D.new()
	_mode_label.font_size = 36
	_mode_label.outline_size = 6
	_mode_label.modulate = Color(0.7, 0.8, 1.0)
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_mode_label)

	_stats_label = Label3D.new()
	_stats_label.font_size = 32
	_stats_label.outline_size = 5
	_stats_label.modulate = Color(0.75, 0.75, 0.8)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_stats_label)


func _create_vr_controls() -> void:
	var total_w := _total_width()
	var panel_y := -0.8
	var panel_z := total_w * 0.5 + 1.0

	_mode_button = BUTTON_SCENE.instantiate()
	_mode_button.position = Vector3(-2.5, panel_y, panel_z)
	add_child(_mode_button)
	var mb_area = _mode_button.get_node_or_null("InteractableAreaButton")
	if mb_area:
		mb_area.button_pressed.connect(_on_mode_pressed)

	_reset_button = BUTTON_SCENE.instantiate()
	_reset_button.position = Vector3(-1.0, panel_y, panel_z)
	add_child(_reset_button)
	var rb_area = _reset_button.get_node_or_null("InteractableAreaButton")
	if rb_area:
		rb_area.button_pressed.connect(_on_reset_pressed)

	_density_slider = SLIDER_SCENE.instantiate()
	_density_slider.position = Vector3(0.5, panel_y, panel_z)
	add_child(_density_slider)
	_density_slider.set_normalized_value(obstacle_density / 0.5)
	_density_slider.set_param_name("Walls")
	_density_slider.slider_moved.connect(_on_density_changed)

	_speed_slider = SLIDER_SCENE.instantiate()
	_speed_slider.position = Vector3(2.0, panel_y, panel_z)
	add_child(_speed_slider)
	_speed_slider.set_normalized_value(clampf((step_speed - 0.5) / 9.5, 0.0, 1.0))
	_speed_slider.set_param_name("Speed")
	_speed_slider.slider_moved.connect(_on_speed_changed)

	_size_slider = SLIDER_SCENE.instantiate()
	_size_slider.position = Vector3(3.5, panel_y, panel_z)
	add_child(_size_slider)
	_size_slider.set_normalized_value(clampf((grid_size - 10.0) / 30.0, 0.0, 1.0))
	_size_slider.set_param_name("Grid")
	_size_slider.slider_moved.connect(_on_size_changed)


# --- VR Callbacks ---

func _on_mode_pressed() -> void:
	_mode = (_mode + 1) % 3
	_restart()

func _on_reset_pressed() -> void:
	_restart()

func _on_density_changed(_v: float) -> void:
	obstacle_density = _density_slider.get_normalized_value() * 0.5
	_restart()

func _on_speed_changed(_v: float) -> void:
	step_speed = lerpf(0.5, 10.0, _speed_slider.get_normalized_value())

func _on_size_changed(_v: float) -> void:
	grid_size = int(lerpf(10.0, 40.0, _size_slider.get_normalized_value()))
	_goal = Vector2i(grid_size - 2, grid_size - 2)
	_restart()


# --- Grid Generation ---

func _generate_grid() -> void:
	_grid.clear()
	for x in range(grid_size):
		var row: Array = []
		for y in range(grid_size):
			row.append(0)
		_grid.append(row)

	# Random obstacles
	for x in range(grid_size):
		for y in range(grid_size):
			if randf() < obstacle_density:
				_grid[x][y] = 1

	# Clear start/goal and paths to them
	_grid[_start.x][_start.y] = 0
	_grid[_goal.x][_goal.y] = 0
	# Clear a small area around start and goal
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var sx := _start.x + dx
			var sy := _start.y + dy
			var gx := _goal.x + dx
			var gy := _goal.y + dy
			if _in_bounds(Vector2i(sx, sy)):
				_grid[sx][sy] = 0
			if _in_bounds(Vector2i(gx, gy)):
				_grid[gx][gy] = 0


func _in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < grid_size and p.y >= 0 and p.y < grid_size

func _walkable(p: Vector2i) -> bool:
	return _in_bounds(p) and _grid[p.x][p.y] == 0


# --- Algorithm State ---

func _make_alg_state(alg_name: String) -> Dictionary:
	return {
		"name": alg_name,
		"open": [],         # Array of Vector2i
		"closed": [],       # Array of Vector2i (as dict for O(1))
		"closed_set": {},   # pos -> true
		"came_from": {},    # pos -> pos
		"g_score": {},      # pos -> float
		"f_score": {},      # pos -> float
		"parent": {},       # for Theta*: pos -> pos (line-of-sight parent)
		"path": [],         # final path
		"jump_points": [],  # JPS jump points found
		"los_lines": [],    # Theta* line-of-sight checks
		"step": AlgStep.IDLE,
		"nodes_expanded": 0,
		"path_length": 0.0,
	}


func _start_algorithms() -> void:
	_alg_states.clear()
	_running = true
	_finished = false
	_auto_restart_timer = 0.0
	_step_timer = 0.0

	match _mode:
		Mode.JPS:
			_compare_offsets = [Vector3.ZERO]
			var s := _make_alg_state("JPS")
			_init_alg(s)
			_alg_states.append(s)
		Mode.THETA:
			_compare_offsets = [Vector3.ZERO]
			var s := _make_alg_state("Theta*")
			_init_alg(s)
			_alg_states.append(s)
		Mode.COMPARE:
			var gap := (_total_single_width() + 1.0)
			_compare_offsets = [
				Vector3(-gap, 0, 0),
				Vector3(0, 0, 0),
				Vector3(gap, 0, 0),
			]
			for alg_name in ["A*", "JPS", "Theta*"]:
				var s := _make_alg_state(alg_name)
				_init_alg(s)
				_alg_states.append(s)


func _init_alg(state: Dictionary) -> void:
	state["open"] = [_start]
	state["g_score"][_start] = 0.0
	state["f_score"][_start] = _heuristic(_start, _goal)
	state["step"] = AlgStep.RUNNING
	if state["name"] == "Theta*":
		state["parent"][_start] = _start


func _restart() -> void:
	_generate_grid()
	_start_algorithms()


# --- Algorithm Stepping ---

func _advance_all() -> void:
	var all_done := true
	for s in _alg_states:
		if s["step"] == AlgStep.RUNNING:
			_advance_one(s)
			all_done = false
	if all_done:
		_running = false
		_finished = true


func _advance_one(state: Dictionary) -> void:
	var open: Array = state["open"]
	if open.is_empty():
		state["step"] = AlgStep.DONE
		return

	# Find node with lowest f_score
	var best_idx := 0
	var best_f: float = state["f_score"].get(open[0], INF)
	for i in range(1, open.size()):
		var f: float = state["f_score"].get(open[i], INF)
		if f < best_f:
			best_f = f
			best_idx = i

	var current: Vector2i = open[best_idx]
	open.remove_at(best_idx)

	if current == _goal:
		_reconstruct_path(state)
		state["step"] = AlgStep.DONE
		return

	state["closed"].append(current)
	state["closed_set"][current] = true
	state["nodes_expanded"] += 1

	match state["name"]:
		"A*":
			_expand_astar(state, current)
		"JPS":
			_expand_jps(state, current)
		"Theta*":
			_expand_theta(state, current)


# --- Standard A* Expansion ---

func _expand_astar(state: Dictionary, current: Vector2i) -> void:
	for nb in _neighbors(current):
		if state["closed_set"].has(nb):
			continue
		var move_cost := 1.0 if (nb.x == current.x or nb.y == current.y) else 1.414
		var tent_g: float = state["g_score"].get(current, INF) + move_cost
		if tent_g < state["g_score"].get(nb, INF):
			state["came_from"][nb] = current
			state["g_score"][nb] = tent_g
			state["f_score"][nb] = tent_g + _heuristic(nb, _goal)
			if nb not in state["open"]:
				state["open"].append(nb)


# --- Jump Point Search ---

func _expand_jps(state: Dictionary, current: Vector2i) -> void:
	var pruned := _jps_pruned_neighbors(state, current)
	for dir in pruned:
		var jp = _jps_jump(current, dir)
		if jp != Vector2i(-1, -1):
			if state["closed_set"].has(jp):
				continue
			state["jump_points"].append(jp)
			var d := Vector2(jp - current).length()
			var tent_g: float = state["g_score"].get(current, INF) + d
			if tent_g < state["g_score"].get(jp, INF):
				state["came_from"][jp] = current
				state["g_score"][jp] = tent_g
				state["f_score"][jp] = tent_g + _heuristic(jp, _goal)
				if jp not in state["open"]:
					state["open"].append(jp)


func _jps_pruned_neighbors(state: Dictionary, current: Vector2i) -> Array:
	# If no parent, return all directions
	if not state["came_from"].has(current):
		var dirs: Array = []
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nb := current + Vector2i(dx, dy)
				if _walkable(nb):
					dirs.append(Vector2i(dx, dy))
		return dirs

	var parent: Vector2i = state["came_from"][current]
	var dx := clampi(current.x - parent.x, -1, 1)
	var dy := clampi(current.y - parent.y, -1, 1)
	var dirs: Array = []

	if dx != 0 and dy != 0:
		# Diagonal move — natural neighbors + forced
		if _walkable(current + Vector2i(dx, 0)):
			dirs.append(Vector2i(dx, 0))
		if _walkable(current + Vector2i(0, dy)):
			dirs.append(Vector2i(0, dy))
		if _walkable(current + Vector2i(dx, dy)):
			dirs.append(Vector2i(dx, dy))
		# Forced neighbors
		if not _walkable(current + Vector2i(-dx, 0)) and _walkable(current + Vector2i(-dx, dy)):
			dirs.append(Vector2i(-dx, dy))
		if not _walkable(current + Vector2i(0, -dy)) and _walkable(current + Vector2i(dx, -dy)):
			dirs.append(Vector2i(dx, -dy))
	elif dx != 0:
		# Horizontal move
		if _walkable(current + Vector2i(dx, 0)):
			dirs.append(Vector2i(dx, 0))
		# Forced neighbors
		if not _walkable(current + Vector2i(0, 1)) and _walkable(current + Vector2i(dx, 1)):
			dirs.append(Vector2i(dx, 1))
		if not _walkable(current + Vector2i(0, -1)) and _walkable(current + Vector2i(dx, -1)):
			dirs.append(Vector2i(dx, -1))
	else:
		# Vertical move
		if _walkable(current + Vector2i(0, dy)):
			dirs.append(Vector2i(0, dy))
		# Forced neighbors
		if not _walkable(current + Vector2i(1, 0)) and _walkable(current + Vector2i(1, dy)):
			dirs.append(Vector2i(1, dy))
		if not _walkable(current + Vector2i(-1, 0)) and _walkable(current + Vector2i(-1, dy)):
			dirs.append(Vector2i(-1, dy))

	return dirs


func _jps_jump(pos: Vector2i, dir: Vector2i) -> Vector2i:
	var next := pos + dir
	if not _walkable(next):
		return Vector2i(-1, -1)
	if next == _goal:
		return next

	# Check forced neighbors
	if dir.x != 0 and dir.y != 0:
		# Diagonal — check forced and recurse on components
		if (_walkable(next + Vector2i(-dir.x, dir.y)) and not _walkable(next + Vector2i(-dir.x, 0))):
			return next
		if (_walkable(next + Vector2i(dir.x, -dir.y)) and not _walkable(next + Vector2i(0, -dir.y))):
			return next
		# Recurse horizontally and vertically
		if _jps_jump(next, Vector2i(dir.x, 0)) != Vector2i(-1, -1):
			return next
		if _jps_jump(next, Vector2i(0, dir.y)) != Vector2i(-1, -1):
			return next
	else:
		if dir.x != 0:
			if (_walkable(next + Vector2i(dir.x, 1)) and not _walkable(next + Vector2i(0, 1))):
				return next
			if (_walkable(next + Vector2i(dir.x, -1)) and not _walkable(next + Vector2i(0, -1))):
				return next
		else:
			if (_walkable(next + Vector2i(1, dir.y)) and not _walkable(next + Vector2i(1, 0))):
				return next
			if (_walkable(next + Vector2i(-1, dir.y)) and not _walkable(next + Vector2i(-1, 0))):
				return next

	return _jps_jump(next, dir)


# --- Theta* (Any-Angle) ---

func _expand_theta(state: Dictionary, current: Vector2i) -> void:
	for nb in _neighbors(current):
		if state["closed_set"].has(nb):
			continue
		# Try line-of-sight from parent of current
		var par: Vector2i = state["parent"].get(current, current)
		if _line_of_sight(par, nb):
			var d := Vector2(nb - par).length()
			var tent_g: float = state["g_score"].get(par, INF) + d
			if tent_g < state["g_score"].get(nb, INF):
				state["parent"][nb] = par
				state["came_from"][nb] = par
				state["g_score"][nb] = tent_g
				state["f_score"][nb] = tent_g + _heuristic(nb, _goal)
				state["los_lines"].append([par, nb])
				if nb not in state["open"]:
					state["open"].append(nb)
		else:
			# Fall back to A* step
			var move_cost := 1.0 if (nb.x == current.x or nb.y == current.y) else 1.414
			var tent_g: float = state["g_score"].get(current, INF) + move_cost
			if tent_g < state["g_score"].get(nb, INF):
				state["parent"][nb] = current
				state["came_from"][nb] = current
				state["g_score"][nb] = tent_g
				state["f_score"][nb] = tent_g + _heuristic(nb, _goal)
				if nb not in state["open"]:
					state["open"].append(nb)


func _line_of_sight(a: Vector2i, b: Vector2i) -> bool:
	# Bresenham line to check if path is clear
	var x0 := a.x
	var y0 := a.y
	var x1 := b.x
	var y1 := b.y
	var dx := absi(x1 - x0)
	var dy := absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx - dy

	while true:
		if not _walkable(Vector2i(x0, y0)):
			return false
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy
	return true


# --- Utilities ---

func _neighbors(pos: Vector2i) -> Array:
	var result: Array = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nb := pos + Vector2i(dx, dy)
			if _walkable(nb):
				# For diagonal, check that both cardinal neighbors are walkable
				if dx != 0 and dy != 0:
					if _walkable(pos + Vector2i(dx, 0)) or _walkable(pos + Vector2i(0, dy)):
						result.append(nb)
				else:
					result.append(nb)
	return result


func _heuristic(a: Vector2i, b: Vector2i) -> float:
	var dx := absf(float(b.x - a.x))
	var dy := absf(float(b.y - a.y))
	# Octile distance
	return maxf(dx, dy) + (1.414 - 1.0) * minf(dx, dy)


func _reconstruct_path(state: Dictionary) -> void:
	var p: Array = []
	var current := _goal
	while state["came_from"].has(current):
		p.append(current)
		current = state["came_from"][current]
	p.append(_start)
	p.reverse()
	state["path"] = p

	# Compute path length
	var length := 0.0
	for i in range(1, p.size()):
		length += Vector2(p[i] - p[i - 1]).length()
	state["path_length"] = length


# --- Drawing ---

func _total_single_width() -> float:
	return grid_size * cell_size

func _total_width() -> float:
	if _mode == Mode.COMPARE:
		return _total_single_width() * 3.0 + 2.0
	return _total_single_width()

func _cell_center(pos: Vector2i, offset: Vector3) -> Vector3:
	var hw := grid_size * cell_size * 0.5
	return Vector3(
		pos.x * cell_size - hw + cell_size * 0.5 + offset.x,
		pos.y * cell_size - hw + cell_size * 0.5 + offset.z,  # use Z for Y on the wall
		0.0
	)


func _draw_all() -> void:
	_draw_grids()
	_draw_cells()
	_draw_paths()
	_draw_overlays()


func _draw_grids() -> void:
	_grid_im.clear_surfaces()
	_grid_im.surface_begin(Mesh.PRIMITIVE_LINES)

	for si in range(_alg_states.size()):
		var off: Vector3 = _compare_offsets[si] if si < _compare_offsets.size() else Vector3.ZERO
		var hw := grid_size * cell_size * 0.5
		# Grid lines
		for i in range(grid_size + 1):
			var p := i * cell_size - hw
			_grid_im.surface_set_color(COL_GRID)
			_grid_im.surface_add_vertex(Vector3(p + off.x, -hw + off.z, -0.02))
			_grid_im.surface_add_vertex(Vector3(p + off.x, hw + off.z, -0.02))
			_grid_im.surface_add_vertex(Vector3(-hw + off.x, p + off.z, -0.02))
			_grid_im.surface_add_vertex(Vector3(hw + off.x, p + off.z, -0.02))

	_grid_im.surface_end()


func _draw_cells() -> void:
	_cells_im.clear_surfaces()
	_cells_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for si in range(_alg_states.size()):
		var off: Vector3 = _compare_offsets[si] if si < _compare_offsets.size() else Vector3.ZERO
		var state: Dictionary = _alg_states[si]

		for x in range(grid_size):
			for y in range(grid_size):
				var pos := Vector2i(x, y)
				var c := _cell_center(pos, off)
				var col: Color

				if pos == _start:
					col = COL_START
				elif pos == _goal:
					col = COL_GOAL
				elif _grid[x][y] == 1:
					col = COL_WALL
				elif pos in state["path"]:
					col = _path_color(state["name"])
				elif state["closed_set"].has(pos):
					col = COL_CLOSED
				elif pos in state["open"]:
					col = COL_OPEN
				else:
					col = COL_FLOOR

				_draw_quad(c, cell_size * 0.45, col)

	_cells_im.surface_end()


func _draw_paths() -> void:
	_path_im.clear_surfaces()
	_path_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for si in range(_alg_states.size()):
		var off: Vector3 = _compare_offsets[si] if si < _compare_offsets.size() else Vector3.ZERO
		var state: Dictionary = _alg_states[si]
		var p: Array = state["path"]
		var col := _path_color(state["name"])

		# Draw path as thick line segments
		for i in range(1, p.size()):
			var a := _cell_center(p[i - 1], off)
			var b := _cell_center(p[i], off)
			_draw_thick_line(a, b, cell_size * 0.12, col)

		# Draw jump points for JPS
		if state["name"] == "JPS":
			for jp in state["jump_points"]:
				var c := _cell_center(jp, off)
				_draw_diamond(c, cell_size * 0.3, COL_JUMP)

	_path_im.surface_end()


func _draw_overlays() -> void:
	_overlay_im.clear_surfaces()
	_overlay_im.surface_begin(Mesh.PRIMITIVE_LINES)

	for si in range(_alg_states.size()):
		var off: Vector3 = _compare_offsets[si] if si < _compare_offsets.size() else Vector3.ZERO
		var state: Dictionary = _alg_states[si]

		# Draw Theta* line-of-sight checks (last N)
		if state["name"] == "Theta*":
			var lines: Array = state["los_lines"]
			var start_idx := maxi(0, lines.size() - 30)
			for i in range(start_idx, lines.size()):
				var line: Array = lines[i]
				var a := _cell_center(line[0], off)
				var b := _cell_center(line[1], off)
				_overlay_im.surface_set_color(COL_LOS)
				_overlay_im.surface_add_vertex(Vector3(a.x, a.y, 0.03))
				_overlay_im.surface_add_vertex(Vector3(b.x, b.y, 0.03))

	_overlay_im.surface_end()


func _path_color(alg_name: String) -> Color:
	match alg_name:
		"A*": return COL_PATH_ASTAR
		"JPS": return COL_PATH_JPS
		"Theta*": return COL_PATH_THETA
	return COL_PATH_ASTAR


func _draw_quad(center: Vector3, half: float, col: Color) -> void:
	var z := center.z + 0.01
	_cells_im.surface_set_color(col)
	_cells_im.surface_add_vertex(Vector3(center.x - half, center.y - half, z))
	_cells_im.surface_add_vertex(Vector3(center.x + half, center.y - half, z))
	_cells_im.surface_add_vertex(Vector3(center.x + half, center.y + half, z))
	_cells_im.surface_add_vertex(Vector3(center.x - half, center.y - half, z))
	_cells_im.surface_add_vertex(Vector3(center.x + half, center.y + half, z))
	_cells_im.surface_add_vertex(Vector3(center.x - half, center.y + half, z))


func _draw_diamond(center: Vector3, r: float, col: Color) -> void:
	var z := center.z + 0.05
	_path_im.surface_set_color(col)
	_path_im.surface_add_vertex(Vector3(center.x, center.y - r, z))
	_path_im.surface_add_vertex(Vector3(center.x + r, center.y, z))
	_path_im.surface_add_vertex(Vector3(center.x, center.y + r, z))
	_path_im.surface_add_vertex(Vector3(center.x, center.y - r, z))
	_path_im.surface_add_vertex(Vector3(center.x, center.y + r, z))
	_path_im.surface_add_vertex(Vector3(center.x - r, center.y, z))


func _draw_thick_line(a: Vector3, b: Vector3, thickness: float, col: Color) -> void:
	var dir := (b - a).normalized()
	var perp := Vector3(-dir.y, dir.x, 0.0) * thickness * 0.5
	var z_off := Vector3(0, 0, 0.04)
	_path_im.surface_set_color(col)
	_path_im.surface_add_vertex(a - perp + z_off)
	_path_im.surface_add_vertex(b - perp + z_off)
	_path_im.surface_add_vertex(b + perp + z_off)
	_path_im.surface_add_vertex(a - perp + z_off)
	_path_im.surface_add_vertex(b + perp + z_off)
	_path_im.surface_add_vertex(a + perp + z_off)


# --- Labels ---

func _update_labels() -> void:
	var tw := _total_width()
	var hw := grid_size * cell_size * 0.5

	_title_label.position = Vector3(0, hw + 1.2, 0)
	_info_label.position = Vector3(0, hw + 0.6, 0)
	_mode_label.position = Vector3(0, -hw - 0.6, 0)

	var mode_names := ["Jump Point Search", "Theta* (Any-Angle)", "Algorithm Comparison"]
	_title_label.text = mode_names[_mode]

	match _mode:
		Mode.JPS:
			_info_label.text = "Prunes symmetric paths — only expands jump points"
		Mode.THETA:
			_info_label.text = "Line-of-sight shortcuts — optimal any-angle paths"
		Mode.COMPARE:
			_info_label.text = "A* vs JPS vs Theta* — same grid, different strategies"

	_mode_label.text = "[Mode: %s]  Grid: %dx%d  Walls: %d%%" % [
		mode_names[_mode], grid_size, grid_size, int(obstacle_density * 100)]

	# Stats
	var stats := ""
	for s in _alg_states:
		var status := "searching..." if s["step"] == AlgStep.RUNNING else "done"
		if s["step"] == AlgStep.DONE and s["path"].is_empty():
			status = "no path"
		var path_info := ""
		if s["path_length"] > 0:
			path_info = "  len=%.1f" % s["path_length"]
		stats += "%s: %d nodes%s  [%s]\n" % [s["name"], s["nodes_expanded"], path_info, status]

	_stats_label.text = stats.strip_edges()
	_stats_label.position = Vector3(tw * 0.5 + 1.5, 0, 0)


# --- apply_grid_config ---

func apply_grid_config(config: Dictionary) -> void:
	if config.has("grid_size"):
		grid_size = clampi(int(config["grid_size"]), 8, 50)
		_goal = Vector2i(grid_size - 2, grid_size - 2)
	if config.has("obstacle_density"):
		obstacle_density = clampf(float(config["obstacle_density"]), 0.0, 0.5)
	if config.has("step_speed"):
		step_speed = clampf(float(config["step_speed"]), 0.1, 20.0)
	if config.has("cell_size"):
		cell_size = clampf(float(config["cell_size"]), 0.1, 1.0)
	if config.has("mode"):
		var m: String = str(config["mode"]).to_upper()
		match m:
			"JPS": _mode = Mode.JPS
			"THETA": _mode = Mode.THETA
			"COMPARE": _mode = Mode.COMPARE

	if _density_slider:
		_density_slider.set_normalized_value(obstacle_density / 0.5)
	if _speed_slider:
		_speed_slider.set_normalized_value(clampf((step_speed - 0.5) / 9.5, 0.0, 1.0))
	if _size_slider:
		_size_slider.set_normalized_value(clampf((grid_size - 10.0) / 30.0, 0.0, 1.0))

	_restart()
