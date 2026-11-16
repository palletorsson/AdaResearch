extends Node3D
## THE WAY ROUND (floor SpeculativeComputation_Rhizome_Network; the pass, 2026-11-16)
##
## The hall, of its cave: "Which connections can a body enter, and which can it only see?" "From outside, you can
## follow several passages with your eyes." "Nearness is not yet a relation you can enter." "One added connection
## can change what a journey is." "We can enter its relations and choose among them; we cannot yet make a new
## opening in its wall. That is a desire the encounter can produce."
##
## The cave stands out over the void: its near mouth is seven metres past the north edge of the floor. As it was
## placed, a body could only see it. This is the way to it and round it - a PREFAB ASSEMBLAGE form, from the lab's
## own planks and panels.
##
## A plank footbridge (4 m and 2 m planks, joints staggered, plank rails) from the north edge into the cave's near
## mouth. And an outer way: a gangway of two-metre panels from the cave's far mouth, round its north-east corner
## and back down its east side toward the east wing - from which the passages can be followed with the eyes, one
## rising across another. The outer way stops 1.7 m short of the floor. From the wing it can be seen and not
## entered. A plate on the floor and a plate on the gangway each lay the last panel, or lift it: with it laid
## there is a way out of the cave that is not the way in.
##
## The tower keeps this floor awake, and counts the visitor as standing on it, wherever they are on the bridges
## or in the cave. `panel` is the axis: up, laid.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const EDGE := -0.8                        # the floor's north edge, in the work's own measure (north is -z)
const IN_END := -8.75                     # where the footbridge ends, a metre inside the near mouth
const IN_WIDE := 1.5
const FAR_MOUTH := -35.5                  # the cave's far mouth
const OUT_X := 16.0                       # the outer way's line down the cave's east side
const TURN_Z := -36.5                     # its line across the cave's far end
const GAP_FROM := -2.5                    # the gangway's last fixed panel ends here; the floor's edge is 1.7 m on
const PANELS := ["up", "laid"]
const PLATES := [
	{"key": "floor", "says": "LAY / LIFT\nTHE PANEL", "at": Vector2(17.7, 0.4)},
	{"key": "gangway", "says": "LAY / LIFT\nTHE PANEL", "at": Vector2(16.0, -4.5)},
]
const PLATE := 0.84
const DARK := Color("191e29")
const PALE := Color("efe9dc")

@export_enum("up", "laid") var panel := "up"

