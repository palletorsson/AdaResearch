extends Node3D
## ONE NUMBER IS A LINE ON THIS FLOOR (floor QFEP_Introduction; the pass, 2026-11-15)
##
## The hall: "Can two different arrangements of a model produce the same number?" Its console answers with four
## rails and a KEEP button: "The outline remembers what the total cannot." This is that question at body size - a
## PLAYGROUND form.
##
## A painted floor six metres square. A step east is F, a step north is E. The floor is banded by the console's own
## total, F - lambda E + 0.3 phi: a tenth to a band. Stand still: the floor keeps that place - a flag, and a red
## line through every other place with the same total. Walk the line. The large number on the stand does not move;
## the four-axis shape beside it does, and the pale outline of the kept place stays. Two arrangements, one number:
## the number is a whole line, and it cannot say where on the line a body stands.
##
## Plates beside the floor set the other two controls. Lambda 0: the lines run north, and a walk in E changes
## nothing ("E's contribution passes through another control"). Phi 1: every place is 0.30 more, and the kept
## number is found somewhere else. AGAIN lets the floor keep a new place.
##
## It measures nothing. F and E here are where a body stands, as on the console they are where a rail stands; the
## change value 0.3 is fixed, as there. `weight` is the axis: the lambda the floor starts with (zero, half, one).
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const SKIN := preload("res://commons/artifacts/total_line/total_line.gdshader")
const WEIGHT := {"zero": 0.0, "half": 0.5, "one": 1.0}
const SIDE := 6.0
const HALF := 3.0
const CHANGE := 0.3                      # the console's fixed change value
const NEAR := 0.02                       # two totals this close are the same number, as the stand prints them
const PLATES := [
	{"key": "lam0", "says": "λ 0", "at": Vector2(3.75, 1.6), "lam": 0.0},
	{"key": "lamh", "says": "λ ½", "at": Vector2(3.75, 0.4), "lam": 0.5},
	{"key": "lam1", "says": "λ 1", "at": Vector2(3.75, -0.8), "lam": 1.0},
	{"key": "phi0", "says": "φ 0", "at": Vector2(-3.75, 1.6), "phi": 0.0},
	{"key": "phi1", "says": "φ 1", "at": Vector2(-3.75, 0.4), "phi": 1.0},
	{"key": "again", "says": "AGAIN", "at": Vector2(-3.75, -1.4)},
]
const PLATE := 0.84
const RADAR := 0.7
const DARK := Color("191e29")
const RED := Color("e01a29")              # the kept place and its line: not pink, which is the tower's own walk on every floor
const PALE := Color("efe9dc")
const AMBER := Color("e8a23a")

@export_enum("zero", "half", "one") var weight := "half"

var _city = City.new()
var _skin: ShaderMaterial
var _plate_tiles: Array[MeshInstance3D] = []
var _marks: Array[Label3D] = []
var _flag: Node3D
var _flag_words: Label3D
var _number: Label3D
var _line_here: Label3D
var _line_kept: Label3D
var _line_same: Label3D
var _shape: ImmediateMesh
var _outline: Array[MeshInstance3D] = []
var _board: Label3D
var _lam := 0.5
var _phi := 0.0
var _here := Vector2(-9, -9)             # (F, E) of the visitor on the floor
var _kept: Array = []                    # [F, E, lambda, phi, total]
var _same := false
var _found := 0
var _pair: Array = []
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_weight"): _take({"weight": get_meta("config_weight")})
	_lam = float(WEIGHT[weight])
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_remark()
	_show()
	_tell()


