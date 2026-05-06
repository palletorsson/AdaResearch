# @identity
# essence: cell(t+1) = GoL(neighbors(t)) -- walking creature with 6x6 Game of Life grid as armor
# desire: Conway's automaton tiling a walker's torso, alive cells as armor, dead cells as vulnerability
# critical_parameter: _grid state / _generation -- GoL rules determine which body cells are armored
# triggers: _ca_timer advances generations; alive cells block damage; dead cells expose creature
# emerges: emergent armor patterns -- gliders, oscillators, still lifes have tactical meaning as coverage
# needs: HazardCreatureBase [has]; 6x6 GoL grid [has]; cell mesh [has]; armor logic [has]; VR interaction [missing]
# relationships: embodies cellularautomata sequence; GoL rules create unpredictable defense patterns
# truth: armor that evolves by its own rules -- the creature does not choose defenses, emergence does.

extends HazardCreatureBase
class_name LifeformWalker
## Cellular Automata hazard — a walking creature with a 6×6 Game of Life grid
## on its torso. Living cells provide armor; dead cells expose weakness.
## CA rules run each tick, teaching local rules → global patterns.

@export_group("Cellular Automata")
@export var ca_rows: int = 6
@export var ca_cols: int = 6
@export var ca_tick_rate: float = 0.5
@export var ca_tick_rate_chase: float = 0.2
@export var cell_size: float = 0.05

@export_group("Appearance")
@export var alive_color: Color = Color(0.2, 1.0, 0.3)
@export var dead_color: Color = Color(0.1, 0.1, 0.12)
@export var body_color: Color = Color(0.25, 0.3, 0.28)
@export var emission_alive: Color = Color(0.1, 0.8, 0.2)

# CA state
var _grid: Array = []  # 2D array of bools
var _ca_timer: float = 0.0
var _generation: int = 0
var _alive_count: int = 0

# Visual
var _cell_meshes: Array[MeshInstance3D] = []
var _cell_mats: Array[StandardMaterial3D] = []
var _body_mi: MeshInstance3D = null
var _head_mi: MeshInstance3D = null
var _leg_l: MeshInstance3D = null
var _leg_r: MeshInstance3D = null
var _label: Label3D = null
var _walk_phase: float = 0.0
var _body_mat: StandardMaterial3D
var _alive_mat: StandardMaterial3D
var _dead_mat: StandardMaterial3D


func _on_ready() -> void:
	add_to_group("ca_enemy")
	_init_grid()


func _init_grid() -> void:
	_grid.clear()
	for r in range(ca_rows):
		var row: Array = []
		for c in range(ca_cols):
			row.append(randf() > 0.5)
		_grid.append(row)
	_count_alive()


func _create_materials() -> void:
	_body_mat = _make_material(body_color)
	_alive_mat = _make_material(alive_color, emission_alive)
	_dead_mat = _make_material(dead_color)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.45, 0.55, 0.2)
	col.shape = shape
	col.position.y = 0.45
	add_child(col)


