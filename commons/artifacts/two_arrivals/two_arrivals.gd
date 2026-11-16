extends Node3D
## TWO ARRIVALS (floor PostCrisis_Synthesis; the pass, 2026-11-16)
##
## The hall, of its two bodies and its ledger: "Several different gestures can finish at the same coordinates. The
## figure keeps the destination." "The hand has arrived. Your hand is missing." "The missing path saves work and
## storage. It also closes a question." "What would you want the record to keep next? The path of the hand might
## let you compare two ways of arriving. Another version of the pose might let you undo a decision ... A note
## might keep the reason you tried it. Each addition would make another kind of return available. None would keep
## the whole event." This is that next record, for a walk - a ROBOT STATION form.
##
## A line on the floor from START to END. Walk it however you like: straight, round, with a stop. The work keeps
## the last two walks, the EARLIER in blue and the LATEST in amber (a memory that keeps two alternatives). A stand
## reads them twice. As a record of the DESTINATION: both arrived; the same. As a record of the PATH: how long
## each was, how long it took, its longest pause, how far it went from the line.
##
## KEEP THE PATH / ONLY THE DESTINATION chooses what the next walk's record holds. A walk recorded without its
## path never gets one back. At END three plates offer a NOTE for the latest walk - CAREFULLY, RELUCTANTLY, WITH
## DELIGHT - the three words the hall gives; the stand says they were written by somebody else.
##
## The work is found with two example walks. `keeps` is the axis: destination, path, note. The same arithmetic is
## benched in tools/probes/two_arrivals_bench.py.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const START := Vector2(-3.0, 0.0)
const END := Vector2(3.0, 0.0)
const HALF_X := 4.0
const HALF_Z := 3.0
const KEEPS := ["destination", "path", "note"]
const NOTES := ["CAREFULLY", "RELUCTANTLY", "WITH DELIGHT"]
const NOTE_X := 4.6
const KEEP_AT := Vector2(0.0, 3.3)
const PLATE := 0.84
const DOTS := 3000
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const BLUE := Color("6fb6ff")
const AMBER := Color("f2a23a")

@export_enum("destination", "path", "note") var keeps := "path"

var _city = City.new()
var _keep_path := true
var _walks: Array = [{}, {}]              # [earlier, latest]: {points, times, note, end}
var _recording := false
var _points := PackedVector2Array()
var _times := PackedFloat32Array()
var _clock := 0.0
var _trails: Array[MultiMeshInstance3D] = []
var _live: MultiMeshInstance3D
var _ends: Array[MeshInstance3D] = []
var _plate_tiles := {}
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_keeps"): _take({"keeps": get_meta("config_keeps")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("keeps") and KEEPS.has(str(config_data["keeps"])): keeps = str(config_data["keeps"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := keeps
	_take(config_data)
	if is_inside_tree() and _board != null and keeps != before: _found()


func _found() -> void:
	_keep_path = keeps != "destination"
	_recording = false
	_walks = [_record(example(false), true), _record(example(true), true)]
	if keeps == "destination":
		for w in _walks:
			w["points"] = PackedVector2Array()
			w["times"] = PackedFloat32Array()
	if keeps == "note": _walks[1]["note"] = "RELUCTANTLY"
	_lay()
	_show()
	_tell()


## ---- the rule ----

