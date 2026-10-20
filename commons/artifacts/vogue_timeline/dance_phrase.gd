extends RefCounted
## A measurable hand phrase, not a model of voguing or a probability of skill.
## Coordinates: metres relative to head, in the calibrated upright facing frame,
## divided by chosen reach. No inferred elbows, hips or feet enter recognition.
const LENGTH := 32.0
const CUE_BEATS := 2.0
const SECTION_BEATS := 8.0
const HOLD_BEATS := 0.24
const SECTIONS := ["FRAME", "SWEEP", "WEAVE", "RETURN"]
const NAMES := ["FRAME", "LIFT", "HALO", "FAN", "OPEN", "SCOOP", "OFFER", "RISE", "DIAGONAL", "RIBBON", "WEAVE", "UNFOLD", "CROWN", "ARC", "GATHER", "RETURN"]
const LEFT := [
	Vector3(-0.38, 0.08, -0.48), Vector3(-0.58, 0.50, -0.42),
	Vector3(-0.24, 0.68, -0.50), Vector3(-0.78, 0.30, -0.30),
	Vector3(-0.90, -0.18, -0.30), Vector3(-0.60, -0.68, -0.56),
	Vector3(-0.27, -0.28, -0.88), Vector3(-0.50, 0.40, -0.62),
	Vector3(-0.72, 0.50, -0.32), Vector3(-0.78, -0.16, -0.66),
	Vector3(0.18, -0.40, -0.72), Vector3(-0.26, 0.46, -0.72),
	Vector3(-0.48, 0.58, -0.40), Vector3(-0.84, 0.12, -0.44),
	Vector3(-0.42, -0.58, -0.58), Vector3(-0.24, -0.15, -0.75)]
const RIGHT := [
	Vector3(0.38, 0.08, -0.48), Vector3(0.58, 0.50, -0.42),
	Vector3(0.24, 0.68, -0.70), Vector3(0.78, 0.30, -0.30),
	Vector3(0.90, -0.18, -0.30), Vector3(0.60, -0.68, -0.56),
	Vector3(0.27, -0.28, -0.88), Vector3(0.50, 0.40, -0.62),
	Vector3(0.62, -0.48, -0.60), Vector3(0.22, 0.50, -0.66),
	Vector3(-0.22, 0.25, -0.42), Vector3(0.75, -0.12, -0.48),
	Vector3(0.48, 0.58, -0.40), Vector3(0.84, 0.12, -0.44),
	Vector3(0.42, -0.58, -0.58), Vector3(0.24, -0.15, -0.75)]
var bpm := 112.0
var tolerance := 0.32
var beat := -4.0
var hits := 0
var flow_sum := 0.0
var flow_time := 0.0
var dwell := 0.0
var window_id := -999
var hit_id := -999
var error := INF
var hand_errors: Array[float] = [INF, INF]
var recording := false
var use_recorded := false
var recorded: Array = []
var pending: Array = []
var sample_clock := 0.0
var just_hit := false
var just_recorded := false

static func feature(head: Vector3, hand: Vector3, facing: Basis, reach: float) -> Vector3:
	return facing.inverse() * (hand - head) / maxf(reach, 0.1)

func reset() -> void:
	beat = -4.0
	hits = 0
	flow_sum = 0.0
	flow_time = 0.0
	dwell = 0.0
	window_id = -999
	hit_id = -999
	error = INF
	hand_errors.fill(INF)
	just_hit = false

func start_recording() -> void:
	reset()
	pending.clear()
	sample_clock = 0.0
	recording = true
	use_recorded = false

func cancel_recording() -> void:
	recording = false
	pending.clear()

func cue_name(at: float) -> String:
	return "YOURS" if use_recorded else NAMES[int(round(at / CUE_BEATS)) % NAMES.size()]

func section_name(at: float) -> String:
	return "YOUR PHRASE" if use_recorded else SECTIONS[int(fposmod(at, LENGTH) / SECTION_BEATS)]