func _take(config_data: Dictionary) -> void:
	if config_data.has("weight") and WEIGHT.has(str(config_data["weight"])): weight = str(config_data["weight"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := weight
	_take(config_data)
	if is_inside_tree() and _board != null and weight != before:
		_lam = float(WEIGHT[weight])
		_phi = 0.0
		_kept = []
		_same = false
		_remark()
		_show()
		_tell()


## ---- the rule ----

## The hall console's own calculation (qfep_balance_workbench._compute_qfe), with its fixed change value.
static func total(f: float, e: float, lam: float, phi: float) -> float:
	return f - lam * e + phi * CHANGE


func total_here() -> float:
	return total(_here.x, _here.y, _lam, _phi)


func _on_floor() -> bool:
	return _here.x > -8.0


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var region := ""
	if absf(p.y) < 1.5:
		if absf(p.x) <= HALF and absf(p.z) <= HALF: region = "deck"
		else:
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
	var was := _here
	_here = Vector2((p.x + HALF) / SIDE, (HALF - p.z) / SIDE) if region == "deck" else Vector2(-9, -9)
	var changed: bool = was.distance_to(_here) > 0.0003
	if _still >= 0.8:
		_still = -99.0
		if region == "deck":
			if _kept.is_empty():
				_kept = [_here.x, _here.y, _lam, _phi, total_here()]
				changed = true
				_tell()
		elif region != "":
			_press(region)
			changed = true
	if changed: _show()


func _press(key: String) -> void:
	for plate in PLATES:
		if str(plate["key"]) != key: continue
		if plate.has("lam"): _lam = float(plate["lam"])
		elif plate.has("phi"): _phi = float(plate["phi"])
		else:
			_kept = []
			_same = false
	_remark()
	_tell()


## Is the visitor's arrangement another one with the kept number?
func _judge() -> void:
	var now := false
	if _on_floor() and not _kept.is_empty():
		var apart: float = maxf(maxf(absf(_here.x - float(_kept[0])), absf(_here.y - float(_kept[1]))), maxf(absf(_lam - float(_kept[2])), absf(_phi - float(_kept[3]))))
		now = absf(total_here() - float(_kept[4])) < NEAR and apart > 0.08
	if now and not _same:
		_found += 1
		_pair = [_here.x, _here.y, _lam, _phi, total_here()]
		_same = now
		_tell()
	_same = now


func apart_m() -> float:
	if _kept.is_empty() or not _on_floor(): return -1.0
	return Vector2(_here.x - float(_kept[0]), _here.y - float(_kept[1])).length() * SIDE


static func _tuple(t: Array) -> String:
	return "F %.2f   E %.2f   λ %.1f   φ %.0f" % [float(t[0]), float(t[1]), float(t[2]), float(t[3])]


func _show() -> void:
	_judge()
	_skin.set_shader_parameter("lam", _lam)
	_skin.set_shader_parameter("phi", _phi)
	_skin.set_shader_parameter("here", _here)
	_skin.set_shader_parameter("kept", float(_kept[4]) if not _kept.is_empty() else -9.0)
	_skin.set_shader_parameter("kept_at", Vector2(float(_kept[0]), float(_kept[1])) if not _kept.is_empty() else Vector2(-9, -9))
	for i in PLATES.size():
		var plate: Dictionary = PLATES[i]
		var lit: bool = (plate.has("lam") and is_equal_approx(float(plate["lam"]), _lam)) or (plate.has("phi") and is_equal_approx(float(plate["phi"]), _phi))
		(_plate_tiles[i].material_override as StandardMaterial3D).albedo_color = Color("f2a0a6") if lit else PALE
	_number.text = "%.2f" % total_here() if _on_floor() else "–"
	_line_here.text = ("here:   " + _tuple([_here.x, _here.y, _lam, _phi])) if _on_floor() else "walk onto the floor:  east is F,  north is E"
	_line_kept.text = ("kept:   %s   =  %.2f" % [_tuple(_kept), float(_kept[4])]) if not _kept.is_empty() else "stand still, and the floor keeps the place"
	_line_same.text = ("THE SAME NUMBER, %.1f m FROM THE FLAG" % apart_m() if is_equal_approx(_lam, float(_kept[2])) and is_equal_approx(_phi, float(_kept[3])) else "THE SAME NUMBER, ANOTHER ARRANGEMENT") if _same else ""
	_flag.visible = not _kept.is_empty()
	if not _kept.is_empty():
		_flag.position = Vector3(float(_kept[0]) * SIDE - HALF, 0, HALF - float(_kept[1]) * SIDE)
		_flag_words.text = "F %.2f  E %.2f\n= %.2f" % [float(_kept[0]), float(_kept[1]), float(_kept[4])]
	# the four-axis shape, as on the console: F up, E right, lambda down, phi left
	_shape.clear_surfaces()
	if _on_floor():
		var corners := _corners([_here.x, _here.y, _lam, _phi])
		_shape.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in [0, 1, 2, 0, 2, 3]: _shape.surface_add_vertex(Vector3(corners[i].x, corners[i].y, 0))
		_shape.surface_end()
	for i in 4:
		_outline[i].visible = not _kept.is_empty()
		if not _kept.is_empty():
			var corners := _corners(_kept)
			_span(_outline[i], corners[i], corners[(i + 1) % 4])


static func _corners(t: Array) -> Array:
	return [Vector2(0, RADAR * float(t[0])), Vector2(RADAR * float(t[1]), 0), Vector2(0, -RADAR * float(t[2])), Vector2(-RADAR * float(t[3]), 0)]


static func _span(bar: MeshInstance3D, a: Vector2, b: Vector2) -> void:
	var along := b - a
	bar.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, bar.position.z)
	bar.rotation.z = atan2(along.y, along.x)
	bar.scale.x = maxf(along.length(), 0.001)


## The numbers written on the lines, along the floor's middle row.
func _remark() -> void:
	for i in _marks.size():
		var t: float = -0.8 + 0.2 * float(i)
		var f: float = t + _lam * 0.5 - CHANGE * _phi
		_marks[i].visible = f > 0.05 and f < 0.95
		_marks[i].position = Vector3(f * SIDE - HALF, 0.03, 0)
		_marks[i].text = "%.1f" % t if absf(t) > 0.01 else "0"


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["ONE NUMBER IS A LINE ON THIS FLOOR"])
	lines.append("The console asks: can two different arrangements give the same number? Here you are two of its rails. A step east is F, a step north is E, and the floor is banded by the console's own total, F − λE + 0.3φ.")
	lines.append("Stand still on the floor: it keeps the place, with a flag, and draws a red line through every other place with that total. Walk the line. The number on the stand does not move. The shape beside it does, and the pale outline of the kept place stays.")
	lines.append("The plates set the other two rails. λ 0: the lines run north, and a walk in E changes nothing. φ 1: every place is 0.30 more, and the kept number is found somewhere else. AGAIN: keep a new place.")
	lines.append("It measures nothing: F and E are where you stand, as on the console they are where a rail stands.")
	if _found > 0 and not _kept.is_empty():
		lines.append("Found: %s and %s both give %.2f. The number cannot tell them apart." % [_tuple(_kept), _tuple(_pair), float(_kept[4])])
	_board.text = "\n".join(lines)


