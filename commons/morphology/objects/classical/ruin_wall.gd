# ruin_wall.gd
# A broken wall fragment — the kind you see in Pompeii or Delphi. Base
# block intact, top jagged. Composed from three rectangular blocks at
# declining heights, plus optional small rubble fragments.
#
# DNA used:
#   length        — wall length along X (default 2.0m)
#   height        — peak height (default 1.4m)
#   thickness     — wall depth along Z (default 0.35m)
#   jaggedness    — 0..1, height variance across segments (default 0.7)
#   rubble_count  — extra small rock fragments at base (default 4)

extends "res://commons/morphology/sdf/body_recipe.gd"


func _build_from_dna() -> void:
	var length: float = float(dna.get("length", 2.0))
	var max_height: float = float(dna.get("height", 1.4))
	var thickness: float = float(dna.get("thickness", 0.35))
	var jaggedness: float = float(dna.get("jaggedness", 0.7))
	var rubble_count: int = int(dna.get("rubble_count", 4))

	var half_t: float = thickness * 0.5

	# Main wall as three staggered blocks — each a different height to
	# create a broken silhouette. Heights vary deterministically (no random
	# before seq 7 rule — this uses indices, not randf).
	var segments: int = 3
	var seg_length: float = length / float(segments)
	var heights: Array = [
		max_height * (1.0 - jaggedness * 0.1),   # tallest
		max_height * (1.0 - jaggedness * 0.55),  # medium
		max_height * (1.0 - jaggedness * 0.8),   # shortest
	]
	# Shuffle order by deterministic index so pattern isn't always same.
	heights = [heights[1], heights[0], heights[2]]

	for i in segments:
		var x_center: float = (float(i) - float(segments - 1) * 0.5) * seg_length
		var h: float = heights[i]
		var block := make_ellipsoid(
			Vector3(x_center, h * 0.5, 0),
			Vector3(seg_length * 0.5 * 0.96, h * 0.5, half_t),
		)
		_add_part(block, "wall_block")

	# RUBBLE — small fragments at the base, staggered along the wall front.
	# Positioned deterministically (indices, no random).
	if rubble_count > 0:
		for i in rubble_count:
			var t: float = (float(i) + 0.5) / float(rubble_count)
			var x: float = lerp(-length * 0.5 * 0.8, length * 0.5 * 0.8, t)
			# Alternate front/back by parity
			var z: float = (thickness * 0.6) if i % 2 == 0 else -(thickness * 0.6)
			# Varying sizes via modulo, still deterministic
			var size_mul: float = 0.8 + float(i % 3) * 0.2
			var chunk := make_ellipsoid(
				Vector3(x, 0.09 * size_mul, z),
				Vector3(0.12 * size_mul, 0.09 * size_mul, 0.11 * size_mul),
			)
			_add_part(chunk, "rubble")

	# BASE COURSE — a continuous low slab anchoring the wall, visible as
	# the foundation line in weathered ruins.
	var base := make_ellipsoid(
		Vector3(0, 0.06, 0),
		Vector3(length * 0.52, 0.06, half_t * 1.05),
	)
	_add_part(base, "base_course")
