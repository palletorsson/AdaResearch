class_name BoneFoldSolver
extends FoldSolver
## Hierarchical bone rotation solver. For shells, wings, limbs —
## anything with rigid segments connected by hinge-like joints.
##
## Uses segment.pivot_offset for hinge placement.
## Uses segment.size for future clearance validation.

var _last_segments: Array = []

func compute_fold(
	fold_amount: float,
	fold_tension: float,
	segments: Array,
	constraints: Array,
) -> Dictionary:
	_last_segments = segments
	var result: Dictionary = {}

	for seg_res in segments:
		var seg: FoldSegmentData = seg_res as FoldSegmentData
		if not seg:
			continue

		# Activation window: remap global fold_amount to this segment's local range.
		# Before activation_start → stays closed. After activation_end → stays open.
		# Between → interpolates its full angle range.
		var window: float = seg.activation_end - seg.activation_start
		var local_t: float
		if window > 0.001:
			local_t = clamp((fold_amount - seg.activation_start) / window, 0.0, 1.0)
		else:
			local_t = 1.0 if fold_amount >= seg.activation_start else 0.0

		var angle: float = lerp(seg.angle_closed, seg.angle_open, local_t)

		# Parent gating: still works as additional constraint on top of activation windows
		if seg.parent_segment != &"" and seg.parent_min_fold > 0.0:
			var parent_progress: float = _get_parent_progress(seg.parent_segment, segments, fold_amount)
			if parent_progress < seg.parent_min_fold:
				var gate: float = parent_progress / max(seg.parent_min_fold, 0.001)
				angle = lerp(seg.angle_closed, angle, clamp(gate, 0.0, 1.0))

		# Constraints
		for con_res in constraints:
			var con: FoldConstraintData = con_res as FoldConstraintData
			if not con or con.segment_name != seg.segment_name:
				continue
			angle = clamp(angle, con.min_angle, con.max_angle)
			if con.latch_angle >= 0.0 and abs(angle - con.latch_angle) < con.latch_threshold:
				angle = con.latch_angle

		# Tension tremor
		var tremor: float = 0.0
		if fold_tension > 0.3:
			tremor = sin(Time.get_ticks_msec() * 0.01 * seg.mass) * fold_tension * 2.0

		var t := Transform3D.IDENTITY
		t = t.rotated(seg.fold_axis.normalized(), deg_to_rad(angle + tremor))
		result[seg.segment_name] = t

	return result


func compute_secondary(delta: float, _activity: StringName) -> Dictionary:
	var result: Dictionary = {}
	var time_ms: float = Time.get_ticks_msec()
	# Gentle breathing: subtle rotation around X axis, different phase per segment
	var breath_amplitude: float = 0.008
	var breath_speed: float = 0.003
	for i in _last_segments.size():
		var seg: FoldSegmentData = _last_segments[i] as FoldSegmentData
		if not seg:
			continue
		var phase: float = float(i) * 1.3
		var breath: float = sin(time_ms * breath_speed + phase) * breath_amplitude / max(seg.mass, 0.1)
		var t := Transform3D.IDENTITY
		t = t.rotated(Vector3.RIGHT, breath)
		result[seg.segment_name] = t
	return result


func _get_parent_progress(parent_name: StringName, segments: Array, fold_amount: float) -> float:
	for seg_res in segments:
		var seg: FoldSegmentData = seg_res as FoldSegmentData
		if not seg or seg.segment_name != parent_name:
			continue
		var span: float = seg.angle_open - seg.angle_closed
		if abs(span) < 0.001:
			return 1.0
		var current: float = lerp(seg.angle_closed, seg.angle_open, fold_amount)
		return (current - seg.angle_closed) / span
	return 1.0
