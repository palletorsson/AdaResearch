# @identity
# essence: DFS(grid) -> carve(corridors) -> spin(core) -- maze regenerating itself every 8 seconds
# desire: a crystalline core surrounded by DFS-carved maze that rebuilds constantly
# critical_parameter: _maze_grid / regeneration timer -- DFS carving determines corridors; 8-second rebuild
# triggers: timer triggers regeneration; DFS carves new corridors; core spins; walls damage on contact
# emerges: procedural generation as perpetual threat -- never the same maze, never memorizable
# needs: HazardCreatureBase [has]; DFS maze generation [has]; wall mesh [has]; core viz [has]; VR interaction [missing]
# relationships: embodies proceduralgeneration sequence; pairs with constraint_web (generation vs satisfaction)
# truth: the maze generates itself -- DFS carving corridors that are always new, always temporary, always dangerous.

extends HazardCreatureBase
class_name MazeSpinner
## Procedural generation sequence — crystalline core that generates a
## rotating 5x5 maze around itself. Walls are thin BoxMesh segments.
## The maze slowly rotates; during CHASE it spins faster and walls extend
## outward. Regenerates every 8 seconds with a new random seed.

@export_group("Maze")
@export var maze_size: int = 5
@export var cell_size: float = 0.2
@export var wall_height: float = 0.15
@export var wall_thickness: float = 0.02
@export var base_spin_speed: float = 0.3
@export var chase_spin_speed: float = 1.2
@export var regen_interval: float = 8.0
@export var chase_wall_extend: float = 0.05

@export_group("Combat")
@export var wall_damage: float = 8.0

# ── Maze State ─────────────────────────────────────────────────────────
var _maze_grid: Array[Array] = []  # 2D array of bools (visited during generation)
var _walls: Array[Dictionary] = [] # {mesh, mat, row, col, side} side: "h" or "v"
var _carved: Array[Array] = []     # Which walls are carved (removed)
var _core_mesh: MeshInstance3D = null
var _core_mat: StandardMaterial3D = null
var _wall_mat: StandardMaterial3D = null
var _maze_root: Node3D = null
var _label: Label3D = null
var _current_seed: int = 0
var _regen_timer: float = 0.0
var _spin_angle: float = 0.0
var _leg_roots: Array[Node3D] = []
var _walk_phase: float = 0.0


func _on_ready() -> void:
	max_health = 95.0
	_health = max_health
	chase_speed = 2.2
	patrol_speed = 1.2
	contact_damage = 10.0
	detection_radius = 8.0

	_current_seed = randi()
	_generate_maze()


func _create_materials() -> void:
	_core_mat = _make_material(
		Color(0.95, 0.95, 0.95),
		Color(0.9, 0.9, 0.85),
		1.0
	)
	_core_mat.emission_energy_multiplier = 3.0
	_wall_mat = _make_material(
		Color(0.25, 0.1, 0.35),
		Color(0.15, 0.05, 0.25)
	)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	col.shape = shape
	col.position.y = 0.4
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.4

	# Crystalline core — IcoSphere with strong emission
	var ico := SphereMesh.new()
	ico.radius = 0.08
	ico.height = 0.16
	_core_mesh = _add_mesh(ico, _core_mat)
	_core_mesh.name = "Core"

	# Maze container
	_maze_root = Node3D.new()
	_maze_root.name = "MazeRoot"
	_mesh_root.add_child(_maze_root)

	# 2 legs
	for i in range(2):
		var root := Node3D.new()
		root.name = "Leg_%d" % i
		root.position = Vector3((i - 0.5) * 0.1, -0.3, 0)
		_mesh_root.add_child(root)
		_leg_roots.append(root)

		var cyl := CylinderMesh.new()
		cyl.height = 0.18
		cyl.top_radius = 0.02
		cyl.bottom_radius = 0.015
		var leg_mat := _make_material(Color(0.2, 0.1, 0.3), Color.BLACK)
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.set_surface_override_material(0, leg_mat)
		mi.position = Vector3(0, -0.09, 0)
		root.add_child(mi)

	# Label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 36
	_label.pixel_size = 0.003
	_label.position = Vector3(0, 0.5, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)


