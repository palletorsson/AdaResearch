extends RefCounted
## Private observation of one held-pen gesture. Never writes DrawDot or TraceData.
const LIMIT := 4096
const GRAINS := [0.005, 0.020, 0.080]
const GRIDS := [0.010, 0.040, 0.080]
var positions := PackedVector3Array()
var times := PackedFloat64Array()
var surfaces: Array[Dictionary] = []
var elapsed := 0.0
var revision := 0
var base_grain := 0.005
var capturing := false
var source_name := "Draw Dot"

func begin(at: Vector3, board: Dictionary, grain: float, title: String) -> void:
	positions = PackedVector3Array([at])
	times = PackedFloat64Array([0.0])
	surfaces = [board.duplicate()]
	elapsed = 0.0
	base_grain = grain
	source_name = title
	capturing = true
	revision += 1

func append(at: Vector3, delta: float, board: Dictionary) -> void:
	if not capturing or positions.size() >= LIMIT: return
	elapsed += delta
	positions.append(at)
	times.append(elapsed)
	surfaces.append(board.duplicate())
	revision += 1

func end() -> void:
	capturing = false
	revision += 1

func samples(until: float, mode: int, lane: int) -> PackedVector3Array:
	var kept := PackedVector3Array()
	if positions.size() < 2: return kept
	var grain: float = GRAINS[lane] if mode == 0 else base_grain
	var pitch: float = 0.0 if mode == 0 else GRIDS[lane]
	var anchor := positions[0]
	# Match DrawDot: distance from the previous accepted raw position, not arc
	# length or a fixed clock rate. Quantise after acceptance; omit duplicates.
	for i in range(1, positions.size()):
		if times[i] > until: break
		if positions[i].distance_to(anchor) < grain: continue
		anchor = positions[i]
		var point := shape_sample(anchor, pitch, surfaces[i])
		if kept.is_empty() or not kept[-1].is_equal_approx(point): kept.append(point)
	return kept

static func shape_sample(at: Vector3, pitch: float, board: Dictionary) -> Vector3:
	# Mirrors DrawDot's read-only world/board shaping, without changing its settings.
	if not board.is_empty():
		var o: Vector3 = board.origin
		var u_axis: Vector3 = board.u
		var v_axis: Vector3 = board.v
		var d := at - o
		var u := d.dot(u_axis)
		var v := d.dot(v_axis)
		if pitch > 0.0:
			u = snappedf(u, pitch)
			v = snappedf(v, pitch)
		return o + u_axis * clampf(u, -float(board.half_w), float(board.half_w)) + v_axis * clampf(v, -float(board.half_h), float(board.half_h)) + Vector3(board.normal) * 0.004
	return Vector3(snappedf(at.x, pitch), snappedf(at.y, pitch), snappedf(at.z, pitch)) if pitch > 0.0 else at
