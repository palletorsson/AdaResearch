extends Node3D
## FIVE SQUARES AT EVERY CORNER (floor NonEuclidean_Spaces; the pass, 2026-11-15)
##
## Palle, 2026-11-15: non-Euclidean playable spaces for the non-Euclidean maps. The hall's bench has a DISK stop,
## and its text says of the disk: "The visible rim is infinitely far away in that metric." The wing's hyperbolic
## rooms are travelled by trigger from a deck. This one is WALKED: a round deck that shows, under and round the
## one who walks it, a floor of square tiles of which five meet at every corner. A PLAYGROUND form.
##
## The floor is drawn from where the body stands: under the feet it is true to size, a step is a step; farther
## off it is squeezed toward a rim three metres away that keeps its distance - there is more floor than a flat
## room can show. A pink square is painted on the deck itself, 1.4 m a side. Stand still on START: the tile under
## you turns red, home, with an arrow pointing north. Walk the square - forward, left, forward, left, forward,
## left, forward - back to START. On the slab that walk closes. On this floor home is 2.4 m away and its arrow has
## turned by 159 degrees (benched: tools/probes/walked_tiling_bench.py).
##
## `corner` is the axis, and it is the bench's three stops under the feet: five (the disk's geometry: home is
## lost), four (a flat floor: the tiles stay where they are and the walk closes), three (a cube's skin, rounded:
## six tiles in all, home 1.2 m away and turned the other way, and 6.28 m straight ahead is where you stand).
##
## The body is never moved. Its steps are composed as motions of the floor (a pair of complex numbers a, b for
## z -> (a z + b) / (-k conj(b) z + conj(a)), k the curv of the curvature), and the deck's shader draws the tiling
## from that. The arithmetic is this file's own: the wing's geometry_kernel.gd keeps points of H3 and has no
## composition of motions.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const SHADER := preload("res://commons/artifacts/walked_tiling/walked_tiling.gdshader")
const DECK := 2.6
const HORIZON := 3.0
const SIDE := 1.4
const START := Vector3(-0.7, 0, 0.7)
const KIND := {"five": -1, "four": 0, "three": 1}
const PINK := Color("ff5fa8")

@export_enum("five", "four", "three") var corner := "five"

var _city = City.new()
var _skin: ShaderMaterial
var _board: Label3D
var _pointer: Node3D
var _pointer_tag: Label3D
var _body: Node3D
var _on := false
var _last := Vector2.ZERO
var _va := Vector2(1, 0)                 # where the body is in the tile it stands in: the motion vinv
var _vb := Vector2.ZERO
var _ga := Vector2(1, 0)                 # where the body is as seen from home: the motion g
var _gb := Vector2.ZERO
var _home := false
var _still := 0.0
var _walked := 0.0
var _back := false
var _tiles := 0
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_corner"): _take({"corner": get_meta("config_corner")})
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_rest()


