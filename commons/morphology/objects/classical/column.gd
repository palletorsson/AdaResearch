# column.gd
# A Doric column: base + shaft + capital + abacus. Four parts, each slot
# tagged so the stone shader can vary per piece (weathering on the
# plinth, polish on the shaft). Modulor-anchored — default height is
# one rung down from raised-arm (1.4m), capital sits atop.
#
# DNA used:
#   height        — total column height (default 2.26m, Modulor anchor)
#   base_radius   — shaft base radius (default 0.20m)
#   taper         — 0..1, shaft top radius as fraction of base (default 0.82)
#   fluted        — bool (reserved for vertical-ridge pattern shader)

extends "res://commons/morphology/sdf/body_recipe.gd"

const ModulorScale = preload("res://commons/morphology/sdf/modulor_scale.gd")


func _build_from_dna() -> void:
	var height: float = float(dna.get("height", ModulorScale.red(0)))  # 2.26m
	var base_r: float = float(dna.get("base_radius", 0.20))
	var taper: float = float(dna.get("taper", 0.82))
	var shaft_top_r: float = base_r * taper

	var plinth_h: float = base_r * 0.55
	var cap_h: float = base_r * 0.40
	var abacus_h: float = base_r * 0.20

	# PLINTH — wider, shorter than base. Box for a classical look (not round).
	var plinth := make_ellipsoid(
		Vector3(0, plinth_h * 0.5, 0),
		Vector3(base_r * 1.35, plinth_h * 0.5, base_r * 1.35),
	)
	_add_part(plinth, "plinth")

	# SHAFT — tapered from base to top
	var shaft_bottom: Vector3 = Vector3(0, plinth_h, 0)
	var shaft_top_y: float = height - cap_h - abacus_h
	var shaft_top: Vector3 = Vector3(0, shaft_top_y, 0)
	var shaft := _capsule_helper(shaft_bottom, shaft_top, base_r)
	_add_part(shaft, "shaft")

	# Second capsule for upper shaft — approximates taper by overlaying a
	# thinner capsule for the top half.
	var shaft_mid: Vector3 = shaft_bottom.lerp(shaft_top, 0.5)
	var shaft_upper := _capsule_helper(shaft_mid, shaft_top, shaft_top_r)
	_add_part(shaft_upper, "shaft")

	# CAPITAL — flared block atop shaft. Echinus (flat disc-like block).
	var capital_center: Vector3 = Vector3(0, shaft_top_y + cap_h * 0.5, 0)
	var capital := make_ellipsoid(
		capital_center,
		Vector3(base_r * 1.25, cap_h * 0.5, base_r * 1.25),
	)
	_add_part(capital, "capital")

	# ABACUS — flat square slab on top of capital, supports architrave.
	var abacus_center: Vector3 = Vector3(0, height - abacus_h * 0.5, 0)
	var abacus := make_ellipsoid(
		abacus_center,
		Vector3(base_r * 1.4, abacus_h * 0.5, base_r * 1.4),
	)
	_add_part(abacus, "abacus")