static func _leg(a: Vector2, b: Vector2, speed: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n: int = roundi(a.distance_to(b) / speed * 60.0)
	for i in range(1, n + 1): out.append(a.lerp(b, float(i) / float(n)))
	return out


## The two walks the work is found with: straight at 1.5 m/s; and by way of (0, -2) with three seconds standing.
static func example(second: bool) -> PackedVector2Array:
	var out := PackedVector2Array([START])
	if not second:
		out.append_array(_leg(START, END, 1.5))
		return out
	var mid := Vector2(0.0, -2.0)
	out.append_array(_leg(START, mid, 1.5))
	for i in 180: out.append(mid)
	out.append_array(_leg(mid, END, 1.0))
	return out


## A walk made into a record: its points and their times (or neither, when only the destination is kept).
func _record(points: PackedVector2Array, even: bool) -> Dictionary:
	var times := PackedFloat32Array()
	if even:
		for i in points.size(): times.append(float(i) / 60.0)
	else:
		times = _times.duplicate()
	return {"points": points if _keep_path else PackedVector2Array(), "times": times if _keep_path else PackedFloat32Array(), "note": "", "end": points[points.size() - 1] if points.size() > 0 else END}


## What a record of the path says of a walk: metres, seconds, longest pause, farthest from the line. Empty: {}.
static func measure(walk: Dictionary) -> Dictionary:
	var points: PackedVector2Array = walk.get("points", PackedVector2Array())
	var times: PackedFloat32Array = walk.get("times", PackedFloat32Array())
	if points.size() < 2: return {}
	var length := 0.0
	var pause := 0.0
	var longest := 0.0
	var off := 0.0
	for i in range(1, points.size()):
		var dt: float = times[i] - times[i - 1]
		var step: float = points[i].distance_to(points[i - 1])
		length += step
		if dt > 0.0 and step / dt < 0.2:
			pause += dt
			longest = maxf(longest, pause)
		else:
			pause = 0.0
		off = maxf(off, absf(points[i].y))
	return {"length": length, "seconds": times[times.size() - 1] - times[0], "pause": longest, "off": off}


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	_clock += delta
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var at := Vector2(p.x, p.z)
	var level: bool = absf(p.y) < 1.5
	# a walk begins on START and ends on END
	if level and at.distance_to(START) < 0.4:
		_recording = true
		_points = PackedVector2Array([at])
		_times = PackedFloat32Array([_clock])
	elif _recording:
		var inside: bool = level and absf(at.x) <= HALF_X + 0.8 and absf(at.y) <= HALF_Z + 0.6
		if inside and _points.size() < DOTS:
			_points.append(at)
			_times.append(_clock)
			if _points.size() % 8 == 0: _lay_live()
		if not inside or _points.size() >= DOTS:
			_recording = false
			_lay_live()
			_show()
		elif at.distance_to(END) < 0.4:
			_recording = false
			_walks = [_walks[1], _record(_points, false)]
			_points = PackedVector2Array()
			_lay()
			_show()
			_tell()
	var region := ""
	if level:
		if absf(p.x - KEEP_AT.x) < PLATE * 0.5 and absf(p.z - KEEP_AT.y) < PLATE * 0.5: region = "keep"
		for i in 3:
			if absf(p.x - NOTE_X) < 0.4 and absf(p.z - (float(i) - 1.0) * 1.0) < 0.4: region = "note:%d" % i
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		if region == "keep": _keep_path = not _keep_path
		else: _walks[1]["note"] = NOTES[int(region.trim_prefix("note:"))]
		_show()
		_tell()


## The two kept walks on the floor: a trail of dots each where its path was kept, and a ring where each ended.
func _lay() -> void:
	for k in 2:
		var points: PackedVector2Array = _walks[k].get("points", PackedVector2Array())
		var mesh: MultiMesh = _trails[k].multimesh
		mesh.visible_instance_count = points.size()
		for i in points.size(): mesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(points[i].x, 0.026 + 0.006 * float(k), points[i].y)))
		var end: Vector2 = _walks[k].get("end", END)
		_ends[k].position = Vector3(end.x, 0.05 + 0.01 * float(k), end.y)
	_lay_live()


func _lay_live() -> void:
	var mesh: MultiMesh = _live.multimesh
	mesh.visible_instance_count = _points.size() if _recording and _keep_path else 0
	for i in mesh.visible_instance_count: mesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(_points[i].x, 0.04, _points[i].y)))


func _path_line(name: String, walk: Dictionary) -> String:
	var m: Dictionary = measure(walk)
	if m.is_empty(): return "%s:   its path was not kept" % name
	return "%s:   %.2f m   ·   %.1f s   ·   longest pause %.1f s   ·   %.2f m off the line" % [name, float(m["length"]), float(m["seconds"]), float(m["pause"]), float(m["off"])]


