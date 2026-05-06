# amphora.gd
# A two-handled storage vessel — classical pottery form. Body (belly),
# neck, lip, plus two symmetric handles arching from shoulder to neck.
# Everything reads as a single vessel via smooth_union.
#
# DNA used:
#   height       — overall height (default 0.70m = Modulor red rung 3 bigger)
#   belly_width  — widest point (default 0.40m)
#   neck_ratio   — neck width as fraction of belly (default 0.35)

extends "res://commons/morphology/sdf/body_recipe.gd"

const ModulorScale = preload("res://commons/morphology/sdf/modulor_scale.gd")


func _build_from_dna() -> void:
	var height: float = float(dna.get("height", ModulorScale.blue(3)))   # ~0.70m
	var belly_w: float = float(dna.get("belly_width", 0.40))
	var neck_ratio: float = float(dna.get("neck_ratio", 0.35))

	var base_h: float = height * 0.08
	var neck_h: float = height * 0.22
	var body_h: float = height - base_h - neck_h
	var neck_r: float = belly_w * neck_ratio
	var belly_r: float = belly_w * 0.5

	# FOOT — narrow base where the amphora stands.
	var foot := make_ellipsoid(
		Vector3(0, base_h * 0.5, 0),
		Vector3(belly_w * 0.22, base_h * 0.5, belly_w * 0.22),
	)
	_add_part(foot, "foot")

	# BELLY — the big round middle. Ellipsoid stretched vertically, fattest
	# at about 40% of body height.
	var belly_center: Vector3 = Vector3(0, base_h + body_h * 0.45, 0)
	var belly := make_ellipsoid(
		belly_center,
		Vector3(belly_r, body_h * 0.5, belly_r),
	)
	_add_part(belly, "belly")

	# SHOULDER — narrower ellipsoid bridging belly to neck, creates the
	# classical taper transition.
	var shoulder_y: float = base_h + body_h * 0.85
	var shoulder_r: float = belly_r * 0.75
	var shoulder := make_ellipsoid(
		Vector3(0, shoulder_y, 0),
		Vector3(shoulder_r, body_h * 0.12, shoulder_r),
	)
	_add_part(shoulder, "shoulder")

	# NECK — tall narrow cylinder from shoulder to lip.
	var neck_bottom: Vector3 = Vector3(0, base_h + body_h, 0)
	var neck_top: Vector3 = Vector3(0, height - base_h * 0.3, 0)
	var neck := _capsule_helper(neck_bottom, neck_top, neck_r)
	_add_part(neck, "neck")

	# LIP — flared rim at the top.
	var lip := make_ellipsoid(
		Vector3(0, height, 0),
		Vector3(neck_r * 1.3, base_h * 0.4, neck_r * 1.3),
	)
	_add_part(lip, "lip")

	# HANDLES — two symmetric C-curves from shoulder to upper neck.
	# Approximate as three capsules per handle (low end, arch, high end).
	for side in [1.0, -1.0]:
		var shoulder_attach: Vector3 = Vector3(shoulder_r * 0.95 * side, shoulder_y, 0)
		var handle_peak: Vector3 = Vector3((neck_r + 0.05) * 2.0 * side, neck_bottom.y + neck_h * 0.4, 0)
		var neck_attach: Vector3 = Vector3(neck_r * 1.05 * side, neck_bottom.y + neck_h * 0.8, 0)
		_add_part(_capsule_helper(shoulder_attach, handle_peak, 0.025), "handle")
		_add_part(_capsule_helper(handle_peak, neck_attach, 0.025), "handle")
