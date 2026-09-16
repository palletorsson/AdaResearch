extends Node3D
class_name WallDrawing291

# @identity
# essence: a black wall ruled into 30 cm squares and a plate that says what goes in each one, with the drafting left to whoever stands in front of it
# desire: to hand the visitor the draftsman's part of LeWitt's instruction, the one choice the sentence leaves open, instead of showing them a wall someone else already decided
# critical_parameter: start. "empty" is the instruction waiting for a hand; "drawn" is one execution, authored by hand in DRAWN_SHEET, not generated and not the drawing
# triggers: _ready() builds the wall, the rules, one press target per square (push_button.tscn with its visuals hidden and its area widened to the square), the plate and START AGAIN; a press on a square draws or turns its line
# emerges: the rule stays fixed while the wall keeps changing; the counter only ever goes up until START AGAIN; a finished wall is not the end of choosing, because a drawn square can still be turned
# needs: push_button.tscn [present] for every press target; RackTemplates.create_panel [present] for START AGAIN, the helper shannon_entropy_meter uses; TextScreen SCREEN mode [present] for every visible word
# relationships: sol_lewitt_wall_drawing holds three other LeWitt instructions drafted by a seed; this one has no seed and no randomness at all, because the exception comes from the visitor's hand
# truth: the book sets Wall Drawing 291 beside 10 PRINT, an algorithm in English with four choices per square where the program has two. What decides each square is not in the sentence. Here it is you.

## Sol LeWitt, Wall Drawing 291 (1976), with the visitor as the draftsman.
##
## THE INSTRUCTION (paraphrased from the chapter, p. 81): a 30 cm grid covers a
## black wall; each square gets one line bisecting it, vertical, horizontal,
## diagonal right or diagonal left; every square is filled; the draftsman decides
## the direction in each square.
##
## THE PRESS. Every square is its own press target. The first press draws a
## vertical line; each further press turns it: vertical -> horizontal ->
## diagonal right -> diagonal left -> vertical. A drawn square never goes blank
## again; only START AGAIN clears the wall. The counter on the plate describes,
## it does not grade: "N of 40 squares drawn", then "all 40 squares drawn".
##
## THE BUTTONS ARE THE PROJECT'S OWN. Each square carries push_button.tscn, the
## scene pattern_tile_plate uses for its paint cells: its XR Tools area script
## (interactable_area_button_pointer.gd) takes a VR finger through the physics
## overlap and the desktop pointer through pointer_event, on layer 21 with mask
## 18+19. Its round meshes are hidden, its cap's body is switched off, and its
## area's shape is swapped for a box the size of the square, so the whole square
## is the target and not a 7 cm disc in its middle. The box reaches 5 cm in front
## of the face and 25 cm BEHIND it: nothing stops a hand at this wall, and a
## finger that pushes through must stay inside one press rather than leave out of
## the back and press again on the way out. The signal is button_pressed(button),
## ONE argument, so every connection is a lambda taking one argument: a 0-arg
## method would be refused at every press (a dead button). START AGAIN is RackTemplates.create_panel's
## button, wired the way shannon_entropy_meter wires SORT / CONTRAST / DISCLOSE.
##
## NO RANDOMNESS. Nothing in this file calls randf, randi or a RandomNumberGenerator.
## The work can stand before the randomness sequence: the choice is the visitor's.
##
## COLLIDERS. None on the wall. A wall work has no body collider by contract. The
## forty hidden button caps keep their nodes with collision layer and mask 0 and
## the shape disabled. The press areas live under nodes marked em_local_instrument,
## so the museum's seal walk does not read them as the installation's footprint.
## The only live body is START AGAIN's own visible button cap.
##
## CONFIG. columns and rows are BOTH in GridInteractablesComponent.CONFIG_PARAM_NAMES
## (the list at :16; "rows" in its first lines, "columns" under the art history
## gallery params, "cols" too), so `#columns:10#rows:6` arrives as values and
## not as the tutorial rotation shorthand. A key outside that list with a number
## after it would arrive as the boolean true, and _count_value refuses a bool.
## `#start:drawn` is a word and is safe under any key. The default 8 x 5 needs no config.

