# noise_displace_op.gd — Modulator. Shift each selected node by a 3D
# gradient-noise offset, keeping topology identical. Roots are usually
# preserved (opt in) so the graph stays anchored.
#
# Noise uses Godot's FastNoiseLite, seeded deterministically so the same
# config always produces the same wobble.
#
# Params:
#   amp           — max displacement magnitude (default 0.15)
#   freq          — noise frequency — higher = smaller wavelength (default 1.0)
#   seed          — noise seed (default 42)
#   preserve_root — if true, nodes at depth 0 are not moved (default true)
#   axis_mask     — Vector3-like [x,y,z] scale per axis (default [1,1,1])
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, selected: PackedInt32Array) -> void:
	var amp: float = float(params.get("amp", 0.15))
	var freq: float = float(params.get("freq", 1.0))
	var seed_val: int = int(params.get("seed", 42))
	var preserve_root: bool = bool(params.get("preserve_root", true))
	var axis_mask_arr = params.get("axis_mask", [1.0, 1.0, 1.0])
	var mask := Vector3(
		float(axis_mask_arr[0]) if axis_mask_arr.size() > 0 else 1.0,
		float(axis_mask_arr[1]) if axis_mask_arr.size() > 1 else 1.0,
		float(axis_mask_arr[2]) if axis_mask_arr.size() > 2 else 1.0,
	)

	# Three independent noises for X/Y/Z so the offset is a proper 3D vector
	var nx := FastNoiseLite.new()
	var ny := FastNoiseLite.new()
	var nz := FastNoiseLite.new()
	nx.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ny.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	nz.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	nx.seed = seed_val
	ny.seed = seed_val + 101
	nz.seed = seed_val + 211
	nx.frequency = freq
	ny.frequency = freq
	nz.frequency = freq

	for idx in selected:
		if idx >= g.nodes.size():
			continue
		if preserve_root and idx < g.node_depth.size() and g.node_depth[idx] == 0:
			continue
		var p: Vector3 = g.nodes[idx]
		var offset := Vector3(
			nx.get_noise_3d(p.x, p.y, p.z) * mask.x,
			ny.get_noise_3d(p.x, p.y, p.z) * mask.y,
			nz.get_noise_3d(p.x, p.y, p.z) * mask.z,
		) * amp
		g.nodes[idx] = p + offset
