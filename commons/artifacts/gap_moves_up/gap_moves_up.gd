extends Node3D
## LAY THE MISSING PLANK (floor Godel_Incompleteness; the pass, gone back to on 2026-11-16)
##
## The hall, of its tower: "One ringed platform per formal system; on each, the truth the system below could not
## prove, bolted on as a new axiom; above it, a new platform holding the sentence the enlarged system cannot
## prove." "Adding the sentence moves the gap up. It does not close it." This is that paragraph for the legs - a
## PLAYGROUND form, built round the tower itself.
##
## Four landings at the corners of a square, each half a metre higher than the last. A ramp leads from the floor
## to the first, T. Between each landing and the next the rails and the stringers are there and the planks are
## not: across the gap stands a crystal, a sentence that is true up there and cannot be reached from here. A
## plate on the landing lays the planks - the sentence is added as an axiom - and the visitor walks up to the next
## landing, T + G0, where there is another gap and another crystal. Three times. The fourth landing ends at
## tape, and the next crystal stands on a shelf straight above the landing the walk began on: one turn of the
## tower, and the gap is where it was, one level up. The stand counts planks laid, and gaps open: always one.
##
## `planks` is the axis: none, one, two, three - how many are laid when the work is found.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const HALF := 2.3                         # half the side of the square
const SIDE := 1.3                         # a landing
const C := HALF - SIDE * 0.5              # a landing's centre is at (+-C, +-C)
const RISE := 0.5
const RUN := 2.0                          # a ramp, in plan
const ORIGIN := Vector3(-(HALF + RUN), 0, -C)      # the square's centre, from the foot of the first ramp
const STAGES := ["none", "one", "two", "three"]
const PLATE := 0.56
const RESET_AT := Vector2(HALF + RUN + 1.7, C - 1.05)
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const HOT := Color("ff5a3c")
const GLOW := Color("ffd84a")
const DIM := Color("8a8f9c")
const WOOD := Color("6b4a32")
# the landings in the order they are walked: south-east, north-east, north-west, south-west
const CORNERS := [Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(-1, 1)]

@export_enum("none", "one", "two", "three") var planks := "none"

var _city = City.new()
var _frame: Node3D
var _laid := 0
var _on := -1                             # the landing the visitor stands on, or -1
var _top := -1                            # the highest landing reached since the planks were last taken up
var _ramps: Array[Node3D] = []            # the three sets of planks that can be laid
var _ramp_solids: Array[CollisionShape3D] = []
var _bars: Array[Node3D] = []             # what closes each gap until its planks are laid
var _bar_solids: Array[CollisionShape3D] = []
var _things: Array[Node3D] = []           # four crystals: G0 .. G3
var _halos: Array[MeshInstance3D] = []
var _tags: Array[Label3D] = []
var _tiles: Array[MeshInstance3D] = []
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_planks"): _take({"planks": get_meta("config_planks")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("planks") and STAGES.has(str(config_data["planks"])): planks = str(config_data["planks"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := planks
	_take(config_data)
	if is_inside_tree() and _board != null and planks != before: _found()


func _found() -> void:
	_laid = STAGES.find(planks)
	_top = -1
	_show()
	_tell()


## ---- the rule ----

## The system that stands on landing `n`: T, then T with each sentence added that was laid as planks below it.
static func system(n: int) -> String:
	var text := "T"
	for k in n: text += " + G%d" % k
	return text


## However many planks are laid, the gaps still open: the one above the last landing reached by planks.
static func gaps_open(_planks_laid: int) -> int:
	return 1


static func height(n: int) -> float:
	return RISE * float(n + 1)