signal wall_changed(drawn: int, total: int)

## Squares across. 8 by default: 2.4 m of grid.
@export_range(1, 16) var columns: int = 8
## Squares up. 5 by default: 1.5 m of grid from 0.5 m to 2.0 m.
@export_range(1, 10) var rows: int = 5
## "empty": the grid with no lines, waiting for a hand.
## "drawn": one fixed execution, AUTHORED BY HAND in DRAWN_SHEET below, so a
## capture shows a drawn wall. It is not generated; nothing here is random.
@export_enum("empty", "drawn") var start: String = "empty"

const STARTS: PackedStringArray = ["empty", "drawn"]

const BLANK := 0
const VERTICAL := 1
const HORIZONTAL := 2
const DIAGONAL_RIGHT := 3      # rising to the right: /
const DIAGONAL_LEFT := 4       # rising to the left: \
const DIRECTION_NAMES: PackedStringArray = ["blank", "vertical", "horizontal", "diagonal_right", "diagonal_left"]

## THE AUTHORED EXECUTION for start = "drawn". Top row first, V vertical,
## H horizontal, R diagonal right (/), L diagonal left (\). Written by hand for
## this file on 2026-09-16: each row mirrors left to right with the diagonals
## swapped, except one pair (counting from 1: row 4, where column 2 is an H and
## its mirror, column 7, a V). One drafting of 291, not the drawing. 11 V, 9 H,
## 10 R, 10 L. A grid larger than 8 x 5 repeats the sheet.
const DRAWN_SHEET: PackedStringArray = [
	"VRRHHLLV",
	"RVHRLHVL",
	"HRVLRVLH",
	"LHRVVLVR",
	"VLHRLHRV",
]

const TITLE := "WALL DRAWING 291"

const MAX_COLUMNS := 16
const MAX_ROWS := 10

const SQUARE := 0.30           # the instruction's 12 inches, as the chapter gives it: 30 cm
const GRID_BASE_Y := 0.50      # bottom edge of the lowest row: every square within a standing reach
const MARGIN := 0.20           # black wall around the whole composition
const GUTTER := 0.25           # between the grid and the plate column
const SIDE_W := 0.80           # the plate column
const MIN_WALL_H := 2.20
const WALL_D := 0.06           # the wall's thickness, all of it behind z = 0

const LINE_W := 0.016          # the drafted line: reads from 3 m
const LINE_T := 0.003
const LINE_Z := 0.0045
const RULE_W := 0.004          # the grid itself, fainter
const RULE_T := 0.002
const RULE_Z := 0.002

const AREA_INSET := 0.03       # press box is 27 cm of the 30 cm square: a 3 cm gutter between targets
## The press box runs from AREA_FRONT in front of the wall face to AREA_BEHIND
## behind it. The wall has no collider by contract and the hands do not collide
## with it, so a finger that presses keeps going THROUGH the face. A shallow box
## lets it out of the back (button_released) and back in on the way out
## (button_pressed again): one touch would turn a square two steps. Deep enough
## behind the face that a real push stays inside, the touch is one press.
const AREA_FRONT := 0.05       # a finger this close to the face starts pressing
const AREA_BEHIND := 0.25      # a finger this far through the face is still the same press

const PLATE_W := 0.74
const PLATE_Y := 1.45          # plate centre at reading height
const AGAIN_Y := 0.95          # START AGAIN at hand height
const AGAIN_SCALE := 2.0
const TEXT_Z := 0.016          # a TextScreen's frame reaches 14 mm behind its origin

const WALL_COLOR := Color(0.045, 0.045, 0.05)
const RULE_COLOR := Color(0.30, 0.30, 0.31)
const CHALK_COLOR := Color(0.93, 0.92, 0.88)

const PUSH_BUTTON_PATH := "res://commons/interactables/push_button.tscn"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

