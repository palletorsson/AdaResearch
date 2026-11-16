extends Node3D
## YOU ARE THE FOURTH CENTRE (floor ML_Classification; the pass, 2026-11-16)
##
## The hall: "Why can a point change groups even though the point itself has not moved?" "Moving a centre
## changes where the next boundary will fall, so a stationary point can acquire a different group membership."
## And of its table: "Choose a centre, lift it, and put it somewhere else. The observations stay where they
## were. Their colours clear until you ask for a new assignment; the interface admits that your intervention has
## interrupted the answer. Another button moves each centre to its group's mean."
## This is that table with the body as the centre that is moved - a PLAYGROUND form.
##
## The tutorial's own observations (doc/book/studies/ml-classification/cluster_model.gd) stand on a field, three
## metres to its unit: crates, cones and balls that do not move. Three centres are posts. The fourth is a gold
## post until a body steps onto the field; then it is the body. Moving clears the colours. Standing still asks
## for an assignment: every thing is given to its nearest centre (a tie to the lower number, so the visitor
## loses ties), a line runs from it to that centre, and the stand counts how many changed group without moving.
## MEANS sends the three posts to the mean of their things and lays a gold disc at the mean of the visitor's:
## that step is theirs to walk. A post with nothing assigned stays where it is.
##
## The things are of three kinds, and the rule never looks at the kind: the stand says what the visitor's group
## holds, by what they are.
##
## `cohort` is the axis: blobs, rings, block - the hall's three samples. Benched first:
## tools/probes/fourth_centre_bench.py.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const START: Array[Vector2] = [Vector2(-0.6, -0.3), Vector2(0.0, 0.1), Vector2(0.6, 0.3), Vector2(0.0, -0.8)]
const COHORTS := ["blobs", "rings", "block"]
const METRES := 3.0
const HALF := 3.0
const MOST := 25
const KINDS := ["crate", "cone", "ball"]
const PLURAL := ["crates", "cones", "balls"]
const PLATES := {"means": Vector2(4.0, 1.0), "dataset": Vector2(4.0, -1.0)}
const PLATE := 0.84
const DARK := Color("191e29")
const PALE := Color("efe9dc")
const STALE := Color("6c7280")
const TINT: Array[Color] = [Color("4a9de8"), Color("58c878"), Color("e86ab0"), Color("f2c230")]
const NAMES := ["BLUE", "GREEN", "PINK", "YOURS"]

@export_enum("blobs", "rings", "block") var cohort := "blobs"

var _city = City.new()
var _data: Array[Vector2] = []
var _centres: Array[Vector2] = []
var _groups: Array[int] = []              # empty: the colours are cleared
var _before: Array[int] = []              # the assignment before this one, to count what changed
var _changed := 0
var _asked_at := Vector2.ZERO             # where the fourth centre stood when the assignment was asked
var _visitor_is_it := false
var _note := "found"
var _things: Array[Node3D] = []
var _halos: Array[MeshInstance3D] = []
var _ties: Array[MeshInstance3D] = []
var _was: Array[Label3D] = []
var _posts: Array[Node3D] = []
var _mean_marks: Array[MeshInstance3D] = []
var _tiles := {}
var _lines: Array[Label3D] = []
var _status: Label3D
var _board: Label3D
var _region := ""
var _still := 0.0
var _last := Vector3.ZERO
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_cohort"): _take({"cohort": get_meta("config_cohort")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_found()


func _take(config_data: Dictionary) -> void:
	if config_data.has("cohort") and COHORTS.has(str(config_data["cohort"])): cohort = str(config_data["cohort"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := cohort
	_take(config_data)
	if is_inside_tree() and _board != null and cohort != before: _found()


func _found() -> void:
	_data = sample(cohort)
	_centres = []
	_centres.assign(START)
	_before = []
	_groups = []
	_note = "found"
	_place_things()
	_ask(START[3])
	_tell()


## ---- the rule ----

## The tutorial's three samples, in its own units.
static func sample(which: String) -> Array[Vector2]:
	var out: Array[Vector2] = []
	match which:
		"blobs":
			for centre in [Vector2(-0.8, -0.6), Vector2(0.8, -0.6), Vector2(0, 0.7)]:
				for offset in [Vector2(-0.1, 0), Vector2(0.1, 0), Vector2(0, -0.15), Vector2(0, 0.15)]: out.append(centre + offset)
		"rings":
			for radius in [0.35, 0.85]:
				for i in 12: out.append(Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0)) * radius)
		_:
			for z in 5:
				for x in 5: out.append(Vector2(x - 2, z - 2) * 0.4)
	return out


## What a thing is: never read by the rule.
static func kind_of(which: String, i: int) -> int:
	match which:
		"blobs": return i / 4
		"rings": return i / 12
	return (i % 5 + i / 5) % 3


