# tree_body.gd
# Tree recipe — body_type ≈ 0.0 in CritterDNA.
#
# Wraps a GrowthSDF (L-system branches) with a dedicated trunk capsule so
# tree silhouette reads with a clear root column, not just a mess of
# branches. A canopy bulb at the top of the L-system adds foliage mass.
#
# Reads DNA genes:
#   scale           — overall size multiplier (trunk height + girth scale)
#   segments        — L-system iterations (2..4 readable at voxel res)
#   symmetry        — branching factor per recursion (2..4)
#   pattern_density — canopy density (0..1): how fat the top blob is
#
# Composition:
#   trunk (tapered capsule from ground up)
#   + L-system branches (GrowthSDF)
#   + canopy bulb (large ellipsoid crowning the L-system)

extends "res://commons/morphology/sdf/body_recipe.gd"

const GrowthSDFClass = preload("res://commons/morphology/sdf/growth_sdf.gd")


func _build_from_dna() -> void:
	var scale: float = float(dna.get("scale", 1.0))
	var iterations: int = int(dna.get("segments", 3.0))
	var branching: int = int(dna.get("symmetry", 3.0))
	var canopy_density: float = float(dna.get("pattern_density", 0.6))

	iterations = clampi(iterations, 1, 4)
	branching = clampi(branching, 2, 4)

	var trunk_height: float = 0.9 * scale
	var trunk_radius: float = 0.14 * scale

	# Trunk — tapered (use two capsules: wide base, narrower upper)
	var trunk_mid: Vector3 = Vector3(0, trunk_height * 0.55, 0)
	var trunk_top: Vector3 = Vector3(0, trunk_height, 0)
	var trunk_base := _capsule_helper(Vector3.ZERO, trunk_mid, trunk_radius * 1.2)
	var trunk_upper := _capsule_helper(trunk_mid, trunk_top, trunk_radius * 0.85)
	_parts.append(trunk_base)
	_parts.append(trunk_upper)

	# L-system canopy — branches sprouting from top of trunk
	var growth = GrowthSDFClass.new()
	growth.axiom = "F"
	# Rule complexity scales with branching factor
	var rule: String = "F"
	if branching == 2:
		rule = "F[+F]F[-F]"
	elif branching == 3:
		rule = "F[+F]F[-F]F"
	else:
		rule = "F[+F][-F][+F][-F]F"
	growth.rules = {"F": rule}
	growth.iterations = iterations
	growth.step_length = 0.28 * scale
	growth.angle_degrees = 22.0
	growth.branch_radius = 0.08 * scale * lerp(0.7, 1.3, canopy_density)
	growth.origin = trunk_top
	growth.rebuild()
	_parts.append(growth)

	# Canopy bulb — fat ellipsoid smoothing the L-system into foliage mass.
	# Scaled by canopy_density; at low density we get a bare tree, high density
	# gets a full round crown.
	var canopy_r: float = lerpf(0.25, 0.8, canopy_density) * scale
	var canopy_center: Vector3 = trunk_top + Vector3(0, canopy_r * 0.8, 0)
	var canopy := make_ellipsoid(
		canopy_center,
		Vector3(canopy_r, canopy_r * 0.9, canopy_r),
	)
	_parts.append(canopy)
