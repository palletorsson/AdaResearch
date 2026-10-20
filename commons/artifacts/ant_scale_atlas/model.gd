extends RefCounted
## Original trail/turmite engines stay off tree; V2 runs in one private physics world.
## All displays read the selected state without duplicating simulation rules.
const Trail = preload("res://commons/artifacts/stigmergy_grid/stigmergy_grid.gd")
const Turmite = preload("res://commons/artifacts/langton_swarm/langton_swarm.gd")
var trail = Trail.new()
var turmite = Turmite.new()
var mode := 0
var v2: Node
var playing := true:
	set(value):
		playing = value
		if is_instance_valid(v2): v2.set_running(playing and mode == 2)
var steps := [0, 0, 0]
var accum := 0.0
const SEED := 7411

func _init() -> void:
	trail._rng = RandomNumberGenerator.new()
	reset(0)
	reset(1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		trail.free()
		turmite.free()

func reset(which: int) -> void:
	if which == 0:
		trail._rng.seed = hash("stigmergy")
		trail._init_grid()
		trail._init_ants()
		steps[0] = 0
	elif which == 1:
		turmite._rng.seed = SEED
		turmite._reset_state()
		# The existing easel also begins after 900 steps. Keep this visible.
		for i in range(turmite.prerun_steps): turmite._step_swarm()
		steps[1] = turmite.prerun_steps
	elif is_instance_valid(v2):
		v2.restart()
		steps[2] = 0
	accum = 0.0

func select(which: int) -> void:
	mode = clampi(which, 0, 2)
	if is_instance_valid(v2): v2.set_running(playing and mode == 2)
	accum = 0.0

func advance(delta: float) -> bool:
	if not playing: return false
	if mode == 2:
		if not is_instance_valid(v2): return false
		var changed: bool = steps[2] != v2.ticks
		steps[2] = v2.ticks
		return changed
	accum += delta
	var interval: float = trail.UPDATE_INTERVAL if mode == 0 else turmite.step_interval
	# Bounded fixed steps; retain remainder, never accelerate either engine.
	var changed := false
	var batches := 0
	while accum >= interval and batches < 4:
		accum -= interval
		batch()
		changed = true
		batches += 1
	return changed

func batch() -> void:
	if mode == 0:
		trail._step_ants()
		trail._evaporate_and_diffuse()
		steps[0] += 1
	elif mode == 1:
		# Original easel advances five swarm steps every 0.10 seconds.
		for i in range(5): turmite._step_swarm()
		steps[1] += 5

func size() -> int:
	if mode == 2: return v2.colony.grid_resolution
	return trail.grid_size if mode == 0 else turmite.grid

func count() -> int:
	if mode == 2: return v2.ants.size()
	return trail.num_ants if mode == 0 else turmite._ants.size()

func position_of(i: int) -> Vector2:
	if mode == 2:
		var p: Vector3 = v2.ants[i].position
		return Vector2(p.x, p.z) / v2.colony.terrain_size
	if mode == 0:
		return Vector2(trail._ant_x[i], trail._ant_y[i]) / trail.grid_size - Vector2.ONE * .5
	var ant: Dictionary = turmite._ants[i]
	return (Vector2(ant.x, ant.y) + Vector2.ONE * .5) / turmite.grid - Vector2.ONE * .5

func yaw_of(i: int) -> float:
	if mode == 2: return v2.ants[i].rotation.y + PI
	if mode == 0: return PI / 2.0 - trail._ant_angle[i]
	return float(turmite._ants[i].dir) * PI / 2.0

func digest() -> String:
	return var_to_str([trail._pheromone, trail._ant_x, trail._ant_y, trail._ant_angle,
		turmite._state, turmite._ants, steps, v2.digest() if is_instance_valid(v2) else ""]).sha256_text()
