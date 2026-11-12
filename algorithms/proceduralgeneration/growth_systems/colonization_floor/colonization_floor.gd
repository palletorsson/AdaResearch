extends Node3D
## THE COLONIZATION FLOOR (floor PG_Space_Colonization; the pass, 2026-11-12)
##
## The hall's lesson grows a tree toward a cloud of points inside a cube and asks what remains authored: the points,
## the radius, the origin, the step, the budget, who may answer again. This is the same rule on the floor, where one
## of those is handed to the visitor: THE POINTS.
## A dark field 12 x 4.4 m in front of the arrival. POINTS ask; SITES answer.
##   every point asks the nearest site that may answer, if one stands within 1.6 m (ties: the older site);
##   every site that was asked grows one piece of 15 cm toward the sum of the unit directions to its askers;
##   a point is taken when a site stands within 30 cm of it.
## The root stands at the visitor's feet. The field begins with sixty seeded points and a tree comes to them.
## Then walk on it: every 45 cm of your walk leaves a point, and what grows in answer to yours is pink.
##
## `answers` is the axis, the hall's own comparison: all = every site may answer again (a tree);
## tips = only a site without a child (one thread, which cannot branch, wanders among the points and takes few).
## 900 sites can be made; when they are spent nothing grows until BEGIN AGAIN.
## `Field` below is the rule alone, in doubles and in a fixed order, and was predicted on a bench before the work was
## built (tools/probes/colonization_bench.py): field 3 gives a tree of 228 sites that takes all sixty points in 59
## steps, and a thread that spends all 900 sites on six.
const WIDE := 12.0
const DEEP := 4.4
const HEAR := 1.6
const TAKE := 0.3
const PIECE := 0.15
const POINTS := 60
const BUDGET := 900
const DROP := 0.45                     # a walking body leaves a point this often
const THEIRS := Color("5bcefa")
const YOURS := Color("f07fa0")


## The rule alone. x east, y north, origin at the middle of the field.
class Field extends RefCounted:
	var answers := "all"
	var sx := PackedFloat64Array()
	var sy := PackedFloat64Array()
	var parent := PackedInt32Array()
	var children: Array = []            # per site: PackedInt32Array
	var grown_for_visitor := PackedByteArray()
	var px := PackedFloat64Array()
	var py := PackedFloat64Array()
	var alive := PackedByteArray()
	var walked := PackedByteArray()     # the point was left by a body
	var steps := 0

	func _init(seed_number: int, who_answers: String, scatter: int = POINTS) -> void:
		answers = who_answers
		_site(0.0, -DEEP * 0.5 + 0.2, -1, false)
		for i in scatter:
			add_point((hash01([seed_number, i, 0]) - 0.5) * (WIDE - 0.6), (hash01([seed_number, i, 1]) - 0.5) * (DEEP - 0.6), false)

	static func hash01(key: Array) -> float:
		var h := 2166136261
		for v in key:
			h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
			h ^= h >> 13
			h = (h * 1274126177) & 0xffffffff
		h ^= h >> 16
		return float(h & 0xffffff) / 16777216.0

	func _site(x: float, y: float, from: int, for_visitor: bool) -> void:
		sx.append(x)
		sy.append(y)
		parent.append(from)
		children.append(PackedInt32Array())
		grown_for_visitor.append(1 if for_visitor else 0)

	func add_point(x: float, y: float, by_a_body: bool) -> void:
		px.append(x)
		py.append(y)
		alive.append(1)
		walked.append(1 if by_a_body else 0)

	## One step. Returns the sites that were made.
	func step() -> PackedInt32Array:
		var made := PackedInt32Array()
		var ax := {}
		var ay := {}
		var for_visitor := {}
		for t in px.size():
			if alive[t] == 0: continue
			var best := -1
			var best_d: float = HEAR * HEAR
			for s in sx.size():
				if answers == "tips" and not (children[s] as PackedInt32Array).is_empty(): continue
				var dx: float = px[t] - sx[s]
				var dy: float = py[t] - sy[s]
				var d: float = dx * dx + dy * dy
				if d < best_d or (d == best_d and best >= 0 and s < best):
					best = s
					best_d = d
			if best < 0: continue
			var bx: float = px[t] - sx[best]
			var by: float = py[t] - sy[best]
			var far: float = sqrt(bx * bx + by * by)
			if far < 1e-9: continue
			ax[best] = float(ax.get(best, 0.0)) + bx / far
			ay[best] = float(ay.get(best, 0.0)) + by / far
			if walked[t] == 1: for_visitor[best] = true
		var asked: Array = ax.keys()
		asked.sort()
		for s: int in asked:
			if sx.size() >= BUDGET: break
			var far: float = sqrt(float(ax[s]) * float(ax[s]) + float(ay[s]) * float(ay[s]))
			if far < 1e-9: continue
			var nx: float = sx[s] + float(ax[s]) / far * PIECE
			var ny: float = sy[s] + float(ay[s]) / far * PIECE
			var twice := false
			for c in (children[s] as PackedInt32Array):
				if (sx[c] - nx) * (sx[c] - nx) + (sy[c] - ny) * (sy[c] - ny) < 1e-12: twice = true; break
			if twice: continue
			var kids: PackedInt32Array = children[s]
			kids.append(sx.size())
			children[s] = kids
			made.append(sx.size())
			_site(nx, ny, s, for_visitor.has(s))
			for t in px.size():
				if alive[t] == 1 and (px[t] - nx) * (px[t] - nx) + (py[t] - ny) * (py[t] - ny) < TAKE * TAKE: alive[t] = 0
		steps += 1
		return made

	func run() -> void:
		while not step().is_empty(): pass

	func taken() -> int:
		var n := 0
		for a in alive: n += 1 - a
		return n

	func asking() -> int:
		return alive.size() - taken()