## ---- building, once ----

func _box(parent: Node3D, at: Vector3, size: Vector3, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = paint
	mesh.position = at
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
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	return paint


func _build_once() -> void:
	# the floor
	_skin = ShaderMaterial.new()
	_skin.shader = SKIN
	_skin.set_shader_parameter("side", SIDE)
	var deck := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIDE, SIDE)
	deck.mesh = plane
	deck.material_override = _skin
	deck.position = Vector3(0, 0.012, 0)
	deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(deck)
	var edge: StandardMaterial3D = _city.flat(DARK, 0.9)
	for hand in [-1.0, 1.0]:
		_box(self, Vector3(hand * (HALF + 0.03), 0.012, 0), Vector3(0.06, 0.02, SIDE + 0.12), edge)
		_box(self, Vector3(0, 0.012, hand * (HALF + 0.03)), Vector3(SIDE + 0.12, 0.02, 0.06), edge)
	for i in 3:
		_city.floor_words(self, Vector3(-HALF + float(i) * HALF, 0.03, HALF + 0.3), "F %s" % ["0", "½", "1"][i], 44)
		_city.floor_words(self, Vector3(-HALF - 0.36, 0.03, HALF - float(i) * HALF), "E %s" % ["0", "½", "1"][i], 44)
	_city.floor_words(self, Vector3(1.5, 0.03, HALF + 0.3), "east: more F  →", 30, RED)
	_city.floor_words(self, Vector3(-HALF - 0.36, 0.03, -1.5), "↑\nnorth:\nmore E", 30, RED)
	for i in 9: _marks.append(_city.floor_words(self, Vector3.ZERO, "", 40, PALE))
	# the plates
	for plate in PLATES:
		var at: Vector2 = plate["at"]
		var tile: MeshInstance3D = _box(self, Vector3(at.x, 0.012, at.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8))
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_plate_tiles.append(tile)
		_city.floor_words(self, Vector3(at.x, 0.035, at.y), str(plate["says"]), 56 if str(plate["key"]) != "again" else 36, DARK).outline_size = 0
	# the flag
	_flag = Node3D.new()
	_flag.name = "Flag"
	_flag.visible = false
	add_child(_flag)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.015
	pole.bottom_radius = 0.015
	pole.height = 1.7
	var pole_node := MeshInstance3D.new()
	pole_node.mesh = pole
	pole_node.material_override = _city.flat(RED, 0.5)
	pole_node.position = Vector3(0, 0.85, 0)
	_flag.add_child(pole_node)
	_box(_flag, Vector3(0.2, 1.58, 0), Vector3(0.4, 0.22, 0.012), _city.flat(RED, 0.5))
	_flag_words = Label3D.new()
	_flag_words.font_size = 44
	_flag_words.pixel_size = 0.003
	_flag_words.modulate = PALE
	_flag_words.outline_size = 8
	_flag_words.outline_modulate = DARK
	_flag_words.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_flag_words.position = Vector3(0, 2.0, 0)
	_flag.add_child(_flag_words)
	# the stand at the floor's north edge: the number, and the shape
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-0.4, 0, -HALF - 0.6)      # clear of the tower's own floor sign, which stands at x 3.5 on every floor
	add_child(stand)
	var solid := StaticBody3D.new()
	stand.add_child(solid)
	_box(stand, Vector3(0, 1.6, -0.05), Vector3(3.9, 2.5, 0.06), _city.flat(DARK, 0.85))
	_city.wall(solid, Vector3(0, 0, -0.05), Vector3(3.9, 2.85, 0.12))
	for hand in [-1.0, 1.0]: _box(stand, Vector3(hand * 1.8, 0.2, -0.05), Vector3(0.08, 0.4, 0.08), _city.flat(DARK, 0.85))
	_words(stand, Vector3(-0.95, 2.62, 0), 40, 0.003, PALE).text = "THE TOTAL WHERE YOU STAND"
	_number = _words(stand, Vector3(-0.95, 2.05, 0), 250, 0.0032, AMBER)
	_line_here = _words(stand, Vector3(-0.95, 1.38, 0), 29, 0.003, PALE)
	_line_kept = _words(stand, Vector3(-0.95, 1.14, 0), 29, 0.003, Color("f3b3b8"))
	_line_same = _words(stand, Vector3(-0.95, 0.78, 0), 33, 0.003, Color("ff6b74"))
	var radar := Node3D.new()
	radar.position = Vector3(1.1, 1.75, 0.005)
	stand.add_child(radar)
	var rule: StandardMaterial3D = _plain(Color("5b6274"))
	_box(radar, Vector3.ZERO, Vector3(RADAR * 2.0, 0.012, 0.004), rule)
	_box(radar, Vector3.ZERO, Vector3(0.012, RADAR * 2.0, 0.004), rule)
	var letters := [["F", Vector3(0, RADAR + 0.1, 0)], ["E", Vector3(RADAR + 0.1, 0, 0)], ["λ", Vector3(0, -RADAR - 0.1, 0)], ["φ", Vector3(-RADAR - 0.1, 0, 0)]]
	for letter in letters: _words(radar, letter[1], 48, 0.003, PALE).text = str(letter[0])
	_shape = ImmediateMesh.new()
	var fill := MeshInstance3D.new()
	fill.mesh = _shape
	var amber: StandardMaterial3D = _plain(AMBER)
	fill.material_override = amber
	fill.position = Vector3(0, 0, 0.006)
	radar.add_child(fill)
	for i in 4:
		var bar: MeshInstance3D = _box(radar, Vector3(0, 0, 0.012), Vector3(1.0, 0.022, 0.004), _plain(PALE))
		_outline.append(bar)
	_words(radar, Vector3(0, -RADAR - 0.32, 0), 28, 0.003, PALE).text = "amber: you    pale: the kept place"
	_board = _city.board(self, Vector3(-4.7, 0, -2.4), 3.2, 1.7)      # north-west, behind the plates: out of the arrival's view of the console


## ---- for a test ----

func state() -> Dictionary:
	return {"weight": weight, "lam": _lam, "phi": _phi, "on_floor": _on_floor(), "F": snappedf(_here.x, 0.001), "E": snappedf(_here.y, 0.001), "total": snappedf(total_here(), 0.001) if _on_floor() else -9.0,
		"kept": _kept, "same": _same, "apart_m": snappedf(apart_m(), 0.01), "found": _found, "pair": _pair, "number": _number.text, "status": _line_same.text, "flag": _flag.visible,
		"marks": _marks.filter(func(m): return m.visible).map(func(m): return m.text), "board": _board.text if _board != null else "", "build_ms": _build_ms}


func grid_point(f: float, e: float) -> Vector3:
	return to_global(Vector3(f * SIDE - HALF, 0, HALF - e * SIDE))


func plate_point(key: String) -> Vector3:
	for plate in PLATES:
		if str(plate["key"]) == key: return to_global(Vector3((plate["at"] as Vector2).x, 0, (plate["at"] as Vector2).y))
	return global_position
