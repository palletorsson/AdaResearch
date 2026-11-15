extends Node3D
## THE SAME RULE IN LARGER STEPS (floor QFEP_Edge_Of_Chaos; the pass, 2026-11-15)
##
## The hall: "Which changes belong to the model, and which belong to the way its calculation is run?" Its console
## shows one reaction-diffusion field twice, from the same start to the same model time, the second in twice as
## many smaller steps. "Making the picture run faster does not make its calculation more precise." "A low value
## means these calculations are close in that particular respect." And of an earlier version of its own screen:
## it "made its pattern partly by overshooting and clipping its values; that too was something code had made."
## This is that comparison with a rule simple enough to check on foot - a PLAYGROUND form.
##
## The rule: go round the pole, always at right angles to the line to it, at one rate. A circle, drawn pale on the
## floor. Computed a step at a time from START for one turn of model time, every step leaves the circle a little
## (the radius is multiplied by sqrt(1 + dt^2)), so the computation ends outside it: 24 steps end 3.54 m from the
## pole, 48 steps 2.41 m, 96 steps 1.96 m; the rule says 1.60 m. Two computations lie on the floor at a time, in
## stones and tape: amber the coarser, cyan the finer. Walk them. The spiral is not in the rule. The steps made it.
##
## A plate halves both step sizes: the ends come closer to each other and to the rule. WALL stands a ring two
## metres from the pole that clips whatever passes it: then the two ends agree to 0.20 m, neither is where the
## rule ends, and the coarse path is a ring the wall made. A ball runs the coarser path; RUN FASTER moves it three
## times as fast, along the same stones.
##
## Benched in tools/probes/step_spiral_bench.py. `pair` is the axis: coarse (24 and 48 steps), fine (48 and 96).
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const PAIR := {"coarse": [24, 48], "fine": [48, 96]}
const R0 := 1.6
const WALL := 2.0
const LAP := 12.0                        # seconds for the ball's run at x1
const PLATES := [
	{"key": "coarse", "says": "DT\n.26 / .13", "at": Vector2(-2.4, 3.9)},
	{"key": "fine", "says": "DT\n.13 / .065", "at": Vector2(-1.2, 3.9)},
	{"key": "wall", "says": "WALL", "at": Vector2(0.0, 3.9)},
	{"key": "fast", "says": "RUN\nFASTER", "at": Vector2(1.2, 3.9)},
]
const PLATE := 0.84
const AMBER := Color("f2a23a")
const CYAN := Color("40f2ff")
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const RED := Color("e01a29")

@export_enum("coarse", "fine") var pair := "coarse"

var _city = City.new()
var _paths: Node3D
var _wall_ring: MeshInstance3D
var _ball: MeshInstance3D
var _plate_tiles: Array[MeshInstance3D] = []
var _clip := false
var _fast := false
var _coarse := PackedVector2Array()
var _finer := PackedVector2Array()
var _run := 0.0
var _laps := 0
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_pair"): _take({"pair": get_meta("config_pair")})
	var began := Time.get_ticks_msec()
	_build_once()
	_draw()
	_build_ms = Time.get_ticks_msec() - began
	_tell()


