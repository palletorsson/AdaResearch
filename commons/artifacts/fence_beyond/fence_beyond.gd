extends Node3D
## EVERY FENCE HAS SOMETHING BEYOND IT (floor Russell_Paradox; the pass, gone back to on 2026-11-16)
##
## The hall, of cell 6 of its workbench: "The new rule begins with a collection that already exists: U. Filter its
## members rather than collecting from everything whatsoever." "None contains itself, so all four survive the
## filter. The result is U again. But U is not one of those four members. The collection and a member of the
## collection are different things." "The result still lies outside the domain being filtered." This is that
## construction as a yard a body can walk into and out of - a PREFAB ASSEMBLAGE form, from the lab's planks and
## crates.
##
## A yard fenced with plank rails holds four things: 0, 1, 2, 3. Just outside its gate stands one more thing: the
## four taken together. FENCE IT IN builds a wider fence round the yard and that thing: it is a member now, and
## has a number, 4. The same filter over the wider yard gives all five together - and that stands outside again.
## Once more. The fourth fence is tape, two sides of it: the floor ends before the argument does.
##
## A stand counts what is inside the outermost fence and what is outside it: always one. It also says where the
## visitor stands: inside which fence, or outside all of them, with that one thing.
##
## `fences` is the axis: one, two, three, tape.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const HALVES := [0.9, 1.4, 1.9, 2.4]     # half the side of each fence; the last is the tape
const GATE_FROM := -0.85                  # the way through each south side, from here ...
const GATE_TO := -0.05                    # ... to here
const STAGES := ["one", "two", "three", "tape"]
const PLATE_AT := Vector2(-1.9, 3.3)
const PLATE := 0.84
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const GLOW := Color("ffe14a")
const DIM := Color("7c8090")
const TAPE := Color("d8262c")

@export_enum("one", "two", "three", "tape") var fences := "one"

var _city = City.new()
var _stage := 1                           # how many fences stand (the fourth is the tape)
var _rings: Array[Node3D] = []            # what is seen of fence 2, fence 3 and the tape
var _ring_solids := []                    # the collision shapes of fence 2 and fence 3
var _things: Array[Node3D] = []           # the thing outside fence 1, 2, 3 and the tape
var _halos: Array[MeshInstance3D] = []
var _tags: Array[Label3D] = []
var _within := -1                         # the innermost standing fence the visitor is inside; 0: outside all
var _plate_tile: MeshInstance3D
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_fences"): _take({"fences": get_meta("config_fences")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("fences") and STAGES.has(str(config_data["fences"])): fences = str(config_data["fences"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := fences
	_take(config_data)
	if is_inside_tree() and _board != null and fences != before: _found()


func _found() -> void:
	_stage = STAGES.find(fences) + 1
	_show()
	_tell()


## ---- the rule ----

## How many things the outermost standing fence holds: the four, and one more for each fence built round them.
static func inside(stage: int) -> int:
	return 4 + stage - 1


## The thing that stands outside: the things inside, taken together.
static func together(stage: int) -> String:
	var names := PackedStringArray()
	for i in inside(stage): names.append(str(i))
	return "{ " + ", ".join(names) + " }"


## The innermost standing fence a place is inside (1, 2, 3; the tape has no south side and holds nobody); 0: none.
func fence_round(at: Vector2) -> int:
	for k in mini(_stage, 3):
		if absf(at.x) < float(HALVES[k]) and absf(at.y) < float(HALVES[k]): return k + 1
	return 0


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var level: bool = absf(p.y) < 1.5
	var near: bool = level and absf(p.x) < 4.2 and p.z > -3.2 and p.z < 4.6
	var within: int = fence_round(Vector2(p.x, p.z)) if near else -1
	if within != _within:
		_within = within
		_show()
	var region := "plate" if level and absf(p.x - PLATE_AT.x) < PLATE * 0.5 and absf(p.z - PLATE_AT.y) < PLATE * 0.5 else ""
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		_stage = _stage % 4 + 1
		fences = STAGES[_stage - 1]
		_show()
		_tell()


func _status_text() -> String:
	match _stage:
		1: return "FILTER THE YARD: KEEP WHAT DOES NOT CONTAIN ITSELF. ALL FOUR STAY.\nTOGETHER THEY ARE ONE MORE THING, AND IT IS NOT IN THE YARD."
		4: return "THE LAST FENCE IS TAPE, AND TWO SIDES OF IT.\nTHE FLOOR ENDS BEFORE THE ARGUMENT DOES. NOTHING IS EVERYTHING."
	return "YOU FENCED IT IN: IT IS A MEMBER NOW, AND HAS A NUMBER.\nTHE SAME FILTER GIVES ONE MORE THING. IT IS OUTSIDE AGAIN."


