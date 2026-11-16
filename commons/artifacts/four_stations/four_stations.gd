extends Node3D
## FOUR STATIONS, ONE WALK (floor SpeculativeComputation_Situated_Computation; the pass, 2026-11-16)
##
## The hall, of its four panels: "The four-way disagreement has been composed for us. The percentages have not been
## earned by measuring the subject." "Dangerous to whom, under which circumstances, and according to what
## consequence?" "For the room's next experiment, each panel could reveal a distinct criterion and the observation
## it used. A visitor could then compare disagreement caused by different evidence with disagreement caused by
## different definitions." This is that next experiment, with the visitor's own walk as the subject - a ROBOT
## STATION form.
##
## A field six metres square with a line up its middle, START at the south, END at the north. Four stations at its
## corners. Each sees only what comes within 3.4 m of it (an arc on the floor), and each has its own definition of
## DANGEROUS: off the line; fast; near me; staying. Walk from START to END: every station then says what it saw
## (how long, what share of the walk, how fast, how far off the line, how near), what DANGEROUS means to it, and
## its verdict. The walk stays on the floor as a trace, coloured by who saw each step; grey where nobody did.
##
## ONE DEFINITION gives all four the same meaning (speed): what disagreement is left comes from what each saw.
## ONE RECORD gives all four the whole walk: what is left comes from what each means. With both, they agree.
##
## The work is found with an example walk the builder made. `sharing` is the axis: own, one_definition,
## one_record, both. The same arithmetic is benched in tools/probes/four_stations_bench.py.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const HALF := 3.0
const REACH := 3.4
const START := Vector2(0.0, 2.6)
const END := Vector2(0.0, -2.6)
const NAMES := ["NW", "NE", "SW", "SE"]
const CORNERS := [Vector2(-3.0, -3.0), Vector2(3.0, -3.0), Vector2(-3.0, 3.0), Vector2(3.0, 3.0)]
const MEANS := ["more than 0.5 m off the line", "faster than 2.0 m/s", "within 1.5 m of me", "in my sight longer than 3 s"]
const TINTS := [Color("40d8ff"), Color("ffa040"), Color("ff6fb0"), Color("7af08a")]
const SHARING := {"own": [false, false], "one_definition": [true, false], "one_record": [false, true], "both": [true, true]}
const PLATES := [
	{"key": "definition", "says": "ONE\nDEFINITION", "x": -0.7},
	{"key": "record", "says": "ONE\nRECORD", "x": 0.7},
]
const PLATE_Z := 4.1
const PLATE := 0.84
const DOTS := 1500
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const BAD := Color("ff5a3c")
const FINE := Color("9fe6ee")

@export_enum("own", "one_definition", "one_record", "both") var sharing := "own"

var _city = City.new()
var _one_definition := false
var _one_record := false
var _points: PackedVector2Array = PackedVector2Array()      # the walk on the floor
var _times: PackedFloat32Array = PackedFloat32Array()
var _example := true
var _recording := false
var _clock := 0.0
var _trace: MultiMeshInstance3D
var _panels := []                         # per station: {saw, measures, means, verdict}
var _tally: Array[Label3D] = []
var _plate_tiles: Array[MeshInstance3D] = []
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_sharing"): _take({"sharing": get_meta("config_sharing")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("sharing") and SHARING.has(str(config_data["sharing"])): sharing = str(config_data["sharing"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := sharing
	_take(config_data)
	if is_inside_tree() and _board != null and sharing != before: _found()


func _found() -> void:
	_one_definition = SHARING[sharing][0]
	_one_record = SHARING[sharing][1]
	_recording = false
	_example = true
	_points = example_walk()
	_times = PackedFloat32Array()
	for i in _points.size(): _times.append(float(i) / 60.0)
	_lay_trace()
	_show()
	_tell()


## ---- the rule ----

## The walk the work is found with: 1.8 m up the line at 2.4 m/s, then 3.4 m northward at 0.6 m/s while swinging
## 1.4 m to the west and back.
static func example_walk() -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 45: out.append(Vector2(0.0, 2.6 - 2.4 * float(i) / 60.0))
	for i in 341:
		var z: float = 0.8 - 0.6 * float(i) / 60.0
		out.append(Vector2(-1.4 * sin(PI * (0.8 - z) / 3.4), z))
	return out