func _take(config_data: Dictionary) -> void:
	if config_data.has("pair") and PAIR.has(str(config_data["pair"])): pair = str(config_data["pair"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := pair
	_take(config_data)
	if is_inside_tree() and _board != null and pair != before: _draw()


## ---- the rule ----

## One turn of model time from START in `steps` equal steps, the plain way: each step goes at right angles to the
## line from the pole, by the step's length times the distance. With a wall, whatever passes it is put back on it.
static func path(steps: int, wall: float = -1.0) -> PackedVector2Array:
	var dt: float = TAU / float(steps)
	var p := Vector2(R0, 0.0)
	var out := PackedVector2Array([p])
	for i in steps:
		p = Vector2(p.x + dt * p.y, p.y - dt * p.x)          # from east toward north; north is -z
		if wall > 0.0 and p.length() > wall: p = p * (wall / p.length())
		out.append(p)
	return out


func steps() -> Array:
	return PAIR[pair]


func difference() -> float:
	return _coarse[-1].distance_to(_finer[-1])


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _process(delta: float) -> void:
	# the ball runs the coarser path in model time, waits a second at its end, and runs again
	_run += delta * (3.0 if _fast else 1.0) / LAP
	if _run >= 1.0 + 1.0 / LAP:
		_run = 0.0
		_laps += 1
	var at: float = clampf(_run, 0.0, 1.0) * float(_coarse.size() - 1)
	var i: int = mini(int(floor(at)), _coarse.size() - 2)
	var here: Vector2 = _coarse[i].lerp(_coarse[i + 1], at - float(i))
	_ball.position = Vector3(here.x, 0.14, here.y)


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
		if region == "wall": _clip = not _clip
		elif region == "fast": _fast = not _fast
		else: pair = region
		_draw()
		_tell()


func _status_text() -> String:
	if _clip: return "THE WALL CLIPS WHATEVER PASSES IT. THE TWO ENDS AGREE BETTER.\nNEITHER IS WHERE THE RULE ENDS."
	if pair == "fine": return "SMALLER STEPS: THE ENDS ARE CLOSER TO EACH OTHER,\nAND TO THE RULE. THEY ARE NOT ON IT."
	return "THE SPIRAL IS NOT IN THE RULE.\nTHE STEPS MADE IT."


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["THE SAME RULE IN LARGER STEPS"])
	lines.append("The rule: go round the pole, always at right angles to the line to it, at one rate. That is the pale circle. Here it is computed a step at a time, from START, for one turn of model time, in two step sizes: amber the coarser, cyan the finer. Walk both.")
	lines.append("Every step leaves the circle a little, so both end outside it, the coarser further. The first plates change the step sizes. Which changes belong to the rule, and which to the way it was run?")
	lines.append("WALL clips whatever passes two metres, as an earlier version of the hall's screen clipped its values. The ends then agree better. Look where they are. RUN FASTER moves the ball three times as fast along the same stones: faster is not finer.")
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


func _plain(colour: Color) -> StandardMaterial3D:
	var paint: StandardMaterial3D = _city.flat(colour, 0.9)
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return paint


func _ring(radius: float, tube: float, lift: float, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - tube
	torus.outer_radius = radius + tube
	torus.rings = 96
	torus.ring_segments = 6
	mesh.mesh = torus
	mesh.material_override = paint
	mesh.position = Vector3(0, lift, 0)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh


## One computation on the floor: a stone at every place, tape between them, and a larger stone at its end.
func _lay(places: PackedVector2Array, colour: Color, lift: float, name: String) -> void:
	var paint: StandardMaterial3D = _plain(colour)
	var small: float = 0.07 if places.size() <= 50 else 0.04
	var disc := CylinderMesh.new()
	disc.top_radius = small
	disc.bottom_radius = small
	disc.height = 0.012
	for i in places.size():
		var stone := MeshInstance3D.new()
		stone.mesh = disc
		stone.material_override = paint
		stone.position = Vector3(places[i].x, lift + 0.006, places[i].y)
		stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_paths.add_child(stone)
		if i == 0: continue
		var along: Vector2 = places[i] - places[i - 1]
		var tape: MeshInstance3D = _box(_paths, Vector3((places[i].x + places[i - 1].x) * 0.5, lift, (places[i].y + places[i - 1].y) * 0.5), Vector3(0.045, 0.006, along.length()), paint)
		tape.rotation.y = atan2(along.x, along.y)
	var end := MeshInstance3D.new()
	var big := CylinderMesh.new()
	big.top_radius = 0.18
	big.bottom_radius = 0.18
	big.height = 0.014
	end.mesh = big
	end.material_override = paint
	end.position = Vector3(places[-1].x, lift + 0.01, places[-1].y)
	end.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_paths.add_child(end)
	var words: Label3D = _city.floor_words(_paths, Vector3(places[-1].x + 0.55, lift + 0.02, places[-1].y + 0.28), name, 34, colour)
	words.outline_size = 5


func _draw() -> void:
	for child in _paths.get_children():
		_paths.remove_child(child)
		child.queue_free()
	var wall: float = WALL if _clip else -1.0
	_coarse = path(int(steps()[0]), wall)
	_finer = path(int(steps()[1]), wall)
	_lay(_coarse, AMBER, 0.022, "%d steps" % int(steps()[0]))
	_lay(_finer, CYAN, 0.03, "%d steps" % int(steps()[1]))
	_wall_ring.visible = _clip
	_run = 0.0
	_lines[0].text = "%d steps:  ends %.2f m from the pole" % [int(steps()[0]), _coarse[-1].length()]
	_lines[1].text = "%d steps:  ends %.2f m from the pole" % [int(steps()[1]), _finer[-1].length()]
	_lines[2].text = "the rule itself:  %.2f m" % R0
	_lines[3].text = "the two ends are %.2f m apart" % difference()
	_lines[4].text = "the ball runs at ×%d: the same stones" % (3 if _fast else 1)
	_status.text = _status_text()
	for i in PLATES.size():
		var key: String = str(PLATES[i]["key"])
		var lit: bool = key == pair or (key == "wall" and _clip) or (key == "fast" and _fast)
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if lit else PALE


func _build_once() -> void:
	_ring(R0, 0.018, 0.014, _plain(Color("cfc7b4")))
	_wall_ring = _ring(WALL, 0.05, 0.05, _plain(RED))
	_wall_ring.visible = false
	var pole := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.045
	rod.bottom_radius = 0.045
	rod.height = 1.3
	pole.mesh = rod
	pole.material_override = _city.flat(DARK, 0.7)
	pole.position = Vector3(0, 0.65, 0)
	add_child(pole)
	_city.floor_words(self, Vector3(0, 0.03, 0.3), "the pole", 30, PALE)
	_city.floor_words(self, Vector3(R0 + 0.1, 0.03, 0.42), "START", 40, PALE)
	_city.floor_words(self, Vector3(-R0 * 0.72, 0.03, -R0 * 0.72), "the rule: a circle", 28, Color("cfc7b4")).rotation_degrees.y = 45.0
	_paths = Node3D.new()
	_paths.name = "Paths"
	add_child(_paths)
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	_ball.mesh = sphere
	_ball.material_override = _city.flat(AMBER.lightened(0.3), 0.3)
	add_child(_ball)
	for plate in PLATES:
		var at: Vector2 = plate["at"]
		_plate_tiles.append(_box(self, Vector3(at.x, 0.012, at.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8)))
		_city.floor_words(self, Vector3(at.x, 0.035, at.y), str(plate["says"]), 30, DARK).outline_size = 0
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-0.3, 0, -3.6)
	add_child(stand)
	var solid := StaticBody3D.new()
	stand.add_child(solid)
	_box(stand, Vector3(0, 1.55, -0.05), Vector3(3.8, 2.5, 0.06), _city.flat(DARK, 0.85))
	_city.wall(solid, Vector3(0, 0, -0.05), Vector3(3.8, 2.8, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 1.75, 0.15, -0.05), Vector3(0.08, 0.3, 0.08), _city.flat(DARK, 0.85))
	_words(stand, Vector3(0, 2.6, 0), 30, 0.003, PALE).text = "ONE RULE  ·  ONE START  ·  ONE TURN OF MODEL TIME"
	var colours := [AMBER, CYAN, Color("cfc7b4"), PALE, Color("b9c0cc")]
	var heights := [2.26, 1.98, 1.7, 1.38, 0.6]
	var sizes := [38, 38, 30, 38, 24]
	for i in 5: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.003, colours[i]))
	_status = _words(stand, Vector3(0, 0.98, 0), 29, 0.003, Color("f6e39a"))
	_board = _city.board(self, Vector3(-4.4, 0, 3.4), 3.2, 1.7)


## ---- for a test ----

func state() -> Dictionary:
	var on_wall := 0
	for q in _coarse:
		if absf(q.length() - WALL) < 0.0001: on_wall += 1
	return {"pair": pair, "steps": steps(), "ends_m": [snappedf(_coarse[-1].length(), 0.001), snappedf(_finer[-1].length(), 0.001)], "rule_m": R0, "difference_m": snappedf(difference(), 0.001), "wall": _clip,
		"fast": _fast, "speed": 3 if _fast else 1, "on_wall": on_wall, "places": [_coarse.size(), _finer.size()], "laps": _laps, "status": _status.text, "lines": _lines.map(func(l): return l.text),
		"board": _board.text if _board != null else "", "build_ms": _build_ms}


## A place of one of the two computations on the floor (0 the coarser, 1 the finer); -1 is its end.
func stone_point(which: int, i: int) -> Vector3:
	var places: PackedVector2Array = _coarse if which == 0 else _finer
	var q: Vector2 = places[i]
	return to_global(Vector3(q.x, 0, q.y))


func pole_point() -> Vector3:
	return to_global(Vector3.ZERO)


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3((plate["at"] as Vector2).x, 0, (plate["at"] as Vector2).y))
	return global_position
