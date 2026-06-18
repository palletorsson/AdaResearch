extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BriansBrainDisplay

## @identity
## lineage: Brian's Brain → generative video, the refractory trail as visual signal
## essence: a wall-mounted shimmering display — the dying state smears into trails on a framed screen, a device
## truth: the artwork is the dying, not the living; the run is the deep, the edge of the trail forever alive

@export var cols: int = 40
@export var rows: int = 30
@export var cell: float = 0.03
@export var step_time: float = 0.1
@export var off_color: Color = Color(0.04, 0.04, 0.06, 1.0)
@export var on_color: Color = Color(0.6, 1.0, 0.95, 1.0)
@export var dying_color: Color = Color(0.9, 0.35, 0.6, 1.0)

# states: 0 = OFF, 1 = ON, 2 = DYING
var _grid: Array = []
var _next: Array = []
var _field: MultiMeshInstance3D
var _readout: Label3D
var _accum: float = 0.0
var _gen: int = 0
var _live: int = 0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("step_time"):
		step_time = float(config["step_time"])
	for c in get_children():
		c.queue_free()
	_build()


func _make_field(field_cols: int, field_rows: int, field_cell: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(field_cell * 0.88, field_cell * 0.88, field_cell * 0.88)
	mm.mesh = bm
	mm.instance_count = field_cols * field_rows
	for r in range(field_rows):
		for c in range(field_cols):
			var i := r * field_cols + c
			var pos := Vector3(c * field_cell, r * field_cell, 0.0) if plane_xy else Vector3(c * field_cell, 0.0, r * field_cell)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, off_color)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.9 if emissive else 0.0
	mi.material_override = mat
	return mi


func _blank() -> Array:
	var g: Array = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(0)
		g.append(row)
	return g


func _seed() -> void:
	_grid = _blank()
	# scattered sparks plus a couple of glider-ish seeds for travelling trails
	for _i in range(90):
		var x := _rng.randi_range(0, cols - 1)
		var y := _rng.randi_range(0, rows - 1)
		_grid[y][x] = 1


func _on_neighbors(c: int, r: int) -> int:
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x := (c + dx + cols) % cols
			var y := (r + dy + rows) % rows
			if _grid[y][x] == 1:
				n += 1
	return n


func _step() -> void:
	var live := 0
	for r in range(rows):
		for c in range(cols):
			var s: int = _grid[r][c]
			if s == 1:
				_next[r][c] = 2
			elif s == 2:
				_next[r][c] = 0
			else:
				if _on_neighbors(c, r) == 2:
					_next[r][c] = 1
					live += 1
				else:
					_next[r][c] = 0
	var tmp := _grid
	_grid = _next
	_next = tmp
	_live = live
	_gen += 1
	# reseed if the field dies out so the display never goes dark
	if _gen > 4 and _live == 0:
		var any := false
		for r in range(rows):
			for c in range(cols):
				if _grid[r][c] != 0:
					any = true
					break
			if any:
				break
		if not any:
			_seed()
			_gen = 0


func _paint() -> void:
	var mm := _field.multimesh
	for r in range(rows):
		for c in range(cols):
			var i := r * cols + c
			var s: int = _grid[r][c]
			var col := off_color
			if s == 1:
				col = on_color
			elif s == 2:
				col = dying_color
			mm.set_instance_color(i, col)


func _build() -> void:
	# device: a framed wall screen on a slim stand
	var w := cols * cell
	var h := rows * cell
	var frame_mat := _matte_mat(Color(0.08, 0.08, 0.1), 0.6, 0.2)
	var bezel_mat := _steel_mat(Color(0.35, 0.37, 0.42))
	# stand
	add_child(_box(Vector3(0, 0.05, 0), Vector3(0.5, 0.1, 0.35), _matte_mat(Color(0.13, 0.14, 0.17), 0.8)))
	add_child(_box(Vector3(0, 0.45, 0), Vector3(0.1, 0.7, 0.1), bezel_mat))
	# screen frame, centre at y ~1.25
	var cy := 1.25
	add_child(_box(Vector3(0, cy, -0.05), Vector3(w + 0.18, h + 0.18, 0.1), frame_mat))
	add_child(_box(Vector3(0, cy, 0.0), Vector3(w + 0.06, h + 0.06, 0.04), bezel_mat))
	# dark screen backing (the trails glow against it)
	add_child(_box(Vector3(0, cy, 0.02), Vector3(w, h, 0.02), _matte_mat(Color(0.02, 0.02, 0.03), 1.0)))

	_field = _make_field(cols, rows, cell, true)
	_field.position = Vector3(-w * 0.5, cy - h * 0.5, 0.045)
	add_child(_field)

	add_child(_billboard_label("BRIAN'S BRAIN — DISPLAY", Vector3(0, cy + h * 0.5 + 0.22, 0.05), 22, on_color))
	_readout = _billboard_label("gen 0  ·  live 0", Vector3(0, cy - h * 0.5 - 0.2, 0.05), 16, dying_color)
	add_child(_readout)

	_seed()
	_next = _blank()
	for _i in range(10):
		_step()
	_paint()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	var stepped := false
	while _accum >= step_time:
		_accum -= step_time
		_step()
		stepped = true
	_paint()
	if stepped and _readout != null:
		_readout.text = "gen %d  ·  live %d" % [_gen, _live]
