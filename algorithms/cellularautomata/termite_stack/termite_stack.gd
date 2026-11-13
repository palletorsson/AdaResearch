extends Node3D
## THE TERMITE STACK (floor CA_AgentsCircuits; Palle, 2026-11-12: "is there a way to turn cellular automata into
## termite stack ... use termites to work as cellular automata worker in y ... other prefabs so the levels are not
## just boxes ... cellular automata as instruction to make complex forms")
##
## A cellular automaton with one worker. Every cell of a lattice carries a STACK. A termite stands on a cell, reads
## how high the stack under it is, turns as the instruction says for that height, adds one unit, and steps on. A
## stack that is full falls to nothing. That is Langton's ant with as many colours as the instruction has letters
## (a turmite), and here the colour is not paint: it is matter, piled in y.
##
## THE INSTRUCTION IS THE FORM. `rule` names a string of turns, one for each height, and nothing else about the form
## is written anywhere:
##   mound      L L R R                    square lattice  a closed, mirror-symmetric mound
##   lace       R1 L1                      hexagonal       an open symmetric lace of single columns
##   city       L R R R R R L L R          square          a walled plateau with a dense core
##   terraces   R R L L L R L L L R R R    square          stepped ground, twelve heights
##   weave      L1 L1 R1 R1                hexagonal       two leaning triangles of thread
## Each runs for the number of steps at which its form first reaches the field's edge (measured on the bench before
## it was built), is held, falls, and the next instruction begins.
##
## NOT JUST BOXES. `unit` is what a level is made of: hex (a hexagonal prism), drum, block or spire. A stack is one
## column drawn once; the seams between its units are drawn by the shader, so a tall field costs what a flat one does.
const RULES := {
	"mound": {"lattice": "square", "turns": ["L", "L", "R", "R"], "steps": 42800},
	"lace": {"lattice": "hex", "turns": ["R1", "L1"], "steps": 3500},
	"city": {"lattice": "square", "turns": ["L", "R", "R", "R", "R", "R", "L", "L", "R"], "steps": 21500},
	"terraces": {"lattice": "square", "turns": ["R", "R", "L", "L", "L", "R", "L", "L", "L", "R", "R", "R"], "steps": 8100},
	"weave": {"lattice": "hex", "turns": ["L1", "L1", "R1", "R1"], "steps": 6900},
}
const ORDER: PackedStringArray = ["mound", "lace", "city", "terraces", "weave"]
const SQUARE: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const HEX: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]
const TURN := {"L": -1, "R": 1, "R1": -1, "L1": 1}
const HALF := 20                                 # the field reaches this many cells from its middle

@export_enum("mound", "lace", "city", "terraces", "weave") var rule := "mound"
@export_enum("hex", "drum", "block", "spire") var unit := "hex"
@export var field := 5.6                         ## metres across (a playground slot's smaller side, less a margin)
@export var tallest := 2.4                       ## the height of a full stack, metres, whatever the instruction
@export var lift := 0.0                          ## the stacks stand this far above the work's origin (a deck's tiles)
@export var stand_out := 0.0                     ## the board and the plates stand this far from the middle; 0 = a metre past the field
@export var build_seconds := 75.0                ## how long a form takes to build
@export var hold_seconds := 40.0                 ## how long it stands before it falls
@export var cycle := true                        ## after a form falls, the next instruction; false: the same again
@export var build_at_once := false               ## the whole form in _ready (a bench or a still)

var _lattice := "square"
var _turns: PackedInt32Array = PackedInt32Array()
var _dirs: Array[Vector2i] = SQUARE
var _budget := 0
var _n := 2
var _side := 2 * HALF + 1
var _heights := PackedByteArray()
var _slot := PackedInt32Array()                  # cell -> instance, -1 off the field
var _places := PackedVector3Array()              # instance -> where its column stands
var _columns: MultiMesh
var _worker: MeshInstance3D
var _board: Label3D
var _at := Vector2i.ZERO
var _heading := 0
var _step := 0
var _owed := 0.0
var _phase := "build"                            # build | hold | fall
var _clock := 0.0
var _pitch := 0.1
var _pressed := -10.0
var _now := 0.0
var _spent_usec := 0
var _frames := 0


func _ready() -> void:
	for key in ["rule", "unit", "tallest", "cycle", "build_seconds", "hold_seconds", "slot_size", "lift", "stand_out"]:
		if has_meta("config_" + key): apply_grid_config({key: get_meta("config_" + key)})
	_begin(rule)
	if build_at_once: finish()


