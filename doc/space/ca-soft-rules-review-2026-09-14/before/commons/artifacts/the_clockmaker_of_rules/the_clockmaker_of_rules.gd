extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheClockmakerOfRules

## @identity
## lineage: the cellular automata SUPER OBJECT — a clockmaker's bench for worlds the
##   engine refuses to supply. On it: a bare GRID of empty pans (space, made
##   countable); three NEIGHBOURHOOD stencils in brass — von Neumann's cross, Moore's
##   square, the hexagon; a RULE drum of eight little levers, the 8 bits of an
##   elementary rule; and the centrepiece, the DOUBLE BUFFER — two identical trays,
##   read-tray and write-tray, with a swap crank between them, because time is the
##   part you must build. Around the bench the built worlds stand: Rule 30's
##   deterministic snowstorm, Rule 90's Sierpinski, a Life field with a real glider
##   mid-flight, Brian's Brain never resting, Langton's ant with its highway, a
##   Wireworld diode, and a Lenia blob with fractional cells. Each is computed here,
##   not drawn.
## essence: Godot ships no CA primitive. A grid, a neighbourhood, a rule, and TIME —
##   and the last one is the whole secret: read the old tray, write the new, then
##   swap. Every world on this bench was stepped by that crank.
## truth: local rules, global patterns — and you must build the clock yourself.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 30
@export var rule: int = 30               # the elementary rule the drum shows and runs
@export_range(8, 24) var gens: int = 18

func _ready() -> void:
	_rng.seed = seed
	_build_bench()
	_build_grid_station()
	_build_stencils()
	_build_rule_drum()
	_build_double_buffer()
	_build_elementary(rule, Vector3(-1.5, 1.02, 0.75), Color(0.95, 0.75, 0.3), "rule %d" % rule, "determinism no shortcut outruns")
	_build_elementary(90, Vector3(-0.35, 1.02, 0.75), Color(0.5, 0.85, 0.95), "rule 90", "the same step, drawn through time: Sierpinski")
	_build_life()
	_build_brains()
	_build_ant()
	_build_wireworld()
	_build_lenia()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "rule", "gens"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- helpers -------------------------------------------------------------------------

func _tag(at: Vector3, title: String, sub: String) -> void:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.17
	tag.position = at
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text(title, sub)

func _cell(at: Vector3, size: float, tint: Color, glow: float = 0.9) -> void:
	var c := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(size, size * 0.35, size)
	c.mesh = m
	c.position = at
	c.material_override = _glow_mat(tint, glow) if glow > 0.0 else _matte_mat(tint, 0.8)
	add_child(c)

# --- the bench and its four stations ---------------------------------------------------

func _build_bench() -> void:
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(4.8, 0.12, 2.4)
	top.mesh = tm
	top.position = Vector3(0.0, 0.94, 0.0)
	top.material_override = _matte_mat(Color(0.15, 0.12, 0.1), 0.82)
	add_child(top)
	for sx in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.14, 0.94, 1.8)
		leg.mesh = lm
		leg.position = Vector3(sx * 2.2, 0.47, 0.0)
		leg.material_override = _matte_mat(Color(0.11, 0.1, 0.11), 0.9)
		add_child(leg)

func _build_grid_station() -> void:
	# space, made countable: empty pans in a lattice, nothing living in them yet
	for iy in range(5):
		for ix in range(5):
			var pan := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.07, 0.012, 0.07)
			pan.mesh = pm
			pan.position = Vector3(-1.95 + 0.085 * float(ix), 1.01, -0.95 + 0.085 * float(iy))
			pan.material_override = _matte_mat(Color(0.35, 0.34, 0.33), 0.7)
			add_child(pan)
	_tag(Vector3(-1.78, 0.98, -0.5), "the grid", "an array of arrays: space, made countable")

func _build_stencils() -> void:
	# three brass stencils: which cells count as NEAR is a choice
	var specs := [
		["von Neumann", [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]],
		["Moore", [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0),
			Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]],
		["hex", [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,1)]],
	]
	for i in range(3):
		var row: Array = specs[i]
		var offsets: Array = row[1]
		var cx := -1.25 + 0.42 * float(i)
		_cell(Vector3(cx, 1.02, -0.9), 0.055, Color(0.95, 0.8, 0.35), 1.4)
		for o in offsets:
			var off: Vector2i = o
			_cell(Vector3(cx + 0.065 * float(off.x), 1.02, -0.9 + 0.065 * float(off.y)), 0.05,
				Color(0.5, 0.55, 0.62), 0.5)
		_tag(Vector3(cx, 0.98, -0.62), str(row[0]), "")
	_tag(Vector3(-0.85, 0.98, -1.18), "the neighbourhood", "'near' is a choice, not a fact")

