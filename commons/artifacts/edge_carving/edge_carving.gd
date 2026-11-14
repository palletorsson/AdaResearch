extends Node3D
class_name EdgeCarving
## THE EDGES OF THE RESEARCH, CARVED (2026-11-14). Palle: "make these but carved sculptures using sine and randomness,
## what is in between a helix". Each of the research's edges - where it says, in its own words, that it stops
## (commons/data/stickers/readings.json, kind edge) - is a stone column carved along a helix: sine in three dimensions,
## its radius breathing on a second sine, pulled toward chance by a seeded random walk (lambda times the walk). Between
## lambda 0 and 1 lies what is between a helix and a wandering line. The KIND of edge sets how the carving stops:
##   cannot_claim  carved true up to a claim line incised round the column, dissolving into chance above it
##   leaves_out    turns left uncarved: raw stone between the lengths of groove
##   still_open    the groove runs on out of the column's top, open
##   not_yet       only roughed in: the groove grazes the surface, wandering in and out of the stone
##   foreclosed    the helix sealed inside the stone, seen only through a narrow slot in its face
##   dark_spot     a window into a black hollow at the column's core, the helix winding round it
##   does_not_fit  the helix wider than the column: it bites out of its sides
## The edge's words stand on the plinth's front with where they were read (the reading's own lettering); the kind's
## name and colour above them. Collision on the stone and the plinth. Front = +Z.

const KINDS := {
	"cannot_claim": {"label": "CANNOT CLAIM", "colour": Color("#b3121b")},
	"leaves_out": {"label": "LEAVES OUT", "colour": Color("#6b5843")},
	"still_open": {"label": "STILL OPEN", "colour": Color("#1f4f8f")},
	"not_yet": {"label": "NOT YET", "colour": Color("#c0661a")},
	"foreclosed": {"label": "FORECLOSED", "colour": Color("#1d1d1f")},
	"dark_spot": {"label": "DARK SPOT", "colour": Color("#020203")},
	"does_not_fit": {"label": "DOES NOT FIT", "colour": Color("#9b59b6")},
}
const READINGS := "res://commons/data/stickers/readings.json"
const PLINTH := 0.35        # plinth height (m); its top is the column's foot
const PLINTH_W := 0.8
const COL_R := 0.32         # the column's radius
const COL_H := 1.25         # the column's height
const TURNS := 3.25
const WANDER := 0.15        # the random walk's reach at lambda 1 (m)
const WRAP_ADVANCE := 0.68  # a capital's advance as a share of the font size, for breaking the plinth's words into lines

@export_enum("cannot_claim", "leaves_out", "still_open", "not_yet", "foreclosed", "dark_spot", "does_not_fit") var kind := "cannot_claim"
@export var reading := ""   # a readings.json id (kind edge): its words and where they were read
@export var seed := 1

var _stone: CSGCombiner3D
var _knots: Array[Vector3] = []
var _queued := false


func apply_grid_config(config: Dictionary) -> void:
	kind = str(config.get("kind", kind)) if KINDS.has(str(config.get("kind", kind))) else kind
	reading = str(config.get("reading", reading))
	seed = int(config.get("seed", seed))
	if is_inside_tree():
		_queue_build()


func _ready() -> void:
	_queue_build()


## One build, at the frame's end, after the last config. The tower ADDS a work and THEN calls apply_grid_config
## (floor_content.gd): built in _ready and again on the config, the first set was only queued for freeing, so the second
## was renamed (@CSGCombiner3D@18, not Stone) - tools/probes/edge_carving_bench.gd B1.
func _queue_build() -> void:
	if _queued:
		return
	_queued = true
	_build.call_deferred()


