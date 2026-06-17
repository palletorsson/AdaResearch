extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WindRoom

## @identity
## lineage: the room-scale, walk-in end of the Wind ladder — a field of tall windsocks and ground
##   streamers you stand among, all leaning the same way, so the invisible field becomes a place.
## essence: a wind field is one direction and one speed filling the space; every sock and streamer
##   reports the same v², and the big arrow names the way it blows. Stand in it and read the room.
## truth: wind is a field — a force that has decided to be everywhere at once, and you are in it.

@export var wind: float = 0.7
@export var sock_color: Color = Color(0.98, 0.72, 0.32)
@export var arrow_color: Color = Color(0.55, 0.92, 1.0)
var _socks: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("wind"): wind = clampf(float(config["wind"]), 0.0, 1.0)
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_socks.clear()
	_build()


func _build() -> void:
	var steel := _steel_mat(Color(0.34, 0.36, 0.42))
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7, 0.08, 7), _matte_mat(Color(0.16, 0.17, 0.2), 0.9)))
	# a grid of tall windsock poles you walk between
	for gx in [-2.2, 0.0, 2.2]:
		for gz in [-2.2, 0.0, 2.2]:
			if gx == 0.0 and gz == 0.0:
				continue
			var pole := Vector3(gx, 0, gz)
			add_child(_cylinder(pole + Vector3(0, 1.4, 0), 0.04, 2.8, steel))
			var sock := Node3D.new(); sock.position = pole + Vector3(0, 2.8, 0); add_child(sock)
			_socks.append(sock)
	# the big direction arrow overhead — the field's one direction
	add_child(_billboard_label("WIND FIELD\nF ∝ v²   ·   one direction, everywhere\nstand in it and read the room", Vector3(0, 3.6, 0), 30, arrow_color.lerp(Color.WHITE, 0.3)))
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _socks.is_empty():
		return
	_t += delta
	_redraw()


func _redraw() -> void:
	var ang: float = lerpf(deg_to_rad(-82.0), deg_to_rad(-6.0), wind)
	var flap: float = (1.0 - wind) * 0.12
	for i in range(_socks.size()):
		var sock: Node3D = _socks[i]
		for c in sock.get_children():
			sock.remove_child(c); c.queue_free()
		var a: float = ang + sin(_t * 4.0 + i) * flap
		var dir := Vector3(cos(a) + 0.7, sin(a), 0).normalized()
		for s in range(5):
			var r: float = 0.13 - s * 0.022
			sock.add_child(_sphere(dir * (0.22 * s), maxf(r, 0.03), _glow_mat(sock_color.lerp(Color.WHITE, 0.08 * s), 1.0)))
