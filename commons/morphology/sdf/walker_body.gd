# walker_body.gd
# Walker / critter recipe — body_type ≈ 1.0 in CritterDNA.
#
# Reads DNA genes:
#   scale        — overall size multiplier
#   segments     — spine capsule count (3..8). Each segment is a belly lobe.
#   symmetry     — limb pairs (2..4). Standard walker = 2 (four legs).
#   pattern_scale — limb length factor (longer legs at higher values)
#
# Composition:
#   spine (capsule chain along +X, each segment slightly bulged)
#   + head (ellipsoid at front end)
#   + limbs (capsule legs, `symmetry` pairs, each pair straddling a spine node)
#   + tail (thin tapering capsule off back end)

extends "res://commons/morphology/sdf/body_recipe.gd"


func _build_from_dna() -> void:
	var scale: float = float(dna.get("scale", 1.0))
	var spine_segs: int = int(dna.get("segments", 4.0))
	var limb_pairs: int = int(dna.get("symmetry", 2.0))
	var limb_len_factor: float = float(dna.get("pattern_scale", 1.0))

	spine_segs = clampi(spine_segs, 2, 8)
	limb_pairs = clampi(limb_pairs, 1, 4)

	var seg_len: float = 0.35 * scale
	var body_radius: float = 0.16 * scale
	var spine_y: float = 0.45 * scale  # body clearance above ground

	# Spine — chain of capsules along +X. Taper slightly toward tail.
	var spine_nodes: Array = []  # each entry: Vector3 world pos
	for i in spine_segs + 1:
		var x: float = float(i) * seg_len - float(spine_segs) * seg_len * 0.5
		spine_nodes.append(Vector3(x, spine_y, 0))

	for i in spine_segs:
		# Bulge toward middle — midpoint segments slightly thicker
		var t_middle: float = 1.0 - absf(float(i) - float(spine_segs - 1) * 0.5) / (float(spine_segs - 1) * 0.5 + 0.001)
		var r: float = body_radius * lerp(0.85, 1.2, t_middle)
		var seg := _capsule_helper(spine_nodes[i], spine_nodes[i + 1], r)
		_parts.append(seg)

	# Head — ellipsoid at front (+X end), slightly larger, nose-forward
	var front: Vector3 = spine_nodes[-1]
	var head_center: Vector3 = front + Vector3(seg_len * 0.6, 0.02 * scale, 0)
	var head := make_ellipsoid(
		head_center,
		Vector3(0.28 * scale, 0.22 * scale, 0.24 * scale),
	)
	_parts.append(head)

	# Tail — narrow capsule off the back (-X end)
	var back: Vector3 = spine_nodes[0]
	var tail_end: Vector3 = back + Vector3(-seg_len * 1.2, -spine_y * 0.35, 0)
	var tail := _capsule_helper(back, tail_end, body_radius * 0.35)
	_parts.append(tail)

	# Limbs — `limb_pairs` pairs. Distribute along spine, straddling both sides.
	var limb_len: float = 0.52 * scale * limb_len_factor
	# A pair lives under its anchor spine node. Pick evenly-spaced nodes.
	for pair_i in limb_pairs:
		var t_anchor: float = float(pair_i + 1) / float(limb_pairs + 1)
		var anchor_idx_f: float = t_anchor * float(spine_segs)
		var anchor_idx: int = int(clampf(anchor_idx_f, 0.0, float(spine_segs)))
		var hip: Vector3 = spine_nodes[anchor_idx]
		# Single leg: drops from hip down-and-out; SymmetryOp mirrors it via
		# radial rotation around Y (for 2 pairs = 4 legs, count=2 mirrors
		# left/right pairs; we still use explicit left-right here because
		# walker limbs are bilateral, not radial).
		for side in [1.0, -1.0]:
			var foot: Vector3 = hip + Vector3(0, -spine_y - 0.05 * scale, side * limb_len * 0.6)
			var leg := _capsule_helper(hip, foot, body_radius * 0.55)
			_parts.append(leg)
