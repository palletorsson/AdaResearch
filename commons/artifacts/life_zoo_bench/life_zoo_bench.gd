extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LifeZooBench

## @identity
## lineage: Conway's Life taxonomy → still lifes, oscillators, spaceships
## essence: a Life field showing the named zoo — a block, a blinker, a glider, placed apart and tinted
## truth: from one law three behaviours — stillness, pulse, travel; the run is the deep, each creature alive at the edge

@export var cols: int = 30
@export var rows: int = 22
@export var cell: float = 0.022
@export var step_time: float = 0.14
@export var dead_color: Color = Color(0.05, 0.05, 0.07, 1.0)
@export var still_color: Color = Color(0.45, 0.7, 1.0, 1.0)
@export var osc_color: Color = Color(1.0, 0.75, 0.3, 1.0)
@export var ship_color: Color = Color(0.4, 1.0, 0.55, 1.0)
## What the zoo shows of the cells NOBODY lives in. A Life exhibit paints twelve live
## cells and leaves six hundred and forty-eight dark, which quietly says the empty
## lattice is scenery — but the rule runs there too, and the named creatures are the
## handful of the state space anyone bothered to name.
##   void    — the vacancy is unlit, indistinguishable from the room behind the bench.
##   lattice — every site is a dim grey block: the state space is discrete, and mostly
##             empty. The creatures sit ON something.
##   census  — each empty site is tinted by its live-neighbour count, and the sites with
##             exactly three go hot: those are the cells about to be born. The law is
##             drawn where nothing is happening yet.
##   wake    — every site that has EVER been alive keeps a stain in that creature's
##             colour. The block leaves four cells, the blinker a smudge, the glider a
##             diagonal streak across the plate: a long exposure of a still photograph.
## Default `void` paints exactly what it painted before.
@export_enum("void", "lattice", "census", "wake") var vacancy: String = "void"

var _grid: Array = []
var _tag: Array = []
var _next: Array = []
var _ntag: Array = []
var _field: MultiMeshInstance3D
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	vacancy = _norm_vacancy(vacancy)
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("step_time"):
		step_time = float(config["step_time"])
	if config.has("vacancy"):
		vacancy = _norm_vacancy(str(config["vacancy"]))
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
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi


func _blank(fill: int) -> Array:
	var g: Array = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(fill)
		g.append(row)
	return g


func _place(pts: Array, ox: int, oy: int, tag: int) -> void:
	for p: Vector2i in pts:
		var x: int = (p.x + ox) % cols
		var y: int = (p.y + oy) % rows
		_grid[y][x] = 1
		_tag[y][x] = tag


func _seed() -> void:
	_grid = _blank(0)
	_tag = _blank(0)
	# block (still life) — tag 1, left
	_place([Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], 4, 9, 1)
	# blinker (oscillator) — tag 2, middle
	_place([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], 14, 10, 2)
	# glider (spaceship) — tag 3, right, travels
	_place([Vector2i(1, 0), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)], 22, 2, 3)


func _neighbors(c: int, r: int) -> int:
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x := (c + dx + cols) % cols
			var y := (r + dy + rows) % rows
			n += int(_grid[y][x])
	return n


func _dominant_tag(c: int, r: int) -> int:
	# inherit colour from the most-common live neighbour tag
	var counts := {1: 0, 2: 0, 3: 0}
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x := (c + dx + cols) % cols
			var y := (r + dy + rows) % rows
			if _grid[y][x] == 1:
				var t: int = _tag[y][x]
				if counts.has(t):
					counts[t] += 1
	var best := 3
	var bn := -1
	for k in counts:
		if counts[k] > bn:
			bn = counts[k]
			best = k
	return best


func _step() -> void:
	for r in range(rows):
		for c in range(cols):
			var n := _neighbors(c, r)
			var alive: bool = _grid[r][c] == 1
			if alive:
				if n == 2 or n == 3:
					_next[r][c] = 1
					_ntag[r][c] = _tag[r][c]
				else:
					_next[r][c] = 0
					_ntag[r][c] = 0
			else:
				if n == 3:
					_next[r][c] = 1
					_ntag[r][c] = _dominant_tag(c, r)
				else:
					_next[r][c] = 0
					_ntag[r][c] = 0
	var tg := _grid
	_grid = _next
	_next = tg
	var tt := _tag
	_tag = _ntag
	_ntag = tt
	# Appended, and only when something is going to read it: the wake needs a record of
	# every cell that has ever been alive, and `void` must not pay for it.
	if vacancy == "wake":
		_mark_seen()


