extends RefCounted
## THE WALL FIT — the museum's half of one shared rule set.
##
## Palle, 2026-08-20: "we need to find out how we can place things at the walls
## in the right way — does it fit the wall, can we scale to fit, does it need a
## shelf, and some nice distance to the wall?"
##
## The rules live in commons/data/wall_fit_rules.json, consulted by BOTH sides:
## tools/spatial_negotiation.wall_fit_decide (the plan) and this file (the
## museum, and res://commons/scenes/wall_fit_reference.tscn where a nudge IS the
## new convention — the prop_reference_wall principle, applied to artifacts).

const RULES_PATH := "res://commons/data/wall_fit_rules.json"
static var _cache: Dictionary = {}


static func rules() -> Dictionary:
	if _cache.is_empty():
		if FileAccess.file_exists(RULES_PATH):
			var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
			if v is Dictionary:
				_cache = v
		if _cache.is_empty():
			_cache = {"defaults": {}, "tokens": {}}
	return _cache


## The same four answers the negotiator gives: does it FIT, can it SCALE to
## fit (never below scale_min), does its depth want a SHELF, and what
## STAND-OFF keeps it a nice distance from the plaster.
static func decide(token: String, body: Vector3, run_w: float, run_h: float) -> Dictionary:
	var r: Dictionary = (rules().get("defaults", {}) as Dictionary).duplicate()
	var tok_r: Dictionary = (rules().get("tokens", {}) as Dictionary).get(token, {})
	for k in tok_r:
		r[k] = tok_r[k]
	var w: float = body.x
	var d: float = body.y
	var h: float = body.z
	var margin: float = float(r.get("margin_m", 0.15))
	var free_w: float = run_w - 2.0 * margin
	var free_h: float = run_h - 2.0 * margin
	var out: Dictionary = {"mode": "hang", "scale": 1.0, "shelf": false,
		"standoff": float(r.get("standoff_shallow_m", 0.035)), "v_centre": float(r.get("eye_v_m", 1.55))}
	if d <= float(r.get("flat_depth_m", 0.08)):
		out["standoff"] = float(r.get("standoff_flat_m", 0.02))
	elif d <= float(r.get("shallow_depth_m", 0.25)):
		out["standoff"] = float(r.get("standoff_shallow_m", 0.035))
	else:
		out["standoff"] = float(r.get("standoff_boxy_m", 0.05))
		out["shelf"] = true
	if r.has("shelf"):
		out["shelf"] = bool(r["shelf"])
	if free_w <= 0.1 or free_h <= 0.1:
		out["mode"] = "refuse"
		return out
	if w > free_w or h > free_h:
		var sc: float = minf(free_w / maxf(w, 0.01), free_h / maxf(h, 0.01))
		sc = floorf(sc * 20.0) / 20.0
		if sc >= float(r.get("scale_min", 0.55)):
			out["mode"] = "scale"
			out["scale"] = sc
		else:
			out["mode"] = "refuse"
			return out
	var eff_h: float = h * float(out["scale"])
	var v: float = float(r.get("eye_v_m", 1.55))
	if v - eff_h / 2.0 < float(r.get("bottom_min_m", 0.3)):
		v = float(r.get("bottom_min_m", 0.3)) + eff_h / 2.0
	out["v_centre"] = v
	return out


## The shelf a deep body earns: a plain bracket under it, museum tones.
static func make_shelf(width: float, depth: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(maxf(width + 0.12, 0.3), 0.04, maxf(depth + 0.08, 0.2))
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.82, 0.81, 0.79)
	mi.material_override = m
	return mi
