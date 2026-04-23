# sine_radii_op.gd — Rhythmic modulator. Radius = base * (1 + amp *
# sin(freq * depth * TAU + phase)). Because the argument is node depth,
# the wave pulses along the branch path — produces bamboo segments,
# beaded stems, knuckle joints.
#
# Use along_axis="y" to pulse by height instead of depth (gives rings
# of thickness across any orientation).
#
# Params:
#   amp          — max relative variation (default 0.3)
#   freq         — cycles per unit (default 1.0; units = depth levels
#                  OR world meters depending on along_axis)
#   phase        — phase offset 0..1 (default 0)
#   along_axis   — "depth" (default) | "y" | "x" | "z"
#   floor        — minimum radius as fraction of original (default 0.3)
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, selected: PackedInt32Array) -> void:
	var amp: float = float(params.get("amp", 0.3))
	var freq: float = float(params.get("freq", 1.0))
	var phase: float = float(params.get("phase", 0.0)) * TAU
	var axis: String = str(params.get("along_axis", "depth"))
	var floor_frac: float = float(params.get("floor", 0.3))

	for idx in selected:
		if idx >= g.radii.size():
			continue
		var t: float = 0.0
		match axis:
			"depth":
				t = float(g.node_depth[idx]) if idx < g.node_depth.size() else 0.0
			"y":
				t = g.nodes[idx].y
			"x":
				t = g.nodes[idx].x
			"z":
				t = g.nodes[idx].z
		var wave: float = sin(t * freq * TAU + phase)
		var original: float = g.radii[idx]
		var mult: float = 1.0 + amp * wave
		g.radii[idx] = maxf(original * floor_frac, original * mult)
