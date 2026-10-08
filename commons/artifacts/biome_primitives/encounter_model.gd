extends RefCounted
## Accumulating capabilities, one persistent specimen. No hidden mature biome.
## The ground is support; the black mark represents the visitor's projected position.
## Disabling memory preserves its archive. Clearing memory explicitly discards it.

const STAGES := ["Point_One", "Point_Lines", "Point_Trace", "Point_Line_Grid", "Point_Triangle_Context", "Primitives_Polythedra", "Trans_Rotation", "Trans_Scale"]
var form_dna: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/biome_primitives/pilot.json")).form_dna
var seed: int = 7
var extent: float = 12.0
var stage_index: int = 0
var withdrawn: bool = false
var point := Vector3(0, 0.05, 0)
var anchor := Vector3(0, 0.05, 0)
var line_started: bool = false
var interval: float = 0.12
var capacity: int = 64
var cell_size: float = 1.0
var clock: float = 0.0
var dropped: int = 0
var samples: Array[Dictionary] = []
var _elapsed: float = 0.0
var _new_stroke: bool = true
var hinge_time: float = 0.0
var hinge_angle: float = 0.0
var hinge_held: bool = false
var scale_time: float = 0.0
var width_factor: float = 0.6

## A prescribed motor study: two-second rests and eight-second eased turns.
## This is not a force or a spring simulation. Its clock is separate from memory.
func advance_hinge(delta: float, visitor: bool = false) -> void:
	if stage_index < 6 or withdrawn or not is_finite(delta) or delta <= 0: return
	hinge_held = visitor and in_hinge_sweep(point)
	if hinge_held: return
	if stage_index == 7:
		scale_time = fmod(scale_time + minf(delta, .1), 48.0)
		var pose := scale_pose_at(scale_time)
		hinge_time = float(pose.hinge_time)
		hinge_angle = float(pose.angle)
		width_factor = float(pose.factor)
		return
	hinge_time = fmod(hinge_time + minf(delta, .1), 20.0)
	hinge_angle = angle_at(hinge_time)

static func angle_at(seconds: float) -> float:
	var t := fposmod(seconds, 20.0)
	if t < 2: return 0.0
	if t < 10: return PI * .5 * smoothstep(0.0, 1.0, (t - 2) / 8)
	if t < 12: return PI * .5
	return PI * .5 * (1.0 - smoothstep(0.0, 1.0, (t - 12) / 8))

## Compare the SAME turn at two widths. Width changes only while yaw is zero.
static func scale_pose_at(seconds: float) -> Dictionary:
	var t := fposmod(seconds, 48.0)
	if t < 20: return {"angle": angle_at(t), "factor": .6, "hinge_time": t}
	if t < 24: return {"angle": 0.0, "factor": lerpf(.6, 1.25, smoothstep(0.0,1.0,(t-20)/4)), "hinge_time": 0.0}
	if t < 44: return {"angle": angle_at(t-24), "factor": 1.25, "hinge_time": t-24}
	return {"angle": 0.0, "factor": lerpf(1.25,.6,smoothstep(0.0,1.0,(t-44)/4)), "hinge_time": 0.0}

func active_width_factor() -> float:
	return width_factor if stage_index == 7 else 1.0

func in_hinge_sweep(at: Vector3) -> bool:
	if at.y > float(form_dna.height) + .4 or at.y < -.4: return false
	for form in forms():
		if not form.has("pivot"): continue
		var relative := at - _vec(form.pivot)
		# Conservative quarter-disc bounds plus the desktop body's clearance.
		# Holding the complete bank keeps the intervals legible and never restarts
		# at a new phase when the visitor steps out.
		var maximum_factor := 1.25 if stage_index == 7 else 1.0
		if relative.x >= -.4 and relative.z <= .4 and Vector2(relative.x, relative.z).length() <= float(form_dna.width) * maximum_factor + .4:
			return true
	return false

func level() -> int:
	return stage_index - int(withdrawn)

func set_stage(index: int) -> void:
	var before := level()
	stage_index = clampi(index, 0, STAGES.size() - 1)
	withdrawn = false
	_transition(before)

