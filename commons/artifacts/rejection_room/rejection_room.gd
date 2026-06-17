extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RejectionRoom

## @identity
## lineage: rejection sampling — the room you stand inside (toy → bench → room)
## essence: darts rain through the volume; those under the curve settle into a band of light
## truth: walk into the discarding and the kept ones become a floor of glow.

@export var rain_count: int = 70
@export var fall_speed: float = 2.2
@export var settled_keep: int = 220

var _rain: Node3D
var _settled: Node3D
const W: float = 6.0          # curve span across X
const TOP: float = 6.0        # rain start height
const CURVE_Z: float = -3.2   # back wall depth


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("rain_count"): rain_count = int(config["rain_count"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


# curve height in metres for x in [-W/2, W/2]
func _curve_h(x: float) -> float:
	var t: float = (x + W * 0.5) / W            # 0..1
	var d: float = (t - 0.5) / 0.17
	return 0.4 + 4.4 * exp(-0.5 * d * d)


func _build() -> void:
	# floor slab
	add_child(_box(Vector3(0, -0.05, -1.0), Vector3(7.5, 0.1, 7.5), _matte_mat(Color(0.1, 0.11, 0.14))))
	# giant target curve as a glowing wall of points across the back
	var cmat := _glow_mat(Color(0.95, 0.8, 0.3), 2.6)
	for i in range(61):
		var x: float = -W * 0.5 + W * float(i) / 60.0
		_add_point_column(x, cmat)
	# already-settled accepted distribution: a band of light on the floor
	_settled = Node3D.new()
	add_child(_settled)
	for i in range(settled_keep):
		_spawn_settled()
	# falling rain mid-flight
	_rain = Node3D.new()
	add_child(_rain)
	for i in range(rain_count):
		_rain.add_child(_make_drop(_rng.randf() * TOP))
	# overhead label
	add_child(_billboard_label("REJECTION SAMPLING — the kept rain becomes the distribution", Vector3(0, 3.6, -1.0), 40, Color(0.85, 0.95, 1.0)))


func _add_point_column(x: float, mat: Material) -> void:
	var h: float = _curve_h(x)
	var n: int = 5
	for k in range(n):
		var y: float = 0.4 + (h - 0.4) * float(k) / float(n - 1)
		add_child(_sphere(Vector3(x, y, CURVE_Z), 0.07, mat))


func _spawn_settled() -> void:
	var x: float = _sample_under_x()
	var z: float = _rng.randf_range(-2.8, 1.5)
	_settled.add_child(_sphere(Vector3(x, 0.04, z), 0.05, _glow_mat(Color(0.2, 1.0, 0.4), 2.0)))


# draw an accepted x by rejection against the curve, so the floor band matches the shape
func _sample_under_x() -> float:
	for _i in range(20):
		var x: float = _rng.randf_range(-W * 0.5, W * 0.5)
		var y: float = _rng.randf_range(0.0, 5.0)
		if y <= _curve_h(x):
			return x
	return _rng.randf_range(-1.0, 1.0)


func _make_drop(start_y: float) -> MeshInstance3D:
	var x: float = _rng.randf_range(-W * 0.5, W * 0.5)
	var z: float = _rng.randf_range(-2.8, 1.5)
	var d := _sphere(Vector3(x, start_y, z), 0.045, _glow_mat(Color(0.6, 0.75, 1.0), 1.4))
	d.set_meta("x", x)
	d.set_meta("z", z)
	return d


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	for drop in _rain.get_children():
		var mi := drop as MeshInstance3D
		mi.position.y -= fall_speed * delta
		if mi.position.y <= 0.05:
			var x: float = mi.get_meta("x")
			# accept against the curve at this x: taller curve = more likely kept
			var accepted: bool = _curve_h(x) >= _rng.randf_range(0.4, 5.0)
			if accepted:
				_settled.add_child(_sphere(Vector3(x, 0.04, mi.get_meta("z")), 0.05, _glow_mat(Color(0.2, 1.0, 0.4), 2.0)))
			# respawn the drop at the top
			mi.position.y = TOP
			mi.position.x = _rng.randf_range(-W * 0.5, W * 0.5)
			mi.position.z = _rng.randf_range(-2.8, 1.5)
			mi.set_meta("x", mi.position.x)
			mi.set_meta("z", mi.position.z)
	# cap settled glow count
	while _settled.get_child_count() > settled_keep + 120:
		var old := _settled.get_child(0)
		_settled.remove_child(old); old.queue_free()