var _built := false
var _created: Array[Node] = []
var _state: PackedInt32Array = PackedInt32Array()
var _lines: Array[MeshInstance3D] = []
var _press_areas: Array[Area3D] = []
var _plate: Node3D = null
var _again_area: Area3D = null
var _straight_mesh: BoxMesh = null
var _diagonal_mesh: BoxMesh = null
var _chalk: StandardMaterial3D = null


func _ready() -> void:
	if _built:
		return
	_build_all()
	_built = true


## Parent a node we made, and remember we made it, so a rebuild frees our own
## geometry and never the label plates or tag markers the grid adds after us.
func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _build_all() -> void:
	columns = clampi(columns, 1, MAX_COLUMNS)
	rows = clampi(rows, 1, MAX_ROWS)
	start = _pick(start, STARTS, "empty")
	_lines.clear()
	_press_areas.clear()
	_again_area = null
	_plate = null

	_chalk = _flat(CHALK_COLOR, 0.22)
	_straight_mesh = BoxMesh.new()
	_straight_mesh.size = Vector3(SQUARE - RULE_W, LINE_W, LINE_T)
	# A box rotated 45 degrees reaches (L + w) / (2 sqrt 2) along each axis; solve
	# for the L whose ends land on the square's corners inside the rules.
	_diagonal_mesh = BoxMesh.new()
	_diagonal_mesh.size = Vector3(2.0 * sqrt(2.0) * (SQUARE * 0.5 - RULE_W * 0.5) - LINE_W, LINE_W, LINE_T)

	# the state first, so the lines and the plate are built already saying it
	_init_state()
	_build_wall()
	_build_rules()
	_build_squares()
	_build_plate()
	_build_start_again()


# --- layout -------------------------------------------------------------------

func _grid_w() -> float:
	return float(columns) * SQUARE


func _grid_h() -> float:
	return float(rows) * SQUARE


func _wall_w() -> float:
	return MARGIN + _grid_w() + GUTTER + SIDE_W + MARGIN


func _wall_h() -> float:
	return maxf(MIN_WALL_H, GRID_BASE_Y + _grid_h() + MARGIN)


func _grid_x0() -> float:
	return -_wall_w() * 0.5 + MARGIN


func _side_x() -> float:
	return _grid_x0() + _grid_w() + GUTTER + SIDE_W * 0.5


## Square index runs in reading order: row 0 is the TOP row, column 0 the left.
func square_local_centre(index: int) -> Vector3:
	var c: int = index % columns
	var r: int = floori(float(index) / float(columns))
	var x: float = _grid_x0() + (float(c) + 0.5) * SQUARE
	var y: float = GRID_BASE_Y + (float(rows - 1 - r) + 0.5) * SQUARE
	return Vector3(x, y, 0.0)


# --- the wall -------------------------------------------------------------------

func _build_wall() -> void:
	var wall := MeshInstance3D.new()
	wall.name = "Wall"
	var box := BoxMesh.new()
	box.size = Vector3(_wall_w(), _wall_h(), WALL_D)
	wall.mesh = box
	# base at y = 0, front face at z = 0, the thickness behind it
	wall.position = Vector3(0.0, _wall_h() * 0.5, -WALL_D * 0.5)
	wall.material_override = _flat(WALL_COLOR, 0.0)
	_own(wall)


## The 30 cm grid, ruled faintly: columns + 1 verticals and rows + 1 horizontals.
func _build_rules() -> void:
	var holder := Node3D.new()
	holder.name = "Rules"
	_own(holder)
	var mat := _flat(RULE_COLOR, 0.0)
	var v_mesh := BoxMesh.new()
	v_mesh.size = Vector3(RULE_W, _grid_h() + RULE_W, RULE_T)
	var h_mesh := BoxMesh.new()
	h_mesh.size = Vector3(_grid_w() + RULE_W, RULE_W, RULE_T)
	var x0: float = _grid_x0()
	var mid_y: float = GRID_BASE_Y + _grid_h() * 0.5
	for c in range(columns + 1):
		var v := MeshInstance3D.new()
		v.name = "RuleV_%d" % c
		v.mesh = v_mesh
		v.material_override = mat
		v.position = Vector3(x0 + float(c) * SQUARE, mid_y, RULE_Z)
		holder.add_child(v)
	for r in range(rows + 1):
		var h := MeshInstance3D.new()
		h.name = "RuleH_%d" % r
		h.mesh = h_mesh
		h.material_override = mat
		h.position = Vector3(x0 + _grid_w() * 0.5, GRID_BASE_Y + float(r) * SQUARE, RULE_Z)
		holder.add_child(h)


