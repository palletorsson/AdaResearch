class_name ShellFoldSolver
extends FoldSolver
## Concentric layers opening and closing. For nested shells,
## chambered creatures, matryoshka-type nesting.
##
## Uses segment.thickness as minimum radial spacing between layers:
## closed shells stack at thickness intervals, open shells spread apart.
## Uses segment.size to scale each layer's visual radius.

@export var layer_spacing_open: float = 0.15
@export var rotation_per_layer: float = 15.0

func compute_fold(
	fold_amount: float,
	fold_tension: float,
	segments: Array,
	_constraints: Array,
) -> Dictionary:
	var result: Dictionary = {}
	var count: int = segments.size()

	var cumulative_height: float = 0.0

	for i in count:
		var seg: FoldSegmentData = segments[i] as FoldSegmentData
		if not seg:
			continue

		var layer_t: float = float(i) / max(count - 1.0, 1.0)

		# Outer layers open first
		var layer_fold: float = clamp(fold_amount * (1.0 + layer_t * 0.5) - layer_t * 0.3, 0.0, 1.0)

		# Closed spacing = segment thickness (shells stack tight but never intersect)
		# Open spacing = layer_spacing_open
		var spacing: float = lerp(seg.thickness, layer_spacing_open, layer_fold)
		cumulative_height += spacing

		var rot_angle: float = layer_fold * rotation_per_layer * layer_t

		var transform := Transform3D.IDENTITY
		transform.origin = Vector3.UP * cumulative_height
		transform = transform.rotated(Vector3.UP, deg_to_rad(rot_angle))

		# Shell rattle from tension
		if fold_tension > 0.4:
			var rattle: float = sin(Time.get_ticks_msec() * 0.02 * (i + 1)) * fold_tension * 0.01
			transform.origin += Vector3(rattle, 0, rattle)

		result[seg.segment_name] = transform

	return result
