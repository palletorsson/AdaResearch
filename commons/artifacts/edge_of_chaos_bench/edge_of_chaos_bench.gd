extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EdgeOfChaosBench

## @identity
## lineage: Langton 1990 "Computation at the Edge of Chaos" -> the lambda parameter ->
##   Wolfram's four classes read as one continuous dial.
## essence: a bench with a lambda dial. Turn it and one CA walks the whole road —
##   frozen order at low lambda, a boiling chaos at high lambda, and between them a narrow
##   band where structures persist only by moving. A readout names the regime; the edge band
##   glows, because only the alive middle is worth the name.
## truth: order and chaos are not two rules but two ends of one knob, and the interesting
##   thing lives in the thin seam between. The edge is the deep — short to seed (one number),
##   costly and irreversible to unfold, computation's only habitat. Randomness smoothed by a
##   rule becomes structure; structure pushed by a rule becomes noise; life is the walk between.

@export var cols: int = 30
@export var rows: int = 30
@export var cell: float = 0.020
@export var step_time: float = 0.12
@export var lambda: float = 0.45          # Langton's lambda — driven by the dial
@export var sweep_seconds: float = 22.0   # time for the dial to traverse 0..1 and back
@export var dead_color: Color = Color(0.05, 0.05, 0.07, 1.0)
@export var order_color: Color = Color(0.45, 0.62, 1.0, 1.0)   # frozen / periodic end
@export var edge_color: Color = Color(0.30, 1.0, 0.65, 1.0)    # the alive band (Class 4)
@export var chaos_color: Color = Color(1.0, 0.42, 0.30, 1.0)   # boiling end

# Edge band: lambda in this window is the sweet spot
const EDGE_LO: float = 0.40
const EDGE_HI: float = 0.58

var _grid: Array = []
var _next: Array = []
var _field: MultiMeshInstance3D
var _dial: Node3D
var _edge_lamp: MeshInstance3D
var _edge_lamp_mat: StandardMaterial3D
var _readout: Label3D
var _accum: float = 0.0
var _sweep: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cols"):
		cols = int(config["cols"])
	if config.has("rows"):
		rows = int(config["rows"])
	if config.has("step_time"):
		step_time = float(config["step_time"])
	if config.has("lambda"):
		lambda = float(config["lambda"])
	if config.has("sweep_seconds"):
		sweep_seconds = float(config["sweep_seconds"])
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


func _blank_grid() -> Array:
	var g: Array = []
	for r: int in range(rows):
		var row: Array = []
		for c: int in range(cols):
			row.append(0)
		g.append(row)
	return g


func _seed_grid() -> void:
	# seed density tracks lambda so the field starts in-character with the dial
	_grid = _blank_grid()
	var p: float = clampf(lambda, 0.05, 0.95)
	for r: int in range(rows):
		for c: int in range(cols):
			_grid[r][c] = 1 if _rng.randf() < p else 0


func _neighbors(g: Array, c: int, r: int) -> int:
	var n: int = 0
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x: int = (c + dx + cols) % cols
			var y: int = (r + dy + rows) % rows
			n += int(g[y][x])
	return n


func _step() -> void:
	# Totalistic outer-sum CA. lambda widens the "stay/born alive" survival window:
	#   low lambda -> only the tightest counts survive (freezes toward order)
	#   high lambda -> almost any count survives (boils toward chaos)
	#   mid lambda  -> Life-like windows that travel: the edge.
	var lo: int = int(round(lerp(2.0, 0.0, clampf(lambda, 0.0, 1.0))))
	var hi: int = int(round(lerp(3.0, 8.0, clampf(lambda, 0.0, 1.0))))
	var born_lo: int = clampi(lo + 1, 1, 8)
	var born_hi: int = clampi(hi, born_lo, 8)
	for r: int in range(rows):
		for c: int in range(cols):
			var n: int = _neighbors(_grid, c, r)
			var alive: bool = _grid[r][c] == 1
			if alive:
				_next[r][c] = 1 if (n >= lo and n <= hi) else 0
			else:
				_next[r][c] = 1 if (n >= born_lo and n <= born_hi) else 0
	var tmp: Array = _grid
	_grid = _next
	_next = tmp


func _regime_color() -> Color:
	# map lambda onto the order -> edge -> chaos colour ramp
	if lambda < EDGE_LO:
		return order_color.lerp(edge_color, clampf(lambda / EDGE_LO, 0.0, 1.0))
	elif lambda > EDGE_HI:
		return edge_color.lerp(chaos_color, clampf((lambda - EDGE_HI) / (1.0 - EDGE_HI), 0.0, 1.0))
	return edge_color


func _regime_name() -> String:
	if lambda < EDGE_LO * 0.6:
		return "FROZEN  (order)"
	elif lambda < EDGE_LO:
		return "PERIODIC"
	elif lambda <= EDGE_HI:
		return "EDGE  (alive)"
	elif lambda < 0.78:
		return "TURBULENT"
	return "CHAOS"


