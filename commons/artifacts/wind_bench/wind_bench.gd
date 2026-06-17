extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WindBench

## @identity
## lineage: the bench-scale middle of the Wind ladder — a desk fan and a windsock, the push made
##   readable as the sock swings from hanging to horizontal.
## essence: drag force F = ½ρv²C_dA grows with the square of speed; double the wind and the sock's
##   lift quadruples. The fan's blur and the sock's angle both track the same v².
## truth: wind is air with somewhere to be; the force is in the speed, squared.

@export var wind: float = 0.6
@export var sock_color: Color = Color(0.98, 0.72, 0.32)
@export var fan_color: Color = Color(0.55, 0.92, 1.0)
var _fan: Node3D
var _sock: Node3D
var _readout: Label3D
var _t: float = 0.0
const BASE_Y := 0.9


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("wind"): wind = clampf(float(config["wind"]), 0.0, 1.0)
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	var steel := _steel_mat(Color(0.32, 0.34, 0.4))
	add_child(_box(Vector3(0, BASE_Y - 0.1, 0), Vector3(2.6, 0.2, 1.6), _matte_mat(Color(0.15, 0.16, 0.2), 0.8)))
	add_child(_cylinder(Vector3(0, BASE_Y * 0.5, 0), 0.12, BASE_Y - 0.2, steel))
	# the fan (left) — a hub + blades that spin
	_fan = Node3D.new(); _fan.position = Vector3(-0.8, BASE_Y + 0.3, 0); _fan.rotation = Vector3(0, deg_to_rad(90), 0); add_child(_fan)
	add_child(_cylinder(Vector3(-0.8, BASE_Y + 0.3, 0), 0.04, 0.5, steel))
	for i in range(3):
		var a := TAU * float(i) / 3.0
		var bl := _box(Vector3(cos(a) * 0.18, sin(a) * 0.18, 0), Vector3(0.16, 0.08, 0.015), _glow_mat(fan_color, 0.8))
		bl.rotation.z = a; _fan.add_child(bl)
	# the windsock (right) — a pole + a cone that swings up with the wind
	add_child(_cylinder(Vector3(0.7, BASE_Y + 0.25, 0), 0.03, 0.5, steel))
	_sock = Node3D.new(); _sock.position = Vector3(0.7, BASE_Y + 0.5, 0); add_child(_sock)
	_readout = _billboard_label("WIND", Vector3(0, BASE_Y + 1.7, 0), 24, sock_color.lerp(Color.WHITE, 0.3))
	add_child(_readout)
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _fan == null:
		return
	_t += delta
	_fan.rotation.z = _t * (2.0 + wind * 8.0)
	_redraw()


func _redraw() -> void:
	for c in _sock.get_children():
		_sock.remove_child(c); c.queue_free()
	var ang: float = lerpf(deg_to_rad(-85.0), deg_to_rad(-8.0), wind)            # hangs down at low wind, near-horizontal at high
	var dir := Vector3(cos(ang) + 0.6, sin(ang), 0).normalized()
	for s in range(4):                                                          # the tapering sock segments
		var r: float = 0.09 - s * 0.018
		_sock.add_child(_sphere(dir * (0.14 * s), maxf(r, 0.02), _glow_mat(sock_color.lerp(Color.WHITE, 0.1 * s), 1.0)))
	var v: float = lerpf(2.0, 9.0, wind)
	if _readout:
		_readout.text = "WIND\nF = ½ρv²C_dA  (∝ v²)\nv = %.1f   →   push ∝ %.0f" % [v, v * v]