func toggle_capability() -> void:
	var before := level()
	withdrawn = not withdrawn
	_transition(before)

func _transition(before: int) -> void:
	if level() >= 1 and not line_started:
		anchor = point
		line_started = true
	if (before >= 2) != (level() >= 2):
		_new_stroke = true
		_elapsed = 0.0

func move_point(value: Vector3) -> void:
	if level() < 0 or not value.is_finite():
		return
	var edge := extent * 0.5 - 0.05
	point = Vector3(clampf(value.x, -edge, edge), clampf(value.y, 0.05, 5.0), clampf(value.z, -edge, edge))

func advance(delta: float, observed: bool = true) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	clock += delta
	if not observed:
		_new_stroke = true
		_elapsed = 0.0
		return
	if level() < 2:
		return
	_elapsed += delta
	if _elapsed + 0.000001 < interval:
		return
	# A slow frame knows only its current position. Do not invent intermediate samples.
	_elapsed = fmod(_elapsed, interval)
	if not samples.is_empty() and not _new_stroke:
		if point.distance_to(_vec(samples.back()["p"])) < 0.02:
			return
	samples.append({"p": _arr(point), "t": clock, "start": _new_stroke})
	_new_stroke = false
	while samples.size() > capacity:
		samples.pop_front()
		dropped += 1
	if dropped > 0 and not samples.is_empty():
		samples[0]["start"] = true

func clear_memory() -> void:
	samples.clear()
	dropped = 0
	_new_stroke = true
	_elapsed = 0.0

func address() -> Vector2i:
	var count := int(ceil(extent / cell_size))
	return Vector2i(clampi(int(floor((point.x + extent * 0.5) / cell_size)), 0, count - 1),
		clampi(int(floor((point.z + extent * 0.5) / cell_size)), 0, count - 1))

func snapshot() -> Dictionary:
	return {"schema": "ada.biome-primitives.v1", "world": {"seed": seed, "size": extent},
		"stage": STAGES[stage_index], "stage_index": stage_index, "withdrawn": withdrawn,
		"point": _arr(point), "anchor": _arr(anchor), "line_started": line_started,
		"interval": interval, "capacity": capacity, "cell_size": cell_size,
		"clock": clock, "elapsed": _elapsed, "new_stroke": _new_stroke,
		"samples": samples.duplicate(true), "dropped": dropped,
		"visible_samples": samples.size() if level() >= 2 else 0,
		"address": [address().x, address().y] if level() >= 3 else [], "forms": forms(),
		"hinge": {"time": hinge_time, "angle": hinge_angle, "held": hinge_held} if stage_index >= 6 else {},
		"scale": {"time": scale_time, "factor": width_factor} if stage_index == 7 else {}}

## A fixed specimen: same fronts and intervals; the next capability gives depth.
## Authored repetition anticipates the explicit array operation later in the spine.
func forms() -> Array:
	if level() < 4: return []
	var result: Array = []
	var width := float(form_dna.width)
	var height := float(form_dna.height)
	var gaps: Array = form_dna.gaps
	var total: float = width * (gaps.size() + 1)
	for gap in gaps: total += float(gap)
	var x := -total * 0.5 + width * 0.5
	# Rotation revisits the surface specimen. Withdrawing rotation freezes its
	# pose; it does not substitute the earlier solids or erase the motor clock.
	var depth := float(form_dna.depth) if level() >= 5 and stage_index < 6 else float(form_dna.panel_thickness)
	for i in range(gaps.size() + 1):
		var form := {"id": "form_%d" % i, "center": [x, height * 0.5, float(form_dna.front_z) - depth * 0.5],
			"size": [width, height, depth], "front_triangles": 2}
		if stage_index >= 6:
			var pivot := Vector3(x - width * .5, 0, float(form_dna.front_z))
			var actual_width := width * active_width_factor()
			form.size[0] = actual_width
			form.pivot = _arr(pivot)
			form.yaw = hinge_angle
			form.center = _arr(pivot + Basis(Vector3.UP, hinge_angle) * Vector3(actual_width*.5, height*.5, -depth*.5))
		result.append(form)
		if i < gaps.size(): x += width + float(gaps[i])
	return result

static func _arr(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

static func _vec(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
