extends RefCounted
## A bounded wet-load approximation. Only an overloaded patch starts a run;
## ordinary deposited pigment stays in the existing canvas feedback image.
const GRID := Vector2i(96, 60)
const MAX_RUNS := 24
const RUN_THRESHOLD := 12.0
var surface: MeshInstance3D
var wet_cells: Dictionary = {}
var runs: Array[Dictionary] = []
var runs_started := 0
var _down_uv := Vector2.ZERO

func configure(receiver: MeshInstance3D) -> void:
	surface = receiver

func reset() -> void:
	wet_cells.clear(); runs.clear(); runs_started = 0

func deposit(uv: Vector2, axis_x: Vector2, axis_y: Vector2, color: Color, opacity: float) -> void:
	var axes := Transform2D(axis_x, axis_y, uv)
	if absf(axes.determinant()) < 0.00000001: return
	var inverse := axes.affine_inverse()
	var extent := Vector2(absf(axis_x.x) + absf(axis_y.x), absf(axis_x.y) + absf(axis_y.y))
	var lo := Vector2i((uv - extent) * Vector2(GRID)).clamp(Vector2i.ZERO, GRID - Vector2i.ONE)
	var hi := Vector2i((uv + extent) * Vector2(GRID)).clamp(Vector2i.ZERO, GRID - Vector2i.ONE)
	var dose := -log(maxf(1.0 - opacity, 0.0001))
	var fullest := Vector2i(-1, -1)
	var most := RUN_THRESHOLD
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			var key := Vector2i(x, y)
			var at := (Vector2(key) + Vector2(0.5, 0.5)) / Vector2(GRID)
			var radius_sq := (inverse * at).length_squared()
			if radius_sq > 1.0: continue
			var wet: float = wet_cells.get(key, 0.0) + dose * exp(-7.0 * radius_sq)
			wet_cells[key] = minf(wet, RUN_THRESHOLD * 2.0)
			if wet > most: fullest = key; most = wet
	if fullest.x < 0 or runs.size() >= MAX_RUNS: return
	# Project gravity into the receiver, so rotated canvas coordinates still run down.
	_down_uv = surface.get_uv_from_world_pos(surface.global_position + Vector3.DOWN) - surface.get_uv_from_world_pos(surface.global_position)
	if _down_uv.length_squared() < 0.00001: return
	var start := (Vector2(fullest) + Vector2(0.5, 0.5)) / Vector2(GRID)
	for run in runs:
		if (run.start - start).length() < 0.024: return
	var life := 1.6 + fmod(runs_started * 0.37, 0.8)
	runs.append({"start": start, "pos": start, "color": color, "life": life, "total": life, "width": 2.3 + fmod(runs_started * 0.61, 1.8), "age": 0.0})
	runs_started += 1
	# Starting a run consumes the local reservoir instead of spawning endlessly.
	for key in wet_cells:
		if Vector2(key - fullest).length() < 2.5: wet_cells[key] *= 0.22

func advance(delta: float) -> void:
	var dt := minf(delta, 0.05)
	for key in wet_cells.keys():
		wet_cells[key] *= exp(-dt / 1.1)
		if wet_cells[key] < 0.01: wet_cells.erase(key)
	for index in range(runs.size() - 1, -1, -1):
		var run: Dictionary = runs[index]
		var before: Vector2 = run.pos
		var remaining: float = run.life / run.total
		run.pos += _down_uv * (0.025 + 0.12 * remaining) * dt
		run.life -= dt; run.age += dt
		var colour: Color = run.color
		colour.a = 0.46
		surface.brush_layer.add_run(before * Vector2(surface.texture_size), run.pos * Vector2(surface.texture_size), run.width, colour)
		if run.life <= 0.0 or run.pos.x < 0 or run.pos.x > 1 or run.pos.y < 0 or run.pos.y > 1: runs.remove_at(index)