## The nearest centre; equal distances keep the lower number.
static func nearest(p: Vector2, centres: Array[Vector2]) -> int:
	var winner := 0
	var best: float = p.distance_squared_to(centres[0])
	for j in range(1, centres.size()):
		var d: float = p.distance_squared_to(centres[j])
		if d < best:
			best = d
			winner = j
	return winner


static func assign(points: Array[Vector2], centres: Array[Vector2]) -> Array[int]:
	var out: Array[int] = []
	for p in points: out.append(nearest(p, centres))
	return out


## The mean of each group; a centre with nothing assigned stays where it was.
static func means(points: Array[Vector2], groups: Array[int], centres: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for j in centres.size():
		var total := Vector2.ZERO
		var count := 0
		for i in points.size():
			if groups[i] == j:
				total += points[i]
				count += 1
		out.append(total / float(count) if count > 0 else centres[j])
	return out


static func squares(points: Array[Vector2], groups: Array[int], centres: Array[Vector2]) -> float:
	var total := 0.0
	for i in points.size(): total += points[i].distance_squared_to(centres[groups[i]])
	return total


func _sizes() -> Array[int]:
	var out: Array[int] = [0, 0, 0, 0]
	for g in _groups: out[g] += 1
	return out


func _visitor() -> Node3D:
	var game: Node = get_tree().get_first_node_in_group("void_game")
	return game.get("body") as Node3D if game != null else null


func _ask(fourth: Vector2) -> void:
	_centres[3] = fourth
	_asked_at = fourth
	var new: Array[int] = assign(_data, _centres)
	_changed = 0
	if _before.size() == new.size():
		for i in new.size():
			if new[i] != _before[i]: _changed += 1
	for i in MOST:
		_was[i].visible = i < new.size() and _before.size() == new.size() and new[i] != _before[i]
		if _was[i].visible: _was[i].text = "was %s" % NAMES[_before[i]]
	_groups = new
	_before = []
	_before.assign(new)
	if _note != "found": _note = "asked"
	_show()


func _clear(why: String) -> void:
	_groups = []
	_note = why
	_show()


func _physics_process(delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var level: bool = absf(p.y) < 1.5
	var inside: bool = level and absf(p.x) <= HALF and absf(p.z) <= HALF
	var here := Vector2(p.x, p.z) / METRES
	if inside != _visitor_is_it:
		_visitor_is_it = inside
		if inside: _clear("moved")
		else: _show()
	elif inside and not _groups.is_empty() and here.distance_to(_asked_at) > 0.25 / METRES:
		_clear("moved")
	var region := ""
	for key in PLATES:
		var at: Vector2 = PLATES[key]
		if level and absf(p.x - at.x) < PLATE * 0.5 and absf(p.z - at.y) < PLATE * 0.5: region = key
	if inside and _groups.is_empty(): region = "field"
	var moved: float = Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if region != _region or moved > 0.3 * delta:
		_still = 0.0
	elif _still >= 0.0:
		_still += delta
	_region = region
	if _still >= 0.8 and region != "":
		_still = -99.0
		match region:
			"field": _ask(here)
			"dataset":
				cohort = COHORTS[(COHORTS.find(cohort) + 1) % 3]
				_found()
			"means":
				# walking off the field to this plate clears the colours: the mean is taken of the last assignment asked
				if _groups.is_empty() and _before.size() == _data.size(): _groups.assign(_before)
				if _groups.is_empty():
					_note = "nothing to take a mean of"
				else:
					var to: Array[Vector2] = means(_data, _groups, _centres)
					for j in 4: _mean_marks[j].position = Vector3(to[j].x * METRES, 0.02, to[j].y * METRES)
					_mean_marks[3].visible = true
					for j in 3: _centres[j] = to[j]
					_groups = []
					_note = "means"
				_show()


## ---- drawing ----

func _place_things() -> void:
	for i in MOST:
		var here: bool = i < _data.size()
		_things[i].visible = here
		_halos[i].visible = here
		if not here:
			_ties[i].visible = false
			_was[i].visible = false
			continue
		var at := Vector3(_data[i].x * METRES, 0, _data[i].y * METRES)
		_things[i].position = at
		_halos[i].position = at + Vector3(0, 0.012, 0)
		_was[i].position = at + Vector3(0, 0.75, 0)
		var kind: int = kind_of(cohort, i)
		for k in 3: (_things[i].get_child(k) as Node3D).visible = k == kind
	_mean_marks[3].visible = false


func _show() -> void:
	var fresh: bool = not _groups.is_empty()
	for i in _data.size():
		var tint: Color = TINT[_groups[i]] if fresh else STALE
		(_halos[i].material_override as StandardMaterial3D).albedo_color = tint
		_ties[i].visible = fresh
		if not fresh:
			_was[i].visible = false
			continue
		var from: Vector2 = _data[i] * METRES
		var to: Vector2 = _centres[_groups[i]] * METRES
		_ties[i].position = Vector3((from.x + to.x) * 0.5, 0.009, (from.y + to.y) * 0.5)
		_ties[i].rotation.y = -(to - from).angle()
		_ties[i].scale.x = maxf(from.distance_to(to), 0.01)
		(_ties[i].material_override as StandardMaterial3D).albedo_color = tint
	for j in 4: _posts[j].position = Vector3(_centres[j].x * METRES, 0, _centres[j].y * METRES)
	(_posts[3].get_child(0) as Node3D).visible = not _visitor_is_it
	for key in _tiles: ((_tiles[key] as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color("f6e39a") if (key == "means" and fresh) else PALE
	_lines[0].text = "YOU ARE THE FOURTH CENTRE" if _visitor_is_it else "THE FOURTH CENTRE IS THE GOLD POST. STEP ONTO THE FIELD AND IT IS YOU."
	if fresh:
		var n: Array[int] = _sizes()
		var held := [0, 0, 0]
		for i in _data.size():
			if _groups[i] == 3: held[kind_of(cohort, i)] += 1
		_lines[1].text = "GROUPS:   blue %d      green %d      pink %d      yours %d" % [n[0], n[1], n[2], n[3]]
		_lines[2].text = "changed group without moving:  %d          sum of squared distances:  %.2f" % [_changed, squares(_data, _groups, _centres)]
		_lines[3].text = "your group, by what they are:   %d crates   %d cones   %d balls      (the rule never looked)" % held
	else:
		_lines[1].text = "THE COLOURS ARE CLEARED"
		_lines[2].text = "stand still on the field to ask for an assignment"
		_lines[3].text = ""
	_status.text = _status_text(fresh)


func _status_text(fresh: bool) -> String:
	match _note:
		"means": return "THREE POSTS WENT TO THE MEAN OF THEIR THINGS. A POST WITH NOTHING STAYED WHERE IT WAS.\nTHE GOLD DISC IS THE MEAN OF YOURS. THAT STEP IS YOURS TO WALK. THEN ASK AGAIN."
		"moved": return "A CENTRE MOVED: YOU. NOTHING ELSE DID.\nTHE ANSWER IS INTERRUPTED UNTIL YOU STAND STILL AND ASK AGAIN."
		"nothing to take a mean of": return "THERE IS NO ASSIGNMENT TO TAKE A MEAN OF.\nSTAND STILL ON THE FIELD FIRST."
	if fresh and _changed > 0: return "%d THINGS CHANGED GROUP. NONE OF THEM MOVED. A CENTRE DID.\nTHE BOUNDARY BELONGS TO THE MEETING OF THE THINGS AND THE CENTRES." % _changed
	if cohort == "block": return "NO GROUPS WERE PLANTED IN THIS SAMPLE. THE RULE STILL GIVES FOUR.\nDOES THE COLOUR LOOK LESS SURE OF ITSELF?"
	if cohort == "rings": return "TWO RINGS. FOLLOW ONE WITH YOUR EYE, THEN WATCH WHERE ITS COLOUR BREAKS.\nTHE GROUPING FOLLOWS DISTANCE TO A CENTRE, NOT THE FORM YOU WERE TRACING."
	return "TWELVE THINGS IN THREE HEAPS, AND FOUR CENTRES.\nEACH THING IS GIVEN TO ITS NEAREST CENTRE. WALK, STAND STILL, AND COUNT WHAT CHANGED."


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["YOU ARE THE FOURTH CENTRE"])
	lines.append("The crates, cones and balls on the field do not move. Three centres are posts. Step onto the field and the fourth is you. Moving clears the colours. Stand still, and every thing is given to its nearest centre.")
	lines.append("MEANS sends the three posts to the mean of their things. A gold disc shows the mean of yours: walk to it, and ask again. DATASET changes the sample: heaps, rings, a block with nothing planted in it.")
	lines.append("A thing exactly between two centres goes to the lower number. You are number four. The rule looks at where a thing is, never at what it is.")
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


func _disc(parent: Node3D, radius: float, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.012
	mesh.mesh = disc
	mesh.material_override = _plain(colour)
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
	var edge := _plain(Color("7d8494"))
	for z in [-HALF, HALF]: _box(self, Vector3(0, 0.008, z), Vector3(HALF * 2.0, 0.006, 0.03), edge)
	for x in [-HALF, HALF]: _box(self, Vector3(x, 0.008, 0), Vector3(0.03, 0.006, HALF * 2.0), edge)
	# the things: a crate, a cone and a ball at every place, one of them shown; a disc under it; a line to its centre
	for i in MOST:
		var thing := Node3D.new()
		add_child(thing)
		_city.part(thing, "crate", Vector3.ZERO, 0.0, Vector3(0.3, 0.3, 0.3), false)
		_city.part(thing, "traffic_pyramid_5", Vector3.ZERO, 0.0, Vector3(0.26, 0.42, 0.26), false)
		_city.part(thing, "trace_point_ball", Vector3(0, 0.06, 0), 0.0, Vector3(0.28, 0.28, 0.28), false)
		_things.append(thing)
		_halos.append(_disc(self, 0.27, STALE))
		_ties.append(_box(self, Vector3.ZERO, Vector3(1.0, 0.004, 0.025), _plain(STALE)))
		var was: Label3D = _floating(self, Vector3.ZERO, 26, PALE)
		was.visible = false
		_was.append(was)
	# the four centres: a post with a coloured head; the fourth is gold, and is hidden while a body is it
	for j in 4:
		var post := Node3D.new()
		add_child(post)
		var body := Node3D.new()
		post.add_child(body)
		_box(body, Vector3(0, 0.8, 0), Vector3(0.06, 1.6, 0.06), _city.flat(DARK, 0.85))
		_box(body, Vector3(0, 1.72, 0), Vector3(0.26, 0.26, 0.26), _plain(TINT[j]))
		_floating(body, Vector3(0, 2.05, 0), 34, TINT[j]).text = "CENTRE %d" % (j + 1) if j < 3 else "THE FOURTH"
		_disc(post, 0.2, TINT[j]).position = Vector3(0, 0.016, 0)
		_posts.append(post)
		var mark: MeshInstance3D = _disc(self, 0.34, TINT[j])
		mark.visible = false
		_mean_marks.append(mark)
	_floating(_mean_marks[3], Vector3(0, 0.4, 0), 28, TINT[3]).text = "the mean of yours"
	# the two plates, east of the field
	for key in PLATES:
		var at: Vector2 = PLATES[key]
		_tiles[key] = _box(self, Vector3(at.x, 0.012, at.y), Vector3(PLATE, 0.02, PLATE), _city.flat(PALE, 0.8))
		var says: Label3D = _city.floor_words(self, Vector3(at.x, 0.035, at.y), str(key).to_upper(), 44, DARK)
		says.outline_size = 0
		says.rotation_degrees.y = 90.0
	# the stand, raised behind the field
	var stand := Node3D.new()
	stand.name = "Stand"
	stand.position = Vector3(-0.8, 0, -HALF - 0.6)
	add_child(stand)
	var held := StaticBody3D.new()
	stand.add_child(held)
	_box(stand, Vector3(0, 3.6, -0.05), Vector3(5.0, 1.9, 0.06), _city.flat(DARK, 0.85))
	for hand in [-1.0, 1.0]:
		_box(stand, Vector3(hand * 2.4, 1.33, -0.05), Vector3(0.08, 2.66, 0.08), _city.flat(DARK, 0.85))
		_city.wall(held, Vector3(hand * 2.4, 0, -0.05), Vector3(0.1, 4.55, 0.1))
	var heights := [4.28, 3.98, 3.72, 3.48]
	var sizes := [22, 24, 18, 17]
	var colours := [PALE, Color("f6e39a"), Color("b9c0cc"), TINT[3]]
	for i in 4: _lines.append(_words(stand, Vector3(0, float(heights[i]), 0), int(sizes[i]), 0.006, colours[i]))
	_status = _words(stand, Vector3(0, 3.02, 0), 15, 0.006, Color("f2a23a"))
	_board = _city.board(self, Vector3(-4.5, 0, 1.4), 2.3, 1.5)


## ---- for a test ----

func state() -> Dictionary:
	var fresh: bool = not _groups.is_empty()
	var held := [0, 0, 0]
	if fresh:
		for i in _data.size():
			if _groups[i] == 3: held[kind_of(cohort, i)] += 1
	return {"cohort": cohort, "who": "visitor" if _visitor_is_it else "post", "assigned": fresh, "sizes": _sizes() if fresh else [], "changed": _changed, "groups": _groups.duplicate(),
		"squares": squares(_data, _groups, _centres) if fresh else -1.0, "centres": _centres.map(func(c): return [c.x, c.y]), "things": _data.size(), "yours_by_kind": held,
		"mean_of_yours": [_mean_marks[3].position.x / METRES, _mean_marks[3].position.z / METRES], "mean_shown": _mean_marks[3].visible, "ties_shown": _ties.filter(func(t): return t.visible).size(),
		"lines": _lines.map(func(l): return l.text), "status": _status.text, "board": _board.text if _board != null else "", "build_ms": _build_ms}


func plate_point(key: String) -> Vector3:
	var at: Vector2 = PLATES[key]
	return to_global(Vector3(at.x, 0, at.y))


## A place on the field, in the tutorial's units.
func unit_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x * METRES, 0, z * METRES))


func local_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
