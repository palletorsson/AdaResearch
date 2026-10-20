extends RefCounted
enum Objective { CENTER, EDGE, RIDGE }
const LIMIT := 6.0
const MAX_STEP := 0.35
var inertia := 0.6
var personal_pull := 1.5
var social_pull := 0.0
var objective := Objective.CENTER
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var best_positions: Array[Vector2] = []
var best_scores: Array[float] = []
var shared_position := Vector2.ZERO
var shared_score := -INF
var steps := 0
var random := RandomNumberGenerator.new()

func _init() -> void:
	reset()

func score(p: Vector2) -> float:
	if objective == Objective.EDGE: return p.length_squared()
	if objective == Objective.RIDGE: return -pow(p.x-p.y,2.0)/2.0
	return -p.length_squared()

func reset() -> void:
	random.seed = 101006
	positions.clear()
	velocities.clear()
	for i in range(24):
		positions.append(Vector2(random.randf_range(-5.5,5.5),random.randf_range(-5.5,5.5)))
		velocities.append(Vector2(random.randf_range(-0.15,0.15),random.randf_range(-0.15,0.15)))
	steps = 0
	reset_memories()

func reset_memories() -> void:
	best_positions = positions.duplicate()
	best_scores.clear()
	for p in positions: best_scores.append(score(p))
	update_shared()

func update_shared() -> void:
	shared_score = -INF
	for i in range(best_scores.size()):
		if best_scores[i] > shared_score:
			shared_score = best_scores[i]
			shared_position = best_positions[i]

func change_objective(next: int) -> void:
	objective = clampi(next,Objective.CENTER,Objective.RIDGE)
	reset_memories()

func remember() -> void:
	for i in range(positions.size()):
		var value := score(positions[i])
		if value > best_scores[i]:
			best_scores[i] = value
			best_positions[i] = positions[i]
	update_shared()

func terms(i: int, r1: float, r2: float, shared: Vector2) -> Array[Vector2]:
	return [inertia*velocities[i],
		personal_pull*r1*(best_positions[i]-positions[i]),
		social_pull*r2*(shared-positions[i])]

func step() -> void:
	# Include a hand-placed candidate before this iteration starts.
	remember()
	var shared := shared_position
	var next_positions: Array[Vector2] = []
	var next_velocities: Array[Vector2] = []
	for i in range(positions.size()):
		var parts := terms(i,random.randf(),random.randf(),shared)
		var v := (parts[0]+parts[1]+parts[2]).limit_length(MAX_STEP)
		var p := positions[i]+v
		# A bounded search square: stop outward motion at its edge.
		if absf(p.x) > LIMIT:
			p.x = clampf(p.x,-LIMIT,LIMIT)
			v.x = 0.0
		if absf(p.y) > LIMIT:
			p.y = clampf(p.y,-LIMIT,LIMIT)
			v.y = 0.0
		next_positions.append(p)
		next_velocities.append(v)
	positions = next_positions
	velocities = next_velocities
	remember()
	steps += 1