func _build_rule_drum() -> void:
	# eight levers: the 8 bits of the elementary rule, up for 1, down for 0
	var drum := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.08
	dm.bottom_radius = 0.08
	dm.height = 0.62
	drum.mesh = dm
	drum.rotation.z = PI * 0.5
	drum.position = Vector3(0.35, 1.12, -0.85)
	drum.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(drum)
	for b in range(8):
		var on := (rule >> b) & 1
		var lever := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.012, 0.11, 0.012)
		lever.mesh = lm
		lever.position = Vector3(0.35 - 0.27 + 0.077 * float(b), 1.12 + (0.09 if on else 0.02), -0.78)
		lever.rotation.x = 0.0 if on else deg_to_rad(55.0)
		lever.material_override = _glow_mat(Color(0.95, 0.8, 0.3) if on else Color(0.3, 0.3, 0.34), 0.9 if on else 0.2)
		add_child(lever)
	_tag(Vector3(0.35, 0.98, -0.55), "the rule", "eight bits, and a world falls out")

func _build_double_buffer() -> void:
	# the centrepiece: two trays and a swap crank. Time is the part you must build.
	for i in range(2):
		var tray := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.42, 0.035, 0.3)
		tray.mesh = tm
		tray.position = Vector3(1.35, 1.02, -1.05 + 0.42 * float(i))
		tray.material_override = _matte_mat(Color(0.2, 0.22, 0.26) if i == 0 else Color(0.26, 0.22, 0.2), 0.7)
		add_child(tray)
		# a few cells in the read tray, their successors in the write tray
		var r := RandomNumberGenerator.new()
		r.seed = seed + i
		for k in range(6):
			_cell(Vector3(1.2 + 0.06 * float(k), 1.05, -1.05 + 0.42 * float(i)), 0.045,
				Color(0.5, 0.85, 0.95) if r.randf() < 0.5 else Color(0.15, 0.16, 0.2),
				0.9 if r.randf() < 0.5 else 0.1)
		_tag(Vector3(1.35, 0.98, -1.25 + 0.42 * float(i)), "read" if i == 0 else "write", "")
	var crank := MeshInstance3D.new()
	var cm := TorusMesh.new()
	cm.inner_radius = 0.05
	cm.outer_radius = 0.07
	crank.mesh = cm
	crank.rotation.x = PI * 0.5
	crank.position = Vector3(1.78, 1.06, -0.84)
	crank.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(crank)
	_tag(Vector3(1.78, 0.98, -0.5), "the double buffer", "swap - or every cell lies to its neighbour")

# --- the built worlds ------------------------------------------------------------------

func _build_elementary(rule_no: int, origin: Vector3, tint: Color, title: String, sub: String) -> void:
	# genuinely stepped: a row of 25 cells, run `gens` generations by the rule's bits
	var w := 25
	var cur := []
	cur.resize(w)
	for i in range(w):
		cur[i] = 0
	cur[w / 2] = 1
	for g in range(gens):
		for i in range(w):
			if cur[i] == 1:
				_cell(origin + Vector3((float(i) - float(w) * 0.5) * 0.036, 0.0, float(g) * 0.036),
					0.032, tint, 1.0)
		var nxt := []
		nxt.resize(w)
		for i in range(w):
			var l: int = cur[(i - 1 + w) % w]
			var c: int = cur[i]
			var rr: int = cur[(i + 1) % w]
			var idx := (l << 2) | (c << 1) | rr
			nxt[i] = (rule_no >> idx) & 1
		cur = nxt                                  # THE SWAP - the crank, in code
	_tag(origin + Vector3(0.0, -0.04, -0.12), title, sub)

func _build_life() -> void:
	# a real glider, stepped four generations so it has visibly moved
	var W := 9
	var grid := []
	for y in range(W):
		var row := []
		for x in range(W):
			row.append(0)
		grid.append(row)
	for p in [Vector2i(1,0), Vector2i(2,1), Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)]:
		grid[p.y][p.x] = 1
	for step in range(4):
		var nxt := []
		for y in range(W):
			var row := []
			for x in range(W):
				var n := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						n += int(grid[(y + dy + W) % W][(x + dx + W) % W])
				var alive: int = grid[y][x]
				row.append(1 if (alive == 1 and (n == 2 or n == 3)) or (alive == 0 and n == 3) else 0)
			nxt.append(row)
		grid = nxt
	for y in range(W):
		for x in range(W):
			var on: int = grid[y][x]
			_cell(Vector3(0.8 + float(x) * 0.05, 1.02, 0.55 + float(y) * 0.05), 0.044,
				Color(0.55, 0.95, 0.6) if on == 1 else Color(0.16, 0.18, 0.2), 1.1 if on == 1 else 0.08)
	_tag(Vector3(1.0, 0.98, 1.05), "Life", "born on 3, live on 2 or 3 - a glider, four steps on")