func _build() -> void:
	_queued = false
	if not is_inside_tree():
		return
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s/%d" % [kind, seed])
	# the random walk: 48 knots, each a step from the last, then the whole walk centred
	_knots.clear()
	var at := Vector3.ZERO
	for i in 48:
		at += Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.32
		_knots.append(at)
	var mean := Vector3.ZERO
	for k in _knots: mean += k
	mean /= _knots.size()
	for i in _knots.size(): _knots[i] = (_knots[i] - mean).limit_length(1.0)
	_plinth()
	_stone = CSGCombiner3D.new()
	_stone.name = "Stone"
	_stone.use_collision = true
	add_child(_stone)
	var col := CSGCylinder3D.new()
	col.radius = COL_R * (0.75 if kind == "does_not_fit" else 1.0)
	col.height = COL_H
	col.sides = 64
	col.smooth_faces = false   # smoothed normals are scrambled where the boolean cuts the side: facets, like dressed stone
	col.position = Vector3(0, PLINTH + COL_H / 2.0, 0)
	col.material = _mat(Color("#d9d3c5"), 0.92)
	_stone.add_child(col)
	var carved := _mat(Color("#b7ae9b"), 0.98)
	match kind:
		"cannot_claim":
			_groove(0.0, 1.0, COL_R - 0.01, 0.05, func(t: float) -> float: return smoothstep(0.55, 0.95, t), carved)
			var ring := CSGTorus3D.new()
			ring.inner_radius = COL_R - 0.012
			ring.outer_radius = COL_R + 0.03
			ring.sides = 64
			ring.ring_sides = 6
			ring.operation = CSGShape3D.OPERATION_SUBTRACTION
			ring.position = Vector3(0, _y(0.55), 0)
			ring.scale = Vector3(1, 0.18, 1)
			ring.material = _mat(Color("#8e0c16"), 0.9)
			_stone.add_child(ring)
		"leaves_out":
			for span in [[0.0, 0.28], [0.42, 0.6], [0.78, 1.0]]:
				_groove(span[0], span[1], COL_R - 0.01, 0.05, func(_t: float) -> float: return 0.08, carved)
		"still_open":
			_groove(0.0, 1.14, COL_R - 0.01, 0.055, func(t: float) -> float: return 0.12 + 0.5 * smoothstep(0.9, 1.14, t), carved)
		"not_yet":
			_groove(0.0, 1.0, COL_R + 0.022, 0.045, func(_t: float) -> float: return 0.55, _mat(Color("#cfc7b6"), 1.0))
			for i in 12:
				var chip := CSGSphere3D.new()
				chip.radius = rng.randf_range(0.03, 0.06)
				chip.radial_segments = 10
				chip.rings = 6
				chip.operation = CSGShape3D.OPERATION_SUBTRACTION
				var a := rng.randf() * TAU
				chip.position = Vector3(cos(a) * (COL_R + 0.02), PLINTH + rng.randf_range(0.1, COL_H - 0.1), sin(a) * (COL_R + 0.02))
				chip.material = _mat(Color("#cfc7b6"), 1.0)
				_stone.add_child(chip)
		"foreclosed":
			_groove(0.0, 1.0, 0.17, 0.045, func(_t: float) -> float: return 0.05, _mat(Color("#7d7464"), 1.0))
			var slot := CSGBox3D.new()
			slot.size = Vector3(0.045, COL_H * 0.7, COL_R + 0.02)
			slot.position = Vector3(0, PLINTH + COL_H / 2.0, (COL_R + 0.02) / 2.0)
			slot.operation = CSGShape3D.OPERATION_SUBTRACTION
			slot.material = _mat(Color("#8a8070"), 1.0)
			_stone.add_child(slot)
		"dark_spot":
			_groove(0.0, 1.0, COL_R - 0.01, 0.05, func(_t: float) -> float: return 0.1, carved)
			var black := _mat(Color("#060505"), 1.0)
			var hollow := CSGSphere3D.new()
			hollow.radius = 0.2
			hollow.radial_segments = 32
			hollow.rings = 16
			hollow.operation = CSGShape3D.OPERATION_SUBTRACTION
			hollow.position = Vector3(0, PLINTH + COL_H / 2.0, 0)
			hollow.material = black
			_stone.add_child(hollow)
			var window := CSGBox3D.new()
			window.size = Vector3(0.16, 0.2, COL_R)
			window.position = Vector3(0, PLINTH + COL_H / 2.0, COL_R / 2.0 + 0.05)
			window.operation = CSGShape3D.OPERATION_SUBTRACTION
			window.material = black
			_stone.add_child(window)
		"does_not_fit":
			_groove(0.0, 1.0, COL_R * 0.75 + 0.04, 0.085, func(_t: float) -> float: return 0.2, carved)
	_words()


func _y(t: float) -> float:
	return PLINTH + 0.1 + t * (COL_H - 0.2)


## The random walk at t (0..1, beyond 1 held at its end), as an offset: knots joined by a cubic.
func _wander(t: float) -> Vector3:
	var f := clampf(t, 0.0, 1.0) * float(_knots.size() - 1)
	var i := int(floor(f))
	var u := f - i
	var p0 := _knots[maxi(i - 1, 0)]
	var p1 := _knots[i]
	var p2 := _knots[mini(i + 1, _knots.size() - 1)]
	var p3 := _knots[mini(i + 2, _knots.size() - 1)]
	return p1.cubic_interpolate(p2, p0, p3, u)