func _generate_maze() -> void:
	# Clear existing walls
	for w in _walls:
		if is_instance_valid(w["mesh"]):
			w["mesh"].queue_free()
	_walls.clear()

	# Initialize grid
	_maze_grid.clear()
	_carved.clear()
	for row in range(maze_size):
		var grid_row: Array[bool] = []
		grid_row.resize(maze_size)
		for i in range(maze_size):
			grid_row[i] = false
		_maze_grid.append(grid_row)

	# Carved walls: horizontal walls (maze_size rows x maze_size-1 cols)
	# and vertical walls (maze_size-1 rows x maze_size cols)
	# We'll track which walls exist using a set approach
	# h_walls[row][col] = wall between (row,col) and (row,col+1)
	# v_walls[row][col] = wall between (row,col) and (row+1,col)
	var h_walls: Array[Array] = []
	var v_walls: Array[Array] = []
	for row in range(maze_size):
		var h_row: Array[bool] = []
		h_row.resize(maze_size - 1)
		for i in range(maze_size - 1):
			h_row[i] = true  # Wall present
		h_walls.append(h_row)

	for row in range(maze_size - 1):
		var v_row: Array[bool] = []
		v_row.resize(maze_size)
		for i in range(maze_size):
			v_row[i] = true  # Wall present
		v_walls.append(v_row)

	# DFS recursive backtracking
	seed(_current_seed)
	var stack: Array[Vector2i] = []
	var start := Vector2i(0, 0)
	_maze_grid[0][0] = true
	stack.append(start)

	while not stack.is_empty():
		var current: Vector2i = stack.back()
		var neighbors: Array[Vector2i] = _get_unvisited_neighbors(current)

		if neighbors.is_empty():
			stack.pop_back()
		else:
			var next: Vector2i = neighbors[randi() % neighbors.size()]
			# Carve wall between current and next
			if next.x == current.x:
				# Horizontal neighbor — carve vertical wall between them
				var min_col: int = min(current.y, next.y)
				if current.x < h_walls.size() and min_col < h_walls[current.x].size():
					h_walls[current.x][min_col] = false
			else:
				# Vertical neighbor — carve horizontal wall between them
				var min_row: int = min(current.x, next.x)
				if min_row < v_walls.size() and current.y < v_walls[min_row].size():
					v_walls[min_row][current.y] = false

			_maze_grid[next.x][next.y] = true
			stack.append(next)

	# Center offset so maze is centered on origin
	var half_span: float = (maze_size * cell_size) * 0.5

	# Build wall meshes
	# Horizontal walls (between columns)
	for row in range(maze_size):
		for col_idx in range(maze_size - 1):
			if h_walls[row][col_idx]:
				_create_wall_mesh(row, col_idx, "h", half_span)

	# Vertical walls (between rows)
	for row in range(maze_size - 1):
		for col_idx in range(maze_size):
			if v_walls[row][col_idx]:
				_create_wall_mesh(row, col_idx, "v", half_span)

	# Outer boundary walls
	for i in range(maze_size):
		# Top boundary
		_create_boundary_wall(0, i, "top", half_span)
		# Bottom boundary
		_create_boundary_wall(maze_size - 1, i, "bottom", half_span)
		# Left boundary
		_create_boundary_wall(i, 0, "left", half_span)
		# Right boundary
		_create_boundary_wall(i, maze_size - 1, "right", half_span)


func _get_unvisited_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for d in dirs:
		var nr: int = cell.x + d.x
		var nc: int = cell.y + d.y
		if nr >= 0 and nr < maze_size and nc >= 0 and nc < maze_size:
			if not _maze_grid[nr][nc]:
				neighbors.append(Vector2i(nr, nc))
	return neighbors


