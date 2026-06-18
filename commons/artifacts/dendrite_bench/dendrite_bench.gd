extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DendriteBench

## @identity
## lineage: Witten & Sander 1981 diffusion-limited aggregation -> coral, frost, lightning,
##   mineral dendrites, electrodeposits — the universal branch.
## essence: a bench where a coral grows from a single seed. Walkers diffuse in and freeze on
##   contact, and the time they arrived is written into their colour, so the whole history of
##   the growth is legible at once: the violet core is old, the bright rim is the present.
## truth: the dendrite is frozen history — structure as a record that cannot be re-derived,
##   only re-run. Outer tips screen the interior from incoming walkers, so the form races
##   outward and self-organises into branches no one drew. Chance, caught by one local sticking
##   rule, hardens into a shape; the run is the deep, and the colour map is its memory.

@export var grid: int = 40                 # square field side (odd-ish; seed near centre)
@export var cell: float = 0.014
@export var step_time: float = 0.10
@export var grow_per_step: int = 2         # walkers frozen per timer tick (visible accretion)
@export var max_filled_frac: float = 0.30  # reseed when crystal reaches this fill
@export var seed_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var young_color: Color = Color(0.40, 1.0, 0.75, 1.0)   # newest growth (live rim)
@export var mid_color: Color = Color(0.30, 0.70, 1.0, 1.0)     # middle history
@export var old_color: Color = Color(0.70, 0.40, 1.0, 1.0)     # oldest core (violet)
@export var empty_color: Color = Color(0.04, 0.05, 0.09, 1.0)
@export var walker_color: Color = Color(1.0, 0.85, 0.35, 1.0)  # the wandering particle

var _state: Array = []        # 0 empty, 1 frozen
var _age: Array = []          # arrival order (-1 empty)
var _field: MultiMeshInstance3D
var _filled: int = 0
var _max_age: int = 1
var _accum: float = 0.0
var _walk_x: int = 0          # live walker shown so you can SEE it diffusing
var _walk_y: int = 0
var _walk_active: bool = false


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = int(config["grid"])
	if config.has("step_time"):
		step_time = float(config["step_time"])
	for child in get_children():
		child.queue_free()
	_build()


func _make_field(field_cols: int, field_rows: int, field_cell: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(field_cell * 0.88, field_cell * 0.88, field_cell * 0.88)
	mm.mesh = bm
	mm.instance_count = field_cols * field_rows
	for r: int in range(field_rows):
		for c: int in range(field_cols):
			var i: int = r * field_cols + c
			var pos := Vector3(c * field_cell, r * field_cell, 0.0) if plane_xy else Vector3(c * field_cell, 0.0, r * field_cell)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, empty_color)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.7 if emissive else 0.0
	mi.material_override = mat
	return mi


func _reset() -> void:
	_state = []
	_age = []
	for r: int in range(grid):
		var srow: Array = []
		var arow: Array = []
		for c: int in range(grid):
			srow.append(0)
			arow.append(-1)
		_state.append(srow)
		_age.append(arow)
	var mid: int = grid / 2
	_state[mid][mid] = 1
	_age[mid][mid] = 0
	_filled = 1
	_max_age = 1
	_walk_active = false
	var mm: MultiMesh = _field.multimesh
	for i: int in range(grid * grid):
		mm.set_instance_color(i, empty_color)
	_paint_cell(mid, mid)


func _has_frozen_neighbor(c: int, r: int) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var x: int = c + d.x
		var y: int = r + d.y
		if x < 0 or x >= grid or y < 0 or y >= grid:
			continue
		if int(_state[y][x]) == 1:
			return true
	return false


func _spawn_walker() -> void:
	# launch on the border so it must diffuse inward toward the cluster
	var x: int = _rng.randi_range(0, grid - 1)
	var y: int = _rng.randi_range(0, grid - 1)
	if _rng.randf() < 0.5:
		x = 0 if _rng.randf() < 0.5 else grid - 1
	else:
		y = 0 if _rng.randf() < 0.5 else grid - 1
	_walk_x = x
	_walk_y = y
	_walk_active = true


func _grow_one() -> void:
	# one walker random-walks until it sticks; leaves _walk_* on its last position
	if not _walk_active:
		_spawn_walker()
	var budget: int = grid * grid
	while budget > 0:
		budget -= 1
		if int(_state[_walk_y][_walk_x]) == 0 and _has_frozen_neighbor(_walk_x, _walk_y):
			_state[_walk_y][_walk_x] = 1
			_age[_walk_y][_walk_x] = _max_age
			_max_age += 1
			_filled += 1
			_paint_cell(_walk_x, _walk_y)
			_walk_active = false
			return
		var dir: int = _rng.randi_range(0, 3)
		match dir:
			0: _walk_x += 1
			1: _walk_x -= 1
			2: _walk_y += 1
			_: _walk_y -= 1
		_walk_x = (_walk_x + grid) % grid
		_walk_y = (_walk_y + grid) % grid


func _age_color(a: int) -> Color:
	if a <= 0:
		return seed_color
	var t: float = clampf(float(a) / float(max(_max_age - 1, 1)), 0.0, 1.0)
	# two-stop ramp old -> mid -> young across arrival time
	if t < 0.5:
		return old_color.lerp(mid_color, t * 2.0)
	return mid_color.lerp(young_color, (t - 0.5) * 2.0)


func _paint_cell(c: int, r: int) -> void:
	var i: int = r * grid + c
	if int(_state[r][c]) == 1:
		_field.multimesh.set_instance_color(i, _age_color(int(_age[r][c])))
	else:
		_field.multimesh.set_instance_color(i, empty_color)


func _repaint_all() -> void:
	for r: int in range(grid):
		for c: int in range(grid):
			_paint_cell(c, r)


func _show_walker() -> void:
	# tint the live walker's current empty cell so the diffusion is visible
	if not _walk_active:
		return
	if int(_state[_walk_y][_walk_x]) == 0:
		_field.multimesh.set_instance_color(_walk_y * grid + _walk_x, walker_color)


func _build() -> void:
	# --- bench housing ---
	var base_mat := _matte_mat(Color(0.16, 0.17, 0.2), 0.85)
	var steel := _steel_mat(Color(0.45, 0.47, 0.52))
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 0.7), base_mat))
	add_child(_box(Vector3(0, 0.5, -0.12), Vector3(0.12, 0.62, 0.12), steel))
	add_child(_box(Vector3(0, 0.86, 0), Vector3(1.0, 0.04, 0.6), _steel_mat(Color(0.3, 0.32, 0.36))))

	# --- field standing vertical on the bench top, facing +Z ---
	_field = _make_field(grid, grid, cell, true)
	var w: float = grid * cell
	_field.position = Vector3(-w * 0.5, 0.9, 0.04)
	add_child(_field)

	add_child(_billboard_label("DENDRITE GROWTH\nstructure as frozen history", Vector3(0, 1.6, 0.05), 28, young_color))

	# pre-grow so a branching coral already stands on first frame
	_reset()
	var target: int = int(float(grid * grid) * max_filled_frac * 0.65)
	for _i: int in range(target):
		_grow_one()
	_repaint_all()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_time:
		return
	_accum = 0.0
	if float(_filled) >= float(grid * grid) * max_filled_frac:
		_reset()
		var target: int = int(float(grid * grid) * max_filled_frac * 0.65)
		for _i: int in range(target):
			_grow_one()
		_repaint_all()
		return
	for _g: int in range(max(grow_per_step, 1)):
		_grow_one()
	_show_walker()