@export var field := 3                  ## which scatter of points the field begins with
@export_enum("all", "tips") var answers := "all"
@export var steps_per_second := 12.0
@export var grows_alone := true         ## the tree comes to the first points by itself; off for a bench
@export var begin_again_seconds := 30.0 ## after the budget is spent
@export var pregrown := false           ## the rule has already run to its end when the work appears (a still, a bench)

var _field: Field
var _pieces: MultiMesh
var _dots: MultiMesh
var _board: Label3D
var _plates: Array[Vector3] = []
var _near := {}
var _dropped := {}                      # body -> where it left its last point (field coordinates)
var _acc := 0.0
var _idle := 0.0
var _pressed := -10.0
var _now := 0.0
var _points_left := 0                   # by bodies, since the field began
var _drawn_points := -1
var _spent_usec := 0
var _worst_usec := 0
var _frames := 0


func _ready() -> void:
	var given := {}
	for key in ["field", "answers", "steps_per_second", "grows_alone", "begin_again_seconds", "pregrown"]:
		if has_meta("config_" + key): given[key] = get_meta("config_" + key)
	_take(given)
	_build()
	begin()


func _take(config_data: Dictionary) -> bool:
	var changed := false
	if config_data.has("field") and int(float(str(config_data["field"]))) != field:
		field = int(float(str(config_data["field"])))
		changed = true
	if config_data.has("answers") and str(config_data["answers"]) in ["all", "tips"] and str(config_data["answers"]) != answers:
		answers = str(config_data["answers"])
		changed = true
	if config_data.has("steps_per_second"): steps_per_second = maxf(0.5, float(str(config_data["steps_per_second"])))
	if config_data.has("begin_again_seconds"): begin_again_seconds = maxf(1.0, float(str(config_data["begin_again_seconds"])))
	if config_data.has("grows_alone"): grows_alone = str(config_data["grows_alone"]).to_lower() in ["true", "1", "yes"]
	if config_data.has("pregrown") and (str(config_data["pregrown"]).to_lower() in ["true", "1", "yes"]) != pregrown:
		pregrown = not pregrown
		changed = true
	return changed


func apply_grid_config(config_data: Dictionary) -> void:
	if _take(config_data) and is_inside_tree() and _pieces != null: begin()


## The field as it starts: the root, the scatter, nothing grown.
func begin() -> void:
	_field = Field.new(field, answers)
	_pieces.visible_instance_count = 0
	_points_left = 0
	_dropped.clear()
	_acc = 0.0
	_idle = 0.0
	_drawn_points = -1
	if pregrown:
		_field.run()
		for site in range(1, _field.sx.size()): _draw_piece(site)
	_draw_points()
	_write()


func _on_floor(x: float, y: float, up: float) -> Vector3:
	return Vector3(x, up, -y)


