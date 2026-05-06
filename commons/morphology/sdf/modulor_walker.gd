# modulor_walker.gd
# A walker body where every length comes from the Modulor ladder. Instead
# of abstract `scale * 0.35` coefficients, each part is declared at a
# specific ladder level. The same recipe at different levels is
# self-similar geometry — a level-3 walker and a level-6 walker differ
# only in φⁿ scale; their topology is identical.
#
# DNA used:
#   scale         — overall multiplier on Modulor lengths (tweak size)
#   segments      — spine segment count (2..6)
#   symmetry      — limb pairs (default 2 = four-legged)
#   ladder_offset — shift the whole body down the ladder (0 = human, 3 = hand-sized)

extends "res://commons/morphology/sdf/body_recipe.gd"

const ModulorScale = preload("res://commons/morphology/sdf/modulor_scale.gd")
const FoldChain = preload("res://commons/morphology/sdf/fold_chain.gd")


func _build_from_dna() -> void:
	var scale: float = float(dna.get("scale", 1.0))
	var spine_segs: int = int(dna.get("segments", 4.0))
	var limb_pairs: int = int(dna.get("symmetry", 2.0))
	var ladder_offset: int = int(dna.get("ladder_offset", 0))

	spine_segs = clampi(spine_segs, 2, 6)
	limb_pairs = clampi(limb_pairs, 1, 4)

	# Torso length from Modulor — default body is "torso" level (rung 1)
	var torso_len: float = ModulorScale.red(1 + ladder_offset) * scale
	var torso_r: float = ModulorScale.link_radius(torso_len, 0.1)

	# Leg length from Modulor — "limb" level (rung 2) down from torso
	var leg_len: float = ModulorScale.red(2 + ladder_offset) * scale

	# Clearance above ground — derived from leg length, not a magic number
	var spine_y: float = leg_len * 0.85

	# Spine — chain of capsules along +X
	var seg_len: float = torso_len / float(spine_segs)
	var spine_nodes: Array = []
	for i in spine_segs + 1:
		var x: float = float(i) * seg_len - torso_len * 0.5
		spine_nodes.append(Vector3(x, spine_y, 0))

	for i in spine_segs:
		# Slight bulge toward middle
		var t_middle: float = 1.0 - absf(float(i) - float(spine_segs - 1) * 0.5) / (float(spine_segs - 1) * 0.5 + 0.001)
		var r: float = torso_r * lerp(0.85, 1.2, t_middle)
		_parts.append(_capsule_helper(spine_nodes[i], spine_nodes[i + 1], r))

	# Head — ellipsoid sized one rung DOWN from torso (φ⁻¹ smaller)
	var head_size: float = ModulorScale.red(2 + ladder_offset) * scale * 0.45
	var front: Vector3 = spine_nodes[-1]
	var head_center: Vector3 = front + Vector3(seg_len * 0.7, head_size * 0.1, 0)
	var head := make_ellipsoid(
		head_center,
		Vector3(head_size, head_size * 0.85, head_size * 0.9),
	)
	_parts.append(head)

	# Tail — one rung DOWN from leg, thin
	var tail_len: float = ModulorScale.red(3 + ladder_offset) * scale
	var tail_end: Vector3 = spine_nodes[0] + Vector3(-tail_len, -spine_y * 0.3, 0)
	_parts.append(_capsule_helper(spine_nodes[0], tail_end, torso_r * 0.35))

	# Legs — FoldChain each, straddling spine nodes
	for pair_i in limb_pairs:
		var t_anchor: float = float(pair_i + 1) / float(limb_pairs + 1)
		var anchor_idx: int = clampi(int(t_anchor * float(spine_segs)), 0, spine_segs)
		var hip: Vector3 = spine_nodes[anchor_idx]
		for side in [1.0, -1.0]:
			var hip_out: Vector3 = hip + Vector3(0, 0, side * torso_r * 0.8)
			var leg_chain: Resource = FoldChain.leg(hip_out, side)
			# Scale the chain by dna.scale + ladder_offset by overriding radius_ratio
			# (length auto-scales via ladder_level in segments — but they're fixed
			# to anchor-level. For ladder_offset we need to rewrite segment levels.)
			if ladder_offset != 0 or scale != 1.0:
				leg_chain.segments = [
					{ladder_level = 2 + ladder_offset, angle_degrees =  0.0, axis = Vector3.FORWARD},
					{ladder_level = 3 + ladder_offset, angle_degrees = 12.0, axis = Vector3.FORWARD},
					{ladder_level = 4 + ladder_offset, angle_degrees = 80.0, axis = Vector3.FORWARD},
				]
			leg_chain.build()
			_parts.append(leg_chain)
