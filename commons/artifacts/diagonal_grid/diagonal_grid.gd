extends Node3D
## THE GRID AND THE ROW THAT IS NOT ON IT (floor Russell_Paradox; the pass, 2026-11-14)
##
## A visual argument for plate 3 of the hall's cardboard (commons/data/arguments/Russell_Paradox.json): the shape
## under Russell's paradox is a grid and its diagonal.
##
## The things are the workbench's own four sets at cell 6 - 0 contains nothing, 1 contains 0, 2 contains 0 and 1,
## 3 contains 0, 1 and 2 (so: row r contains column c when c is less than r). Rows are the things, columns the same
## things; a ball lies where the row contains the column. The diagonal asks each thing whether it contains itself,
## and every answer here is no: four empty cells in pink frames.
##
## South of the grid, outside it, lies a plank with the OPPOSITE of the diagonal at every place: a ball under every
## column. Stand on a diagonal cell: the board says at which place the new row disagrees with that row. It
## disagrees with every row at that row's own place, so it is not one of the rows. With four things that is no
## trouble - it is the set of all four, U, and it lies outside the list. That is the hall's cell 6.
##
## Stand still on EVERYTHING: the list is declared complete. The plank must then be a row; it is carried in as a
## fifth row with a fifth column for it, and its own diagonal cell has to hold a ball exactly when it does not.
## Nothing is put there, and nothing blinks: the hall says of its own lamp that a timer makes it flicker, not logic.
##
## `stage` is the axis, the three steps of the argument: grid = the things and the diagonal; new_row = the
## opposite of the diagonal, outside; everything = the list declared complete.
##
## Built from the tower's prefabs through prefab_city.gd: timber panels let into the floor, trace balls, a 4 m
## plank. Forty seconds with nobody near and it is again what its row says.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const N := 4
const PROUD := 0.014
const DWELL := 0.8
const EMPTY_SECONDS := 40.0
const NAMES := ["0", "1", "2", "3"]
const BLUE := Color("3f6fd0")
const YELLOW := Color("ffd23c")
const PINK := Color("ff5fa8")
const PLATE_AT := Vector3(3.8, 0, 3.4)

@export_enum("grid", "new_row", "everything") var stage := "new_row"

var _city = City.new()
var _given := "new_row"
var _outside: Node3D
var _fifth: Node3D
var _row_balls: Array[Node3D] = []
var _board: Label3D
var _body: CharacterBody3D
var _on := -1                            # the diagonal cell the body stands on
var _still := 0.0
var _held := false
var _touched := false
var _away := 0.0
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_stage"): _take({"stage": get_meta("config_stage")})
	_given = stage
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_apply()