## One square = its line (hidden while blank) and its press target.
func _build_squares() -> void:
	var holder := Node3D.new()
	holder.name = "Squares"
	# the press areas are hand targets, not the installation's footprint
	holder.set_meta("em_local_instrument", true)
	_own(holder)
	var btn_scene: PackedScene = load(PUSH_BUTTON_PATH)
	var n: int = columns * rows
	for index in range(n):
		var square := Node3D.new()
		square.name = "Square_%d" % index
		square.position = square_local_centre(index)
		holder.add_child(square)

		var line := MeshInstance3D.new()
		line.name = "Line"
		line.mesh = _straight_mesh
		line.material_override = _chalk
		line.position = Vector3(0.0, 0.0, LINE_Z)
		line.visible = false
		square.add_child(line)
		_lines.append(line)

		var area: Area3D = null
		_show_line(index)
		if btn_scene != null:
			var btn: Node3D = btn_scene.instantiate() as Node3D
			btn.name = "Press"
			# the .tscn root already turns the button's +Y to face +Z; keep that basis
			btn.transform.origin = Vector3.ZERO
			# Hide the round button: the square is the visual (pattern_tile_plate does the same)
			for mesh_name in ["BaseMesh", "ButtonMesh", "AccentRing"]:
				var m: Node = btn.find_child(mesh_name, true, false)
				if m is Node3D:
					(m as Node3D).visible = false
			# The round button's own body is a 6 cm disc on layer 1 at the square's
			# centre. Its mesh is hidden, so its collider would be an invisible stop
			# for a hand and a snag for a walking body on a wall that has none. Keep
			# the node (the area's `button` path animates it) and switch it off.
			var cap_body: StaticBody3D = btn.get_node_or_null("Button") as StaticBody3D
			if cap_body != null:
				cap_body.collision_layer = 0
				cap_body.collision_mask = 0
				var cap_shape: CollisionShape3D = cap_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
				if cap_shape != null:
					cap_shape.disabled = true
			var area_node: Node = btn.get_node_or_null("InteractableAreaButton")
			if area_node != null and area_node.has_signal("button_pressed"):
				area = area_node as Area3D
				# The whole square is the target. A NEW shape per square: the scene's
				# own AreaShape sub-resource is shared by every push button in the project.
				var cs: CollisionShape3D = area_node.get_node_or_null("CollisionShape3D") as CollisionShape3D
				if cs != null:
					var box := BoxShape3D.new()
					# the button root turns local +Y to face +Z, so the box's Y is its
					# depth: from AREA_FRONT in front of the face to AREA_BEHIND behind it
					box.size = Vector3(SQUARE - AREA_INSET, AREA_FRONT + AREA_BEHIND, SQUARE - AREA_INSET)
					cs.shape = box
					cs.position = Vector3(0.0, (AREA_FRONT - AREA_BEHIND) * 0.5, 0.0)
				# button_pressed(button) carries ONE argument: a lambda that takes it
				var square_index: int = index
				area_node.button_pressed.connect(func(_b): press_square(square_index))
			square.add_child(btn)
		_press_areas.append(area)


# --- the plate ------------------------------------------------------------------

## Configure BEFORE add_child: TextScreen's setters rebuild only when in-tree.
func _build_plate() -> void:
	var ts := TextScreenScript.new()
	ts.name = "Plate"
	ts.mode = 0                       # Mode.SCREEN: a framed panel on the wall, no post
	ts.width_m = PLATE_W
	ts.position = Vector3(_side_x(), PLATE_Y, TEXT_Z)
	ts.set_text(TITLE, _plate_body())
	_own(ts)
	_plate = ts


