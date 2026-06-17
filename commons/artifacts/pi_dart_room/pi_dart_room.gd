extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PiDartRoom
## @identity
## lineage: Monte Carlo estimators — Buffon's needle, the unit-square dartboard
## essence: pi falls out of pure chance — count the darts, divide, multiply by four
## truth: throw enough blind darts and the circle remembers its own number

@export var dart_rate: int = 6      # darts added per process tick
@export var max_darts: int = 700
@export var radius: float = 5.6     # quarter-circle radius across the floor

var _darts: Node3D
var _label: Label3D
var _inside: int = 0
var _total: int = 0
var _origin := Vector3(-2.8, 0.0, -2.8)   # the corner the arc sweeps from

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
	_inside = 0
	_total = 0
	add_child(_box(Vector3(0, -0.05, 0), Vector3(6.4, 0.1, 6.4), _matte_mat(Color(0.12, 0.13, 0.16))))
	# quarter-circle arc of light from the corner
	var arc_mat := _glow_mat(Color(0.4, 0.9, 1.0), 2.2)
	var seg: int = 40
	for i in range(seg):
		var a0: float = (float(i) / seg) * PI * 0.5
		var a1: float = (float(i + 1) / seg) * PI * 0.5
		var p0: Vector3 = _origin + Vector3(cos(a0), 0, sin(a0)) * radius + Vector3(0, 0.04, 0)
		var p1: Vector3 = _origin + Vector3(cos(a1), 0, sin(a1)) * radius + Vector3(0, 0.04, 0)
		add_child(_cylinder_between(p0, p1, 0.05, arc_mat))
	_darts = Node3D.new()
	add_child(_darts)
	_throw(260)   # pre-scatter so the circle reads immediately
	_label = _billboard_label("pi ~ 0.000", Vector3(0, 3.6, 0), 80, Color(0.95, 0.95, 1.0))
	add_child(_label)
	_refresh_label()

func _throw(n: int) -> void:
	var green := _glow_mat(Color(0.3, 1.0, 0.4), 1.6)
	var red := _glow_mat(Color(1.0, 0.35, 0.35), 1.6)
	for _i in range(n):
		var x: float = _rng.randf() * radius
		var z: float = _rng.randf() * radius
		var hit: bool = (x * x + z * z) <= radius * radius
		if hit: _inside += 1
		_total += 1
		var dot: MeshInstance3D = _sphere(_origin + Vector3(x, 0.06, z), 0.07, green if hit else red)
		_darts.add_child(dot)

func _refresh_label() -> void:
	if _total > 0:
		var est: float = 4.0 * float(_inside) / float(_total)
		_label.text = "pi ~ %.4f   (%d/%d)" % [est, _inside, _total]

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	if _darts.get_child_count() < max_darts:
		_throw(dart_rate)
		_refresh_label()