func _take(config_data: Dictionary) -> void:
	if config_data.has("stage") and str(config_data["stage"]) in ["grid", "new_row", "everything"]: stage = str(config_data["stage"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := stage
	_take(config_data)
	_given = stage
	if is_inside_tree() and _board != null and stage != before: _apply()


## Does the thing of row r contain the thing of column c? The workbench's four sets: each contains the earlier ones.
func contains(r: int, c: int) -> bool:
	return c < r


## The opposite of the diagonal at place k.
func new_row(k: int) -> bool:
	return not contains(k, k)


func _cell(r: int, c: int) -> Vector3:
	return Vector3(-1.5 + float(c), 0, -1.5 + float(r))


func _in_tree(node: Node3D, wanted: bool) -> void:
	if wanted and node.get_parent() == null: add_child(node)
	elif not wanted and node.get_parent() != null: remove_child(node)


func _exit_tree() -> void:
	for node in [_outside, _fifth]:
		if is_instance_valid(node) and node.get_parent() == null: node.free()


func _apply() -> void:
	_in_tree(_outside, stage == "new_row")
	_in_tree(_fifth, stage == "everything")
	_tell()


func _physics_process(delta: float) -> void:
	var here := _body != null and is_instance_valid(_body)
	var on := -1
	var on_plate := false
	if here:
		var p := to_local(_body.global_position)
		for k in N:
			var c := _cell(k, k)
			if absf(p.x - c.x) < 0.5 and absf(p.z - c.z) < 0.5: on = k
		on_plate = Vector2(p.x - PLATE_AT.x, p.z - PLATE_AT.z).length() < 0.32
		if on_plate and Vector2(_body.velocity.x, _body.velocity.z).length() < 0.3:
			_still += delta
			if _still >= DWELL and not _held:
				_held = true
				_touched = true
				stage = "new_row" if stage == "everything" else "everything"
				_apply()
		else:
			_still = 0.0
			if not on_plate: _held = false
	if on != _on:
		_on = on
		for k in _row_balls.size(): _row_balls[k].scale = Vector3.ONE * (1.6 if k == _on else 1.0)
		_tell()


func _process(delta: float) -> void:
	if _body != null and is_instance_valid(_body):
		_away = 0.0
		return
	_away += delta
	if _touched and _away >= EMPTY_SECONDS:
		_touched = false
		stage = _given
		_apply()


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["THE GRID AND THE ROW THAT IS NOT ON IT"])
	lines.append("Rows are the workbench's four sets, columns the same four. A blue ball: this row contains that column. The pink frames are the diagonal: does a thing contain itself? Four times no.")
	if stage == "grid":
		lines.append("Now write a row that says the opposite of the diagonal at every place. Where would it go?")
	elif stage == "new_row":
		if _on >= 0:
			lines.append("You stand on place %s. Row %s says NO there (%s does not contain %s). The new row says YES. So the new row is not row %s." % [NAMES[_on], NAMES[_on], NAMES[_on], NAMES[_on], NAMES[_on]])
		else:
			lines.append("The yellow row on the plank is the opposite of the diagonal: yes at every place. Stand on a pink frame to see where it disagrees with that row.")
		lines.append("It disagrees with every row at that row's own place, so it is not on the list. No trouble: it is the set of all four, and it lies outside. Now stand still on EVERYTHING.")
	else:
		lines.append("The list is declared complete: everything is on it. Then the new row must be a row - the fifth - with a column of its own. Look at its own place: it must hold a ball exactly when it does not.")
		lines.append("Nothing can be put there. The same row that was harmless outside has nowhere to be. That is the paradox: not the row, the claim that the list was everything.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _ball(parent: Node3D, at: Vector3, colour: Color) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	parent.add_child(holder)
	var ball: Node3D = _city.part(holder, "trace_point_ball", Vector3.ZERO, 0, Vector3(0.36, 0.36, 0.36), false)
	var paint: StandardMaterial3D = _city.flat(colour, 0.35)
	for mesh in ball.find_children("*", "MeshInstance3D", true, false): (mesh as MeshInstance3D).material_override = paint
	return holder


func _frame(parent: Node3D, at: Vector3) -> void:
	for side in [-1.0, 1.0]:
		_city.sheet(parent, at + Vector3(0, PROUD + 0.004, side * 0.46), Vector2(1.0, 0.07), PINK)
		_city.sheet(parent, at + Vector3(side * 0.46, PROUD + 0.004, 0), Vector2(0.07, 1.0), PINK)


func _build_once() -> void:
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	for r in N:
		for c in N:
			_city.part(ground, "timber_panel_1x1", _cell(r, c) + Vector3(0, PROUD - 0.045, 0), 0, Vector3.ZERO, false)
			if contains(r, c): _ball(ground, _cell(r, c) + Vector3(0, PROUD, 0), BLUE)
		_frame(ground, _cell(r, r))
		_city.floor_words(ground, Vector3(-2.35, 0.014, -1.5 + float(r)), "row %s" % NAMES[r], 34)
		_city.floor_words(ground, Vector3(-1.5 + float(r), 0.014, -2.3), "has %s?" % NAMES[r], 30)
	# the new row, outside: a plank south of the grid with the opposite of the diagonal
	_outside = Node3D.new()
	_outside.name = "Outside"
	add_child(_outside)
	_city.part(_outside, "timber_plank_4m", Vector3(0, 0, 2.9), 0, Vector3.ZERO, false)
	for k in N:
		if new_row(k): _row_balls.append(_ball(_outside, Vector3(-1.5 + float(k), 0.06, 2.9), YELLOW))
	_city.floor_words(_outside, Vector3(-0.2, 0.014, 3.45), "THE NEW ROW: the opposite of the diagonal. Not on the list.", 30, YELLOW)
	# the list declared complete: a fifth row and a fifth column
	_fifth = Node3D.new()
	_fifth.name = "Fifth"
	add_child(_fifth)
	for k in N:
		_city.part(_fifth, "timber_panel_1x1", Vector3(-1.5 + float(k), PROUD - 0.045, 2.5), 0, Vector3.ZERO, false)
		_city.part(_fifth, "timber_panel_1x1", Vector3(2.5, PROUD - 0.045, -1.5 + float(k)), 0, Vector3.ZERO, false)
		if new_row(k): _ball(_fifth, Vector3(-1.5 + float(k), PROUD, 2.5), YELLOW)
	_city.part(_fifth, "timber_panel_1x1", Vector3(2.5, PROUD - 0.045, 2.5), 0, Vector3.ZERO, false)
	_frame(_fifth, Vector3(2.5, 0, 2.5))
	_city.floor_words(_fifth, Vector3(2.5, PROUD + 0.012, 2.5), "a ball here\nexactly when\nthere is none", 26, PINK.lightened(0.3))
	_city.floor_words(_fifth, Vector3(-2.45, 0.014, 2.5), "row R", 34, YELLOW)
	_city.floor_words(_fifth, Vector3(2.5, 0.014, -2.3), "has R?", 30, YELLOW)
	# the plate EVERYTHING, the body's sensor, the board
	_city.sheet(ground, PLATE_AT + Vector3(0, 0.006, 0), Vector2(0.62, 0.62), Color("3a3d45"))
	_city.floor_words(ground, PLATE_AT + Vector3(0, 0.016, 0.6), "EVERYTHING\nstand still", 28)
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(10.0, 2.4, 10.0)
	var shape := CollisionShape3D.new()
	shape.shape = room
	shape.position = Vector3(0.5, 1.2, 0.5)
	sensor.add_child(shape)
	ground.add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	_board = _city.board(ground, Vector3(4.6, 0, -0.4), 3.0, 1.2)
	(_board.get_parent().get_parent() as Node3D).rotation_degrees.y = -60.0


## ---- for a test ----

func state() -> Dictionary:
	var marks := []
	for r in N:
		var row := ""
		for c in N: row += "1" if contains(r, c) else "0"
		marks.append(row)
	var opposite := ""
	for k in N: opposite += "1" if new_row(k) else "0"
	return {"stage": stage, "rows": marks, "new_row": opposite, "on_the_list": marks.has(opposite), "standing_on": _on, "outside_shown": _outside.get_parent() != null,
		"fifth_shown": _fifth.get_parent() != null, "board": _board.text if _board != null else "", "prefab_parts": int(_city.parts), "build_ms": _build_ms}


func cell_point(r: int, c: int) -> Vector3:
	return to_global(_cell(r, c))


func everything_plate() -> Vector3:
	return to_global(PLATE_AT)
