# noise_radii_op.gd — Modulator. Multiply each selected node's radius by
# (1 + amp * noise(pos * freq)). Creates knotty/gnarled trunks, thick-and-
# thin vines, organic variation of thickness along a branch.
#
# Params:
#   amp    — max relative deviation (0.3 = ±30%) (default 0.3)
#   freq   — noise frequency (default 2.0)
#   seed   — (default 42)
#   floor  — minimum radius as fraction of original (default 0.3)
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, selected: PackedInt32Array) -> void:
	var amp: float = float(params.get("amp", 0.3))
	var freq: float = float(params.get("freq", 2.0))
	var seed_val: int = int(params.get("seed", 42))
	var floor_frac: float = float(params.get("floor", 0.3))

	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = seed_val
	n.frequency = freq

	for idx in selected:
		if idx >= g.radii.size():
			continue
		var p: Vector3 = g.nodes[idx]
		var sample: float = n.get_noise_3d(p.x, p.y, p.z)  # -1..1
		var mult: float = 1.0 + amp * sample
		var original: float = g.radii[idx]
		var new_r: float = maxf(original * floor_frac, original * mult)
		g.radii[idx] = new_r