func _take(config_data: Dictionary) -> void:
	if config_data.has("corner") and KIND.has(str(config_data["corner"])): corner = str(config_data["corner"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := corner
	_take(config_data)
	if is_inside_tree() and _board != null and corner != before: _rest()


## ---- the rule: motions of a floor of curvature k ----

func k() -> int:
	return int(KIND[corner])


static func cmul(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x)


static func conj(a: Vector2) -> Vector2:
	return Vector2(a.x, -a.y)


static func cdiv(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(a.x * b.x + a.y * b.y, a.y * b.x - a.x * b.y) / maxf(b.length_squared(), 1e-18)


## The motion that carries the origin a step `by` (metres, as x + i z).
static func step_motion(by: Vector2, curv: int) -> Array:
	var d: float = by.length()
	if d < 1e-9: return [Vector2(1, 0), Vector2.ZERO]
	var u: Vector2 = by / d
	if curv < 0: return [Vector2(cosh(d * 0.5), 0), u * sinh(d * 0.5)]
	if curv > 0: return [Vector2(cos(d * 0.5), 0), u * sin(d * 0.5)]
	return [Vector2(1, 0), u * (d * 0.5)]


## first . second: the second is done first.
static func compose(a1: Vector2, b1: Vector2, a2: Vector2, b2: Vector2, curv: int) -> Array:
	var a: Vector2 = cmul(a1, a2) - float(curv) * cmul(b1, conj(b2))
	var b: Vector2 = cmul(a1, b2) + cmul(b1, conj(a2))
	var size: float = sqrt(maxf(1e-18, a.length_squared() + float(curv) * b.length_squared())) if curv != 0 else a.length()
	return [a / size, b / size]


## Where a motion puts the origin, as a distance in metres.
static func reach(a: Vector2, b: Vector2, curv: int) -> float:
	var z: float = cdiv(b, conj(a)).length()
	if curv < 0: return 2.0 * atanh(minf(z, 0.999999999))
	if curv > 0: return 2.0 * atan(z)
	return 2.0 * z


## The tile: half its width (centre to the middle of an edge), metres. Four squares to a corner are given 1.1 m.
func inradius() -> float:
	if k() < 0: return acosh(cos(PI / 5.0) / sin(PI / 4.0))
	if k() > 0: return acos(cos(PI / 3.0) / sin(PI / 4.0))
	return 0.55


func _half_w() -> float:
	var r: float = inradius()
	return tanh(r * 0.5) if k() < 0 else (tan(r * 0.5) if k() > 0 else r * 0.5)


func _beyond(z: Vector2, i: int) -> bool:
	var dir: Vector2 = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)][i]
	if k() == 0: return z.dot(dir) > _half_w()
	var r: float = inradius()
	var far: float = (1.0 / tanh(r)) if k() < 0 else (-1.0 / tan(r))
	var sigma: float = (1.0 / sinh(r)) if k() < 0 else (1.0 / sin(r))
	var l2: float = (z - dir * far).length_squared()
	return l2 < sigma * sigma if k() < 0 else l2 > sigma * sigma


## Into the neighbouring tile across edge i: a half turn about that edge's middle.
func _across(i: int) -> void:
	var dir: Vector2 = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)][i]
	var out: Array = step_motion(dir * inradius(), k())
	var back: Array = step_motion(-dir * inradius(), k())
	var half: Array = compose(out[0], out[1], Vector2(0, 1), Vector2.ZERO, k())
	half = compose(half[0], half[1], back[0], back[1], k())
	var next: Array = compose(half[0], half[1], _va, _vb, k())
	_va = next[0]
	_vb = next[1]
	_tiles += 1


func _move(by: Vector2) -> void:
	var motion: Array = step_motion(by, k())
	var v: Array = compose(_va, _vb, motion[0], motion[1], k())
	_va = v[0]
	_vb = v[1]
	var g: Array = compose(_ga, _gb, motion[0], motion[1], k())
	_ga = g[0]
	_gb = g[1]
	for n in 6:
		var here: Vector2 = cdiv(_vb, conj(_va))
		var crossed := false
		for i in 4:
			if _beyond(here, i):
				_across(i)
				crossed = true
				break
		if not crossed: break


func home_m() -> float:
	return reach(_ga, _gb, k())


func turned_deg() -> float:
	return wrapf(rad_to_deg(2.0 * atan2(_ga.y, _ga.x)), -180.0, 180.0)


func _identity() -> void:
	_va = Vector2(1, 0)
	_vb = Vector2.ZERO
	_ga = Vector2(1, 0)
	_gb = Vector2.ZERO
	_tiles = 0


## Nobody on the deck: the picture is drawn from START, a tile under it.
func _rest() -> void:
	_identity()
	_home = false
	_back = false
	_walked = 0.0
	_still = 0.0
	_last = Vector2(START.x, START.z)
	_push()
	_tell()


