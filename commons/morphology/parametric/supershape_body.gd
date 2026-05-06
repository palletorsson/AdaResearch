# supershape_body.gd — Gielis superformula as a closed 3D surface.
# Ported from tools/blender/math/supershape.py. One parameterized
# primitive that subsumes sphere, cube, star, flower, prism etc. by
# tweaking m / n1 / n2 / n3.
#
# DNA used:
#   scale  — overall scale (default 0.5)
#   m      — symmetry (default 6 = hex star; 2 = prism; 0 = sphere)
#   n1,n2,n3 — shape exponents (default 1,1,1 ≈ sphere)
#   a,b    — radial scales (default 1,1)
#   num_u  — longitude segments (default 64)
#   num_v  — latitude segments  (default 32)

extends "res://commons/morphology/parametric/parametric_body.gd"


func _setup() -> void:
	u_min = -PI
	u_max =  PI
	v_min = -PI * 0.5
	v_max =  PI * 0.5
	num_u = clampi(int(dna.get("num_u", 64)), 16, 128)
	num_v = clampi(int(dna.get("num_v", 32)), 8, 128)
	close_u = true
	close_v = false


func _surface(theta: float, phi: float) -> Vector3:
	var s: float = float(dna.get("scale", 0.5))
	var m: float = float(dna.get("m", 6.0))
	var n1: float = float(dna.get("n1", 1.0))
	var n2: float = float(dna.get("n2", 1.0))
	var n3: float = float(dna.get("n3", 1.0))
	var a: float = float(dna.get("a", 1.0))
	var b: float = float(dna.get("b", 1.0))

	var r1: float = _superformula(phi,   m, a, b, n1, n2, n3)
	var r2: float = _superformula(theta, m, a, b, n1, n2, n3)
	var x: float = s * r1 * cos(phi) * r2 * cos(theta)
	var y: float = s * r1 * sin(phi) * r2 * cos(theta)
	var z: float = s * r2 * sin(theta)
	return Vector3(x, y, z)


static func _superformula(angle: float, m: float, a: float, b: float,
		n1: float, n2: float, n3: float) -> float:
	var t1: float = pow(abs((1.0 / a) * cos(m * angle / 4.0)), n2)
	var t2: float = pow(abs((1.0 / b) * sin(m * angle / 4.0)), n3)
	var s: float = t1 + t2
	if s <= 1e-6:
		return 0.0
	# Original formula: r = (t1 + t2) ^ (-1/n1)
	return pow(s, -1.0 / max(n1, 0.01))
