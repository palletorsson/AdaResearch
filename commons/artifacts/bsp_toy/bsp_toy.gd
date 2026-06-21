extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BspToy

## @identity
## name: "Boolean & space partition"
## tier: small
## truth: "CUT IN TWO, THEN CUT EACH HALF" — a square becomes a floor plan by nothing
##   but a recursion of straight cuts; partition is the cheapest architecture.
## essence: A held ~0.35m BSP. A square splits recursively, alternating horizontal /
##   vertical at a random ratio, down to a minimum size; every leaf is a room — an
##   inset thin box of varied colour and height. The nesting is the whole point.

@export var extent: float = 0.34
@export var min_leaf: float = 0.05
@export var max_depth: int = 5
@export var inset: float = 0.008
@export var base_col: Color = Color(0.14, 0.15, 0.18)
@export var label_col: Color = Color(0.85, 0.90, 0.98)

const PAL := [
	Color(0.30, 0.65, 0.95),
	Color(0.95, 0.55, 0.25),
	Color(0.45, 0.85, 0.55),
	Color(0.90, 0.40, 0.65),
	Color(0.95, 0.85, 0.30),
	Color(0.55, 0.50, 0.90),
]


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("max_depth"):
		max_depth = clampi(int(config["max_depth"]), 2, 7)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _split(x: float, z: float, w: float, d: float, depth: int, horizontal: bool) -> void:
	# stop: too deep, too small, or a random chance to leave this a leaf
	var too_small: bool = (w < min_leaf * 2.0) or (d < min_leaf * 2.0)
	if depth >= max_depth or too_small or (depth >= 2 and _rng.randf() < 0.22):
		_emit_leaf(x, z, w, d, depth)
		return
	var ratio: float = _rng.randf_range(0.35, 0.65)
	if horizontal:
		var dw: float = w * ratio
		_split(x, z, dw, d, depth + 1, false)
		_split(x + dw, z, w - dw, d, depth + 1, false)
	else:
		var dd: float = d * ratio
		_split(x, z, w, dd, depth + 1, true)
		_split(x, z + dd, w, d - dd, depth + 1, true)


func _emit_leaf(x: float, z: float, w: float, d: float, depth: int) -> void:
	var iw: float = maxf(w - inset * 2.0, 0.004)
	var id: float = maxf(d - inset * 2.0, 0.004)
	var col: Color = PAL[depth % PAL.size()]
	var h: float = 0.010 + depth * 0.010
	var cx: float = x + w * 0.5 - extent * 0.5
	var cz: float = z + d * 0.5 - extent * 0.5
	add_child(_box(Vector3(cx, h * 0.5 + 0.002, cz), Vector3(iw, h, id), _glow_mat(col, 1.0)))


func _build() -> void:
	# base plate (the un-cut square)
	add_child(_box(Vector3(0.0, -0.004, 0.0), Vector3(extent + 0.02, 0.012, extent + 0.02), _matte_mat(base_col, 0.7)))
	_split(0.0, 0.0, extent, extent, 0, _rng.randf() < 0.5)
	add_child(_billboard_label("BSP", Vector3(0.0, extent * 0.7 + 0.10, 0.0), 16, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	rotation.y += delta * 0.4
