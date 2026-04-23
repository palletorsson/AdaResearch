# mobius_strip_body.gd — Classic half-twisted strip.
# Ported from tools/blender/math/mobius_strip.py.
#
# DNA used:
#   radius     — loop radius (default 1.0)
#   width      — half-width of the strip (default 0.3)
#   twists     — number of half-twists (default 1)
#   segments   — segments along the loop (default 48)
#   w_segments — segments across the strip (default 8)

extends "res://commons/morphology/parametric/parametric_body.gd"


func _setup() -> void:
	u_min = 0.0
	u_max = TAU
	v_min = -1.0
	v_max = 1.0
	num_u = clampi(int(dna.get("segments", 48)), 12, 128)
	num_v = clampi(int(dna.get("w_segments", 8)), 4, 32)
	close_u = true
	close_v = false


func _surface(u: float, v: float) -> Vector3:
	var r: float = float(dna.get("radius", 1.0))
	var w: float = float(dna.get("width", 0.3))
	var t: float = float(dna.get("twists", 1))
	var half_twist: float = t * u / 2.0
	var x: float = cos(u) * (r + v * w * sin(half_twist))
	var y: float = sin(u) * (r + v * w * sin(half_twist))
	var z: float = v * w * cos(half_twist)
	return Vector3(x, y, z)