func _show() -> void:
	for k in 3: _rings[k].visible = _stage >= k + 2
	for k in 2:
		for shape in _ring_solids[k]: (shape as CollisionShape3D).disabled = _stage < k + 2
	for k in 4:
		_things[k].visible = k < _stage
		_halos[k].visible = k == _stage - 1
		_tags[k].visible = k < _stage
		_tags[k].text = together(k + 1) if k == _stage - 1 else str(4 + k)
		_tags[k].modulate = GLOW if k == _stage - 1 else DIM
	_lines[0].text = "INSIDE THE FENCE:   %d" % inside(_stage)
	_lines[1].text = "OUTSIDE IT:   1"
	_lines[2].text = "fences built:  %d%s" % [_stage, "  (the last is tape)" if _stage == 4 else ""]
	if _within > 0: _lines[3].text = "you stand inside fence %d of %d" % [_within, mini(_stage, 3)]
	elif _within == 0: _lines[3].text = "YOU STAND OUTSIDE EVERY FENCE HERE.
SO DOES  %s" % together(_stage)
	else: _lines[3].text = ""
	_status.text = _status_text()
	(_plate_tile.material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if _stage > 1 else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["EVERY FENCE HAS SOMETHING BEYOND IT"])
	lines.append("In the yard: four things, 0, 1, 2, 3. Keep the ones that do not contain themselves: all four. Taken together they are one more thing. It is not one of the four. It stands outside the gate.")
	lines.append("Stand on FENCE IT IN. A wider fence takes that thing in: it is a member now. Filter again: all five, together, outside again. Walk in through the gates and out, and count on the stand.")
	lines.append("What was a contradiction at the workbench is here a way of always finding the next thing. The fourth fence is tape. Who else is outside it?")
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


## A plank on edge as a rail, 0.9 m up: `metres` long (1, 2 or 4), along x (yaw 0) or along z (yaw 90).
func _rail(parent: Node3D, at: Vector3, yaw: float, metres: int) -> void:
	var bar: Node3D = _city.part(parent, "timber_plank_%dm" % metres, at + Vector3(0, 0.9, 0), yaw, Vector3.ZERO, false)
	bar.rotation_degrees.x = 90.0


func _post(parent: Node3D, at: Vector3) -> void:
	var post: Node3D = _city.part(parent, "timber_plank_1m", at + Vector3(0, 0.5, 0), 0.0, Vector3.ZERO, false)
	post.rotation_degrees.z = 90.0


## One fence: rails on three sides and on the south side either side of the way through; what holds a body.
## `pieces`: the planks of a full side (metres and where their middles lie along it).
func _fence(parent: Node3D, solid: StaticBody3D, half: float, pieces: Array, west: Array, east: Array) -> Array:
	var shapes: Array = []
	for piece in pieces:
		_rail(parent, Vector3(float(piece[1]), 0, -half), 0.0, int(piece[0]))
		_rail(parent, Vector3(-half, 0, float(piece[1])), 90.0, int(piece[0]))
		_rail(parent, Vector3(half, 0, float(piece[1])), 90.0, int(piece[0]))
	for piece in west + east: _rail(parent, Vector3(float(piece[1]), 0, half), 0.0, int(piece[0]))
	shapes.append(_city.wall(solid, Vector3(0, 0, -half), Vector3(half * 2.0, 1.1, 0.08)))
	shapes.append(_city.wall(solid, Vector3(-half, 0, 0), Vector3(0.08, 1.1, half * 2.0)))
	shapes.append(_city.wall(solid, Vector3(half, 0, 0), Vector3(0.08, 1.1, half * 2.0)))
	if half + GATE_FROM > 0.05: shapes.append(_city.wall(solid, Vector3((-half + GATE_FROM) * 0.5, 0, half), Vector3(half + GATE_FROM, 1.1, 0.08)))
	shapes.append(_city.wall(solid, Vector3((GATE_TO + half) * 0.5, 0, half), Vector3(half - GATE_TO, 1.1, 0.08)))
	for corner in [Vector3(-half, 0, -half), Vector3(half, 0, -half), Vector3(-half, 0, half), Vector3(half, 0, half), Vector3(GATE_FROM, 0, half), Vector3(GATE_TO, 0, half)]: _post(parent, corner)
	return shapes


