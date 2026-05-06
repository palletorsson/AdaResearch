class_name ChainFoldSolver
extends FoldSolver
## Segments along a compressible curve. For accordion bodies, tails,
## telescoping necks — anything that extends and contracts.
##
## Uses segment.thickness to enforce minimum compressed length:
## the chain can never be shorter than the sum of all segment thicknesses.

@export var curve_length_open: float = 3.0
@export var curvature_folded: float = 0.8
@export var curvature_open: float = 0.1

func compute_fold(
	fold_amount: float,
	fold_tension: float,
	segments: Array,
	_constraints: Array,
) -> Dictionary:
	var result: Dictionary = {}
	var count: int = segments.size()
	if count == 0:
		return result

	# Minimum length = sum of segment thicknesses (can't compress past solid matter)
	var min_length: float = 0.0
	for seg_res in segments:
		var seg: FoldSegmentData = seg_res as FoldSegmentData
		if seg:
			min_length += seg.thickness

	# Folded length is at least the stacked thickness
	var curve_length_folded: float = max(min_length, 0.01)
	var length: float = lerp(curve_length_folded, curve_length_open, fold_amount)
	var curvature: float = lerp(curvature_folded, curvature_open, fold_amount)

	# Track cumulative offset so thick segments push neighbors apart
	var cumulative_z: float = 0.0

	for i in count:
		var seg: FoldSegmentData = segments[i] as FoldSegmentData
		if not seg:
			continue

		var t: float = float(i) / max(count - 1.0, 1.0)

		# Position: distribute along curve, respecting thickness
		var target_z: float = t * length
		# Ensure this segment starts after previous segment's thickness
		cumulative_z = max(cumulative_z, target_z)
		var z: float = cumulative_z
		cumulative_z += seg.thickness

		var y: float = curvature * sin(PI * t) * length * 0.15

		# Tension zigzag
		var x: float = 0.0
		if fold_tension > 0.2:
			x = sin(t * PI * 4.0 + Time.get_ticks_msec() * 0.005) * fold_tension * 0.05

		var transform := Transform3D.IDENTITY
		transform.origin = Vector3(x, y, z)
		result[seg.segment_name] = transform

	return result
