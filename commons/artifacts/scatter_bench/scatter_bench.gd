extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ScatterBench
## @identity
## lineage: Pollock's drip canvas — Cage's chance operations with a loaded brush
## essence: aim is abandoned; the hand flings and the field decides
## truth: randomness is not noise — held long enough, it composes

@export var density: float = 0.6
@export var max_marks: int = 80

var _canvas: Node3D
var _marks: Array = []
var _palette: Array = []
var _dial: MeshInstance3D
var _step := 0.0
var _w := 0.9
var _h := 0.68

func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())

func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("density"): density = float(config["density"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()

func _build() -> void:
	_marks.clear()
	_palette = [Color(0.95, 0.2, 0.2), Color(0.95, 0.85, 0.2), Color(0.2, 0.6, 0.95), Color(0.95, 0.95, 0.95)]
	var steel := _steel_mat(Color(0.4, 0.42, 0.5))
	var wood := _matte_mat(Color(0.35, 0.25, 0.18), 0.85)
	add_child(_box(Vector3(0, 0.75, 0), Vector3(1.1, 0.2, 0.5), steel))
	# Easel legs + canvas.
	add_child(_cylinder_between(Vector3(-0.35, 0.85, 0.1), Vector3(-0.2, 1.55, -0.05), 0.02, wood))
	add_child(_cylinder_between(Vector3(0.35, 0.85, 0.1), Vector3(0.2, 1.55, -0.05), 0.02, wood))
	add_child(_box(Vector3(0, 1.2, -0.08), Vector3(_w + 0.06, _h + 0.06, 0.02), _matte_mat(Color(0.92, 0.9, 0.85), 0.9)))
	_canvas = Node3D.new()
	_canvas.position = Vector3(0, 1.2, -0.06)
	add_child(_canvas)
	# Canvas already covered in drips and splatters.
	for i in range(max_marks):
		_fling_mark()
	# Density dial.
	add_child(_cylinder(Vector3(0.45, 0.92, 0.0), 0.12, 0.05, steel))
	_dial = _box(Vector3(0.45, 0.95, 0.0), Vector3(0.02, 0.15, 0.02), _glow_mat(Color(1.0, 0.5, 0.3), 3.0))
	_dial.rotation.z = lerpf(1.2, -1.2, density)
	add_child(_dial)
	add_child(_billboard_label("Random art / chance as a brush", Vector3(0, 1.66, 0), 26, Color(1.0, 0.9, 0.8)))

func _fling_mark() -> void:
	var col: Color = _palette[_rng.randi() % _palette.size()]
	var mat := _glow_mat(col, 2.2)
	var cx := _rng.randf_range(-_w * 0.46, _w * 0.46)
	var cy := _rng.randf_range(-_h * 0.46, _h * 0.46)
	var pick := _rng.randf()
	var node: Node3D
	if pick < 0.4:
		# Flung dotted line.
		var dir := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized() * _rng.randf_range(0.08, 0.22)
		node = _dashed(Vector3(cx, cy, 0.01), Vector3(cx + dir.x, cy + dir.y, 0.01), 0.006, mat)
	elif pick < 0.7:
		# Short arc.
		node = Node3D.new()
		var n := 5
		for i in range(n):
			var t := float(i) / float(n)
			var ang := _rng.randf_range(0, TAU) + t * 1.4
			var rr := _rng.randf_range(0.04, 0.1)
			node.add_child(_sphere(Vector3(cx + cos(ang) * rr, cy + sin(ang) * rr, 0.012), 0.008, mat))
	else:
		# Speckle cluster.
		node = Node3D.new()
		var n := _rng.randi_range(3, 7)
		for i in range(n):
			node.add_child(_sphere(Vector3(cx + _rng.randf_range(-0.04, 0.04), cy + _rng.randf_range(-0.04, 0.04), 0.012), _rng.randf_range(0.005, 0.012), mat))
	_canvas.add_child(node)
	_marks.append(node)

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	density = 0.55 + sin(Time.get_ticks_msec() * 0.0004) * 0.35
	if _dial: _dial.rotation.z = lerpf(1.2, -1.2, density)
	_step += delta
	if _step < 0.3: return
	_step = 0.0
	var n := 1 + int(density * 3.0)
	for i in range(n):
		_fling_mark()
	# Cull oldest to cap total marks.
	while _marks.size() > max_marks:
		var old: Node3D = _marks.pop_front()
		old.queue_free()
