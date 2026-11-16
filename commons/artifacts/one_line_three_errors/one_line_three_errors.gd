extends Node3D
## ONE LINE, THREE ERRORS (floor ML_Gradient_Landscape; the pass, 2026-11-16)
##
## The hall: "Can the same observations lead a learner downhill in different directions?" "The two horizontal
## coordinates represent the line's slope and intercept. ... Moving across the surface therefore changes the
## proposed model." "Choose one candidate slope and intercept in your imagination and compare what the three
## surfaces would say about that same candidate. The candidate line is unchanged; only the rule assigning its
## height differs." "Choosing a score and choosing how to follow it are separate decisions."
## This is that candidate chosen with the feet - a PLAYGROUND form.
##
## The floor is the plane of candidate lines: a step east is more slope, a step north is more intercept. Where a
## body stands is one line, and it is drawn north of the field as a plank among five observation posts - the
## tutorial's own five (doc/book/studies/ml-gradient/line_fit.gd), which lie on one line. Red sticks join each
## observation to the plank: the residuals. Three bars beside the posts give that one line's error under three
## rules - squared, Huber, and the exhibit's wavy rule - on one scale.
##
## At the feet lie three arrows, one a rule: each is one step downhill for that rule, and a disc lies where the
## step would land, with the error before and after. Walk along an arrow and you are following that rule; the
## other two turn under you.
##
## OUTLIER lifts the fifth observation to 4.7, as the tutorial's switch does. STEP lengthens every arrow from 0.5
## to 1.2 of its gradient: a tip turns red where the step passes the improvement and lands worse. (At 0.2, the
## first short step tried, Huber's arrow was under ten centimetres and could not be followed with the feet.)
##
## `outlier` (off, on) and `step` (short, long) are the axes. Benched first:
## tools/probes/one_line_three_errors_bench.py.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const DATA: Array[Vector2] = [Vector2(-1.0, -0.3), Vector2(-0.5, -0.05), Vector2(0.0, 0.2), Vector2(0.5, 0.45), Vector2(1.0, 0.7)]
const OUTLIER_Y := 4.7
const START := Vector2(-1.0, 1.0)         # the tutorial's start: where the ball rests
const MID := Vector2(0.8, 0.7)            # the candidate at the middle of the field
const METRES := 1.5                       # floor metres to one unit of slope or intercept
const HALF := Vector2(3.15, 2.4)          # the field: slope -1.3 .. 2.9, intercept -0.9 .. 2.3
const RATES := {"short": 0.5, "long": 1.2}
const RULES := ["squared", "huber", "wavy"]
const WALL_Z := -3.1
const WALL_X := 2.0                       # metres on the wall to one unit of x
const WALL_Y := 0.6                       # metres on the wall to one unit of y - and of error, on the bars
const WALL_BASE := 0.9
const BAR_BASE := 1.0
const PLATES := {"outlier": Vector2(-1.6, 3.2), "step": Vector2(1.6, 3.2)}
const PLATE := 0.84
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const HOT := Color("ff4a32")
const TINT := {"squared": Color("4a9de8"), "huber": Color("58c878"), "wavy": Color("e86ab0")}

@export_enum("off", "on") var outlier := "off"
@export_enum("short", "long") var step := "short"

