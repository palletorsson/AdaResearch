extends Node3D
## ASKED, READ BACK, MEASURED (floor QFEP_Synthesis; the pass, 2026-11-15)
##
## The hall, of its specimen: "The intended mapping, the number on the plate and the mechanical response are three
## things we have to check against one another." "In the engine used here, drag is unused; changing the stiffness
## property on a running body does not rebuild its existing constraints. Pressure and damping do update." "A
## property readback alone cannot establish that a running constraint changed." "Steady pressure is something you
## have given it. Stillness would be something else." "A future observation could preserve a trace of deformation
## over time." This is that account with a body tall enough to watch - a ROBOT STATION form.
##
## A mast three metres tall on a sprung foot. PULSE strikes it and it sways. A stand has three columns for each of
## three properties - ASKED (the plate), READ BACK (the property), MEASURED (from the mast's own motion: the time
## of a swing, and how much of a swing is left after one more) - and under them the trace: the tip's place over
## the last twelve seconds.
##
## The plates ask. DAMPING is taken at once. STIFFNESS is read back at once and does nothing until REBUILD: the
## spring that is running was built before. DRAG is asked, read back, and used by nothing. The rings on the foot
## are the spring as built. BREATHE / STEADY gives or stops a slow imposed sway: steady, the mast goes on moving
## from whatever struck it, and the stand says steady is not still.
##
## The motion is computed here in four small steps a tick (the floor above this one is about why). `built` is the
## axis: soft, middle, stiff - the spring the mast is found with.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const STIFF := [4.0, 9.0, 16.0]          # per second squared: the swing's time is 2 pi / sqrt(k - c*c/4)
const DAMP := [0.2, 0.8, 2.0]            # per second
const DRAG := [0.0, 0.5, 1.0]            # asked and read back; nothing uses it
const BUILT := {"soft": 0, "middle": 1, "stiff": 2}
const TALL := 3.2
const STRIKE := 0.6                      # radians a second, given by PULSE
const WINDOW := 12.0                     # seconds of trace
const BARS := 96
const PLATES := [
	{"key": "stiff", "says": "STIFFNESS\n→", "x": -2.75},
	{"key": "rebuild", "says": "REBUILD", "x": -1.65},
	{"key": "damp", "says": "DAMPING\n→", "x": -0.55},
	{"key": "drag", "says": "DRAG\n→", "x": 0.55},
	{"key": "pulse", "says": "PULSE", "x": 1.65},
	{"key": "breathe", "says": "BREATHE\n/ STEADY", "x": 2.75},
]
const PLATE_Z := 2.6
const PLATE := 0.84
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const ASK := Color("f6e39a")
const READ := Color("9fe6ee")
const MEAS := Color("f2a23a")

@export_enum("soft", "middle", "stiff") var built := "middle"