func _show() -> void:
	_lines[0].text = "A RECORD OF THE DESTINATION:   earlier: arrived   ·   latest: arrived   ·   THE SAME"
	_lines[1].text = "A RECORD OF THE PATH:"
	_lines[2].text = _path_line("earlier", _walks[0])
	_lines[3].text = _path_line("latest", _walks[1])
	var note: String = str(_walks[1].get("note", ""))
	_lines[4].text = "A NOTE ON THE LATEST:   %s" % (("%s   (one of three words somebody else wrote)" % note) if note != "" else "none")
	if _recording: _status.text = "A WALK IS BEING %s. GO TO END." % ("FOLLOWED" if _keep_path else "WAITED FOR: ONLY ITS END WILL BE KEPT")
	elif not _keep_path: _status.text = "THE NEXT WALK WILL BE KEPT AS A DESTINATION ONLY.\nTHAT SAVES WORK AND STORAGE. IT ALSO CLOSES A QUESTION."
	elif measure(_walks[0]).is_empty() or measure(_walks[1]).is_empty(): _status.text = "A WALK KEPT WITHOUT ITS PATH DOES NOT GET ONE BACK.\nMORE PRECISE COORDINATES WOULD NOT RECOVER THE MOVEMENT."
	else: _status.text = "TWO WAYS OF ARRIVING AT ONE PLACE. WHY EITHER WAS WALKED\nIS IN NEITHER RECORD."
	((_plate_tiles["keep"] as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = PALE if _keep_path else Color("f6e39a")
	for i in 3: ((_plate_tiles["note:%d" % i] as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if note == NOTES[i] else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["TWO ARRIVALS"])
	lines.append("The amber body keeps where your hand ended. It does not keep how it got there. This floor keeps a walk instead. Go from START to END however you like: straight, round, with a stop on the way. The last two walks stay on the floor, the earlier in blue, the latest in amber.")
	lines.append("The stand reads them twice. As a record of the destination, they are the same. As a record of the path, they are not. The plate south of the line chooses what the next walk's record will hold; a walk kept without its path does not get one back.")
	lines.append("At END, three plates offer a note for the latest walk. The words are the hall's. They may not be yours. Two alternatives, a path, a reason in three words: each makes another kind of return possible. None keeps the walk.")
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


func _trail(colour: Color, size: float) -> MultiMeshInstance3D:
	var trail := MultiMeshInstance3D.new()
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	var dot := BoxMesh.new()
	dot.size = Vector3(size, 0.008, size)
	many.mesh = dot
	many.instance_count = DOTS
	many.visible_instance_count = 0
	trail.multimesh = many
	trail.material_override = _plain(colour)
	trail.custom_aabb = AABB(Vector3(-HALF_X - 1.0, 0, -HALF_Z - 1.0), Vector3(HALF_X * 2.0 + 2.0, 0.2, HALF_Z * 2.0 + 2.0))
	add_child(trail)
	return trail


func _disc(at: Vector3, radius: float, paint: Material) -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = 0.02
	disc.mesh = shape
	disc.material_override = paint
	disc.position = at
	add_child(disc)
	return disc


func _build_once() -> void:
	# the line, START and END
	_box(self, Vector3(0, 0.012, 0), Vector3(END.x - START.x, 0.008, 0.05), _plain(Color("5b6274")))
	for mark in [[START, "START"], [END, "END"]]:
		var at: Vector2 = mark[0]
		_disc(Vector3(at.x, 0.012, at.y), 0.4, _city.flat(PALE, 0.8))
		_city.floor_words(self, Vector3(at.x, 0.035, at.y), str(mark[1]), 52, DARK).outline_size = 0
	# the two kept walks and the one being made
	_trails = [_trail(BLUE, 0.06), _trail(AMBER, 0.06)]
	_live = _trail(PALE, 0.04)
	for k in 2:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.46 + 0.1 * float(k)
		torus.outer_radius = 0.52 + 0.1 * float(k)
		torus.rings = 40
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = _plain(BLUE if k == 0 else AMBER)
		ring.scale.y = 0.2
		add_child(ring)
		_ends.append(ring)
	# the plates: what the next record keeps; three words for a note
	_plate_tiles["keep"] = _box(self, Vector3(KEEP_AT.x, 0.012, KEEP_AT.y), Vector3(PLATE * 1.9, 0.02, PLATE), _city.flat(PALE, 0.8))
	_city.floor_words(self, Vector3(KEEP_AT.x, 0.035, KEEP_AT.y), "KEEP THE PATH  /\nONLY THE DESTINATION", 40, DARK).outline_size = 0
	for i in 3:
		var z: float = (float(i) - 1.0) * 1.0
		_plate_tiles["note:%d" % i] = _box(self, Vector3(NOTE_X, 0.012, z), Vector3(0.8, 0.02, 0.8), _city.flat(PALE, 0.8))
		_city.floor_words(self, Vector3(NOTE_X, 0.035, z), str(NOTES[i]).replace(" ", "\n"), 34, DARK).outline_size = 0
	_city.floor_words(self, Vector3(NOTE_X, 0.03, -1.9), "a note:", 40, PALE)
	# the stand
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-1.4, 0, -3.4)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 2.3, -0.05), Vector3(5.6, 2.3, 0.06), _city.flat(DARK, 0.85))
	_city.wall(held, Vector3(0, 0, -0.05), Vector3(5.6, 3.5, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 2.7, 0.58, -0.05), Vector3(0.08, 1.16, 0.08), _city.flat(DARK, 0.85))
	var heights := [3.16, 2.82, 2.52, 2.24, 1.92]
	var sizes := [22, 24, 22, 22, 22]
	var colours := [PALE, PALE, BLUE, AMBER, Color("b9c0cc")]
	for i in 5: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.005, colours[i]))
	_status = _words(stand, Vector3(0, 1.46, 0), 20, 0.005, Color("f6e39a"))
	_board = _city.board(self, Vector3(-5.2, 0, 2.6), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	var out := {"keep_path": _keep_path, "recording": _recording, "status": _status.text, "lines": _lines.map(func(l): return l.text), "board": _board.text if _board != null else "", "build_ms": _build_ms}
	for k in 2:
		var name: String = "earlier" if k == 0 else "latest"
		var m: Dictionary = measure(_walks[k])
		out[name] = {"kept_path": not m.is_empty(), "length": snappedf(float(m.get("length", -1.0)), 0.01), "seconds": snappedf(float(m.get("seconds", -1.0)), 0.01), "pause": snappedf(float(m.get("pause", -1.0)), 0.01),
			"off": snappedf(float(m.get("off", -1.0)), 0.01), "note": str(_walks[k].get("note", "")), "end_from_END": snappedf((_walks[k].get("end", END) as Vector2).distance_to(END), 0.01), "dots": _trails[k].multimesh.visible_instance_count}
	return out


func plate_point(key: String) -> Vector3:
	if key == "keep": return to_global(Vector3(KEEP_AT.x, 0, KEEP_AT.y))
	return to_global(Vector3(NOTE_X, 0, (float(NOTES.find(key)) - 1.0) * 1.0))


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
