extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TenPrintTextile
## @identity
## lineage: 10 PRINT as a Jacquard loom — chance threaded into a continuous bolt
## essence: the maze becomes cloth, woven forever, no two metres alike
## truth: a generative rule is a pattern that production never finishes printing

@export var cols: int = 14
@export var rows: int = 18

var _bolt: Node3D
var _woven: Array = []
var _step := 0.0
var _row_h := 0.07
var _top_y := 1.4
var _bottom_y := -0.2

func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())

func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()

func _build() -> void:
	_woven.clear()
	var steel := _steel_mat(Color(0.45, 0.4, 0.35))
	# Loom frame: two uprights and a heddle beam the cloth spills over.
	add_child(_box(Vector3(-0.55, 0.6, 0), Vector3(0.06, 1.7, 0.1), steel))
	add_child(_box(Vector3(0.55, 0.6, 0), Vector3(0.06, 1.7, 0.1), steel))
	add_child(_cylinder_between(Vector3(-0.55, _top_y, 0), Vector3(0.55, _top_y, 0), 0.05, steel))
	add_child(_cylinder_between(Vector3(-0.55, _top_y + 0.12, 0.0), Vector3(0.55, _top_y + 0.12, 0.0), 0.03, steel))
	_bolt = Node3D.new()
	add_child(_bolt)
	# Full hanging bolt already woven, top to bottom.
	for r in range(rows):
		var y := _top_y - (float(r) + 0.5) * _row_h
		_woven.append(_weave_row(y))
	add_child(_billboard_label("10 PRINT textile", Vector3(0, _top_y + 0.32, 0), 24, Color(0.95, 0.85, 0.6)))

func _weave_row(y: float) -> Array:
	var w := 1.0
	var sx := w / float(cols)
	var threads: Array = []
	for c in range(cols):
		var cx := -w * 0.5 + (float(c) + 0.5) * sx
		var slash := _rng.randf() < 0.5
		# Thread colors: warm warp vs cool weft per coin flip.
		var hue := (0.07 if slash else 0.58) + _rng.randf() * 0.05
		var mat := _glow_mat(Color.from_hsv(hue, 0.6, 0.95), 1.8)
		var bar := _box(Vector3(cx, y, 0.02), Vector3(sx * 0.9, _row_h * 0.42, 0.03), mat)
		bar.rotation.z = (PI * 0.25) if slash else (-PI * 0.25)
		_bolt.add_child(bar)
		threads.append(bar)
	return threads

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_step += delta
	if _step < 0.18: return
	_step = 0.0
	# Scroll the whole bolt down; new woven row appears at the top.
	for row in _woven:
		for bar in row:
			bar.position.y -= _row_h
	# Cull the row that fell off the bottom, weave a fresh one at the top.
	if _woven.size() > 0 and _woven[0].size() > 0 and _woven[0][0].position.y < _bottom_y:
		var dead: Array = _woven.pop_front()
		for bar in dead:
			bar.queue_free()
		_woven.append(_weave_row(_top_y - _row_h * 0.5))
