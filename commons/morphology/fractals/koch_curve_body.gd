# koch_curve_body.gd — Koch snowflake curve as a body of capsules.
# Ported from tools/blender/fractals/koch_curve.py. Each recursive step
# replaces one edge with four edges shaped like a triangle bump; the
# final edges render as capsules smooth-unioned into one fractal ribbon.
#
# DNA used:
#   depth      — recursion depth (default 3)
#   length     — total span of the starting edge (default 2.0)
#   radius     — capsule radius (default 0.04)

extends "res://commons/morphology/sdf/body_recipe.gd"


func _build_from_dna() -> void:
	var depth: int = clampi(int(dna.get("depth", 3)), 0, 6)
	var length: float = float(dna.get("length", 2.0))
	var radius: float = float(dna.get("radius", 0.04))

	joint_k = clamp(radius * 0.5, 0.01, 0.1)

	var start := Vector3(-length * 0.5, 0, 0)
	var end := Vector3(length * 0.5, 0, 0)
	var segments: Array = []
	_koch(start, end, depth, segments)
	for seg in segments:
		var cap := _capsule_helper(seg[0], seg[1], radius)
		_add_part(cap, "body")


func _koch(a: Vector3, b: Vector3, depth: int, out: Array) -> void:
	if depth == 0:
		out.append([a, b])
		return
	# Split ab into 3 equal parts and bump the middle third into a triangle
	var v3 := Vector3((2.0 * a.x + b.x) / 3.0, (2.0 * a.y + b.y) / 3.0, (2.0 * a.z + b.z) / 3.0)
	var v5 := Vector3((a.x + 2.0 * b.x) / 3.0, (a.y + 2.0 * b.y) / 3.0, (a.z + 2.0 * b.z) / 3.0)
	# Peak of the bump: rotate (v5-v3) by 60° around +Z
	var bump_sin: float = sin(PI / 3.0)
	var v4 := Vector3(
		(a.x + b.x) * 0.5 + (b.y - a.y) * bump_sin / 3.0,
		(a.y + b.y) * 0.5 + (a.x - b.x) * bump_sin / 3.0,
		(a.z + b.z) * 0.5,
	)
	_koch(a, v3, depth - 1, out)
	_koch(v3, v4, depth - 1, out)
	_koch(v4, v5, depth - 1, out)
	_koch(v5, b, depth - 1, out)
