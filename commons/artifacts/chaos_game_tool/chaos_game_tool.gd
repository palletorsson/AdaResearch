extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ChaosGameTool

## @identity
## Iterated function systems (IFS) — APPLIED, a chaos-game device.
## Truth: roll, fold, plot, repeat — the shape is in the dice. A spinner picks
## the next affine map, a bright point bounces to it, and the attractor
## accumulates one batch at a time. You are watching randomness draw the same
## figure every run, because the figure lives in the maps, not in the order.

@export var max_points: int = 6000
@export var batch: int = 90
@export var add_interval: float = 0.3
@export var dot: float = 0.009

var _seeds: MultiMeshInstance3D
var _live: int = 0
var _accum: float = 0.0
var _px: float = 0.0
var _py: float = 0.0
var _spinner: Node3D
var _bouncer: MeshInstance3D
var _readout: Label3D
var _origin := Vector3(0.0, 1.02, 0.0)
var _scale_x: float = 0.0
var _scale_y: float = 0.0
var _last_map: int = 0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _field(n: int, box: bool = false) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = (BoxMesh.new() if box else SphereMesh.new())
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.22 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	# Compact device body (~1m).
	var body_mat := _matte_mat(Color(0.13, 0.14, 0.17), 0.8, 0.2)
	add_child(_box(Vector3(0.0, 0.4, 0.0), Vector3(1.0, 0.12, 0.7), body_mat))
	var post_mat := _steel_mat(Color(0.28, 0.3, 0.34))
	add_child(_cylinder(Vector3(0.0, 0.2, 0.0), 0.06, 0.4, post_mat))

	# Spinner: a small disk with 3 colored wedges marking the 3 maps.
	_spinner = Node3D.new()
	_spinner.position = Vector3(-0.35, 0.5, 0.2)
	add_child(_spinner)
	var hub := _steel_mat(Color(0.4, 0.42, 0.46))
	_spinner.add_child(_cylinder(Vector3.ZERO, 0.12, 0.03, hub))
	var wedge_cols: Array[Color] = [Color(1.0, 0.45, 0.35), Color(0.4, 0.7, 1.0), Color(1.0, 0.85, 0.35)]
	for w in range(3):
		var a: float = (float(w) / 3.0) * TAU
		var arm_mat := _glow_mat(wedge_cols[w], 2.0)
		_spinner.add_child(_box(Vector3(cos(a) * 0.07, 0.02, sin(a) * 0.07), Vector3(0.06, 0.02, 0.02), arm_mat))
	# Pointer needle (fixed) over the spinner.
	_spinner.add_child(_box(Vector3(0.0, 0.05, -0.13), Vector3(0.015, 0.015, 0.06), _glow_mat(Color.WHITE, 3.0)))

	# Bouncing point.
	_bouncer = _sphere(_origin, 0.03, _glow_mat(Color(1.0, 0.95, 0.5), 4.0))
	add_child(_bouncer)

	# Accumulating attractor (Sierpinski via chaos game).
	_scale_x = 0.42
	_scale_y = 0.42
	_seeds = _field(max_points)
	add_child(_seeds)
	_clear_field()
	_live = 0
	_px = 0.0
	_py = 0.4

	_readout = _billboard_label("THE CHAOS GAME\n0 points", Vector3(0.0, 1.05, 0.0), 22, Color(1.0, 0.95, 0.7))
	_readout.position = Vector3(0.0, 1.65, 0.0)
	add_child(_readout)


func _clear_field() -> void:
	var mm: MultiMesh = _seeds.multimesh
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), _origin))
		mm.set_instance_color(i, Color(0, 0, 0, 0))


# Three vertices of an upright triangle, in device-local XY above the body.
func _vertex(k: int) -> Vector2:
	match k:
		0:
			return Vector2(0.0, 0.55)
		1:
			return Vector2(-0.3, 0.0)
		_:
			return Vector2(0.3, 0.0)


func _vcolor(k: int) -> Color:
	match k:
		0:
			return Color(1.0, 0.45, 0.35)
		1:
			return Color(0.4, 0.7, 1.0)
		_:
			return Color(1.0, 0.85, 0.35)


func _add_batch() -> void:
	if _live >= max_points:
		return
	var mm: MultiMesh = _seeds.multimesh
	var n: int = mini(batch, max_points - _live)
	for _b in range(n):
		var k: int = _rng.randi() % 3
		_last_map = k
		var v: Vector2 = _vertex(k)
		_px = lerp(_px, v.x, 0.5)
		_py = lerp(_py, v.y, 0.5)
		var pos := _origin + Vector3(_px, _py, 0.0)
		mm.set_instance_transform(_live, Transform3D(Basis().scaled(Vector3(dot, dot, dot)), pos))
		mm.set_instance_color(_live, _vcolor(k))
		_live += 1
	# Park the bouncer at the most recent plotted point.
	_bouncer.position = _origin + Vector3(_px, _py, 0.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Spin the wheel; snap-ish to the last chosen map for legibility.
	if _spinner:
		_spinner.rotation.y += delta * 5.0
	_accum += delta
	if _accum >= add_interval:
		_accum = 0.0
		if _live >= max_points:
			# Settle: reset and redraw fresh, so the device keeps "playing".
			_clear_field()
			_live = 0
			_px = 0.0
			_py = 0.4
		_add_batch()
		if _readout:
			_readout.text = "THE CHAOS GAME\n%d points" % _live