func apply_grid_config(config_data: Dictionary) -> void:
	var again := false
	if config_data.has("rule") and RULES.has(str(config_data["rule"])) and str(config_data["rule"]) != rule: rule = str(config_data["rule"]); again = true
	if config_data.has("unit") and str(config_data["unit"]) in ["hex", "drum", "block", "spire"] and str(config_data["unit"]) != unit: unit = str(config_data["unit"]); again = true
	if config_data.has("tallest"): tallest = float(config_data["tallest"]); again = true
	if config_data.has("lift"): lift = float(config_data["lift"]); again = true
	if config_data.has("cycle"): cycle = str(config_data["cycle"]).to_lower() in ["true", "1", "yes"]
	if config_data.has("build_seconds"): build_seconds = maxf(1.0, float(config_data["build_seconds"]))
	if config_data.has("hold_seconds"): hold_seconds = maxf(0.0, float(config_data["hold_seconds"]))
	if config_data.has("stand_out"): stand_out = float(str(config_data["stand_out"])); again = true
	if config_data.has("slot_size") and config_data["slot_size"] is Array and (config_data["slot_size"] as Array).size() == 2:
		field = minf(float(config_data["slot_size"][0]), float(config_data["slot_size"][1])) - 0.4; again = true
	if again and is_inside_tree() and _columns != null:
		_begin(rule)
		if build_at_once: finish()


func _cell(at: Vector2i) -> int:
	return (at.x + HALF) + (at.y + HALF) * _side


func _on_field(at: Vector2i) -> bool:
	if _lattice == "square": return absi(at.x) <= HALF and absi(at.y) <= HALF
	return maxi(maxi(absi(at.x), absi(at.y)), absi(at.x + at.y)) <= HALF


func _where(at: Vector2i) -> Vector3:
	if _lattice == "square": return Vector3(float(at.x) * _pitch, lift, float(at.y) * _pitch)
	return Vector3((float(at.x) + float(at.y) * 0.5) * _pitch, lift, float(at.y) * _pitch * 0.8660254)


func _unit_mesh() -> Mesh:
	var across: float = _pitch * 0.94
	if unit == "block":
		var box := BoxMesh.new()
		box.size = Vector3(across, 1.0, across)
		return box
	var round := CylinderMesh.new()
	round.height = 1.0
	round.radial_segments = 14 if unit == "drum" else 6
	round.rings = 1
	# a hexagonal prism's flats face its six neighbours on the hexagonal lattice and fill the cell on the square one
	var radius: float = across * 0.5 if unit == "drum" else (across * 0.5 / 0.8660254 if _lattice == "hex" else across * 0.5)
	round.bottom_radius = radius
	round.top_radius = radius * (0.38 if unit == "spire" else 1.0)
	return round


## A new instruction on an empty field.
func _begin(which: String) -> void:
	rule = which
	var spec: Dictionary = RULES[rule]
	_lattice = str(spec.lattice)
	_dirs = SQUARE if _lattice == "square" else HEX
	_turns = PackedInt32Array()
	for letter in spec.turns: _turns.append(int(TURN[letter]))
	_n = _turns.size()
	_budget = int(spec.steps)
	_pitch = field / float(_side)
	_heights = PackedByteArray()
	_heights.resize(_side * _side)
	_slot = PackedInt32Array()
	_slot.resize(_side * _side)
	_places = PackedVector3Array()
	for r in range(-HALF, HALF + 1):
		for q in range(-HALF, HALF + 1):
			var at := Vector2i(q, r)
			if _on_field(at):
				_slot[_cell(at)] = _places.size()
				_places.append(_where(at))
			else:
				_slot[_cell(at)] = -1
	if _columns == null: _furnish()
	_columns.instance_count = 0
	_columns.mesh = _unit_mesh()
	_columns.instance_count = _places.size()
	for i in _places.size(): _draw(i, 0)
	_at = Vector2i.ZERO
	_heading = 0
	_step = 0
	_owed = 0.0
	_phase = "build"
	_clock = 0.0
	_seat_worker()
	_write()


