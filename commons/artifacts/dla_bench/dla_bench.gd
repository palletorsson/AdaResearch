extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DlaBench

## @identity
## Diffusion-limited aggregation — MEDIUM, frost on a bench.
## Truth: stick where you land. A walker stumbles in from the rim on a random
## walk; the instant it touches the cluster it freezes, and the next walker must
## find its own way past the arms already grown. No designer placed a single
## branch — the dendrite is the shadow of a thousand drunkards' walks, coloured
## here by the order in which they arrived.

@export var particle_count: int = 600
@export var grid_n: int = 121
@export var cell: float = 0.0055
@export var max_walk_steps: int = 4000

var _seeds: MultiMeshInstance3D
var _origin := Vector3(0.0, 0.97, 0.0)


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
	# Bench base.
	var base_mat := _matte_mat(Color(0.1, 0.12, 0.16), 0.85)
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.2, 0.7), base_mat))
	var pillar_mat := _steel_mat(Color(0.28, 0.3, 0.36))
	add_child(_cylinder(Vector3(0.0, 0.45, 0.0), 0.07, 0.9, pillar_mat))

	_seeds = _field(particle_count, true)
	add_child(_seeds)
	_grow_dla()

	add_child(_billboard_label("STICK WHERE YOU LAND", Vector3(0.0, 1.6, 0.0), 26, Color(0.7, 0.9, 1.0)))


func _grow_dla() -> void:
	var mm: MultiMesh = _seeds.multimesh
	var n: int = grid_n
	var c: int = n / 2
	# Occupancy grid.
	var occ: PackedByteArray = PackedByteArray()
	occ.resize(n * n)
	for q in range(occ.size()):
		occ[q] = 0
	occ[c * n + c] = 1

	var placed: int = 0
	# Seed crystal at centre.
	_place(mm, placed, c, c, n, 0.0)
	placed += 1

	var max_r: int = 2
	var rim_limit: int = c - 2
	var cold := Color(0.45, 0.7, 1.0)
	var warm := Color(0.9, 0.95, 1.0)

	while placed < particle_count:
		# Release a walker just outside the current cluster radius.
		var spawn_r: int = mini(max_r + 5, rim_limit)
		var ang: float = _rng.randf() * TAU
		var wx: int = c + int(round(cos(ang) * float(spawn_r)))
		var wy: int = c + int(round(sin(ang) * float(spawn_r)))
		wx = clampi(wx, 1, n - 2)
		wy = clampi(wy, 1, n - 2)
		var stuck: bool = false
		for _step in range(max_walk_steps):
			# 4-neighbour check for adjacency to cluster.
			if _adjacent(occ, wx, wy, n):
				stuck = true
				break
			# Random step.
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
			# If it wandered too far, kill and respawn (counts as no placement).
			var dx: int = wx - c
			var dy: int = wy - c
			if dx * dx + dy * dy > (rim_limit + 6) * (rim_limit + 6):
				stuck = false
				break
			wx = clampi(wx, 1, n - 2)
			wy = clampi(wy, 1, n - 2)
		if stuck:
			occ[wy * n + wx] = 1
			var t: float = float(placed) / float(particle_count)
			_place(mm, placed, wx, wy, n, t)
			# color by arrival time
			mm.set_instance_color(placed, cold.lerp(warm, t))
			placed += 1
			var rr: int = int(round(sqrt(float(dx_sq(wx, c) + dx_sq(wy, c)))))
			if rr > max_r:
				max_r = rr


func dx_sq(a: int, b: int) -> int:
	var d: int = a - b
	return d * d


func _adjacent(occ: PackedByteArray, x: int, y: int, n: int) -> bool:
	if occ[y * n + x] == 1:
		return false
	if x + 1 < n and occ[y * n + (x + 1)] == 1:
		return true
	if x - 1 >= 0 and occ[y * n + (x - 1)] == 1:
		return true
	if y + 1 < n and occ[(y + 1) * n + x] == 1:
		return true
	if y - 1 >= 0 and occ[(y - 1) * n + x] == 1:
		return true
	return false


func _place(mm: MultiMesh, idx: int, gx: int, gy: int, n: int, t: float) -> void:
	var c: int = n / 2
	var pos := _origin + Vector3(float(gx - c) * cell, 0.006, float(gy - c) * cell)
	var s: float = cell * 0.95
	mm.set_instance_transform(idx, Transform3D(Basis().scaled(Vector3(s, cell * 1.4, s)), pos))
	mm.set_instance_color(idx, Color(0.45, 0.7, 1.0).lerp(Color(0.9, 0.95, 1.0), t))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _seeds:
		_seeds.rotation.y = sin(Time.get_ticks_msec() * 0.0004) * 0.06
