# klein_bottle_body.gd — Non-orientable closed surface.
# Ported from tools/blender/math/klein_bottle.py.
#
# DNA used:
#   scale    — overall scale factor (default 0.05 so default result is ~1m across)
#   num_u    — samples along U (default 48)
#   num_v    — samples along V (default 24)

extends "res://commons/morphology/parametric/parametric_body.gd"


func _setup() -> void:
	u_min = 0.0
	u_max = TAU
	v_min = 0.0
	v_max = TAU
	num_u = clampi(int(dna.get("num_u", 48)), 12, 128)
	num_v = clampi(int(dna.get("num_v", 24)), 8, 64)
	close_u = true
	close_v = true


func _surface(u: float, v: float) -> Vector3:
	var s: float = float(dna.get("scale", 0.05))
	var half: bool = u < PI
	var r: float = 4.0 * (1.0 - cos(u) / 2.0)
	var x: float
	var y: float
	if half:
		x = 6.0 * cos(u) * (1.0 + sin(u)) + r * cos(u) * cos(v)
		y = 16.0 * sin(u) + r * sin(u) * cos(v)
	else:
		x = 6.0 * cos(u) * (1.0 + sin(u)) + r * cos(v + PI)
		y = 16.0 * sin(u)
	var z: float = r * sin(v)
	return Vector3(x, y, z) * s
