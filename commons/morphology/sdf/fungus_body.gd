# fungus_body.gd
# Fungus recipe — body_type ≈ 3.0 in CritterDNA.
#
# Reads DNA genes:
#   scale            — cap + stem size
#   segments         — number of gill sectors under cap (3..12)
#   pattern_density  — 0..1, controls whether cap has warts (blotches)
#   symmetry         — warts count around cap if pattern_density > 0.3
#
# Composition:
#   stem (tapered capsule, straight up)
#   + cap (flattened ellipsoid at top)
#   + gills (thin ellipsoids under cap via SymmetryOp)
#   + warts (small ellipsoids on cap via SymmetryOp, conditional)

extends "res://commons/morphology/sdf/body_recipe.gd"


func _build_from_dna() -> void:
	var scale: float = float(dna.get("scale", 1.0))
	var gill_count: int = int(dna.get("segments", 8.0))
	var pattern_density: float = float(dna.get("pattern_density", 0.3))
	var wart_count: int = int(dna.get("symmetry", 5.0))

	gill_count = clampi(gill_count, 3, 16)
	wart_count = clampi(wart_count, 3, 10)

	var stem_height: float = 0.9 * scale
	var stem_radius: float = 0.14 * scale

	# Stem — slightly bulging base via two-capsule stack
	var stem_lower := _capsule_helper(
		Vector3.ZERO,
		Vector3(0, stem_height * 0.5, 0),
		stem_radius * 1.15
	)
	var stem_upper := _capsule_helper(
		Vector3(0, stem_height * 0.5, 0),
		Vector3(0, stem_height, 0),
		stem_radius * 0.85
	)
	_parts.append(stem_lower)
	_parts.append(stem_upper)

	# Cap — squashed ellipsoid atop the stem
	var cap_center: Vector3 = Vector3(0, stem_height + 0.08 * scale, 0)
	var cap_radius: float = 0.55 * scale
	var cap := make_ellipsoid(
		cap_center,
		Vector3(cap_radius, 0.32 * scale, cap_radius),
	)
	_parts.append(cap)

	# Gills — thin radial plates under cap
	var gill := make_ellipsoid(
		cap_center + Vector3(cap_radius * 0.5, -0.12 * scale, 0),
		Vector3(cap_radius * 0.55, 0.015 * scale, 0.025 * scale),
	)
	var gill_ring := make_symmetry(gill, gill_count, Vector3.UP, cap_center)
	_parts.append(gill_ring)

	# Warts — small bumps on cap top, only if pattern_density high enough
	if pattern_density > 0.3:
		var wart_r: float = 0.08 * scale * lerpf(0.6, 1.4, pattern_density)
		var wart := make_ellipsoid(
			cap_center + Vector3(cap_radius * 0.65, 0.18 * scale, 0),
			Vector3(wart_r, wart_r * 0.7, wart_r),
		)
		var wart_ring := make_symmetry(wart, wart_count, Vector3.UP, cap_center)
		_parts.append(wart_ring)
