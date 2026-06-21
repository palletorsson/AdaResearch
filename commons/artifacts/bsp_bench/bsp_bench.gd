extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BspBench

## @identity
## name: "Boolean & space partition"
## tier: medium
## truth: "SUBTRACTION BECOMES ARCHITECTURE" — take away from a solid block along
##   chosen planes and what is left is rooms, walls and the corridors that join them.
## essence: A bench BSP floor plan. Recursive splitting carves rooms (floor boxes with
##   low wall outlines); sibling rooms are linked by a corridor cut between their
##   centres. The plan reads as a tiny building seen from above.

@export var plan: float = 0.92
@export var min_leaf: float = 0.10
@export var max_depth: int = 4
@export var wall_h: float = 0.05
@export var body_col: Color = Color(0.16, 0.17, 0.21)
@export var floor_col: Color = Color(0.30, 0.40, 0.55)
@export var wall_col: Color = Color(0.70, 0.66, 0.60)
@export var hall_col: Color = Color(0.95, 0.78, 0.30)
@export var label_col: Color = Color(0.85, 0.90, 0.98)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("max_depth"):
		max_depth = clampi(int(config["max_depth"]), 2, 6)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


# returns center Vector2 (in plan-local coords, origin at corner) of the node's room
func _split(x: float, z: float, w: float, d: float, depth: int, horizontal: bool) -> Vector2:
	var too_small: bool = (w < min_leaf * 2.0) or (d < min_leaf * 2.0)
	if depth >= max_depth or too_small or (depth >= 2 and _rng.randf() < 0.20):
		return _emit_room(x, z, w, d, depth)
	var ratio: float = _rng.randf_range(0.38, 0.62)
	var a: Vector2
	var b: Vector2
	if horizontal:
		var dw: float = w * ratio
		a = _split(x, z, dw, d, depth + 1, false)
		b = _split(x + dw, z, w - dw, d, depth + 1, false)
	else:
		var dd: float = d * ratio
		a = _split(x, z, w, dd, depth + 1, true)
		b = _split(x, z + dd, w, d - dd, depth + 1, true)
	_emit_corridor(a, b)
	return (a + b) * 0.5


func _emit_room(x: float, z: float, w: float, d: float, depth: int) -> Vector2:
	var pad: float = 0.012
	var iw: float = maxf(w - pad * 2.0, 0.02)
	var id: float = maxf(d - pad * 2.0, 0.02)
	var cx: float = x + w * 0.5 - plan * 0.5
	var cz: float = z + d * 0.5 - plan * 0.5
	# floor
	add_child(_box(Vector3(cx, 0.862, cz), Vector3(iw, 0.008, id), _matte_mat(floor_col, 0.7)))
	# wall outline as four thin bars
	var t: float = 0.012
	add_child(_box(Vector3(cx, 0.86 + wall_h * 0.5, cz - id * 0.5), Vector3(iw, wall_h, t), _matte_mat(wall_col, 0.8)))
	add_child(_box(Vector3(cx, 0.86 + wall_h * 0.5, cz + id * 0.5), Vector3(iw, wall_h, t), _matte_mat(wall_col, 0.8)))
	add_child(_box(Vector3(cx - iw * 0.5, 0.86 + wall_h * 0.5, cz), Vector3(t, wall_h, id), _matte_mat(wall_col, 0.8)))
	add_child(_box(Vector3(cx + iw * 0.5, 0.86 + wall_h * 0.5, cz), Vector3(t, wall_h, id), _matte_mat(wall_col, 0.8)))
	return Vector2(cx, cz)


func _emit_corridor(a: Vector2, b: Vector2) -> void:
	# L-shaped link: a thin glowing strip from a to b (horizontal leg then vertical leg)
	var corner := Vector2(b.x, a.y)
	_hall_seg(a, corner)
	_hall_seg(corner, b)


func _hall_seg(p: Vector2, q: Vector2) -> void:
	var mid: Vector2 = (p + q) * 0.5
	var len_x: float = absf(q.x - p.x)
	var len_z: float = absf(q.y - p.y)
	var sx: float = maxf(len_x, 0.02)
	var sz: float = maxf(len_z, 0.02)
	add_child(_box(Vector3(mid.x, 0.866, mid.y), Vector3(sx, 0.006, sz), _glow_mat(hall_col, 1.2)))


func _build() -> void:
	add_child(_box(Vector3(0.0, 0.40, 0.0), Vector3(1.1, 0.8, 1.1), _matte_mat(body_col, 0.7, 0.1)))
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(plan + 0.06, 0.02, plan + 0.06), _matte_mat(Color(0.09, 0.09, 0.11), 0.6)))
	_split(0.0, 0.0, plan, plan, 0, _rng.randf() < 0.5)
	add_child(_billboard_label("BSP PLAN", Vector3(0.0, 1.6, 0.0), 22, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	rotation.y = sin(Time.get_ticks_msec() * 0.0002) * 0.04