func _push() -> void:
	var r: float = inradius()
	_skin.set_shader_parameter("kind", k())
	_skin.set_shader_parameter("body", _last)
	_skin.set_shader_parameter("vinv_a", _va)
	_skin.set_shader_parameter("vinv_b", _vb)
	var near: bool = _home and home_m() < 5.5
	_skin.set_shader_parameter("home_on", near)
	_skin.set_shader_parameter("g_a", _ga if near else Vector2(1, 0))
	_skin.set_shader_parameter("g_b", _gb if near else Vector2.ZERO)
	_skin.set_shader_parameter("half_w", _half_w())
	if k() != 0:
		_skin.set_shader_parameter("centre_far", (1.0 / tanh(r)) if k() < 0 else (-1.0 / tan(r)))
		_skin.set_shader_parameter("sigma", (1.0 / sinh(r)) if k() < 0 else (1.0 / sin(r)))
	# the pointer at the walker's feet: which way home lies
	var show: bool = _home and _on and home_m() > 0.35
	_pointer.visible = show
	if show:
		var toward: Vector2 = cdiv(-_gb, _ga)
		var bearing: Vector2 = toward.normalized() if toward.length() > 1e-9 else Vector2(1, 0)
		_pointer.position = Vector3(_last.x + bearing.x * 0.55, 0.05, _last.y + bearing.y * 0.55)
		_pointer.rotation.y = atan2(bearing.x, bearing.y)
		_pointer_tag.text = "home  %.1f m" % home_m()


func _physics_process(delta: float) -> void:
	var here := _body != null and is_instance_valid(_body)
	var p := to_local(_body.global_position) if here else Vector3.ZERO
	var on: bool = here and Vector2(p.x, p.z).length() < DECK - 0.05 and absf(p.y) < 1.5
	if not on:
		if _on:
			_on = false
			_rest()
		return
	var at := Vector2(p.x, p.z)
	if not _on:
		# stepping on: as if walked straight from START
		_on = true
		_identity()
		_last = Vector2(START.x, START.z)
		_move(at - _last)
		_last = at
		_push()
		_tell()
		return
	var by: Vector2 = at - _last
	var mark: float = at.distance_to(Vector2(START.x, START.z))
	if by.length() > 0.0008:
		_move(by)
		_walked += by.length()
		_last = at
		_still = 0.0
		_push()
	else:
		_still += delta
	if not _home and mark < 0.3 and _still > 0.8:
		_identity()
		_home = true
		_walked = 0.0
		_back = false
		_push()
		_tell()
	elif _home:
		if not _back and mark < 0.3 and _walked > SIDE * 2.0 and _still > 0.4:
			_back = true
			_tell()
		elif _back and mark > 0.45:
			_back = false
			_tell()