func _furnish() -> void:
	var look := Shader.new()
	look.code = """
shader_type spatial;
varying float v_along;
varying float v_units;
void vertex() {
	v_along = VERTEX.y + 0.5;
	v_units = INSTANCE_CUSTOM.x;
}
void fragment() {
	float k = v_along * v_units;
	float near = min(fract(k), 1.0 - fract(k));
	float seam = (1.0 - smoothstep(0.0, 0.05, near)) * step(0.5, v_units - 0.5);
	float level = floor(min(k, v_units - 0.001));
	vec3 tone = COLOR.rgb * mix(0.55, 1.0, (level + 1.0) / max(v_units, 1.0));
	ALBEDO = mix(tone, vec3(0.05, 0.04, 0.07), seam * 0.85);
	EMISSION = tone * 0.22;
	ROUGHNESS = 0.55;
}
"""
	_columns = MultiMesh.new()
	_columns.transform_format = MultiMesh.TRANSFORM_3D
	_columns.use_colors = true
	_columns.use_custom_data = true
	var mat := ShaderMaterial.new()
	mat.shader = look
	var inst := MultiMeshInstance3D.new()
	inst.name = "Stacks"
	inst.multimesh = _columns
	inst.material_override = mat
	inst.custom_aabb = AABB(Vector3(-field * 0.55, -0.1, -field * 0.55), Vector3(field * 1.1, tallest + 0.5, field * 1.1))
	add_child(inst)
	_worker = MeshInstance3D.new()
	_worker.name = "Termite"
	var ball := SphereMesh.new()
	ball.radius = 0.085
	ball.height = 0.17
	_worker.mesh = ball
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.86, 0.25)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.8, 0.2)
	glow.emission_energy_multiplier = 2.5
	_worker.material_override = glow
	add_child(_worker)
	# what it says, and two plates, outside the yard on the side toward the middle of the floor
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	var out: float = stand_out if stand_out > 0.0 else field * 0.5 + 1.0
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(out + 0.1, 0, -field * 0.5 - 0.3)
	stand.rotation.y = 0.5
	add_child(stand)
	var panel := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(2.1, 1.2, 0.06)
	panel.mesh = slab
	panel.material_override = dark
	panel.position.y = 1.3
	stand.add_child(panel)
	var post := MeshInstance3D.new()
	var leg := BoxMesh.new()
	leg.size = Vector3(0.12, 0.72, 0.06)
	post.mesh = leg
	post.material_override = dark
	post.position.y = 0.36
	stand.add_child(post)
	_board = Label3D.new()
	_board.pixel_size = 0.0022
	_board.font_size = 30
	_board.line_spacing = 2.0
	_board.modulate = Color(0.88, 0.94, 1.0)
	_board.outline_size = 4
	_board.outline_modulate = Color(0, 0, 0, 1)
	_board.width = 900
	_board.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board.position = Vector3(0, 1.3, 0.035)
	stand.add_child(_board)
	var pad := BoxMesh.new()
	pad.size = Vector3(0.7, 0.03, 0.7)
	var press := BoxShape3D.new()
	press.size = Vector3(0.6, 1.0, 0.6)
	for entry in [["NEXT\nINSTRUCTION", -0.9, 0], ["BUILD\nAGAIN", 0.9, 1]]:
		var plate := MeshInstance3D.new()
		plate.mesh = pad
		plate.material_override = dark
		plate.position = Vector3(out, 0.015, float(entry[1]))
		add_child(plate)
		var word := Label3D.new()
		word.text = str(entry[0])
		word.pixel_size = 0.003
		word.font_size = 36
		word.modulate = Color(1.0, 0.82, 0.16)
		word.rotation_degrees = Vector3(-90, 90, 0)
		word.position = plate.position + Vector3(0, 0.02, 0)
		add_child(word)
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 0xFFFFFFFF
		var area_shape := CollisionShape3D.new()
		area_shape.shape = press
		area_shape.position.y = 0.5
		area.add_child(area_shape)
		area.position = plate.position
		var which: int = int(entry[2])
		area.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBody3D: press_plate(which))
		add_child(area)


func _colour(h: int) -> Color:
	var t: float = float(h) / float(maxi(1, _n - 1))
	return Color("5bcefa").lerp(Color("ffffff"), t * 2.0) if t < 0.5 else Color("ffffff").lerp(Color("f5a9b8"), t * 2.0 - 1.0)


## One column to a height in units, 0 hides it. `shrink` is the fall.
func _draw(instance: int, h: int, shrink := 1.0) -> void:
	var tall: float = tallest * float(h) / float(maxi(1, _n - 1)) * shrink
	var at: Vector3 = _places[instance]
	if h <= 0 or tall < 0.002:
		_columns.set_instance_transform(instance, Transform3D(Basis().scaled(Vector3.ZERO), at))
		return
	var turned := Basis(Vector3.UP, PI / 6.0) if (unit != "block" and unit != "drum" and _lattice == "hex") else Basis()
	_columns.set_instance_transform(instance, Transform3D(turned.scaled(Vector3(1, tall, 1)), at + Vector3(0, tall * 0.5, 0)))
	_columns.set_instance_color(instance, _colour(h))
	_columns.set_instance_custom_data(instance, Color(float(h), 0, 0, 0))


