extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DlaGrower

## @identity
## Diffusion-limited aggregation — APPLIED, a frost / lightning generator.
## Truth: frost is a record of arrivals. The device accretes a branching crystal
## one walker at a time — each random walk ends frozen against the growing tips,
## so the tips keep reaching outward and the branches keep their gaps. When the
## crystal fills, the chamber clears and grows a fresh, never-identical fern of
## ice. Same rule, new frost, every time.

@export var max_particles: int = 800
@export var batch: int = 6
@export var grow_interval: float = 0.3
@export var grid_n: int = 141
@export var cell: float = 0.006
@export var max_walk_steps: int = 5000

var _seeds: MultiMeshInstance3D
var _occ: PackedByteArray
var _placed: int = 0
var _max_r: int = 2
var _accum: float = 0.0
var _readout: Label3D
var _origin := Vector3(0.0, 1.04, 0.0)


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
	# Compact device body (~1m) with a glass chamber feel.
	var body_mat := _matte_mat(Color(0.1, 0.13, 0.18), 0.8, 0.2)
	add_child(_box(Vector3(0.0, 0.4, 0.0), Vector3(1.0, 0.12, 0.7), body_mat))
	var post_mat := _steel_mat(Color(0.3, 0.34, 0.4))
	add_child(_cylinder(Vector3(0.0, 0.2, 0.0), 0.06, 0.4, post_mat))
	# A faint ring marking the release rim.
	add_child(_torus(_origin, 0.4, 0.006, _glow_mat(Color(0.5, 0.75, 1.0), 1.5)))

	_seeds = _field(max_particles, true)
	add_child(_seeds)
	_reset_crystal()

	_readout = _billboard_label("FROST GENERATOR\n0 / %d" % max_particles, Vector3(0.0, 1.7, 0.0), 22, Color(0.7, 0.9, 1.0))
	add_child(_readout)


func _reset_crystal() -> void:
	var n: int = grid_n
	var c: int = n / 2
	_occ = PackedByteArray()
	_occ.resize(n * n)
	for q in range(_occ.size()):
		_occ[q] = 0
	_occ[c * n + c] = 1
	_placed = 0
	_max_r = 2
	var mm: MultiMesh = _seeds.multimesh
	for i in range(mm.instance_count):
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), _origin))
		mm.set_instance_color(i, Color(0, 0, 0, 0))
	# Seed crystal at centre.
	_place(mm, 0, c, c, 0.0)
	_placed = 1


func _grow_batch() -> void:
	var mm: MultiMesh = _seeds.multimesh
	var n: int = grid_n
	var c: int = n / 2
	var rim_limit: int = c - 2
	var added: int = 0
	var attempts: int = 0
	while added < batch and _placed < max_particles and attempts < batch * 6:
		attempts += 1
		var spawn_r: int = mini(_max_r + 5, rim_limit)
		var ang: float = _rng.randf() * TAU
		var wx: int = c + int(round(cos(ang) * float(spawn_r)))
		var wy: int = c + int(round(sin(ang) * float(spawn_r)))
		wx = clampi(wx, 1, n - 2)
		wy = clampi(wy, 1, n - 2)
		var stuck: bool = false
		for _step in range(max_walk_steps):
			if _adjacent(wx, wy, n):
				stuck = true
				break
			var d: int = _rng.randi() % 4
			match d:
				0:
					wx += 1
				1:
					wx -= 1
				2:
					wy += 1
				_:
					wy -= 1
			var dx: int = wx - c
			var dy: int = wy - c
			if dx * dx + dy * dy > (rim_limit + 6) * (rim_limit + 6):
				stuck = false
				break
			wx = clampi(wx, 1, n - 2)
			wy = clampi(wy, 1, n - 2)
		if stuck:
			_occ[wy * n + wx] = 1
			var t: float = float(_placed) / float(max_particles)
			_place(mm, _placed, wx, wy, t)
			_placed += 1
			added += 1
			var rdx: int = wx - c
			var rdy: int = wy - c
			var rr: int = int(round(sqrt(float(rdx * rdx + rdy * rdy))))
			if rr > _max_r:
				_max_r = rr


func _adjacent(x: int, y: int, n: int) -> bool:
	if _occ[y * n + x] == 1:
		return false
	if x + 1 < n and _occ[y * n + (x + 1)] == 1:
		return true
	if x - 1 >= 0 and _occ[y * n + (x - 1)] == 1:
		return true
	if y + 1 < n and _occ[(y + 1) * n + x] == 1:
		return true
	if y - 1 >= 0 and _occ[(y - 1) * n + x] == 1:
		return true
	return false


func _place(mm: MultiMesh, idx: int, gx: int, gy: int, t: float) -> void:
	var c: int = grid_n / 2
	var pos := _origin + Vector3(float(gx - c) * cell, 0.006, float(gy - c) * cell)
	var s: float = cell * 0.95
	mm.set_instance_transform(idx, Transform3D(Basis().scaled(Vector3(s, cell * 1.6, s)), pos))
	# Arrival-time colour: deep blue core -> bright white-blue tips.
	mm.set_instance_color(idx, Color(0.35, 0.6, 1.0).lerp(Color(0.95, 0.98, 1.0), t))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum >= grow_interval:
		_accum = 0.0
		if _placed >= max_particles:
			_reset_crystal()
		else:
			_grow_batch()
		if _readout:
			_readout.text = "FROST GENERATOR\n%d / %d" % [_placed, max_particles]
	if _seeds:
		_seeds.rotation.y = sin(Time.get_ticks_msec() * 0.0003) * 0.05
