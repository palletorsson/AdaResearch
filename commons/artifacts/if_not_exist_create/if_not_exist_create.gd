extends Node3D
class_name IfNotExistCreate

## A WISH STANDING IN THE ROOM — an instruction to build, left where it is wanted.
##
## Palle, 2026-08-27: "add a new instruction artifact for a
## if_not_exist_create:what to create. That can be read by AI and the artifact
## is created if not exist and placed in the map."
##
## The point is that the request lives at the COORDINATE. A backlog says "the
## forces hall wants something for torque"; this says it at (14,9) in
## VFM_02_Operations, at the size the gap actually is, and you meet it while
## walking. When the thing is built, the marker is replaced by it and the wish
## is gone — the map is both the request and the record of it being met.
##
## THE SYNTAX IS THE TAIL, NOT THE HEAD, and that is not a preference.
## `if_not_exist_create:torque_bench` would be read by
## GridInteractablesComponent as name:rotation — asFloat("torque_bench") is 0,
## the words are dropped, and nothing reports it. Only `#key:value` reaches an
## artifact's apply_grid_config. So:
##
##   if_not_exist_create#make:torque_bench#why:the_hall_shows_force_but_not_turning
##   if_not_exist_create#make:torque_bench#like:mass_spring_bench#cells:2x2
##
##   make    the token to create, snake_case — this is what the tool greps for
##   why     one line, underscores for spaces, on what the hall is missing
##   like    an existing artifact to model it on, when there is an obvious one
##   cells   the footprint it should fit, as WxD
##
## Everything is optional except `make`. A marker with no `make` still renders
## and still lists, because a gap you cannot name yet is worth marking.

@export var make: String = ""
@export_multiline var why: String = ""
@export var like: String = ""
@export var cells: String = ""
## Cage height. A wish has to be visible ACROSS a hall — at 1.6 m the cage sat
## below the eye line and read as furniture among the artifacts it is asking to
## join, which is the one thing it must not look like.
@export var height_m: float = 2.6
## Paint the footprint on the floor, in the corpus's own floor idiom
## (walk_this_line_marking): a white outline you can stand inside. The cage says
## how tall, the paint says where — and the paint is the half that survives
## being looked at from above, which is how the plan views read a hall.
@export var marking: bool = true
@export var paint_color: Color = Color.WHITE
## A body in the volume. ON by default: the wish RESERVES the space, and a
## marker you can walk through is a marker something else gets placed inside.
## Switch it off with #solid:0 where the cage would seal a corridor.
@export var solid: bool = true
## Cap height of the wish text.
@export var text_m: float = 0.16
## The unbuilt colour. Deliberately not a museum colour: this is scaffolding and
## should read as scaffolding from across the hall.
@export var colour: Color = Color(0.98, 0.62, 0.09)

var _applied: bool = false
var _built: bool = false


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
	make = _s(config_data, ["make", "create", "token", "if_not_exist_create"], make)
	why = _s(config_data, ["why", "text", "note", "because"], why)
	like = _s(config_data, ["like", "model", "after"], like)
	cells = _s(config_data, ["cells", "footprint", "size"], cells)
	height_m = _num(config_data, ["height_m", "height", "tall"], height_m)
	if config_data.has("marking"):
		marking = _flag(config_data["marking"], marking)
	if config_data.has("solid"):
		solid = _flag(config_data["solid"], solid)
	_applied = true
	# The museum calls this BEFORE _ready and the grid calls it after, so build
	# on whichever arrives second rather than assuming an order.
	if is_inside_tree():
		_build()


func _s(cfg: Dictionary, keys: Array, fallback: String) -> String:
	for k in keys:
		if cfg.has(k):
			var v: Variant = cfg[k]
			# A BARE FLAG IS NOT A VALUE. `#make:2` is read as tutorial
			# shorthand — the artifact receives `true` and the map silently
			# gains a 2 degree rotation — so taking bool(true) as the wish
			# would write "True" on the marker.
			if typeof(v) == TYPE_BOOL:
				continue
			var s: String = str(v).strip_edges().replace("_", " ")
			if s != "":
				return s
	return fallback


func _num(cfg: Dictionary, keys: Array, fallback: float) -> float:
	for k in keys:
		if cfg.has(k) and typeof(cfg[k]) != TYPE_BOOL:
			var t: String = str(cfg[k]).strip_edges()
			if t.is_valid_float():
				return float(t)
	return fallback


func _flag(v: Variant, fallback: bool) -> bool:
	# `#solid:0` arrives as the STRING "0", and bool("0") in GDScript is true.
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	var t: String = str(v).strip_edges().to_lower()
	if t in ["0", "false", "no", "off"]:
		return false
	if t in ["1", "true", "yes", "on"]:
		return true
	return fallback


