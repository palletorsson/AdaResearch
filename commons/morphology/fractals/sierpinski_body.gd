# sierpinski_body.gd — Sierpinski tetrahedron fractal.
# Ported from tools/blender/fractals/sierpinski.py. Each step replaces
# one tetrahedron with four smaller tetrahedra at its corners. Final
# tetras are rendered as their four edge capsules (wireframe look) —
# a cleaner read than packed solid shapes at high depth.
#
# DNA used:
#   depth      — recursion depth (default 3). depth 4 ≈ 256 tetras.
#   size       — base tetrahedron edge (default 1.0)
#   radius     — capsule radius per edge (default 0.02)

extends "res://commons/morphology/sdf/body_recipe.gd"


func _build_from_dna() -> void:
	var depth: int = clampi(int(dna.get("depth", 3)), 0, 5)
	var size: float = float(dna.get("size", 1.0))
	var radius: float = float(dna.get("radius", 0.02))

	joint_k = clamp(radius * 0.5, 0.005, 0.05)

	# Start tetrahedron — regular, apex on +Y
	var h: float = size * sqrt(2.0 / 3.0)
	var corners: Array = [
		Vector3(-size * 0.5, 0, -size * 0.288),
		Vector3( size * 0.5, 0, -size * 0.288),
		Vector3( 0,          0,  size * 0.577),
		Vector3( 0,          h,  0),
	]
	var tetras: Array = []
	_subdivide(corners, depth, tetras)

	# Emit the 6 edges of each leaf tetrahedron as capsules
	for t in tetras:
		var pairs := [[0,1], [0,2], [0,3], [1,2], [1,3], [2,3]]
		for pair in pairs:
			var cap := _capsule_helper(t[pair[0]], t[pair[1]], radius)
			_add_part(cap, "body")


func _subdivide(corners: Array, depth: int, out: Array) -> void:
	if depth == 0:
		out.append(corners)
		return
	# Midpoints of each edge (but we only need the 4 smaller tetrahedra
	# at the original corners, each shrunk by 2x toward its corner).
	for i in 4:
		var new_corners: Array = []
		for j in 4:
			var p: Vector3 = corners[j]
			# Contract toward corner[i] by factor 0.5
			new_corners.append((corners[i] as Vector3).lerp(p, 0.5))
		_subdivide(new_corners, depth - 1, out)
