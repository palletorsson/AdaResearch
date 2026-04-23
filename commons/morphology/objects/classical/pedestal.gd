# pedestal.gd
# A classical display pedestal: base + die (the vertical block holding
# inscriptions) + cornice. Square plan, Modulor-scaled to hand-reachable
# shelf height by default.
#
# DNA used:
#   height        — overall height (default 1.13m = Modulor navel)
#   width         — plan width (default 0.53m)
#   depth         — plan depth (default 0.53m, square by default)

extends "res://commons/morphology/sdf/body_recipe.gd"

const ModulorScale = preload("res://commons/morphology/sdf/modulor_scale.gd")


func _build_from_dna() -> void:
	var height: float = float(dna.get("height", ModulorScale.blue(2)))  # ~1.13m
	var width: float = float(dna.get("width", ModulorScale.red(3)))     # ~0.53m
	var depth_w: float = float(dna.get("depth", width))

	var base_h: float = height * 0.12
	var cornice_h: float = height * 0.10
	var die_h: float = height - base_h - cornice_h

	var half_w: float = width * 0.5
	var half_d: float = depth_w * 0.5

	# BASE — widest, short block at the ground.
	var base_center: Vector3 = Vector3(0, base_h * 0.5, 0)
	var base := make_ellipsoid(
		base_center,
		Vector3(half_w * 1.15, base_h * 0.5, half_d * 1.15),
	)
	_add_part(base, "base")

	# DIE — the main vertical block. Can carry inscriptions or a statue.
	var die_center: Vector3 = Vector3(0, base_h + die_h * 0.5, 0)
	var die := make_ellipsoid(
		die_center,
		Vector3(half_w, die_h * 0.5, half_d),
	)
	_add_part(die, "die")

	# CORNICE — slightly wider cap with a top ledge.
	var cornice_center: Vector3 = Vector3(0, base_h + die_h + cornice_h * 0.5, 0)
	var cornice := make_ellipsoid(
		cornice_center,
		Vector3(half_w * 1.1, cornice_h * 0.5, half_d * 1.1),
	)
	_add_part(cornice, "cornice")