var _city = City.new()
var _q := START
var _visitor_is_it := false
var _plank: Node3D
var _fifth: Node3D
var _fifth_post: MeshInstance3D
var _sticks: Array[MeshInstance3D] = []
var _bars := {}
var _bar_tags := {}
var _shafts := {}
var _tips := {}
var _tip_tags := {}
var _ghost: Node3D
var _tiles := {}
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _reads := {}
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	_take({"outlier": get_meta("config_outlier", outlier), "step": get_meta("config_step", step)})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("outlier") and str(config_data["outlier"]) in ["off", "on"]: outlier = str(config_data["outlier"])
	if config_data.has("step") and RATES.has(str(config_data["step"])): step = str(config_data["step"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := [outlier, step]
	_take(config_data)
	if is_inside_tree() and _board != null and before != [outlier, step]: _found()


func _found() -> void:
	_draw()
	_tell()


## ---- the rule ----

static func observation(i: int, with_outlier: bool) -> Vector2:
	return Vector2(DATA[i].x, OUTLIER_Y) if with_outlier and i == 4 else DATA[i]


static func one(rule: String, e: float) -> float:
	match rule:
		"squared": return e * e
		"huber": return 0.5 * e * e if absf(e) <= 1.0 else absf(e) - 0.5
	return sin(3.0 * e) + 0.5 * e * e


## The error of the line `q` (slope, intercept) under one rule: the mean over the five observations.
static func error_of(rule: String, q: Vector2, with_outlier: bool) -> float:
	var total := 0.0
	for i in 5:
		var at: Vector2 = observation(i, with_outlier)
		total += one(rule, q.x * at.x + q.y - at.y)
	return total / 5.0


static func gradient(rule: String, q: Vector2, with_outlier: bool) -> Vector2:
	var h := 0.001
	return Vector2(error_of(rule, q + Vector2(h, 0), with_outlier) - error_of(rule, q - Vector2(h, 0), with_outlier),
		error_of(rule, q + Vector2(0, h), with_outlier) - error_of(rule, q - Vector2(0, h), with_outlier)) / (2.0 * h)


## Where one step downhill lands, for one rule.
static func step_from(rule: String, q: Vector2, with_outlier: bool, rate: float) -> Vector2:
	return q - rate * gradient(rule, q, with_outlier)


## The line a place on the field stands for, and the place a line has (local x, z).
static func candidate(x: float, z: float) -> Vector2:
	return Vector2(MID.x + x / METRES, MID.y - z / METRES)


static func place(q: Vector2) -> Vector2:
	return Vector2((q.x - MID.x) * METRES, -(q.y - MID.y) * METRES)


static func on_the_field(at: Vector2) -> bool:
	return absf(at.x) <= HALF.x and absf(at.y) <= HALF.y


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var level: bool = absf(p.y) < 1.5
	var inside: bool = level and on_the_field(Vector2(p.x, p.z))
	var q: Vector2 = candidate(p.x, p.z) if inside else START
	if inside != _visitor_is_it or q.distance_to(_q) > 0.01:
		_visitor_is_it = inside
		_q = q
		_draw()
	var region := ""
	for key in PLATES:
		var at: Vector2 = PLATES[key]
		if level and absf(p.x - at.x) < PLATE * 0.5 and absf(p.z - at.y) < PLATE * 0.5: region = key
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		if region == "outlier": outlier = "on" if outlier == "off" else "off"
		else: step = "long" if step == "short" else "short"
		_draw()
		_tell()


## ---- drawing: every time the candidate moves ----

func _draw() -> void:
	var lifted: bool = outlier == "on"
	var rate: float = RATES[step]
	# the line as a plank among the posts, and the residuals
	var tilt: float = atan(WALL_Y * _q.x / WALL_X)
	_plank.position = Vector3(0, WALL_BASE + WALL_Y * _q.y, WALL_Z)
	_plank.rotation.z = tilt
	_plank.scale = Vector3(1.0 / cos(tilt), 1, 1)
	_fifth.position.y = WALL_BASE + WALL_Y * observation(4, lifted).y
	_fifth_post.position.y = _fifth.position.y * 0.5
	_fifth_post.scale.y = _fifth.position.y
	for i in 5:
		var at: Vector2 = observation(i, lifted)
		var from: float = WALL_BASE + WALL_Y * at.y
		var to: float = WALL_BASE + WALL_Y * (_q.x * at.x + _q.y)
		_sticks[i].position = Vector3(WALL_X * at.x, (from + to) * 0.5, WALL_Z + 0.03)
		_sticks[i].scale.y = maxf(absf(to - from), 0.004)
	# the three errors of this one line, on one scale, and one step downhill for each rule
	var here: Vector2 = place(_q)
	_ghost.visible = not _visitor_is_it
	_ghost.position = Vector3(here.x, 0, here.y)
	_reads = {}
	var worse := 0
	for rule in RULES:
		var before: float = error_of(rule, _q, lifted)
		var to_q: Vector2 = step_from(rule, _q, lifted, rate)
		var after: float = error_of(rule, to_q, lifted)
		var landing: Vector2 = place(to_q)
		var off: bool = not on_the_field(landing)
		var run: Vector2 = landing - here
		if off:
			# the arrow is drawn as far as the edge of the field
			var keep := 1.0
			if absf(run.x) > 0.0001: keep = minf(keep, ((HALF.x if run.x > 0.0 else -HALF.x) - here.x) / run.x)
			if absf(run.y) > 0.0001: keep = minf(keep, ((HALF.y if run.y > 0.0 else -HALF.y) - here.y) / run.y)
			run *= clampf(keep, 0.0, 1.0)
		var better: bool = after < before
		if not better: worse += 1
		var high: float = clampf(WALL_Y * before, -0.8, 3.3)
		var bar: MeshInstance3D = _bars[rule]
		bar.position.y = BAR_BASE + high * 0.5
		bar.scale.y = maxf(absf(high), 0.01)
		var bar_tag: Label3D = _bar_tags[rule]
		bar_tag.position.y = BAR_BASE + maxf(high, 0.0) + 0.22
		bar_tag.text = "%s\n%.2f" % [str(rule).to_upper(), before]
		var shaft: MeshInstance3D = _shafts[rule]
		var tip: MeshInstance3D = _tips[rule]
		var tag: Label3D = _tip_tags[rule]
		var long: float = run.length()
		shaft.visible = long > 0.03
		tip.visible = shaft.visible
		tag.visible = shaft.visible
		shaft.position = Vector3(here.x + run.x * 0.5, shaft.position.y, here.y + run.y * 0.5)
		shaft.rotation.y = -run.angle()
		shaft.scale.x = maxf(long, 0.01)
		tip.position = Vector3(here.x + run.x, tip.position.y, here.y + run.y)
		(tip.material_override as StandardMaterial3D).albedo_color = TINT[rule] if better else HOT
		tag.position = Vector3(here.x + run.x, 0.45 + 0.32 * float(RULES.find(rule)), here.y + run.y)      # one above the other where the tips lie close
		tag.modulate = TINT[rule] if better else HOT
		tag.text = "%s\n%.2f  →  %.2f%s%s" % [str(rule).to_upper(), before, after, "" if better else "   WORSE", "\nlands off the floor" if off else ""]
		_reads[rule] = {"error": before, "to": [to_q.x, to_q.y], "after": after, "better": better, "off_floor": off, "long_units": (to_q - _q).length(), "heading_deg": rad_to_deg((to_q - _q).angle()), "shown": shaft.visible}
	for key in _tiles:
		var lit: bool = (outlier == "on") if key == "outlier" else (step == "long")
		((_tiles[key] as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if lit else PALE
	_lines[0].text = "%s   slope  %.2f     intercept  %.2f" % ["YOUR PLACE IS A LINE:" if _visitor_is_it else "THE BALL'S PLACE IS A LINE:", _q.x, _q.y]
	_lines[1].text = "ITS ERROR, THREE WAYS:   SQUARED %.2f     HUBER %.2f     WAVY %.2f" % [float(_reads["squared"]["error"]), float(_reads["huber"]["error"]), float(_reads["wavy"]["error"])]
	_lines[2].text = "the fifth observation:  %s      the step:  %s (%.1f)" % ["LIFTED TO 4.7" if lifted else "on the line with the others", step.to_upper(), rate]
	if step == "long":
		_status.text = "THE SAME ARROWS, MORE THAN TWICE AS LONG.  %s\nCHOOSING A SCORE AND CHOOSING HOW TO FOLLOW IT ARE SEPARATE DECISIONS." % ("%d OF THE THREE STEPS PASS THE IMPROVEMENT AND LAND WORSE." % worse if worse > 0 else "HERE ALL THREE STILL LAND BETTER.")
	elif lifted:
		_status.text = "THE FIFTH OBSERVATION IS FAR OFF. A MISTAKE, A RARE EVENT, OR SOMEONE THE FIT NEGLECTS?\nNO RULE OF ERROR CAN ANSWER THAT. EACH ONLY DECIDES HOW HARD IT PULLS."
	else:
		_status.text = "FIVE OBSERVATIONS, ONE LINE, THREE RULES OF ERROR. EACH ARROW IS ONE STEP DOWNHILL FOR ITS RULE.\nWALK ALONG ONE. THE OTHER TWO TURN UNDER YOU."


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["ONE LINE, THREE ERRORS"])
	lines.append("Step onto the field. A step east is more slope; a step north is more intercept. Where you stand is one line: the plank among the five posts ahead. The red sticks are what it misses by.")
	lines.append("The three bars are that one line's error under three rules. The three arrows at your feet are one step downhill for each rule. Walk along one arrow until it shrinks to nothing. Then look where the other two still point.")
	lines.append("OUTLIER lifts the fifth observation. STEP makes the arrows more than twice as long. Neither moves the other four observations, and neither moves you.")
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


func _floating(parent: Node3D, at: Vector3, size: int, colour: Color) -> Label3D:
	var tag: Label3D = _words(parent, at, size, 0.0035, colour)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.outline_size = 8
	tag.outline_modulate = DARK
	return tag


func _build_once() -> void:
	var line := _plain(Color("7d8494"))
	# the field: its edge, a faint line a unit, and what a step is
	for z in [-HALF.y, HALF.y]: _box(self, Vector3(0, 0.008, z), Vector3(HALF.x * 2.0, 0.006, 0.03), line)
	for x in [-HALF.x, HALF.x]: _box(self, Vector3(x, 0.008, 0), Vector3(0.03, 0.006, HALF.y * 2.0), line)
	var faint := _plain(Color("565c6b"))
	for s in [-1, 0, 1, 2]:
		var x: float = place(Vector2(float(s), 0)).x
		_box(self, Vector3(x, 0.006, 0), Vector3(0.012, 0.004, HALF.y * 2.0), faint)
		var mark: Label3D = _city.floor_words(self, Vector3(x, 0.02, HALF.y + 0.22), "slope %d" % s, 30, PALE)
		mark.outline_size = 0
	for b in [0, 1, 2]:
		var z: float = place(Vector2(0, float(b))).y
		_box(self, Vector3(0, 0.006, z), Vector3(HALF.x * 2.0, 0.004, 0.012), faint)
		var mark: Label3D = _city.floor_words(self, Vector3(-HALF.x - 0.55, 0.02, z), "intercept %d" % b, 30, PALE)
		mark.outline_size = 0
	_city.floor_words(self, Vector3(0, 0.02, HALF.y + 0.5), "a step east: more slope   →", 34, PALE)
	# the five observations: a post and a ball each; the fifth can be lifted
	var post := _city.flat(DARK, 0.85)
	for i in 5:
		var at: Vector2 = DATA[i]
		var high: float = WALL_BASE + WALL_Y * at.y
		var stem: MeshInstance3D = _box(self, Vector3(WALL_X * at.x, high * 0.5, WALL_Z - 0.02), Vector3(0.04, 1.0, 0.04), post)
		stem.scale.y = high
		if i < 4:
			_city.part(self, "trace_point_ball", Vector3(WALL_X * at.x, high - 0.09, WALL_Z), 0.0, Vector3(0.18, 0.18, 0.18), false)
		else:
			# the fifth can be lifted: its own node, whose height is the ball's centre
			_fifth = Node3D.new()
			_fifth.position = Vector3(WALL_X * at.x, high, WALL_Z)
			add_child(_fifth)
			_city.part(_fifth, "trace_point_ball", Vector3(0, -0.09, 0), 0.0, Vector3(0.18, 0.18, 0.18), false)
			_fifth_post = stem
		_sticks.append(_box(self, Vector3(WALL_X * at.x, high, WALL_Z + 0.03), Vector3(0.035, 1.0, 0.02), _plain(HOT)))
	# the candidate line: a plank on edge, turned and lifted as the candidate moves
	_plank = Node3D.new()
	_plank.name = "Line"
	add_child(_plank)
	_city.part(_plank, "timber_plank_4m", Vector3(0, -0.06, 0), 0.0, Vector3(4.7, 0.12, 0.04), false)
	# the one line's three errors, as bars on the wall's own scale, from a shelf
	_box(self, Vector3(-3.2, BAR_BASE, WALL_Z), Vector3(1.4, 0.03, 0.4), post)
	for k in 3:
		var rule: String = RULES[k]
		var x: float = -2.75 - 0.45 * float(k)
		_bars[rule] = _box(self, Vector3(x, BAR_BASE, WALL_Z), Vector3(0.34, 1.0, 0.3), _plain(TINT[rule]))
		_bar_tags[rule] = _floating(self, Vector3(x, BAR_BASE, WALL_Z + 0.1), 30, TINT[rule])
	# one step downhill for each rule: a shaft from the feet, a disc where it lands, and what the step does
	for k in 3:
		var rule: String = RULES[k]
		_shafts[rule] = _box(self, Vector3(0, 0.014 + 0.002 * float(k), 0), Vector3(1.0, 0.006, 0.07), _plain(TINT[rule]))
		var tip := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.15
		disc.bottom_radius = 0.15
		disc.height = 0.012
		tip.mesh = disc
		tip.material_override = _plain(TINT[rule])
		tip.position = Vector3(0, 0.02 + 0.002 * float(k), 0)
		add_child(tip)
		_tips[rule] = tip
		_tip_tags[rule] = _floating(self, Vector3.ZERO, 32, TINT[rule])
	_ghost = _city.part(self, "trace_point_ball", Vector3.ZERO, 0.0, Vector3(0.26, 0.26, 0.26), false)
	# the two plates
	for key in PLATES:
		var at: Vector2 = PLATES[key]
		_tiles[key] = _box(self, Vector3(at.x, 0.012, at.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8))
		var says: Label3D = _city.floor_words(self, Vector3(at.x, 0.035, at.y), str(key).to_upper(), 46, DARK)
		says.outline_size = 0
	# the stand, raised behind the posts
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-0.3, 0, WALL_Z - 0.5)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 3.85, -0.05), Vector3(4.8, 1.7, 0.06), _city.flat(DARK, 0.85))
	for hand in [-1.0, 1.0]:
		_box(stand, Vector3(hand * 2.3, 1.5, -0.05), Vector3(0.08, 3.0, 0.08), _city.flat(DARK, 0.85))
		_city.wall(held, Vector3(hand * 2.3, 0, -0.05), Vector3(0.1, 4.7, 0.1))
	var heights := [4.42, 4.1, 3.82]
	var sizes := [24, 22, 18]
	var colours := [PALE, Color("f6e39a"), Color("b9c0cc")]
	for i in 3: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.006, colours[i]))
	_status = _words(stand, Vector3(0, 3.36, 0), 15, 0.006, Color("f2a23a"))
	_board = _city.board(self, Vector3(-4.7, 0, HALF.y + 0.3), 2.3, 1.5)


## ---- for a test ----

func state() -> Dictionary:
	return {"outlier": outlier, "step": step, "who": "visitor" if _visitor_is_it else "example", "q": [_q.x, _q.y], "rules": _reads.duplicate(true),
		"plank_tilt_deg": rad_to_deg(_plank.rotation.z), "plank_high_m": _plank.position.y, "fifth_high_m": _fifth.position.y,
		"lines": _lines.map(func(l): return l.text), "status": _status.text, "board": _board.text if _board != null else "", "build_ms": _build_ms}


func plate_point(key: String) -> Vector3:
	var at: Vector2 = PLATES[key]
	return to_global(Vector3(at.x, 0, at.y))


## Where on the floor a line (slope, intercept) is.
func line_point(slope: float, intercept: float) -> Vector3:
	var at: Vector2 = place(Vector2(slope, intercept))
	return to_global(Vector3(at.x, 0, at.y))


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