## One groove: the helix from t0 to t1 (t 0..1 is the column's height), its radius breathing on a second sine, pulled by
## lambda(t) times the random walk; a circle of radius r carried along it and taken out of the stone.
func _groove(t0: float, t1: float, radius: float, r: float, lambda: Callable, mat: Material) -> void:
	var curve := Curve3D.new()
	curve.bake_interval = 0.015
	var n := int(ceil((t1 - t0) * 220.0)) + 2
	for k in n:
		var t := lerpf(t0, t1, float(k) / float(n - 1))
		var a := t * TURNS * TAU
		var rr := radius * (1.0 + 0.08 * sin(t * TAU * 2.0))
		var w := _wander(t) * WANDER * float(lambda.call(t))
		curve.add_point(Vector3(cos(a) * rr + w.x, _y(t) + w.y * 0.5, sin(a) * rr + w.z))
	var path := Path3D.new()
	path.curve = curve
	_stone.add_child(path)
	var tube := CSGPolygon3D.new()
	tube.operation = CSGShape3D.OPERATION_SUBTRACTION
	tube.mode = CSGPolygon3D.MODE_PATH
	var ring := PackedVector2Array()
	for k in 12:
		ring.append(Vector2(cos(k * TAU / 12.0), sin(k * TAU / 12.0)) * r)
	tube.polygon = ring
	tube.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	tube.path_interval = 0.02
	tube.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
	tube.path_local = true
	tube.path_joined = false
	tube.smooth_faces = true
	tube.material = mat
	_stone.add_child(tube)
	tube.path_node = tube.get_path_to(path)


func _plinth() -> void:
	var body := StaticBody3D.new()
	body.name = "Plinth"
	add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(PLINTH_W, PLINTH, PLINTH_W)
	mesh.mesh = box
	mesh.position.y = PLINTH / 2.0
	mesh.material_override = _mat(Color("#3b3631"), 0.85)
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = box.size
	shape.shape = bs
	shape.position = mesh.position
	body.add_child(shape)


## The edge's words on the plinth's front, read from readings.json by id (the same lettering the sticker carries).
func _words() -> void:
	var k: Dictionary = KINDS.get(kind, KINDS.cannot_claim)
	var words := ""
	var where := ""
	if FileAccess.file_exists(READINGS) and reading != "":
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(READINGS))
		if doc is Dictionary:
			for r in doc.get("readings", []):
				if r is Dictionary and str(r.get("id", "")) == reading:
					words = str(r.get("a", ""))
					where = str(r.get("hall", "")).replace("_", " ") if str(r.get("hall", "")) != "" else str(r.get("file", "")).get_file().get_basename().replace("_", " ")
	# a kind whose colour is near black (foreclosed, dark spot) is lettered in the stone's colour, to read on the dark plinth
	var kc: Color = k.colour if k.colour.get_luminance() > 0.2 else Color("#e4ddcd")
	var label := _label(k.label, 30, kc, 0.6)
	label.position = Vector3(0, PLINTH - 0.065, PLINTH_W / 2.0 + 0.002)
	if words != "":
		var body := _label(words.to_upper(), 22, Color("#efe9dc"), 0.7)
		body.position = Vector3(0, PLINTH * 0.45, PLINTH_W / 2.0 + 0.002)
		var src := _label(where.to_upper(), 14, Color("#a89a85"), 0.7)
		src.position = Vector3(0, 0.04, PLINTH_W / 2.0 + 0.002)


func _label(t: String, size: int, colour: Color, width_m: float) -> Label3D:
	var l := Label3D.new()
	l.font_size = size
	l.pixel_size = 0.0012
	# the lines are broken here, not by autowrap: the exported text (export_void_editor.gd records a Label3D's text, not
	# its width) then breaks the same way wherever it is drawn - Godot, the web's floor editor, the 3D sticker view
	l.text = wrap_words(t, maxi(8, int(width_m / (l.pixel_size * size * WRAP_ADVANCE))))
	l.modulate = colour
	l.outline_size = 0
	l.width = width_m / l.pixel_size
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.double_sided = false
	add_child(l)
	return l


## Greedy word wrap: lines of at most max_chars characters, broken at spaces (a longer word keeps its own line).
static func wrap_words(t: String, max_chars: int) -> String:
	var lines := PackedStringArray()
	var line := ""
	for w in t.split(" ", false):
		if line == "":
			line = w
		elif line.length() + 1 + w.length() <= max_chars:
			line += " " + w
		else:
			lines.append(line)
			line = w
	if line != "":
		lines.append(line)
	return "\n".join(lines)


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m
