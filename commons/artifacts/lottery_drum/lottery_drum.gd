extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LotteryDrum
## @identity
## lineage: the raffle cage, the bingo tumbler — uniform RNG you can watch turn
## essence: every numbered ball, equally likely; the tumble is fairness performed
## truth: uniform means no ball is favoured — surprise distributed without bias

@export var ball_count: int = 20
@export var draw_max: int = 49

var _drum: Node3D
var _readout: Label3D
var _chute_ball: MeshInstance3D
var _tumble := 0.0
var _drawn := -1

func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())

func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("draw_max"): draw_max = int(config["draw_max"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()

func _build() -> void:
	var steel := _steel_mat(Color(0.4, 0.42, 0.5))
	# Stand + axle cradle.
	add_child(_box(Vector3(0, 0.06, 0), Vector3(0.7, 0.12, 0.5), steel))
	add_child(_cylinder(Vector3(-0.32, 0.45, 0), 0.04, 0.7, steel))
	add_child(_cylinder(Vector3(0.32, 0.45, 0), 0.04, 0.7, steel))
	# Transparent drum shell: glass sphere + a glass band.
	var glass := _glass_mat(Color(0.6, 0.8, 1.0), 0.18)
	add_child(_sphere(Vector3(0, 0.8, 0), 0.3, glass))
	var band := _cylinder(Vector3(0, 0.8, 0), 0.31, 0.18, glass)
	band.rotation.x = PI * 0.5
	add_child(band)
	# Tumbling ball group inside.
	_drum = Node3D.new()
	_drum.position = Vector3(0, 0.8, 0)
	add_child(_drum)
	for i in range(ball_count):
		var dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized()
		var rr := _rng.randf_range(0.05, 0.22)
		var hue := _rng.randf()
		_drum.add_child(_sphere(dir * rr, 0.03, _glow_mat(Color.from_hsv(hue, 0.6, 1.0), 2.2)))
	# Output chute + the ball currently sitting in it.
	add_child(_box(Vector3(0.0, 0.42, 0.32), Vector3(0.12, 0.08, 0.18), steel))
	_chute_ball = _sphere(Vector3(0.0, 0.46, 0.42), 0.05, _glow_mat(Color(1.0, 0.85, 0.2), 3.0))
	add_child(_chute_ball)
	# Readout of the drawn number.
	_drawn = _rng.randi_range(1, draw_max)
	_readout = _billboard_label("DRAW: %d" % _drawn, Vector3(0, 1.3, 0), 30, Color(1.0, 0.9, 0.4))
	add_child(_readout)

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	# Tumble the balls.
	_drum.rotation.x += delta * 1.1
	_drum.rotation.y += delta * 1.7
	_tumble += delta
	if _tumble < 2.0: return
	_tumble = 0.0
	# Eject a fresh uniform draw, update readout + chute ball color.
	_drawn = _rng.randi_range(1, draw_max)
	if _readout: _readout.text = "DRAW: %d" % _drawn
	if _chute_ball:
		var hue := float(_drawn) / float(draw_max)
		_chute_ball.material_override = _glow_mat(Color.from_hsv(hue, 0.7, 1.0), 3.0)