func _seat_worker() -> void:
	if _worker == null: return
	var h: int = _heights[_cell(_at)] if _on_field(_at) else 0
	_worker.position = _where(_at) + Vector3(0, tallest * float(h) / float(maxi(1, _n - 1)) + 0.11, 0)


## The rule, once: read the stack, turn, add a unit (a full stack falls), step on.
func _work() -> bool:
	if _step >= _budget: return false
	var i: int = _cell(_at)
	var h: int = _heights[i]
	_heading = posmod(_heading + _turns[h], _dirs.size())
	h = (h + 1) % _n
	_heights[i] = h
	_draw(_slot[i], h)
	var to: Vector2i = _at + _dirs[_heading]
	if not _on_field(to):
		_budget = _step + 1          # the form has reached the edge: it is finished here
	else:
		_at = to
	_step += 1
	return true


## Up to `count` steps now.
func advance(count: int) -> void:
	for i in count:
		if not _work(): break
	_seat_worker()
	if _step >= _budget and _phase == "build":
		_phase = "hold"
		_clock = 0.0
	_write()


func finish() -> void:
	advance(_budget - _step)


func next_rule() -> void:
	_begin(ORDER[(ORDER.find(rule) + 1) % ORDER.size()])


## Plate 0: the next instruction. Plate 1: the same again.
func press_plate(which: int) -> void:
	if _now - _pressed < 1.5: return
	_pressed = _now
	if which == 0: next_rule()
	else: _begin(rule)


func _write() -> void:
	if _board == null: return
	var turns: PackedStringArray = PackedStringArray(RULES[rule].turns)
	var lines := PackedStringArray(["A TERMITE READS THE STACK IT STANDS ON",
		"It turns as the instruction says for that height, adds one unit, steps on. A full stack falls.", "",
		"INSTRUCTION  %s" % " ".join(turns),
		"%s lattice  |  %d heights  |  form %d of %d: %s" % ["hexagonal" if _lattice == "hex" else "square", _n, ORDER.find(rule) + 1, ORDER.size(), rule.to_upper()],
		"step %d of %d  |  %d cells stand" % [_step, _budget, standing()]])
	if _phase == "hold": lines.append("Built. Nothing else was written down.")
	_board.text = "\n".join(lines)


func _process(delta: float) -> void:
	var began := Time.get_ticks_usec()
	_now += delta
	match _phase:
		"build":
			_owed += delta * float(_budget) / build_seconds
			var count: int = mini(int(_owed), 1500)
			if count > 0:
				_owed -= float(count)
				for i in count:
					if not _work(): break
				_seat_worker()
				if _step >= _budget:
					_phase = "hold"
					_clock = 0.0
			_clock += delta
			if _clock >= 0.25: _clock = 0.0; _write()
		"hold":
			_clock += delta
			if _clock == delta: _write()
			if hold_seconds > 0.0 and _clock >= hold_seconds:
				_phase = "fall"
				_clock = 0.0
		"fall":
			_clock += delta
			var left: float = clampf(1.0 - _clock / 1.6, 0.0, 1.0)
			for cell_index in _heights.size():
				var slot: int = _slot[cell_index]
				if slot >= 0 and _heights[cell_index] > 0: _draw(slot, _heights[cell_index], left * left)
			if left <= 0.0:
				if cycle: next_rule()
				else: _begin(rule)
	_spent_usec += Time.get_ticks_usec() - began
	_frames += 1


## ---- for a test ----

func standing() -> int:
	var count := 0
	for h in _heights: if h > 0: count += 1
	return count


## How many cells stand at each height from 1 up, the step, the budget, the phase.
func state() -> Dictionary:
	var hist: Array = []
	hist.resize(maxi(0, _n - 1))
	hist.fill(0)
	for h in _heights:
		if h > 0: hist[h - 1] += 1
	return {"rule": rule, "lattice": _lattice, "unit": unit, "step": _step, "budget": _budget, "phase": _phase, "standing": standing(), "heights": hist,
		"termite": [_at.x, _at.y, _heading], "columns": _places.size(), "pitch_m": _pitch}


## The tallest column's top above the work's floor, metres.
func top() -> float:
	var best := 0
	for h in _heights: best = maxi(best, h)
	return tallest * float(best) / float(maxi(1, _n - 1))


func frame_ms() -> float:
	var ms := float(_spent_usec) / 1000.0 / maxf(1.0, float(_frames))
	_spent_usec = 0
	_frames = 0
	return ms
