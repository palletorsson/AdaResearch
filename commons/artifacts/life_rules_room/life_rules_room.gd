extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LifeRulesRoom

## @identity
## lineage: life-like cellular automata → the B/S rule family (Conway, HighLife, Seeds, Day&Night)
## essence: a room of four wall panels, same seed, four different birth/survival rules diverging
## truth: B3/S23 was never a law — change two digits and you get another world; each rule a contingent universe, the run the deep

@export var cols: int = 40
@export var rows: int = 40
@export var cell: float = 0.075
@export var step_time: float = 0.16
@export var dead_color: Color = Color(0.05, 0.05, 0.07, 1.0)

var _panels: Array = []  # each: {grid, next, field, born:Array, survive:Array, color:Color}
var _accum: float = 0.0


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
			mm.set_instance_color(i, dead_color)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
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


func _seed_grid() -> Array:
	# deterministic shared seed: a soup blob in the centre
	var g := _blank()
	var seed_rng := RandomNumberGenerator.new()
	seed_rng.seed = 13371
	var cx := cols / 2
	var cy := rows / 2
	for r in range(cy - 8, cy + 8):
		for c in range(cx - 8, cx + 8):
			g[r][c] = 1 if seed_rng.randf() < 0.42 else 0
	return g


func _neighbors(g: Array, c: int, r: int) -> int:
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x := (c + dx + cols) % cols
			var y := (r + dy + rows) % rows
			n += int(g[y][x])
	return n


func _step_panel(p: Dictionary) -> void:
	var g: Array = p["grid"]
	var nx: Array = p["next"]
	var born: Array = p["born"]
	var survive: Array = p["survive"]
	for r in range(rows):
		for c in range(cols):
			var n := _neighbors(g, c, r)
			if g[r][c] == 1:
				nx[r][c] = 1 if survive.has(n) else 0
			else:
				nx[r][c] = 1 if born.has(n) else 0
	p["grid"] = nx
	p["next"] = g


func _paint_panel(p: Dictionary) -> void:
	var g: Array = p["grid"]
	var col: Color = p["color"]
	var mm: MultiMesh = (p["field"] as MultiMeshInstance3D).multimesh
	for r in range(rows):
		for c in range(cols):
			var i := r * cols + c
			mm.set_instance_color(i, col if g[r][c] == 1 else dead_color)


func _add_panel(rule_name: String, born: Array, survive: Array, col: Color, origin: Vector3, basis: Basis) -> void:
	var field := _make_field(cols, rows, cell, true)
	var node := Node3D.new()
	node.transform = Transform3D(basis, origin)
	var w := cols * cell
	# backing board
	var board := _box(Vector3(w * 0.5, w * 0.5, -0.06), Vector3(w + 0.3, w + 0.3, 0.08), _matte_mat(Color(0.1, 0.11, 0.14), 0.9))
	node.add_child(board)
	node.add_child(field)
	node.add_child(_billboard_label(rule_name, Vector3(w * 0.5, w + 0.45, 0.0), 24, col))
	add_child(node)
	var p := {
		"grid": _seed_grid(),
		"next": _blank(),
		"field": field,
		"born": born,
		"survive": survive,
		"color": col,
	}
	# pre-run so first frame already diverged
	for _i in range(8):
		_step_panel(p)
	_paint_panel(p)
	_panels.append(p)


func _build() -> void:
	# room floor 7x7
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7, 0.1, 7), _matte_mat(Color(0.12, 0.12, 0.15), 0.95)))

	var wall := 3.3
	var span := cols * cell  # ~3m
	var off := -span * 0.5

	# four panels on four walls, fields facing inward
	# +Z wall (north), faces -Z toward centre
	_add_panel("Conway B3/S23", [3], [2, 3], Color(0.4, 1.0, 0.55),
		Vector3(off, 0.4, -wall), Basis())
	# -Z wall (south), faces +Z
	_add_panel("HighLife B36/S23", [3, 6], [2, 3], Color(1.0, 0.6, 0.3),
		Vector3(-off, 0.4, wall), Basis(Vector3.UP, PI))
	# +X wall (east), faces -X
	_add_panel("Seeds B2/S", [2], [], Color(0.55, 0.7, 1.0),
		Vector3(wall, 0.4, -off), Basis(Vector3.UP, -PI * 0.5))
	# -X wall (west), faces +X
	_add_panel("Day&Night B3678/S34678", [3, 6, 7, 8], [3, 4, 6, 7, 8], Color(0.9, 0.5, 1.0),
		Vector3(-wall, 0.4, off), Basis(Vector3.UP, PI * 0.5))

	add_child(_billboard_label("LIFE-LIKE RULES\na family, not a law", Vector3(0, 3.6, 0), 40, Color(0.92, 0.94, 1.0)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	while _accum >= step_time:
		_accum -= step_time
		for p in _panels:
			_step_panel(p)
	for p in _panels:
		_paint_panel(p)