func _centre(n: int) -> Vector3:
	var corner: Vector2 = CORNERS[n]
	return Vector3(corner.x * C, height(n), corner.y * C)


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := _frame.to_local(body.global_position)
	var on := -1
	var region := ""
	for n in 4:
		var at := _centre(n)
		if absf(p.x - at.x) < SIDE * 0.5 and absf(p.z - at.z) < SIDE * 0.5 and p.y - at.y > -0.3 and p.y - at.y < 1.3:
			on = n
			if n < 3 and absf(p.x - at.x) < PLATE * 0.5 and absf(p.z - at.z) < PLATE * 0.5: region = "add%d" % n
	if absf(p.y) < 1.3 and absf(p.x - RESET_AT.x) < 0.42 and absf(p.z - RESET_AT.y) < 0.42: region = "reset"
	if on != _on:
		_on = on
		_top = maxi(_top, on)
		_show()
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		if region == "reset":
			_laid = 0
			_top = -1
		elif int(region.trim_prefix("add")) == _laid:
			_laid += 1
		else:
			return
		planks = STAGES[_laid]
		_show()
		_tell()


func _status_text() -> String:
	if _on == 3: return "THE TOWER GOES ON. THE FLOOR DOES NOT.\nADDING THE SENTENCE MOVES THE GAP UP. IT DOES NOT CLOSE IT."
	if _on >= 0 and _laid > _on: return "THE PLANKS ARE LAID: G%d IS AN AXIOM NOW. WALK UP.\nTHE SYSTEM UP THERE IS  %s." % [_on, system(_on + 1)]
	if _on >= 0: return "G%d IS TRUE UP THERE, AND THERE IS NO WAY TO IT FROM  %s.\nSTAND ON  ADD IT." % [_on, system(_on)]
	if _top >= 0: return "YOU CAME DOWN. THE PLANKS YOU LAID ARE STILL LAID.\nTHE GAP IS STILL OPEN, ABOVE THE LAST OF THEM."
	return "A SYSTEM, AND ACROSS A GAP A SENTENCE IT CANNOT REACH.\nGO UP THE RAMP AND LOOK."