func _build() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.10, 0.105, 0.13)
	dark.roughness = 0.9
	var mat := MeshInstance3D.new()
	mat.name = "Field"
	var sheet := BoxMesh.new()
	sheet.size = Vector3(WIDE, 0.02, DEEP)
	mat.mesh = sheet
	mat.material_override = dark
	mat.position.y = 0.002
	add_child(mat)
	var paint := StandardMaterial3D.new()
	paint.vertex_color_use_as_albedo = true
	paint.vertex_color_is_srgb = true
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_pieces = MultiMesh.new()
	_pieces.transform_format = MultiMesh.TRANSFORM_3D
	_pieces.use_colors = true
	var piece := BoxMesh.new()
	piece.size = Vector3(PIECE + 0.03, 0.03, 0.05)
	_pieces.mesh = piece
	_pieces.instance_count = BUDGET
	_pieces.visible_instance_count = 0
	_dots = MultiMesh.new()
	_dots.transform_format = MultiMesh.TRANSFORM_3D
	_dots.use_colors = true
	var dot := CylinderMesh.new()
	dot.top_radius = 0.05
	dot.bottom_radius = 0.05
	dot.height = 0.02
	dot.radial_segments = 10
	_dots.mesh = dot
	_dots.instance_count = 512
	_dots.visible_instance_count = 0
	for pair in [["Branches", _pieces], ["Points", _dots]]:
		var shown := MultiMeshInstance3D.new()
		shown.name = pair[0]
		shown.multimesh = pair[1]
		shown.material_override = paint
		shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(shown)
	# the root: a small ring at the visitor's feet
	var root := MeshInstance3D.new()
	root.name = "Root"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.10
	ring.outer_radius = 0.16
	root.mesh = ring
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(1.0, 0.82, 0.16)
	lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	root.material_override = lit
	root.position = _on_floor(0.0, -DEEP * 0.5 + 0.2, 0.03)
	add_child(root)
	# board and plates at the east end
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(WIDE * 0.5 + 0.9, 0, -0.6)
	stand.rotation.y = -1.16
	add_child(stand)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(2.5, 1.3, 0.06)
	panel.mesh = face
	panel.material_override = dark
	panel.position.y = 1.35
	stand.add_child(panel)
	for side in [-1.05, 1.05]:
		var leg := MeshInstance3D.new()
		var post := BoxMesh.new()
		post.size = Vector3(0.08, 0.7, 0.06)
		leg.mesh = post
		leg.material_override = dark
		leg.position = Vector3(side, 0.35, 0)
		stand.add_child(leg)
	_board = Label3D.new()
	_board.pixel_size = 0.0022
	_board.font_size = 30
	_board.line_spacing = 2.0
	_board.modulate = Color(0.88, 0.94, 1.0)
	_board.outline_size = 4
	_board.outline_modulate = Color(0, 0, 0, 1)
	_board.width = 1080
	_board.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board.position = Vector3(0, 1.35, 0.035)
	stand.add_child(_board)
	var pad := BoxMesh.new()
	pad.size = Vector3(0.7, 0.03, 0.7)
	var press := BoxShape3D.new()
	press.size = Vector3(0.6, 1.0, 0.6)
	var words := ["BEGIN\nAGAIN", "WHO\nANSWERS"]
	for which in 2:
		var at := Vector3(WIDE * 0.5 + 1.5, 0.015, 1.6 + float(which) * 1.05)      # clear of a body that walks off the field's end
		_plates.append(at)
		var plate := MeshInstance3D.new()
		plate.mesh = pad
		plate.material_override = dark
		plate.position = at
		add_child(plate)
		var word := Label3D.new()
		word.text = words[which]
		word.pixel_size = 0.003
		word.font_size = 34
		word.modulate = Color(1.0, 0.82, 0.16)
		word.rotation_degrees = Vector3(-90, 0, 0)
		word.position = at + Vector3(0, 0.02, 0)
		add_child(word)
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 0xFFFFFFFF
		var touch := CollisionShape3D.new()
		touch.shape = press
		touch.position.y = 0.5
		area.add_child(touch)
		area.position = at
		area.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBody3D: press_plate(which))
		add_child(area)
	var zone := Area3D.new()
	zone.name = "Near"
	zone.collision_layer = 0
	zone.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(WIDE + 4.0, 3.0, DEEP + 4.0)
	var room_shape := CollisionShape3D.new()
	room_shape.shape = room
	room_shape.position.y = 1.5
	zone.add_child(room_shape)
	zone.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _near[b] = true)
	zone.body_exited.connect(func(b: Node) -> void:
		_near.erase(b); _dropped.erase(b))
	add_child(zone)


func _draw_piece(site: int) -> void:
	var from: int = _field.parent[site]
	if from < 0: return
	var a := _on_floor(_field.sx[from], _field.sy[from], 0.03)
	var b := _on_floor(_field.sx[site], _field.sy[site], 0.03)
	var along := (b - a).normalized()
	var turn := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	_pieces.set_instance_transform(site - 1, Transform3D(turn, (a + b) * 0.5))
	_pieces.set_instance_color(site - 1, YOURS if _field.grown_for_visitor[site] == 1 else THEIRS)
	_pieces.visible_instance_count = site


