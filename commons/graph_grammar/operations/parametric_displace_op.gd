# parametric_displace_op.gd — Modulator. Displace each selected node by
# a parametric curve sampled at t = depth (or any chosen coord). Opens
# commons/primitives/parametric/ as a library of displacement trajectories —
# helix, trefoil, lissajous, rose, butterfly, seashell spiral — so a straight
# branch can be bent into a knot or a spiral by a single line of DNA.
#
# All curves return a Vector3 per t. amp scales the curve, t_scale sets
# the wavelength (cycles per unit of t).
#
# Params:
#   curve       — "helix" | "trefoil" | "lissajous" | "rose" | "butterfly" | "sine"
#   t_source    — "depth" (default) | "y" | "x" | "z" | "radial"
#   t_scale     — multiply t before feeding to curve (default 1.0)
#   amp         — displacement magnitude (default 0.15)
#   preserve_root — don't move depth-0 nodes (default true)
#   axes        — Vector3-like [ax, ay, az] per-axis scale (default [1,1,1])
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, selected: PackedInt32Array) -> void:
	var curve: String = str(params.get("curve", "helix"))
	var t_source: String = str(params.get("t_source", "depth"))
	var t_scale: float = float(params.get("t_scale", 1.0))
	var amp: float = float(params.get("amp", 0.15))
	var preserve_root: bool = bool(params.get("preserve_root", true))
	var axes_arr = params.get("axes", [1.0, 1.0, 1.0])
	var axes := Vector3(
		float(axes_arr[0]) if axes_arr.size() > 0 else 1.0,
		float(axes_arr[1]) if axes_arr.size() > 1 else 1.0,
		float(axes_arr[2]) if axes_arr.size() > 2 else 1.0,
	)

	for idx in selected:
		if idx >= g.nodes.size():
			continue
		if preserve_root and idx < g.node_depth.size() and g.node_depth[idx] == 0:
			continue
		var p: Vector3 = g.nodes[idx]
		var t: float = 0.0
		match t_source:
			"depth":  t = float(g.node_depth[idx]) if idx < g.node_depth.size() else 0.0
			"y":      t = p.y
			"x":      t = p.x
			"z":      t = p.z
			"radial": t = Vector2(p.x, p.z).length()
		var offset: Vector3 = _sample(curve, t * t_scale) * amp
		offset.x *= axes.x
		offset.y *= axes.y
		offset.z *= axes.z
		g.nodes[idx] = p + offset


## Parametric curve library — each returns Vector3 per t.
## Curves are normalized to ~unit magnitude so amp maps directly to meters.
static func _sample(curve: String, t: float) -> Vector3:
	match curve:
		"helix":
			# Spring: cos on X, sin on Z (Y handled by t_source or stays)
			return Vector3(cos(t), 0.0, sin(t))
		"trefoil":
			# Classic trefoil knot, scaled to ~unit radius
			var x: float = (sin(t) + 2.0 * sin(2.0 * t)) / 3.0
			var y: float = (cos(t) - 2.0 * cos(2.0 * t)) / 3.0
			var z: float = -sin(3.0 * t)
			return Vector3(x, y, z)
		"figure_eight":
			# Figure-eight knot — winds 3 times around one axis, 4 around another
			var x2: float = (2.0 + cos(2.0 * t)) * cos(3.0 * t) / 3.0
			var y2: float = (2.0 + cos(2.0 * t)) * sin(3.0 * t) / 3.0
			var z2: float = sin(4.0 * t)
			return Vector3(x2, y2, z2)
		"torus_knot":
			# (p, q) = (2, 3) torus knot — classic pretzel
			var p: float = 2.0
			var q: float = 3.0
			var maj: float = 1.0
			var mnr: float = 0.4
			return Vector3(
				(maj + mnr * cos(q * t)) * cos(p * t),
				mnr * sin(q * t),
				(maj + mnr * cos(q * t)) * sin(p * t),
			) * 0.5
		"lissajous":
			# 3:4:5 frequency ratio — non-repeating interference pattern
			return Vector3(sin(3.0 * t), sin(4.0 * t + PI * 0.5), sin(5.0 * t))
		"rose":
			# 4-petal rose in XZ plane: r = cos(2 * theta)
			var theta: float = t
			var rr: float = cos(2.0 * theta)
			return Vector3(rr * cos(theta), 0.0, rr * sin(theta))
		"rose_5":
			# 5-petal rose — odd n gives n petals
			var tt: float = t
			var r5: float = cos(5.0 * tt)
			return Vector3(r5 * cos(tt), 0.0, r5 * sin(tt))
		"butterfly":
			# Fay's butterfly curve in XY
			var e_term: float = exp(cos(t)) - 2.0 * cos(4.0 * t) - pow(sin(t / 12.0), 5.0)
			return Vector3(sin(t) * e_term * 0.25, cos(t) * e_term * 0.25, 0.0)
		"sine":
			return Vector3(sin(t), 0.0, 0.0)
		"spiral":
			# Archimedean spiral in XZ — radius grows with t
			return Vector3(t * 0.1 * cos(t), 0.0, t * 0.1 * sin(t))
		"seashell":
			# Logarithmic seashell spiral: radius DECAYS with t (tighter spiral)
			# while winding. From commons/primitives/parametric/seashell.gd
			var tau_w: float = (1.0 - t / (TAU * 2.0))
			return Vector3(tau_w * cos(t), tau_w * 0.1 * sin(t), tau_w * sin(t))
		"wave_torus":
			# Major + minor radii with wave modulation — donut-ring displacement
			var maj2: float = 1.0
			var min2: float = 0.25
			var wave: float = cos(8.0 * t)  # 8-fold ring pattern
			return Vector3(
				(maj2 + min2 * wave) * cos(t),
				min2 * sin(t * 3.0),  # vertical ripple
				(maj2 + min2 * wave) * sin(t),
			) * 0.4
		"helicoid":
			# Minimal surface as a curve — radius increases with t, winding
			return Vector3(t * 0.2 * cos(t * 2.0), t * 0.1, t * 0.2 * sin(t * 2.0))
		"dini":
			# Dini-surface-inspired: tractrix profile + helical twist
			var tt2: float = t
			var a: float = 0.5
			var b: float = 0.15
			var tractrix: float = cos(tt2) + log(maxf(0.05, tan(abs(sin(tt2)) * 0.5 + 0.1)))
			return Vector3(
				a * cos(tt2 * 3.0) * sin(tt2),
				b * tt2 + a * tractrix * 0.1,
				a * sin(tt2 * 3.0) * sin(tt2),
			)
		"enneper":
			# Enneper-order-3 projection — cusped minimal-surface-like curve
			var r_e: float = 0.5
			return Vector3(
				r_e * cos(t) - (pow(r_e, 3.0) / 3.0) * cos(3.0 * t),
				r_e * sin(t) + (pow(r_e, 3.0) / 3.0) * sin(3.0 * t),
				pow(r_e, 2.0) * cos(2.0 * t),
			)
		"breather":
			# Breather-like pulse — amplitude modulated over period
			return Vector3(
				sin(t) * (1.0 + 0.4 * cos(t * 0.3)),
				0.0,
				cos(t) * (1.0 + 0.4 * cos(t * 0.3)),
			)
	return Vector3.ZERO