func _paint() -> void:
	var live: Color = _regime_color()
	var mm: MultiMesh = _field.multimesh
	for r: int in range(rows):
		for c: int in range(cols):
			var i: int = r * cols + c
			mm.set_instance_color(i, live if _grid[r][c] == 1 else dead_color)


func _update_indicators() -> void:
	# dial needle angle follows lambda; edge lamp brightens inside the sweet band
	if is_instance_valid(_dial):
		_dial.rotation.z = lerp(2.3, -2.3, clampf(lambda, 0.0, 1.0))
	if is_instance_valid(_edge_lamp_mat):
		var inside: float = 0.0
		if lambda >= EDGE_LO and lambda <= EDGE_HI:
			# 1.0 at the centre of the band, easing to edges
			var t: float = (lambda - EDGE_LO) / (EDGE_HI - EDGE_LO)
			inside = 1.0 - absf(t - 0.5) * 2.0
		_edge_lamp_mat.albedo_color = dead_color.lerp(edge_color, 0.4 + inside * 0.6)
		_edge_lamp_mat.emission = edge_color
		_edge_lamp_mat.emission_energy_multiplier = (0.2 + inside * 2.2) if emissive else 0.0
	if is_instance_valid(_readout):
		_readout.text = "lambda %.2f\n%s" % [lambda, _regime_name()]
		_readout.modulate = _regime_color()


func _build() -> void:
	# --- bench housing ---
	var base_mat := _matte_mat(Color(0.16, 0.17, 0.2), 0.85)
	var steel := _steel_mat(Color(0.45, 0.47, 0.52))
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 0.7), base_mat))
	add_child(_box(Vector3(0, 0.5, -0.12), Vector3(0.12, 0.62, 0.12), steel))
	add_child(_box(Vector3(0, 0.86, 0), Vector3(1.0, 0.04, 0.6), _steel_mat(Color(0.3, 0.32, 0.36))))

	# --- field standing vertical on the bench top, facing +Z ---
	_field = _make_field(cols, rows, cell, true)
	var w: float = cols * cell
	_field.position = Vector3(-w * 0.5, 0.9, 0.04)
	add_child(_field)

	# --- lambda dial on the right of the bench top ---
	_dial = Node3D.new()
	_dial.position = Vector3(0.42, 0.9, 0.22)
	add_child(_dial)
	_dial.add_child(_cylinder(Vector3(0, 0, -0.01), 0.075, 0.02, _steel_mat(Color(0.28, 0.30, 0.34))))
	# needle (points along -Y of the dial body before rotation)
	_dial.add_child(_box(Vector3(0, 0.045, 0.012), Vector3(0.012, 0.09, 0.012), _glow_mat(edge_color, 1.2)))
	# tick marks: order (left), edge (centre), chaos (right)
	_dial.add_child(_sphere(Vector3(-0.085, 0.0, 0.0), 0.012, _glow_mat(order_color, 0.9)))
	_dial.add_child(_sphere(Vector3(0.0, 0.092, 0.0), 0.012, _glow_mat(edge_color, 1.2)))
	_dial.add_child(_sphere(Vector3(0.085, 0.0, 0.0), 0.012, _glow_mat(chaos_color, 0.9)))

	# --- edge lamp: a band that lights when the dial sits in the sweet spot ---
	_edge_lamp_mat = _glow_mat(edge_color, 0.4)
	_edge_lamp = _box(Vector3(-w * 0.5 + w * 0.5, 0.9 + rows * cell + 0.04, 0.04), Vector3(w * 0.5, 0.03, 0.02), _edge_lamp_mat)
	add_child(_edge_lamp)
	add_child(_billboard_label("Class 4 band", Vector3(0, 0.9 + rows * cell + 0.12, 0.05), 12, edge_color))

	# --- regime readout + title ---
	_readout = _billboard_label("", Vector3(0.42, 1.12, 0.22), 16, edge_color)
	add_child(_readout)
	add_child(_billboard_label("EDGE OF CHAOS\nstructure persists only by moving", Vector3(0, 1.6, 0.05), 28, edge_color))

	# --- pre-run so the first frame already shows the pattern in-character ---
	_seed_grid()
	_next = _blank_grid()
	for _i: int in range(30):
		_step()
	_paint()
	_update_indicators()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# slow auto-sweep of the dial across the whole road and back
	_sweep += delta
	var phase: float = fmod(_sweep / maxf(sweep_seconds, 0.5), 1.0)
	# triangle wave 0..1..0 across lambda's useful range
	var tri: float = phase * 2.0 if phase < 0.5 else (1.0 - phase) * 2.0
	lambda = lerp(0.12, 0.85, tri)

	_accum += delta
	while _accum >= step_time:
		_accum -= step_time
		_step()
	_paint()
	_update_indicators()