func _build() -> void:
	if _built:
		for c in get_children():
			c.queue_free()
	_built = true
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(colour.r, colour.g, colour.b, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = colour
	mat.emission_energy_multiplier = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# THE FOOTPRINT IT IS ASKING FOR, drawn at that size. A marker that is always
	# one cell tells you a thing is wanted; a marker at 2x3 tells you the gap.
	var w := 1.0
	var d := 1.0
	if cells.find("x") > 0:
		var p := cells.split("x")
		if p.size() >= 2 and String(p[0]).is_valid_float() and String(p[1]).is_valid_float():
			w = maxf(0.5, float(p[0]))
			d = maxf(0.5, float(p[1]))

	var h: float = maxf(0.5, height_m)

	# THE FOOTPRINT PAINTED ON THE FLOOR, in the idiom walk_this_line_marking
	# already established for this corpus: white, procedural, floated a few
	# millimetres clear of the floor against z-fighting. Same argument as that
	# artifact makes — "nothing about paint prevents anything, it works by being
	# read and obeyed" — which is exactly what a wish is.
	if marking:
		var pm := StandardMaterial3D.new()
		pm.albedo_color = paint_color
		pm.emission_enabled = true
		pm.emission = paint_color
		pm.emission_energy_multiplier = 0.25
		pm.cull_mode = BaseMaterial3D.CULL_DISABLED
		for r in _floor_ring(w, d):
			var paint := MeshInstance3D.new()
			var pb := BoxMesh.new()
			pb.size = r[1]
			paint.mesh = pb
			paint.position = r[0]
			paint.material_override = pm
			add_child(paint)

	# A cage, not a solid: it marks a volume that is meant to be filled, and a
	# body standing inside it later should not be hidden by it.
	for e in _cage_edges(w, d, h):
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = e[1]
		bar.mesh = box
		bar.position = e[0]
		bar.material_override = mat
		bar.layers = 1
		add_child(bar)

	var label := MeshInstance3D.new()
	var tm := TextMesh.new()
	tm.text = _caption()
	tm.font_size = int(max(8.0, text_m * 64.0))
	tm.pixel_size = text_m / max(1.0, float(tm.font_size)) * 64.0 * 0.0156
	tm.uppercase = false
	# WRAP TO THE FOOTPRINT IT IS ASKING FOR. A `why` is a whole sentence, and
	# unwrapped it ran three times wider than a 2x2 cage — which in a hall is a
	# caption lying across the neighbouring artifact, claiming to describe it.
	# WIDTH IS IN FONT PIXELS, NOT METRES — and the difference is not subtle.
	# Set to 1.8 (read as "1.8 m") it wrapped to ONE CHARACTER per line: a
	# thirty-metre column of letters whose AABB swallowed the artifact, so the
	# capture framed a cage four pixels wide. Divide through pixel_size to get
	# there from a real width.
	tm.width = maxf(1.8, w + 0.4) / maxf(0.0001, tm.pixel_size)
	tm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mesh = tm
	# ABOVE the cage, clear of it. TextMesh centres its block on the origin, so
	# a 3-line caption pinned just over the rail sinks half its lines back
	# inside — measured, not guessed: at y 1.75 over a 1.6 rail, lines 2 and 3
	# were behind the top edge.
	# POSITION BY THE BLOCK'S FLOOR, not by its centre. Two guesses failed here
	# for the same reason: the caption's origin is not where it looks. Counting
	# newlines missed the line autowrap added, and then assuming a centred
	# origin put the block half a line low. get_aabb().position.y is the mesh's
	# own lowest point in local space, so lifting by -that puts the bottom of
	# the last line exactly where asked, whatever the origin turns out to be.
	var ab: AABB = tm.get_aabb()
	var floor_y: float = ab.position.y
	if ab.size.y <= 0.0:
		floor_y = -float(tm.text.split("
").size()) * text_m * 1.5
	label.position = Vector3(0.0, h + 0.30 - floor_y, 0.0)
	var lm := StandardMaterial3D.new()
	lm.albedo_color = colour
	lm.emission_enabled = true
	lm.emission = colour
	lm.emission_energy_multiplier = 0.6
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	label.material_override = lm
	add_child(label)

	# THE BODY. Static, on the same layer the grid's own props use, so a wish
	# occupies its cell the way the artifact that replaces it will.
	if solid:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(w, h, d)
		col.shape = box
		col.position = Vector3(0.0, h * 0.5, 0.0)
		body.add_child(col)
		add_child(body)


func _caption() -> String:
	var head: String = make if make != "" else "unnamed"
	var out: String = "MAKE: " + head
	if cells != "":
		out += "  (" + cells + ")"
	if why != "":
		out += "\n" + why
	if like != "":
		out += "\nlike " + like
	return out


func _floor_ring(w: float, d: float) -> Array:
	const LIFT := 0.006   # metres clear of the floor, against z-fighting
	var t: float = 0.055
	var hw: float = w * 0.5
	var hd: float = d * 0.5
	var out: Array = []
	out.append([Vector3(0.0, LIFT, -hd), Vector3(w, 0.004, t)])
	out.append([Vector3(0.0, LIFT, hd), Vector3(w, 0.004, t)])
	out.append([Vector3(-hw, LIFT, 0.0), Vector3(t, 0.004, d)])
	out.append([Vector3(hw, LIFT, 0.0), Vector3(t, 0.004, d)])
	return out


func _cage_edges(w: float, d: float, h: float) -> Array:
	var t := 0.03
	var hw := w * 0.5
	var hd := d * 0.5
	var out: Array = []
	for sx in [-hw, hw]:
		for sz in [-hd, hd]:
			out.append([Vector3(sx, h * 0.5, sz), Vector3(t, h, t)])
	for y in [0.02, h]:
		out.append([Vector3(0.0, y, -hd), Vector3(w, t, t)])
		out.append([Vector3(0.0, y, hd), Vector3(w, t, t)])
		out.append([Vector3(-hw, y, 0.0), Vector3(t, t, d)])
		out.append([Vector3(hw, y, 0.0), Vector3(t, t, d)])
	return out
