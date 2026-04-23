# sine_displace_op.gd — Rhythmic position modulator. Displaces nodes by
# sin(freq * t + phase) along a chosen axis, where t is depth or a world
# coordinate. Produces undulating branches, serpentine trunks, wave-forms.
#
# Classic use case: displace along X/Z as a function of Y — creates a
# serpentine curve that rises with the branch.
#
# Params:
#   amp          — max displacement (default 0.2)
#   freq         — cycles per unit (default 0.5)
#   phase        — phase offset 0..1 (default 0)
#   along_axis   — "depth" | "y" | "x" | "z" — what t is (default "y")
#   displace     — Vector3-like [x,y,z] direction to push (default [1,0,0])
#   preserve_root — don't move the root (default true)
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, selected: PackedInt32Array) -> void:
	var amp: float = float(params.get("amp", 0.2))
	var freq: float = float(params.get("freq", 0.5))
	var phase: float = float(params.get("phase", 0.0)) * TAU
	var axis: String = str(params.get("along_axis", "y"))
	var disp_arr = params.get("displace", [1.0, 0.0, 0.0])
	var disp := Vector3(
		float(disp_arr[0]) if disp_arr.size() > 0 else 1.0,
		float(disp_arr[1]) if disp_arr.size() > 1 else 0.0,
		float(disp_arr[2]) if disp_arr.size() > 2 else 0.0,
	)
	var preserve_root: bool = bool(params.get("preserve_root", true))

	for idx in selected:
		if idx >= g.nodes.size():
			continue
		if preserve_root and idx < g.node_depth.size() and g.node_depth[idx] == 0:
			continue
		var t: float = 0.0
		var p: Vector3 = g.nodes[idx]
		match axis:
			"depth":
				t = float(g.node_depth[idx]) if idx < g.node_depth.size() else 0.0
			"y": t = p.y
			"x": t = p.x
			"z": t = p.z
		var wave: float = sin(t * freq * TAU + phase)
		g.nodes[idx] = p + disp * (amp * wave)
