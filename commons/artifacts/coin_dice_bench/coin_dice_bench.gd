extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CoinDiceBench
## @identity
## lineage: the oldest randomizers — a flipped coin, a thrown die
## essence: two faces, six faces — discrete outcomes counted until the bars level out
## truth: every toss forgets the last; only the tally remembers

@export var spin_speed: float = 5.0

var _coin: Node3D
var _die: Node3D
var _bars: Node3D
var _heads: int = 26
var _tails: int = 24
var _faces: Array[int] = [9, 8, 9, 8, 9, 8]
var _t: float = 0.0

func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())

func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()

func _build() -> void:
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 0.7), _steel_mat(Color(0.3, 0.32, 0.38))))
	add_child(_cylinder(Vector3(0, -0.25, 0), 0.08, 0.5, _steel_mat(Color(0.22, 0.24, 0.28))))
	# coin on a peg, edge-on mid-flip
	add_child(_cylinder(Vector3(-0.32, 0.55, 0.05), 0.015, 0.42, _steel_mat(Color(0.4, 0.42, 0.48))))
	_coin = Node3D.new()
	_coin.position = Vector3(-0.32, 0.78, 0.05)
	var coin_mesh: MeshInstance3D = _cylinder(Vector3.ZERO, 0.13, 0.025, _glow_mat(Color(1.0, 0.85, 0.3), 1.2))
	coin_mesh.rotation.x = PI * 0.5
	_coin.add_child(coin_mesh)
	add_child(_coin)
	# die on a tray
	add_child(_box(Vector3(0.34, 0.52, 0.05), Vector3(0.3, 0.04, 0.3), _matte_mat(Color(0.15, 0.16, 0.2))))
	_die = Node3D.new()
	_die.position = Vector3(0.34, 0.66, 0.05)
	_die.rotation = Vector3(0.4, 0.7, 0.2)
	_build_die(_die)
	add_child(_die)
	# back panel with two bar charts
	add_child(_box(Vector3(0, 1.0, -0.32), Vector3(1.1, 0.9, 0.04), _matte_mat(Color(0.1, 0.11, 0.14))))
	_bars = Node3D.new()
	add_child(_bars)
	_rebuild_bars()
	add_child(_billboard_label("DISCRETE CHANCE", Vector3(0, 1.6, -0.3), 38, Color(0.95, 0.95, 1.0)))

func _build_die(parent: Node3D) -> void:
	parent.add_child(_box(Vector3.ZERO, Vector3(0.18, 0.18, 0.18), _matte_mat(Color(0.9, 0.9, 0.92))))
	var pip := _glow_mat(Color(0.1, 0.1, 0.12), 0.4)
	var f: float = 0.092
	for off in [Vector3(0.05, 0.05, f), Vector3(-0.05, -0.05, f), Vector3(f, 0.0, 0.0), Vector3(0.0, f, -0.05)]:
		parent.add_child(_sphere(off, 0.022, pip))

func _rebuild_bars() -> void:
	for c in _bars.get_children():
		_bars.remove_child(c); c.queue_free()
	var heads_mat := _glow_mat(Color(0.4, 0.9, 1.0), 1.4)
	var ht_max: float = float(maxi(_heads, _tails)) + 1.0
	var hx: Array[float] = [-0.42, -0.28]
	var hv: Array[int] = [_heads, _tails]
	for i in range(2):
		var h: float = clampf(float(hv[i]) / ht_max, 0.05, 1.0) * 0.55
		_bars.add_child(_box(Vector3(hx[i], 0.72 + h * 0.5, -0.29), Vector3(0.09, h, 0.04), heads_mat))
	var die_mat := _glow_mat(Color(1.0, 0.7, 0.35), 1.4)
	var dmax: float = float(_faces.max()) + 1.0
	for i in range(6):
		var dh: float = clampf(float(_faces[i]) / dmax, 0.05, 1.0) * 0.55
		_bars.add_child(_box(Vector3(-0.05 + i * 0.085, 0.72 + dh * 0.5, -0.29), Vector3(0.06, dh, 0.04), die_mat))

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_coin.rotation.x += spin_speed * delta
	_die.rotation.y += spin_speed * 0.6 * delta
	_die.rotation.x += spin_speed * 0.4 * delta
	_t += delta
	if _t >= 0.5:
		_t = 0.0
		if _rng.randf() < 0.5: _heads += 1
		else: _tails += 1
		_faces[_rng.randi_range(0, 5)] += 1
		_rebuild_bars()