## What a station observed of the walk: seconds seen, share, top speed, most off the line, nearest. With `whole`
## it is given every step, seen or not.
func observe(station: int, whole: bool) -> Dictionary:
	var corner: Vector2 = CORNERS[station]
	var seen := 0.0
	var count := 0
	var top := 0.0
	var off := 0.0
	var near := 1e9
	for i in _points.size():
		var p: Vector2 = _points[i]
		if not whole and p.distance_to(corner) > REACH: continue
		count += 1
		if i > 0:
			var dt: float = _times[i] - _times[i - 1]
			seen += dt
			if dt > 0.0005: top = maxf(top, p.distance_to(_points[i - 1]) / dt)
		else:
			seen += 1.0 / 60.0
		off = maxf(off, absf(p.x))
		near = minf(near, p.distance_to(corner))
	return {"seen_s": seen, "share": float(count) / maxf(float(_points.size()), 1.0), "top": top, "off": off, "near": near}


## A station's verdict from what it observed, by its own definition or (one definition) by speed.
static func verdict(station: int, o: Dictionary, one_definition: bool) -> String:
	if float(o["seen_s"]) < 0.25: return "NOT SEEN"
	var rule: int = 1 if one_definition else station
	var hit := false
	match rule:
		0: hit = float(o["off"]) > 0.5
		1: hit = float(o["top"]) > 2.0
		2: hit = float(o["near"]) < 1.5
		3: hit = float(o["seen_s"]) > 3.0
	return "DANGEROUS" if hit else "NOT DANGEROUS"


func verdicts(one_definition: bool, one_record: bool) -> Array:
	var out: Array = []
	for s in 4: out.append(verdict(s, observe(s, one_record), one_definition))
	return out


static func _differ(list: Array) -> bool:
	for v in list:
		if v != list[0]: return true
	return false


## [the four differ as found, they still differ under one definition (so: from what each saw), they still differ
## given one record (so: from what each means)]
func causes() -> Array:
	return [_differ(verdicts(false, false)), _differ(verdicts(true, false)), _differ(verdicts(false, true))]


## Seconds of the walk that no station saw.
func unseen() -> float:
	var out := 0.0
	for i in _points.size():
		var any := false
		for corner in CORNERS:
			if _points[i].distance_to(corner) <= REACH: any = true
		if not any: out += (_times[i] - _times[i - 1]) if i > 0 else 1.0 / 60.0
	return out


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
	# a walk: it begins on START and ends on END (or where the visitor leaves the field)
	if level and at.distance_to(START) < 0.4 and (not _recording or _points.size() > 60):
		_recording = true
		_example = false
		_points = PackedVector2Array([at])
		_times = PackedFloat32Array([_clock])
		_lay_trace()
		_show()
	elif _recording:
		var inside: bool = level and absf(at.x) <= HALF + 0.3 and absf(at.y) <= HALF + 0.3
		if inside and _points.size() < DOTS:
			_points.append(at)
			_times.append(_clock)
			if _points.size() % 6 == 0: _lay_trace()
		if not inside or at.distance_to(END) < 0.4 or _points.size() >= DOTS:
			_recording = false
			_lay_trace()
			_show()
			_tell()
	var region := ""
	if level:
		for plate in PLATES:
			if absf(p.x - float(plate["x"])) < PLATE * 0.5 and absf(p.z - PLATE_Z) < PLATE * 0.5: region = str(plate["key"])
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		if region == "definition": _one_definition = not _one_definition
		else: _one_record = not _one_record
		_show()
		_tell()


## The walk as dots on the floor, each in the colour of the first station that saw it; grey where none did.
func _lay_trace() -> void:
	var mesh: MultiMesh = _trace.multimesh
	mesh.visible_instance_count = _points.size()
	for i in _points.size():
		var tint := Color("7c8090")
		for s in 4:
			if _points[i].distance_to(CORNERS[s]) <= REACH:
				tint = TINTS[s]
				break
		mesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(_points[i].x, 0.03, _points[i].y)))
		mesh.set_instance_color(i, tint)


