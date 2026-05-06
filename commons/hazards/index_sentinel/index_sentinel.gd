# @identity
# essence: fire(grid[i][j]) -> traverse(row_major) -- walking 4x4 grid firing cells by array index
# desire: a sentinel attacking in row-major order, each cell lighting before firing -- traversal as combat
# critical_parameter: _current_row / _current_col -- which cell fires next; row-major makes pattern learnable
# triggers: fire_timer advances through [i][j]; cell lights, fires, resets; wraps at grid boundary
# emerges: array indexing as attack pattern -- teaches [i][j] access by making each cell lethal
# needs: HazardCreatureBase [has]; 4x4 cell grid [has]; row-major traversal [has]; cell highlight [has]; VR interaction [missing]
# relationships: embodies array_tutorial sequence; pairs with data_tree_walker (linear vs hierarchical)
# truth: the array attacks in row-major order -- i and j are not abstract, they are targeting coordinates.

extends HazardCreatureBase
class_name IndexSentinel
## Array Tutorial hazard — a walking 4×4 grid that fires cells by [i][j] index.
## Teaches array indexing and traversal through attack patterns.

@export_group("Array")
@export var grid_rows: int = 4
@export var grid_cols: int = 4
@export var cell_size: float = 0.08
@export var cell_gap: float = 0.02
@export var fire_interval: float = 1.5
@export var projectile_speed: float = 6.0

@export_group("Appearance")
@export var body_color: Color = Color(0.2, 0.25, 0.35)
@export var cell_color: Color = Color(0.3, 0.8, 0.4)
@export var active_color: Color = Color(1.0, 0.2, 0.1)
@export var emission_color: Color = Color(0.3, 0.9, 0.5)

# Array state
var _cells: Array[MeshInstance3D] = []
var _cell_materials: Array[StandardMaterial3D] = []
var _current_row: int = 0
var _current_col: int = 0
var _fire_timer: float = 0.0
var _telegraphing: bool = false
var _telegraph_time: float = 0.0
var _body_mesh: MeshInstance3D = null
var _leg_l: MeshInstance3D = null
var _leg_r: MeshInstance3D = null
var _walk_phase: float = 0.0
var _label: Label3D = null

# Materials
var _body_mat: StandardMaterial3D
var _cell_mat: StandardMaterial3D
var _active_mat: StandardMaterial3D


func _on_ready() -> void:
	add_to_group("array_enemy")


func _create_materials() -> void:
	_body_mat = _make_material(body_color)
	_cell_mat = _make_material(cell_color, emission_color * 0.3)
	_active_mat = _make_material(active_color, Color(1.0, 0.3, 0.1), 1.0)
	_active_mat.emission_energy_multiplier = 3.0


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, 0.6, 0.3)
	col.shape = shape
	col.position.y = 0.4
	add_child(col)


func _build_mesh() -> void:
	# Body slab
	var body := BoxMesh.new()
	var grid_w: float = grid_cols * (cell_size + cell_gap)
	var grid_h: float = grid_rows * (cell_size + cell_gap)
	body.size = Vector3(grid_w + 0.06, grid_h + 0.06, 0.04)
	_body_mesh = _add_mesh(body, _body_mat, Vector3(0.0, 0.5, 0.0))

	# Grid cells
	var start_x: float = -(grid_w - cell_size) * 0.5
	var start_y: float = (grid_h - cell_size) * 0.5
	for r in range(grid_rows):
		for c in range(grid_cols):
			var cell_mesh := BoxMesh.new()
			cell_mesh.size = Vector3(cell_size, cell_size, cell_size)
			var mat: StandardMaterial3D = _cell_mat.duplicate()
			var pos := Vector3(
				start_x + c * (cell_size + cell_gap),
				start_y - r * (cell_size + cell_gap),
				0.03
			)
			var mi := MeshInstance3D.new()
			mi.mesh = cell_mesh
			mi.set_surface_override_material(0, mat)
			mi.position = pos
			_body_mesh.add_child(mi)
			_cells.append(mi)
			_cell_materials.append(mat)

	# Legs
	var leg := CylinderMesh.new()
	leg.top_radius = 0.03
	leg.bottom_radius = 0.04
	leg.height = 0.35
	_leg_l = _add_mesh(leg, _body_mat, Vector3(-0.12, 0.17, 0.0))
	_leg_r = _add_mesh(leg, _body_mat, Vector3(0.12, 0.17, 0.0))

	# Index label
	_label = Label3D.new()
	_label.text = "[0][0]"
	_label.font_size = 32
	_label.pixel_size = 0.002
	_label.modulate = Color(1.0, 1.0, 0.3)
	_label.position = Vector3(0.0, 0.95, 0.05)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mesh_root.add_child(_label)