func _build_mesh() -> void:
	# Torso
	var torso := BoxMesh.new()
	var grid_w: float = ca_cols * (cell_size + 0.01) + 0.04
	var grid_h: float = ca_rows * (cell_size + 0.01) + 0.04
	torso.size = Vector3(grid_w, grid_h, 0.06)
	_body_mi = _add_mesh(torso, _body_mat, Vector3(0.0, 0.5, 0.0))

	# CA cells on torso
	var start_x: float = -(ca_cols - 1) * (cell_size + 0.01) * 0.5
	var start_y: float = (ca_rows - 1) * (cell_size + 0.01) * 0.5
	for r in range(ca_rows):
		for c in range(ca_cols):
			var cm := BoxMesh.new()
			cm.size = Vector3(cell_size, cell_size, cell_size)
			var mat: StandardMaterial3D = _alive_mat.duplicate()
			var pos := Vector3(
				start_x + c * (cell_size + 0.01),
				start_y - r * (cell_size + 0.01),
				0.035
			)
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.set_surface_override_material(0, mat)
			mi.position = pos
			_body_mi.add_child(mi)
			_cell_meshes.append(mi)
			_cell_mats.append(mat)

	# Head
	var head := SphereMesh.new()
	head.radius = 0.08
	head.height = 0.16
	_head_mi = _add_mesh(head, _body_mat, Vector3(0.0, 0.82, 0.0))

	# Legs
	var leg := CylinderMesh.new()
	leg.top_radius = 0.025
	leg.bottom_radius = 0.03
	leg.height = 0.3
	_leg_l = _add_mesh(leg, _body_mat, Vector3(-0.1, 0.15, 0.0))
	_leg_r = _add_mesh(leg, _body_mat, Vector3(0.1, 0.15, 0.0))

	# Label
	_label = Label3D.new()
	_label.text = "Gen: 0 | Alive: 0"
	_label.font_size = 24
	_label.pixel_size = 0.002
	_label.modulate = alive_color
	_label.position = Vector3(0.0, 0.95, 0.06)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mesh_root.add_child(_label)


func _process_visual(delta: float) -> void:
	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		var spd: float = patrol_speed if _state == BaseState.PATROL else chase_speed
		_walk_phase += delta * spd * 4.0
		if _leg_l and _leg_r:
			_leg_l.position.y = 0.15 + sin(_walk_phase) * 0.06
			_leg_r.position.y = 0.15 - sin(_walk_phase) * 0.06

	# CA tick
	var tick: float = ca_tick_rate_chase if _state == BaseState.CHASE else ca_tick_rate
	_ca_timer += delta
	if _ca_timer >= tick:
		_ca_timer = 0.0
		_step_ca()
		_update_cell_visuals()


func _step_ca() -> void:
	var new_grid: Array = []
	for r in range(ca_rows):
		var row: Array = []
		for c in range(ca_cols):
			var neighbors: int = _count_neighbors(r, c)
			var alive: bool = _grid[r][c]
			if alive:
				row.append(neighbors == 2 or neighbors == 3)
			else:
				row.append(neighbors == 3)
		new_grid.append(row)
	_grid = new_grid
	_generation += 1
	_count_alive()

	# If CA dies completely, reinitialize
	if _alive_count == 0:
		_init_grid()


func _count_neighbors(row: int, col: int) -> int:
	var count: int = 0
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			if dr == 0 and dc == 0:
				continue
			var nr: int = row + dr
			var nc: int = col + dc
			if nr >= 0 and nr < ca_rows and nc >= 0 and nc < ca_cols:
				if _grid[nr][nc]:
					count += 1
	return count


func _count_alive() -> void:
	_alive_count = 0
	for r in range(ca_rows):
		for c in range(ca_cols):
			if _grid[r][c]:
				_alive_count += 1


func _update_cell_visuals() -> void:
	for r in range(ca_rows):
		for c in range(ca_cols):
			var idx: int = r * ca_cols + c
			if idx >= _cell_mats.size():
				continue
			var alive: bool = _grid[r][c]
			if alive:
				_cell_mats[idx].albedo_color = alive_color
				_cell_mats[idx].emission_enabled = true
				_cell_mats[idx].emission = emission_alive
				_cell_mats[idx].emission_energy_multiplier = 1.5
			else:
				_cell_mats[idx].albedo_color = dead_color
				_cell_mats[idx].emission_enabled = false

	if _label:
		_label.text = "Gen: %d | Alive: %d" % [_generation, _alive_count]


## Armor effect — alive cells reduce damage taken.
func _on_damaged(amount: float) -> void:
	var armor: float = float(_alive_count) / float(ca_rows * ca_cols)
	var reduced: float = amount * (1.0 - armor * 0.7)
	# Base class already subtracted full amount; add back the difference
	_health += amount - reduced
	if _health > 0.0:
		_set_state(BaseState.STUNNED)
