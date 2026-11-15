extends Node3D
## EVERY DOOR, HALF AS FAR (floor NonEuclidean_Spaces; the pass, 2026-11-15)
##
## The hall: "The visible rim is infinitely far away in that metric." On the bench that is a sentence about a disk
## seen from above. This is the same rule walked along one line - a PLAYGROUND form.
##
## A plank goes out over the north edge to a cardboard funnel six metres long. Look in: a door, and behind it a
## door half the size, half as far from the tip, and behind that another. Go in. Every door is as far as the last
## one was and as large when you reach it; the tip is six metres ahead and stays six metres ahead. There is no
## last door. A step counts for more the nearer the rim it is taken: a finite way on the picture, and no number
## of steps.
##
## How, and the board says so: the visitor is not made smaller (the tower's walker has no size to change, and a
## headset's player would have to be re-scaled at every step). The funnel is made larger round the visitor, about
## its own tip, by exactly the visitor's steps: L = (metres gone in) / 6, scale e^L; the tip is kept six metres
## ahead. The ground under the feet does not slide (benched: tools/probes/halving_door_bench.py). The funnel is
## the same under its own ratio, so what is shown is always one funnel between 1 and 1/q times its size, with the
## doors renumbered; the door behind is papered over, because the hall behind it cannot be made larger too. The
## body is not moved - except sideways on the way out, by however far it was pushed off the plank's line by the
## walls, with all it can see, before the paper (headset: the player body's teleport(pose) - NOT tried).
##
## `ratio` is the axis: half, two_thirds, three_quarters - any ratio under one gives a rim that is never reached.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const RATIO := {"half": 0.5, "two_thirds": 2.0 / 3.0, "three_quarters": 0.75}
const SAYS := {"half": "HALF", "two_thirds": "TWO THIRDS", "three_quarters": "THREE QUARTERS"}
const D := 6.0                           # from the mouth to the tip, and from the visitor to the tip
const HALF := 1.6                        # half the funnel's width where the visitor stands
const HIGH := 2.6
const DOOR_W := 1.1
const DOOR_H := 2.1
const MOUTH := -3.0                      # the mouth, north of the work's own place (the slab's edge is at about -0.7)
const DECK_FROM := -0.4
const DECK_W := 1.6
const STOP := 5.0
const CARD := Color("c4a070")
const PAPER := Color("d9d2c2")
const BLOCK := Color("3a3d45")
const DARK := Color("191e29")
const PINK := Color("ff5fa8")
const PALE := Color("efe9dc")
const TIMBER := Color("8a6a45")

@export_enum("half", "two_thirds", "three_quarters") var ratio := "half"

var _city = City.new()
var _funnel: Node3D                      # its origin is the tip; made larger about it
var _guard: StaticBody3D                 # what holds a body: at the tip, never scaled
var _stops: Array[CollisionShape3D] = []
var _support: StaticBody3D
var _support_shape: CollisionShape3D
var _lamp: OmniLight3D
var _doors := []                         # per door shown: {node, front, sub, note, back}
var _screen_words: Label3D
var _flag: Node3D
var _flag_words: Label3D
var _board: Label3D
var _in := false
var _was := -99.0
var _ax := 0.0                           # metres gone in past the mouth
var _lat := 0.0
var _x := 0.0                            # the visitor's distance from the funnel's axis, as shown
var _nb := 0                             # the door behind the visitor
var _walked := 0.0
var _noted := -1.0
var _deep := 0.0                         # the furthest in, in doors
var _shifts := 0
var _last_visit := ""
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_ratio"): _take({"ratio": get_meta("config_ratio")})
	add_to_group("void_floor_extension")
	add_to_group("void_exterior_walk")
	process_physics_priority = 10        # after the body has moved: the tip is six metres ahead in the same tick
	var began := Time.get_ticks_msec()
	_build_once()
	_build_funnel()
	_build_ms = Time.get_ticks_msec() - began
	_place(0.0, 0.0)
	_number()
	_tell()