func _show() -> void:
	var total: float = (_times[_times.size() - 1] - _times[0] + 1.0 / 60.0) if _times.size() > 0 else 0.0
	var counts := {"DANGEROUS": 0, "NOT DANGEROUS": 0, "NOT SEEN": 0}
	for s in 4:
		var panel: Dictionary = _panels[s]
		if _recording:
			(panel["saw"] as Label3D).text = "WATCHING..."
			(panel["measures"] as Label3D).text = ""
			(panel["verdict"] as Label3D).text = ""
			continue
		var o: Dictionary = observe(s, _one_record)
		var v: String = verdict(s, o, _one_definition)
		counts[v] += 1
		(panel["saw"] as Label3D).text = ("I WAS GIVEN THE WHOLE WALK: %.2f s" % float(o["seen_s"])) if _one_record else ("I SAW %.2f s OF %.2f s  (%d %%)" % [float(o["seen_s"]), total, int(round(float(o["share"]) * 100.0))])
		(panel["measures"] as Label3D).text = "fastest %.2f m/s   ·   %.2f m off the line\nnearest to me %.2f m" % [float(o["top"]), float(o["off"]), float(o["near"])] if float(o["seen_s"]) >= 0.25 else "too little to measure"
		(panel["means"] as Label3D).text = "DANGEROUS MEANS:\n%s" % str(MEANS[1 if _one_definition else s])
		(panel["verdict"] as Label3D).text = v
		(panel["verdict"] as Label3D).modulate = BAD if v == "DANGEROUS" else (FINE if v == "NOT DANGEROUS" else Color("8a90a0"))
	if _recording:
		_tally[0].text = "A WALK IS BEING WATCHED."
		_tally[1].text = "Go to END."
		_tally[2].text = ""
		_tally[3].text = ""
	else:
		var why: Array = causes()
		_tally[0].text = "ONE WALK%s\n%d say DANGEROUS  ·  %d say NOT  ·  %d did not see it" % [" (the builder's example)" if _example else " (yours)", counts["DANGEROUS"], counts["NOT DANGEROUS"], counts["NOT SEEN"]]
		var now: bool = _differ(verdicts(_one_definition, _one_record))
		if _one_definition and _one_record: _tally[1].text = "ONE DEFINITION, ONE RECORD: " + ("THEY STILL DIFFER." if now else "THEY AGREE.")
		elif _one_definition: _tally[1].text = "ONE DEFINITION: " + ("WHAT IS LEFT COMES FROM WHAT EACH SAW." if now else "THEY AGREE. THE DIFFERENCE WAS IN THE MEANINGS.")
		elif _one_record: _tally[1].text = "ONE RECORD: " + ("WHAT IS LEFT COMES FROM WHAT EACH MEANS." if now else "THEY AGREE. THE DIFFERENCE WAS IN WHAT EACH SAW.")
		elif not why[0]: _tally[1].text = "AS FOUND, THE FOUR AGREE."
		else: _tally[1].text = "AS FOUND THEY DIFFER: FROM " + ("WHAT EACH SAW AND WHAT EACH MEANS." if why[1] and why[2] else ("WHAT EACH SAW." if why[1] else "WHAT EACH MEANS."))
		_tally[2].text = "%.2f s of this walk no station saw." % unseen()
		_tally[3].text = "A share seen is a number that was earned. It is not a confidence."
	for i in PLATES.size():
		var lit: bool = (str(PLATES[i]["key"]) == "definition" and _one_definition) or (str(PLATES[i]["key"]) == "record" and _one_record)
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if lit else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["FOUR STATIONS, ONE WALK"])
	lines.append("The subject is a walk: from START up the field to END, however you like. Four stations stand at the corners. Each sees only what comes inside its arc, and each means something different by DANGEROUS: off the line, fast, near me, staying. Walk, then read all four. The trace on the floor shows who saw each step; grey where nobody did.")
	lines.append("ONE DEFINITION gives all four the same meaning. If they still disagree, it is because of what each saw. ONE RECORD gives all four the whole walk. If they still disagree, it is because of what each means. With both, they agree.")
	lines.append("The share each station saw is a number it earned. None of the four says whether you are dangerous. Ask each one: to whom, and by what consequence?")
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