func _draw_points() -> void:
	var shown := 0
	for t in _field.px.size():
		if _field.alive[t] == 0 or shown >= _dots.instance_count: continue
		_dots.set_instance_transform(shown, Transform3D(Basis(), _on_floor(_field.px[t], _field.py[t], 0.025)))
		_dots.set_instance_color(shown, Color(1.0, 0.82, 0.16) if _field.walked[t] == 1 else Color(0.92, 0.95, 1.0))
		shown += 1
	_dots.visible_instance_count = shown
	_drawn_points = shown


func _write() -> void:
	if _board == null or _field == null: return
	var spent: bool = _field.sx.size() >= BUDGET
	_board.text = "\n".join(PackedStringArray(["THE POINTS ARE YOURS",
		"Every point asks the nearest site within 1.6 m. A site that is asked grows 15 cm toward the sum of those who ask. A point is taken when a site stands within 30 cm.",
		"Walk on the field: every 45 cm of your walk leaves a point, and what grows in answer to yours is pink.", "",
		"field %d  |  %s  |  %d of %d sites  |  %d points taken, %d asking%s" % [field, "every site answers" if answers == "all" else "only a tip answers", _field.sx.size(), BUDGET, _field.taken(), _field.asking(),
			"\nThe budget is spent. Nothing grows until BEGIN AGAIN." if spent else ""]]))


## Plate 0: the same field again from the root. Plate 1: who may answer.
func press_plate(which: int) -> void:
	if _now - _pressed < 1.0: return
	_pressed = _now
	if which == 1: answers = "tips" if answers == "all" else "all"
	begin()


func set_answers(who: String) -> void:
	if who in ["all", "tips"] and who != answers:
		answers = who
		begin()


func set_field(number: int) -> void:
	field = number
	begin()


func _physics_process(delta: float) -> void:
	var began := Time.get_ticks_usec()
	_now += delta
	# a walking body leaves points
	for b in _near:
		if not is_instance_valid(b): continue
		var here: Vector3 = to_local((b as Node3D).global_position)
		var at := Vector2(here.x, -here.z)
		if absf(at.x) > WIDE * 0.5 or absf(at.y) > DEEP * 0.5 or here.y > 0.6:
			_dropped.erase(b)
			continue
		if not _dropped.has(b) or (_dropped[b] as Vector2).distance_to(at) >= DROP:
			_dropped[b] = at
			if _field.asking() < 300:
				_field.add_point(float(at.x), float(at.y), true)
				_points_left += 1
				_idle = 0.0
	# the rule
	if grows_alone or _points_left > 0:
		_acc += delta
		var done := 0
		while _acc >= 1.0 / steps_per_second and done < 2:
			_acc -= 1.0 / steps_per_second
			done += 1
			var made: PackedInt32Array = _field.step()
			for site in made: _draw_piece(site)
			if not made.is_empty(): _write()
	if _field.asking() != _drawn_points or _dots.visible_instance_count != _drawn_points: _draw_points()
	if _field.sx.size() >= BUDGET:
		_idle += delta
		if _idle >= begin_again_seconds:
			field += 1
			begin()
	var spent := Time.get_ticks_usec() - began
	_spent_usec += spent
	_worst_usec = maxi(_worst_usec, spent)
	_frames += 1


## ---- for a test ----

func state() -> Dictionary:
	return {"field": field, "answers": answers, "steps": _field.steps, "sites": _field.sx.size(), "taken": _field.taken(), "asking": _field.asking(), "left_by_bodies": _points_left}


## How many pieces grew in answer to a body's points, and how many of a body's points still ask.
func yours() -> Dictionary:
	var pieces := 0
	for v in _field.grown_for_visitor: pieces += v
	var asking := 0
	for t in _field.px.size():
		if _field.walked[t] == 1 and _field.alive[t] == 1: asking += 1
	return {"pieces": pieces, "still_asking": asking}


func field_point(x: float, y: float) -> Vector3:
	return to_global(_on_floor(x, y, 0.0))


func plate_centre(which: int) -> Vector3:
	return to_global(_plates[which])


func frame_ms() -> Dictionary:
	var out := {"mean": float(_spent_usec) / 1000.0 / maxf(1.0, float(_frames)), "worst": float(_worst_usec) / 1000.0}
	_spent_usec = 0
	_worst_usec = 0
	_frames = 0
	return out