func _take(config_data: Dictionary) -> void:
	if config_data.has("ratio") and RATIO.has(str(config_data["ratio"])): ratio = str(config_data["ratio"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := ratio
	_take(config_data)
	if is_inside_tree() and _board != null and ratio != before and not _in:
		_deep = 0.0
		_last_visit = ""
		_build_funnel()
		_place(0.0, 0.0)
		_number()
		_tell()


## ---- the rule ----

func q() -> float:
	return float(RATIO[ratio])


## Metres of walking from one door to the next.
func door_every() -> float:
	return D * log(1.0 / q())


## Doors passed, as a number that need not be whole, `gone` metres past the mouth.
func doors_at(gone: float) -> float:
	return maxf(gone, 0.0) / door_every()


## One step: the visitor's distance from the axis, as shown, after going `dl` sideways and `da` toward the tip.
static func beside(x: float, dl: float, da: float) -> float:
	return (x + dl) * exp(da / D)


func _game() -> Node:
	return get_tree().get_first_node_in_group("void_game")


func _visitor() -> Node3D:
	var game := _game()
	return game.get("body") as Node3D if game != null else null


## The tower keeps this floor awake while its visitor is in the funnel, however far north that is.
func contains_visitor(at: Vector3) -> bool:
	var p := to_local(at)
	if absf(p.y) > 5.0: return false
	return _in or (p.z < 0.6 and p.z > MOUTH - 0.2 and absf(p.x) < DECK_W * 0.5 + 0.6)


func _shift(body: Node3D, to: Transform3D) -> void:
	var game := _game()
	if game != null and bool(game.get("vr")) and body.has_method("teleport"):
		body.call("teleport", to)
	else:
		body.global_transform = to
	if game != null and game.has_method("rebase_player_motion"): game.call("rebase_player_motion")
	_shifts += 1


func _physics_process(_delta: float) -> void:
	var body := _visitor()
	if body == null: return
	var p := to_local(body.global_position)
	var lat: float = p.x
	var ax: float = MOUTH - p.z
	if not _in:
		var through: bool = _was <= 0.0 and _was > -0.8 and ax > 0.0 and ax < 0.6 and absf(lat) < DOOR_W * 0.5 and absf(p.y) < 1.5
		_was = ax
		if not through:
			_lamp.visible = absf(p.y) < 3.0 and Vector2(lat, ax).length() < 8.0      # lit for whoever comes to look in
			_lamp.position = Vector3(0, 1.7, MOUTH - 1.3)
			return
		_in = true
		_ax = ax
		_lat = lat
		_x = lat
		_walked = 0.0
		_noted = -1.0
		_deep = 0.0
		_support.position = Vector3(lat, 0, MOUTH - 40.0)
		_support_shape.disabled = false
		_flag.visible = false
		_lamp.visible = true
	_was = ax
	if ax <= 0.0 or p.y < -2.5:
		_leave()
		return
	var da: float = ax - _ax
	var dl: float = lat - _lat
	_x = clampf(beside(_x, dl, da), -(HALF - 0.1), HALF - 0.1)
	_walked += Vector2(dl, da).length()
	_ax = ax
	_lat = lat
	_deep = maxf(_deep, doors_at(ax))
	# on the way out, in the first chamber, before the paper: the body is set back onto the plank's line with all
	# it can see - the funnel is where it was built again, and the mouth leads onto the plank
	if da < 0.0 and ax < 1.5 and absf(lat - _x) > 0.02:
		var pose: Transform3D = body.global_transform
		pose.origin -= global_basis.x.normalized() * (lat - _x)
		_shift(body, pose)
		lat = _x
		_lat = lat
	_place(lat, ax)


func _leave() -> void:
	_in = false
	var far: float = D * pow(q(), _deep)
	_last_visit = "Last visit: %.1f m walked, %d door%s. On the picture that is %s from the tip, and a visitor %s tall. The flag on the funnel's back is there." % [
		_walked, int(_deep), "" if int(_deep) == 1 else "s", length(far), length(1.7 * pow(q(), _deep))]
	_flag.position = Vector3(0, HIGH * far / D + 0.02, MOUTH - D + far)
	_flag_words.text = "door %d\n%s from the tip" % [int(_deep), length(far)]
	_flag.visible = _deep > 0.05
	_support_shape.disabled = true
	_lamp.visible = false
	_x = 0.0
	_place(0.0, 0.0)
	_number()
	_tell()


## A length as one would say it.
static func length(m: float) -> String:
	if m >= 1.0: return "%.2f m" % m
	if m >= 0.01: return "%.1f cm" % (m * 100.0)
	if m >= 0.0001: return "%.2f mm" % (m * 1000.0)
	if m >= 1e-7: return "%.2f thousandths of a mm" % (m * 1e6)
	return "10^%d m" % int(floor(log(m) / log(10.0)))


func _one_in(n: int) -> String:
	var v: float = pow(1.0 / q(), float(n))
	if v < 100.0: return ("%.2f" % v).trim_suffix("0").trim_suffix("0").trim_suffix(".")
	if v < 1e9: return "%d" % int(round(v))
	return "10^%d" % int(floor(log(v) / log(10.0)))


## The funnel shown for a visitor `lat` from the plank's line and `ax` past the mouth.
func _place(lat: float, ax: float) -> void:
	var doors: float = doors_at(ax) if _in else 0.0
	var nb: int = int(floor(doors))
	var s: float = pow(q(), float(nb) - doors)          # 1 .. 1/q
	_funnel.position = Vector3(lat - _x, 0, MOUTH - maxf(ax, 0.0) - D) if _in else Vector3(0, 0, MOUTH - D)
	_funnel.scale = Vector3.ONE * s
	_guard.position = _funnel.position
	for k in 2:
		var size: float = s * pow(q(), float(k))
		for hand in 2:
			_stops[k * 2 + hand].position = Vector3((-1.0 if hand == 0 else 1.0) * (size * DOOR_W * 0.5 + STOP * 0.5), 1.5, D * size)
	if nb != _nb:
		_nb = nb
		_number()
	if _in:
		_lamp.position = Vector3(lat, 2.0, MOUTH - ax)
		var mid := Vector2(lat, maxf(ax, 40.0))
		if Vector2(_support.position.x, MOUTH - _support.position.z).distance_to(mid) > 15.0: _support.position = Vector3(mid.x, 0, MOUTH - mid.y)
		if absf(_walked - _noted) >= 0.05:
			_noted = _walked
			var far: float = D * pow(q(), doors)
			var note: String = "walked: %.1f m\nthe tip: %.1f m ahead\non the picture: %s\nfrom it, and you\n%s tall" % [_walked, D, length(far), length(1.7 * pow(q(), doors))]
			for k in mini(3, _doors.size()): (_doors[k]["note"] as Label3D).text = note


func _number() -> void:
	for k in _doors.size():
		var n: int = _nb + k
		var door: Dictionary = _doors[k]
		(door["front"] as Label3D).text = "IN" if n == 0 else str(n)
		(door["back"] as Label3D).text = "" if n == 0 else str(n)
		(door["sub"] as Label3D).text = ("every door\n%s as far" % str(SAYS[ratio]).to_lower()) if n == 0 else ("1 : " + _one_in(n))
		if not _in: (door["note"] as Label3D).text = ""
	if _screen_words != null: _screen_words.text = "OUT" if _nb == 0 else "paper\nback through door %d" % _nb


func _tell() -> void:
	if _board == null: return
	var lines := PackedStringArray(["EVERY DOOR, %s AS FAR" % str(SAYS[ratio])])
	lines.append("A cardboard funnel six metres long, out over the edge. Look in from the plank: a door, and behind it a door %s the size, %s as far from the tip, and so on. Count them if you can." % [str(SAYS[ratio]).to_lower(), str(SAYS[ratio]).to_lower()])
	lines.append("Go in. Every door is as far as the last one was (%.1f m of walking) and as large when you reach it. The tip is six metres ahead and stays six metres ahead. There is no last door." % door_every())
	lines.append("This is the disk's rule for distance, walked along one line: a step counts for more the nearer the rim it is taken. The rim is a finite way off on the picture, and no number of steps away.")
	lines.append("How: you are not made smaller. The funnel is made larger round you, about its tip, by exactly your steps, and the door behind you is papered over, because the hall cannot be made larger too. Out here it is as it was built.")
	if _last_visit != "": lines.append(_last_visit)
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


func _words(parent: Node3D, at: Vector3, size: int, pixel: float, colour: Color, back: bool = false) -> Label3D:
	var label3d := Label3D.new()
	label3d.font_size = size
	label3d.pixel_size = pixel
	label3d.modulate = colour
	label3d.outline_size = 0
	label3d.double_sided = false
	label3d.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label3d.position = at
	if back: label3d.rotation.y = PI
	parent.add_child(label3d)
	return label3d


func _triangles(parent: Node3D, points: PackedVector3Array, paint: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in points: tool.add_vertex(point)
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	mesh.material_override = paint
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)


## Card that takes no shadow: the tower's own shadows lie at heights that do not grow with the funnel.
func _card(colour: Color, both: bool = true) -> StandardMaterial3D:
	var paint: StandardMaterial3D = _city.flat(colour, 0.95)
	if both: paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.disable_receive_shadows = true
	return paint


## The plank, its rails, the beams the funnel lies on, the board, and what holds a body: built once.
func _build_once() -> void:
	var timber: StandardMaterial3D = _city.flat(TIMBER, 0.9)
	var deck_long: float = DECK_FROM - MOUTH
	var solid := StaticBody3D.new()
	solid.name = "Plank"
	add_child(solid)
	for i in 4:
		_box(self, Vector3((float(i) - 1.5) * DECK_W * 0.25, 0.006, (DECK_FROM + MOUTH) * 0.5), Vector3(DECK_W * 0.25 - 0.015, 0.03, deck_long), timber if i % 2 == 0 else _city.flat(TIMBER.darkened(0.12), 0.9))
	_city.wall(solid, Vector3(0, -0.4, (DECK_FROM + MOUTH) * 0.5 - 0.3), Vector3(DECK_W, 0.4, deck_long + 0.6))
	for hand in [-1.0, 1.0]:
		var x: float = hand * (DECK_W * 0.5 + 0.03)
		for i in 3: _box(self, Vector3(x, 0.5, DECK_FROM - 0.1 - float(i) * (deck_long - 0.2) * 0.5), Vector3(0.06, 1.0, 0.06), timber)
		_box(self, Vector3(x, 1.0, (DECK_FROM + MOUTH) * 0.5), Vector3(0.05, 0.06, deck_long), timber)
		_box(self, Vector3(x, 0.55, (DECK_FROM + MOUTH) * 0.5), Vector3(0.03, 0.04, deck_long), timber)
		_city.wall(solid, Vector3(x, 0, (DECK_FROM + MOUTH) * 0.5), Vector3(0.06, 1.1, deck_long))
		_box(self, Vector3(hand * 0.5, -0.11, (DECK_FROM + 0.3 + MOUTH - D - 0.3) * 0.5), Vector3(0.12, 0.18, D - MOUTH + DECK_FROM + 0.6), _city.flat(BLOCK, 0.9))
	_board = _city.board(self, Vector3(-2.7, 0, 0.15), 3.2, 1.6)
	# what holds a body in the funnel: two walls from the tip, and the two doors the body is between
	_guard = StaticBody3D.new()
	_guard.name = "Guard"
	add_child(_guard)
	var slant: float = atan(HALF / D)
	var long: float = 2.3 * D / cos(slant)
	for hand in [-1.0, 1.0]:
		var side := CollisionShape3D.new()
		var slab := BoxShape3D.new()
		slab.size = Vector3(0.12, 3.0, long)
		side.shape = slab
		side.rotation.y = hand * slant
		side.position = Vector3(hand * sin(slant), 0, cos(slant)) * long * 0.5 + Vector3(hand * cos(slant), 0, -sin(slant)) * 0.06 + Vector3(0, 1.5, 0)
		_guard.add_child(side)
	for i in 4:
		var stop := CollisionShape3D.new()
		var block := BoxShape3D.new()
		block.size = Vector3(STOP, 3.0, 0.1)
		stop.shape = block
		_guard.add_child(stop)
		_stops.append(stop)
	# the ground in there: flat, still, and only while somebody is in
	_support = StaticBody3D.new()
	_support.name = "Support"
	add_child(_support)
	_support_shape = CollisionShape3D.new()
	var ground := BoxShape3D.new()
	ground.size = Vector3(80, 0.4, 80)
	_support_shape.shape = ground
	_support_shape.position = Vector3(0, -0.2, 0)
	_support_shape.disabled = true
	_support.add_child(_support_shape)
	_lamp = OmniLight3D.new()
	_lamp.omni_range = 9.0
	_lamp.light_energy = 1.1
	_lamp.shadow_enabled = false
	_lamp.visible = false
	add_child(_lamp)
	# how far the last visitor got, on the funnel's back
	_flag = Node3D.new()
	_flag.name = "Flag"
	_flag.visible = false
	add_child(_flag)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.012
	pole.bottom_radius = 0.012
	pole.height = 0.9
	var pole_node := MeshInstance3D.new()
	pole_node.mesh = pole
	pole_node.material_override = _city.flat(PINK, 0.5)
	pole_node.position = Vector3(0, 0.45, 0)
	_flag.add_child(pole_node)
	_box(_flag, Vector3(0.16, 0.8, 0), Vector3(0.3, 0.18, 0.01), _city.flat(PINK, 0.5))
	_flag_words = Label3D.new()
	_flag_words.font_size = 40
	_flag_words.pixel_size = 0.003
	_flag_words.modulate = PALE
	_flag_words.outline_size = 8
	_flag_words.outline_modulate = DARK
	_flag_words.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_flag_words.position = Vector3(0, 1.15, 0)
	_flag.add_child(_flag_words)


## One door at its built size, its foot at the node's origin, facing south (+z): two leaves of wall, a lintel, a
## pink sill, its number, a crate beside it.
func _door(parent: Node3D, crate: bool, card: Material) -> Dictionary:
	var node := Node3D.new()
	parent.add_child(node)
	var leaf: float = (HALF * 2.0 + 0.04 - DOOR_W) * 0.5
	for hand in [-1.0, 1.0]: _box(node, Vector3(hand * (DOOR_W + leaf) * 0.5, (HIGH + 0.02) * 0.5, 0), Vector3(leaf, HIGH + 0.02, 0.05), card)
	_box(node, Vector3(0, (HIGH + 0.02 + DOOR_H) * 0.5, 0), Vector3(DOOR_W, HIGH + 0.02 - DOOR_H, 0.05), card)
	_box(node, Vector3(0, 0.016, 0), Vector3(DOOR_W, 0.008, 0.07), _card(PINK, false))
	var front: Label3D = _words(node, Vector3(0, 2.36, 0.028), 190, 0.0016, BLOCK)
	var back: Label3D = _words(node, Vector3(0, 2.36, -0.028), 190, 0.0016, BLOCK, true)
	var sub: Label3D = _words(node, Vector3(DOOR_W * 0.5 + 0.5, 1.72, 0.028), 56, 0.002, BLOCK)
	var note: Label3D = _words(node, Vector3(DOOR_W * 0.5 + 0.5, 1.2, 0.028), 30, 0.002, Color("7a1f3d"))
	if crate: _city.part(node, "crate", Vector3(-(DOOR_W * 0.5 + 0.48), 0, 0.42), 14.0, Vector3(0.55, 0.55, 0.55), false)
	return {"node": node, "front": front, "back": back, "sub": sub, "note": note}


func _build_funnel() -> void:
	if _funnel != null:
		remove_child(_funnel)
		_funnel.queue_free()
	_doors.clear()
	_nb = 0
	_funnel = Node3D.new()
	_funnel.name = "Funnel"
	add_child(_funnel)
	var card: StandardMaterial3D = _card(CARD)
	_triangles(_funnel, PackedVector3Array([Vector3(0, 0.012, 0), Vector3(HALF, 0.012, D), Vector3(-HALF, 0.012, D)]), _card(PAPER))
	_triangles(_funnel, PackedVector3Array([Vector3(0, 0.02, 0), Vector3(0.02, 0.02, D), Vector3(-0.02, 0.02, D)]), _card(PINK))
	_triangles(_funnel, PackedVector3Array([
		Vector3(0, 0, 0), Vector3(-HALF, 0, D), Vector3(-HALF, HIGH, D),
		Vector3(0, 0, 0), Vector3(HALF, HIGH, D), Vector3(HALF, 0, D),
		Vector3(0, 0, 0), Vector3(-HALF, HIGH, D), Vector3(HALF, HIGH, D)]), card)
	var k := 0
	while pow(q(), float(k)) >= 0.003:
		var size: float = pow(q(), float(k))
		var door: Dictionary = _door(_funnel, k > 0 and size >= 0.06, _card(CARD.darkened(0.06), false))      # the first door's crate would stand outside
		(door["node"] as Node3D).position = Vector3(0, 0, D * size)
		(door["node"] as Node3D).scale = Vector3.ONE * size
		_doors.append(door)
		k += 1
	# the paper over the door behind: seen from inside only
	var first: Node3D = _doors[0]["node"]
	var paper := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(DOOR_W, DOOR_H)
	paper.mesh = quad
	var night: StandardMaterial3D = _city.flat(DARK, 0.9)
	night.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paper.material_override = night
	paper.position = Vector3(0, DOOR_H * 0.5, -0.03)
	paper.rotation.y = PI
	paper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	first.add_child(paper)
	_screen_words = _words(first, Vector3(0, 1.5, -0.034), 64, 0.0026, PALE, true)


func _exit_tree() -> void:
	_in = false


## ---- for a test ----

func state() -> Dictionary:
	var body := _visitor()
	var doors: float = doors_at(_ax) if _in else 0.0
	var s: float = _funnel.scale.x
	var tip_ahead := -1.0
	var tip_beside := 0.0
	if body != null:
		var p := to_local(body.global_position)
		tip_ahead = p.z - _funnel.position.z
		tip_beside = p.x - _funnel.position.x
	var labels := []
	for k in mini(4, _doors.size()): labels.append((_doors[k]["front"] as Label3D).text)
	var picture := []
	for k in mini(6, _doors.size()): picture.append(snappedf(D * pow(q(), float(k)), 0.001))
	return {"ratio": ratio, "q": q(), "door_every_m": snappedf(door_every(), 0.001), "in": _in, "doors": snappedf(doors, 0.01), "door_behind": _nb, "scale": snappedf(s, 0.001),
		"tip_ahead_m": snappedf(tip_ahead, 0.01), "tip_beside_m": snappedf(tip_beside, 0.01), "beside_axis_m": snappedf(_x, 0.01),
		"next_door_ahead_m": snappedf(D - D * s * q(), 0.01), "next_door_wide_m": snappedf(s * q() * DOOR_W, 0.01), "door_behind_m": snappedf(D * s - D, 0.01), "door_behind_high_m": snappedf(HIGH * s, 0.01),
		"gone_m": snappedf(_ax if _in else 0.0, 0.01), "walked_m": snappedf(_walked, 0.01), "deepest_doors": snappedf(_deep, 0.01), "picture_from_tip_m": D * pow(q(), doors), "picture_tall_m": 1.7 * pow(q(), doors),
		"funnel_at": [snappedf(_funnel.position.x, 0.001), snappedf(_funnel.position.z, 0.001)], "built_at": [0.0, MOUTH - D], "shifts": _shifts, "labels": labels, "paper": _screen_words.text if _screen_words != null else "",
		"doors_shown": _doors.size(), "picture_doors_m": picture, "flag": _flag.visible, "flag_words": _flag_words.text, "board": _board.text if _board != null else "", "prefab_parts": int(_city.parts), "build_ms": _build_ms}


## A place on the plank's line: `by` metres on the hall's side of the mouth (negative: inside the funnel).
func mouth_point(by: float) -> Vector3:
	return to_global(Vector3(0, 0, MOUTH + by))