func _build_once() -> void:
	var solid := StaticBody3D.new()
	solid.name = "Fences"
	add_child(solid)
	# the yard: four things, and the first fence, which always stands
	_fence(self, solid, float(HALVES[0]), [[2, 0.0]], [], [[1, 0.45]])
	var places := [Vector2(-0.55, -0.55), Vector2(0.0, -0.6), Vector2(0.55, -0.55), Vector2(0.55, 0.1)]
	for i in 4:
		_city.part(self, "crate", Vector3(places[i].x, 0, places[i].y), 12.0 * float(i), Vector3(0.34, 0.34, 0.34), false)
		var number: Label3D = _words(self, Vector3(places[i].x, 0.52, places[i].y), 56, 0.003, PALE)
		number.text = str(i)
		number.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		number.double_sided = true
	_city.wall(solid, Vector3(0.05, 0, -0.55), Vector3(1.5, 0.4, 0.4))
	# the second and third fence, built when asked for
	var plans := [[[2, -0.4], [1, 0.9]], [[4, 0.0]]]
	for k in 2:
		var ring := Node3D.new()
		ring.name = "Fence%d" % (k + 2)
		add_child(ring)
		_ring_solids.append(_fence(ring, solid, float(HALVES[k + 1]), plans[k], [[1, -1.35]], [[2, 0.95]]))
		_rings.append(ring)
	# the fourth: tape on thin posts, the west and the north side only
	var tape := Node3D.new()
	tape.name = "Tape"
	add_child(tape)
	var far: float = float(HALVES[3])
	_box(tape, Vector3(0, 0.9, -far), Vector3(far * 2.0, 0.06, 0.008), _plain(TAPE))
	_box(tape, Vector3(-far, 0.9, 0), Vector3(0.008, 0.06, far * 2.0), _plain(TAPE))
	for corner in [Vector3(-far, 0, -far), Vector3(far, 0, -far), Vector3(-far, 0, far), Vector3(0, 0, -far), Vector3(-far, 0, 0)]: _box(tape, corner + Vector3(0, 0.47, 0), Vector3(0.04, 0.94, 0.04), _city.flat(DARK, 0.8))
	_city.floor_words(tape, Vector3(-far + 1.3, 0.03, far + 0.3), "the floor ends here", 34, TAPE)
	_rings.append(tape)
	# the thing outside each fence: a crystal, a ring of light under the one that is outside now, and its name
	for k in 4:
		var at := Vector3(0.45, 0, float(HALVES[k]) + 0.25)
		var thing: Node3D = _city.part(self, "pentagonal_bipyramid_7", at, 18.0 * float(k), Vector3(0.3, 0.46, 0.3), false)
		_things.append(thing)
		var halo := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.23
		disc.bottom_radius = 0.23
		disc.height = 0.012
		halo.mesh = disc
		halo.material_override = _plain(GLOW)
		halo.position = at + Vector3(0, 0.012, 0)
		add_child(halo)
		_halos.append(halo)
		var tag: Label3D = _words(self, at + Vector3(0, 0.66, 0), 40, 0.003, GLOW)
		tag.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		tag.double_sided = true
		_tags.append(tag)
	_city.floor_words(self, Vector3((GATE_FROM + GATE_TO) * 0.5, 0.03, float(HALVES[3]) + 0.55), "the way in", 40, PALE)
	# the plate
	_plate_tile = _box(self, Vector3(PLATE_AT.x, 0.012, PLATE_AT.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8))
	_city.floor_words(self, Vector3(PLATE_AT.x, 0.035, PLATE_AT.y), "FENCE\nIT IN", 50, DARK).outline_size = 0
	# the stand, raised behind the yard and read across it; the board beside the way in
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(0.3, 0, -3.0)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 3.4, -0.05), Vector3(4.0, 2.4, 0.06), _city.flat(DARK, 0.85))
	for hand in [-1.0, 1.0]:
		_box(stand, Vector3(hand * 1.9, 1.1, -0.05), Vector3(0.08, 2.2, 0.08), _city.flat(DARK, 0.85))
		_city.wall(held, Vector3(hand * 1.9, 0, -0.05), Vector3(0.1, 4.6, 0.1))
	var heights := [4.3, 3.94, 3.62, 3.26]
	var sizes := [34, 34, 22, 20]
	var colours := [PALE, GLOW, Color("b9c0cc"), Color("9fe6ee")]
	for i in 4: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.006, colours[i]))
	_status = _words(stand, Vector3(0, 2.7, 0), 17, 0.006, Color("f2a23a"))
	_board = _city.board(self, Vector3(1.5, 0, 3.75), 2.3, 1.4)


## ---- for a test ----

func state() -> Dictionary:
	return {"stage": _stage, "inside": inside(_stage), "outside": 1, "outside_thing": together(_stage), "member_numbers": range(_stage - 1).map(func(k): return _tags[k].text), "visitor_within": _within,
		"fence_2_solid": not (_ring_solids[0][0] as CollisionShape3D).disabled, "fence_3_solid": not (_ring_solids[1][0] as CollisionShape3D).disabled, "tape_shown": _rings[2].visible,
		"lines": _lines.map(func(l): return l.text), "status": _status.text, "board": _board.text if _board != null else "", "build_ms": _build_ms}


func plate_point() -> Vector3:
	return to_global(Vector3(PLATE_AT.x, 0, PLATE_AT.y))


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