func _build_once() -> void:
	# the field: its edge, its line, START and END
	var edge: StandardMaterial3D = _plain(Color("5b6274"))
	for hand in [-1.0, 1.0]:
		_box(self, Vector3(hand * HALF, 0.012, 0), Vector3(0.04, 0.008, HALF * 2.0), edge)
		_box(self, Vector3(0, 0.012, hand * HALF), Vector3(HALF * 2.0, 0.008, 0.04), edge)
	_box(self, Vector3(0, 0.014, 0), Vector3(0.06, 0.008, START.y - END.y), _plain(PALE))
	for mark in [[START, "START"], [END, "END"]]:
		var disc := MeshInstance3D.new()
		var shape := CylinderMesh.new()
		shape.top_radius = 0.4
		shape.bottom_radius = 0.4
		shape.height = 0.02
		disc.mesh = shape
		disc.material_override = _city.flat(PALE, 0.8)
		disc.position = Vector3((mark[0] as Vector2).x, 0.012, (mark[0] as Vector2).y)
		add_child(disc)
		_city.floor_words(self, Vector3((mark[0] as Vector2).x, 0.035, (mark[0] as Vector2).y), str(mark[1]), 52, DARK).outline_size = 0
	# the four stations: a post, the arc it sees within, a panel turned to the middle of the field
	var solid := StaticBody3D.new()
	add_child(solid)
	for s in 4:
		var corner: Vector2 = CORNERS[s]
		var paint: StandardMaterial3D = _plain(TINTS[s])
		for k in 25:
			var a: float = atan2(-corner.y, -corner.x) + deg_to_rad(-45.0 + 90.0 * float(k) / 24.0)
			var at: Vector2 = corner + Vector2(cos(a), sin(a)) * REACH
			if absf(at.x) > HALF or absf(at.y) > HALF: continue
			var dash: MeshInstance3D = _box(self, Vector3(at.x, 0.016, at.y), Vector3(0.05, 0.008, 0.16), paint)
			dash.rotation.y = -a
		var station := Node3D.new()
		station.name = "Station%s" % NAMES[s]
		station.position = Vector3(corner.x, 0, corner.y)
		station.rotation.y = atan2(-corner.x, -corner.y)          # its face toward the middle of the field
		add_child(station)
		_box(station, Vector3(0, 0.6, 0), Vector3(0.1, 1.2, 0.1), _city.flat(DARK, 0.8))
		_box(station, Vector3(0, 1.22, 0.02), Vector3(0.3, 0.06, 0.06), paint)
		_box(station, Vector3(0, 2.04, 0), Vector3(2.0, 1.66, 0.05), _city.flat(DARK, 0.85))
		_city.wall(solid, Vector3(corner.x, 0, corner.y), Vector3(0.3, 2.8, 0.3))
		_words(station, Vector3(0, 2.7, 0.04), 34, 0.004, TINTS[s]).text = "STATION %s" % NAMES[s]
		var panel := {"saw": _words(station, Vector3(0, 2.48, 0.04), 24, 0.004, PALE), "measures": _words(station, Vector3(0, 2.22, 0.04), 20, 0.004, Color("b9c0cc")),
			"means": _words(station, Vector3(0, 1.86, 0.04), 24, 0.004, Color("f6e39a")), "verdict": _words(station, Vector3(0, 1.44, 0.04), 52, 0.004, PALE)}
		_panels.append(panel)
	# the trace
	_trace = MultiMeshInstance3D.new()
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.use_colors = true
	var dot := BoxMesh.new()
	dot.size = Vector3(0.07, 0.01, 0.07)
	many.mesh = dot
	many.instance_count = DOTS
	many.visible_instance_count = 0
	_trace.multimesh = many
	var ink: StandardMaterial3D = _plain(Color.WHITE)
	ink.vertex_color_use_as_albedo = true
	_trace.material_override = ink
	_trace.custom_aabb = AABB(Vector3(-HALF - 0.5, 0, -HALF - 0.5), Vector3(HALF * 2.0 + 1.0, 0.2, HALF * 2.0 + 1.0))
	add_child(_trace)
	# the plates
	for plate in PLATES:
		_plate_tiles.append(_box(self, Vector3(float(plate["x"]), 0.012, PLATE_Z), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(float(plate["x"]), 0.035, PLATE_Z), str(plate["says"]), 48, DARK).outline_size = 0
	# the tally
	var stand := Node3D.new()
	stand.name = "Tally"
	stand.position = Vector3(0, 0, -4.4)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 3.42, -0.05), Vector3(5.4, 1.72, 0.06), _city.flat(DARK, 0.85))
	_city.wall(held, Vector3(-2.3, 0, -0.05), Vector3(0.1, 4.1, 0.1))
	_city.wall(held, Vector3(2.3, 0, -0.05), Vector3(0.1, 4.1, 0.1))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 2.3, 1.3, -0.05), Vector3(0.08, 2.6, 0.08), _city.flat(DARK, 0.85))
	var heights := [3.96, 3.48, 3.14, 2.84]
	var sizes := [28, 28, 22, 20]
	var colours := [PALE, Color("f2a23a"), Color("b9c0cc"), Color("f6e39a")]
	for i in 4: _tally.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.0055, colours[i]))
	_board = _city.board(self, Vector3(0.0, 0, 5.7), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	var stations := []
	for s in 4:
		var o: Dictionary = observe(s, _one_record)
		stations.append({"name": NAMES[s], "seen_s": snappedf(float(o["seen_s"]), 0.01), "share": snappedf(float(o["share"]), 0.001), "top": snappedf(float(o["top"]), 0.01), "off": snappedf(float(o["off"]), 0.01),
			"near": snappedf(float(o["near"]), 0.01), "verdict": verdict(s, o, _one_definition)})
	return {"one_definition": _one_definition, "one_record": _one_record, "example": _example, "recording": _recording, "samples": _points.size(), "stations": stations, "verdicts": verdicts(_one_definition, _one_record),
		"causes": causes(), "unseen_s": snappedf(unseen(), 0.01), "dots": _trace.multimesh.visible_instance_count, "tally": _tally.map(func(l): return l.text), "board": _board.text if _board != null else "", "build_ms": _build_ms}


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3(float(plate["x"]), 0, PLATE_Z))
	return global_position


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