func _plate_body() -> String:
	return "\n".join(PackedStringArray([
		"after Sol LeWitt, 1976",
		"each square gets one line:",
		"vertical, horizontal or a diagonal",
		"every square is filled",
		"you are the draftsman: press a square",
		counter_line(),
	]))


## Describes, never grades.
func counter_line() -> String:
	var total: int = square_count()
	var drawn: int = drawn_count()
	var noun: String = "square" if total == 1 else "squares"
	if total > 0 and drawn >= total:
		return "all %d %s drawn" % [total, noun]
	return "%d of %d %s drawn" % [drawn, total, noun]


## Only the body changes after the build. Setting `body` alone rebuilds the
## screen once; set_text would rebuild it three times (both setters, then again).
func _refresh_plate() -> void:
	if _plate != null and is_instance_valid(_plate):
		_plate.set("body", _plate_body())


## START AGAIN: the proven RackTemplates button, and a TextScreen caption beside
## it (the rack's own labels are Label3D and baked tags, which the capture
## pipeline does not render, so the panel carries no label of its own).
func _build_start_again() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		return
	# A single space, not "": the title is blank to the eye either way, but an
	# empty title becomes an empty node name (an engine error) in RackTemplates
	# versions that do not fall back to "RackPanel". " " is "_" there.
	var panel: Node3D = RackTpl.create_panel(" ", [
		[{"type": "button"}],
	])
	panel.name = "StartAgainPanel"
	# the panel's button area is a hand target, not the installation's footprint
	panel.set_meta("em_local_instrument", true)
	panel.position = Vector3(_side_x() - 0.24, AGAIN_Y, 0.012)
	panel.scale = Vector3.ONE * AGAIN_SCALE
	_own(panel)
	var btn: Node = panel.find_child("Btn_0", true, false)
	if btn != null:
		var area: Node = btn.get_node_or_null("InteractableAreaButton")
		if area != null and area.has_signal("button_pressed"):
			_again_area = area as Area3D
			area.button_pressed.connect(func(_b): start_again())

	var caption := TextScreenScript.new()
	caption.name = "StartAgainCaption"
	caption.mode = 0
	caption.width_m = 0.40
	caption.position = Vector3(_side_x() + 0.16, AGAIN_Y, TEXT_Z)
	caption.set_text("START AGAIN", "clears every square")
	_own(caption)


# --- the drafting ---------------------------------------------------------------

func _init_state() -> void:
	var n: int = columns * rows
	_state.resize(n)
	for index in range(n):
		_state[index] = authored_direction(index) if start == "drawn" else BLANK


## The authored sheet's direction for a square, repeating the 8 x 5 sheet on a
## larger grid. Authored, not generated.
func authored_direction(index: int) -> int:
	var c: int = index % columns
	var r: int = floori(float(index) / float(columns))
	var row_text: String = DRAWN_SHEET[r % DRAWN_SHEET.size()]
	match row_text[c % row_text.length()]:
		"V":
			return VERTICAL
		"H":
			return HORIZONTAL
		"R":
			return DIAGONAL_RIGHT
		"L":
			return DIAGONAL_LEFT
	return VERTICAL


## The draftsman's act. Blank -> vertical; a drawn square turns to the next
## direction. Nothing makes a drawn square blank except start_again().
func press_square(index: int) -> void:
	if index < 0 or index >= _state.size():
		return
	var was: int = _state[index]
	var now: int = VERTICAL if was == BLANK else (was % 4) + 1
	_state[index] = now
	_show_line(index)
	if was == BLANK:
		_refresh_plate()          # the counter only moves when a blank square is drawn
	wall_changed.emit(drawn_count(), square_count())


func start_again() -> void:
	for index in range(_state.size()):
		_state[index] = BLANK
		_show_line(index)
	_refresh_plate()
	wall_changed.emit(drawn_count(), square_count())