func _show() -> void:
	for k in 3:
		_ramps[k].visible = _laid > k
		_ramp_solids[k].disabled = _laid <= k
		_bars[k].visible = _laid <= k
		_bar_solids[k].disabled = _laid > k
		(_tiles[k].material_override as StandardMaterial3D).albedo_color = GLOW if _laid == k else Color("6f7480")
	for k in 4:
		_things[k].visible = k <= _laid
		_halos[k].visible = k == _laid
		_tags[k].visible = k <= _laid
		_tags[k].text = ("G%d" % k) if k == _laid else ("G%d: an axiom now" % k)
		_tags[k].modulate = GLOW if k == _laid else DIM
	_lines[0].text = ("YOU STAND ON:   %s" % system(_on)) if _on >= 0 else "LAY THE MISSING PLANK"
	_lines[1].text = "planks laid:   %d of 3" % _laid
	_lines[2].text = "GAPS OPEN:   %d" % gaps_open(_laid)
	_status.text = _status_text()


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["LAY THE MISSING PLANK"])
	lines.append("The first landing is a system, T. Across the gap is a sentence that is true up there and cannot be reached from T. Stand on ADD IT: the planks are laid. The sentence is an axiom now, and you can walk up.")
	lines.append("On the next landing there is another gap and another sentence. Three times; then the floor ends, and the next sentence stands straight above where you began.")
	lines.append("Each set of planks is one particular sentence, with an argument behind it, in a stated system. A conviction is not a plank. START AGAIN, beside this board, takes the planks up.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _box(parent: Node3D, at: Vector3, size: Vector3, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = paint
	mesh.position = at
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh


func _words(parent: Node3D, at: Vector3, size: int, pixel: float, colour: Color) -> Label3D:
	var label3d := Label3D.new()
	label3d.font_size = size
	label3d.pixel_size = pixel
	label3d.modulate = colour
	label3d.outline_size = 0
	label3d.double_sided = false
	label3d.position = at
	parent.add_child(label3d)
	return label3d


func _plain(colour: Color) -> StandardMaterial3D:
	var paint: StandardMaterial3D = _city.flat(colour, 0.9)
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return paint


## A plank on edge as a rail: its foot at `at`, `long` metres, along x or along z.
func _rail(parent: Node3D, at: Vector3, along_x: bool, long: float) -> void:
	_city.part(parent, "timber_plank_2m", at + Vector3(0, 0.8, 0), 0.0 if along_x else 90.0, Vector3(long, 0.18, 0.04), false)


## A ramp from `low` to `high` (points on its walking surface, in the square's frame): a tilted body whose own x
## runs up the slope. Rails and stringers always; the planks and what holds a body are returned to be switched.
func _ramp(low: Vector3, high: Vector3, laid_from_the_start: bool) -> Dictionary:
	var along: Vector3 = (high - low).normalized()
	var side: Vector3 = Vector3.UP.cross(along).normalized()
	var up: Vector3 = along.cross(side).normalized()
	var body := StaticBody3D.new()
	body.transform = Transform3D(Basis(along, up, along.cross(up)), (low + high) * 0.5)
	_frame.add_child(body)
	var long: float = low.distance_to(high)
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(long + 0.08, 0.1, 1.14)
	shape.shape = block
	shape.position = Vector3(0, -0.05, 0)
	body.add_child(shape)
	var dark: StandardMaterial3D = _city.flat(DARK, 0.85)
	for hand in [-1.0, 1.0]:
		_box(body, Vector3(0, -0.1, hand * 0.5), Vector3(long, 0.08, 0.06), dark)
		_city.part(body, "timber_plank_2m", Vector3(0, 0.8, hand * 0.6), 0.0, Vector3(long, 0.18, 0.04), false)
		for end in [-1.0, 1.0]: _box(body, Vector3(end * (long * 0.5 - 0.06), 0.45, hand * 0.6), Vector3(0.05, 0.9, 0.05), dark)
	var deck := Node3D.new()
	deck.name = "Planks"
	body.add_child(deck)
	for k in 4: _city.part(deck, "timber_plank_2m", Vector3(0, -0.05, -0.405 + 0.27 * float(k)), 0.0, Vector3(long, 0.05, 0.25), false)
	deck.visible = laid_from_the_start
	shape.disabled = not laid_from_the_start
	return {"planks": deck, "shape": shape}


func _build_once() -> void:
	_frame = Node3D.new()
	_frame.name = "Spiral"
	_frame.position = ORIGIN
	add_child(_frame)
	var solid := StaticBody3D.new()
	solid.name = "Held"
	_frame.add_child(solid)
	var wood: StandardMaterial3D = _city.flat(WOOD, 0.9)
	# the four landings: a panel, what holds a body, a post at each corner, rails on the two outer sides
	for n in 4:
		var at := _centre(n)
		var corner: Vector2 = CORNERS[n]
		_city.part(_frame, "timber_panel_2x2", Vector3(at.x, at.y - 0.08, at.z), 0.0, Vector3(SIDE, 0.08, SIDE), false)
		_city.wall(solid, Vector3(at.x, at.y - 0.12, at.z), Vector3(SIDE, 0.12, SIDE))
		var tall: float = at.y + 1.0 if n > 0 else 2.5
		for a in [-1.0, 1.0]:
			for b in [-1.0, 1.0]: _box(_frame, Vector3(at.x + a * (SIDE * 0.5 - 0.04), tall * 0.5, at.z + b * (SIDE * 0.5 - 0.04)), Vector3(0.08, tall, 0.08), wood)
		# the outer side along x (north or south of the square), and the outer side along z (east or west)
		var far_z: float = corner.y * HALF
		var far_x: float = corner.x * HALF
		if n != 0:
			_rail(_frame, Vector3(far_x, at.y, at.z), false, SIDE)
			_city.wall(solid, Vector3(far_x, at.y, at.z), Vector3(0.06, 1.1, SIDE))
		_rail(_frame, Vector3(at.x, at.y, far_z), true, SIDE)
		_city.wall(solid, Vector3(at.x, at.y, far_z), Vector3(SIDE, 1.1, 0.06))
		var name_words: Label3D = _city.floor_words(_frame, Vector3(at.x - corner.x * 0.05, at.y + 0.02, at.z + corner.y * 0.47), system(n), 30, DARK)
		name_words.outline_size = 0
		if corner.y > 0.0: name_words.rotation_degrees.y = 180.0
	# the first landing's west side, toward the gap that is never closed, a level below it
	_rail(_frame, Vector3(C - SIDE * 0.5, height(0), C), false, SIDE)
	_city.wall(solid, Vector3(C - SIDE * 0.5, height(0), C), Vector3(0.06, 1.1, SIDE))
	# the way up from the floor: always there
	_ramp(Vector3(HALF + RUN, 0, C), Vector3(HALF, height(0), C), true)
	for hand in [-1.0, 1.0]: _city.wall(solid, Vector3(HALF + RUN * 0.5, 0, C + hand * 0.6), Vector3(RUN, 1.6, 0.06))
	# the three gaps: rails and stringers, planks that can be laid, and a bar across the gap until they are
	var ends := [
		[Vector3(C, height(0), C - SIDE * 0.5), Vector3(C, height(1), -C + SIDE * 0.5)],
		[Vector3(C - SIDE * 0.5, height(1), -C), Vector3(-C + SIDE * 0.5, height(2), -C)],
		[Vector3(-C, height(2), -C + SIDE * 0.5), Vector3(-C, height(3), C - SIDE * 0.5)],
	]
	for k in 3:
		var low: Vector3 = ends[k][0]
		var high: Vector3 = ends[k][1]
		var made: Dictionary = _ramp(low, high, false)
		_ramps.append(made["planks"])
		_ramp_solids.append(made["shape"])
		var runs_z: bool = absf(high.z - low.z) > absf(high.x - low.x)
		var middle: Vector3 = (low + high) * 0.5
		for hand in [-1.0, 1.0]:
			var off := Vector3(hand * 0.6, 0, 0) if runs_z else Vector3(0, 0, hand * 0.6)
			_city.wall(solid, Vector3(middle.x, low.y, middle.z) + off, Vector3(0.06, RISE + 1.1, RUN) if runs_z else Vector3(RUN, RISE + 1.1, 0.06))
		# the bar, with what it says on the side of the landing it closes
		var bar := Node3D.new()
		bar.name = "Bar%d" % k
		bar.position = low
		bar.rotation_degrees.y = [0.0, 90.0, 180.0][k]
		_frame.add_child(bar)
		_box(bar, Vector3(0, 0.9, 0), Vector3(SIDE - 0.1, 0.07, 0.03), _plain(HOT))
		_box(bar, Vector3(0, 1.12, 0), Vector3(1.16, 0.36, 0.02), _city.flat(DARK, 0.85))      # low: the sentence across the gap is seen over it
		var says: Label3D = _words(bar, Vector3(0, 1.12, 0.02), 22, 0.003, PALE)
		says.text = "G%d  IS TRUE UP THERE.\nNO PLANKS LEAD TO IT FROM\n%s" % [k, system(k)]
		_bars.append(bar)
		_bar_solids.append(_city.wall(solid, low, Vector3(0.06, 1.1, SIDE) if not runs_z else Vector3(SIDE, 1.1, 0.06)))
		# the plate on the landing below the gap
		var at := _centre(k)
		_tiles.append(_box(_frame, Vector3(at.x, at.y + 0.012, at.z), Vector3(PLATE, 0.02, PLATE), _city.flat(GLOW, 0.8)))
		var add_words: Label3D = _city.floor_words(_frame, Vector3(at.x, at.y + 0.035, at.z), "ADD\nIT", 40, DARK)
		add_words.outline_size = 0
	# the fourth gap is never closed: tape across the last landing's east side, and what it says
	var last := _centre(3)
	var tape := Node3D.new()
	tape.position = Vector3(last.x + SIDE * 0.5, last.y, last.z)
	tape.rotation_degrees.y = -90.0
	_frame.add_child(tape)
	for high_at in [0.55, 0.95]: _box(tape, Vector3(0, high_at, 0), Vector3(SIDE - 0.1, 0.06, 0.008), _plain(Color("ff3b30")))
	_box(tape, Vector3(0, 1.15, 0), Vector3(1.16, 0.3, 0.02), _city.flat(DARK, 0.85))
	_words(tape, Vector3(0, 1.15, 0.02), 24, 0.003, PALE).text = "G3  IS TRUE UP THERE.\nTHE FLOOR ENDS HERE."
	_city.wall(solid, Vector3(last.x + SIDE * 0.5, last.y, last.z), Vector3(0.06, 1.1, SIDE))
	# the level above the first landing: a shelf on its four posts, where the next sentence stands
	var first := _centre(0)
	_city.part(_frame, "timber_panel_2x2", Vector3(first.x, 2.5 - 0.06, first.z), 0.0, Vector3(SIDE, 0.06, SIDE), false)
	# the sentences: G0, G1, G2 in the outer corner of the landing above each gap; G3 on the shelf
	for k in 4:
		var at := Vector3(first.x, 2.5, first.z)
		if k < 3:
			var above := _centre(k + 1)
			var corner: Vector2 = CORNERS[k + 1]
			at = Vector3(above.x + corner.x * 0.38, above.y, above.z + corner.y * 0.38)
		var thing: Node3D = _city.part(_frame, "pentagonal_bipyramid_7", at, 18.0 * float(k), Vector3(0.3, 0.46, 0.3), false)
		_things.append(thing)
		var halo := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.23
		disc.bottom_radius = 0.23
		disc.height = 0.012
		halo.mesh = disc
		halo.material_override = _plain(GLOW)
		halo.position = at + Vector3(0, 0.012, 0)
		_frame.add_child(halo)
		_halos.append(halo)
		var tag: Label3D = _words(_frame, at + Vector3(0, 0.68, 0), 44, 0.003, GLOW)
		tag.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		tag.double_sided = true
		_tags.append(tag)
	# START AGAIN, on the floor beside the board
	_box(_frame, Vector3(RESET_AT.x, 0.012, RESET_AT.y), Vector3(0.84, 0.02, 0.84), _city.flat(PALE, 0.8))
	var again: Label3D = _city.floor_words(_frame, Vector3(RESET_AT.x, 0.035, RESET_AT.y), "START\nAGAIN", 46, DARK)
	again.outline_size = 0
	_city.floor_words(_frame, Vector3(HALF + RUN + 0.5, 0.03, C), "the way up to  T", 40, PALE).rotation_degrees.y = 90.0
	# the stand: in the well of the square, above heads, read from the way in
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(0.0, 0, 0.0)
	stand.rotation_degrees.y = 90.0
	_frame.add_child(stand)
	_box(stand, Vector3(0, 4.1, -0.05), Vector3(4.3, 1.7, 0.06), _city.flat(DARK, 0.85))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 0.92, 1.63, -0.05), Vector3(0.08, 3.26, 0.08), _city.flat(DARK, 0.85))
	var heights := [4.7, 4.38, 4.06]
	var sizes := [30, 24, 34]
	var colours := [PALE, Color("b9c0cc"), HOT]
	for i in 3: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.007, colours[i]))
	_status = _words(stand, Vector3(0, 3.56, 0), 17, 0.007, Color("f2a23a"))
	_board = _city.board(_frame, Vector3(HALF + RUN + 0.3, 0, C - 1.85), 2.3, 1.5)


## ---- for a test ----

func state() -> Dictionary:
	return {"planks": planks, "laid": _laid, "gaps_open": gaps_open(_laid), "on": _on, "top": _top, "system": system(_on) if _on >= 0 else "",
		"bars": _bar_solids.map(func(s): return not s.disabled), "ramps": _ramp_solids.map(func(s): return not s.disabled),
		"sentences_shown": _things.filter(func(t): return t.visible).size(), "axioms": _tags.filter(func(t): return t.visible and t.text.contains("axiom")).size(),
		"lines": _lines.map(func(l): return l.text), "status": _status.text, "board": _board.text if _board != null else "", "build_ms": _build_ms}


## A landing's centre, the plate on it, in the world.
func landing_point(n: int) -> Vector3:
	return _frame.to_global(_centre(n))


func reset_point() -> Vector3:
	return _frame.to_global(Vector3(RESET_AT.x, 0, RESET_AT.y))


## A point on the floor in the square's frame (its centre at 0, 0; +x east, +z south).
func local_point(x: float, z: float) -> Vector3:
	return _frame.to_global(Vector3(x, 0, z))


func in_frame(at: Vector3) -> Vector3:
	return _frame.to_local(at)