func _process_visual(delta: float) -> void:
	# Walk animation
	_walk_phase += delta * patrol_speed * 4.0
	if _leg_l and _leg_r:
		var swing: float = sin(_walk_phase) * 0.08
		_leg_l.position.y = 0.17 + swing
		_leg_r.position.y = 0.17 - swing

	# Fire timing
	_fire_timer += delta

	if _telegraphing:
		_telegraph_time += delta
		# Flash the active cell
		var idx: int = _current_row * grid_cols + _current_col
		if idx < _cell_materials.size():
			var flash: float = abs(sin(_telegraph_time * 8.0))
			_cell_materials[idx].albedo_color = active_color.lerp(Color.WHITE, flash * 0.5)

		if _telegraph_time >= 0.5:
			_fire_projectile()
			_telegraphing = false
			_advance_index()

	elif _fire_timer >= fire_interval and _state == BaseState.CHASE:
		_telegraphing = true
		_telegraph_time = 0.0
		_fire_timer = 0.0
		_highlight_current_cell()


func _highlight_current_cell() -> void:
	# Reset all cells
	for i in range(_cell_materials.size()):
		_cell_materials[i].albedo_color = cell_color
		if _cell_materials[i].emission_enabled:
			_cell_materials[i].emission = emission_color * 0.3
			_cell_materials[i].emission_energy_multiplier = 1.0

	# Highlight current
	var idx: int = _current_row * grid_cols + _current_col
	if idx < _cell_materials.size():
		_cell_materials[idx].albedo_color = active_color
		_cell_materials[idx].emission_enabled = true
		_cell_materials[idx].emission = Color(1.0, 0.3, 0.1)
		_cell_materials[idx].emission_energy_multiplier = 3.0

	# Update label
	if _label:
		_label.text = "[%d][%d]" % [_current_row, _current_col]


func _fire_projectile() -> void:
	var idx: int = _current_row * grid_cols + _current_col
	if idx >= _cells.size():
		return

	# Create projectile from cell position
	var cell: MeshInstance3D = _cells[idx]
	var spawn_pos: Vector3 = cell.global_position

	var proj := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(cell_size, cell_size, cell_size)
	proj.mesh = mesh
	proj.set_surface_override_material(0, _active_mat.duplicate())

	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(cell_size, cell_size, cell_size)
	col.shape = shape
	area.add_child(col)
	area.collision_layer = 0
	area.collision_mask = 2  # Player layer
	proj.add_child(area)

	get_tree().current_scene.add_child(proj)
	proj.global_position = spawn_pos

	# Direction toward player
	var dir: Vector3 = _get_player_direction()
	dir.y = 0.0
	if dir.length() < 0.01:
		dir = Vector3.FORWARD

	# Animate with tween
	var tween := get_tree().create_tween()
	tween.tween_property(proj, "global_position",
		spawn_pos + dir.normalized() * 8.0, 8.0 / projectile_speed)
	tween.tween_callback(proj.queue_free)

	# Connect area for damage
	area.body_entered.connect(func(body: Node3D) -> void:
		_try_damage_target(body)
		proj.queue_free()
	)

	# Shrink the cell briefly
	cell.scale = Vector3(0.3, 0.3, 0.3)
	var restore := get_tree().create_tween()
	restore.tween_property(cell, "scale", Vector3.ONE, 0.5)

	# Reset cell material
	_cell_materials[idx].albedo_color = cell_color


func _advance_index() -> void:
	_current_col += 1
	if _current_col >= grid_cols:
		_current_col = 0
		_current_row += 1
		if _current_row >= grid_rows:
			_current_row = 0