func _show_line(index: int) -> void:
	if index < 0 or index >= _lines.size():
		return
	var line: MeshInstance3D = _lines[index]
	if line == null or not is_instance_valid(line):
		return
	var d: int = _state[index]
	match d:
		VERTICAL:
			line.mesh = _straight_mesh
			line.rotation = Vector3(0.0, 0.0, PI * 0.5)
			line.visible = true
		HORIZONTAL:
			line.mesh = _straight_mesh
			line.rotation = Vector3.ZERO
			line.visible = true
		DIAGONAL_RIGHT:
			line.mesh = _diagonal_mesh
			line.rotation = Vector3(0.0, 0.0, PI * 0.25)
			line.visible = true
		DIAGONAL_LEFT:
			line.mesh = _diagonal_mesh
			line.rotation = Vector3(0.0, 0.0, -PI * 0.25)
			line.visible = true
		_:
			line.visible = false


# --- readbacks (for probes and anyone curious) ----------------------------------

func square_count() -> int:
	return _state.size()


func drawn_count() -> int:
	var d: int = 0
	for s in _state:
		if s != BLANK:
			d += 1
	return d


func is_complete() -> bool:
	return square_count() > 0 and drawn_count() == square_count()


func square_state(index: int) -> int:
	if index < 0 or index >= _state.size():
		return BLANK
	return _state[index]


func square_direction(index: int) -> String:
	return DIRECTION_NAMES[square_state(index)]


func state_snapshot() -> PackedInt32Array:
	return _state.duplicate()


func square_line(index: int) -> MeshInstance3D:
	if index < 0 or index >= _lines.size():
		return null
	return _lines[index]


func square_press_area(index: int) -> Area3D:
	if index < 0 or index >= _press_areas.size():
		return null
	return _press_areas[index]


func start_again_area() -> Area3D:
	return _again_area


func square_global_centre(index: int) -> Vector3:
	return to_global(square_local_centre(index))


func plate_body() -> String:
	if _plate == null or not is_instance_valid(_plate):
		return ""
	return str(_plate.get("body"))


# --- materials and parsing ------------------------------------------------------

func _flat(c: Color, emission: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	m.metallic = 0.0
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m


## Accept a word only if it names something we build; a typo lands on the
## current value whole rather than on a half-built wall.
func _pick(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## A count from a token. A bool is the tutorial-shorthand misparse (an unlisted
## key:number arrives as `true`), so it is refused rather than read as 1.
func _count_value(raw: Variant, fallback: int, most: int) -> int:
	if raw is bool:
		return fallback
	if raw is int or raw is float:
		return clampi(int(raw), 1, most)
	var text: String = str(raw).strip_edges()
	if text.is_valid_int():
		return clampi(text.to_int(), 1, most)
	return fallback


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_build_all()


## Grid config. Keys: "columns" (or "cols"), "rows", "start" (empty | drawn).
## A rebuild clears whatever the visitor drew, so it only happens when a key
## that shapes the wall actually changed.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_columns: int = columns
	var before_rows: int = rows
	var before_start: String = start

	if config_data.has("columns"):
		columns = _count_value(config_data["columns"], columns, MAX_COLUMNS)
	elif config_data.has("cols"):
		columns = _count_value(config_data["cols"], columns, MAX_COLUMNS)
	if config_data.has("rows"):
		rows = _count_value(config_data["rows"], rows, MAX_ROWS)
	if config_data.has("start"):
		start = _pick(str(config_data["start"]), STARTS, start)

	if not _built:
		return                    # _ready builds with these values, once
	if columns == before_columns and rows == before_rows and start == before_start:
		return
	if columns == before_columns and rows == before_rows:
		# Only `start` changed: same wall, new state. No rebuild, so the forty push
		# buttons are not freed while push_button.gd's _ready is still awaiting its
		# process frames (the grid hands config over with call_deferred, in the
		# same frame the wall was built).
		_init_state()
		for index in range(_state.size()):
			_show_line(index)
		_refresh_plate()
		wall_changed.emit(drawn_count(), square_count())
		return
	_rebuild_now()