func _color_for(tag: int) -> Color:
	match tag:
		1:
			return still_color
		2:
			return osc_color
		_:
			return ship_color


func _paint() -> void:
	var mm := _field.multimesh
	for r in range(rows):
		for c in range(cols):
			var i := r * cols + c
			mm.set_instance_color(i, _color_for(_tag[r][c]) if _grid[r][c] == 1 else _dead_color_at(c, r))


func _build() -> void:
	var base_mat := _matte_mat(Color(0.16, 0.17, 0.2), 0.85)
	var steel := _steel_mat(Color(0.45, 0.47, 0.52))
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 0.7), base_mat))
	add_child(_box(Vector3(0, 0.5, -0.12), Vector3(0.12, 0.62, 0.12), steel))
	add_child(_box(Vector3(0, 0.86, 0), Vector3(1.0, 0.04, 0.6), _steel_mat(Color(0.3, 0.32, 0.36))))

	_field = _make_field(cols, rows, cell, true)
	var w := cols * cell
	_field.position = Vector3(-w * 0.5, 0.9, 0.04)
	add_child(_field)

	add_child(_billboard_label("THE LIFE ZOO", Vector3(0, 1.6, 0.05), 30, Color(0.9, 0.92, 1.0)))
	var ly := 1.42
	add_child(_billboard_label("still", Vector3(-w * 0.30, ly, 0.06), 16, still_color))
	add_child(_billboard_label("pulse", Vector3(0.0, ly, 0.06), 16, osc_color))
	add_child(_billboard_label("travel", Vector3(w * 0.28, ly, 0.06), 16, ship_color))

	_seed()
	_next = _blank(0)
	_ntag = _blank(0)
	for _i in range(4):
		_step()
	_paint()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	while _accum >= step_time:
		_accum -= step_time
		_step()
	_paint()


# ═══════════════════════════════════════════════════════════════════════════
# VACANCY — what the zoo shows of the cells nobody lives in
# ═══════════════════════════════════════════════════════════════════════════
#
# The plate is 660 sites and twelve of them are alive. A zoo that paints only the
# twelve is making a claim without noticing: that the empty lattice is backdrop.
# It is not. The rule is evaluated at every site every generation, the birth
# condition fires in the vacancy, and the three named creatures are simply the
# corner of the state space somebody bothered to name. Each value below is a true
# statement about the same automaton — only the default is silent about it.
#
# Appended whole; `void` returns dead_color and nothing above this line moved.

const VACANCY_VALUES: PackedStringArray = ["void", "lattice", "census", "wake"]
## The discrete site, lit just enough to be a thing rather than a gap.
const LATTICE_COLOR: Color = Color(0.19, 0.20, 0.24, 1.0)
## Neighbour-count ramp: nothing nearby, something nearby, and exactly-three.
const CENSUS_COLD: Color = Color(0.10, 0.11, 0.14, 1.0)
const CENSUS_WARM: Color = Color(0.22, 0.30, 0.42, 1.0)
const CENSUS_BIRTH: Color = Color(0.88, 0.32, 0.74, 1.0)

## Every site that has ever held a live cell, by creature tag. Built lazily, so a
## bench left at `void` never allocates it.
var _seen: Array = []


## An unknown word keeps the DEFAULT — a typo in a map token is inert, never a crash.
func _norm_vacancy(v: String) -> String:
	var s: String = v.strip_edges().to_lower()
	return s if VACANCY_VALUES.has(s) else "void"


func _mark_seen() -> void:
	if _seen.size() != rows:
		_seen = _blank(0)
	for r in range(rows):
		for c in range(cols):
			if _grid[r][c] == 1:
				_seen[r][c] = _tag[r][c]


## The colour of an empty site. `void` returns exactly what the bench returned before.
func _dead_color_at(c: int, r: int) -> Color:
	match vacancy:
		"lattice":
			return LATTICE_COLOR
		"census":
			var n: int = _neighbors(c, r)
			if n == 3:
				# Three live neighbours and no cell: this site is alive next tick.
				return CENSUS_BIRTH
			if n <= 0:
				return CENSUS_COLD
			return CENSUS_COLD.lerp(CENSUS_WARM, clampf(float(n) / 8.0, 0.0, 1.0))
		"wake":
			if _seen.size() == rows:
				var t: int = int(_seen[r][c])
				if t > 0:
					return _color_for(t).darkened(0.62)
	return dead_color