func _tell() -> void:
	if _board == null: return
	var count: String = {"five": "FIVE", "four": "FOUR", "three": "THREE"}[corner]
	var lines := PackedStringArray(["%s SQUARES AT EVERY CORNER" % count])
	if k() < 0:
		lines.append("The deck shows a floor on which five square tiles meet at every corner. Under your feet it is true to size. Farther off it is squeezed toward a rim that keeps three metres from you: within three metres this floor has 57 m², a flat one 28.")
	elif k() > 0:
		lines.append("The deck shows a floor on which three square tiles meet at every corner: a cube's skin, rounded. There are six tiles and 12.6 m² in all. 6.28 m straight ahead is where you stand.")
	else:
		lines.append("The deck shows a floor on which four square tiles meet at every corner: a floor. The tiles stay where they are.")
	lines.append("Stand still on START: the tile under you turns red, home, its arrow pointing north. Then walk the pink square - forward, left, forward, left, forward, left, forward - back to START.")
	if _back:
		if home_m() < 0.3: lines.append("You are back on START after %.1f m, and home is under your feet. The square closed." % _walked)
		else: lines.append("You are back on START after %.1f m. Home is %.1f m away and its arrow has turned %d°. The square closed on the deck. It did not close on this floor." % [_walked, home_m(), int(round(absf(turned_deg())))])
	elif _home:
		lines.append("Home is set. Walk the pink square.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _strip(from: Vector3, to: Vector3, wide: float, colour: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(wide, 0.006, 1.0)
	mesh.mesh = box
	mesh.material_override = _city.flat(colour, 0.5)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.position = (from + to) * 0.5
	mesh.scale = Vector3(1, 1, maxf(0.02, from.distance_to(to)))
	mesh.rotation.y = atan2(to.x - from.x, to.z - from.z)
	add_child(mesh)


func _build_once() -> void:
	# the deck: one disk, its skin the tiling
	_skin = ShaderMaterial.new()
	_skin.shader = SHADER
	_skin.set_shader_parameter("deck_r", DECK)
	_skin.set_shader_parameter("horizon", HORIZON)
	var deck := MeshInstance3D.new()
	var disk := PlaneMesh.new()
	disk.size = Vector2(DECK * 2.0, DECK * 2.0)
	deck.mesh = disk
	deck.material_override = _skin
	deck.position = Vector3(0, 0.012, 0)
	deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deck.name = "Deck"
	add_child(deck)
	var rim := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = DECK - 0.03
	ring.outer_radius = DECK + 0.05
	rim.mesh = ring
	rim.scale = Vector3(1, 0.06, 1)
	rim.material_override = _city.flat(Color("3a3d45"), 0.6)
	rim.position = Vector3(0, 0.014, 0)
	add_child(rim)
	# painted on the deck itself: the square to walk, and START
	var half: float = SIDE * 0.5
	var corners: Array[Vector3] = [Vector3(-half, 0.022, half), Vector3(half, 0.022, half), Vector3(half, 0.022, -half), Vector3(-half, 0.022, -half)]
	for i in 4:
		var from: Vector3 = corners[i]
		var to: Vector3 = corners[(i + 1) % 4]
		_strip(from, to, 0.045, PINK)
		var along: Vector3 = (to - from).normalized()
		var across: Vector3 = Vector3(-along.z, 0, along.x)
		var tip: Vector3 = from.lerp(to, 0.62)
		for hand in [-1.0, 1.0]: _strip(tip, tip - along * 0.16 + across * hand * 0.1, 0.035, PINK)
	var start := MeshInstance3D.new()
	var mark := TorusMesh.new()
	mark.inner_radius = 0.22
	mark.outer_radius = 0.27
	start.mesh = mark
	start.scale = Vector3(1, 0.05, 1)
	start.material_override = _city.flat(PINK, 0.5)
	start.position = START + Vector3(0, 0.024, 0)
	add_child(start)
	_city.floor_words(self, START + Vector3(-0.05, 0.03, 0.48), "START", 30, PINK.lightened(0.35))
	# which way home lies, at the walker's feet
	_pointer = Node3D.new()
	_pointer.name = "Pointer"
	add_child(_pointer)
	var shaft := MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.05, 0.012, 0.34)
	shaft.mesh = bar
	shaft.material_override = _city.flat(Color("c1121c"), 0.5)
	_pointer.add_child(shaft)
	var head := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.16, 0.16, 0.012)
	head.mesh = prism
	head.material_override = _city.flat(Color("c1121c"), 0.5)
	head.rotation.x = PI * 0.5
	head.position = Vector3(0, 0, 0.24)
	_pointer.add_child(head)
	_pointer_tag = _city.sign_post(_pointer, Vector3(0, 0.42, 0))
	_pointer_tag.pixel_size = 0.0024
	_pointer_tag.modulate = Color(1.0, 0.86, 0.86)
	# the body, and the board east of the deck, read from the deck
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := CylinderShape3D.new()
	room.radius = DECK + 1.2
	room.height = 3.4
	var area := CollisionShape3D.new()
	area.shape = room
	area.position = Vector3(0, 1.7, 0)
	sensor.add_child(area)
	add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	_board = _city.board(self, Vector3(DECK + 0.6, 0, -1.3), 3.0, 1.35)
	(_board.get_parent().get_parent() as Node3D).rotation.y = -PI * 0.5


## ---- for a test ----

func state() -> Dictionary:
	return {"corner": corner, "k": k(), "on_deck": _on, "home_set": _home, "home_m": snappedf(home_m(), 0.001), "turned_deg": snappedf(turned_deg(), 0.1), "walked_m": snappedf(_walked, 0.01), "back": _back,
		"tiles_crossed": _tiles, "inradius": snappedf(inradius(), 0.0001), "board": _board.text if _board != null else "", "pointer": _pointer.visible, "prefab_parts": int(_city.parts), "build_ms": _build_ms}


## The corners of the painted square, from START going round with the square on the left: 0 START, 1, 2, 3.
func square_point(i: int) -> Vector3:
	var half: float = SIDE * 0.5
	var corners: Array[Vector3] = [Vector3(-half, 0, half), Vector3(half, 0, half), Vector3(half, 0, -half), Vector3(-half, 0, -half)]
	return to_global(corners[posmod(i, 4)])


func off_deck_point() -> Vector3:
	return to_global(Vector3(-DECK - 1.2, 0, 0.7))
