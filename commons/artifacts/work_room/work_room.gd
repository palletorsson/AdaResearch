extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WorkRoom

## @identity
## lineage: the room-scale, walk-in end of the Work ladder — a long floor track and a big cart you
##   push from one end to the other, the work piling up in a growing bar as the distance is paid out.
## essence: W = F·d. A steady force (orange) pushes a cart along the floor; every metre traversed
##   adds force × distance to the total, and the bar beside the track grows to that running sum.
## truth: work is force paid out over distance — only the part that goes the way of the motion counts.

@export var force_mag: float = 1.0
@export var track_length: float = 6.0
@export var cart_color: Color = Color(0.55, 0.60, 0.72)
@export var force_color: Color = Color(0.98, 0.72, 0.32)
@export var bar_color: Color = Color(0.55, 0.95, 0.58)

var _cart: Node3D
var _bar: Node3D
var _readout: Label3D
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("force_mag"): force_mag = float(config["force_mag"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	var half: float = track_length * 0.5
	add_child(_box(Vector3(0, -0.05, 0), Vector3(track_length + 0.8, 0.1, 1.6), _matte_mat(Color(0.16, 0.17, 0.2), 0.9)))
	for i in range(int(track_length) + 1):                     # distance ticks along the floor
		var tx: float = -half + float(i)
		add_child(_box(Vector3(tx, 0.02, 0), Vector3(0.05, 0.06, 1.4), _glow_mat(Color(0.4, 0.42, 0.5), 0.4)))
	_cart = Node3D.new(); add_child(_cart)
	_cart.add_child(_box(Vector3(0, 0.5, 0), Vector3(0.9, 1.0, 1.0), _glow_mat(cart_color, 0.6)))
	_bar = Node3D.new(); add_child(_bar)                       # the work bar grows beside the track
	_readout = _billboard_label("WORK", Vector3(0, 2.6, 0), 30, bar_color.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _cart == null:
		return
	_t += delta * 0.3
	_redraw()


func _redraw() -> void:
	var frac: float = fmod(_t, 1.0)
	var half: float = track_length * 0.5
	var x: float = lerpf(-half, half, frac)
	_cart.position = Vector3(x, 0, 0)
	for c in _bar.get_children():
		_bar.remove_child(c); c.queue_free()
	var origin := Vector3(x - 1.0, 0.5, 0)
	_bar.add_child(_arrow(origin, Vector3(x - 0.45, 0.5, 0), 0.07, _glow_mat(force_color, 1.5)))     # applied force F
	var d: float = x + half
	var W: float = force_mag * d
	var bar_h: float = maxf(W * 0.5, 0.001)                    # growing work bar at the far edge
	_bar.add_child(_box(Vector3(half + 0.6, bar_h * 0.5, 0), Vector3(0.4, bar_h, 0.4), _glow_mat(bar_color, 1.4)))
	if _readout:
		_readout.text = "WORK\nW = F·d\nF = %.1f   d = %.1f\nW = %.2f" % [force_mag, d, W]
