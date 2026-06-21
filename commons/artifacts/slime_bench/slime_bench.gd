extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SlimeBench

## @identity
## name: Slime Bench
## tier: medium
## truth: agents that follow their own trail build a transport network
##
## A Physarum (slime mould) simulation on a bench. Hundreds of agents wander a
## grid, each sniffing the trail field at three points ahead — left, centre,
## right — and steering toward the strongest scent. They move, deposit a little
## trail, and the field diffuses and decays. Pre-run ~80 steps so the bench
## already shows the veins the colony has carved.

@export var grid_size: int = 64
@export var agent_count: int = 300
@export var prerun_steps: int = 80
@export var sense_dist: float = 3.0
@export var sense_angle: float = 0.6
@export var turn_speed: float = 0.5
@export var deposit: float = 0.22
@export var decay: float = 0.92
@export var low_color: Color = Color(0.08, 0.18, 0.22)
@export var high_color: Color = Color(0.4, 1.0, 0.7)

const BENCH_TOP: float = 0.85
const PLATE: float = 0.9
var _cell: float = 0.0

var _field_buf: PackedFloat32Array = PackedFloat32Array()
var _field_tmp: PackedFloat32Array = PackedFloat32Array()
var _agents: Array[Vector3] = []  # x, y, heading
var _field_mi: MultiMeshInstance3D
var _accum: float = 0.0


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


func _build() -> void:
	_cell = PLATE / float(grid_size)
	# housing — a bench with the simulation plate on top
	add_child(_box(Vector3(0.0, BENCH_TOP * 0.5, 0.0), Vector3(1.05, BENCH_TOP, 0.7), _matte_mat(Color(0.18, 0.2, 0.24))))
	add_child(_box(Vector3(0.0, BENCH_TOP + 0.01, 0.0), Vector3(PLATE + 0.05, 0.03, PLATE + 0.05), _matte_mat(Color(0.05, 0.07, 0.08))))
	add_child(_billboard_label("PHYSARUM", Vector3(0.0, 1.6, 0.0), 32, high_color))

	_init_sim()
	for _s in range(prerun_steps):
		_step_sim()
	_field_mi = _make_field()
	add_child(_field_mi)


func _init_sim() -> void:
	var n: int = grid_size * grid_size
	_field_buf = PackedFloat32Array()
	_field_buf.resize(n)
	_field_tmp = PackedFloat32Array()
	_field_tmp.resize(n)
	_agents.clear()
	var centre: float = float(grid_size) * 0.5
	for _i in range(agent_count):
		# start clustered in a ring near the middle
		var ang: float = _rng.randf() * TAU
		var rad: float = _rng.randf() * float(grid_size) * 0.2
		var x: float = centre + cos(ang) * rad
		var y: float = centre + sin(ang) * rad
		_agents.append(Vector3(x, y, _rng.randf() * TAU))


func _idx(gx: int, gy: int) -> int:
	return wrapi(gy, 0, grid_size) * grid_size + wrapi(gx, 0, grid_size)


func _sample(fx: float, fy: float) -> float:
	return _field_buf[_idx(int(floor(fx)), int(floor(fy)))]


func _step_sim() -> void:
	# 1. agents sense, turn, move, deposit
	for i in range(_agents.size()):
		var a: Vector3 = _agents[i]
		var head: float = a.z
		var fc: float = _sample(a.x + cos(head) * sense_dist, a.y + sin(head) * sense_dist)
		var fl: float = _sample(a.x + cos(head - sense_angle) * sense_dist, a.y + sin(head - sense_angle) * sense_dist)
		var fr: float = _sample(a.x + cos(head + sense_angle) * sense_dist, a.y + sin(head + sense_angle) * sense_dist)
		if fc >= fl and fc >= fr:
			pass
		elif fc < fl and fc < fr:
			head += (turn_speed if _rng.randf() < 0.5 else -turn_speed)
		elif fl > fr:
			head -= turn_speed
		else:
			head += turn_speed
		var nx: float = wrapf(a.x + cos(head), 0.0, float(grid_size))
		var ny: float = wrapf(a.y + sin(head), 0.0, float(grid_size))
		_agents[i] = Vector3(nx, ny, head)
		var di: int = _idx(int(floor(nx)), int(floor(ny)))
		_field_buf[di] = minf(_field_buf[di] + deposit, 1.0)
	# 2. diffuse (3x3 box blur) + decay into tmp, then swap
	for gy in range(grid_size):
		for gx in range(grid_size):
			var acc: float = 0.0
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					acc += _field_buf[_idx(gx + ox, gy + oy)]
			_field_tmp[gy * grid_size + gx] = (acc / 9.0) * decay
	var swap: PackedFloat32Array = _field_buf
	_field_buf = _field_tmp
	_field_tmp = swap


func _field(n: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.16 if emissive else 0.0
	mi.material_override = mat
	return mi


func _make_field() -> MultiMeshInstance3D:
	var n: int = grid_size * grid_size
	var mi := _field(n)
	var mm: MultiMesh = mi.multimesh
	var box := mm.mesh as BoxMesh
	box.size = Vector3(_cell * 0.95, 1.0, _cell * 0.95)
	_paint_field(mm)
	return mi


func _paint_field(mm: MultiMesh) -> void:
	var top: float = BENCH_TOP + 0.03
	var half: float = PLATE * 0.5
	for gy in range(grid_size):
		for gx in range(grid_size):
			var i: int = gy * grid_size + gx
			var v: float = clampf(_field_buf[i], 0.0, 1.0)
			var h: float = 0.004 + v * 0.07
			var px: float = -half + (float(gx) + 0.5) * _cell
			var pz: float = -half + (float(gy) + 0.5) * _cell
			var xf := Transform3D(Basis().scaled(Vector3(1.0, h, 1.0)), Vector3(px, top + h * 0.5, pz))
			mm.set_instance_transform(i, xf)
			mm.set_instance_color(i, low_color.lerp(high_color, v))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# keep the colony alive — advance and repaint at a calm cadence
	_accum += delta
	if _accum < 0.12:
		return
	_accum = 0.0
	_step_sim()
	if _field_mi != null:
		_paint_field(_field_mi.multimesh)