func _create_wall_mesh(row: int, col_idx: int, side: String, half_span: float) -> void:
	var box := BoxMesh.new()
	var pos := Vector3.ZERO
	var mat := _wall_mat.duplicate() as StandardMaterial3D

	if side == "h":
		# Wall between (row, col) and (row, col+1) — vertical wall segment
		box.size = Vector3(wall_thickness, wall_height, cell_size)
		var x: float = (col_idx + 1) * cell_size - half_span
		var z: float = (row + 0.5) * cell_size - half_span
		pos = Vector3(x, 0, z)
	else:
		# Wall between (row, col) and (row+1, col) — horizontal wall segment
		box.size = Vector3(cell_size, wall_height, wall_thickness)
		var x: float = (col_idx + 0.5) * cell_size - half_span
		var z: float = (row + 1) * cell_size - half_span
		pos = Vector3(x, 0, z)

	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	_maze_root.add_child(mi)

	_walls.append({
		"mesh": mi,
		"mat": mat,
		"row": row,
		"col": col_idx,
		"side": side,
	})


func _create_boundary_wall(row: int, col_idx: int, side: String, half_span: float) -> void:
	var box := BoxMesh.new()
	var pos := Vector3.ZERO
	var mat := _wall_mat.duplicate() as StandardMaterial3D

	match side:
		"top":
			box.size = Vector3(cell_size, wall_height, wall_thickness)
			pos = Vector3((col_idx + 0.5) * cell_size - half_span, 0, -half_span)
		"bottom":
			box.size = Vector3(cell_size, wall_height, wall_thickness)
			pos = Vector3((col_idx + 0.5) * cell_size - half_span, 0, half_span)
		"left":
			box.size = Vector3(wall_thickness, wall_height, cell_size)
			pos = Vector3(-half_span, 0, (row + 0.5) * cell_size - half_span)
		"right":
			box.size = Vector3(wall_thickness, wall_height, cell_size)
			pos = Vector3(half_span, 0, (row + 0.5) * cell_size - half_span)

	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	_maze_root.add_child(mi)

	_walls.append({
		"mesh": mi,
		"mat": mat,
		"row": row,
		"col": col_idx,
		"side": side,
	})


func _process_visual(delta: float) -> void:
	# Spin the maze
	var spin_speed: float = base_spin_speed
	if _state == BaseState.CHASE:
		spin_speed = chase_spin_speed

	_spin_angle += delta * spin_speed
	if is_instance_valid(_maze_root):
		_maze_root.rotation.y = _spin_angle

	# During chase: extend walls outward slightly
	if _state == BaseState.CHASE:
		for w in _walls:
			if is_instance_valid(w["mesh"]):
				var dir_from_center: Vector3 = w["mesh"].position.normalized()
				var target_pos: Vector3 = w["mesh"].position + dir_from_center * chase_wall_extend * delta
				# Clamp so walls don't fly away
				if target_pos.length() < maze_size * cell_size:
					w["mesh"].position = target_pos

	# Regeneration timer
	_regen_timer += delta
	if _regen_timer >= regen_interval:
		_regen_timer = 0.0
		_current_seed = randi()
		_generate_maze()

	# Core pulsing
	if is_instance_valid(_core_mesh):
		var pulse: float = 1.0 + sin(_spin_angle * 3.0) * 0.15
		_core_mesh.scale = Vector3.ONE * pulse

	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 5.0
		for i in range(_leg_roots.size()):
			_leg_roots[i].rotation.x = sin(_walk_phase + float(i) * PI) * 0.25

	# Wall proximity damage to player
	if is_instance_valid(_player_node):
		for w in _walls:
			if not is_instance_valid(w["mesh"]):
				continue
			var wall_world: Vector3 = w["mesh"].global_position
			var dist: float = wall_world.distance_to(_player_node.global_position)
			if dist < 0.12:
				var gm = get_node_or_null("/root/GameManager")
				if gm and gm.has_method("apply_health_damage"):
					gm.apply_health_damage(wall_damage * delta)
				break

	# Label
	if _label:
		_label.text = "SEED: %04d, WALLS: %d" % [_current_seed % 10000, _walls.size()]


func _on_damaged(_amount: float) -> void:
	# Speed up rotation temporarily
	_spin_angle += 2.0
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.CHASE:
		_regen_timer = regen_interval * 0.7  # Regenerate sooner