var _city = City.new()
var _laid := false
var _last_panel: Node3D
var _last_solid: CollisionShape3D
var _plate_tiles: Array[MeshInstance3D] = []
var _lines: Array[Label3D] = []
var _status: Label3D
var _gap_says: Label3D
var _board: Label3D
var _parts_built := 0
var _gangway_done := false
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	add_to_group("void_floor_extension")
	add_to_group("void_exterior_walk")
	if has_meta("config_panel"): _take({"panel": get_meta("config_panel")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()
	_build_gangway()


func _take(config_data: Dictionary) -> void:
	if config_data.has("panel") and PANELS.has(str(config_data["panel"])): panel = str(config_data["panel"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := panel
	_take(config_data)
	if is_inside_tree() and _board != null and panel != before: _found()


func _found() -> void:
	_laid = panel == "laid"
	_show()
	_tell()


## The tower keeps this floor awake while its visitor is on the bridges or in the cave, however far out.
func contains_visitor(at: Vector3) -> bool:
	var p := to_local(at)
	return absf(p.y) < 8.5 and p.z < 0.2 and p.z > -40.6 and p.x > -16.6 and p.x < 18.2


## How many ways lead between the floor and the cave.
func ways() -> int:
	return 2 if _laid else 1


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var region := ""
	if absf(p.y) < 1.5:
		for plate in PLATES:
			var at: Vector2 = plate["at"]
			if absf(p.x - at.x) < PLATE * 0.5 and absf(p.z - at.y) < PLATE * 0.5: region = str(plate["key"])
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		_laid = not _laid
		_show()
		_tell()


func _show() -> void:
	_last_panel.visible = _laid
	_last_solid.disabled = not _laid
	_lines[1].text = "WAYS BETWEEN THIS FLOOR AND THE CAVE:   %d" % ways()
	if _laid:
		_status.text = "ONE PANEL ADDED. THERE IS NOW A WAY OUT THAT IS NOT THE WAY IN:\nTHROUGH THE CAVE, AND BACK ROUND ITS OUTSIDE."
		_gap_says.text = "one panel"
	else:
		_status.text = "THE OUTER WAY ENDS 1.7 m FROM THE FLOOR, ON THE EAST WING.\nYOU CAN SEE IT. YOU CANNOT ENTER IT. LAY THE PANEL, FROM EITHER SIDE."
		_gap_says.text = "1.7 m"
	for tile in _plate_tiles: (tile.material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if _laid else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["THE WAY ROUND"])
	lines.append("The cave stands out over the void. The plank footbridge ahead goes into its near mouth: walk in. Inside, the passages divide and meet; you can come back to a place by another way. The cave has a second mouth at its far end.")
	lines.append("From that far mouth a gangway goes round the outside of the cave and back down its east side. Walk it and follow with your eyes the passages you were in: one rises across another. It stops 1.7 m short of the floor. Near is not yet a way.")
	lines.append("A plate at each end of the gap lays the last panel, or lifts it. You cannot make a new opening in the cave's wall. You can add this one connection, and see what it does to the journey.")
	_board.text = "\n".join(lines)


## ---- building ----

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


## A plank on edge as a rail, 0.9 m up: `metres` long (1, 2 or 4), along x (yaw 0) or along z (yaw 90).
func _rail(at: Vector3, yaw: float, metres: int) -> void:
	var bar: Node3D = _city.part(self, "timber_plank_%dm" % metres, at + Vector3(0, 0.9, 0), yaw, Vector3.ZERO, false)
	bar.rotation_degrees.x = 90.0
	_parts_built += 1


## An upright: a two-metre plank that goes from under the deck to the rail.
func _post(at: Vector3) -> void:
	var post: Node3D = _city.part(self, "timber_plank_2m", at + Vector3(0, 0.05, 0), 0.0, Vector3.ZERO, false)
	post.rotation_degrees.z = 90.0
	_parts_built += 1


func _panel(parent: Node3D, token: String, at: Vector3) -> void:
	_city.part(parent, token, at, 0.0, Vector3.ZERO, false)
	_parts_built += 1


## What holds a body - the decks and their rails as plain solids - and the footbridge, the plates and the stand.
func _build_once() -> void:
	var solid := StaticBody3D.new()
	solid.name = "Decks"
	add_child(solid)
	var in_long: float = EDGE - IN_END
	_city.wall(solid, Vector3(0, -0.4, (EDGE + IN_END) * 0.5), Vector3(IN_WIDE, 0.4, in_long + 0.1))
	for hand in [-1.0, 1.0]: _city.wall(solid, Vector3(hand * (IN_WIDE * 0.5 + 0.03), 0, EDGE - 4.0), Vector3(0.06, 1.1, 7.0))
	# the outer way: down the cave's east side, across its far end, and a threshold in the far mouth
	var south_long: float = GAP_FROM - (TURN_Z - 1.0)
	_city.wall(solid, Vector3(OUT_X, -0.4, GAP_FROM - south_long * 0.5), Vector3(2.0, 0.4, south_long))
	_city.wall(solid, Vector3((OUT_X - 1.0 - 1.0) * 0.5, -0.4, TURN_Z), Vector3(OUT_X, 0.4, 2.0))
	_city.wall(solid, Vector3(0, -0.4, FAR_MOUTH + 0.5), Vector3(2.0, 0.4, 1.0))
	_city.wall(solid, Vector3(OUT_X + 1.03, 0, GAP_FROM - south_long * 0.5), Vector3(0.06, 1.1, south_long))
	_city.wall(solid, Vector3(OUT_X - 1.03, 0, (GAP_FROM + FAR_MOUTH) * 0.5), Vector3(0.06, 1.1, GAP_FROM - FAR_MOUTH))
	_city.wall(solid, Vector3(8.0, 0, TURN_Z - 1.03), Vector3(18.0, 1.1, 0.06))
	_city.wall(solid, Vector3(8.5, 0, TURN_Z + 1.03), Vector3(13.0, 1.1, 0.06))
	_city.wall(solid, Vector3(-1.03, 0, TURN_Z), Vector3(0.06, 1.1, 2.0))
	# the last panel: from the gangway's end to the floor's edge
	_last_solid = _city.wall(solid, Vector3(OUT_X, -0.4, (GAP_FROM + EDGE) * 0.5), Vector3(2.0, 0.4, EDGE - GAP_FROM + 0.1))
	_last_panel = Node3D.new()
	_last_panel.name = "LastPanel"
	add_child(_last_panel)
	_panel(_last_panel, "timber_panel_2x2", Vector3(OUT_X, -0.035, (GAP_FROM + EDGE) * 0.5))
	_gap_says = _city.floor_words(self, Vector3(OUT_X - 2.0, 0.03, EDGE + 0.5), "1.7 m", 60, PALE)
	# the plank footbridge into the near mouth: six rows, 4 + 4 m and 2 + 4 + 2 m, so the joints of neighbours do not meet
	for r in 6:
		var x: float = (float(r) - 2.5) * 0.25
		var pieces := [4, 4] if r % 2 == 0 else [2, 4, 2]
		var at: float = EDGE + 0.05
		for piece in pieces:
			_city.part(self, "timber_plank_%dm" % int(piece), Vector3(x, -0.055, at - float(piece) * 0.5), 90.0, Vector3.ZERO, false)
			_parts_built += 1
			at -= float(piece)
	for hand in [-1.0, 1.0]:
		var x: float = hand * (IN_WIDE * 0.5 + 0.03)
		for z in [EDGE - 2.5, EDGE - 6.5]: _rail(Vector3(x, 0, z), 90.0, 4)
		for z in [EDGE - 0.5, EDGE - 4.5]: _post(Vector3(x, 0, z))
	_city.floor_words(self, Vector3(0, 0.03, EDGE + 0.55), "the way in", 52, PALE)
	# the plates: one on the floor, one on the gangway beyond the gap
	for plate in PLATES:
		var at: Vector2 = plate["at"]
		_plate_tiles.append(_box(self, Vector3(at.x, 0.018, at.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(at.x, 0.042, at.y), str(plate["says"]), 44, DARK).outline_size = 0
	# the stand, beside the way in
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-2.7, 0, 0.45)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 1.75, -0.05), Vector3(3.3, 1.7, 0.06), _city.flat(DARK, 0.85))
	_city.wall(held, Vector3(0, 0, -0.05), Vector3(3.3, 2.6, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 1.5, 0.45, -0.05), Vector3(0.08, 0.9, 0.08), _city.flat(DARK, 0.85))
	_lines.append(_words(stand, Vector3(0, 2.36, 0), 26, 0.004, PALE))
	_lines[0].text = "THE CAVE HAS TWO MOUTHS.\nTHIS BRIDGE GOES INTO THE NEAR ONE."
	_lines.append(_words(stand, Vector3(0, 1.94, 0), 30, 0.004, Color("f6e39a")))
	_status = _words(stand, Vector3(0, 1.4, 0), 20, 0.004, Color("f2a23a"))
	_board = _city.board(self, Vector3(3.2, 0, 2.6), 3.2, 1.7)


## The gangway's panels, rails and uprights: laid a few a frame, so the floor does not stall as it arrives.
func _build_gangway() -> void:
	var laid := 0
	_panel(self, "timber_panel_2x1", Vector3(OUT_X, -0.045, GAP_FROM - 0.5))
	_panel(self, "timber_panel_2x1", Vector3(0, -0.045, FAR_MOUTH + 0.5))
	for k in 16:
		_panel(self, "timber_panel_2x2", Vector3(OUT_X, -0.045, GAP_FROM - 2.0 - 2.0 * float(k)))
		laid += 1
		if laid % 4 == 0: await get_tree().process_frame
	for k in 9:
		_panel(self, "timber_panel_2x2", Vector3(OUT_X - 2.0 * float(k), -0.045, TURN_Z))
		laid += 1
		if laid % 4 == 0: await get_tree().process_frame
	# rails: the east side and the west side of the run south, the north and the south side of the run across
	for k in 8:
		_rail(Vector3(OUT_X + 1.03, 0, GAP_FROM - 2.0 - 4.0 * float(k)), 90.0, 4)
		_rail(Vector3(OUT_X - 1.03, 0, GAP_FROM - 2.0 - 4.0 * float(k)), 90.0, 4)
		for side in [-1.03, 1.03]: _post(Vector3(OUT_X + side, 0, GAP_FROM - 4.0 * float(k) - 0.1))
		await get_tree().process_frame
	_rail(Vector3(OUT_X + 1.03, 0, GAP_FROM - 33.0), 90.0, 2)
	_rail(Vector3(OUT_X + 1.03, 0, GAP_FROM - 34.5), 90.0, 1)
	_rail(Vector3(OUT_X - 1.03, 0, GAP_FROM - 32.5), 90.0, 1)
	for side in [-1.03, 1.03]: _post(Vector3(OUT_X + side, 0, GAP_FROM - 32.1))
	for k in 4:
		_rail(Vector3(OUT_X - 1.0 - 4.0 * float(k), 0, TURN_Z - 1.03), 0.0, 4)
		_post(Vector3(OUT_X + 0.9 - 4.0 * float(k), 0, TURN_Z - 1.03))
		if k < 3:
			_rail(Vector3(OUT_X - 3.0 - 4.0 * float(k), 0, TURN_Z + 1.03), 0.0, 4)
			_post(Vector3(OUT_X - 1.1 - 4.0 * float(k), 0, TURN_Z + 1.03))
		await get_tree().process_frame
	_rail(Vector3(0.0, 0, TURN_Z - 1.03), 0.0, 2)
	_rail(Vector3(2.5, 0, TURN_Z + 1.03), 0.0, 1)
	_rail(Vector3(-1.03, 0, TURN_Z), 90.0, 2)
	for at in [Vector3(-0.9, 0, TURN_Z - 1.03), Vector3(2.1, 0, TURN_Z + 1.03), Vector3(-1.03, 0, TURN_Z + 0.9)]: _post(at)
	_gangway_done = true


## ---- for a test ----

func state() -> Dictionary:
	return {"panel": "laid" if _laid else "up", "ways": ways(), "last_panel_solid": not _last_solid.disabled, "last_panel_shown": _last_panel.visible, "parts": _parts_built, "gangway_done": _gangway_done,
		"status": _status.text, "lines": _lines.map(func(l): return l.text), "board": _board.text if _board != null else "", "build_ms": _build_ms}


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3((plate["at"] as Vector2).x, 0, (plate["at"] as Vector2).y))
	return global_position


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