func _build_brains() -> void:
	# Brian's Brain: three states, and the field never rests
	var r := RandomNumberGenerator.new()
	r.seed = seed
	for y in range(7):
		for x in range(7):
			var st := r.randi_range(0, 2)
			var brain_tints := [Color(0.16, 0.18, 0.2), Color(0.95, 0.95, 0.9), Color(0.35, 0.45, 0.95)]
			var tint: Color = brain_tints[st]
			_cell(Vector3(1.72 + float(x) * 0.05, 1.02, 0.55 + float(y) * 0.05), 0.044, tint,
				1.2 if st > 0 else 0.08)
	_tag(Vector3(1.87, 0.98, 1.0), "Brian's Brain", "a dying state, and it never rests")

func _build_ant() -> void:
	# Langton's ant, genuinely run: 220 steps, its highway emerging from chaos
	var W := 21
	var cells := {}
	var pos := Vector2i(W / 2, W / 2)
	var dir := 0
	for step in range(220):
		var black: bool = cells.get(pos, false)
		dir = (dir + (1 if not black else 3)) % 4
		cells[pos] = not black
		var steps := [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]
		var d: Vector2i = steps[dir]
		pos += d
		pos.x = clampi(pos.x, 0, W - 1)
		pos.y = clampi(pos.y, 0, W - 1)
	for key in cells:
		if cells[key]:
			var k: Vector2i = key
			_cell(Vector3(-1.95 + float(k.x) * 0.028, 1.02, 0.35 + float(k.y) * 0.028), 0.024,
				Color(0.9, 0.55, 0.35), 0.9)
	_cell(Vector3(-1.95 + float(pos.x) * 0.028, 1.05, 0.35 + float(pos.y) * 0.028), 0.03, Color(0.95, 0.2, 0.15), 2.0)
	_tag(Vector3(-1.66, 0.98, 1.05), "Langton's ant", "two rules, and a highway out of chaos")

func _build_wireworld() -> void:
	# a diode: conductor, head, tail - four states make logic
	var path := [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0),
		Vector2i(4,1), Vector2i(4,2), Vector2i(3,2), Vector2i(2,2)]
	for i in range(path.size()):
		var p: Vector2i = path[i]
		var tint := Color(0.85, 0.7, 0.25)
		var glow := 0.5
		if i == 2:
			tint = Color(0.35, 0.6, 1.0)
			glow = 1.8
		elif i == 1:
			tint = Color(0.9, 0.35, 0.3)
			glow = 1.4
		_cell(Vector3(0.35 + float(p.x) * 0.05, 1.02, 0.6 + float(p.y) * 0.05), 0.044, tint, glow)
	_tag(Vector3(0.45, 0.98, 0.78), "Wireworld", "four states: wires, and wires make logic")

func _build_lenia() -> void:
	# continuous CA: cells are fractions, so the glider has a soft body
	for y in range(9):
		for x in range(9):
			var dx := float(x) - 4.0
			var dy := float(y) - 4.0
			var d := sqrt(dx * dx + dy * dy)
			var v: float = clampf(1.0 - absf(d - 2.2) / 2.0, 0.0, 1.0)
			if v > 0.02:
				_cell(Vector3(-0.9 + float(x) * 0.042, 1.02, -0.05 + float(y) * 0.042), 0.038,
					Color(0.6, 0.35, 0.9) * (0.3 + 0.7 * v), 0.4 + 1.2 * v)
	_tag(Vector3(-0.72, 0.98, 0.4), "Lenia", "fractions, not bits - the glider grows a body")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ClockmakerPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-2.45, 0.24, 1.2)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE CLOCKMAKER OF RULES",
			"The engine ships no cellular automaton. Four things must be built: a grid,\na neighbourhood, a rule - and TIME, the two trays and the crank between them.\nEvery world on this bench was stepped by that swap: Rule 30's snowstorm,\nRule 90's Sierpinski, a glider four generations on, an ant's highway.")
