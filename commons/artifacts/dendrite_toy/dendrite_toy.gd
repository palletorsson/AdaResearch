extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DendriteToy

## @identity
## lineage: Witten & Sander 1981 diffusion-limited aggregation -> frost, coral, soot,
##   electrodeposition, the branching everything.
## essence: a small frost crystal you hold in the hand. Particles random-walk in from the
##   edges and freeze where they touch what is already frozen, so the shape grows outward as
##   a fractal antler of ice. It is never the same twice.
## truth: the branch is frozen history — every twig records the order in which chance arrived.
##   Tips shadow the interior, so growth races outward and hollows out: the form is not designed,
##   it is the residue of a million coin-flips that cannot be replayed any cheaper than living
##   them. Randomness, made to stick by one local rule, becomes structure.

@export var grid: int = 31                 # square field side (odd: seed at centre)
@export var cell: float = 0.012
@export var step_time: float = 0.10
@export var grow_per_step: int = 1         # particles frozen per timer tick
@export var max_filled_frac: float = 0.32  # reseed when the crystal fills this much
@export var seed_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var young_color: Color = Color(0.45, 0.85, 1.0, 1.0)   # newest growth (frost blue)
@export var old_color: Color = Color(0.65, 0.45, 1.0, 1.0)     # oldest growth (violet core)
@export var empty_color: Color = Color(0.05, 0.06, 0.10, 1.0)

var _state: Array = []        # 0 empty, 1 frozen
var _age: Array = []          # arrival order (-1 if empty), used for history colouring
var _field: MultiMeshInstance3D
var _filled: int = 0
var _max_age: int = 1
var _accum: float = 0.0


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
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
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
	# clear field colours
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


func _grow_one() -> void:
	# launch a walker on the bounding ring and random-walk until it touches the cluster
	var x: int = _rng.randi_range(0, grid - 1)
	var y: int = _rng.randi_range(0, grid - 1)
	# bias the launch to the border so it diffuses inward
	if _rng.randf() < 0.5:
		x = 0 if _rng.randf() < 0.5 else grid - 1
	else:
		y = 0 if _rng.randf() < 0.5 else grid - 1
	var budget: int = grid * grid
	while budget > 0:
		budget -= 1
		if int(_state[y][x]) == 0 and _has_frozen_neighbor(x, y):
			_state[y][x] = 1
			_age[y][x] = _max_age
			_max_age += 1
			_filled += 1
			_paint_cell(x, y)
			return
		var dir: int = _rng.randi_range(0, 3)
		match dir:
			0: x += 1
			1: x -= 1
			2: y += 1
			_: y -= 1
		# wrap walkers that wander off, keeps the diffusion alive
		x = (x + grid) % grid
		y = (y + grid) % grid


func _age_color(a: int) -> Color:
	if a <= 0:
		return seed_color
	var t: float = clampf(float(a) / float(max(_max_age - 1, 1)), 0.0, 1.0)
	# newest (t~1) reads young/frost, oldest (t~0) reads violet core
	return old_color.lerp(young_color, t)


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


func _build() -> void:
	# held backing plate, ~0.4m field span, centred on origin (no table)
	var span: float = float(grid) * cell
	add_child(_box(Vector3(0.0, 0.0, -0.012), Vector3(span + 0.04, span + 0.04, 0.012), _matte_mat(Color(0.09, 0.10, 0.13))))

	_field = _make_field(grid, grid, cell, true)
	_field.position = Vector3(-span * 0.5, -span * 0.5, 0.0)
	add_child(_field)

	add_child(_billboard_label("FROST", Vector3(0.0, span * 0.5 + 0.045, 0.0), 13, young_color))

	# pre-grow so a branching crystal already exists on first frame
	_reset()
	var target: int = int(float(grid * grid) * max_filled_frac * 0.7)
	for _i: int in range(target):
		_grow_one()
	# recolour for the final history (max_age grew during the pre-run)
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
		var target: int = int(float(grid * grid) * max_filled_frac * 0.7)
		for _i: int in range(target):
			_grow_one()
		_repaint_all()
		return
	for _g: int in range(max(grow_per_step, 1)):
		_grow_one()
