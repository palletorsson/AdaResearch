# flower_body.gd
# Flower recipe — body_type ≈ 2.0 in CritterDNA.
#
# Reads DNA genes:
#   scale         — overall size multiplier
#   segments      — number of leaf pairs on stem (2..6)
#   symmetry      — petal count (3..8)
#   pattern_scale — petal length factor
#
# Composition:
#   stem (capsule)
#   + leaves (ellipsoids, N pairs along stem at golden-phyllotaxis angles)
#   + petals (ellipsoids via SymmetryOp at top of stem)
#   + blossom center (small ellipsoid)

extends "res://commons/morphology/sdf/body_recipe.gd"


func _build_from_dna() -> void:
	var scale: float = float(dna.get("scale", 1.0))
	var leaf_pairs: int = int(dna.get("segments", 3.0))
	var petal_count: int = int(dna.get("symmetry", 5.0))
	var petal_length_factor: float = float(dna.get("pattern_scale", 1.0))

	leaf_pairs = clampi(leaf_pairs, 1, 6)
	petal_count = clampi(petal_count, 3, 10)

	var stem_height: float = 1.5 * scale
	var stem_radius: float = 0.06 * scale

	# Stem
	var stem := _capsule_helper(Vector3.ZERO, Vector3(0, stem_height, 0), stem_radius)
	_add_part(stem, "stem")

	# Leaves — N pairs along stem, each pair on opposite sides, rotated by
	# golden-phyllotaxis angle between pairs
	var golden: float = PI * (3.0 - sqrt(5.0))  # ~137.5°
	for i in leaf_pairs:
		var y: float = stem_height * (0.2 + 0.55 * float(i) / float(leaf_pairs))
		var theta: float = float(i) * golden
		var leaf_len: float = 0.28 * scale
		for side in [1.0, -1.0]:
			var dir := Vector3(cos(theta) * side, -0.1, sin(theta) * side).normalized()
			var leaf_center := Vector3(0, y, 0) + dir * leaf_len * 0.5
			var leaf_basis := Basis.looking_at(-dir, Vector3.UP)
			var leaf := make_ellipsoid(
				leaf_center,
				Vector3(leaf_len * 0.35, 0.03 * scale, leaf_len),
				leaf_basis
			)
			_add_part(leaf, "leaf")

	# Blossom — at top of stem
	var blossom_center: Vector3 = Vector3(0, stem_height, 0)

	# Single petal template: a lopsided ellipsoid pointing outward.
	# Tilt around Z so outer tip lifts upward, giving the blossom a dome.
	var petal_len: float = 0.42 * scale * petal_length_factor
	var petal_offset: float = petal_len * 0.55
	var tilt_angle: float = deg_to_rad(28.0)  # petal rake — lifts outer tip
	var petal_basis := Basis(Vector3.FORWARD, -tilt_angle)
	# Offset the petal's position along its tilted axis so the base meets
	# the blossom center and the tip rises outward.
	var base_to_tip: Vector3 = petal_basis * Vector3(petal_offset, 0, 0)
	var one_petal := make_ellipsoid(
		blossom_center + base_to_tip,
		Vector3(petal_len * 0.55, 0.04 * scale, petal_len * 0.32),
		petal_basis
	)
	var petal_ring := make_symmetry(one_petal, petal_count, Vector3.UP, blossom_center)
	_add_part(petal_ring, "petal")

	# Blossom center — small bulb nestled between petals
	var center_bulb := make_ellipsoid(
		blossom_center + Vector3(0, 0.06 * scale, 0),
		Vector3(0.11 * scale, 0.09 * scale, 0.11 * scale),
	)
	_add_part(center_bulb, "stamen")