var _city = City.new()
var _asked := [1, 1, 0]                  # indices into STIFF, DAMP, DRAG: what the plates ask
var _k := 9.0                            # the spring as built
var _angle := 0.0
var _speed := 0.0
var _breathing := false
var _clock := 0.0
var _pulses := 0
var _sample := 0.0
var _trace := PackedFloat32Array()
var _ups: Array[float] = []              # times of the last upward crossings of rest
var _peaks: Array[float] = []            # the last positive peaks
var _was := 0.0
var _rising := false
var _mast: Node3D
var _rings: Array[MeshInstance3D] = []
var _bars: Array[MeshInstance3D] = []
var _plate_tiles: Array[MeshInstance3D] = []
var _cells := []                         # [row][column] Label3D
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_built"): _take({"built": get_meta("config_built")})
	_trace.resize(BARS)
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("built") and BUILT.has(str(config_data["built"])): built = str(config_data["built"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := built
	_take(config_data)
	if is_inside_tree() and _board != null and built != before: _found()


func _found() -> void:
	_asked = [int(BUILT[built]), 1, 0]
	_k = float(STIFF[int(BUILT[built])])
	_angle = 0.0
	_speed = 0.0
	_breathing = false
	_ups.clear()
	_peaks.clear()
	_trace.fill(0.0)
	_show()
	_tell()


## ---- the rule ----

## One tick of the mast: a spring that pulls it back and a damper that slows it, in four small steps.
static func swing(angle: float, speed: float, k: float, c: float, delta: float) -> Vector2:
	var h: float = delta / 4.0
	for i in 4:
		speed += (-k * angle - c * speed) * h
		angle += speed * h
	return Vector2(angle, speed)


## The time of one swing, measured between the last two times the mast passed rest going east; -1 when it has not.
func measured_period() -> float:
	return _ups[-1] - _ups[-2] if _ups.size() >= 2 else -1.0


## How much of a swing is left one swing later: the last peak over the one before; -1 when there are not two.
func measured_left() -> float:
	return _peaks[-1] / _peaks[-2] if _peaks.size() >= 2 and _peaks[-2] > 0.002 else -1.0


func damping() -> float:
	return float(DAMP[int(_asked[1])])           # taken at once


func moving() -> bool:
	return absf(_angle) > 0.004 or absf(_speed) > 0.01


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	_clock += delta
	var push: float = 0.35 * sin(_clock * 0.9) if _breathing else 0.0       # the imposed breathing: a slow push, not a place
	_speed += push * delta
	var next: Vector2 = swing(_angle, _speed, _k, damping(), delta)
	_was = _angle
	_angle = next.x
	_speed = next.y
	if _was < 0.0 and _angle >= 0.0:
		_ups.append(_clock)
		if _ups.size() > 4: _ups.pop_front()
	if _rising and _speed <= 0.0 and _angle > 0.002:
		_peaks.append(_angle)
		if _peaks.size() > 4: _peaks.pop_front()
	_rising = _speed > 0.0
	_mast.rotation.z = -_angle
	_sample += delta
	if _sample >= WINDOW / float(BARS):
		_sample = 0.0
		for i in BARS - 1: _trace[i] = _trace[i + 1]
		_trace[BARS - 1] = _angle * TALL
		for i in BARS:
			var tall: float = clampf(_trace[i], -0.75, 0.75)
			_bars[i].scale.y = maxf(absf(tall), 0.004)
			_bars[i].position.y = tall * 0.5
		_show()
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var region := ""
	if absf(p.y) < 1.5:
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
		_press(region)


func _press(key: String) -> void:
	match key:
		"stiff": _asked[0] = (int(_asked[0]) + 1) % 3
		"damp": _asked[1] = (int(_asked[1]) + 1) % 3
		"drag": _asked[2] = (int(_asked[2]) + 1) % 3
		"rebuild":
			_k = float(STIFF[int(_asked[0])])
			_ups.clear()
			_peaks.clear()
		"pulse":
			_speed += STRIKE
			_pulses += 1
			_ups.clear()
			_peaks.clear()
		"breathe": _breathing = not _breathing
	_show()
	_tell()


func _status_text() -> String:
	if not is_equal_approx(float(STIFF[int(_asked[0])]), _k):
		return "STIFFNESS: ASKED AND READ BACK AGREE. THE SPRING THAT IS RUNNING\nWAS BUILT BEFORE. NOTHING CHANGES UNTIL REBUILD."
	if int(_asked[2]) != 0:
		return "DRAG IS ASKED FOR AND READ BACK. NOTHING HERE USES IT:\nTHE MEASURED COLUMN IS WHERE THAT SHOWS."
	if not _breathing and moving():
		return "STEADY IS WHAT YOU GAVE IT. IT IS NOT STILL:\nIT GOES ON MOVING FROM WHAT STRUCK IT."
	if _breathing: return "BREATHING: A SLOW PUSH THE MAKER CHOSE. IT IS NOT THE MAST'S OWN."
	return "STAND ON PULSE, AND WATCH THE MEASURED COLUMN."


func _show() -> void:
	var period: float = measured_period()
	var left: float = measured_left()
	var rows := [
		["%.0f" % float(STIFF[int(_asked[0])]), "%.0f" % float(STIFF[int(_asked[0])]), ("a swing takes %.2f s" % period) if period > 0.0 else "—"],
		["%.1f" % damping(), "%.1f" % damping(), ("%.2f left after one swing" % left) if left > 0.0 else "—"],
		["%.1f" % float(DRAG[int(_asked[2])]), "%.1f" % float(DRAG[int(_asked[2])]), "used by nothing"],
	]
	for r in 3:
		for c in 3: (_cells[r][c] as Label3D).text = str(rows[r][c])
	_status.text = _status_text()
	var built_rings: int = 3 + 3 * STIFF.find(_k)
	for i in _rings.size(): _rings[i].visible = i < built_rings
	for i in PLATES.size():
		var key: String = str(PLATES[i]["key"])
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = ASK if (key == "breathe" and _breathing) or (key == "rebuild" and not is_equal_approx(float(STIFF[int(_asked[0])]), _k)) else PALE


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["ASKED, READ BACK, MEASURED"])
	lines.append("A mast on a sprung foot. Stand on PULSE: it is struck, and sways. The stand keeps three columns: what a plate ASKED for, what the property READS BACK, and what was MEASURED from the mast's own motion. Under them, the tip's place over the last twelve seconds.")
	lines.append("Ask for more DAMPING: it is taken at once, and the trace dies sooner. Ask for more STIFFNESS: the first two columns change, the third does not, until REBUILD - the rings on the foot are the spring as built. Ask for DRAG: asked, read back, used by nothing.")
	lines.append("BREATHE / STEADY gives or stops a slow imposed sway. Steady is something you gave it. Stillness would be something else. A readback alone cannot tell you that a running body changed. Measure.")
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
	# the foot, with the spring as built shown in rings
	var solid := StaticBody3D.new()
	add_child(solid)
	_box(self, Vector3(0, 0.15, 0), Vector3(0.7, 0.3, 0.7), _city.flat(DARK, 0.8))
	_city.wall(solid, Vector3.ZERO, Vector3(0.7, 0.3, 0.7))
	for i in 9:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.1
		torus.outer_radius = 0.16
		torus.rings = 24
		torus.ring_segments = 8
		ring.mesh = torus
		ring.material_override = _city.flat(MEAS, 0.5)
		ring.position = Vector3(0, 0.34 + 0.07 * float(i), 0)
		add_child(ring)
		_rings.append(ring)
	_mast = Node3D.new()
	_mast.name = "Mast"
	_mast.position = Vector3(0, 0.3, 0)
	add_child(_mast)
	var pole := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.035
	rod.bottom_radius = 0.06
	rod.height = TALL
	pole.mesh = rod
	pole.material_override = _city.flat(Color("6b4a32"), 0.8)
	pole.position = Vector3(0, TALL * 0.5, 0)
	_mast.add_child(pole)
	var top := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.16
	ball.height = 0.32
	top.mesh = ball
	top.material_override = _city.flat(Color("7a3fa0"), 0.4)
	top.position = Vector3(0, TALL, 0)
	_mast.add_child(top)
	_city.floor_words(self, Vector3(0, 0.03, 0.75), "it sways east and west", 44, PALE)
	# the plates
	for plate in PLATES:
		_plate_tiles.append(_box(self, Vector3(float(plate["x"]), 0.012, PLATE_Z), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(float(plate["x"]), 0.035, PLATE_Z), str(plate["says"]), 56, DARK).outline_size = 0
	# the stand: three columns for three properties, and the trace
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-1.3, 0, -3.3)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 1.75, -0.05), Vector3(4.2, 3.0, 0.06), _city.flat(DARK, 0.85))
	_city.wall(held, Vector3(0, 0, -0.05), Vector3(4.2, 3.3, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 1.95, 0.13, -0.05), Vector3(0.08, 0.26, 0.08), _city.flat(DARK, 0.85))
	var heads := [["ASKED", ASK, -0.75], ["READ BACK", READ, 0.05], ["MEASURED", MEAS, 1.25]]
	for head in heads: _words(stand, Vector3(float(head[2]), 3.02, 0), 30, 0.004, head[1]).text = str(head[0])
	var names := ["stiffness", "damping", "drag"]
	for r in 3:
		var y: float = 2.72 - 0.3 * float(r)
		_words(stand, Vector3(-1.6, y, 0), 30, 0.004, PALE).text = str(names[r])
		var row := []
		for c in 3: row.append(_words(stand, Vector3(float(heads[c][2]), y, 0), 40 if c < 2 else 28, 0.004, heads[c][1]))
		_cells.append(row)
	_status = _words(stand, Vector3(0, 1.72, 0), 26, 0.004, Color("f6e39a"))
	_box(stand, Vector3(0, 0.72, 0.0), Vector3(3.6, 0.006, 0.01), _plain(Color("5b6274")))
	_words(stand, Vector3(-1.05, 1.36, 0), 22, 0.004, Color("b9c0cc")).text = "the tip's place, the last 12 s"
	var paint: StandardMaterial3D = _plain(Color("c9a0e6"))
	for i in BARS:
		var bar: MeshInstance3D = _box(stand, Vector3(-1.78 + 3.56 * float(i) / float(BARS - 1), 0.72, 0.006), Vector3(0.026, 1.0, 0.004), paint)
		bar.scale.y = 0.004
		_bars.append(bar)
		# a bar is a child of a holder at the trace's zero line, so that its height can grow either way
		var holder := Node3D.new()
		holder.position = bar.position
		stand.add_child(holder)
		bar.reparent(holder)
		bar.position = Vector3.ZERO
	_board = _city.board(self, Vector3(-4.7, 0, 2.0), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	return {"built": built, "asked": [float(STIFF[int(_asked[0])]), damping(), float(DRAG[int(_asked[2])])], "read_back": [float(STIFF[int(_asked[0])]), damping(), float(DRAG[int(_asked[2])])], "built_k": _k,
		"period_s": snappedf(measured_period(), 0.001), "left": snappedf(measured_left(), 0.001), "rings": _rings.filter(func(r): return r.visible).size(), "breathing": _breathing, "moving": moving(), "pulses": _pulses,
		"tip_m": snappedf(_angle * TALL, 0.001), "trace_peak_m": snappedf(maxf(absf(Array(_trace).max()), absf(Array(_trace).min())), 0.001), "status": _status.text, "board": _board.text if _board != null else "", "build_ms": _build_ms}


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3(float(plate["x"]), 0, PLATE_Z))
	return global_position