static func _curve(points: Array, slot: int, elapsed: float) -> Vector3:
	var next := (slot + 1) % points.size()
	var previous := posmod(slot - 1, points.size())
	var after := (slot + 2) % points.size()
	# Only the four section anchors pause. Other poses carry velocity through
	# the beat, with shared tangents rather than sixteen stop/start line segments.
	var start_hold := HOLD_BEATS if slot % 4 == 0 else 0.0
	var end_hold := HOLD_BEATS if next % 4 == 0 else 0.0
	var travel := CUE_BEATS - start_hold - end_hold
	var t := clampf((elapsed - start_hold) / travel, 0.0, 1.0)
	var m0: Vector3 = Vector3.ZERO if slot % 4 == 0 else (points[next] - points[previous]) * travel / (2.0 * CUE_BEATS)
	var m1: Vector3 = Vector3.ZERO if next % 4 == 0 else (points[after] - points[slot]) * travel / (2.0 * CUE_BEATS)
	var t2 := t * t
	var t3 := t2 * t
	return points[slot] * (2.0*t3 - 3.0*t2 + 1.0) + m0 * (t3 - 2.0*t2 + t) + points[next] * (-2.0*t3 + 3.0*t2) + m1 * (t3 - t2)

func target(at: float) -> Array:
	var phase := fposmod(at, LENGTH)
	if use_recorded and recorded.size() > 1:
		# Longer recordings are sampled by the preview every frame. Binary search
		# keeps lookup small without altering the measured movement.
		var low := 0
		var high := recorded.size()
		while low < high:
			var mid := (low + high) / 2
			if float(recorded[mid].beat) <= phase: low = mid + 1
			else: high = mid
		if low > 0 and low < recorded.size():
			var a: Dictionary = recorded[low - 1]
			var b: Dictionary = recorded[low]
			var mix := inverse_lerp(float(a.beat), float(b.beat), phase)
			return [a.left.lerp(b.left, mix), a.right.lerp(b.right, mix)]
		# Loop seam connects the last measured sample to the first.
		var last: Dictionary = recorded[-1]
		var first: Dictionary = recorded[0]
		var wrapped := phase if phase >= float(last.beat) else phase + LENGTH
		var t := inverse_lerp(float(last.beat), float(first.beat) + LENGTH, wrapped)
		return [last.left.lerp(first.left, t), last.right.lerp(first.right, t)]
	var slot := int(floor(phase / CUE_BEATS))
	var elapsed := fposmod(phase, CUE_BEATS)
	return [_curve(LEFT, slot, elapsed), _curve(RIGHT, slot, elapsed)]

func advance(seconds: float, left: Vector3, right: Vector3, valid: bool) -> void:
	just_hit = false
	just_recorded = false
	hand_errors.fill(INF)
	if not valid or not left.is_finite() or not right.is_finite():
		dwell = 0.0
		error = INF
		return # Lost tracking pauses the phrase; stale coordinates never earn hits.
	var dt := clampf(seconds, 0.0, 0.1)
	beat += dt * bpm / 60.0
	if beat < 0.0:
		return
	if recording:
		sample_clock -= dt
		if sample_clock <= 0.0 and beat < LENGTH:
			pending.append({"beat":beat,"left":left,"right":right})
			sample_clock += 0.05
		if beat >= LENGTH:
			recording = false
			if pending.size() >= 40:
				recorded = pending.duplicate(true)
				use_recorded = true
				just_recorded = true
			pending.clear()
			reset()
		return
	var goal := target(beat)
	hand_errors[0] = left.distance_to(goal[0])
	hand_errors[1] = right.distance_to(goal[1])
	error = sqrt((hand_errors[0]*hand_errors[0] + hand_errors[1]*hand_errors[1]) / 2.0)
	flow_sum += clampf(1.0 - error / (tolerance * 2.0), 0.0, 1.0) * dt
	flow_time += dt
	var cue := int(round(beat / CUE_BEATS))
	if cue != window_id:
		window_id = cue
		dwell = 0.0
	# A good left hand cannot compensate for a right hand outside its target.
	# The continuous flow measure above still uses RMS distance.
	if absf(beat - float(cue) * CUE_BEATS) <= 0.35 and hand_errors[0] <= tolerance and hand_errors[1] <= tolerance:
		dwell += dt
		if dwell >= 0.12 and hit_id != cue:
			hit_id = cue
			hits += 1
			just_hit = true
	else:
		dwell = 0.0
